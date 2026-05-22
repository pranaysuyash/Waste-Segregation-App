import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/offline_degradation_tier.dart';
import '../services/offline_classification_service.dart';
import 'classification_pipeline_providers.dart';

final offlineClassificationServiceProvider =
    Provider<OfflineClassificationService>((ref) {
  final pipeline = ref.read(classificationPipelineProvider);
  return OfflineClassificationService(pipeline: pipeline);
});

/// Current degradation tier based on local model availability.
final offlineDegradationTierProvider = Provider<OfflineDegradationTier>((ref) {
  final service = ref.read(offlineClassificationServiceProvider);
  return service.determineTier();
});
