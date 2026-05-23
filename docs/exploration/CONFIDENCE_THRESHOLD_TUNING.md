# Confidence Threshold Tuning

**Date**: 2026-05-23
**Status**: Exploration — calibration methodology and threshold strategy
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) G3
**Decision this unblocks**: Trustworthy routing decisions, cost optimization, accuracy guarantees
**Kill criteria**: If model self-reported confidence perfectly correlates with accuracy (it doesn't), calibration is unnecessary

---

## 1. Current State

### Confidence fields

| Field | Location | Type | Default |
|-------|----------|------|---------|
| `WasteClassification.confidence` | `waste_classification.dart:377` | `double?` | Model-reported |
| `VisionModelConfig.confidenceThreshold` | `vision_model_config.dart:62` | `double` | 0.7 |
| `LocalClassificationResult.confidence` | `local_classifier_service.dart` | `double` | Layer 0 computed |

### Problem: Uncalibrated confidence

Model-reported confidence (e.g., `0.87`) does NOT reliably mean the result is correct 87% of the time. It's an uncalibrated signal that varies by:
- Provider (OpenAI vs Gemini report confidence differently)
- Category (hazardous items tend to have inflated confidence)
- Image quality (blurry images sometimes get high confidence)

### Routing now uses calibrated confidence (2026-05-23)

`ClassificationRouter` (`lib/services/classification_router.dart`) implements 4 strategies with confidence-based escalation. `ClassificationPipeline.classify()` calibrates cloud confidence via `ConfidenceCalibrationService` and logs routing decisions. Layer 0 confidence handling for accept/hint/reject remains in the pipeline's local path.

---

## 2. Calibration Methodology

### Method 1: Empirical binning (recommended for phase 1)

1. Run eval harness on golden set with each provider
2. Bin predictions by model-reported confidence (0.0–0.1, 0.1–0.2, ..., 0.9–1.0)
3. Calculate actual accuracy in each bin
4. Build calibration lookup table

```
Model says 0.85 → Lookup table → Actual accuracy ~0.72
Model says 0.95 → Lookup table → Actual accuracy ~0.89
```

### Method 2: Platt scaling (phase 2)

Fit a logistic regression to map model confidence → calibrated probability:
```
calibrated = sigmoid(a * raw_confidence + b)
```
Parameters `a` and `b` learned from held-out eval data.

### Method 3: Per-category calibration

Different categories have different calibration curves:
```
Plastic bottles at 0.80 confidence → actual 0.85
Medical waste at 0.80 confidence → actual 0.60
```
Maintain separate calibration parameters per category.

---

## 3. Proposed Threshold Table

### Starting thresholds (hypotheses — need calibration data)

| Layer | Pass Threshold | Escalate Below | Override |
|-------|---------------|----------------|----------|
| Layer 0 | ≥ 0.90 | < 0.90 → Layer 1 | Deterministic (no override needed) |
| Layer 1 | ≥ 0.75 | < 0.75 → Layer 2 | Hazardous/Medical → Layer 3 regardless |
| Layer 2 | ≥ 0.60 | < 0.60 → Layer 3 | Safety-critical → Layer 3 |
| Layer 3 | Accept all | N/A (no further escalation) | None |

### Per-category overrides

| Category | Minimum Layer | Minimum Confidence | Rationale |
|----------|--------------|-------------------|-----------|
| Hazardous Waste | Layer 3 | 0.80 | Safety-critical — must be correct |
| Medical Waste | Layer 3 | 0.80 | Safety-critical — must be correct |
| E-Waste | Layer 2 | 0.70 | Often misclassified, moderate safety |
| Wet Waste | Layer 0 | 0.90 | Usually easy to identify |
| Dry Waste | Layer 1 | 0.75 | Moderate difficulty |
| Non-Waste | Layer 1 | 0.75 | Requires context understanding |

---

## 4. Confidence-Aware Routing Decision

```
Input: classification result with raw confidence
  1. Apply calibration: raw → calibrated
  2. Check category override: is this category safety-critical?
     → Yes: escalate to minimum layer regardless of confidence
     → No: proceed with confidence-based routing
  3. Compare calibrated confidence against threshold for current layer
     → Above threshold: accept result
     → Below threshold: escalate to next layer
  4. Log routing decision for eval harness review
```

---

## 5. Threshold Drift Monitoring

### Problem

Thresholds calibrated today may be wrong tomorrow:
- Provider updates models without notice
- User demographics shift (different waste patterns in new regions)
- Seasonal variation (packaging changes during holidays)

### Solution

Weekly automated eval harness run:
1. Run golden set against all providers
2. Compare calibration curves against baseline
3. If any bin drifts > 5% from expected accuracy → alert
4. If safety-critical bins drift → auto-tighten thresholds (conservative)

### Telemetry

Record per-classification:
- Raw confidence
- Calibrated confidence
- Routing decision (accepted/escalated)
- User correction (if any)
- Final accuracy (ground truth from corrections)

---

## 6. Implementation Path

1. **Build calibration data**: Run eval harness, collect confidence/accuracy pairs — *pending (eval harness exists, needs continuous runs)*
2. **Create calibration service** ✅: `ConfidenceCalibrationService` (`lib/services/confidence_calibration_service.dart`) — empirical binning, per-category overrides, safety overrides
3. **Wire into pipeline** ✅: `ClassificationPipeline.classify()` now calibrates cloud confidence, logs routing decisions via `ClassificationRouter`
4. **Add per-category overrides** ✅: Hazardous→L3, Medical→L3, E-Waste→L2 built into calibration service and router
5. **Build drift monitoring**: Weekly eval comparison + alerting — *pending*
6. **Tune thresholds**: A/B test threshold values via Remote Config — *pending*

---

## 7. Related

- [Eval Harness & Golden Sets](EVAL_HARNESS_AND_GOLDEN_SETS.md) — calibration data source
- [Multi-Model AI Routing](MULTI_MODEL_AI_ROUTING.md) — routing decisions using confidence
- [Classification Confidence](../EXPLORATION_TOPICS.md#2-classification-confidence--uncertainty-) — parent entry
- `lib/models/vision_model_config.dart` — current threshold configuration
- `lib/services/classification_pipeline.dart` — Layer 0 confidence handling
