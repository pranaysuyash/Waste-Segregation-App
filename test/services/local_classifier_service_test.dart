import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/services/local_classifier_service.dart';

void main() {
  group('LocalClassificationResult', () {
    test('requiresEscalation is false when confidence is high and not safety-sensitive', () {
      final result = LocalClassificationResult(
        category: 'Dry Waste',
        confidence: 0.92,
        modelVersion: '1.0.0-test',
      );
      expect(result.requiresEscalation, isFalse);
      expect(result.isSafetySensitive, isFalse);
    });

    test('requiresEscalation is true when confidence is below pass threshold', () {
      final result = LocalClassificationResult(
        category: 'Dry Waste',
        confidence: 0.60,
        modelVersion: '1.0.0-test',
      );
      expect(result.requiresEscalation, isTrue);
    });

    test('requiresEscalation is true when shouldEscalateToCloud is set', () {
      final result = LocalClassificationResult(
        category: 'Dry Waste',
        confidence: 0.95,
        shouldEscalateToCloud: true,
        modelVersion: '1.0.0-test',
      );
      expect(result.requiresEscalation, isTrue);
    });

    test('requiresEscalation is true when failureReason is non-null', () {
      final result = LocalClassificationResult(
        category: 'Dry Waste',
        confidence: 0.0,
        modelVersion: '1.0.0-test',
        failureReason: 'Model crashed',
      );
      expect(result.requiresEscalation, isTrue);
    });

    test('isSafetySensitive returns true for hazardous categories', () {
      final hazardous = LocalClassificationResult(
        category: 'Hazardous Waste',
        confidence: 0.80,
        modelVersion: '1.0.0-test',
      );
      expect(hazardous.isSafetySensitive, isTrue);
      expect(hazardous.requiresEscalation, isTrue);

      final medical = LocalClassificationResult(
        category: 'Medical Waste',
        confidence: 0.80,
        modelVersion: '1.0.0-test',
      );
      expect(medical.isSafetySensitive, isTrue);
      expect(medical.requiresEscalation, isTrue);
    });

    test('safety-sensitive category at very high confidence does not escalate', () {
      final result = LocalClassificationResult(
        category: 'Hazardous Waste',
        confidence: 0.95,
        modelVersion: '1.0.0-test',
      );
      expect(result.isSafetySensitive, isTrue);
      expect(result.requiresEscalation, isFalse);
    });

    test('e-waste and chemical waste are safety-sensitive', () {
      for (final cat in ['E-Waste', 'Electronic Waste', 'Chemical Waste', 'Sharps']) {
        final result = LocalClassificationResult(
          category: cat,
          confidence: 0.85,
          modelVersion: '1.0.0-test',
        );
        expect(result.isSafetySensitive, isTrue,
            reason: '$cat should be safety-sensitive');
        expect(result.requiresEscalation, isTrue,
            reason: '$cat at confidence 0.85 should escalate');
      }
    });

    test('unknown category always escalates regardless of confidence', () {
      final result = LocalClassificationResult(
        category: 'Unknown',
        confidence: 0.99,
        modelVersion: '1.0.0-test',
      );
      expect(result.isSafetySensitive, isFalse);
      expect(result.requiresEscalation, isTrue);
    });

    test('requires manual review always escalates', () {
      final result = LocalClassificationResult(
        category: 'Requires Manual Review',
        confidence: 0.99,
        modelVersion: '1.0.0-test',
      );
      expect(result.requiresEscalation, isTrue);
    });
  });

  group('FakeLocalClassifier', () {
    late FakeLocalClassifier fake;
    final dummyBytes = Uint8List.fromList([0, 1, 2, 3]);

    setUp(() {
      fake = FakeLocalClassifier();
    });

    test('default result has high confidence and does not escalate', () async {
      final result = await fake.classify(
        imageBytes: dummyBytes,
        region: 'Bangalore, IN',
      );
      expect(result.category, equals('Dry Waste'));
      expect(result.subCategory, equals('Plastic Bottle'));
      expect(result.confidence, greaterThan(0.90));
      expect(result.shouldEscalateToCloud, isFalse);
      expect(result.modelVersion, equals('1.0.0-test'));
      expect(result.processingTimeMs, equals(42));
    });

    test('classify uses stubbedResult when provided', () async {
      fake.stubbedResult = LocalClassificationResult(
        category: 'Wet Waste',
        subcategory: 'Food Scraps',
        confidence: 0.65,
        shouldEscalateToCloud: true,
        modelVersion: '1.0.0-test',
        processingTimeMs: 100,
      );
      final result = await fake.classify(
        imageBytes: dummyBytes,
        region: 'Bangalore, IN',
      );
      expect(result.category, equals('Wet Waste'));
      expect(result.confidence, equals(0.65));
      expect(result.shouldEscalateToCloud, isTrue);
    });

    test('classify throws when model is not loaded', () async {
      fake = FakeLocalClassifier(isModelLoaded: false);
      expect(
        () => fake.classify(imageBytes: dummyBytes, region: 'Bangalore, IN'),
        throwsA(isA<LocalClassifierException>()),
      );
    });

    test('classify throws when shouldThrowOnClassify is true', () async {
      fake.shouldThrowOnClassify = true;
      expect(
        () => fake.classify(imageBytes: dummyBytes, region: 'Bangalore, IN'),
        throwsA(isA<LocalClassifierException>()),
      );
    });

    test('loadModel succeeds by default', () async {
      fake = FakeLocalClassifier(isModelLoaded: false);
      expect(fake.isModelLoaded, isFalse);
      await fake.loadModel();
      expect(fake.isModelLoaded, isTrue);
    });

    test('loadModel throws when shouldThrowOnLoad is true', () async {
      fake = FakeLocalClassifier(shouldThrowOnLoad: true);
      expect(
        () => fake.loadModel(),
        throwsA(isA<LocalClassifierException>()),
      );
    });

    test('unloadModel sets isModelLoaded to false', () async {
      expect(fake.isModelLoaded, isTrue);
      await fake.unloadModel();
      expect(fake.isModelLoaded, isFalse);
    });

    test('stubbedShouldEscalate forces escalation flag', () async {
      fake.stubbedShouldEscalate = true;
      final result = await fake.classify(
        imageBytes: dummyBytes,
        region: 'Bangalore, IN',
      );
      expect(result.shouldEscalateToCloud, isTrue);
      expect(result.requiresEscalation, isTrue);
    });

    test('isModelLoaded reflects loadModel/unloadModel cycle', () async {
      fake = FakeLocalClassifier(isModelLoaded: false);
      expect(fake.isModelLoaded, isFalse);
      await fake.loadModel();
      expect(fake.isModelLoaded, isTrue);
      await fake.unloadModel();
      expect(fake.isModelLoaded, isFalse);
      await fake.loadModel();
      expect(fake.isModelLoaded, isTrue);
    });

    test('modelId and modelVersion are configurable', () {
      fake = FakeLocalClassifier(
        modelId: 'custom-model',
        modelVersion: '2.0.0-rc1',
      );
      expect(fake.modelId, equals('custom-model'));
      expect(fake.modelVersion, equals('2.0.0-rc1'));
    });
  });

  group('LocalClassifierThresholds', () {
    test('default values are set correctly', () {
      const thresholds = LocalClassifierThresholds();
      expect(thresholds.passThreshold, equals(0.75));
      expect(thresholds.escalateThreshold, equals(0.50));
      expect(thresholds.safetyOverrideThreshold, equals(0.90));
    });

    test('default static constants match constructor defaults', () {
      const defaults = LocalClassifierThresholds();
      expect(defaults.passThreshold, equals(0.75));
      expect(defaults.escalateThreshold, equals(0.50));
      expect(defaults.safetyOverrideThreshold, equals(0.90));
      expect(LocalClassifierThresholds.defaultPassThreshold, equals(0.75));
      expect(LocalClassifierThresholds.defaultEscalateThreshold, equals(0.50));
      expect(LocalClassifierThresholds.defaultSafetyOverrideThreshold, equals(0.90));
    });

    test('custom thresholds are accepted', () {
      const thresholds = LocalClassifierThresholds(
        passThreshold: 0.80,
        escalateThreshold: 0.40,
        safetyOverrideThreshold: 0.85,
      );
      expect(thresholds.passThreshold, equals(0.80));
      expect(thresholds.escalateThreshold, equals(0.40));
      expect(thresholds.safetyOverrideThreshold, equals(0.85));
    });
  });

  group('LocalClassifier abstract interface contract', () {
    test('can be implemented by a custom class', () {
      final impl = _MinimalClassifier();
      expect(impl.modelId, equals('minimal'));
      expect(impl.modelVersion, equals('0.0.1'));
      expect(impl.isModelLoaded, isFalse);
    });
  });
}

/// Minimal [LocalClassifier] implementation that exercises the interface.
class _MinimalClassifier implements LocalClassifier {
  @override
  String get modelId => 'minimal';

  @override
  String get modelVersion => '0.0.1';

  @override
  bool isModelLoaded = false;

  @override
  Future<void> loadModel() async {
    isModelLoaded = true;
  }

  @override
  Future<void> unloadModel() async {
    isModelLoaded = false;
  }

  @override
  Future<LocalClassificationResult> classify({
    required Uint8List imageBytes,
    required String region,
  }) async {
    return LocalClassificationResult(
      category: 'Dry Waste',
      confidence: 0.80,
      modelVersion: modelVersion,
    );
  }
}
