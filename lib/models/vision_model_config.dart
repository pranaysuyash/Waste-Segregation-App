import 'package:hive/hive.dart';

part 'vision_model_config.g.dart';

/// Enum for different vision model types available in the app
@HiveType(typeId: 30)
enum VisionModelType {
  /// On-device models (zero cost)
  @HiveField(0)
  smolVLM,
  
  @HiveField(1)
  mobileNetV3,
  
  @HiveField(2)
  efficientNet,
  
  @HiveField(3)
  yoloV8,
  
  @HiveField(4)
  yoloV11,
  
  /// Cloud-based models
  @HiveField(5)
  openAI,
  
  @HiveField(6)
  gemini,
  
  /// Custom trained models
  @HiveField(7)
  roboflowCustom,
  
  @HiveField(8)
  tfliteCustom,
}

/// Enum for model analysis mode
@HiveType(typeId: 31)
enum AnalysisMode {
  @HiveField(0)
  instant, // Individual analysis (higher cost)
  
  @HiveField(1)
  batch, // Batched analysis (lower cost, slight delay)
  
  @HiveField(2)
  onDevice, // On-device only (zero cost)
  
  @HiveField(3)
  hybrid, // On-device first, cloud fallback
}

/// Configuration for vision model usage
@HiveType(typeId: 32)
class VisionModelConfig extends HiveObject {
  VisionModelConfig({
    required this.modelType,
    required this.analysisMode,
    this.confidenceThreshold = 0.7,
    this.maxImageSize = 1024,
    this.enableObjectDetection = false,
    this.enableSegmentation = false,
    this.batchSize = 5,
    this.batchTimeoutSeconds = 30,
    this.modelVersion,
    this.customModelPath,
    this.roboflowApiKey,
    this.roboflowWorkspace,
    this.roboflowProject,
    this.preferOnDevice = true,
  });

  @HiveField(0)
  final VisionModelType modelType;

  @HiveField(1)
  final AnalysisMode analysisMode;

  @HiveField(2)
  final double confidenceThreshold;

  @HiveField(3)
  final int maxImageSize;

  @HiveField(4)
  final bool enableObjectDetection;

  @HiveField(5)
  final bool enableSegmentation;

  @HiveField(6)
  final int batchSize;

  @HiveField(7)
  final int batchTimeoutSeconds;

  @HiveField(8)
  final String? modelVersion;

  @HiveField(9)
  final String? customModelPath;

  @HiveField(10)
  final String? roboflowApiKey;

  @HiveField(11)
  final String? roboflowWorkspace;

  @HiveField(12)
  final String? roboflowProject;

  @HiveField(13)
  final bool preferOnDevice;

  /// Factory for default on-device configuration
  factory VisionModelConfig.onDevice() {
    return VisionModelConfig(
      modelType: VisionModelType.yoloV8,
      analysisMode: AnalysisMode.onDevice,
      confidenceThreshold: 0.6,
      enableObjectDetection: true,
      preferOnDevice: true,
    );
  }

  /// Factory for hybrid configuration (on-device with cloud fallback)
  factory VisionModelConfig.hybrid() {
    return VisionModelConfig(
      modelType: VisionModelType.yoloV8,
      analysisMode: AnalysisMode.hybrid,
      confidenceThreshold: 0.7,
      enableObjectDetection: true,
      preferOnDevice: true,
    );
  }

  /// Factory for batch cloud configuration (cost optimized)
  factory VisionModelConfig.batchCloud() {
    return VisionModelConfig(
      modelType: VisionModelType.openAI,
      analysisMode: AnalysisMode.batch,
      batchSize: 10,
      batchTimeoutSeconds: 60,
      preferOnDevice: false,
    );
  }

  VisionModelConfig copyWith({
    VisionModelType? modelType,
    AnalysisMode? analysisMode,
    double? confidenceThreshold,
    int? maxImageSize,
    bool? enableObjectDetection,
    bool? enableSegmentation,
    int? batchSize,
    int? batchTimeoutSeconds,
    String? modelVersion,
    String? customModelPath,
    String? roboflowApiKey,
    String? roboflowWorkspace,
    String? roboflowProject,
    bool? preferOnDevice,
  }) {
    return VisionModelConfig(
      modelType: modelType ?? this.modelType,
      analysisMode: analysisMode ?? this.analysisMode,
      confidenceThreshold: confidenceThreshold ?? this.confidenceThreshold,
      maxImageSize: maxImageSize ?? this.maxImageSize,
      enableObjectDetection: enableObjectDetection ?? this.enableObjectDetection,
      enableSegmentation: enableSegmentation ?? this.enableSegmentation,
      batchSize: batchSize ?? this.batchSize,
      batchTimeoutSeconds: batchTimeoutSeconds ?? this.batchTimeoutSeconds,
      modelVersion: modelVersion ?? this.modelVersion,
      customModelPath: customModelPath ?? this.customModelPath,
      roboflowApiKey: roboflowApiKey ?? this.roboflowApiKey,
      roboflowWorkspace: roboflowWorkspace ?? this.roboflowWorkspace,
      roboflowProject: roboflowProject ?? this.roboflowProject,
      preferOnDevice: preferOnDevice ?? this.preferOnDevice,
    );
  }
}

/// Model performance metrics
@HiveType(typeId: 33)
class ModelPerformanceMetrics extends HiveObject {
  ModelPerformanceMetrics({
    required this.modelType,
    required this.totalInferences,
    required this.averageLatencyMs,
    required this.averageConfidence,
    required this.successRate,
    required this.totalCost,
    required this.lastUpdated,
  });

  @HiveField(0)
  final VisionModelType modelType;

  @HiveField(1)
  final int totalInferences;

  @HiveField(2)
  final double averageLatencyMs;

  @HiveField(3)
  final double averageConfidence;

  @HiveField(4)
  final double successRate;

  @HiveField(5)
  final double totalCost;

  @HiveField(6)
  final DateTime lastUpdated;
}
