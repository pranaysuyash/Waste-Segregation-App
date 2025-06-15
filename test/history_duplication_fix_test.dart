import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';

void main() {
  group('History Duplication Fix Tests', () {
    
    test('WasteClassification model should have correct properties', () {
      // Create a test classification
      final classification = WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
        itemName: 'Test Plastic Bottle',
        category: 'Dry Waste',
        subcategory: 'Plastic',
        confidence: 0.95,
            region: 'Test Region',
            visualFeatures: ['test feature'],
            alternatives: [],
        timestamp: DateTime.now(),
        imageUrl: '/test/path/image.jpg',
        explanation: 'This is a plastic bottle that should be recycled',
        region: 'Test Region',
        visualFeatures: ['plastic', 'bottle', 'clear'],
        alternatives: [],
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Rinse and recycle',
          steps: ['Remove cap', 'Rinse thoroughly', 'Place in recycling bin'],
          hasUrgentTimeframe: false,
        ),
        isRecyclable: true,
        isCompostable: false,
        requiresSpecialDisposal: false,
        isSaved: true,
        userId: 'test_user',
      );
      
      // Verify properties
      expect(classification.itemName, equals('Test Plastic Bottle'));
      expect(classification.category, equals('Dry Waste'));
      expect(classification.subcategory, equals('Plastic'));
      expect(classification.confidence, equals(0.95));
      expect(classification.isRecyclable, equals(true));
      expect(classification.isCompostable, equals(false));
      expect(classification.isSaved, equals(true));
      expect(classification.userId, equals('test_user'));
    });
    
    test('WasteClassification copyWith should preserve original values', () {
      // Create a test classification
      final original = WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
        itemName: 'Test Item',
        category: 'Dry Waste',
        explanation: 'Test explanation',
        region: 'Test Region',
        visualFeatures: ['test'],
        alternatives: [],
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Test method',
          steps: ['Step 1'],
          hasUrgentTimeframe: false,
        ),
        isSaved: false,
        userId: 'test_user',
      );
      
      // Create a copy with isSaved set to true
      final saved = original.copyWith(isSaved: true);
      
      // Verify that the copy has the updated isSaved value
      expect(saved.isSaved, equals(true));
      expect(saved.itemName, equals(original.itemName));
      expect(saved.category, equals(original.category));
      expect(saved.userId, equals(original.userId));
      
      // Verify original is unchanged
      expect(original.isSaved, equals(false));
    });
    
    test('DisposalInstructions should be created correctly', () {
      final instructions = DisposalInstructions(
        primaryMethod: 'Recycle',
        steps: ['Clean', 'Sort', 'Dispose'],
        hasUrgentTimeframe: false,
      );
      
      expect(instructions.primaryMethod, equals('Recycle'));
      expect(instructions.steps.length, equals(3));
      expect(instructions.steps, contains('Clean'));
      expect(instructions.steps, contains('Sort'));
      expect(instructions.steps, contains('Dispose'));
      expect(instructions.hasUrgentTimeframe, equals(false));
    });
  });
} 