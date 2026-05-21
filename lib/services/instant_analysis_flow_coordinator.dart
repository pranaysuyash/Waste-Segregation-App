import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/widgets/analysis_progress_view.dart';

typedef InstantAnalysisDelay = Future<void> Function(Duration duration);
typedef InstantAnalysisStageSetter = void Function(
  AnalysisProgressStage stage,
);
typedef InstantAnalysisNavigationCallback = Future<void> Function(
  WasteClassification classification,
);
typedef InstantAnalysisStateChecker = bool Function();

class InstantAnalysisFlowCoordinator {
  const InstantAnalysisFlowCoordinator({
    this.localRulesDelay = const Duration(milliseconds: 320),
    this.successDelay = const Duration(milliseconds: 280),
  });

  final Duration localRulesDelay;
  final Duration successDelay;

  Future<void> completeSuccessFlow({
    required WasteClassification classification,
    required InstantAnalysisStageSetter setStage,
    required InstantAnalysisNavigationCallback navigateToResult,
    required InstantAnalysisStateChecker isMounted,
    required InstantAnalysisStateChecker isCancelled,
    InstantAnalysisDelay delay = Future<void>.delayed,
  }) async {
    if (isCancelled() || !isMounted()) return;

    setStage(AnalysisProgressStage.applyingLocalRules);
    await delay(localRulesDelay);
    if (isCancelled() || !isMounted()) return;

    setStage(AnalysisProgressStage.success);
    await delay(successDelay);
    if (isCancelled() || !isMounted()) return;

    await navigateToResult(classification);
  }
}
