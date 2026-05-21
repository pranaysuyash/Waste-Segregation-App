# Backend Classification Gateway - Implementation Notes

**Date**: 2026-05-21  
**Status**: Phase 2 complete (backend proxy implemented and wired into `AiService`)

---

## What was implemented

### 1. `functions/src/classify_image.ts`

A Firebase HTTPS callable function exported as `classifyImage`. It:

- Requires Firebase Auth (`context.auth.uid`); rejects unauthenticated callers with `unauthenticated`.
- Enforces App Check when the callable App Check env flag is enabled, using the same fail-closed pattern as the other guarded function paths.
- Accepts `{ imageBase64, mimeType, clientHash?, region?, lang?, requestId? }`.
- Validates payload size and MIME type before any provider call.
- Computes a server-side SHA-256 hash of the encoded image payload and uses that as the authoritative cache key.
- Checks Firestore `classifications` for a non-expired cached result.
- Enforces per-UID rate limiting with a default of **10 requests / 60 seconds**.
- Calls OpenAI first and Gemini as fallback.
- Writes cost telemetry to `ai_cost_events`.
- Caches the JSON classification result, not the image bytes.
- Returns the classification payload plus meta data such as provider, model, cache state, and remaining requests.

### 2. `functions/src/index.ts`

`classifyImage` is exported from the backend entrypoint so the callable is deployed alongside the existing functions.

### 3. `lib/services/providers/backend_proxy_provider.dart`

A Flutter provider that calls the `classifyImage` callable function. It:

- Base64-encodes image bytes before sending.
- Maps function errors to `AiFailure` kinds.
- Returns a response shape that `AiService` can parse without changing the classification parsing pipeline.
- Exposes `BackendProxyProvider.isEnabled` via `USE_BACKEND_AI_IN_RELEASE`.

### 4. `lib/services/ai_service.dart`

`AiService` now routes classification through the backend proxy in release, and can opt into the backend path in debug/profile via `USE_BACKEND_AI_IN_RELEASE`.

### 5. `lib/services/enhanced_ai_api_service.dart`

`EnhancedAiApiService` now follows the same release invariant:

- release: backend proxy first, direct provider clients are not initialized unless the fallback path is actually needed
- debug/profile: backend proxy is available when the canonical backend-routing flag is enabled
- direct provider fallback remains available only for non-release fallback flows

---

## How routing works now

- Release classification is backend-first and fail-closed to the proxy path.
- Debug/profile can still use direct client providers unless the backend proxy flag is enabled.
- Direct client providers remain as a controlled fallback path for non-release flows and for the queue retry surface.

---

## Environment variables required in Firebase Functions

| Variable | Required | Default | Description |
|---|---|---|---|
| `OPENAI_API_KEY` | Yes | - | OpenAI secret key |
| `GEMINI_API_KEY` | Yes | - | Gemini secret key |
| `CLASSIFY_IMAGE_MAX_REQUESTS` | No | `10` | Callable rate-limit cap |
| `CLASSIFY_IMAGE_WINDOW_SECONDS` | No | `60` | Callable rate-limit window |
| `REQUIRE_APPCHECK_CALLABLE` | No | `false` | Enforce App Check for callable routes |
| `ENFORCE_APPCHECK_IN_EMULATOR` | No | `false` | Force App Check enforcement in emulator |

---

## Known limitations / follow-up items

1. `EnhancedAiApiService` still does not apply the same safety guard as `AiService`.
2. On-device inference is still a placeholder and does not run real TFLite inference.
3. Daily quota enforcement is still not implemented on top of the callable per-UID window.
4. If the offline queue should never bypass the backend proxy, that retry surface should be routed or guarded next.
