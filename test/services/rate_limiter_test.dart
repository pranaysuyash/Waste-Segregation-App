import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/services/rate_limiter.dart';

void main() {
  group('RateLimiter', () {
    late RateLimiter limiter;

    setUp(() {
      limiter = RateLimiter(
        maxRequests: 5,
        windowDuration: const Duration(seconds: 10),
        enableLogging: false,
      );
    });

    tearDown(() {
      limiter.dispose();
    });

    test('acquire() resolves immediately when under limit', () async {
      // Should complete within a short time (no queuing)
      await expectLater(
        limiter.acquire(),
        completes,
      );
    });

    test('acquire() allows up to maxRequests promptly', () async {
      final stopwatch = Stopwatch()..start();
      for (var i = 0; i < 5; i++) {
        await limiter.acquire();
      }
      stopwatch.stop();
      // All 5 should have completed nearly instantly (< 200ms)
      expect(stopwatch.elapsedMilliseconds, lessThan(200));
    });

    test('getStatistics() returns correct structure', () async {
      await limiter.acquire();
      final stats = limiter.getStatistics();

      expect(stats['max_requests'], 5);
      expect(stats['window_duration_ms'], 10000);
      expect(stats['current_requests'], 1);
      expect(stats['available_requests'], 4);
      expect(stats['pending_requests'], 0);
      expect(stats['utilization_percent'], 20);
    });

    test('getStatistics() after multiple requests reflects correct counts',
        () async {
      for (var i = 0; i < 3; i++) {
        await limiter.acquire();
      }
      final stats = limiter.getStatistics();
      expect(stats['current_requests'], 3);
      expect(stats['available_requests'], 2);
      expect(stats['utilization_percent'], 60);
    });

    test('getTimeUntilNextRequest() returns zero when available', () async {
      final time = limiter.getTimeUntilNextRequest();
      expect(time, Duration.zero);
    });

    test('reset() clears all request records', () async {
      for (var i = 0; i < 3; i++) {
        await limiter.acquire();
      }
      limiter.reset();

      final stats = limiter.getStatistics();
      expect(stats['current_requests'], 0);
      expect(stats['pending_requests'], 0);
    });

    test('reset() completes pending queued requests', () async {
      // Fill up the rate limiter
      for (var i = 0; i < 5; i++) {
        await limiter.acquire();
      }

      // Queue a pending request
      final pendingFuture = limiter.acquire();

      // Reset should complete the pending request
      limiter.reset();

      await expectLater(pendingFuture, completes);
    });

    test('dispose() completes pending requests with error', () async {
      // Fill up the rate limiter
      for (var i = 0; i < 5; i++) {
        await limiter.acquire();
      }

      // Queue a pending request
      final pendingFuture = limiter.acquire();

      // Dispose should error the pending request
      limiter.dispose();

      await expectLater(pendingFuture, throwsA(isA<StateError>()));
    });

    test('dispose() clears request records', () async {
      await limiter.acquire();
      limiter.dispose();

      final stats = limiter.getStatistics();
      expect(stats['current_requests'], 0);
      expect(stats['pending_requests'], 0);
    });

    test('multiple acquire/release cycles work correctly', () async {
      for (var cycle = 0; cycle < 3; cycle++) {
        await limiter.acquire();
        final stats = limiter.getStatistics();
        expect(stats['current_requests'], cycle + 1);
      }
    });

    test('burst limit is respected', () async {
      final burstLimiter = RateLimiter(
        maxRequests: 20,
        windowDuration: const Duration(seconds: 60),
        burstLimit: 2,
        enableLogging: false,
      );

      // First two requests should succeed immediately
      await burstLimiter.acquire();
      await burstLimiter.acquire();

      // Statistics should reflect the burst constraint
      final stats = burstLimiter.getStatistics();
      expect(stats['current_requests'], 2);

      burstLimiter.dispose();
    });

    test('empty limiter returns zero statistics', () async {
      final stats = limiter.getStatistics();
      expect(stats['current_requests'], 0);
      expect(stats['available_requests'], 5);
      expect(stats['pending_requests'], 0);
      expect(stats['utilization_percent'], 0);
      expect(stats['oldest_request'], isNull);
      expect(stats['newest_request'], isNull);
    });
  });

  group('CostAwareRateLimiter', () {
    late CostAwareRateLimiter costLimiter;

    setUp(() {
      costLimiter = CostAwareRateLimiter(
        maxRequests: 10,
        windowDuration: const Duration(seconds: 60),
        costPerRequest: 0.01,
        maxCostPerWindow: 0.10,
        enableLogging: false,
      );
    });

    tearDown(() {
      costLimiter.dispose();
    });

    test('starts with zero cost', () {
      expect(costLimiter.currentCost, 0.0);
      expect(costLimiter.availableCost, 0.10);
    });

    test('currentCost increases with requests', () async {
      await costLimiter.acquire();
      expect(costLimiter.currentCost, 0.01);
      expect(costLimiter.availableCost, closeTo(0.09, 0.001));
    });

    test('costMultiplier affects cost calculation', () {
      expect(costLimiter.currentCost, 0.0);

      costLimiter.updateCostMultiplier(2.0);
      expect(costLimiter.costMultiplier, 2.0);
    });

    test('updateCostMultiplier updates future request costs', () async {
      costLimiter.updateCostMultiplier(2.0);
      await costLimiter.acquire();
      // costPerRequest (0.01) * multiplier (2.0) = 0.02 per request
      expect(costLimiter.currentCost, 0.02);
    });

    test('getStatistics() includes cost data', () async {
      await costLimiter.acquire();
      final stats = costLimiter.getStatistics();

      expect(stats['cost_per_request'], 0.01);
      expect(stats['cost_multiplier'], 1.0);
      expect(stats['current_cost'], 0.01);
      expect(stats['max_cost_per_window'], 0.10);
      expect(stats['available_cost'], closeTo(0.09, 0.001));
    });

    test('blocks requests when cost limit is reached', () async {
      // Each request costs 0.01, max is 0.10, so 10 requests should fill it
      for (var i = 0; i < 10; i++) {
        await costLimiter.acquire();
      }

      // At this point currentCost should be 0.10 (max)
      expect(costLimiter.currentCost, closeTo(0.10, 0.001));
      expect(costLimiter.availableCost, closeTo(0.0, 0.001));

      // Next request should be queued (over cost limit)
      final overLimitFuture = costLimiter.acquire();
      final stats = costLimiter.getStatistics();
      expect(stats['pending_requests'], greaterThanOrEqualTo(1));

      // Clean up
      costLimiter.reset();
      await overLimitFuture; // Complete the future after reset
    });

    test('reset() clears cost state', () async {
      await costLimiter.acquire();
      expect(costLimiter.currentCost, 0.01);

      costLimiter.reset();
      expect(costLimiter.currentCost, 0.0);
    });

    test('costAware statistics show utilization', () async {
      for (var i = 0; i < 5; i++) {
        await costLimiter.acquire();
      }

      final stats = costLimiter.getStatistics();
      // 5 requests * 0.01 = 0.05 cost / 0.10 max = 50%
      expect(stats['cost_utilization_percent'], 50);
    });
  });
}
