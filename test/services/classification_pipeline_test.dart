import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/services/barcode_lookup_service.dart';
import 'package:waste_segregation_app/services/classification_pipeline.dart';
import 'package:waste_segregation_app/services/layer0_router.dart';
import 'package:waste_segregation_app/services/local_classifier_service.dart';

void main() {
  late ClassificationPipeline pipeline;
  late StubLayer0Router layer0Router;
  late FakeLocalClassifier localClassifier;
  final dummyBytes = Uint8List.fromList([0, 1, 2, 3]);

  setUp(() {
    layer0Router = StubLayer0Router();
    localClassifier = FakeLocalClassifier(isModelLoaded: false);
    pipeline = ClassificationPipeline(
      layer0Router: layer0Router,
      localClassifier: localClassifier,
    );
  });

  group('ClassificationPipeline.tryLocalOnly', () {
    test('returns L0 result when Layer 0 accepts', () async {
      layer0Router.stubbedDecision = Layer0Decision.accept;
      layer0Router.stubbedWasteClassification = WasteClassification(
        itemName: 'Plastic Bottle',
        category: 'Dry Waste',
        explanation: 'Layer 0 test',
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Recycle',
          steps: ['Step 1'],
          hasUrgentTimeframe: false,
        ),
        region: 'Bangalore, IN',
        visualFeatures: [],
        alternatives: [],
        confidence: 0.95,
        modelSource: 'layer0_deterministic',
        source: 'barcode:test',
      );

      final result = await pipeline.tryLocalOnly(
        imageBytes: dummyBytes,
        region: 'Bangalore, IN',
      );

      expect(result, isNotNull);
      expect(result!.category, equals('Dry Waste'));
      expect(result.classificationLayer, equals('layer0_deterministic'));
      expect(result.modelSource, equals('layer0_deterministic'));
    });

    test('returns Layer 1 result when Layer 0 rejects and Layer 1 accepts',
        () async {
      layer0Router.stubbedDecision = Layer0Decision.reject;
      localClassifier = FakeLocalClassifier(
        isModelLoaded: true,
        stubbedResult: LocalClassificationResult(
          category: 'Wet Waste',
          subcategory: 'Food Scraps',
          confidence: 0.92,
          modelVersion: 'test-model-v1',
          processingTimeMs: 50,
        ),
      );
      pipeline = ClassificationPipeline(
        layer0Router: layer0Router,
        localClassifier: localClassifier,
      );

      final result = await pipeline.tryLocalOnly(
        imageBytes: dummyBytes,
        region: 'Bangalore, IN',
      );

      expect(result, isNotNull);
      expect(result!.category, equals('Wet Waste'));
      expect(result.classificationLayer, equals('layer1_on_device'));
      expect(result.modelSource, equals('layer1_on_device'));
      expect(result.modelVersion, equals('test-model-v1'));
    });

    test('returns null when Layer 0 rejects and Layer 1 is not loaded',
        () async {
      layer0Router.stubbedDecision = Layer0Decision.reject;
      localClassifier = FakeLocalClassifier(isModelLoaded: false);

      final result = await pipeline.tryLocalOnly(
        imageBytes: dummyBytes,
        region: 'Bangalore, IN',
      );

      expect(result, isNull);
    });

    test('returns null when Layer 0 rejects and Layer 1 escalates', () async {
      layer0Router.stubbedDecision = Layer0Decision.reject;
      localClassifier = FakeLocalClassifier(
        isModelLoaded: true,
        stubbedResult: LocalClassificationResult(
          category: 'Dry Waste',
          confidence: 0.40,
          modelVersion: 'test-model-v1',
        ),
      );

      final result = await pipeline.tryLocalOnly(
        imageBytes: dummyBytes,
        region: 'Bangalore, IN',
      );

      expect(result, isNull);
    });

    test('returns null when Layer 1 throws', () async {
      layer0Router.stubbedDecision = Layer0Decision.reject;
      localClassifier = FakeLocalClassifier(
        isModelLoaded: true,
        shouldThrowOnClassify: true,
      );

      final result = await pipeline.tryLocalOnly(
        imageBytes: dummyBytes,
        region: 'Bangalore, IN',
      );

      expect(result, isNull);
    });

    test('returns null when Layer 0 throws', () async {
      layer0Router.shouldThrow = true;
      localClassifier = FakeLocalClassifier(isModelLoaded: false);

      final result = await pipeline.tryLocalOnly(
        imageBytes: dummyBytes,
        region: 'Bangalore, IN',
      );

      expect(result, isNull);
    });

    test('safety-sensitive category from Layer 0 escalates', () async {
      layer0Router.stubbedDecision = Layer0Decision.escalate;

      final result = await pipeline.tryLocalOnly(
        imageBytes: dummyBytes,
        region: 'Bangalore, IN',
      );

      expect(result, isNull);
    });

    test('hint from Layer 0 falls through to Layer 1', () async {
      layer0Router.stubbedDecision = Layer0Decision.hint;
      localClassifier = FakeLocalClassifier(isModelLoaded: false);

      final result = await pipeline.tryLocalOnly(
        imageBytes: dummyBytes,
        region: 'Bangalore, IN',
      );

      expect(result, isNull);
    });
  });

  group('ClassificationPipeline.classify (full pipeline with cloud)', () {
    test('calls cloud classifier when local layers all fail', () async {
      layer0Router.stubbedDecision = Layer0Decision.reject;
      localClassifier = FakeLocalClassifier(isModelLoaded: false);

      var cloudCalled = false;
      final result = await pipeline.classify(
        imageBytes: dummyBytes,
        region: 'Bangalore, IN',
        cloudClassifier: ({
          required Uint8List imageBytes,
          required String imageName,
          required String region,
          required String language,
        }) async {
          cloudCalled = true;
          return WasteClassification(
            itemName: 'Cloud Item',
            category: 'Dry Waste',
            explanation: 'Cloud classification',
            disposalInstructions: DisposalInstructions(
              primaryMethod: 'Dispose',
              steps: ['Step 1'],
              hasUrgentTimeframe: false,
            ),
            region: region,
            visualFeatures: [],
            alternatives: [],
            confidence: 0.85,
            modelSource: 'openai',
          );
        },
      );

      expect(result.category, equals('Dry Waste'));
      expect(result.classificationLayer, equals('layer2_cloud_cheap'));
      expect(cloudCalled, isTrue);
    });

    test('does NOT call cloud classifier when Layer 0 accepts', () async {
      layer0Router.stubbedDecision = Layer0Decision.accept;
      layer0Router.stubbedWasteClassification = WasteClassification(
        itemName: 'Bottle',
        category: 'Dry Waste',
        explanation: 'L0',
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Recycle',
          steps: ['Step 1'],
          hasUrgentTimeframe: false,
        ),
        region: 'Bangalore, IN',
        visualFeatures: [],
        alternatives: [],
        confidence: 0.95,
      );

      var cloudCalled = false;
      final result = await pipeline.classify(
        imageBytes: dummyBytes,
        region: 'Bangalore, IN',
        cloudClassifier: ({
          required Uint8List imageBytes,
          required String imageName,
          required String region,
          required String language,
        }) async {
          cloudCalled = true;
          return WasteClassification.fallback('test');
        },
      );

      expect(result.category, equals('Dry Waste'));
      expect(cloudCalled, isFalse);
    });

    test('does NOT call cloud classifier when Layer 1 accepts', () async {
      layer0Router.stubbedDecision = Layer0Decision.reject;
      localClassifier = FakeLocalClassifier(
        isModelLoaded: true,
        stubbedResult: LocalClassificationResult(
          category: 'Wet Waste',
          confidence: 0.88,
          modelVersion: 'test-v1',
        ),
      );
      pipeline = ClassificationPipeline(
        layer0Router: layer0Router,
        localClassifier: localClassifier,
      );

      var cloudCalled = false;
      final result = await pipeline.classify(
        imageBytes: dummyBytes,
        region: 'Bangalore, IN',
        cloudClassifier: ({
          required Uint8List imageBytes,
          required String imageName,
          required String region,
          required String language,
        }) async {
          cloudCalled = true;
          return WasteClassification.fallback('test');
        },
      );

      expect(result.category, equals('Wet Waste'));
      expect(cloudCalled, isFalse);
    });
  });

  group('ClassificationPipeline.buildLocalClassification', () {
    test('builds a WasteClassification from a LocalClassificationResult',
        () async {
      final localResult = LocalClassificationResult(
        category: 'Dry Waste',
        subcategory: 'Plastic Bottle',
        confidence: 0.92,
        modelVersion: 'mobilenet_v3_v1',
        processingTimeMs: 42,
      );

      final wc = pipeline.buildLocalClassification(
        localResult: localResult,
        region: 'Bangalore, IN',
      );

      expect(wc.itemName, equals('Plastic Bottle'));
      expect(wc.category, equals('Dry Waste'));
      expect(wc.subcategory, equals('Plastic Bottle'));
      expect(wc.confidence, equals(0.92));
      expect(wc.modelSource, equals('layer1_on_device'));
      expect(wc.modelVersion, equals('mobilenet_v3_v1'));
      expect(wc.classificationLayer, equals('layer1_on_device'));
      expect(wc.source, equals('layer1_on_device'));
      expect(wc.region, equals('Bangalore, IN'));
    });

    test('uses category as itemName when no subcategory', () async {
      final localResult = LocalClassificationResult(
        category: 'Wet Waste',
        confidence: 0.85,
        modelVersion: 'v1',
      );

      final wc = pipeline.buildLocalClassification(
        localResult: localResult,
        region: 'Bangalore, IN',
      );

      expect(wc.itemName, equals('Wet Waste'));
      expect(wc.category, equals('Wet Waste'));
      expect(wc.subcategory, isNull);
    });
  });
}

