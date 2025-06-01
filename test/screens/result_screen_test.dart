import 'dart:async';
import 'dart:io'; // For File mock in re-analysis (though direct File mock is hard)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:waste_segregation_app/models/gamification.dart'; // For UserGamificationProfile if needed by GamificationService mock
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/screens/result_screen.dart';
import 'package:waste_segregation_app/services/ai_service.dart';
import 'package:waste_segregation_app/services/gamification_service.dart';
import 'package:waste_segregation_app/services/storage_service.dart';
import 'package:waste_segregation_app/utils/constants.dart'; // For AppTheme for consistent styling
import 'package:waste_segregation_app/widgets/classification_feedback_widget.dart';

// Import generated mocks
import 'result_screen_test.mocks.dart';


// Helper to create a WasteClassification object with varying text lengths
WasteClassification createMockClassification({
  String? id,
  String itemName = 'Default Item Name',
  String category = 'Default Category',
  String? subcategory = 'Default Subcategory',
  String explanation = 'Default explanation.',
  String educationalFact = 'Default educational fact.',
  DisposalInstructions? disposalInstructions,
  double? confidence = 0.9, // Added for confidence tests
  bool? clarificationNeeded = false, // Added for confidence tests
  String? imageUrl, // Added for re-analysis tests
  double? confidence = 0.9, // Added for confidence tests
  bool? clarificationNeeded = false, // Added for confidence tests
  String? imageUrl, // Added for re-analysis tests
}) {
  return WasteClassification(
    id: id ?? 'test_id_${DateTime.now().millisecondsSinceEpoch}',
    itemName: itemName,
    category: category,
    subcategory: subcategory,
    explanation: explanation,
    disposalInstructions: disposalInstructions ?? DisposalInstructions(primaryMethod: 'Dispose carefully', steps: ['Step 1']),
    materialType: 'Organic',
    isRecyclable: false,
    isCompostable: true,
    requiresSpecialDisposal: false,
    recyclingCode: null,
    environmentalImpact: 'Low impact',
    recoveryOptions: 'Compost',
    reductionTips: ['Reduce usage'],
    sustainabilityFacts: [educationalFact],
    typicalLocation: 'Kitchen',
    commonMistakes: ['Mixing with dry waste'],
    localRegulations: 'Follow local guidelines',
    imageUrl: imageUrl, // Use passed imageUrl
    timestamp: DateTime.now(),
    region: 'Test Region',
    confidence: confidence, // Use passed confidence
    clarificationNeeded: clarificationNeeded, // Use passed clarificationNeeded
    alternativeDisposalMethods: [],
    historicalSignificance: 'None',
    culturalSignificance: 'None',
    safetyWarnings: [],
    visualFeatures: [],
    userFeedback: [],
    source: 'test',
    isSaved: false,
    hasUrgentTimeframe: false,
  );
}

