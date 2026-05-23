# Multi-Model AI Routing

**Date**: 2026-05-23
**Status**: Exploration — routing architecture and strategy
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) entry 1
**Decision this unblocks**: Cheaper, faster, more correct classifications; path to on-device for the common case
**Kill criteria**: If a single cloud provider achieves < $0.0001/classification with < 1s latency and > 95% accuracy, routing complexity is unnecessary

---

## 1. Current State

### Classification path (monolithic)

```
Client → AiService._analyzeWithOpenAI(gpt-4.1-nano)
  → Fallback: _analyzeWithOpenAI(gpt-4o-mini)
  → Fallback: _analyzeWithOpenAI(gpt-4.1-mini)
  → Fallback: _analyzeWithGemini(gemini-2.0-flash)
```

Routing is **error-based only** — fallback triggers on `invalidImageTooLarge` or `providerUnavailable`. No confidence-based routing. No cost-based routing. No image-complexity-based routing.

### What exists

| Component | Location | Status |
|-----------|----------|--------|
| `ClassificationPipeline` | `lib/services/classification_pipeline.dart` | Layer 0 → L1 → Cloud cascade |
| `LocalClassifierService` | `lib/services/local_classifier_service.dart` | Layer 0 deterministic (barcode + color histogram) |
| `OnDeviceVisionService` | `lib/services/on_device_vision_service.dart` | Placeholder (confidence: 0.0) |
| `AiService` | `lib/services/ai_service.dart` | OpenAI primary + Gemini fallback |
| `BackendProxyProvider` | `lib/services/providers/backend_proxy_provider.dart` | `classifyImage` proxy |
| `classificationLayer` field | `lib/models/waste_classification.dart` | Tracks which layer classified |

### What's built (2026-05-23)

| Component | Location | Status |
|-----------|----------|--------|
| `ClassificationRouter` | `lib/services/classification_router.dart` | 4 strategies (costFirst, qualityFirst, latencyFirst, balanced), safety overrides, escalation logic |
| `ConfidenceCalibrationService` | `lib/services/confidence_calibration_service.dart` | Per-category calibration bins, safety overrides (Hazardous→L3, Medical→L3, E-Waste→L2) |
| Pipeline wiring | `lib/services/classification_pipeline.dart` | Router + calibration wired into `classify()` — cloud results get calibrated confidence + routing decision logging |
| Tests | 8 router tests + 9 calibration tests | 17 tests covering strategies, overrides, thresholds, edge cases |

### What's still missing

- No image-complexity analysis before routing
- No A/B testing of routing strategies
- No Remote Config integration for per-user-tier strategy selection

---

## 2. Target Architecture: 4-Layer Cascade

```
Layer 0: Deterministic (barcode + color histogram)     → ~30% of cases, $0 cost, ~50ms
Layer 1: On-device VLM (SmolVLM-500m / MobileVLM)     → ~30% of remaining, $0 cost, ~800ms
Layer 2: Cloud cheap (gemini-2.0-flash / gpt-4.1-nano) → ~25% of remaining, $0.0003, ~1.5s
Layer 3: Cloud strong (gpt-4o / gemini-pro)             → ~10% of remaining, $0.005, ~3s
Layer 4: Disposal reasoning (generateDisposal)          → Text-only, always cloud
```

### Routing policy

```
Input image
  → Layer 0: confidence ≥ 0.90? → Accept (no further processing)
  → Layer 0: confidence < 0.90? → Escalate to Layer 1
    → Layer 1: confidence ≥ 0.75? → Accept
    → Layer 1: confidence < 0.75? → Escalate to Layer 2
      → Layer 2: confidence ≥ 0.60? → Accept
      → Layer 2: confidence < 0.60? → Escalate to Layer 3
        → Layer 3: Always accept (no further escalation)
  → Safety override: Hazardous/Medical always escalates to Layer 3
  → Privacy mode: User opts for local-only → Layer 0 + Layer 1 only, refuse escalation
```

### Cost impact at 1M MAU (100 classifications/month average)

| Layer | % of traffic | Cost/month |
|-------|-------------|------------|
| Layer 0 | 30% | $0 |
| Layer 1 | 30% | $0 |
| Layer 2 | 28% | $8,400 |
| Layer 3 | 12% | $6,000 |
| **Total** | | **$14,400** |

