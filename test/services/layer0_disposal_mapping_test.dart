import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/services/layer0_disposal_mapping.dart';

void main() {
  group('Layer0DisposalMapping', () {
    test('returns instructions for known subcategory', () {
      final disposal = Layer0DisposalMapping.getDisposalInstructions(
        'Dry Waste',
        'Plastic Bottle',
      );

      expect(disposal, isNotNull);
      expect(disposal!.primaryMethod, contains('Recycle'));
    });

    test('returns instructions for Wet Waste subcategory', () {
      final disposal = Layer0DisposalMapping.getDisposalInstructions(
        'Wet Waste',
        'Food Scraps',
      );

      expect(disposal, isNotNull);
      expect(disposal!.primaryMethod, contains('Green bin'));
    });

    test('returns category fallback when subcategory is unknown', () {
      final disposal = Layer0DisposalMapping.getDisposalInstructions(
        'Dry Waste',
        'Unknown Subcategory',
      );

      expect(disposal, isNotNull);
      expect(disposal!.primaryMethod, contains('Blue bin'));
    });

    test('returns Wet Waste category fallback', () {
      final disposal = Layer0DisposalMapping.getDisposalInstructions(
        'Wet Waste',
        'Something Unknown',
      );

      expect(disposal, isNotNull);
      expect(disposal!.primaryMethod, contains('Green bin'));
    });

    test('returns null when category has no fallback', () {
      final disposal = Layer0DisposalMapping.getDisposalInstructions(
        'Hazardous Waste',
        'Battery',
      );

      expect(disposal, isNull);
    });

    test('returns null for null subcategory with unknown category', () {
      final disposal = Layer0DisposalMapping.getDisposalInstructions(
        'Unknown Category',
        null,
      );

      expect(disposal, isNull);
    });

    test('maps all Dry Waste packaging types', () {
      const dryWasteSubcategories = [
        'Plastic Bottle',
        'PET Plastic',
        'HDPE Plastic',
        'Plastic',
        'Glass Bottle',
        'Glass',
        'Cardboard',
        'Paper',
        'Aluminium Can',
        'Metal Can',
        'Metal',
        'Tetra Pak',
        'Packaged Item',
      ];

      for (final sub in dryWasteSubcategories) {
        final disposal = Layer0DisposalMapping.getDisposalInstructions(
          'Dry Waste',
          sub,
        );
        expect(disposal, isNotNull, reason: 'Missing mapping for Dry Waste|$sub');
      }
    });

    test('maps all Wet Waste food subcategories', () {
      const wetWasteSubcategories = [
        'Organic / Food Scraps',
        'Garden Waste / Compost',
        'Liquid / Beverage',
        'Dairy',
        'Meat / Fish',
        'Fruit',
        'Vegetable',
        'Food Scraps',
        'Baked Goods',
      ];

      for (final sub in wetWasteSubcategories) {
        final disposal = Layer0DisposalMapping.getDisposalInstructions(
          'Wet Waste',
          sub,
        );
        expect(disposal, isNotNull, reason: 'Missing mapping for Wet Waste|$sub');
      }
    });

    test('Meat / Fish has urgent timeframe', () {
      final disposal = Layer0DisposalMapping.getDisposalInstructions(
        'Wet Waste',
        'Meat / Fish',
      );

      expect(disposal, isNotNull);
      expect(disposal!.hasUrgentTimeframe, isTrue);
    });
  });
}
