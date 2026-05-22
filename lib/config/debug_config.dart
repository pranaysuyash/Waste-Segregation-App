/// Debug configuration for development builds
///
/// Provides runtime guardrails and logging for ResultScreen migration.
/// Only active in debug builds - no overhead in release.
library;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../utils/waste_app_logger.dart';

/// Debug configuration for ResultScreen migration
class ResultScreenDebugConfig {
  ResultScreenDebugConfig._();

  /// Enable verbose logging for ResultScreen operations
  static bool get enableLogging => kDebugMode;

  /// Log which ResultScreen version is being used
  static void logVersionUsed(String version, String classificationId) {
    if (!enableLogging) return;

    WasteAppLogger.info(
      '[RESULT_SCREEN] Version selected',
      context: {
        'version': version,
        'classificationId': classificationId,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Log pipeline output summary
  static void logPipelineOutput({
    required String classificationId,
    required int pointsEarned,
    required int achievementsCount,
    required bool isSaved,
    String? analysisSource,
    String? modelVersion,
    String? fallbackReason,
    String? error,
  }) {
    if (!enableLogging) return;

    if (error != null) {
      WasteAppLogger.warning(
        '[RESULT_SCREEN] Pipeline error',
        context: {
          'classificationId': classificationId,
          'error': error,
        },
      );
    } else {
      WasteAppLogger.info(
        '[RESULT_SCREEN] Pipeline completed',
        context: {
          'classificationId': classificationId,
          'pointsEarned': pointsEarned,
          'achievementsCount': achievementsCount,
          'isSaved': isSaved,
          'analysisSource': analysisSource,
          'modelVersion': modelVersion,
          'fallbackReason': fallbackReason,
        },
      );
    }
  }

  /// Log analytics events as they fire
  static void logAnalyticsEvent(String eventName, Map<String, dynamic> params) {
    if (!enableLogging) return;

    WasteAppLogger.info(
      '[RESULT_SCREEN] Analytics event',
      context: {
        'event': eventName,
        'parameters': params,
      },
    );
  }

  /// Log navigation actions
  static void logNavigation(String action, String from, String to) {
    if (!enableLogging) return;

    WasteAppLogger.info(
      '[RESULT_SCREEN] Navigation',
      context: {
        'action': action,
        'from': from,
        'to': to,
      },
    );
  }

  /// Log save operations with idempotency check
  static void logSaveAttempt(String classificationId, {required bool isRetry}) {
    if (!enableLogging) return;

    WasteAppLogger.info(
      '[RESULT_SCREEN] Save attempt',
      context: {
        'classificationId': classificationId,
        'isRetry': isRetry,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Assert parity invariants (only in debug)
  static void assertParity({
    required String classificationId,
    required String category,
    required double confidence,
    required bool hasDisposalInstructions,
  }) {
    if (!enableLogging) return;

    assert(classificationId.isNotEmpty, 'Classification ID cannot be empty');
    assert(category.isNotEmpty, 'Category cannot be empty');
    assert(confidence >= 0 && confidence <= 1, 'Confidence must be 0-1');
    assert(hasDisposalInstructions, 'Disposal instructions required');
  }
}

/// Feature flag overrides for development testing
class DebugFeatureFlags {
  DebugFeatureFlags._();

  /// Force legacy ResultScreen (ignores remote config)
  ///
  /// Usage: Add `?legacyResults=1` to app URL in dev
  static bool get forceLegacyResults {
    if (!kDebugMode) return false;

    // Check URL query parameter
    // This would need to be integrated with your navigation system
    return _urlParams['legacyResults'] == '1';
  }

  /// Force V2 ResultScreen (ignores remote config)
  ///
  /// Usage: Add `?v2Results=1` to app URL in dev
  static bool get forceV2Results {
    if (!kDebugMode) return false;

    return _urlParams['v2Results'] == '1';
  }

  /// Get effective screen version based on overrides
  static String get effectiveVersion {
    if (forceLegacyResults) return 'legacy';
    if (forceV2Results) return 'v2';
    return 'remote_config'; // Use Firebase Remote Config
  }

  // Simulated URL params - integrate with your routing
  static final Map<String, String> _urlParams = {};

  /// Set URL params for testing
  static void setUrlParams(Map<String, String> params) {
    if (!kDebugMode) return;
    _urlParams.clear();
    _urlParams.addAll(params);
  }
}

/// Debug-only UI indicators
class DebugIndicators {
  DebugIndicators._();

  /// Build a debug banner showing which ResultScreen version is active
  ///
  /// Only visible in debug builds. Returns null in release.
  static Widget? buildVersionBanner(String version) {
    if (!kDebugMode) return null;

    return Container(
      color: version == 'v2' ? Colors.green : Colors.orange,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(
        'RESULT: $version',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
