# Local ML First-Pass Classifier — Plan + Scaffold

**Date**: 2026-05-21
**Status**: SEED → IMPLEMENTED (interface + scaffold live; model binaries deferred)
**Author**: Session review
**Repo**: `/Users/pranay/Projects/LLM/image/waste_seg/waste_segregation_app`

---

## 1. Mission

Prepare the app for on-device local ML **without prematurely training or bundling a model**.

The scaffold enables:

- local classifier to handle obvious wet/dry/hazardous/e-waste
- cloud escalation only for uncertain/hard cases
- offline classification for common items
- testability via fake local classifier
- clean integration with the existing 4-layer cascade architecture

### What this is NOT

- This is not a model training plan.
- This is not a model bundling decision.
- This is not replacing the existing `OnDeviceVisionService` placeholder.
- This is not a production inference engine.

### What this IS

- A clean abstract interface that can be wired now.
- A `LocalClassificationResult` that carries confidence and escalation signal.
- A `FakeLocalClassifier` for tests.
- A confidence threshold policy that determines when to escalate to cloud.
- A model asset versioning convention.
- A router integration point into the existing `AiService` / `ClassificationProvider` contract.

---

## 2. Existing Codebase Context

### Relevant existing artifacts

| File | Role |
|---|---|
| `lib/services/ai_service.dart` | Current classification entry point — cloud-only, no local inference |
| `lib/services/on_device_vision_service.dart` | Placeholder on-device service — `_performInference()` returns synthetic `confidence: 0.0` |
| `lib/services/providers/classification_provider.dart` | Abstract interface for all classifier providers |
| `lib/services/providers/local_vlm_provider.dart` | `ClassificationProvider` impl — throws `UnimplementedError` |
| `lib/models/vision_model_config.dart` | `VisionModelConfig`, `VisionModelType`, `AnalysisMode` enums |
| `lib/services/model_download_service.dart` | Downloads TFLite model files from remote URLs |
| `lib/services/deterministic_classifier.dart` | Does not exist yet (planned Layer 0 in local-first VLM roadmap) |
| `docs/review/LOCAL_FIRST_VLM_AI_ROADMAP_2026-05-21.md` | 4-layer local-first cascade target architecture |
| `docs/review/AI_GATEWAY_ROUTER_IMPLEMENTATION_2026-05-21.md` | Backend gateway + provider interface architecture |
| `lib/models/waste_classification.dart` | Full `WasteClassification` data model |
| `lib/services/providers/ai_provider_response.dart` | Raw provider response wire model |

### Key architectural gap

The existing `OnDeviceVisionService._performInference()` (line 219 of `on_device_vision_service.dart`) is a placeholder that returns confidence `0.0`. The `LocalVlmProvider` throws `UnimplementedError`.

What's missing is:

1. A **clean abstract interface** for local classification that is model-agnostic (TFLite / CoreML / ONNX / VLM).
2. A **result type** that explicitly carries the escalation decision (not just a confidence float).
3. A **confidence threshold policy** that is configurable, category-aware, and safety-gated.
4. A **test fake** that lets the rest of the app be tested without mocking platform channels.
5. A **model version and asset path convention** that enables lazy download and bundle fallback.

---

## 3. Interface Design

### `LocalClassifier` — abstract interface

```dart
/// Performs on-device first-pass waste classification.
///
/// Implementations wrap a concrete inference engine:
/// - TFLite (tflite_flutter)
/// - CoreML (via platform channel)
/// - ONNX Runtime (onnxruntime)
/// - VLM via llama.cpp FFI (SmolVLM, MobileVLM)
///
/// The [classify] method returns a [LocalClassificationResult] that
/// explicitly encodes whether the result should be escalated to cloud.
abstract class LocalClassifier {
  String get modelId;
  String get modelVersion;
  bool get isModelLoaded;

  Future<void> loadModel();
  Future<void> unloadModel();

  Future<LocalClassificationResult> classify({
    required Uint8List imageBytes,
    required String region,
  });
}
```

### `LocalClassificationResult` — value object

