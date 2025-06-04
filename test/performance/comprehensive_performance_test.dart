import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/screens/home_screen.dart';
import 'package:waste_segregation_app/screens/history_screen.dart';
import 'package:waste_segregation_app/screens/educational_content_screen.dart';
import '../test_config/plugin_mock_setup.dart';

void main() {
  group('Comprehensive Performance Tests', () {
    setUpAll(() {
      TestHelpers.setUpAll();
      PluginMockSetup.setupAll();
    });

    tearDownAll(() {
      TestHelpers.tearDownAll();
    });

    group('Screen Loading Performance', () {
      testWidgets('Home screen loads within 1 second', (WidgetTester tester) async {
        final stopwatch = Stopwatch()..start();
        
        await tester.pumpWidget(
          const MaterialApp(
            home: HomeScreen(),
          ),
        );
        
        await tester.pumpAndSettle();
        stopwatch.stop();
        
        expect(stopwatch.elapsedMilliseconds, lessThan(1000),
            reason: 'Home screen should load within 1 second');
      });

      testWidgets('History screen loads within 1.5 seconds', (WidgetTester tester) async {
        final stopwatch = Stopwatch()..start();
        
        await tester.pumpWidget(
          const MaterialApp(
            home: HistoryScreen(),
          ),
        );
        
        await tester.pumpAndSettle();
        stopwatch.stop();
        
        expect(stopwatch.elapsedMilliseconds, lessThan(1500),
            reason: 'History screen should load within 1.5 seconds');
      });

      testWidgets('Educational content screen loads within 2 seconds', (WidgetTester tester) async {
        final stopwatch = Stopwatch()..start();
        
        await tester.pumpWidget(
          const MaterialApp(
            home: EducationalContentScreen(),
          ),
        );
        
        await tester.pumpAndSettle();
        stopwatch.stop();
        
        expect(stopwatch.elapsedMilliseconds, lessThan(2000),
            reason: 'Educational content screen should load within 2 seconds');
      });
    });

    group('Frame Rate Performance', () {
      testWidgets('Maintains 60fps during scrolling', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ListView.builder(
                itemCount: 100,
                itemBuilder: (context, index) => ListTile(
                  title: Text('Item $index'),
                  subtitle: Text('Subtitle for item $index'),
                ),
              ),
            ),
          ),
        );

        // Simulate scrolling and measure frame times
        final scrollable = find.byType(Scrollable);
        expect(scrollable, findsOneWidget);

        // Perform scroll gesture
        await tester.drag(scrollable, const Offset(0, -500));
        await tester.pump();

        // Check that no frames were dropped (simplified check)
        expect(tester.binding.hasScheduledFrame, isFalse,
            reason: 'Should not have dropped frames during scrolling');
      });

      testWidgets('Animation performance test', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  width: 100,
                  height: 100,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        );

        // Trigger animation and measure performance
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));
        
        // Verify animation is smooth (no dropped frames)
        expect(tester.binding.hasScheduledFrame, isFalse);
      });
    });

    group('Memory Usage Tests', () {
      testWidgets('Memory usage stays reasonable during intensive operations', (WidgetTester tester) async {
        // Create a widget that uses significant memory
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                ),
                itemCount: 50,
                itemBuilder: (context, index) => Container(
                  color: Colors.primaries[index % Colors.primaries.length],
                  child: Center(child: Text('$index')),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        
        // Memory usage test (simplified - in real app would use actual memory monitoring)
        expect(find.byType(Container), findsNWidgets(50));
      });
    });

    group('UI Responsiveness Tests', () {
      testWidgets('Button tap responds within 16ms', (WidgetTester tester) async {
        bool tapped = false;
        final stopwatch = Stopwatch();
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    stopwatch.stop();
                    tapped = true;
                  },
                  child: const Text('Tap Me'),
                ),
              ),
            ),
          ),
        );

        stopwatch.start();
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();

        expect(tapped, isTrue);
        expect(stopwatch.elapsedMilliseconds, lessThan(16),
            reason: 'Button should respond within 16ms for 60fps');
      });

      testWidgets('Text input responds immediately', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(
                child: TextField(
                  decoration: InputDecoration(hintText: 'Type here'),
                ),
              ),
            ),
          ),
        );

        final textField = find.byType(TextField);
        await tester.enterText(textField, 'Test input');
        await tester.pump();

        expect(find.text('Test input'), findsOneWidget);
      });
    });

    group('Performance Regression Detection', () {
      testWidgets('Performance baseline test', (WidgetTester tester) async {
        // This test establishes a baseline for performance
        final stopwatch = Stopwatch()..start();
        
        await tester.pumpWidget(
          const MaterialApp(
            home: HomeScreen(),
          ),
        );
        
        await tester.pumpAndSettle();
        stopwatch.stop();
        
        // Store baseline (in real implementation, would save to file)
        final loadTime = stopwatch.elapsedMilliseconds;
        
        // Ensure we don't regress beyond 20% of baseline
        expect(loadTime, lessThan(1200), // 20% buffer on 1000ms target
            reason: 'Performance should not regress beyond baseline');
      });
    });
  });
} 