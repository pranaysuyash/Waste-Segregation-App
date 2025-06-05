import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/widgets/waste_chart_widgets.dart';

void main() {
  group('Chart Accessibility Tests', () {
    late AnimationController animationController;

    setUpAll(() {
      // Create a test binding for animation controller
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    setUp(() {
      animationController = AnimationController(
        duration: const Duration(milliseconds: 1000),
        vsync: TestVSync(),
      );
      animationController.value = 1.0; // Set to complete for testing
    });

    tearDown(() {
      animationController.dispose();
    });

    group('WasteCategoryPieChart Accessibility', () {
      testWidgets('renders with data and has semantic structure', (WidgetTester tester) async {
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
                ),
              ),
            ),
          ),
        );

        // Verify the widget renders
        expect(find.byType(WasteCategoryPieChart), findsOneWidget);
        
        // Verify it has semantic structure
        final handle = tester.ensureSemantics();
        
        // Check that there are semantic nodes (accessibility structure exists)
        final semanticsNodes = tester.binding.pipelineOwner.semanticsOwner?.rootSemanticsNode?.debugDescribeChildren();
        expect(semanticsNodes, isNotNull);
        
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
        
        // Verify the widget renders even with empty data
        expect(find.byType(WasteCategoryPieChart), findsOneWidget);
        
        // Should show some kind of empty state message
        expect(find.text('No data available'), findsOneWidget);
      });
      
      testWidgets('has proper widget structure', (WidgetTester tester) async {
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
        
        // Verify the widget structure
        expect(find.byType(WasteCategoryPieChart), findsOneWidget);
        expect(find.byType(Column), findsAtLeastNWidgets(1));
        
        // Should have some form of legend or labels
        expect(find.byType(Chip), findsAtLeastNWidgets(2)); // Legend items
      });
    });
    
    group('TopSubcategoriesBarChart Accessibility', () {
      testWidgets('renders with data and has semantic structure', (WidgetTester tester) async {
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
        
        // Verify the widget renders
        expect(find.byType(TopSubcategoriesBarChart), findsOneWidget);
        
        // Verify it has semantic structure
        final handle = tester.ensureSemantics();
        
        // Check that there are semantic nodes
        final semanticsNodes = tester.binding.pipelineOwner.semanticsOwner?.rootSemanticsNode?.debugDescribeChildren();
        expect(semanticsNodes, isNotNull);
        
        handle.dispose();
      });
      
      testWidgets('handles empty data gracefully', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TopSubcategoriesBarChart(
                data: const [],
                animationController: animationController,
              ),
            ),
          ),
        );
        
        // Verify the widget renders even with empty data
        expect(find.byType(TopSubcategoriesBarChart), findsOneWidget);
        
        // Should show some kind of empty state message
        expect(find.text('No data available'), findsOneWidget);
      });
      
      testWidgets('has data table structure', (WidgetTester tester) async {
        final testData = [
          ChartData('Paper', 8, Colors.blue),
          ChartData('Plastic', 12, Colors.orange),
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
        
        // Verify the widget structure includes data table elements
        expect(find.byType(TopSubcategoriesBarChart), findsOneWidget);
        expect(find.byType(Column), findsAtLeastNWidgets(1));
        expect(find.byType(Container), findsAtLeastNWidgets(1));
        
        // Should have text elements for the data
        expect(find.text('Subcategory'), findsOneWidget);
        expect(find.text('Count'), findsOneWidget);
      });
    });
    
    group('WeeklyItemsChart Accessibility', () {
      testWidgets('renders with data and has semantic structure', (WidgetTester tester) async {
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
        
        // Verify the widget renders
        expect(find.byType(WeeklyItemsChart), findsOneWidget);
        
        // Verify it has semantic structure
        final handle = tester.ensureSemantics();
        
        // Check that there are semantic nodes
        final semanticsNodes = tester.binding.pipelineOwner.semanticsOwner?.rootSemanticsNode?.debugDescribeChildren();
        expect(semanticsNodes, isNotNull);
        
        handle.dispose();
      });
      
      testWidgets('handles empty data gracefully', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: WeeklyItemsChart(
                data: const [],
                animationController: animationController,
              ),
            ),
          ),
        );
        
        // Verify the widget renders even with empty data
        expect(find.byType(WeeklyItemsChart), findsOneWidget);
        
        // Should show some kind of empty state message
        expect(find.text('No data available'), findsOneWidget);
      });
      
      testWidgets('has summary structure', (WidgetTester tester) async {
        final testData = [
          ChartData('Mon', 5, Colors.blue),
          ChartData('Tue', 8, Colors.blue),
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
        
        // Verify the widget structure includes summary elements
        expect(find.byType(WeeklyItemsChart), findsOneWidget);
        expect(find.byType(Column), findsAtLeastNWidgets(1));
        
        // Should have summary text elements
        expect(find.text('Weekly Summary'), findsOneWidget);
        expect(find.textContaining('Total items:'), findsOneWidget);
        expect(find.textContaining('Average per day:'), findsOneWidget);
      });
    });
    
    group('Chart Data Validation', () {
      testWidgets('ChartData model works correctly', (WidgetTester tester) async {
        final chartData = ChartData('Test Label', 42.0, Colors.red);
        
        expect(chartData.label, equals('Test Label'));
        expect(chartData.value, equals(42.0));
        expect(chartData.color, equals(Colors.red));
      });
      
      testWidgets('charts handle various data sizes', (WidgetTester tester) async {
        // Test with single item
        final singleData = [ChartData('Single', 1, Colors.blue)];
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 400,
                child: WasteCategoryPieChart(
                  data: singleData,
                  animationController: animationController,
                ),
              ),
            ),
          ),
        );
        
        expect(find.byType(WasteCategoryPieChart), findsOneWidget);
        
        // Test with many items
        final manyData = List.generate(10, (index) => 
          ChartData('Item $index', index.toDouble() + 1, Colors.blue));
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 400,
                child: WasteCategoryPieChart(
                  data: manyData,
                  animationController: animationController,
                ),
              ),
            ),
          ),
        );
        
        expect(find.byType(WasteCategoryPieChart), findsOneWidget);
      });
    });
  });
}

/// Test implementation of TickerProvider for animation controller
class TestVSync implements TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
} 