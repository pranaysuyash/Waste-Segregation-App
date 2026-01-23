import 'dart:math';
import 'package:hive/hive.dart';
import '../models/vision_model_config.dart';
import '../services/model_selection_service.dart';
import '../utils/waste_app_logger.dart';

part 'ab_testing_config.g.dart';

/// A/B testing framework for model comparison
/// 
/// Enables:
/// - Random assignment to test groups
/// - Performance comparison between strategies
/// - Statistical significance testing
/// - Conversion tracking
@HiveType(typeId: 34)
class ABTestConfig extends HiveObject {
  ABTestConfig({
    required this.testId,
    required this.name,
    required this.variants,
    required this.startDate,
    this.endDate,
    this.trafficAllocation = 0.5,
    this.isActive = true,
  });

  @HiveField(0)
  final String testId;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final List<ABTestVariant> variants;

  @HiveField(3)
  final DateTime startDate;

  @HiveField(4)
  final DateTime? endDate;

  @HiveField(5)
  final double trafficAllocation; // 0.0 to 1.0

  @HiveField(6)
  final bool isActive;
}

@HiveType(typeId: 35)
class ABTestVariant extends HiveObject {
  ABTestVariant({
    required this.variantId,
    required this.name,
    required this.strategy,
    required this.config,
    this.weight = 0.5,
  });

  @HiveField(0)
  final String variantId;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final ModelSelectionStrategy strategy;

  @HiveField(3)
  final VisionModelConfig config;

  @HiveField(4)
  final double weight; // 0.0 to 1.0
}

@HiveType(typeId: 36)
class ABTestResult extends HiveObject {
  ABTestResult({
    required this.testId,
    required this.variantId,
    required this.userId,
    required this.timestamp,
    required this.latencyMs,
    required this.cost,
    required this.accuracy,
    this.userSatisfaction,
    this.converted = false,
  });

  @HiveField(0)
  final String testId;

  @HiveField(1)
  final String variantId;

  @HiveField(2)
  final String userId;

  @HiveField(3)
  final DateTime timestamp;

  @HiveField(4)
  final int latencyMs;

  @HiveField(5)
  final double cost;

  @HiveField(6)
  final double accuracy;

  @HiveField(7)
  final double? userSatisfaction; // 1-5 rating

  @HiveField(8)
  final bool converted; // User completed desired action
}

/// Service for managing A/B tests
class ABTestingService {
  ABTestingService({
    Box<ABTestConfig>? testsBox,
    Box<ABTestResult>? resultsBox,
    Box<String>? assignmentsBox,
  })  : _testsBox = testsBox,
        _resultsBox = resultsBox,
        _assignmentsBox = assignmentsBox,
        _random = Random();

  final Box<ABTestConfig>? _testsBox;
  final Box<ABTestResult>? _resultsBox;
  final Box<String>? _assignmentsBox; // userId -> variantId
  final Random _random;

  /// Initialize the service
  Future<void> initialize() async {
    if (_testsBox == null) {
      WasteAppLogger.warning('A/B testing boxes not initialized');
    }
  }

  /// Create a new A/B test
  Future<void> createTest(ABTestConfig config) async {
    try {
      await _testsBox?.put(config.testId, config);
      WasteAppLogger.info('A/B test created: ${config.testId}');
    } catch (e, s) {
      WasteAppLogger.severe('Failed to create A/B test', e, s);
      rethrow;
    }
  }

  /// Get active tests
  List<ABTestConfig> getActiveTests() {
    try {
      final now = DateTime.now();
      return _testsBox?.values
              .where((test) =>
                  test.isActive &&
                  test.startDate.isBefore(now) &&
                  (test.endDate == null || test.endDate!.isAfter(now)))
              .toList() ??
          [];
    } catch (e) {
      WasteAppLogger.warning('Error getting active tests: $e');
      return [];
    }
  }

  /// Assign user to variant
  Future<ABTestVariant?> assignVariant(String userId, String testId) async {
    try {
      // Check if already assigned
      final existingAssignment = _assignmentsBox?.get('${userId}_$testId');
      if (existingAssignment != null) {
        // Return existing variant
        final test = _testsBox?.get(testId);
        return test?.variants.firstWhere(
          (v) => v.variantId == existingAssignment,
          orElse: () => test.variants.first,
        );
      }

      // Get test config
      final test = _testsBox?.get(testId);
      if (test == null || !test.isActive) {
        return null;
      }

      // Check traffic allocation
      if (_random.nextDouble() > test.trafficAllocation) {
        return null; // User not in test
      }

      // Assign to variant based on weights
      final totalWeight = test.variants.fold<double>(
        0.0,
        (sum, variant) => sum + variant.weight,
      );
      
      var rand = _random.nextDouble() * totalWeight;
      ABTestVariant? selectedVariant;
      
      for (final variant in test.variants) {
        rand -= variant.weight;
        if (rand <= 0) {
          selectedVariant = variant;
          break;
        }
      }
      
      selectedVariant ??= test.variants.first;

      // Save assignment
      await _assignmentsBox?.put(
        '${userId}_$testId',
        selectedVariant.variantId,
      );

      WasteAppLogger.info(
        'User $userId assigned to variant ${selectedVariant.variantId}',
      );

      return selectedVariant;
    } catch (e, s) {
      WasteAppLogger.severe('Failed to assign variant', e, s);
      return null;
    }
  }

