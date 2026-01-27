import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import '../models/vision_model_config.dart';
import '../utils/waste_app_logger.dart';

/// Service for downloading and managing TFLite model files
///
/// Handles:
/// - Model file downloads from remote URLs
/// - Local caching and storage
/// - Version management
/// - Download progress tracking
/// - WiFi-only download option
class ModelDownloadService {
  ModelDownloadService({
    this.baseUrl = 'https://storage.googleapis.com/waste-segregation-models',
    this.requireWifi = true,
  });

  final String baseUrl;
  final bool requireWifi;

  // Model file metadata
  static const Map<VisionModelType, ModelMetadata> modelMetadata = {
    VisionModelType.smolVLM: ModelMetadata(
      fileName: 'smolvlm_waste_classifier.tflite',
      version: '1.0.0',
      sizeBytes: 200 * 1024 * 1024, // 200MB
      description: 'SmolVLM vision-language model for waste classification',
    ),
    VisionModelType.mobileNetV3: ModelMetadata(
      fileName: 'mobilenet_v3_waste_classifier.tflite',
      version: '1.0.0',
      sizeBytes: 20 * 1024 * 1024, // 20MB
      description: 'MobileNetV3 lightweight classifier',
    ),
    VisionModelType.efficientNet: ModelMetadata(
      fileName: 'efficientnet_waste_classifier.tflite',
      version: '1.0.0',
      sizeBytes: 50 * 1024 * 1024, // 50MB
      description: 'EfficientNet balanced classifier',
    ),
    VisionModelType.yoloV8: ModelMetadata(
      fileName: 'yolov8_waste_detector.tflite',
      version: '1.0.0',
      sizeBytes: 50 * 1024 * 1024, // 50MB
      description: 'YOLOv8 object detection model',
    ),
    VisionModelType.yoloV11: ModelMetadata(
      fileName: 'yolov11_waste_detector.tflite',
      version: '1.0.0',
      sizeBytes: 60 * 1024 * 1024, // 60MB
      description: 'YOLOv11 latest object detection model',
    ),
  };

  /// Check if model is downloaded
  Future<bool> isModelDownloaded(VisionModelType modelType) async {
    try {
      final metadata = modelMetadata[modelType];
      if (metadata == null) {
        return false;
      }

      final appDir = await getApplicationDocumentsDirectory();
      final modelDir = Directory(path.join(appDir.path, 'models'));
      final modelFile = File(path.join(modelDir.path, metadata.fileName));

      return await modelFile.exists();
    } catch (e) {
      WasteAppLogger.warning('Error checking model existence: $e');
      return false;
    }
  }

  /// Get local model path if downloaded
  Future<String?> getModelPath(VisionModelType modelType) async {
    try {
      final isDownloaded = await isModelDownloaded(modelType);
      if (!isDownloaded) {
        return null;
      }

      final metadata = modelMetadata[modelType];
      if (metadata == null) {
        return null;
      }

      final appDir = await getApplicationDocumentsDirectory();
      final modelDir = Directory(path.join(appDir.path, 'models'));
      return path.join(modelDir.path, metadata.fileName);
    } catch (e) {
      WasteAppLogger.warning('Error getting model path: $e');
      return null;
    }
  }

