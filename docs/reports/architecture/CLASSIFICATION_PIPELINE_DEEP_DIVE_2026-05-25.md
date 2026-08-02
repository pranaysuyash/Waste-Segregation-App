# Classification Pipeline Deep Dive — Full Flow Map, Gap Analysis, and Observability Assessment

**Date**: 2026-05-25
**Scope**: End-to-end trace of the classification pipeline: camera shutter → state machine → multi-layer routing → quality gates → cache → policy → rendering → feedback → offline queue → retry → fallback chain
**Method**: First-principles trace through every service, model, screen, and provider. Verified against actual code, not architecture docs.
**Status**: Baseline reference for pipeline observability, F13 (Scan Failure Resilience), F3 (Continuous Learning), and the analytics stack.

---

## 1. Executive Summary

The classification pipeline is the app's core product — every other feature (gamification, families, analytics, token economy) depends on it. It is also the app's least observable subsystem.

**What it is**: A 4-layer routing pipeline (deterministic → on-device ML → cheap cloud → strong cloud) gated by a 20-state state machine with 50 validated transitions, backed by a dual-tier cache, an offline queue, exponential-backoff retry, and a feedback loop.

**Key finding**: The pipeline is architecturally well-structured — clean layer separation, proper state machine, multiple safety gates, dual cache tiers. But it is **observability-thin**:
- 15+ routing/quality fields collected on every classification (`routeDecision`, `routeLatencyMs`, `routeCostUsd`, `qualityScore`, `needsReview`, etc.) are stored in the model but surfaced in zero UIs
- The routing dashboard (`model_routing_screen.dart`) is a 112-line stub saying "Future: Evidence Dashboard"
- Layer 1 (on-device ML) uses a `FakeLocalClassifier(isModelLoaded: false)` — it's effectively skipped in production
- Failures are transient in the state machine — no persistent `FailedClassification` model exists
- The offline queue drops items silently after 3 retries with no dead-letter queue or audit trail
- Architecture doc (`CURRENT_AI_ARCHITECTURE.md`) describes a 1-layer (backend proxy only) flow that diverges from the 4-layer pipeline actually implemented

**What this means**: The routing logic exists, the data is collected, but nobody — not the user, not the operator, not the analytics pipeline — can answer "what actually happened" for any given classification. This is the prerequisite gap before F3 (Continuous Learning) or F13 (Scan Failure Recovery) can be credible.

---

## 2. End-to-End Flow Map

