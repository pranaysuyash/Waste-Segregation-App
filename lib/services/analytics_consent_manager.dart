import 'package:shared_preferences/shared_preferences.dart';
import '../utils/waste_app_logger.dart';

/// Manages user consent for analytics tracking in compliance with GDPR/CCPA
class AnalyticsConsentManager {
  static const String _consentKeyPrefix = 'analytics_consent_';
  static const String _consentVersionKey = 'consent_version';
  static const String _consentTimestampKey = 'consent_timestamp';
  static const String _anonymousIdKey = 'anonymous_id';
  
  // Current consent version - increment when consent requirements change
  static const int currentConsentVersion = 1;
  
  // Consent types
  static const String essentialConsent = 'essential';
  static const String analyticsConsent = 'analytics';
  static const String marketingConsent = 'marketing';
  static const String performanceConsent = 'performance';

  /// Check if user has provided consent for analytics tracking
  Future<bool> hasAnalyticsConsent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if consent version is current
      final consentVersion = prefs.getInt(_consentVersionKey) ?? 0;
      if (consentVersion < currentConsentVersion) {
        WasteAppLogger.info('Consent version outdated, requiring new consent', null, null, {
          'current_version': currentConsentVersion,
          'stored_version': consentVersion,
          'service': 'AnalyticsConsentManager'
        });
        return false;
      }
      
