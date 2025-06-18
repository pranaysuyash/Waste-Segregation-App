import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/remote_config_service.dart';

// Base provider for remote config service
final _remoteConfigServiceProvider = Provider<RemoteConfigService>((ref) {
  return RemoteConfigService();
});

/// Comprehensive feature flags provider that returns all flags as a map
final featureFlagsProvider = FutureProvider<Map<String, bool>>((ref) async {
  final remoteConfig = ref.read(_remoteConfigServiceProvider);
  
  return {
    'results_v2_enabled': await remoteConfig.getBool('results_v2_enabled'),
    'home_header_v2_enabled': await remoteConfig.getBool('home_header_v2_enabled'), 
    'accessibility_enhanced': await remoteConfig.getBool('accessibility_enhanced'),
    'micro_animations_enabled': await remoteConfig.getBool('micro_animations_enabled'),
    'golden_test_mode': await remoteConfig.getBool('golden_test_mode'),
  };
});

// Individual feature flag providers for convenience
/// Provider for the Result Screen V2 feature flag
final resultScreenV2FeatureFlagProvider = FutureProvider<bool>((ref) async {
  final flags = await ref.watch(featureFlagsProvider.future);
  return flags['results_v2_enabled'] ?? false;
});

/// Provider for the Home Header V2 feature flag
final homeHeaderV2FeatureFlagProvider = FutureProvider<bool>((ref) async {
  final flags = await ref.watch(featureFlagsProvider.future);
  return flags['home_header_v2_enabled'] ?? false;
});

/// Provider for accessibility enhancements feature flag
final accessibilityEnhancedFeatureFlagProvider = FutureProvider<bool>((ref) async {
  final flags = await ref.watch(featureFlagsProvider.future);
  return flags['accessibility_enhanced'] ?? false;
});

/// Provider for micro animations feature flag
final microAnimationsFeatureFlagProvider = FutureProvider<bool>((ref) async {
  final flags = await ref.watch(featureFlagsProvider.future);
  return flags['micro_animations_enabled'] ?? false;
});

/// Provider for golden test mode feature flag
final goldenTestModeFeatureFlagProvider = FutureProvider<bool>((ref) async {
  final flags = await ref.watch(featureFlagsProvider.future);
  return flags['golden_test_mode'] ?? false;
});

// Legacy providers for backward compatibility (deprecated)
@Deprecated('Use resultScreenV2FeatureFlagProvider instead')
final resultsV2EnabledProvider = resultScreenV2FeatureFlagProvider;

@Deprecated('Use homeHeaderV2FeatureFlagProvider instead')
final homeHeaderV2EnabledProvider = homeHeaderV2FeatureFlagProvider;

@Deprecated('Use accessibilityEnhancedFeatureFlagProvider instead')
final accessibilityEnhancedProvider = accessibilityEnhancedFeatureFlagProvider;

@Deprecated('Use microAnimationsFeatureFlagProvider instead')
final microAnimationsEnabledProvider = microAnimationsFeatureFlagProvider;

@Deprecated('Use goldenTestModeFeatureFlagProvider instead')
final goldenTestModeProvider = goldenTestModeFeatureFlagProvider; 