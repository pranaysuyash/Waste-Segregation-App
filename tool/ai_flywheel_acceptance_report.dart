import 'dart:convert';
import 'dart:io';

import 'package:waste_segregation_app/ai_flywheel/provider_quality_gate.dart';

class Criterion {
  const Criterion(this.id, this.text, this.check);

  final int id;
  final String text;
  final bool Function() check;
}

bool _exists(String path) =>
    File(path).existsSync() || Directory(path).existsSync();

Map<String, dynamic>? _readJsonFile(String path) {
  final f = File(path);
  if (!f.existsSync()) return null;
  try {
    return jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}

int _jsonlLineCount(String path) {
  final f = File(path);
  if (!f.existsSync()) return 0;
  return f.readAsLinesSync().where((l) => l.trim().isNotEmpty).length;
}

void main(List<String> args) {
  final out = _arg(args, '--out',
      fallback: 'build/reports/ai_flywheel/acceptance_report.json');

  final offlineEvalJson =
      _readJsonFile('build/reports/ai_eval/offline_latest.json') ??
          _readJsonFile('build/reports/ai_eval/latest.json');
  final providerEvalFiles = <String, String>{
    'backend': 'build/reports/ai_eval/recorded_backend_latest.json',
    'openai': 'build/reports/ai_eval/recorded_openai_latest.json',
    'gemini': 'build/reports/ai_eval/recorded_gemini_latest.json',
    'local': 'build/reports/ai_eval/recorded_local_latest.json',
  };
  final datasetVersionJson =
      _readJsonFile('build/reports/ai_dataset/latest/version.json');
  final routerJson =
      _readJsonFile('build/reports/ai_eval/router_compare.json') ??
          _readJsonFile('build/reports/ai_eval/router_compare_backend.json');
  final seedCoverageJson =
      _readJsonFile('build/reports/ai_eval/seed_coverage_report.json');

  final criteria = <Criterion>[
    Criterion(1, 'Golden eval schema exists',
        () => _exists('test/fixtures/ai_eval/schema.md')),
    Criterion(
        2,
        '>=100 seed eval cases exist and semantic coverage report passes',
        () =>
            _jsonlLineCount('test/fixtures/ai_eval/golden_cases.jsonl') >=
                100 &&
            seedCoverageJson != null &&
            seedCoverageJson['allRulesPassed'] == true),
    Criterion(3, 'Offline scorer-smoke eval report exists',
        () => offlineEvalJson != null),
    Criterion(4, 'Safety + must-not + local-rule + multi-item scoring exists',
        () => _exists('lib/ai_flywheel/eval_scoring.dart')),
    Criterion(
        5,
        'Consent-aware training candidate schema exists',
        () =>
            _exists('functions/src/training_data.ts') &&
            _exists('lib/models/user_profile.dart')),
    Criterion(
        6,
        'Candidate creation gated by consent',
        () =>
            _exists('lib/services/training_data_service.dart') &&
            _exists('functions/src/training_data.ts')),
    Criterion(7, 'Review workflow + states defined',
        () => _exists('docs/guides/ai_flywheel/review_workflow.md')),
    Criterion(
        8,
        'Dataset export/versioning + excluded artifact exists',
        () =>
            _exists('tool/ai_dataset_exporter.dart') &&
            _exists('build/reports/ai_dataset/latest/excluded.jsonl')),
    Criterion(
        9,
        'Excluded-by-default rules reflected in dataset output',
        () =>
            datasetVersionJson != null &&
            datasetVersionJson['excludedCounts'] != null),
    Criterion(
        10,
        'Router comparison metrics + recommendations output exists',
        () =>
            routerJson != null &&
            _exists(
                'build/reports/ai_eval/router_strategy_recommendations.md')),
    Criterion(
        11,
        'Tests for schema/scoring/consent/export/review/router exist',
        () =>
            _exists('test/ai_flywheel/flywheel_foundation_test.dart') &&
            _exists('test/services/training_data_service_test.dart')),
    Criterion(
        12,
        'Documentation explains unlock path and final evidence summary exists',
        () =>
            _exists('docs/review/AI_LEARNING_FLYWHEEL_EXPANSION.md') &&
            _exists('build/reports/ai_flywheel/FINAL_EVIDENCE_SUMMARY.md')),
  ];

  final rows = <Map<String, dynamic>>[];
  for (final c in criteria) {
    rows.add(<String, dynamic>{
      'id': c.id,
      'criterion': c.text,
      'pass': c.check(),
    });
  }

  final passed = rows.where((r) => r['pass'] == true).length;
  final providerThresholds = _thresholdsFromArgs(args);
  final providerGate = ProviderQualityGate(providerThresholds);
  final providerResults = <String, ProviderQualityGateResult>{};
  for (final entry in providerEvalFiles.entries) {
    final summary = _readJsonFile(entry.value);
    if (summary == null) {
      continue;
    }
    providerResults[entry.key] =
        providerGate.evaluateSummary(summary, defaultProviderLabel: entry.key);
  }

  final providerRows = providerResults.map(
    (provider, result) => MapEntry(provider, result.toJson()),
  );
  final providerQualityAllPassed = providerResults.isNotEmpty &&
      providerResults.values.every((r) => r.passed);

  final report = <String, dynamic>{
    'generatedAt': DateTime.now().toIso8601String(),
    'harness': <String, dynamic>{
      'passed': passed,
      'total': rows.length,
      'allPassed': passed == rows.length,
    },
    'providerQualityGate': <String, dynamic>{
      'description':
          'Provider quality gate is separate from harness checks and determines release-readiness.',
      'thresholds': providerThresholds.toJson(),
      'evaluatedProviders': providerRows,
      'allPassed': providerQualityAllPassed,
      'releaseReady': providerQualityAllPassed,
      'missingProviders': providerEvalFiles.keys
          .where((k) => !providerRows.containsKey(k))
          .toList(),
    },
    'passed': passed,
    'total': rows.length,
    'allPassed': passed == rows.length,
    'criteria': rows,
    'notes': <String>[
      'Harness pass (`allPassed`) confirms scaffold and artifact integrity, not provider quality.',
      'Provider quality gate (`providerQualityGate.releaseReady`) is the model safety/readiness signal.',
      'Offline scorer-smoke can include synthetic failures and is not a product-quality result by itself.',
    ],
  };

  final outFile = File(out);
  outFile.parent.createSync(recursive: true);
  outFile.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(report));

  stdout.writeln('Acceptance report written to $out');
  stdout.writeln('Passed $passed/${rows.length}');
}

