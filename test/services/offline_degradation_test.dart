import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/services/barcode_lookup_service.dart';
import 'package:waste_segregation_app/services/classification_pipeline.dart';
import 'package:waste_segregation_app/services/layer0_router.dart';
import 'package:waste_segregation_app/services/local_classifier_service.dart';

void main() {
  late ClassificationPipeline pipeline;

  setUp(() {
    pipeline = ClassificationPipeline(
      layer0Router: _HintTestRouter(),
      localClassifier: _NoOpLocalClassifier(),
    );
  });

  group('ClassificationPipeline.tryLocalWithHint', () {
    test('returns accepted classification when Layer 0 accepts', () async {
      pipeline = ClassificationPipeline(
        layer0Router: _HintTestRouter(decision: Layer0Decision.accept),
        localClassifier: _NoOpLocalClassifier(),
      );

      final result = await pipeline.tryLocalWithHint(
        imageBytes: Uint8List.fromList([0, 1, 2, 3]),
        region: 'Bangalore, IN',
      );

      expect(result.accepted, isNotNull);
      expect(result.accepted!.category, equals('Dry Waste'));
      expect(result.accepted!.classificationLayer, equals('layer0_deterministic'));
      expect(result.layer0Result, isNotNull);
      expect(result.layer0Result!.decision, equals(Layer0Decision.accept));
    });

    test('returns layer0Result with hint when Layer 0 hints', () async {
      pipeline = ClassificationPipeline(
        layer0Router: _HintTestRouter(decision: Layer0Decision.hint),
        localClassifier: _NoOpLocalClassifier(),
      );

      final result = await pipeline.tryLocalWithHint(
        imageBytes: Uint8List.fromList([0, 1, 2, 3]),
        region: 'Bangalore, IN',
      );

      expect(result.accepted, isNull);
      expect(result.layer0Result, isNotNull);
      expect(result.layer0Result!.decision, equals(Layer0Decision.hint));
    });

    test('returns layer0Result with reject when Layer 0 rejects', () async {
      pipeline = ClassificationPipeline(
        layer0Router: _HintTestRouter(decision: Layer0Decision.reject),
        localClassifier: _NoOpLocalClassifier(),
      );

      final result = await pipeline.tryLocalWithHint(
        imageBytes: Uint8List.fromList([0, 1, 2, 3]),
        region: 'Bangalore, IN',
      );

      expect(result.accepted, isNull);
      expect(result.layer0Result, isNotNull);
      expect(result.layer0Result!.decision, equals(Layer0Decision.reject));
    });

    test('returns null layer0Result when Layer 0 throws', () async {
      pipeline = ClassificationPipeline(
        layer0Router: _HintTestRouter(shouldThrow: true),
        localClassifier: _NoOpLocalClassifier(),
      );

      final result = await pipeline.tryLocalWithHint(
        imageBytes: Uint8List.fromList([0, 1, 2, 3]),
        region: 'Bangalore, IN',
      );

      expect(result.accepted, isNull);
      expect(result.layer0Result, isNull);
    });

    test('escalate preserves layer0Result for inspection', () async {
      pipeline = ClassificationPipeline(
        layer0Router: _HintTestRouter(decision: Layer0Decision.escalate),
        localClassifier: _NoOpLocalClassifier(),
      );

      final result = await pipeline.tryLocalWithHint(
        imageBytes: Uint8List.fromList([0, 1, 2, 3]),
        region: 'Bangalore, IN',
      );

      expect(result.accepted, isNull);
      expect(result.layer0Result!.decision, equals(Layer0Decision.escalate));
      expect(result.layer0Result!.routeReason, equals('stub_escalate'));
    });
  });

  group('WasteClassification.isOfflineHint', () {
    test('defaults to false', () {
      final wc = WasteClassification(
        itemName: 'Test',
        category: 'Dry Waste',
        explanation: 'Test',
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Recycle',
          steps: ['Step 1'],
          hasUrgentTimeframe: false,
        ),
        region: 'Bangalore, IN',
        visualFeatures: [],
        alternatives: [],
      );

      expect(wc.isOfflineHint, isFalse);
    });

    test('can be set to true', () {
      final wc = WasteClassification(
        itemName: 'Test',
        category: 'Dry Waste',
        explanation: 'Test',
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Recycle',
          steps: ['Step 1'],
          hasUrgentTimeframe: false,
        ),
        region: 'Bangalore, IN',
        visualFeatures: [],
        alternatives: [],
        isOfflineHint: true,
      );

      expect(wc.isOfflineHint, isTrue);
    });

    test('preserved in copyWith', () {
      final wc = WasteClassification(
        itemName: 'Test',
        category: 'Dry Waste',
        explanation: 'Test',
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Recycle',
          steps: ['Step 1'],
          hasUrgentTimeframe: false,
        ),
        region: 'Bangalore, IN',
        visualFeatures: [],
        alternatives: [],
        isOfflineHint: true,
      );

      final copy = wc.copyWith(category: 'Wet Waste');
      expect(copy.isOfflineHint, isTrue);
      expect(copy.category, equals('Wet Waste'));
    });

    test('can be toggled in copyWith', () {
      final wc = WasteClassification(
        itemName: 'Test',
        category: 'Dry Waste',
        explanation: 'Test',
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Recycle',
          steps: ['Step 1'],
          hasUrgentTimeframe: false,
        ),
        region: 'Bangalore, IN',
        visualFeatures: [],
        alternatives: [],
        isOfflineHint: true,
      );

      final copy = wc.copyWith(isOfflineHint: false);
      expect(copy.isOfflineHint, isFalse);
    });

    test('serialized and deserialized from JSON', () {
      final wc = WasteClassification(
        itemName: 'Test',
        category: 'Dry Waste',
        explanation: 'Test',
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Recycle',
          steps: ['Step 1'],
          hasUrgentTimeframe: false,
        ),
        region: 'Bangalore, IN',
        visualFeatures: [],
        alternatives: [],
        isOfflineHint: true,
      );

      final json = wc.toJson();
      expect(json['isOfflineHint'], isTrue);

      final restored = WasteClassification.fromJson(json);
      expect(restored.isOfflineHint, isTrue);
    });
  });
}

