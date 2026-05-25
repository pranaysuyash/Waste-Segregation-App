# Safety-Critical Autonomy Rules

**Status**: Exploration doc — open research
**Last Updated**: 2026-05-25
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) (P0 #5)
**Related**: [CONFIDENCE_THRESHOLD_TUNING.md](CONFIDENCE_THRESHOLD_TUNING.md), [BACKEND_CLASSIFICATION_PROXY.md](BACKEND_CLASSIFICATION_PROXY.md), [TRUTHFUL_AI_EVAL_GATES.md](TRUTHFUL_AI_EVAL_GATES.md), [MULTI_MODEL_AI_ROUTING.md](MULTI_MODEL_AI_ROUTING.md)

---

## Why This Matters

In safety-critical AI systems for waste classification, misclassification can lead to fires, toxic leaks, worker injury, and legal penalties. Certain waste categories must **never** be resolved by weak local inference until measured fail rates justify it.

The core principle: **if the system is unsure, the default action must be the safest possible state** — treat as hazardous until proven otherwise.

---

## Research Summary

### Categories Requiring Deterministic Safety Rules

AI should never be the sole decision-maker for these waste streams:

| Category | Risk | Examples | Current Handling |
|----------|------|---------|-----------------|
| **Batteries** | Fire during processing/shredding | Li-ion, NiMH, lead-acid, button cells | Treat as hazardous, require dropoff |
| **Medical/Biohazardous** | Infection, disease transmission | Syringes, bandages with blood, expired meds | Must-never-compost default |
| **Sharps** | Puncture-related transmission | Needles, scalpel blades, lancets | Immediate hazard handling |
| **Chemicals** | Corrosive, flammable, toxic | Paint thinners, pesticides, cleaning agents | Special collection required |
| **E-waste (selected)** | Heavy metals, mercury | CFL bulbs, thermostats, CRTs, PCB-containing | WEEE collection path |
| **Aerosols/Pressurized** | Explosion during compaction | Spray cans, gas canisters, propane tanks | Must-not-compact/shred |
| **Asbestos/Construction** | Carcinogenic fibers | Old insulation, tiles, brake pads | Professional disposal only |

### The "Conservative Logic" Architecture

For safety-critical items, the routing policy must be **unidirectional and deterministic**:

1. **Forbidden List**: Items the AI is forbidden to classify autonomously under any circumstances
2. **Mandatory Escalation**: Any confidence level below a safety-critical threshold triggers cloud-layer escalation
3. **Override Confirmation**: Even cloud-layer classification for safety-critical items must display a clear warning to the user

### Confidence Threshold Policy

Standard multi-tier confidence protocol for safety-critical systems:

| Tier | Confidence | Action | Example |
|------|-----------|--------|---------|
| **High** | >99.9% | Proceed with normal handling | Clear plastic bottle, 95% confidence |
| **Medium** | 90-99.9% | Flag for verification, demote confidence | Maybe-battery, could-be-medical |
| **Low** | <90% | Default to hazardous treatment | Unknown shiny object near hazardous zone |

**For safety-critical categories**:
- Any confidence < 0.95 for a safety-critical label → force escalate to cloud (Layer 3)
- Any confidence < 0.80 for safety-critical → force escalate to manual review
- If provider disagreement on safety-critical → force escalate to manual review

### Regulatory Context

While there's no blanket "AI standard" for waste classification, existing regulations create binding constraints:

- **Resource Conservation and Recovery Act (RCRA)** — waste characterization must be based on "generator knowledge" or analytical testing. AI alone does not satisfy this.
- **Country-specific regulations** — India's E-Waste Rules 2022, Hazardous Waste Rules 2016 require documented handling procedures
- **EU regulations** — Waste Framework Directive requires traceable disposal path for hazardous categories

**Legal implication**: If AI misclassifies hazardous waste as general waste and it causes harm, liability falls on the app/developer, not the AI provider.

---

## Design Specification

### Safety Rule Set

```dart
class SafetyCriticalRules {
  // Categories that MUST never be resolved by local inference
  static const alwaysEscalateToCloud = [
    'battery',
    'medical_waste',
    'sharp',
    'chemical_hazardous',
    'aerosol',
    'asbestos',
  ];
  
  // Categories that require cloud confidence > 0.95
  static const safetyCriticalCategories = [
    'e_waste',
    'hazardous_waste',
    'flammable',
    'corrosive',
    'reactive',
    'toxic',
  ];
  
  // Minimum confidence thresholds per tier
  static const cloudMinConfidence = 0.95;
  static const localMinConfidence = 0.90; // never used for safety-critical
  static const manualReviewThreshold = 0.80; // for safety-critical items
}
```

### Routing Logic (in `ClassificationRouter`)

```
1. If predicted category ∈ alwaysEscalateToCloud → route directly to Layer 3 (cloud)
2. If predicted category ∈ safetyCriticalCategories:
   a. If confidence < manualReviewThreshold → flag for manual review
   b. If confidence < cloudMinConfidence → escalate to Layer 3
   c. If provider disagreement → escalate to manual review
3. If predicted category ∉ safetyCritical and ∉ alwaysEscalateToCloud:
   a. Standard cascade routing (L0 → L1 → L2 → L3)
   b. Standard confidence thresholds apply
```

### UX for Safety-Critical Results

For safety-critical classifications, the result screen must include:

- **Visual warning icon** (not subtle — should be visible at a glance)
- **Trust disclaimer**: "This appears to be [battery]. Please verify before disposal."
- **Call-to-action**: "Find your nearest battery dropoff point" (not "dispose in general waste")
- **User confirmation**: Require user to tap "I understand" before proceeding to disposal info

### Safety Audit Trail

Every safety-critical classification must record:
- Predicted category and confidence per provider
- Which routing tier handled it
- Whether escalation was attempted / succeeded
- User confirmation (if any)
- Timestamp, location, user ID (for incident response)

---

## Open Questions

1. Should the safety rule set be server-driven (Remote Config) or hardcoded? Server-driven allows emergency updates without app release.
2. Should we maintain a "safety override" capability for expert users (e.g., waste management professionals)?
3. How do we handle mixed-material items where one component is safety-critical? (E.g., a toy with a battery inside)
4. Should safety-critical results require network connectivity to display? Or can they be cached with an expiry?
5. How do we evolve the forbidden list as the local classifier improves?

---

## Current Code Anchors

- `lib/services/local_policy_engine.dart` — `safetyOverrideAlways` check type already exists
- `lib/services/classification_pipeline.dart` — current cascade, needs safety routing integration
- `lib/services/local_classifier_service.dart` — `LocalClassificationResult.requiresEscalation` has 5 conditions

---

## What Could Kill This

- Too restrictive → users bypass warnings → safety is worse than a more usable but less safe system
- False positive for safety labels → users stop trusting warnings
- Legal liability from misclassification despite precautions
- Regulatory requirements change faster than the app can update

---

## Next Steps

1. Define the definitive safety-critical category list and confidence thresholds
2. Implement safety routing logic in `ClassificationRouter` (evaluate vs hand-coded rule set)
3. Add safety-critical visual treatment to result screen
4. Implement safety audit trail to Firestore
5. Test with real hazardous waste images to measure false positive/negative rates
6. Set up Remote Config for emergency rule updates
