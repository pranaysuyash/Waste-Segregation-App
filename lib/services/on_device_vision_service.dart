import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:waste_segregation_app/models/waste_classification.dart';
import '../models/vision_model_config.dart';
import '../utils/waste_app_logger.dart';
import '../utils/platform_file_io.dart';
import 'package:uuid/uuid.dart';

/// Service for on-device vision inference (zero cost)
///
/// Supports multiple on-device vision models including:
/// - SmolVLM: Small vision-language model optimized for mobile
/// - MobileNetV3: Lightweight classification network
/// - EfficientNet: Efficient convolutional network
/// - YOLOv8: Fast object detection
/// - YOLOv11: Latest YOLO version with improved accuracy
///
/// Benefits:
/// - Zero API costs (runs locally on device)
/// - Better privacy (no data sent to cloud)
/// - Works offline
/// - Faster inference for simple cases
///
/// Limitations:
/// - Lower accuracy than cloud models for complex items
/// - Requires model download and device storage
/// - Performance varies by device hardware
class OnDeviceVisionService {
  OnDeviceVisionService({
    VisionModelConfig? config,
  }) : _config = config ?? VisionModelConfig.onDevice();

  final VisionModelConfig _config;
  bool _isInitialized = false;
  String? _modelPath;

  /// Initialize the service and download/load model if needed
  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    try {
      WasteAppLogger.info(
          'Initializing on-device vision service with model: ${_config.modelType}');

      // Check if model exists locally
      final modelExists = await _checkModelExists();

      if (!modelExists) {
        WasteAppLogger.info(
            'Model not found locally, attempting to load from assets');
        await _loadModelFromAssets();
      }

      _isInitialized = true;
      WasteAppLogger.info('On-device vision service initialized successfully');
    } catch (e, s) {
      WasteAppLogger.severe('Failed to initialize on-device vision service',
          error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Check if model file exists locally
  Future<bool> _checkModelExists() async {
    // File system access is not available on web — short-circuit in that case.
    if (kIsWeb) {
      WasteAppLogger.info(
          'Running on web; local model files are not available');
      return false;
    }

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final modelDirPath = path.join(appDir.path, 'models');
      final modelFilePath = path.join(modelDirPath, _getModelFileName());

      if (await fileExists(modelFilePath)) {
        _modelPath = modelFilePath;
        return true;
      }

      return false;
    } catch (e, s) {
      WasteAppLogger.warning('Error checking model existence',
          error: e, stackTrace: s);
      return false;
    }
  }

  /// Load model from assets bundle
  Future<void> _loadModelFromAssets() async {
    // On web we can't write files to a local filesystem — keep the asset path as the model identifier.
    final modelFileName = _getModelFileName();

    if (kIsWeb) {
      try {
        final assetPath = 'assets/models/$modelFileName';
        // Attempt to ensure asset is available by loading it
        await rootBundle.load(assetPath);
        _modelPath = assetPath;
        WasteAppLogger.info('Model asset available on web: $assetPath');
      } catch (e, s) {
        WasteAppLogger.warning('Model asset not available on web',
            error: e, stackTrace: s);
      }
      return;
    }

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final modelDirPath = path.join(appDir.path, 'models');

      await createDirectory(modelDirPath);

      final modelFilePath = path.join(modelDirPath, modelFileName);

      // Try to load from assets (if model is bundled)
      // Note: For production, models should be downloaded separately due to size
      try {
        final assetPath = 'assets/models/$modelFileName';
        final data = await rootBundle.load(assetPath);
        await writeFileBytes(modelFilePath, data.buffer.asUint8List());
        _modelPath = modelFilePath;
        WasteAppLogger.info('Model loaded from assets: $_modelPath');
      } catch (e, s) {
        WasteAppLogger.warning('Model not found in assets',
            error: e, stackTrace: s);
        // Model needs to be downloaded separately
        // For now, we'll create a placeholder path
        _modelPath = modelFilePath;
      }
    } catch (e, s) {
      WasteAppLogger.severe('Failed to load model from assets',
          error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Get model file name based on configuration
  String _getModelFileName() {
    switch (_config.modelType) {
      case VisionModelType.smolVLM:
        return 'smolvlm_waste_classifier.tflite';
      case VisionModelType.mobileNetV3:
        return 'mobilenet_v3_waste_classifier.tflite';
      case VisionModelType.efficientNet:
        return 'efficientnet_waste_classifier.tflite';
      case VisionModelType.yoloV8:
        return 'yolov8_waste_detector.tflite';
      case VisionModelType.yoloV11:
        return 'yolov11_waste_detector.tflite';
      case VisionModelType.tfliteCustom:
        return _config.customModelPath ?? 'custom_model.tflite';
      default:
        throw UnsupportedError(
            'Model type ${_config.modelType} not supported for on-device inference');
    }
  }

  /// Analyze image using on-device model
  ///
  /// This is a placeholder implementation that demonstrates the architecture.
  /// In production, this would use tflite_flutter to run actual inference.
  Future<WasteClassification> analyzeImage(
    File imageFile, {
    String? region,
    String? classificationId,
  }) async {
    // This method requires file-system access and is not supported on web.
    if (kIsWeb) {
      throw UnsupportedError(
          'analyzeImage is not supported on web. Use analyzeWebImage instead.');
    }

    if (!_isInitialized) {
      await initialize();
    }

    try {
      final startTime = DateTime.now();
      WasteAppLogger.info(
          'Starting on-device analysis with ${_config.modelType}');

      // Read image bytes via platform-abstracted I/O
      final imageBytes = await readFileBytes(imageFile.path);

      // TODO: Implement actual TFLite inference here
      // For now, return a placeholder result indicating on-device analysis
      final result = await _performInference(imageBytes, region);

      final endTime = DateTime.now();
      final processingTime = endTime.difference(startTime).inMilliseconds;

      WasteAppLogger.info(
          'On-device analysis completed in ${processingTime}ms');

      return result.copyWith(
        id: classificationId ?? const Uuid().v4(),
        processingTimeMs: processingTime,
        modelSource: 'on-device-${_config.modelType.name}',
        timestamp: DateTime.now(),
      );
    } catch (e, s) {
      WasteAppLogger.severe('On-device analysis failed',
          error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Analyze web image using on-device model
  Future<WasteClassification> analyzeWebImage(
    Uint8List imageBytes, {
    String? region,
    String? classificationId,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final startTime = DateTime.now();

      final result = await _performInference(imageBytes, region);

      final endTime = DateTime.now();
      final processingTime = endTime.difference(startTime).inMilliseconds;

      return result.copyWith(
        id: classificationId ?? const Uuid().v4(),
        processingTimeMs: processingTime,
        modelSource: 'on-device-${_config.modelType.name}',
        timestamp: DateTime.now(),
      );
    } catch (e, s) {
      WasteAppLogger.severe('On-device web analysis failed',
          error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Perform actual inference (placeholder)
  ///
  /// In production, this would:
  /// 1. Preprocess the image (resize, normalize)
  /// 2. Run TFLite inference
  /// 3. Post-process the output
  /// 4. Map to waste classification categories
  Future<WasteClassification> _performInference(
    Uint8List imageBytes,
    String? region,
  ) async {
    // This is a placeholder implementation
    // In production, use tflite_flutter package for actual inference

    WasteAppLogger.info('Performing on-device inference (placeholder mode)');

    // Simulate processing time
    await Future.delayed(const Duration(milliseconds: 100));

    // Return a placeholder classification indicating on-device mode
    // In production, this would be the actual model output
    return WasteClassification(
      itemName: 'On-Device Analysis Required',
      category: 'On-Device Mode',
      explanation:
          'This is a placeholder result. Full on-device inference requires model integration. '
          'Model type: ${_config.modelType.name}. '
          'Please add TFLite models to enable zero-cost on-device analysis.',
      disposalInstructions: DisposalInstructions(
        primaryMethod: 'Setup on-device models',
        steps: [
          'Add TFLite model files to assets/models/',
          'Download pre-trained waste classification models',
          'Or train custom models for your specific use case',
        ],
        hasUrgentTimeframe: false,
      ),
      visualFeatures: [
        'On-device processing',
        'Zero API cost',
        'Privacy-preserving'
      ],
      alternatives: [
        AlternativeClassification(
          category: 'Cloud Analysis',
          confidence: 0.8,
          reason: 'Cloud-based analysis available as fallback',
        ),
      ],
      region: region ?? 'Global',
      confidence: 0.0, // Indicates placeholder result
      modelSource: 'on-device-${_config.modelType.name}',
      modelVersion: '1.0.0-placeholder',
    );
  }

  /// Get model information
  Map<String, dynamic> getModelInfo() {
    return {
      'model_type': _config.modelType.name,
      'is_initialized': _isInitialized,
      'model_path': _modelPath,
      'confidence_threshold': _config.confidenceThreshold,
      'max_image_size': _config.maxImageSize,
      'object_detection_enabled': _config.enableObjectDetection,
      'segmentation_enabled': _config.enableSegmentation,
    };
  }

  /// Dispose resources
  void dispose() {
    // Clean up resources when service is no longer needed
    _isInitialized = false;
    _modelPath = null;
    WasteAppLogger.info('On-device vision service disposed');
  }
}
