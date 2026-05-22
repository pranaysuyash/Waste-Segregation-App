import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/ai_flywheel/dataset_exporter.dart';
import 'package:waste_segregation_app/ai_flywheel/eval_models.dart';
import 'package:waste_segregation_app/ai_flywheel/eval_runner.dart';
import 'package:waste_segregation_app/ai_flywheel/eval_scoring.dart';
import 'package:waste_segregation_app/ai_flywheel/router_metrics.dart';
import 'package:waste_segregation_app/ai_flywheel/training_candidate_policy.dart';

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
    expect(summary.caseCount, 1);
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
        ),
      ),
      isFalse,
    );
  });

  test('11. Dataset export produces deterministic manifest order', () async {
    final raw = <Map<String, dynamic>>[
      <String, dynamic>{'candidateId': 'b', 'consent': <String, dynamic>{'enabledAtCapture': true}, 'review': <String, dynamic>{'status': 'training_eligible'}, 'image': <String, dynamic>{'redactionStatus': 'passed'}},
      <String, dynamic>{'candidateId': 'a', 'consent': <String, dynamic>{'enabledAtCapture': true}, 'review': <String, dynamic>{'status': 'training_eligible'}, 'image': <String, dynamic>{'redactionStatus': 'passed'}},
    ];
    final outDir = Directory.systemTemp.createTempSync('dataset-order-test').path;
    await DatasetExporter().export(rawCandidates: raw, datasetVersion: 'waste-v0.1', outputDir: outDir);
    final first = File('$outDir/manifest.jsonl').readAsLinesSync().first;
    expect(first.contains('"candidateId":"a"'), isTrue);
  });

  test('12. Router comparison handles fake backend/local/provider outputs', () {
    final result = RouterMetrics.compare(provider: 'backend', outcomes: <Map<String, dynamic>>[
      <String, dynamic>{'strictPass': true, 'acceptableAlternativePass': false, 'safetyCriticalFailure': false, 'mustNotViolation': false, 'localRuleFailure': false, 'latencyMs': 1000, 'estimatedCostUsd': 0.001, 'cacheHit': true, 'usedFallback': false, 'providerFailure': false},
      <String, dynamic>{'strictPass': false, 'acceptableAlternativePass': false, 'safetyCriticalFailure': true, 'mustNotViolation': true, 'localRuleFailure': true, 'latencyMs': 1200, 'estimatedCostUsd': 0.002, 'cacheHit': false, 'usedFallback': true, 'providerFailure': false},
    ]);
    expect(result.total, 2);
    expect(result.safetyCriticalFailures, 1);
  });
}
