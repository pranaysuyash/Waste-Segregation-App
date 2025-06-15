import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:waste_segregation_app/widgets/classification_feedback_widget.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/services/ai_service.dart';

import 'classification_feedback_widget_test.mocks.dart';

@GenerateMocks([AiService])
void main() {
  group('ClassificationFeedbackWidget Tests', () {
    late MockAiService mockAiService;
    late WasteClassification testClassification;
    late Function(WasteClassification) mockOnFeedbackSubmitted;
    late List<WasteClassification> submittedClassifications;

    setUp(() {
      mockAiService = MockAiService();
      submittedClassifications = [];
      mockOnFeedbackSubmitted = (classification) {
        submittedClassifications.add(classification);
      };

      testClassification = WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
        id: 'test-id',
        itemName: 'Test Item',
        subcategory: 'Paper',
        explanation: 'This is a test item for classification feedback testing.',
          primaryMethod: 'Recycle in paper bin',
          steps: ['Remove any plastic components', 'Place in recycling bin'],
          hasUrgentTimeframe: false,
        ),
        region: 'Test Region',
        visualFeatures: ['paper', 'white', 'rectangular'],
        alternatives: [
          AlternativeClassification(
            category: 'Wet Waste',
            subcategory: 'Compostable',
            confidence: 0.2,
            reason: 'Could be compostable if organic',
          ),
        ],
        confidence: 0.85,
        timestamp: DateTime.now(),
      );
    });

    Widget createTestWidget({
      bool showCompactVersion = false,
      WasteClassification? classification,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Provider<AiService>.value(
            value: mockAiService,
            child: ClassificationFeedbackWidget(
              classification: classification ?? testClassification,
              onFeedbackSubmitted: mockOnFeedbackSubmitted,
              showCompactVersion: showCompactVersion,
            ),
          ),
        ),
      );
    }

    group('Widget Construction', () {
      testWidgets('should render compact feedback widget', (tester) async {
        await tester.pumpWidget(createTestWidget(showCompactVersion: true));

        expect(find.text('Was this classification correct?'), findsOneWidget);
        expect(find.text('Correct'), findsOneWidget);
        expect(find.text('Incorrect'), findsOneWidget);
      });

      testWidgets('should render full feedback widget', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.text('Your feedback helps train our AI model to be more accurate.'), findsOneWidget);
        expect(find.text('Is this classification correct?'), findsOneWidget);
        expect(find.text('Yes'), findsOneWidget);
        expect(find.text('No'), findsOneWidget);
      });

      testWidgets('should display classification details', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.textContaining('Test Item'), findsOneWidget);
        expect(find.textContaining('Dry Waste'), findsOneWidget);
      });

      testWidgets('should handle widget disposal properly', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        // Navigate away to trigger disposal
        await tester.pumpWidget(const MaterialApp(home: Text('Different Widget')));
        
        // Should complete without errors
        expect(find.text('Different Widget'), findsOneWidget);
      });
    });

    group('User Confirmation', () {
      testWidgets('should handle correct confirmation in compact mode', (tester) async {
        await tester.pumpWidget(createTestWidget(showCompactVersion: true));

        await tester.tap(find.text('Correct'));
        await tester.pumpAndSettle();

        expect(submittedClassifications.length, equals(1));
        expect(submittedClassifications.first.userConfirmed, isTrue);
        expect(submittedClassifications.first.userCorrection, isNull);
      });

      testWidgets('should handle incorrect confirmation in compact mode', (tester) async {
        await tester.pumpWidget(createTestWidget(showCompactVersion: true));

        await tester.tap(find.text('Incorrect'));
        await tester.pumpAndSettle();

        expect(find.text('What should it be?'), findsOneWidget);
        expect(find.text('Wet Waste'), findsOneWidget);
        expect(find.text('Hazardous Waste'), findsOneWidget);
      });

      testWidgets('should handle correct confirmation in full mode', (tester) async {
        await tester.pumpWidget(createTestWidget());

        await tester.tap(find.text('Yes'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Submit Feedback'));
        await tester.pumpAndSettle();

        expect(submittedClassifications.length, equals(1));
        expect(submittedClassifications.first.userConfirmed, isTrue);
      });

      testWidgets('should handle incorrect confirmation in full mode', (tester) async {
        await tester.pumpWidget(createTestWidget());

        await tester.tap(find.text('No'));
        await tester.pumpAndSettle();

        expect(find.text('What should the correct classification be?'), findsOneWidget);
        expect(find.text('Wet Waste'), findsOneWidget);
        expect(find.text('Dry Waste'), findsOneWidget);
      });

      testWidgets('should maintain state when switching between options', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Select incorrect first
        await tester.tap(find.text('No'));
        await tester.pumpAndSettle();

        expect(find.text('What should the correct classification be?'), findsOneWidget);

        // Switch back to correct
        await tester.tap(find.text('Yes'));
        await tester.pumpAndSettle();

        expect(find.text('What should the correct classification be?'), findsNothing);
      });
    });

    group('Correction Options', () {
      testWidgets('should show correction options when incorrect is selected', (tester) async {
        await tester.pumpWidget(createTestWidget(showCompactVersion: true));

        await tester.tap(find.text('Incorrect'));
        await tester.pumpAndSettle();

        final correctionOptions = [
          'Wet Waste',
          'Dry Waste',
          'Hazardous Waste',
          'Medical Waste',
          'Non-Waste',
          'Different subcategory',
          'Wrong material type',
          'Custom correction...'
        ];

        // Should show at least the first 4 correction options in compact mode
        expect(find.text('Wet Waste'), findsOneWidget);
        expect(find.text('Dry Waste'), findsOneWidget);
        expect(find.text('Hazardous Waste'), findsOneWidget);
        expect(find.text('Medical Waste'), findsOneWidget);
      });

      testWidgets('should handle correction selection', (tester) async {
        await tester.pumpWidget(createTestWidget(showCompactVersion: true));

        await tester.tap(find.text('Incorrect'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Wet Waste'));
        await tester.pumpAndSettle();

        // The chip should show as selected
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
      });

      testWidgets('should handle custom correction option', (tester) async {
        await tester.pumpWidget(createTestWidget());

        await tester.tap(find.text('No'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Custom correction...'));
        await tester.pumpAndSettle();

        expect(find.text('Custom correction'), findsOneWidget);
        expect(find.byType(TextField), findsAtLeastNWidgets(1));
      });

      testWidgets('should handle custom correction input', (tester) async {
        await tester.pumpWidget(createTestWidget());

        await tester.tap(find.text('No'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Custom correction...'));
        await tester.pumpAndSettle();

        const customCorrection = 'Electronic Waste';
        await tester.enterText(
          find.widgetWithText(TextField, 'Custom correction'),
          customCorrection,
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Submit Feedback'));
        await tester.pumpAndSettle();

        expect(submittedClassifications.length, equals(1));
        expect(submittedClassifications.first.userCorrection, equals(customCorrection));
        expect(submittedClassifications.first.userConfirmed, isFalse);
      });

      testWidgets('should clear custom correction when selecting predefined option', (tester) async {
        await tester.pumpWidget(createTestWidget());

        await tester.tap(find.text('No'));
        await tester.pumpAndSettle();

        // First select custom correction
        await tester.tap(find.text('Custom correction...'));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.widgetWithText(TextField, 'Custom correction'),
          'Some custom text',
        );

        // Then select a predefined option
        await tester.tap(find.text('Wet Waste'));
        await tester.pumpAndSettle();

        // Custom correction field should not be visible
        expect(find.widgetWithText(TextField, 'Custom correction'), findsNothing);
      });
    });

    group('Notes and Additional Information', () {
      testWidgets('should handle notes input in full mode', (tester) async {
        await tester.pumpWidget(createTestWidget());

        const noteText = 'This item had a confusing label';
        await tester.enterText(
          find.widgetWithText(TextField, 'Additional notes (optional)'),
          noteText,
        );

        await tester.tap(find.text('Yes'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Submit Feedback'));
        await tester.pumpAndSettle();

        expect(submittedClassifications.length, equals(1));
        expect(submittedClassifications.first.userNotes, equals(noteText));
      });

      testWidgets('should handle empty notes gracefully', (tester) async {
        await tester.pumpWidget(createTestWidget());

        await tester.tap(find.text('Yes'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Submit Feedback'));
        await tester.pumpAndSettle();

        expect(submittedClassifications.length, equals(1));
        expect(submittedClassifications.first.userNotes, isNull);
      });

      testWidgets('should trim whitespace from notes', (tester) async {
        await tester.pumpWidget(createTestWidget());

        const noteText = '  This note has whitespace  ';
        await tester.enterText(
          find.widgetWithText(TextField, 'Additional notes (optional)'),
          noteText,
        );

        await tester.tap(find.text('Yes'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Submit Feedback'));
        await tester.pumpAndSettle();

        expect(submittedClassifications.first.userNotes, equals('This note has whitespace'));
      });
    });

    group('Compact Mode Specific Features', () {
      testWidgets('should show more options expansion in compact mode', (tester) async {
        await tester.pumpWidget(createTestWidget(showCompactVersion: true));

        await tester.tap(find.text('Incorrect'));
        await tester.pumpAndSettle();

        expect(find.text('More options'), findsOneWidget);

        await tester.tap(find.text('More options'));
        await tester.pumpAndSettle();

        expect(find.text('Less options'), findsOneWidget);
        expect(find.text('Additional notes (optional)'), findsOneWidget);
      });

      testWidgets('should handle responsive layout in compact mode', (tester) async {
        // Test narrow screen
        tester.binding.window.physicalSizeTestValue = const Size(300, 600);
        tester.binding.window.devicePixelRatioTestValue = 1.0;

        await tester.pumpWidget(createTestWidget(showCompactVersion: true));

        await tester.tap(find.text('Incorrect'));
        await tester.pumpAndSettle();

        // Should show buttons in column layout for narrow screens
        expect(find.text('Correct'), findsOneWidget);
        expect(find.text('Incorrect'), findsOneWidget);

        addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
        addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);
      });

      testWidgets('should handle wide screen layout in compact mode', (tester) async {
        // Test wide screen
        tester.binding.window.physicalSizeTestValue = const Size(800, 600);
        tester.binding.window.devicePixelRatioTestValue = 1.0;

        await tester.pumpWidget(createTestWidget(showCompactVersion: true));

        // Should show buttons in row layout for wide screens
        expect(find.text('Correct'), findsOneWidget);
        expect(find.text('Incorrect'), findsOneWidget);

        addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
        addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);
      });
    });

    group('Reanalysis Functionality', () {
      testWidgets('should show reanalysis button when correction is selected', (tester) async {
        await tester.pumpWidget(createTestWidget(showCompactVersion: true));

        await tester.tap(find.text('Incorrect'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Wet Waste'));
        await tester.pumpAndSettle();

        expect(find.text('Re-analyze with correction'), findsOneWidget);
      });

      testWidgets('should handle reanalysis with mock AI service', (tester) async {
        final reanalyzedClassification = testClassification.copyWith(
          category: 'Wet Waste',
          confidence: 0.92,
        );

        when(mockAiService.handleUserCorrection(
          any,
          any,
          any,
          model: anyNamed('model'),
        )).thenAnswer((_) async => reanalyzedClassification);

        await tester.pumpWidget(createTestWidget(showCompactVersion: true));

        await tester.tap(find.text('Incorrect'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Wet Waste'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Re-analyze with correction'));
        await tester.pumpAndSettle();

        // Should show reanalyzing indicator
        expect(find.text('Re-analyzing with your correction...'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Wait for reanalysis to complete
        await tester.pumpAndSettle();

        verify(mockAiService.handleUserCorrection(
          any,
          'Wet Waste',
          any,
          model: anyNamed('model'),
        )).called(1);
      });

      testWidgets('should handle reanalysis error gracefully', (tester) async {
        when(mockAiService.handleUserCorrection(
          any,
          any,
          any,
          model: anyNamed('model'),
        )).thenThrow(Exception('Reanalysis failed'));

        await tester.pumpWidget(createTestWidget(showCompactVersion: true));

        await tester.tap(find.text('Incorrect'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Wet Waste'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Re-analyze with correction'));
        await tester.pumpAndSettle();

        // Wait for error handling
        await tester.pumpAndSettle();

        expect(find.text('Reanalysis failed'), findsOneWidget);
        expect(submittedClassifications.length, equals(1));
        expect(submittedClassifications.first.userCorrection, equals('Wet Waste'));
      });

      testWidgets('should handle exhausted models scenario', (tester) async {
        final classificationWithExhaustedModels = testClassification.copyWith(
          reanalysisModelsTried: [
            'gpt-4.1-nano',
            'gpt-4o-mini',
            'gpt-4.1-mini',
            'gemini-2.0-flash',
          ],
        );

        await tester.pumpWidget(createTestWidget(
          showCompactVersion: true,
          classification: classificationWithExhaustedModels,
        ));

        await tester.tap(find.text('Incorrect'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Wet Waste'));
        await tester.pumpAndSettle();

        expect(find.text('No more reanalysis possible'), findsOneWidget);
        expect(find.textContaining('All available AI models have been tried'), findsOneWidget);
      });
    });

    group('Feedback Submission', () {
      testWidgets('should submit feedback with all required information', (tester) async {
        await tester.pumpWidget(createTestWidget());

        await tester.tap(find.text('No'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Hazardous Waste'));
        await tester.pumpAndSettle();

        const noteText = 'This item contains batteries';
        await tester.enterText(
          find.widgetWithText(TextField, 'Additional notes (optional)'),
          noteText,
        );

        await tester.tap(find.text('Submit Feedback'));
        await tester.pumpAndSettle();

        expect(submittedClassifications.length, equals(1));
        final submitted = submittedClassifications.first;
        expect(submitted.userConfirmed, isFalse);
        expect(submitted.userCorrection, equals('Hazardous Waste'));
        expect(submitted.userNotes, equals(noteText));
        expect(submitted.category, equals('Hazardous Waste'));
        expect(submitted.viewCount, equals(1));
      });

      testWidgets('should update disposal instructions when correction is made', (tester) async {
        await tester.pumpWidget(createTestWidget(showCompactVersion: true));

        await tester.tap(find.text('Incorrect'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Hazardous Waste'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('More options'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Submit Feedback'));
        await tester.pumpAndSettle();

        final submitted = submittedClassifications.first;
        expect(submitted.category, equals('Hazardous Waste'));
        expect(submitted.disposalInstructions.primaryMethod, equals('Special disposal facility'));
        expect(submitted.disposalInstructions.hasUrgentTimeframe, isTrue);
      });

      testWidgets('should handle feedback submission without correction', (tester) async {
        await tester.pumpWidget(createTestWidget());

        await tester.tap(find.text('Yes'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Submit Feedback'));
        await tester.pumpAndSettle();

        expect(submittedClassifications.length, equals(1));
        final submitted = submittedClassifications.first;
        expect(submitted.userConfirmed, isTrue);
        expect(submitted.userCorrection, isNull);
        expect(submitted.category, equals(testClassification.category));
      });
    });

    group('FeedbackButton Widget', () {
      testWidgets('should render feedback button with no existing feedback', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FeedbackButton(
                classification: testClassification,
                onFeedbackSubmitted: mockOnFeedbackSubmitted,
              ),
            ),
          ),
        );

        expect(find.text('Give feedback'), findsOneWidget);
        expect(find.byIcon(Icons.feedback_outlined), findsOneWidget);
      });

      testWidgets('should render feedback button with existing feedback', (tester) async {
        final classificationWithFeedback = testClassification.copyWith(
          userConfirmed: true,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FeedbackButton(
                classification: classificationWithFeedback,
                onFeedbackSubmitted: mockOnFeedbackSubmitted,
              ),
            ),
          ),
        );

        expect(find.text('Feedback given'), findsOneWidget);
        expect(find.byIcon(Icons.feedback), findsOneWidget);
      });

      testWidgets('should open feedback dialog when tapped', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Provider<AiService>.value(
                value: mockAiService,
                child: FeedbackButton(
                  classification: testClassification,
                  onFeedbackSubmitted: mockOnFeedbackSubmitted,
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Give feedback'));
        await tester.pumpAndSettle();

        expect(find.text('Help us improve classification'), findsOneWidget);
        expect(find.byIcon(Icons.close), findsOneWidget);
      });

      testWidgets('should close feedback dialog when close button is tapped', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Provider<AiService>.value(
                value: mockAiService,
                child: FeedbackButton(
                  classification: testClassification,
                  onFeedbackSubmitted: mockOnFeedbackSubmitted,
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Give feedback'));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        expect(find.text('Help us improve classification'), findsNothing);
      });
    });

    group('Accessibility', () {
      testWidgets('should have proper semantics for correction chips', (tester) async {
        await tester.pumpWidget(createTestWidget(showCompactVersion: true));

        await tester.tap(find.text('Incorrect'));
        await tester.pumpAndSettle();

        // Check semantics for correction chips
        expect(
          tester.widget<Semantics>(
            find.ancestor(
              of: find.text('Wet Waste'),
              matching: find.byType(Semantics),
            ),
          ).properties.button,
          isTrue,
        );
      });

      testWidgets('should have proper tooltips and labels', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Provider<AiService>.value(
                value: mockAiService,
                child: FeedbackButton(
                  classification: testClassification,
                  onFeedbackSubmitted: mockOnFeedbackSubmitted,
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Give feedback'));
        await tester.pumpAndSettle();

        expect(find.byTooltip('Close feedback dialog'), findsOneWidget);
      });

      testWidgets('should handle focus navigation properly', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Should be able to navigate through form elements
        await tester.tap(find.text('No'));
        await tester.pumpAndSettle();

        // Focus should work on interactive elements
        expect(find.byType(RadioListTile<bool>), findsNWidgets(2));
        expect(find.byType(TextField), findsAtLeastNWidgets(1));
      });
    });

    group('Edge Cases and Error Handling', () {
      testWidgets('should handle null classification gracefully', (tester) async {
        final nullFieldsClassification = WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
          id: 'test_id',
          itemName: 'Test Item',
          explanation: 'Test explanation',
            primaryMethod: 'Test disposal',
            steps: ['Test step'],
            hasUrgentTimeframe: false,
          ),
          region: 'Test Region',
          visualFeatures: [],
          alternatives: [],
          confidence: 0.5,
          timestamp: DateTime.now(),
        );

        await tester.pumpWidget(createTestWidget(
          classification: nullFieldsClassification,
        ));

        expect(find.text('Was this classification correct?'), findsOneWidget);
      });

      testWidgets('should handle very long classification names', (tester) async {
        final longNameClassification = testClassification.copyWith(
          itemName: 'This is a very long item name that should be handled gracefully by the widget even if it exceeds normal length expectations',
          category: 'Very Long Category Name That Should Not Break Layout',
        );

        await tester.pumpWidget(createTestWidget(
          classification: longNameClassification,
          showCompactVersion: true,
        ));

        expect(find.text('Was this classification correct?'), findsOneWidget);
      });

      testWidgets('should handle rapid button taps without crashing', (tester) async {
        await tester.pumpWidget(createTestWidget(showCompactVersion: true));

        // Rapidly tap correct button multiple times
        for (var i = 0; i < 5; i++) {
          await tester.tap(find.text('Correct'));
          await tester.pump();
        }

        await tester.pumpAndSettle();

        // Should only submit once
        expect(submittedClassifications.length, equals(1));
      });

      testWidgets('should preserve existing feedback when initializing', (tester) async {
        final existingFeedbackClassification = testClassification.copyWith(
          userConfirmed: false,
          userCorrection: 'Wet Waste',
          userNotes: 'Original note',
        );

        await tester.pumpWidget(createTestWidget(
          classification: existingFeedbackClassification,
        ));

        // Should show existing feedback state
        expect(find.text('Original note'), findsOneWidget);
      });

      testWidgets('should handle empty custom correction submission', (tester) async {
        await tester.pumpWidget(createTestWidget());

        await tester.tap(find.text('No'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Custom correction...'));
        await tester.pumpAndSettle();

        // Submit without entering custom text
        await tester.tap(find.text('Submit Feedback'));
        await tester.pumpAndSettle();

        expect(submittedClassifications.length, equals(1));
        expect(submittedClassifications.first.userCorrection, isNull);
      });
    });

    group('Performance Tests', () {
      testWidgets('should handle multiple feedback widgets without performance issues', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Provider<AiService>.value(
                value: mockAiService,
                child: ListView(
                  children: List.generate(10, (index) =>
                    ClassificationFeedbackWidget(
                      classification: testClassification.copyWith(id: 'test_$index'),
                      onFeedbackSubmitted: mockOnFeedbackSubmitted,
                      showCompactVersion: true,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        expect(find.text('Was this classification correct?'), findsNWidgets(10));
      });

      testWidgets('should efficiently handle state changes', (tester) async {
        await tester.pumpWidget(createTestWidget(showCompactVersion: true));

        final stopwatch = Stopwatch()..start();

        // Perform multiple state changes
        await tester.tap(find.text('Incorrect'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Wet Waste'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('More options'));
        await tester.pumpAndSettle();

        stopwatch.stop();

        // Should complete quickly (less than 1 second for state changes)
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });
    });
  });
}
