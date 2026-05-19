# AI Service Refactor (Motto v2) - 2026-05-19

## Scope completed
- Fixed injected OpenAI config usage in service HTTP calls.
- Added typed AI failures (`AiFailure`, `AiFailureKind`) and replaced string-based fallback routing.
- Prevented empty web image bytes from being persisted.
- Made fallback extraction output visible in returned fallback classification.
- Added provider/model-aware parsing metadata so Gemini/OpenAI source modeling is explicit.
- Enforced max-size validation after OpenAI compression.
- Fixed correction routing so Gemini correction uses Gemini endpoint shape.
- Added context-aware cache key builder and integrated it in AI cache read/write paths.
- Marked segmentation as debug-only behind explicit `enableDebugGridSegmentation`.

## Tests executed
- `flutter test test/services/ai_service_test.dart`
- Result: all tests passed.

## Remaining architecture work (next phase)
- Extract provider clients into dedicated modules:
  - `openai_provider_client.dart`
  - `gemini_provider_client.dart`
  - `backend_ai_client.dart`
- Move prompt content to a dedicated prompt builder module with versioned prompt objects.
- Move parsing into a dedicated response parser with strict schema validation.
- Expand tests for provider fallback branches with mocked Dio responses.
