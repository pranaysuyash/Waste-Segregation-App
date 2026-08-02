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

## Full classification pipeline (4 layers)

The ReLoop uses a multi-layer routing pipeline that progresses from
free/deterministic methods up to expensive cloud models only when necessary.
Every decision is recorded on the resulting `WasteClassification` record.

### Layer 0 — Deterministic (free, always available)

Pure client-side logic — no network, no model download.

```
Image / camera frame
         │
         ▼
ImageQualityGate         ← rejects blurry/dark/<300px images before any routing
         │ pass
         ▼
Layer0Router
         ├── BarcodeLookupService   ← Open Food Facts API (requires network)
         │     product match → category + material (high confidence)
         │
         └── ColorHistogramClassifier  ← HSV-based clustering (pure math)
               color clusters → category heuristic (medium confidence)
```

Layer 0 produces a `Layer0Result` with a `Layer0Decision`:
- `accept` — confident enough, skip higher layers
- `hint` — partial match, pass to higher layers with hint context
- `escalate` — no match, full cloud classification needed

### Layer 1 — On-device ML (not yet deployed)

Architecture exists; production wiring uses `FakeLocalClassifier(isModelLoaded: false)`.

```
ObjectDetectionService + OnDeviceVisionService
         │
         ▼
LocalClassifierService abstract
         │  FakeLocalClassifier (production) ← returns null, escalates to cloud
         │  TFLiteLocalClassifier (not deployed) ← actual model inference
```

### Layer 2 — Cloud cheap (GPT-4.1-nano via backend proxy)

```
ClassificationPipeline
         │
         ▼
ClassificationRouter.decide()
         │  selects initial layer + strategy
         ▼
EnhancedAiApiService.analyzeWasteImage()
         │  calls Firebase classifyImage callable
         ▼
OpenAI GPT-4.1-nano primary
         │ success → WasteClassification with analysisSource='cloud_primary'
         │ failure → Gemini flash fallback
         ▼
ClassificationRouterGuardrails.evaluateCloud()
         │  confidence gate, policy pack check
         ▼
ConfidenceCalibrationService
         │  category overrides, minimum layer enforcement
```

### Layer 3 — Cloud strong (GPT-4o, implicit — no dedicated route yet)

Reached when Layer 2 produces low confidence or a policy pack requires
stronger analysis. Currently implicit in the API fallback chain; the
`modelRoute` field records which model actually handled the request.

### Routing and quality fields (15 fields, all stored, all invisible in UI)

Every completed `WasteClassification` carries these fields populated by
`ResultPipeline._decorateForPersistence()`:

| Field | Source | Purpose |
|---|---|---|
| `routeDecision` | Derived from quality + duplicate state | `'cache_hit'`, `'retake'`, `'manual_review'`, `'local_first'` |
| `routeReason` | Derived from quality reasons | Human-readable chain, e.g. `'low_resolution,low_confidence'` |
| `policyPackId` | `localGuidelinesVersion` or `'policy-unknown'` | Which society/region policy was active |
| `modelRoute` | `modelSource` | Actual model name that produced the result |
| `modelSelectionStrategy` | `ModelSelectionStrategy.name` | Strategy selected before routing |
| `routeLatencyMs` | `processingTimeMs` | End-to-end latency for this classification |
| `routeCostUsd` | Estimated from model source | Approximate cost per call |
| `qualityScore` | Derived from image metrics | Normalized edge quality 0.0–1.0 |
| `qualityReasons` | Derived from image + confidence | `'low_resolution'`, `'low_confidence'`, etc. |
| `duplicateScore` | Set to 1.0 if duplicate hit | Whether a duplicate classification was reused |
| `duplicateClusterId` | Matched classification ID | Which prior classification was reused |
| `rawConfidence` | AI model confidence | Uncalibrated confidence from the model |
| `calibratedConfidence` | Same as raw (no calibration yet) | Reserved for future calibration curves |
| `needsReview` | True when confidence < 0.65 or clarificationNeeded | Flag for manual review |
| `reviewReason` | Same as `routeReason` | Why the classification needs review |