```dart
class LocalClassificationResult {
  final String category;          // 'Wet Waste', 'Dry Waste', etc.
  final String? subcategory;      // 'PET Plastic', 'Food Scraps'
  final double confidence;        // 0.0–1.0
  final bool shouldEscalateToCloud;
  final String modelVersion;
  final int processingTimeMs;
  final String? failureReason;

  // Safety-sensitive categories always escalate unless verified.
  static const Set<String> _alwaysEscalateCategories = {
    'Hazardous Waste',
    'Medical Waste',
    'E-Waste',
    'Electronic Waste',
    'Chemical Waste',
    'Sharps',
    'Pharmaceutical Waste',
    'Unknown',
  };

  bool get isSafetySensitive => _alwaysEscalateCategories.contains(category);

  /// Returns true when the result should be escalated regardless of confidence.
  bool get requiresEscalation =>
      shouldEscalateToCloud ||
      isSafetySensitive ||
      confidence < LocalClassifierThresholds.defaultPassThreshold;
}
```

### Design rationale

- **Separate from `ClassificationProvider`**: `ClassificationProvider` is wired for cloud providers with API keys, cost estimates, and Dio-based HTTP. Local inference is fundamentally different — no HTTP, no API keys, no per-call cost tracking the same way.
- **Separate from `WasteClassification`**: The existing model is a 90+ field Hive entity with display-ready data. A local classifier should produce a lightweight result that the router then enriches into a `WasteClassification`.
- **`shouldEscalateToCloud` is explicit**: Rather than relying on callers to interpret raw confidence, the result carries the decision. This makes router logic trivial and audit-trail ready.
- **Category-aware escalation**: `isSafetySensitive` checks are in `LocalClassificationResult` itself so they can't be forgotten by callers.

---

## 4. Confidence Threshold Policy

### Default thresholds

| Threshold | Value | When it applies |
|---|---|---|
| `passThreshold` | 0.75 | Default: local result is accepted at or above this |
| `escalateThreshold` | 0.50 | Below this: force cloud even for non-safety items |
| `safetyOverrideThreshold` | 0.90 | Safety-sensitive items must exceed this to avoid escalation |

### Configurable provider

```dart
class LocalClassifierThresholds {
  LocalClassifierThresholds({
    this.passThreshold = 0.75,
    this.escalateThreshold = 0.50,
    this.safetyOverrideThreshold = 0.90,
  });

  final double passThreshold;
  final double escalateThreshold;
  final double safetyOverrideThreshold;

  static const double defaultPassThreshold = 0.75;
  static const double defaultEscalateThreshold = 0.50;
  static const double defaultSafetyOverrideThreshold = 0.90;
}
```

### Escalation policy

An item escalates to cloud when **any** of:

1. `confidence < escalateThreshold` (model is clearly uncertain)
2. `isSafetySensitive && confidence < safetyOverrideThreshold` (hazardous/medical/e-waste needs high certainty)
3. `shouldEscalateToCloud == true` (model itself flagged uncertainty)
4. Model returned an error / `failureReason` is non-null (infrastructure failure)
5. Model is not loaded / unavailable

An item is accepted locally when **all** of:

1. `confidence >= passThreshold` (for non-safety) OR `confidence >= safetyOverrideThreshold` (for safety)
2. `shouldEscalateToCloud == false`
3. No model error

### Calibration note

These thresholds are **starting hypotheses**. They must be calibrated against the eval harness golden set once real inference is wired. See Section 10 (Open Questions) for the calibration methodology.

---

## 5. Offline Behavior

### Degradation tiers

| Tier | Condition | Behavior |
|---|---|---|
| 1 — Full offline | Model loaded + passes confidence | Local classification, no network |
| 2 — Model available, low confidence | Model loaded but confidence < threshold | Local result with `shouldEscalateToCloud: true`; queued for cloud reanalysis when online |
| 3 — Model not available | First launch, model not yet downloaded | Image captured + queued via `OfflineQueueService`; classification deferred until online |
| 4 — Neither | No model, no network | Capture + queue; show message "Classification queued — will process when online" |

### Offline queue semantics

The existing `OfflineQueueService` (`lib/services/offline_queue_service.dart`) already handles queuing classifications when offline. The local classifier is a **network-independent first pass** that runs even when offline. Items that pass the local confidence threshold are classified locally and never queued for cloud. Items that fail the local threshold are queued for cloud reanalysis.

### UX for offline model download

