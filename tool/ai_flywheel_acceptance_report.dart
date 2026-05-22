import 'dart:convert';
import 'dart:io';

class Criterion {
  const Criterion(this.id, this.text, this.check);

  final int id;
  final String text;
  final bool Function() check;
}

bool _exists(String path) => File(path).existsSync() || Directory(path).existsSync();

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
  final out = _arg(args, '--out', fallback: 'build/reports/ai_flywheel/acceptance_report.json');

  final evalJson = _readJsonFile('build/reports/ai_eval/latest.json');
  final datasetVersionJson = _readJsonFile('build/reports/ai_dataset/latest/version.json');
  final routerJson = _readJsonFile('build/reports/ai_eval/router_compare.json')
      ?? _readJsonFile('build/reports/ai_eval/router_compare_backend.json');

  final criteria = <Criterion>[
    Criterion(1, 'Golden eval schema exists', () => _exists('test/fixtures/ai_eval/schema.md')),
    Criterion(2, '>=30 seed eval cases exist', () => _jsonlLineCount('test/fixtures/ai_eval/golden_cases.jsonl') >= 30),
    Criterion(3, 'Offline eval report exists', () => evalJson != null),
    Criterion(4, 'Safety + must-not scored separately',
        () => _exists('lib/ai_flywheel/eval_scoring.dart')),
    Criterion(5, 'Consent-aware training candidate schema exists',
        () => _exists('functions/src/training_data.ts') && _exists('lib/models/user_profile.dart')),
    Criterion(6, 'Candidate creation gated by consent',
        () => _exists('lib/services/training_data_service.dart') && _exists('functions/src/training_data.ts')),
    Criterion(7, 'Review states defined',
        () => _exists('docs/guides/ai_flywheel/annotation_review_workflow.md')),
    Criterion(8, 'Dataset export/versioning scaffold exists',
        () => _exists('tool/ai_dataset_exporter.dart') && _exists('lib/ai_flywheel/dataset_exporter.dart')),
    Criterion(9, 'Excluded-by-default rules reflected in dataset output',
        () => datasetVersionJson != null && datasetVersionJson['excludedCounts'] != null),
    Criterion(10, 'Router comparison metrics output exists', () => routerJson != null),
    Criterion(11, 'Tests for schema/scoring/consent/export exist',
        () => _exists('test/ai_flywheel/flywheel_foundation_test.dart')),
    Criterion(12, 'Documentation explains unlock path',
        () => _exists('docs/review/AI_LEARNING_FLYWHEEL_FOUNDATION_2026-05-21.md')),
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
  final report = <String, dynamic>{
    'generatedAt': DateTime.now().toIso8601String(),
    'passed': passed,
    'total': rows.length,
    'allPassed': passed == rows.length,
    'criteria': rows,
    'notes': <String>[
      'Criteria that depend on runtime artifacts remain false until verification commands are executed.',
      'This report checks presence/shape of evidence artifacts, not semantic correctness of model outputs.',
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
