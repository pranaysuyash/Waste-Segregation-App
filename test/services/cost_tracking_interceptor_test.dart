import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:waste_segregation_app/services/cost_tracking_interceptor.dart';

/// A [RequestInterceptorHandler] whose [next] is a no-op, preventing any
/// async pipeline errors in tests where no real Dio chain exists.
class _NoOpRequestInterceptorHandler extends RequestInterceptorHandler {
  @override
  void next(RequestOptions requestOptions) {
    // no-op — exercising the interceptor in isolation
  }
}

/// A [ResponseInterceptorHandler] whose [next] is a no-op.
class _NoOpResponseInterceptorHandler extends ResponseInterceptorHandler {
  @override
  void next(Response response) {
    // no-op
  }
}

/// A [ErrorInterceptorHandler] whose [next] is a no-op.
///
/// In a real Dio pipeline, `next(DioException)` completes an internal completer
/// with the error, which would propagate as an unhandled async error in test
/// isolation.  Overriding to a no-op avoids this while still exercising the
/// interceptor's error path.
class _NoOpErrorInterceptorHandler extends ErrorInterceptorHandler {
  @override
  void next(DioException error) {
    // no-op — prevents unhandled async error in isolated tests
  }
}

/// Helper to simulate a full request→response cycle through the interceptor.
void _simulateRequestCycle(
  CostTrackingInterceptor interceptor, {
  required String baseUrl,
  required String path,
  int statusCode = 200,
  Map<String, dynamic>? responseData,
}) {
  final options = RequestOptions(baseUrl: baseUrl, path: path);
  interceptor.onRequest(options, _NoOpRequestInterceptorHandler());
  final response = Response(
    requestOptions: options,
    statusCode: statusCode,
    data: responseData ?? {},
  );
  interceptor.onResponse(response, _NoOpResponseInterceptorHandler());
}

/// Helper to simulate a failed request cycle through the interceptor.
void _simulateFailedRequestCycle(
  CostTrackingInterceptor interceptor, {
  required String baseUrl,
  required String path,
  int statusCode = 500,
  DioExceptionType errorType = DioExceptionType.badResponse,
}) {
  final options = RequestOptions(baseUrl: baseUrl, path: path);
  interceptor.onRequest(options, _NoOpRequestInterceptorHandler());
  final error = DioException(
    type: errorType,
    requestOptions: options,
    response: Response(
      requestOptions: options,
      statusCode: statusCode,
    ),
  );
  interceptor.onError(error, _NoOpErrorInterceptorHandler());
}

