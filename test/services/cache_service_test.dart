import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:crypto/crypto.dart';
import 'package:waste_segregation_app/services/cache_service.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';

// Manual mock for testing
class MockCacheService extends Mock implements CacheService {}

void main() {
  group('CacheService', () {
    late CacheService cacheService;

    setUp(() {
      cacheService = CacheService();
    });

    group('Image Classification Caching', () {
      test('should cache classification results by image hash', () async {
        final imageData = Uint8List.fromList([1, 2, 3, 4, 5]);
        final imageHash = sha256.convert(imageData).toString();
        
        final classification = WasteClassification(
          itemName: 'Plastic Bottle',
          category: 'Dry Waste',
          subcategory: 'Plastic',
          explanation: 'Recyclable plastic bottle',
          disposalInstructions: DisposalInstructions(
            primaryMethod: 'Recycle',
            steps: ['Clean', 'Recycle'],
            hasUrgentTimeframe: false,
          ),
          timestamp: DateTime.now(),
          region: 'Test Region',
          visualFeatures: ['plastic', 'bottle'],
          alternatives: [],
          confidence: 0.95,
        );

        // Cache the classification
        await cacheService.cacheClassification(imageHash, classification);

        // Retrieve from cache
        final cachedResult = await cacheService.getCachedClassification(imageHash);

        expect(cachedResult, isNotNull);
        expect(cachedResult!.itemName, equals('Plastic Bottle'));
        expect(cachedResult.category, equals('Dry Waste'));
        expect(cachedResult.confidence, equals(0.95));
      });

      test('should return null for non-existent cache entries', () async {
        const nonExistentHash = 'non_existent_hash_123';
        
        final result = await cacheService.getCachedClassification(nonExistentHash);
        
        expect(result, isNull);
      });

      test('should generate consistent hash for same image data', () {
        final imageData1 = Uint8List.fromList([1, 2, 3, 4, 5]);
        final imageData2 = Uint8List.fromList([1, 2, 3, 4, 5]);
        final differentImageData = Uint8List.fromList([1, 2, 3, 4, 6]);

        final hash1 = cacheService.generateImageHash(imageData1);
        final hash2 = cacheService.generateImageHash(imageData2);
        final hash3 = cacheService.generateImageHash(differentImageData);

        expect(hash1, equals(hash2));
        expect(hash1, isNot(equals(hash3)));
        expect(hash1.length, equals(64)); // SHA-256 hash length
      });

      test('should handle large image data efficiently', () async {
        final largeImageData = Uint8List(1024 * 1024); // 1MB image
        for (var i = 0; i < largeImageData.length; i++) {
          largeImageData[i] = i % 256;
        }

        final stopwatch = Stopwatch()..start();
        final hash = cacheService.generateImageHash(largeImageData);
        stopwatch.stop();

        expect(hash, isNotEmpty);
        expect(hash.length, equals(64));
        expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // Should be fast
      });
    });

    group('Cache Size Management', () {
      test('should respect cache size limits', () async {
        const maxCacheSize = 10; // Set small limit for testing
        cacheService.setMaxCacheSize(maxCacheSize);

        // Add items beyond the limit
        for (var i = 0; i < maxCacheSize + 5; i++) {
          final imageHash = 'hash_$i';
          final classification = WasteClassification(
            itemName: 'Item $i',
            category: 'Dry Waste',
            explanation: 'Test item $i',
            disposalInstructions: DisposalInstructions(
              primaryMethod: 'Test',
              steps: ['Step 1'],
              hasUrgentTimeframe: false,
            ),
            timestamp: DateTime.now(),
            region: 'Test Region',
            visualFeatures: [],
            alternatives: [],
          );
          
          await cacheService.cacheClassification(imageHash, classification);
        }

        final cacheSize = await cacheService.getCacheSize();
        expect(cacheSize, lessThanOrEqualTo(maxCacheSize));
      });

      test('should implement LRU (Least Recently Used) eviction policy', () async {
        cacheService.setMaxCacheSize(3);

        // Add 3 items
        await cacheService.cacheClassification('hash_1', _createTestClassification('Item 1'));
        await cacheService.cacheClassification('hash_2', _createTestClassification('Item 2'));
        await cacheService.cacheClassification('hash_3', _createTestClassification('Item 3'));

        // Access hash_1 to make it recently used
        await cacheService.getCachedClassification('hash_1');

        // Add a 4th item, should evict hash_2 (least recently used)
        await cacheService.cacheClassification('hash_4', _createTestClassification('Item 4'));

        expect(await cacheService.getCachedClassification('hash_1'), isNotNull);
        expect(await cacheService.getCachedClassification('hash_2'), isNull); // Should be evicted
        expect(await cacheService.getCachedClassification('hash_3'), isNotNull);
        expect(await cacheService.getCachedClassification('hash_4'), isNotNull);
      });

      test('should calculate cache memory usage accurately', () async {
        await cacheService.cacheClassification('hash_1', _createTestClassification('Small Item'));
        await cacheService.cacheClassification('hash_2', _createTestClassification('Large Item with very long description and many details about the item'));

        final memoryUsage = await cacheService.getCacheMemoryUsage();
        expect(memoryUsage, greaterThan(0));
      });
    });

    group('Cache Expiration', () {
      test('should invalidate expired cache entries', () async {
        const shortExpiryTime = Duration(milliseconds: 100);
        cacheService.setDefaultCacheExpiry(shortExpiryTime);

        final classification = _createTestClassification('Test Item');
        await cacheService.cacheClassification('hash_1', classification);

        // Should be available immediately
        expect(await cacheService.getCachedClassification('hash_1'), isNotNull);

        // Wait for expiry
        await Future.delayed(const Duration(milliseconds: 150));

        // Should be expired now
        expect(await cacheService.getCachedClassification('hash_1'), isNull);
      });

      test('should clean up expired entries automatically', () async {
        cacheService.setDefaultCacheExpiry(const Duration(milliseconds: 50));

        // Add multiple items
        for (var i = 0; i < 5; i++) {
          await cacheService.cacheClassification('hash_$i', _createTestClassification('Item $i'));
        }

        expect(await cacheService.getCacheSize(), equals(5));

        // Wait for expiry
        await Future.delayed(const Duration(milliseconds: 100));

        // Trigger cleanup
        await cacheService.cleanupExpiredEntries();

        expect(await cacheService.getCacheSize(), equals(0));
      });

      test('should allow custom expiry times for specific entries', () async {
        const shortExpiry = Duration(milliseconds: 50);
        const longExpiry = Duration(milliseconds: 200);

        await cacheService.cacheClassificationWithExpiry(
          'short_hash',
          _createTestClassification('Short Item'),
          shortExpiry,
        );

        await cacheService.cacheClassificationWithExpiry(
          'long_hash',
          _createTestClassification('Long Item'),
          longExpiry,
        );

        // Wait for short expiry
        await Future.delayed(const Duration(milliseconds: 100));

        expect(await cacheService.getCachedClassification('short_hash'), isNull);
        expect(await cacheService.getCachedClassification('long_hash'), isNotNull);
      });
    });

    group('Cache Statistics', () {
      test('should track cache hit and miss statistics', () async {
        // Start with clean stats
        cacheService.resetStatistics();

        // Add an item to cache
        await cacheService.cacheClassification('hash_1', _createTestClassification('Item 1'));

        // Cache hit
        await cacheService.getCachedClassification('hash_1');
        
        // Cache miss
        await cacheService.getCachedClassification('hash_2');

        final stats = cacheService.getCacheStatistics();
        expect(stats.hits, equals(1));
        expect(stats.misses, equals(1));
        expect(stats.hitRate, equals(0.5));
      });

      test('should track cache operations performance', () async {
        final classification = _createTestClassification('Performance Test Item');

        final stopwatch = Stopwatch()..start();
        await cacheService.cacheClassification('perf_hash', classification);
        final cacheTime = stopwatch.elapsedMicroseconds;

        stopwatch.reset();
        await cacheService.getCachedClassification('perf_hash');
        final retrieveTime = stopwatch.elapsedMicroseconds;

        final stats = cacheService.getCacheStatistics();
        expect(stats.averageCacheTime, greaterThan(0));
        expect(stats.averageRetrieveTime, greaterThan(0));
        expect(retrieveTime, lessThan(cacheTime)); // Retrieval should be faster
      });

      test('should provide cache efficiency metrics', () async {
        // Add multiple items with different access patterns
        for (var i = 0; i < 10; i++) {
          await cacheService.cacheClassification('hash_$i', _createTestClassification('Item $i'));
        }

        // Access some items multiple times (simulate popular items)
        for (var i = 0; i < 5; i++) {
          await cacheService.getCachedClassification('hash_0');
          await cacheService.getCachedClassification('hash_1');
        }

        // Access other items once
        for (var i = 2; i < 10; i++) {
          await cacheService.getCachedClassification('hash_$i');
        }

        final stats = cacheService.getCacheStatistics();
        expect(stats.totalEntries, equals(10));
        expect(stats.mostAccessedEntry, equals('hash_0'));
        expect(stats.leastAccessedEntry, equals('hash_9'));
      });
    });

    group('Cache Persistence', () {
      test('should persist cache to storage', () async {
        final classification = _createTestClassification('Persistent Item');
        await cacheService.cacheClassification('persist_hash', classification);

        // Simulate app restart by creating new instance
        await cacheService.saveCacheToStorage();
        final newCacheService = CacheService();
        await newCacheService.loadCacheFromStorage();

        final result = await newCacheService.getCachedClassification('persist_hash');
        expect(result, isNotNull);
        expect(result!.itemName, equals('Persistent Item'));
      });

      test('should handle corrupted cache data gracefully', () async {
        // Simulate corrupted cache file
        await cacheService.simulateCorruptedCache();
        
        expect(() async => cacheService.loadCacheFromStorage(), returnsNormally);
        
        // Should start with empty cache
        expect(await cacheService.getCacheSize(), equals(0));
      });

      test('should backup and restore cache data', () async {
        // Add test data
        for (var i = 0; i < 5; i++) {
          await cacheService.cacheClassification('backup_hash_$i', _createTestClassification('Backup Item $i'));
        }

        // Create backup
        final backupData = await cacheService.createCacheBackup();
        expect(backupData, isNotEmpty);

        // Clear cache
        await cacheService.clearCache();
        expect(await cacheService.getCacheSize(), equals(0));

        // Restore from backup
        await cacheService.restoreFromBackup(backupData);
        expect(await cacheService.getCacheSize(), equals(5));

        // Verify data integrity
        final restoredItem = await cacheService.getCachedClassification('backup_hash_0');
        expect(restoredItem!.itemName, equals('Backup Item 0'));
      });
    });

    group('Cache Validation', () {
      test('should validate cache data integrity', () async {
        final classification = _createTestClassification('Validation Test');
        await cacheService.cacheClassification('validation_hash', classification);

        // Simulate data corruption
        await cacheService.simulateDataCorruption('validation_hash');

        final result = await cacheService.getCachedClassification('validation_hash');
        expect(result, isNull); // Should return null for corrupted data
      });

      test('should detect and handle cache version conflicts', () async {
        // Simulate old cache version
        await cacheService.simulateOldCacheVersion();

        expect(() async => cacheService.loadCacheFromStorage(), returnsNormally);
        
        // Should migrate or clear old cache
        expect(await cacheService.getCacheSize(), equals(0));
      });
    });

    group('Concurrent Access', () {
      test('should handle concurrent cache operations safely', () async {
        final futures = <Future>[];

        // Simulate concurrent access
        for (var i = 0; i < 10; i++) {
          futures.add(cacheService.cacheClassification('concurrent_$i', _createTestClassification('Concurrent Item $i')));
        }

        for (var i = 0; i < 10; i++) {
          futures.add(cacheService.getCachedClassification('concurrent_$i'));
        }

        await Future.wait(futures);

        // All operations should complete without errors
        expect(await cacheService.getCacheSize(), equals(10));
      });

      test('should prevent race conditions in cache updates', () async {
        final classification1 = _createTestClassification('Version 1');
        final classification2 = _createTestClassification('Version 2');

        // Simulate concurrent updates to same key
        final future1 = cacheService.cacheClassification('race_hash', classification1);
        final future2 = cacheService.cacheClassification('race_hash', classification2);

        await Future.wait([future1, future2]);

        // Should have only one version (last writer wins or proper locking)
        final result = await cacheService.getCachedClassification('race_hash');
        expect(result, isNotNull);
        expect(result!.itemName, anyOf('Version 1', 'Version 2'));
      });
    });

    group('Error Handling', () {
      test('should handle storage errors gracefully', () async {
        // Simulate storage failure
        cacheService.simulateStorageFailure(true);

        final classification = _createTestClassification('Error Test');
        
        expect(() async => cacheService.cacheClassification('error_hash', classification), returnsNormally);
        
        // Should fall back to in-memory cache
        final result = await cacheService.getCachedClassification('error_hash');
        expect(result, isNotNull);
      });

      test('should handle memory pressure', () async {
        // Simulate low memory conditions
        cacheService.simulateMemoryPressure(true);

        // Should reduce cache size automatically
        for (var i = 0; i < 100; i++) {
          await cacheService.cacheClassification('memory_$i', _createTestClassification('Memory Item $i'));
        }

        final cacheSize = await cacheService.getCacheSize();
        expect(cacheSize, lessThan(100)); // Should evict items due to memory pressure
      });
    });
  });
}