/// Test router that returns a configurable decision with classification data.
class _HintTestRouter extends Layer0Router {
  _HintTestRouter({
    this.decision = Layer0Decision.reject,
    this.shouldThrow = false,
  }) : super(
          colorClassifier: _NoOpLocalClassifier(),
          barcodeService: _NoOpBarcodeService(),
        );

  final Layer0Decision decision;
  final bool shouldThrow;

  @override
  Future<Layer0Result> classify({
    Uint8List? imageBytes,
    String? barcode,
    required String region,
  }) async {
    if (shouldThrow) throw Exception('Router error');

    WasteClassification? wc;
    if (decision == Layer0Decision.accept) {
      wc = WasteClassification(
        itemName: 'Plastic Bottle',
        category: 'Dry Waste',
        explanation: 'Layer 0 accepted',
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Recycle',
          steps: ['Step 1'],
          hasUrgentTimeframe: false,
        ),
        region: region,
        visualFeatures: [],
        alternatives: [],
        confidence: 0.95,
        modelSource: 'layer0_deterministic',
        source: 'test',
      );
    }

    return Layer0Result(
      decision: decision,
      wasteClassification: wc,
      totalProcessingTimeMs: 10,
      routeReason: 'stub_${decision.name}',
      classificationResult: LocalClassificationResult(
        category: 'Dry Waste',
        subCategory: 'Plastic Bottle',
        confidence: decision == Layer0Decision.accept ? 0.95 : 0.65,
        modelVersion: 'color_histogram_v1',
      ),
    );
  }
}

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

class _NoOpBarcodeService implements BarcodeLookupService {
  @override
  Future<BarcodeLookupResult> lookup(
    String barcode, {
    String region = 'IN',
  }) async {
    return BarcodeLookupResult(found: false);
  }
}
