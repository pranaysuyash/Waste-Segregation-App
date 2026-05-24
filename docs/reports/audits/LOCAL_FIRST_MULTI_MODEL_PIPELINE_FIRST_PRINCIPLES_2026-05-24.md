# Local-First Multi-Model Pipeline First-Principles Audit

Date: 2026-05-24
Scope: repo truth map, local-model readiness, pipeline split, and review harness options
Status: audit note for follow-up agents

## Executive verdict

The repo already has a real local-first control plane, but not a real local-model stack yet.

What is real today:
- Deterministic Layer 0 routing exists and is live.
- A canonical multi-stage classification pipeline exists.
- Preprocessing helpers, segmentation seams, and local-classifier contracts exist.
- Cloud classification and backend proxy paths are real and production-shaped.

What is still scaffolded or placeholder:
- On-device inference is still synthetic / placeholder.
- YOLO, MobileSAM, and object-detection service paths are mostly stubs or no-op fallbacks.
- No checked-in model binaries are present.
- TFLite runtime support is not yet wired as a real production path.

## What the code actually does today

### Real local/offline behavior

- `Layer0Router` performs deterministic barcode lookup and color-histogram routing.
- `ColorHistogramClassifier` is a genuine local computation path, not a mock.
- `OfflineClassificationService` and the capture flow already try local-first behavior before cloud fallback.
- `ClassificationPipeline` is the canonical orchestrator for Layer 0 -> Layer 1 -> cloud.

### Local-model scaffolding

- `LocalClassifier` exists as a clean contract with thresholds and a fake implementation for tests.
- `TFLitePreprocessingHelper` exists and is useful for a future interpreter-backed model.
- `ModelDownloadService` and `VisionModelConfig` provide asset/version seams.
- `SegmentationService` has a canonical interface plus heuristic fallbacks.

### Placeholder or fake local-model pieces

- `OnDeviceVisionService` still returns synthetic output after a delay.
- `ObjectDetectionService` does not provide a real production detection path.
- `YoloSegmentationBackend`, `CloudSegmentationBackend`, and `MobileSamBackend` are not yet shipping implementations.
- The canonical local-classifier provider is still fake or deterministic rather than a real interpreter-backed model.

## Docs truth map

### Aligned docs

- `docs/reference/APP_KNOWLEDGE_BASE.md` accurately describes the current placeholder-heavy on-device state.
- `docs/review/BACKEND_PLATFORM_AND_MONEY_STRATEGY_2026-05-21.md` matches the real hybrid / backend-authoritative direction.
- `docs/review/AI_PIPELINE_TRUTH_MAP_2026-05-21.md` and `docs/review/MULTI_ITEM_SEGMENTATION_UX_V1_2026-05-21.md` are broadly consistent with the live code shape.

### Aspirational or stale docs

- `docs/implementation/ai/ai_powered_image_segmentation.md` is still a target spec rather than a runtime truth document.
- `assets/models/README.md` reads like a download/catalog guide, but the repo still has no checked-in weights.
- `README.md` is still more cloud-centric than the actual local Layer 0 plus scaffolded Layer 1 path.
- A stale backend comment still claims `classifyImage` does not exist, even though it is live.

## Minimal viable task split

### 1. Preprocessing

Owner:
- `EnhancedImageService`
- `TFLitePreprocessingHelper`

What it should do:
- normalize orientation and bytes
- resize and prepare canonical tensors
- keep this contract independent from model selection

### 2. Background removal / segmentation

Owner:
- `SegmentationService`
- `SegmentationBackend`

What it should do:
- own the single segmentation seam
- support heuristic fallback first
- later swap in a real backend without creating a second mask API

### 3. Local classification

Owner:
- `LocalClassifier`
- `ClassificationPipeline`

What it should do:
- own the local-first acceptance contract
- keep one live local implementation at a time
- start with deterministic / lightweight local logic before real interpreter-backed models

### 4. Cloud fallback

Owner:
- backend proxy path
- `classifyImage`
- release-safe cloud routing

What it should do:
- handle ambiguity, safety-sensitive classes, and model failure
- remain the authoritative paid path in release
- avoid hidden duplicate direct-cloud routes

### 5. Policy / disposal reasoning

Owner:
- backend policy path
- region-specific rules corpus

What it should do:
- stay separate from vision classification
- reason about disposal as a text / policy problem, not a vision problem

## Immediate risks

### Duplicate routing risk

There are already multiple orchestrators making routing decisions:
- `ClassificationPipeline`
- `ModelSelectionService`
- `AiService`
- `EnhancedAiApiService`

This is the biggest long-term drift risk in the stack. Do not create a second parallel router.

### Duplicate segmentation truth risk

Multiple files currently define different notions of region / crop / mask:
- `SegmentationService`
- `MobileSamBackend`
- `ObjectDetectionService`
- `SegmentationRouteService`

This is currently mostly harmless because most paths are stubbed, but it will become a real maintenance problem once one path becomes live.

### Fallback masking risk

Several placeholder paths return plausible output or empty arrays, which can make the app look more capable than it is:
- `OnDeviceVisionService`
- `ObjectDetectionService`
- `CloudSegmentationBackend`
- fake local classifier provider

Treat these as scaffolding, not production inference.

## Local-model / CLI harness reality

The machine does have usable CLI harnesses for review experiments:
- `codex` exists and exposes a non-interactive `review` command.
- `claude` exists and supports `--print` plus custom agents.
- `gemini` exists and supports non-interactive prompting.
- `gemini gemma` is a real local-model routing surface with setup/start/stop/status/logs commands for LiteRT-LM.

That means future agents can do blind review passes or local-model experiments without inventing new infrastructure.

## Practical recommendation

1. Keep `ClassificationPipeline` as the single canonical router.
2. Treat deterministic Layer 0 as real product logic.
3. Treat on-device VLM / TFLite / segmentation backends as the next implementation frontier, not as already-shipped capability.
4. Keep cloud fallback authoritative until local evaluation proves the safety and quality thresholds are met.
5. Do not split the pipeline into multiple competing router abstractions.

## Handoff note for future agents

If you are resuming work from this audit, the safest next move is to:
- verify the current routing truth in code,
- choose one canonical local-model implementation path,
- and wire the first real interpreter-backed local classifier behind the existing `LocalClassifier` contract.

Do not start by creating another router, another segmentation seam, or another cloud fallback path.