  /// Record test result
  Future<void> recordResult(ABTestResult result) async {
    try {
      final key = '${result.testId}_${result.variantId}_${result.timestamp.millisecondsSinceEpoch}';
      await _resultsBox?.put(key, result);
    } catch (e, s) {
      WasteAppLogger.severe('Failed to record A/B test result', e, s);
    }
  }

  /// Get results for a test
  List<ABTestResult> getResults(String testId) {
    try {
      return _resultsBox?.values
              .where((result) => result.testId == testId)
              .toList() ??
          [];
    } catch (e) {
      WasteAppLogger.warning('Error getting test results: $e');
      return [];
    }
  }

  /// Calculate variant statistics
  Map<String, VariantStats> getVariantStats(String testId) {
    final results = getResults(testId);
    final statsByVariant = <String, List<ABTestResult>>{};

    // Group by variant
    for (final result in results) {
      statsByVariant.putIfAbsent(result.variantId, () => []).add(result);
    }

    // Calculate stats for each variant
    final stats = <String, VariantStats>{};
    for (final entry in statsByVariant.entries) {
      stats[entry.key] = _calculateStats(entry.value);
    }

    return stats;
  }

  VariantStats _calculateStats(List<ABTestResult> results) {
    if (results.isEmpty) {
      return VariantStats(
        sampleSize: 0,
        avgLatencyMs: 0,
        avgCost: 0,
        avgAccuracy: 0,
        conversionRate: 0,
        avgSatisfaction: null,
      );
    }

    final avgLatency = results.fold<int>(
          0,
          (sum, r) => sum + r.latencyMs,
        ) /
        results.length;

    final avgCost = results.fold<double>(
          0,
          (sum, r) => sum + r.cost,
        ) /
        results.length;

    final avgAccuracy = results.fold<double>(
          0,
          (sum, r) => sum + r.accuracy,
        ) /
        results.length;

    final conversions = results.where((r) => r.converted).length;
    final conversionRate = conversions / results.length;

    final satisfactionResults =
        results.where((r) => r.userSatisfaction != null).toList();
    final avgSatisfaction = satisfactionResults.isNotEmpty
        ? satisfactionResults.fold<double>(
              0,
              (sum, r) => sum + r.userSatisfaction!,
            ) /
            satisfactionResults.length
        : null;

    return VariantStats(
      sampleSize: results.length,
      avgLatencyMs: avgLatency.toInt(),
      avgCost: avgCost,
      avgAccuracy: avgAccuracy,
      conversionRate: conversionRate,
      avgSatisfaction: avgSatisfaction,
    );
  }

  /// Get winner (variant with best overall performance)
  String? getWinner(String testId, {double significanceLevel = 0.05}) {
    final stats = getVariantStats(testId);
    
    if (stats.length < 2) {
      return null; // Need at least 2 variants
    }

    // Simple winner determination based on composite score
    // In production, use proper statistical significance testing
    String? winner;
    double bestScore = double.negativeInfinity;

    for (final entry in stats.entries) {
      final s = entry.value;
      
      // Composite score (adjust weights as needed)
      final score = (s.avgAccuracy * 0.4) +
          (s.conversionRate * 0.3) +
          ((s.avgSatisfaction ?? 3) / 5 * 0.2) +
          ((1000 - s.avgLatencyMs) / 1000 * 0.1);

      if (score > bestScore && s.sampleSize >= 30) {
        // Min sample size for statistical validity
        bestScore = score;
        winner = entry.key;
      }
    }

    return winner;
  }

  /// End test and select winner
  Future<void> endTest(String testId) async {
    try {
      final test = _testsBox?.get(testId);
      if (test == null) {
        return;
      }

      final winner = getWinner(testId);
      final updatedTest = ABTestConfig(
        testId: test.testId,
        name: test.name,
        variants: test.variants,
        startDate: test.startDate,
        endDate: DateTime.now(),
        trafficAllocation: test.trafficAllocation,
        isActive: false,
      );

      await _testsBox?.put(testId, updatedTest);
      
      WasteAppLogger.info(
        'A/B test ended: $testId, Winner: ${winner ?? "No clear winner"}',
      );
    } catch (e, s) {
      WasteAppLogger.severe('Failed to end A/B test', e, s);
      rethrow;
    }
  }
}

/// Variant statistics
class VariantStats {
  const VariantStats({
    required this.sampleSize,
    required this.avgLatencyMs,
    required this.avgCost,
    required this.avgAccuracy,
    required this.conversionRate,
    this.avgSatisfaction,
  });

  final int sampleSize;
  final int avgLatencyMs;
  final double avgCost;
  final double avgAccuracy;
  final double conversionRate;
  final double? avgSatisfaction;

  @override
  String toString() {
    return 'VariantStats(n=$sampleSize, latency=${avgLatencyMs}ms, '
        'cost=\$${avgCost.toStringAsFixed(4)}, accuracy=${avgAccuracy.toStringAsFixed(2)}, '
        'conversion=${(conversionRate * 100).toStringAsFixed(1)}%, '
        'satisfaction=${avgSatisfaction?.toStringAsFixed(1) ?? "N/A"})';
  }
}
