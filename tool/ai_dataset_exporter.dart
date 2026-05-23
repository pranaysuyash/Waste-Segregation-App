import 'dart:convert';
import 'dart:io';

import 'package:waste_segregation_app/ai_flywheel/dataset_exporter.dart';

Future<void> main(List<String> args) async {
  final input = _arg(args, '--input', fallback: 'test/fixtures/ai_eval/recorded_outputs/training_candidates_sample.jsonl');
  final output = _arg(args, '--out', fallback: 'build/reports/ai_dataset/latest');
  final version = _arg(args, '--version', fallback: 'waste-v0.1');

  final lines = await File(input).readAsLines();
  final raw = lines.where((l) => l.trim().isNotEmpty).map((l) => jsonDecode(l) as Map<String, dynamic>).toList();

  final exporter = DatasetExporter();
  final summary = await exporter.export(
    rawCandidates: raw,
    datasetVersion: version,
    outputDir: output,
  );

  stdout.writeln('Exported ${summary.caseCount} candidates to $output');
}

String _arg(List<String> args, String name, {required String fallback}) {
  for (var i = 0; i < args.length; i += 1) {
    if (args[i] == name && i + 1 < args.length) return args[i + 1].trim();
    if (args[i].startsWith('$name=')) return args[i].split('=').last.trim();
  }
  return fallback;
}
