# Issue Review: Unguarded Client-Side AI Provider Calls in Release Builds

**Date:** 2026-05-21  
**Severity:** Critical (P0 — data exfiltration risk, API key exposure in release binary)  
**Scope:** `lib/services/enhanced_ai_api_service.dart`, `lib/services/ai_job_service.dart`, `lib/services/offline_queue_service.dart`

---

## Root Pattern

`ProductionSafetyConfig.guardClientAiCall()` exists to block direct AI provider HTTP calls in release builds unless `--dart-define=ALLOW_CLIENT_AI_IN_RELEASE=true` is explicitly set. The guard works correctly in `AiService` and at `ApiClientFactory` level. However, two separate production-reachable paths bypassed the guard entirely.

---

## Affected Files and Findings

### 1. `lib/services/enhanced_ai_api_service.dart` — FIXED

**Gap:** `_analyzeWithOpenAI()` and `_analyzeWithGemini()` made direct Dio POST calls to OpenAI and Gemini endpoints without calling `guardClientAiCall()` first. These methods are reachable in production via:

```
OfflineQueueService._processQueue()
  → EnhancedAiApiService().analyzeWasteImage()
    → _analyzeWithOpenAI() / _analyzeWithGemini()
```

**Fix:** Added `ProductionSafetyConfig.guardClientAiCall('OpenAI')` and `guardClientAiCall('Gemini')` as the first statement in each method.

**Defense-in-depth note:** `ApiClientFactory.getOpenAIClient()` and `getGeminiClient()` also call `guardClientAiCall` before creating Dio clients, so the guard is double-enforced. The addition in the private methods is belt-and-suspenders.

**Backend routing behavior (added by parallel agent, verified):**  
`_backendRoutingEnabled = kReleaseMode || useBackendAiInRelease || BackendProxyProvider.isEnabled`.  
In release builds this is always `true`, routing to `_analyzeWithBackend` first. `_backendRoutingFailClosed = kReleaseMode || useBackendAiInRelease` — in release, backend failures are re-thrown immediately and direct providers are never reached. The guards in `_analyzeWithOpenAI`/`_analyzeWithGemini` serve as defense-in-depth for edge cases where the routing flag logic changes.

---

### 2. `lib/services/ai_job_service.dart` — FIXED (new finding via §10 pattern search)

**Gap:** `_uploadToOpenAI()` (line ~212) and `_submitOpenAIBatchJob()` (line ~247) made raw `http.MultipartRequest` and `http.post` calls to `https://api.openai.com/v1/files` and `https://api.openai.com/v1/batches` respectively, with NO `guardClientAiCall()` anywhere in the file. These are direct HTTP calls bypassing the `ApiClientFactory` guard layer entirely (they use `dart:http`, not Dio).

Production exposure path:
```
aiJobServiceProvider (lib/providers/ai_job_providers.dart)
  → AiJobService.createBatchJob()
    → _createOpenAIBatchFile()
      → _uploadToOpenAI()        ← direct http.MultipartRequest to api.openai.com
    → _submitOpenAIBatchJob()    ← direct http.post to api.openai.com
```

**Fix:** Added `ProductionSafetyConfig.guardClientAiCall('OpenAI Batch API')` as the **first statement** in `createBatchJob()`, the sole public entry point. This ensures neither `_uploadToOpenAI` nor `_submitOpenAIBatchJob` can be reached in a blocked release build, and also prevents the token deduction step from running before the safety check.

Import added: `import '../utils/production_safety_config.dart';`

---

### 3. `lib/services/offline_queue_service.dart` — FIXED (new finding via exception propagation analysis)

