import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../utils/waste_app_logger.dart';

enum ModelDownloadState { notDownloaded, downloading, ready, error }

enum YoloModelVariant {
  yolo11nSeg('yolo11n-seg'),
  yolo26nSeg('yolo26n-seg'),
  customWaste('waste-custom');

  final String label;
  const YoloModelVariant(this.label);
}

class YoloModelManager {
  YoloModelManager({YoloModelVariant? variant})
      : _variant = variant ?? YoloModelVariant.yolo11nSeg;

  final YoloModelVariant _variant;
  ModelDownloadState _state = ModelDownloadState.notDownloaded;
  String? _modelPath;
  String? _error;

  ModelDownloadState get state => _state;
  String? get modelPath => _modelPath;
  String? get error => _error;
  YoloModelVariant get variant => _variant;

  String get _modelFileName {
    switch (_variant) {
      case YoloModelVariant.yolo11nSeg:
        return 'yolo11n_seg_640.tflite';
      case YoloModelVariant.yolo26nSeg:
        return 'yolo26n_seg_640.tflite';
      case YoloModelVariant.customWaste:
        return 'waste_seg_model.tflite';
    }
  }

  String? get _modelUrl {
    switch (_variant) {
      case YoloModelVariant.yolo11nSeg:
        return 'https://github.com/ultralytics/assets/releases/download/v8.3.0/yolo11n-seg.tflite';
      case YoloModelVariant.yolo26nSeg:
        return null; // Not yet published — build from Ultralytics export
      case YoloModelVariant.customWaste:
        return null; // Custom model URL TBD
    }
  }

  Future<void> initialize() async {
    // Check bundled assets first
    if (kIsWeb) {
      _state = ModelDownloadState.ready;
      return;
    }

    final dir = await getApplicationDocumentsDirectory();
    final modelDir = Directory('${dir.path}/models');
    if (!await modelDir.exists()) {
      await modelDir.create(recursive: true);
    }

    final file = File('${modelDir.path}/$_modelFileName');
    if (await file.exists()) {
      _modelPath = file.path;
      _state = ModelDownloadState.ready;
      WasteAppLogger.info('YOLO model found at ${file.path}');
      return;
    }

    // Check bundled assets
    _modelPath = 'assets/models/$_modelFileName';
    _state = ModelDownloadState.ready;
  }

  Future<bool> download() async {
    final url = _modelUrl;
    if (url == null) {
      _error = 'No download URL for $_variant';
      _state = ModelDownloadState.error;
      return false;
    }

    _state = ModelDownloadState.downloading;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/models/$_modelFileName');
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        _modelPath = file.path;
        _state = ModelDownloadState.ready;
        WasteAppLogger.info('YOLO model downloaded to ${file.path}');
        return true;
      } else {
        _error = 'Download failed: HTTP ${response.statusCode}';
        _state = ModelDownloadState.error;
        return false;
      }
    } catch (e) {
      _error = 'Download error: $e';
      _state = ModelDownloadState.error;
      WasteAppLogger.warning('YOLO model download failed', error: e);
      return false;
    }
  }

  String get sizeDisplay {
    switch (_variant) {
      case YoloModelVariant.yolo11nSeg:
        return '6.2 MB';
      case YoloModelVariant.yolo26nSeg:
        return '6.7 MB';
      case YoloModelVariant.customWaste:
        return '~10 MB';
    }
  }
}
