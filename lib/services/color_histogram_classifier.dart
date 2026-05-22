import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import 'local_classifier_service.dart';

/// Color-rule entry used for HSV-bin → category mapping.
class _ColorRule {
  const _ColorRule({
    required this.hueMin,
    required this.hueMax,
    required this.satMin,
    required this.satMax,
    required this.valMin,
    required this.valMax,
    required this.category,
    this.subcategory,
    required this.baseConfidence,
  });

  final double hueMin;
  final double hueMax;
  final double satMin;
  final double satMax;
  final double valMin;
  final double valMax;
  final String category;
  final String? subcategory;
  final double baseConfidence;

  bool matches(double h, double s, double v) =>
      h >= hueMin &&
      h <= hueMax &&
      s >= satMin &&
      s <= satMax &&
      v >= valMin &&
      v <= valMax;
}

/// Ordered color rules — first match wins.
const List<_ColorRule> _kColorRules = [
  // Green organic tones → Wet Waste
  _ColorRule(
    hueMin: 60, hueMax: 150,
    satMin: 0.20, satMax: 1.0,
    valMin: 0.15, valMax: 1.0,
    category: 'Wet Waste', subcategory: 'Organic / Food Scraps',
    baseConfidence: 0.80,
  ),
  // Brown/yellow organic tones → Wet Waste
  _ColorRule(
    hueMin: 20, hueMax: 50,
    satMin: 0.15, satMax: 0.80,
    valMin: 0.10, valMax: 0.55,
    category: 'Wet Waste', subcategory: 'Garden Waste / Compost',
    baseConfidence: 0.75,
  ),
  // High-saturation multi-color packaging → Dry Waste
  _ColorRule(
    hueMin: 0, hueMax: 360,
    satMin: 0.50, satMax: 1.0,
    valMin: 0.60, valMax: 1.0,
    category: 'Dry Waste', subcategory: 'Packaging (multi-color)',
    baseConfidence: 0.65,
  ),
  // Near-white / clear → Dry Waste (glass/white plastic)
  _ColorRule(
    hueMin: 0, hueMax: 360,
    satMin: 0.0, satMax: 0.08,
    valMin: 0.90, valMax: 1.0,
    category: 'Dry Waste', subcategory: 'Glass / White Plastic',
    baseConfidence: 0.55,
  ),
  // Grey / metal tones → Dry Waste
  _ColorRule(
    hueMin: 0, hueMax: 360,
    satMin: 0.0, satMax: 0.10,
    valMin: 0.40, valMax: 0.70,
    category: 'Dry Waste', subcategory: 'Metal / Aluminium',
    baseConfidence: 0.55,
  ),
];

/// Internal result from isolate computation.
class _HistogramResult {
  _HistogramResult({
    this.category,
    this.subcategory,
    this.confidence = 0.0,
    this.processingTimeMs = 0,
    this.failureReason,
    this.dominantHue,
    this.dominantSat,
    this.dominantVal,
  });

  final String? category;
  final String? subcategory;
  final double confidence;
  final int processingTimeMs;
  final String? failureReason;
  final double? dominantHue;
  final double? dominantSat;
  final double? dominantVal;
}

