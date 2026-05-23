# Current AI Architecture [CURRENT - verified 2026-05-22]

> This document reflects the actual codebase state as of 2026-05-22.
> It supersedes aspirational design docs in `docs/implementation/ai/` and `docs/reports/architecture/`.
> When code and this document diverge, trust the code and update this document.

## What the app does

The ReLoop now uses two distinct AI pipelines:

1. **Classification** - backend proxy first in release. `AiService` routes through `BackendProxyProvider` to the `classifyImage` Firebase callable in release, and can opt into that backend path in debug/profile with `USE_BACKEND_AI_IN_RELEASE=true`. Direct OpenAI and Gemini clients still exist for non-release flows and direct-provider fallback paths.

2. **Disposal instructions** - fully backend. A Firebase Cloud Function (`generateDisposal`) receives text parameters and calls OpenAI GPT-4 to generate localized disposal guidance.

The instant-analysis screen now keeps its success-path handoff in a tiny coordinator (`lib/services/instant_analysis_flow_coordinator.dart`) so the navigation boundary can be tested without the full widget tree. That is an implementation detail of the capture flow, not a separate AI pipeline.

---

## Classification flow

```
User action (camera / gallery)
         │
         ▼
ImageService.saveFilePermanently()   ← image persisted BEFORE any AI call
         │
         ▼
AiService backend routing gate
         │  release -> backend proxy is canonical
         │  debug/profile -> can opt in with USE_BACKEND_AI_IN_RELEASE
         ▼
BackendProxyProvider.analyze()
         │
         ▼
classifyImage Firebase callable
         │  auth + rate limit + cache + optional App Check
         ▼
OpenAI Vision primary
         │ success -> WasteClassification
         │ failure -> Gemini fallback
```

Direct provider path still exists for non-release branches and direct fallback logic:

```
AiService direct branch
         │
         ▼
ProductionSafetyConfig.guardClientAiCall()
         ▼
OpenAI Vision primary -> Gemini fallback
```

## Disposal flow

```
ResultScreen / DisposalInstructionsService
         │
         ▼
HTTP POST  https://asia-south1-waste-segregation-app-df523.cloudfunctions.net/generateDisposal
         │  (text params only - no image)
         │  Rate limit: 25 req/min, IP-based token bucket
         ▼
generateDisposal (Cloud Function, asia-south1)
         │
         ▼
OpenAI GPT-4 text-only call
         │
         ▼
Disposal instructions returned to client
```

---

## Key files

| Layer | File | Responsibility |
|---|---|---|
| Client AI orchestration | `lib/services/ai_service.dart` | Backend proxy routing plus direct OpenAI vision + Gemini fallback |
| Backend proxy client | `lib/services/providers/backend_proxy_provider.dart` | Calls `classifyImage` callable |
| Backend classification function | `functions/src/classify_image.ts` | Authenticated, rate-limited image classification proxy |
| Instant analysis flow coordinator | `lib/services/instant_analysis_flow_coordinator.dart` | Isolated success-path stage timing + result navigation handoff for `InstantAnalysisScreen` |
| OpenAI provider | `lib/services/providers/openai_provider_client.dart` | HTTP calls to OpenAI API |
| Gemini provider | `lib/services/providers/gemini_provider_client.dart` | HTTP calls to Gemini API |
| Image persistence | `lib/services/image_service.dart` | `saveFilePermanently()` - called before AI |
| Release guard | `lib/utils/production_safety_config.dart` | `guardClientAiCall()` blocks direct client AI in release |
| Constants / key config | `lib/utils/constants.dart` | `String.fromEnvironment` key injection |
| Disposal service | `lib/services/disposal_instructions_service.dart` | HTTP call to `generateDisposal` function |
| Backend disposal function | `functions/src/index.ts` (`generateDisposal`) | OpenAI GPT-4 text call, rate limiting |

---

## Build mode behavior

| Mode | Classification | Disposal function | Notes |
|---|---|---|---|
| Debug | Direct client allowed by default; backend proxy can be enabled with `USE_BACKEND_AI_IN_RELEASE=true` | Allowed | Best for local iteration |
| Profile | Direct client allowed by default; backend proxy can be enabled with `USE_BACKEND_AI_IN_RELEASE=true` | Allowed | Same as debug for routing |
| Release | Backend proxy route is the canonical path | Allowed | Fail-closed to the backend classification path |
| Release + legacy direct override | Not the canonical path | Allowed | Keep only for controlled transition cases |

---

## API key mechanism

Classification now has two key models:

- **Backend proxy path**: OpenAI and Gemini keys live in Firebase Functions environment variables.
- **Direct client path**: keys are still injected at Flutter build time via `--dart-define` for debug/profile and any direct-provider fallback paths.

Direct client examples:

```bash
flutter run \
  --dart-define=OPENAI_API_KEY=sk-... \
  --dart-define=GEMINI_API_KEY=AI...
```

The compiled binary contains the client-side key value for direct-provider flows. The release backend proxy path avoids that exposure for the canonical production classification route.

---

## Rate limiting (actual defaults)

| Endpoint | Limit | Mechanism |
|---|---|---|
| `generateDisposal` | 25 req/min | IP-based token bucket in `functions/src/index.ts` |
| `classifyImage` | 10 req/min | UID-based token bucket in `functions/src/classify_image.ts` |
| Classification direct client branch | No server-side limit | Controlled by release guard and client-side quota logic |

---

## App Check status

App Check is conditional, not universally fail-closed. The callable classification function can enforce App Check when configured, but the backend environment still controls whether enforcement is required.

---

## Image storage

Images are saved permanently on-device by `ImageService.saveFilePermanently()` before classification. The backend proxy receives compressed image bytes over HTTPS and does not persist the image bytes; it only caches hashes and classification JSON in Firestore.

---

## What does NOT exist or is still incomplete

| Claimed in older docs | Reality |
|---|---|
| `classifyImage` Cloud Function | Exists now and is part of the release classification path |
| Gemini as primary provider | Gemini is still the fallback; OpenAI remains primary |
| TFLite on-device model | Not implemented |
| Anthropic Claude as tertiary model | Not implemented |
| Keys stored server-side only | Not true for direct-client fallback paths |
| App Check fail-closed everywhere | Conditional; controlled by env and function type |
| 50/day or 10/min classification client-only model | Classification is now server-side via `classifyImage` |

---

**Last verified**: 2026-05-21
**Verified against**: `lib/services/ai_service.dart`, `lib/services/providers/backend_proxy_provider.dart`, `lib/services/disposal_instructions_service.dart`, `lib/utils/production_safety_config.dart`, `lib/utils/constants.dart`, `functions/src/index.ts`, `functions/src/classify_image.ts`
