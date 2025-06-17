import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import 'home_header.dart';

/// A/B testing wrapper for HomeHeader
/// Uses Remote Config to control which version of the header to show
class HomeHeaderWrapper extends ConsumerWidget {
  const HomeHeaderWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeHeaderV2Enabled = ref.watch(homeHeaderV2EnabledProvider);
    
    return homeHeaderV2Enabled.when(
      data: (isEnabled) {
        if (isEnabled) {
          // Show new HomeHeader v2
          return const HomeHeader();
        } else {
          // Show legacy header (fallback)
          return _buildLegacyHeader(context);
        }
      },
      loading: () => const HomeHeader(), // Default to new header while loading
      error: (_, __) => const HomeHeader(), // Default to new header on error
    );
  }

  /// Legacy header fallback for A/B testing
  Widget _buildLegacyHeader(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ready to make a difference today?',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Analytics helper for A/B testing
class HomeHeaderAnalytics {
  static const String _headerV2ViewEvent = 'home_header_v2_viewed';
  static const String _headerV2InteractionEvent = 'home_header_v2_interaction';
  static const String _headerLegacyViewEvent = 'home_header_legacy_viewed';

  /// Track when HomeHeader v2 is viewed
  static void trackHeaderV2View() {
    // TODO: Integrate with your analytics service
    // AnalyticsService.logEvent(_headerV2ViewEvent);
  }

  /// Track interactions with HomeHeader v2
  static void trackHeaderV2Interaction(String interaction) {
    // TODO: Integrate with your analytics service
    // AnalyticsService.logEvent(_headerV2InteractionEvent, {
    //   'interaction_type': interaction,
    // });
  }

  /// Track when legacy header is viewed
  static void trackLegacyHeaderView() {
    // TODO: Integrate with your analytics service
    // AnalyticsService.logEvent(_headerLegacyViewEvent);
  }
}

/// Remote Config keys for A/B testing
class HomeHeaderRemoteConfigKeys {
  static const String homeHeaderV2Enabled = 'home_header_v2_enabled';
  static const String homeHeaderV2RolloutPercentage = 'home_header_v2_rollout_percentage';
  static const String homeHeaderV2TargetAudience = 'home_header_v2_target_audience';
  
  /// Default values for remote config
  static const Map<String, dynamic> defaults = {
    homeHeaderV2Enabled: true,
    homeHeaderV2RolloutPercentage: 100,
    homeHeaderV2TargetAudience: 'all',
  };
} 