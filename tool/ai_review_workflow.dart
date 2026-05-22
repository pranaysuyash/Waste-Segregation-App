import 'dart:convert';
import 'dart:io';

const _validStates = <String>{
  'unreviewed',
  'approved',
  'rejected',
  'needs_redaction',
  'golden',
  'training_eligible',
  'deleted',
};

void main(List<String> args) {
  final mode = _arg(args, '--mode', fallback: 'export');
  final inputPath = _arg(args, '--input', fallback: 'test/fixtures/ai_eval/recorded_outputs/training_candidates_sample.jsonl');
  final decisionsPath = _arg(args, '--decisions', fallback: 'tool/templates/review_decisions_template.jsonl');
  final outputPath = _arg(args, '--out', fallback: 'build/reports/ai_review/updated_candidates.jsonl');
  final reviewer = _arg(args, '--reviewer', fallback: 'reviewer@example.com');

  if (mode == 'export') {
    _exportTemplate(inputPath, outputPath);
    return;
  }
  if (mode == 'apply') {
    _applyDecisions(inputPath, decisionsPath, outputPath, reviewer);
    return;
  }
  if (mode == 'report') {
    _report(outputPath);
    return;
  }

  stderr.writeln('Unsupported mode: $mode. Use export|apply|report');
  exitCode = 2;
}

String _arg(List<String> args, String name, {required String fallback}) {
  for (var i = 0; i < args.length; i += 1) {
    if (args[i] == name && i + 1 < args.length) return args[i + 1].trim();
    if (args[i].startsWith('$name=')) return args[i].split('=').last.trim();
  }
  return fallback;
}

List<Map<String, dynamic>> _readJsonl(String path) {
  final file = File(path);
  if (!file.existsSync()) return <Map<String, dynamic>>[];
  return file
      .readAsLinesSync()
      .where((l) => l.trim().isNotEmpty)
      .map((l) => jsonDecode(l) as Map<String, dynamic>)
      .toList();
}

void _writeJsonl(String path, List<Map<String, dynamic>> rows) {
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(rows.map(jsonEncode).join('\n') + '\n');
}

void _exportTemplate(String inputPath, String outputPath) {
  final rows = _readJsonl(inputPath);
  final template = rows.map((r) {
    final id = '${r['candidateId'] ?? ''}';
    final prediction = (r['modelPrediction'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    return <String, dynamic>{
      'candidateId': id,
      'currentStatus': (r['review'] as Map?)?['status'] ?? 'unreviewed',
      'predictedCategory': prediction['category'],
      'reviewDecision': null,
      'groundTruth': <String, dynamic>{
        'category': null,
        'subcategory': null,
        'itemName': null,
        'material': null,
        'confidence': null,
      },
      'notes': null,
    };
  }).toList();

  _writeJsonl(outputPath, template);
  stdout.writeln('Exported review template: $outputPath (${template.length} rows)');
}

void _applyDecisions(
  String inputPath,
  String decisionsPath,
  String outputPath,
  String reviewer,
) {
  final candidates = _readJsonl(inputPath);
  final decisions = _readJsonl(decisionsPath);
  final decisionMap = <String, Map<String, dynamic>>{};
  for (final d in decisions) {
    final id = '${d['candidateId'] ?? ''}';
    if (id.isNotEmpty) decisionMap[id] = d;
  }

  final now = DateTime.now().toIso8601String();
  final updated = <Map<String, dynamic>>[];

  for (final c in candidates) {
    final id = '${c['candidateId'] ?? ''}';
    final d = decisionMap[id];
    if (d == null) {
      updated.add(c);
      continue;
    }

    final decision = '${d['reviewDecision'] ?? ''}';
    if (!_validStates.contains(decision)) {
      throw StateError('Invalid reviewDecision "$decision" for $id');
    }

    final review = (c['review'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    review['status'] = decision;
    review['reviewer'] = reviewer;
    review['reviewedAt'] = now;
    review['reviewNotes'] = d['notes'];
    c['review'] = review;

    final gt = (d['groundTruth'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    c['reviewerVerified'] = <String, dynamic>{
      'reviewer': reviewer,
      'reviewedAt': now,
      'status': decision,
      'groundTruth': gt,
      'notes': d['notes'],
    };

    c['dataset'] = <String, dynamic>{
      'eligible': decision == 'golden' || decision == 'training_eligible',
      'includedInVersions': c['dataset'] is Map
          ? (((c['dataset'] as Map)['includedInVersions'] as List?) ?? const <dynamic>[])
          : const <dynamic>[],
    };

    updated.add(c);
  }

  _writeJsonl(outputPath, updated);
  stdout.writeln('Applied decisions -> $outputPath (${updated.length} rows)');
}

void _report(String path) {
  final rows = _readJsonl(path);
  final counts = <String, int>{};
  for (final r in rows) {
    final status = '${(r['review'] as Map?)?['status'] ?? 'unknown'}';
    counts[status] = (counts[status] ?? 0) + 1;
  }

  stdout.writeln('Review report: $path');
  stdout.writeln('Total rows: ${rows.length}');
  for (final k in counts.keys.toList()..sort()) {
    stdout.writeln('  $k: ${counts[k]}');
  }
}
