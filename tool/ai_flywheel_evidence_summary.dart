import 'dart:convert';
import 'dart:io';

Map<String, dynamic>? readJson(String path) {
  final f = File(path);
  if (!f.existsSync()) return null;
  try {
    return jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}

int jsonlCount(String path) {
  final f = File(path);
  if (!f.existsSync()) return 0;
  return f.readAsLinesSync().where((l) => l.trim().isNotEmpty).length;
}

void main(List<String> args) {
  final out = _arg(args, '--out', fallback: 'build/reports/ai_flywheel/FINAL_EVIDENCE_SUMMARY.md');

  final acceptance = readJson('build/reports/ai_flywheel/acceptance_report.json');
  final seedCoverage = readJson('build/reports/ai_eval/seed_coverage_report.json');
  final evalLatest = readJson('build/reports/ai_eval/offline_latest.json') ?? readJson('build/reports/ai_eval/latest.json');
  final datasetVersion = readJson('build/reports/ai_dataset/latest/version.json');
  final router = readJson('build/reports/ai_eval/router_compare_backend.json') ?? readJson('build/reports/ai_eval/router_compare.json');

  final b = StringBuffer();
  b.writeln('# AI Flywheel Final Evidence Summary');
  b.writeln();
  b.writeln('- Generated: ${DateTime.now().toIso8601String()}');
  b.writeln();

  b.writeln('## Acceptance status');
  if (acceptance == null) {
    b.writeln('- Acceptance report missing: `build/reports/ai_flywheel/acceptance_report.json`');
  } else {
    final harness = (acceptance['harness'] as Map?)?.cast<String, dynamic>();
    final providerQuality =
        (acceptance['providerQualityGate'] as Map?)?.cast<String, dynamic>();
    b.writeln(
        '- Harness passed: ${harness?['passed'] ?? acceptance['passed']}/${harness?['total'] ?? acceptance['total']}');
    b.writeln('- Harness all passed: ${harness?['allPassed'] ?? acceptance['allPassed']}');
    if (providerQuality != null) {
      b.writeln(
          '- Provider quality releaseReady: ${providerQuality['releaseReady']}');
      b.writeln(
          '- Provider quality allPassed: ${providerQuality['allPassed']}');
    }
  }
  b.writeln();

  b.writeln('## Seed coverage status');
  if (seedCoverage == null) {
    b.writeln('- Seed coverage report missing: `build/reports/ai_eval/seed_coverage_report.json`');
  } else {
    b.writeln('- Rules passed: ${seedCoverage['passedRules']}/${seedCoverage['totalRules']}');
    b.writeln('- All rules passed: ${seedCoverage['allRulesPassed']}');
  }
  b.writeln();

  b.writeln('## Eval snapshot (offline/latest)');
  if (evalLatest == null) {
    b.writeln('- Eval report missing: `build/reports/ai_eval/offline_latest.json` or `latest.json`');
  } else {
    b.writeln('- Cases: ${evalLatest['cases']}');
    b.writeln('- Strict pass: ${evalLatest['strictPass']}');
    b.writeln('- Acceptable pass: ${evalLatest['acceptablePass']}');
    b.writeln('- Fail: ${evalLatest['fail']}');
    b.writeln('- Safety-critical failures: ${evalLatest['safetyCriticalFailures']}');
    b.writeln('- Must-not violations: ${evalLatest['mustNotViolations']}');
    b.writeln('- Local-rule failures: ${evalLatest['localRuleFailures']}');
  }
  b.writeln();

  b.writeln('## Dataset export snapshot');
  if (datasetVersion == null) {
    b.writeln('- Dataset version report missing: `build/reports/ai_dataset/latest/version.json`');
  } else {
    b.writeln('- Dataset version: ${datasetVersion['datasetVersion']}');
    b.writeln('- Case count: ${datasetVersion['caseCount']}');
    b.writeln('- Excluded counts: ${jsonEncode(datasetVersion['excludedCounts'])}');
  }
  b.writeln('- Manifest rows: ${jsonlCount('build/reports/ai_dataset/latest/manifest.jsonl')}');
  b.writeln('- Label rows: ${jsonlCount('build/reports/ai_dataset/latest/labels.jsonl')}');
  b.writeln();

  b.writeln('## Router comparison snapshot');
  if (router == null) {
    b.writeln('- Router comparison report missing: `build/reports/ai_eval/router_compare_backend.json` or `router_compare.json`');
  } else {
    final providers = (router['providers'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    if (providers.isEmpty) {
      b.writeln('- No provider entries found');
    } else {
      for (final key in providers.keys.toList()..sort()) {
        final v = (providers[key] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
        b.writeln('- $key: accuracy=${v['accuracy']} safetyFailures=${v['safetyCriticalFailures']} mustNot=${v['mustNotViolations']} localRule=${v['localRuleFailures']} avgLatencyMs=${v['avgLatencyMs']} avgCost=${v['avgEstimatedCostUsd']}');
      }
    }
  }
  b.writeln();

  b.writeln('## Artifact checklist');
  for (final path in <String>[
    'build/reports/ai_eval/offline_latest.json',
    'build/reports/ai_eval/recorded_backend_latest.json',
    'build/reports/ai_eval/recorded_openai_latest.json',
    'build/reports/ai_eval/recorded_gemini_latest.json',
    'build/reports/ai_eval/recorded_local_latest.json',
    'build/reports/ai_eval/merged_records.jsonl',
    'build/reports/ai_eval/router_compare_backend.json',
    'build/reports/ai_eval/seed_coverage_report.json',
    'build/reports/ai_dataset/latest/manifest.jsonl',
    'build/reports/ai_dataset/latest/labels.jsonl',
    'build/reports/ai_dataset/latest/version.json',
    'build/reports/ai_review/review_template.jsonl',
    'build/reports/ai_review/updated_candidates.jsonl',
    'build/reports/ai_flywheel/acceptance_report.json',
  ]) {
    b.writeln('- ${File(path).existsSync() ? '[x]' : '[ ]'} `$path`');
  }

  final outFile = File(out);
  outFile.parent.createSync(recursive: true);
  outFile.writeAsStringSync(b.toString());

  stdout.writeln('Evidence summary written to $out');
}

String _arg(List<String> args, String name, {required String fallback}) {
  for (var i = 0; i < args.length; i += 1) {
    if (args[i] == name && i + 1 < args.length) return args[i + 1].trim();
    if (args[i].startsWith('$name=')) return args[i].split('=').last.trim();
  }
  return fallback;
}