- First launch: prompt to download the lightweight model (~20MB for MobileNetV3) on Wi-Fi.
- Until downloaded: all classifications go through cloud (or queue if offline).
- After download: local-first for common items.
- Model download screen already exists: `lib/screens/model_download_screen.dart`.

---

## 6. Safety-Sensitive Categories

### Always-escalate categories (unless verified at high confidence)

| Category | Reason |
|---|---|
| Hazardous Waste | Misclassification = environmental harm, health risk |
| Medical Waste | Misclassification = biohazard, infection risk |
| E-Waste / Electronic Waste | Contains heavy metals, requires certified recycling |
| Chemical Waste | Toxic, corrosive, flammable — wrong disposal is dangerous |
| Sharps | Biohazard — need incineration / puncture-proof container |
| Pharmaceutical Waste | Drug disposal rules vary; never guess |
| Unknown / Requires Manual Review | Model has no confident answer |

### Escalation behavior

- Safety-sensitive items NEVER return without escalation unless `confidence >= safetyOverrideThreshold (0.90)`.
- The `LocalClassificationResult.requiresEscalation` getter enforces this automatically.
- Router MUST check this getter; it cannot be overridden by the caller.

---

## 7. Model Asset Path / Versioning

### Conventions

```
assets/models/
  mobilenet_v3_waste_classifier.tflite    # Bundled (small, ~20MB)
  mobilenet_v3_waste_classifier.metadata  # JSON: version, hash, date

Downloaded (lazy):
  {appDocDir}/models/
    smolvlm_waste_classifier.tflite        # ~1GB, downloaded on Wi-Fi
    smolvlm_waste_classifier.metadata.json
    mobilenet_v3_waste_classifier.tflite   # Same file, may be bundled or downloaded
    mobilenet_v3_waste_classifier.metadata.json
```

### Metadata format

```json
{
  "modelId": "mobilenet_v3_waste_v1",
  "modelVersion": "1.0.0",
  "framework": "tflite",
  "inputShape": [1, 224, 224, 3],
  "quantization": "int8",
  "sizeBytes": 20971520,
  "sha256": "a1b2c3d4e5f6...",
  "classes": ["Wet Waste", "Dry Waste", "Hazardous Waste", "Medical Waste", "Non-Waste"],
  "trainedOn": "2026-04-15",
  "minimumAppVersion": "2.1.0"
}
```

### Version check on load

```dart
Future<void> _validateModelVersion(String modelPath) async {
  final metadataFile = File('$modelPath.metadata.json');
  if (!await metadataFile.exists()) {
    throw LocalClassifierException('Model metadata not found');
  }
  final metadata = jsonDecode(await metadataFile.readAsString());
  final required = metadata['minimumAppVersion'] as String;
  if (!_appVersionMeetsMinimum(required)) {
    throw LocalClassifierException(
      'Model requires app version $required, current is ${_currentVersion}',
    );
  }
}
```

---

## 8. Router Integration Point

### Where the local classifier fits in the 4-layer cascade

```
Layer 0: DeterministicClassifier (barcode + histogram)   [future]
    │ fail / no match
    ▼
Layer 1: LocalClassifier (on-device, free, private)      ← THIS SCAFFOLD
    │ confidence < threshold OR safety-sensitive
    ▼
Layer 2: BackendProxyProvider / cloud cheap               [live]
    │ confidence < threshold OR clarificationNeeded
    ▼
Layer 3: Cloud strong model                               [future]
```

### Integration into AiService

The local classifier should NOT be called inside `AiService`. Instead, a new `ClassificationRouter` wraps the layers:

```dart
class ClassificationRouter {
  final LocalClassifier localClassifier;
  final AiService aiService;
  final LocalClassifierThresholds thresholds;

  Future<WasteClassification> classify({
    required Uint8List imageBytes,
    required String region,
  }) async {
    // Layer 1: try local
    if (localClassifier.isModelLoaded) {
      final localResult = await localClassifier.classify(
        imageBytes: imageBytes,
        region: region,
      );
      if (!localResult.requiresEscalation) {
        return _enrichLocalResult(localResult, imageBytes);
      }
    }

    // Layer 2: cloud (via existing AiService)
    return aiService.analyzeWebImage(imageBytes, 'capture', region: region);
  }
}
```

### Connection to ClassificationProvider

