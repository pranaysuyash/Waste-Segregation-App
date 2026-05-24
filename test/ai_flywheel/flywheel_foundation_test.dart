import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/ai_flywheel/dataset_exporter.dart';
import 'package:waste_segregation_app/ai_flywheel/eval_models.dart';
import 'package:waste_segregation_app/ai_flywheel/eval_runner.dart';
import 'package:waste_segregation_app/ai_flywheel/eval_scoring.dart';
import 'package:waste_segregation_app/ai_flywheel/provider_quality_gate.dart';
import 'package:waste_segregation_app/ai_flywheel/router_metrics.dart';
import 'package:waste_segregation_app/ai_flywheel/router_policy_recommendations.dart';
import 'package:waste_segregation_app/ai_flywheel/training_candidate_policy.dart';
import 'package:waste_segregation_app/services/ai_router_policy_config.dart';
import 'package:waste_segregation_app/services/classification_router_guardrails.dart';
import 'package:waste_segregation_app/services/local_classifier_service.dart';

void main() {
  test('1. Eval schema validates good cases', () {
    final line = File('test/fixtures/ai_eval/golden_cases.jsonl').readAsLinesSync().first;
    final caseObj = EvalCase.fromJson(jsonDecode(line) as Map<String, dynamic>);
    expect(caseObj.id, isNotEmpty);
  });

  test('2. Eval schema rejects missing expected category', () {
    expect(
      () => EvalCase.fromJson(<String, dynamic>{
        'id': 'bad',
        'imageRef': 'x.jpg',
        'region': 'Bangalore, IN',
        'language': 'en',
        'expected': <String, dynamic>{},
        'mustNot': <String>[],
        'safetyCritical': false,
        'localRuleCritical': false,
      }),
      throwsFormatException,
    );
  });

  test('3. Must-not violation is counted as failure', () {
    final c = EvalCase.fromJson(<String, dynamic>{
      'id': 'x','imageRef': 'x','region': 'r','language': 'en',
      'expected': <String, dynamic>{'category': 'Wet Waste'},
      'mustNot': <String>['Dry Waste'],
      'safetyCritical': false,
      'localRuleCritical': true,
    });
    final p = EvalPrediction(caseId: 'x', category: 'Dry Waste', provider: 'backend', model: 'm', confidence: 0.9);
    final o = EvalScoring.scoreCase(c, p);
    expect(o.mustNotViolation, isTrue);
  });

  test('4. Safety-critical failure is scored separately', () {
    final c = EvalCase.fromJson(<String, dynamic>{
      'id': 'x','imageRef': 'x','region': 'r','language': 'en',
      'expected': <String, dynamic>{'category': 'Hazardous Waste'},
      'mustNot': <String>['Dry Waste'],
      'safetyCritical': true,
      'localRuleCritical': false,
    });
    final o = EvalScoring.scoreCase(c, const EvalPrediction(caseId: 'x', category: 'Dry Waste', provider: 'backend', model: 'm'));
    expect(o.safetyCriticalFailure, isTrue);
  });

  test('5. Acceptable alternative can pass non-strictly', () {
    final c = EvalCase.fromJson(<String, dynamic>{
      'id': 'x','imageRef': 'x','region': 'r','language': 'en',
      'expected': <String, dynamic>{'category': 'Wet Waste'},
      'acceptableAlternatives': <Map<String, dynamic>>[<String, dynamic>{'category': 'Reject Waste'}],
      'mustNot': <String>[],
      'safetyCritical': false,
      'localRuleCritical': false,
    });
    final o = EvalScoring.scoreCase(c, const EvalPrediction(caseId: 'x', category: 'Reject Waste', provider: 'backend', model: 'm'));
    expect(o.acceptableAlternativePass, isTrue);
  });

  test('6. Offline eval mode requires no API keys', () async {
    final summary = await EvalRunner(fixtureRoot: 'test/fixtures/ai_eval').run(mode: 'offline');
    expect(summary.cases, greaterThan(0));
  });

  test('7. Training candidate is not created when consent is false', () {
    expect(
      TrainingCandidatePolicy.shouldCreateCandidate(const TrainingConsentSnapshot(enabled: false, policyVersion: 'training-data-v1')),
      isFalse,
    );
  });

  test('8. Training candidate can be created when consent is true', () {
    expect(
      TrainingCandidatePolicy.shouldCreateCandidate(const TrainingConsentSnapshot(enabled: true, policyVersion: 'training-data-v1')),
      isTrue,
    );
  });

  test('9. Revoked/deleted/rejected candidates are excluded from export', () async {
    final lines = File('test/fixtures/ai_eval/recorded_outputs/training_candidates_sample.jsonl').readAsLinesSync();
    final raw = lines.map((l) => jsonDecode(l) as Map<String, dynamic>).toList();
    final outDir = Directory.systemTemp.createTempSync('dataset-export-test').path;
    final summary = await DatasetExporter().export(rawCandidates: raw, datasetVersion: 'waste-v0.1', outputDir: outDir);
    expect(summary.caseCount, 2);
    expect(File('$outDir/excluded.jsonl').existsSync(), isTrue);
  });

  test('10. User correction does not automatically become golden truth', () {
    expect(
      TrainingCandidatePolicy.exportEligible(
        const TrainingCandidateRecord(
          candidateId: 'x',
          reviewStatus: 'approved',
          consentEnabledAtCapture: true,
          policyVersion: 'training-data-v1',
          deletedAt: null,
          excludedFromTrainingAt: null,
          privacyStatus: 'pii_passed',
          hasVerifiedLabel: true,
        ),
      ),
      isFalse,
    );
  });

  test('11. Dataset export produces deterministic manifest order', () async {
    final raw = <Map<String, dynamic>>[
      <String, dynamic>{'candidateId': 'b', 'consent': <String, dynamic>{'enabledAtCapture': true,'policyVersion':'training-data-v1'}, 'review': <String, dynamic>{'status': 'training_eligible'}, 'reviewerVerified':<String,dynamic>{'reviewedAt':'2026-05-23T00:00:00Z','groundTruth':<String,dynamic>{'category':'Dry Waste'}}, 'image': <String, dynamic>{'redactionStatus': 'pii_passed'}},
      <String, dynamic>{'candidateId': 'a', 'consent': <String, dynamic>{'enabledAtCapture': true,'policyVersion':'training-data-v1'}, 'review': <String, dynamic>{'status': 'training_eligible'}, 'reviewerVerified':<String,dynamic>{'reviewedAt':'2026-05-23T00:00:00Z','groundTruth':<String,dynamic>{'category':'Dry Waste'}}, 'image': <String, dynamic>{'redactionStatus': 'pii_passed'}},
    ];
    final outDir = Directory.systemTemp.createTempSync('dataset-order-test').path;
    await DatasetExporter().export(rawCandidates: raw, datasetVersion: 'waste-v0.1', outputDir: outDir);
    final first = File('$outDir/manifest.jsonl').readAsLinesSync().first;
    expect(first.contains('"candidateId":"a"'), isTrue);
  });

  test('12. Router comparison handles fake backend/local/provider outputs', () {
    final result = RouterMetrics.compare(provider: 'backend', outcomes: <Map<String, dynamic>>[
      <String, dynamic>{'strictPass': true, 'acceptableAlternativePass': false, 'safetyCriticalFailure': false, 'mustNotViolation': false, 'localRuleFailure': false, 'multiItemFailure': false, 'overconfidentWrong': false, 'underconfidentCorrect': false, 'latencyMs': 1000, 'estimatedCostUsd': 0.001, 'cacheHit': true, 'fallbackUsed': false, 'providerFailure': false},
      <String, dynamic>{'strictPass': false, 'acceptableAlternativePass': false, 'safetyCriticalFailure': true, 'mustNotViolation': true, 'localRuleFailure': true, 'multiItemFailure': true, 'overconfidentWrong': true, 'underconfidentCorrect': false, 'latencyMs': 1200, 'estimatedCostUsd': 0.002, 'cacheHit': false, 'fallbackUsed': true, 'providerFailure': false},
    ]);
    expect(result.total, 2);
    expect(result.safetyCriticalFailures, 1);
    expect(result.multiItemFailures, 1);
  });

  test('13. Stale policy version excluded unless override', () {
    const record = TrainingCandidateRecord(
      candidateId: 'x',
      reviewStatus: 'training_eligible',
      consentEnabledAtCapture: true,
      policyVersion: 'training-data-v0',
      deletedAt: null,
      excludedFromTrainingAt: null,
      privacyStatus: 'pii_passed',
      hasVerifiedLabel: true,
    );
    expect(TrainingCandidatePolicy.exportEligible(record), isFalse);
    expect(
      TrainingCandidatePolicy.exportEligible(record, allowPolicyOverride: true),
      isTrue,
    );
  });

  test('14. Local router guardrails escalate safety unless high confidence', () {
    const guardrails = ClassificationRouterGuardrails();
    final low = LocalClassificationResult(
      category: 'E-Waste',
      confidence: 0.93,
      modelVersion: 'local-v2',
    );
    final high = LocalClassificationResult(
      category: 'E-Waste',
      confidence: 0.99,
      modelVersion: 'local-v2',
    );
    expect(guardrails.evaluateLocal(low).accepted, isFalse);
    expect(guardrails.evaluateLocal(high).accepted, isTrue);
  });

  test('15. Unknown region with local rule is policy overclaim', () {
    final c = EvalCase.fromJson(<String, dynamic>{
      'id': 'x',
      'imageRef': 'x',
      'region': 'unknown city',
      'language': 'en',
      'expected': <String, dynamic>{'category': 'Dry Waste'},
      'mustNot': <String>[],
      'safetyCritical': false,
      'localRuleCritical': false,
      'localRuleId': null,
    });
    const p = EvalPrediction(
      caseId: 'x',
      category: 'Dry Waste',
      provider: 'backend',
      model: 'm',
      localRuleId: 'city_rule',
    );
    final o = EvalScoring.scoreCase(c, p);
    expect(o.policyOverclaim, isTrue);
  });

  test('16. Multi-item category mismatch is failure', () {
    final c = EvalCase.fromJson(<String, dynamic>{
      'id': 'x',
      'imageRef': 'x',
      'region': 'Bangalore, IN',
      'language': 'en',
      'expected': <String, dynamic>{'category': 'Dry Waste'},
      'mustNot': <String>[],
      'safetyCritical': false,
      'localRuleCritical': false,
      'expectedItems': <Map<String, dynamic>>[
        <String, dynamic>{'itemName': 'plastic bottle', 'category': 'Dry Waste'},
        <String, dynamic>{'itemName': 'banana peel', 'category': 'Wet Waste'},
      ],
    });
    const p = EvalPrediction(
      caseId: 'x',
      category: 'Dry Waste',
      provider: 'backend',
      model: 'm',
      predictedItems: <Map<String, dynamic>>[
        <String, dynamic>{'itemName': 'plastic bottle', 'category': 'Dry Waste'},
        <String, dynamic>{'itemName': 'banana peel', 'category': 'Dry Waste'},
      ],
    );
    final o = EvalScoring.scoreCase(c, p);
    expect(o.multiItemFailure, isTrue);
  });

  test('17. Provider quality gate fails when safety/must-not are non-zero', () {
    const gate = ProviderQualityGate(ProviderQualityGateThresholds());
    final result = gate.evaluateSummary(
      <String, dynamic>{
        'cases': 10,
        'strictPass': 9,
        'acceptablePass': 0,
        'mustNotViolations': 1,
        'safetyCriticalFailures': 1,
        'localRuleFailures': 0,
        'providerLabel': 'backend',
      },
      defaultProviderLabel: 'backend',
    );
    expect(result.passed, isFalse);
    expect(result.failureReasons, isNotEmpty);
  });

  test('18. Provider quality gate passes with clean summary', () {
    const gate = ProviderQualityGate(ProviderQualityGateThresholds());
    final result = gate.evaluateSummary(
      <String, dynamic>{
        'cases': 20,
        'strictPass': 19,
        'acceptablePass': 1,
        'mustNotViolations': 0,
        'safetyCriticalFailures': 0,
        'localRuleFailures': 0,
        'providerLabel': 'backend',
      },
      defaultProviderLabel: 'backend',
    );
    expect(result.passed, isTrue);
    expect(result.accuracy, equals(1.0));
  });

  test('19. Router recommendation text is generated from policy pack', () {
    const policy = AiRouterPolicyConfig(
      policyPackVersion: 'router-policy-v9',
      localAcceptanceThreshold: 0.91,
      localEscalationThreshold: 0.73,
      localSafetyThreshold: 0.98,
      blockCacheOnRuleVersionChange: true,
      enforceSafetyEscalation: true,
    );
    final text = buildRouterStrategyRecommendations(policy);
    expect(text.contains('router-policy-v9'), isTrue);
    expect(text.contains('0.91'), isTrue);
    expect(text.contains('0.73'), isTrue);
    expect(text.contains('0.98'), isTrue);
  });
}
