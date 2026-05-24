import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/services/barcode_lookup_service.dart';
import 'package:waste_segregation_app/services/layer0_router.dart';
import 'package:waste_segregation_app/services/local_classifier_service.dart';

void main() {
  late Layer0Router router;

  setUp(() {
    router = Layer0Router(
      colorClassifier: _StubColorClassifier(),
      barcodeService: _StubBarcodeService(),
    );
  });

  group('Layer0Router barcode path', () {
    test('accepts when barcode returns high-confidence non-safety result',
        () async {
      router = Layer0Router(
        colorClassifier: _StubColorClassifier(),
        barcodeService: _StubBarcodeService(
          barcodeResult: BarcodeLookupResult(
            found: true,
            category: 'Dry Waste',
            subCategory: 'Plastic Bottle',
            confidence: 0.95,
            productName: 'Coke 500ml',
            brand: 'Coca-Cola',
          ),
        ),
      );

      final result = await router.classify(
        barcode: '8901234567890',
        region: 'Bangalore, IN',
      );

      expect(result.decision, equals(Layer0Decision.accept));
      expect(result.routeReason, equals('barcode_accept'));
      expect(result.wasteClassification, isNotNull);
      expect(result.wasteClassification!.category, equals('Dry Waste'));
      expect(result.wasteClassification!.itemName, equals('Coke 500ml'));
      expect(result.wasteClassification!.brand, equals('Coca-Cola'));
    });

    test('escalates when barcode identifies safety category', () async {
      router = Layer0Router(
        colorClassifier: _StubColorClassifier(),
        barcodeService: _StubBarcodeService(
          barcodeResult: BarcodeLookupResult(
            found: true,
            category: 'Hazardous Waste',
            confidence: 0.95,
          ),
        ),
      );

      final result = await router.classify(
        barcode: '8901234567890',
        region: 'Bangalore, IN',
      );

      expect(result.decision, equals(Layer0Decision.escalate));
      expect(result.routeReason, equals('barcode_safety_escalate'));
    });

    test('hints when barcode confidence is between hint and accept thresholds',
        () async {
      router = Layer0Router(
        colorClassifier: _RejectingColorClassifier(),
        barcodeService: _StubBarcodeService(
          barcodeResult: BarcodeLookupResult(
            found: true,
            category: 'Dry Waste',
            confidence: 0.70,
          ),
        ),
      );

      final result = await router.classify(
        barcode: '8901234567890',
        region: 'Bangalore, IN',
      );

      expect(result.decision, equals(Layer0Decision.hint));
      expect(result.routeReason, equals('barcode_hint'));
    });

    test('falls through to color when barcode not found', () async {
      router = Layer0Router(
        colorClassifier: _StubColorClassifier(
          result: LocalClassificationResult(
            category: 'Wet Waste',
            subCategory: 'Organic / Food Scraps',
            confidence: 0.92,
            modelVersion: 'color_histogram_v1',
          ),
        ),
        barcodeService: _StubBarcodeService(
          barcodeResult: BarcodeLookupResult(found: false),
        ),
      );

      final result = await router.classify(
        barcode: '8901234567890',
        imageBytes: Uint8List.fromList([0, 1, 2, 3]),
        region: 'Bangalore, IN',
      );

      expect(result.decision, equals(Layer0Decision.accept));
      expect(result.routeReason, equals('color_accept'));
    });
  });

  group('Layer0Router color histogram path', () {
    test('accepts when color classifier returns high confidence', () async {
      router = Layer0Router(
        colorClassifier: _StubColorClassifier(
          result: LocalClassificationResult(
            category: 'Wet Waste',
            subCategory: 'Organic / Food Scraps',
            confidence: 0.92,
            modelVersion: 'color_histogram_v1',
          ),
        ),
        barcodeService: _StubBarcodeService(),
      );

      final result = await router.classify(
        imageBytes: Uint8List.fromList([0, 1, 2, 3]),
        region: 'Bangalore, IN',
      );

      expect(result.decision, equals(Layer0Decision.accept));
      expect(result.wasteClassification, isNotNull);
      expect(result.wasteClassification!.category, equals('Wet Waste'));
      expect(result.wasteClassification!.modelSource,
          equals('layer0_deterministic'));
    });

    test('hints when color confidence is between thresholds', () async {
      router = Layer0Router(
        colorClassifier: _StubColorClassifier(
          result: LocalClassificationResult(
            category: 'Dry Waste',
            confidence: 0.80,
            modelVersion: 'color_histogram_v1',
          ),
        ),
        barcodeService: _StubBarcodeService(),
      );

      final result = await router.classify(
        imageBytes: Uint8List.fromList([0, 1, 2, 3]),
        region: 'Bangalore, IN',
      );

      expect(result.decision, equals(Layer0Decision.hint));
      expect(result.routeReason, equals('color_hint'));
    });

    test('rejects when color confidence is below hint threshold', () async {
      router = Layer0Router(
        colorClassifier: _StubColorClassifier(
          result: LocalClassificationResult(
            category: 'Dry Waste',
            confidence: 0.30,
            modelVersion: 'color_histogram_v1',
          ),
        ),
        barcodeService: _StubBarcodeService(),
      );

      final result = await router.classify(
        imageBytes: Uint8List.fromList([0, 1, 2, 3]),
        region: 'Bangalore, IN',
      );

      expect(result.decision, equals(Layer0Decision.reject));
    });
  });

  group('Layer0Router fallback', () {
    test('rejects when neither barcode nor color produces a result', () async {
      router = Layer0Router(
        colorClassifier: _RejectingColorClassifier(),
        barcodeService: _StubBarcodeService(
          barcodeResult: BarcodeLookupResult(found: false),
        ),
      );

      final result = await router.classify(
        region: 'Bangalore, IN',
      );

      expect(result.decision, equals(Layer0Decision.reject));
      expect(result.routeReason, equals('no_path_accepted'));
    });

    test('rejects when no barcode and no image provided', () async {
      final result = await router.classify(region: 'Bangalore, IN');

      expect(result.decision, equals(Layer0Decision.reject));
    });

    test('rejects when color classifier throws', () async {
      router = Layer0Router(
        colorClassifier: _ThrowingColorClassifier(),
        barcodeService: _StubBarcodeService(),
      );

      final result = await router.classify(
        imageBytes: Uint8List.fromList([0, 1, 2, 3]),
        region: 'Bangalore, IN',
      );

      expect(result.decision, equals(Layer0Decision.reject));
    });
  });

  group('Layer0Router safety categories', () {
    for (final category in [
      'Hazardous Waste',
      'Medical Waste',
      'E-Waste',
      'Chemical Waste',
      'Pharmaceutical Waste',
    ]) {
      test('escalates barcode-identified $category', () async {
        router = Layer0Router(
          colorClassifier: _RejectingColorClassifier(),
          barcodeService: _StubBarcodeService(
            barcodeResult: BarcodeLookupResult(
              found: true,
              category: category,
              confidence: 0.95,
            ),
          ),
        );

        final result = await router.classify(
          barcode: '12345678',
          region: 'Bangalore, IN',
        );

        expect(result.decision, equals(Layer0Decision.escalate));
      });
    }
  });
}

