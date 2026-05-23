import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/classification_pipeline.dart';
import '../services/classification_router.dart';
import '../services/local_classifier_service.dart';
import 'layer0_providers.dart';
import 'cost_management_providers.dart';

/// Provides the currently available [LocalClassifier] implementation.
///
/// Returns a model that reports [LocalClassifier.isModelLoaded] as `false`
/// until a real on-device model is wired (Phase C). This ensures the
/// pipeline gracefully falls through to cloud classification.
///
/// Replace this provider with `TfliteLocalClassifier` once real inference
/// is implemented.
final localClassifierProvider = Provider<LocalClassifier>((ref) {
  return FakeLocalClassifier(isModelLoaded: false);
});

/// Resolves the routing strategy from remote config.
///
/// Falls back to `balanced` if remote config is unavailable.
final routingStrategyProvider = FutureProvider<RoutingStrategy>((ref) async {
  final remoteConfig = ref.read(remoteConfigServiceProvider);
  final strategyName = await remoteConfig.getClassificationRoutingStrategy();
  return RoutingStrategy.values.firstWhere(
    (s) => s.name == strategyName,
    orElse: () => RoutingStrategy.balanced,
  );
});

/// Provides the [ClassificationPipeline] that orchestrates
/// Layer 0 → Layer 1 → Cloud classification.
///
/// Uses the routing strategy from remote config when available,
/// otherwise defaults to balanced.
final classificationPipelineProvider = Provider<ClassificationPipeline>((ref) {
  final layer0Router = ref.read(layer0RouterProvider);
  final localClassifier = ref.read(localClassifierProvider);
  final strategyAsync = ref.watch(routingStrategyProvider);

  final strategy = strategyAsync.when(
    data: (s) => s,
    loading: () => RoutingStrategy.balanced,
    error: (_, __) => RoutingStrategy.balanced,
  );

  return ClassificationPipeline(
    layer0Router: layer0Router,
    localClassifier: localClassifier,
    router: ClassificationRouter(strategy: strategy),
  );
});

/// Whether Layer 1 (on-device ML) should be attempted.
///
/// Controlled by remote config so it can be rolled out gradually.
final layer1EnabledProvider = FutureProvider<bool>((ref) async {
  final remoteConfig = ref.read(remoteConfigServiceProvider);
  await remoteConfig.initialize();
  return remoteConfig.getBool('layer1_enabled');
});
