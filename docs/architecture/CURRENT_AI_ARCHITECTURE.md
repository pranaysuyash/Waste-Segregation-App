# Current AI Architecture [CURRENT — verified 2026-05-21]

> This document reflects the actual codebase state as of 2026-05-21.
> It supersedes aspirational design docs in `docs/implementation/ai/` and `docs/reports/architecture/`.
> When code and this document diverge, trust the code and update this document.

## What the app does

The Waste Segregation App uses two distinct AI pipelines:

1. **Classification** — fully Flutter client-side. The user takes or picks a photo; the image is saved permanently on-device first, then sent directly to OpenAI Vision as the primary provider. If OpenAI fails, Gemini is the fallback. There is no backend function involved in classification.

2. **Disposal instructions** — fully backend. A Firebase Cloud Function (`generateDisposal`) receives text parameters (no image) and calls OpenAI GPT-4 to generate localised disposal guidance.

---

## Classification flow

```
User action (camera / gallery)
         │
         ▼
ImageService.saveFilePermanently()   ← image persisted BEFORE any AI call
         │
         ▼
ProductionSafetyConfig.guardClientAiCall()
         │  blocks in release unless ALLOW_CLIENT_AI_IN_RELEASE=true
         ▼
AiService.classifyImageWithFallback()
         │
         ├─── Primary: OpenAI Vision (gpt-4.1-nano / gpt-4o-mini / gpt-4.1-mini)
         │         │ success → WasteClassification
         │         │ failure ↓
         └─── Fallback: Gemini Vision (gemini-2.0-flash)
                   │ success → WasteClassification
                   │ failure → ClassificationException shown to user
```

## Disposal flow

```
ResultScreen / DisposalInstructionsService
         │
         ▼
HTTP POST  https://asia-south1-waste-segregation-app-df523.cloudfunctions.net/generateDisposal
         │  (text params only — no image)
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
| Client AI orchestration | `lib/services/ai_service.dart` | Primary OpenAI vision + Gemini fallback |
| OpenAI provider | `lib/services/providers/openai_provider_client.dart` | HTTP calls to OpenAI API |
| Image persistence | `lib/services/image_service.dart` | `saveFilePermanently()` — called before AI |
| Release guard | `lib/utils/production_safety_config.dart` | `guardClientAiCall()` blocks AI in release |
| Constants / key config | `lib/utils/constants.dart` | `String.fromEnvironment` key injection |
| Disposal service | `lib/services/disposal_instructions_service.dart` | HTTP call to `generateDisposal` function |
| Backend disposal function | `functions/src/index.ts` (`generateDisposal`) | OpenAI GPT-4 text call, rate limiting |

---

## Build mode behavior

| Mode | Client AI (classification) | Disposal function | Notes |
|---|---|---|---|
| Debug | Allowed | Allowed | Keys injected via `--dart-define` |
| Profile | Allowed | Allowed | Same as debug for keys |
| Release (default) | **Blocked** by `guardClientAiCall` | Allowed | AI calls throw unless opt-in |
| Release + `ALLOW_CLIENT_AI_IN_RELEASE=true` | Allowed | Allowed | Override for staged rollout |

---

## API key mechanism

Keys are **not** in `.env` files at runtime. They are injected at Flutter **build time** via `--dart-define`:

```bash
flutter run \
  --dart-define=OPENAI_API_KEY=sk-... \
  --dart-define=GEMINI_API_KEY=AI...
```

They are accessed in Dart as `String.fromEnvironment('OPENAI_API_KEY')`. The compiled binary contains the key value — this is the current, accepted posture with the release guard as the primary abuse prevention control. Full server-side key migration is a planned future hardening step (see `docs/reports/architecture/API_SECURITY_ARCHITECTURE_DECISION.md` for the goal architecture, noting that doc's "migration completed" claims are incorrect).

---

## Rate limiting (actual defaults)

| Endpoint | Limit | Mechanism |
|---|---|---|
| `generateDisposal` | 25 req/min | IP-based token bucket in `functions/src/index.ts` |
| Classification (client) | No server-side limit | Controlled by release guard + client-side quota logic |

**Note**: Several older docs cite 50/day or 10/min limits — those are aspirational values from pre-implementation design docs, not current reality.

---

## App Check status

App Check is **conditional**, not fail-closed. The `REQUIRE_APPCHECK_HTTP` environment variable controls enforcement on HTTP endpoints. In current production configuration it is not universally enforced. This is a known gap tracked in `docs/review/APPCHECK_RATE_LIMIT_IMPLEMENTATION_PACKET_2026-05-21.md`.

---

## Image storage

Images are saved **permanently on-device** (in app documents directory) by `ImageService.saveFilePermanently()` *before* the AI classification call. They are **not** uploaded to cloud storage as part of the classification flow. The `imageUrl` field in `WasteClassification` refers to this local path. Cloud backup of images is a planned future feature.

---

## What does NOT exist (common doc errors)

| Claimed in older docs | Reality |
|---|---|
| `classifyImage` Cloud Function | Does not exist — classification is client-side Flutter |
| Gemini as primary provider | Gemini is the fallback; OpenAI is primary |
| TFLite on-device model | Not implemented |
| Anthropic Claude as tertiary model | Not implemented |
| Keys stored server-side only | Keys are client build-time `--dart-define` injected |
| App Check fail-closed | Conditional; controlled by env var |
| 50/day or 10/min rate limits | Actual limit is 25/min on `generateDisposal` |

---

**Last verified**: 2026-05-21
**Verified against**: `lib/services/ai_service.dart`, `lib/services/disposal_instructions_service.dart`, `lib/utils/production_safety_config.dart`, `lib/utils/constants.dart`, `functions/src/index.ts`, `docs/review/SECRET_PATH_AND_RELEASE_GUARD_AUDIT_2026-05-21.md`
