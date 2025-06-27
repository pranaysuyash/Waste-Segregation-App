import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:waste_segregation_app/widgets/result_screen/result_header.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';

void main() {
  group('ResultHeader Widget Tests', () {
    late WasteClassification mockClassification;

    setUp(() {
      mockClassification = WasteClassification(
        id: 'test-classification',
        itemName: 'Test Aluminum Can',
        category: 'Recyclable',
        confidence: 0.92,
        explanation: 'This appears to be an aluminum can based on visual analysis.',
        region: 'Test Region',
        visualFeatures: ['metallic surface', 'cylindrical shape'],
        alternatives: [],
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Recycle in designated bin',
          steps: [
            'Clean the item thoroughly',
            'Remove any labels or stickers',
            'Place in the appropriate recycling bin',
          ],
          hasUrgentTimeframe: false,
        ),
        timestamp: DateTime.now(),
      );
    });

    Widget createTestWidget({
      required WasteClassification classification,
      int pointsEarned = 15,
      VoidCallback? onDisposeCorrectly,
    }) {
      return ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ResultHeader(
              classification: classification,
              pointsEarned: pointsEarned,
              onDisposeCorrectly: onDisposeCorrectly ?? () {},
            ),
          ),
        ),
      );
    }

    testWidgets('renders classification information correctly', (tester) async {
      await tester.pumpWidget(createTestWidget(classification: mockClassification));
      await tester.pumpAndSettle();

      // Check if item name is displayed
      expect(find.text('Test Aluminum Can'), findsOneWidget);

      // Check if category is displayed
      expect(find.text('Recyclable'), findsOneWidget);

      // Check if confidence is displayed
      expect(find.text('92% confidence'), findsOneWidget);

      // Check if points are displayed
      expect(find.text('+15 XP'), findsOneWidget);

      // Check if primary CTA is present
      expect(find.text('Dispose Correctly'), findsOneWidget);
    });

    testWidgets('displays different category colors correctly', (tester) async {
      final hazardousClassification = mockClassification.copyWith(
        category: 'Hazardous',
        itemName: 'Battery',
      );

      await tester.pumpWidget(createTestWidget(classification: hazardousClassification));
      await tester.pumpAndSettle();

      expect(find.text('Hazardous'), findsOneWidget);
      expect(find.text('Battery'), findsOneWidget);
    });

    testWidgets('handles dispose correctly button tap', (tester) async {
      bool buttonTapped = false;

      await tester.pumpWidget(createTestWidget(
        classification: mockClassification,
        onDisposeCorrectly: () {
          buttonTapped = true;
        },
      ));
      await tester.pumpAndSettle();

      // Tap the dispose correctly button
      await tester.tap(find.text('Dispose Correctly'));
      await tester.pumpAndSettle();

      expect(buttonTapped, isTrue);
    });

    testWidgets('displays environmental impact correctly', (tester) async {
      await tester.pumpWidget(createTestWidget(classification: mockClassification));
      await tester.pumpAndSettle();

      // Check if environmental impact is shown
      expect(find.text('−3g CO₂e'), findsOneWidget);
    });

    testWidgets('shows confidence bar animation', (tester) async {
      await tester.pumpWidget(createTestWidget(classification: mockClassification));

      // Pump a few frames to allow animation to start
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Confidence bar should be present
      expect(find.text('92% confidence'), findsOneWidget);
    });

    testWidgets('handles zero points correctly', (tester) async {
      await tester.pumpWidget(createTestWidget(
        classification: mockClassification,
        pointsEarned: 0,
      ));
      await tester.pumpAndSettle();

      expect(find.text('+0 XP'), findsOneWidget);
    });

    testWidgets('handles high points correctly', (tester) async {
      await tester.pumpWidget(createTestWidget(
        classification: mockClassification,
        pointsEarned: 50,
      ));
      await tester.pumpAndSettle();

      expect(find.text('+50 XP'), findsOneWidget);
    });

    testWidgets('displays placeholder when no image URL', (tester) async {
      final classificationNoImage = mockClassification.copyWith(imageUrl: null);

      await tester.pumpWidget(createTestWidget(classification: classificationNoImage));
      await tester.pumpAndSettle();

      // Should find the placeholder icon
      expect(find.byIcon(Icons.image), findsOneWidget);
    });

    testWidgets('handles low confidence correctly', (tester) async {
      final lowConfidenceClassification = mockClassification.copyWith(confidence: 0.45);

      await tester.pumpWidget(createTestWidget(classification: lowConfidenceClassification));
      await tester.pumpAndSettle();

      expect(find.text('45% confidence'), findsOneWidget);
    });
  });
}