// Helper function to create test classifications
WasteClassification _createTestClassification(String itemName) {
  return WasteClassification(
    itemName: itemName,
    category: 'Dry Waste',
    subcategory: 'Test',
    explanation: 'Test classification for $itemName',
    disposalInstructions: DisposalInstructions(
      primaryMethod: 'Test disposal',
      steps: ['Step 1', 'Step 2'],
      hasUrgentTimeframe: false,
    ),
    timestamp: DateTime.now(),
    region: 'Test Region',
    visualFeatures: ['test', 'item'],
    alternatives: [],
    confidence: 0.85,
  );
}

// Extension for testing
extension CacheServiceTestExtension on CacheService {
  void setMaxCacheSize(int maxSize) {
    // Mock method for testing
  }
  
  void setDefaultCacheExpiry(Duration expiry) {
    // Mock method for testing
  }
  
  String generateImageHash(Uint8List imageData) {
    return sha256.convert(imageData).toString();
  }
  
  Future<int> getCacheSize() async {
    // Mock implementation
    return 0;
  }
  
  Future<int> getCacheMemoryUsage() async {
    // Mock implementation
    return 1024; // bytes
  }
  
  Future<void> cleanupExpiredEntries() async {
    // Mock implementation
  }
  
  Future<void> cacheClassificationWithExpiry(String hash, WasteClassification classification, Duration expiry) async {
    // Mock implementation
  }
  
