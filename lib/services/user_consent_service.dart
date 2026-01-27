import 'package:shared_preferences/shared_preferences.dart';

class UserConsentAuditEntry {
  UserConsentAuditEntry(
      {required this.timestamp,
      required this.consentType,
      required this.value});

  final DateTime timestamp;
  final String consentType;
  final bool value;
}

class UserConsentService {
  UserConsentService([SharedPreferences? prefs]) : _prefs = prefs;

  SharedPreferences? _prefs;

  // Consent keys
  static const _analyticsKey = 'analytics_consent';
  static const _marketingKey = 'marketing_consent';
  static const _functionalKey = 'functional_consent';
  static const _dataProcessingKey = 'data_processing_consent';

  // Timestamp / audit keys
  static const _consentTimestampKey = 'consent_timestamp';
  static const _dataDeletionKey = 'data_deletion_request_timestamp';
  static const _dataExportKey = 'data_export_request_timestamp';
  static const _auditTrailKey = 'consent_audit_trail';

  // Cookie keys
  static const _essentialCookiesKey = 'essential_cookies_consent';
  static const _performanceCookiesKey = 'performance_cookies_consent';
  static const _advertisingCookiesKey = 'advertising_cookies_consent';

  // Third-party keys
  static const _googleAnalyticsKey = 'google_analytics_consent';
  static const _firebaseKey = 'firebase_consent';
  static const _crashReportingKey = 'crash_reporting_consent';

  // Banner keys
  static const _bannerDismissedKey = 'consent_banner_dismissed';

  // Region keys
  static const _userRegionKey = 'user_region';

  // Privacy / TOS keys
  static const _privacyPolicyConsentKey = 'privacy_policy_consent';
  static const _termsOfServiceConsentKey = 'terms_of_service_consent';
  static const _privacyPolicyVersionKey = 'privacy_policy_version';
  static const _termsOfServiceVersionKey = 'terms_of_service_version';
  static const currentPrivacyPolicyVersion = '1.0.0';
  static const currentTermsOfServiceVersion = '1.0.0';

  //  Helpers
  // NOTE: _preferences getter will throw if _prefs is null.
  // Always inject SharedPreferences via constructor or call initialize() first.
  SharedPreferences get _preferences {
    if (_prefs == null) {
      throw StateError(
        'UserConsentService requires SharedPreferences to be injected via constructor '
        'or initialize() must be called first. '
        'Use: UserConsentService(await SharedPreferences.getInstance())',
      );
    }
    return _prefs!;
  }

  /// Initialize the service by loading SharedPreferences asynchronously.
  /// Call this if SharedPreferences was not injected via the constructor.
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> _ensureInitialized() async {
    if (_prefs != null) return;
    await initialize();
  }

