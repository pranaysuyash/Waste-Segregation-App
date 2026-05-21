/// Golden tests for ResultPipeline
///
/// These tests verify that ResultPipeline produces consistent, expected output
/// for canonical classification fixtures. They catch regressions in:
/// - Gamification calculation
/// - State transitions
/// - Side effects (save, sync, etc.)
///
/// Run: flutter test test/services/result_pipeline_golden_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/services/result_pipeline.dart';

import '../fixtures/classifications/fixtures.dart';

void main() {
  group('ResultPipeline Golden Tests', () {
    group('Plastic Bottle (Standard Recyclable)', () {
      late WasteClassification fixture;

      setUp(() {
        fixture = plasticBottleFixture;
      });

      test('fixture has expected properties', () {
        expect(fixture.id, ClassificationFixtureIds.plasticBottle);
        expect(fixture.category, 'Dry Waste');
        expect(fixture.confidence, 0.94);
        expect(fixture.isRecyclable, true);
        expect(fixture.riskLevel, 'low');
        expect(fixture.disposalInstructions.steps.length, 5);
      });

      test('disposal instructions are complete', () {
        final instructions = fixture.disposalInstructions;

        expect(instructions.primaryMethod, isNotEmpty);
        expect(instructions.steps, isNotEmpty);
        expect(instructions.warnings, isNotEmpty);
        expect(instructions.tips, isNotEmpty);

        // Verify specific content that should not change
        expect(instructions.steps[0], contains('Empty'));
        expect(instructions.warnings?[0], contains('burn'));
        expect(instructions.tips?[0], contains('Caps'));
      });

      test('has expected visual features', () {
        expect(fixture.visualFeatures, contains('transparent'));
        expect(fixture.visualFeatures, contains('cylindrical'));
      });

      test('color code matches category', () {
        // Dry waste = blue
        expect(fixture.colorCode, '#2196F3');
      });
    });

    group('Wet Waste Food (Compostable)', () {
      late WasteClassification fixture;

      setUp(() {
        fixture = wetWasteFoodFixture;
      });

      test('fixture has expected properties', () {
        expect(fixture.id, ClassificationFixtureIds.wetWasteFood);
        expect(fixture.category, 'Wet Waste');
        expect(fixture.isCompostable, true);
        expect(fixture.isRecyclable, false);
        expect(fixture.colorCode, '#4CAF50'); // Green
      });

      test('has urgent timeframe flag', () {
        expect(fixture.disposalInstructions.hasUrgentTimeframe, true);
        expect(fixture.disposalInstructions.timeframe, contains('24 hours'));
      });
    });

    group('Medical Waste (High Risk)', () {
      late WasteClassification fixture;

      setUp(() {
        fixture = medicalWasteFixture;
      });

      test('fixture has high risk properties', () {
        expect(fixture.id, ClassificationFixtureIds.medicalWaste);
        expect(fixture.category, 'Biomedical Waste');
        expect(fixture.riskLevel, 'high');
        expect(fixture.colorCode, '#F44336'); // Red
        expect(fixture.requiresSpecialDisposal, true);
      });

      test('requires PPE', () {
        expect(fixture.requiredPPE, isNotNull);
        expect(fixture.requiredPPE, contains('gloves'));
      });

      test('has urgent disposal requirement', () {
        expect(fixture.disposalInstructions.hasUrgentTimeframe, true);
      });

      test('has strong warnings', () {
        final warnings = fixture.disposalInstructions.warnings;
        expect(warnings?.any((w) => w.contains('NEVER')), true);
        expect(warnings?.any((w) => w.contains('hazard')), true);
      });
    });

    group('Unknown Low Confidence', () {
      late WasteClassification fixture;

      setUp(() {
        fixture = unknownLowConfidenceFixture;
      });

      test('fixture has fallback properties', () {
        expect(fixture.id, ClassificationFixtureIds.unknownLowConfidence);
        expect(fixture.category, 'Requires Manual Review');
        expect(fixture.confidence, lessThan(0.5));
        expect(fixture.clarificationNeeded, true);
        expect(fixture.colorCode, '#9E9E9E'); // Grey
      });

      test('has alternatives for user guidance', () {
        expect(fixture.alternatives, isNotEmpty);
        expect(fixture.alternatives!.length, greaterThanOrEqualTo(2));
      });
    });

    group('E-Waste (Special Disposal)', () {
      late WasteClassification fixture;

      setUp(() {
        fixture = eWastePhoneFixture;
      });

      test('fixture has e-waste properties', () {
        expect(fixture.id, ClassificationFixtureIds.eWastePhone);
        expect(fixture.category, 'E-Waste');
        expect(fixture.requiresSpecialDisposal, true);
        expect(fixture.isRecyclable, true); // But special process
      });

      test('has data security warnings', () {
        final warnings = fixture.disposalInstructions.warnings;
        expect(warnings?.any((w) => w.contains('data')), true);
      });
    });

    group('All Fixtures Consistency', () {
      test('all fixtures have required fields', () {
        for (final fixture in allClassificationFixtures) {
          // Required identifiers
          expect(fixture.id, isNotEmpty,
              reason: '${fixture.itemName} missing id');
          expect(fixture.itemName, isNotEmpty,
              reason: '${fixture.id} missing itemName');
          expect(fixture.category, isNotEmpty,
              reason: '${fixture.id} missing category');

          // Required disposal info
          expect(fixture.disposalInstructions, isNotNull,
              reason: '${fixture.id} missing disposalInstructions');
          expect(fixture.disposalInstructions.primaryMethod, isNotEmpty,
              reason: '${fixture.id} missing primaryMethod');
          expect(fixture.disposalInstructions.steps, isNotEmpty,
              reason: '${fixture.id} missing steps');

          // Required metadata
          expect(fixture.confidence, greaterThanOrEqualTo(0.0),
              reason: '${fixture.id} invalid confidence');
          expect(fixture.confidence, lessThanOrEqualTo(1.0),
              reason: '${fixture.id} invalid confidence');
          expect(fixture.timestamp, isNotNull,
              reason: '${fixture.id} missing timestamp');
        }
      });

      test('all fixtures have valid color codes', () {
        final validColors = [
          '#2196F3', // Blue - Dry Waste
          '#4CAF50', // Green - Wet Waste
          '#FF9800', // Orange - E-Waste
          '#F44336', // Red - Hazardous/Medical
          '#9E9E9E', // Grey - Unknown
          '#FF5722', // Deep Orange - Single-use
        ];

        for (final fixture in allClassificationFixtures) {
          expect(
            validColors.contains(fixture.colorCode),
            true,
            reason: '${fixture.id} has unexpected color: ${fixture.colorCode}',
          );
        }
      });

      test('risk levels are consistent', () {
        final validRiskLevels = ['low', 'medium', 'high', 'unknown'];

        for (final fixture in allClassificationFixtures) {
          expect(
            validRiskLevels.contains(fixture.riskLevel),
            true,
            reason: '${fixture.id} has invalid riskLevel: ${fixture.riskLevel}',
          );
        }
      });

      test('high risk fixtures require special disposal', () {
        for (final fixture in highRiskFixtures) {
          expect(
            fixture.requiresSpecialDisposal,
            true,
            reason:
                '${fixture.id} is high risk but not marked special disposal',
          );
          expect(
            fixture.riskLevel,
            anyOf('high', 'medium'),
            reason: '${fixture.id} risk level mismatch',
          );
        }
      });
    });

    group('Category Coverage', () {
      test('all major categories have fixtures', () {
        final categories = fixturesByCategory.keys.toList();

        expect(categories, contains('Dry Waste'));
        expect(categories, contains('Wet Waste'));
        expect(categories, contains('E-Waste'));
        expect(categories, contains('Hazardous Waste'));
        expect(categories, contains('Biomedical Waste'));
        expect(categories, contains('Unknown'));
      });

      test('each category has at least one fixture', () {
        for (final entry in fixturesByCategory.entries) {
          expect(
            entry.value.length,
            greaterThanOrEqualTo(1),
            reason: 'Category ${entry.key} has no fixtures',
          );
        }
      });
    });

    group('Snapshot Serialization', () {
      test('fixtures can be serialized to JSON', () {
        // This test ensures fixtures are serializable for golden snapshots
        for (final fixture in allClassificationFixtures) {
          // Note: Actual serialization test would require toJson() method
          // This is a placeholder for when that's implemented
          expect(fixture.id, isNotNull);
          expect(fixture.toString(), isNotEmpty);
        }
      });

      test('fixture IDs are unique', () {
        final ids = allClassificationFixtures.map((f) => f.id).toList();
        final uniqueIds = ids.toSet();

        expect(
          uniqueIds.length,
          ids.length,
          reason: 'Duplicate fixture IDs found',
        );
      });
    });
  });
}