These fields are surfaced in the `ModelRoutingScreen` — a full dashboard
showing per-layer distribution, quality gate, route decisions, cost and
latency metrics, plus an expandable per-classification detail list.

### Offline pipeline

When the device is offline, `OfflineClassificationService` routes through
three degradation tiers:

1. **`fullOffline`** — Layer 0 + Layer 1 (requires on-device ML model loaded)
2. **`deterministicOnly`** — Layer 0 only (always available)
3. **`queued`** — Image queued for cloud processing when connectivity returns

`OfflineQueueService` manages a Hive-backed queue with 3-retry max.
Permanent failures now move to a **dead-letter queue** (`DeadLetterClassification`)
with full error details for audit and manual retry.

### Layer mapping in classificationLayer field

```
'layer0_deterministic'  — Layer 0 (barcode or color histogram)
'layer1_on_device'      — Layer 1 (on-device ML, not yet deployed)
'layer2_cloud_cheap'    — Layer 2 (GPT-4.1-nano, Gemini flash)
'layer3_cloud_strong'   — Layer 3 (GPT-4o, Gemini pro)
'layer0_hint_pending_cloud' — Offline hint awaiting cloud verification
```

### Key files for the full pipeline

| Layer | File | Responsibility |
|---|---|---|
| Orchestrator | `lib/services/classification_pipeline.dart` | L0→L1→cloud orchestration |
| L0 router | `lib/services/layer0_router.dart` | Barcode + color histogram routing |
| L0 barcode | `lib/services/barcode_lookup_service.dart` | Open Food Facts API wrapper |
| L0 color | `lib/services/color_histogram_classifier.dart` | HSV-based deterministic |
| L1 abstract | `lib/services/local_classifier_service.dart` | FakeLocalClassifier (production) |
| L2/L3 cloud | `lib/services/enhanced_ai_api_service.dart` | Backend proxy AI calls |
| Router | `lib/services/classification_router.dart` | Adaptive routing decision |
| Guardrails | `lib/services/classification_router_guardrails.dart` | Confidence + policy evaluation |
| Calibration | `lib/services/confidence_calibration_service.dart` | Category overrides |
| Quality gate | `lib/services/image_quality_gate.dart` | Pre-flight image validation |
| Cache (classifications) | `lib/services/cache_service.dart` | ClassificationCacheService (canonical) |
| Offline | `lib/services/offline_classification_service.dart` | Degradation tier routing |
| Cache (images) | `lib/services/cache_service.dart` | Automatic JPEG compression + resize via `_compressImage()`, separate `_imageBox` Hive store, in-memory dedup with 5-min TTL |
| Offline queue | `lib/services/offline_queue_service.dart` | Hive-backed queue + dead-letter |
| Post-classification | `lib/services/result_pipeline.dart` | Quality derive, save, gamify, sync |
| Eval harness | `lib/ai_flywheel/eval_runner.dart` | Pipeline quality evaluation |

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
| TFLite on-device model | Not implemented — production uses FakeLocalClassifier |
| Anthropic Claude as tertiary model | Not implemented |
| Keys stored server-side only | Not true for direct-client fallback paths |
| App Check fail-closed everywhere | Conditional; controlled by env and function type |
| 50/day or 10/min classification client-only model | Classification is now server-side via `classifyImage` |

## What is described here that has no UI

| Pipeline component | UI status |
|---|---|
| ClassificationCacheService stats | `CacheStatisticsCard` widget exists but is only used in widgetbook |
| Model routing cost breakdown | `ModelRoutingScreen` Cost & Performance card — total cost, avg cost/call, avg latency |

**What now has UI (built since last revision)**:

