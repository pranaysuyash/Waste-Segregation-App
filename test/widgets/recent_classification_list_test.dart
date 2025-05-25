import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/widgets/modern_ui/modern_cards.dart';
import 'package:waste_segregation_app/utils/constants.dart';

void main() {
  group('Recent Classification List Tests', () {
    testWidgets('RecentClassificationCard displays basic information correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecentClassificationCard(
              itemName: 'Plastic Bottle',
              category: 'Dry Waste',
              subcategory: 'Plastic',
              timestamp: DateTime.now(),
              imageUrl: 'test_image.jpg',
              isRecyclable: true,
              isCompostable: false,
              requiresSpecialDisposal: false,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Plastic Bottle'), findsOneWidget);
      expect(find.text('Dry Waste'), findsOneWidget);
      expect(find.text('Plastic'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.byIcon(Icons.recycling), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('RecentClassificationCard handles long item names without overflow', (WidgetTester tester) async {
      const longItemName = 'Very Long Item Name That Should Not Cause Overflow Issues In The Layout';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: RecentClassificationCard(
                itemName: longItemName,
                category: 'Wet Waste',
                timestamp: DateTime.now(),
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(RecentClassificationCard), findsOneWidget);
      expect(find.textContaining('Very Long'), findsOneWidget);
      
      // Should not throw overflow errors
      await tester.pumpAndSettle();
    });

    testWidgets('RecentClassificationCard adapts to narrow screens', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 250, // Narrow width
              child: RecentClassificationCard(
                itemName: 'Test Item',
                category: 'Hazardous Waste',
                subcategory: 'Battery',
                timestamp: DateTime.now(),
                isRecyclable: true,
                isCompostable: true,
                requiresSpecialDisposal: true,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(RecentClassificationCard), findsOneWidget);
      expect(find.text('Test Item'), findsOneWidget);
      expect(find.text('Hazardous Waste'), findsOneWidget);
      
      // Should handle narrow width gracefully
      await tester.pumpAndSettle();
    });

    testWidgets('RecentClassificationCard adapts to very narrow screens', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200, // Very narrow width
              child: RecentClassificationCard(
                itemName: 'Test Item',
                category: 'Medical Waste',
                subcategory: 'Syringe',
                timestamp: DateTime.now(),
                imageUrl: 'test_image.jpg',
                isRecyclable: false,
                isCompostable: false,
                requiresSpecialDisposal: true,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(RecentClassificationCard), findsOneWidget);
      expect(find.text('Test Item'), findsOneWidget);
      expect(find.text('Medical Waste'), findsOneWidget);
      
      // Should handle very narrow width gracefully
      await tester.pumpAndSettle();
    });

    testWidgets('RecentClassificationCard handles tap events correctly', (WidgetTester tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecentClassificationCard(
              itemName: 'Test Item',
              category: 'Dry Waste',
              timestamp: DateTime.now(),
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(RecentClassificationCard));
      expect(tapped, isTrue);
    });

    testWidgets('RecentClassificationCard shows/hides optional elements correctly', (WidgetTester tester) async {
      // Test without optional elements
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecentClassificationCard(
              itemName: 'Basic Item',
              category: 'Wet Waste',
              timestamp: DateTime.now(),
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Basic Item'), findsOneWidget);
      expect(find.text('Wet Waste'), findsOneWidget);
      expect(find.byIcon(Icons.recycling), findsNothing); // No recyclable indicator
      expect(find.byIcon(Icons.eco), findsNothing); // No compostable indicator

      // Test with all optional elements
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecentClassificationCard(
              itemName: 'Full Item',
              category: 'Dry Waste',
              subcategory: 'Paper',
              timestamp: DateTime.now(),
              imageUrl: 'test_image.jpg',
              isRecyclable: true,
              isCompostable: true,
              requiresSpecialDisposal: true,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Full Item'), findsOneWidget);
      expect(find.text('Dry Waste'), findsOneWidget);
      expect(find.text('Paper'), findsOneWidget);
      expect(find.byIcon(Icons.recycling), findsOneWidget);
      expect(find.byIcon(Icons.eco), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber), findsOneWidget);
    });

    testWidgets('RecentClassificationCard uses custom colors correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecentClassificationCard(
              itemName: 'Colored Item',
              category: 'Custom Category',
              timestamp: DateTime.now(),
              categoryColor: Colors.purple,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byType(RecentClassificationCard), findsOneWidget);
      expect(find.text('Colored Item'), findsOneWidget);
      expect(find.text('Custom Category'), findsOneWidget);
    });

    testWidgets('RecentClassificationCard handles date formatting correctly', (WidgetTester tester) async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = DateTime(now.year, now.month, now.day - 1);
      final oldDate = DateTime(2023, 1, 15);

      // Test today
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecentClassificationCard(
              itemName: 'Today Item',
              category: 'Wet Waste',
              timestamp: today,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Today'), findsOneWidget);

      // Test yesterday
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecentClassificationCard(
              itemName: 'Yesterday Item',
              category: 'Wet Waste',
              timestamp: yesterday,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Yesterday'), findsOneWidget);

      // Test old date
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecentClassificationCard(
              itemName: 'Old Item',
              category: 'Wet Waste',
              timestamp: oldDate,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('15/1/2023'), findsOneWidget);
    });

    testWidgets('RecentClassificationCard handles multiple property indicators', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecentClassificationCard(
              itemName: 'Multi Property Item',
              category: 'Dry Waste',
              timestamp: DateTime.now(),
              isRecyclable: true,
              isCompostable: true,
              requiresSpecialDisposal: true,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.recycling), findsOneWidget);
      expect(find.byIcon(Icons.eco), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber), findsOneWidget);
    });

    testWidgets('RecentClassificationCard handles extremely long text gracefully', (WidgetTester tester) async {
      const extremelyLongItemName = 'This is an extremely long item name that should definitely cause overflow issues if not handled properly by the responsive text system';
      const extremelyLongSubcategory = 'Very Long Subcategory Name That Should Not Break Layout';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200, // Very narrow to force overflow
              child: RecentClassificationCard(
                itemName: extremelyLongItemName,
                category: 'Dry Waste',
                subcategory: extremelyLongSubcategory,
                timestamp: DateTime.now(),
                isRecyclable: true,
                isCompostable: true,
                requiresSpecialDisposal: true,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(RecentClassificationCard), findsOneWidget);
      
      // Should not throw overflow errors
      await tester.pumpAndSettle();
    });

    testWidgets('RecentClassificationCard accessibility test', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecentClassificationCard(
              itemName: 'Accessible Item',
              category: 'Wet Waste',
              subcategory: 'Food',
              timestamp: DateTime.now(),
              isRecyclable: false,
              isCompostable: true,
              onTap: () {},
            ),
          ),
        ),
      );

      // Should be accessible by text content
      expect(find.text('Accessible Item'), findsOneWidget);
      expect(find.text('Wet Waste'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      
      // Should be tappable
      await tester.tap(find.byType(RecentClassificationCard));
      await tester.pumpAndSettle();
    });

    testWidgets('RecentClassificationCard performance test with multiple instances', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: List.generate(
                5,
                (index) => RecentClassificationCard(
                  itemName: 'Item $index',
                  category: 'Category $index',
                  subcategory: 'Subcategory $index',
                  timestamp: DateTime.now().subtract(Duration(days: index)),
                  isRecyclable: index % 2 == 0,
                  isCompostable: index % 3 == 0,
                  requiresSpecialDisposal: index % 4 == 0,
                  onTap: () {},
                ),
              ),
            ),
          ),
        ),
      );

      // All instances should render
      expect(find.byType(RecentClassificationCard), findsNWidgets(5));
      for (int i = 0; i < 5; i++) {
        expect(find.text('Item $i'), findsOneWidget);
        expect(find.text('Category $i'), findsOneWidget);
        expect(find.text('Subcategory $i'), findsOneWidget);
      }
    });

    testWidgets('RecentClassificationCard handles image display options', (WidgetTester tester) async {
      // Test with image enabled
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecentClassificationCard(
              itemName: 'Item With Image',
              category: 'Dry Waste',
              timestamp: DateTime.now(),
              imageUrl: 'test_image.jpg',
              showImage: true,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byType(RecentClassificationCard), findsOneWidget);

      // Test with image disabled
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecentClassificationCard(
              itemName: 'Item Without Image',
              category: 'Dry Waste',
              timestamp: DateTime.now(),
              imageUrl: 'test_image.jpg',
              showImage: false,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byType(RecentClassificationCard), findsOneWidget);
    });

    testWidgets('RecentClassificationCard handles property indicators toggle', (WidgetTester tester) async {
      // Test with property indicators enabled
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecentClassificationCard(
              itemName: 'Item With Indicators',
              category: 'Dry Waste',
              timestamp: DateTime.now(),
              isRecyclable: true,
              isCompostable: true,
              showPropertyIndicators: true,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.recycling), findsOneWidget);
      expect(find.byIcon(Icons.eco), findsOneWidget);

      // Test with property indicators disabled
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecentClassificationCard(
              itemName: 'Item Without Indicators',
              category: 'Dry Waste',
              timestamp: DateTime.now(),
              isRecyclable: true,
              isCompostable: true,
              showPropertyIndicators: false,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.recycling), findsNothing);
      expect(find.byIcon(Icons.eco), findsNothing);
    });

    testWidgets('RecentClassificationCard handles vertical badge layout', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 180, // Very narrow to force vertical layout
              child: RecentClassificationCard(
                itemName: 'Narrow Item',
                category: 'Hazardous Waste',
                subcategory: 'Chemical',
                timestamp: DateTime.now(),
                isRecyclable: false,
                isCompostable: false,
                requiresSpecialDisposal: true,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(RecentClassificationCard), findsOneWidget);
      expect(find.text('Narrow Item'), findsOneWidget);
      expect(find.text('Hazardous Waste'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber), findsOneWidget);
      
      // Should handle vertical layout gracefully
      await tester.pumpAndSettle();
    });
  });

  group('Recent Classification List Theme Tests', () {
    testWidgets('RecentClassificationCard respects theme colors', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: RecentClassificationCard(
              itemName: 'Theme Test',
              category: 'Wet Waste',
              timestamp: DateTime.now(),
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byType(RecentClassificationCard), findsOneWidget);
      await tester.pumpAndSettle();

      // Test with dark theme
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: RecentClassificationCard(
              itemName: 'Theme Test',
              category: 'Wet Waste',
              timestamp: DateTime.now(),
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byType(RecentClassificationCard), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('RecentClassificationCard handles default category colors', (WidgetTester tester) async {
      final categories = [
        'Wet Waste',
        'Dry Waste',
        'Hazardous Waste',
        'Medical Waste',
        'Non-Waste',
        'Unknown Category',
      ];

      for (final category in categories) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RecentClassificationCard(
                itemName: 'Test Item',
                category: category,
                timestamp: DateTime.now(),
                onTap: () {},
              ),
            ),
          ),
        );

        expect(find.byType(RecentClassificationCard), findsOneWidget);
        expect(find.text(category), findsOneWidget);
        await tester.pumpAndSettle();
      }
    });
  });
} 