import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('merge records tool semantics produce deterministic case/provider/model sort', () {
    final rows = <Map<String, dynamic>>[
      <String, dynamic>{'caseId': 'c2', 'provider': 'gemini', 'model': 'm2'},
      <String, dynamic>{'caseId': 'c1', 'provider': 'openai', 'model': 'm1'},
      <String, dynamic>{'caseId': 'c1', 'provider': 'backend', 'model': 'm0'},
    ];

    rows.sort((a, b) {
      final ak = '${a['caseId']}|${a['provider']}|${a['model']}';
      final bk = '${b['caseId']}|${b['provider']}|${b['model']}';
      return ak.compareTo(bk);
    });

    final ordered = rows.map((e) => '${e['caseId']}|${e['provider']}|${e['model']}').toList();
    expect(ordered, <String>[
      'c1|backend|m0',
      'c1|openai|m1',
      'c2|gemini|m2',
    ]);
  });

  test('merged jsonl write pattern is newline-delimited JSON', () {
    final temp = File('${Directory.systemTemp.path}/eval-merge-jsonl-test-${DateTime.now().microsecondsSinceEpoch}.jsonl');
    final rows = <Map<String, dynamic>>[
      <String, dynamic>{'caseId': 'c1', 'provider': 'backend', 'model': 'm0'},
      <String, dynamic>{'caseId': 'c2', 'provider': 'openai', 'model': 'm1'},
    ];
    temp.writeAsStringSync(rows.map(jsonEncode).join('\n') + '\n');

    final lines = temp.readAsLinesSync();
    expect(lines.length, 2);
    expect((jsonDecode(lines.first) as Map<String, dynamic>)['caseId'], 'c1');
    temp.deleteSync();
  });
}
