import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final input = _arg(args, '--input',
      fallback: 'build/reports/ai_review/updated_candidates.jsonl');
  final outJson =
      _arg(args, '--out-json', fallback: 'build/reports/ai_review/dashboard.json');
  final outMd =
      _arg(args, '--out-md', fallback: 'build/reports/ai_review/dashboard.md');

  final file = File(input);
  if (!file.existsSync()) {
    stderr.writeln('Missing review data: $input');
    exitCode = 2;
    return;
  }

  final rows = file
      .readAsLinesSync()
      .where((l) => l.trim().isNotEmpty)
      .map((l) => jsonDecode(l) as Map<String, dynamic>)
      .toList();

  final statusCounts = <String, int>{};
  final privacyFlagCounts = <String, int>{};
  final qualityFlagCounts = <String, int>{};
  final reviewers = <String, int>{};
  var trainingEligible = 0;
  var golden = 0;
  var excluded = 0;

  for (final r in rows) {
    final review = (r['review'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    final status = '${review['status'] ?? 'unknown'}';
    statusCounts[status] = (statusCounts[status] ?? 0) + 1;
    final reviewer = '${review['reviewer'] ?? 'unassigned'}';
    reviewers[reviewer] = (reviewers[reviewer] ?? 0) + 1;
    final privacy = ((review['privacyFlags'] as List?) ?? const <dynamic>[]).map((e) => '$e');
    final quality = ((review['qualityFlags'] as List?) ?? const <dynamic>[]).map((e) => '$e');
    for (final p in privacy) {
      privacyFlagCounts[p] = (privacyFlagCounts[p] ?? 0) + 1;
    }
    for (final q in quality) {
      qualityFlagCounts[q] = (qualityFlagCounts[q] ?? 0) + 1;
    }
    final lc = (r['lifecycle'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    if (lc['trainingEligible'] == true) trainingEligible += 1;
    if (lc['golden'] == true) golden += 1;
    if (lc['excluded'] == true) excluded += 1;
  }

  final dashboard = <String, dynamic>{
    'generatedAt': DateTime.now().toIso8601String(),
    'input': input,
    'total': rows.length,
    'statusCounts': statusCounts,
    'privacyFlagCounts': privacyFlagCounts,
    'qualityFlagCounts': qualityFlagCounts,
    'reviewers': reviewers,
    'lifecycle': <String, dynamic>{
      'trainingEligible': trainingEligible,
      'golden': golden,
      'excluded': excluded,
    },
  };

  final outJsonFile = File(outJson);
  outJsonFile.parent.createSync(recursive: true);
  outJsonFile.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(dashboard));

  final b = StringBuffer();
  b.writeln('# Review Dashboard');
  b.writeln();
  b.writeln('- Total rows: ${rows.length}');
  b.writeln('- Training eligible: $trainingEligible');
  b.writeln('- Golden: $golden');
  b.writeln('- Excluded: $excluded');
  b.writeln();
  b.writeln('## Status counts');
  for (final k in statusCounts.keys.toList()..sort()) {
    b.writeln('- $k: ${statusCounts[k]}');
  }
  b.writeln();
  b.writeln('## Reviewer throughput');
  for (final k in reviewers.keys.toList()..sort()) {
    b.writeln('- $k: ${reviewers[k]}');
  }
  final outMdFile = File(outMd);
  outMdFile.parent.createSync(recursive: true);
  outMdFile.writeAsStringSync(b.toString());

  stdout.writeln('Wrote review dashboard: ${outJsonFile.path}');
  stdout.writeln('Wrote review dashboard markdown: ${outMdFile.path}');
}

String _arg(List<String> args, String name, {required String fallback}) {
  for (var i = 0; i < args.length; i += 1) {
    if (args[i] == name && i + 1 < args.length) return args[i + 1].trim();
    if (args[i].startsWith('$name=')) return args[i].split('=').last.trim();
  }
  return fallback;
}

