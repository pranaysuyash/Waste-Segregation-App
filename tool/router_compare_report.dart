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

  final report = <String, dynamic>{'providers': <String, dynamic>{}};
  for (final p in byProvider.keys.toList()..sort()) {
    final r = RouterMetrics.compare(provider: p, outcomes: byProvider[p]!);
    report['providers'][p] = <String, dynamic>{
      'total': r.total,
      'correct': r.correct,
      'accuracy': r.total == 0 ? 0 : r.correct / r.total,
      'safetyCriticalFailures': r.safetyCriticalFailures,
      'mustNotViolations': r.mustNotViolations,
      'localRuleFailures': r.localRuleFailures,
      'avgLatencyMs': r.avgLatencyMs,
      'avgEstimatedCostUsd': r.avgEstimatedCostUsd,
      'cacheHitRate': r.cacheHitRate,
      'fallbackRate': r.fallbackRate,
      'providerFailureRate': r.providerFailureRate,
    };
  }

  final outFile = File(out);
  outFile.parent.createSync(recursive: true);
  outFile.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(report));
  stdout.writeln('Wrote router comparison report: $out');
}

String _arg(List<String> args, String name, {required String fallback}) {
  for (var i = 0; i < args.length; i += 1) {
    if (args[i] == name && i + 1 < args.length) return args[i + 1].trim();
    if (args[i].startsWith('$name=')) return args[i].split('=').last.trim();
  }
  return fallback;
}
