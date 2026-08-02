import 'package:waste_segregation_app/services/local_guidelines_plugin.dart';
import 'package:waste_segregation_app/services/user_consent_service.dart';

/// Canonical service for resolving and persisting user-selected regions.
class RegionResolutionService {
  const RegionResolutionService();

  /// Fallback region used when no explicit region preference exists yet.
  static const String fallbackRegion = 'Bangalore, IN';

  /// Returns a canonical plugin-backed region value when possible.
  ///
  /// If [requestedRegion] is empty, returns [fallbackRegion].
  /// If the value can be matched to a plugin alias/ID, returns the plugin region.
  /// Otherwise returns the trimmed string as-is.
  String resolveCanonicalRegion(String? requestedRegion) {
    final normalized = requestedRegion?.trim() ?? '';
    if (normalized.isEmpty) return fallbackRegion;

    LocalGuidelinesManager.initializeDefaultPlugins();
    final plugin = LocalGuidelinesManager.getPluginForRegion(normalized);
    if (plugin != null) return plugin.region;
    return normalized;
  }
}

/// Wrapper service around [UserConsentService] user_region persistence.
class RegionPreferenceService {
  RegionPreferenceService(
    this._userConsentService, {
    RegionResolutionService? regionResolutionService,
  }) : _regionResolutionService =
          regionResolutionService ?? const RegionResolutionService();

  final UserConsentService _userConsentService;
  final RegionResolutionService _regionResolutionService;

  /// Returns the currently stored region or the default canonical fallback.
  String get resolvedHomeRegion {
    return _regionResolutionService.resolveCanonicalRegion(
      _userConsentService.userRegion,
    );
  }

  /// Resolves a selected or persisted region value.
  String resolve(String? region) {
    return _regionResolutionService.resolveCanonicalRegion(region);
  }

  /// Persists a canonicalized region for future scans and settings screens.
  Future<void> persistHomeRegion(String region) async {
    final canonical = resolve(region);
    await _userConsentService.setUserRegion(canonical);
  }
}