**Gap:** `_processQueue()` wrapped `EnhancedAiApiService().analyzeWasteImage()` in a generic `catch (e, stackTrace)` block that refunded tokens, incremented `item.retryCount`, and retried up to 3 times before permanent failure — regardless of exception type. `ProductionSafetyException` is a terminal, non-retriable condition (the build is blocked; retrying won't help), but it was treated as a transient failure to retry.

**Fix:** Added `if (e is ProductionSafetyException) rethrow;` as the first statement in the catch block, before the token refund and retry logic. `ProductionSafetyException` now propagates immediately up to `_processQueue()`'s caller.

Import added: `import '../utils/production_safety_config.dart';`

---

## Files Verified as Correctly Guarded (No Changes Needed)

| File | Guard location | Mechanism |
|------|---------------|-----------|
| `lib/services/ai_service.dart` | Lines 1287, 1561, 1763 | `guardClientAiCall` at each direct provider call site |
| `lib/services/api_client_factory.dart` | Lines 21–22, 74–75 | `guardClientAiCall` before Dio client creation |
| `lib/services/providers/openai_provider_client.dart` | Line 108 | `guardClientAiCall` at provider class level |
| `lib/services/providers/gemini_provider_client.dart` | Via `ApiClientFactory` | Guarded at factory construction; direct usage requires passing through factory |
| `lib/services/providers/backend_proxy_provider.dart` | N/A — correct by design | Routes through Firebase Callable, not direct AI API |

---

## Guard Coverage Map (Post-Fix)

```
Release build direct AI call paths:
  EnhancedAiApiService._analyzeWithOpenAI()   ← guardClientAiCall('OpenAI') [FIXED]
  EnhancedAiApiService._analyzeWithGemini()   ← guardClientAiCall('Gemini') [FIXED]
  AiService._callOpenAI()                     ← guardClientAiCall (existing, 3 sites)
  AiJobService.createBatchJob()               ← guardClientAiCall('OpenAI Batch API') [FIXED]
  ApiClientFactory.getOpenAIClient()          ← guardClientAiCall (existing)
  ApiClientFactory.getGeminiClient()          ← guardClientAiCall (existing)
  OpenAiProviderClient.analyze()              ← guardClientAiCall (existing, line 108)
  BackendProxyProvider.*                      ← no guard needed (secure backend path)
```

---

## Exception Propagation Contract (Verified)

`ProductionSafetyException` extends `Exception`, not `AiFailure`. In `EnhancedAiApiService`, catch blocks at lines 134, 199, 223, 264, 320, 355 use `on AiFailure catch` or generic `catch` with `rethrow`. In all cases, `ProductionSafetyException` either:
- Skips the `on AiFailure` handler entirely (type mismatch), or
- Is caught by a generic handler that ends in `rethrow`.

This means `ProductionSafetyException` propagates unmodified from its throw site to `OfflineQueueService`, which now re-throws it immediately.

---

## dart-define Flag Summary

| Flag | Purpose | Reads in |
|------|---------|---------|
| `ALLOW_CLIENT_AI_IN_RELEASE=true` | Permit direct AI calls in release (escape hatch) | `ProductionSafetyConfig._allowClientAiInRelease` |
| `USE_BACKEND_CLASSIFICATION=true` | Route to backend proxy (canonical) | `ProductionSafetyConfig._useBackendClassification`, `BackendProxyProvider.isEnabled` |
| `USE_BACKEND_AI_IN_RELEASE=true` | Legacy alias for `USE_BACKEND_CLASSIFICATION` | `ProductionSafetyConfig._useBackendClassificationLegacy` |

---

## Resolved Items *(2026-05-22)*

1. **`OfflineQueueService` queue cleanup on `ProductionSafetyException`** — FIXED.
   Previous `rethrow` left items stranded forever in the queue. Now: refunds the
   token for the current item, clears the entire queue box (all items are
   unprocessable for the same build reason), increments `permanentFailCount`, and
   `break`s out of the loop so `_processQueue` exits normally through the `finally`
   block. Tested via `offline_queue_service_test.dart` (no regression).

2. **Tests** — FIXED. `test/services/enhanced_ai_api_service_safety_test.dart`
   added with 26 passing tests covering: construction with/without injectable proxy,
   static flag contracts, backend routing via `overrideBackendRoutingForTest`,
   `providerCallCount` telemetry, terminal vs non-terminal failure rethrow,
   `ProductionSafetyConfig` invariants, and `getStatistics` shape.

3. **`AiJobService` batch result polling** — confirmed no guard needed (Firestore reads only).

4. **CI safety flag audit** — FIXED. Added `Safety flag audit` step to
   `.github/workflows/release.yml` that `grep`s `.github/`, `Makefile`, and
   `scripts/` for `ALLOW_CLIENT_AI_IN_RELEASE=true` and fails the build if found.

5. **`EnhancedAiApiService` injectable `backendProxy`** — FIXED. Added
   `ClassificationProvider? backendProxy` optional constructor parameter, stored as
   `_backendProxy`. `_analyzeWithBackend` uses
   `_backendProxy ?? BackendProxyProvider(functions: FirebaseFunctions.instance)`.
   Also added `@visibleForTesting overrideBackendRoutingForTest(bool?)` and
   `@visibleForTesting int get providerCallCount`, mirroring `AiService`.

## Remaining Open Items

- **`getStatistics()` reports `backend_proxy_mode: false` in debug with backend routing
  override active** — minor cosmetic gap; `getStatistics()` uses `kReleaseMode`
  as its proxy-mode indicator but doesn't check `_backendRoutingOverride`. Not a
  correctness issue at runtime; tracked for future cleanup.
- **No test for `OfflineQueueService._processQueue` safety-exception clear path** —
  the existing test only covers queueing and clearing; the internal `_processQueue`
  path requires a running `TokenService` + Hive. Tracked for integration test.
