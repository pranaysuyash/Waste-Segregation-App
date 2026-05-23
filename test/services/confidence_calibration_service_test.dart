import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/services/confidence_calibration_service.dart';

void main() {
  group('ConfidenceCalibrationService', () {
    test('calibrate returns raw value when no bins loaded', () {
      final service = ConfidenceCalibrationService();
      expect(service.calibrate(0.85), equals(0.85));
      expect(service.calibrate(0.0), equals(0.0));
      expect(service.calibrate(1.0), equals(1.0));
    });

    test('calibrate returns empirical accuracy when bins loaded', () {
      final service = ConfidenceCalibrationService();
      service.updateBins([
        const CalibrationBin(
            rawLow: 0.8, rawHigh: 0.9, empiricalAccuracy: 0.72, sampleCount: 100),
        const CalibrationBin(
            rawLow: 0.9, rawHigh: 1.0, empiricalAccuracy: 0.89, sampleCount: 80),
      ]);

      expect(service.calibrate(0.85), equals(0.72));
      expect(service.calibrate(0.95), equals(0.89));
    });

    test('calibrate returns top bin accuracy for values above highest bin', () {
      final service = ConfidenceCalibrationService();
      service.updateBins([
        const CalibrationBin(
            rawLow: 0.8, rawHigh: 0.9, empiricalAccuracy: 0.72, sampleCount: 100),
      ]);

      expect(service.calibrate(0.95), equals(0.72));
    });

    test('decide accepts when confidence above threshold', () {
      final service = ConfidenceCalibrationService();
      final decision = service.decide(
        rawConfidence: 0.95,
        currentLayer: 0,
        category: 'Dry Waste',
      );

      expect(decision.action, equals(RoutingAction.accept));
      expect(decision.targetLayer, equals(0));
    });

    test('decide escalates when confidence below threshold', () {
      final service = ConfidenceCalibrationService();
      final decision = service.decide(
        rawConfidence: 0.50,
        currentLayer: 0,
        category: 'Dry Waste',
      );

      expect(decision.action, equals(RoutingAction.escalate));
      expect(decision.targetLayer, equals(1));
    });

    test('decide overrides safety-critical categories', () {
      final service = ConfidenceCalibrationService();
      final decision = service.decide(
        rawConfidence: 0.95,
        currentLayer: 0,
        category: 'Hazardous Waste',
      );

      expect(decision.action, equals(RoutingAction.override));
      expect(decision.targetLayer, equals(3));
    });

    test('decide overrides medical waste regardless of confidence', () {
      final service = ConfidenceCalibrationService();
      final decision = service.decide(
        rawConfidence: 0.99,
        currentLayer: 1,
        category: 'Medical Waste',
      );

      expect(decision.action, equals(RoutingAction.override));
      expect(decision.targetLayer, equals(3));
    });

    test('decide accepts on layer 3 regardless of confidence', () {
      final service = ConfidenceCalibrationService();
      final decision = service.decide(
        rawConfidence: 0.01,
        currentLayer: 3,
        category: 'Unknown',
      );

      expect(decision.action, equals(RoutingAction.accept));
    });

    test('hasCalibrationData reflects bin state', () {
      final service = ConfidenceCalibrationService();
      expect(service.hasCalibrationData, isFalse);

      service.updateBins([
        const CalibrationBin(
            rawLow: 0.0, rawHigh: 1.0, empiricalAccuracy: 0.8, sampleCount: 10),
      ]);
      expect(service.hasCalibrationData, isTrue);
    });
  });

  group('ConfidenceCalibrationService drift detection', () {
    test('detectDrift returns empty when no baseline set', () {
      final service = ConfidenceCalibrationService();
      service.updateBins([
        const CalibrationBin(
            rawLow: 0.8, rawHigh: 0.9, empiricalAccuracy: 0.72, sampleCount: 100),
      ]);
      expect(service.detectDrift(), isEmpty);
    });

    test('detectDrift returns empty when no bins loaded', () {
      final service = ConfidenceCalibrationService();
      // Set baseline via updateBins + setBaseline
      service.updateBins([
        const CalibrationBin(
            rawLow: 0.8, rawHigh: 0.9, empiricalAccuracy: 0.72, sampleCount: 100),
      ]);
      service.setBaseline();

      // Clear bins
      service.updateBins([]);
      expect(service.detectDrift(), isEmpty);
    });

    test('detectDrift identifies bins beyond 5% threshold', () {
      final service = ConfidenceCalibrationService();
      service.updateBins([
        const CalibrationBin(
            rawLow: 0.8, rawHigh: 0.9, empiricalAccuracy: 0.72, sampleCount: 100),
        const CalibrationBin(
            rawLow: 0.9, rawHigh: 1.0, empiricalAccuracy: 0.89, sampleCount: 80),
      ]);
      service.setBaseline();

      // Simulate drift: first bin drops from 0.72 to 0.60 (>5% drift)
      service.updateBins([
        const CalibrationBin(
            rawLow: 0.8, rawHigh: 0.9, empiricalAccuracy: 0.60, sampleCount: 120),
        const CalibrationBin(
            rawLow: 0.9, rawHigh: 1.0, empiricalAccuracy: 0.88, sampleCount: 90),
      ]);

      final drifts = service.detectDrift();
      expect(drifts.length, equals(1));
      expect(drifts.first.rawLow, equals(0.8));
      expect(drifts.first.delta, closeTo(-0.12, 0.001));
    });

    test('detectDrift respects custom threshold', () {
      final service = ConfidenceCalibrationService();
      service.updateBins([
        const CalibrationBin(
            rawLow: 0.8, rawHigh: 0.9, empiricalAccuracy: 0.72, sampleCount: 100),
      ]);
      service.setBaseline();

      // Drift of 3% — below default 5% but above 2%
      service.updateBins([
        const CalibrationBin(
            rawLow: 0.8, rawHigh: 0.9, empiricalAccuracy: 0.75, sampleCount: 110),
      ]);

      expect(service.detectDrift(), isEmpty); // 3% < 5% default
      expect(service.detectDrift(maxDrift: 0.02), isNotEmpty); // 3% > 2%
    });

    test('hasBaseline reflects baseline state', () {
      final service = ConfidenceCalibrationService();
      expect(service.hasBaseline, isFalse);

      service.updateBins([
        const CalibrationBin(
            rawLow: 0.0, rawHigh: 1.0, empiricalAccuracy: 0.8, sampleCount: 10),
      ]);
      service.setBaseline();
      expect(service.hasBaseline, isTrue);
    });
  });
}
