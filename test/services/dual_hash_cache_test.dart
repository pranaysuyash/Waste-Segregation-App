import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:waste_segregation_app/services/cache_service.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/models/cached_classification.dart';

// Helper function to create test classifications
WasteClassification _createTestClassification(String itemName) {
  return WasteClassification(
    id: 'test-${DateTime.now().millisecondsSinceEpoch}',
    itemName: itemName,
    category: 'Dry Waste',
    subcategory: 'Plastic',
    explanation: 'Test item: $itemName',
    disposalInstructions: DisposalInstructions(
      primaryMethod: 'Test disposal',
      steps: ['Test step'],
      hasUrgentTimeframe: false,
    ),
    timestamp: DateTime.now(),
    region: 'Test Region',
    visualFeatures: ['test', 'item'],
    alternatives: [],
    confidence: 0.85,
  );
}

void main() {
  setUpAll(() async {
    // Initialize Hive for testing with temporary directory
    final tempDir = await Directory.systemTemp.createTemp('hive_test');
    Hive.init(tempDir.path);

    // Register adapters if not already registered
    try {
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(CachedClassificationAdapter());
      }
    } catch (e) {
      // Adapter already registered, ignore
    }

    try {
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(WasteClassificationAdapter());
      }
    } catch (e) {
      // Adapter already registered, ignore
    }

    try {
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(DisposalInstructionsAdapter());
      }
    } catch (e) {
      // Adapter already registered, ignore
    }
  });

  tearDownAll(() async {
    // Clean up Hive
    await Hive.close();
  });

  group('Dual-Hash Cache System', () {
    late ClassificationCacheService cacheService;

    setUp(() async {
      // Reset feature flags to default state
      CacheFeatureFlags.setContentHashVerification(true);

      cacheService = ClassificationCacheService();
      await cacheService.initialize();
    });

    tearDown(() async {
      // Clean up after each test
      await cacheService.clearCache();

      // Reset feature flags to default state
      CacheFeatureFlags.setContentHashVerification(true);
    });

    test('should handle legacy cache entries without contentHash gracefully', () async {
      // Create a legacy cache entry without contentHash (simulating old data)
      final legacyClassification = WasteClassification(
        id: 'test-legacy-id',
        itemName: 'Legacy Item',
        category: 'Dry Waste',
        subcategory: 'Plastic',
        explanation: 'Legacy test item',
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Recycle',
          steps: ['Clean', 'Recycle'],
          hasUrgentTimeframe: false,
        ),
        timestamp: DateTime.now(),
        region: 'Test Region',
        visualFeatures: ['plastic'],
        alternatives: [],
        confidence: 0.9,
      );

      final legacyEntry = CachedClassification(
        imageHash: 'phash_123456789abcdef0',
        classification: legacyClassification,
        // Note: No contentHash provided (simulating legacy data)
      );

      // Manually store legacy entry
      final box = cacheService.cacheBox;
      await box.put('phash_123456789abcdef0', legacyEntry.serialize());

      // Test 1: Exact match should work for legacy entries
      final exactMatch = await cacheService.getCachedClassification('phash_123456789abcdef0');
      expect(exactMatch, isNotNull);
      expect(exactMatch!.classification.itemName, equals('Legacy Item'));

      // Test 2: Similarity search without contentHash should be skipped for safety
      final similarityResult = await cacheService.getCachedClassification(
        'phash_123456789abcdef1', // Similar but different hash (16 chars after prefix)
        contentHash: 'md5_newcontenthashdifferent',
      );
      expect(similarityResult, isNull); // Should not match due to missing contentHash in legacy entry
    });

    test('should prevent false positives when legacy entries lack contentHash', () async {
      // Create two different images with similar perceptual hashes
      final classification1 = _createTestClassification('Red Pen');

      // Store first item as legacy (no contentHash)
      final legacyEntry = CachedClassification(
        imageHash: 'phash_000000010f3f7f3f',
        classification: classification1,
        // No contentHash - simulating legacy data
      );

      final box = cacheService.cacheBox;
      await box.put('phash_000000010f3f7f3f', legacyEntry.serialize());

      // Try to find similar item with contentHash verification
      final result = await cacheService.getCachedClassification(
        'phash_800103032f7f3f0f', // Similar hash (distance = 10)
        contentHash: 'md5_differentcontenthashdifferent',
      );

      // Should return null because legacy entry lacks contentHash for verification
      expect(result, isNull);
    });

    test('should work correctly with new dual-hash entries', () async {
      final classification = _createTestClassification('New Item');

      // Store with both hashes (new system)
      await cacheService.cacheClassification(
        'phash_123456789abcdef0',
        classification,
        contentHash: 'md5_newitemcontenthashabc123',
        imageSize: 1024,
      );

      // Test exact match
      final exactMatch = await cacheService.getCachedClassification('phash_123456789abcdef0');
      expect(exactMatch, isNotNull);
      expect(exactMatch!.classification.itemName, equals('New Item'));

      // Test similarity match with correct contentHash
      final similarMatch = await cacheService.getCachedClassification(
        'phash_123456789abcdef1', // 1 bit different (last char 0->1)
        contentHash: 'md5_newitemcontenthashabc123', // Same content hash
      );
      expect(similarMatch, isNotNull);
      expect(similarMatch!.classification.itemName, equals('New Item'));

      // Test similarity match with wrong contentHash (should fail verification)
      final wrongContentMatch = await cacheService.getCachedClassification(
        'phash_123456789abcdef1', // 1 bit different (last char 0->1)
        contentHash: 'md5_differentcontenthashdiff', // Different content hash
      );
      expect(wrongContentMatch, isNull);
    });

    test('should respect feature flag kill-switch', () async {
      final classification = _createTestClassification('Kill Switch Test');

      // Store with both hashes
      await cacheService.cacheClassification(
        'phash_123456789abcdef4',
        classification,
        contentHash: 'md5_killswitchcontenthashabc',
      );

      // Disable content hash verification
      CacheFeatureFlags.setContentHashVerification(false);

      // Should still work with basic perceptual matching (fallback mode)
      final result = await cacheService.getCachedClassification(
        'phash_123456789abcdef5', // 1 bit different (last char 4->5)
      );
      expect(result, isNotNull);
      expect(result!.classification.itemName, equals('Kill Switch Test'));

      // Re-enable for other tests
      CacheFeatureFlags.setContentHashVerification(true);
    });

    test('should maintain cache statistics correctly', () async {
      final classification = _createTestClassification('Stats Test Item');

      // Cache with dual-hash
      await cacheService.cacheClassification(
        'phash_123456789abcdef6',
        classification,
        contentHash: 'md5_statstestcontenthashabc',
      );

      // Test cache hit
      final hit = await cacheService.getCachedClassification(
        'phash_123456789abcdef6',
        contentHash: 'md5_statstestcontenthashabc',
      );
      expect(hit, isNotNull);

      // Test cache miss
      final miss = await cacheService.getCachedClassification(
        'phash_123456789abcdef7', // 16 chars
        contentHash: 'md5_nonexistentcontenthashabc',
      );
      expect(miss, isNull);

      final stats = cacheService.getCacheStatistics();
      expect(stats['hits'], greaterThan(0));
      expect(stats['misses'], greaterThan(0));
    });

    test('should handle corrupted legacy cache entries gracefully', () async {
      final box = cacheService.cacheBox;

      // Store corrupted JSON
      await box.put('phash_123456789abcdef8', '{"invalid": json}');

      // Should not crash and return null
      final result = await cacheService.getCachedClassification('phash_123456789abcdef8');
      expect(result, isNull);
    });
  });
}