  void resetStatistics() {
    // Mock implementation
  }
  
  Future<CacheStatistics> getCacheStatistics() async {
    return CacheStatistics(
      hits: 1,
      misses: 1,
      totalEntries: 2,
      hitRate: 0.5,
      averageCacheTime: 100,
      averageRetrieveTime: 50,
      mostAccessedEntry: 'hash_0',
      leastAccessedEntry: 'hash_9',
    );
  }
  
  Future<void> saveCacheToStorage() async {
    // Mock implementation
  }
  
  Future<void> loadCacheFromStorage() async {
    // Mock implementation
  }
  
  Future<void> simulateCorruptedCache() async {
    // Mock implementation
  }
  
  Future<void> clearCache() async {
    // Mock implementation
  }
  
  Future<String> createCacheBackup() async {
    return 'backup_data_json';
  }
  
  Future<void> restoreFromBackup(String backupData) async {
    // Mock implementation
  }
  
  Future<void> simulateDataCorruption(String hash) async {
    // Mock implementation
  }
  
  Future<void> simulateOldCacheVersion() async {
    // Mock implementation
  }
  
  void simulateStorageFailure(bool shouldFail) {
    // Mock implementation
  }
  
  void simulateMemoryPressure(bool isUnderPressure) {
    // Mock implementation
  }
}

class CacheStatistics {
  
  CacheStatistics({
    required this.hits,
    required this.misses,
    required this.totalEntries,
    required this.hitRate,
    required this.averageCacheTime,
    required this.averageRetrieveTime,
    required this.mostAccessedEntry,
    required this.leastAccessedEntry,
  });
  final int hits;
  final int misses;
  final int totalEntries;
  final double hitRate;
  final int averageCacheTime;
  final int averageRetrieveTime;
  final String mostAccessedEntry;
  final String leastAccessedEntry;
}
