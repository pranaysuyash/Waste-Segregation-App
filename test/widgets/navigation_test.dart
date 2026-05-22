import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/services/instant_analysis_flow_coordinator.dart';
import 'package:waste_segregation_app/models/classification_state.dart';

void main() {
  group('InstantAnalysisScreen navigation contract', () {
    test('success flow advances stages and navigates once', () async {
      final coordinator = InstantAnalysisFlowCoordinator(
        localRulesDelay: Duration.zero,
        successDelay: Duration.zero,
      );
      final stages = <ClassificationState>[];
      var navigateCount = 0;

      await coordinator.completeSuccessFlow(
        classification: WasteClassification(
          id: 'test-classification',
          itemName: 'Test Item',
          category: 'Dry Waste',
          explanation: 'Test',
          disposalInstructions: DisposalInstructions(
            primaryMethod: 'Recycle',
            steps: const ['Rinse'],
            hasUrgentTimeframe: false,
          ),
          region: 'Test Region',
          visualFeatures: const [],
          alternatives: const [],
          confidence: 0.95,
          timestamp: DateTime(2026, 5, 21),
        ),
        setStage: stages.add,
        navigateToResult: (_) async {
          navigateCount += 1;
        },
        isMounted: () => true,
        isCancelled: () => false,
        delay: (_) async {},
      );

      expect(stages, <ClassificationState>[
        ClassificationState.policyApplied,
        ClassificationState.classificationSucceeded,
      ]);
      expect(navigateCount, 1);
    });
  });
}
