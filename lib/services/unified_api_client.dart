import 'dart:async';
import 'package:dio/dio.dart';
import '../utils/waste_app_logger.dart';
import 'enhanced_api_error_handler.dart';
import 'cost_tracking_interceptor.dart';
import 'rate_limiter.dart';
import '../models/api_version.dart';
import '../models/api_response.dart';

/// Unified API client with comprehensive error handling, versioning, and optimization
///
/// Features:
/// - Unified interface for all API calls
/// - Automatic retry with exponential backoff
/// - Request/response interceptors
/// - Rate limiting and cost optimization
/// - API versioning support
/// - Request deduplication
/// - Circuit breaker pattern
/// - Comprehensive logging and monitoring
class UnifiedApiClient {
  UnifiedApiClient({
    String? baseUrl,
    Map<String, String>? defaultHeaders,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Duration? sendTimeout,
    EnhancedApiErrorHandler? errorHandler,
    this.enableRequestDeduplication = false,
    this.enableRateLimiting = true,
    this.maxConcurrentRequests = 10,
  }) : _errorHandler = errorHandler ?? EnhancedApiErrorHandler() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl ?? '',
      connectTimeout: connectTimeout ?? const Duration(seconds: 30),
      receiveTimeout: receiveTimeout ?? const Duration(seconds: 60),
      sendTimeout: sendTimeout ?? const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'WasteSegregationApp/1.0',
        ...?defaultHeaders,
      },
    ));

    _setupInterceptors();
    _initializeRateLimiter();
    // Schedule periodic deduplication cache cleanup
    if (enableRequestDeduplication) {
      _schedulePeriodicCleanup();
    }
  }

  late final Dio _dio;
  final EnhancedApiErrorHandler _errorHandler;
  final bool enableRequestDeduplication;
  final bool enableRateLimiting;
  final int maxConcurrentRequests;

  // Request deduplication
  final Map<String, Future<Response>> _pendingRequests = {};
  final Map<String, DateTime> _requestTimestamps = {};
  static const Duration _deduplicationWindow = Duration(seconds: 5);

  // Rate limiting
  final Map<String, RateLimiter> _rateLimiters = {};
  int _activeRequests = 0;
  final List<Completer<void>> _requestQueue = [];

  // API versioning
  final Map<String, ApiVersion> _apiVersions = {};
  ApiVersion? _defaultVersion;

  /// Initialize the client with API version configurations
  void configureApiVersions({
    required Map<String, ApiVersion> versions,
    ApiVersion? defaultVersion,
  }) {
    _apiVersions.clear();
    _apiVersions.addAll(versions);
    _defaultVersion = defaultVersion ?? versions.values.first;

    WasteAppLogger.info('API versions configured', context: {
      'versions': versions.keys.toList(),
      'default_version': _defaultVersion?.version,
    });
  }

  /// Make a GET request with unified error handling
  Future<ApiResponse<T>> get<T>({
    required String endpoint,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    String? apiVersion,
    bool enableCache = true,
    Duration? timeout,
    String? operationId,
  }) async {
    return _executeRequest<T>(
      method: 'GET',
      endpoint: endpoint,
      queryParameters: queryParameters,
      headers: headers,
      apiVersion: apiVersion,
      enableCache: enableCache,
      timeout: timeout,
      operationId: operationId ?? 'GET_$endpoint',
    );
  }

  /// Make a POST request with unified error handling
  Future<ApiResponse<T>> post<T>({
    required String endpoint,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    String? apiVersion,
    Duration? timeout,
    String? operationId,
    ProgressCallback? onSendProgress,
  }) async {
    return _executeRequest<T>(
      method: 'POST',
      endpoint: endpoint,
      data: data,
      queryParameters: queryParameters,
      headers: headers,
      apiVersion: apiVersion,
      timeout: timeout,
      operationId: operationId ?? 'POST_$endpoint',
      onSendProgress: onSendProgress,
    );
  }

  /// Make a PUT request with unified error handling
  Future<ApiResponse<T>> put<T>({
    required String endpoint,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    String? apiVersion,
    Duration? timeout,
    String? operationId,
  }) async {
    return _executeRequest<T>(
      method: 'PUT',
      endpoint: endpoint,
      data: data,
      queryParameters: queryParameters,
      headers: headers,
      apiVersion: apiVersion,
      timeout: timeout,
      operationId: operationId ?? 'PUT_$endpoint',
    );
  }

  /// Make a DELETE request with unified error handling
  Future<ApiResponse<T>> delete<T>({
    required String endpoint,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    String? apiVersion,
    Duration? timeout,
    String? operationId,
  }) async {
    return _executeRequest<T>(
      method: 'DELETE',
      endpoint: endpoint,
      queryParameters: queryParameters,
      headers: headers,
      apiVersion: apiVersion,
      timeout: timeout,
      operationId: operationId ?? 'DELETE_$endpoint',
    );
  }

  /// Execute request with comprehensive error handling and optimization
  Future<ApiResponse<T>> _executeRequest<T>({
    required String method,
    required String endpoint,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    String? apiVersion,
    bool enableCache = false,
    Duration? timeout,
    required String operationId,
    ProgressCallback? onSendProgress,
  }) async {
    // Get API version configuration
    final version = _getApiVersion(apiVersion);
    final versionedEndpoint = _buildVersionedEndpoint(endpoint, version);

    // Build request key for deduplication
    final requestKey =
        _buildRequestKey(method, versionedEndpoint, queryParameters, data);

    // Check for duplicate requests
    if (enableRequestDeduplication && _isDuplicateRequest(requestKey)) {
      WasteAppLogger.info('Deduplicating request', context: {
        'operation_id': operationId,
        'request_key': requestKey,
        'method': method,
        'endpoint': versionedEndpoint,
      });

      final existingRequest = _pendingRequests[requestKey]!;
      final response = await existingRequest;
      return _buildApiResponse<T>(response, operationId);
    }

    // Apply rate limiting
    await _acquireRateLimit(version.serviceName);

    // Execute request with error handling
    final requestFuture = _errorHandler.executeWithErrorHandling<Response>(
      serviceName: version.serviceName,
      operationId: operationId,
      operation: () => _makeHttpRequest(
        method: method,
        endpoint: versionedEndpoint,
        data: data,
        queryParameters: queryParameters,
        headers: _buildHeaders(headers, version),
        timeout: timeout,
        onSendProgress: onSendProgress,
      ),
      metadata: {
        'method': method,
        'endpoint': versionedEndpoint,
        'api_version': version.version,
        'has_data': data != null,
        'query_params': queryParameters?.keys.toList(),
      },
    );

    // Store for deduplication
    if (enableRequestDeduplication) {
      _pendingRequests[requestKey] = requestFuture;
      _requestTimestamps[requestKey] = DateTime.now();
    }

    try {
      final response = await requestFuture;
      return _buildApiResponse<T>(response, operationId);
    } finally {
      // Clean up deduplication cache
      if (enableRequestDeduplication) {
        _pendingRequests.remove(requestKey);
        _requestTimestamps.remove(requestKey);
      }

      // Release rate limit
      _releaseRateLimit(version.serviceName);
    }
  }

  /// Make the actual HTTP request
  Future<Response> _makeHttpRequest({
    required String method,
    required String endpoint,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    Duration? timeout,
    ProgressCallback? onSendProgress,
  }) async {
    final options = Options(
      method: method,
      headers: headers,
      sendTimeout: timeout,
      receiveTimeout: timeout,
    );

    switch (method.toUpperCase()) {
      case 'GET':
        return _dio.get(
          endpoint,
          queryParameters: queryParameters,
          options: options,
        );
      case 'POST':
        return _dio.post(
          endpoint,
          data: data,
          queryParameters: queryParameters,
          options: options,
          onSendProgress: onSendProgress,
        );
      case 'PUT':
        return _dio.put(
          endpoint,
          data: data,
          queryParameters: queryParameters,
          options: options,
        );
      case 'DELETE':
        return _dio.delete(
          endpoint,
          queryParameters: queryParameters,
          options: options,
        );
      default:
        throw ArgumentError('Unsupported HTTP method: $method');
    }
  }

  /// Setup request/response interceptors
  void _setupInterceptors() {
    // Request interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final startTime = DateTime.now();
        options.extra['start_time'] = startTime;

        WasteAppLogger.info('API Request', context: {
          'method': options.method,
          'url': options.uri.toString(),
          'headers': _sanitizeHeaders(options.headers),
          'has_data': options.data != null,
          'timestamp': startTime.toIso8601String(),
        });

        handler.next(options);
      },
      onResponse: (response, handler) {
        final startTime =
            response.requestOptions.extra['start_time'] as DateTime?;
        final duration = startTime != null
            ? DateTime.now().difference(startTime)
            : Duration.zero;

        WasteAppLogger.info('API Response', context: {
          'method': response.requestOptions.method,
          'url': response.requestOptions.uri.toString(),
          'status_code': response.statusCode,
          'duration_ms': duration.inMilliseconds,
          'response_size': response.data?.toString().length ?? 0,
        });

        handler.next(response);
      },
      onError: (error, handler) {
        final startTime = error.requestOptions.extra['start_time'] as DateTime?;
        final duration = startTime != null
            ? DateTime.now().difference(startTime)
            : Duration.zero;

        WasteAppLogger.warning('API Error', error: error, context: {
          'method': error.requestOptions.method,
          'url': error.requestOptions.uri.toString(),
          'error_type': error.type.name,
          'status_code': error.response?.statusCode,
          'duration_ms': duration.inMilliseconds,
          'error_message': error.message,
        });

        handler.next(error);
      },
    ));

    // Add cost tracking interceptor
    _dio.interceptors.add(CostTrackingInterceptor());
  }

  /// Initialize rate limiting system
  void _initializeRateLimiter() {
    // Default rate limiters for different services
    _rateLimiters['openai'] = RateLimiter(
      maxRequests: 60,
      windowDuration: const Duration(minutes: 1),
      burstLimit: 10,
    );

    _rateLimiters['gemini'] = RateLimiter(
      maxRequests: 100,
      windowDuration: const Duration(minutes: 1),
      burstLimit: 15,
    );

    _rateLimiters['firebase'] = RateLimiter(
      maxRequests: 1000,
      windowDuration: const Duration(minutes: 1),
      burstLimit: 50,
    );
  }

  /// Acquire rate limit for service
  Future<void> _acquireRateLimit(String serviceName) async {
    if (!enableRateLimiting) return;

    // Check concurrent request limit
    while (_activeRequests >= maxConcurrentRequests) {
      final completer = Completer<void>();
      _requestQueue.add(completer);
      await completer.future;
    }

    _activeRequests++;

    // Check service-specific rate limit
    final rateLimiter = _rateLimiters[serviceName];
    if (rateLimiter != null) {
      await rateLimiter.acquire();
    }
  }

  /// Release rate limit for service
  void _releaseRateLimit(String serviceName) {
    if (!enableRateLimiting) return;

    _activeRequests--;

    // Process queued requests
    if (_requestQueue.isNotEmpty) {
      final completer = _requestQueue.removeAt(0);
      completer.complete();
    }
  }

  /// Get API version configuration
  ApiVersion _getApiVersion(String? versionName) {
    if (versionName != null && _apiVersions.containsKey(versionName)) {
      return _apiVersions[versionName]!;
    }
    return _defaultVersion ?? ApiVersion.defaultVersion();
  }

  /// Build versioned endpoint
  String _buildVersionedEndpoint(String endpoint, ApiVersion version) {
    if (version.pathPrefix.isNotEmpty) {
      return '${version.pathPrefix}/$endpoint'.replaceAll('//', '/');
    }
    return endpoint;
  }

  /// Build headers with version-specific additions
  Map<String, String> _buildHeaders(
      Map<String, String>? headers, ApiVersion version) {
    final combinedHeaders = <String, String>{
      ...?headers,
      ...version.headers,
    };

    // Add version header if specified
    if (version.headerName.isNotEmpty) {
      combinedHeaders[version.headerName] = version.version;
    }

    return combinedHeaders;
  }

  /// Build request key for deduplication
  String _buildRequestKey(
    String method,
    String endpoint,
    Map<String, dynamic>? queryParameters,
    dynamic data,
  ) {
    final components = [
      method,
      endpoint,
      queryParameters?.toString() ?? '',
      data?.toString() ?? '',
    ];
    return components.join('|');
  }

  /// Check if request is duplicate within time window
  bool _isDuplicateRequest(String requestKey) {
    if (!_pendingRequests.containsKey(requestKey)) return false;

    final timestamp = _requestTimestamps[requestKey];
    if (timestamp == null) return false;

    final age = DateTime.now().difference(timestamp);
    return age < _deduplicationWindow;
  }

  /// Build API response wrapper
  ApiResponse<T> _buildApiResponse<T>(Response response, String operationId) {
    return ApiResponse<T>(
      data: response.data,
      statusCode: response.statusCode ?? 0,
      statusMessage: response.statusMessage,
      headers: response.headers.map,
      operationId: operationId,
      requestOptions: response.requestOptions,
    );
  }

  /// Sanitize headers for logging (remove sensitive data)
  Map<String, dynamic> _sanitizeHeaders(Map<String, dynamic> headers) {
    final sanitized = Map<String, dynamic>.from(headers);
    const sensitiveKeys = ['authorization', 'api-key', 'x-api-key', 'bearer'];

    for (final key in sensitiveKeys) {
      if (sanitized.containsKey(key)) {
        sanitized[key] = '***REDACTED***';
      }
    }

    return sanitized;
  }

  /// Clean up expired deduplication entries
  void _cleanupDeduplicationCache() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    for (final entry in _requestTimestamps.entries) {
      if (now.difference(entry.value) > _deduplicationWindow) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _pendingRequests.remove(key);
      _requestTimestamps.remove(key);
    }

    if (expiredKeys.isNotEmpty) {
      WasteAppLogger.fine('Cleaned up deduplication cache', context: {
        'service': 'unified_api_client',
        'expired_entries': expiredKeys.length,
        'remaining_entries': _requestTimestamps.length,
      });
    }
  }

  /// Schedule periodic cleanup of deduplication cache
  void _schedulePeriodicCleanup() {
    // Run cleanup every 5 minutes
    Timer.periodic(const Duration(minutes: 5), (_) {
      _cleanupDeduplicationCache();
    });
  }

  /// Get client statistics for monitoring
  Map<String, dynamic> getStatistics() {
    return {
      'active_requests': _activeRequests,
      'queued_requests': _requestQueue.length,
      'pending_deduplicated_requests': _pendingRequests.length,
      'rate_limiters': _rateLimiters
          .map((key, value) => MapEntry(key, value.getStatistics())),
      'circuit_breaker_status': _errorHandler.getCircuitBreakerStatus(),
      'api_versions':
          _apiVersions.map((key, value) => MapEntry(key, value.toMap())),
    };
  }

  /// Dispose resources
  void dispose() {
    _dio.close();
    _pendingRequests.clear();
    _requestTimestamps.clear();
    _requestQueue.clear();
    _rateLimiters.clear();
  }
}
