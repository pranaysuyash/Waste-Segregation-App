import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/widgets/classification_feedback_widget.dart';
import 'package:waste_segregation_app/widgets/history_list_item.dart';
import 'package:waste_segregation_app/widgets/interactive_tag.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';

void main() {
  group('UI Overflow Fixes Tests', () {
    testWidgets('Classification feedback chips handle overflow correctly', (WidgetTester tester) async {
      // Create a test classification
      final classification = WasteClassification(
        itemName: 'Very Long Item Name That Could Cause Overflow Issues',
        category: 'Very Long Category Name',
        subcategory: 'Very Long Subcategory Name',
        explanation: 'Test explanation',
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Test method',
          steps: ['Test step'],
          hasUrgentTimeframe: false,
        ),
        region: 'Test Region',
        visualFeatures: [],
        alternatives: [],
        confidence: 0.95,
      );

      // Build the widget in a constrained container
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300, // Narrow width to test overflow
              child: ClassificationFeedbackWidget(
                classification: classification,
                onFeedbackSubmitted: (updatedClassification) {},
                showCompactVersion: true,
              ),
            ),
          ),
        ),
      );

      // Verify the widget renders without overflow
      expect(find.byType(ClassificationFeedbackWidget), findsOneWidget);
      
      // Tap "Incorrect" to show correction options
      await tester.tap(find.text('Incorrect'));
      await tester.pumpAndSettle();

      // Verify correction chips are displayed
      expect(find.byType(Wrap), findsWidgets);
      
      // Check that no RenderFlex overflow occurs
      expect(tester.takeException(), isNull);
    });

    testWidgets('History list item handles long category names', (WidgetTester tester) async {
      final classification = WasteClassification(
        itemName: 'Very Long Item Name That Could Cause Overflow',
        category: 'Very Long Category Name That Might Overflow',
        subcategory: 'Very Long Subcategory Name',
        explanation: 'Test explanation',
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

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300, // Narrow width to test overflow
              child: HistoryListItem(
                classification: classification,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      // Verify the widget renders without overflow
      expect(find.byType(HistoryListItem), findsOneWidget);
      
      // Check that no RenderFlex overflow occurs
      expect(tester.takeException(), isNull);
    });

    testWidgets('Interactive tag collection handles many tags', (WidgetTester tester) async {
      // Create many tags to test overflow
      final tags = List.generate(10, (index) => 
        TagData(
          text: 'Very Long Tag Name $index That Could Overflow',
          color: Colors.blue,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300, // Narrow width to test overflow
              child: InteractiveTagCollection(
                tags: tags,
              ),
            ),
          ),
        ),
      );

      // Verify the widget renders without overflow
      expect(find.byType(InteractiveTagCollection), findsOneWidget);
      
      // Verify "more" button appears when there are many tags
      expect(find.textContaining('more'), findsOneWidget);
      
      // Check that no RenderFlex overflow occurs
      expect(tester.takeException(), isNull);
    });

    testWidgets('Modal dialogs have proper height constraints', (WidgetTester tester) async {
      final classification = WasteClassification(
        itemName: 'Test Item',
        category: 'Test Category',
        explanation: 'Test explanation',
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Test method',
          steps: ['Test step'],
          hasUrgentTimeframe: false,
        ),
        region: 'Test Region',
        visualFeatures: [],
        alternatives: [],
        confidence: 0.95,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      child: Container(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.8,
                        ),
                        child: SingleChildScrollView(
                          child: ClassificationFeedbackWidget(
                            classification: classification,
                            onFeedbackSubmitted: (updatedClassification) {},
                          ),
                        ),
                      ),
                    ),
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // Tap to show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog is displayed
      expect(find.byType(Dialog), findsOneWidget);
      
      // Verify dialog has height constraints
      final dialog = tester.widget<Dialog>(find.byType(Dialog));
      expect(dialog.child, isA<Container>());
      
      // Check that no overflow occurs
      expect(tester.takeException(), isNull);
    });
  });
} 