```
                        ┌─────────────────────────────────────────┐
                        │          CAMERA / GALLERY CAPTURE        │
                        │  ImageService.saveFilePermanently()      │
                        └────────────────┬────────────────────────┘
                                         │
                                         ▼
              ┌────────────────────────────────────────────┐
              │         [1] IMAGE QUALITY GATE             │
              │   image_quality_gate.dart                   │
              │   • Min resolution: 300×300                 │
              │   • Blur detection: Laplacian var ≥ 100     │
              │   • Brightness: 40–250 range                │
              │   • Fail-open: if check crashes, pass       │
              └────────────────┬────────────────────────────┘
                               │
                         ┌─────┴──────┐
                         │  REJECTED  │  FAILED
                         ▼            ▼
              qualityRejected   failedRetryable
                                         │
                                         ▼
              ┌────────────────────────────────────────────┐
              │         [2] DUAL HASH GENERATION           │
              │   ai_service.dart (lines 757-763)           │
              │   • Perceptual hash (phash) — similarity     │
              │   • Content hash (SHA256) — exact verify    │
              │   • Runs in Isolate via compute()            │
              └────────────────┬────────────────────────────┘
                               │
                               ▼
              ┌────────────────────────────────────────────┐
              │         [3] CACHE CHECK                    │
              │   cache_service.dart / enhanced_cache.dart  │
              │   Composite key:                             │
              │   phash::region::lang::promptVer::schemaVer  │
              │   ::guidelinesVer::provider::model            │
              │   • Stage A: Exact key match                 │
              │   • Stage B: Hamming distance ≤ 6/64 bits    │
              │   • Stage C: Fallback basic (no content ver) │
              │   LRU eviction: 1000 entries max             │
              └────────────────┬────────────────────────────┘
                         ┌─────┴──────┐
                         │   HIT      │  MISS
                         ▼            ▼
                    cacheHit     classificationSucceeded
                    (short-circuit)    │
                                       ▼
              ┌────────────────────────────────────────────┐
              │         [4] LAYER 0: DETERMINISTIC         │
              │   layer0_router.dart                        │
              │   ┌──── BARCODE LOOKUP ──────────────────┐  │
              │   │  world.openfoodfacts.org/api/v0/     │  │
              │   │  LRU cache: 500 entries, 7-day TTL   │  │
              │   │  Confidence: 0.90 (packaging match)  │  │
              │   │             0.80 (food cat match)    │  │
              │   │             0.60 (unknown)           │  │
              │   └──────────────────────────────────────┘  │
              │   ┌──── COLOR HISTOGRAM ─────────────────┐  │
              │   │  Isolate: downsample 256×256, HSV    │  │
              │   │  5 rules: green→wet, brown→wet,     │  │
              │   │  multi-color→dry, white→dry, grey→dry│  │
              │   │  Confidence: 0.80→0.55               │  │
              │   └──────────────────────────────────────┘  │
              └────────────────┬────────────────────────────┘
                         ┌─────┴──────────────────┐
                         │  accept (conf≥0.90)    │  escalate/hint/reject
                         ▼                       ▼
                    classificationSucceeded    Layer 1
                    layer='layer0_deterministic'
                                         │
                                         ▼
              ┌────────────────────────────────────────────┐
              │         [5] LAYER 1: ON-DEVICE ML          │
              │   local_classifier_service.dart              │
              │   CURRENT STATE: FakeLocalClassifier(        │
              │     isModelLoaded: false)                    │
              │   → Always returns !isModelLoaded             │
              │   → Layer 1 is effectively SKIPPED           │
              │                                              │
              │   CONFIGURED THRESHOLDS:                    │
              │   • passThreshold: 0.75                     │
              │   • escalateThreshold: 0.50                 │
              │   • safetyOverrideThreshold: 0.90           │
              │   • Guardrails: 0.85 accept, 0.70 escalate  │
              └────────────────┬────────────────────────────┘
                               │  (always escalates currently)
                               ▼
              ┌────────────────────────────────────────────┐
              │         [6] LAYER 2/3: CLOUD               │
              │   EnhancedAiApiService.analyzeWasteImage()  │
              │                                              │
              │   Provider Router:                           │
              │   1. Backend Proxy (Firebase callable)       │
              │      → classifyImage Cloud Function          │
              │      → auth + rate limit (10/min) + OpenAI   │
              │      → Gemini fallback on provider failure   │
              │      → Fail-closed in release mode           │
              │   2. Direct OpenAI (debug/profile only)      │
              │      → ProductionSafetyConfig guarded        │
              │   3. Direct Gemini (debug/profile, fallback) │
              │                                              │
              │   RETRY: exponential backoff                 │
              │   500×2^retry ms (500ms, 1s, 2s), max 3      │
              │                                              │
              │   CIRCUIT BREAKER:                           │
              │   OpenAI: 5 fails, 3-min cooldown            │
              │   Gemini: 8 fails, 3-min cooldown            │
              └────────────────┬────────────────────────────┘
                               │
                               ▼
              ┌────────────────────────────────────────────┐
              │         [7] GUARDRAILS + POLICY            │
              │   classification_router_guardrails.dart      │
              │   • evaluateCloud():                        │
              │     - Rule version change → reject          │
              │     - Requires Manual Review category → rej │
              │   • evaluateLocal():                        │
              │     - Safety < 0.97 → reject                │
              │     - Confidence < 0.85 → reject            │
              │     - Confidence < 0.70 → escalate          │
              │                                              │
              │   local_global_rule_resolver.dart            │
              │   • Society policy overrides                 │
              │   • Local regulation amendments              │
              │   • policyPackId applied                     │
              │                                              │
              │   confidence_calibration_service.dart        │
              │   • Identity curve (no eval data yet)        │
              │   • Category overrides:                     │
              │     Hazardous → min L3                       │
              │     Medical → min L3                         │
              │     E-Waste → min L2                         │
              └────────────────┬────────────────────────────┘
                               │
                         ┌─────┴──────────────────┐
                         │  accepted              │  clarificationNeeded
                         ▼                       ▼
                    classificationSucceeded  awaitingUserConfirmation
                               │
                               ▼
              ┌────────────────────────────────────────────┐
              │         [8] RESULT PIPELINE                │
              │   result_pipeline.dart                      │
              │   1. Local save + duplicate detection       │
              │   2. Gamification (points, achievements)    │
              │   3. Cloud sync (Firestore)                 │
              │   4. Community feed post (if opted in)      │
              │   5. Interstitial ad (if count met)         │
              │   6. Analytics tracking                     │
              └───────────────────┬────────────────────────┘
                                  │
                                  ▼
              ┌────────────────────────────────────────────┐
              │         [9] RESULT RENDERING               │
              │   result_screen.dart (2067 lines)           │
              │   • Header (category chip, confidence bar)  │
              │   • DisposalAccordion                       │
              │   • ExplanationPanel (+ alternatives)       │
              │   • Impact Reveal (eco-score, CO2, etc.)    │
              │   • Category Snapshot (18 fields)           │
              │   • Safety Warnings                         │
              │   • MaterialsPreview                        │
              │   • Local Rules (BBMP)                      │
              │   • Points card + Near-Milestone Nudge      │
              └───────────────────┬────────────────────────┘
                                  │
                                  ▼
              ┌────────────────────────────────────────────┐
              │         [10] FEEDBACK LOOP                 │
              │   CorrectionDialog → ResultPipeline        │
              │   1. Idempotency check (stable dedup key)   │
              │   2. Local Hive save                        │
              │   3. TrainingDataService attachment         │
              │   4. Cloud sync (Firestore feedback)        │
              │   5. Gamification (3pts confirm/15pts corr) │
              │   6. Re-analysis via handleUserCorrection() │
              │      → Firebase function or direct provider │
              └────────────────────────────────────────────┘
```