String _arg(List<String> args, String name, {required String fallback}) {
  for (var i = 0; i < args.length; i += 1) {
    if (args[i] == name && i + 1 < args.length) return args[i + 1].trim();
    if (args[i].startsWith('$name=')) return args[i].split('=').last.trim();
  }
  return fallback;
}

ProviderQualityGateThresholds _thresholdsFromArgs(List<String> args) {
  final minAccuracy =
      _argDouble(args, '--quality-min-accuracy', fallback: 0.95);
  final maxMustNot = _argInt(args, '--quality-max-must-not', fallback: 0);
  final maxSafety = _argInt(args, '--quality-max-safety', fallback: 0);
  final maxLocalRule = _argInt(args, '--quality-max-local-rule', fallback: 0);
  return ProviderQualityGateThresholds(
    minAccuracy: minAccuracy,
    maxMustNotViolations: maxMustNot,
    maxSafetyCriticalFailures: maxSafety,
    maxLocalRuleFailures: maxLocalRule,
  );
}

double _argDouble(List<String> args, String name, {required double fallback}) {
  final raw = _arg(args, name, fallback: '$fallback');
  return double.tryParse(raw) ?? fallback;
}

int _argInt(List<String> args, String name, {required int fallback}) {
  final raw = _arg(args, name, fallback: '$fallback');
  return int.tryParse(raw) ?? fallback;
}
