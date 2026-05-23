import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:waste_segregation_app/services/color_histogram_classifier.dart';
import 'package:waste_segregation_app/services/local_classifier_service.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Encode a solid-color 16×16 PNG for use as test image bytes.
///
/// We keep the image small so the test runs fast; [ColorHistogramClassifier]
/// immediately downsamples to 256 px anyway, so resolution doesn't affect
/// the HSV averages.
Uint8List _solidPng(int r, int g, int b) {
  final image = img.Image(width: 16, height: 16);
  img.fill(image, color: img.ColorRgb8(r, g, b));
  return Uint8List.fromList(img.encodePng(image));
}

/// A clearly invalid byte sequence (not a valid image format).
final Uint8List _invalidImageBytes = Uint8List.fromList([0, 1, 2, 3, 4, 5]);

/// Empty byte array.
final Uint8List _emptyBytes = Uint8List(0);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late ColorHistogramClassifier classifier;

  setUpAll(() async {
    // ColorHistogramClassifier is pure computation; loadModel is a no-op.
    classifier = ColorHistogramClassifier();
    await classifier.loadModel();
  });

  // -------------------------------------------------------------------------
  // Metadata
  // -------------------------------------------------------------------------

  group('ColorHistogramClassifier metadata', () {
    test('modelId is color_histogram_v1', () {
      expect(classifier.modelId, equals('color_histogram_v1'));
    });

    test('modelVersion is 1.0.0', () {
      expect(classifier.modelVersion, equals('1.0.0'));
    });

    test('isModelLoaded is true without calling loadModel', () {
      // Pure computation — always ready.
      final fresh = ColorHistogramClassifier();
      expect(fresh.isModelLoaded, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // Color → category mapping
  // -------------------------------------------------------------------------

  group('Green image → Wet Waste / Organic / Food Scraps', () {
    // R=0, G=200, B=0 → HSV ≈ (120°, 1.0, 0.78) — matches rule 1.
    late LocalClassificationResult result;

    setUpAll(() async {
      result = await classifier.classify(
        imageBytes: _solidPng(0, 200, 0),
        region: 'IN',
      );
    });

    test('category is Wet Waste', () {
      expect(result.category, equals('Wet Waste'));
    });

    test('subcategory is Organic / Food Scraps', () {
      expect(result.subcategory, equals('Organic / Food Scraps'));
    });

    test('confidence is high (solid image gets +0.10 clarity boost)', () {
      // baseConfidence=0.80, clarityModifier=+0.10 → 0.90
      expect(result.confidence, closeTo(0.90, 0.01));
    });

    test('does not escalate', () {
      expect(result.requiresEscalation, isFalse);
    });
  });

  group('Brown/earthy image → Wet Waste / Garden Waste / Compost', () {
    // R=130, G=90, B=40 → HSV ≈ (33°, 0.69, 0.51) — matches rule 2.
    late LocalClassificationResult result;

    setUpAll(() async {
      result = await classifier.classify(
        imageBytes: _solidPng(130, 90, 40),
        region: 'IN',
      );
    });

    test('category is Wet Waste', () {
      expect(result.category, equals('Wet Waste'));
    });

    test('subcategory is Garden Waste / Compost', () {
      expect(result.subcategory, equals('Garden Waste / Compost'));
    });

    test('confidence is high', () {
      // baseConfidence=0.75, clarityModifier=+0.10 → 0.85
      expect(result.confidence, closeTo(0.85, 0.01));
    });

    test('does not escalate', () {
      expect(result.requiresEscalation, isFalse);
    });
  });

  group('High-saturation bright-red image → Dry Waste / Packaging (multi-color)', () {
    // R=255, G=0, B=0 → HSV ≈ (0°, 1.0, 1.0) — matches rule 3.
    late LocalClassificationResult result;

    setUpAll(() async {
      result = await classifier.classify(
        imageBytes: _solidPng(255, 0, 0),
        region: 'IN',
      );
    });

    test('category is Dry Waste', () {
      expect(result.category, equals('Dry Waste'));
    });

    test('subcategory is Packaging (multi-color)', () {
      expect(result.subcategory, equals('Packaging (multi-color)'));
    });

    test('confidence after clarity boost is ≥ 0.70', () {
      // baseConfidence=0.65, clarityModifier=+0.10 → 0.75
      expect(result.confidence, greaterThanOrEqualTo(0.70));
    });
  });

  group('Near-white image → Dry Waste / Glass / White Plastic', () {
    // R=252, G=252, B=252 → HSV ≈ (0°, 0.0, 0.99) — matches rule 4.
    late LocalClassificationResult result;

    setUpAll(() async {
      result = await classifier.classify(
        imageBytes: _solidPng(252, 252, 252),
        region: 'IN',
      );
    });

    test('category is Dry Waste', () {
      expect(result.category, equals('Dry Waste'));
    });

    test('subcategory is Glass / White Plastic', () {
      expect(result.subcategory, equals('Glass / White Plastic'));
    });

    test('confidence reflects lower base (0.55 + 0.10 clarity)', () {
      expect(result.confidence, closeTo(0.65, 0.01));
    });

    test('requiresEscalation is true because confidence < defaultPassThreshold (0.75)', () {
      // 0.65 < 0.75 → requiresEscalation
      expect(result.requiresEscalation, isTrue);
    });
  });

  group('Medium-grey image → Dry Waste / Metal / Aluminium', () {
    // R=150, G=150, B=150 → HSV ≈ (0°, 0.0, 0.59) — matches rule 5.
    late LocalClassificationResult result;

    setUpAll(() async {
      result = await classifier.classify(
        imageBytes: _solidPng(150, 150, 150),
        region: 'IN',
      );
    });

    test('category is Dry Waste', () {
      expect(result.category, equals('Dry Waste'));
    });

    test('subcategory is Metal / Aluminium', () {
      expect(result.subcategory, equals('Metal / Aluminium'));
    });

    test('confidence is ≈ 0.65', () {
      // baseConfidence=0.55, clarityModifier=+0.10
      expect(result.confidence, closeTo(0.65, 0.01));
    });
  });

  group('Dark-grey image → no rule match → Unknown', () {
    // R=50, G=50, B=50 → HSV ≈ (0°, 0.0, 0.20) — below all rules.
    late LocalClassificationResult result;

    setUpAll(() async {
      result = await classifier.classify(
        imageBytes: _solidPng(50, 50, 50),
        region: 'IN',
      );
    });

    test('category is Unknown', () {
      expect(result.category, equals('Unknown'));
    });

    test('confidence is 0.0', () {
      expect(result.confidence, equals(0.0));
    });

    test('escalates because no match', () {
      expect(result.requiresEscalation, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // Error handling
  // -------------------------------------------------------------------------

  group('Error handling', () {
    test('invalid image bytes returns failure result, not exception', () async {
      final result = await classifier.classify(
        imageBytes: _invalidImageBytes,
        region: 'IN',
      );

      expect(result.category, equals('Unknown'));
      expect(result.confidence, equals(0.0));
      expect(result.shouldEscalateToCloud, isTrue);
      expect(result.failureReason, isNotNull);
    });

    test('empty image bytes returns failure result, not exception', () async {
      // The underlying compute call may either fail to decode or produce
      // a failureReason — either way the result must be safe to use.
      final result = await classifier.classify(
        imageBytes: _emptyBytes,
        region: 'IN',
      );

      // Must not throw. Confidence must be 0 or escalation must be set.
      expect(result.shouldEscalateToCloud || result.confidence == 0.0, isTrue);
    });

    test('processing time is reported (≥ 0 ms)', () async {
      final result = await classifier.classify(
        imageBytes: _solidPng(0, 200, 0),
        region: 'IN',
      );
      expect(result.processingTimeMs, greaterThanOrEqualTo(0));
    });
  });

  // -------------------------------------------------------------------------
  // Region independence
  // -------------------------------------------------------------------------

  group('Region parameter does not affect color matching', () {
    test('same image, different region, same category', () async {
      final bytes = _solidPng(0, 200, 0);
      final inResult =
          await classifier.classify(imageBytes: bytes, region: 'IN');
      final usResult =
          await classifier.classify(imageBytes: bytes, region: 'US');

      expect(inResult.category, equals(usResult.category));
      expect(inResult.subcategory, equals(usResult.subcategory));
      expect(inResult.confidence, closeTo(usResult.confidence, 0.001));
    });
  });

  // -------------------------------------------------------------------------
  // Lifecycle
  // -------------------------------------------------------------------------

  group('Lifecycle', () {
    test('unloadModel and loadModel are no-ops and do not throw', () async {
      final c = ColorHistogramClassifier();
      await expectLater(c.unloadModel(), completes);
      await expectLater(c.loadModel(), completes);
      expect(c.isModelLoaded, isTrue);
    });
  });
}