---

## 3. State Machine Analysis: 20 States, 50 Transitions

**File**: `lib/models/classification_state.dart`

### Complete State Table

| # | State | Meaning | Terminal? | Recoverable? |
|---|-------|---------|-----------|-------------|
| 1 | `idle` | No image selected (initial/reset) | No | — |
| 2 | `imageSelected` | User captured/picked image | No | — |
| 3 | `qualityChecking` | Pre-flight quality gate | No | — |
| 4 | `qualityRejected` | Image failed quality check | No | Yes (retake/use anyway) |
| 5 | `cacheChecking` | Checking classification cache | No | — |
| 6 | `cacheHit` | Cache returned valid result | No | — |
| 7 | `cloudClassifying` | Cloud AI running | No | — |
| 8 | `localClassifying` | On-device model running | No | — |
| 9 | `queuedOffline` | Offline, queued for later | No | — |
| 10 | `classificationSucceeded` | AI returned usable result | No | — |
| 11 | `policyApplied` | Local policy engine applied | No | — |
| 12 | `awaitingUserConfirmation` | Low confidence / fallback | No | — |
| 13 | `saving` | Saving to local storage | No | — |
| 14 | `saved` | Local save confirmed | No | — |
| 15 | `syncing` | Syncing to cloud | No | — |
| 16 | `synced` | Cloud sync confirmed | Yes | — |
| 17 | `failedRetryable` | Transient failure | No | Yes |
| 18 | `failedPermanent` | Terminal failure | Yes | No |
| 19 | `cancelled` | User/system cancelled | Yes | No |

### Transition Complexity

Valid transitions: **50** (captured in `kClassificationTransitions` map)

Key structural observations:
- **No direct idle→classifying** paths — always through qualityChecking/cacheChecking
- **qualityRejected can bypass to cacheChecking** — user taps "Use Anyway"
- **failedRetryable → qualityChecking** — full restart, not partial resume
- **syncing → saved** — sync failure is explicitly non-critical
- **synced → idle** — flow complete, reset for next scan
- **cancelled → idle** — absorb-only transition, only reset allowed
- **No "retry from cache" path** — retry always restarts from qualityChecking

### What's Missing

| Gap | Impact |
|-----|--------|
| No `failedRetryable` persistence — failures are runtime-only | F13 cannot start. Every failure disappears on reset |
| No `failedPermanent` recovery when connectivity returns | Offline-queued items that hit 3 retries have no dead-letter path |
| No `needsReview` persisted state | Classifications marked `needsReview: true` have no dedicated UI surface |
| No state duration tracking | Cannot answer "how long did each state take?" without manual instrumentation |

---

## 4. Multi-Layer Routing Deep Dive

### Layer 0: Deterministic (Barcode + Color Histogram)

| Property | Value |
|----------|-------|
| Cost | Zero (free, no API call) |
| Latency | ~10-50ms (isolate-based) |
| Availability | Always (no network, no model load) |
| Acceptance threshold | 0.90 (barcode or color) |
| Hint threshold | 0.50 (degraded, offline only) |
| Safety escalation | Always: Hazardous, Medical, E-Waste, Chemical, Sharps, Pharma |
| Data source | `layer0_router.dart`, `color_histogram_classifier.dart`, `barcode_lookup_service.dart` |

Decision matrix:
| Condition | Decision |
|-----------|----------|
| Barcode hit, safety category | `escalate` |
| Barcode hit, conf ≥ 0.90 | `accept` |
| Barcode hit, conf ≥ 0.50 | `hint` |
| Color match, conf ≥ 0.90, not safety | `accept` |
| Color match, safety, conf ≥ 0.50 | `escalate` |
| Color match, conf ≥ 0.50 | `hint` |
| Neither | `reject` |

### Layer 1: On-Device ML (Currently Dead)

| Property | Value |
|----------|-------|
| Cost | Zero (on-device) |
| Model | TFLite/CoreML/ONNX |
| Implementation | `FakeLocalClassifier(isModelLoaded: false)` |
| Status | **Effectively dead** — always returns `!isModelLoaded` |
| Pass threshold | 0.75 (classifier), 0.85 (guardrails) |
| Safety override | 0.90 minimum for safety categories |

