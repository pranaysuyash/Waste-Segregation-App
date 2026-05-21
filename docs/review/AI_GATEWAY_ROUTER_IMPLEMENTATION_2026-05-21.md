# AI Gateway / Router — Implementation Notes
**Date:** 2026-05-21
**Status:** Implemented (backend callable deployed; client flag off by default)

---

## 1. Current Architecture (Before This Work)

The app called AI providers directly from the Flutter client:

```
Flutter client
  └─► _analyzeWithOpenAI()  → POST https://api.openai.com/v1/chat/completions
                              (API key in client dart-define)
  └─► _analyzeWithGemini()  → POST https://generativelanguage.googleapis.com/...
                              (API key in client dart-define)
```

Problems:
- API keys had to be embedded in the built app (dart-define), making them extractable.
- No server-side cost ceiling; a single runaway client could exhaust the API budget.
- Rate limiting was client-enforced only — easily bypassed.
- No server-side classification cache — identical images were re-classified on every device.
- No auditability: no structured log of which user classified what and at what cost.

---

## 2. New Architecture (Backend Gateway + Provider Interface + Local VLM Stub)

```
Flutter client
  └─► AiService._backendRoutingEnabled
        │  true (release or dart-define set)
        ▼
      BackendProxyProvider.analyze()
        │  Firebase HTTPS Callable (App Check + Auth + rate limit)
        ▼
      classifyImage (functions/src/classify_image.ts)
        ├─► OpenAI gpt-4.1-nano  [primary]
        │     └─► cache result in Firestore `classifications`
        │     └─► write to Firestore `ai_cost_events`
        └─► Gemini 2.0 Flash     [fallback, if OpenAI fails]
              └─► same cache + telemetry path
```

Provider interface layer (lib/services/providers/):

```
ClassificationProvider (abstract interface)
  ├─ BackendProxyProvider   — Firebase Callable client
  ├─ GeminiProviderClient   — direct Gemini Vision HTTP
  ├─ OpenAiProviderClient   — direct OpenAI Vision HTTP
  └─ LocalVlmProvider       — on-device stub (UnimplementedError)
```

In release builds the entire chain is backend gateway first for both `AiService` and `EnhancedAiApiService`, with no client-side AI key needed for the canonical production path.

---

## 3. Why Backend Gateway Is Not the Final Architecture

The backend gateway is a **stepping stone**, not the target state.

The target architecture is **local-first with cloud escalation**:

```
Layer 1: LocalVlmProvider (on-device, free, private)
  ├─ moondream2 / SmolVLM / MobileVLM (to be bundled in Phase 3)
  └─ Returns result instantly, no network, no cost
       │  If confidence < threshold or model not bundled
       ▼
Layer 2: Backend gateway (Firebase Callable)
  ├─ OpenAI gpt-4.1-nano  [primary]
  └─ Gemini 2.0 Flash     [fallback]
```

Why: user privacy (images never leave the device for routine items), zero
incremental cost at scale, offline-capable classification, and regulatory
alignment (GDPR/DPDPA on-device processing preference).

The backend gateway reduces key exposure risk now while the on-device model
pipeline is built out. Cloud remains the escalation path for edge cases and
high-confidence requirements.

---

## 4. Release Safety Behavior

### Canonical Build Flag

```
--dart-define=USE_BACKEND_AI_IN_RELEASE=true
```

This is the **single** flag that controls backend routing. It is read by:
- `ProductionSafetyConfig.useBackendAiInRelease` (utility class)
- `BackendProxyProvider.isEnabled` (provider class)

**Do not** add a second backend-routing flag or any alternative spelling. There is exactly one.

### Behavior Per Build Mode

| Build mode | `USE_BACKEND_AI_IN_RELEASE` | Backend used? | Client AI allowed? |
|---|---|---|---|
| debug | not set | No (via `_backendRoutingEnabled`) | Yes |
| debug | `true` | Yes | Yes (flag set, backend-first) |
| profile | not set | No | Yes |
| profile | `true` | Yes | Yes |
| release | not set | Yes (kReleaseMode=true forces it) | No (`ProductionSafetyException`) |
| release | `true` | Yes | No |
| release | `false` | Yes (kReleaseMode overrides) | No |

Key invariant: **release builds always use the backend, regardless of the flag**.
The flag is an opt-in for debug/profile builds during development.

---

## 5. Provider Fallback Policy

### Server-Side Fallback (inside Firebase Function)

```
classifyImage:
  1. OpenAI gpt-4.1-nano (primary)
     → success: cache + return
     → failure: log warning, try Gemini
  2. Gemini 2.0 Flash (fallback)
     → success: cache + return
     → failure: refund tokens + throw UNAVAILABLE
```

