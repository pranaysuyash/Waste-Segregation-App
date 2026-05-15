import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../utils/waste_app_logger.dart';

/// Pre-flight quality check to prevent wasting API credits on poor-quality images
///
/// Checks:
/// - Minimum resolution (300x300)
/// - Blur detection via Laplacian variance
/// - Brightness (too dark or overexposed)
///
/// Fail-open design: if checks crash, image is allowed (better UX than blocking)
class ImageQualityGate {
  // Configurable thresholds
  static int minDimension = 300;
  static double minVariance = 100.0; // Blur threshold - lower = blurrier
  static int minBrightness = 40;
  static int maxBrightness = 250; // Overexposed threshold

  /// Check image quality before sending to AI API
  /// Returns [QualityCheckResult] with pass/fail and detailed metrics
  static Future<QualityCheckResult> check(Uint8List bytes) async {
    final stopwatch = Stopwatch()..start();

    try {
      // Try multiple decoders
      img.Image? image;
      try {
        image = img.decodeJpg(bytes);
      } catch (_) {
        try {
          image = img.decodePng(bytes);
        } catch (_) {
          image = img.decodeImage(bytes); // Generic fallback
        }
      }

      if (image == null) {
        WasteAppLogger.warning('Could not decode image for quality check');
        return QualityCheckResult(
          isValid: false,
          reason: 'Invalid image format',
          suggestion: 'Try taking the photo again',
          failureType: QualityFailureType.decodeError,
        );
      }

      final width = image.width;
      final height = image.height;

      // Check 1: Minimum resolution
      if (width < minDimension || height < minDimension) {
        final result = QualityCheckResult(
          isValid: false,
          reason: 'Image too small (${width}x$height)',
          suggestion: 'Move closer to the object',
          failureType: QualityFailureType.resolution,
          metrics: {
            'width': width.toString(),
            'height': height.toString(),
            'required': '$minDimension x $minDimension',
          },
        );

        _logQualityCheck(result, stopwatch.elapsedMilliseconds);
        return result;
      }

      // Check 2: Blur detection (Laplacian variance)
      final variance = await _calculateLaplacianVariance(image);
      if (variance < minVariance) {
        final result = QualityCheckResult(
          isValid: false,
          reason: 'Image too blurry',
          suggestion: 'Hold steady and ensure focus before capturing',
          failureType: QualityFailureType.blur,
          metrics: {
            'blur_variance': variance.toStringAsFixed(1),
            'threshold': minVariance.toStringAsFixed(1),
          },
        );

        _logQualityCheck(result, stopwatch.elapsedMilliseconds);
        return result;
      }

      // Check 3: Brightness
      final brightness = await _averageBrightness(image);
      if (brightness < minBrightness) {
        final result = QualityCheckResult(
          isValid: false,
          reason: 'Image too dark',
          suggestion: 'Turn on lights or use camera flash',
          failureType: QualityFailureType.tooDark,
          metrics: {
            'brightness': brightness.toStringAsFixed(0),
            'min_threshold': minBrightness.toString(),
          },
        );

        _logQualityCheck(result, stopwatch.elapsedMilliseconds);
        return result;
      }

      if (brightness > maxBrightness) {
        final result = QualityCheckResult(
          isValid: false,
          reason: 'Image overexposed',
          suggestion: 'Reduce lighting or move to shade',
          failureType: QualityFailureType.overexposed,
          metrics: {
            'brightness': brightness.toStringAsFixed(0),
            'max_threshold': maxBrightness.toString(),
          },
        );

        _logQualityCheck(result, stopwatch.elapsedMilliseconds);
        return result;
      }

      // All checks passed
      final result = QualityCheckResult(
        isValid: true,
        reason: 'Image quality acceptable',
        metrics: {
          'resolution': '${width}x$height',
          'blur_variance': variance.toStringAsFixed(1),
          'brightness': brightness.toStringAsFixed(0),
        },
      );

      _logQualityCheck(result, stopwatch.elapsedMilliseconds);
      return result;
    } catch (e, stackTrace) {
      // Fail open - don't block user if quality check crashes
      WasteAppLogger.warning(
        'Quality check error, allowing image (fail-open)',
        error: e,
        stackTrace: stackTrace,
      );

      final result = QualityCheckResult(
        isValid: true, // Allow through on error
        reason: 'Quality check unavailable (allowed)',
        suggestion: 'Photo will be sent to AI for analysis',
      );

      // Note: Analytics tracking removed due to static method constraints
      // Error is logged above via WasteAppLogger

      return result;
    }
  }

  /// Calculate Laplacian variance (edge detection) to detect blur
  /// Low variance = blurry (few edges), high variance = sharp (many edges)
  static Future<double> _calculateLaplacianVariance(img.Image src) async {
    final gray = img.grayscale(src);
    double sum = 0;
    double sumSquared = 0;
    var count = 0;

    // Sample every 4th pixel for performance (still accurate)
    for (var y = 2; y < gray.height - 2; y += 4) {
      for (var x = 2; x < gray.width - 2; x += 4) {
        final laplacian = _computeLaplacian(gray, x, y);
        sum += laplacian;
        sumSquared += laplacian * laplacian;
        count++;
      }
    }

    if (count == 0) return 0;

    final mean = sum / count;
    final variance = (sumSquared / count) - (mean * mean);
    return variance;
  }

  /// Compute Laplacian at a single pixel using 3x3 kernel
  static double _computeLaplacian(img.Image gray, int x, int y) {
    final center = img.getLuminance(gray.getPixel(x, y));
    final north = img.getLuminance(gray.getPixel(x, y - 1));
    final south = img.getLuminance(gray.getPixel(x, y + 1));
    final east = img.getLuminance(gray.getPixel(x + 1, y));
    final west = img.getLuminance(gray.getPixel(x - 1, y));

    // Simplified Laplacian: 4*center - sum(neighbors)
    return (4 * center - north - south - east - west).abs().toDouble();
  }

  /// Calculate average brightness of the image
  static Future<double> _averageBrightness(img.Image src) async {
    num total = 0;
    var count = 0;

    // Sample every 8th pixel for performance
    for (var y = 0; y < src.height; y += 8) {
      for (var x = 0; x < src.width; x += 8) {
        total += img.getLuminance(src.getPixel(x, y));
        count++;
      }
    }

    return count > 0 ? (total / count).toDouble() : 0.0;
  }

  /// Log quality check result for analytics
  static void _logQualityCheck(QualityCheckResult result, int durationMs) {
    WasteAppLogger.info(
      'Image quality check: ${result.isValid ? "PASS" : "FAIL"}',
      context: {
        'valid': result.isValid,
        'reason': result.reason,
        'failure_type': result.failureType?.name,
        'duration_ms': durationMs,
        ...?result.metrics,
      },
    );
  }
}

/// Result of image quality check
class QualityCheckResult {
  QualityCheckResult({
    required this.isValid,
    required this.reason,
    this.suggestion = '',
    this.failureType,
    this.metrics,
  });
  final bool isValid;
  final String reason;
  final String suggestion;
  final QualityFailureType? failureType;
  final Map<String, String>? metrics;

  /// Get user-friendly message for display
  String get userMessage => '$reason\n\n$suggestion';
}

/// Types of quality check failures for analytics
enum QualityFailureType {
  resolution,
  blur,
  tooDark,
  overexposed,
  decodeError,
}
