import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/utils/constants.dart';
import 'package:waste_segregation_app/utils/waste_theme.dart';

void main() {
  group('WasteTheme', () {
    group('categoryColor', () {
      test('returns correct colours for known categories', () {
        expect(WasteTheme.categoryColor('Wet Waste'), AppTheme.wetWasteColor);
        expect(WasteTheme.categoryColor('wet waste'), AppTheme.wetWasteColor);
        expect(WasteTheme.categoryColor('Organic'), AppTheme.wetWasteColor);
        expect(WasteTheme.categoryColor('Dry Waste'), AppTheme.dryWasteColor);
        expect(WasteTheme.categoryColor('dry waste'), AppTheme.dryWasteColor);
        expect(WasteTheme.categoryColor('Recyclable'), AppTheme.dryWasteColor);
        expect(WasteTheme.categoryColor('Hazardous Waste'), AppTheme.hazardousWasteColor);
        expect(WasteTheme.categoryColor('hazardous'), AppTheme.hazardousWasteColor);
        expect(WasteTheme.categoryColor('Medical Waste'), AppTheme.medicalWasteColor);
        expect(WasteTheme.categoryColor('Non-Waste'), AppTheme.nonWasteColor);
        expect(WasteTheme.categoryColor('Requires Manual Review'), AppTheme.manualReviewColor);
      });

      test('returns neutral colour for unknown categories', () {
        expect(WasteTheme.categoryColor('unknown'), AppTheme.neutralColor);
        expect(WasteTheme.categoryColor(''), AppTheme.neutralColor);
      });

      test('is case-insensitive', () {
        expect(WasteTheme.categoryColor('WET WASTE'), AppTheme.wetWasteColor);
        expect(WasteTheme.categoryColor('Wet Waste'), AppTheme.wetWasteColor);
      });
    });

    group('categoryIcon', () {
      test('returns correct icons for known categories', () {
        expect(WasteTheme.categoryIcon('Wet Waste'), Icons.eco);
        expect(WasteTheme.categoryIcon('Dry Waste'), Icons.recycling);
        expect(WasteTheme.categoryIcon('Hazardous Waste'), Icons.warning);
        expect(WasteTheme.categoryIcon('Medical Waste'), Icons.medical_services);
        expect(WasteTheme.categoryIcon('Non-Waste'), Icons.check_circle);
        expect(WasteTheme.categoryIcon('Requires Manual Review'), Icons.help_outline);
      });

      test('returns default icon for unknown categories', () {
        expect(WasteTheme.categoryIcon('unknown'), Icons.category);
      });
    });

    group('confidenceColor', () {
      test('returns success colour for high confidence', () {
        expect(WasteTheme.confidenceColor(100), AppTheme.successColor);
        expect(WasteTheme.confidenceColor(80), AppTheme.successColor);
        expect(WasteTheme.confidenceColor(90), AppTheme.successColor);
      });

      test('returns warning colour for medium confidence', () {
        expect(WasteTheme.confidenceColor(60), AppTheme.warningColor);
        expect(WasteTheme.confidenceColor(79), AppTheme.warningColor);
        expect(WasteTheme.confidenceColor(70), AppTheme.warningColor);
      });

      test('returns error colour for low confidence', () {
        expect(WasteTheme.confidenceColor(0), AppTheme.errorColor);
        expect(WasteTheme.confidenceColor(59), AppTheme.errorColor);
        expect(WasteTheme.confidenceColor(30), AppTheme.errorColor);
      });
    });

    group('confidenceColorFromFraction', () {
      test('converts fraction correctly', () {
        expect(WasteTheme.confidenceColorFromFraction(0.9), AppTheme.successColor);
        expect(WasteTheme.confidenceColorFromFraction(0.7), AppTheme.warningColor);
        expect(WasteTheme.confidenceColorFromFraction(0.5), AppTheme.errorColor);
        expect(WasteTheme.confidenceColorFromFraction(1.0), AppTheme.successColor);
        expect(WasteTheme.confidenceColorFromFraction(0.0), AppTheme.errorColor);
      });
    });

    group('binColor', () {
      test('returns correct colours for bin labels', () {
        expect(WasteTheme.binColor('green'), isNotNull);
        expect(WasteTheme.binColor('blue'), isNotNull);
        expect(WasteTheme.binColor('red'), isNotNull);
        expect(WasteTheme.binColor('black'), isNotNull);
        expect(WasteTheme.binColor('yellow'), isNotNull);
      });

      test('returns neutral for unknown', () {
        expect(WasteTheme.binColor('unknown'), AppTheme.neutralColor);
      });
    });

    group('binColorForCategory', () {
      test('returns correct bin colours for categories', () {
        expect(WasteTheme.binColorForCategory('Wet Waste'), isNotNull);
        expect(WasteTheme.binColorForCategory('Dry Waste'), isNotNull);
        expect(WasteTheme.binColorForCategory('Hazardous Waste'), isNotNull);
        expect(WasteTheme.binColorForCategory('Medical Waste'), isNotNull);
        expect(WasteTheme.binColorForCategory('Non-Waste'), isNotNull);
      });
    });

    group('categoryDisplayLabel', () {
      test('normalises category labels', () {
        expect(WasteTheme.categoryDisplayLabel('Wet Waste'), 'Wet Waste');
        expect(WasteTheme.categoryDisplayLabel('hazardous'), 'Hazardous Waste');
        expect(WasteTheme.categoryDisplayLabel('e-waste'), 'E-Waste');
        expect(WasteTheme.categoryDisplayLabel('organic'), 'Wet Waste');
      });
    });

    group('Semantics helpers', () {
      test('categorySemanticsLabel returns expected format', () {
        expect(
          WasteTheme.categorySemanticsLabel('Dry Waste'),
          'Waste category: Dry Waste',
        );
      });

      test('confidenceSemanticsLabel returns expected format', () {
        expect(
          WasteTheme.confidenceSemanticsLabel(89),
          'High confidence: 89 percent',
        );
        expect(
          WasteTheme.confidenceSemanticsLabel(65),
          'Medium confidence: 65 percent',
        );
        expect(
          WasteTheme.confidenceSemanticsLabel(34),
          'Low confidence: 34 percent',
        );
      });

      test('binSemanticsLabel returns expected format', () {
        expect(
          WasteTheme.binSemanticsLabel('green'),
          'Dispose in green bin',
        );
      });
    });
  });
}
