import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/services/prompts/classification_prompts.dart';

void main() {
  group('ClassificationPrompts.systemPrompt', () {
    test('contains the default region', () {
      final prompt = ClassificationPrompts.systemPrompt('Bangalore, IN');
      expect(prompt, contains('Bangalore, IN'));
    });

    test('mentions waste classification', () {
      final prompt = ClassificationPrompts.systemPrompt('Mumbai, IN');
      expect(prompt, contains('waste classification'));
    });

    test('mentions recycling and disposal', () {
      final prompt = ClassificationPrompts.systemPrompt('Delhi, IN');
      expect(prompt, contains('recycling'));
      expect(prompt, contains('disposal'));
    });
  });

  group('ClassificationPrompts.mainClassificationPrompt', () {
    test('contains basic classification section', () {
      expect(
          ClassificationPrompts.mainClassificationPrompt, contains('BASIC CLASSIFICATION'));
    });

    test('contains environmental impact section', () {
      expect(
          ClassificationPrompts.mainClassificationPrompt, contains('ENVIRONMENTAL IMPACT'));
    });

    test('contains circular economy section', () {
      expect(
          ClassificationPrompts.mainClassificationPrompt, contains('CIRCULAR ECONOMY'));
    });

    test('contains local guidelines section', () {
      expect(ClassificationPrompts.mainClassificationPrompt,
          contains('LOCAL GUIDELINES'));
    });

    test('contains safety section', () {
      expect(ClassificationPrompts.mainClassificationPrompt,
          contains('SAFETY & HANDLING'));
    });

    test('contains standard fields section', () {
      expect(ClassificationPrompts.mainClassificationPrompt,
          contains('STANDARD FIELDS'));
    });

    test('contains special instructions for Bangalore', () {
      expect(ClassificationPrompts.mainClassificationPrompt,
          contains('BANGALORE'));
    });

    test('instructs to return only JSON', () {
      expect(ClassificationPrompts.mainClassificationPrompt,
          contains('Return ONLY the JSON'));
    });

    test('has non-empty content', () {
      expect(
          ClassificationPrompts.mainClassificationPrompt.length, greaterThan(500));
    });
  });

  group('ClassificationPrompts.correctionPrompt', () {
    test('contains the user correction text', () {
      final prompt = ClassificationPrompts.correctionPrompt(
        {'itemName': 'Bottle'},
        'This is actually paper',
        'I can see fibers',
      );
      expect(prompt, contains('This is actually paper'));
      expect(prompt, contains('I can see fibers'));
    });

    test('contains previous classification data', () {
      final prompt = ClassificationPrompts.correctionPrompt(
        {'itemName': 'Bottle', 'category': 'Dry Waste'},
        'Paper bag',
        null,
      );
      expect(prompt, contains('Bottle'));
      expect(prompt, contains('Paper bag'));
    });

    test('includes previous classification as JSON', () {
      final prompt = ClassificationPrompts.correctionPrompt(
        {'itemName': 'Can'},
        'Glass',
        null,
      );
      expect(prompt, contains('"itemName"'));
      expect(prompt, contains('"Can"'));
    });

    test('handles null reason with fallback text', () {
      final prompt = ClassificationPrompts.correctionPrompt(
        {'itemName': 'Bottle'},
        'Paper',
        null,
      );
      expect(prompt, contains('Not provided'));
    });

    test('mentions disagreement area', () {
      final prompt = ClassificationPrompts.correctionPrompt(
        {'itemName': 'Bottle'},
        'This is glass',
        'It is transparent and heavy',
      );
      expect(prompt, contains('disagreement'));
    });
  });
}
