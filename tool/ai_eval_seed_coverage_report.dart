import 'dart:convert';
import 'dart:io';

class CoverageRule {
  const CoverageRule({required this.id, required this.description, required this.matches});
  final String id;
  final String description;
  final bool Function(Map<String, dynamic>) matches;
}

String _text(Map<String, dynamic> row) {
  final expected = (row['expected'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
  final hints = (row['inputHints'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
  return [
    '${row['id'] ?? ''}',
    '${row['imageRef'] ?? ''}',
    '${expected['itemName'] ?? ''}',
    '${expected['category'] ?? ''}',
    '${expected['subcategory'] ?? ''}',
    '${expected['materialType'] ?? ''}',
    '${hints['knownContext'] ?? ''}',
    '${row['notes'] ?? ''}',
  ].join(' ').toLowerCase();
}

bool _containsAny(String t, List<String> words) => words.any(t.contains);

void main(List<String> args) {
  final input = _arg(args, '--input', fallback: 'test/fixtures/ai_eval/golden_cases.jsonl');
  final out = _arg(args, '--out', fallback: 'build/reports/ai_eval/seed_coverage_report.json');

  final file = File(input);
  if (!file.existsSync()) {
    stderr.writeln('Missing input: $input');
    exitCode = 2;
    return;
  }

  final rows = file
      .readAsLinesSync()
      .where((l) => l.trim().isNotEmpty)
      .map((l) => jsonDecode(l) as Map<String, dynamic>)
      .toList();

  final rules = <CoverageRule>[
    CoverageRule(id: 'common_household_family', description: 'common household family', matches: (r) => _containsAny(_text(r), ['plastic bottle','dirty plastic','milk packet','cardboard','newspaper','paper cup','metal can','glass bottle','food scraps','tea bag','coconut shell','garden waste','textile'])),
    CoverageRule(id: 'safety_critical_family', description: 'safety critical family', matches: (r) => _containsAny(_text(r), ['lithium battery','swollen battery','medicine strip','sanitary waste','syringe','chemical bottle','aerosol','cfl','thermometer'])),
    CoverageRule(id: 'ewaste_family', description: 'e-waste family', matches: (r) => _containsAny(_text(r), ['charging cable','phone charger','earphones','old phone','keyboard','circuit board','power adapter','led bulb'])),
    CoverageRule(id: 'ambiguous_family', description: 'ambiguous/hard family', matches: (r) => _containsAny(_text(r), ['greasy pizza','clean pizza','bioplastic','tetra pak','wax coated','plastic coated','foil lined','dirty aluminium'])),
    CoverageRule(id: 'multi_item_family', description: 'multi-item family', matches: (r) => ((r['inputHints'] as Map?)?['multiItem'] == true) || _containsAny(_text(r), ['mix','multi-item'])),
    CoverageRule(id: 'region_global_family', description: 'region/global/local-rule family', matches: (r) => _containsAny(_text(r), ['bbmp','unknown city','non india','global','apartment society','campus office','conflicting local'])),
    CoverageRule(id: 'local_rule_fields', description: 'local/global policy fields present', matches: (r) => r['localRuleId'] != null && r['authority'] != null),
    CoverageRule(id: 'multi_item_schema_fields', description: 'multi-item schema fields present', matches: (r) => (r['expectedItems'] is List) || ((r['inputHints'] as Map?)?['multiItem'] == true)),
    CoverageRule(id: 'at_least_100_cases', description: 'at least 100 meaningful/placeholder cases', matches: (_) => rows.length >= 100),
  ];

  final result = <String, dynamic>{
    'generatedAt': DateTime.now().toIso8601String(),
    'totalCases': rows.length,
    'rules': <Map<String, dynamic>>[],
  };

  var passCount = 0;
  for (final rule in rules) {
    final hits = rows.where(rule.matches).toList();
    final passed = rule.id == 'at_least_100_cases' ? rows.length >= 100 : hits.isNotEmpty;
    if (passed) passCount += 1;
    (result['rules'] as List).add(<String, dynamic>{
      'id': rule.id,
      'description': rule.description,
      'passed': passed,
      'hitCount': hits.length,
      'exampleCaseIds': hits.take(3).map((h) => h['id']).toList(),
    });
  }

  result['passedRules'] = passCount;
  result['totalRules'] = rules.length;
  result['allRulesPassed'] = passCount == rules.length;

  final outFile = File(out);
  outFile.parent.createSync(recursive: true);
  outFile.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(result));

  stdout.writeln('Seed coverage report written: $out');
  stdout.writeln('Passed rules: $passCount/${rules.length}');
}

String _arg(List<String> args, String name, {required String fallback}) {
  for (var i = 0; i < args.length; i += 1) {
    if (args[i] == name && i + 1 < args.length) return args[i + 1].trim();
    if (args[i].startsWith('$name=')) return args[i].split('=').last.trim();
  }
  return fallback;
}
