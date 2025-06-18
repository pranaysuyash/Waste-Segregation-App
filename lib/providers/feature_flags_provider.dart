import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/remote_config_service.dart';

/// Provider for the results v2 feature flag
final resultsV2EnabledProvider = FutureProvider<bool>((ref) async {
  final remoteConfig = RemoteConfigService();
  return remoteConfig.getBool('results_v2_enabled');
});

/// Provider for home header v2 feature flag (existing)
final homeHeaderV2EnabledProvider = FutureProvider<bool>((ref) async {
  final remoteConfig = RemoteConfigService();
  return remoteConfig.getBool('home_header_v2_enabled');
});

/// Provider for accessibility enhancements
final accessibilityEnhancedProvider = FutureProvider<bool>((ref) async {
  final remoteConfig = RemoteConfigService();
  return remoteConfig.getBool('accessibility_enhanced');
});

/// Provider for micro animations
final microAnimationsEnabledProvider = FutureProvider<bool>((ref) async {
  final remoteConfig = RemoteConfigService();
  return remoteConfig.getBool('micro_animations_enabled');
});

/// Provider for golden test mode
final goldenTestModeProvider = FutureProvider<bool>((ref) async {
  final remoteConfig = RemoteConfigService();
  return remoteConfig.getBool('golden_test_mode');
}); 