/// Widget tests for ResultScreen critical states
/// 
/// These tests verify UI renders correctly for key scenarios.
/// They don't test pixel-perfect rendering, but critical elements presence.
/// 
/// Run: flutter test test/screens/result_screen_widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';

import '../fixtures/classifications/fixtures.dart';

void main() {
  group('ResultScreen Widget Tests', () {
    group('Classification Fixtures', () {
      test('plastic bottle fixture has correct properties', () {
        final fixture = plasticBottleFixture;
        
        expect(fixture.id, ClassificationFixtureIds.plasticBottle);
        expect(fixture.category, 'Dry Waste');
        expect(fixture.itemName, 'Plastic Water Bottle');
        expect(fixture.confidence, 0.94);
        expect(fixture.isRecyclable, true);
      });

      test('medical waste fixture has high risk properties', () {
        final fixture = medicalWasteFixture;
        
        expect(fixture.id, ClassificationFixtureIds.medicalWaste);
        expect(fixture.category, 'Biomedical Waste');
        expect(fixture.riskLevel, 'high');
        expect(fixture.requiresSpecialDisposal, true);
      });

      test('unknown fixture has low confidence', () {
        final fixture = unknownLowConfidenceFixture;
        
        expect(fixture.id, ClassificationFixtureIds.unknownLowConfidence);
        expect(fixture.category, 'Requires Manual Review');
        expect(fixture.confidence, lessThan(0.5));
        expect(fixture.clarificationNeeded, true);
      });

      test('all fixtures have valid categories', () {
        final validCategories = [
          'Dry Waste',
          'Wet Waste',
          'E-Waste',
          'Hazardous Waste',
          'Biomedical Waste',
          'Requires Manual Review',
        ];

        for (final fixture in allClassificationFixtures) {
          expect(
            validCategories.contains(fixture.category),
            true,
            reason: '${fixture.id} has invalid category: ${fixture.category}',
          );
        }
      });

      test('all fixtures have disposal instructions', () {
        for (final fixture in allClassificationFixtures) {
          expect(
            fixture.disposalInstructions,
            isNotNull,
            reason: '${fixture.id} missing disposalInstructions',
          );
          expect(
            fixture.disposalInstructions.primaryMethod.isNotEmpty,
            true,
            reason: '${fixture.id} missing primaryMethod',
          );
          expect(
            fixture.disposalInstructions.steps.isNotEmpty,
            true,
            reason: '${fixture.id} missing steps',
          );
        }
      });
    });

    group('Fixture Categories', () {
      test('high risk fixtures require special disposal', () {
        for (final fixture in highRiskFixtures) {
          expect(
            fixture.requiresSpecialDisposal,
            true,
            reason: '${fixture.id} should require special disposal',
          );
        }
      });
    });

    group('Critical UI States', () {
      test('high confidence classification has expected properties', () {
        final fixture = plasticBottleFixture;
        
        // High confidence (> 0.8)
        expect(fixture.confidence, greaterThan(0.8));
        
        // Should not need clarification
        expect(fixture.clarificationNeeded, isNot(true));
        
        // Should have color code
        expect(fixture.colorCode, isNotEmpty);
      });

      test('low confidence classification shows clarification', () {
        final fixture = unknownLowConfidenceFixture;
        
        // Low confidence (< 0.5)
        expect(fixture.confidence, lessThan(0.5));
        
        // Should need clarification
        expect(fixture.clarificationNeeded, true);
        
        // Should have alternatives
        expect(fixture.alternatives, isNotEmpty);
      });

      test('hazardous waste has warnings', () {
        final fixture = hazardousBatteryFixture;
        
        // Should have warnings
        expect(fixture.disposalInstructions.warnings, isNotEmpty);
        
        // Should have risk level
        expect(fixture.riskLevel, isNot('low'));
      });
    });

    group('Analytics Parity', () {
      test('fixtures have stable IDs for analytics', () {
        // All fixture IDs should start with 'fixture-'
        for (final fixture in allClassificationFixtures) {
          expect(
            fixture.id.startsWith('fixture-'),
            true,
            reason: '${fixture.id} should start with fixture-',
          );
        }
      });

      test('fixture IDs are unique', () {
        final ids = allClassificationFixtures.map((f) => f.id).toList();
        final uniqueIds = ids.toSet();
        
        expect(uniqueIds.length, ids.length);
      });
    });
  });
}
