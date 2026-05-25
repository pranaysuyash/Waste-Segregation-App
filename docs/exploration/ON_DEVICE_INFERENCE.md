# On-Device Inference Tier — Exploration Doc

**Track**: L1
**Phase**: LATER — Scale + Frontier
**Status**: 🟡 Interface + pipeline in place (Phase A+B). Real model (Phase C) deferred.
**Last Updated**: 2026-05-24
**Frontier dependency**: [F1. Fully On-Device Multi-Model Stack](../EXPLORATION_FRONTIER.md#f1-fully-on-device-multi-model-stack)
**Parent**: [EXPLORATION_TOPICS.md #6](../EXPLORATION_TOPICS.md#6-on-device-inference-)
**Sibling topics**: Model Cascades (#7), Battery / Thermal (#8), Model Lifecycle (A4)

---

## Decision This Unblocks

Whether we can ship a zero-cost, offline-capable classification path for the *common case* (single object, well-lit, not ambiguous) and reserve cloud spend for edge cases.

## De-Risk Question

Can a Flutter-shippable local model handle the common case within battery, quality, and latency budget on a mid-tier Android device?

## Kill Criteria

1. After two serious model evaluations, top-1 accuracy is still > 10–15 points behind cloud Gemini/GPT-4-class on the golden set, and the gap isn't closing.
2. Inference latency on mid-tier devices (Snapdragon 680, 6 GB RAM) is consistently > 3 seconds for the common case.
3. APK size increase from bundled model weights exceeds 30 MB and lazy-download is blocked by storage/connectivity constraints.

---

## What Already Exists

The codebase has a well-architected 3-layer cascade already wired end-to-end:

| Component | File | Status |
|-----------|------|--------|
| `LocalClassifier` abstract interface | `lib/services/local_classifier_service.dart` | ✅ Complete |
| `LocalClassificationResult` with escalation logic | same file | ✅ 5 escalation conditions defined |
| `LocalClassifierThresholds` policy | same file | ✅ Pass (0.75), escalate (0.50), safety (0.90) |
| `ClassificationPipeline` (L0→L1→Cloud) | `lib/services/classification_pipeline.dart` | ✅ Orchestrator complete |
| `OnDeviceVisionService` | `lib/services/on_device_vision_service.dart` | 🔄 Shell — model loading scaffolding present, inference stub |
| `VisionModelConfig` | `lib/models/vision_model_config.dart` | ✅ MobileNetV3, EfficientNet, YOLOv8/YOLOv11, SmolVLM configs |
| `ModelDownloadService` | `lib/services/model_download_service.dart` | ✅ Download + cache infrastructure |
| TFLite preprocessing helper | `lib/services/tflite_preprocessing_helper.dart` | ✅ Image-to-tensor pipeline |
| `classificationLayer` field on `WasteClassification` | model | ✅ Tracks which layer produced the result |
| 36 tests | `test/services/local_classifier_service_test.dart`, etc. | ✅ |

**What's missing**: An actual TFLite model file and the `_runInference()` call that feeds a tensor through it.

---

## Phase Plan

### Phase A ✅ — Interface & Threshold Policy (DONE)

- Abstract `LocalClassifier` interface
- `LocalClassificationResult` with `requiresEscalation` decision logic
- `LocalClassifierThresholds` with default values
- Tests for escalation conditions

### Phase B ✅ — Pipeline Orchestration (DONE)

- `ClassificationPipeline` wiring L0 → L1 → Cloud with fallback
- `classificationLayer` tracking on results
- Offline hint flow (`isOfflineHint` field)
- 36 tests for the pipeline

### Phase C — Real Model Integration (DEFERRED)

This is the work that makes on-device inference real.

**C.1 Model Selection**

| Candidate | Size | Top-1 (ImageNet) | Flutter support | Notes |
|-----------|------|--------------------|-----------------|-------|
| MobileNetV3-Small | ~4 MB | 67.4% | `tflite_flutter` | Best size/quality for classification |
| EfficientNet-Lite0 | ~6 MB | 75.1% | `tflite_flutter` | Better accuracy, still small |
| YOLOv8n (classification) | ~6 MB | ~70% | `tflite_flutter` | Object detection as bonus |
| SmolVLM / Gemma 3n | 300MB–2GB | VLM-quality | `google_generative_ai` on-device | Full VLM, heavy resource use |

Recommendation: start with **EfficientNet-Lite0** for classification-only. It's the best accuracy-per-MB in the TFLite-compatible class. Train it on our waste categories (5 classes: wet, dry, hazardous, medical, non-waste + subcategories).

**C.2 Training Pipeline**

1. Collect golden set from `TrainingDataService` consent-gated pipeline (already built).
2. Label with category + subcategory + bounding box (if detection needed).
3. Fine-tune EfficientNet-Lite0 on TFLite Model Maker or custom Keras → TFLite conversion.
4. Evaluate against held-out golden set. Target: ≥ 80% top-1 on waste categories.
5. Export `.tflite` model with metadata (labels, input shape, quantization).

**C.3 Device Tier Gating**

```dart
enum DeviceModelTier { low, mid, high }

// Gate on-device inference to mid+ tier
// Low tier: skip on-device, go directly to cloud
// Mid tier: EfficientNet-Lite0 (quantized)
// High tier: EfficientNet-Lite0 or larger model
```

**C.4 APK Size Strategy**

- Bundle a quantized (INT8) EfficientNet-Lite0 (~2 MB) as the default.
- Lazy-download larger models (YOLOv8n, SmolVLM) based on device tier and user opt-in.
- `ModelDownloadService` already handles download + cache.

**C.5 Latency Budget**

| Device tier | Target latency | Model |
|-------------|---------------|-------|
| Low | N/A (skip) | — |
| Mid (Snapdragon 680) | < 500ms | EfficientNet-Lite0 INT8 |
| High (Snapdragon 8 Gen 2) | < 200ms | EfficientNet-Lite0 FP16 |

---

## Dependency Graph

```
Eval Harness (X1) ──▶ Golden Set ──▶ Training Data ──▶ Model Fine-Tuning
                                                     │
On-Device Interface (A) ──▶ Pipeline (B) ──▶ Real Model (C) ──▶ Ship
                                                     │
                              Battery/Thermal (#8) ──┘
                              Model Lifecycle (A4) ──┘
```

## Concrete Next Steps

1. **Golden set assembly** — Export 500+ consent-gated classifications via `tools/training_dataset_export.py` with balanced category distribution.
2. **Model fine-tuning** — Train EfficientNet-Lite0 on waste categories using TFLite Model Maker. Target: 80%+ top-1 on held-out set.
3. **Wire inference** — Implement `_runInference()` in `OnDeviceVisionService` using `tflite_flutter` package.
4. **Device tier detection** — Add RAM / NPU detection to gate model selection.
5. **Battery monitoring** — Add thermal/battery check before on-device inference (reference `docs/exploration/` for Battery / Thermal topic).

## Open Questions

- **Subcategory granularity**: Can a single model do both 5-class category AND subcategory (PET, HDPE, food scraps, etc.)? Or does subcategory need a second-stage model?
- **Quantization quality**: How much accuracy does INT8 quantization cost on waste-specific images vs ImageNet?
- **Google Play policy**: Does on-device ML trigger any additional disclosure requirements?
- **iOS parity**: Core ML delegation for TFLite — is it reliable enough for production?

## Downstream Artefacts

- `assets/models/waste_classifier_efficientnet_lite0.tflite` — model file
- `lib/services/on_device_vision_service.dart` — real inference wiring
- `docs/exploration/DEVICE_BUDGET.md` — battery/thermal/memory budget doc
- Updated `VisionModelConfig` with real model metadata
