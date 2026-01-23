import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/ab_testing_config.dart';
import 'package:waste_segregation_app/models/vision_model_config.dart';
import 'package:waste_segregation_app/services/model_selection_service.dart';

void main() {
  group('ABTestConfig', () {
    test('creates config correctly', () {
      final config = ABTestConfig(
        testId: 'test1',
        name: 'Test Experiment',
        variants: [],
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 2, 1),
        trafficAllocation: 0.5,
        isActive: true,
      );

      expect(config.testId, 'test1');
      expect(config.name, 'Test Experiment');
      expect(config.trafficAllocation, 0.5);
      expect(config.isActive, true);
    });

    test('defaults isActive to true', () {
      final config = ABTestConfig(
        testId: 'test1',
        name: 'Test',
        variants: [],
        startDate: DateTime.now(),
      );

      expect(config.isActive, true);
    });

    test('defaults trafficAllocation to 0.5', () {
      final config = ABTestConfig(
        testId: 'test1',
        name: 'Test',
        variants: [],
        startDate: DateTime.now(),
      );

      expect(config.trafficAllocation, 0.5);
    });
  });

  group('ABTestVariant', () {
    test('creates variant correctly', () {
      final variant = ABTestVariant(
        variantId: 'variant1',
        name: 'Hybrid Strategy',
        strategy: ModelSelectionStrategy.hybrid,
        config: VisionModelConfig.hybrid(),
        weight: 0.5,
      );

      expect(variant.variantId, 'variant1');
      expect(variant.name, 'Hybrid Strategy');
      expect(variant.strategy, ModelSelectionStrategy.hybrid);
      expect(variant.weight, 0.5);
    });

    test('defaults weight to 0.5', () {
      final variant = ABTestVariant(
        variantId: 'variant1',
        name: 'Test',
        strategy: ModelSelectionStrategy.hybrid,
        config: VisionModelConfig.hybrid(),
      );

      expect(variant.weight, 0.5);
    });
  });

  group('ABTestResult', () {
    test('creates result correctly', () {
      final result = ABTestResult(
        testId: 'test1',
        variantId: 'variant1',
        userId: 'user123',
        timestamp: DateTime(2026, 1, 1),
        latencyMs: 120,
        cost: 0.005,
        accuracy: 0.85,
        userSatisfaction: 4.5,
        converted: true,
      );

      expect(result.testId, 'test1');
      expect(result.variantId, 'variant1');
      expect(result.userId, 'user123');
      expect(result.latencyMs, 120);
      expect(result.cost, 0.005);
      expect(result.accuracy, 0.85);
      expect(result.userSatisfaction, 4.5);
      expect(result.converted, true);
    });

    test('defaults converted to false', () {
      final result = ABTestResult(
        testId: 'test1',
        variantId: 'variant1',
        userId: 'user123',
        timestamp: DateTime.now(),
        latencyMs: 100,
        cost: 0.0,
        accuracy: 0.8,
      );

      expect(result.converted, false);
    });

    test('allows null userSatisfaction', () {
      final result = ABTestResult(
        testId: 'test1',
        variantId: 'variant1',
        userId: 'user123',
        timestamp: DateTime.now(),
        latencyMs: 100,
        cost: 0.0,
        accuracy: 0.8,
      );

      expect(result.userSatisfaction, null);
    });
  });

  group('VariantStats', () {
    test('creates stats correctly', () {
      const stats = VariantStats(
        sampleSize: 100,
        avgLatencyMs: 120,
        avgCost: 0.005,
        avgAccuracy: 0.85,
        conversionRate: 0.6,
        avgSatisfaction: 4.2,
      );

      expect(stats.sampleSize, 100);
      expect(stats.avgLatencyMs, 120);
      expect(stats.avgCost, 0.005);
      expect(stats.avgAccuracy, 0.85);
      expect(stats.conversionRate, 0.6);
      expect(stats.avgSatisfaction, 4.2);
    });

    test('toString includes all metrics', () {
      const stats = VariantStats(
        sampleSize: 50,
        avgLatencyMs: 100,
        avgCost: 0.003,
        avgAccuracy: 0.9,
        conversionRate: 0.7,
        avgSatisfaction: 4.5,
      );

      final str = stats.toString();
      
      expect(str, contains('n=50'));
      expect(str, contains('latency=100ms'));
      expect(str, contains('cost=\$0.0030'));
      expect(str, contains('accuracy=0.90'));
      expect(str, contains('conversion=70.0%'));
      expect(str, contains('satisfaction=4.5'));
    });

    test('toString handles null satisfaction', () {
      const stats = VariantStats(
        sampleSize: 50,
        avgLatencyMs: 100,
        avgCost: 0.003,
        avgAccuracy: 0.9,
        conversionRate: 0.7,
      );

      final str = stats.toString();
      expect(str, contains('satisfaction=N/A'));
    });
  });

  group('ABTestingService', () {
    late ABTestingService service;

    setUp(() {
      service = ABTestingService();
    });

    test('initializes without error', () async {
      await service.initialize();
      // Should complete without throwing
    });

    test('getActiveTests returns empty list initially', () {
      final tests = service.getActiveTests();
      expect(tests, isEmpty);
    });

    test('getResults returns empty list for non-existent test', () {
      final results = service.getResults('non-existent');
      expect(results, isEmpty);
    });

    test('getVariantStats returns empty map for non-existent test', () {
      final stats = service.getVariantStats('non-existent');
      expect(stats, isEmpty);
    });

    test('getWinner returns null for non-existent test', () {
      final winner = service.getWinner('non-existent');
      expect(winner, null);
    });

    test('getWinner returns null for test with < 2 variants', () {
      final winner = service.getWinner('test-with-one-variant');
      expect(winner, null);
    });
  });
}
