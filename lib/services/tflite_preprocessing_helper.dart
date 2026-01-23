import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../utils/waste_app_logger.dart';

/// Lightweight TensorFlow Lite preprocessing helper
/// 
/// Replaces unmaintained tflite_flutter_helper package
/// Handles image preprocessing for TFLite model inference
class TFLitePreprocessingHelper {
  /// Preprocess image for TFLite model
  /// 
  /// Handles:
  /// - Image resizing to model input dimensions
  /// - Normalization (optional)
  /// - Float32 conversion for model input
  static Future<List<Float32List>> preprocessImageForInference({
    required img.Image image,
    required int inputWidth,
    required int inputHeight,
    bool normalize = true,
    double normalizeMin = -1.0,
    double normalizeMax = 1.0,
  }) async {
    try {
      // Resize image to model input dimensions
      final resized = img.copyResize(
        image,
        width: inputWidth,
        height: inputHeight,
        interpolation: img.Interpolation.linear,
      );

      // Convert to Float32 buffer
      final float32List = Float32List(inputWidth * inputHeight * 3);
      
      int pixelIndex = 0;
      for (int y = 0; y < inputHeight; y++) {
        for (int x = 0; x < inputWidth; x++) {
          final pixel = resized.getPixelSafe(x, y);
          
          // Extract RGB channels
          final r = img.getRed(pixel).toDouble();
          final g = img.getGreen(pixel).toDouble();
          final b = img.getBlue(pixel).toDouble();

          // Normalize if requested
          if (normalize) {
            float32List[pixelIndex] = _normalize(r, normalizeMin, normalizeMax);
            float32List[pixelIndex + 1] = _normalize(g, normalizeMin, normalizeMax);
            float32List[pixelIndex + 2] = _normalize(b, normalizeMin, normalizeMax);
          } else {
            float32List[pixelIndex] = r;
            float32List[pixelIndex + 1] = g;
            float32List[pixelIndex + 2] = b;
          }
          
          pixelIndex += 3;
        }
      }

      WasteAppLogger.info(
        'Image preprocessed for TFLite inference',
        context: {
          'original_size': '${image.width}x${image.height}',
          'model_input': '${inputWidth}x${inputHeight}',
          'normalized': normalize,
        },
      );

      return [float32List];
    } catch (e, s) {
      WasteAppLogger.severe(
        'Error preprocessing image for TFLite inference',
        e,
        s,
      );
      rethrow;
    }
  }

  /// Normalize pixel value from 0-255 range to specified range
  static double _normalize(
    double value,
    double minRange,
    double maxRange,
  ) {
    // Scale from 0-255 to 0-1
    final normalized = value / 255.0;
    // Scale to target range
    return minRange + (normalized * (maxRange - minRange));
  }

  /// Postprocess TFLite output probabilities
  /// 
  /// Takes raw model output and converts to readable predictions
  static Map<String, double> postprocessProbabilities({
    required List<double> predictions,
    required List<String> labels,
    double confidenceThreshold = 0.5,
  }) {
    if (predictions.length != labels.length) {
      throw ArgumentError(
        'Predictions count (${predictions.length}) must match labels count (${labels.length})',
      );
    }

    final results = <String, double>{};
    
    for (int i = 0; i < predictions.length; i++) {
      final confidence = predictions[i];
      if (confidence >= confidenceThreshold) {
        results[labels[i]] = confidence;
      }
    }

    return results;
  }

  /// Get top-N predictions from model output
  static List<MapEntry<String, double>> getTopPredictions({
    required List<double> predictions,
    required List<String> labels,
    int topN = 3,
  }) {
    if (predictions.length != labels.length) {
      throw ArgumentError(
        'Predictions count (${predictions.length}) must match labels count (${labels.length})',
      );
    }

    // Create list of predictions with labels
    final labeledPredictions = <MapEntry<String, double>>[];
    for (int i = 0; i < predictions.length; i++) {
      labeledPredictions.add(MapEntry(labels[i], predictions[i]));
    }

    // Sort by confidence descending
    labeledPredictions.sort((a, b) => b.value.compareTo(a.value));

    // Return top N
    return labeledPredictions.take(topN).toList();
  }

  /// Convert image bytes to Image object for preprocessing
  static img.Image decodeImageBytes(Uint8List bytes) {
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        throw Exception('Failed to decode image bytes');
      }
      return decoded;
    } catch (e) {
      WasteAppLogger.severe('Error decoding image bytes', e, null);
      rethrow;
    }
  }

  /// Batch preprocess multiple images
  static Future<List<List<Float32List>>> batchPreprocessImages({
    required List<img.Image> images,
    required int inputWidth,
    required int inputHeight,
    bool normalize = true,
  }) async {
    final results = <List<Float32List>>[];
    
    for (final image in images) {
      final processed = await preprocessImageForInference(
        image: image,
        inputWidth: inputWidth,
        inputHeight: inputHeight,
        normalize: normalize,
      );
      results.add(processed);
    }
    
    return results;
  }
}
