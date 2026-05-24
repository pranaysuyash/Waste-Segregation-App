import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:waste_segregation_app/models/cached_classification.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/services/cache_service.dart';
import 'package:waste_segregation_app/utils/constants.dart';

WasteClassification _classification({String itemName = 'Plastic Bottle'}) {
  return WasteClassification(
    itemName: itemName,
    category: 'Dry Waste',
    subCategory: 'Plastic',
    explanation: 'Test classification',
    disposalInstructions: DisposalInstructions(
      primaryMethod: 'Recycle',
      steps: const ['Rinse', 'Sort'],
      hasUrgentTimeframe: false,
    ),
    region: 'Test Region',
    visualFeatures: const ['plastic', 'bottle'],
    alternatives: [
      AlternativeClassification(
        category: 'Plastic',
        confidence: 0.2,
        reason: 'fallback',
      ),
    ],
    confidence: 0.95,
  );
}

void main() {
  setUpAll(() async {
    Hive.init('.');
  });

  tearDownAll(() async {
    // Shared Hive root left open intentionally for the rest of the suite.
  });

  group('CacheService', () {
    setUp(() async {
      final box = await Hive.openBox<String>(StorageKeys.cacheBox);
      await box.clear();
    });

    test('initializes and starts empty', () async {
      final service = CacheService(maxCacheSize: 10);

      await service.initialize();

      expect(service.getCacheStatistics()['size'], 0);
      expect(service.cacheBox.isOpen, isTrue);
    });

    test('stores and retrieves a cached classification', () async {
      final service = CacheService(maxCacheSize: 10);
      final classification = _classification();

      await service.cacheClassification(
        'phash-123',
        classification,
        contentHash: 'content-123',
        imageSize: 4096,
        entryImageHash: 'raw-phash-123',
      );

      final cached = await service.getCachedClassification(
        'phash-123',
        contentHash: 'content-123',
      );

      expect(cached, isNotNull);
      expect(cached!.imageHash, 'raw-phash-123');
      expect(cached.classification.itemName, classification.itemName);
      expect(cached.contentHash, 'content-123');
      expect(service.getCacheStatistics()['size'], 1);
    });

    test('clearCache resets entries and statistics', () async {
      final service = CacheService(maxCacheSize: 10);
      await service.cacheClassification('phash-clear', _classification());
      expect(service.getCacheStatistics()['size'], 1);

      await service.clearCache();

      expect(service.getCacheStatistics()['size'], 0);
      expect(await service.getCachedClassification('phash-clear'), isNull);
    });

    test('cleanupExpiredEntries removes stale and corrupted entries', () async {
      final box = await Hive.openBox<String>(StorageKeys.cacheBox);
      final now = DateTime.now();
      final oldEntry = CachedClassification(
        imageHash: 'old',
        classification: _classification(itemName: 'Old'),
        timestamp: now.subtract(const Duration(days: 40)),
        lastAccessed: now.subtract(const Duration(days: 40)),
      );
      final freshEntry = CachedClassification(
        imageHash: 'fresh',
        classification: _classification(itemName: 'Fresh'),
        timestamp: now,
        lastAccessed: now,
      );

      await box.put('old', oldEntry.serialize());
      await box.put('fresh', freshEntry.serialize());

      final service = CacheService(maxCacheSize: 10);
      await service.initialize();

      final removed = await service.cleanupExpiredEntries(
        maxAge: const Duration(days: 30),
      );

      expect(removed, 1);
      expect(box.containsKey('old'), isFalse);
      expect(box.containsKey('fresh'), isTrue);
    });

    test('evicts oldest entry when cache exceeds max size', () async {
      final service = CacheService(maxCacheSize: 1);

      await service.cacheClassification('first', _classification());
      await service.cacheClassification(
          'second', _classification(itemName: 'Second'));

      expect(service.getCacheStatistics()['size'], 1);
      expect(await service.getCachedClassification('first'), isNull);
      expect(await service.getCachedClassification('second'), isNotNull);
    });
  });
}