### Client-Side Fallback (inside AiService)

```
_backendRoutingEnabled:
  - true + _backendRoutingFailClosed (release): rethrow ALL failures
  - true + NOT fail-closed (debug): rethrow only terminal failures

Terminal failures (always rethrow, never fall to direct client):
  - AiFailureKind.auth           — unauthenticated / App Check
  - AiFailureKind.cancelled      — user cancelled
  - AiFailureKind.budgetExceeded — client budget gate
  - AiFailureKind.unsafeClientAiBlocked — safety guard

Non-terminal failures (fall to OpenAI direct, debug only):
  - AiFailureKind.network        — timeout, connection refused
  - AiFailureKind.providerUnavailable
  - AiFailureKind.rateLimited    — (note: server rate limit is separate from client)
  - AiFailureKind.unknown
```

When `LocalVlmProvider` is wired (Phase 3), it becomes Layer 1 and the
`BackendProxyProvider` becomes Layer 2. The fallback chain becomes:
`LocalVlm → Backend → (dev-only direct client)`.

---

## 6. ClassificationProvider Interface

**File:** `lib/services/providers/classification_provider.dart`

```dart
abstract interface class ClassificationProvider {
  String get providerName;
  String get modelName;
  double? get estimatedCostPerCall;
  Future<AiProviderResponse> analyze({
    required Uint8List imageBytes,
    required String mimeType,
    String prompt = '',
    String? clientHash,
    String? region,
    String? lang,
    String? requestId,
    CancelToken? cancelToken,
  });
}
```

### Implementors

| Class | providerName | modelName | estimatedCostPerCall |
|---|---|---|---|
| `BackendProxyProvider` | `'backend'` | `'classifyImage'` | `null` (server-tracked) |
| `GeminiProviderClient` | `'gemini'` | configured at construction | ~$0.00031/call |
| `OpenAiProviderClient` | `'openai'` | configured at construction | ~$0.00047/call |
| `LocalVlmProvider` | `'local_vlm'` | `'not-yet-bundled'` | `0.0` (free) |

### `estimatedCostPerCall` Semantics

- `null`: cost is opaque to the client (tracked server-side in `ai_cost_events`).
- `0.0`: free — on-device inference with no external API calls.
- `> 0`: rough estimate in USD for budget forecasting. Not used for billing.

### `prompt` Handling by Provider

- `BackendProxyProvider`: ignored — server builds its own prompt from the classification template.
- `GeminiProviderClient`: passed directly as the combined system+user message.
- `OpenAiProviderClient.analyze()`: treated as `systemPrompt`; a fixed user message is appended. Use `analyzeWithSplitPrompts()` for full control.
- `LocalVlmProvider`: unused until a model is bundled.

---

## 7. Privacy / Retention

- **Image bytes are NEVER stored server-side.** The `classifyImage` function hashes the base64 payload server-side (SHA-256) and only the hash is written to Firestore.
- The client-supplied `clientHash` is accepted as a deduplication **hint** only. The server always computes its own hash and never trusts the client-supplied value as a cache key.
- `ai_cost_events` stores: `uid`, `imageHash` (not bytes), `provider`, `model`, `inputTokens`, `outputTokens`, `estimatedCostUsd`, `success`, `cacheHit`, `timestamp`.
- `classifications` cache stores: the parsed JSON result + `imageHash` + `cachedAtEpoch`. No image bytes.
- On-device images are saved to permanent storage (via `EnhancedImageService.saveImagePermanently`) **before** analysis. The analysis path only receives bytes — the storage path is decided upstream.

---

## 8. Cost / Telemetry Fields

Every successful and failed classification writes one document to `ai_cost_events`:

| Field | Type | Meaning |
|---|---|---|
| `uid` | string | Firebase Auth UID of the requesting user |
| `timestamp` | Firestore ServerTimestamp | When the event was written |
| `provider` | string | `'openai'`, `'gemini'`, `'cache'`, `'none'` |
| `model` | string | Model identifier (e.g. `'gpt-4.1-nano'`) |
| `inputTokens` | number \| null | Prompt token count from provider |
| `outputTokens` | number \| null | Completion token count from provider |
| `estimatedCostUsd` | number \| null | Rough USD cost (6 decimal places) |
| `imageHash` | string | SHA-256 of the base64 image payload |
| `success` | boolean | Whether classification succeeded |
| `cacheHit` | boolean | Whether result was served from Firestore cache |