**Key insight**: Layer 1 is architecturally complete (interfaces defined, providers wired, thresholds configured, guardrails implemented) but functionally dead. The `FakeLocalClassifier` stub is the production path. The actual `LocalClassifier`/`OnDeviceVisionService`/`ObjectDetectionService` infrastructure exists but the model loading pipeline was never completed.

### Layer 2: Cloud — Cheap Model (GPT-4.1-nano / GPT-4o-mini)

| Property | Value |
|----------|-------|
| Cost | $0.00015/1K in, $0.0006/1K out |
| Latency | ~1-3s (backend proxy) |
| Acceptance threshold | 0.60 |
| Provider | Backend proxy (Firebase) → OpenAI → Gemini |
| Retry | Exponential backoff 500×2^N ms, max 3 |
| Circuit breaker | 5 failures / 3 min cooldown |

Provider router priority:
```
1. BackendProxyProvider (Firebase callable)
   → classifyImage function
   → OpenAI Vision primary
   → Gemini fallback (providerUnavailable / invalidImageTooLarge only)
2. Direct OpenAI client (debug/profile only)
   → ProductionSafetyConfig guard
3. Direct Gemini client (debug/profile fallback)
```

### Layer 3: Cloud — Strong Model (GPT-4o)

| Property | Value |
|----------|-------|
| Acceptance threshold | 0.0 (accepts all — final stage) |
| Activation | Category overrides: Hazardous → min L3, Medical → min L3, E-Waste → min L2 |
| Model | GPT-4o (or whichever strong model the backend proxy routes to) |

**Key insight**: Layer 3 is **implicit** — it's not a separate code path from Layer 2. The backend proxy (`classifyImage` function) decides which OpenAI model to use. The client-side Layer 3 routing is expressed only through `ConfidenceCalibrationService.categoryOverrides` that set `minimumLayer: 3`. The actual model selection happens server-side.

---

## 5. Quality Gates Inventory

| Gate | File | What It Checks | Fail Action |
|------|------|----------------|-------------|
| **Pre-flight Image Quality** | `image_quality_gate.dart` | 300×300 min, blur, brightness | `qualityRejected` state |
| **Cache Verification** | `cache_service.dart` | Content hash match after phash similarity | Cache miss → pipeline |
| **Router Guardrails (Local)** | `classification_router_guardrails.dart:evaluateLocal` | Safety ≥ 0.97, confidence ≥ 0.85, unknown category | Escalate or reject |
| **Router Guardrails (Cloud)** | `classification_router_guardrails.dart:evaluateCloud` | Rule version change, manual-review category | Reject |
| **Calibration Override** | `confidence_calibration_service.dart` | Category minimum layer enforcement | Escalate to higher layer |
| **Result Pipeline Quality** | `result_pipeline.dart:_deriveQualityScore/_deriveQualityReasons` | Image resolution, confidence, clarification flag | Quality score annotation (decorative) |
| **AI Flywheel Provider Gate** | `ai_flywheel/provider_quality_gate.dart` | Min 95% accuracy, 0 safety violations | Provider rejected |

### Quality Gate Data Flow

Every gate writes its decision to `WasteClassification` fields, but **the gate outputs are never surfaced**:

| Gate Output | Stored In | Surfaced? |
|-------------|-----------|-----------|
| Quality score (0-1) | `WasteClassification.qualityScore` | No |
| Quality reasons | `WasteClassification.qualityReasons` | No |
| Duplicate score | `WasteClassification.duplicateScore` | No |
| Duplicate cluster ID | `WasteClassification.duplicateClusterId` | No |
| Needs review flag | `WasteClassification.needsReview` | No |
| Review reason | `WasteClassification.reviewReason` | No |
| Raw confidence | `WasteClassification.rawConfidence` | No |
| Calibrated confidence | `WasteClassification.calibratedConfidence` | No |

---

## 6. Cache Architecture

### Dual Cache Tier

| Tier | File | Storage | Max Size | Eviction | TTL |
|------|------|---------|----------|----------|-----|
| **Primary** | `cache_service.dart` | Hive `StorageKeys.cacheBox` | 1000 entries | LRU (10% when full) | 30-day cleanup |
| **Enhanced** | `enhanced_cache_service.dart` | Hive `enhanced_cache_classifications` + `enhanced_cache_images` | 2000 entries / 100MB | Compression q0.8 | Not specified |

### Context-Aware Composite Key

Format: `phash_<hex>::region::lang::promptVersion::schemaVersion::guidelinesVersion::provider::model`

This means: same image + different region = cache miss. Same image + different model = cache miss. Correct by design.

### Cache Hit Path

```
Cache hit → short-circuit to classificationSucceeded
         → WasteClassification returned with routeDecision: 'cache_hit'
         → duplicateScore: 1.0
         → No points awarded (duplicate)
         → No cloud cost incurred
```

### Cache Bypass

- `blockCacheOnRuleVersionChange` flag (Remote Config)
- When `localRuleVersionChanged` → full cache bypass
- Layer 0 and Layer 1 results are NOT cached (deterministic by nature)

