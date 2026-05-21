import 'dart:typed_data';

/// Exception thrown by a [LocalClassifier] implementation.
class LocalClassifierException implements Exception {
  LocalClassifierException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'LocalClassifierException: $message';
}

/// Threshold policy that governs when a [LocalClassificationResult]
/// is accepted locally vs escalated to cloud inference.
///
/// These are starting hypotheses — calibrate against the eval harness
/// golden set once real inference is wired.
class LocalClassifierThresholds {
  const LocalClassifierThresholds({
    this.passThreshold = 0.75,
    this.escalateThreshold = 0.50,
    this.safetyOverrideThreshold = 0.90,
  });

  /// Minimum confidence to accept a local result for non-safety items.
  final double passThreshold;

  /// Below this threshold, the result is escalated regardless of category.
  final double escalateThreshold;

  /// Safety-sensitive items must exceed this confidence to avoid escalation.
  final double safetyOverrideThreshold;

  static const double defaultPassThreshold = 0.75;
  static const double defaultEscalateThreshold = 0.50;
  static const double defaultSafetyOverrideThreshold = 0.90;
}

/// Lightweight result from a [LocalClassifier] inference run.
///
/// This is distinct from [WasteClassification] — it carries only the data
/// the local model can produce. The router enriches it into a full
/// [WasteClassification] after the layer decision.
class LocalClassificationResult {
  LocalClassificationResult({
    required this.category,
    this.subcategory,
    required this.confidence,
    this.shouldEscalateToCloud = false,
    required this.modelVersion,
    this.processingTimeMs = 0,
    this.failureReason,
  });

  /// Broad waste category (e.g. 'Wet Waste', 'Dry Waste', 'Hazardous Waste').
  final String category;

  /// Optional subcategory (e.g. 'PET Plastic', 'Food Scraps').
  final String? subcategory;

  /// Model confidence in [0.0, 1.0]. Not calibrated — treat as ordinal.
  final double confidence;

  /// True when the model's internal heuristics flagged uncertainty.
  /// The router MUST escalate when this is set, regardless of confidence.
  final bool shouldEscalateToCloud;

  /// Model version string (e.g. 'mobilenet_v3_waste_v1.0.0').
  final String modelVersion;

  /// Inference wall-clock time in milliseconds.
  final int processingTimeMs;

  /// Non-null when the model produced an error instead of a result.
  final String? failureReason;

  /// Safety-sensitive categories that escalate unless confidence is very high.
  static const Set<String> _safetyCategories = {
    'Hazardous Waste',
    'Medical Waste',
    'Medical',
    'E-Waste',
    'Electronic Waste',
    'Chemical Waste',
    'Chemical',
    'Sharps',
    'Pharmaceutical Waste',
    'Pharmaceutical',
  };

  /// Categories that always escalate regardless of confidence.
  static const Set<String> _alwaysEscalateCategories = {
    'Unknown',
    'Requires Manual Review',
  };

  /// True when [category] is in the safety-sensitive set.
  bool get isSafetySensitive => _safetyCategories.contains(category);

  /// True when the router MUST escalate this result to cloud inference.
  ///
  /// The router should call this — not re-implement the logic.
  bool get requiresEscalation {
    if (failureReason != null) return true;
    if (shouldEscalateToCloud) return true;
    if (_alwaysEscalateCategories.contains(category)) return true;
    if (isSafetySensitive) {
      return confidence < LocalClassifierThresholds.defaultSafetyOverrideThreshold;
    }
    return confidence < LocalClassifierThresholds.defaultPassThreshold;
  }
}

/// Performs on-device first-pass waste classification.
///
/// Implementations wrap a concrete inference engine:
///   - TFLite (tflite_flutter)
///   - CoreML (via platform channel)
///   - ONNX Runtime (onnxruntime)
///   - VLM via llama.cpp FFI (SmolVLM, MobileVLM)
///
/// The [classify] method returns a [LocalClassificationResult] that
/// explicitly encodes whether the result should be escalated to cloud.
///
/// This is intentionally separate from [ClassificationProvider] because
/// local inference has different lifecycle, error, and cost semantics
/// than cloud HTTP providers.
abstract class LocalClassifier {
  /// Human-readable model identifier (e.g. 'mobilenet_v3_waste').
  String get modelId;

  /// Semantic version of the loaded model (e.g. '1.0.0').
  String get modelVersion;

  /// True when the model is loaded and ready for inference.
  bool get isModelLoaded;

  /// Load the model from its configured source (bundled asset or download).
  Future<void> loadModel();

  /// Unload the model and free device memory.
  Future<void> unloadModel();

  /// Run inference on [imageBytes] and return a [LocalClassificationResult].
  ///
  /// Throws [LocalClassifierException] on model-level failures.
  Future<LocalClassificationResult> classify({
    required Uint8List imageBytes,
    required String region,
  });
}

/// Fake implementation of [LocalClassifier] for unit and widget tests.
///
/// All methods are synchronous or trivially async — no real inference
/// or platform channels are involved.
class FakeLocalClassifier implements LocalClassifier {
  FakeLocalClassifier({
    this.modelId = 'fake-local-classifier',
    this.modelVersion = '1.0.0-test',
    this.isModelLoaded = true,
    this.stubbedResult,
    this.stubbedShouldEscalate = false,
    this.shouldThrowOnClassify = false,
    this.shouldThrowOnLoad = false,
  });

  @override
  final String modelId;

  @override
  final String modelVersion;

  @override
  bool isModelLoaded;

  /// When set, [classify] returns this result instead of the default.
  LocalClassificationResult? stubbedResult;

  /// When true, [classify] sets [LocalClassificationResult.shouldEscalateToCloud].
  bool stubbedShouldEscalate;

  /// When true, [classify] throws [LocalClassifierException].
  bool shouldThrowOnClassify;

  /// When true, [loadModel] throws [LocalClassifierException].
  bool shouldThrowOnLoad;

  @override
  Future<void> loadModel() async {
    if (shouldThrowOnLoad) {
      throw LocalClassifierException('Simulated load failure');
    }
    isModelLoaded = true;
  }

  @override
  Future<void> unloadModel() async {
    isModelLoaded = false;
  }

  @override
  Future<LocalClassificationResult> classify({
    required Uint8List imageBytes,
    required String region,
  }) async {
    if (!isModelLoaded) {
      throw LocalClassifierException('Model not loaded');
    }
    if (shouldThrowOnClassify) {
      throw LocalClassifierException('Simulated inference failure');
    }
    return stubbedResult ??
        LocalClassificationResult(
          category: 'Dry Waste',
          subcategory: 'Plastic Bottle',
          confidence: 0.92,
          shouldEscalateToCloud: stubbedShouldEscalate,
          modelVersion: modelVersion,
          processingTimeMs: 42,
        );
  }
}
