import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/scan_orchestrator.dart';
import '../services/result_pipeline.dart';
import 'app_providers.dart';

/// Canonical scan composition for foreground and background classification.
final scanOrchestratorProvider = Provider<ScanOrchestrator>((ref) {
  return ScanOrchestrator(
    aiService: ref.read(aiServiceProvider),
    resultPipeline: ref.read(resultPipelineProvider.notifier),
  );
});
