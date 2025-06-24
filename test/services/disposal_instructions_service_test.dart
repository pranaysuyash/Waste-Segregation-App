import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/services/disposal_instructions_service.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';

void main() {
  group('DisposalInstructionsService', () {
    late DisposalInstructionsService service;

    setUp(() {
      service = DisposalInstructionsService();
    });

    test('should generate material ID correctly', () {
      // Test the private method through public interface
      final service = DisposalInstructionsService();

      // This will call _generateMaterialId internally
      expect(() => service.getDisposalInstructions(material: 'plastic bottle'), returnsNormally);
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

    test('should return different instructions for different categories', () async {
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
      expect(instructions2.primaryMethod, isNot(equals(instructions1.primaryMethod)));
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
