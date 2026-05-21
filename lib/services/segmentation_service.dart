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
          'No segmentation backend available — using manual-only mode',
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
      return _config.modelType == VisionModelType.roboflowCustom
          ? CloudSegmentationBackend(_config)
          : OnDeviceSegmentationBackend();
    }
    return null;
  }

  Future<List<DetectedWasteRegion>> detectRegions(Uint8List imageBytes,
      {double confidenceThreshold = 0.5}) async {
    if (_backend != null && _config.enableSegmentation) {
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
    WasteAppLogger.info('On-device segmentation backend initialized (stub)');
    return true;
  }

  @override
  Future<List<DetectedWasteRegion>> detectRegions(
    Uint8List imageBytes, {
    double confidenceThreshold = 0.5,
  }) async {
    WasteAppLogger.info('On-device segmentation detectRegions (stub)');
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
      'Cloud segmentation backend initialized (stub, model=${config.modelType})',
    );
    return true;
  }

  @override
  Future<List<DetectedWasteRegion>> detectRegions(
    Uint8List imageBytes, {
    double confidenceThreshold = 0.5,
  }) async {
    WasteAppLogger.info('Cloud segmentation detectRegions (stub)');
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
