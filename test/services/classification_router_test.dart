import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/services/classification_router.dart';

void main() {
  group('ClassificationRouter', () {
    test('initialLayer returns 0 by default', () {
      final router = ClassificationRouter();
      expect(router.initialLayer(), equals(0));
    });

    test('initialLayer returns 0 even for safety categories', () {
      final router = ClassificationRouter();
      expect(router.initialLayer(category: 'Hazardous Waste'), equals(0));
    });

    test('decide with barcode suggests Layer 0', () {
      final router = ClassificationRouter();
      final result = router.decideInitial(
        imageBytes: Uint8List(10),
        barcode: '1234567890',
      );

      expect(result.targetLayer, equals(0));
      expect(result.reason, contains('Barcode'));
    });

    test('decideInitial without barcode still starts at Layer 0', () {
      final router = ClassificationRouter();
      final result = router.decideInitial(imageBytes: Uint8List(10));

      expect(result.targetLayer, equals(0));
    });

    test('costFirst strategy does not escalate beyond calibration', () {
      final router =
          ClassificationRouter(strategy: RoutingStrategy.costFirst);
      final result = router.decide(
        rawConfidence: 0.50,
        currentLayer: 0,
        category: 'Dry Waste',
      );

      // Cost-first keeps the calibration's target, doesn't add extra escalation
      expect(result.targetLayer, equals(1));
    });

    test('qualityFirst strategy accepts high confidence at layer 0', () {
      final router =
          ClassificationRouter(strategy: RoutingStrategy.qualityFirst);
      final result = router.decide(
        rawConfidence: 0.95,
        currentLayer: 0,
        category: 'Dry Waste',
      );

      // 0.95 >= 0.90 threshold for layer 0 → accepted
      expect(result.targetLayer, equals(0));
    });

    test('logDecision does not throw', () {
      final router = ClassificationRouter();
      final result = router.decide(
        rawConfidence: 0.85,
        currentLayer: 0,
        category: 'Wet Waste',
      );

      expect(() => router.logDecision(result), returnsNormally);
    });

    test('decide handles safety override for e-waste at layer 0', () {
      final router = ClassificationRouter();
      final result = router.decide(
        rawConfidence: 0.99,
        currentLayer: 0,
        category: 'E-Waste',
      );

      expect(result.targetLayer, equals(2));
    });
  });
}
