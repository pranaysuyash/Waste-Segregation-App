# Model Lifecycle — Download, Selection, Versioning

**Purpose**: Explore how model weights get to the device, how the right model is selected per device tier, how upgrades roll out, and how old versions sunset.
**Status**: Exploration — `model_download_service.dart` and `model_selection_service.dart` exist; no lifecycle policy
**Last Updated**: 2026-05-25
**Related**: [ON_DEVICE_INFERENCE.md](ON_DEVICE_INFERENCE.md), [CONFIDENCE_THRESHOLD_TUNING.md](CONFIDENCE_THRESHOLD_TUNING.md), [EVAL_HARNESS_AND_GOLDEN_SETS.md](EVAL_HARNESS_AND_GOLDEN_SETS.md)

---

## Problem Statement

On-device inference capability exists (Phase A+B), but the operational machinery to manage model versions across thousands of devices does not. Without explicit lifecycle management:

- A model update requires a full app release
- Old model versions cannot be rolled back after rollout
- There's no way to target models to specific device tiers (NPU vs CPU, RAM tiers)
- Model weights on disk have no integrity verification
- Battery/thermal constraints cannot adapt the model selection per device state

---

## Model Delivery Strategies

| Strategy | Pros | Cons | Use Case |
|----------|------|------|----------|
| **Bundle with app** | Always available, no download delay | Increases app size, requires app store update for new models | Tiny models (< 5MB) |
| **Lazy download on first launch** | Small initial install, can prompt on Wi-Fi | First scan offline won't work, download UX friction | Small models (5-50MB) |
| **Progressive download** | Download base model first, fine-tune later | Complex version reconciliation | Medium models (50-200MB) |
| **Remote config gated** | Controlled rollout, kill switch | Requires remote config infrastructure | All models (recommended) |

---

## Device Tier Selection

The app should select the right model based on device capability:

| Tier | Criteria | Model Size | Capabilities |
|------|----------|------------|-------------|
| **Flagship** | NPU present, >= 8GB RAM | Full (200MB+) | Full classification + detection |
| **Mid-range** | No NPU, >= 4GB RAM | Medium (50-100MB) | Classification only |
| **Budget** | Low RAM, older OS | Small (5-20MB) | Limited categories, lower accuracy |
| **Fallback** | No on-device model downloaded | None | Cloud-only classification |

**Selection inputs**: Device model, OS version, RAM, NPU presence, battery level, thermal state, available storage.

---

## Versioning & Rollback

| Capability | Implementation |
|------------|---------------|
| **Model version registry** | Firestore doc per model version: `{version, url, sha256, min_tier, max_tier, valid_from, valid_to}` |
| **Model selection** | Select latest `valid` model matching device tier |
| **Integrity verification** | SHA-256 hash check before loading |
| **Rollback** | Update `valid_to` on current version, previous version becomes active |
| **A/B model testing** | Remote config flag routes X% of devices to experimental model |
| **Staged rollout** | Increment percentage from 1% → 10% → 50% → 100% with monitoring gates |

---

## Battery & Thermal Adaptation

The lifecycle system should adapt to device state:

| State | Action |
|-------|--------|
| Battery low | Downgrade to smaller model; reduce inference frequency |
| Charging + Wi-Fi | Download model updates, run batch background processing |
| Overheating | Fall back to cloud-only inference; let on-device cool down |
| Storage critical | Delete oldest unused model version |

---

## Key Decisions Needed

1. **Download timing**: Prompt user on first launch, or auto-download on Wi-Fi?
2. **Model size limit**: What's the max acceptable download size for user-perceived friction?
3. **Device tier detection**: Manual user selection vs automatic detection vs both?
4. **Model storage policy**: Keep N latest versions, or only the active one?

---

## Open Questions

- Should model downloads be gated behind premium? (Model = feature advantage)
- How do we handle model version conflicts in multi-device family accounts?
- What's the rollback SLA when a model update degrades accuracy?
- How do we test new models against eval sets before rollout without user impact?

---

## Next Steps

1. Define version schema in Firestore
2. Implement device tier detection service
3. Build staged rollout controller (Remote Config + monitoring gates)
4. Add SHA-256 verification to model loading
5. Implement battery/thermal adaptation hooks
