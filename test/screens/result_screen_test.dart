import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/screens/result_screen.dart';
import 'package:waste_segregation_app/widgets/classification_feedback_widget.dart';
import 'package:waste_segregation_app/services/storage_service.dart'; // Mock needed
import 'package:waste_segregation_app/services/gamification_service.dart'; // Mock needed
import 'package:mockito/mockito.dart';

// Mocks
class MockStorageService extends Mock implements StorageService {}
class MockGamificationService extends Mock implements GamificationService {}

// Helper to create a WasteClassification object with varying text lengths
WasteClassification createMockClassification({
  String itemName = 'Default Item Name',
  String category = 'Default Category',
  String subcategory = 'Default Subcategory',
  String explanation = 'Default explanation.',
  String educationalFact = 'Default educational fact.',
  DisposalInstructions? disposalInstructions,
}) {
  return WasteClassification(
    itemName: itemName,
    category: category,
    subcategory: subcategory,
    materialType: 'Test Material',
    isRecyclable: true,
    isCompostable: false,
    requiresSpecialDisposal: false,
    disposalMethod: 'Test disposal method',
    recyclingCode: 1,
    explanation: explanation,
    disposalInstructions: disposalInstructions ?? DisposalInstructions(
      primaryMethod: 'Dispose carefully',
      steps: ['Step 1'],
      hasUrgentTimeframe: false,
    ),
    timestamp: DateTime.now(),
    region: 'Test Region',
    visualFeatures: [],
    alternatives: [],
  );
}

