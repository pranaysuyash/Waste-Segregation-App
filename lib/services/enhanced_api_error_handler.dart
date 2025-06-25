import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import '../utils/waste_app_logger.dart';

/// Enhanced error handler for API operations with circuit breaker pattern
///
/// Provides:
/// - Detailed error classification and logging
/// - Circuit breaker pattern for failing services
/// - Automatic retry logic with exponential backoff
/// - Cost-aware error handling
class EnhancedApiErrorHandler {
  EnhancedApiErrorHandler({
    this.maxRetries = 3,
    this.circuitBreakerThreshold = 5,
    this.circuitBreakerTimeout = const Duration(minutes: 5),
  });

  final int maxRetries;
  final int circuitBreakerThreshold;
  final Duration circuitBreakerTimeout;

  // Circuit breaker state
  final Map<String, CircuitBreakerState> _circuitStates = {};
  final Map<String, DateTime> _lastFailureTime = {};
  final Map<String, int> _failureCount = {};

  /// Execute an API operation with enhanced error handling
  Future<T> executeWithErrorHandling<T>({
    required String serviceName,
    required Future<T> Function() operation,
    required String operationId,
    Map<String, dynamic>? metadata,
    bool costSensitive = true,
  }) async {
    // Check circuit breaker
    if (_isCircuitOpen(serviceName)) {
      final error = ApiException.circuitBreakerOpen(
        'Service $serviceName is temporarily unavailable',
        serviceName,
      );
      
      WasteAppLogger.severe('Circuit breaker open for service', error, null, {
        'service': serviceName,
        'operation_id': operationId,
        'circuit_state': _circuitStates[serviceName]?.name,
        'failure_count': _failureCount[serviceName],
        'last_failure': _lastFailureTime[serviceName]?.toIso8601String(),
        ...?metadata,
      });
      
      throw error;
    }

    int attemptCount = 0;
    Exception? lastException;

    while (attemptCount < maxRetries) {
      try {
        final result = await operation();
        
        // Reset circuit breaker on success
        _resetCircuitBreaker(serviceName);
        
        WasteAppLogger.info('API operation successful', null, null, {
          'service': serviceName,
          'operation_id': operationId,
          'attempt': attemptCount + 1,
          'total_attempts': attemptCount + 1,
          ...?metadata,
        });
        
        return result;
      } catch (e) {
        attemptCount++;
        lastException = e is Exception ? e : Exception(e.toString());
        
        final classifiedError = _classifyError(e, serviceName);
        final shouldRetry = _shouldRetry(classifiedError, attemptCount, costSensitive);
        
        WasteAppLogger.warning('API operation failed', e, null, {
          'service': serviceName,
          'operation_id': operationId,
          'attempt': attemptCount,
          'max_attempts': maxRetries,
          'error_type': classifiedError.type.name,
          'error_code': classifiedError.code,
          'should_retry': shouldRetry,
          'cost_sensitive': costSensitive,
          ...?metadata,
        });

        // Update circuit breaker state
        _recordFailure(serviceName);

        if (!shouldRetry || attemptCount >= maxRetries) {
          break;
        }

        // Exponential backoff with jitter
        final delay = _calculateBackoffDelay(attemptCount, classifiedError);
        WasteAppLogger.info('Retrying after delay', null, null, {
          'service': serviceName,
          'operation_id': operationId,
          'delay_ms': delay.inMilliseconds,
          'attempt': attemptCount,
        });
        
        await Future.delayed(delay);
      }
    }

    // All retries exhausted
    final finalError = _enhanceErrorWithContext(lastException!, serviceName, attemptCount, metadata);
    
    WasteAppLogger.severe('API operation failed after all retries', finalError, null, {
      'service': serviceName,
      'operation_id': operationId,
      'total_attempts': attemptCount,
      'circuit_state': _circuitStates[serviceName]?.name,
      ...?metadata,
    });

    throw finalError;
  }

  /// Classify error type for appropriate handling
  ClassifiedApiError _classifyError(dynamic error, String serviceName) {
    if (error is DioException) {
      return _classifyDioError(error, serviceName);
    }
    
    if (error is SocketException || error is TimeoutException) {
      return ClassifiedApiError(
        originalError: error,
        type: ApiErrorType.network,
        isRetryable: true,
        code: 'NETWORK_ERROR',
        message: 'Network connectivity issue',
        serviceName: serviceName,
      );
    }

    if (error is HttpException) {
      final statusCode = _extractStatusCode(error.message);
      return ClassifiedApiError(
        originalError: error,
        type: _getErrorTypeFromStatusCode(statusCode),
        isRetryable: _isRetryableStatusCode(statusCode),
        code: 'HTTP_$statusCode',
        message: error.message,
        serviceName: serviceName,
      );
    }

    // Unknown error type
    return ClassifiedApiError(
      originalError: error,
      type: ApiErrorType.unknown,
      isRetryable: false,
      code: 'UNKNOWN_ERROR',
      message: error.toString(),
      serviceName: serviceName,
    );
  }

