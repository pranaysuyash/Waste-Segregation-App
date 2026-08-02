# ADR-005: Multi-Layer Classification Pipeline

* Status: accepted
* Deciders: Development Team
* Date: 2026-05-25

Technical Story: The classification pipeline must progress from free/deterministic methods up to expensive cloud models only when necessary. How should we route images through classification layers while tracking provenance and controlling costs?

## Context and Problem Statement

Every waste classification requires routing an image through the appropriate classification method. The key tensions are:

1. **Cost control**: Cloud API calls cost money — avoid them when free methods suffice
2. **Quality**: Cloud models are more accurate than on-device models
3. **Latency**: On-device classification is faster than cloud
4. **Offline support**: Users may not have network connectivity
5. **Auditability**: Every classification must record which model/method produced it

The current implementation uses a 4-layer routing architecture that progresses from free/deterministic to expensive/cloud.

## Decision Drivers

* **Cost efficiency**: Use free methods (Layer 0) whenever possible before escalating to paid cloud APIs
* **Progressive escalation**: Only move to higher layers when lower layers cannot produce a confident result
* **Provenance tracking**: Every classification must record which layer resolved it
* **Graceful degradation**: If higher layers fail, fall back to lower layers
* **Offline resilience**: Layer 0 and Layer 1 work without network

## Considered Options

* **Option 1**: Direct cloud-only classification (simple, expensive)
* **Option 2**: Two-layer system (on-device + cloud)
* **Option 3**: Multi-layer routing with deterministic escalation
* **Option 4**: ML-based routing (learn which layer to use)

## Decision Outcome

Chosen option: **Option 3 — Multi-layer routing with deterministic escalation.**

The pipeline progresses through 4 layers:
- Layer 0: Deterministic (barcode lookup, color histogram) — free, always available
- Layer 1: On-device ML (TFLite) — free, requires model download
- Layer 2: Cloud cheap (GPT-4.1-nano, Gemini flash) — paid, canonical production path
- Layer 3: Cloud strong (GPT-4o, Gemini pro) — paid, implicit fallback

### Positive Convironments

* **Cost efficiency**: Most classifications resolve at Layer 0 (barcode) or Layer 2 (cheap cloud)
* **Provenance**: Every WasteClassification records `classificationLayer`, `analysisSource`, `modelRoute`
* **Offline resilience**: Layer 0 works without network; queued items process when connectivity returns
* **Testability**: Each layer can be tested independently with mocked dependencies

### Negative Consequences

* **Complexity**: 4-layer routing adds decision logic and provenance tracking overhead
* **Layer 1 not deployed**: On-device ML is wired but returns null (FakeLocalClassifier)
* **Routing ambiguity**: Layer 3 has no dedicated route — it's implicit in API fallback chain

## Implementation Structure

### Layer 0 — Deterministic

```
Image → ImageQualityGate → Layer0Router
  ├── BarcodeLookupService (Open Food Facts API)
  └── ColorHistogramClassifier (HSV-based clustering)

Layer0Decision: accept | hint | escalate
```

### Layer 1 — On-Device ML (Not Deployed)

```
ObjectDetectionService + OnDeviceVisionService
  → LocalClassifierService (FakeLocalClassifier in production)
  → Returns null → escalates to cloud
```

### Layer 2 — Cloud Cheap (Production Default)

```
ClassificationPipeline → ClassificationRouter
  → EnhancedAiApiService → classifyImage Firebase callable
  → OpenAI GPT-4.1-nano primary → Gemini flash fallback
```

### Layer 3 — Cloud Strong (Implicit)

Reached when Layer 2 produces calibrated confidence < 0.50 or a policy pack requires stronger analysis. Currently implicit in the API fallback chain — no dedicated route exists yet.

### Provenance Fields

Every WasteClassification carries:
- `classificationLayer`: Which layer resolved it (runtime-only, not persisted to Hive)
- `analysisSource`: `cloud_primary`, `local_experimental`, or `local_failed_fallback_cloud`
- `modelRoute`: Which model actually handled the request
- `modelSelectionStrategy`: How the model was selected
- `rawConfidence`: Model's self-reported confidence
- `calibratedConfidence`: Category-level calibrated confidence
- `routeLatencyMs`: Time taken for routing decision
- `routeCostUsd`: Cost of the API call

## Links

* Implementation: `lib/services/classification_pipeline.dart`
* Router: `lib/services/classification_router.dart`
* Layer 0: `lib/services/layer0_router.dart`
* Backend proxy: `lib/services/backend_proxy_provider.dart`
* Tests: `test/services/classification_pipeline_test.dart`
* Architecture doc: `docs/architecture/CURRENT_AI_ARCHITECTURE.md`
* Refined by: [CONTEXT.md](../../CONTEXT.md) Classification Pipeline section
