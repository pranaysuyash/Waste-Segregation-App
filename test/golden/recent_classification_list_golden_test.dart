import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/widgets/modern_ui/modern_cards.dart';

void main() {
  group('Recent Classification List Golden Tests', () {
    testWidgets('RecentClassificationCard basic layout golden test', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  RecentClassificationCard(
                    itemName: 'Plastic Water Bottle',
                    category: 'Dry Waste',
                    subcategory: 'Plastic',
                    timestamp: DateTime(2024, 1, 15, 10, 30),
                    imageUrl: 'test_image.jpg',
                    isRecyclable: true,
                    isCompostable: false,
                    requiresSpecialDisposal: false,
                    onTap: () {},
                  ),
                  const SizedBox(height: 16),
                  RecentClassificationCard(
                    itemName: 'Apple Core',
                    category: 'Wet Waste',
                    subcategory: 'Food',
                    timestamp: DateTime(2024, 1, 14, 15, 45),
                    imageUrl: 'test_image2.jpg',
                    isRecyclable: false,
                    isCompostable: true,
                    requiresSpecialDisposal: false,
                    onTap: () {},
                  ),
                  const SizedBox(height: 16),
                  RecentClassificationCard(
                    itemName: 'Used Battery',
                    category: 'Hazardous Waste',
                    subcategory: 'Electronic',
                    timestamp: DateTime(2024, 1, 13, 9, 15),
                    imageUrl: 'test_image3.jpg',
                    isRecyclable: false,
                    isCompostable: false,
                    requiresSpecialDisposal: true,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('recent_classification_list_basic.png'),
      );
    });

    testWidgets('RecentClassificationCard overflow handling golden test', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SizedBox(
                    width: 300,
                    child: RecentClassificationCard(
                      itemName: 'Very Long Item Name That Should Not Cause Overflow Issues',
                      category: 'Dry Waste',
                      subcategory: 'Very Long Subcategory Name',
                      timestamp: DateTime(2024, 1, 15, 10, 30),
                      imageUrl: 'test_image.jpg',
                      isRecyclable: true,
                      isCompostable: true,
                      requiresSpecialDisposal: true,
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 250,
                    child: RecentClassificationCard(
                      itemName: 'Medium Width Item Name',
                      category: 'Wet Waste',
                      subcategory: 'Food',
                      timestamp: DateTime(2024, 1, 14, 15, 45),
                      imageUrl: 'test_image2.jpg',
                      isRecyclable: false,
                      isCompostable: true,
                      requiresSpecialDisposal: false,
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 200,
                    child: RecentClassificationCard(
                      itemName: 'Narrow Screen Item',
                      category: 'Hazardous Waste',
                      subcategory: 'Chemical',
                      timestamp: DateTime(2024, 1, 13, 9, 15),
                      isRecyclable: false,
                      isCompostable: false,
                      requiresSpecialDisposal: true,
                      showImage: false, // Hide image for narrow screen
                      onTap: () {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('recent_classification_list_overflow.png'),
      );
    });

    testWidgets('RecentClassificationCard property indicators golden test', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  RecentClassificationCard(
                    itemName: 'Recyclable Only',
                    category: 'Dry Waste',
                    timestamp: DateTime(2024, 1, 15, 10, 30),
                    isRecyclable: true,
                    isCompostable: false,
                    requiresSpecialDisposal: false,
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),
                  RecentClassificationCard(
                    itemName: 'Compostable Only',
                    category: 'Wet Waste',
                    timestamp: DateTime(2024, 1, 14, 15, 45),
                    isRecyclable: false,
                    isCompostable: true,
                    requiresSpecialDisposal: false,
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),
                  RecentClassificationCard(
                    itemName: 'Special Disposal Only',
                    category: 'Hazardous Waste',
                    timestamp: DateTime(2024, 1, 13, 9, 15),
                    isRecyclable: false,
                    isCompostable: false,
                    requiresSpecialDisposal: true,
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),
                  RecentClassificationCard(
                    itemName: 'All Properties',
                    category: 'Medical Waste',
                    timestamp: DateTime(2024, 1, 12, 14, 20),
                    isRecyclable: true,
                    isCompostable: true,
                    requiresSpecialDisposal: true,
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),
                  RecentClassificationCard(
                    itemName: 'No Properties',
                    category: 'Non-Waste',
                    timestamp: DateTime(2024, 1, 11, 11, 10),
                    isRecyclable: false,
                    isCompostable: false,
                    requiresSpecialDisposal: false,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('recent_classification_list_indicators.png'),
      );
    });

    testWidgets('RecentClassificationCard responsive layout golden test', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Wide layout
                  SizedBox(
                    width: 400,
                    child: RecentClassificationCard(
                      itemName: 'Wide Layout Item',
                      category: 'Dry Waste',
                      subcategory: 'Paper',
                      timestamp: DateTime(2024, 1, 15, 10, 30),
                      imageUrl: 'test_image.jpg',
                      isRecyclable: true,
                      isCompostable: false,
                      requiresSpecialDisposal: false,
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Medium layout
                  SizedBox(
                    width: 300,
                    child: RecentClassificationCard(
                      itemName: 'Medium Layout Item',
                      category: 'Wet Waste',
                      subcategory: 'Food',
                      timestamp: DateTime(2024, 1, 14, 15, 45),
                      imageUrl: 'test_image2.jpg',
                      isRecyclable: false,
                      isCompostable: true,
                      requiresSpecialDisposal: false,
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Narrow layout
                  SizedBox(
                    width: 250,
                    child: RecentClassificationCard(
                      itemName: 'Narrow Layout Item',
                      category: 'Hazardous Waste',
                      subcategory: 'Chemical',
                      timestamp: DateTime(2024, 1, 13, 9, 15),
                      imageUrl: 'test_image3.jpg',
                      isRecyclable: false,
                      isCompostable: false,
                      requiresSpecialDisposal: true,
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Very narrow layout
                  SizedBox(
                    width: 180,
                    child: RecentClassificationCard(
                      itemName: 'Very Narrow Item',
                      category: 'Medical Waste',
                      subcategory: 'Syringe',
                      timestamp: DateTime(2024, 1, 12, 14, 20),
                      isRecyclable: false,
                      isCompostable: false,
                      requiresSpecialDisposal: true,
                      showImage: false, // Hide image for very narrow
                      onTap: () {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('recent_classification_list_responsive.png'),
      );
    });

    testWidgets('RecentClassificationCard minimal layout golden test', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  RecentClassificationCard(
                    itemName: 'Basic Item',
                    category: 'Dry Waste',
                    timestamp: DateTime(2024, 1, 15, 10, 30),
                    onTap: () {},
                  ),
                  const SizedBox(height: 16),
                  RecentClassificationCard(
                    itemName: 'Item with Subcategory',
                    category: 'Wet Waste',
                    subcategory: 'Food',
                    timestamp: DateTime(2024, 1, 14, 15, 45),
                    onTap: () {},
                  ),
                  const SizedBox(height: 16),
                  RecentClassificationCard(
                    itemName: 'Item with Image Only',
                    category: 'Hazardous Waste',
                    timestamp: DateTime(2024, 1, 13, 9, 15),
                    imageUrl: 'test_image.jpg',
                    showPropertyIndicators: false,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(Scaffold),
        matchesGoldenFile('recent_classification_list_minimal.png'),
      );
    });
  });
}
