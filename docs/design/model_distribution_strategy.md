# Model Distribution Strategy — Bundle vs Lazy-Download

**Date**: 2026-05-21
**Status**: DECIDED
**Unblocks**: Phase C real inference engine

---

## Decision

**Bundle MobileNetV3 (~20MB) in the app binary. Lazy-download SmolVLM-500M (~1GB) on first Wi-Fi.**

Two models, two distribution strategies. There is no single answer for all model sizes.

---

## Reasoning

### What gets bundled (MobileNetV3, ~20MB)

- **20MB APK increase** is acceptable for the Indian market where median device storage is 64–128GB.
- Users get instant offline classification on first launch — no download wait, no "model not available" state.
- MobileNetV3 is the smallest viable model (TFLite-native, 50ms inference on mid-tier).
- Bundling avoids the cold-start problem: a user who opens the app in airplane mode on day one gets classification.

### What gets lazy-downloaded (SmolVLM-500M, ~1GB)

- **1GB is too large to bundle** — would push APK past Google Play's 200MB limit and cause install abandonment on mobile data.
- Downloaded on first Wi-Fi connection via existing `ModelDownloadService`.
- User is prompted ("Download on-device AI model for offline classification? 1GB, Wi-Fi recommended.") with a defer option.
- Progress tracked in `model_download_screen.dart` (already exists).

### What never gets downloaded (optional tiers)

- YOLOv8/v11 (50–60MB each): only download if the user enables multi-object detection in premium settings.
- EfficientNet (50MB): superseded by MobileNetV3 for speed or SmolVLM for accuracy. Not bundled unless benchmarks show a gap.

---

## APK Size Budget

| Component | Size |
|---|---|
| App code + assets (current) | ~35MB |
| MobileNetV3 TFLite model | ~20MB |
| **Total bundled APK** | **~55MB** |
| Google Play limit | 200MB |
| Headroom | 145MB |

55MB is acceptable for the target market (median device 64–128GB storage).

---

## UX States

| State | What user sees | Model available? |
|---|---|---|
| First launch (online) | App works normally, cloud classification. Background: "Downloading on-device AI model..." on Wi-Fi. | MobileNetV3 bundled; SmolVLM downloading |
| First launch (offline) | Full offline classification — bundled MobileNetV3 handles common items. | MobileNetV3 yes; SmolVLM no |
| After Wi-Fi download | "On-device AI ready!" notification. SmolVLM now available for harder cases. | Both available |
| Storage low | Prompt to delete SmolVLM, fall back to MobileNetV3 + cloud. | MobileNetV3 always available |

---

## Download Flow

1. **Post-install**: `ModelDownloadService` checks for SmolVLM on first Wi-Fi.
2. **Progress**: `model_download_screen.dart` shows download progress, estimated time, and pause/resume.
3. **Completion**: `OnDeviceVisionService` loads the model; `localClassifierProvider` switches from MobileNetV3 to SmolVLM.
4. **Failure**: Network drops mid-download — resume on next Wi-Fi. Model file validated with SHA-256 on completion.

---

## Related

- `lib/services/model_download_service.dart` — download implementation
- `lib/screens/model_download_screen.dart` — download UI
- `lib/services/local_classifier_service.dart` — interface consumed by pipeline
- `lib/providers/classification_pipeline_providers.dart` — provides available classifier to pipeline
