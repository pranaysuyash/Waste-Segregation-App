import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
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
    if (enableRequestDeduplication) {
      _schedulePeriodicCleanup();
    }
  }

  late final Dio _dio;
  final EnhancedApiErrorHandler _errorHandler;
  final bool enableRequestDeduplication;
  final bool enableRateLimiting;
  final int maxConcurrentRequests;

  bool _disposed = false;

  // Request deduplication
  final Map<String, Future<Response>> _pendingRequests = {};
  final Map<String, DateTime> _requestTimestamps = {};
  static const Duration _deduplicationWindow = Duration(seconds: 5);

  // Rate limiting
  final Map<String, RateLimiter> _rateLimiters = {};
  int _activeRequests = 0;
  final List<Completer<void>> _requestQueue = [];

  // Periodic cleanup timer
  Timer? _cleanupTimer;

  // API versioning
  final Map<String, ApiVersion> _apiVersions = {};
  ApiVersion? _defaultVersion;

  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );
  static final RegExp _numericPattern = RegExp(r'^\d+$');
  static final RegExp _longOpaquePattern = RegExp(r'^[A-Za-z0-9\-_]{21,}$');

  static const _sensitiveHeaderKeys = {
    'authorization',
    'x-goog-api-key',
    'api-key',
    'x-api-key',
    'cookie',
    'set-cookie',
  };

  /// Initialize the client with API version configurations
  void configureApiVersions({
    required Map<String, ApiVersion> versions,
    ApiVersion? defaultVersion,
  }) {
    _apiVersions
      ..clear()
      ..addAll(versions);
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
    Duration? timeout,
    String? operationId,
  }) async {
    return _executeRequest<T>(
      method: 'GET',
      endpoint: endpoint,
      queryParameters: queryParameters,
      headers: headers,
      apiVersion: apiVersion,
      timeout: timeout,
      operationId: operationId ?? 'GET',
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
      operationId: operationId ?? 'POST',
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
      operationId: operationId ?? 'PUT',
    );
  }

  /// Make a PATCH request with unified error handling
  Future<ApiResponse<T>> patch<T>({
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
      method: 'PATCH',
      endpoint: endpoint,
      data: data,
      queryParameters: queryParameters,
      headers: headers,
      apiVersion: apiVersion,
      timeout: timeout,
      operationId: operationId ?? 'PATCH',
      onSendProgress: onSendProgress,
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
      operationId: operationId ?? 'DELETE',
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
    Duration? timeout,
    required String operationId,
    ProgressCallback? onSendProgress,
  }) async {
    if (_disposed) {
      throw StateError('UnifiedApiClient has been disposed');
    }

    // Get API version configuration
    final version = _getApiVersion(apiVersion);
    final versionedEndpoint = _buildVersionedEndpoint(endpoint, version);

    // Build sanitized request key for deduplication
    final requestKey =
        _buildRequestKey(method, versionedEndpoint, queryParameters, data);

    // Check for duplicate requests
    if (enableRequestDeduplication && _isDuplicateRequest(requestKey)) {
      WasteAppLogger.info('Deduplicating request', context: {
        'operation_id': operationId,
        'method': method,
        'endpoint': _sanitizePath(versionedEndpoint),
      });

      final existingRequest = _pendingRequests[requestKey]!;
      final response = await existingRequest;
      return _buildApiResponse<T>(response, operationId);
    }

    // Apply rate limiting (inside try/finally to ensure release)
    final acquired = <String>{};

    try {
      await _acquireRateLimit(version.serviceName);
      acquired.add(version.serviceName);

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
          'endpoint': _sanitizePath(versionedEndpoint),
          'api_version': version.version,
          'has_data': data != null,
        },
      );

      // Store for deduplication
      if (enableRequestDeduplication) {
        _pendingRequests[requestKey] = requestFuture;
        _requestTimestamps[requestKey] = DateTime.now();
      }

      final response = await requestFuture;
      return _buildApiResponse<T>(response, operationId);
    } finally {
      // Clean up deduplication cache
      if (enableRequestDeduplication) {
        unawaited(_pendingRequests.remove(requestKey));
        _requestTimestamps.remove(requestKey);
      }

      // Release rate limit for each acquired service
      for (final service in acquired) {
        _releaseRateLimit(service);
      }
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
      case 'PATCH':
        return _dio.patch(
          endpoint,
          data: data,
          queryParameters: queryParameters,
          options: options,
          onSendProgress: onSendProgress,
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
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final startTime = DateTime.now();
        options.extra['start_time'] = startTime;

        WasteAppLogger.info('API Request', context: {
          'method': options.method,
          'host': options.uri.host,
          'path': _sanitizePath(options.uri.path),
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
          'host': response.requestOptions.uri.host,
          'path': _sanitizePath(response.requestOptions.uri.path),
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
          'host': error.requestOptions.uri.host,
          'path': _sanitizePath(error.requestOptions.uri.path),
          'error_type': error.type.name,
          'status_code': error.response?.statusCode,
          'duration_ms': duration.inMilliseconds,
          'error_message': error.message,
        });

        handler.next(error);
      },
    ));

    _dio.interceptors.add(CostTrackingInterceptor());
  }

  /// Initialize rate limiting system
  void _initializeRateLimiter() {
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

    while (_activeRequests >= maxConcurrentRequests) {
      final completer = Completer<void>();
      _requestQueue.add(completer);
      await completer.future;
    }

    _activeRequests++;

    final rateLimiter = _rateLimiters[serviceName];
    if (rateLimiter != null) {
      await rateLimiter.acquire();
    }
  }

  /// Release rate limit for service
  void _releaseRateLimit(String serviceName) {
    if (!enableRateLimiting) return;

    _activeRequests--;

    if (_requestQueue.isNotEmpty) {
      _requestQueue.removeAt(0).complete();
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

    if (version.headerName.isNotEmpty) {
      combinedHeaders[version.headerName] = version.version;
    }

    return combinedHeaders;
  }

  /// Build a stable hashed request key for deduplication
  /// Uses only sanitized components — never raw body/query.
  String _buildRequestKey(
    String method,
    String endpoint,
    Map<String, dynamic>? queryParameters,
    dynamic data,
  ) {
    final sanitizedPath = _sanitizePath(endpoint);
    final hasQuery = queryParameters != null && queryParameters.isNotEmpty;
    final hasData = data != null;

    final hashInput = '$method|$sanitizedPath|$hasQuery|$hasData';
    final hash = sha256.convert(utf8.encode(hashInput));
    return base64Encode(hash.bytes);
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

  /// Sanitize headers for logging (case-insensitive, broader set)
  Map<String, dynamic> _sanitizeHeaders(Map<String, dynamic> headers) {
    final sanitized = Map<String, dynamic>.from(headers);
    for (final key in sanitized.keys) {
      if (_sensitiveHeaderKeys.contains(key.toLowerCase())) {
        sanitized[key] = '***REDACTED***';
      }
    }
    return sanitized;
  }

  /// Sanitize a URI path: strip query params, normalize ID segments
  String _sanitizePath(String path) {
    final clean = path.split('?').first;
    final segments = clean
        .split('/')
        .where((s) => s.isNotEmpty)
        .map((segment) {
      if (_numericPattern.hasMatch(segment)) return ':id';
      if (_uuidPattern.hasMatch(segment)) return ':id';
      if (_longOpaquePattern.hasMatch(segment)) return ':id';
      return segment;
    }).toList();
    return '/${segments.join('/')}';
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
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (_) {
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
    _disposed = true;
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    _dio.close();
    _pendingRequests.clear();
    _requestTimestamps.clear();

    // Complete queued request completers with an error
    final queued = List<Completer<void>>.from(_requestQueue);
    _requestQueue.clear();
    for (final completer in queued) {
      if (!completer.isCompleted) {
        completer.completeError(
          StateError('UnifiedApiClient disposed'),
        );
      }
    }

    _rateLimiters.clear();
  }
}
