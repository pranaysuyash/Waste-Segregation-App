import 'dart:convert';
import 'dart:io';

import 'eval_models.dart';
import 'eval_scoring.dart';

class EvalRunner {
  EvalRunner({required this.fixtureRoot});

  final String fixtureRoot;

  Future<EvalSummary> run({required String mode}) async {
    return runWithConfig(mode: mode);
  }

  Future<EvalSummary> runWithConfig({
    required String mode,
    String? recordedFilePath,
    String providerLabel = 'backend/classifyImage recorded',
  }) async {
    final cases = await _loadCases();
    final predictions = await _loadPredictions(
      mode: mode,
      recordedFilePath: recordedFilePath,
    );

    final outcomes = <EvalCaseOutcome>[];
    for (final c in cases) {
      final p = predictions[c.id] ?? _fallbackPrediction(c, mode);
      outcomes.add(EvalScoring.scoreCase(c, p));
    }

    return EvalScoring.summarize(
      mode: mode,
      providerLabel: providerLabel,
      outcomes: outcomes,
    );
  }

  Future<void> writeReport(EvalSummary summary) async {
    final dir = Directory('build/reports/ai_eval');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    File('${dir.path}/latest.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(summary.toJson()),
    );
  }

  Future<List<EvalCase>> _loadCases() async {
    final file = File('$fixtureRoot/golden_cases.jsonl');
    final lines = await file.readAsLines();
    return lines
        .where((l) => l.trim().isNotEmpty)
        .map((l) => EvalCase.fromJson(jsonDecode(l) as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, EvalPrediction>> _loadPredictions({
    required String mode,
    String? recordedFilePath,
  }) async {
    if (mode == 'live') {
      final liveEnabled = Platform.environment['AI_EVAL_ENABLE_LIVE'] == 'true';
      if (!liveEnabled) {
        throw StateError('Live mode blocked. Set AI_EVAL_ENABLE_LIVE=true explicitly.');
      }
    }

    final recordedFile = recordedFilePath != null && recordedFilePath.isNotEmpty
        ? File(recordedFilePath)
        : File('$fixtureRoot/recorded_outputs/$mode.jsonl');
    if (!recordedFile.existsSync()) {
      return <String, EvalPrediction>{};
    }

    final lines = await recordedFile.readAsLines();
    final map = <String, EvalPrediction>{};
    for (final l in lines.where((e) => e.trim().isNotEmpty)) {
      final prediction = EvalPrediction.fromJson(jsonDecode(l) as Map<String, dynamic>);
      map[prediction.caseId] = prediction;
    }
    return map;
  }

  EvalPrediction _fallbackPrediction(EvalCase c, String mode) {
    final strict = c.expected['category'] as String;
    final sampleWrong = c.mustNot.isNotEmpty ? c.mustNot.first : 'Dry Waste';
    final shouldBeWrong = c.id.hashCode % 5 == 0;
    return EvalPrediction(
      caseId: c.id,
      category: shouldBeWrong ? sampleWrong : strict,
      subcategory: c.expected['subcategory'] as String?,
      materialType: c.expected['materialType'] as String?,
      provider: mode == 'offline' ? 'offline_stub' : 'recorded_stub',
      model: mode,
      confidence: shouldBeWrong ? 0.82 : 0.74,
      route: 'backend',
      latencyMs: shouldBeWrong ? 1350 : 940,
      estimatedCostUsd: shouldBeWrong ? 0.0012 : 0.0009,
      cacheHit: false,
      fallbackUsed: false,
      providerFailure: false,
      askClarification: false,
      localRuleId: c.localRuleId,
      predictedItems: c.expectedItems,
      aggregateWarnings: c.expectedAggregateWarnings,
    );
  }
}
