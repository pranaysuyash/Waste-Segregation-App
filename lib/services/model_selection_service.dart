import 'dart:io';
import 'dart:typed_data';
import 'package:waste_segregation_app/models/waste_classification.dart';
import '../models/vision_model_config.dart';
import '../utils/waste_app_logger.dart';
import 'on_device_vision_service.dart';
import 'batching_service.dart';
import 'ai_service.dart';

/// Strategy for selecting the best model for analysis
enum ModelSelectionStrategy {
  /// Always prefer on-device (zero cost, privacy)
  onDeviceFirst,

  /// Use on-device, fallback to cloud if confidence is low
  hybrid,

  /// Use cloud models only (highest accuracy)
  cloudOnly,

  /// Batch mode for cost optimization
  batchMode,

  /// Cost optimized (smallest/cheapest models)
  costOptimized,

  /// Performance optimized (fastest models)
  performanceOptimized,

  /// Accuracy optimized (best models regardless of cost)
  accuracyOptimized,
}

/// Service for intelligent model selection and routing
///
/// This service acts as a router that:
/// 1. Selects the best model based on user preferences and requirements
/// 2. Routes analysis to appropriate service (on-device, cloud, batch)
/// 3. Implements fallback logic for robustness
/// 4. Tracks performance and costs
///
/// Benefits:
/// - Optimized cost/accuracy trade-off
/// - Flexible model selection
/// - Automatic fallback handling
/// - Performance monitoring
class ModelSelectionService {
  ModelSelectionService({
    required this.aiService,
    OnDeviceVisionService? onDeviceService,
    BatchingService? batchingService,
    this.strategy = ModelSelectionStrategy.hybrid,
    VisionModelConfig? config,
  })  : _onDeviceService = onDeviceService,
        _batchingService = batchingService,
        _config = config ?? VisionModelConfig.hybrid();

  final AiService aiService;
  final OnDeviceVisionService? _onDeviceService;
  final BatchingService? _batchingService;
  ModelSelectionStrategy strategy;
  final VisionModelConfig _config;

  // Performance tracking
  int _totalAnalyses = 0;
  int _onDeviceAnalyses = 0;
  int _cloudAnalyses = 0;
  int _batchAnalyses = 0;
  double _totalCost = 0.0;

