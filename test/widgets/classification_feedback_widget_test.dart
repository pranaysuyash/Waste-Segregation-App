import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/widgets/classification_feedback_widget.dart';
import 'package:waste_segregation_app/utils/constants.dart'; // For AppTheme

// Helper to create a WasteClassification object
WasteClassification createMockClassification({
  String itemName = 'Test Item',
  String category = 'Test Category',
  bool? userConfirmed, // To control internal state for button visibility
}) {
  return WasteClassification(
    id: 'test_id_${DateTime.now().millisecondsSinceEpoch}',
    itemName: itemName,
    category: category,
    explanation: 'Test explanation.',
    disposalInstructions: DisposalInstructions(primaryMethod: 'Dispose correctly', steps: ['Step 1']),
    timestamp: DateTime.now(),
    userConfirmed: userConfirmed, // Set this to test different states
  );
}

void main() {
  Widget createTestableWidget({
    required WasteClassification classification,
    required Function(WasteClassification) onFeedbackSubmitted,
    VoidCallback? onReanalyzeRequested,
    bool isProcessing = false,
    bool showCompactVersion = false, // Default to full version for these tests
  }) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: AppTheme.primaryColor,
        colorScheme: ColorScheme.fromSeed(seedColor: AppTheme.primaryColor),
        textTheme: AppTheme.textTheme,
        cardTheme: AppTheme.cardTheme,
        elevatedButtonTheme: AppTheme.elevatedButtonTheme,
        outlinedButtonTheme: AppTheme.outlinedButtonTheme,
      ),
      home: Scaffold(
        body: ClassificationFeedbackWidget(
          classification: classification,
          onFeedbackSubmitted: onFeedbackSubmitted,
          onReanalyzeRequested: onReanalyzeRequested,
          isProcessing: isProcessing,
          showCompactVersion: showCompactVersion,
        ),
      ),
    );
  }

  group('ClassificationFeedbackWidget Tests - Re-analysis Button', () {
    testWidgets('"Re-analyze Image" button visibility: shown when conditions met', (WidgetTester tester) async {
      int reanalyzeCallCount = 0;
      final classification = createMockClassification(userConfirmed: false); // User confirmed incorrect

      await tester.pumpWidget(createTestableWidget(
        classification: classification,
        onFeedbackSubmitted: (_) {},
        onReanalyzeRequested: () { reanalyzeCallCount++; },
      ));

      // To make the button appear, _userConfirmed must be false.
      // In the widget, this state is set by tapping "No, incorrect".
      // So, we first tap that.
      final incorrectRadio = find.ancestor(
        of: find.text('No, incorrect'),
        matching: find.byType(RadioListTile<bool>),
      );
      expect(incorrectRadio, findsOneWidget);
      await tester.tap(incorrectRadio);
      await tester.pumpAndSettle();

      expect(find.widgetWithIcon(OutlinedButton, Icons.travel_explore), findsOneWidget);
      expect(find.text('Re-analyze'), findsOneWidget);
    });

    testWidgets('"Re-analyze Image" button NOT visible if onReanalyzeRequested is null', (WidgetTester tester) async {
      final classification = createMockClassification(userConfirmed: false);
      await tester.pumpWidget(createTestableWidget(
        classification: classification,
        onFeedbackSubmitted: (_) {},
        onReanalyzeRequested: null, // Explicitly null
      ));

      final incorrectRadio = find.ancestor(of: find.text('No, incorrect'), matching: find.byType(RadioListTile<bool>));
      await tester.tap(incorrectRadio);
      await tester.pumpAndSettle();

      expect(find.widgetWithIcon(OutlinedButton, Icons.travel_explore), findsNothing);
    });

    testWidgets('"Re-analyze Image" button NOT visible if userConfirmed is true', (WidgetTester tester) async {
      final classification = createMockClassification(userConfirmed: true);
      await tester.pumpWidget(createTestableWidget(
        classification: classification,
        onFeedbackSubmitted: (_) {},
        onReanalyzeRequested: () {},
      ));
      // User confirmed true, so "No, incorrect" path not taken, button shouldn't show
      expect(find.widgetWithIcon(OutlinedButton, Icons.travel_explore), findsNothing);
    });

     testWidgets('"Re-analyze Image" button NOT visible if userConfirmed is null (no selection made)', (WidgetTester tester) async {
      final classification = createMockClassification(userConfirmed: null);
      await tester.pumpWidget(createTestableWidget(
        classification: classification,
        onFeedbackSubmitted: (_) {},
        onReanalyzeRequested: () {},
      ));
      // No selection made, button shouldn't show
      expect(find.widgetWithIcon(OutlinedButton, Icons.travel_explore), findsNothing);
    });

    testWidgets('"Re-analyze Image" button calls onReanalyzeRequested when tapped', (WidgetTester tester) async {
      int reanalyzeCallCount = 0;
      final classification = createMockClassification(userConfirmed: false);
      await tester.pumpWidget(createTestableWidget(
        classification: classification,
        onFeedbackSubmitted: (_) {},
        onReanalyzeRequested: () { reanalyzeCallCount++; },
      ));

      final incorrectRadio = find.ancestor(of: find.text('No, incorrect'), matching: find.byType(RadioListTile<bool>));
      await tester.tap(incorrectRadio);
      await tester.pumpAndSettle();

      final reanalyzeButton = find.widgetWithIcon(OutlinedButton, Icons.travel_explore);
      expect(reanalyzeButton, findsOneWidget);
      await tester.tap(reanalyzeButton);
      await tester.pumpAndSettle();

      expect(reanalyzeCallCount, 1);
    });

    testWidgets('Buttons are disabled when isProcessing is true', (WidgetTester tester) async {
      final classification = createMockClassification(userConfirmed: false);
      await tester.pumpWidget(createTestableWidget(
        classification: classification,
        onFeedbackSubmitted: (_) {},
        onReanalyzeRequested: () {},
        isProcessing: true, // Set isProcessing to true
      ));

      final incorrectRadio = find.ancestor(of: find.text('No, incorrect'), matching: find.byType(RadioListTile<bool>));
      await tester.tap(incorrectRadio); // Make re-analyze button potentially visible
      await tester.pumpAndSettle();

      final reanalyzeButton = tester.widget<OutlinedButton>(find.widgetWithIcon(OutlinedButton, Icons.travel_explore));
      final submitButton = tester.widget<ElevatedButton>(find.widgetWithIcon(ElevatedButton, Icons.send));

      expect(reanalyzeButton.onPressed, isNull);
      expect(submitButton.onPressed, isNull); // Submit should also be disabled
    });

    testWidgets('Buttons are enabled when isProcessing is false', (WidgetTester tester) async {
      final classification = createMockClassification(userConfirmed: false);
       await tester.pumpWidget(createTestableWidget(
        classification: classification,
        onFeedbackSubmitted: (_) {},
        onReanalyzeRequested: () {},
        isProcessing: false,
      ));

      final incorrectRadio = find.ancestor(of: find.text('No, incorrect'), matching: find.byType(RadioListTile<bool>));
      await tester.tap(incorrectRadio); // Make re-analyze button potentially visible
      await tester.pumpAndSettle();

      // Also make a choice for submit button to be enabled (_userConfirmed != null)
      // Tapping "No, incorrect" already sets _userConfirmed = false, so submit button should be enabled.

      final reanalyzeButton = tester.widget<OutlinedButton>(find.widgetWithIcon(OutlinedButton, Icons.travel_explore));
      final submitButton = tester.widget<ElevatedButton>(find.widgetWithIcon(ElevatedButton, Icons.send));

      expect(reanalyzeButton.onPressed, isNotNull);
      expect(submitButton.onPressed, isNotNull);
    });
  });
}