  /// Classify Dio-specific errors
  ClassifiedApiError _classifyDioError(DioException error, String serviceName) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ClassifiedApiError(
          originalError: error,
          type: ApiErrorType.timeout,
          isRetryable: true,
          code: 'TIMEOUT_${error.type.name.toUpperCase()}',
          message: 'Request timeout - ${error.message}',
          serviceName: serviceName,
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode ?? 0;
        return ClassifiedApiError(
          originalError: error,
          type: _getErrorTypeFromStatusCode(statusCode),
          isRetryable: _isRetryableStatusCode(statusCode),
          code: 'HTTP_$statusCode',
          message: _extractErrorMessage(error),
          serviceName: serviceName,
          responseData: error.response?.data,
        );

      case DioExceptionType.cancel:
        return ClassifiedApiError(
          originalError: error,
          type: ApiErrorType.cancellation,
          isRetryable: false,
          code: 'REQUEST_CANCELLED',
          message: 'Request was cancelled',
          serviceName: serviceName,
        );

      case DioExceptionType.connectionError:
        return ClassifiedApiError(
          originalError: error,
          type: ApiErrorType.network,
          isRetryable: true,
          code: 'CONNECTION_ERROR',
          message: 'Network connection failed',
          serviceName: serviceName,
        );

      default:
        return ClassifiedApiError(
          originalError: error,
          type: ApiErrorType.unknown,
          isRetryable: false,
          code: 'DIO_ERROR_${error.type.name.toUpperCase()}',
          message: error.message ?? 'Unknown Dio error',
          serviceName: serviceName,
        );
    }
  }

  /// Determine if error should be retried
  bool _shouldRetry(ClassifiedApiError error, int attemptCount, bool costSensitive) {
    // Never retry if not retryable
    if (!error.isRetryable) return false;

    // Don't retry if max attempts reached
    if (attemptCount >= maxRetries) return false;

    // For cost-sensitive operations, be more conservative with retries
    if (costSensitive) {
      switch (error.type) {
        case ApiErrorType.authentication:
        case ApiErrorType.authorization:
        case ApiErrorType.client:
        case ApiErrorType.unknown:
          return false; // Don't retry these for cost-sensitive ops
        case ApiErrorType.rateLimit:
          return attemptCount < 2; // Only retry rate limits once for cost-sensitive
        default:
          return true;
      }
    }

    return true;
  }

  /// Calculate backoff delay with exponential backoff and jitter
  Duration _calculateBackoffDelay(int attemptCount, ClassifiedApiError error) {
    // Base delay starts at 1 second
    int baseDelayMs = 1000;

    // Adjust base delay based on error type
    switch (error.type) {
      case ApiErrorType.rateLimit:
        baseDelayMs = 5000; // 5 seconds for rate limits
        break;
      case ApiErrorType.server:
        baseDelayMs = 2000; // 2 seconds for server errors
        break;
      case ApiErrorType.timeout:
        baseDelayMs = 3000; // 3 seconds for timeouts
        break;
      default:
        baseDelayMs = 1000; // 1 second for others
    }

    // Exponential backoff: base * 2^(attempt-1)
    final exponentialDelay = baseDelayMs * (1 << (attemptCount - 1));

    // Add jitter (±25% of delay)
    final jitter = (exponentialDelay * 0.25).round();
    final randomJitter = (jitter * 2 * (0.5 - (DateTime.now().millisecondsSinceEpoch % 1000) / 1000.0)).round();

    final finalDelay = exponentialDelay + randomJitter;
    
    // Cap at 30 seconds
    return Duration(milliseconds: finalDelay.clamp(baseDelayMs, 30000));
  }

  /// Check if circuit breaker is open for a service
  bool _isCircuitOpen(String serviceName) {
    final state = _circuitStates[serviceName];
    final lastFailure = _lastFailureTime[serviceName];
    
    if (state == CircuitBreakerState.open && lastFailure != null) {
      final timeSinceFailure = DateTime.now().difference(lastFailure);
      if (timeSinceFailure > circuitBreakerTimeout) {
        // Move to half-open state
        _circuitStates[serviceName] = CircuitBreakerState.halfOpen;
        return false;
      }
      return true;
    }
    
    return false;
  }

  /// Record a failure for circuit breaker
  void _recordFailure(String serviceName) {
    _failureCount[serviceName] = (_failureCount[serviceName] ?? 0) + 1;
    _lastFailureTime[serviceName] = DateTime.now();

    if (_failureCount[serviceName]! >= circuitBreakerThreshold) {
      _circuitStates[serviceName] = CircuitBreakerState.open;
      
      WasteAppLogger.warning('Circuit breaker opened for service', null, null, {
        'service': serviceName,
        'failure_count': _failureCount[serviceName],
        'threshold': circuitBreakerThreshold,
        'circuit_state': 'open',
      });
    }
  }

  /// Reset circuit breaker after successful operation
  void _resetCircuitBreaker(String serviceName) {
    if (_circuitStates[serviceName] != null) {
      _circuitStates[serviceName] = CircuitBreakerState.closed;
      _failureCount[serviceName] = 0;
      _lastFailureTime.remove(serviceName);
    }
  }

  /// Enhance error with additional context
  Exception _enhanceErrorWithContext(
    Exception originalError,
    String serviceName,
    int attemptCount,
    Map<String, dynamic>? metadata,
  ) {
    final errorMessage = '''
Service: $serviceName
Attempts: $attemptCount/$maxRetries
Circuit State: ${_circuitStates[serviceName]?.name ?? 'closed'}
Original Error: ${originalError.toString()}
${metadata != null ? 'Metadata: ${metadata.toString()}' : ''}
'''.trim();

    if (originalError is ApiException) {
      return originalError.copyWith(message: errorMessage);
    }

    return ApiException.enhanced(
      errorMessage,
      serviceName,
      originalError: originalError,
    );
  }

  // Helper methods for error classification
  ApiErrorType _getErrorTypeFromStatusCode(int statusCode) {
    if (statusCode >= 200 && statusCode < 300) return ApiErrorType.success;
    if (statusCode == 401) return ApiErrorType.authentication;
    if (statusCode == 403) return ApiErrorType.authorization;
    if (statusCode == 429) return ApiErrorType.rateLimit;
    if (statusCode >= 400 && statusCode < 500) return ApiErrorType.client;
    if (statusCode >= 500) return ApiErrorType.server;
    return ApiErrorType.unknown;
  }

  bool _isRetryableStatusCode(int statusCode) {
    // Retry on server errors, rate limits, and some client errors
    return statusCode >= 500 || 
           statusCode == 429 || 
           statusCode == 408 || 
           statusCode == 503 ||
           statusCode == 502 ||
           statusCode == 504;
  }

  int _extractStatusCode(String? message) {
    if (message == null) return 0;
    final match = RegExp(r'(\d{3})').firstMatch(message);
    return match != null ? int.tryParse(match.group(1)!) ?? 0 : 0;
  }

  String _extractErrorMessage(DioException error) {
    try {
      if (error.response?.data is Map<String, dynamic>) {
        final data = error.response!.data as Map<String, dynamic>;
        return data['error']?['message'] ?? 
               data['message'] ?? 
               data['detail'] ?? 
               error.message ?? 
               'Unknown API error';
      }
    } catch (_) {
      // Fall through to default
    }
    
    return error.message ?? 'API request failed';
  }

  /// Get circuit breaker status for monitoring
  Map<String, dynamic> getCircuitBreakerStatus() {
    return {
      'services': _circuitStates.map((key, value) => MapEntry(key, {
        'state': value.name,
        'failure_count': _failureCount[key] ?? 0,
        'last_failure': _lastFailureTime[key]?.toIso8601String(),
      })),
      'threshold': circuitBreakerThreshold,
      'timeout_minutes': circuitBreakerTimeout.inMinutes,
    };
  }
}