| Pipeline component | UI status |
|---|---|
| Layer 0–3 routing decisions | `ModelRoutingScreen` — full dashboard with per-layer distribution, quality gate, route decisions, cost/latency metrics, per-classification detail list, per-layer success/failure rates |
| Offline dead-letter queue | `ImpactDashboardScreen` — count with red indicator, tappable dialog with retry/delete/clear all |
| Per-layer success/failure rates | In `ModelRoutingScreen` layer breakdown card — displayed as `count✓/count✗` per layer with overall success percentage |

## Society Policy Override Layer

The ReLoop supports apartment-society-level waste policy deltas on top of the base city plugin.
A society (RWA, apartment complex) can register custom rules that override specific city-level
policies — e.g., a different bin color, collection schedule, or disposal method.

### Architecture

```
User scan (with societyId)
         │
         ▼
LocalPolicyEngine.applyPolicy()
         │  resolves city plugin (e.g. bbmp_bangalore)
         │  applies confidence gating + safety overrides
         ▼
_applySocietyOverrides()
         │  fetches SocietyPolicyOverride from SocietyPolicyService
         │  validates basePluginId matches resolved city plugin
         │  filters overrides by category key
         │  applies each RuleOverride (binColor, collectionFrequency, etc.)
         │  detects conflicts between city and society rules
         ▼
LocalPolicyDecision (with societyId, societyName, societyOverrides, societyConflicts)
         │
         ▼
PolicyProvenanceCard (surfaces society info in result screen)
```

### Key files

| File | Responsibility |
|---|---|
| `lib/services/local_policy_engine.dart` | `applyPolicy()` accepts `societyId` + `societyPolicyService`, calls `_applySocietyOverrides()` |
| `lib/services/society_policy_service.dart` | Firestore-backed CRUD for `society_policies/{societyId}` collection. DI via optional `firebase` param |
| `lib/models/society_policy_override.dart` | `SocietyPolicyOverride`, `RuleOverride`, `RuleOverrideType` enum, `SocietyAwareDecision` |
| `lib/widgets/result_screen/policy_provenance_card.dart` | Surfaces `societyName`, `societyOverrides`, `societyConflicts` in result screen |

### Data model

```dart
SocietyPolicyOverride {
  societyId: String           // Firestore doc ID
  societyName: String         // Display name (e.g. 'Green Habitat')
  basePluginId: String        // Must match city plugin ID (e.g. 'bbmp_bangalore')
  overrides: List<RuleOverride>  // Delta rules
  isVerified: bool            // Community verification status
  locationLat/Lng, address, unitCount  // Optional metadata
}

RuleOverride {
  categoryKey: String         // e.g. 'wet_waste', 'hazardous_waste'
  overrideType: RuleOverrideType  // binColor, collectionFrequency, etc.
  value: String               // New value (e.g. 'Pink Bin')
  description: String?        // Optional explanation
}
```

### Decision fields added to LocalPolicyDecision

| Field | Type | Description |
|---|---|---|
| `societyId` | `String?` | Society ID if override was requested |
| `societyName` | `String?` | Society display name |
| `societyConflictCount` | `int` | Number of conflicts detected |
| `societyConflicts` | `List<String>` | Human-readable conflict descriptions |
| `societyOverrides` | `List<String>` | Descriptions of applied overrides |

### Conflict detection

When a society override is applied, the engine checks for conflicts between the city-level
rule and the society-level override. If both exist for the same category key, the conflict
is recorded but the society override takes precedence. The conflict is surfaced in:
- `LocalPolicyDecision.societyConflicts` (for programmatic access)
- `PolicyProvenanceCard` (for user-facing display)
- `WasteClassification.localRegulations` (for persistence)

### Test infrastructure requirements

The society override layer requires a mock `SocietyPolicyService` for unit testing because
the real service accesses `FirebaseFirestore.instance` in its constructor (even when not used).

**Critical rule**: Any `FakeService` extending `SocietyPolicyService` MUST pass a
`MockFirebaseFirestore` to `super(firestore: ...)`. Without this, the parent constructor
accesses `FirebaseFirestore.instance` which throws `[core/no-app]` in the test environment.

