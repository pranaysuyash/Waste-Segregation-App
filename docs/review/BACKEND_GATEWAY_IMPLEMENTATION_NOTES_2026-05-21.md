# Backend Classification Gateway — Implementation Notes

**Date**: 2026-05-21  
**Status**: Phase 1 complete (files created; wiring into AiService is Phase 2)

---

## What was implemented

### 1. `functions/src/classify_image.ts`

A Firebase HTTPS Callable function exported as `classifyImage`. It:

- Requires Firebase Auth (`context.auth.uid`); rejects unauthenticated callers with `unauthenticated`.
- Enforces App Check (fail-closed) when `REQUIRE_APPCHECK_CALLABLE=true` matches the pattern used by `spendUserTokens` in `index.ts`.
- Accepts `{ imageBase64, mimeType, clientHash?, region?, lang? }`.
- Validates image size: base64 string length checked against `ceil(4 MB × 4/3)` characters. Rejects oversized payloads before any AI call.
- Validates MIME type: only `image/jpeg`, `image/png`, `image/webp` accepted.
- Computes a server-side SHA-256 hash of the base64 string. This is the **authoritative** cache key. The optional `clientHash` from the client is accepted as a deduplication hint only.
- Checks `classifications` Firestore collection for a non-expired cache entry keyed by `{serverHash}::{region}::{lang}`.
- Enforces per-UID rate limit: default **10 requests / 60 seconds** (configurable via env vars). Uses the same `enforceRateLimit()` Firestore transaction pattern as the existing `spendUserTokens` function.
- Calls **OpenAI Vision** (primary) → **Gemini Flash** (fallback). Both providers are called with the same prompt and both parse the JSON response in the same way.
- Writes a cost telemetry record to `ai_cost_events` on every call (success, failure, and cache hit). Cache hits record `estimatedCostUsd: 0`.
- Caches the JSON result (never the image bytes) in `classifications`.
- Returns `{ classification: { ...WasteClassification fields }, meta: { provider, model, serverImageHash, cachedResult, remainingRequests } }`.
- **Image bytes are never written to any persistent store.**

### 2. `functions/src/index.ts` — one line added

```typescript
export { classifyImage } from './classify_image';
```

Added immediately above `getBatchStats`. No other changes to `index.ts`.

### 3. `lib/services/providers/backend_proxy_provider.dart`

A Flutter provider class that calls the `classifyImage` callable function. It:

- Accepts `FirebaseFunctions` via constructor (injectable; testable).
- Exposes an `analyze({ imageBytes, mimeType, prompt, clientHash, region, lang, cancelToken })` method with the same signature shape as `GeminiProviderClient.analyze` and `OpenAiProviderClient.analyze`.
- Encodes image bytes as base64 before sending.
- Returns an `AiProviderResponse` where `rawResponseMap` is the `classification` sub-object and `textContent` is its JSON-encoded string form. This ensures `AiService._processAiResponseData` can parse it via the same path it uses for Gemini responses (checking `textContent` first).
- Maps `FirebaseFunctionsException` error codes to `AiFailure` kinds consistently with the other provider clients.
- Does **not** call `ProductionSafetyConfig.guardClientAiCall` — backend routing bypasses the client-AI guard by design.
- Exposes `static const bool isEnabled = bool.fromEnvironment('USE_BACKEND_CLASSIFICATION')` for the feature flag.

---

## How to enable in Flutter

Pass the dart-define flag at build time:

```bash
flutter run --dart-define=USE_BACKEND_CLASSIFICATION=true
flutter build appbundle --dart-define=USE_BACKEND_CLASSIFICATION=true
```

Then in `AiService` (Phase 2 wiring — not yet done), check `BackendProxyProvider.isEnabled` and route to the backend provider before attempting direct OpenAI/Gemini calls:

```dart
// Phase 2 wiring sketch — add to AiService
if (BackendProxyProvider.isEnabled && kReleaseMode) {
  final backendProvider = BackendProxyProvider(
    functions: FirebaseFunctions.instanceFor(region: 'asia-south1'),
    region: analysisRegion,
  );
  final response = await backendProvider.analyze(
    imageBytes: imageBytes,
    mimeType: mimeType,
    clientHash: contentHash,
    region: analysisRegion,
    lang: analysisLang,
  );
  return _processAiResponseData(response.textContent ?? jsonEncode(response.rawResponseMap), ...);
}
```

---

## Environment variables required in Firebase Functions

| Variable | Required | Default | Description |
|---|---|---|---|
| `OPENAI_API_KEY` | Yes (for primary) | — | OpenAI secret key |
| `GEMINI_API_KEY` | Yes (for fallback) | — | Google AI / Generative Language key |
| `REQUIRE_APPCHECK_CALLABLE` | Recommended in prod | `false` | Enforce App Check on callable functions |
| `ENFORCE_APPCHECK_IN_EMULATOR` | No | `false` | Also enforce in emulator (for testing) |
| `CLASSIFY_IMAGE_MAX_REQUESTS` | No | `10` | Max requests per UID per window |
| `CLASSIFY_IMAGE_WINDOW_SECONDS` | No | `60` | Rate limit window size in seconds |
| `CLASSIFY_CACHE_TTL_SECONDS` | No | `86400` | Cache TTL (1 day default) |
| `OPENAI_VISION_MODEL` | No | `gpt-4.1-nano` | OpenAI model for vision |
| `GEMINI_VISION_MODEL` | No | `gemini-2.0-flash` | Gemini model for vision |

