import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import '../mixins/disposable_service_mixin.dart';
import '../services/memory_management_service.dart';
import '../utils/waste_app_logger.dart';

/// Configuration for image processing operations
class ImageProcessingConfig {
  const ImageProcessingConfig({
    this.maxWidth = 1024,
    this.maxHeight = 1024,
    this.quality = 85,
    this.format = ImageFormat.jpeg,
    this.enableMemoryOptimization = true,
    this.maxConcurrentOperations = 3,
  });

  final int maxWidth;
  final int maxHeight;
  final int quality;
  final ImageFormat format;
  final bool enableMemoryOptimization;
  final int maxConcurrentOperations;
}

/// Supported image formats
enum ImageFormat { jpeg, png, webp }

/// Result of image processing operation
class ImageProcessingResult {
  const ImageProcessingResult({
    required this.processedData,
    required this.originalSize,
    required this.processedSize,
    required this.compressionRatio,
    required this.processingTimeMs,
    required this.format,
    this.width,
    this.height,
  });

  final Uint8List processedData;
  final int originalSize;
  final int processedSize;
  final double compressionRatio;
  final int processingTimeMs;
  final ImageFormat format;
  final int? width;
  final int? height;

  Map<String, dynamic> toJson() => {
    'originalSize': originalSize,
    'processedSize': processedSize,
    'compressionRatio': compressionRatio,
    'processingTimeMs': processingTimeMs,
    'format': format.name,
    'width': width,
    'height': height,
    'sizeSavingBytes': originalSize - processedSize,
    'sizeSavingPercent': ((originalSize - processedSize) / originalSize * 100).toStringAsFixed(1),
  };
}

/// Enhanced image processing service with memory management
class EnhancedImageProcessingService extends ChangeNotifier with DisposableServiceMixin {
  EnhancedImageProcessingService({
    ImageProcessingConfig? config,
  }) : _config = config ?? const ImageProcessingConfig() {
    initializeService();
  }

  final ImageProcessingConfig _config;
  final Map<String, Completer<ImageProcessingResult>> _activeOperations = {};
  int _operationCounter = 0;

  /// Process image from file path
  Future<ImageProcessingResult> processImageFromPath(
    String imagePath, {
    ImageProcessingConfig? customConfig,
  }) async {
    ensureNotDisposed('processImageFromPath');
    
    final operationId = 'path_${++_operationCounter}';
    
    return executeTrackedOperation(operationId, () async {
      MemoryManagementService.instance.trackImageOperation(operationId);
      
      try {
        final file = File(imagePath);
        if (!await file.exists()) {
          throw ArgumentError('Image file does not exist: $imagePath');
        }
        
        final imageData = await file.readAsBytes();
        return await _processImageData(imageData, customConfig ?? _config, operationId);
        
      } finally {
        MemoryManagementService.instance.completeImageOperation(operationId);
      }
    });
  }

  /// Process image from byte data
  Future<ImageProcessingResult> processImageFromBytes(
    Uint8List imageData, {
    ImageProcessingConfig? customConfig,
  }) async {
    ensureNotDisposed('processImageFromBytes');
    
    final operationId = 'bytes_${++_operationCounter}';
    
    return executeTrackedOperation(operationId, () async {
      MemoryManagementService.instance.trackImageOperation(operationId);
      
      try {
        return await _processImageData(imageData, customConfig ?? _config, operationId);
      } finally {
        MemoryManagementService.instance.completeImageOperation(operationId);
      }
    });
  }

  /// Process multiple images concurrently with resource management
  Future<List<ImageProcessingResult>> processMultipleImages(
    List<String> imagePaths, {
    ImageProcessingConfig? customConfig,
    int? maxConcurrent,
  }) async {
    ensureNotDisposed('processMultipleImages');
    
    final config = customConfig ?? _config;
    final concurrency = maxConcurrent ?? config.maxConcurrentOperations;
    
    final results = <ImageProcessingResult>[];
    final semaphore = Semaphore(concurrency);
    
    final futures = imagePaths.map((path) async {
      await semaphore.acquire();
      try {
        return await processImageFromPath(path, customConfig: config);
      } finally {
        semaphore.release();
      }
    });
    
    return await Future.wait(futures);
  }

  /// Get processing statistics
  Map<String, dynamic> getProcessingStats() {
    return {
      'activeOperations': _activeOperations.length,
      'totalOperationsProcessed': _operationCounter,
      'maxConcurrentOperations': _config.maxConcurrentOperations,
      'memoryOptimizationEnabled': _config.enableMemoryOptimization,
      'defaultQuality': _config.quality,
      'defaultMaxDimensions': '${_config.maxWidth}x${_config.maxHeight}',
      'serviceHealth': getServiceHealth(),
    };
  }