```dart
// Minimal fake — full MockFirebaseFirestore pattern in leaderboard_service_test.dart
class _FakeSocietyPolicyService extends SocietyPolicyService {
  _FakeSocietyPolicyService(this.policyOverride)
      : super(firestore: MockFirebaseFirestore());  // ← REQUIRED
  // ...
}
```

For the full `MockFirebaseFirestore` implementation, see the established pattern in
`test/services/leaderboard_service_test.dart`.

---

## Pending / Future Work

| Item | Status | Notes |
|---|---|---|
| Per-layer success/failure trend lines | Capability exists; needs time-series storage | Current dashboard shows point-in-time counts. Historical trends require a time-binned store (e.g. daily snapshots). |
| Image compression wired into AiService | `ClassificationCacheService` has `_compressImage()`, `_imageBox`, `storeImage()` | No caller passes `imageData:` through `cacheClassification()` yet. `AiService` classifies and caches metadata only — image bytes are not routed through the cache. Wiring this in is a single-line change in the result pipeline. |
| EnhancedCacheService removal | `@Deprecated` in-tree per §7 | Zero production imports confirmed. Delete only with explicit approval. |

---

### Future work

- **GPS-based society auto-detection**: Currently requires explicit `societyId` passthrough.
  Planned: detect society from GPS coordinates using `SocietyPolicyService.findSocietiesNear()`.
  See `docs/exploration/GPS_REGION_SELECTION_UX.md`.
- **Society governance dashboard**: Metrics on override usage, conflict frequency, and
  verification status across registered societies.

---

**Last verified**: 2026-08-01
**Verified against**: `lib/services/ai_service.dart`, `lib/services/providers/backend_proxy_provider.dart`, `lib/services/disposal_instructions_service.dart`, `lib/utils/production_safety_config.dart`, `lib/utils/constants.dart`, `functions/src/index.ts`, `functions/src/classify_image.ts`, `lib/services/classification_pipeline.dart`, `lib/services/layer0_router.dart`, `lib/services/classification_router.dart`, `lib/services/classification_router_guardrails.dart`, `lib/services/confidence_calibration_service.dart`, `lib/services/result_pipeline.dart`, `lib/services/offline_queue_service.dart`, `lib/services/cache_service.dart`, `lib/services/enhanced_cache_service.dart`

## Addendum: runtime service identity and taxonomy source of truth (2026-08-01)

The bootstrapper constructs and initializes application services before
`WasteSegregationApp` is built. `WasteSegregationApp` must override the matching
Riverpod providers with those exact instances. Provider-created defaults remain
valid for isolated tests and lightweight composition, but must not replace the
initialized runtime instances in the application scope.

The recycling taxonomy is a packaged application asset at
`lib/data/recycling_taxonomy.json`. It is the only production taxonomy data
source. Test-only JSON injection remains available through
`fallbackJsonOverride`. If the packaged asset is unavailable, resolution
returns an explicit `taxonomy_unavailable` result and preserves the base
classification rather than silently using stale duplicate data.

### Anything else?

Yes. The provider identity contract and the taxonomy packaging contract are
tested separately because either can regress while the Dart type checker still
passes.

## Addendum: actionable disposal decision presentation (2026-08-02)

The result screen now presents one recommended next step through
`DisposalDecisionCard`. It composes the existing disposal instructions, region,
policy metadata, confidence, taxonomy status, and correction loop. Detailed
steps remain in `DisposalAccordion`; the new card is the decision summary, not
a second disposal engine.

The presentation is conservative by design:

- policy-backed results identify the local rule context;
- results without a local rule pack are labelled as general guidance;
- low-confidence, clarification-needed, and unavailable-taxonomy results ask
  the user to review before acting;
- correction continues through the existing `CorrectionDialog` and
  `AiService.handleUserCorrection` path.