/// Stub implementation of [Layer0Router] for testing.
class StubLayer0Router extends Layer0Router {
  StubLayer0Router({
    this.stubbedDecision = Layer0Decision.reject,
    this.stubbedWasteClassification,
    this.shouldThrow = false,
  }) : super(
          colorClassifier: _NoOpLocalClassifier(),
          barcodeService: StubBarcodeLookupService(),
        );

  Layer0Decision stubbedDecision;
  WasteClassification? stubbedWasteClassification;
  bool shouldThrow;

  @override
  Future<Layer0Result> classify({
    Uint8List? imageBytes,
    String? barcode,
    required String region,
  }) async {
    if (shouldThrow) {
      throw Exception('Stub Layer0Router error');
    }
    return Layer0Result(
      decision: stubbedDecision,
      wasteClassification: stubbedWasteClassification,
      totalProcessingTimeMs: 10,
      routeReason: 'stub_${stubbedDecision.name}',
    );
  }
}

/// Stub for [BarcodeLookupService] required by [Layer0Router] constructor.
class StubBarcodeLookupService implements BarcodeLookupService {
  @override
  Future<BarcodeLookupResult> lookup(
    String barcode, {
    String region = 'IN',
  }) async {
    return BarcodeLookupResult(found: false);
  }
}

/// No-op [LocalClassifier] for stubbing the Layer0Router constructor.
class _NoOpLocalClassifier implements LocalClassifier {
  @override
  String get modelId => 'noop';

  @override
  String get modelVersion => 'noop';

  @override
  bool get isModelLoaded => false;

  @override
  Future<LocalClassificationResult> classify({
    required Uint8List imageBytes,
    required String region,
  }) async {
    return LocalClassificationResult(
      category: 'Unknown',
      confidence: 0.0,
      modelVersion: 'noop',
    );
  }

  @override
  Future<void> loadModel() async {}

  @override
  Future<void> unloadModel() async {}
}