@GenerateMocks([StorageService, GamificationService, AiService])
void main() {
  late MockStorageService mockStorageService;
  late MockGamificationService mockGamificationService;
  late MockAiService mockAiService;

  setUp(() {
    mockStorageService = MockStorageService();
    mockGamificationService = MockGamificationService();
    mockAiService = MockAiService();

    // Default stubs
    when(mockStorageService.saveClassification(any)).thenAnswer((_) async {});
    when(mockGamificationService.processClassification(any)).thenAnswer((_) async {});
    when(mockGamificationService.getProfile()).thenAnswer((_) async => UserGamificationProfile.empty('mockUserId'));
    when(mockGamificationService.addPoints(any, customPoints: anyNamed('customPoints'))).thenAnswer((_) async {});

    when(mockAiService.handleUserCorrection(
      originalClassification: anyNamed('originalClassification'),
      userCorrection: anyNamed('userCorrection'),
      userReason: anyNamed('userReason'),
      imageFile: anyNamed('imageFile'),
    )).thenAnswer((_) async => createMockClassification(itemName: 'Re-analyzed Item', category: 'Re-analyzed Category', id: Uuid().v4()));
  });

  Widget createTestableWidget(Widget child) {
    return MultiProvider(
      providers: [
        Provider<StorageService>.value(value: mockStorageService),
        Provider<GamificationService>.value(value: mockGamificationService),
        Provider<AiService>.value(value: mockAiService),
      ],
      child: MaterialApp(
        theme: ThemeData( // Apply a theme similar to the app's for consistency
          primaryColor: AppTheme.primaryColor,
          colorScheme: ColorScheme.fromSeed(seedColor: AppTheme.primaryColor),
          textTheme: AppTheme.textTheme,
          cardTheme: AppTheme.cardTheme,
        ),
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
      final classificationWithLongFact = createMockClassification(educationalFact: longEducationalFact);

      testWidgets('Educational Fact is initially truncated and shows "Read More"', (WidgetTester tester) async {
        await tester.pumpWidget(createTestableWidget(ResultScreen(classification: classificationWithLongFact)));
        await tester.pumpAndSettle();

        final factTextWidget = tester.widget<Text>(find.text(longEducationalFact));
        expect(factTextWidget.overflow, TextOverflow.ellipsis);
        expect(factTextWidget.maxLines, 3);
        expect(find.widgetWithText(GestureDetector, 'Read More').at(1), findsOneWidget);
      });

      testWidgets('Tapping "Read More" on fact expands it and shows "Show Less"', (WidgetTester tester) async {
        await tester.pumpWidget(createTestableWidget(ResultScreen(classification: classificationWithLongFact)));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(GestureDetector, 'Read More').at(1));
        await tester.pumpAndSettle();

        final factTextWidget = tester.widget<Text>(find.text(longEducationalFact));
        expect(factTextWidget.maxLines, isNull);
        expect(factTextWidget.overflow, TextOverflow.visible);
        expect(find.widgetWithText(GestureDetector, 'Show Less').at(1), findsOneWidget);
        expect(find.widgetWithText(GestureDetector, 'Read More').at(1), findsNothing);
      });

      testWidgets('Tapping "Show Less" on fact collapses it and shows "Read More"', (WidgetTester tester) async {
        await tester.pumpWidget(createTestableWidget(ResultScreen(classification: classificationWithLongFact)));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(GestureDetector, 'Read More').at(1));
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(GestureDetector, 'Show Less').at(1));
        await tester.pumpAndSettle();

        final factTextWidget = tester.widget<Text>(find.text(longEducationalFact));
        expect(factTextWidget.overflow, TextOverflow.ellipsis);
        expect(factTextWidget.maxLines, 3);
        expect(find.widgetWithText(GestureDetector, 'Read More').at(1), findsOneWidget);
        expect(find.widgetWithText(GestureDetector, 'Show Less').at(1), findsNothing);
      });
    });

    group('Confidence Warnings', () {
      testWidgets('Displays warning for low confidence (< 0.7)', (WidgetTester tester) async {
        final classification = createMockClassification(confidence: 0.65);
        await tester.pumpWidget(createTestableWidget(ResultScreen(classification: classification)));
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
        expect(find.text('Low confidence in this result. Please verify.'), findsOneWidget);
      });

      testWidgets('Displays warning if clarificationNeeded is true', (WidgetTester tester) async {
        final classification = createMockClassification(clarificationNeeded: true, confidence: 0.8); // High confidence but clarification needed
        await tester.pumpWidget(createTestableWidget(ResultScreen(classification: classification)));
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
        expect(find.text('AI suggests clarification may be needed for this item.'), findsOneWidget);
      });

      testWidgets('Displays combined warning for low confidence and clarificationNeeded', (WidgetTester tester) async {
        final classification = createMockClassification(confidence: 0.5, clarificationNeeded: true);
        await tester.pumpWidget(createTestableWidget(ResultScreen(classification: classification)));
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
        expect(find.text('Low confidence. Clarification may be needed. Please verify.'), findsOneWidget);
      });

      testWidgets('No warning if confidence is high and clarificationNeeded is false', (WidgetTester tester) async {
        final classification = createMockClassification(confidence: 0.9, clarificationNeeded: false);
        await tester.pumpWidget(createTestableWidget(ResultScreen(classification: classification)));
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
      });

       testWidgets('No low-confidence warning if confidence is null (clarificationNeeded false)', (WidgetTester tester) async {
        final classification = createMockClassification(confidence: null, clarificationNeeded: false);
        await tester.pumpWidget(createTestableWidget(ResultScreen(classification: classification)));
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
      });

      testWidgets('Clarification warning shown even if confidence is null and clarificationNeeded true', (WidgetTester tester) async {
        final classification = createMockClassification(confidence: null, clarificationNeeded: true);
        await tester.pumpWidget(createTestableWidget(ResultScreen(classification: classification)));
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
        expect(find.text('AI suggests clarification may be needed for this item.'), findsOneWidget);
      });
    });

    group('Re-analysis Flow', () {
      testWidgets('Successful re-analysis updates classification and shows SnackBar', (WidgetTester tester) async {
        final initialId = 'initialId123';
        final reanalyzedId = 'reanalyzedId456';
        final initialClassification = createMockClassification(id: initialId, itemName: 'Initial Item', category: 'Initial Category', imageUrl: '/fake/image.png', confidence: 0.8);
        final newMockClassification = createMockClassification(id: reanalyzedId, itemName: 'Re-analyzed Item', category: 'Re-analyzed Category', confidence: 0.95);

        when(mockAiService.handleUserCorrection(
          originalClassification: anyNamed('originalClassification'),
          userCorrection: anyNamed('userCorrection'),
          userReason: anyNamed('userReason'),
          imageFile: anyNamed('imageFile'),
        )).thenAnswer((_) async => newMockClassification);

        await tester.pumpWidget(createTestableWidget(ResultScreen(classification: initialClassification)));
        await tester.pumpAndSettle();

        expect(find.text('Initial Item'), findsOneWidget);

        // Trigger re-analysis: Tap "No, incorrect" then "Re-analyze"
        await tester.tap(find.ancestor(of: find.text('No, incorrect'), matching: find.byType(RadioListTile<bool>)));
        await tester.pumpAndSettle();

        final reanalyzeButton = find.widgetWithIcon(OutlinedButton, Icons.travel_explore);
        expect(reanalyzeButton, findsOneWidget);
        await tester.tap(reanalyzeButton);
        await tester.pump(); // Show loading

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        await tester.pumpAndSettle(); // Re-analysis completes

        expect(find.text('Re-analyzed Item'), findsOneWidget);
        expect(find.text('Re-analyzed Category'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text('Re-analysis complete! Classification updated.'), findsOneWidget);

        // Verify the key of ClassificationFeedbackWidget changed (indirectly)
        final feedbackWidget = tester.widget<ClassificationFeedbackWidget>(find.byType(ClassificationFeedbackWidget));
        expect(feedbackWidget.key, equals(Key(reanalyzedId)));
      });

      testWidgets('Failed re-analysis (AI Error) shows SnackBar and keeps old data', (WidgetTester tester) async {
        final initialClassification = createMockClassification(itemName: 'AI Error Item', category: 'AI Error Category', imageUrl: '/fake/image.png');
        when(mockAiService.handleUserCorrection(
            originalClassification: anyNamed('originalClassification'),
            userCorrection: anyNamed('userCorrection'),
            userReason: anyNamed('userReason'),
            imageFile: anyNamed('imageFile')))
        .thenThrow(Exception('AI service failed'));

        await tester.pumpWidget(createTestableWidget(ResultScreen(classification: initialClassification)));
        await tester.pumpAndSettle();

        await tester.tap(find.ancestor(of: find.text('No, incorrect'), matching: find.byType(RadioListTile<bool>)));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithIcon(OutlinedButton, Icons.travel_explore));
        await tester.pump();
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        await tester.pumpAndSettle();

        expect(find.text('AI Error Item'), findsOneWidget); // Original data
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.textContaining('Re-analysis failed: AI service failed'), findsOneWidget);
      });

      testWidgets('Failed re-analysis (Image File Error) shows SnackBar and no AI call', (WidgetTester tester) async {
        final initialClassification = createMockClassification(itemName: 'No Image Item', imageUrl: null); // No image

        await tester.pumpWidget(createTestableWidget(ResultScreen(classification: initialClassification)));
        await tester.pumpAndSettle();

        await tester.tap(find.ancestor(of: find.text('No, incorrect'), matching: find.byType(RadioListTile<bool>)));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithIcon(OutlinedButton, Icons.travel_explore));
        await tester.pumpAndSettle();

        expect(find.text('Original image not available for re-analysis.'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        verifyNever(mockAiService.handleUserCorrection(
            originalClassification: anyNamed('originalClassification'),
            userCorrection: anyNamed('userCorrection'),
            userReason: anyNamed('userReason'),
            imageFile: anyNamed('imageFile')));
      });
    });
  });
}
