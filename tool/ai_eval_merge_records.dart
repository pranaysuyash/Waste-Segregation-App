import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final inputsArg = _arg(args, '--inputs', fallback: '');
  final out = _arg(args, '--out', fallback: 'build/reports/ai_eval/merged_records.jsonl');
  if (inputsArg.trim().isEmpty) {
    stderr.writeln('Provide --inputs as comma-separated JSONL paths');
    exitCode = 2;
    return;
  }

  final inputs = inputsArg
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  final merged = <Map<String, dynamic>>[];
  for (final path in inputs) {
    final file = File(path);
    if (!file.existsSync()) {
      stderr.writeln('Skipping missing: $path');
      continue;
    }
    final lines = file.readAsLinesSync().where((l) => l.trim().isNotEmpty);
    for (final l in lines) {
      merged.add(jsonDecode(l) as Map<String, dynamic>);
    }
  }

  merged.sort((a, b) {
    final ak = '${a['caseId']}|${a['provider']}|${a['model']}';
    final bk = '${b['caseId']}|${b['provider']}|${b['model']}';
    return ak.compareTo(bk);
  });

  final outFile = File(out);
  outFile.parent.createSync(recursive: true);
  outFile.writeAsStringSync(merged.map(jsonEncode).join('\n') + '\n');
  stdout.writeln('Merged ${merged.length} rows -> $out');
}

String _arg(List<String> args, String name, {required String fallback}) {
  for (var i = 0; i < args.length; i += 1) {
    if (args[i] == name && i + 1 < args.length) return args[i + 1].trim();
    if (args[i].startsWith('$name=')) return args[i].split('=').last.trim();
  }
  return fallback;
}