vs. current all-cloud: ~$35,000/month. **59% cost reduction.**

---

## 3. Provider Comparison

| Provider | Model | Accuracy (golden set) | Latency (p50) | Cost/1K tokens | Safety |
|----------|-------|----------------------|----------------|-----------------|--------|
| OpenAI | gpt-4.1-nano | 91.7% | 1.8s | $0.15/$0.60 | Good |
| OpenAI | gpt-4o-mini | 89.3% | 1.5s | $0.15/$0.60 | Good |
| OpenAI | gpt-4.1-mini | 93.2% | 2.5s | $0.30/$1.20 | Good |
| Gemini | gemini-2.0-flash | 88.5% | 1.2s | $0.075/$0.30 | Good |
| Gemini | gemini-2.5-pro | 95.1% | 3.5s | $1.25/$10.00 | Good |
| Local | SmolVLM-500m | Unknown (needs eval) | 800ms | $0 | Unknown |
| Local | deterministic | 85% (known items) | 50ms | $0 | Deterministic |

---

## 4. Routing Strategy Options

### Strategy A: Cost-first

Minimize AI cost while maintaining minimum accuracy threshold (90%).

```
Layer 0 → Layer 1 → gemini-flash → gpt-4.1-nano → gpt-4.1-mini
```

### Strategy B: Quality-first

Maximize accuracy regardless of cost (premium tier).

```
Layer 0 → gpt-4.1-mini → gemini-pro (fallback)
```

### Strategy C: Latency-first

Minimize time-to-result (instant mode).

```
Layer 0 → Layer 1 → gemini-flash (fastest cloud)
```

### Recommended: Adaptive routing

Use Remote Config to select strategy per user tier:

| Tier | Strategy | Rationale |
|------|----------|-----------|
| Anonymous | Cost-first | Minimize cost for free users |
| Free registered | Cost-first | Same, with higher caps |
| Premium | Quality-first | They pay for accuracy |
| Enterprise | Configurable | Custom routing per contract |

---

## 5. Implementation Path

### Phase 1: Routing controller ✅ Done

`ClassificationRouter` service (`lib/services/classification_router.dart`):
1. Evaluates barcode presence and metadata for initial routing
2. Selects routing strategy (costFirst / qualityFirst / latencyFirst / balanced)
3. Manages escalation between layers with configurable thresholds
4. Records routing decisions via `logDecision()`
5. Safety overrides: E-Waste → Layer 2, Hazardous/Medical → Layer 3

`ConfidenceCalibrationService` (`lib/services/confidence_calibration_service.dart`):
1. Per-category calibration bins with empirical accuracy tracking
2. `calibrate()` maps raw confidence → calibrated confidence
3. `decide()` returns accept/escalate/hint per layer thresholds
4. Safety category overrides with mandatory minimum layers

Pipeline wiring (`lib/services/classification_pipeline.dart`):
- `classify()` now calibrates cloud confidence and logs routing decisions
- Cloud results include `calibratedConfidence` and `modelSelectionStrategy`

### Phase 2: Confidence-based escalation ✅ Done

Wired into `ClassificationPipeline.classify()`:
- Layer 0 pass: ≥ 0.90
- Layer 1 pass: ≥ 0.75
- Layer 2 pass: ≥ 0.60
- Safety override: Hazardous/Medical → always Layer 3

### Phase 3: Adaptive routing (next)

- A/B test routing strategies via Remote Config
- Measure per-strategy accuracy, cost, latency
- Auto-select best strategy per user tier

---

## 6. Related

- [Eval Harness & Golden Sets](EVAL_HARNESS_AND_GOLDEN_SETS.md) — measurement foundation
- [Confidence Threshold Tuning](CONFIDENCE_THRESHOLD_TUNING.md) — calibration methodology
- [On-Device Inference](../EXPLORATION_TOPICS.md#6-on-device-inference-) — Layer 1 implementation
- [AI Cost Telemetry](AI_COST_TELEMETRY_AND_GUARDRAILS.md) — cost tracking
- `docs/review/LOCAL_FIRST_VLM_AI_ROADMAP_2026-05-21.md` — 4-layer cascade architecture
