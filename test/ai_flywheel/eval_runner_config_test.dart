import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/ai_flywheel/eval_runner.dart';

void main() {
  test('runWithConfig uses custom recorded file and provider label', () async {
    final tempDir = Directory.systemTemp.createTempSync('eval-runner-config-test');
    final fixtureRoot = Directory('${tempDir.path}/fixtures')..createSync(recursive: true);
    final recordedDir = Directory('${fixtureRoot.path}/recorded_outputs')..createSync(recursive: true);

    final caseRow = <String, dynamic>{
      'id': 'case_001_custom',
      'imageRef': 'fixtures/images/custom.jpg',
      'region': 'Bangalore, IN',
      'language': 'en',
      'expected': <String, dynamic>{'category': 'Wet Waste'},
      'mustNot': <String>['Dry Waste'],
      'safetyCritical': false,
      'localRuleCritical': true,
    };

    final recordedRow = <String, dynamic>{
      'caseId': 'case_001_custom',
      'category': 'Wet Waste',
      'provider': 'openai',
      'model': 'gpt-4.1-nano',
      'confidence': 0.88,
      'route': 'direct',
      'latencyMs': 930,
      'estimatedCostUsd': 0.001,
      'cacheHit': false,
    };

    File('${fixtureRoot.path}/golden_cases.jsonl').writeAsStringSync('${jsonEncode(caseRow)}\n');
    File('${recordedDir.path}/custom.jsonl').writeAsStringSync('${jsonEncode(recordedRow)}\n');

    final runner = EvalRunner(fixtureRoot: fixtureRoot.path);
    final summary = await runner.runWithConfig(
      mode: 'recorded',
      recordedFilePath: '${recordedDir.path}/custom.jsonl',
      providerLabel: 'openai/direct',
    );

    expect(summary.cases, 1);
    expect(summary.strictPass, 1);
    expect(summary.providerLabel, 'openai/direct');
    expect(summary.outcomes.first.provider, 'openai');
  });
}
