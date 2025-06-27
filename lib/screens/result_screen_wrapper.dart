import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/waste_classification.dart';
import '../providers/feature_flags_provider.dart';
import '../utils/waste_app_logger.dart';
import 'result_screen.dart';
import 'result_screen_v2.dart';

/// ResultScreenWrapper handles feature flag conditional rendering
///
/// Routes to either:
/// - ResultScreenV2 (new composable UI) when results_v2_enabled = true
/// - ResultScreen (legacy monolith) when results_v2_enabled = false
///
/// This enables safe A/B testing and gradual rollout of the new UI
class ResultScreenWrapper extends ConsumerWidget {
  const ResultScreenWrapper({
    super.key,
    required this.classification,
    this.showActions = true,
    this.autoAnalyze = false,
    this.heroTag,
  });

  final WasteClassification classification;
  final bool showActions;
  final bool autoAnalyze;
  final String? heroTag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featureFlagAsync = ref.watch(resultScreenV2FeatureFlagProvider);

    return featureFlagAsync.when(
      data: (useV2) {
        // Log which version is being used for analytics
        WasteAppLogger.info('Result screen version selected', null, null, {
          'version': useV2 ? 'v2' : 'legacy',
          'classificationId': classification.id,
          'autoAnalyze': autoAnalyze,
          'service': 'ResultScreenWrapper',
        });

        if (useV2) {
          return ResultScreenV2(
            classification: classification,
            showActions: showActions,
            autoAnalyze: autoAnalyze,
            heroTag: heroTag,
          );
        } else {
          return ResultScreen(
            classification: classification,
            showActions: showActions,
            autoAnalyze: autoAnalyze,
          );
        }
      },
      loading: () {
        // While loading feature flags, show a minimal loading screen
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
      error: (error, stackTrace) {
        // On error loading feature flags, default to legacy screen
        WasteAppLogger.warning('Feature flags failed to load, defaulting to legacy', error, stackTrace, {
          'classificationId': classification.id,
          'service': 'ResultScreenWrapper',
        });

        return ResultScreen(
          classification: classification,
          showActions: showActions,
          autoAnalyze: autoAnalyze,
        );
      },
    );
  }
}
