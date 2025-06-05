import 'package:flutter/foundation.dart';

/// Configuration for developer-only features with multiple safety checks
/// 
/// This class ensures developer options can NEVER appear in production builds
/// by using multiple layers of protection:
/// 1. Compile-time constants
/// 2. Runtime assertions
/// 3. Build mode checks
class DeveloperConfig {
  // Private constructor to prevent instantiation
  DeveloperConfig._();
  
  /// Compile-time constant that determines if developer features are available
  /// This will be optimized out in release builds
  static const bool _kDeveloperFeaturesCompileTime = kDebugMode;
  
  /// Runtime check that also validates build mode
  /// This provides an additional safety layer
  static bool get _runtimeSafetyCheck {
    // In release builds, this should always be false
    if (kReleaseMode) {
      return false;
    }
    
    // In debug mode, verify that we're actually in debug mode
    return kDebugMode;
  }
  
  /// Master switch for all developer features
  /// Uses both compile-time and runtime checks for maximum safety
  static bool get isDeveloperModeEnabled {
    // Compile-time check - will be optimized out in release builds
    if (!_kDeveloperFeaturesCompileTime) {
      return false;
    }
    
    // Runtime safety check
    if (!_runtimeSafetyCheck) {
      return false;
    }
    
    // Additional assertion for development builds
    assert(() {
      // This block only runs in debug mode
      if (kReleaseMode) {
        throw StateError('Developer features should never be enabled in release mode!');
      }
      return true;
    }());
    
    return true;
  }
  
  /// Check if developer options should be shown in settings
  static bool get canShowDeveloperOptions {
    return isDeveloperModeEnabled;
  }
  
  /// Check if factory reset developer tool should be available
  static bool get canShowFactoryReset {
    return isDeveloperModeEnabled;
  }
  
  /// Check if premium feature toggles should be available
  static bool get canShowPremiumToggles {
    return isDeveloperModeEnabled;
  }
  
  /// Check if crash test button should be available
  static bool get canShowCrashTest {
    return isDeveloperModeEnabled;
  }
  
  /// Check if debug logging should be enabled
  static bool get isDebugLoggingEnabled {
    return isDeveloperModeEnabled;
  }
  
  /// Validate that we're not in a compromised state
  /// This method should be called at app startup
  static void validateSecurity() {
    // In release mode, absolutely no developer features should be available
    if (kReleaseMode) {
      if (isDeveloperModeEnabled) {
        throw StateError('SECURITY VIOLATION: Developer features enabled in release build!');
      }
    }
    
    // Additional runtime checks
    if (kReleaseMode && _runtimeSafetyCheck) {
      throw StateError('SECURITY VIOLATION: Runtime safety check failed in release build!');
    }
    
    // Log the current state for verification (only in debug)
    if (kDebugMode) {
      debugPrint('🔒 Developer Config Security Check Passed');
      debugPrint('📊 Developer Mode Enabled: $isDeveloperModeEnabled');
      debugPrint('🏗️ Build Mode: ${kDebugMode ? 'DEBUG' : kReleaseMode ? 'RELEASE' : 'PROFILE'}');
    }
  }
  
  /// Get developer features status for debugging
  static Map<String, dynamic> getStatus() {
    if (!kDebugMode) {
      return {'error': 'Status not available in non-debug builds'};
    }
    
    return {
      'isDeveloperModeEnabled': isDeveloperModeEnabled,
      'canShowDeveloperOptions': canShowDeveloperOptions,
      'canShowFactoryReset': canShowFactoryReset,
      'canShowPremiumToggles': canShowPremiumToggles,
      'canShowCrashTest': canShowCrashTest,
      'isDebugLoggingEnabled': isDebugLoggingEnabled,
      'buildMode': kDebugMode ? 'DEBUG' : kReleaseMode ? 'RELEASE' : 'PROFILE',
      'compileTimeCheck': _kDeveloperFeaturesCompileTime,
      'runtimeSafetyCheck': _runtimeSafetyCheck,
    };
  }
} 