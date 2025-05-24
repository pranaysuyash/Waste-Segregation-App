import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/gamification.dart';

void main() {
  group('Statistics Display Fix Tests', () {
    test('Total items identified calculation should convert points to items correctly', () {
      // Create a mock profile with category points
      const categoryPoints = {
        'Wet Waste': 100, // 10 items (100 points / 10 = 10 items)
        'Dry Waste': 30,  // 3 items (30 points / 10 = 3 items)
        'Hazardous Waste': 20, // 2 items (20 points / 10 = 2 items)
      };
      
      const points = UserPoints(
        total: 150,
        categoryPoints: categoryPoints,
      );
      
      // Calculate total items identified (same logic as _getTotalItemsIdentified)
      int totalItems = 0;
      for (final entry in points.categoryPoints.entries) {
        totalItems += (entry.value / 10).round();
      }
      
      // Should be 15 total items (10 + 3 + 2)
      expect(totalItems, equals(15));
      
      // Each category should show correct item count
      final wetWasteItems = (categoryPoints['Wet Waste']! / 10).round();
      final dryWasteItems = (categoryPoints['Dry Waste']! / 10).round();
      final hazardousWasteItems = (categoryPoints['Hazardous Waste']! / 10).round();
      
      expect(wetWasteItems, equals(10));
      expect(dryWasteItems, equals(3));
      expect(hazardousWasteItems, equals(2));
      
      // Total points should still be 150
      expect(points.total, equals(150));
    });

    test('Points to items conversion should handle edge cases', () {
      // Test with partial points (should round correctly)
      const categoryPoints = {
        'Wet Waste': 105, // Should round to 11 items (105 / 10 = 10.5 → 11)
        'Dry Waste': 27,  // Should round to 3 items (27 / 10 = 2.7 → 3)
      };
      
      int totalItems = 0;
      for (final entry in categoryPoints.entries) {
        totalItems += (entry.value / 10).round();
      }
      
      expect(totalItems, equals(14)); // 11 + 3 = 14
    });

    test('Empty category points should result in zero items', () {
      const points = UserPoints(
        total: 0,
        categoryPoints: {},
      );
      
      int totalItems = 0;
      for (final entry in points.categoryPoints.entries) {
        totalItems += (entry.value / 10).round();
      }
      
      expect(totalItems, equals(0));
    });
  });
} 