---

## 7. Offline Queue, Retry, and Fallback Chain

### Degradation Ladder

| Tier | Available Capability | Queue Behavior |
|------|---------------------|----------------|
| `fullOffline` | Layer 0 + Layer 1 | Instant local result or queue |
| `deterministicOnly` | Layer 0 only | Hint-level result or queue |
| `queued` | Nothing | Always queue for cloud |

### Queue Mechanics

| Property | Value |
|----------|-------|
| Storage | Hive `classification_queue.hive` |
| Model | `QueuedClassification` (6 fields) |
| Max retries | 3 (hardcoded) |
| Backoff | None between cycles (next connectivity change) |
| Token cost | Spends `AnalysisSpeed.batch` tokens per item |
| Fail action (3 retries) | Delete from queue, fire analytics event |
| Catastrophic fail | `ProductionSafetyException` → clear ALL queues |

### Retry Policy

```
Layer 0 failure → log → fall through to Layer 1
Layer 1 failure → log → fall through to Cloud
Cloud failure → retry 3× with exponential backoff
  → Gemini fallback (if eligible)
  → propagate terminal failure
All layers failed → WasteClassification.fallback() returned
```

### Fallback Classification Data

The `WasteClassification.fallback()` factory creates:

```dart
itemName: 'Unidentified Item - Fallback',
category: 'Requires Manual Review',
confidence: 0.0,
needsReview: true,
reviewReason: 'fallback_classification',
routeDecision: 'manual_review',
routeReason: 'fallback_classification',
policyPackId: 'policy-unknown',
modelRoute: 'fallback',
analysisSource: 'cloud_primary',
analysisFallbackReason: 'analysis_failed',
```

### Critical Gaps in Offline/Retry

| Gap | Impact |
|-----|--------|
| No dead-letter queue | After 3 retries, item is silently dropped. No audit trail beyond analytics event. |
| No per-item backoff | All items in the queue are retried at the same time on next connectivity. No staggered retry. |
| No exponential backoff per item | Only has "retry on next connectivity cycle" — no increasing delay between attempts. |
| No failed classification persistence | `ClassificationState.failedRetryable` and `failedPermanent` are runtime-only. Refresh the page and the failure is gone. |
| No retry button for permanent failures | User cannot retry a permanently failed classification — they must re-capture. |

---

## 8. Observability Assessment — What's Stored vs What's Surfaced

### Routing Fields (15 fields, 0 surfaced)

| Field | HiveField | Type | Source | UI Surface |
|-------|-----------|------|--------|------------|
| `routeDecision` | 95 | `String?` | Router/Cache | None |
| `routeReason` | 96 | `String?` | Router | None |
| `policyPackId` | 97 | `String?` | Policy engine | None |
| `modelRoute` | 98 | `String?` | Router | None |
| `routeLatencyMs` | 99 | `int?` | Router timer | None |
| `routeCostUsd` | 100 | `double?` | Cost tracker | None |
| `analysisSource` | 101 | `String?` | Pipeline | Category Snapshot label |
| `analysisFallbackReason` | 102 | `String?` | Pipeline | Category Snapshot label |
| `modelSelectionStrategy` | 103 | `String?` | `ModelSelectionService` | None |
| `classificationLayer` | Runtime | `String?` | Pipeline | `OfflineResultBanner` (for offline hints only) |
| `isOfflineHint` | Runtime | `bool` | Offline service | Banner only |
| `needsCloudVerification` | Runtime | `bool` | Offline service | Banner only |

### Quality Fields (8 fields, 0 surfaced)

| Field | HiveField | Type | Source | UI Surface |
|-------|-----------|------|--------|------------|
| `qualityScore` | 87 | `double?` | `result_pipeline.dart` | None |
| `qualityReasons` | 88 | `List<String>?` | `result_pipeline.dart` | None |
| `duplicateScore` | 89 | `double?` | Cache/dedup | None |
| `duplicateClusterId` | 90 | `String?` | Cache/dedup | None |
| `rawConfidence` | 91 | `double?` | AI response | None |
| `calibratedConfidence` | 92 | `double?` | Calibration service | None |
| `needsReview` | 93 | `bool?` | Router guardrails | None |
| `reviewReason` | 94 | `String?` | Router guardrails | None |

### What IS Surfaced in Category Snapshot

The `result_screen.dart` Category Snapshot section does show:
- `analysisSourceLabel` (formatted version of `analysisSource`)
- `analysisFallbackReason`
- `modelVersion`

But NOT: `routeDecision`, `routeLatencyMs`, `routeCostUsd`, `routeReason`, `modelRoute`, `classificationLayer` (except offline), `modelSelectionStrategy`, any quality fields.

### The Model Routing Dashboard

**File**: `lib/screens/model_routing_screen.dart`

