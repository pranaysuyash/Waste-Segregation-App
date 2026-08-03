import 'package:flutter/foundation.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import '../utils/waste_app_logger.dart';

/// Storefront/payment-rail eligibility — determines which payment options
/// to show based on platform, store programme enrolment, and remote config.
///
/// COMMIT-7: This service enforces store compliance:
/// - iOS: Apple requires IAP for digital functionality (no external checkout)
/// - Android: Google Play alternative billing requires programme enrolment
/// - Web: External checkout always available
///
/// The server catalogue's `eligiblePlatforms` field is the authoritative
/// source for product-level eligibility. This service provides client-side
/// platform-level gating for UI rendering.
class StorefrontEligibilityService {
  StorefrontEligibilityService({FirebaseRemoteConfig? remoteConfig})
      : _remoteConfig = remoteConfig;

  /// Lazily resolved so construction never touches Firebase (test-safe).
  /// Never throws: returns null when Remote Config is unavailable, and the
  /// boolean getters below treat null as their documented fail-open default.
  /// This makes the fail-open property structural rather than depending on
  /// every call site remembering to wrap in try/catch.
  FirebaseRemoteConfig? _remoteConfig;
  FirebaseRemoteConfig? get _rc {
    if (_remoteConfig == null) {
      try {
        _remoteConfig = FirebaseRemoteConfig.instance;
      } catch (_) {
        return null; // Firebase not initialized (e.g. widget tests) — fail open.
      }
    }
    return _remoteConfig;
  }

  /// Whether external checkout (DodoPayments web checkout) is available
  /// on the current platform.
  bool get isExternalCheckoutAvailable {
    if (_isKillSwitchEnabled) return false;

    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        // Apple requires IAP for digital functionality. External checkout
        // is never available on iOS unless Apple grants a specific entitlement.
        return _isIosExternalCheckoutEntitled;
      case TargetPlatform.android:
        // Google Play alternative billing requires programme enrolment.
        // Show external checkout only if the user's device is enrolled.
        return _isAndroidAlternativeBillingEnrolled;
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        // Desktop platforms: external checkout available via web.
        return true;
      case TargetPlatform.fuchsia:
        return false;
    }
  }

  /// Whether in-app purchase (IAP) is available on the current platform.
  bool get isIapAvailable {
    if (_isKillSwitchEnabled) return false;

    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return true; // IAP is required on iOS
      case TargetPlatform.android:
        return true; // IAP is always available on Android
      case TargetPlatform.macOS:
        return true; // IAP available on macOS
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return false;
    }
  }

  /// Whether both payment rails are available (shows divider + "or").
  bool get showDualPaymentRails =>
      isExternalCheckoutAvailable && isIapAvailable;

  /// Human-readable label for the primary payment rail on this platform.
  String get primaryPaymentLabel {
    if (isIapAvailable) return 'App Store';
    if (isExternalCheckoutAvailable) return 'Card / UPI';
    return 'Premium';
  }

  // --- Remote config flags ---

  /// Kill switch: remotely disable all payment rails.
  /// Use this if a payment provider is compromised or store policy changes.
  bool get _isKillSwitchEnabled {
    try {
      return _rc?.getBool('storefront_kill_switch') ?? false;
    } catch (e) {
      // Remote config not available — default to enabled (fail open for UX)
      return false;
    }
  }

  /// iOS external checkout entitlement.
  ///
  /// Apple permits external purchase links only under specific storefront
  /// and entitlement rules. This flag is set to true only when the app
  /// has been granted the relevant Apple entitlement.
  ///
  /// Default: false (Apple requires IAP by default).
  bool get _isIosExternalCheckoutEntitled {
    try {
      return _rc?.getBool('ios_external_checkout_entitled') ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Android alternative billing programme enrolment.
  ///
  /// Google Play's India alternative billing programme requires:
  /// 1. Programme enrolment in Play Console
  /// 2. User-choice billing UX
  /// 3. Transaction reporting to Google
  /// 4. Continued service fees
  ///
  /// This flag is true only when the app is enrolled and compliant.
  /// See: https://support.google.com/googleplay/android-developer/answer/13306652
  ///
  /// Default: false (require explicit enrolment).
  bool get _isAndroidAlternativeBillingEnrolled {
    try {
      return _rc?.getBool('android_alternative_billing_enrolled') ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Log eligibility state for diagnostics (no PII).
  void logEligibilityState() {
    WasteAppLogger.info('Storefront eligibility state', context: {
      'platform': defaultTargetPlatform.name,
      'external_checkout': isExternalCheckoutAvailable,
      'iap': isIapAvailable,
      'dual_rails': showDualPaymentRails,
      'kill_switch': _isKillSwitchEnabled,
      'ios_entitled': _isIosExternalCheckoutEntitled,
      'android_enrolled': _isAndroidAlternativeBillingEnrolled,
    });
  }
}