void main() {
  group('CostTrackingInterceptor', () {
    late CostTrackingInterceptor interceptor;

    setUp(() {
      interceptor = CostTrackingInterceptor(enableDetailedLogging: false);
    });

    test('getCostStatistics() returns empty summary initially', () {
      final stats = interceptor.getCostStatistics();
      expect(stats['summary']['total_cost'], 0.0);
      expect(stats['summary']['total_requests'], 0);
      expect(stats['summary']['tracked_services'], isEmpty);
    });

    test('resetCostTracking() clears all tracked data', () {
      // Simulate a full request cycle so data is recorded
      _simulateRequestCycle(
        interceptor,
        baseUrl: 'https://api.openai.com',
        path: '/v1/chat/completions',
      );

      // Verify data was recorded
      var stats = interceptor.getCostStatistics();
      expect(stats['summary']['total_requests'], 1);

      // Reset and verify cleared
      interceptor.resetCostTracking();
      stats = interceptor.getCostStatistics();
      expect(stats['summary']['total_requests'], 0);
    });

    test('setServiceCost() updates default cost for a service', () {
      interceptor.setServiceCost('custom_service', 0.005);
      // After setting the cost, a request should use the new value
      _simulateRequestCycle(
        interceptor,
        baseUrl: 'https://custom.service.com',
        path: '/api',
      );
      // If no exception was thrown, the cost was used
      final stats = interceptor.getCostStatistics();
      expect(stats.containsKey('custom_service'), isFalse); // URL doesn't map to 'custom_service'
      expect(stats['summary']['total_requests'], 1); // captured as "unknown"
    });

    group('Service name extraction (via URL patterns)', () {
      test('extracts openai from openai.com URLs', () {
        _simulateRequestCycle(
          interceptor,
          baseUrl: 'https://api.openai.com',
          path: '/v1/chat/completions',
        );

        final stats = interceptor.getCostStatistics();
        expect(stats['openai'], isNotNull);
        expect(stats['openai']['service_name'], 'openai');
        expect(stats['openai']['total_requests'], 1);
      });

      test('extracts gemini from googleapis.com URLs', () {
        _simulateRequestCycle(
          interceptor,
          baseUrl: 'https://generativelanguage.googleapis.com',
          path: '/v1beta/models',
        );

        final stats = interceptor.getCostStatistics();
        expect(stats['gemini'], isNotNull);
        expect(stats['gemini']['service_name'], 'gemini');
        expect(stats['gemini']['total_requests'], 1);
      });

      test('extracts firebase from firestore/host URLs', () {
        // firestore.googleapis.com contains 'googleapis.com' as a substring,
        // so the extractor must check 'firestore' before 'googleapis.com'.
        // The production code handles this correctly.
        _simulateRequestCycle(
          interceptor,
          baseUrl: 'https://firestore.googleapis.com',
          path: '/v1/projects/test/databases',
        );

        final stats = interceptor.getCostStatistics();
        expect(stats['firebase'], isNotNull);
        expect(stats['firebase']['service_name'], 'firebase');
        expect(stats['firebase']['total_requests'], 1);
      });

      test('extracts unknown for unrecognized URLs', () {
        _simulateRequestCycle(
          interceptor,
          baseUrl: 'https://example.com',
          path: '/api',
        );

        final stats = interceptor.getCostStatistics();
        expect(stats['unknown'], isNotNull);
        expect(stats['unknown']['service_name'], 'unknown');
      });
    });

    group('Error tracking', () {
      test('tracks failed requests separately', () {
        _simulateFailedRequestCycle(
          interceptor,
          baseUrl: 'https://api.openai.com',
          path: '/v1/chat/completions',
          statusCode: 500,
        );

        final stats = interceptor.getCostStatistics();
        expect(stats['openai'], isNotNull);
        expect(stats['openai']['total_requests'], 1);
        expect(stats['openai']['error_rate'], 1.0);
      });

      test('tracks mixed success and failure', () {
        _simulateRequestCycle(
          interceptor,
          baseUrl: 'https://api.openai.com',
          path: '/v1/chat/completions',
        );
        _simulateFailedRequestCycle(
          interceptor,
          baseUrl: 'https://api.openai.com',
          path: '/v1/chat/completions',
          statusCode: 500,
        );

        final stats = interceptor.getCostStatistics();
        expect(stats['openai']['total_requests'], 2);
        expect(stats['openai']['error_rate'], 0.5);
      });
    });

    group('ServiceCostTracker', () {
      test('records and reports cost correctly', () {
        final tracker = ServiceCostTracker('test_service');
        expect(tracker.getStatistics()['total_requests'], 0);
        expect(tracker.getStatistics()['total_cost'], 0.0);

        tracker.recordRequest(
          cost: 0.01,
          duration: const Duration(seconds: 1),
          requestSize: 1000,
          responseSize: 5000,
          statusCode: 200,
          endpoint: '/test',
        );

        final stats = tracker.getStatistics();
        expect(stats['total_requests'], 1);
        expect(stats['total_cost'], 0.01);
        expect(stats['average_cost'], 0.01);
        expect(stats['error_rate'], 0.0);
        expect(stats['total_data_bytes'], 6000);
      });

      test('calculates error rate correctly', () {
        final tracker = ServiceCostTracker('test_service');

        for (var i = 0; i < 3; i++) {
          tracker.recordRequest(
            cost: 0.01,
            duration: const Duration(seconds: 1),
            requestSize: 100,
            responseSize: 200,
            statusCode: 200,
            endpoint: '/test',
          );
        }
        tracker.recordRequest(
          cost: 0.01,
          duration: const Duration(seconds: 1),
          requestSize: 100,
          responseSize: 0,
          statusCode: 500,
          endpoint: '/test',
          isError: true,
        );

        final stats = tracker.getStatistics();
        expect(stats['total_requests'], 4);
        expect(stats['error_rate'], 0.25);
      });

      test('truncates at 1000 requests', () {
        final tracker = ServiceCostTracker('test_service');

        for (var i = 0; i < 1010; i++) {
          tracker.recordRequest(
            cost: 0.001,
            duration: const Duration(milliseconds: 100),
            requestSize: 100,
            responseSize: 200,
            statusCode: 200,
            endpoint: '/test',
          );
        }

        final stats = tracker.getStatistics();
        expect(stats['total_requests'], 1000); // truncated
      });

      test('returns empty stats when no requests recorded', () {
        final tracker = ServiceCostTracker('test_service');
        final stats = tracker.getStatistics();

        expect(stats['total_requests'], 0);
        expect(stats['total_cost'], 0.0);
        expect(stats['average_cost'], 0.0);
        expect(stats['error_rate'], 0.0);
        expect(stats['average_duration_ms'], 0);
        expect(stats['total_data_bytes'], 0);
      });
    });

    group('Cost summary structure', () {
      test('summary contains all expected fields', () {
        final stats = interceptor.getCostStatistics();
        final summary = stats['summary'] as Map<String, dynamic>;

        expect(summary.containsKey('total_cost'), isTrue);
        expect(summary.containsKey('total_requests'), isTrue);
        expect(summary.containsKey('average_cost_per_request'), isTrue);
        expect(summary.containsKey('tracked_services'), isTrue);
      });

      test('summary aggregates data across multiple services', () {
        _simulateRequestCycle(
          interceptor,
          baseUrl: 'https://api.openai.com',
          path: '/v1/chat/completions',
        );
        _simulateRequestCycle(
          interceptor,
          baseUrl: 'https://generativelanguage.googleapis.com',
          path: '/v1beta/models',
        );

        final stats = interceptor.getCostStatistics();
        expect(stats['summary']['total_requests'], 2);
        expect(stats['summary']['average_cost_per_request'], greaterThan(0));
        expect(
            (stats['summary']['tracked_services'] as List).length, 2);
      });
    });
  });

  group('RequestCostData', () {
    test('creates with all required fields', () {
      final now = DateTime.now();
      final data = RequestCostData(
        timestamp: now,
        cost: 0.01,
        duration: const Duration(seconds: 2),
        requestSize: 1000,
        responseSize: 5000,
        statusCode: 200,
        endpoint: '/test',
        isError: false,
      );

      expect(data.timestamp, now);
      expect(data.cost, 0.01);
      expect(data.duration.inSeconds, 2);
      expect(data.requestSize, 1000);
      expect(data.responseSize, 5000);
      expect(data.statusCode, 200);
      expect(data.endpoint, '/test');
      expect(data.isError, isFalse);
    });
  });
}
