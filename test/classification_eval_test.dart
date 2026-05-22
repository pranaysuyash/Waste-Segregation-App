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
    // Verify golden directory exists
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
        expect(case_['id'], isNotNull,
            reason: 'Case $i missing required field "id"');
        expect(case_['expected'], isNotNull,
            reason: 'Case ${case_['id']} missing required field "expected"');

        final expected = case_['expected'] as Map<String, dynamic>;
        expect(expected['category'], isNotNull,
            reason: 'Case ${case_['id']} missing expected.category');
        expect(expected['material'], isNotNull,
            reason: 'Case ${case_['id']} missing expected.material');
      }
    });

    test('schema validation: each golden case matches schema', () {
      for (final (i, case_) in goldenCases.indexed) {
        // Validate required top-level fields
        expect(case_['id'], isA<String>(),
            reason: 'Case $i: "id" must be a string');
        expect(case_['description'], isA<String>(),
            reason: 'Case $i: "description" must be a string');

        final expected = case_['expected'] as Map<String, dynamic>;
        expect(expected['category'], isA<String>(),
            reason: 'Case ${case_['id']}: expected.category must be string');
        expect(expected['material'], isA<String>(),
            reason: 'Case ${case_['id']}: expected.material must be string');

        // Validate acceptance criteria
        final criteria = case_['acceptance_criteria'];
        if (criteria != null) {
          expect(criteria['min_confidence'], isA<num>(),
              reason:
                  'Case ${case_['id']}: acceptance_criteria.min_confidence must be num');
        }
      }
    });

    test('all golden cases have unique IDs', () {
      final ids = goldenCases.map((c) => c['id'] as String).toList();
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
      // Print structured report
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
        final desc = case_['description'] as String? ?? '';
        output.writeln('  [${case_['id']}] $desc');
      }

      // Print to stdout so CI can capture it
      // ignore: avoid_print
      print(output.toString());
    });
  });
}