  /// Internal image processing implementation
  Future<ImageProcessingResult> _processImageData(
    Uint8List imageData,
    ImageProcessingConfig config,
    String operationId,
  ) async {
    final stopwatch = Stopwatch()..start();
    final originalSize = imageData.length;
    
    try {
      // Check if operation was cancelled
      if (isDisposed) {
        throw StateError('Service disposed during operation');
      }
      
      // Decode image
      img.Image? image = img.decodeImage(imageData);
      if (image == null) {
        throw ArgumentError('Unable to decode image data');
      }
      
      WasteAppLogger.debug('Image decoded successfully', {
        'service': 'enhanced_image_processing',
        'operation_id': operationId,
        'original_width': image.width,
        'original_height': image.height,
        'original_size_bytes': originalSize,
      });
      
      // Apply memory optimization if enabled
      if (config.enableMemoryOptimization) {
        image = await _optimizeImageMemory(image, config, operationId);
      }
      
      // Resize if needed
      if (image.width > config.maxWidth || image.height > config.maxHeight) {
        image = await _resizeImage(image, config, operationId);
      }
      
      // Encode with specified format and quality
      final processedData = await _encodeImage(image, config, operationId);
      
      stopwatch.stop();
      
      final result = ImageProcessingResult(
        processedData: processedData,
        originalSize: originalSize,
        processedSize: processedData.length,
        compressionRatio: processedData.length / originalSize,
        processingTimeMs: stopwatch.elapsedMilliseconds,
        format: config.format,
        width: image.width,
        height: image.height,
      );
      
      WasteAppLogger.performanceLog('image_processing_complete', stopwatch.elapsedMilliseconds, 
        context: {
          'service': 'enhanced_image_processing',
          'operation_id': operationId,
          'original_size_kb': (originalSize / 1024).toStringAsFixed(1),
          'processed_size_kb': (processedData.length / 1024).toStringAsFixed(1),
          'compression_ratio': result.compressionRatio.toStringAsFixed(3),
          'size_reduction_percent': ((1 - result.compressionRatio) * 100).toStringAsFixed(1),
        });
      
      return result;
      
    } catch (e) {
      stopwatch.stop();
      
      WasteAppLogger.severe('Image processing failed', e, null, {
        'service': 'enhanced_image_processing',
        'operation_id': operationId,
        'processing_time_ms': stopwatch.elapsedMilliseconds,
        'original_size_bytes': originalSize,
      });
      
      rethrow;
    }
  }

  /// Optimize image memory usage
  Future<img.Image> _optimizeImageMemory(
    img.Image image,
    ImageProcessingConfig config,
    String operationId,
  ) async {
    // Convert to more memory-efficient format if needed
    if (image.numChannels > 3 && config.format == ImageFormat.jpeg) {
      // Remove alpha channel for JPEG
      final optimized = img.Image(
        width: image.width,
        height: image.height,
        numChannels: 3,
      );
      
      img.compositeImage(optimized, image);
      
      WasteAppLogger.debug('Image memory optimized', {
        'service': 'enhanced_image_processing',
        'operation_id': operationId,
        'original_channels': image.numChannels,
        'optimized_channels': optimized.numChannels,
      });
      
      return optimized;
    }
    
    return image;
  }

  /// Resize image maintaining aspect ratio
  Future<img.Image> _resizeImage(
    img.Image image,
    ImageProcessingConfig config,
    String operationId,
  ) async {
    final aspectRatio = image.width / image.height;
    int newWidth, newHeight;
    
    if (image.width > image.height) {
      newWidth = config.maxWidth;
      newHeight = (config.maxWidth / aspectRatio).round();
      
      if (newHeight > config.maxHeight) {
        newHeight = config.maxHeight;
        newWidth = (config.maxHeight * aspectRatio).round();
      }
    } else {
      newHeight = config.maxHeight;
      newWidth = (config.maxHeight * aspectRatio).round();
      
      if (newWidth > config.maxWidth) {
        newWidth = config.maxWidth;
        newHeight = (config.maxWidth / aspectRatio).round();
      }
    }
    
    final resized = img.copyResize(
      image,
      width: newWidth,
      height: newHeight,
      interpolation: img.Interpolation.cubic,
    );
    
    WasteAppLogger.debug('Image resized', {
      'service': 'enhanced_image_processing',
      'operation_id': operationId,
      'original_dimensions': '${image.width}x${image.height}',
      'new_dimensions': '${newWidth}x${newHeight}',
      'aspect_ratio': aspectRatio.toStringAsFixed(3),
    });
    
    return resized;
  }

  /// Encode image with specified format and quality
  Future<Uint8List> _encodeImage(
    img.Image image,
    ImageProcessingConfig config,
    String operationId,
  ) async {
    Uint8List encodedData;
    
    switch (config.format) {
      case ImageFormat.jpeg:
        encodedData = img.encodeJpg(image, quality: config.quality);
        break;
      case ImageFormat.png:
        encodedData = img.encodePng(image);
        break;
      case ImageFormat.webp:
        // Note: WebP encoding might not be available in all environments
        try {
          // WebP encoding not available in current image package version
          encodedData = img.encodeJpg(image, quality: config.quality);
        } catch (e) {
          WasteAppLogger.warning('WebP encoding failed, falling back to JPEG', e, null, {
            'service': 'enhanced_image_processing',
            'operation_id': operationId,
          });
          encodedData = img.encodeJpg(image, quality: config.quality);
        }
        break;
    }
    
    WasteAppLogger.debug('Image encoded', {
      'service': 'enhanced_image_processing',
      'operation_id': operationId,
      'format': config.format.name,
      'quality': config.quality,
      'encoded_size_bytes': encodedData.length,
    });
    
    return encodedData;
  }

  @override
  void dispose() {
    // Cancel all active operations
    for (final completer in _activeOperations.values) {
      if (!completer.isCompleted) {
        completer.completeError(StateError('Service disposed'));
      }
    }
    _activeOperations.clear();
    
    super.dispose();
  }
}

/// Semaphore for controlling concurrent operations
class Semaphore {
  Semaphore(this.maxCount) : _currentCount = maxCount;
  
  final int maxCount;
  int _currentCount;
  final Queue<Completer<void>> _waitQueue = Queue<Completer<void>>();
  
  Future<void> acquire() async {
    if (_currentCount > 0) {
      _currentCount--;
      return;
    }
    
    final completer = Completer<void>();
    _waitQueue.add(completer);
    return completer.future;
  }
  
  void release() {
    if (_waitQueue.isNotEmpty) {
      final completer = _waitQueue.removeFirst();
      completer.complete();
    } else {
      _currentCount++;
    }
  }
}