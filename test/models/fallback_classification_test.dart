import 'package:flutter_test/flutter_test.dart';
import '../../lib/models/waste_classification.dart';

void main() {
  group('Fallback Classification Tests', () {
    test('should create proper fallback classification with helpful messaging', () {
      const imagePath = '/test/image.jpg';
      const userId = 'test_user_123';
      
      final fallback = WasteClassification.fallback(imagePath, userId: userId);
      
      // Verify basic properties
      expect(fallback.itemName, equals('Unidentified Item'));
      expect(fallback.category, equals('Requires Manual Review'));
      expect(fallback.subcategory, equals('Classification Needed'));
      expect(fallback.userId, equals(userId));
      expect(fallback.imageUrl, equals(imagePath));
      expect(fallback.confidence, equals(0.0));
      expect(fallback.clarificationNeeded, isTrue);
      expect(fallback.riskLevel, equals('unknown'));
      
      // Verify explanation is helpful and informative
      expect(fallback.explanation, contains('AI was unable to automatically identify'));
      expect(fallback.explanation, contains('image quality'));
      expect(fallback.explanation, contains('feedback'));
      
      // Verify disposal instructions are comprehensive
      expect(fallback.disposalInstructions.primaryMethod, equals('Manual identification required'));
      expect(fallback.disposalInstructions.steps, isNotEmpty);
      expect(fallback.disposalInstructions.steps.length, greaterThanOrEqualTo(5));
      expect(fallback.disposalInstructions.warnings, isNotNull);
      expect(fallback.disposalInstructions.tips, isNotNull);
      expect(fallback.disposalInstructions.hasUrgentTimeframe, isFalse);
      
      // Verify steps contain useful guidance
      final steps = fallback.disposalInstructions.steps.join(' ').toLowerCase();
      expect(steps, contains('material type'));
      expect(steps, contains('local waste'));
      expect(steps, contains('feedback'));
      
      // Verify warnings are present
      final warnings = fallback.disposalInstructions.warnings!.join(' ').toLowerCase();
      expect(warnings, contains('do not dispose'));
      expect(warnings, contains('special handling'));
      
      // Verify tips are helpful
      final tips = fallback.disposalInstructions.tips!.join(' ').toLowerCase();
      expect(tips, contains('clearer photo'));
      expect(tips, contains('lighting'));
      expect(tips, contains('image frame'));
      
      // Verify alternatives are provided
      expect(fallback.alternatives, isNotEmpty);
      expect(fallback.alternatives.length, equals(3));
      
      final categories = fallback.alternatives.map((alt) => alt.category).toList();
      expect(categories, contains('Wet Waste'));
      expect(categories, contains('Dry Waste'));
      expect(categories, contains('Hazardous Waste'));
      
      // Verify each alternative has a reason
      for (final alternative in fallback.alternatives) {
        expect(alternative.reason, isNotEmpty);
        expect(alternative.confidence, equals(0.0));
      }
      
      // Verify suggested action is provided
      expect(fallback.suggestedAction, isNotNull);
      expect(fallback.suggestedAction, contains('identify'));
      expect(fallback.suggestedAction, contains('feedback'));
    });

    test('should handle null parameters gracefully', () {
      const imagePath = '/test/image.jpg';
      
      final fallback = WasteClassification.fallback(imagePath);
      
      expect(fallback.id, isNotNull);
      expect(fallback.id, isNotEmpty);
      expect(fallback.userId, isNull);
      expect(fallback.imageUrl, equals(imagePath));
    });

    test('should provide different alternatives with unique reasons', () {
      const imagePath = '/test/image.jpg';
      
      final fallback = WasteClassification.fallback(imagePath);
      
      final reasons = fallback.alternatives.map((alt) => alt.reason).toList();
      
      // Each reason should be unique
      expect(reasons.toSet().length, equals(reasons.length));
      
      // Each reason should provide guidance for that category
      expect(reasons[0], contains('organic matter'));  // Wet waste
      expect(reasons[1], contains('paper, plastic, glass'));  // Dry waste
      expect(reasons[2], contains('batteries, electronics'));  // Hazardous waste
    });

    test('should create consistent fallback classifications', () {
      const imagePath = '/test/image.jpg';
      const userId = 'test_user';
      
      final fallback1 = WasteClassification.fallback(imagePath, userId: userId);
      final fallback2 = WasteClassification.fallback(imagePath, userId: userId);
      
      // Should have different IDs
      expect(fallback1.id, isNot(equals(fallback2.id)));
      
      // But same core properties
      expect(fallback1.itemName, equals(fallback2.itemName));
      expect(fallback1.category, equals(fallback2.category));
      expect(fallback1.subcategory, equals(fallback2.subcategory));
      expect(fallback1.explanation, equals(fallback2.explanation));
      expect(fallback1.disposalInstructions.primaryMethod, 
             equals(fallback2.disposalInstructions.primaryMethod));
    });

    test('should be serializable to and from JSON', () {
      const imagePath = '/test/image.jpg';
      const userId = 'test_user';
      
      final original = WasteClassification.fallback(imagePath, userId: userId);
      final json = original.toJson();
      final restored = WasteClassification.fromJson(json);
      
      expect(restored.itemName, equals(original.itemName));
      expect(restored.category, equals(original.category));
      expect(restored.subcategory, equals(original.subcategory));
      expect(restored.explanation, equals(original.explanation));
      expect(restored.confidence, equals(original.confidence));
      expect(restored.clarificationNeeded, equals(original.clarificationNeeded));
      expect(restored.alternatives.length, equals(original.alternatives.length));
    });
  });
} 