import 'package:waste_segregation_app/utils/waste_app_logger.dart';

/// Calibration entry mapping raw confidence to empirical accuracy.
class CalibrationBin {
  const CalibrationBin({
    required this.rawLow,
    required this.rawHigh,
    required this.empiricalAccuracy,
    required this.sampleCount,
  });

  final double rawLow;
  final double rawHigh;
  final double empiricalAccuracy;
  final int sampleCount;

  bool contains(double raw) => raw >= rawLow && raw < rawHigh;
}

/// Per-category routing override.
class CategoryOverride {
  const CategoryOverride({
    required this.category,
    required this.minimumLayer,
    required this.minimumConfidence,
  });

  final String category;
  final int minimumLayer;
  final double minimumConfidence;
}

/// Layer pass thresholds.
class LayerThreshold {
  const LayerThreshold({
    required this.layer,
    required this.passThreshold,
  });

  final int layer;
  final double passThreshold;
}

/// Calibrates model-reported confidence against empirical accuracy
/// and determines routing decisions (accept / escalate / override).
class ConfidenceCalibrationService {
  ConfidenceCalibrationService();

  // ── Layer thresholds (from CONFIDENCE_THRESHOLD_TUNING.md) ──────────

  static const List<LayerThreshold> layerThresholds = [
    LayerThreshold(layer: 0, passThreshold: 0.90),
    LayerThreshold(layer: 1, passThreshold: 0.75),
    LayerThreshold(layer: 2, passThreshold: 0.60),
    LayerThreshold(layer: 3, passThreshold: 0.0), // accept all
  ];

  // ── Per-category overrides (safety-critical categories) ─────────────

  static const List<CategoryOverride> categoryOverrides = [
    CategoryOverride(
        category: 'Hazardous Waste', minimumLayer: 3, minimumConfidence: 0.80),
    CategoryOverride(
        category: 'Medical Waste', minimumLayer: 3, minimumConfidence: 0.80),
    CategoryOverride(
        category: 'E-Waste', minimumLayer: 2, minimumConfidence: 0.70),
  ];

  // ── Identity calibration curve (no data yet) ────────────────────────
  // Until eval harness data is collected, calibration is a pass-through.

  List<CalibrationBin> _bins = const [];
  DateTime? _binsUpdatedAt;

  /// Update the calibration lookup table from eval harness results.
  void updateBins(List<CalibrationBin> bins) {
    _bins = List.unmodifiable(bins);
    _binsUpdatedAt = DateTime.now();
    WasteAppLogger.info('calibration_bins_updated', context: {
      'bin_count': bins.length,
      'total_samples': bins.fold<int>(0, (sum, b) => sum + b.sampleCount),
    });
  }

  /// Calibrate a raw model-reported confidence using the lookup table.
  /// Returns the raw value unchanged if no bins are loaded.
  double calibrate(double rawConfidence) {
    if (_bins.isEmpty) return rawConfidence;

    for (final bin in _bins) {
      if (bin.contains(rawConfidence)) {
        return bin.empiricalAccuracy;
      }
    }

    // Above the highest bin — return the top bin's accuracy.
    if (_bins.isNotEmpty && rawConfidence >= _bins.last.rawHigh) {
      return _bins.last.empiricalAccuracy;
    }

    return rawConfidence;
  }

  /// Determine the routing decision for a classification result.
  ///
  /// Returns a [RoutingDecision] with:
  /// - [action]: accept, escalate, or override
  /// - [targetLayer]: the layer that should handle this
  /// - [calibratedConfidence]: the calibrated confidence value
  /// - [reason]: human-readable explanation
  RoutingDecision decide({
    required double rawConfidence,
    required int currentLayer,
    required String category,
  }) {
    final calibrated = calibrate(rawConfidence);

    // Check per-category override first.
    final override = categoryOverrides.where((o) => o.category == category).firstOrNull;
    if (override != null && currentLayer < override.minimumLayer) {
      return RoutingDecision(
        action: RoutingAction.override,
        targetLayer: override.minimumLayer,
        calibratedConfidence: calibrated,
        reason:
            'Category "$category" requires Layer ${override.minimumLayer}+ (safety override)',
      );
    }

    // Check layer pass threshold.
    final threshold = layerThresholds
        .where((t) => t.layer == currentLayer)
        .firstOrNull;
    if (threshold == null) {
      // Unknown layer — accept.
      return RoutingDecision(
        action: RoutingAction.accept,
        targetLayer: currentLayer,
        calibratedConfidence: calibrated,
        reason: 'Unknown layer $currentLayer — accepted',
      );
    }

    if (calibrated >= threshold.passThreshold) {
      return RoutingDecision(
        action: RoutingAction.accept,
        targetLayer: currentLayer,
        calibratedConfidence: calibrated,
        reason:
            'Confidence ${calibrated.toStringAsFixed(2)} >= ${threshold.passThreshold} for Layer $currentLayer',
      );
    }

    final nextLayer = currentLayer + 1;
    return RoutingDecision(
      action: RoutingAction.escalate,
      targetLayer: nextLayer > 3 ? 3 : nextLayer,
      calibratedConfidence: calibrated,
      reason:
          'Confidence ${calibrated.toStringAsFixed(2)} < ${threshold.passThreshold} for Layer $currentLayer — escalate to Layer $nextLayer',
    );
  }

  /// Whether calibration data is available.
  bool get hasCalibrationData => _bins.isNotEmpty;
  DateTime? get binsUpdatedAt => _binsUpdatedAt;
}

enum RoutingAction { accept, escalate, override }

class RoutingDecision {
  const RoutingDecision({
    required this.action,
    required this.targetLayer,
    required this.calibratedConfidence,
    required this.reason,
  });

  final RoutingAction action;
  final int targetLayer;
  final double calibratedConfidence;
  final String reason;

  @override
  String toString() =>
      'RoutingDecision($action → L$targetLayer, conf=$calibratedConfidence, $reason)';
}