      // Check specific analytics consent
      return prefs.getBool('${_consentKeyPrefix}$analyticsConsent') ?? false;
    } catch (e) {
      WasteAppLogger.severe('Error checking analytics consent', e, null, {
        'service': 'AnalyticsConsentManager'
      });
      return false; // Default to no consent on error
    }
  }

  /// Check if user has provided consent for performance tracking
  Future<bool> hasPerformanceConsent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('${_consentKeyPrefix}$performanceConsent') ?? false;
    } catch (e) {
      WasteAppLogger.severe('Error checking performance consent', e, null, {
        'service': 'AnalyticsConsentManager'
      });
      return false;
    }
  }

  /// Check if user has provided consent for marketing tracking
  Future<bool> hasMarketingConsent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('${_consentKeyPrefix}$marketingConsent') ?? false;
    } catch (e) {
      WasteAppLogger.severe('Error checking marketing consent', e, null, {
        'service': 'AnalyticsConsentManager'
      });
      return false;
    }
  }

  /// Essential consent is always true (required for app functionality)
  Future<bool> hasEssentialConsent() async {
    return true; // Essential cookies/tracking always allowed
  }

  /// Set consent for specific tracking type
  Future<void> setConsent({
    required String consentType,
    required bool granted,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setBool('${_consentKeyPrefix}$consentType', granted);
      await prefs.setInt(_consentVersionKey, currentConsentVersion);
      await prefs.setString(_consentTimestampKey, DateTime.now().toIso8601String());
      
      WasteAppLogger.info('Consent updated', null, null, {
        'consent_type': consentType,
        'granted': granted,
        'version': currentConsentVersion,
        'service': 'AnalyticsConsentManager'
      });
    } catch (e) {
      WasteAppLogger.severe('Error setting consent', e, null, {
        'consent_type': consentType,
        'granted': granted,
        'service': 'AnalyticsConsentManager'
      });
    }
  }

  /// Set multiple consents at once (for consent banner)
  Future<void> setAllConsents({
    required bool analytics,
    required bool performance,
    required bool marketing,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setBool('${_consentKeyPrefix}$analyticsConsent', analytics);
      await prefs.setBool('${_consentKeyPrefix}$performanceConsent', performance);
      await prefs.setBool('${_consentKeyPrefix}$marketingConsent', marketing);
      await prefs.setInt(_consentVersionKey, currentConsentVersion);
      await prefs.setString(_consentTimestampKey, DateTime.now().toIso8601String());
      
      WasteAppLogger.info('All consents updated', null, null, {
        'analytics': analytics,
        'performance': performance,
        'marketing': marketing,
        'version': currentConsentVersion,
        'service': 'AnalyticsConsentManager'
      });
    } catch (e) {
      WasteAppLogger.severe('Error setting all consents', e, null, {
        'service': 'AnalyticsConsentManager'
      });
    }
  }

  /// Check if user needs to provide consent (first time or version updated)
  Future<bool> needsConsentDialog() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if consent version exists and is current
      final consentVersion = prefs.getInt(_consentVersionKey) ?? 0;
      final hasConsentTimestamp = prefs.containsKey(_consentTimestampKey);
      
      return consentVersion < currentConsentVersion || !hasConsentTimestamp;
    } catch (e) {
      WasteAppLogger.severe('Error checking consent dialog need', e, null, {
        'service': 'AnalyticsConsentManager'
      });
      return true; // Show dialog on error to be safe
    }
  }

  /// Get or create anonymous ID for non-authenticated users
  Future<String> getAnonymousId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? anonymousId = prefs.getString(_anonymousIdKey);
      
      if (anonymousId == null) {
        // Generate new anonymous ID
        anonymousId = 'anon_${DateTime.now().millisecondsSinceEpoch}_${(DateTime.now().microsecond % 10000)}';
        await prefs.setString(_anonymousIdKey, anonymousId);
        
        WasteAppLogger.info('Generated new anonymous ID', null, null, {
          'anonymous_id': anonymousId,
          'service': 'AnalyticsConsentManager'
        });
      }
      
      return anonymousId;
    } catch (e) {
      WasteAppLogger.severe('Error getting anonymous ID', e, null, {
        'service': 'AnalyticsConsentManager'
      });
      // Return a fallback ID
      return 'anon_fallback_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// Clear anonymous ID (for identity stitching when user authenticates)
  Future<void> clearAnonymousId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_anonymousIdKey);
      
      WasteAppLogger.info('Anonymous ID cleared for identity stitching', null, null, {
        'service': 'AnalyticsConsentManager'
      });
    } catch (e) {
      WasteAppLogger.severe('Error clearing anonymous ID', e, null, {
        'service': 'AnalyticsConsentManager'
      });
    }
  }

  /// Get current consent status for all types
  Future<Map<String, bool>> getAllConsentStatus() async {
    try {
      return {
        essentialConsent: await hasEssentialConsent(),
        analyticsConsent: await hasAnalyticsConsent(),
        performanceConsent: await hasPerformanceConsent(),
        marketingConsent: await hasMarketingConsent(),
      };
    } catch (e) {
      WasteAppLogger.severe('Error getting consent status', e, null, {
        'service': 'AnalyticsConsentManager'
      });
      return {
        essentialConsent: true,
        analyticsConsent: false,
        performanceConsent: false,
        marketingConsent: false,
      };
    }
  }

  /// Withdraw all consent (for GDPR "right to be forgotten")
  Future<void> withdrawAllConsent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Remove all consent keys
      await prefs.remove('${_consentKeyPrefix}$analyticsConsent');
      await prefs.remove('${_consentKeyPrefix}$performanceConsent');
      await prefs.remove('${_consentKeyPrefix}$marketingConsent');
      await prefs.remove(_consentVersionKey);
      await prefs.remove(_consentTimestampKey);
      await prefs.remove(_anonymousIdKey);
      
      WasteAppLogger.info('All consent withdrawn', null, null, {
        'service': 'AnalyticsConsentManager'
      });
    } catch (e) {
      WasteAppLogger.severe('Error withdrawing consent', e, null, {
        'service': 'AnalyticsConsentManager'
      });
    }
  }

  /// Get consent metadata for event tracking
  Future<Map<String, dynamic>> getConsentMetadata() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final consentStatus = await getAllConsentStatus();
      
      return {
        'consent_version': prefs.getInt(_consentVersionKey) ?? 0,
        'consent_timestamp': prefs.getString(_consentTimestampKey),
        'consent_status': consentStatus,
        'anonymous_id': await getAnonymousId(),
      };
    } catch (e) {
      WasteAppLogger.severe('Error getting consent metadata', e, null, {
        'service': 'AnalyticsConsentManager'
      });
      return {
        'consent_version': 0,
        'consent_timestamp': null,
        'consent_status': {
          essentialConsent: true,
          analyticsConsent: false,
          performanceConsent: false,
          marketingConsent: false,
        },
        'anonymous_id': await getAnonymousId(),
      };
    }
  }

  /// Check if event should be tracked based on consent and event type
  Future<bool> shouldTrackEvent(String eventType) async {
    try {
      switch (eventType) {
        case 'essential':
        case 'session':
        case 'error':
          return await hasEssentialConsent();
        
        case 'analytics':
        case 'user_action':
        case 'screen_view':
        case 'classification':
        case 'gamification':
          return await hasAnalyticsConsent();
        
        case 'performance':
        case 'slow_resource':
        case 'api_error':
          return await hasPerformanceConsent();
        
        case 'marketing':
        case 'social':
          return await hasMarketingConsent();
        
        default:
          // Default to analytics consent for unknown types
          return await hasAnalyticsConsent();
      }
    } catch (e) {
      WasteAppLogger.severe('Error checking event tracking permission', e, null, {
        'event_type': eventType,
        'service': 'AnalyticsConsentManager'
      });
      return false; // Default to not tracking on error
    }
  }
} 