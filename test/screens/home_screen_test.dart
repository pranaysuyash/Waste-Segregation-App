import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:waste_segregation_app/screens/home_screen.dart';
import 'package:waste_segregation_app/services/ai_service.dart';
import 'package:waste_segregation_app/services/storage_service.dart';
import 'package:waste_segregation_app/services/gamification_service.dart';
import 'package:waste_segregation_app/services/analytics_service.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/models/gamification.dart';
import 'package:waste_segregation_app/models/user_profile.dart';

// Mock services
class MockAiService extends Mock implements AiService {}
class MockStorageService extends Mock implements StorageService {}
class MockGamificationService extends Mock implements GamificationService {}
class MockAnalyticsService extends Mock implements AnalyticsService {}

void main() {
  group('HomeScreen Widget Tests', () {
    late MockAiService mockAiService;
    late MockStorageService mockStorageService;
    late MockGamificationService mockGamificationService;
    late MockAnalyticsService mockAnalyticsService;

    setUp(() {
      mockAiService = MockAiService();
      mockStorageService = MockStorageService();
      mockGamificationService = MockGamificationService();
      mockAnalyticsService = MockAnalyticsService();
    });

    Widget createHomeScreen() {
      return MaterialApp(
        home: MultiProvider(
          providers: [
            Provider<AiService>.value(value: mockAiService),
            Provider<StorageService>.value(value: mockStorageService),
            Provider<GamificationService>.value(value: mockGamificationService),
            Provider<AnalyticsService>.value(value: mockAnalyticsService),
          ],
          child: HomeScreen(),
        ),
      );
    }

    group('Initial State', () {
      testWidgets('should display scan button prominently', (WidgetTester tester) async {
        // Setup mocks
        when(mockStorageService.getRecentClassifications(limit: any))
            .thenAnswer((_) async => []);
        when(mockGamificationService.getUserProfile())
            .thenAnswer((_) async => null);

        await tester.pumpWidget(createHomeScreen());
        await tester.pumpAndSettle();

        // Find scan button
        final scanButton = find.byKey(Key('scan_button'));
        expect(scanButton, findsOneWidget);

        // Verify button is prominent (check for specific styling)
        final FloatingActionButton fab = tester.widget(scanButton);
        expect(fab.backgroundColor, isNotNull);
        expect(fab.child, isA<Icon>());
      });

      testWidgets('should show welcome message for new users', (WidgetTester tester) async {
        when(mockStorageService.getRecentClassifications(limit: any))
            .thenAnswer((_) async => []);
        when(mockGamificationService.getUserProfile())
            .thenAnswer((_) async => null);

        await tester.pumpWidget(createHomeScreen());
        await tester.pumpAndSettle();

        expect(find.textContaining('Welcome'), findsOneWidget);
        expect(find.textContaining('Start by scanning'), findsOneWidget);
      });

      testWidgets('should display app branding and logo', (WidgetTester tester) async {
        when(mockStorageService.getRecentClassifications(limit: any))
            .thenAnswer((_) async => []);
        when(mockGamificationService.getUserProfile())
            .thenAnswer((_) async => null);

        await tester.pumpWidget(createHomeScreen());
        await tester.pumpAndSettle();

        expect(find.textContaining('Waste Segregation'), findsOneWidget);
        // Check for app logo or icon
        expect(find.byType(Icon), findsWidgets);
      });
    });

    group('Recent Classifications', () {
      testWidgets('should show recent classifications when available', (WidgetTester tester) async {
        final recentClassifications = [
          WasteClassification(
            itemName: 'Plastic Bottle',
            category: 'Dry Waste',
            subcategory: 'Plastic',
            explanation: 'Recyclable plastic bottle',
            disposalInstructions: DisposalInstructions(
              primaryMethod: 'Recycle',
              steps: ['Clean', 'Recycle'],
              hasUrgentTimeframe: false,
            ),
            timestamp: DateTime.now().subtract(Duration(hours: 1)),
            region: 'Test Region',
            visualFeatures: ['plastic', 'bottle'],
            alternatives: [],
            confidence: 0.95,
          ),
          WasteClassification(
            itemName: 'Apple Core',
            category: 'Wet Waste',
            subcategory: 'Food Waste',
            explanation: 'Compostable organic waste',
            disposalInstructions: DisposalInstructions(
              primaryMethod: 'Compost',
              steps: ['Compost bin'],
              hasUrgentTimeframe: false,
            ),
            timestamp: DateTime.now().subtract(Duration(hours: 2)),
            region: 'Test Region',
            visualFeatures: ['organic', 'fruit'],
            alternatives: [],
            confidence: 0.88,
          ),
        ];

        when(mockStorageService.getRecentClassifications(limit: any))
            .thenAnswer((_) async => recentClassifications);
        when(mockGamificationService.getUserProfile())
            .thenAnswer((_) async => null);

        await tester.pumpWidget(createHomeScreen());
        await tester.pumpAndSettle();

        expect(find.text('Recent Classifications'), findsOneWidget);
        expect(find.text('Plastic Bottle'), findsOneWidget);
        expect(find.text('Apple Core'), findsOneWidget);
        expect(find.text('Dry Waste'), findsOneWidget);
        expect(find.text('Wet Waste'), findsOneWidget);
      });

      testWidgets('should handle empty recent classifications gracefully', (WidgetTester tester) async {
        when(mockStorageService.getRecentClassifications(limit: any))
            .thenAnswer((_) async => []);
        when(mockGamificationService.getUserProfile())
            .thenAnswer((_) async => null);

        await tester.pumpWidget(createHomeScreen());
        await tester.pumpAndSettle();

        expect(find.textContaining('No recent classifications'), findsOneWidget);
        expect(find.textContaining('Start scanning'), findsOneWidget);
      });

      testWidgets('should navigate to history on view all tap', (WidgetTester tester) async {
        final recentClassifications = [
          _createTestClassification('Test Item', 'Dry Waste'),
        ];

        when(mockStorageService.getRecentClassifications(limit: any))
            .thenAnswer((_) async => recentClassifications);
        when(mockGamificationService.getUserProfile())
            .thenAnswer((_) async => null);

        await tester.pumpWidget(createHomeScreen());
        await tester.pumpAndSettle();

        final viewAllButton = find.byKey(Key('view_all_button'));
        expect(viewAllButton, findsOneWidget);

        await tester.tap(viewAllButton);
        await tester.pumpAndSettle();

        // Verify navigation occurred (would need navigation mock or route testing)
      });
    });

    group('Gamification Elements', () {
      testWidgets('should display user points and level', (WidgetTester tester) async {
        final userProfile = GamificationProfile(
          userId: 'test_user',
          points: UserPoints(total: 250, level: 2),
          streak: Streak(current: 5, longest: 10, lastUsageDate: DateTime.now()),
          achievements: [],
        );

        when(mockStorageService.getRecentClassifications(limit: any))
            .thenAnswer((_) async => []);
        when(mockGamificationService.getUserProfile())
            .thenAnswer((_) async => userProfile);

        await tester.pumpWidget(createHomeScreen());
        await tester.pumpAndSettle();

        expect(find.textContaining('250'), findsOneWidget); // Points
        expect(find.textContaining('Level 2'), findsOneWidget);
        expect(find.textContaining('Streak'), findsOneWidget);
        expect(find.textContaining('5'), findsOneWidget); // Current streak
      });

      testWidgets('should show achievement progress', (WidgetTester tester) async {
        final userProfile = GamificationProfile(
          userId: 'test_user',
          points: UserPoints(total: 150),
          streak: Streak(current: 3, longest: 8, lastUsageDate: DateTime.now()),
          achievements: [
            Achievement(
              id: 'waste_novice',
              title: 'Waste Novice',
              description: 'Classify 5 items',
              type: AchievementType.wasteIdentified,
              threshold: 5,
              iconName: 'star',
              color: Colors.blue,
              progress: 0.8,
            ),
          ],
        );

        when(mockStorageService.getRecentClassifications(limit: any))
            .thenAnswer((_) async => []);
        when(mockGamificationService.getUserProfile())
            .thenAnswer((_) async => userProfile);

        await tester.pumpWidget(createHomeScreen());
        await tester.pumpAndSettle();

        expect(find.textContaining('Waste Novice'), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
      });

      testWidgets('should display daily streak information', (WidgetTester tester) async {
        final userProfile = GamificationProfile(
          userId: 'test_user',
          points: UserPoints(total: 100),
          streak: Streak(
            current: 7,
            longest: 15,
            lastUsageDate: DateTime.now(),
          ),
          achievements: [],
        );

        when(mockStorageService.getRecentClassifications(limit: any))
            .thenAnswer((_) async => []);
        when(mockGamificationService.getUserProfile())
            .thenAnswer((_) async => userProfile);

        await tester.pumpWidget(createHomeScreen());
        await tester.pumpAndSettle();

        expect(find.textContaining('7'), findsOneWidget); // Current streak
        expect(find.textContaining('day'), findsWidgets); // Streak text
      });
    });

    group('Quick Actions', () {
      testWidgets('should provide quick action buttons', (WidgetTester tester) async {
        when(mockStorageService.getRecentClassifications(limit: any))
            .thenAnswer((_) async => []);
        when(mockGamificationService.getUserProfile())
            .thenAnswer((_) async => null);

        await tester.pumpWidget(createHomeScreen());
        await tester.pumpAndSettle();

        expect(find.byKey(Key('camera_button')), findsOneWidget);
        expect(find.byKey(Key('gallery_button')), findsOneWidget);
        expect(find.byKey(Key('history_button')), findsOneWidget);
        expect(find.byKey(Key('educational_content_button')), findsOneWidget);
      });

      testWidgets('should navigate to camera on camera button tap', (WidgetTester tester) async {
        when(mockStorageService.getRecentClassifications(limit: any))
            .thenAnswer((_) async => []);
        when(mockGamificationService.getUserProfile())
            .thenAnswer((_) async => null);

        await tester.pumpWidget(createHomeScreen());
        await tester.pumpAndSettle();

        final cameraButton = find.byKey(Key('camera_button'));
        expect(cameraButton, findsOneWidget);

        await tester.tap(cameraButton);
        await tester.pumpAndSettle();

        // Verify analytics tracking
        verify(mockAnalyticsService.trackEvent(any)).called(1);
      });

      testWidgets('should show educational content button', (WidgetTester tester) async {
        when(mockStorageService.getRecentClassifications(limit: any))
            .thenAnswer((_) async => []);
        when(mockGamificationService.getUserProfile())
            .thenAnswer((_) async => null);

        await tester.pumpWidget(createHomeScreen());
        await tester.pumpAndSettle();

        final educationButton = find.byKey(Key('educational_content_button'));
        expect(educationButton, findsOneWidget);
        expect(find.textContaining('Learn'), findsOneWidget);
      });
    });

    group('Error Handling', () {
      testWidgets('should handle no internet connection gracefully', (WidgetTester tester) async {
        when(mockStorageService.getRecentClassifications(limit: any))
            .thenThrow(Exception('No internet connection'));
        when(mockGamificationService.getUserProfile())
            .thenAnswer((_) async => null);

        await tester.pumpWidget(createHomeScreen());
        await tester.pumpAndSettle();

        // Should still show basic UI elements
        expect(find.byKey(Key('scan_button')), findsOneWidget);
        expect(find.textContaining('offline'), findsOneWidget);
      });

      testWidgets('should show error message for data loading failures', (WidgetTester tester) async {
        when(mockStorageService.getRecentClassifications(limit: any))
            .thenThrow(Exception('Database error'));
        when(mockGamificationService.getUserProfile())
            .thenThrow(Exception('Profile error'));

        await tester.pumpWidget(createHomeScreen());
        await tester.pumpAndSettle();

        expect(find.textContaining('Error'), findsWidgets);
        expect(find.byType(Icon), findsWidgets); // Error icons
      });

      testWidgets('should provide retry mechanism for failed operations', (WidgetTester tester) async {
        when(mockStorageService.getRecentClassifications(limit: any))
            .thenThrow(Exception('Temporary error'));
        when(mockGamificationService.getUserProfile())
            .thenAnswer((_) async => null);

        await tester.pumpWidget(createHomeScreen());
        await tester.pumpAndSettle();

        final retryButton = find.byKey(Key('retry_button'));
        expect(retryButton, findsOneWidget);

        // Setup successful retry
        when(mockStorageService.getRecentClassifications(limit: any))
            .thenAnswer((_) async => []);

        await tester.tap(retryButton);
        await tester.pumpAndSettle();

        // Should show success state
        expect(find.textContaining('Error'), findsNothing);
      });
    });

    group('Responsive Design', () {
      testWidgets('should adapt to different screen sizes', (WidgetTester tester) async {
        when(mockStorageService.getRecentClassifications(limit: any))
            .thenAnswer((_) async => []);
        when(mockGamificationService.getUserProfile())
            .thenAnswer((_) async => null);

        // Test on small screen
        tester.binding.window.physicalSizeTestValue = Size(320, 568);
        tester.binding.window.devicePixelRatioTestValue = 1.0;

        await tester.pumpWidget(createHomeScreen());
        await tester.pumpAndSettle();

        expect(find.byKey(Key('scan_button')), findsOneWidget);

        // Test on large screen
        tester.binding.window.physicalSizeTestValue = Size(414, 896);
        tester.binding.window.devicePixelRatioTestValue = 1.0;

        await tester.pumpWidget(createHomeScreen());
        await tester.pumpAndSettle();

        expect(find.byKey(Key('scan_button')), findsOneWidget);

        addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
        addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);
      });

      testWidgets('should handle orientation changes', (WidgetTester tester) async {
        when(mockStorageService.getRecentClassifications(limit: any))
            .thenAnswer((_) async => []);
        when(mockGamificationService.getUserProfile())
            .thenAnswer((_) async => null);

        await tester.pumpWidget(createHomeScreen());
        await tester.pumpAndSettle();

        // Verify portrait layout
        expect(find.byKey(Key('scan_button')), findsOneWidget);

        // Simulate landscape orientation
        tester.binding.window.physicalSizeTestValue = Size(896, 414);
        await tester.pumpWidget(createHomeScreen());
        await tester.pumpAndSettle();

        // Should still show essential elements
        expect(find.byKey(Key('scan_button')), findsOneWidget);

        addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      });
    });

    group('Analytics Tracking', () {
      testWidgets('should track screen view events', (WidgetTester tester) async {
        when(mockStorageService.getRecentClassifications(limit: any))
            .thenAnswer((_) async => []);
        when(mockGamificationService.getUserProfile())
            .thenAnswer((_) async => null);

        await tester.pumpWidget(createHomeScreen());
        await tester.pumpAndSettle();

        // Verify analytics tracking was called
        verify(mockAnalyticsService.trackEvent(any)).called(greaterThanOrEqualTo(1));
      });

      testWidgets('should track user interactions', (WidgetTester tester) async {
        when(mockStorageService.getRecentClassifications(limit: any))
            .thenAnswer((_) async => []);
        when(mockGamificationService.getUserProfile())
            .thenAnswer((_) async => null);

        await tester.pumpWidget(createHomeScreen());
        await tester.pumpAndSettle();

        // Tap on scan button
        await tester.tap(find.byKey(Key('scan_button')));
        await tester.pumpAndSettle();

        // Verify interaction tracking
        verify(mockAnalyticsService.trackEvent(any)).called(greaterThan(1));
      });
    });

    group('Accessibility', () {
      testWidgets('should provide semantic labels for screen readers', (WidgetTester tester) async {
        when(mockStorageService.getRecentClassifications(limit: any))
            .thenAnswer((_) async => []);
        when(mockGamificationService.getUserProfile())
            .thenAnswer((_) async => null);

        await tester.pumpWidget(createHomeScreen());
        await tester.pumpAndSettle();

        expect(find.bySemanticsLabel('Scan waste item'), findsOneWidget);
        expect(find.bySemanticsLabel('View classification history'), findsOneWidget);
        expect(find.bySemanticsLabel('Learn about waste disposal'), findsOneWidget);
      });

      testWidgets('should support keyboard navigation', (WidgetTester tester) async {
        when(mockStorageService.getRecentClassifications(limit: any))
            .thenAnswer((_) async => []);
        when(mockGamificationService.getUserProfile())
            .thenAnswer((_) async => null);

        await tester.pumpWidget(createHomeScreen());
        await tester.pumpAndSettle();

        // Test tab navigation
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();

        // Verify focus management
        expect(tester.binding.focusManager.primaryFocus, isNotNull);
      });

      testWidgets('should have sufficient color contrast', (WidgetTester tester) async {
        when(mockStorageService.getRecentClassifications(limit: any))
            .thenAnswer((_) async => []);
        when(mockGamificationService.getUserProfile())
            .thenAnswer((_) async => null);

        await tester.pumpWidget(createHomeScreen());
        await tester.pumpAndSettle();

        // Find text widgets and verify contrast
        final textWidgets = find.byType(Text);
        expect(textWidgets, findsWidgets);

        // Note: Actual contrast testing would require color analysis
        // This is a placeholder for contrast verification
      });
    });
  });
}

// Helper function to create test classification
WasteClassification _createTestClassification(String itemName, String category) {
  return WasteClassification(
    itemName: itemName,
    category: category,
    subcategory: 'Test',
    explanation: 'Test classification',
    disposalInstructions: DisposalInstructions(
      primaryMethod: 'Test disposal',
      steps: ['Step 1'],
      hasUrgentTimeframe: false,
    ),
    timestamp: DateTime.now(),
    region: 'Test Region',
    visualFeatures: ['test'],
    alternatives: [],
    confidence: 0.8,
  );
}
