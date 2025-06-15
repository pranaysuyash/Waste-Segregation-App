import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:waste_segregation_app/screens/waste_dashboard_screen.dart';
import 'package:waste_segregation_app/services/storage_service.dart';
import 'package:waste_segregation_app/services/gamification_service.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/models/gamification.dart';

import 'waste_dashboard_screen_test.mocks.dart';

@GenerateMocks([StorageService, GamificationService])
void main() {
  group('WasteDashboardScreen Tests', () {
    late MockStorageService mockStorageService;
    late MockGamificationService mockGamificationService;
    late List<WasteClassification> testClassifications;
    late GamificationProfile testGamificationProfile;

    setUp(() {
      mockStorageService = MockStorageService();
      mockGamificationService = MockGamificationService();

      // Create test data
      testClassifications = [
        WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
          id: 'test1',
          itemName: 'Plastic Bottle',
          subcategory: 'Plastic',
          confidence: 0.95,
            region: 'Test Region',
            visualFeatures: ['test feature'],
            alternatives: [],
          timestamp: DateTime.now().subtract(const Duration(days: 5)),
          imageUrl: 'test_url_1',
          source: 'ai',
          isRecyclable: true,
          disposalInstructions: DisposalInstructions(
            primaryMethod: 'Recycle',
            steps: ['Clean', 'Dispose'],
            timeframe: 'Weekly',
            location: 'Blue bin',
            hasUrgentTimeframe: false,
          ),
        ),
        WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
          id: 'test2',
          itemName: 'Food Scraps',
          subcategory: 'Food Waste',
          confidence: 0.87,
            region: 'Test Region',
            visualFeatures: ['test feature'],
            alternatives: [],
          timestamp: DateTime.now().subtract(const Duration(days: 3)),
          imageUrl: 'test_url_2',
          source: 'ai',
          isRecyclable: false,
          disposalInstructions: DisposalInstructions(
            primaryMethod: 'Compost',
            steps: ['Compost'],
            timeframe: 'Daily',
            location: 'Green bin',
            hasUrgentTimeframe: false,
          ),
        ),
        WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
          id: 'test3',
          itemName: 'Battery',
          subcategory: 'Batteries',
          confidence: 0.92,
            region: 'Test Region',
            visualFeatures: ['test feature'],
            alternatives: [],
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          imageUrl: 'test_url_3',
          source: 'ai',
          isRecyclable: false,
          disposalInstructions: DisposalInstructions(
            primaryMethod: 'Special disposal',
            steps: ['Take to collection center'],
            timeframe: 'ASAP',
            location: 'Hazardous waste facility',
            hasUrgentTimeframe: true,
          ),
        ),
      ];

      testGamificationProfile = GamificationProfile(
        userId: 'test_user',
        points: GamificationPoints(
          total: 150,
          level: 3,
          nextLevelThreshold: 200,
        ),
        streaks: {
          StreakType.dailyClassification.toString(): GamificationStreak(
            type: StreakType.dailyClassification,
            currentCount: 5,
            maxCount: 10,
            lastUpdated: DateTime.now(),
          ),
        },
        achievements: [],
        level: 3,
        badges: [],
        challenges: [],
        stats: GamificationStats(
          totalClassifications: 25,
          correctClassifications: 20,
          streakDays: 5,
          badgesEarned: 2,
        ),
      );

      // Set up default mock responses
      when(mockStorageService.getAllClassifications())
          .thenAnswer((_) async => testClassifications);
      when(mockGamificationService.getProfile())
          .thenAnswer((_) async => testGamificationProfile);
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: MultiProvider(
          providers: [
            Provider<StorageService>.value(value: mockStorageService),
            Provider<GamificationService>.value(value: mockGamificationService),
          ],
          child: const WasteDashboardScreen(),
        ),
      );
    }

    group('Widget Construction and Loading', () {
      testWidgets('should show loading indicator initially', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Waste Analytics Dashboard'), findsOneWidget);
      });

      testWidgets('should load data and show dashboard', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        // Wait for data to load
        await tester.pumpAndSettle();

        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text('Total Items'), findsOneWidget);
        expect(find.text('3'), findsOneWidget); // Total items count
      });

      testWidgets('should show refresh button in app bar', (tester) async {
        await tester.pumpWidget(createTestWidget());

        expect(find.byIcon(Icons.refresh), findsOneWidget);
        expect(find.byTooltip('Refresh Data'), findsOneWidget);
      });

      testWidgets('should handle refresh action', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.refresh));
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        await tester.pumpAndSettle();

        verify(mockStorageService.getAllClassifications()).called(2);
      });
    });

    group('Empty State Handling', () {
      testWidgets('should show empty state when no classifications', (tester) async {
        when(mockStorageService.getAllClassifications())
            .thenAnswer((_) async => <WasteClassification>[]);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.byType(EmptyStateWidget), findsOneWidget);
        expect(find.text('No Data Yet'), findsOneWidget);
        expect(find.text('Start classifying waste items to see your personalized analytics dashboard.'), findsOneWidget);
      });
    });

    group('Error Handling', () {
      testWidgets('should handle storage service errors', (tester) async {
        when(mockStorageService.getAllClassifications())
            .thenThrow(Exception('Storage error'));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Failed to load data: Exception: Storage error'), findsOneWidget);
      });

      testWidgets('should handle gamification service errors', (tester) async {
        when(mockGamificationService.getProfile())
            .thenThrow(Exception('Gamification error'));

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Error loading gamification data.'), findsOneWidget);
      });
    });

    group('Summary Statistics', () {
      testWidgets('should display correct summary stats', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Total Items'), findsOneWidget);
        expect(find.text('3'), findsOneWidget); // Total count

        expect(find.text('Days Tracking'), findsOneWidget);
        expect(find.text('6'), findsOneWidget); // Days since first classification

        expect(find.text('Recyclable'), findsOneWidget);
        expect(find.text('1'), findsOneWidget); // Recyclable count
      });

      testWidgets('should handle single day tracking', (tester) async {
        final singleDayClassifications = [
          testClassifications.first.copyWith(
            timestamp: DateTime.now(),
          ),
        ];

        when(mockStorageService.getAllClassifications())
            .thenAnswer((_) async => singleDayClassifications);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('1'), findsNWidgets(3)); // Days Tracking should be 1
      });
    });

    group('Activity Chart', () {
      testWidgets('should show chart when data is available', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.byType(WebChartWidget), findsOneWidget);
        expect(find.text('Items classified over time'), findsOneWidget);
      });

      testWidgets('should show empty chart message when no data', (tester) async {
        when(mockStorageService.getAllClassifications())
            .thenAnswer((_) async => <WasteClassification>[]);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Not enough data yet'), findsAtLeastNWidgets(1));
        expect(find.text('Classify some items to see your activity chart!'), findsOneWidget);
      });
    });

    group('Category Distribution', () {
      testWidgets('should show pie chart with category data', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.byType(WebPieChartWidget), findsOneWidget);
        expect(find.text('Category breakdown of your classifications'), findsOneWidget);
      });

      testWidgets('should show category legend', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Dry Waste'), findsAtLeastNWidgets(1));
        expect(find.text('Wet Waste'), findsAtLeastNWidgets(1));
        expect(find.text('Hazardous Waste'), findsAtLeastNWidgets(1));
      });

      testWidgets('should show empty state for category distribution', (tester) async {
        when(mockStorageService.getAllClassifications())
            .thenAnswer((_) async => <WasteClassification>[]);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Not enough data yet'), findsAtLeastNWidgets(1));
        expect(find.text('Classify items to see category breakdown!'), findsOneWidget);
      });
    });

    group('Top Subcategories', () {
      testWidgets('should show top subcategories list', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Most frequently identified waste types'), findsOneWidget);
        expect(find.text('Plastic'), findsOneWidget);
        expect(find.text('Food Waste'), findsOneWidget);
        expect(find.text('Batteries'), findsOneWidget);
      });

      testWidgets('should show progress bars for subcategories', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.byType(LinearProgressIndicator), findsAtLeastNWidgets(3));
      });

      testWidgets('should show empty state for subcategories', (tester) async {
        when(mockStorageService.getAllClassifications())
            .thenAnswer((_) async => <WasteClassification>[]);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Classify more items to see top waste types!'), findsOneWidget);
      });
    });

    group('Recent Classifications', () {
      testWidgets('should show recent classifications list', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Your latest classifications'), findsOneWidget);
        expect(find.text('Battery'), findsOneWidget);
        expect(find.text('Food Scraps'), findsOneWidget);
        expect(find.text('Plastic Bottle'), findsOneWidget);
      });

      testWidgets('should show category icons', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.compost), findsOneWidget); // Wet waste
        expect(find.byIcon(Icons.recycling), findsOneWidget); // Dry waste
        expect(find.byIcon(Icons.warning), findsOneWidget); // Hazardous waste
      });

      testWidgets('should show recyclable indicators', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.recycling), findsAtLeastNWidgets(1));
        expect(find.byIcon(Icons.do_not_disturb), findsAtLeastNWidgets(1));
      });

      testWidgets('should show empty state for recent classifications', (tester) async {
        when(mockStorageService.getAllClassifications())
            .thenAnswer((_) async => <WasteClassification>[]);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('No classifications yet'), findsOneWidget);
        expect(find.text('Start classifying items to see your history!'), findsOneWidget);
      });
    });

    group('Environmental Impact', () {
      testWidgets('should show impact metrics', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Your positive environmental impact'), findsOneWidget);
        expect(find.text('Recycling Rate'), findsOneWidget);
        expect(find.text('CO₂ Emissions Saved'), findsOneWidget);
        expect(find.text('Water Saved'), findsOneWidget);
      });

      testWidgets('should calculate recycling rate correctly', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 1 recyclable out of 3 total = 33.3%
        expect(find.text('33.3%'), findsOneWidget);
      });

      testWidgets('should calculate CO2 savings', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 1 recyclable * 0.5 = 0.5 kg
        expect(find.text('0.5 kg'), findsOneWidget);
      });

      testWidgets('should calculate water savings', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // 1 recyclable * 100 = 100 L
        expect(find.text('100 L'), findsOneWidget);
      });

      testWidgets('should handle zero recyclable items', (tester) async {
        final nonRecyclableClassifications = testClassifications
            .map((c) => c.copyWith(isRecyclable: false))
            .toList();

        when(mockStorageService.getAllClassifications())
            .thenAnswer((_) async => nonRecyclableClassifications);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('0.0%'), findsOneWidget); // Recycling rate
        expect(find.text('0.0 kg'), findsOneWidget); // CO2 savings
        expect(find.text('0 L'), findsOneWidget); // Water savings
      });
    });

    group('Gamification Section', () {
      testWidgets('should show gamification progress', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Your Gamification Progress'), findsOneWidget);
        expect(find.text('Streak'), findsOneWidget);
        expect(find.text('Points'), findsOneWidget);
        expect(find.text('5'), findsOneWidget); // Streak count
        expect(find.text('150'), findsOneWidget); // Points total
      });

      testWidgets('should show level information', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Level 3'), findsOneWidget);
      });

      testWidgets('should show leaderboard coming soon message', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.textContaining('Leaderboard coming soon'), findsOneWidget);
      });

      testWidgets('should handle gamification loading state', (tester) async {
        when(mockGamificationService.getProfile())
            .thenAnswer((_) async {
          await Future.delayed(const Duration(seconds: 2));
          return testGamificationProfile;
        });

        await tester.pumpWidget(createTestWidget());
        await tester.pump(); // Pump once to get past initial loading
        await tester.pump(); // Pump again to see gamification loading

        expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
      });
    });

    group('EmptyStateWidget', () {
      testWidgets('should render with title and message', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: EmptyStateWidget(
                title: 'Test Title',
                message: 'Test Message',
              ),
            ),
          ),
        );

        expect(find.text('Test Title'), findsOneWidget);
        expect(find.text('Test Message'), findsOneWidget);
      });

      testWidgets('should render with icon', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: EmptyStateWidget(
                title: 'Test Title',
                message: 'Test Message',
                icon: Icons.info,
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.info), findsOneWidget);
      });

      testWidgets('should render with action button', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmptyStateWidget(
                title: 'Test Title',
                message: 'Test Message',
                actionButton: ElevatedButton(
                  onPressed: () {},
                  child: const Text('Action'),
                ),
              ),
            ),
          ),
        );

        expect(find.text('Action'), findsOneWidget);
        expect(find.byType(ElevatedButton), findsOneWidget);
      });
    });

    group('GamificationSummaryCard', () {
      testWidgets('should render with required properties', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: GamificationSummaryCard(
                title: 'Points',
                value: '150',
                unit: 'Level 3',
                icon: Icons.star,
                color: Colors.blue,
              ),
            ),
          ),
        );

        expect(find.text('Points'), findsOneWidget);
        expect(find.text('150'), findsOneWidget);
        expect(find.text('Level 3'), findsOneWidget);
        expect(find.byIcon(Icons.star), findsOneWidget);
      });

      testWidgets('should render with trend', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: GamificationSummaryCard(
                title: 'Points',
                value: '150',
                unit: 'Level 3',
                icon: Icons.star,
                color: Colors.blue,
                trend: '+12%',
              ),
            ),
          ),
        );

        expect(find.text('+12%'), findsOneWidget);
      });

      testWidgets('should handle long text gracefully', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Row(
                children: [
                  GamificationSummaryCard(
                    title: 'Very Long Title That Should Be Truncated',
                    value: '150',
                    unit: 'Very Long Unit Text That Should Be Truncated',
                    icon: Icons.star,
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.textContaining('Very Long Title'), findsOneWidget);
        expect(find.textContaining('Very Long Unit'), findsOneWidget);
      });
    });

    group('Chart Widgets', () {
      testWidgets('should render WebChartWidget', (tester) async {
        final chartData = [
          {'date': DateTime.now(), 'count': 5},
          {'date': DateTime.now().subtract(const Duration(days: 1)), 'count': 3},
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: WebChartWidget(
                data: chartData,
                title: 'Test Chart',
              ),
            ),
          ),
        );

        expect(find.byType(WebChartWidget), findsOneWidget);
      });

      testWidgets('should render WebPieChartWidget', (tester) async {
        final pieData = [
          {'label': 'Dry Waste', 'value': 10, 'color': '#FF0000', 'percentage': '50%'},
          {'label': 'Wet Waste', 'value': 10, 'color': '#00FF00', 'percentage': '50%'},
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: WebPieChartWidget(data: pieData),
            ),
          ),
        );

        expect(find.byType(WebPieChartWidget), findsOneWidget);
      });

      testWidgets('should handle WebChartWidget with empty data', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: WebChartWidget(
                data: [],
                title: 'Empty Chart',
              ),
            ),
          ),
        );

        expect(find.byType(WebChartWidget), findsOneWidget);
      });

      testWidgets('should handle WebPieChartWidget with empty data', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: WebPieChartWidget(data: []),
            ),
          ),
        );

        expect(find.byType(WebPieChartWidget), findsOneWidget);
      });
    });

    group('Data Processing', () {
      testWidgets('should process classifications correctly', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Verify category counts are correct
        expect(find.text('3'), findsOneWidget); // Total items

        // Each category should appear once in recent classifications
        expect(find.text('Dry Waste'), findsAtLeastNWidgets(1));
        expect(find.text('Wet Waste'), findsAtLeastNWidgets(1));
        expect(find.text('Hazardous Waste'), findsAtLeastNWidgets(1));
      });

      testWidgets('should handle classifications without subcategories', (tester) async {
        final classificationsWithoutSubcategories = [
          testClassifications.first.copyWith(),
          testClassifications.last.copyWith(subcategory: ''),
        ];

        when(mockStorageService.getAllClassifications())
            .thenAnswer((_) async => classificationsWithoutSubcategories);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Should still render without errors
        expect(find.text('Total Items'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);
      });

      testWidgets('should sort classifications by date correctly', (tester) async {
        final unsortedClassifications = [
          testClassifications[2], // Most recent (1 day ago)
          testClassifications[0], // Oldest (5 days ago)
          testClassifications[1], // Middle (3 days ago)
        ];

        when(mockStorageService.getAllClassifications())
            .thenAnswer((_) async => unsortedClassifications);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Recent classifications should show most recent first
        expect(find.text('Battery'), findsOneWidget); // Most recent should be visible
      });
    });

    group('Performance and Edge Cases', () {
      testWidgets('should handle large datasets efficiently', (tester) async {
        final largeDataset = List.generate(1000, (index) =>
          WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
            id: 'test_$index',
            itemName: 'Item $index',
            subcategory: 'Subcategory $index',
            confidence: 0.8,
            region: 'Test Region',
            visualFeatures: ['test feature'],
            alternatives: [],
            timestamp: DateTime.now().subtract(Duration(days: index % 30)),
            imageUrl: 'test_url_$index',
            source: 'ai',
            isRecyclable: index % 2 == 0,
            disposalInstructions: DisposalInstructions(
              primaryMethod: 'Method',
              steps: ['Step'],
              timeframe: 'Time',
              location: 'Location',
              hasUrgentTimeframe: false,
            ),
          ),
        );

        when(mockStorageService.getAllClassifications())
            .thenAnswer((_) async => largeDataset.cast<WasteClassification>());

        final stopwatch = Stopwatch()..start();

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        stopwatch.stop();

        // Should complete within reasonable time (less than 5 seconds)
        expect(stopwatch.elapsedMilliseconds, lessThan(5000));
        expect(find.text('1000'), findsOneWidget); // Total items
      });

      testWidgets('should handle classifications with null values', (tester) async {
        final classificationWithNulls = WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
          id: 'test_null',
          itemName: 'Test Item',
          confidence: 0.5,
            region: 'Test Region',
            visualFeatures: ['test feature'],
            alternatives: [],
          timestamp: DateTime.now(),
          imageUrl: 'test_url',
          source: 'ai',
          // Other fields are null by default
        );

        when(mockStorageService.getAllClassifications())
            .thenAnswer((_) async => [classificationWithNulls]);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Total Items'), findsOneWidget);
        expect(find.text('1'), findsOneWidget);
      });

      testWidgets('should handle rapid refresh actions', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Rapidly tap refresh multiple times
        for (var i = 0; i < 5; i++) {
          await tester.tap(find.byIcon(Icons.refresh));
          await tester.pump();
        }

        await tester.pumpAndSettle();

        // Should handle multiple refresh calls gracefully
        verify(mockStorageService.getAllClassifications()).called(greaterThan(1));
      });
    });

    group('Responsive Layout', () {
      testWidgets('should handle different screen sizes', (tester) async {
        // Test with small screen
        tester.binding.window.physicalSizeTestValue = const Size(400, 600);
        tester.binding.window.devicePixelRatioTestValue = 1.0;

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Total Items'), findsOneWidget);

        // Test with large screen
        tester.binding.window.physicalSizeTestValue = const Size(1200, 800);

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Total Items'), findsOneWidget);

        addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
        addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);
      });

      testWidgets('should handle scrolling', (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Should be scrollable
        expect(find.byType(SingleChildScrollView), findsOneWidget);

        // Test scrolling to bottom
        await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -500));
        await tester.pumpAndSettle();

        // Should still find gamification section
        expect(find.text('Your Gamification Progress'), findsOneWidget);
      });
    });
  });
}