/// Circuit breaker states
enum CircuitBreakerState {
  closed,   // Normal operation
  open,     // Failing, blocking requests
  halfOpen, // Testing if service is back
}

/// API error types for classification
enum ApiErrorType {
  success,
  network,
  timeout,
  authentication,
  authorization,
  rateLimit,
  client,
  server,
  cancellation,
  unknown,
}

/// Classified API error with enhanced metadata
class ClassifiedApiError {
  const ClassifiedApiError({
    required this.originalError,
    required this.type,
    required this.isRetryable,
    required this.code,
    required this.message,
    required this.serviceName,
    this.responseData,
  });

  final dynamic originalError;
  final ApiErrorType type;
  final bool isRetryable;
  final String code;
  final String message;
  final String serviceName;
  final dynamic responseData;

  @override
  String toString() {
    return 'ClassifiedApiError(type: $type, code: $code, message: $message, retryable: $isRetryable)';
  }
}

/// Enhanced API exception with additional context
class ApiException implements Exception {
  const ApiException({
    required this.message,
    required this.serviceName,
    this.code,
    this.originalError,
    this.responseData,
  });

  factory ApiException.circuitBreakerOpen(String message, String serviceName) {
    return ApiException(
      message: message,
      serviceName: serviceName,
      code: 'CIRCUIT_BREAKER_OPEN',
    );
  }

  factory ApiException.enhanced(
    String message,
    String serviceName, {
    Exception? originalError,
  }) {
    return ApiException(
      message: message,
      serviceName: serviceName,
      code: 'ENHANCED_ERROR',
      originalError: originalError,
    );
  }

  final String message;
  final String serviceName;
  final String? code;
  final Exception? originalError;
  final dynamic responseData;

  ApiException copyWith({
    String? message,
    String? serviceName,
    String? code,
    Exception? originalError,
    dynamic responseData,
  }) {
    return ApiException(
      message: message ?? this.message,
      serviceName: serviceName ?? this.serviceName,
      code: code ?? this.code,
      originalError: originalError ?? this.originalError,
      responseData: responseData ?? this.responseData,
    );
  }

  @override
  String toString() {
    return 'ApiException: $message (Service: $serviceName, Code: $code)';
  }
}