The existing `ClassificationProvider` interface continues to serve cloud providers. The `LocalClassifier` is a **separate contract** because:

- It does not use `Dio`, `CancelToken`, or HTTP.
- Its cost is always `0.0` and deterministic.
- Its `analyze()` is synchronous after model load (async for the loading step).
- `estimatedCostPerCall` is meaningless for local inference.

When a real model is wired, the `LocalVlmProvider` can be updated to delegate to `LocalClassifier`, but the primary integration point is through `ClassificationRouter`, not through the provider interface directly.

---

## 9. Test Strategy

### FakeLocalClassifier

```dart
class FakeLocalClassifier implements LocalClassifier {
  FakeLocalClassifier({
    this.modelId = 'fake-model',
    this.modelVersion = '1.0.0-test',
    this.isModelLoaded = true,
    this.stubbedResult,
    this.stubbedShouldEscalate = false,
  });

  @override
  final String modelId;
  @override
  final String modelVersion;
  @override
  bool isModelLoaded;

  LocalClassificationResult? stubbedResult;
  bool stubbedShouldEscalate;

  /// Simulate a model load failure
  bool shouldThrowOnLoad = false;

  @override
  Future<void> loadModel() async {
    if (shouldThrowOnLoad) throw Exception('Model load failed');
    isModelLoaded = true;
  }

  @override
  Future<void> unloadModel() async {
    isModelLoaded = false;
  }

  @override
  Future<LocalClassificationResult> classify({
    required Uint8List imageBytes,
    required String region,
  }) async {
    if (!isModelLoaded) throw LocalClassifierException('Model not loaded');
    return stubbedResult ?? LocalClassificationResult(
      category: 'Dry Waste',
      subcategory: 'Plastic Bottle',
      confidence: 0.92,
      shouldEscalateToCloud: stubbedShouldEscalate,
      modelVersion: modelVersion,
      processingTimeMs: 42,
    );
  }
}
```

### Test scenarios

| Scenario | Fake setup | Expected behavior |
|---|---|---|
| Local classifies with high confidence | `confidence: 0.92`, `shouldEscalate: false` | Result accepted locally, no cloud call |
| Local classifies with low confidence | `confidence: 0.40`, `shouldEscalate: false` | Escalated to cloud |
| Local classifies hazardous | `category: 'Hazardous Waste'`, `confidence: 0.80` | Escalated (below 0.90 safety override) |
| Local classifies hazardous at high confidence | `category: 'Hazardous Waste'`, `confidence: 0.95` | Accepted locally |
| Local model not loaded | `isModelLoaded: false` | Skips local, goes directly to cloud |
| Local model throws | `shouldThrowOnLoad: true` | Gracefully falls through to cloud |
| Local result flags escalation | `shouldEscalateToCloud: true` | Escalated regardless of confidence |
| Offline + model loaded + high confidence | Model loaded, confidence high | Returns local result, no queue |
| Offline + model loaded + low confidence | Model loaded, confidence low | Returns result with `shouldEscalateToCloud: true`, queued |

### Test file

`test/services/local_classifier_service_test.dart`:

- Tests the `FakeLocalClassifier` behavior
- Tests `LocalClassificationResult.requiresEscalation` getter
- Tests thresholds: `passThreshold`, `escalateThreshold`, `safetyOverrideThreshold`
- Tests `ClassificationRouter` integration with fake + cloud

---

## 10. Open Questions

### Model selection

1. **Which model architecture first?** MobileNetV3 (~20MB, fast, TFLite-native) is the lowest-risk starting point. SmolVLM-500M (~1GB) is better for VLM reasoning but requires `llama.cpp` FFI or ONNX conversion. Recommendation: start with MobileNetV3 + waste classification head, graduate to SmolVLM.

2. **Bundle vs lazy-download?** MobileNetV3 can be bundled (~20MB APK increase). SmolVLM must be lazy-downloaded (~1GB). Recommendation: bundle MobileNetV3 for first launch experience, lazy-download SmolVLM for users who opt in.

### Threshold calibration

3. **How to calibrate thresholds without an eval harness?** The current thresholds (0.75 pass, 0.90 safety override) are guesses. Real calibration requires the eval harness golden set (see `docs/review/AI_EVAL_HARNESS_IMPLEMENTATION_PACKET_2026-05-21.md`).

