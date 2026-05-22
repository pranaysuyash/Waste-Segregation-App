import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:waste_segregation_app/services/enhanced_storage_service.dart';
import 'package:waste_segregation_app/utils/constants.dart';

void main() {
  late EnhancedStorageService service;
  late Directory hiveTestDir;

  setUpAll(() async {
    hiveTestDir = Directory.systemTemp.createTempSync('enhanced_storage_hive_');
    Hive.init(hiveTestDir.path);
    await Hive.openBox(StorageKeys.userBox);
    await Hive.openBox(StorageKeys.settingsBox);
    await Hive.openBox(StorageKeys.classificationsBox);
    await Hive.openBox(StorageKeys.gamificationBox);
  });

  setUp(() async {
    service = EnhancedStorageService();
    await Hive.box(StorageKeys.userBox).clear();
    await Hive.box(StorageKeys.settingsBox).clear();
    await Hive.box(StorageKeys.classificationsBox).clear();
    await Hive.box(StorageKeys.gamificationBox).clear();
    service.clearCache();
  });

  tearDownAll(() async {
    await Hive.close();
    if (hiveTestDir.existsSync()) {
      hiveTestDir.deleteSync(recursive: true);
    }
  });

  group('EnhancedStorageService', () {
    test('store and get route through Hive and cache stats reflect hits and misses',
        () async {
      await service.store('settings_themeMode', 'dark');

      expect(await service.get<String>('settings_themeMode'), 'dark');
      expect(await service.get<String>('settings_themeMode'), 'dark');

      final stats = service.getCacheStats();
      expect(stats['cache_hits'], 2);
      expect(stats['cache_misses'], 0);
      expect(stats['cache_size'], 1);

      service.invalidateCache('settings_themeMode');
      expect(service.getCacheStats()['cache_size'], 0);

      expect(await service.get<String>('settings_themeMode'), 'dark');
      expect(service.getCacheStats()['cache_misses'], 1);
    });

    test('addToCache evicts the oldest entry when capacity is exceeded',
        () async {
      for (var i = 0; i <= EnhancedStorageService.maxCacheSize; i++) {
        service.addToCache('key_$i', 'value_$i');
      }

      final stats = service.getCacheStats();
      expect(stats['cache_size'], EnhancedStorageService.maxCacheSize);
      expect(await service.get<String>('key_0'), isNull);
      expect(
        await service.get<String>('key_${EnhancedStorageService.maxCacheSize}'),
        'value_${EnhancedStorageService.maxCacheSize}',
      );
    });

    test('clearCache resets hits, misses, and size', () {
      service.addToCache('temp', 'value');
      expect(service.getCacheStats()['cache_size'], 1);

      service.clearCache();

      expect(service.getCacheStats(), {
        'cache_hits': 0,
        'cache_misses': 0,
        'hit_rate': '0.0',
        'cache_size': 0,
      });
    });
  });
}