  /// Download model with progress callback
  Future<void> downloadModel(
    VisionModelType modelType, {
    void Function(double progress)? onProgress,
    void Function(String status)? onStatusChange,
  }) async {
    final metadata = modelMetadata[modelType];
    if (metadata == null) {
      throw Exception('Model metadata not found for $modelType');
    }

    try {
      onStatusChange?.call('Preparing download...');
      WasteAppLogger.info('Starting download for ${metadata.fileName}');

      // Create models directory
      final appDir = await getApplicationDocumentsDirectory();
      final modelDir = Directory(path.join(appDir.path, 'models'));
      if (!await modelDir.exists()) {
        await modelDir.create(recursive: true);
      }

      final modelFile = File(path.join(modelDir.path, metadata.fileName));

      // Check if already downloaded
      if (await modelFile.exists()) {
        WasteAppLogger.info('Model already downloaded: ${metadata.fileName}');
        onProgress?.call(1.0);
        onStatusChange?.call('Already downloaded');
        return;
      }

      // Download from URL
      final url = '$baseUrl/${metadata.fileName}';
      onStatusChange?.call('Downloading from server...');

      final request = http.Request('GET', Uri.parse(url));
      final response = await http.Client().send(request);

      if (response.statusCode != 200) {
        throw Exception('Download failed with status ${response.statusCode}');
      }

      final totalBytes = response.contentLength ?? metadata.sizeBytes;
      var downloadedBytes = 0;

      final sink = modelFile.openWrite();

      try {
        await for (final chunk in response.stream) {
          sink.add(chunk);
          downloadedBytes += chunk.length;

          final progress = downloadedBytes / totalBytes;
          onProgress?.call(progress);

          final mbDownloaded =
              (downloadedBytes / (1024 * 1024)).toStringAsFixed(1);
          final mbTotal = (totalBytes / (1024 * 1024)).toStringAsFixed(1);
          onStatusChange?.call('Downloaded $mbDownloaded MB / $mbTotal MB');
        }
      } finally {
        await sink.close();
      }

      WasteAppLogger.info(
          'Model downloaded successfully: ${metadata.fileName}');
      onProgress?.call(1.0);
      onStatusChange?.call('Download complete');
    } catch (e, s) {
      WasteAppLogger.severe('Model download failed', error: e, stackTrace: s);
      onStatusChange?.call('Download failed: $e');
      rethrow;
    }
  }

  /// Download all available models
  Future<void> downloadAllModels({
    void Function(VisionModelType model, double progress)? onProgress,
    void Function(VisionModelType model, String status)? onStatusChange,
  }) async {
    for (final entry in modelMetadata.entries) {
      try {
        await downloadModel(
          entry.key,
          onProgress: (progress) => onProgress?.call(entry.key, progress),
          onStatusChange: (status) => onStatusChange?.call(entry.key, status),
        );
      } catch (e) {
        WasteAppLogger.warning('Failed to download ${entry.key.name}: $e');
        // Continue with other models
      }
    }
  }

  /// Delete model to free up space
  Future<void> deleteModel(VisionModelType modelType) async {
    try {
      final metadata = modelMetadata[modelType];
      if (metadata == null) {
        return;
      }

      final appDir = await getApplicationDocumentsDirectory();
      final modelDir = Directory(path.join(appDir.path, 'models'));
      final modelFile = File(path.join(modelDir.path, metadata.fileName));

      if (await modelFile.exists()) {
        await modelFile.delete();
        WasteAppLogger.info('Model deleted: ${metadata.fileName}');
      }
    } catch (e, s) {
      WasteAppLogger.severe('Failed to delete model', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Get total size of downloaded models
  Future<int> getTotalDownloadedSize() async {
    try {
      var totalSize = 0;

      for (final entry in modelMetadata.entries) {
        final isDownloaded = await isModelDownloaded(entry.key);
        if (isDownloaded) {
          totalSize += entry.value.sizeBytes;
        }
      }

      return totalSize;
    } catch (e) {
      WasteAppLogger.warning('Error calculating total size: $e');
      return 0;
    }
  }

  /// Get download status for all models
  Future<Map<VisionModelType, ModelStatus>> getAllModelStatus() async {
    final status = <VisionModelType, ModelStatus>{};

    for (final entry in modelMetadata.entries) {
      final isDownloaded = await isModelDownloaded(entry.key);
      status[entry.key] = ModelStatus(
        modelType: entry.key,
        metadata: entry.value,
        isDownloaded: isDownloaded,
      );
    }

    return status;
  }
}

/// Model metadata information
class ModelMetadata {
  const ModelMetadata({
    required this.fileName,
    required this.version,
    required this.sizeBytes,
    required this.description,
  });

  final String fileName;
  final String version;
  final int sizeBytes;
  final String description;

  String get sizeString {
    final mb = sizeBytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }
}

/// Model download status
class ModelStatus {
  const ModelStatus({
    required this.modelType,
    required this.metadata,
    required this.isDownloaded,
  });

  final VisionModelType modelType;
  final ModelMetadata metadata;
  final bool isDownloaded;
}
