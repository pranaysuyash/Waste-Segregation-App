#!/usr/bin/env python3
"""Apply Phase 2A provider-client refactoring to ai_service.dart.

This script replaces the raw HTTP call sections in _analyzeWithOpenAI and
_analyzeWithGemini with delegations to the respective provider clients.
It is idempotent - safe to re-run.
"""

import re

FILE = "lib/services/ai_service.dart"

with open(FILE) as f:
    content = f.read()

changes = 0

# ----------------------------------------------------------------
# 1. Add imports if not present
# ----------------------------------------------------------------
if "openai_provider_client.dart" not in content:
    content = content.replace(
        "import 'package:waste_segregation_app/utils/production_safety_config.dart';",
        "import 'package:waste_segregation_app/utils/production_safety_config.dart';\n"
        "import 'package:waste_segregation_app/services/providers/openai_provider_client.dart';\n"
        "import 'package:waste_segregation_app/services/providers/gemini_provider_client.dart';"
    )
    changes += 1
    print("Added provider client imports")

# ----------------------------------------------------------------
# 2. Add provider client fields after _webSaveCallCount
# ----------------------------------------------------------------
field_block = """
  late final OpenAiProviderClient _openAiProvider = OpenAiProviderClient(
    dio: _dio,
    baseUrl: openAiBaseUrl,
    apiKey: openAiApiKey,
    model: ApiConfig.primaryModel,
  );

  late final GeminiProviderClient _geminiProvider = GeminiProviderClient(
    dio: _dio,
    baseUrl: geminiBaseUrl,
    apiKey: geminiApiKey,
    model: ApiConfig.tertiaryModel,
  );
"""

if "late final OpenAiProviderClient" not in content:
    content = content.replace(
        "  int _webSaveCallCount = 0;\n",
        "  int _webSaveCallCount = 0;\n" + field_block,
    )
    changes += 1
    print("Added provider client fields")

# ----------------------------------------------------------------
# 3. Replace _analyzeWithOpenAI HTTP body
# ----------------------------------------------------------------
# The replacement: from compression through token extraction, use provider
openai_old_start = """    final openAiBody = <String, dynamic>{
      'model': modelName,
      'messages': [
        {'role': 'system', 'content': _systemPrompt},
        {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text':
                  '$_mainClassificationPrompt\\n\\nAdditional context:\\n- Region: $region\\n- Instructions language: $language\\n- Image source: web upload'
            },
            {
              'type': 'image_url',
              'image_url': {'url': 'data:$mimeType;base64,$base64Image'}
            }
          ]
        }
      ],
      'max_tokens': 1500,
      'temperature': 0.1
    };

    late final Response response;
    try {
      response = await _dio.post(
        '$openAiBaseUrl/chat/completions',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $openAiApiKey',
          },
        ),
        data: openAiBody,
        cancelToken: _cancelToken,
      );
    } on DioException catch (e) {
      _handleDioException(e, provider: providerName, model: modelName);
      rethrow;
    }

    if (response.statusCode != 200) {
      throw Exception(
          'OpenAI request failed with status ${response.statusCode}');
    }

    final processingTime = DateTime.now().difference(startTime);
    final Map<String, dynamic> responseData = response.data;

    final usage = responseData['usage'] as Map<String, dynamic>?;
    final inputTokens = usage?['prompt_tokens'] ?? 1500;
    final outputTokens = usage?['completion_tokens'] ?? 800;"""

# Escape for raw string in Python: the string above uses raw strings
openai_new = """    final providerResponse = await _openAiProvider.analyze(
      imageBytes: compressedBytes,
      mimeType: mimeType,
      systemPrompt: _systemPrompt,
      userPrompt:
          '$_mainClassificationPrompt\\n\\nAdditional context:\\n- Region: $region\\n- Instructions language: $language\\n- Image source: web upload',
      maxTokens: 1500,
      cancelToken: _cancelToken,
    );

    final processingTime = DateTime.now().difference(startTime);
    final responseData = providerResponse.rawResponseMap;
    final inputTokens = providerResponse.inputTokens ?? 1500;
    final outputTokens = providerResponse.outputTokens ?? 800;"""

if openai_old_start in content:
    content = content.replace(openai_old_start, openai_new, 1)
    changes += 1
    print("Refactored _analyzeWithOpenAI HTTP body")
else:
    print("WARNING: OpenAI old content not found - checking for alternate forms...")
    # Try alternate form (may have been partially edited)
    if "late final Response response;" in content:
        print("  Found 'late final Response response;' - still need refactor")
    if "_openAiProvider.analyze" in content:
        print("  _openAiProvider.analyze already present")

# ----------------------------------------------------------------
# 4. Remove base64Image line before OpenAI compression (no longer needed as separate step)
# ----------------------------------------------------------------
if "final base64Image = base64Encode(compressedBytes);" in content:
    content = content.replace(
        "    final base64Image = base64Encode(compressedBytes);\n",
        ""
    )
    changes += 1
    print("Removed standalone base64Encode line for OpenAI")