Current state: **112-line stub** with:
- `Available Strategies` — lists enum values (no actual data)
- `Evidence Collection` — text description of what's recorded
- `Future: Evidence Dashboard` — placeholder card

**Planned features per stub**: Per-source success/failure counts, average confidence/latency, fallback chain analysis, correction rate per strategy, cost breakdown, strategy recommendation engine. **None implemented.**

### Impact Dashboard Coverage

**File**: `lib/screens/impact_dashboard_screen.dart`

Shows aggregate system metrics:
- Classification quality (high/low confidence count)
- Accuracy rate (confirmations vs corrections)
- Offline queue stats
- Cost savings

**Does NOT show**: Per-layer metrics, route distribution, cache hit rate, fallback rate, latency distribution, error rates by layer.

---

## 9. Architecture Drift (motto §7 Assessment)

### Actual Code vs `CURRENT_AI_ARCHITECTURE.md`

The architecture doc (`docs/architecture/CURRENT_AI_ARCHITECTURE.md`, last verified 2026-05-22) describes:

```
AiService backend routing gate → BackendProxyProvider → classifyImage → OpenAI → Gemini
```

This is accurate for the **cloud** path. But it omits:

| What's Missing From Doc | Where It Exists | Drift Severity |
|------------------------|-----------------|----------------|
| Layer 0 (deterministic) pipeline | `layer0_router.dart`, `color_histogram_classifier.dart`, `barcode_lookup_service.dart` | Medium — doc describes a 1-layer cloud flow, code has 4 layers |
| Layer 1 (on-device ML) | `local_classifier_service.dart`, `object_detection_service.dart`, `on_device_vision_service.dart` | Medium — doc doesn't mention on-device pipeline at all |
| ClassificationPipeline orchestrator | `classification_pipeline.dart` | Medium — the orchestrator that chains L0→L1→cloud is undocumented |
| ClassificationRouter + Guardrails | `classification_router.dart`, `classification_router_guardrails.dart` | Medium — routing decision engine completely undocumented |
| ConfidenceCalibrationService | `confidence_calibration_service.dart` | Low — calibration layer is internal |
| Cache architecture | `cache_service.dart`, `enhanced_cache_service.dart` | Low — cache is documented elsewhere |
| State machine | `classification_state.dart`, `classification_state_provider.dart` | Low — mostly a client concern |

**Assessment**: The architecture doc is incomplete, not wrong. It describes only the cloud classification path (the canonical release-mode path) and omits the 4-layer orchestration, routing, guardrails, and calibration that wrap it. This is a doc gap, not code gap.

### Duplicate Pipelines Check

| Feature | Canonical Path | Alternative Path | Status |
|---------|---------------|------------------|--------|
| Cloud classification | Backend proxy via Firebase callable | Direct OpenAI/Gemini client | Controlled by build mode + feature flags — intentional, not drift |
| Image persistence | `ImageService.saveFilePermanently()` | `CloudStorageService` upload | Separate concerns (local vs cloud) |
| Cache | `ClassificationCacheService` | `EnhancedCacheService` | Two implementations for the same purpose — potential drift risk |
| Classification processing | `ClassificationPipeline` | `EnhancedAiApiService` standalone | Pipeline orchestrates; EnhancedAiApiService is the cloud implementation — clean separation |

**`EnhancedCacheService` vs `ClassificationCacheService`**: Two cache implementations with different storage schemas. `EnhancedCacheService` has its own Hive box (`enhanced_cache_classifications`), its own image storage (`enhanced_cache_images`), and its own compression/image-processing pipeline. This is a **potential supersession candidate per motto §7** — if `EnhancedCacheService` was meant to replace `ClassificationCacheService`, the old one should be deprecated with callers migrated.

---

## 10. Gap Analysis and Recommendations

### P0 — Blocks Launch/Money

| Gap | What's Needed | File(s) | Effort |
|-----|---------------|---------|--------|
| Failures are transient — no persistent record | Create `FailedClassification` persistence model. Replace runtime-only state transitions with Hive-backed failure storage. | `classification_state.dart`, `classification_pipeline.dart` | 2-3 days |
| Offline queue has no dead-letter path | Add `deadLetterQueue` collection, per-item failure recording, admin review surface | `offline_queue_service.dart` | 1 day |
| Route decision data exists but cannot be queried | Add `getRouteDistribution()`, `getCacheHitRate()`, `getFallbackRate()` methods to StorageService + a screen | `storage_service.dart`, `model_routing_screen.dart` | 2-3 days |

### P1 — Serious Observability Gap

