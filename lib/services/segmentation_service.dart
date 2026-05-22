import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/detected_waste_region.dart';
import '../models/vision_model_config.dart';
import '../utils/waste_app_logger.dart';

abstract class SegmentationBackend {
  Future<bool> initialize();
  Future<List<DetectedWasteRegion>> detectRegions(
    Uint8List imageBytes, {
    double confidenceThreshold = 0.5,
  });
  Future<Uint8List?> extractCrop(
    Uint8List imageBytes,
    NormalizedBoundingBox box,
  );
  void dispose();
}

class SegmentationService {
  SegmentationService({VisionModelConfig? config})
      : _config = config ?? VisionModelConfig.onDevice();

  final VisionModelConfig _config;
  SegmentationBackend? _backend;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      _backend = _createBackend();
      if (_backend == null) {
        WasteAppLogger.warning(
          'No segmentation backend — using manual-only mode',
        );
        _isInitialized = true;
        return;
      }
      await _backend!.initialize();
      _isInitialized = true;
      WasteAppLogger.info('SegmentationService initialized');
    } catch (e, s) {
      WasteAppLogger.severe('SegmentationService init failed',
          error: e, stackTrace: s);
      _isInitialized = true;
    }
  }

  SegmentationBackend? _createBackend() {
    if (_config.enableSegmentation) {
      switch (_config.modelType) {
        case VisionModelType.roboflowCustom:
          return CloudSegmentationBackend(_config);
        case VisionModelType.yoloV8:
        case VisionModelType.yoloV11:
        case VisionModelType.tfliteCustom:
          return YoloSegmentationBackend();
        default:
          return OnDeviceSegmentationBackend();
      }
    }
    return null;
  }

  Future<List<DetectedWasteRegion>> detectRegions(Uint8List imageBytes,
      {double confidenceThreshold = 0.5}) async {
    if (_backend != null) {
      try {
        return await _backend!.detectRegions(
          imageBytes,
          confidenceThreshold: confidenceThreshold,
        );
      } catch (e) {
        WasteAppLogger.warning('Segmentation backend failed', error: e);
      }
    }
    return [];
  }

  Future<Uint8List?> extractCrop(
    Uint8List imageBytes,
    NormalizedBoundingBox box,
  ) async {
    if (_backend != null) {
      try {
        return await _backend!.extractCrop(imageBytes, box);
      } catch (e) {
        WasteAppLogger.warning('Crop extraction failed', error: e);
      }
    }
    return null;
  }

  void dispose() {
    _backend?.dispose();
    _isInitialized = false;
  }
}

class OnDeviceSegmentationBackend extends SegmentationBackend {
  @override
  Future<bool> initialize() async {
    WasteAppLogger.info('On-device segmentation backend initialized');
    return true;
  }

  @override
  Future<List<DetectedWasteRegion>> detectRegions(
    Uint8List imageBytes, {
    double confidenceThreshold = 0.5,
  }) async {
    WasteAppLogger.info(
      'On-device segmentation: no TFLite model loaded. '
      'Place model at assets/models/yolo_waste.tflite',
    );
    return [];
  }

  @override
  Future<Uint8List?> extractCrop(
    Uint8List imageBytes,
    NormalizedBoundingBox box,
  ) async {
    return null;
  }

  @override
  void dispose() {}
}

class YoloSegmentationBackend extends SegmentationBackend {
  bool _modelLoaded = false;

  @override
  Future<bool> initialize() async {
    try {
      // TODO: Load YOLO TFLite model from:
      //   1. Bundled assets (assets/models/yolo_waste.tflite)
      //   2. Downloaded model cache (app documents directory)
      //   3. Remote model URL
      _modelLoaded = await _loadTFLiteModel();
      WasteAppLogger.info(
        _modelLoaded
            ? 'YOLO segmentation backend loaded TFLite model'
            : 'YOLO segmentation backend: no model found, using fallback',
      );
      return true;
    } catch (e) {
      WasteAppLogger.warning('YOLO backend init failed', error: e);
      _modelLoaded = false;
      return false;
    }
  }

  Future<bool> _loadTFLiteModel() async {
    // Stub: try loading from bundled assets
    // In production, use tflite_flutter or mediapipe:
    //   final interpreter = await Interpreter.fromAsset('models/yolo_waste.tflite');
    return false;
  }

  @override
  Future<List<DetectedWasteRegion>> detectRegions(
    Uint8List imageBytes, {
    double confidenceThreshold = 0.5,
  }) async {
    if (_modelLoaded) {
      // TODO: Run TFLite inference, apply NMS, return detections
      // 1. Preprocess: resize to 640x640, normalize
      // 2. Run interpreter
      // 3. Post-process: decode outputs, NMS, threshold
      // 4. Map to DetectedWasteRegion
      return [];
    }
    return [];
  }

  @override
  Future<Uint8List?> extractCrop(
    Uint8List imageBytes,
    NormalizedBoundingBox box,
  ) async {
    return null;
  }

  @override
  void dispose() {}
}

class CloudSegmentationBackend extends SegmentationBackend {
  CloudSegmentationBackend(this.config);
  final VisionModelConfig config;

  @override
  Future<bool> initialize() async {
    WasteAppLogger.info(
      'Cloud segmentation backend initialized (model=${config.modelType})',
    );
    return true;
  }

  @override
  Future<List<DetectedWasteRegion>> detectRegions(
    Uint8List imageBytes, {
    double confidenceThreshold = 0.5,
  }) async {
    WasteAppLogger.info(
      'Cloud segmentation: no API configured for ${config.modelType}',
    );
    return [];
  }

  @override
  Future<Uint8List?> extractCrop(
    Uint8List imageBytes,
    NormalizedBoundingBox box,
  ) async {
    return null;
  }

  @override
  void dispose() {}
}

class GridSegmentationBackend extends SegmentationBackend {
  GridSegmentationBackend({this.gridSize = 4});
  final int gridSize;

  @override
  Future<bool> initialize() async => true;

  @override
  Future<List<DetectedWasteRegion>> detectRegions(
    Uint8List imageBytes, {
    double confidenceThreshold = 0.5,
  }) async {
    final cellWidth = 1.0 / gridSize;
    final cellHeight = 1.0 / gridSize;
    final regions = <DetectedWasteRegion>[];
    var index = 0;
    for (var row = 0; row < gridSize; row++) {
      for (var col = 0; col < gridSize; col++) {
        index++;
        regions.add(DetectedWasteRegion(
          id: 'grid_$index',
          boundingBox: NormalizedBoundingBox(
            left: col * cellWidth,
            top: row * cellHeight,
            width: cellWidth,
            height: cellHeight,
          ),
          label: 'Region $index',
          confidence: 0.5,
        ));
      }
    }
    return regions;
  }

  @override
  Future<Uint8List?> extractCrop(
    Uint8List imageBytes,
    NormalizedBoundingBox box,
  ) async {
    return null;
  }

  @override
  void dispose() {}
}
