import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import '../utils/waste_app_logger.dart';

/// Service for managing Firebase Remote Config for A/B testing and feature flags
class RemoteConfigService {
  factory RemoteConfigService() => _instance;
  RemoteConfigService._internal();
  static final RemoteConfigService _instance = RemoteConfigService._internal();

  FirebaseRemoteConfig? _remoteConfig;
  bool _initialized = false;

  /// Initialize Remote Config with default values
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _remoteConfig = FirebaseRemoteConfig.instance;

      // Set default values for feature flags
      await _remoteConfig!.setDefaults({
        'home_header_v2_enabled': true, // Default to new header
        'results_v2_enabled': false, // Default to legacy result screen
        'golden_test_mode': false,
        'accessibility_enhanced': true,
        'micro_animations_enabled': true,
      });

      // Configure fetch settings
      await _remoteConfig!.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: Duration.zero, // For testing - use longer in production
      ));

      // Fetch and activate
      await _remoteConfig!.fetchAndActivate();
      _initialized = true;

      if (kDebugMode) {
        WasteAppLogger.info('RemoteConfigService initialized successfully', null, null,
            {'service': 'remote_config', 'status': 'initialized'});
      }
    } catch (e) {
      WasteAppLogger.severe('RemoteConfigService initialization failed', e, null,
          {'service': 'remote_config', 'action': 'continue_without_remote_config'});
      // Continue without remote config in case of failure
      _initialized = true;
    }
  }

  /// Get boolean value with fallback
  Future<bool> getBool(String key, {bool defaultValue = false}) async {
    await initialize();

    try {
      return _remoteConfig?.getBool(key) ?? defaultValue;
    } catch (e) {
      if (kDebugMode) {
        WasteAppLogger.severe('🔥 Error getting remote config bool for $key: $e');
      }
      return defaultValue;
    }
  }

  /// Get string value with fallback
  Future<String> getString(String key, {String defaultValue = ''}) async {
    await initialize();

    try {
      return _remoteConfig?.getString(key) ?? defaultValue;
    } catch (e) {
      if (kDebugMode) {
        WasteAppLogger.severe('🔥 Error getting remote config string for $key: $e');
      }
      return defaultValue;
    }
  }

  /// Get integer value with fallback
  Future<int> getInt(String key, {int defaultValue = 0}) async {
    await initialize();

    try {
      return _remoteConfig?.getInt(key) ?? defaultValue;
    } catch (e) {
      if (kDebugMode) {
        WasteAppLogger.severe('🔥 Error getting remote config int for $key: $e');
      }
      return defaultValue;
    }
  }

  /// Force fetch new config (for testing)
  Future<void> forceFetch() async {
    await initialize();

    try {
      await _remoteConfig?.fetchAndActivate();
      if (kDebugMode) {
        WasteAppLogger.info('🔧 Remote config force fetched');
      }
    } catch (e) {
      if (kDebugMode) {
        WasteAppLogger.severe('🔥 Error force fetching remote config: $e');
      }
    }
  }

  /// Get all remote config values (for debugging)
  Map<String, dynamic> getAllValues() {
    if (!_initialized || _remoteConfig == null) return {};

    try {
      return _remoteConfig!.getAll().map((key, value) => MapEntry(key, value.asString()));
    } catch (e) {
      if (kDebugMode) {
        WasteAppLogger.severe('🔥 Error getting all remote config values: $e');
      }
      return {};
    }
  }
}
