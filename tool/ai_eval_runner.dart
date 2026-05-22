import 'dart:io';

import 'package:waste_segregation_app/ai_flywheel/eval_runner.dart';

Future<void> main(List<String> args) async {
  var mode = 'offline';
  String? recordedFile;
  var providerLabel = 'backend/classifyImage recorded';
  for (var i = 0; i < args.length; i += 1) {
    final arg = args[i];
    if (arg.startsWith('--mode=')) {
      mode = arg.split('=').last.trim();
      break;
    }
    if (arg == '--mode' && i + 1 < args.length) {
      mode = args[i + 1].trim();
      break;
    }
    if (arg.startsWith('--recorded-file=')) {
      recordedFile = arg.split('=').last.trim();
      continue;
    }
    if (arg == '--recorded-file' && i + 1 < args.length) {
      recordedFile = args[i + 1].trim();
      continue;
    }
    if (arg.startsWith('--provider-label=')) {
      providerLabel = arg.split('=').last.trim();
      continue;
    }
    if (arg == '--provider-label' && i + 1 < args.length) {
      providerLabel = args[i + 1].trim();
      continue;
    }
  }

  if (!const <String>{'offline', 'recorded', 'live'}.contains(mode)) {
    stderr.writeln('Invalid mode: $mode (expected offline|recorded|live)');
    exitCode = 2;
    return;
  }

  final runner = EvalRunner(fixtureRoot: 'test/fixtures/ai_eval');
  final summary = await runner.runWithConfig(
    mode: mode,
    recordedFilePath: recordedFile,
    providerLabel: providerLabel,
  );
  await runner.writeReport(summary);

  stdout.writeln('Eval run: ${DateTime.now().toIso8601String()}');
  stdout.writeln('Mode: ${summary.mode}');
  stdout.writeln('Cases: ${summary.cases}');
  stdout.writeln('Strict pass: ${summary.strictPass}');
  stdout.writeln('Acceptable pass: ${summary.acceptablePass}');
  stdout.writeln('Fail: ${summary.fail}');
  stdout.writeln('Safety-critical failures: ${summary.safetyCriticalFailures}');
  stdout.writeln('Must-not violations: ${summary.mustNotViolations}');
  stdout.writeln('Local-rule failures: ${summary.localRuleFailures}');
  stdout.writeln('Avg confidence on correct: ${summary.avgConfidenceOnCorrect.toStringAsFixed(2)}');
  stdout.writeln('Avg confidence on wrong: ${summary.avgConfidenceOnWrong.toStringAsFixed(2)}');
  stdout.writeln('Provider: ${summary.providerLabel}');
}