# ----------------------------------------------------------------
# 5. Replace _analyzeWithGemini HTTP body
# ----------------------------------------------------------------
gemini_old_start = """    final requestBody = <String, dynamic>{
      'contents': [
        {
          'parts': [
            {
              'text':
                  '$_systemPrompt\\n\\n$_mainClassificationPrompt\\n\\nAdditional context:\\n- Region: $region\\n- Instructions language: $language\\n- Image source: Gemini analysis (OpenAI fallback)'
            },
            {
              'inline_data': {'mime_type': mimeType, 'data': base64Image}
            }
          ]
        }
      ],
      'generationConfig': {'temperature': 0.1, 'maxOutputTokens': 1500}
    };

    late final Response response;
    try {
      response = await _dio.post(
        '$geminiBaseUrl/models/${ApiConfig.tertiaryModel}:generateContent',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': geminiApiKey,
          },
        ),
        data: requestBody,
        cancelToken: _cancelToken,
      );
    } on DioException catch (e) {
      _handleDioException(e, provider: providerName, model: modelName);
      rethrow;
    }

    if (response.statusCode == 200) {
      final endTime = DateTime.now();
      final processingTime = endTime.difference(startTime);

      WasteAppLogger.info('Received successful response from Gemini.');
      final Map<String, dynamic> responseData = response.data;

      // Extract content from Gemini response format
      if (responseData['candidates'] != null &&
          responseData['candidates'].isNotEmpty &&
          responseData['candidates'][0]['content'] != null &&
          responseData['candidates'][0]['content']['parts'] != null &&
          responseData['candidates'][0]['content']['parts'].isNotEmpty) {
        final String content =
            responseData['candidates'][0]['content']['parts'][0]['text'];

        // Extract token usage from Gemini response (if available)
        final usage = responseData['usageMetadata'] as Map<String, dynamic>?;
        final inputTokens =
            usage?['promptTokenCount'] ?? 1500; // Fallback estimate
        final outputTokens =
            usage?['candidatesTokenCount'] ?? 800; // Fallback estimate"""

gemini_new = """    final providerResponse = await _geminiProvider.analyze(
      imageBytes: processedBytes,
      mimeType: mimeType,
      prompt:
          '$_systemPrompt\\n\\n$_mainClassificationPrompt\\n\\nAdditional context:\\n- Region: $region\\n- Instructions language: $language\\n- Image source: Gemini analysis (OpenAI fallback)',
      maxOutputTokens: 1500,
      cancelToken: _cancelToken,
    );

    if (providerResponse.textContent == null) {
      throw AiFailure(
        AiFailureKind.malformedProviderResponse,
        'Invalid Gemini response format',
        provider: providerName,
        model: modelName,
      );
    }

    final processingTime = DateTime.now().difference(startTime);
    final inputTokens = providerResponse.inputTokens ?? 1500;
    final outputTokens = providerResponse.outputTokens ?? 800;"""

if gemini_old_start in content:
    content = content.replace(gemini_old_start, gemini_new, 1)
    changes += 1
    print("Refactored _analyzeWithGemini HTTP body + response extraction")
else:
    print("WARNING: Gemini old content not found")

# ----------------------------------------------------------------
# 6. Replace Gemini textContent assignment (content -> providerResponse.textContent)
# ----------------------------------------------------------------
if "final String content =" in content and "candidates" in content.split("final String content =")[0][-200:]:
    # Replace the candidates extraction and OpenAI format conversion
    gemini_text_old = """        // Convert Gemini response to OpenAI format for processing
        final openAiFormat = <String, dynamic>{
          'choices': [
            {
              'message': {'content': content}
            }
          ]
        };"""

    gemini_text_new = """        // Convert Gemini response to OpenAI format for processing
        final openAiFormat = <String, dynamic>{
          'choices': [
            {
              'message': {'content': providerResponse.textContent}
            }
          ]
        };"""

    if gemini_text_old in content:
        content = content.replace(gemini_text_old, gemini_text_new, 1)
        changes += 1
        print("Replaced Gemini content var with providerResponse.textContent")
    else:
        # Maybe already replaced
        if "providerResponse.textContent" in content:
            print("  providerResponse.textContent already present")
        else:
            print("  Gemini alternate format not found, may be in different state")

# ----------------------------------------------------------------
# 7. Remove Gemini else-branch (malformed response) - now handled before cost
# ----------------------------------------------------------------
gemini_else_old = """      } else {
        throw AiFailure(
          AiFailureKind.malformedProviderResponse,
          'Invalid Gemini response format',
          provider: providerName,
          model: modelName,
        );
      }
    } else {
      throw AiFailure(
        _failureKindFromStatus(response.statusCode ?? 0),
        'Gemini API Error ${response.statusCode}: ${response.data}',
        provider: providerName,
        model: modelName,
      );
    }"""

# This may be tricky - the else block might now be orphaned. Let's be careful.
# Only remove if it follows the processing block we just replaced.
try:
    if "invalidGeminiElse" not in content and "throw AiFailure" in content:
        lines = content.split("\n")
        new_lines = []
        i = 0
        skip_block = False
        gemini_elses_removed = 0
        while i < len(lines):
            line = lines[i]
            # Look for the orphaned else block pattern after our replacement
            if (line.strip() == "} else {" and 
                i + 1 < len(lines) and "throw AiFailure" in lines[i + 1] and
                "malformedProviderResponse" in lines[i + 1]):
                # Check if this is the now-orphaned Gemini else block
                # Look ahead for the closing braces
                j = i
                # Skip lines that form the else { throw ... } }
                while j < len(lines) and (lines[j].strip() == "} else {" or 
                                           lines[j].strip().startswith("throw AiFailure") or
                                           lines[j].strip() == ");" or
                                           lines[j].strip() == "}"):
                    j += 1
                    if j - i > 10:
                        break
                # Remove the block
                i = j
                gemini_elses_removed += 1
                continue
            new_lines.append(line)
            i += 1
        if gemini_elses_removed > 0:
            content = "\n".join(new_lines)
            changes += 1
            print(f"Removed orphaned Gemini else blocks ({gemini_elses_removed})")
except Exception as e:
    print(f"Skipped complex else removal: {e}")

# ----------------------------------------------------------------
# Write back
# ----------------------------------------------------------------
with open(FILE, "w") as f:
    f.write(content)

print(f"\nTotal changes: {changes}")
