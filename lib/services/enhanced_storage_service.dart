import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../models/user_profile.dart';
import 'package:waste_segregation_app/utils/waste_app_logger.dart';

/// Enhanced Storage Service with Smart Caching
/// Extends the base storage service with LRU cache and performance optimizations
class EnhancedStorageService extends StorageService {
  static const int maxCacheSize = 200;
  final LinkedHashMap<String, CacheEntry> _lruCache = LinkedHashMap();
  
  // Cache Statistics
  int _cacheHits = 0;
  int _cacheMisses = 0;
  
  /// Generic get method with caching support
  Future<T?> get<T>(String key) async {
    // Check LRU cache first
    if (_lruCache.containsKey(key)) {
      final entry = _lruCache.remove(key)!;
      
      // Check if cache entry is still valid
      if (!entry.isExpired) {
        _lruCache[key] = entry; // Move to end (most recently used)
        _cacheHits++;
        return entry.value as T?;
      } else {
        // Remove expired entry
        _lruCache.remove(key);
      }
    }
    
    // Cache miss - get from persistent storage using Hive directly
    _cacheMisses++;
    final result = await _getFromHive<T>(key);
    
    if (result != null) {
      addToCache(key, result);
    }
    
    return result;
  }
  
  /// Generic store method with caching support
  Future<void> store<T>(String key, T value) async {
    // Store in cache
    addToCache(key, value);
    
    // Store in persistent storage using Hive directly
    await _storeInHive(key, value);
  }
  
  /// Internal method to get from Hive storage
  Future<T?> _getFromHive<T>(String key) async {
    try {
      // Determine which box to use based on key pattern
      late Box box;
      
      if (key == StorageKeys.userProfileKey || key.startsWith('user_')) {
        box = Hive.box(StorageKeys.userBox);
      } else if (key.startsWith('settings_') || key == StorageKeys.isDarkModeKey || 
                 key == StorageKeys.isGoogleSyncEnabledKey || key == StorageKeys.themeModeKey) {
        box = Hive.box(StorageKeys.settingsBox);
      } else if (key.startsWith('classification_')) {
        box = Hive.box(StorageKeys.classificationsBox);
      } else if (key.startsWith('gamification_') || key == StorageKeys.userGamificationProfileKey ||
                 key == StorageKeys.achievementsKey || key == StorageKeys.streakKey ||
                 key == StorageKeys.pointsKey || key == StorageKeys.challengesKey ||
                 key == StorageKeys.weeklyStatsKey) {
        box = Hive.box(StorageKeys.gamificationBox);
      } else {
        // Default to settings box for unknown keys
        box = Hive.box(StorageKeys.settingsBox);
      }
      
      return box.get(key) as T?;
    } catch (e) {
      WasteAppLogger.severe('Error getting value from Hive for key $key: $e');
      return null;
    }
  }
  
  /// Internal method to store in Hive storage
  Future<void> _storeInHive<T>(String key, T value) async {
    try {
      // Determine which box to use based on key pattern
      late Box box;
      
      if (key == StorageKeys.userProfileKey || key.startsWith('user_')) {
        box = Hive.box(StorageKeys.userBox);
      } else if (key.startsWith('settings_') || key == StorageKeys.isDarkModeKey || 
                 key == StorageKeys.isGoogleSyncEnabledKey || key == StorageKeys.themeModeKey) {
        box = Hive.box(StorageKeys.settingsBox);
      } else if (key.startsWith('classification_')) {
        box = Hive.box(StorageKeys.classificationsBox);
      } else if (key.startsWith('gamification_') || key == StorageKeys.userGamificationProfileKey ||
                 key == StorageKeys.achievementsKey || key == StorageKeys.streakKey ||
                 key == StorageKeys.pointsKey || key == StorageKeys.challengesKey ||
                 key == StorageKeys.weeklyStatsKey) {
        box = Hive.box(StorageKeys.gamificationBox);
      } else {
        // Default to settings box for unknown keys
        box = Hive.box(StorageKeys.settingsBox);
      }
      
      await box.put(key, value);
    } catch (e) {
      WasteAppLogger.severe('Error storing value in Hive for key $key: $e');
      rethrow;
    }
  }
  
  void addToCache(String key, dynamic value, {Duration? ttl}) {
    // Remove oldest entries if cache is full
    while (_lruCache.length >= maxCacheSize) {
      _lruCache.remove(_lruCache.keys.first);
    }
    
    _lruCache[key] = CacheEntry(
      value: value,
      timestamp: DateTime.now(),
      ttl: ttl ?? const Duration(hours: 24),
    );
  }
  
  /// Preload Critical Data using base class methods
  Future<void> preloadCriticalData() async {
    try {
      // Load critical data using the base class methods
      await Future.wait([
        getCurrentUserProfile().then((data) => addToCache(StorageKeys.userProfileKey, data)),
        getSettings().then((data) => addToCache('settings', data)),
        getAllClassifications().then((data) => addToCache('all_classifications', data)),
      ]);
    } catch (e) {
      WasteAppLogger.severe('Error preloading critical data: $e');
    }
  }
  
  /// Enhanced getCurrentUserProfile with caching
  @override
  Future<UserProfile?> getCurrentUserProfile() async {
    const key = StorageKeys.userProfileKey;
    
    // Check cache first
    if (_lruCache.containsKey(key)) {
      final entry = _lruCache.remove(key)!;
      if (!entry.isExpired) {
        _lruCache[key] = entry;
        _cacheHits++;
        return entry.value as UserProfile?;
      } else {
        _lruCache.remove(key);
      }
    }
    
    // Cache miss - get from base class
    _cacheMisses++;
    final result = await super.getCurrentUserProfile();
    if (result != null) {
      addToCache(key, result);
    }
    return result;
  }
  
  /// Enhanced getSettings with caching
  @override
  Future<Map<String, dynamic>> getSettings() async {
    const key = 'settings';
    
    // Check cache first
    if (_lruCache.containsKey(key)) {
      final entry = _lruCache.remove(key)!;
      if (!entry.isExpired) {
        _lruCache[key] = entry;
        _cacheHits++;
        return entry.value as Map<String, dynamic>;
      } else {
        _lruCache.remove(key);
      }
    }
    
    // Cache miss - get from base class
    _cacheMisses++;
    final result = await super.getSettings();
    addToCache(key, result);
    return result;
  }
  
  /// Cache Statistics
  Map<String, dynamic> getCacheStats() {
    final total = _cacheHits + _cacheMisses;
    return {
      'cache_hits': _cacheHits,
      'cache_misses': _cacheMisses,
      'hit_rate': total > 0 ? (_cacheHits / total * 100).toStringAsFixed(1) : '0.0',
      'cache_size': _lruCache.length,
    };
  }
  
  /// Clear Cache
  void clearCache() {
    _lruCache.clear();
    _cacheHits = 0;
    _cacheMisses = 0;
  }
  
  /// Invalidate cache for specific key
  void invalidateCache(String key) {
    _lruCache.remove(key);
  }
  
  /// Warm up cache with frequently accessed data
  Future<void> warmUpCache() async {
    await preloadCriticalData();
  }
}

class CacheEntry {
  CacheEntry({
    required this.value,
    required this.timestamp,
    required this.ttl,
  });
  final dynamic value;
  final DateTime timestamp;
  final Duration ttl;
  
  bool get isExpired => DateTime.now().difference(timestamp) > ttl;
}
