import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/widgets/result_screen/explanation_panel.dart';

void main() {
  group('ExplanationPanel', () {
    testWidgets('renders nothing when no content fields exist', (tester) async {
      final c = WasteClassification(
        id: 'c1',
        itemName: 'Mystery',
        category: 'Dry Waste',
        explanation: '',
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Dispose',
          steps: const ['Step'],
          hasUrgentTimeframe: false,
        ),
        region: 'Unknown',
        visualFeatures: const [],
        alternatives: const [],
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: ExplanationPanel(classification: c)),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Why this classification?'), findsNothing);
    });

    testWidgets('renders and expands for confident result with alternatives', (
      tester,
    ) async {
      final c = WasteClassification(
        id: 'c2',
        itemName: 'Paper Cup',
        category: 'Dry Waste',
        subcategory: 'Paper',
        explanation: 'Paper cup with plastic lining',
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Recycle',
          steps: const ['Rinse', 'Recycle'],
          hasUrgentTimeframe: false,
        ),
        region: 'Test',
        visualFeatures: const ['cup', 'white'],
        alternatives: [
          AlternativeClassification(
            category: 'Wet Waste',
            subcategory: 'Food Soiled',
            confidence: 0.25,
            reason: 'If heavily food-soiled, compost instead',
          ),
        ],
        confidence: 0.92,
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: ExplanationPanel(classification: c)),
      ));
      await tester.pumpAndSettle();

      // Header visible, collapsed by default for high confidence
      expect(find.text('Why this classification?'), findsOneWidget);
      expect(find.textContaining('92% confident'), findsOneWidget);

      // Expand
      await tester.tap(find.text('Why this classification?'),
          warnIfMissed: false);
      await tester.pumpAndSettle();

      // Sections visible after expand
      expect(find.text('Visual clues'), findsOneWidget);
      expect(find.text('cup'), findsOneWidget);
      expect(find.text('white'), findsOneWidget);
      expect(find.text('Reasoning'), findsOneWidget);
      expect(find.text('Could also be…'), findsOneWidget);
      expect(find.text('Wet Waste — Food Soiled'), findsOneWidget);
      expect(
          find.text('If heavily food-soiled, compost instead'), findsOneWidget);
      expect(find.text('25%'), findsOneWidget);
      expect(find.text('Confidence'), findsOneWidget);
      expect(find.text('92%'), findsOneWidget);
      expect(
        find.text(
            'High confidence — the AI is very sure about this classification.'),
        findsOneWidget,
      );
    });

    testWidgets(
        'shows uncertainty copy for low confidence and is expanded by default',
        (
      tester,
    ) async {
      final c = WasteClassification(
        id: 'c3',
        itemName: 'Unknown',
        category: 'Requires Manual Review',
        explanation: 'Unclear image',
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Review',
          steps: const ['Check'],
          hasUrgentTimeframe: false,
        ),
        region: 'Test',
        visualFeatures: const ['blurry'],
        alternatives: const [],
        confidence: 0.45,
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: ExplanationPanel(classification: c)),
      ));
      await tester.pumpAndSettle();

      // Expanded by default for low confidence
      expect(find.text('Why this classification?'), findsOneWidget);
      expect(
        find.text(
            'The AI is uncertain about this classification. Consider reviewing the alternatives or providing a clearer image.'),
        findsOneWidget,
      );

      // Confidence progress bar
      expect(find.text('45%'), findsOneWidget);
    });

    testWidgets('shows local guideline when available', (tester) async {
      final c = WasteClassification(
        id: 'c4',
        itemName: 'Glass Bottle',
        category: 'Dry Waste',
        explanation: 'Clear glass',
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Recycle',
          steps: const ['Recycle'],
          hasUrgentTimeframe: false,
        ),
        region: 'Bangalore',
        visualFeatures: const ['transparent'],
        alternatives: const [],
        localGuidelinesReference: 'BBMP Rule 4.2: Glass must be rinsed',
        confidence: 0.88,
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: ExplanationPanel(classification: c)),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Why this classification?'),
          warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Local guideline'), findsOneWidget);
      expect(find.text('BBMP Rule 4.2: Glass must be rinsed'), findsOneWidget);
    });
  });
}
