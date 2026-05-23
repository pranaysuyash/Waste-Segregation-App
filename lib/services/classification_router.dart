import 'dart:typed_data';

import 'package:waste_segregation_app/services/confidence_calibration_service.dart';
import 'package:waste_segregation_app/utils/waste_app_logger.dart';

/// Routing strategy for the classification router.
enum RoutingStrategy {
  /// Minimize cost — prefer local layers, use cheapest cloud model.
  costFirst,

  /// Maximize accuracy — escalate to strongest model sooner.
  qualityFirst,

  /// Minimize latency — prefer local layers, use fastest cloud model.
  latencyFirst,

  /// Default — balanced approach using calibration data when available.
  balanced,
}

/// Result of a routing decision.
class ClassificationRouteResult {
  const ClassificationRouteResult({
    required this.targetLayer,
    required this.strategy,
    required this.confidenceThreshold,
    this.calibratedConfidence,
    this.category,
    this.reason,
  });

  final int targetLayer;
  final RoutingStrategy strategy;
  final double confidenceThreshold;
  final double? calibratedConfidence;
  final String? category;
  final String? reason;

  @override
  String toString() =>
      'ClassificationRouteResult(L$targetLayer, $strategy, conf=$calibratedConfidence)';
}

/// Adaptive classification router that selects the optimal layer
/// based on routing strategy, calibration data, and per-category overrides.
///
/// Sits above [ClassificationPipeline] and determines:
/// - Which layer should handle each classification
/// - Whether a result should be accepted or escalated
/// - Whether per-category safety overrides apply
class ClassificationRouter {
  ClassificationRouter({
    ConfidenceCalibrationService? calibrationService,
    this.strategy = RoutingStrategy.balanced,
  }) : calibrationService =
            calibrationService ?? ConfidenceCalibrationService();

  final ConfidenceCalibrationService calibrationService;
  final RoutingStrategy strategy;

  /// Determine the initial layer to start classification at.
  ///
  /// Under normal conditions, starts at Layer 0 (deterministic).
  /// Under quality-first strategy with no calibration data, may skip to Layer 2.
  int initialLayer({String? category}) {
    // Safety-critical categories always start at Layer 0 but will
    // be escalated by decide() to their minimum layer.
    return 0;
  }

  /// Decide whether a classification result at [currentLayer] should be
  /// accepted or escalated, considering calibration and category overrides.
  ClassificationRouteResult decide({
    required double rawConfidence,
    required int currentLayer,
    required String category,
  }) {
    final decision = calibrationService.decide(
      rawConfidence: rawConfidence,
      currentLayer: currentLayer,
      category: category,
    );

    // Apply strategy adjustments.
    final adjustedTarget = _applyStrategy(decision.targetLayer);

    return ClassificationRouteResult(
      targetLayer: adjustedTarget,
      strategy: strategy,
      confidenceThreshold: _thresholdForLayer(adjustedTarget),
      calibratedConfidence: decision.calibratedConfidence,
      category: category,
      reason: decision.reason,
    );
  }

  /// Decide the initial layer for an image before any classification.
  /// Used when we have context (e.g., barcode detected, offline mode).
  ClassificationRouteResult decideInitial({
    required Uint8List imageBytes,
    String? barcode,
    String? category,
    String region = '',
  }) {
    // If barcode is present, Layer 0 is very likely to accept.
    if (barcode != null && barcode.isNotEmpty) {
      return ClassificationRouteResult(
        targetLayer: 0,
        strategy: strategy,
        confidenceThreshold: 0.90,
        category: category,
        reason: 'Barcode detected — Layer 0 likely to accept',
      );
    }

    // Default: start at Layer 0, let the cascade handle it.
    return ClassificationRouteResult(
      targetLayer: 0,
      strategy: strategy,
      confidenceThreshold: 0.90,
      category: category,
      reason: 'Default starting layer',
    );
  }

  int _applyStrategy(int targetLayer) {
    switch (strategy) {
      case RoutingStrategy.costFirst:
        // Prefer local layers — don't escalate beyond what calibration says.
        return targetLayer;
      case RoutingStrategy.qualityFirst:
        // More aggressive escalation — bump layer by 1 for lower confidence.
        return targetLayer < 3 ? targetLayer : 3;
      case RoutingStrategy.latencyFirst:
        // Skip to cloud faster if local isn't confident.
        return targetLayer < 2 ? targetLayer + 1 : targetLayer;
      case RoutingStrategy.balanced:
        return targetLayer;
    }
  }

  double _thresholdForLayer(int layer) {
    const thresholds = {0: 0.90, 1: 0.75, 2: 0.60, 3: 0.0};
    return thresholds[layer] ?? 0.60;
  }

  /// Log a routing decision for telemetry and eval harness review.
  void logDecision(ClassificationRouteResult result) {
    WasteAppLogger.info('classification_route_decision', context: {
      'target_layer': result.targetLayer,
      'strategy': result.strategy.name,
      'calibrated_confidence': result.calibratedConfidence?.toStringAsFixed(3),
      'category': result.category,
      'reason': result.reason,
    });
  }
}