  /// Analyze image with intelligent model selection
  Future<WasteClassification> analyzeImage(
    File imageFile, {
    String? region,
    String? instructionsLang,
    bool? forceCloud,
    bool? forceBatch,
  }) async {
    _totalAnalyses++;

    try {
      // Determine which service to use based on strategy
      final useCloud = forceCloud ?? _shouldUseCloud();
      final useBatch = forceBatch ?? _shouldUseBatch();
      var attemptedLocal = false;
      String? localFallbackReason;

      if (useBatch) {
        // Canonical batch execution is handled by AiJobService (async job flow).
        // This sync API must never return placeholder batch results.
        WasteAppLogger.warning(
          'Batch strategy requested via ModelSelectionService.analyzeImage; '
          'routing through cloud sync path. Use AiJobService for true async batch jobs.',
        );
        _batchAnalyses++;
      }

      if (!useCloud && _onDeviceService != null) {
        attemptedLocal = true;
        WasteAppLogger.info('Attempting on-device analysis');
        try {
          final result = await _onDeviceService.analyzeImage(
            imageFile,
            region: region,
          );

          // Check if confidence is acceptable
          if (_isConfidenceAcceptable(result)) {
            _onDeviceAnalyses++;
            WasteAppLogger.info(
                'On-device analysis succeeded with confidence ${result.confidence}');
            return _markLocalExperimental(result);
          } else {
            localFallbackReason =
                'low_confidence_${result.confidence?.toStringAsFixed(2) ?? 'unknown'}';
            WasteAppLogger.info(
                'On-device confidence too low (${result.confidence}), falling back to cloud');
          }
        } catch (e, s) {
          localFallbackReason = 'on_device_analysis_failed';
          WasteAppLogger.warning(
              'On-device analysis failed, falling back to cloud',
              error: e,
              stackTrace: s);
        }
      }

      // Fallback to cloud analysis
      WasteAppLogger.info('Using cloud analysis');
      _cloudAnalyses++;
      final result = await aiService.analyzeImage(
        imageFile,
        region: region,
        instructionsLang: instructionsLang,
      );

      // Track cloud costs (approximate)
      _totalCost += _estimateCost(result);

      if (attemptedLocal && localFallbackReason != null) {
        return _markLocalFailedFallbackCloud(
          result,
          fallbackReason: localFallbackReason,
        );
      }

      return _markCloudPrimary(result);
    } catch (e, s) {
      WasteAppLogger.severe('Analysis failed with all methods',
          error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Analyze web image with intelligent model selection
  Future<WasteClassification> analyzeWebImage(
    Uint8List imageBytes,
    String imageName, {
    String? region,
    String? instructionsLang,
    bool? forceCloud,
  }) async {
    _totalAnalyses++;

    try {
      final useCloud = forceCloud ?? _shouldUseCloud();
      var attemptedLocal = false;
      String? localFallbackReason;

      if (!useCloud && _onDeviceService != null) {
        attemptedLocal = true;
        WasteAppLogger.info('Attempting on-device web analysis');
        try {
          final result = await _onDeviceService.analyzeWebImage(
            imageBytes,
            region: region,
          );

          if (_isConfidenceAcceptable(result)) {
            _onDeviceAnalyses++;
            return _markLocalExperimental(result);
          }
          localFallbackReason =
              'low_confidence_${result.confidence?.toStringAsFixed(2) ?? 'unknown'}';
        } catch (e, s) {
          localFallbackReason = 'on_device_analysis_failed';
          WasteAppLogger.warning(
              'On-device web analysis failed, falling back to cloud',
              error: e,
              stackTrace: s);
        }
      }

      // Fallback to cloud analysis
      WasteAppLogger.info('Using cloud web analysis');
      _cloudAnalyses++;
      final result = await aiService.analyzeWebImage(
        imageBytes,
        imageName,
        region: region,
        instructionsLang: instructionsLang,
      );

      _totalCost += _estimateCost(result);

      if (attemptedLocal && localFallbackReason != null) {
        return _markLocalFailedFallbackCloud(
          result,
          fallbackReason: localFallbackReason,
        );
      }

      return _markCloudPrimary(result);
    } catch (e, s) {
      WasteAppLogger.severe('Web analysis failed with all methods',
          error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Determine if cloud service should be used
  bool _shouldUseCloud() {
    switch (strategy) {
      case ModelSelectionStrategy.onDeviceFirst:
        return false; // Always try on-device first
      case ModelSelectionStrategy.hybrid:
        return false; // Try on-device first, fallback to cloud
      case ModelSelectionStrategy.cloudOnly:
        return true; // Always use cloud
      case ModelSelectionStrategy.batchMode:
        return false; // Batch service will handle cloud
      case ModelSelectionStrategy.costOptimized:
        return false; // Prefer on-device for cost
      case ModelSelectionStrategy.performanceOptimized:
        return _onDeviceService == null; // Use on-device if available
      case ModelSelectionStrategy.accuracyOptimized:
        return true; // Cloud models are more accurate
    }
  }

  /// Determine if batch mode should be used
  bool _shouldUseBatch() {
    switch (strategy) {
      case ModelSelectionStrategy.batchMode:
        return true;
      case ModelSelectionStrategy.costOptimized:
        return true; // Batch is cost-effective
      default:
        return false;
    }
  }

  /// Check if confidence level is acceptable
  bool _isConfidenceAcceptable(WasteClassification result) {
    final confidence = result.confidence ?? 0.0;
    return confidence >= _config.confidenceThreshold;
  }

  WasteClassification _markCloudPrimary(WasteClassification result) {
    return result.copyWith(
      analysisSource: WasteClassification.analysisSourceCloudPrimary,
      analysisFallbackReason: null,
      modelSelectionStrategy: strategy.name,
    );
  }

  WasteClassification _markLocalExperimental(WasteClassification result) {
    return result.copyWith(
      analysisSource: WasteClassification.analysisSourceLocalExperimental,
      analysisFallbackReason: null,
      modelSelectionStrategy: strategy.name,
    );
  }

  WasteClassification _markLocalFailedFallbackCloud(
    WasteClassification result, {
    required String fallbackReason,
  }) {
    return result.copyWith(
      analysisSource: WasteClassification.analysisSourceLocalFailedFallbackCloud,
      analysisFallbackReason: fallbackReason,
      modelSelectionStrategy: strategy.name,
    );
  }

  /// Estimate cost of cloud analysis (approximate)
  double _estimateCost(WasteClassification result) {
    // Rough estimates based on model source
    if (result.modelSource?.contains('gpt-4') ?? false) {
      return 0.01; // ~$0.01 per image for GPT-4 Vision
    } else if (result.modelSource?.contains('gemini') ?? false) {
      return 0.005; // ~$0.005 per image for Gemini
    } else if (result.modelSource?.contains('batch') ?? false) {
      return 0.005; // ~50% discount for batch
    }
    return 0.0; // On-device is free
  }

  /// Get usage statistics
  Map<String, dynamic> getStatistics() {
    final onDevicePercentage = _totalAnalyses > 0
        ? (_onDeviceAnalyses / _totalAnalyses * 100).toStringAsFixed(1)
        : '0.0';
    final cloudPercentage = _totalAnalyses > 0
        ? (_cloudAnalyses / _totalAnalyses * 100).toStringAsFixed(1)
        : '0.0';
    final batchPercentage = _totalAnalyses > 0
        ? (_batchAnalyses / _totalAnalyses * 100).toStringAsFixed(1)
        : '0.0';

    return {
      'total_analyses': _totalAnalyses,
      'on_device_analyses': _onDeviceAnalyses,
      'cloud_analyses': _cloudAnalyses,
      'batch_analyses': _batchAnalyses,
      'on_device_percentage': '$onDevicePercentage%',
      'cloud_percentage': '$cloudPercentage%',
      'batch_percentage': '$batchPercentage%',
      'total_cost': '\$${_totalCost.toStringAsFixed(2)}',
      'average_cost_per_analysis': _totalAnalyses > 0
          ? '\$${(_totalCost / _totalAnalyses).toStringAsFixed(4)}'
          : '\$0.00',
      'strategy': strategy.name,
    };
  }

  /// Get recommended strategy based on usage patterns
  ModelSelectionStrategy getRecommendedStrategy() {
    if (_totalAnalyses < 10) {
      return ModelSelectionStrategy.hybrid; // Default for new users
    }

    final avgCost = _totalCost / _totalAnalyses;

    // If spending too much, recommend cost optimization
    if (avgCost > 0.01) {
      return ModelSelectionStrategy.costOptimized;
    }

    // If mostly using cloud, might want to try on-device
    if (_cloudAnalyses > _totalAnalyses * 0.8) {
      return ModelSelectionStrategy.hybrid;
    }

    return strategy; // Keep current strategy
  }

  /// Change strategy at runtime.
  void setStrategy(ModelSelectionStrategy newStrategy) {
    if (newStrategy == strategy) return;
    WasteAppLogger.info(
      'ModelSelectionStrategy changed: ${strategy.name} → ${newStrategy.name}',
    );
    strategy = newStrategy;
  }

  /// Initialize all services
  Future<void> initialize() async {
    WasteAppLogger.info('Initializing model selection service');

    // Initialize on-device service if available
    if (_onDeviceService != null) {
      try {
        await _onDeviceService.initialize();
        WasteAppLogger.info('On-device service initialized');
      } catch (e, s) {
        WasteAppLogger.warning('Failed to initialize on-device service',
            error: e, stackTrace: s);
      }
    }

    // Initialize AI service
    try {
      await aiService.initialize();
      WasteAppLogger.info('AI service initialized');
    } catch (e, s) {
      WasteAppLogger.warning('Failed to initialize AI service',
          error: e, stackTrace: s);
    }

    WasteAppLogger.info('Model selection service initialization complete');
  }

  /// Dispose all services
  void dispose() {
    _onDeviceService?.dispose();
    _batchingService?.dispose();
    aiService.dispose();
    WasteAppLogger.info('Model selection service disposed');
  }
}
