import 'ai_provider_response.dart';

/// Converts [AiProviderResponse] from any provider into the map shape
/// expected by `_processAiResponseData` (the OpenAI choices format).
///
/// Each provider returns a different wire format:
///   - OpenAI:  `{ choices: [{ message: { content: "<json>" } }] }`  (rawResponseMap)
///   - Gemini:  `textContent` field with the classification JSON string
///   - Backend: `textContent` field with the classification JSON string
///
/// This adapter normalises all three so the parser never needs to know
/// which provider was used.
class AiProviderResponseAdapter {
  static Map<String, dynamic> toParserMap(AiProviderResponse response) {
    if (response.provider == 'openai') {
      return response.rawResponseMap;
    }

    final text = response.textContent;
    if (text != null && text.isNotEmpty) {
      return {
        'choices': [
          {
            'message': {'content': text}
          }
        ]
      };
    }

    return response.rawResponseMap;
  }
}
