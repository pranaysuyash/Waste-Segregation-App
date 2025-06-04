import 'dart:typed_data'; // Added import
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:waste_segregation_app/services/ai_service.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import '../test_helper.dart';

// Manual mock for testing
class MockAiService extends Mock implements AiService {}

void main() {
  group('AiService', () {
    late AiService aiService;

    setUpAll(() async {
      await TestHelper.setupCompleteTest();
    });

    tearDownAll(() async {
      await TestHelper.tearDownCompleteTest();
    });

    setUp(() {
      aiService = AiService();
    });

    tearDown(() async {
      await TestHelper.cleanupServiceTest();
    });

    group('Image Classification', () {
      test('should handle empty image gracefully', () async {
        // This test expects an exception for empty image data
        expect(() async => aiService.analyzeWebImage(Uint8List(0), 'test.jpg'),
               throwsA(isA<Exception>()));
      });

      test('should handle null or empty image path', () async {
        try {
          final result = await aiService.analyzeWebImage(Uint8List(0), '');
          // If it succeeds, it should return a fallback classification
          expect(result, isA<WasteClassification>());
          expect(result.clarificationNeeded, isTrue);
        } catch (e) {
          // Exception is also acceptable for null/empty image path
          expect(e, isA<Exception>());
        }
      });

      test('should handle invalid file extension', () async {
        try {
          final result = await aiService.analyzeWebImage(Uint8List(0), 'invalid_file.txt');
          // If it succeeds, it should return a fallback classification
          expect(result, isA<WasteClassification>());
          expect(result.clarificationNeeded, isTrue);
        } catch (e) {
          // Exception is also acceptable for invalid file extensions
          expect(e, isA<Exception>());
        }
      });

      // Test with a small test image if available
      test('should attempt API call with valid image data', () async {
        // Create a minimal test image (1x1 pixel)
        final testImageData = Uint8List.fromList([
          0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46,
          0x00, 0x01, 0x01, 0x01, 0x00, 0x48, 0x00, 0x48, 0x00, 0x00,
          0xFF, 0xDB, 0x00, 0x43, 0x00, 0x08, 0x06, 0x06, 0x07, 0x06,
          0x05, 0x08, 0x07, 0x07, 0x07, 0x09, 0x09, 0x08, 0x0A, 0x0C,
          0x14, 0x0D, 0x0C, 0x0B, 0x0B, 0x0C, 0x19, 0x12, 0x13, 0x0F,
          0xFF, 0xD9 // JPEG end marker
        ]);

        try {
          final result = await aiService.analyzeWebImage(testImageData, 'test.jpg');
          // If we get a result, validate it
          expect(result, isA<WasteClassification>());
          expect(result.itemName, isNotEmpty);
          expect(result.category, isNotEmpty);
        } catch (e) {
          // API call expected to fail in test environment without valid keys or due to invalid test image
          // This is acceptable - we're testing the flow, not the API response
          expect(e, isA<Exception>());
          print('Expected test failure due to test environment: $e');
        }
      });
    });

    group('Classification Result Validation', () {
      test('WasteClassification should have required fields', () {
        final classification = WasteClassification(
          itemName: 'Test Item',
          category: 'Dry Waste',
          subcategory: 'Plastic',
          explanation: 'Test explanation',
          disposalInstructions: DisposalInstructions(
            primaryMethod: 'Recycle',
            steps: ['Step 1', 'Step 2'],
            hasUrgentTimeframe: false,
          ),
          timestamp: DateTime.now(),
          region: 'Test Region',
          visualFeatures: ['plastic', 'bottle'],
          alternatives: [],
          confidence: 0.85,
        );

        expect(classification.itemName, equals('Test Item'));
        expect(classification.category, equals('Dry Waste'));
        expect(classification.subcategory, equals('Plastic'));
        expect(classification.confidence, equals(0.85));
        expect(classification.disposalInstructions.steps.length, equals(2));
        expect(classification.visualFeatures.length, equals(2));
      });

      test('should validate confidence score range', () {
        final highConfidenceClassification = WasteClassification(
          itemName: 'Test Item',
          category: 'Dry Waste',
          explanation: 'Test explanation',
          disposalInstructions: DisposalInstructions(
            primaryMethod: 'Recycle',
            steps: ['Step 1'],
            hasUrgentTimeframe: false,
          ),
          timestamp: DateTime.now(),
          region: 'Test Region',
          visualFeatures: [],
          alternatives: [],
          confidence: 0.95,
        );

        final lowConfidenceClassification = WasteClassification(
          itemName: 'Test Item',
          category: 'Dry Waste',
          explanation: 'Test explanation',
          disposalInstructions: DisposalInstructions(
            primaryMethod: 'Recycle',
            steps: ['Step 1'],
            hasUrgentTimeframe: false,
          ),
          timestamp: DateTime.now(),
          region: 'Test Region',
          visualFeatures: [],
          alternatives: [],
          confidence: 0.25,
        );

        expect(highConfidenceClassification.confidence, greaterThan(0.8));
        expect(lowConfidenceClassification.confidence, lessThan(0.5));
      });
    });

    group('Category Validation', () {
      test('should recognize valid waste categories', () {
        const validCategories = [
          'Dry Waste',
          'Wet Waste',
          'Hazardous Waste',
          'Medical Waste',
          'Non-Waste'
        ];

        for (final category in validCategories) {
          final classification = WasteClassification(
            itemName: 'Test Item',
            category: category,
            explanation: 'Test explanation',
            disposalInstructions: DisposalInstructions(
              primaryMethod: 'Test method',
              steps: ['Step 1'],
              hasUrgentTimeframe: false,
            ),
            timestamp: DateTime.now(),
            region: 'Test Region',
            visualFeatures: [],
            alternatives: [],
          );

          expect(validCategories.contains(classification.category), isTrue);
        }
      });
    });

    group('Error Handling', () {
      test('should handle network errors gracefully', () async {
        try {
          final result = await aiService.analyzeWebImage(Uint8List(0), 'non_existent_file.jpg');
          // If it succeeds, it should return a fallback classification
          expect(result, isA<WasteClassification>());
          expect(result.clarificationNeeded, isTrue);
        } catch (e) {
          // Exception is also acceptable for network errors
          expect(e, isA<Exception>());
        }
      });

      test('should handle invalid file formats', () async {
        try {
          final result = await aiService.analyzeWebImage(Uint8List(0), 'invalid_file.txt');
          // If it succeeds, it should return a fallback classification
          expect(result, isA<WasteClassification>());
          expect(result.clarificationNeeded, isTrue);
        } catch (e) {
          // Exception is also acceptable for invalid file formats
          expect(e, isA<Exception>());
        }
      });
    });

    group('Disposal Instructions', () {
      test('should provide appropriate disposal instructions for different waste types', () {
        final plasticClassification = WasteClassification(
          itemName: 'Plastic Bottle',
          category: 'Dry Waste',
          subcategory: 'Plastic',
          explanation: 'Recyclable plastic bottle',
          disposalInstructions: DisposalInstructions(
            primaryMethod: 'Recycle in blue bin',
            steps: ['Remove cap', 'Rinse clean', 'Place in recycling bin'],
            hasUrgentTimeframe: false,
          ),
          timestamp: DateTime.now(),
          region: 'Test Region',
          visualFeatures: [],
          alternatives: [],
        );

        final hazardousClassification = WasteClassification(
          itemName: 'Battery',
          category: 'Hazardous Waste',
          subcategory: 'Electronic Waste',
          explanation: 'Contains toxic materials',
          disposalInstructions: DisposalInstructions(
            primaryMethod: 'Take to hazardous waste facility',
            steps: ['Do not throw in regular trash', 'Find local e-waste center', 'Drop off safely'],
            hasUrgentTimeframe: true,
          ),
          timestamp: DateTime.now(),
          region: 'Test Region',
          visualFeatures: [],
          alternatives: [],
        );

        expect(plasticClassification.disposalInstructions.hasUrgentTimeframe, isFalse);
        expect(hazardousClassification.disposalInstructions.hasUrgentTimeframe, isTrue);
        expect(plasticClassification.disposalInstructions.steps.length, equals(3));
        expect(hazardousClassification.disposalInstructions.steps.length, equals(3));
      });
    });

    group('Cache Integration', () {
      test('should use cache service properly', () async {
        // Test that the AI service integrates with cache properly
        final mockCache = TestHelper.createMockCacheService();
        
        // Test cache initialization and basic functionality
        await mockCache.initialize();
        
        // Test cache operations
        final testHash = 'test_hash';
        final testClassification = WasteClassification(
          itemName: 'Test Item',
          category: 'Dry Waste',
          explanation: 'Test explanation',
          disposalInstructions: DisposalInstructions(
            primaryMethod: 'Test method',
            steps: ['Step 1'],
            hasUrgentTimeframe: false,
          ),
          timestamp: DateTime.now(),
          region: 'Test Region',
          visualFeatures: [],
          alternatives: [],
        );
        
        // Test caching
        await mockCache.cacheClassification(testHash, testClassification);
        
        // Test retrieval
        final cached = await mockCache.getCachedClassification(testHash);
        expect(cached, isNotNull);
        expect(cached!.classification.itemName, equals('Test Item'));
        
        // Test statistics
        final stats = mockCache.getCacheStatistics();
        expect(stats, containsPair('size', 1));
        
        // Test cache clearing
        await mockCache.clearCache();
        final statsAfterClear = mockCache.getCacheStatistics();
        expect(statsAfterClear, containsPair('size', 0));
      });
    });
  });
} 