Set these with:
```bash
firebase functions:secrets:set OPENAI_API_KEY
firebase functions:secrets:set GEMINI_API_KEY
```

Or via `firebase functions:config:set` for legacy config (the code checks both).

---

## Firestore collections created

### `classifications`

Stores cached classification results keyed by `{serverSHA256}::{region}::{lang}`.

Schema per document:
```
{
  // All WasteClassification JSON fields (itemName, category, etc.)
  imageHash: string,       // server SHA-256 of the base64 input
  region: string,
  lang: string,
  provider: string,        // "openai" | "gemini"
  model: string,
  cachedAtEpoch: number,   // Unix seconds — used for TTL check
  createdAt: Timestamp,
}
```

Image bytes are **never** stored. Only the hash and the JSON result.

### `ai_cost_events`

Append-only log of every call (including cache hits) for cost tracking and analytics.

Schema per document:
```
{
  uid: string,
  timestamp: Timestamp,
  provider: string,        // "openai" | "gemini" | "none" | "cache"
  model: string,
  inputTokens: number | null,
  outputTokens: number | null,
  estimatedCostUsd: number | null,
  imageHash: string,       // partial reference — not the full bytes
  success: boolean,
  cacheHit: boolean,
}
```

`estimatedCostUsd` uses rough per-model rates embedded in the function. Not for billing — for operational awareness only.

---

## Rate limit config

Default: **10 requests per UID per 60-second window** (lower than `generateDisposal`'s 25/min because vision API calls cost 10–20× more).

- Stored in `rate_limits` collection as `classifyImage:uid:{uid}` — same pattern as `spendUserTokens`.
- Override with `CLASSIFY_IMAGE_MAX_REQUESTS` and `CLASSIFY_IMAGE_WINDOW_SECONDS` env vars.
- Future: Agent 3 is creating a `rate_limit_config.ts` module. Once that lands, read limits from there instead of the local env vars above.

---

## Privacy guarantee

The entire pipeline is designed so that **no image data leaves the client-side memory and lands in persistent storage**:

1. The client sends `imageBase64` to the callable function over a TLS-encrypted HTTPS channel.
2. The function hashes the base64 string immediately and logs only the first 16 hex chars of that hash.
3. The base64 string is passed to the AI provider (OpenAI or Gemini) and then discarded.
4. Only the SHA-256 hash and the classification JSON are written to Firestore.
5. Firebase callable function execution is ephemeral; memory is released after return.

---

## Migration path

| Phase | Description | Status |
|---|---|---|
| Phase 1 | Create `classify_image.ts`, `BackendProxyProvider`, export in `index.ts` | Done (this PR) |
| Phase 2 | Wire `BackendProxyProvider` into `AiService`: check `BackendProxyProvider.isEnabled` before direct client calls, pass through `analyze()` | Pending |
| Phase 3 | Flip default routing: make backend the default in release, direct client AI opt-out only | Pending |
| Phase 4 | Deprecate `ALLOW_CLIENT_AI_IN_RELEASE`: warn if set, remove after one release cycle | Future |

**Phase 2 is a single-file change in `lib/services/ai_service.dart`.**  
The plumbing (types, response parsing, error mapping) is already in place.

---

## TypeScript compilation check

The `classify_image.ts` file uses only packages already in `functions/package.json`:
- `firebase-functions` (^5.1.1)
- `firebase-admin` (^12.7.0)
- `axios` (^1.15.2)
- `crypto` (Node built-in, available in Node 18)

It does not require any new dependencies.

Run `cd functions && npm run build` to verify compilation before deploying.

---

## Known limitations / follow-up items

1. **Phase 2 wiring not done**: `AiService` does not yet call `BackendProxyProvider`. The flag `USE_BACKEND_CLASSIFICATION=true` has no effect until Phase 2 is implemented.
2. **Prompt version drift**: The classification prompt in `classify_image.ts` is a copy of the prompt in `ai_service.dart`. If `ai_service.dart`'s prompt evolves, `classify_image.ts` must be updated in sync. Consider extracting to a shared prompt artifact (or passing the prompt from client to server) in Phase 3.
3. **Cache invalidation**: There is no proactive cache invalidation. If the prompt changes, the `CLASSIFY_CACHE_TTL_SECONDS` window must expire naturally, or a cache wipe script needs to run. Consider adding a `promptVersion` field to the cache key.
4. **Token counts for Gemini**: `promptTokenCount` and `candidatesTokenCount` are extracted from `usageMetadata` but Gemini does not always include this field. Cost estimates may be null for some Gemini calls.
5. **Firestore index**: The `ai_cost_events` collection will need a composite index on `(uid, timestamp)` for per-user cost queries. Create via `firestore.indexes.json` before Phase 3.