class _StubColorClassifier implements LocalClassifier {
  _StubColorClassifier({LocalClassificationResult? result})
      : _result = result ??
            LocalClassificationResult(
              category: 'Wet Waste',
              confidence: 0.92,
              modelVersion: 'color_histogram_v1',
            );

  final LocalClassificationResult _result;

  @override
  Future<LocalClassificationResult> classify({
    required Uint8List imageBytes,
    required String region,
  }) async {
    if (_result.confidence < 0.40) {
      return LocalClassificationResult(
        category: _result.category,
        confidence: _result.confidence,
        modelVersion: _result.modelVersion,
        failureReason: 'Low confidence',
      );
    }
    return _result;
  }

  @override
  String get modelId => 'color_histogram_v1';

  @override
  String get modelVersion => 'color_histogram_v1';

  @override
  bool get isModelLoaded => true;

  @override
  Future<void> loadModel() async {}

  @override
  Future<void> unloadModel() async {}
}

class _RejectingColorClassifier implements LocalClassifier {
  @override
  Future<LocalClassificationResult> classify({
    required Uint8List imageBytes,
    required String region,
  }) async {
    return LocalClassificationResult(
      category: 'Unknown',
      confidence: 0.10,
      modelVersion: 'color_histogram_v1',
      failureReason: 'Could not classify',
    );
  }

  @override
  String get modelId => 'color_histogram_v1';

  @override
  String get modelVersion => 'color_histogram_v1';

  @override
  bool get isModelLoaded => true;

  @override
  Future<void> loadModel() async {}

  @override
  Future<void> unloadModel() async {}
}

class _ThrowingColorClassifier implements LocalClassifier {
  @override
  Future<LocalClassificationResult> classify({
    required Uint8List imageBytes,
    required String region,
  }) async {
    throw Exception('Color classifier crash');
  }

  @override
  String get modelId => 'color_histogram_v1';

  @override
  String get modelVersion => 'color_histogram_v1';

  @override
  bool get isModelLoaded => true;

  @override
  Future<void> loadModel() async {}

  @override
  Future<void> unloadModel() async {}
}

class _StubBarcodeService implements BarcodeLookupService {
  _StubBarcodeService({BarcodeLookupResult? barcodeResult})
      : _barcodeResult =
            barcodeResult ?? BarcodeLookupResult(found: false);

  final BarcodeLookupResult _barcodeResult;

  @override
  Future<BarcodeLookupResult> lookup(
    String barcode, {
    String region = 'IN',
  }) async {
    return _barcodeResult;
  }
}
