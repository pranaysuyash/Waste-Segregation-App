import 'dart:convert';
import 'dart:io';

import 'package:waste_segregation_app/ai_flywheel/router_metrics.dart';

void main(List<String> args) {
  final input = _arg(args, '--input', fallback: 'build/reports/ai_eval/latest.json');
  final out = _arg(args, '--out', fallback: 'build/reports/ai_eval/router_compare.json');

  final file = File(input);
  if (!file.existsSync()) {
    stderr.writeln('Missing input file: $input');
    exitCode = 2;
    return;
  }

  final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final outcomes = ((data['outcomes'] as List?) ?? const <dynamic>[])
      .whereType<Map>()
      .map((e) => e.cast<String, dynamic>())
      .toList();

  final byProvider = <String, List<Map<String, dynamic>>>{};
  for (final o in outcomes) {
    final provider = '${o['provider'] ?? 'unknown'}';
    byProvider.putIfAbsent(provider, () => <Map<String, dynamic>>[]).add(o);
  }

  final providersReport = <String, dynamic>{};
  for (final p in byProvider.keys.toList()..sort()) {
    final r = RouterMetrics.compare(provider: p, outcomes: byProvider[p]!);
    providersReport[p] = <String, dynamic>{
      'total': r.total,
      'correct': r.correct,
      'accuracy': r.total == 0 ? 0 : r.correct / r.total,
      'safetyCriticalFailures': r.safetyCriticalFailures,
      'mustNotViolations': r.mustNotViolations,
      'localRuleFailures': r.localRuleFailures,
      'multiItemFailures': r.multiItemFailures,
      'overconfidentWrong': r.overconfidentWrong,
      'underconfidentCorrect': r.underconfidentCorrect,
      'avgLatencyMs': r.avgLatencyMs,
      'avgEstimatedCostUsd': r.avgEstimatedCostUsd,
      'cacheHitRate': r.cacheHitRate,
      'fallbackRate': r.fallbackRate,
      'providerFailureRate': r.providerFailureRate,
    };
  }

  final disagreement = <String, int>{};
  final groupedByCase = <String, List<Map<String, dynamic>>>{};
  for (final o in outcomes) {
    final caseId = '${o['caseId'] ?? ''}';
    groupedByCase.putIfAbsent(caseId, () => <Map<String, dynamic>>[]).add(o);
  }
  for (final entry in groupedByCase.entries) {
    final categories = entry.value.map((e) => '${e['predictedCategory'] ?? ''}').toSet();
    if (categories.length > 1) {
      disagreement[entry.key] = categories.length;
    }
  }

  final report = <String, dynamic>{
    'providers': providersReport,
    'providerDisagreementMatrix': {
      'disagreementCaseCount': disagreement.length,
      'cases': disagreement,
    },
  };

  final outFile = File(out);
  outFile.parent.createSync(recursive: true);
  outFile.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(report));

  final rec = StringBuffer();
  rec.writeln('# Router Strategy Recommendations');
  rec.writeln();
  rec.writeln('- Use `local` route only when confidence >= 0.85 and case is not safety-critical.');
  rec.writeln('- Always escalate batteries/medical/e-waste to backend until local safety-critical fail rate is < 1%.');
  rec.writeln('- Escalate to backend when local confidence < 0.70.');
  rec.writeln('- If providers disagree on safety category, ask user clarification and enqueue review candidate.');
  rec.writeln('- Avoid cache reuse when local-rule version changes.');
  final recFile = File('build/reports/ai_eval/router_strategy_recommendations.md');
  recFile.parent.createSync(recursive: true);
  recFile.writeAsStringSync(rec.toString());

  stdout.writeln('Wrote router comparison report: $out');
  stdout.writeln('Wrote strategy recommendations: ${recFile.path}');
}

String _arg(List<String> args, String name, {required String fallback}) {
  for (var i = 0; i < args.length; i += 1) {
    if (args[i] == name && i + 1 < args.length) return args[i + 1].trim();
    if (args[i].startsWith('$name=')) return args[i].split('=').last.trim();
  }
  return fallback;
}