void main() {
  late MockStorageService mockStorageService;
  late MockGamificationService mockGamificationService;

  setUp(() {
    mockStorageService = MockStorageService();
    mockGamificationService = MockGamificationService();
  });

  Widget createTestableWidget(Widget child) {
    return MultiProvider(
      providers: [
        Provider<StorageService>.value(value: mockStorageService),
        Provider<GamificationService>.value(value: mockGamificationService),
      ],
      child: MaterialApp(
        home: Scaffold(body: child),
      ),
    );
  }

  group('ResultScreen Tests', () {
    group('Item Name Overflow', () {
      testWidgets('Item name uses ellipsis for long names', (WidgetTester tester) async {
        final longItemName = 'This is a very very very extremely long item name that should definitely overflow and show an ellipsis';
        final classification = createMockClassification(itemName: longItemName);

        await tester.pumpWidget(createTestableWidget(ResultScreen(classification: classification)));
        await tester.pumpAndSettle(); // Allow time for layout

        final itemNameTextWidget = tester.widget<Text>(find.text(longItemName));

        expect(itemNameTextWidget.overflow, TextOverflow.ellipsis);
        expect(itemNameTextWidget.maxLines, 2); // As per implementation
      });
    });

    group('ClassificationFeedbackWidget Integration', () {
      testWidgets('Feedback widget is present and configured when showActions is true', (WidgetTester tester) async {
        final classification = createMockClassification();
        await tester.pumpWidget(createTestableWidget(ResultScreen(classification: classification, showActions: true)));
        await tester.pumpAndSettle();

        expect(find.byType(ClassificationFeedbackWidget), findsOneWidget);
        final feedbackWidget = tester.widget<ClassificationFeedbackWidget>(find.byType(ClassificationFeedbackWidget));
        expect(feedbackWidget.showCompactVersion, isFalse); // As per recent change
      });

      testWidgets('Feedback widget is NOT present when showActions is false', (WidgetTester tester) async {
        final classification = createMockClassification();
        await tester.pumpWidget(createTestableWidget(ResultScreen(classification: classification, showActions: false)));
        await tester.pumpAndSettle();

        expect(find.byType(ClassificationFeedbackWidget), findsNothing);
      });
    });

    group('Explanation Read More/Show Less', () {
      final longExplanation = 'This is a very long explanation that spans multiple lines and should definitely be truncated initially. It needs to be long enough to ensure that the ellipsis is applied and the Read More button is shown. We will then tap the button to expand it and see the full content, and then tap Show Less to collapse it again.';
      final classificationWithLongExplanation = createMockClassification(explanation: longExplanation);

      testWidgets('Explanation is initially truncated and shows "Read More"', (WidgetTester tester) async {
        await tester.pumpWidget(createTestableWidget(ResultScreen(classification: classificationWithLongExplanation)));
        await tester.pumpAndSettle();

        final explanationTextWidget = tester.widget<Text>(find.text(longExplanation));
        expect(explanationTextWidget.overflow, TextOverflow.ellipsis);
        expect(explanationTextWidget.maxLines, 3); // As per implementation
        expect(find.text('Read More'), findsOneWidget);
        expect(find.text('Show Less'), findsNothing);
      });

      testWidgets('Tapping "Read More" expands explanation and shows "Show Less"', (WidgetTester tester) async {
        await tester.pumpWidget(createTestableWidget(ResultScreen(classification: classificationWithLongExplanation)));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Read More'));
        await tester.pumpAndSettle();

        final explanationTextWidget = tester.widget<Text>(find.text(longExplanation));
        expect(explanationTextWidget.maxLines, isNull); // Expanded
        expect(explanationTextWidget.overflow, TextOverflow.visible);
        expect(find.text('Show Less'), findsOneWidget);
        expect(find.text('Read More'), findsNothing);
      });

      testWidgets('Tapping "Show Less" collapses explanation and shows "Read More"', (WidgetTester tester) async {
        await tester.pumpWidget(createTestableWidget(ResultScreen(classification: classificationWithLongExplanation)));
        await tester.pumpAndSettle();

        // Expand first
        await tester.tap(find.text('Read More'));
        await tester.pumpAndSettle();
        expect(find.text('Show Less'), findsOneWidget);

        // Then collapse
        await tester.tap(find.text('Show Less'));
        await tester.pumpAndSettle();

        final explanationTextWidget = tester.widget<Text>(find.text(longExplanation));
        expect(explanationTextWidget.overflow, TextOverflow.ellipsis);
        expect(explanationTextWidget.maxLines, 3);
        expect(find.text('Read More'), findsOneWidget);
        expect(find.text('Show Less'), findsNothing);
      });
    });

    group('Educational Fact Read More/Show Less', () {
      final longEducationalFact = 'This is a very long educational fact that also spans multiple lines and is designed to be truncated. It must be sufficiently lengthy to trigger the ellipsis and display the Read More button. Users can then expand it to read the full fact and subsequently collapse it using the Show Less button.';
      // We use sustainabilityFacts in the mock, which maps to educationalFact in the UI logic
      final classificationWithLongFact = createMockClassification(educationalFact: longEducationalFact);


      testWidgets('Educational Fact is initially truncated and shows "Read More"', (WidgetTester tester) async {
        await tester.pumpWidget(createTestableWidget(ResultScreen(classification: classificationWithLongFact)));
        await tester.pumpAndSettle();

        // The actual text displayed comes from _getEducationalFact, which uses classification.sustainabilityFacts.
        // We need to find the text that _getEducationalFact would produce.
        // For simplicity in testing, we'll assume the passed educationalFact string is directly rendered.
        // In a more complex scenario, we might need to mock _getEducationalFact or use more specific finders.
        final factTextWidget = tester.widget<Text>(find.text(longEducationalFact));
        expect(factTextWidget.overflow, TextOverflow.ellipsis);
        expect(factTextWidget.maxLines, 3); // As per implementation
        expect(find.text('Read More'), findsOneWidget); // This one is for explanation
        expect(find.widgetWithText(GestureDetector, 'Read More').at(1), findsOneWidget); // Find the second "Read More"
      });

      testWidgets('Tapping "Read More" on fact expands it and shows "Show Less"', (WidgetTester tester) async {
        await tester.pumpWidget(createTestableWidget(ResultScreen(classification: classificationWithLongFact)));
        await tester.pumpAndSettle();

        // Tap the second "Read More" button (for educational fact)
        await tester.tap(find.widgetWithText(GestureDetector, 'Read More').at(1));
        await tester.pumpAndSettle();

        final factTextWidget = tester.widget<Text>(find.text(longEducationalFact));
        expect(factTextWidget.maxLines, isNull); // Expanded
        expect(factTextWidget.overflow, TextOverflow.visible);
        expect(find.widgetWithText(GestureDetector, 'Show Less').at(1), findsOneWidget);
        expect(find.widgetWithText(GestureDetector, 'Read More').at(1), findsNothing);
      });

      testWidgets('Tapping "Show Less" on fact collapses it and shows "Read More"', (WidgetTester tester) async {
        await tester.pumpWidget(createTestableWidget(ResultScreen(classification: classificationWithLongFact)));
        await tester.pumpAndSettle();

        // Expand first
        await tester.tap(find.widgetWithText(GestureDetector, 'Read More').at(1));
        await tester.pumpAndSettle();
        expect(find.widgetWithText(GestureDetector, 'Show Less').at(1), findsOneWidget);

        // Then collapse
        await tester.tap(find.widgetWithText(GestureDetector, 'Show Less').at(1));
        await tester.pumpAndSettle();

        final factTextWidget = tester.widget<Text>(find.text(longEducationalFact));
        expect(factTextWidget.overflow, TextOverflow.ellipsis);
        expect(factTextWidget.maxLines, 3);
        expect(find.widgetWithText(GestureDetector, 'Read More').at(1), findsOneWidget);
        expect(find.widgetWithText(GestureDetector, 'Show Less').at(1), findsNothing);
      });
    });
  });
}
