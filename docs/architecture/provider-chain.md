# Provider Chain Architecture

## Overview

The provider chain handles image classification requests through a layered pipeline:
**DTO → Provider Client → Router → Post-Processor → Accounting**.

## Layers

### 1. DTO: `AiProviderResponse`
**`lib/services/providers/ai_provider_response.dart`**

Pure data carrier with zero imports. Carries:
- `provider` / `model` — identity
- `rawResponseMap` — full wire response for parsing
- `textContent` — pre-extracted text (Gemini)
- `inputTokens` / `outputTokens` — usage metadata

### 2. Normalisation: `AiProviderResponseAdapter`
**`lib/services/providers/ai_provider_response_adapter.dart`**

Normalises provider responses to a uniform `{ choices: [{ message: { content } }] }` shape expected by `AiResponseParser`. Three paths:
- **OpenAI**: passthrough (already matches)
- **Gemini / Backend**: wraps `textContent` into the canonical shape
- **Fallback**: returns `rawResponseMap` as-is when neither condition matches

### 3. Provider Clients

Each implements `ClassificationProvider`:

| Client | File | Provider |
|--------|------|----------|
| `OpenAiProviderClient` | `openai_provider_client.dart` | OpenAI API |
| `GeminiProviderClient` | `gemini_provider_client.dart` | Gemini API |
| `BackendProxyProvider` | `backend_proxy_provider.dart` | Firebase Functions |

Each owns: HTTP call construction, error mapping (DioException → AiFailure), token extraction, and response wrapping.

### 4. Router: `AiProviderRouter`
**`lib/services/providers/ai_provider_router.dart`**

Stateless orchestrator that accepts three `ProviderCall` closures and runs the fallback chain:

```
backend (if enabled)
  ├─ success → return
  ├─ terminal failure → rethrow
  └─ non-terminal → fall through
openai
  ├─ success → return
  ├─ terminal / ProductionSafety → rethrow
  ├─ non-terminal (tooLarge / providerUnavailable) → gemini fallback
  ├─ non-terminal (other) → rethrow
  └─ generic Exception → unknown kind → gemini fallback on maxRetries
gemini
  ├─ success → return
  └─ failure → rethrow
```

Returns `ProviderRouterResult` with `response`, `providerUsed`, and `attemptedProviders`.

### 5. Post-Processor: `ClassificationResultProcessor`
**`lib/services/classification_result_processor.dart`**

Encapsulates the 5-step post-processing pipeline:
1. Normalise via `AiProviderResponseAdapter.toParserMap`
2. Parse via `AiResponseParser.processResponse`
3. Apply policy via `LocalPolicyEngine.applyPolicy`
4. Attach metadata via `_attachPolicyDecisionMetadata`
5. Write cache via `_cacheService`

### 6. Accounting: `AiUsageAccountingService`
**`lib/services/ai_usage_accounting_service.dart`**

Records client-side AI cost:
- **openai / gemini**: records actual usage from response tokens
- **backend**: skips (server-tracked)
- **local providers**: records 0.0

## Flow Diagram

```
AiService._orchestrateAnalysis()
  │
  ├── AiProviderRouter.orchestrate()
  │     ├── backendCall()  ──► BackendProxyProvider
  │     ├── openAiCall()   ──► OpenAiProviderClient
  │     └── geminiCall()   ──► GeminiProviderClient
  │
  ├── ClassificationResultProcessor.process()
  │     ├── AiProviderResponseAdapter.toParserMap()
  │     ├── AiResponseParser.processResponse()
  │     ├── LocalPolicyEngine.applyPolicy()
  │     └── _cacheService.write()
  │
  └── AiUsageAccountingService.recordUsage()
```

## Test Files

| File | Tests | Scope |
|------|-------|-------|
| `ai_provider_response_adapter_test.dart` | 5 | Adapter normalisation |
| `ai_provider_router_test.dart` | 11 | Backend/OpenAI/Gemini fallback |
| `openai_provider_client_test.dart` | 13 | HTTP, errors, tokens |
| `gemini_provider_client_test.dart` | 10 | HTTP, errors, tokens |
| `ai_service_backend_test.dart` | 19 | Integration-level backend routing |
