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

## Open Items

1. **`OfflineQueueService` token refund on `ProductionSafetyException`**: Tokens deducted before `analyzeWasteImage` is called (at queue item creation time) are NOT refunded when `ProductionSafetyException` fires, because the refund code is after the `rethrow`. This is the correct outcome for safety violations — the item is abandoned — but verify that queue item deletion also occurs (it currently does not; the `retryCount` increment and `item.delete()` are also skipped). **Action required:** confirm queue item cleanup path for safety exceptions at the `_processQueue` outer loop level.

2. **Tests:** No unit tests exist for `guardClientAiCall` integration in `EnhancedAiApiService` or `AiJobService`. Tests should mock `kReleaseMode=true` and verify both services throw `ProductionSafetyException` rather than making HTTP calls.

3. **`AiJobService` batch result polling (`updateJobStatus`, `getUserJobs`)**: These read from Firestore, not direct AI API — no guard needed. Confirmed.

4. **CI build flags**: Ensure release CI builds do NOT set `ALLOW_CLIENT_AI_IN_RELEASE=true` inadvertently. Recommend adding a build-time assertion or CI lint check.
