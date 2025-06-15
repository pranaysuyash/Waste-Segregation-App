import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:waste_segregation_app/screens/result_screen.dart';
import 'package:waste_segregation_app/services/storage_service.dart';
import 'package:waste_segregation_app/services/gamification_service.dart';
import 'package:waste_segregation_app/services/analytics_service.dart';
import 'package:waste_segregation_app/services/ai_service.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/widgets/classification_feedback_widget.dart';

// Mock services
class MockStorageService extends Mock implements StorageService {}
class MockGamificationService extends Mock implements GamificationService {}
class MockAnalyticsService extends Mock implements AnalyticsService {}
class MockAiService extends Mock implements AiService {}

void main() {
  group('ResultScreen Widget Tests', () {
    late MockStorageService mockStorageService;
    late MockGamificationService mockGamificationService;
    late MockAnalyticsService mockAnalyticsService;
    late MockAiService mockAiService;

    setUp(() {
      mockStorageService = MockStorageService();
      mockGamificationService = MockGamificationService();
      mockAnalyticsService = MockAnalyticsService();
      mockAiService = MockAiService();
    });

    Widget createResultScreen(WasteClassification classification) {
      return MaterialApp(
        home: MultiProvider(
          providers: [
            Provider<StorageService>.value(value: mockStorageService),
            Provider<GamificationService>.value(value: mockGamificationService),
            Provider<AnalyticsService>.value(value: mockAnalyticsService),
            Provider<AiService>.value(value: mockAiService),
          ],
          child: ResultScreen(classification: classification),
        ),
      );
    }

    group('Classification Display', () {
      testWidgets('should display classification results correctly', (WidgetTester tester) async {
        final classification = WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
          itemName: 'Plastic Water Bottle',
          subcategory: 'Plastic',
          explanation: 'Clear plastic bottle, recyclable with PET code 1. This type of plastic is widely accepted in recycling programs.',
            primaryMethod: 'Recycle in blue bin',
            steps: ['Remove cap and label', 'Rinse thoroughly', 'Place in recycling bin'],
            hasUrgentTimeframe: false,
            warnings: ['Ensure bottle is empty'],
            tips: ['Check for recycling code'],
          ),
          timestamp: DateTime.now(),
          region: 'Test Region',
          visualFeatures: ['plastic', 'bottle', 'clear', 'PET'],
          alternatives: [
            AlternativeClassification(
              category: 'Non-Waste',
              subcategory: 'Reusable',
              confidence: 0.3,
              reason: 'Could be reused as storage container',
            ),
          ],
          confidence: 0.92,
          isRecyclable: true,
          isCompostable: false,
          requiresSpecialDisposal: false,
          recyclingCode: 1,
          materialType: 'PET Plastic',
        );

        await tester.pumpWidget(createResultScreen(classification));
        await tester.pumpAndSettle();

        // Verify main classification details
        expect(find.text('Plastic Water Bottle'), findsOneWidget);
        expect(find.text('Dry Waste'), findsOneWidget);
        expect(find.text('Plastic'), findsOneWidget);
        expect(find.textContaining('Clear plastic bottle'), findsOneWidget);
        expect(find.text('92%'), findsOneWidget); // Confidence score

        // Verify disposal instructions
        expect(find.text('Recycle in blue bin'), findsOneWidget);
        expect(find.text('Remove cap and label'), findsOneWidget);
        expect(find.text('Rinse thoroughly'), findsOneWidget);
        expect(find.text('Place in recycling bin'), findsOneWidget);

        // Verify additional information
        expect(find.text('PET Plastic'), findsOneWidget);
        expect(find.textContaining('Recyclable'), findsOneWidget);
      });

      testWidgets('should handle long item names without overflow', (WidgetTester tester) async {
        final classification = WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
          itemName: 'Very Long Item Name That Could Potentially Cause Text Overflow Issues In The UI Components',
          subcategory: 'Plastic',
          explanation: 'This is a very long explanation that contains a lot of detailed information about the waste item and its classification, disposal methods, environmental impact, and various other relevant details that users might find useful.',
            primaryMethod: 'Very detailed disposal method with extensive instructions',
            steps: [
              'This is a very long step with detailed instructions that might cause overflow',
              'Another lengthy step with comprehensive guidance for proper disposal',
              'Final step with additional safety precautions and environmental considerations'
            ],
            hasUrgentTimeframe: false,
          ),
          timestamp: DateTime.now(),
          region: 'Test Region',
          visualFeatures: ['very', 'long', 'list', 'of', 'visual', 'features', 'detected'],
          alternatives: [],
          confidence: 0.85,
        );

        await tester.pumpWidget(createResultScreen(classification));
        await tester.pumpAndSettle();

        // Verify no overflow errors
        expect(tester.takeException(), isNull);

        // Check for text overflow widgets or ellipsis
        final textWidgets = find.byType(Text);
        expect(textWidgets, findsWidgets);

        // Verify scrollable areas are present for long content
        expect(find.byType(SingleChildScrollView), findsWidgets);
      });

      testWidgets('should show confidence scores appropriately', (WidgetTester tester) async {
        final highConfidenceClassification = WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
          itemName: 'Clear Plastic Bottle',
          explanation: 'High confidence classification',
            primaryMethod: 'Recycle',
            steps: ['Recycle'],
            hasUrgentTimeframe: false,
          ),
          timestamp: DateTime.now(),
          region: 'Test Region',
          visualFeatures: [],
          alternatives: [],
          confidence: 0.95,
        );

        await tester.pumpWidget(createResultScreen(highConfidenceClassification));
        await tester.pumpAndSettle();

        expect(find.text('95%'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle), findsOneWidget); // High confidence icon

        // Test low confidence classification
        final lowConfidenceClassification = highConfidenceClassification.copyWith(
          confidence: 0.65,
        );

        await tester.pumpWidget(createResultScreen(lowConfidenceClassification));
        await tester.pumpAndSettle();

        expect(find.text('65%'), findsOneWidget);
        expect(find.byIcon(Icons.warning), findsOneWidget); // Low confidence warning
        expect(find.textContaining('uncertain'), findsOneWidget);
      });

      testWidgets('should display alternative classifications', (WidgetTester tester) async {
        final classification = WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
          itemName: 'Glass Jar',
          explanation: 'Glass container',
            primaryMethod: 'Recycle',
            steps: ['Clean', 'Recycle'],
            hasUrgentTimeframe: false,
          ),
          timestamp: DateTime.now(),
          region: 'Test Region',
          visualFeatures: ['glass'],
          alternatives: [
            AlternativeClassification(
              category: 'Non-Waste',
              subcategory: 'Reusable',
              confidence: 0.4,
              reason: 'Could be reused for storage',
            ),
            AlternativeClassification(
              category: 'Hazardous Waste',
              subcategory: 'Broken Glass',
              confidence: 0.2,
              reason: 'If broken, requires special handling',
            ),
          ],
          confidence: 0.8,
        );

        await tester.pumpWidget(createResultScreen(classification));
        await tester.pumpAndSettle();

        expect(find.textContaining('Alternative'), findsOneWidget);
        expect(find.text('Non-Waste'), findsOneWidget);
        expect(find.text('Reusable'), findsOneWidget);
        expect(find.text('Hazardous Waste'), findsOneWidget);
        expect(find.textContaining('storage'), findsOneWidget);
        expect(find.textContaining('special handling'), findsOneWidget);
      });
    });

    group('User Actions', () {
      testWidgets('should allow saving to history', (WidgetTester tester) async {
        final classification = _createTestClassification();

        when(mockStorageService.saveClassification(any))
            .thenAnswer((_) async => {});
        when(mockGamificationService.processClassification(any))
            .thenAnswer((_) async => {});

        await tester.pumpWidget(createResultScreen(classification));
        await tester.pumpAndSettle();

        final saveButton = find.byKey(const Key('save_button'));
        expect(saveButton, findsOneWidget);

        await tester.tap(saveButton);
        await tester.pumpAndSettle();

        verify(mockStorageService.saveClassification(any)).called(1);
        verify(mockGamificationService.processClassification(any)).called(1);
        expect(find.textContaining('Saved'), findsOneWidget);
      });

      testWidgets('should provide share functionality', (WidgetTester tester) async {
        final classification = _createTestClassification();

        await tester.pumpWidget(createResultScreen(classification));
        await tester.pumpAndSettle();

        final shareButton = find.byKey(const Key('share_button'));
        expect(shareButton, findsOneWidget);

        await tester.tap(shareButton);
        await tester.pumpAndSettle();

        // Verify analytics tracking for share action
        verify(mockAnalyticsService.trackEvent(any)).called(greaterThan(0));
      });

      testWidgets('should handle re-analysis requests', (WidgetTester tester) async {
        final classification = _createTestClassification();

        when(mockAiService.analyzeWebImage(any, any))
            .thenAnswer((_) async => classification.copyWith(
              confidence: 0.88,
              explanation: 'Re-analyzed classification',
            ));

        await tester.pumpWidget(createResultScreen(classification));
        await tester.pumpAndSettle();

        // Tap on "Not sure about this result?" or re-analyze button
        final reAnalyzeButton = find.byKey(const Key('re_analyze_button'));
        expect(reAnalyzeButton, findsOneWidget);

        await tester.tap(reAnalyzeButton);
        await tester.pumpAndSettle();

        // Should show loading indicator
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Should show updated results
        expect(find.textContaining('Re-analyzed'), findsOneWidget);
        verify(mockAiService.analyzeWebImage(any, any)).called(1);
      });

      testWidgets('should integrate feedback widget', (WidgetTester tester) async {
        final classification = _createTestClassification();

        await tester.pumpWidget(createResultScreen(classification));
        await tester.pumpAndSettle();

        expect(find.byType(ClassificationFeedbackWidget), findsOneWidget);

        // Test feedback interactions
        final thumbsUpButton = find.byKey(const Key('feedback_correct'));
        expect(thumbsUpButton, findsOneWidget);

        await tester.tap(thumbsUpButton);
        await tester.pumpAndSettle();

        expect(find.textContaining('Thank you'), findsOneWidget);
      });
    });

    group('Disposal Instructions', () {
      testWidgets('should display detailed disposal instructions', (WidgetTester tester) async {
        final classification = WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
          itemName: 'Hazardous Battery',
          subcategory: 'Electronic Waste',
          explanation: 'Contains toxic materials',
            primaryMethod: 'Take to hazardous waste facility',
            steps: [
              'Do not throw in regular trash',
              'Find local e-waste center',
              'Transport safely in original packaging',
              'Drop off during operating hours'
            ],
            hasUrgentTimeframe: true,
            timeframe: 'Within 30 days',
            warnings: [
              'Do not puncture or damage',
              'Keep away from children',
              'Avoid extreme temperatures'
            ],
            tips: [
              'Many retailers offer take-back programs',
              'Check manufacturer recycling options'
            ],
            location: 'Certified e-waste facility',
          ),
          timestamp: DateTime.now(),
          region: 'Test Region',
          visualFeatures: ['battery', 'electronic'],
          alternatives: [],
          confidence: 0.9,
          requiresSpecialDisposal: true,
        );

        await tester.pumpWidget(createResultScreen(classification));
        await tester.pumpAndSettle();

        // Verify urgent disposal notice
        expect(find.textContaining('Urgent'), findsOneWidget);
        expect(find.textContaining('Within 30 days'), findsOneWidget);

        // Verify detailed steps
        expect(find.textContaining('Do not throw in regular trash'), findsOneWidget);
        expect(find.textContaining('Find local e-waste center'), findsOneWidget);

        // Verify warnings
        expect(find.textContaining('Do not puncture'), findsOneWidget);
        expect(find.textContaining('Keep away from children'), findsOneWidget);

        // Verify tips
        expect(find.textContaining('take-back programs'), findsOneWidget);

        // Verify special disposal indicator
        expect(find.byIcon(Icons.warning), findsWidgets);
      });

      testWidgets('should show location-specific disposal information', (WidgetTester tester) async {
        final classification = WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
          itemName: 'Paper Box',
          subcategory: 'Paper',
          explanation: 'Recyclable cardboard',
            primaryMethod: 'Recycle in blue bin',
            steps: ['Flatten the box', 'Remove any tape', 'Place in recycling bin'],
            hasUrgentTimeframe: false,
            location: 'Curbside recycling',
            localInfo: {
              'collection_day': 'Tuesday',
              'bin_type': 'Blue recycling bin',
              'facility': 'City Recycling Center'
            },
          ),
          timestamp: DateTime.now(),
          region: 'Bangalore, India',
          visualFeatures: ['cardboard', 'box'],
          alternatives: [],
          confidence: 0.88,
        );

        await tester.pumpWidget(createResultScreen(classification));
        await tester.pumpAndSettle();

        expect(find.textContaining('Bangalore'), findsOneWidget);
        expect(find.textContaining('Tuesday'), findsOneWidget);
        expect(find.textContaining('Blue recycling bin'), findsOneWidget);
        expect(find.textContaining('City Recycling Center'), findsOneWidget);
      });
    });

    group('Environmental Impact', () {
      testWidgets('should display environmental impact information', (WidgetTester tester) async {
        final classification = WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
          itemName: 'Aluminum Can',
          subcategory: 'Metal',
          explanation: 'Highly recyclable aluminum',
            primaryMethod: 'Recycle',
            steps: ['Rinse clean', 'Recycle'],
            hasUrgentTimeframe: false,
          ),
          timestamp: DateTime.now(),
          region: 'Test Region',
          visualFeatures: ['aluminum', 'can'],
          alternatives: [],
          confidence: 0.93,
          isRecyclable: true,
          environmentalImpact: {
            'co2_saved': '0.5 kg',
            'energy_saved': '95%',
            'water_saved': '90%',
            'recyclability': 'Infinite'
          },
        );

        await tester.pumpWidget(createResultScreen(classification));
        await tester.pumpAndSettle();

        expect(find.textContaining('Environmental Impact'), findsOneWidget);
        expect(find.textContaining('0.5 kg'), findsOneWidget); // CO2 saved
        expect(find.textContaining('95%'), findsOneWidget); // Energy saved
        expect(find.textContaining('90%'), findsOneWidget); // Water saved
        expect(find.textContaining('Infinite'), findsOneWidget); // Recyclability
      });

      testWidgets('should show gamification rewards for environmentally positive actions', (WidgetTester tester) async {
        final classification = _createTestClassification();

        when(mockGamificationService.processClassification(any))
            .thenAnswer((_) async => {
              'points_earned': 10,
              'achievements_unlocked': ['Eco Warrior'],
              'streak_bonus': 5,
            });

        await tester.pumpWidget(createResultScreen(classification));
        await tester.pumpAndSettle();

        // Tap save to trigger gamification
        await tester.tap(find.byKey(const Key('save_button')));
        await tester.pumpAndSettle();

        expect(find.textContaining('10 points'), findsOneWidget);
        expect(find.textContaining('Eco Warrior'), findsOneWidget);
        expect(find.textContaining('streak bonus'), findsOneWidget);
      });
    });

    group('Error Handling', () {
      testWidgets('should handle save failures gracefully', (WidgetTester tester) async {
        final classification = _createTestClassification();

        when(mockStorageService.saveClassification(any))
            .thenThrow(Exception('Storage error'));

        await tester.pumpWidget(createResultScreen(classification));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('save_button')));
        await tester.pumpAndSettle();

        expect(find.textContaining('Error saving'), findsOneWidget);
        expect(find.byIcon(Icons.error), findsOneWidget);

        // Should provide retry option
        final retryButton = find.byKey(const Key('retry_save_button'));
        expect(retryButton, findsOneWidget);
      });

      testWidgets('should handle re-analysis failures', (WidgetTester tester) async {
        final classification = _createTestClassification();

        when(mockAiService.analyzeWebImage(any, any))
            .thenThrow(Exception('AI service error'));

        await tester.pumpWidget(createResultScreen(classification));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('re_analyze_button')));
        await tester.pumpAndSettle();

        await tester.pumpAndSettle(const Duration(seconds: 2));

        expect(find.textContaining('Analysis failed'), findsOneWidget);
        expect(find.textContaining('Try again'), findsOneWidget);
      });

      testWidgets('should handle network connectivity issues', (WidgetTester tester) async {
        final classification = _createTestClassification();

        when(mockAnalyticsService.trackEvent(any))
            .thenThrow(Exception('Network error'));

        await tester.pumpWidget(createResultScreen(classification));
        await tester.pumpAndSettle();

        // Should still function without analytics
        expect(find.text(classification.itemName), findsOneWidget);
        expect(find.byKey(const Key('save_button')), findsOneWidget);
      });
    });

    group('Accessibility', () {
      testWidgets('should provide semantic labels for screen readers', (WidgetTester tester) async {
        final classification = _createTestClassification();

        await tester.pumpWidget(createResultScreen(classification));
        await tester.pumpAndSettle();

        expect(find.bySemanticsLabel('Classification result'), findsOneWidget);
        expect(find.bySemanticsLabel('Save to history'), findsOneWidget);
        expect(find.bySemanticsLabel('Share result'), findsOneWidget);
        expect(find.bySemanticsLabel('Request re-analysis'), findsOneWidget);
      });

      testWidgets('should support keyboard navigation', (WidgetTester tester) async {
        final classification = _createTestClassification();

        await tester.pumpWidget(createResultScreen(classification));
        await tester.pumpAndSettle();

        // Test tab navigation between interactive elements
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();

        expect(tester.binding.focusManager.primaryFocus, isNotNull);

        // Test Enter key activation
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
      });

      testWidgets('should announce important changes to screen readers', (WidgetTester tester) async {
        final classification = _createTestClassification();

        await tester.pumpWidget(createResultScreen(classification));
        await tester.pumpAndSettle();

        // Mock screen reader announcements
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.accessibility,
          (call) async {
            if (call.method == 'announce') {
              // Verify announcements are made
              expect(call.arguments, isA<Map>());
            }
            return null;
          },
        );

        await tester.tap(find.byKey(const Key('save_button')));
        await tester.pumpAndSettle();
      });
    });

    group('Performance', () {
      testWidgets('should render large classifications efficiently', (WidgetTester tester) async {
        final largeClassification = WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
          itemName: 'Complex Multi-Material Item',
          subcategory: 'Composite',
          explanation: 'A' * 5000, // Very long explanation
            primaryMethod: 'Special handling required',
            steps: List.generate(50, (i) => 'Step ${i + 1}: ${'Detailed instruction ' * 10}'),
            hasUrgentTimeframe: false,
            warnings: List.generate(20, (i) => 'Warning ${i + 1}: ${'Important safety note ' * 5}'),
            tips: List.generate(15, (i) => 'Tip ${i + 1}: ${'Helpful advice ' * 8}'),
          ),
          timestamp: DateTime.now(),
          region: 'Test Region',
          visualFeatures: List.generate(100, (i) => 'feature_$i'),
          alternatives: List.generate(10, (i) => AlternativeClassification(
            category: 'Category $i',
            subcategory: 'Subcategory $i',
            confidence: 0.1 + (i * 0.08),
            reason: 'Detailed reason $i with extensive explanation',
          )),
          confidence: 0.75,
        );

        final stopwatch = Stopwatch()..start();
        await tester.pumpWidget(createResultScreen(largeClassification));
        await tester.pumpAndSettle();
        stopwatch.stop();

        // Should render within reasonable time (adjust threshold as needed)
        expect(stopwatch.elapsedMilliseconds, lessThan(5000));

        // Should not cause memory issues
        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle image loading efficiently', (WidgetTester tester) async {
        final classification = _createTestClassification();
        
        // Add image path to classification
        final classificationWithImage = classification.copyWith(
          imageUrl: 'test_image.jpg',
        );

        await tester.pumpWidget(createResultScreen(classificationWithImage));
        await tester.pumpAndSettle();

        // Should show image placeholder or loading state
        expect(find.byType(Image), findsWidgets);
      });
    });
  });
}

// Helper function to create test classification
WasteClassification _createTestClassification() {
  return WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
    itemName: 'Test Item',
    subcategory: 'Plastic',
    explanation: 'Test classification for UI testing',
      primaryMethod: 'Recycle',
      steps: ['Clean item', 'Place in recycling bin'],
      hasUrgentTimeframe: false,
    ),
    timestamp: DateTime.now(),
    region: 'Test Region',
    visualFeatures: ['test', 'plastic'],
    alternatives: [],
    confidence: 0.85,
    isRecyclable: true,
  );
}