| Gap | What's Needed | File(s) | Effort |
|-----|---------------|---------|--------|
| 15 routing/quality fields stored but zero UI surface | Build `ModelRoutingDashboard → ClassificationRouteHistoryCard → RouteDetailSheet` widget stack | `model_routing_screen.dart`, new widgets | 3-4 days |
| Cache hit rate, miss rate, eviction rate not trackable | Add `ClassificationCacheService` statistics to ImpactDashboard or Routing screen | `cache_service.dart`, `impact_dashboard_screen.dart` | 1 day |
| Layer success/failure rates cannot be computed | Ensure every classification has `classificationLayer` persisted, then aggregate | `classification_pipeline.dart`, `waste_classification.dart` | 0.5 day |
| `ImpactDashboard` doesn't show per-layer metrics | Add layer distribution chart, latency histogram, cost breakdown | `impact_dashboard_screen.dart` | 2 days |

### P2 — Architecture Cleanup

| Gap | What's Needed | File(s) | Effort |
|-----|---------------|---------|--------|
| `EnhancedCacheService` and `ClassificationCacheService` overlap | Decide canonical cache, deprecate the other, migrate data | `cache_service.dart`, `enhanced_cache_service.dart` | 2-3 days |
| Layer 1 is `FakeLocalClassifier` — architectural debt | Either implement real on-device ML (F1) or remove the dead code path | `local_classifier_service.dart`, `classification_pipeline_providers.dart` | 1-2 weeks (F1) or 1 day (prune) |
| Architecture doc incomplete | Update `CURRENT_AI_ARCHITECTURE.md` to describe full pipeline, not just cloud path | `docs/architecture/CURRENT_AI_ARCHITECTURE.md` | 0.5 day |
| No state duration tracking | Add `DateTime` capture on state entry transitions | `classification_state.dart` | 0.5 day |

### P3 — Polish/DX

| Gap | What's Needed | File(s) | Effort |
|-----|---------------|---------|--------|
| `model_routing_screen.dart` is a stub | Replace with real dashboard or remove the route | `model_routing_screen.dart` | 3-4 days (build) or 0.5 (remove) |
| `ClassificationState` missing error detail | Add `failureReason` and `failureDetails` fields to the state machine | `classification_state.dart` | 0.5 day |
| No offline queue health metrics in routing screen | Add queue depth, average wait time, failure rate | `offline_queue_service.dart`, `model_routing_screen.dart` | 1 day |

---

## 11. Data Contracts at Each Pipeline Stage

### Pre-Cache / Layer 0 Entry

```
Input:  Uint8List imageBytes, String region, String? barcode
Output: Layer0Result { decision, wasteClassification?, routeReason, totalProcessingTimeMs }
```

### Layer 1 Entry

```
Input:  Uint8List imageBytes, String region
Output: LocalClassificationResult { category, confidence, failureReason,
         requiresEscalation, shouldEscalateToCloud, wasteClassification? }
```

### Cloud Entry

```
Input:  Uint8List imageBytes, String region, String? language, String? userId
Output: WasteClassification (full 100+ field model)
```

### After Guardrails

```
Depends on guardrail evaluation. If rejected:
  → WasteClassification with routeDecision: 'manual_review',
     clarificationNeeded: true
If accepted:
  → Standard WasteClassification with classificationLayer, analysisSource populated
```

### Cache Hit

```
Output: WasteClassification with routeDecision: 'cache_hit', duplicateScore: 1.0
```

### Offline Queue Entry

```
Model: QueuedClassification { id, imageBytes, region, queuedAt, retryCount, userId?, imageName? }
Queue: Hive box 'classification_queue'
```

### Fallback Output

```dart
WasteClassification.fallback(String imagePath, {String? userId, String? id})
→ confidence: 0.0, category: 'Requires Manual Review',
  routeDecision: 'manual_review', needsReview: true
```

---

## 12. Key Files

