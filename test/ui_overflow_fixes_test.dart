import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/widgets/correction_dialog.dart';
import 'package:waste_segregation_app/widgets/history_list_item.dart';
import 'package:waste_segregation_app/widgets/interactive_tag.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';

void main() {
  group('UI Overflow Fixes Tests', () {
    testWidgets('History list item opens feedback dialog and refreshes on submission',
        (WidgetTester tester) async {
      final classification = WasteClassification(
        itemName: 'Very Long Item Name That Could Cause Overflow',
        subCategory: 'Very Long Subcategory Name',
        explanation: 'Test explanation',
        category: 'plastic',
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Test method',
          steps: ['Test step'],
          hasUrgentTimeframe: false,
        ),
        region: 'Test Region',
        visualFeatures: [],
        alternatives: [],
        confidence: 0.95,
        isRecyclable: true,
        isCompostable: true,
        requiresSpecialDisposal: true,
      );

      var feedbackCalls = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: HistoryListItem(
                classification: classification,
                onFeedbackSubmitted: (_) => feedbackCalls++,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byTooltip('Give feedback'));
      await tester.pumpAndSettle();
      expect(find.byType(CorrectionDialog), findsOneWidget);

      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.pop(const CorrectionResult(
        userConfirmed: false,
        userSuggestedCategory: 'Wet Waste',
      ));
      await tester.pumpAndSettle();

      expect(feedbackCalls, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Interactive tag collection handles many tags',
        (WidgetTester tester) async {
      final tags = List.generate(
        10,
        (index) => TagData(
          text: 'Very Long Tag Name $index That Could Overflow',
          color: Colors.blue,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: InteractiveTagCollection(
                tags: tags,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(InteractiveTagCollection), findsOneWidget);
      expect(find.textContaining('more'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