  // Synchronous getters rely on injected prefs; tests inject mocks so no async needed.
  bool _getBool(String key) {
    try {
      return _preferences.getBool(key) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _setBool(String key, bool value) async {
    try {
      await _ensureInitialized();
      await _preferences.setBool(key, value);
    } catch (_) {}
  }

  String? _getString(String key) {
    try {
      return _preferences.getString(key);
    } catch (_) {
      return null;
    }
  }

  Future<void> _setString(String key, String value) async {
    try {
      await _ensureInitialized();
      await _preferences.setString(key, value);
    } catch (_) {}
  }

  List<String>? _getStringList(String key) {
    try {
      return _preferences.getStringList(key);
    } catch (_) {
      return null;
    }
  }

  Future<void> _setStringList(String key, List<String> value) async {
    try {
      await _ensureInitialized();
      await _preferences.setStringList(key, value);
    } catch (_) {}
  }

  // Consent booleans
  bool get hasAnalyticsConsent => _getBool(_analyticsKey);
  bool get hasMarketingConsent => _getBool(_marketingKey);
  bool get hasFunctionalConsent => _getBool(_functionalKey);
  bool get hasDataProcessingConsent => _getBool(_dataProcessingKey);

  Future<void> setAnalyticsConsent(bool value) =>
      _setBool(_analyticsKey, value);
  Future<void> setMarketingConsent(bool value) =>
      _setBool(_marketingKey, value);
  Future<void> setFunctionalConsent(bool value) =>
      _setBool(_functionalKey, value);
  Future<void> setDataProcessingConsent(bool value) =>
      _setBool(_dataProcessingKey, value);

  bool get hasNecessaryConsents =>
      hasAnalyticsConsent && hasFunctionalConsent && hasDataProcessingConsent;
  bool get hasAllConsents => hasNecessaryConsents && hasMarketingConsent;

  Future<void> revokeAllConsents() async {
    await Future.wait([
      setAnalyticsConsent(false),
      setMarketingConsent(false),
      setFunctionalConsent(false),
      setDataProcessingConsent(false),
    ]);
  }

  // Timestamp management
  Future<void> setConsentTimestamp(DateTime timestamp) =>
      _setString(_consentTimestampKey, timestamp.toIso8601String());

  DateTime? get consentTimestamp {
    final ts = _getString(_consentTimestampKey);
    if (ts == null) return null;
    return DateTime.tryParse(ts);
  }

  bool get isConsentExpired {
    final ts = consentTimestamp;
    if (ts == null) return true;
    return DateTime.now().difference(ts).inDays >= 365;
  }

  bool get needsConsentRenewal {
    final ts = consentTimestamp;
    if (ts == null) return true;
    return DateTime.now().difference(ts).inDays >= 330;
  }

  // Data subject rights
  bool get canRequestDataDeletion => hasDataProcessingConsent;
  bool get canRequestDataExport => hasDataProcessingConsent;

  Future<void> recordDataDeletionRequest(DateTime timestamp) =>
      _setString(_dataDeletionKey, timestamp.toIso8601String());

  Future<void> recordDataExportRequest(DateTime timestamp) =>
      _setString(_dataExportKey, timestamp.toIso8601String());

  DateTime? get dataDeletionRequestTimestamp {
    final ts = _getString(_dataDeletionKey);
    return ts == null ? null : DateTime.tryParse(ts);
  }

  DateTime? get dataExportRequestTimestamp {
    final ts = _getString(_dataExportKey);
    return ts == null ? null : DateTime.tryParse(ts);
  }

  // Cookies
  Future<void> setEssentialCookiesConsent(bool value) =>
      _setBool(_essentialCookiesKey, value);
  Future<void> setPerformanceCookiesConsent(bool value) =>
      _setBool(_performanceCookiesKey, value);
  Future<void> setAdvertisingCookiesConsent(bool value) =>
      _setBool(_advertisingCookiesKey, value);

  bool get hasEssentialCookiesConsent => _getBool(_essentialCookiesKey);
  bool get hasPerformanceCookiesConsent => _getBool(_performanceCookiesKey);
  bool get hasAdvertisingCookiesConsent => _getBool(_advertisingCookiesKey);

  // Third-party consents
  Future<void> setGoogleAnalyticsConsent(bool value) =>
      _setBool(_googleAnalyticsKey, value);
  Future<void> setFirebaseConsent(bool value) => _setBool(_firebaseKey, value);
  Future<void> setCrashReportingConsent(bool value) =>
      _setBool(_crashReportingKey, value);

  bool get hasGoogleAnalyticsConsent => _getBool(_googleAnalyticsKey);
  bool get hasFirebaseConsent => _getBool(_firebaseKey);
  bool get hasCrashReportingConsent => _getBool(_crashReportingKey);

  // Banner management
  bool get shouldShowConsentBanner =>
      !hasNecessaryConsents && !_getBool(_bannerDismissedKey);
  Future<void> dismissConsentBanner() => _setBool(_bannerDismissedKey, true);
  bool get isConsentBannerDismissed => _getBool(_bannerDismissedKey);

  // Audit trail
  Future<void> recordConsentChange(
      String consentType, bool value, DateTime timestamp) async {
    final existing = _getStringList(_auditTrailKey) ?? <String>[];
    final updated = [
      ...existing,
      '${timestamp.toIso8601String()}|$consentType|$value'
    ];
    // Limit size to 100
    final limited =
        updated.length > 100 ? updated.sublist(updated.length - 100) : updated;
    await _setStringList(_auditTrailKey, limited);
  }

  List<UserConsentAuditEntry> get consentAuditTrail {
    final raw = _getStringList(_auditTrailKey) ?? <String>[];
    final entries = <UserConsentAuditEntry>[];

    for (final entry in raw) {
      final parts = entry.split('|');
      if (parts.length != 3) continue;
      final ts = DateTime.tryParse(parts[0]);
      if (ts == null) continue;
      final val = parts[2].toLowerCase() == 'true';
      entries.add(UserConsentAuditEntry(
          timestamp: ts, consentType: parts[1], value: val));
    }

    return entries;
  }

  // Region handling
  Future<void> setUserRegion(String region) =>
      _setString(_userRegionKey, region);
  String get userRegion => _getString(_userRegionKey) ?? '';
  bool get isGDPRApplicable => userRegion.toUpperCase() == 'EU';
  bool get isCCPAApplicable => userRegion.toUpperCase() == 'US';

  List<String> get requiredConsentsForRegion {
    if (isGDPRApplicable) {
      return ['analytics', 'marketing', 'functional', 'data_processing'];
    }
    if (isCCPAApplicable) {
      return ['data_processing'];
    }
    return ['functional'];
  }

  // Privacy/TOS tracking
  Future<void> recordPrivacyPolicyConsent() async {
    await _setBool(_privacyPolicyConsentKey, true);
    await _setString(_privacyPolicyVersionKey, currentPrivacyPolicyVersion);
  }

  Future<void> recordTermsOfServiceConsent() async {
    await _setBool(_termsOfServiceConsentKey, true);
    await _setString(_termsOfServiceVersionKey, currentTermsOfServiceVersion);
  }

  Future<void> recordAllConsents() async {
    await Future.wait([
      recordPrivacyPolicyConsent(),
      recordTermsOfServiceConsent(),
      setAnalyticsConsent(true),
      setFunctionalConsent(true),
      setDataProcessingConsent(true),
    ]);
  }

  bool get hasPrivacyPolicyConsent => _getBool(_privacyPolicyConsentKey);
  bool get hasTermsOfServiceConsent => _getBool(_termsOfServiceConsentKey);

  bool get needsReconsent {
    try {
      final savedPrivacyVersion = _getString(_privacyPolicyVersionKey) ?? '';
      final savedTermsVersion = _getString(_termsOfServiceVersionKey) ?? '';
      return savedPrivacyVersion != currentPrivacyPolicyVersion ||
          savedTermsVersion != currentTermsOfServiceVersion;
    } catch (_) {
      return true;
    }
  }

  bool get hasAllRequiredConsents {
    try {
      return hasPrivacyPolicyConsent &&
          hasTermsOfServiceConsent &&
          !needsReconsent;
    } catch (_) {
      return false;
    }
  }

  // Export minimal consent data
  Map<String, dynamic> exportConsentData() {
    return {
      'analytics_consent': hasAnalyticsConsent,
      'marketing_consent': hasMarketingConsent,
      'functional_consent': hasFunctionalConsent,
      'data_processing_consent': hasDataProcessingConsent,
      'consent_timestamp': consentTimestamp?.toIso8601String(),
    };
  }
}