4. **Per-category thresholds?** Certain categories (e.g., "Non-Waste" / reusable items) may need different thresholds. The `LocalClassiferThresholds` should eventually support per-category overrides.

### Platform constraints

5. **TFLite on iOS vs Android**: TFLite on iOS uses Core ML delegation (good NPU support). Android uses NNAPI/GPU delegation (varies by device). The `LocalClassifier` should be able to report delegate type and fall back to CPU if GPU/NPU is unavailable. See `model_selection_service.dart` for device-tier checks.

6. **Web support**: Local inference on web is fundamentally different (WebAssembly / ONNX Runtime Web / TensorFlow.js). The `LocalClassifier` interface should be implementable for web but the initial implementation targets mobile only. Web should continue using cloud classification for now. See `web.dart` / `web_interop.dart` for the web platform boundary.

### VLM integration

7. **How does LocalClassifier relate to LocalVlmProvider?** The `LocalVlmProvider` exists as a `ClassificationProvider` impl (throws `UnimplementedError`). When a real VLM is wired, it could either:
   a. Delegate to `LocalClassifier` (if the model fits the classification-only API).
   b. Remain separate (if the VLM needs free-form prompting beyond classification).
   Recommendation: keep them separate. `LocalClassifier` is for fixed-category classification. `LocalVlmProvider` is for open-ended VLM queries.

---

## 11. Implementation Checklist

### Phase A — Scaffold (this PR)

- [x] `LocalClassifier` abstract interface
- [x] `LocalClassificationResult` with escalation logic
- [x] `LocalClassifierThresholds` policy
- [x] `LocalClassifierException`
- [x] `FakeLocalClassifier` for tests
- [x] Plan document

### Phase B — Wiring

- [ ] `ClassificationRouter` that calls LocalClassifier → AiService
- [ ] Wire router into capture flow (replace direct `AiService` call)
- [ ] Wire offline queue to check local result before enqueuing
- [ ] Add `classificationLayer` field to `WasteClassification` (reference: `LOCAL_FIRST_VLM_AI_ROADMAP.md`)

### Phase C — Real Inference Engine

- [ ] Add `tflite_flutter` to `pubspec.yaml`
- [ ] Train / procure MobileNetV3 waste classification head
- [ ] Implement `TfliteLocalClassifier` extending `LocalClassifier`
- [ ] Wire model download flow (existing `ModelDownloadService`)
- [ ] Calibrate thresholds against eval harness

### Phase D — VLM Layer

- [ ] SmolVLM-500M conversion to TFLite or ONNX
- [ ] Implement VLM-based `LocalClassifier`
- [ ] Model download UI and storage management

---

## 12. Related Documents

| Document | Relationship |
|---|---|
| `docs/review/LOCAL_FIRST_VLM_AI_ROADMAP_2026-05-21.md` | 4-layer cascade architecture; this scaffold implements Layer 1 contract |
| `docs/review/AI_GATEWAY_ROUTER_IMPLEMENTATION_2026-05-21.md` | Provider interface + backend gateway; local classifier feeds into same router |
| `docs/review/AI_PIPELINE_TRUTH_MAP_2026-05-21.md` | Complete AI pipeline truth map |
| `docs/review/AI_EVAL_HARNESS_IMPLEMENTATION_PACKET_2026-05-21.md` | Threshold calibration depends on eval harness |
| `docs/exploration/MULTI_MODEL_AI_STACK.md` | Multi-model AI stack roadmap |
| `docs/EXPLORATION_FRONTIER.md` | F1: Fully On-Device Multi-Model Stack |
| `lib/services/ai_service.dart` | Current cloud classification entry point |
| `lib/services/on_device_vision_service.dart` | Placeholder on-device service (to be refactored into LocalClassifier impl) |
| `lib/services/providers/classification_provider.dart` | Abstract interface for cloud providers |
| `lib/services/providers/local_vlm_provider.dart` | VLM stub that throws UnimplementedError |
| `lib/services/model_download_service.dart` | Model download and version management |
| `lib/models/vision_model_config.dart` | VisionModelType and AnalysisMode enums |

---

*Last updated: 2026-05-21. Owner: Pranay. Status: SEED → IMPLEMENTED.*
