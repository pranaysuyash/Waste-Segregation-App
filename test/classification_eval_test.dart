import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
// Imports reserved for future provider/model fixture evaluation:
// import 'package:waste_segregation_app/models/waste_classification.dart';
// import 'package:waste_segregation_app/models/vision_model_config.dart';
// import 'package:waste_segregation_app/services/model_selection_service.dart';

/// Golden-image evaluation harness for classification quality.
///
/// Each golden case is a JSON entry with expected category/material/disposal
/// output plus optionally a fixture path for the provider output file.
///
/// Usage:
///   flutter test test/classification_eval_test.dart
///
/// To add golden samples:
///   1. Add a JSON entry to eval/classification/golden/golden_cases_v1.jsonl
///   2. Optionally add provider-specific outputs to eval/classification/fixtures/
///   3. This test loads and validates them
void main() {
  final goldenDir = Directory('eval/classification/golden');
  final goldenFile = File('${goldenDir.path}/golden_cases_v1.jsonl');

  setUpAll(() {
    if (!goldenDir.existsSync()) {
      throw StateError(
        'Golden eval directory not found at ${goldenDir.path}. '
        'Run from project root.',
      );
    }
  });

  group('Golden classification eval harness', () {
    late List<Map<String, dynamic>> goldenCases;
    late int totalCases;

    String caseId(Map<String, dynamic> case_) =>
        (case_['case_id'] ?? case_['id'] ?? 'unknown') as String;

    setUp(() {
      goldenCases = [];

      if (goldenFile.existsSync()) {
        final lines = goldenFile.readAsLinesSync();
        for (final line in lines) {
          if (line.trim().isEmpty) continue;
          try {
            goldenCases.add(jsonDecode(line) as Map<String, dynamic>);
          } catch (e) {
            // Skip malformed lines
          }
        }
      }
      totalCases = goldenCases.length;
    });

    test('golden cases file exists and has entries', () {
      expect(goldenFile.existsSync(), isTrue,
          reason: 'Golden cases file not found at ${goldenFile.path}');
      expect(totalCases, greaterThan(0),
          reason: 'Golden cases file has no valid JSON entries');
    });

    test('each golden case has required fields', () {
      for (final (i, case_) in goldenCases.indexed) {
        final id = caseId(case_);
        expect(case_['case_id'] ?? case_['id'], isNotNull,
            reason: 'Case $i missing required field "case_id" or "id"');
        expect(case_['expected'], isNotNull,
            reason: 'Case $id missing required field "expected"');

        final expected = case_['expected'] as Map<String, dynamic>;
        expect(expected['category'], isNotNull,
            reason: 'Case $id missing expected.category');
        expect(expected['sub_category'] ?? expected['material'], isNotNull,
            reason: 'Case $id missing expected.sub_category or expected.material');
      }
    });

    test('schema validation: each golden case matches schema', () {
      for (final (i, case_) in goldenCases.indexed) {
        final id = caseId(case_);
        expect(caseId(case_), isA<String>(),
            reason: 'Case $i: "case_id"/"id" must be a string');

        final description = case_['input'] is Map
            ? (case_['input'] as Map)['description']
            : case_['description'];
        expect(description, isA<String>(),
            reason: 'Case $id: description must be a string');

        final expected = case_['expected'] as Map<String, dynamic>;
        expect(expected['category'], isA<String>(),
            reason: 'Case $id: expected.category must be string');
        final material =
            expected['sub_category'] ?? expected['material'];
        expect(material, isA<String>(),
            reason: 'Case $id: expected.sub_category/material must be string');

        final acceptance = case_['acceptance'] ?? case_['acceptance_criteria'];
        if (acceptance != null) {
          final acc = acceptance as Map;
          expect(
            acc['acceptable_categories'] ?? acc['min_confidence'],
            isNotNull,
            reason:
                'Case $id: acceptance must have acceptable_categories or min_confidence',
          );
        }
      }
    });

    test('all golden cases have unique IDs', () {
      final ids = goldenCases.map((c) => caseId(c)).toList();
      final uniqueIds = ids.toSet();
      final duplicateIds = <String>{};
      final seen = <String>{};
      for (final id in ids) {
        if (!seen.add(id)) duplicateIds.add(id);
      }
      expect(uniqueIds.length, ids.length,
          reason: 'Duplicate golden case IDs found: ${duplicateIds.join(', ')}');
    });

    test('report: golden case summary', () {
      final output = StringBuffer();
      output.writeln('=== Classification Eval Report ===');
      output.writeln('Total golden cases: $totalCases');
      output.writeln('');
      output.writeln('Categories tested:');

      final categories = <String, int>{};
      for (final case_ in goldenCases) {
        final expected = case_['expected'] as Map<String, dynamic>;
        final cat = expected['category'] as String;
        categories[cat] = (categories[cat] ?? 0) + 1;
      }
      final sortedEntries = categories.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      for (final entry in sortedEntries) {
        output.writeln('  ${entry.key}: ${entry.value} cases');
      }

      output.writeln('');
      output.writeln('Case IDs:');
      for (final case_ in goldenCases) {
        final input = case_['input'] as Map<String, dynamic>?;
        final desc = input?['description'] as String? ??
            case_['description'] as String? ??
            '';
        output.writeln('  [${caseId(case_)}] $desc');
      }

      // ignore: avoid_print
      print(output.toString());
    });
  });
}
