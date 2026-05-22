import 'dart:convert';
import 'dart:io';

import 'package:waste_segregation_app/ai_flywheel/dataset_exporter.dart';

Future<void> main(List<String> args) async {
  final input = args.where((a) => a.startsWith('--input=')).map((a) => a.split('=').last).firstWhere(
        (_) => true,
        orElse: () => 'test/fixtures/ai_eval/recorded_outputs/training_candidates_sample.jsonl',
      );
  final output = args.where((a) => a.startsWith('--out=')).map((a) => a.split('=').last).firstWhere(
        (_) => true,
        orElse: () => 'build/reports/ai_dataset/latest',
      );
  final version = args.where((a) => a.startsWith('--version=')).map((a) => a.split('=').last).firstWhere(
        (_) => true,
        orElse: () => 'waste-v0.1',
      );

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
