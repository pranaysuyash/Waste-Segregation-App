import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/detected_waste_region.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/widgets/per_item_result_card.dart';

void main() {
  group('PerItemResultCard', () {
    DetectedWasteRegion makeRegion({
      String label = 'Item',
      String itemName = 'Test Item',
      String category = 'Dry Waste',
      double confidence = 0.85,
      String disposalMethod = 'Recycle',
    }) {
      return DetectedWasteRegion(
        boundingBox: NormalizedBoundingBox(
            left: 0.1, top: 0.1, width: 0.4, height: 0.4),
        label: label,
        confidence: confidence,
        classification: WasteClassification(
          itemName: itemName,
          category: category,
          explanation: 'Test',
          disposalInstructions: DisposalInstructions(
            primaryMethod: disposalMethod,
            steps: ['Step 1'],
            hasUrgentTimeframe: false,
          ),
          visualFeatures: [],
          alternatives: [],
          region: 'Test',
        ),
      );
    }

    testWidgets('displays item number and label', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: PerItemResultCard(
            region: makeRegion(label: 'Bottle'),
            index: 0,
            totalItems: 3,
          ),
        ),
      ));

      expect(find.text('Bottle'), findsOneWidget);
      expect(find.text('1 / 3'), findsOneWidget);
    });

    testWidgets('displays category badge', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: PerItemResultCard(
            region: makeRegion(category: 'Hazardous Waste'),
            index: 0,
          ),
        ),
      ));

      expect(find.text('Hazardous Waste'), findsOneWidget);
    });

    testWidgets('displays disposal method', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: PerItemResultCard(
            region: makeRegion(disposalMethod: 'Special drop-off'),
            index: 0,
          ),
        ),
      ));

      expect(find.text('Special drop-off'), findsOneWidget);
    });

    testWidgets('displays confidence percentage', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: PerItemResultCard(
            region: makeRegion(confidence: 0.92),
            index: 0,
          ),
        ),
      ));

      expect(find.text('92% confidence'), findsOneWidget);
    });

    testWidgets('shows pending state when no classification', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: PerItemResultCard(
            region: DetectedWasteRegion(
              boundingBox: NormalizedBoundingBox(
                  left: 0.1, top: 0.1, width: 0.4, height: 0.4),
              label: 'Unknown',
            ),
            index: 0,
          ),
        ),
      ));

      expect(find.text('Classification pending...'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: PerItemResultCard(
            region: makeRegion(),
            index: 0,
            onTap: () => tapped = true,
          ),
        ),
      ));

      await tester.tap(find.text('Test Item'));
      expect(tapped, true);
    });

    testWidgets('displays item name from classification', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: PerItemResultCard(
            region: makeRegion(itemName: 'Plastic Bottle'),
            index: 0,
          ),
        ),
      ));

      expect(find.text('Plastic Bottle'), findsOneWidget);
    });

    testWidgets('handles wet waste category color', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: PerItemResultCard(
            region: makeRegion(category: 'Wet Waste'),
            index: 0,
          ),
        ),
      ));

      expect(find.text('Wet Waste'), findsOneWidget);
    });
  });
}
