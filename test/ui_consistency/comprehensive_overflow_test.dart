import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:waste_segregation_app/widgets/modern_ui/modern_cards.dart';
import 'package:waste_segregation_app/screens/modern_home_screen.dart';
import 'package:waste_segregation_app/utils/constants.dart';
import 'package:waste_segregation_app/services/gamification_service.dart';
import 'package:waste_segregation_app/services/ad_service.dart';
import 'package:waste_segregation_app/services/storage_service.dart';
import 'package:waste_segregation_app/services/ai_service.dart';
import 'package:waste_segregation_app/services/analytics_service.dart';
import 'package:waste_segregation_app/services/community_service.dart';
import '../test_helper.dart';

// Mock classes
class MockGamificationService extends Mock implements GamificationService {}
class MockAdService extends Mock implements AdService {}
class MockStorageService extends Mock implements StorageService {}
class MockAiService extends Mock implements AiService {}
class MockAnalyticsService extends Mock implements AnalyticsService {}
class MockCommunityService extends Mock implements CommunityService {}

void main() {
  group('Comprehensive Overflow Tests', () {
    setUpAll(() async {
      await TestHelper.setupCompleteTest();
    });

    tearDownAll(() async {
      await TestHelper.tearDownCompleteTest();
    });

    setUp(() async {
      await TestHelper.cleanupServiceTest();
    });

    group('StatsCard Overflow Tests', () {
      testWidgets('StatsCard handles very narrow screen without overflow', (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(280, 600)); // Very narrow screen
        
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: StatsCard(
                        title: 'Very Long Classification Title That Could Overflow',
                        value: '1,234,567,890',
                        icon: Icons.analytics,
                        color: AppTheme.primaryColor,
                        trend: '+999%',
                        subtitle: 'Really long subtitle that might cause issues',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pump();

        // Check for RenderFlex overflow errors
        expect(tester.takeException(), isNull, reason: 'No RenderFlex overflow should occur');
        
        // Verify the card is rendered
        expect(find.byType(StatsCard), findsOneWidget);
        
        // Reset screen size
        await tester.binding.setSurfaceSize(null);
      });

      testWidgets('Multiple StatsCards in row handle overflow gracefully', (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(320, 568)); // iPhone SE size
        
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: StatsCard(
                        title: 'Classifications Today',
                        value: '999,999',
                        icon: Icons.analytics,
                        color: AppTheme.primaryColor,
                        trend: '+150%',
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: StatsCard(
                        title: 'Daily Streak Counter',
                        value: '365',
                        subtitle: 'consecutive days',
                        icon: Icons.local_fire_department,
                        color: Colors.orange,
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: StatsCard(
                        title: 'Total Points Earned',
                        value: '1,234,567',
                        icon: Icons.stars,
                        color: Colors.amber,
                        trend: '+999%',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pump();
        
        // Check for overflow errors
        expect(tester.takeException(), isNull, reason: 'Three StatsCards should fit without overflow');
        
        // Verify all cards are rendered
        expect(find.byType(StatsCard), findsNWidgets(3));
        
        // Reset screen size
        await tester.binding.setSurfaceSize(null);
      });

      testWidgets('StatsCard adapts text scaling properly', (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(300, 600));
        
        await tester.pumpWidget(
          const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                textScaler: TextScaler.linear(2.0), // Large text scaling
              ),
              child: Scaffold(
                body: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: StatsCard(
                    title: 'Large Text Test',
                    value: '123,456',
                    icon: Icons.analytics,
                    subtitle: 'Scaled text',
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pump();
        
        // No overflow with large text scaling
        expect(tester.takeException(), isNull, reason: 'Large text scaling should not cause overflow');
        
        // Reset screen size
        await tester.binding.setSurfaceSize(null);
      });
    });

    group('Home Screen Layout Tests', () {
      testWidgets('ModernHomeScreen handles small screens without overflow', (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(280, 568)); // Very small screen
        
        // Create mock providers for the home screen
        final mockGamificationService = MockGamificationService();
        final mockAdService = MockAdService();
        final mockStorageService = MockStorageService();
        final mockAiService = MockAiService();
        final mockAnalyticsService = MockAnalyticsService();
        final mockCommunityService = MockCommunityService();
        
        // Mock the screen with all required providers
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              Provider<GamificationService>.value(value: mockGamificationService),
              ChangeNotifierProvider<AdService>.value(value: mockAdService),
              Provider<StorageService>.value(value: mockStorageService),
              Provider<AiService>.value(value: mockAiService),
              ChangeNotifierProvider<AnalyticsService>.value(value: mockAnalyticsService),
              Provider<CommunityService>.value(value: mockCommunityService),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: ModernHomeScreen(isGuestMode: true),
              ),
            ),
          ),
        );

        // Wait for initial loading
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Check for overflow errors during initial render
        expect(tester.takeException(), isNull, reason: 'Home screen should handle small screens without overflow');
        
        // Try scrolling to test different sections
        final scrollView = find.byType(SingleChildScrollView);
        if (scrollView.hasFound) {
          await tester.drag(scrollView.first, const Offset(0, -200));
          await tester.pump();
          
          // Check for overflow after scrolling
          expect(tester.takeException(), isNull, reason: 'No overflow after scrolling');
        }
        
        // Reset screen size
        await tester.binding.setSurfaceSize(null);
      });

      testWidgets('Today\'s Impact Goal section handles narrow screens', (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(300, 600));
        
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Simulate the Today's Impact Goal widget
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(Icons.emoji_events, color: AppTheme.primaryColor),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '🌍 Today\'s Impact Goal - Make a Difference',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('2', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                                Text(' of '),
                                Text('10', style: TextStyle(fontSize: 20)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pump();
        
        // No overflow in impact goal section
        expect(tester.takeException(), isNull, reason: 'Today\'s Impact Goal should handle narrow screens');
        
        // Reset screen size
        await tester.binding.setSurfaceSize(null);
      });
    });

    group('Responsive Layout Edge Cases', () {
      testWidgets('Extremely narrow width (200px) handles gracefully', (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(200, 600)); // Extremely narrow
        
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: StatsCard(
                        title: 'Test',
                        value: '999',
                        icon: Icons.analytics,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: StatsCard(
                              title: 'A',
                              value: '1',
                            ),
                          ),
                          SizedBox(width: 4),
                          Expanded(
                            child: StatsCard(
                              title: 'B',
                              value: '2',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pump();
        
        // Even extremely narrow screens should not overflow
        expect(tester.takeException(), isNull, reason: 'Extremely narrow screens should be handled gracefully');
        
        // Reset screen size
        await tester.binding.setSurfaceSize(null);
      });

      testWidgets('Landscape orientation handles overflow properly', (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(812, 375)); // iPhone landscape
        
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(child: StatsCard(title: 'Classifications', value: '123')),
                    SizedBox(width: 8),
                    Expanded(child: StatsCard(title: 'Streak', value: '45')),
                    SizedBox(width: 8),
                    Expanded(child: StatsCard(title: 'Points', value: '6789')),
                    SizedBox(width: 8),
                    Expanded(child: StatsCard(title: 'Level', value: '12')),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pump();
        
        // Landscape with 4 cards should work fine
        expect(tester.takeException(), isNull, reason: 'Landscape orientation should handle multiple cards');
        expect(find.byType(StatsCard), findsNWidgets(4));
        
        // Reset screen size
        await tester.binding.setSurfaceSize(null);
      });

      testWidgets('Very long text values are truncated properly', (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(300, 600));
        
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: EdgeInsets.all(16.0),
                child: StatsCard(
                  title: 'This is an extremely long title that should be truncated if necessary to prevent overflow issues in the UI',
                  value: '1,234,567,890,123,456,789',
                  subtitle: 'This is also a very long subtitle that might cause problems if not handled correctly',
                  trend: '+999,999%',
                ),
              ),
            ),
          ),
        );

        await tester.pump();
        
        // Very long content should be handled gracefully
        expect(tester.takeException(), isNull, reason: 'Very long text should be truncated to prevent overflow');
        
        // Reset screen size
        await tester.binding.setSurfaceSize(null);
      });
    });

    group('Dynamic Content Tests', () {
      testWidgets('Stats cards adapt to changing values without overflow', (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(350, 600));
        
        var testValue = '0';
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    children: [
                      StatsCard(
                        title: 'Dynamic Value',
                        value: testValue,
                        icon: Icons.analytics,
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            testValue = '999,999,999,999,999';
                          });
                        },
                        child: const Text('Increase Value'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );

        await tester.pump();
        
        // Initial state should be fine
        expect(tester.takeException(), isNull);
        
        // Tap to increase value dramatically
        await tester.tap(find.text('Increase Value'));
        await tester.pump();
        
        // Even very large values should not cause overflow
        expect(tester.takeException(), isNull, reason: 'Dynamic value changes should not cause overflow');
        
        // Reset screen size
        await tester.binding.setSurfaceSize(null);
      });
    });
  });
} 