| Layer | File | Purpose |
|-------|------|---------|
| State Machine | `lib/models/classification_state.dart` | 20-state enum + 50-transition state machine |
| State Provider | `lib/providers/classification_state_provider.dart` | Riverpod StateNotifier for state machine |
| Pipeline Orchestrator | `lib/services/classification_pipeline.dart` | L0 → L1 → cloud orchestration |
| Layer 0 | `lib/services/layer0_router.dart` | Barcode + color histogram router |
| Layer 0 Color | `lib/services/color_histogram_classifier.dart` | HSV-based deterministic classification |
| Layer 0 Barcode | `lib/services/barcode_lookup_service.dart` | Open Food Facts API wrapper |
| Layer 0 Mapping | `lib/services/layer0_disposal_mapping.dart` | Hardcoded disposal for 25+ subcategories |
| Layer 1 | `lib/services/local_classifier_service.dart` | Abstract on-device ML (FakeLocalClassifier) |
| Layer 1 Vision | `lib/services/on_device_vision_service.dart` | TFLite/CoreML/ONNX inference |
| Layer 1 YOLO | `lib/services/object_detection_service.dart` | YOLO model management |
| Cloud Router | `lib/services/providers/ai_provider_router.dart` | Backend proxy → OpenAI → Gemini orchestration |
| Cloud Backend | `lib/services/providers/backend_proxy_provider.dart` | Firebase callable client |
| Cloud OpenAI | `lib/services/providers/openai_provider_client.dart` | Direct OpenAI HTTP client |
| Cloud Gemini | `lib/services/providers/gemini_provider_client.dart` | Direct Gemini HTTP client |
| Cloud Service | `lib/services/enhanced_ai_api_service.dart` | Cloud A/B race, fallback, guard integration |
| Router | `lib/services/classification_router.dart` | Adaptive routing: decide(), decideInitial() |
| Guardrails | `lib/services/classification_router_guardrails.dart` | evaluateLocal(), evaluateCloud() |
| Calibration | `lib/services/confidence_calibration_service.dart` | Category overrides, layer thresholds |
| Policy | `lib/services/local_global_rule_resolver.dart` | Local → society policy precedence |
| Pre-flight Quality | `lib/services/image_quality_gate.dart` | Resolution, blur, brightness checks |
| Cache Primary | `lib/services/cache_service.dart` | Hive perceptual hash cache, LRU eviction |
| Cache Enhanced | `lib/services/enhanced_cache_service.dart` | Alternative cache with image compression |
| Cache Key | `lib/services/classification_cache_key.dart` | Context-aware composite key builder |
| Offline Service | `lib/services/offline_classification_service.dart` | Degradation tiers, local-only/hint paths |
| Offline Queue | `lib/services/offline_queue_service.dart` | Hive-backed queue, processing, retry |
| Network Resilience | `lib/services/resilient_network_service.dart` | Retry with backoff, circuit breaker |
| Result Pipeline | `lib/services/result_pipeline.dart` | Post-classification: save, gamify, sync, post, ad |
| Feedback Model | `lib/models/classification_feedback.dart` | 16-field correction record |
| Correction Dialog | `lib/widgets/correction_dialog.dart` | User-facing correction UI |
| AI Flywheel Eval | `lib/ai_flywheel/eval_runner.dart` | Eval harness for pipeline quality measurement |
| AI Flywheel Quality | `lib/ai_flywheel/provider_quality_gate.dart` | 95% accuracy, 0 safety violation gate |
| AI Flywheel Training | `lib/ai_flywheel/training_candidate_policy.dart` | Correction → training data pipeline |
| Result Screen | `lib/screens/result_screen.dart` | 2067-line result rendering |
| Impact Dashboard | `lib/screens/impact_dashboard_screen.dart` | System metrics (partial) |
| Routing Dashboard | `lib/screens/model_routing_screen.dart` | **Stub** — 112 lines, "Future: Evidence Dashboard" |
| Pipeline Providers | `lib/providers/classification_pipeline_providers.dart` | Riverpod wiring for pipeline |
| Cost Guardrails | `lib/services/cost_guardrail_service.dart` | Budget %, batch mode enforcement |
| Dynamic Pricing | `lib/services/dynamic_pricing_service.dart` | Per-model costs, daily/weekly/monthly budgets |
| Model Selection | `lib/services/model_selection_service.dart` | 7 strategy enum + strategy selection |
| Arch Doc | `docs/architecture/CURRENT_AI_ARCHITECTURE.md` | Current (incomplete) architecture description |
| Analytical Audit | `docs/reports/analytics/CONSOLIDATED_ANALYTICS_AUDIT_2026-05-25.md` | Prior analytics gap analysis |
| Analytical Audit Detail | `docs/reports/analytics/ANALYTICS_UI_GAP_ANALYSIS_2026-05-25.md` | Prior analytics gap detail |

---

## 13. Confidence Assessment

| Claim | Confidence | Evidence |
|-------|------------|----------|
| 20 ClassificationState states exist with 50 transitions | 100% | Read `lib/models/classification_state.dart` — enum and `kClassificationTransitions` map verified |
| Layer 1 uses FakeLocalClassifier | 100% | `lib/providers/classification_pipeline_providers.dart` line 19 |
| 15 routing/quality fields on WasteClassification have zero UI surface | 100% | Grep of every screen file for each field name. Only `analysisSource` and `analysisFallbackReason` referenced (in Category Snapshot) |
| `model_routing_screen.dart` is a stub | 100% | Read the 112-line file — "Future: Evidence Dashboard" placeholder |
| Offline queue drops after 3 retries | 100% | `lib/services/offline_queue_service.dart` line 393: `if (item.retryCount >= 3)` |
| Architecture doc is incomplete, not wrong | 90% | Doc describes cloud path accurately. Layer 0/1, router, guardrails, calibration not covered. Doc preamble says "supersedes aspirational design docs" |

**Uncertainties**:
- Whether `EnhancedCacheService` or `ClassificationCacheService` is the intended canonical cache — both are active, no deprecation marker on either
- Whether Layer 1 `FakeLocalClassifier` was intentional deferral or incomplete work
- Whether route latency/cost fields are actually populated in production (they're collected by the router, but no production dash confirm)
