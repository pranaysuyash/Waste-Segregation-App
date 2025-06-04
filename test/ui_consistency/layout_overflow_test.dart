import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/widgets/modern_ui/modern_cards.dart';
import 'package:waste_segregation_app/utils/constants.dart';

void main() {
  group('Layout Overflow Detection Tests', () {
    group('StatsCard RenderFlex Overflow Tests', () {
      testWidgets('Single StatsCard should not overflow on narrow screen', (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(300, 600));
        
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: EdgeInsets.all(16.0),
                child: StatsCard(
                  title: 'Very Long Classification Title That Could Potentially Overflow',
                  value: '1,234,567,890',
                  icon: Icons.analytics,
                  color: AppTheme.primaryColor,
                  trend: '+999%',
                  subtitle: 'Really long subtitle that might cause layout issues',
                ),
              ),
            ),
          ),
        );

        await tester.pump();

        // Check for any RenderFlex overflow errors
        expect(tester.takeException(), isNull, reason: 'Single StatsCard should not overflow');
        
        // Verify the card is rendered
        expect(find.byType(StatsCard), findsOneWidget);
        
        await tester.binding.setSurfaceSize(null);
      });

      testWidgets('Three StatsCards in row should handle tight space', (WidgetTester tester) async {
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
                        title: 'Classifications',
                        value: '999,999',
                        icon: Icons.analytics,
                        color: AppTheme.primaryColor,
                        trend: '+150%',
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: StatsCard(
                        title: 'Streak',
                        value: '365',
                        subtitle: 'days',
                        icon: Icons.local_fire_department,
                        color: Colors.orange,
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: StatsCard(
                        title: 'Points',
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
        expect(tester.takeException(), isNull, reason: 'Three StatsCards should fit without overflow on small screen');
        
        // Verify all cards are rendered
        expect(find.byType(StatsCard), findsNWidgets(3));
        
        await tester.binding.setSurfaceSize(null);
      });

      testWidgets('StatsCard handles extremely long values gracefully', (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(280, 600)); // Very narrow
        
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: EdgeInsets.all(8.0),
                child: StatsCard(
                  title: 'This is an extremely long title that should be truncated properly to prevent overflow issues in the UI layout system and ensure good user experience',
                  value: '1,234,567,890,123,456,789,999,888,777',
                  subtitle: 'This is also a very long subtitle that might cause problems if not handled correctly by the layout system',
                  trend: '+999,999,999%',
                  icon: Icons.analytics,
                ),
              ),
            ),
          ),
        );

        await tester.pump();
        
        // Very long content should be handled gracefully
        expect(tester.takeException(), isNull, reason: 'Extremely long text should be truncated to prevent overflow');
        
        await tester.binding.setSurfaceSize(null);
      });

      testWidgets('StatsCard with large text scaling should not overflow', (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(350, 600));
        
        await tester.pumpWidget(
          const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                textScaler: TextScaler.linear(2.0), // Large text scaling for accessibility
              ),
              child: Scaffold(
                body: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: StatsCard(
                    title: 'Large Text Test',
                    value: '123,456',
                    icon: Icons.analytics,
                    subtitle: 'Scaled text should fit',
                    trend: '+50%',
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pump();
        
        // Large text scaling should not cause overflow
        expect(tester.takeException(), isNull, reason: 'Large text scaling should not cause overflow');
        
        await tester.binding.setSurfaceSize(null);
      });
    });

    group('Impact Goal Layout Tests', () {
      testWidgets('Today\'s Impact Goal handles narrow screens', (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(300, 600));
        
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: EdgeInsets.all(16.0),
                child: Card(
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
                                '🌍 Today\'s Impact Goal - Make a Difference Today',
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
                        SizedBox(height: 8),
                        Text(
                          'Keep going! You\'re making a great environmental impact.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pump();
        
        // No overflow in impact goal section
        expect(tester.takeException(), isNull, reason: 'Today\'s Impact Goal should handle narrow screens');
        
        await tester.binding.setSurfaceSize(null);
      });
    });

    group('Edge Case Layout Tests', () {
      testWidgets('Extremely narrow width (200px) handles gracefully', (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(200, 600)); // Extremely narrow
        
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(4.0),
                      child: StatsCard(
                        title: 'Test',
                        value: '999',
                        icon: Icons.analytics,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(4.0),
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
        
        await tester.binding.setSurfaceSize(null);
      });

      testWidgets('Dynamic value changes do not cause overflow', (WidgetTester tester) async {
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
                        title: 'Dynamic Value Test',
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
        
        await tester.binding.setSurfaceSize(null);
      });
    });
  });
} 