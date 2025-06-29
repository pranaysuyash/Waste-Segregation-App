import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waste_segregation_app/services/cache_service.dart';
import 'package:waste_segregation_app/models/cached_classification.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';

/// Test helper utilities for setting up and tearing down test environment
class TestHelper {
  static bool _hiveInitialized = false;

  /// Initialize Hive for testing without path dependencies
  static Future<void> initializeHive() async {
    if (_hiveInitialized) return;

    try {
      // Initialize Hive in memory for tests
      Hive.init('.');

      // Register adapters if needed
      // Note: Only register if not already registered

      _hiveInitialized = true;
      debugPrint('✅ Test Hive initialized in memory');
    } catch (e) {
      debugPrint('❌ Error initializing test Hive: $e');
      // Don't rethrow - allow tests to continue with mock services
    }
  }

  /// Clean up Hive boxes and close them
  static Future<void> cleanupHive() async {
    if (!_hiveInitialized) return;

    try {
      // Close all boxes that might be open
      await Hive.close();
    } catch (e) {
      debugPrint('⚠️ Warning: Error cleaning up test Hive: $e');
    }
  }

  /// Completely tear down Hive for tests
  static Future<void> tearDownHive() async {
    if (!_hiveInitialized) return;

    try {
      await Hive.close();
      _hiveInitialized = false;
      debugPrint('✅ Test Hive torn down');
    } catch (e) {
      debugPrint('⚠️ Warning: Error tearing down test Hive: $e');
    }
  }

  /// Setup mock SharedPreferences for testing
  static void setupMockSharedPreferences([Map<String, Object>? initialValues]) {
    SharedPreferences.setMockInitialValues(initialValues ?? {});
  }

  /// Create a mock cache service that doesn't need Hive
  static ClassificationCacheService createMockCacheService() {
    return MockClassificationCacheService();
  }

  /// Setup test environment for service tests
  static Future<void> setupServiceTest() async {
    setupMockSharedPreferences();
    await initializeHive();
  }

  /// Cleanup after service tests
  static Future<void> cleanupServiceTest() async {
    await cleanupHive();
  }

  /// Setup complete test environment including all dependencies
  static Future<void> setupCompleteTest() async {
    setupMockSharedPreferences();
    await initializeHive();
  }

  /// Complete cleanup including Hive teardown
  static Future<void> tearDownCompleteTest() async {
    await tearDownHive();
  }
}

/// Mock ClassificationCacheService that doesn't require Hive
class MockClassificationCacheService extends Mock implements ClassificationCacheService {
  final Map<String, CachedClassification> _mockCache = {};

  @override
  Future<void> initialize() async {}

  @override
  Future<CachedClassification?> getCachedClassification(
    String imageHash, {
    String? contentHash,
    int similarityThreshold = 6,
  }) async {
    return _mockCache[imageHash];
  }

  @override
  Future<void> cacheClassification(
    String imageHash,
    WasteClassification classification, {
    String? contentHash,
    int? imageSize,
  }) async {
    _mockCache[imageHash] = CachedClassification.fromClassification(
      imageHash,
      classification,
      imageSize: imageSize,
    );
  }

  @override
  Map<String, dynamic> getCacheStatistics() {
    return {
      'hits': 0,
      'misses': 0,
      'size': _mockCache.length,
      'bytesSaved': 0,
      'createdAt': DateTime.now(),
    };
  }

  @override
  Future<void> clearCache() async {
    _mockCache.clear();
  }
}
