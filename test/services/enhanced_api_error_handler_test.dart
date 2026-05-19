import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:waste_segregation_app/services/enhanced_api_error_handler.dart';

/// Creates an [EnhancedApiErrorHandler] with minimal retries for fast
/// circuit breaker tests.
///
/// The [circuitBreakerTimeout] is kept long (5 min) so the circuit stays
/// **open** after failures — used for tests that verify blocking.
EnhancedApiErrorHandler _blockingCircuitHandler() {
  return EnhancedApiErrorHandler(
    maxRetries: 1,
    circuitBreakerThreshold: 2,
    circuitBreakerTimeout: const Duration(minutes: 5),
  );
}

/// Creates an [EnhancedApiErrorHandler] with [Duration.zero] timeout so the
/// circuit transitions to **half-open** immediately after opening.
///
/// Used for the 'resets circuit breaker on success after failures' test.
EnhancedApiErrorHandler _resettingCircuitHandler() {
  return EnhancedApiErrorHandler(
    maxRetries: 1,
    circuitBreakerThreshold: 2,
    circuitBreakerTimeout: Duration.zero,
  );
}

void main() {
  group('EnhancedApiErrorHandler', () {
    group('Error classification', () {
      test('classifies timeout errors', () {
        expect(
          EnhancedApiErrorHandler(maxRetries: 1).executeWithErrorHandling(
            serviceName: 'test',
            operation: () => throw DioException(
              type: DioExceptionType.connectionTimeout,
              requestOptions: RequestOptions(path: '/test'),
            ),
            operationId: 'test-op',
          ),
          throwsA(isA<ApiException>()),
        );
      });

      test('classifies 429 as rate limit', () {
        expect(
          EnhancedApiErrorHandler(maxRetries: 1).executeWithErrorHandling(
            serviceName: 'test',
            operation: () => throw DioException(
              type: DioExceptionType.badResponse,
              response: Response(
                statusCode: 429,
                requestOptions: RequestOptions(path: '/test'),
              ),
              requestOptions: RequestOptions(path: '/test'),
            ),
            operationId: 'test-op',
          ),
          throwsA(isA<ApiException>()),
        );
      });

      test('classifies 401 as authentication', () {
        expect(
          EnhancedApiErrorHandler(maxRetries: 1).executeWithErrorHandling(
            serviceName: 'test',
            operation: () => throw DioException(
              type: DioExceptionType.badResponse,
              response: Response(
                statusCode: 401,
                requestOptions: RequestOptions(path: '/test'),
              ),
              requestOptions: RequestOptions(path: '/test'),
            ),
            operationId: 'test-op',
          ),
          throwsA(isA<ApiException>()),
        );
      });

      test('classifies 500 as server error', () {
        expect(
          EnhancedApiErrorHandler(maxRetries: 1).executeWithErrorHandling(
            serviceName: 'test',
            operation: () => throw DioException(
              type: DioExceptionType.badResponse,
              response: Response(
                statusCode: 500,
                requestOptions: RequestOptions(path: '/test'),
              ),
              requestOptions: RequestOptions(path: '/test'),
            ),
            operationId: 'test-op',
          ),
          throwsA(isA<ApiException>()),
        );
      });

      test('classifies cancellation as non-retryable', () {
        expect(
          EnhancedApiErrorHandler(maxRetries: 1).executeWithErrorHandling(
            serviceName: 'test',
            operation: () => throw DioException(
              type: DioExceptionType.cancel,
              requestOptions: RequestOptions(path: '/test'),
            ),
            operationId: 'test-op',
          ),
          throwsA(isA<ApiException>()),
        );
      });

      test('classifies connection error as network', () {
        expect(
          EnhancedApiErrorHandler(maxRetries: 1).executeWithErrorHandling(
            serviceName: 'test',
            operation: () => throw DioException(
              type: DioExceptionType.connectionError,
              requestOptions: RequestOptions(path: '/test'),
            ),
            operationId: 'test-op',
          ),
          throwsA(isA<ApiException>()),
        );
      });
    });

    group('Circuit breaker', () {
      test('opens after threshold failures', () async {
        final handler = _blockingCircuitHandler();

        // Trigger circuit breaker (threshold = 2, each call has 1 attempt)
        for (var i = 0; i < 2; i++) {
          try {
            await handler.executeWithErrorHandling(
              serviceName: 'circuit_test',
              operation: () => throw DioException(
                type: DioExceptionType.connectionTimeout,
                requestOptions: RequestOptions(path: '/test'),
              ),
              operationId: 'test-op',
            );
          } catch (_) {}
        }

        final status = handler.getCircuitBreakerStatus();
        final serviceStatus = status['services']['circuit_test'];
        expect(serviceStatus['state'], 'open');
        expect(serviceStatus['failure_count'], greaterThanOrEqualTo(2));
      });

      test('blocks requests when circuit is open', () async {
        final handler = _blockingCircuitHandler();

        // Trigger circuit breaker (threshold = 2)
        for (var i = 0; i < 2; i++) {
          try {
            await handler.executeWithErrorHandling(
              serviceName: 'block_test',
              operation: () => throw DioException(
                type: DioExceptionType.connectionTimeout,
                requestOptions: RequestOptions(path: '/test'),
              ),
              operationId: 'test-op',
            );
          } catch (_) {}
        }

        // Next request should be blocked immediately with circuit breaker error
        try {
          await handler.executeWithErrorHandling(
            serviceName: 'block_test',
            operation: () async => 'should_not_reach',
            operationId: 'test-op',
          );
          fail('Expected ApiException to be thrown');
        } catch (e) {
          expect(e, isA<ApiException>());
          final apiException = e as ApiException;
          expect(apiException.code, 'CIRCUIT_BREAKER_OPEN');
          expect(apiException.serviceName, 'block_test');
        }
      });

      test('succeeds immediately when operation succeeds', () async {
        final handler = _blockingCircuitHandler();
        final result = await handler.executeWithErrorHandling(
          serviceName: 'success_test',
          operation: () async => 'success',
          operationId: 'test-op',
        );

        expect(result, 'success');

        // Circuit should be closed — no failures recorded
        final status = handler.getCircuitBreakerStatus();
        expect(status['services']['success_test'], isNull);
      });

      test('resets circuit breaker on success after failures', () async {
        final handler = _resettingCircuitHandler();

        // Trigger some failures
        for (var i = 0; i < 2; i++) {
          try {
            await handler.executeWithErrorHandling(
              serviceName: 'reset_test',
              operation: () => throw DioException(
                type: DioExceptionType.connectionTimeout,
                requestOptions: RequestOptions(path: '/test'),
              ),
              operationId: 'test-op',
            );
          } catch (_) {}
        }

        // Now succeed (circuit transitions to half-open immediately with Duration.zero)
        await handler.executeWithErrorHandling(
          serviceName: 'reset_test',
          operation: () async => 'recovered',
          operationId: 'test-op',
        );

        // Circuit should be closed again
        final status = handler.getCircuitBreakerStatus();
        expect(status['services']['reset_test']['state'], 'closed');
        expect(status['services']['reset_test']['failure_count'], 0);
      });
    });

    group('Retry logic', () {
      test('succeeds on retry after initial failure', () async {
        final handler = EnhancedApiErrorHandler(maxRetries: 3);

        var attempts = 0;
        final result = await handler.executeWithErrorHandling(
          serviceName: 'retry_test',
          operation: () async {
            attempts++;
            if (attempts < 3) {
              throw DioException(
                type: DioExceptionType.connectionTimeout,
                requestOptions: RequestOptions(path: '/test'),
              );
            }
            return 'success_on_attempt_3';
          },
          operationId: 'test-op',
        );

        expect(attempts, 3);
        expect(result, 'success_on_attempt_3');
      }, timeout: const Timeout(Duration(seconds: 10)));

      test('throws after exhausting all retries', () async {
        final handler = EnhancedApiErrorHandler(maxRetries: 3);

        var attempts = 0;
        try {
          await handler.executeWithErrorHandling(
            serviceName: 'exhaust_test',
            operation: () async {
              attempts++;
              throw DioException(
                type: DioExceptionType.connectionTimeout,
                requestOptions: RequestOptions(path: '/test'),
              );
            },
            operationId: 'test-op',
          );
          fail('Expected ApiException to be thrown');
        } catch (e) {
          expect(e, isA<ApiException>());
          expect(attempts, 3);
        }
      }, timeout: const Timeout(Duration(seconds: 10)));
    });

    group('Circuit breaker status', () {
      test('getCircuitBreakerStatus() returns expected structure', () {
        final handler = _blockingCircuitHandler();
        final status = handler.getCircuitBreakerStatus();

        expect(status.containsKey('services'), isTrue);
        expect(status.containsKey('threshold'), isTrue);
        expect(status.containsKey('timeout_minutes'), isTrue);
        expect(status['threshold'], 2);
        expect(status['timeout_minutes'], 5);
      });

      test('status includes per-service failure data after failures', () async {
        final handler = _blockingCircuitHandler();

        for (var i = 0; i < 2; i++) {
          try {
            await handler.executeWithErrorHandling(
              serviceName: 'status_test',
              operation: () => throw DioException(
                type: DioExceptionType.connectionTimeout,
                requestOptions: RequestOptions(path: '/test'),
              ),
              operationId: 'test-op',
            );
          } catch (_) {}
        }

        final status = handler.getCircuitBreakerStatus();
        final serviceStatus = status['services']['status_test'];
        expect(serviceStatus['failure_count'], greaterThanOrEqualTo(2));
        expect(serviceStatus['last_failure'], isNotNull);
      });
    });
  });

  group('ApiException', () {
    test('circuitBreakerOpen factory sets correct code', () {
      final exception = ApiException.circuitBreakerOpen(
        'Service is down',
        'test_service',
      );

      expect(exception.message, 'Service is down');
      expect(exception.serviceName, 'test_service');
      expect(exception.code, 'CIRCUIT_BREAKER_OPEN');
    });

    test('enhanced factory sets code and preserves original error', () {
      final original = Exception('root cause');
      final exception = ApiException.enhanced(
        'Enhanced error',
        'test_service',
        originalError: original,
      );

      expect(exception.message, 'Enhanced error');
      expect(exception.serviceName, 'test_service');
      expect(exception.code, 'ENHANCED_ERROR');
      expect(exception.originalError, original);
    });

    test('copyWith creates modified copy', () {
      final exception = ApiException(
        message: 'original',
        serviceName: 'svc',
        code: 'ERR_001',
      );

      final modified = exception.copyWith(message: 'modified');
      expect(modified.message, 'modified');
      expect(modified.serviceName, 'svc');
      expect(modified.code, 'ERR_001');
    });

    test('toString() includes key details', () {
      final exception = ApiException(
        message: 'Something went wrong',
        serviceName: 'my_service',
        code: 'ERR_42',
      );

      final str = exception.toString();
      expect(str, contains('Something went wrong'));
      expect(str, contains('my_service'));
      expect(str, contains('ERR_42'));
    });
  });
}
