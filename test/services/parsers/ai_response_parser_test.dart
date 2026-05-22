import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/services/parsers/ai_response_parser.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';

void main() {
  group('AiResponseParser.cleanJsonString', () {
    test('extracts JSON from markdown code block', () {
      final raw = '```json\n{"key": "value"}\n```';
      expect(AiResponseParser.cleanJsonString(raw), '{"key": "value"}');
    });

    test('extracts JSON from code block with extra text', () {
      final raw = 'Here is the result:\n```json\n{"itemName": "bottle"}\n```';
      expect(
          AiResponseParser.cleanJsonString(raw), '{"itemName": "bottle"}');
    });

    test('extracts JSON without code block using curly braces', () {
      final raw = 'Some text {"key": "value"} more text';
      expect(AiResponseParser.cleanJsonString(raw), '{"key": "value"}');
    });

    test('returns raw string if no JSON found', () {
      final raw = 'Just some text';
      expect(AiResponseParser.cleanJsonString(raw), 'Just some text');
    });

    test('removes single-line comments', () {
      final raw = '{"key": "value" // comment\n}';
      expect(AiResponseParser.cleanJsonString(raw), '{"key": "value" \n}');
    });

    test('removes multi-line comments', () {
      final raw = '{"key": /* comment */ "value"}';
      expect(AiResponseParser.cleanJsonString(raw), '{"key":  "value"}');
    });

    test('handles empty string', () {
      expect(AiResponseParser.cleanJsonString(''), '');
    });
  });

  group('AiResponseParser.parseBool', () {
    test('returns null for null input', () {
      expect(AiResponseParser.parseBool(null), isNull);
    });

    test('returns bool for bool input', () {
      expect(AiResponseParser.parseBool(true), isTrue);
      expect(AiResponseParser.parseBool(false), isFalse);
    });

    test('parses int as bool', () {
      expect(AiResponseParser.parseBool(1), isTrue);
      expect(AiResponseParser.parseBool(0), isFalse);
    });

    test('parses string as bool', () {
      expect(AiResponseParser.parseBool('true'), isTrue);
      expect(AiResponseParser.parseBool('false'), isFalse);
      expect(AiResponseParser.parseBool('1'), isTrue);
    });

    test('returns false for unknown string', () {
      expect(AiResponseParser.parseBool('maybe'), isFalse);
    });
  });

  group('AiResponseParser.parseInt', () {
    test('returns null for null input', () {
      expect(AiResponseParser.parseInt(null), isNull);
    });

    test('returns int for int input', () {
      expect(AiResponseParser.parseInt(42), 42);
    });

    test('parses string as int', () {
      expect(AiResponseParser.parseInt('42'), 42);
    });

    test('returns null for unparseable string', () {
      expect(AiResponseParser.parseInt('not-a-number'), isNull);
    });
  });

  group('AiResponseParser.parseDouble', () {
    test('returns null for null input', () {
      expect(AiResponseParser.parseDouble(null), isNull);
    });

    test('returns double for double input', () {
      expect(AiResponseParser.parseDouble(3.14), 3.14);
    });

    test('converts int to double', () {
      expect(AiResponseParser.parseDouble(42), 42.0);
    });

    test('parses string as double', () {
      expect(AiResponseParser.parseDouble('3.14'), 3.14);
    });
  });

  group('AiResponseParser.parseRecyclingCode', () {
    test('returns null for null input', () {
      expect(AiResponseParser.parseRecyclingCode(null), isNull);
    });

    test('returns int for int input', () {
      expect(AiResponseParser.parseRecyclingCode(1), 1);
    });

    test('extracts number from string', () {
      expect(AiResponseParser.parseRecyclingCode('PET (1)'), 1);
      expect(AiResponseParser.parseRecyclingCode('5'), 5);
    });

    test('returns null for string with no digits', () {
      expect(AiResponseParser.parseRecyclingCode('PET'), isNull);
    });
  });

  group('AiResponseParser.safeStringParse', () {
    test('returns null for null input', () {
      expect(AiResponseParser.safeStringParse(null), isNull);
    });

    test('returns trimmed string for string input', () {
      expect(AiResponseParser.safeStringParse('  hello  '), 'hello');
    });

    test('converts non-string to string', () {
      expect(AiResponseParser.safeStringParse(42), '42');
    });

    test('returns null for empty string', () {
      expect(AiResponseParser.safeStringParse(''), isNull);
    });
  });

  group('AiResponseParser.parseStringListSafely', () {
    test('returns empty list for null', () {
      expect(AiResponseParser.parseStringListSafely(null), isEmpty);
    });

    test('converts list of values', () {
      expect(AiResponseParser.parseStringListSafely(['a', 'b']),
          ['a', 'b']);
    });

    test('parses JSON array string', () {
      expect(
          AiResponseParser.parseStringListSafely('["a", "b"]'), ['a', 'b']);
    });

    test('splits comma-separated string', () {
      expect(
          AiResponseParser.parseStringListSafely('a, b, c'), ['a', 'b', 'c']);
    });
  });

  group('AiResponseParser.parseStringMapSafely', () {
    test('returns null for null input', () {
      expect(AiResponseParser.parseStringMapSafely(null), isNull);
    });

    test('converts map entries', () {
      final result =
          AiResponseParser.parseStringMapSafely({'key': 'value', 'num': 42});
      expect(result, {'key': 'value', 'num': '42'});
    });
  });

  group('AiResponseParser.parseDisposalInstructions', () {
    test('returns default instructions for null', () {
      final result = AiResponseParser.parseDisposalInstructions(null);
      expect(result.primaryMethod, 'Review required');
      expect(result.steps, ['Please review manually']);
    });

    test('parses Map input', () {
      final result = AiResponseParser.parseDisposalInstructions({
        'primaryMethod': 'Recycle',
        'steps': ['Step 1', 'Step 2']
      });
      expect(result.primaryMethod, 'Recycle');
      expect(result.steps, ['Step 1', 'Step 2']);
    });

    test('parses String input', () {
      final result =
          AiResponseParser.parseDisposalInstructions('Dispose properly');
      expect(result.primaryMethod, 'Dispose properly');
    });

    test('parses List input', () {
      final result = AiResponseParser.parseDisposalInstructions([
        'Recycle',
        'Clean first',
        'Sort by type'
      ]);
      expect(result.primaryMethod, 'Recycle');
      expect(result.steps.length, 3);
    });
  });

  group('AiResponseParser.parseAlternatives', () {
    test('returns empty list for null', () {
      expect(AiResponseParser.parseAlternatives(null), isEmpty);
    });

    test('parses valid alternatives', () {
      final result = AiResponseParser.parseAlternatives([
        {
          'itemName': 'Paper bag',
          'category': 'Dry Waste',
          'reason': 'More eco-friendly',
          'confidence': 0.85,
        }
      ]);
      expect(result.length, 1);
      expect(result[0].category, 'Dry Waste');
      expect(result[0].reason, 'More eco-friendly');
      expect(result[0].confidence, 0.85);
    });

    test('filters out invalid alternatives', () {
      final result = AiResponseParser.parseAlternatives([
        {'category': 'Dry Waste', 'reason': 'Valid', 'confidence': 0.9},
        'not a map',
      ]);
      expect(result.length, 1);
    });
  });

  group('AiResponseParser.parseStepsFromString', () {
    test('returns default steps for empty string', () {
      expect(AiResponseParser.parseStepsFromString(''),
          ['Please review manually']);
    });

    test('splits by newline', () {
      expect(AiResponseParser.parseStepsFromString('Step 1\nStep 2'),
          ['Step 1', 'Step 2']);
    });

    test('splits by comma', () {
      expect(AiResponseParser.parseStepsFromString('Step 1, Step 2'),
          ['Step 1', 'Step 2']);
    });

    test('splits by numbered list without newlines', () {
      expect(AiResponseParser.parseStepsFromString('1. First 2. Second'),
          ['First', 'Second']);
    });
  });

  group('AiResponseParser.processResponse', () {
    test('parses valid JSON response', () {
      final responseData = {
        'choices': [
          {
            'message': {
              'content': jsonEncode({
                'itemName': 'Plastic Bottle',
                'category': 'Dry Waste',
                'confidence': 0.95,
              })
            }
          }
        ]
      };

      final result = AiResponseParser.processResponse(
        responseData,
        '/images/test.jpg',
        'Bangalore, IN',
        'en',
        null,
        'test-123',
        provider: 'openai',
        model: 'gpt-4',
      );

      expect(result.itemName, 'Plastic Bottle');
      expect(result.category, 'Dry Waste');
      expect(result.id, 'test-123');
    });

    test('returns fallback on empty choices', () {
      final responseData = {'choices': <dynamic>[]};
      final result = AiResponseParser.processResponse(
        responseData,
        '/images/test.jpg',
        'Bangalore, IN',
        'en',
        null,
        null,
        provider: 'openai',
        model: 'gpt-4',
      );
      expect(result.category, 'Requires Manual Review');
    });

    test('returns fallback on missing choices', () {
      final responseData = <String, dynamic>{};
      final result = AiResponseParser.processResponse(
        responseData,
        '/images/test.jpg',
        'Bangalore, IN',
        'en',
        null,
        null,
        provider: 'openai',
        model: 'gpt-4',
      );
      expect(result.category, 'Requires Manual Review');
    });

    test('returns fallback on invalid JSON content', () {
      final responseData = {
        'choices': [
          {
            'message': {'content': 'Not valid JSON'}
          }
        ]
      };

      final result = AiResponseParser.processResponse(
        responseData,
        '/images/test.jpg',
        'Bangalore, IN',
        'en',
        null,
        'test-456',
        provider: 'openai',
        model: 'gpt-4',
      );

      expect(result.id, 'test-456');
    });

    test('handles JSON in markdown code block', () {
      final responseData = {
        'choices': [
          {
            'message': {
              'content': '```json\n{"itemName": "Can", "category": "Dry Waste"}\n```'
            }
          }
        ]
      };

      final result = AiResponseParser.processResponse(
        responseData,
        '/images/can.jpg',
        'Bangalore, IN',
        'en',
        null,
        null,
        provider: 'gemini',
        model: 'gemini-2.0-flash',
      );

      expect(result.itemName, 'Can');
      expect(result.category, 'Dry Waste');
    });
  });
}