/// Top-level isolate entry — required by [compute].
_HistogramResult _computeHistogramInIsolate(Uint8List imageBytes) {
  final sw = Stopwatch()..start();

  final image = img.decodeImage(imageBytes);
  if (image == null) {
    return _HistogramResult(failureReason: 'Failed to decode image');
  }

  // Downsample to 256px max dimension for speed.
  final resized = img.copyResize(image, width: 256, height: 256);

  // Accumulate HSV stats.
  var sumH = 0.0;
  var sumS = 0.0;
  var sumV = 0.0;
  var validPixels = 0;

  for (var y = 0; y < resized.height; y++) {
    for (var x = 0; x < resized.width; x++) {
      final pixel = resized.getPixelSafe(x, y);
      final r = pixel.r.toDouble();
      final g = pixel.g.toDouble();
      final b = pixel.b.toDouble();

      final hsv = _rgbToHsv(r, g, b);
      sumH += hsv[0];
      sumS += hsv[1];
      sumV += hsv[2];
      validPixels++;
    }
  }

  if (validPixels == 0) {
    return _HistogramResult(failureReason: 'No valid pixels');
  }

  final avgH = sumH / validPixels;
  final avgS = sumS / validPixels;
  final avgV = sumV / validPixels;

  // Compute peak dominance: how much the dominant hue bin exceeds the average.
  // Use 12 hue bins (30 degrees each).
  final hueBins = List.filled(12, 0);
  for (var y = 0; y < resized.height; y++) {
    for (var x = 0; x < resized.width; x++) {
      final pixel = resized.getPixelSafe(x, y);
      final hsv = _rgbToHsv(pixel.r.toDouble(), pixel.g.toDouble(), pixel.b.toDouble());
      final bin = (hsv[0] / 30).floor().clamp(0, 11);
      hueBins[bin]++;
    }
  }
  final sortedBins = List<int>.from(hueBins)..sort((a, b) => b - a);
  final peakDominance = sortedBins[0] / validPixels;
  final secondPeakRatio = sortedBins.length > 1 ? sortedBins[1] / validPixels : 0.0;

  // Match against color rules using average HSV.
  String? matchedCategory;
  String? matchedSubcategory;
  var baseConfidence = 0.0;

  for (final rule in _kColorRules) {
    if (rule.matches(avgH, avgS, avgV)) {
      matchedCategory = rule.category;
      matchedSubcategory = rule.subcategory;
      baseConfidence = rule.baseConfidence;
      break;
    }
  }

  sw.stop();

  if (matchedCategory == null) {
    return _HistogramResult(
      processingTimeMs: sw.elapsedMilliseconds,
      dominantHue: avgH,
      dominantSat: avgS,
      dominantVal: avgV,
    );
  }

  // Adjust confidence based on peak clarity.
  // Strong peak (>60%) boosts confidence; weak peak (<40%) penalises it.
  var clarityModifier = 0.0;
  if (peakDominance > 0.60) {
    clarityModifier = 0.10;
  } else if (peakDominance > 0.40) {
    clarityModifier = 0.0;
  } else {
    clarityModifier = -0.15;
  }

  // Penalise if second peak is close (image is mixed).
  if (secondPeakRatio > 0.25) {
    clarityModifier -= 0.05;
  }

  final confidence = (baseConfidence + clarityModifier).clamp(0.0, 0.99);

  return _HistogramResult(
    category: matchedCategory,
    subcategory: matchedSubcategory,
    confidence: confidence,
    processingTimeMs: sw.elapsedMilliseconds,
    dominantHue: avgH,
    dominantSat: avgS,
    dominantVal: avgV,
  );
}

/// Standard RGB (0.0-1.0) to HSV conversion.
/// Returns [hue (0-360), saturation (0-1), value (0-1)].
List<double> _rgbToHsv(double r, double g, double b) {
  final max = [r, g, b].reduce((a, b) => a > b ? a : b);
  final min = [r, g, b].reduce((a, b) => a < b ? a : b);
  final delta = max - min;

  double h;
  if (delta < 1e-6) {
    h = 0.0;
  } else if (max == r) {
    h = 60.0 * (((g - b) / delta) % 6);
  } else if (max == g) {
    h = 60.0 * (((b - r) / delta) + 2);
  } else {
    h = 60.0 * (((r - g) / delta) + 4);
  }
  if (h < 0) h += 360.0;

  final s = max < 1e-6 ? 0.0 : delta / max;
  return [h, s, max];
}

/// A [LocalClassifier] that uses HSV color histogram analysis to classify
/// waste items with visually unambiguous color profiles.
///
/// This is Layer 0 of the local-first cascade — zero AI, zero network,
/// zero cost. It handles items with clear color signatures (organic green/brown,
/// metallic grey, clear glass) by computing average HSV and peak dominance
/// on a downsampled image.
///
/// Runs computation in a background isolate via [compute] to avoid UI jank.
class ColorHistogramClassifier implements LocalClassifier {
  @override
  String get modelId => 'color_histogram_v1';

  @override
  String get modelVersion => '1.0.0';

  @override
  bool get isModelLoaded => true; // Pure computation — no model loading.

  @override
  Future<void> loadModel() async {
    // No-op: this classifier uses pure math, not a model file.
  }

  @override
  Future<void> unloadModel() async {
    // No-op.
  }

  @override
  Future<LocalClassificationResult> classify({
    required Uint8List imageBytes,
    required String region,
  }) async {
    final sw = Stopwatch()..start();

    try {
      _HistogramResult result;

      if (kIsWeb) {
        // Isolates not available on web — run synchronously.
        result = _computeHistogramInIsolate(imageBytes);
      } else {
        result = await compute(_computeHistogramInIsolate, imageBytes);
      }

      sw.stop();

      if (result.failureReason != null) {
        return LocalClassificationResult(
          category: 'Unknown',
          confidence: 0.0,
          shouldEscalateToCloud: true,
          modelVersion: modelVersion,
          processingTimeMs: sw.elapsedMilliseconds,
          failureReason: result.failureReason,
        );
      }

      return LocalClassificationResult(
        category: result.category ?? 'Unknown',
        subcategory: result.subcategory,
        confidence: result.confidence,
        shouldEscalateToCloud: result.confidence < 0.50,
        modelVersion: modelVersion,
        processingTimeMs: sw.elapsedMilliseconds,
      );
    } catch (e) {
      sw.stop();
      return LocalClassificationResult(
        category: 'Unknown',
        confidence: 0.0,
        shouldEscalateToCloud: true,
        modelVersion: modelVersion,
        processingTimeMs: sw.elapsedMilliseconds,
        failureReason: 'Color histogram error: $e',
      );
    }
  }
}
