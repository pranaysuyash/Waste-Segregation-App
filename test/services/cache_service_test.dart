
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/services/cache_service.dart';

class MockBox extends Mock implements Box<String> {}

void main() {
  late ClassificationCacheService cacheService;
  late Box<String> mockCacheBox;
  
  setUpAll(() async {
    // Initialize Hive for testing
    TestWidgetsFlutterBinding.ensureInitialized();
    // Use in-memory path for testing
    Hive.init('./test/hive_test');
  });
  
  setUp(() async {
    // Open a new box for each test
    mockCacheBox = await Hive.openBox<String>('test_cache_box');
    
    // Create cache service with test configuration
    cacheService = ClassificationCacheService(maxCacheSize: 10);
    // Replace the cache box with our test box
    // This requires modifying the service to expose the box for testing
    await cacheService.initialize();
  });
  
  tearDown(() async {
    // Clear the box after each test
    await mockCacheBox.clear();
    await mockCacheBox.close();
  });
  
  group('ClassificationCacheService', () {
    test('should initialize correctly', () async {
      expect(cacheService.getCacheStatistics()['size'], 0);
      expect(cacheService.getCacheStatistics()['hits'], 0);
      expect(cacheService.getCacheStatistics()['misses'], 0);
    });
    
    test('should return null for cache miss', () async {
      final result = await cacheService.getCachedClassification('nonexistent_hash');
      expect(result, isNull);
      expect(cacheService.getCacheStatistics()['misses'], 1);
    });
    
    test('should cache and retrieve a classification', () async {
      // Create test classification
      final testClassification = WasteClassification(
        itemName: 'Test Item',
        category: 'Dry Waste',
        explanation: 'Test explanation',
      );
      
      // Cache the classification
      await cacheService.cacheClassification(
        'test_hash',
        testClassification,
        imageSize: 1024,
      );
      
      // Verify it's cached correctly
      expect(cacheService.getCacheStatistics()['size'], 1);
      
      // Retrieve from cache
      final cachedResult = await cacheService.getCachedClassification('test_hash');
      
      // Verify the retrieved result
      expect(cachedResult, isNotNull);
      expect(cachedResult!.imageHash, 'test_hash');
      expect(cachedResult.classification.itemName, 'Test Item');
      expect(cachedResult.classification.category, 'Dry Waste');
      expect(cachedResult.useCount, 2); // Initial count (1) + retrieval increment (1)
      expect(cacheService.getCacheStatistics()['hits'], 1);
    });
    
    test('should respect max cache size and evict oldest items', () async {
      // Create test classification
      final testClassification = WasteClassification(
        itemName: 'Test Item',
        category: 'Dry Waste',
        explanation: 'Test explanation',
      );
      
      // Cache multiple items beyond max size
      for (int i = 0; i < 15; i++) {
        await cacheService.cacheClassification(
          'test_hash_$i',
          testClassification,
        );
      }
      
      // Verify cache size is maintained
      expect(cacheService.getCacheStatistics()['size'], lessThanOrEqualTo(10));
      
      // Verify oldest items were evicted (first few hashes should be gone)
      final firstResult = await cacheService.getCachedClassification('test_hash_0');
      expect(firstResult, isNull);
      
      // But newer items should be present
      final lastResult = await cacheService.getCachedClassification('test_hash_14');
      expect(lastResult, isNotNull);
    });
    
    test('should update access count and time on cache hit', () async {
      // Create test classification
      final testClassification = WasteClassification(
        itemName: 'Test Item',
        category: 'Dry Waste',
        explanation: 'Test explanation',
      );
      
      // Cache the classification
      await cacheService.cacheClassification('test_hash', testClassification);
      
      // Retrieve twice
      final firstRetrieval = await cacheService.getCachedClassification('test_hash');
      final firstAccessTime = firstRetrieval!.lastAccessed;
      final firstUseCount = firstRetrieval.useCount;
      
      // Add a small delay
      await Future.delayed(const Duration(milliseconds: 10));
      
      // Retrieve again
      final secondRetrieval = await cacheService.getCachedClassification('test_hash');
      
      // Verify count incremented and time updated
      expect(secondRetrieval!.useCount, firstUseCount + 1);
      expect(
        secondRetrieval.lastAccessed.isAfter(firstAccessTime), 
        isTrue,
        reason: 'Last accessed time should be updated on cache hit',
      );
    });
    
    test('should clear cache correctly', () async {
      // Create test classification
      final testClassification = WasteClassification(
        itemName: 'Test Item',
        category: 'Dry Waste',
        explanation: 'Test explanation',
      );
      
      // Cache a few items
      for (int i = 0; i < 5; i++) {
        await cacheService.cacheClassification(
          'test_hash_$i',
          testClassification,
        );
      }
      
      // Verify items are cached
      expect(cacheService.getCacheStatistics()['size'], 5);
      
      // Clear cache
      await cacheService.clearCache();
      
      // Verify cache is empty
      expect(cacheService.getCacheStatistics()['size'], 0);
      expect(cacheService.getCacheStatistics()['hits'], 0);
      expect(cacheService.getCacheStatistics()['misses'], 0);
      
      // Try to retrieve an item
      final result = await cacheService.getCachedClassification('test_hash_0');
      expect(result, isNull);
    });
  });
  
  group('Hash comparison functionality', () {
    // Skip image generation tests since we can't easily create valid test images
    // Instead, test directly with generated perceptual hash values
    
    test('should find similar hashes in cache with threshold of 10', () async {
      // Create test classification
      final testClassification = WasteClassification(
        itemName: 'Test Item',
        category: 'Dry Waste',
        explanation: 'Test explanation',
      );
      
      // Create a mock perceptual hash directly (instead of trying to generate from fake images)
      final String baseHash = 'phash_1a2b3c4d5e6f7890';
      
      // Cache the classification with this hash
      await cacheService.cacheClassification(
        baseHash,
        testClassification,
      );
      
      // Create a slightly modified version of the hash (simulate slight image differences)
      String modifiedHash = 'phash_';
      final baseHex = baseHash.substring(6);
      
      // Modify a few bits to create a hash with hamming distance of ~8
      for (int i = 0; i < baseHex.length; i++) {
        if (i == 3 || i == 7 || i == 11) {
          // Flip a few bits in these hex digits
          int value = int.parse(baseHex[i], radix: 16);
          value = (value + 8) % 16; // Modify by 8 to ensure some bit changes
          modifiedHash += value.toRadixString(16);
        } else {
          modifiedHash += baseHex[i];
        }
      }
      
      // Verify the hashes are different
      expect(baseHash, isNot(equals(modifiedHash)));
      
      // Calculate the actual hamming distance to verify our test setup
      // Convert to binary
      String hexToBinary(String hex) {
        String binary = '';
        for (int i = 0; i < hex.length; i++) {
          final int value = int.parse(hex[i], radix: 16);
          String binDigit = value.toRadixString(2).padLeft(4, '0');
          binary += binDigit;
        }
        return binary;
      }
      
      // Calculate hamming distance
      int hammingDistance(String a, String b) {
        if (a.length != b.length) {
          throw ArgumentError('Strings must be of equal length');
        }
        int distance = 0;
        for (int i = 0; i < a.length; i++) {
          if (a[i] != b[i]) distance++;
        }
        return distance;
      }
      
      final baseBinary = hexToBinary(baseHash.substring(6));
      final modifiedBinary = hexToBinary(modifiedHash.substring(6));
      final distance = hammingDistance(baseBinary, modifiedBinary);
      
      print('Hamming distance between test hashes: $distance');
      
      // Try to retrieve with the modified hash
      final cachedResult = await cacheService.getCachedClassification(
        modifiedHash,
        similarityThreshold: 10
      );
      
      // Should find a match with the new threshold
      expect(cachedResult, isNotNull, 
        reason: 'Similar hash should be found with threshold 10');
      
      if (cachedResult != null) {
        expect(cachedResult.classification.itemName, equals('Test Item'));
      }
    });
    
    test('should fail to find match with threshold that is too strict', () async {
      // Create test classification
      final testClassification = WasteClassification(
        itemName: 'Another Test Item',
        category: 'Wet Waste', 
        explanation: 'Test explanation',
      );
      
      // Create a mock perceptual hash directly
      final String baseHash = 'phash_abcdef0123456789';
      
      // Cache the classification with this hash
      await cacheService.cacheClassification(
        baseHash,
        testClassification,
      );
      
      // Create a hash with larger distance (simulate more different image)
      String modifiedHash = 'phash_';
      final baseHex = baseHash.substring(6);
      
      // Modify many bits to create a hash with hamming distance > 10
      for (int i = 0; i < baseHex.length; i++) {
        if (i % 2 == 0) { // Modify every other character
          int value = int.parse(baseHex[i], radix: 16);
          value = (value + 8) % 16; // Significant change
          modifiedHash += value.toRadixString(16);
        } else {
          modifiedHash += baseHex[i];
        }
      }
      
      // Try to retrieve with a strict threshold
      final cachedResult = await cacheService.getCachedClassification(
        modifiedHash,
        similarityThreshold: 5 // Too strict
      );
      
      // Should NOT find a match with a strict threshold
      expect(cachedResult, isNull, 
        reason: 'Similar hash should NOT be found with strict threshold of 5');
    });
  });
}

// Simple mock implementation for tests
class Mock {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}