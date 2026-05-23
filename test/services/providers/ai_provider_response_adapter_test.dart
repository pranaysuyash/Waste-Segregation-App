import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/services/providers/ai_provider_response.dart';
import 'package:waste_segregation_app/services/providers/ai_provider_response_adapter.dart';

void main() {
  group('AiProviderResponseAdapter.toParserMap', () {
    test('OpenAI returns rawResponseMap unchanged', () {
      const response = AiProviderResponse(
        provider: 'openai',
        model: 'gpt-4.1-nano',
        rawResponseMap: {
          'choices': [
            {
              'message': {'content': '{"itemName":"Bottle"}'},
            },
          ],
        },
        textContent: null,
      );

      final result = AiProviderResponseAdapter.toParserMap(response);

      expect(result, same(response.rawResponseMap));
    });

    test('Gemini with textContent returns choices/message/content wrapper', () {
      const response = AiProviderResponse(
        provider: 'gemini',
        model: 'gemini-2.0-flash',
        rawResponseMap: {
          'candidates': [
            {
              'content': {
                'parts': [{'text': '{"itemName":"Can"}'}],
              },
            },
          ],
        },
        textContent: '{"itemName":"Can"}',
      );

      final result = AiProviderResponseAdapter.toParserMap(response);

      expect(result, hasLength(1));
      expect(result['choices'], isA<List>());
      final choice = (result['choices'] as List).first as Map<String, dynamic>;
      expect(choice['message']['content'], equals('{"itemName":"Can"}'));
    });

    test('Backend with textContent returns choices/message/content wrapper', () {
      const response = AiProviderResponse(
        provider: 'backend',
        model: 'classifyImage',
        rawResponseMap: {'result': 'ok'},
        textContent: '{"itemName":"Box"}',
      );

      final result = AiProviderResponseAdapter.toParserMap(response);

      expect(result['choices'], isA<List>());
      final choice = (result['choices'] as List).first as Map<String, dynamic>;
      expect(choice['message']['content'], equals('{"itemName":"Box"}'));
    });

    test('non-OpenAI without textContent falls back to rawResponseMap', () {
      const response = AiProviderResponse(
        provider: 'gemini',
        model: 'gemini-2.0-flash',
        rawResponseMap: {'candidates': []},
        textContent: null,
      );

      final result = AiProviderResponseAdapter.toParserMap(response);

      expect(result, same(response.rawResponseMap));
    });

    test('non-OpenAI with empty textContent falls back to rawResponseMap', () {
      const response = AiProviderResponse(
        provider: 'backend',
        model: 'classifyImage',
        rawResponseMap: {'error': 'no data'},
        textContent: '',
      );

      final result = AiProviderResponseAdapter.toParserMap(response);

      expect(result, same(response.rawResponseMap));
    });
  });
}
