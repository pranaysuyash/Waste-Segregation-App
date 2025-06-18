import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/remote_config_service.dart';

/// Provider for the results v2 feature flag
final resultsV2EnabledProvider = FutureProvider<bool>((ref) async {
  final remoteConfig = RemoteConfigService();
  return await remoteConfig.getBool('results_v2_enabled', defaultValue: false);
});

/// Provider for home header v2 feature flag (existing)
final homeHeaderV2EnabledProvider = FutureProvider<bool>((ref) async {
  final remoteConfig = RemoteConfigService();
  return await remoteConfig.getBool('home_header_v2_enabled', defaultValue: true);
});

/// Provider for accessibility enhancements
final accessibilityEnhancedProvider = FutureProvider<bool>((ref) async {
  final remoteConfig = RemoteConfigService();
  return await remoteConfig.getBool('accessibility_enhanced', defaultValue: true);
});

/// Provider for micro animations
final microAnimationsEnabledProvider = FutureProvider<bool>((ref) async {
  final remoteConfig = RemoteConfigService();
  return await remoteConfig.getBool('micro_animations_enabled', defaultValue: true);
});

/// Provider for golden test mode
final goldenTestModeProvider = FutureProvider<bool>((ref) async {
  final remoteConfig = RemoteConfigService();
  return await remoteConfig.getBool('golden_test_mode', defaultValue: false);
}); 