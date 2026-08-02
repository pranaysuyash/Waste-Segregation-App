import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:waste_segregation_app/services/region_preference_service.dart';
import 'app_providers.dart';

/// Region resolution strategy service.
final regionResolutionServiceProvider =
    Provider<RegionResolutionService>((_) => const RegionResolutionService());

/// Region preference persistence service.
final regionPreferenceServiceProvider =
    Provider<RegionPreferenceService>((ref) {
  return RegionPreferenceService(
    ref.watch(userConsentServiceProvider),
    regionResolutionService: ref.watch(regionResolutionServiceProvider),
  );
});

/// Canonical reactive home-region value for analysis and rules.
final regionPreferenceProvider = StateNotifierProvider<RegionPreferenceNotifier, String>(
  (ref) => RegionPreferenceNotifier(
    ref.watch(regionPreferenceServiceProvider),
  ),
);

class RegionPreferenceNotifier extends StateNotifier<String> {
  RegionPreferenceNotifier(this._regionPreferenceService)
      : super(_regionPreferenceService.resolvedHomeRegion);

  final RegionPreferenceService _regionPreferenceService;

  /// Updates in-memory state and persists canonicalized region.
  Future<void> setRegion(String region) async {
    final canonical = _regionPreferenceService.resolve(region);
    if (canonical == state) return;
    state = canonical;
    await _regionPreferenceService.persistHomeRegion(canonical);
  }

  /// Returns resolved region using the same logic as analyzer paths.
  String resolve(String? region) =>
      _regionPreferenceService.resolve(region);
}

