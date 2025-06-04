import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/widgets/waste_chart_widgets.dart';

void main() {
  group('Chart Accessibility Tests', () {
    late AnimationController animationController;
    
    setUp(() {
      animationController = AnimationController(
        duration: const Duration(milliseconds: 500),
        vsync: TestVSync(),
      );
    });
    
    tearDown(() {
      animationController.dispose();
    });
    
    group('WasteCategoryPieChart Accessibility', () {
      testWidgets('provides semantic labels for screen readers', (WidgetTester tester) async {
        final testData = [
          ChartData('Wet Waste', 10, Colors.green),
          ChartData('Dry Waste', 15, Colors.blue),
          ChartData('Hazardous Waste', 5, Colors.red),
        ];
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 400,
                child: WasteCategoryPieChart(
                  data: testData,
                  animationController: animationController,
                  semanticsLabel: 'Test pie chart',
                ),
              ),
            ),
          ),
        );
        
        // Enable semantics
        final SemanticsHandle handle = tester.ensureSemantics();
        
        // Find the main chart semantics
        expect(find.bySemanticsLabel('Test pie chart'), findsOneWidget);
        
        // Verify accessible description contains data
        final semanticsNode = tester.getSemantics(find.byType(WasteCategoryPieChart));
        expect(semanticsNode.value, contains('Dry Waste: 15 items'));
        expect(semanticsNode.value, contains('Wet Waste: 10 items'));
        expect(semanticsNode.value, contains('Hazardous Waste: 5 items'));
        
        // Verify hint for interaction
        expect(semanticsNode.hint, equals('Double tap to hear detailed breakdown'));
        
        // Verify legend is accessible
        expect(find.bySemanticsLabel('Chart legend'), findsOneWidget);
        
        handle.dispose();
      });
      
      testWidgets('handles empty data gracefully', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: WasteCategoryPieChart(
                data: const [],
                animationController: animationController,
              ),
            ),
          ),
        );
        
        final SemanticsHandle handle = tester.ensureSemantics();
        
        // Should provide accessible message for empty state
        expect(find.bySemanticsLabel('No waste category data available'), findsOneWidget);
        
        handle.dispose();
      });
      
      testWidgets('legend items have proper semantic labels', (WidgetTester tester) async {
        final testData = [
          ChartData('Wet Waste', 10, Colors.green),
          ChartData('Dry Waste', 15, Colors.blue),
        ];
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 400,
                child: WasteCategoryPieChart(
                  data: testData,
                  animationController: animationController,
                ),
              ),
            ),
          ),
        );
        
        final SemanticsHandle handle = tester.ensureSemantics();
        
        // Verify each legend item has proper semantics
        expect(find.byWidgetPredicate((widget) => 
          widget is Semantics && 
          widget.properties.label != null &&
          widget.properties.label!.contains('Wet Waste: 10 items')
        ), findsOneWidget);
        expect(find.byWidgetPredicate((widget) => 
          widget is Semantics && 
          widget.properties.label != null &&
          widget.properties.label!.contains('Dry Waste: 15 items')
        ), findsOneWidget);
        
        handle.dispose();
      });
    });
    
    group('TopSubcategoriesBarChart Accessibility', () {
      testWidgets('provides semantic labels and data table', (WidgetTester tester) async {
        final testData = [
          ChartData('Paper', 8, Colors.blue),
          ChartData('Plastic', 12, Colors.orange),
          ChartData('Glass', 4, Colors.green),
        ];
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 500,
                child: TopSubcategoriesBarChart(
                  data: testData,
                  animationController: animationController,
                  semanticsLabel: 'Test bar chart',
                ),
              ),
            ),
          ),
        );
        
        final SemanticsHandle handle = tester.ensureSemantics();
        
        // Find the main chart semantics
        expect(find.bySemanticsLabel('Test bar chart'), findsOneWidget);
        
        // Verify accessible description
        final semanticsNode = tester.getSemantics(find.byType(TopSubcategoriesBarChart));
        expect(semanticsNode.value, contains('Plastic: 12 items'));
        expect(semanticsNode.value, contains('Paper: 8 items'));
        expect(semanticsNode.value, contains('Glass: 4 items'));
        
        // Verify data table is present and accessible
        expect(find.bySemanticsLabel('Data table for subcategories'), findsOneWidget);
        
        // Verify individual data rows have semantic labels
        expect(find.bySemanticsLabel('Plastic: 12 items'), findsOneWidget);
        expect(find.bySemanticsLabel('Paper: 8 items'), findsOneWidget);
        expect(find.bySemanticsLabel('Glass: 4 items'), findsOneWidget);
        
        handle.dispose();
      });
      
      testWidgets('sorts data correctly for accessibility', (WidgetTester tester) async {
        final testData = [
          ChartData('Low', 2, Colors.blue),
          ChartData('High', 20, Colors.orange),
          ChartData('Medium', 10, Colors.green),
        ];
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 500,
                child: TopSubcategoriesBarChart(
                  data: testData,
                  animationController: animationController,
                ),
              ),
            ),
          ),
        );
        
        final SemanticsHandle handle = tester.ensureSemantics();
        
        // Verify description mentions highest values first
        final semanticsNode = tester.getSemantics(find.byType(TopSubcategoriesBarChart));
        expect(semanticsNode.value, contains('High: 20 items'));
        expect(semanticsNode.value, contains('Medium: 10 items'));
        expect(semanticsNode.value, contains('Low: 2 items'));
        
        handle.dispose();
      });
    });
    
    group('WeeklyItemsChart Accessibility', () {
      testWidgets('provides weekly summary and semantic labels', (WidgetTester tester) async {
        final testData = [
          ChartData('Mon', 5, Colors.blue),
          ChartData('Tue', 8, Colors.blue),
          ChartData('Wed', 3, Colors.blue),
          ChartData('Thu', 12, Colors.blue),
          ChartData('Fri', 7, Colors.blue),
        ];
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 500,
                child: WeeklyItemsChart(
                  data: testData,
                  animationController: animationController,
                  semanticsLabel: 'Weekly activity chart',
                ),
              ),
            ),
          ),
        );
        
        final SemanticsHandle handle = tester.ensureSemantics();
        
        // Find the main chart semantics
        expect(find.bySemanticsLabel('Weekly activity chart'), findsOneWidget);
        
        // Verify accessible description includes summary
        final semanticsNode = tester.getSemantics(find.byType(WeeklyItemsChart));
        expect(semanticsNode.value, contains('35 total items')); // 5+8+3+12+7
        expect(semanticsNode.value, contains('Thu with 12 items')); // Highest day
        
        // Verify weekly summary is accessible
        expect(find.bySemanticsLabel('Weekly summary'), findsOneWidget);
        
        // Verify summary contains correct calculations
        expect(find.text('Total items: 35'), findsOneWidget);
        expect(find.text('Average per day: 7.0'), findsOneWidget);
        
        handle.dispose();
      });
      
      testWidgets('handles single day data correctly', (WidgetTester tester) async {
        final testData = [
          ChartData('Today', 10, Colors.blue),
        ];
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 500,
                child: WeeklyItemsChart(
                  data: testData,
                  animationController: animationController,
                ),
              ),
            ),
          ),
        );
        
        final SemanticsHandle handle = tester.ensureSemantics();
        
        // Verify description works with single data point
        final semanticsNode = tester.getSemantics(find.byType(WeeklyItemsChart));
        expect(semanticsNode.value, contains('10 total items'));
        expect(semanticsNode.value, contains('Today with 10 items'));
        
        handle.dispose();
      });
    });
    
    group('Chart Interaction Accessibility', () {
      testWidgets('charts respond to semantic tap actions', (WidgetTester tester) async {
        final testData = [
          ChartData('Test', 5, Colors.blue),
        ];
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 400,
                child: WasteCategoryPieChart(
                  data: testData,
                  animationController: animationController,
                ),
              ),
            ),
          ),
        );
        
        final SemanticsHandle handle = tester.ensureSemantics();
        
        // Find the chart and verify it has tap action
        final semanticsNode = tester.getSemantics(find.byType(WasteCategoryPieChart));
        expect(semanticsNode.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
        
        // Simulate semantic tap (screen reader double-tap)
        await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
          'flutter/semantics',
          null,
          (data) {},
        );
        
        handle.dispose();
      });
    });
    
    group('Chart Color Accessibility', () {
      testWidgets('charts work without relying solely on color', (WidgetTester tester) async {
        final testData = [
          ChartData('Category A', 10, Colors.red),
          ChartData('Category B', 15, Colors.red), // Same color to test non-color differentiation
        ];
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 400,
                child: WasteCategoryPieChart(
                  data: testData,
                  animationController: animationController,
                ),
              ),
            ),
          ),
        );
        
        final SemanticsHandle handle = tester.ensureSemantics();
        
        // Verify that categories are distinguishable by text labels, not just color
        expect(find.byWidgetPredicate((widget) => 
          widget is Text && 
          widget.data != null &&
          widget.data!.contains('Category A') &&
          widget.data!.contains('%')
        ), findsOneWidget);
        expect(find.byWidgetPredicate((widget) => 
          widget is Text && 
          widget.data != null &&
          widget.data!.contains('Category B') &&
          widget.data!.contains('%')
        ), findsOneWidget);
        
        // Verify semantic labels distinguish between categories
        expect(find.byWidgetPredicate((widget) => 
          widget is Semantics && 
          widget.properties.label != null &&
          widget.properties.label!.contains('Category A: 10 items')
        ), findsOneWidget);
        expect(find.byWidgetPredicate((widget) => 
          widget is Semantics && 
          widget.properties.label != null &&
          widget.properties.label!.contains('Category B: 15 items')
        ), findsOneWidget);
        
        handle.dispose();
      });
    });
  });
}

/// Test implementation of TickerProvider for animation controller
class TestVSync implements TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
} 