import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/cached_classification.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import '../test_helper.dart';

void main() {
  group('CachedClassification Model Tests', () {
    late WasteClassification mockClassification;
    late DateTime testTimestamp;

    setUpAll(() async {
      await TestHelper.setupCompleteTest();
    });

    tearDownAll(() async {
      await TestHelper.tearDownCompleteTest();
    });

    setUp(() {
      testTimestamp = DateTime.parse('2024-01-15T10:30:00Z');
      mockClassification = WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
        itemName: 'Plastic Water Bottle',
        subcategory: 'Plastic',
        explanation: 'Clear plastic bottle, recyclable with PET code 1',
          primaryMethod: 'Recycle in blue bin',
          steps: ['Remove cap and label', 'Rinse thoroughly', 'Place in recycling bin'],
          hasUrgentTimeframe: false,
        ),
        timestamp: testTimestamp,
        region: 'Test Region',
        visualFeatures: ['plastic', 'bottle', 'clear', 'PET'],
        alternatives: [],
        confidence: 0.92,
      );
    });

    group('Constructor Tests', () {
      test('should create CachedClassification with all required fields', () {
        const imageHash = 'test_hash_123';
        const imageSize = 1024;

        final cached = CachedClassification(
          imageHash: imageHash,
          classification: mockClassification,
          timestamp: testTimestamp,
          lastAccessed: testTimestamp,
          imageSize: imageSize,
        );

        expect(cached.imageHash, equals(imageHash));
        expect(cached.classification, equals(mockClassification));
        expect(cached.timestamp, equals(testTimestamp));
        expect(cached.lastAccessed, equals(testTimestamp));
        expect(cached.useCount, equals(1));
        expect(cached.imageSize, equals(imageSize));
      });

      test('should create CachedClassification with default timestamp and lastAccessed', () {
        const imageHash = 'test_hash_123';
        final now = DateTime.now();

        final cached = CachedClassification(
          imageHash: imageHash,
          classification: mockClassification,
        );

        expect(cached.imageHash, equals(imageHash));
        expect(cached.classification, equals(mockClassification));
        expect(cached.useCount, equals(1));
        expect(cached.timestamp.difference(now).inSeconds, lessThan(2));
        expect(cached.lastAccessed.difference(now).inSeconds, lessThan(2));
        expect(cached.imageSize, isNull);
      });

      test('should create CachedClassification from factory constructor', () {
        const imageHash = 'test_hash_456';
        const imageSize = 2048;

        final cached = CachedClassification.fromClassification(
          imageHash,
          mockClassification,
          imageSize: imageSize,
        );

        expect(cached.imageHash, equals(imageHash));
        expect(cached.classification, equals(mockClassification));
        expect(cached.useCount, equals(1));
        expect(cached.imageSize, equals(imageSize));
      });
    });

    group('Usage Tracking Tests', () {
      test('should increment use count and update last accessed when marked used', () {
        const imageHash = 'test_hash_usage';
        final originalLastAccessed = DateTime.now().subtract(const Duration(hours: 1));

        final cached = CachedClassification(
          imageHash: imageHash,
          classification: mockClassification,
          lastAccessed: originalLastAccessed,
        );

        expect(cached.useCount, equals(1));
        expect(cached.lastAccessed, equals(originalLastAccessed));

        cached.markUsed();

        expect(cached.useCount, equals(2));
        expect(cached.lastAccessed.isAfter(originalLastAccessed), isTrue);
      });

      test('should increment use count multiple times correctly', () {
        const imageHash = 'test_hash_multiple';
        final cached = CachedClassification(
          imageHash: imageHash,
          classification: mockClassification,
          useCount: 5,
        );

        expect(cached.useCount, equals(5));

        cached.markUsed();
        expect(cached.useCount, equals(6));

        cached.markUsed();
        expect(cached.useCount, equals(7));

        cached.markUsed();
        expect(cached.useCount, equals(8));
      });
    });

    group('Serialization Tests', () {
      test('should serialize and deserialize correctly with toJson/fromJson', () {
        const imageHash = 'test_hash_serialize';
        const imageSize = 1500;
        
        final original = CachedClassification(
          imageHash: imageHash,
          classification: mockClassification,
          timestamp: testTimestamp,
          lastAccessed: testTimestamp,
          useCount: 3,
          imageSize: imageSize,
        );

        // Test toJson
        final json = original.toJson();
        expect(json['imageHash'], equals(imageHash));
        expect(json['useCount'], equals(3));
        expect(json['imageSize'], equals(imageSize));
        expect(json['timestamp'], equals(testTimestamp.toIso8601String()));
        expect(json['lastAccessed'], equals(testTimestamp.toIso8601String()));
        expect(json['classification'], isA<Map<String, dynamic>>());

        // Test fromJson
        final recreated = CachedClassification.fromJson(json);
        expect(recreated.imageHash, equals(original.imageHash));
        expect(recreated.useCount, equals(original.useCount));
        expect(recreated.imageSize, equals(original.imageSize));
        expect(recreated.timestamp, equals(original.timestamp));
        expect(recreated.lastAccessed, equals(original.lastAccessed));
        expect(recreated.classification.itemName, equals(original.classification.itemName));
        expect(recreated.classification.category, equals(original.classification.category));
      });

      test('should serialize to string and deserialize correctly', () {
        const imageHash = 'test_hash_string_serialize';
        
        final original = CachedClassification(
          imageHash: imageHash,
          classification: mockClassification,
          timestamp: testTimestamp,
          useCount: 2,
        );

        // Test string serialization
        final serialized = original.serialize();
        expect(serialized, isA<String>());
        expect(serialized.isNotEmpty, isTrue);

        // Test string deserialization
        final recreated = CachedClassification.deserialize(serialized);
        expect(recreated.imageHash, equals(original.imageHash));
        expect(recreated.useCount, equals(original.useCount));
        expect(recreated.timestamp, equals(original.timestamp));
        expect(recreated.classification.itemName, equals(original.classification.itemName));
      });

      test('should handle null fields in serialization', () {
        const imageHash = 'test_hash_null_fields';
        
        final cached = CachedClassification(
          imageHash: imageHash,
          classification: mockClassification,
          timestamp: testTimestamp,
        );

        final json = cached.toJson();
        expect(json['imageSize'], isNull);

        final recreated = CachedClassification.fromJson(json);
        expect(recreated.imageSize, isNull);
      });
    });

    group('Cache Expiration and Management Tests', () {
      test('should track age of cache entry correctly', () {
        const imageHash = 'test_hash_age';
        final oldTimestamp = DateTime.now().subtract(const Duration(days: 5));
        
        final cached = CachedClassification(
          imageHash: imageHash,
          classification: mockClassification,
          timestamp: oldTimestamp,
        );

        final age = DateTime.now().difference(cached.timestamp);
        expect(age.inDays, equals(5));
      });

      test('should handle last accessed time for LRU eviction', () {
        const imageHash = 'test_hash_lru';
        final recentlyAccessed = DateTime.now().subtract(const Duration(minutes: 5));
        final longerAgo = DateTime.now().subtract(const Duration(hours: 2));
        
        final cached1 = CachedClassification(
          imageHash: '${imageHash}_1',
          classification: mockClassification,
          lastAccessed: recentlyAccessed,
        );

        final cached2 = CachedClassification(
          imageHash: '${imageHash}_2',
          classification: mockClassification,
          lastAccessed: longerAgo,
        );

        // cached2 should be evicted first (older lastAccessed)
        expect(cached2.lastAccessed.isBefore(cached1.lastAccessed), isTrue);
      });

      test('should handle image size for cache size management', () {
        const imageHash = 'test_hash_size';
        const smallImageSize = 100 * 1024; // 100KB
        const largeImageSize = 5 * 1024 * 1024; // 5MB
        
        final smallCached = CachedClassification(
          imageHash: '${imageHash}_small',
          classification: mockClassification,
          imageSize: smallImageSize,
        );

        final largeCached = CachedClassification(
          imageHash: '${imageHash}_large',
          classification: mockClassification,
          imageSize: largeImageSize,
        );

        expect(smallCached.imageSize, equals(smallImageSize));
        expect(largeCached.imageSize, equals(largeImageSize));
        expect(largeCached.imageSize! > smallCached.imageSize!, isTrue);
      });
    });

    group('Edge Cases and Validation Tests', () {
      test('should handle empty image hash', () {
        final cached = CachedClassification(
          imageHash: '',
          classification: mockClassification,
        );

        expect(cached.imageHash, equals(''));
        expect(cached.classification, isNotNull);
      });

      test('should handle very long image hash', () {
        final longHash = 'a' * 1000;
        final cached = CachedClassification(
          imageHash: longHash,
          classification: mockClassification,
        );

        expect(cached.imageHash, equals(longHash));
        expect(cached.imageHash.length, equals(1000));
      });

      test('should handle zero and negative use counts', () {
        final cached = CachedClassification(
          imageHash: 'test_hash_zero_count',
          classification: mockClassification,
          useCount: 0,
        );

        expect(cached.useCount, equals(0));

        cached.markUsed();
        expect(cached.useCount, equals(1));
      });

      test('should handle very large image sizes', () {
        const imageHash = 'test_hash_large_size';
        const veryLargeSize = 100 * 1024 * 1024; // 100MB
        
        final cached = CachedClassification(
          imageHash: imageHash,
          classification: mockClassification,
          imageSize: veryLargeSize,
        );

        expect(cached.imageSize, equals(veryLargeSize));
      });

      test('should handle extreme timestamps', () {
        const imageHash = 'test_hash_extreme_time';
        final futureDate = DateTime(2030, 12, 31);
        final pastDate = DateTime(1990);
        
        final futureCached = CachedClassification(
          imageHash: '${imageHash}_future',
          classification: mockClassification,
          timestamp: futureDate,
        );

        final pastCached = CachedClassification(
          imageHash: '${imageHash}_past',
          classification: mockClassification,
          timestamp: pastDate,
        );

        expect(futureCached.timestamp, equals(futureDate));
        expect(pastCached.timestamp, equals(pastDate));
      });
    });

    group('Classification Integration Tests', () {
      test('should preserve all classification data accurately', () {
        const imageHash = 'test_hash_classification_data';
        
        final cached = CachedClassification(
          imageHash: imageHash,
          classification: mockClassification,
        );

        // Verify classification data is preserved exactly
        expect(cached.classification.itemName, equals(mockClassification.itemName));
        expect(cached.classification.category, equals(mockClassification.category));
        expect(cached.classification.subcategory, equals(mockClassification.subcategory));
        expect(cached.classification.confidence, equals(mockClassification.confidence));
        expect(cached.classification.visualFeatures, equals(mockClassification.visualFeatures));
        expect(cached.classification.disposalInstructions.primaryMethod, 
               equals(mockClassification.disposalInstructions.primaryMethod));
        expect(cached.classification.disposalInstructions.steps, 
               equals(mockClassification.disposalInstructions.steps));
      });

      test('should handle classification with all optional fields', () {
        final fullClassification = WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
          itemName: 'Complex Item',
          subcategory: 'Chemical',
          explanation: 'Complex hazardous chemical requiring special handling',
            primaryMethod: 'Special facility disposal',
            steps: ['Contact facility', 'Use protective equipment', 'Transport safely'],
            hasUrgentTimeframe: true,
            timeframe: 'Within 24 hours',
            warnings: ['Toxic', 'Corrosive'],
            tips: ['Use gloves', 'Ventilate area'],
            recyclingInfo: 'Cannot be recycled',
            location: 'Hazardous waste center',
            estimatedTime: '2 hours',
          ),
          timestamp: testTimestamp,
          region: 'Test Region',
          visualFeatures: ['chemical', 'container', 'warning'],
          alternatives: [
            AlternativeClassification(
              category: 'Non-Waste',
              subcategory: 'Professional disposal',
              confidence: 0.2,
              reason: 'Requires professional handling',
            ),
          ],
          confidence: 0.95,
          isRecyclable: false,
          isCompostable: false,
          requiresSpecialDisposal: true,
          materialType: 'Chemical compound',
          colorCode: '#RED',
          brand: 'ChemCorp',
          product: 'Industrial Cleaner',
          userId: 'test_user_456',
          isSaved: true,
          clarificationNeeded: false,
        );

        final cached = CachedClassification(
          imageHash: 'test_hash_full_classification',
          classification: fullClassification,
        );

        // Verify all fields are preserved
        expect(cached.classification.requiresSpecialDisposal, isTrue);
        expect(cached.classification.disposalInstructions.hasUrgentTimeframe, isTrue);
        expect(cached.classification.disposalInstructions.timeframe, equals('Within 24 hours'));
        expect(cached.classification.disposalInstructions.warnings?.length, equals(2));
        expect(cached.classification.disposalInstructions.tips?.length, equals(2));
        expect(cached.classification.alternatives.length, equals(1));
        expect(cached.classification.brand, equals('ChemCorp'));
        expect(cached.classification.userId, equals('test_user_456'));
      });
    });
  });
}
