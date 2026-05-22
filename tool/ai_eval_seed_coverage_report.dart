import 'dart:convert';
import 'dart:io';

class CoverageRule {
  const CoverageRule({
    required this.id,
    required this.description,
    required this.matches,
  });

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
    CoverageRule(id: 'clean_plastic_bottle', description: 'clean plastic bottle', matches: (r) {
      final t = _text(r);
      return t.contains('plastic bottle') && ((r['expected'] as Map?)?['category'] == 'Dry Waste');
    }),
    CoverageRule(id: 'dirty_plastic_container', description: 'dirty plastic container', matches: (r) => _containsAny(_text(r), ['dirty plastic', 'soiled plastic'])),
    CoverageRule(id: 'greasy_pizza_box', description: 'greasy pizza box', matches: (r) => _containsAny(_text(r), ['greasy pizza', 'pizza box'])),
    CoverageRule(id: 'clean_cardboard', description: 'clean cardboard', matches: (r) => _containsAny(_text(r), ['clean cardboard'])),
    CoverageRule(id: 'banana_peel_food_waste', description: 'banana peel / food waste', matches: (r) => _containsAny(_text(r), ['banana peel', 'food waste'])),
    CoverageRule(id: 'battery', description: 'battery', matches: (r) => _containsAny(_text(r), ['battery'])),
    CoverageRule(id: 'power_bank', description: 'power bank', matches: (r) => _containsAny(_text(r), ['power bank'])),
    CoverageRule(id: 'medicine_strip', description: 'medicine strip', matches: (r) => _containsAny(_text(r), ['medicine strip'])),
    CoverageRule(id: 'expired_medicine_bottle', description: 'expired medicine bottle', matches: (r) => _containsAny(_text(r), ['expired medicine bottle'])),
    CoverageRule(id: 'sanitary_waste', description: 'sanitary waste', matches: (r) => _containsAny(_text(r), ['sanitary waste'])),
    CoverageRule(id: 'medical_mask', description: 'medical mask', matches: (r) => _containsAny(_text(r), ['medical mask', 'mask'])),
    CoverageRule(id: 'syringe_sharps', description: 'syringe/sharps placeholder', matches: (r) => _containsAny(_text(r), ['syringe', 'sharp'])),
    CoverageRule(id: 'ewaste_cable', description: 'e-waste cable', matches: (r) => _containsAny(_text(r), ['ewaste cable', 'e-waste cable'])),
    CoverageRule(id: 'phone_charger', description: 'phone charger', matches: (r) => _containsAny(_text(r), ['phone charger'])),
    CoverageRule(id: 'broken_glass', description: 'broken glass', matches: (r) => _containsAny(_text(r), ['broken glass'])),
    CoverageRule(id: 'glass_bottle', description: 'glass bottle', matches: (r) => _containsAny(_text(r), ['glass bottle'])),
    CoverageRule(id: 'aerosol_can', description: 'aerosol can', matches: (r) => _containsAny(_text(r), ['aerosol'])),
    CoverageRule(id: 'paint_chemical', description: 'paint/chemical container', matches: (r) => _containsAny(_text(r), ['paint', 'chemical container'])),
    CoverageRule(id: 'multilayer_chips_packet', description: 'multilayer chips packet', matches: (r) => _containsAny(_text(r), ['chips packet', 'multilayer'])),
    CoverageRule(id: 'compostable_looking_bag', description: 'compostable-looking plastic bag', matches: (r) => _containsAny(_text(r), ['compostable', 'plastic bag'])),
    CoverageRule(id: 'paper_cup_lining', description: 'paper cup with plastic lining', matches: (r) => _containsAny(_text(r), ['paper cup', 'plastic lining'])),
    CoverageRule(id: 'non_waste_object', description: 'non-waste object', matches: (r) => _containsAny(_text(r), ['non-waste', 'non waste', 'toy'])),
    CoverageRule(id: 'multi_item', description: 'multi-item mixed waste placeholder', matches: (r) => _containsAny(_text(r), ['multi-item', 'mixed waste']) || ((r['inputHints'] as Map?)?['multiItem'] == true)),
    CoverageRule(id: 'bbmp_specific', description: 'Bangalore/BBMP edge case', matches: (r) => _containsAny(_text(r), ['bbmp', 'bangalore'])),
    CoverageRule(id: 'global_fallback', description: 'generic/global fallback case', matches: (r) => _containsAny(_text(r), ['global'])),
  ];

  final result = <String, dynamic>{
    'generatedAt': DateTime.now().toIso8601String(),
    'totalCases': rows.length,
    'rules': <Map<String, dynamic>>[],
  };

  var passCount = 0;
  for (final rule in rules) {
    final hits = rows.where(rule.matches).toList();
    final passed = hits.isNotEmpty;
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
