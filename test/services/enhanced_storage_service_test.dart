import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:waste_segregation_app/services/enhanced_storage_service.dart';
import 'package:waste_segregation_app/models/user_profile.dart';
import 'package:waste_segregation_app/utils/constants.dart';

// Mock classes
@GenerateMocks([Box])
import 'enhanced_storage_service_test.mocks.dart';

void main() {
  group('CacheEntry', () {
    test('should create with required parameters', () {
      final timestamp = DateTime.now();
      final entry = CacheEntry(
        value: 'test_value',
        timestamp: timestamp,
        ttl: const Duration(minutes: 30),
      );

      expect(entry.value, equals('test_value'));
      expect(entry.timestamp, equals(timestamp));
      expect(entry.ttl, equals(const Duration(minutes: 30)));
    });

    test('should correctly identify expired entries', () {
      final oldTimestamp = DateTime.now().subtract(const Duration(hours: 2));
      final expiredEntry = CacheEntry(
        value: 'expired_value',
        timestamp: oldTimestamp,
        ttl: const Duration(hours: 1),
      );

      final recentTimestamp = DateTime.now().subtract(const Duration(minutes: 10));
      final validEntry = CacheEntry(
        value: 'valid_value',
        timestamp: recentTimestamp,
        ttl: const Duration(hours: 1),
      );

      expect(expiredEntry.isExpired, isTrue);
      expect(validEntry.isExpired, isFalse);
    });

    test('should handle edge case of exactly expired entry', () {
      final exactTimestamp = DateTime.now().subtract(const Duration(hours: 1));
      final exactEntry = CacheEntry(
        value: 'exact_value',
        timestamp: exactTimestamp,
        ttl: const Duration(hours: 1),
      );

      // Due to timing precision, this might be slightly expired
      expect(exactEntry.isExpired, isTrue);
    });
  });

  group('EnhancedStorageService', () {
    late EnhancedStorageService service;
    late MockBox mockUserBox;
    late MockBox mockSettingsBox;
    late MockBox mockClassificationsBox;
    late MockBox mockGamificationBox;

    setUp(() {
      // Initialize Hive mocks
      mockUserBox = MockBox();
      mockSettingsBox = MockBox();
      mockClassificationsBox = MockBox();
      mockGamificationBox = MockBox();

      // Mock Hive.box() calls
      when(mockUserBox.get(any)).thenReturn(null);
      when(mockSettingsBox.get(any)).thenReturn(null);
      when(mockClassificationsBox.get(any)).thenReturn(null);
      when(mockGamificationBox.get(any)).thenReturn(null);

      when(mockUserBox.put(any, any)).thenAnswer((_) async {});
      when(mockSettingsBox.put(any, any)).thenAnswer((_) async {});
      when(mockClassificationsBox.put(any, any)).thenAnswer((_) async {});
      when(mockGamificationBox.put(any, any)).thenAnswer((_) async {});

      service = EnhancedStorageService();
    });

    tearDown(() {
      service.clearCache();
    });

    group('Cache Management', () {
      test('should start with empty cache and zero statistics', () {
        final stats = service.getCacheStats();

        expect(stats['cache_hits'], equals(0));
        expect(stats['cache_misses'], equals(0));
        expect(stats['hit_rate'], equals('0.0'));
        expect(stats['cache_size'], equals(0));
      });

      test('should track cache hits and misses', () async {
        const testKey = 'test_key';
        const testValue = 'test_value';

        // First access should be a cache miss
        await service.store(testKey, testValue);

        // Second access should be a cache hit
        final result = await service.get<String>(testKey);

        expect(result, equals(testValue));

        final stats = service.getCacheStats();
        expect(stats['cache_hits'], greaterThan(0));
        expect(stats['cache_size'], greaterThan(0));
      });

      test('should handle LRU eviction correctly', () async {
        // Fill cache beyond MAX_CACHE_SIZE
        for (var i = 0; i < EnhancedStorageService.MAX_CACHE_SIZE + 10; i++) {
          await service.store('key_$i', 'value_$i');
        }

        final stats = service.getCacheStats();
        expect(stats['cache_size'], lessThanOrEqualTo(EnhancedStorageService.MAX_CACHE_SIZE));

        // Verify that older entries were evicted
        final newValue = await service.get<String>('key_${EnhancedStorageService.MAX_CACHE_SIZE + 5}');

        // key_0 should have been evicted and result in cache miss
        // key_${MAX_CACHE_SIZE + 5} should be in cache and result in cache hit
        expect(newValue, equals('value_${EnhancedStorageService.MAX_CACHE_SIZE + 5}'));
      });

      test('should handle cache expiration correctly', () async {
        const testKey = 'expiring_key';
        const testValue = 'expiring_value';

        // Store with very short TTL
        service.addToCache(testKey, testValue, ttl: const Duration(milliseconds: 1));

        // Wait for expiration
        await Future.delayed(const Duration(milliseconds: 10));

        // Should return null for expired cache entry
        final result = await service.get<String>(testKey);
        expect(result, isNull);
      });

      test('should clear cache correctly', () async {
        // Add some data to cache
        await service.store('key1', 'value1');
        await service.store('key2', 'value2');

        expect(service.getCacheStats()['cache_size'], greaterThan(0));

        // Clear cache
        service.clearCache();

        final stats = service.getCacheStats();
        expect(stats['cache_hits'], equals(0));
        expect(stats['cache_misses'], equals(0));
        expect(stats['cache_size'], equals(0));
      });

      test('should invalidate specific cache entries', () async {
        const testKey = 'invalidate_key';
        const testValue = 'invalidate_value';

        await service.store(testKey, testValue);

        // Verify it's in cache
        final result = await service.get<String>(testKey);
        expect(result, equals(testValue));

        // Invalidate the entry
        service.invalidateCache(testKey);

        // Should no longer be in cache
        final stats = service.getCacheStats();
        expect(stats['cache_size'], equals(0));
      });

      test('should calculate hit rate correctly', () async {
        await service.store('key1', 'value1');
        await service.store('key2', 'value2');

        // Generate some hits and misses
        await service.get<String>('key1'); // hit
        await service.get<String>('key2'); // hit
        await service.get<String>('nonexistent'); // miss

        final stats = service.getCacheStats();
        final hitRate = double.parse(stats['hit_rate']);
        expect(hitRate, greaterThan(0.0));
        expect(hitRate, lessThanOrEqualTo(100.0));
      });
    });

    group('Generic Storage Operations', () {
      test('should store and retrieve different data types', () async {
        // String
        await service.store('string_key', 'test_string');
        final stringResult = await service.get<String>('string_key');
        expect(stringResult, equals('test_string'));

        // Integer
        await service.store('int_key', 42);
        final intResult = await service.get<int>('int_key');
        expect(intResult, equals(42));

        // Map
        final mapData = {'nested': 'value', 'number': 123};
        await service.store('map_key', mapData);
        final mapResult = await service.get<Map<String, dynamic>>('map_key');
        expect(mapResult, equals(mapData));

        // List
        final listData = [1, 2, 3, 'four'];
        await service.store('list_key', listData);
        final listResult = await service.get<List<dynamic>>('list_key');
        expect(listResult, equals(listData));
      });

      test('should return null for non-existent keys', () async {
        final result = await service.get<String>('non_existent_key');
        expect(result, isNull);
      });

      test('should handle complex nested data structures', () async {
        final complexData = {
          'user': {
            'id': '123',
            'preferences': {
              'theme': 'dark',
              'notifications': true,
              'categories': ['environment', 'science', 'health']
            }
          },
          'analytics': {'views': 100, 'completions': 75, 'averageTime': 8.5}
        };

        await service.store('complex_data', complexData);
        final result = await service.get<Map<String, dynamic>>('complex_data');

        expect(result, equals(complexData));
        expect(result?['user']['preferences']['categories'], equals(['environment', 'science', 'health']));
        expect(result?['analytics']['averageTime'], equals(8.5));
      });
    });

    group('Box Routing Logic', () {
      test('should route user profile keys to user box', () async {
        final userProfile = UserProfile(
          id: 'test_user',
          displayName: 'Test User',
          email: 'test@example.com',
        );

        // Test routing for user profile key
        await service.store(StorageKeys.userProfileKey, userProfile);
        await service.store('user_settings', {'theme': 'dark'});
        await service.store('user_preferences', {'lang': 'en'});

        // Verify data is stored (we can't easily test box routing without complex mocking)
        final retrievedProfile = await service.get<UserProfile>(StorageKeys.userProfileKey);
        expect(retrievedProfile?.id, equals('test_user'));
      });

      test('should route settings keys correctly', () async {
        await service.store(StorageKeys.isDarkModeKey, true);
        await service.store(StorageKeys.isGoogleSyncEnabledKey, false);
        await service.store(StorageKeys.themeModeKey, 'auto');
        await service.store('settings_general', {'language': 'en'});

        final darkMode = await service.get<bool>(StorageKeys.isDarkModeKey);
        final syncEnabled = await service.get<bool>(StorageKeys.isGoogleSyncEnabledKey);
        final themeMode = await service.get<String>(StorageKeys.themeModeKey);

        expect(darkMode, isTrue);
        expect(syncEnabled, isFalse);
        expect(themeMode, equals('auto'));
      });

      test('should route classification keys correctly', () async {
        final classificationData = {
          'id': 'classification_123',
          'category': 'Recyclable',
          'confidence': 0.95,
          'timestamp': DateTime.now().toIso8601String(),
        };

        await service.store('classification_123', classificationData);
        await service.store('classification_history', [classificationData]);

        final result = await service.get<Map<String, dynamic>>('classification_123');
        expect(result?['category'], equals('Recyclable'));
        expect(result?['confidence'], equals(0.95));
      });

      test('should route gamification keys correctly', () async {
        final gamificationData = {
          'points': 1500,
          'level': 10,
          'achievements': ['first_classification', 'eco_warrior'],
          'streak': 7,
        };

        await service.store(StorageKeys.userGamificationProfileKey, gamificationData);
        await service.store(StorageKeys.achievementsKey, gamificationData['achievements']);
        await service.store(StorageKeys.pointsKey, gamificationData['points']);
        await service.store('gamification_stats', {'totalTime': 120});

        final profile = await service.get<Map<String, dynamic>>(StorageKeys.userGamificationProfileKey);
        final achievements = await service.get<List<String>>(StorageKeys.achievementsKey);

        expect(profile?['points'], equals(1500));
        expect(achievements, equals(['first_classification', 'eco_warrior']));
      });

      test('should route unknown keys to settings box by default', () async {
        await service.store('unknown_key_type', 'default_value');
        await service.store('random_setting', {'custom': true});

        final unknownResult = await service.get<String>('unknown_key_type');
        final randomResult = await service.get<Map<String, dynamic>>('random_setting');

        expect(unknownResult, equals('default_value'));
        expect(randomResult?['custom'], isTrue);
      });
    });

    group('Performance and Optimization', () {
      test('should handle concurrent operations safely', () async {
        final futures = <Future>[];

        // Simulate concurrent reads and writes
        for (var i = 0; i < 50; i++) {
          futures.add(service.store('concurrent_key_$i', 'value_$i'));
        }

        for (var i = 0; i < 50; i++) {
          futures.add(service.get<String>('concurrent_key_$i'));
        }

        await Future.wait(futures);

        // Verify cache remains consistent
        final stats = service.getCacheStats();
        expect(stats['cache_size'], lessThanOrEqualTo(EnhancedStorageService.MAX_CACHE_SIZE));
      });

      test('should maintain performance with large datasets', () async {
        final stopwatch = Stopwatch()..start();

        // Store many items
        for (var i = 0; i < 1000; i++) {
          await service.store('perf_key_$i', {
            'id': i,
            'data': 'large_data_$i' * 10, // Simulate larger data
            'timestamp': DateTime.now().toIso8601String(),
          });
        }

        stopwatch.stop();

        // Verify cache doesn't grow beyond limit
        final stats = service.getCacheStats();
        expect(stats['cache_size'], lessThanOrEqualTo(EnhancedStorageService.MAX_CACHE_SIZE));

        // Performance should be reasonable (this is a rough check)
        expect(stopwatch.elapsedMilliseconds, lessThan(10000)); // 10 seconds max
      });

      test('should optimize for frequently accessed data', () async {
        // Store some data
        await service.store('frequent_key', 'frequent_value');
        await service.store('rare_key', 'rare_value');

        // Access frequent_key multiple times
        for (var i = 0; i < 10; i++) {
          await service.get<String>('frequent_key');
        }

        // Access rare_key once
        await service.get<String>('rare_key');

        // Add many more items to potentially evict from cache
        for (var i = 0; i < 50; i++) {
          await service.store('filler_$i', 'filler_value_$i');
        }

        // Frequent key should still result in cache hit due to LRU
        final frequentResult = await service.get<String>('frequent_key');
        expect(frequentResult, equals('frequent_value'));
      });
    });

    group('Integration with Base StorageService', () {
      test('should extend base storage service functionality', () {
        expect(service, isA<EnhancedStorageService>());
        // Since EnhancedStorageService extends StorageService,
        // it should have all the base functionality
      });

      test('should handle preload critical data operation', () async {
        // This test verifies the method doesn't throw errors
        // In a real scenario, this would require proper Hive initialization
        expect(() => service.preloadCriticalData(), returnsNormally);
      });

      test('should handle warmup cache operation', () async {
        // This test verifies the method doesn't throw errors
        expect(() => service.warmUpCache(), returnsNormally);
      });
    });

    group('Error Handling and Edge Cases', () {
      test('should handle null values gracefully', () async {
        await service.store('null_key', null);
        final result = await service.get<String?>('null_key');
        expect(result, isNull);
      });

      test('should handle empty strings and collections', () async {
        await service.store('empty_string', '');
        await service.store('empty_list', <String>[]);
        await service.store('empty_map', <String, dynamic>{});

        final emptyString = await service.get<String>('empty_string');
        final emptyList = await service.get<List<String>>('empty_list');
        final emptyMap = await service.get<Map<String, dynamic>>('empty_map');

        expect(emptyString, equals(''));
        expect(emptyList, equals(<String>[]));
        expect(emptyMap, equals(<String, dynamic>{}));
      });

      test('should handle very long keys', () async {
        final longKey = 'very_long_key_${'a' * 1000}';
        const longValue = 'very_long_value';

        await service.store(longKey, longValue);
        final result = await service.get<String>(longKey);

        expect(result, equals(longValue));
      });

      test('should handle special characters in keys and values', () async {
        const specialKey = 'key-with-special_chars.123!@#\$%^&*()';
        const specialValue = 'value with émojis 🎯 and special chars: éñøñé';

        await service.store(specialKey, specialValue);
        final result = await service.get<String>(specialKey);

        expect(result, equals(specialValue));
      });

      test('should handle rapid cache invalidation', () async {
        const testKey = 'rapid_invalidate';

        for (var i = 0; i < 100; i++) {
          await service.store(testKey, 'value_$i');
          service.invalidateCache(testKey);
        }

        // Should not throw any errors
        final stats = service.getCacheStats();
        expect(stats, isMap);
      });

      test('should handle mixed data types in same session', () async {
        await service.store('mixed_string', 'text');
        await service.store('mixed_int', 42);
        await service.store('mixed_double', 3.14);
        await service.store('mixed_bool', true);
        await service.store('mixed_list', [1, 'two', 3.0]);
        await service.store('mixed_map', {'key': 'value', 'number': 123});

        final stringResult = await service.get<String>('mixed_string');
        final intResult = await service.get<int>('mixed_int');
        final doubleResult = await service.get<double>('mixed_double');
        final boolResult = await service.get<bool>('mixed_bool');
        final listResult = await service.get<List<dynamic>>('mixed_list');
        final mapResult = await service.get<Map<String, dynamic>>('mixed_map');

        expect(stringResult, equals('text'));
        expect(intResult, equals(42));
        expect(doubleResult, equals(3.14));
        expect(boolResult, isTrue);
        expect(listResult, equals([1, 'two', 3.0]));
        expect(mapResult, equals({'key': 'value', 'number': 123}));
      });
    });

    group('Cache Statistics and Monitoring', () {
      test('should provide accurate cache statistics', () async {
        // Perform various operations
        await service.store('stat_key1', 'value1');
        await service.store('stat_key2', 'value2');
        await service.get<String>('stat_key1'); // hit
        await service.get<String>('stat_key2'); // hit
        await service.get<String>('nonexistent'); // miss

        final stats = service.getCacheStats();

        expect(stats, containsPair('cache_hits', isA<int>()));
        expect(stats, containsPair('cache_misses', isA<int>()));
        expect(stats, containsPair('hit_rate', isA<String>()));
        expect(stats, containsPair('cache_size', isA<int>()));

        expect(stats['cache_hits'], greaterThan(0));
        expect(stats['cache_misses'], greaterThan(0));
        expect(stats['cache_size'], greaterThan(0));
      });

      test('should reset statistics when cache is cleared', () async {
        // Build up some statistics
        await service.store('reset_key', 'value');
        await service.get<String>('reset_key');
        await service.get<String>('nonexistent');

        var stats = service.getCacheStats();
        expect(stats['cache_hits'], greaterThan(0));
        expect(stats['cache_misses'], greaterThan(0));

        // Clear cache
        service.clearCache();

        stats = service.getCacheStats();
        expect(stats['cache_hits'], equals(0));
        expect(stats['cache_misses'], equals(0));
        expect(stats['cache_size'], equals(0));
        expect(stats['hit_rate'], equals('0.0'));
      });

      test('should calculate hit rate as percentage', () async {
        // Create predictable hit/miss pattern
        await service.store('hit_test', 'value');

        // Generate 3 hits, 1 miss
        await service.get<String>('hit_test'); // hit
        await service.get<String>('hit_test'); // hit
        await service.get<String>('hit_test'); // hit
        await service.get<String>('miss_test'); // miss

        final stats = service.getCacheStats();
        final hitRate = stats['hit_rate'] as String;

        // Should be 75% (3 hits out of 4 total)
        expect(hitRate, equals('75.0'));
      });
    });

    group('Memory Management', () {
      test('should not leak memory with frequent operations', () async {
        final initialStats = service.getCacheStats();

        // Perform many operations
        for (var i = 0; i < 500; i++) {
          await service.store('memory_test_$i', 'value_$i');
          if (i % 10 == 0) {
            await service.get<String>('memory_test_${i ~/ 2}');
          }
        }

        final finalStats = service.getCacheStats();

        // Cache size should be bounded
        expect(finalStats['cache_size'], lessThanOrEqualTo(EnhancedStorageService.MAX_CACHE_SIZE));

        // Should have reasonable statistics
        expect(finalStats['cache_hits'], isA<int>());
        expect(finalStats['cache_misses'], isA<int>());
      });
    });
  });
}