Cache-hit events record `provider: 'cache'`, `estimatedCostUsd: 0`, `cacheHit: true`.
Failure events record `provider: 'none'`, `estimatedCostUsd: null`, `success: false`.

---

## 9. Offline Queue Behavior

The `OfflineQueueService` (`lib/services/offline_queue_service.dart`) manages
classifications queued when the device is offline. It uses `Hive` for local
persistence and re-processes the queue when connectivity returns.

**No `isBackendMode` field was added** to the queue — it was not needed.
The queue stores `QueuedClassification` objects (imageBytes + region + metadata).
When the queue is drained, each item goes through the normal `AiService`
classification path, which includes the `_backendRoutingEnabled` check. So:

- Items queued while offline will use the backend when drained (if in release mode).
- Items queued in debug mode without the flag set will use the direct client path.
- No migration of existing queued items is needed — the routing decision is made at
  drain time, not at queue time.

---

## 10. Rollout Plan

### Phase 0 — Flag Off, Backend Dormant (current)
- `classifyImage` Firebase function deployed and running.
- `USE_BACKEND_AI_IN_RELEASE` not set anywhere.
- Debug/profile builds use direct client AI.
- Release builds use backend (kReleaseMode forces it).
- Monitor `ai_cost_events` for correctness; no user-facing change.

### Phase 1 — Flag On in Staging / Internal
- Build with `--dart-define=USE_BACKEND_AI_IN_RELEASE=true`.
- Internal QA verifies classification quality and latency.
- Monitor `classifications` cache hit rate in Firestore.
- Tune `CLASSIFY_CACHE_TTL_SECONDS`, `CLASSIFY_IMAGE_MAX_REQUESTS`.

### Phase 2 — Backend Default
- All builds (debug/profile/release) use the backend.
- Remove direct AI keys from CI/build scripts.
- Remove `ALLOW_CLIENT_AI_IN_RELEASE` from internal testing builds.

### Phase 3 — On-Device Layer 1 (LocalVlmProvider)
- Bundle `moondream2` or equivalent via `flutter_tflite` / ONNX.
- Implement `LocalVlmProvider.analyze()` with real inference.
- Update `AiService._backendRoutingEnabled` to check `LocalVlmProvider.isAvailable` first.
- Common items (plastic bottles, paper, food waste) classified entirely on-device.
- Cloud escalation only for edge cases and low-confidence results.

### Phase 4 — Full Cascade
- Local VLM is Layer 1 for high-frequency, well-trained categories.
- Backend gateway is Layer 2 for novel or low-confidence items.
- Direct client AI removed entirely from production code.
- `estimatedCostPerCall` telemetry used for per-user cost forecasting.

---

## 11. Rollback Plan

The backend flag is a build-time constant — no runtime feature flag infrastructure needed.

### Immediate rollback
1. Rebuild the app **without** `--dart-define=USE_BACKEND_AI_IN_RELEASE=true`.
2. Release builds will still use the backend (kReleaseMode hard-codes it), but debug/staging builds will revert to direct client AI.
3. For a full rollback in release builds, set `ALLOW_CLIENT_AI_IN_RELEASE=true` to allow direct client AI while the backend is removed from the code path.

### No data migration required
- `ai_cost_events` only accumulates new telemetry events. Existing documents are not affected.
- `classifications` Firestore cache is additive. Clearing it is safe at any time; results will be re-fetched on next request.
- `classify_token_reservations` documents are idempotent. They can be cleared without affecting user wallet balances (balances are on the `users` document).

### Firebase Function rollback
- The `classifyImage` function can be disabled in the Firebase console without any client change.
- When the function is unavailable, `BackendProxyProvider` maps the error to `AiFailureKind.providerUnavailable`, which is non-terminal in non-release builds and falls through to the direct client path.
- In release builds, the error surfaces to the user (fail-closed is intentional).

---

## Related Documents

- `docs/review/BACKEND_GATEWAY_IMPLEMENTATION_NOTES_2026-05-21.md` — detailed backend implementation notes
- `docs/review/AI_PIPELINE_TRUTH_MAP_2026-05-21.md` — complete AI pipeline truth map
- `docs/review/RATE_LIMIT_TRUTH_TABLE_2026-05-21.md` — rate limit truth table
- `docs/architecture/CURRENT_AI_ARCHITECTURE.md` — current AI architecture overview
- `functions/src/classify_image.ts` — backend callable function source
- `lib/services/providers/classification_provider.dart` — provider interface
- `lib/services/providers/local_vlm_provider.dart` — on-device VLM stub
- `lib/utils/production_safety_config.dart` — canonical flag definition
