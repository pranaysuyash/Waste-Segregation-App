import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/services/disposal_instructions_service.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';

void main() {
  group('DisposalInstructionsService', () {
    late DisposalInstructionsService service;

    setUp(() {
      service = DisposalInstructionsService();
    });

    test('should build language-aware cache keys', () {
      final keyEn = service.buildMaterialCacheKey(
        material: 'plastic bottle',
        category: 'Dry Waste',
        lang: 'en',
      );
      final keyHi = service.buildMaterialCacheKey(
        material: 'plastic bottle',
        category: 'Dry Waste',
        lang: 'hi',
      );

      expect(keyEn, isNot(equals(keyHi)));
      expect(keyEn, contains('lang=en'));
      expect(keyHi, contains('lang=hi'));
    });

    test('should build unicode-safe cache keys', () {
      final key = service.buildMaterialCacheKey(
        material: 'प्लास्टिक बोतल',
        category: 'Dry Waste',
        subcategory: 'PET 1',
        lang: 'hi',
      );

      expect(key, contains('lang=hi'));
      expect(key, contains('material='));
      expect(key, contains('category=dry%20waste'));
      expect(key, contains('subcategory=pet%201'));
      expect(key.contains('/'), false);
    });

    test('should distinguish keys by category and subcategory', () {
      final key1 = service.buildMaterialCacheKey(
        material: 'bottle',
        category: 'Dry Waste',
        subcategory: 'PET',
      );
      final key2 = service.buildMaterialCacheKey(
        material: 'bottle',
        category: 'Dry Waste',
        subcategory: 'HDPE',
      );

      expect(key1, isNot(equals(key2)));
    });

    test('should preserve legacy key format compatibility', () {
      final legacy = service.buildLegacyMaterialId(
        'plastic bottle',
        'Dry Waste',
        'PET 1',
      );
      final canonical = service.buildMaterialCacheKey(
        material: 'plastic bottle',
        category: 'Dry Waste',
        subcategory: 'PET 1',
        lang: 'en',
      );

      expect(legacy, 'plasticbottle_drywaste_pet1');
      expect(canonical, isNot(equals(legacy)));
    });

    test('should return fallback instructions for wet waste', () async {
      final instructions = await service.getDisposalInstructions(
        material: 'food scraps',
        category: 'Wet Waste',
      );

      expect(instructions.primaryMethod, contains('Compost'));
      expect(instructions.steps.length, greaterThan(3));
      expect(instructions.hasUrgentTimeframe, false);
    });

    test('should return fallback instructions for hazardous waste', () async {
      final instructions = await service.getDisposalInstructions(
        material: 'battery',
        category: 'Hazardous Waste',
      );

      expect(instructions.primaryMethod, contains('Special disposal'));
      expect(instructions.steps.length, greaterThan(3));
      expect(instructions.hasUrgentTimeframe, true);
      expect(instructions.warnings, isNotNull);
      expect(instructions.warnings!.isNotEmpty, true);
    });

    test('should handle empty material gracefully', () async {
      final instructions = await service.getDisposalInstructions(
        material: '',
        category: 'Dry Waste',
      );

      expect(instructions.primaryMethod, isNotEmpty);
      expect(instructions.steps.isNotEmpty, true);
    });

    test('should return different instructions for different categories',
        () async {
      final service = DisposalInstructionsService();

      // Test with dry waste
      final instructions1 = await service.getDisposalInstructions(
        material: 'test item',
        category: 'Dry Waste',
      );
      expect(instructions1.steps.length, greaterThan(2));

      // Test with wet waste
      final instructions2 = await service.getDisposalInstructions(
        material: 'test item',
        category: 'Wet Waste',
      );
      expect(instructions2.steps.length, greaterThan(2));
      expect(instructions2.primaryMethod,
          isNot(equals(instructions1.primaryMethod)));
    });

    test('should clear cache correctly', () {
      service.clearCache();
      // Cache should be empty after clearing
      // This is more of a smoke test since cache is private
      expect(() => service.clearCache(), returnsNormally);
    });

    test('should handle preloading common materials', () async {
      // This should not throw an exception even if network fails
      expect(() => service.preloadCommonMaterials(), returnsNormally);
    });

    test('should provide resolution metadata contract', () async {
      final resolution = await service.getDisposalInstructionsWithResolution(
        material: 'test item',
        category: 'Dry Waste',
        lang: 'en',
      );

      expect(resolution.source, isNotEmpty);
      expect(resolution.cacheKey, contains('lang=en'));
      expect(resolution.instructions.primaryMethod, isNotEmpty);
      expect(resolution.instructions.steps, isNotEmpty);
    });
  });

  group('DisposalInstructions Model', () {
    test('should create disposal instructions with required fields', () {
      final instructions = DisposalInstructions(
        primaryMethod: 'Test method',
        steps: ['Step 1', 'Step 2'],
        hasUrgentTimeframe: false,
      );

      expect(instructions.primaryMethod, 'Test method');
      expect(instructions.steps.length, 2);
      expect(instructions.hasUrgentTimeframe, false);
    });

    test('should handle optional fields correctly', () {
      final instructions = DisposalInstructions(
        primaryMethod: 'Test method',
        steps: ['Step 1'],
        hasUrgentTimeframe: true,
        timeframe: 'Immediately',
        location: 'Hazardous waste facility',
        warnings: ['Warning 1', 'Warning 2'],
        tips: ['Tip 1'],
        recyclingInfo: 'Recycling info',
        estimatedTime: '5 minutes',
      );

      expect(instructions.timeframe, 'Immediately');
      expect(instructions.location, 'Hazardous waste facility');
      expect(instructions.warnings?.length, 2);
      expect(instructions.tips?.length, 1);
      expect(instructions.recyclingInfo, 'Recycling info');
      expect(instructions.estimatedTime, '5 minutes');
    });
  });
}
