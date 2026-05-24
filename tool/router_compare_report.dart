import 'dart:convert';
import 'dart:io';

import 'package:waste_segregation_app/ai_flywheel/router_metrics.dart';
import 'package:waste_segregation_app/ai_flywheel/router_policy_recommendations.dart';
import 'package:waste_segregation_app/services/ai_router_policy_config.dart';

void main(List<String> args) {
  final input = _arg(args, '--input', fallback: 'build/reports/ai_eval/latest.json');
  final out = _arg(args, '--out', fallback: 'build/reports/ai_eval/router_compare.json');
  final policyPackFile = _arg(args, '--policy-pack-file', fallback: '');
  final policy = _loadPolicy(policyPackFile);

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
  final safetyDisagreement = <String, int>{};
  final providerPairDisagreement = <String, int>{};
  final groupedByCase = <String, List<Map<String, dynamic>>>{};
  for (final o in outcomes) {
    final caseId = '${o['caseId'] ?? ''}';
    groupedByCase.putIfAbsent(caseId, () => <Map<String, dynamic>>[]).add(o);
  }
  for (final entry in groupedByCase.entries) {
    final categories = entry.value
        .map((e) => '${e['predictedCategory'] ?? ''}')
        .toSet();
    if (categories.length > 1) {
      disagreement[entry.key] = categories.length;
    }
    final safety = entry.value
        .where((e) =>
            (e['predictedCategory'] == 'Hazardous Waste' ||
                e['predictedCategory'] == 'Medical Waste' ||
                e['predictedCategory'] == 'E-Waste'))
        .map((e) => '${e['provider'] ?? 'unknown'}')
        .toList();
    if (safety.isNotEmpty && safety.length != entry.value.length) {
      safetyDisagreement[entry.key] = safety.length;
    }
    for (var i = 0; i < entry.value.length; i += 1) {
      for (var j = i + 1; j < entry.value.length; j += 1) {
        final a = entry.value[i];
        final b = entry.value[j];
        final pair = ('${a['provider']}|${b['provider']}').split('|')..sort();
        final key = '${pair[0]}__${pair[1]}';
        if ('${a['predictedCategory']}' != '${b['predictedCategory']}') {
          providerPairDisagreement[key] =
              (providerPairDisagreement[key] ?? 0) + 1;
        }
      }
    }
  }

  final calibrationByProvider = <String, Map<String, dynamic>>{};
  for (final p in byProvider.keys) {
    final rows = byProvider[p]!;
    final bins = <String, Map<String, num>>{
      '0.00-0.49': <String, num>{'total': 0, 'correct': 0},
      '0.50-0.69': <String, num>{'total': 0, 'correct': 0},
      '0.70-0.84': <String, num>{'total': 0, 'correct': 0},
      '0.85-1.00': <String, num>{'total': 0, 'correct': 0},
    };
    for (final r in rows) {
      final conf = (r['confidence'] as num?)?.toDouble() ?? 0;
      final correct = r['strictPass'] == true || r['acceptableAlternativePass'] == true;
      final bin = conf < 0.5
          ? '0.00-0.49'
          : conf < 0.7
              ? '0.50-0.69'
              : conf < 0.85
                  ? '0.70-0.84'
                  : '0.85-1.00';
      bins[bin]!['total'] = (bins[bin]!['total'] ?? 0) + 1;
      if (correct) bins[bin]!['correct'] = (bins[bin]!['correct'] ?? 0) + 1;
    }
    calibrationByProvider[p] = bins.map((k, v) {
      final total = v['total']!.toInt();
      final correct = v['correct']!.toInt();
      return MapEntry(k, <String, dynamic>{
        'total': total,
        'correct': correct,
        'accuracy': total == 0 ? 0 : correct / total,
      });
    });
  }

  final report = <String, dynamic>{
    'providers': providersReport,
    'providerDisagreementMatrix': {
      'disagreementCaseCount': disagreement.length,
      'cases': disagreement,
      'safetyDisagreementCaseCount': safetyDisagreement.length,
      'safetyCases': safetyDisagreement,
      'providerPairDisagreement': providerPairDisagreement,
    },
    'confidenceCalibration': calibrationByProvider,
  };

  final outFile = File(out);
  outFile.parent.createSync(recursive: true);
  outFile.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(report));

  final recFile = File('build/reports/ai_eval/router_strategy_recommendations.md');
  recFile.parent.createSync(recursive: true);
  recFile.writeAsStringSync(buildRouterStrategyRecommendations(policy));

  final calibrationFile = File('build/reports/ai_eval/calibration_report.json');
  calibrationFile.parent.createSync(recursive: true);
  calibrationFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(<String, dynamic>{
      'generatedAt': DateTime.now().toIso8601String(),
      'confidenceCalibration': calibrationByProvider,
      'providerPairDisagreement': providerPairDisagreement,
      'safetyDisagreementCaseCount': safetyDisagreement.length,
    }),
  );

  stdout.writeln('Wrote router comparison report: $out');
  stdout.writeln('Wrote strategy recommendations: ${recFile.path}');
  stdout.writeln('Wrote calibration report: ${calibrationFile.path}');
}

String _arg(List<String> args, String name, {required String fallback}) {
  for (var i = 0; i < args.length; i += 1) {
    if (args[i] == name && i + 1 < args.length) return args[i + 1].trim();
    if (args[i].startsWith('$name=')) return args[i].split('=').last.trim();
  }

  AiRouterPolicyConfig _loadPolicy(String policyPackFile) {
    if (policyPackFile.trim().isEmpty) {
      return AiRouterPolicyConfig.defaults;
    }
    final file = File(policyPackFile.trim());
    if (!file.existsSync()) {
      stderr.writeln(
          'Policy pack file not found ($policyPackFile). Falling back to defaults.');
      return AiRouterPolicyConfig.defaults;
    }
    return AiRouterPolicyConfig.fromJsonString(file.readAsStringSync());
  }
  return fallback;
}
