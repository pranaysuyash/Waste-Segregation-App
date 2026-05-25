# Continuous Learning Loop — Exploration Doc

**Track**: L4
**Phase**: LATER — Scale + Frontier
**Status**: 🟢 Exploration
**Last Updated**: 2026-05-24
**Frontier dependency**: [F3. Continuous Learning Loop from User Corrections](../EXPLORATION_FRONTIER.md#f3-continuous-learning-loop-from-user-corrections)
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) (continuous learning section)
**Sibling topics**: Eval Harness (#5), Classification Confidence (#2), History Schema (#12)

---

## Decision This Unblocks

Whether user corrections can be turned into a defensible, ethical, weekly improvement cycle that makes the AI measurably better over time — turning the app's usage data into a compounding accuracy advantage.

## De-Risk Question

Can user corrections be collected cleanly (distinguishable from noise), processed ethically (consent + privacy), and turned into measurable AI improvements (eval harness validation) within a sustainable weekly cadence?

## Kill Criteria

1. Correction signal is too noisy / sparse to be useful after a representative sample (e.g., > 50% of corrections are "user changed their mind" vs "AI was wrong").
2. Privacy review concludes we can't ethically use this data without consent burden that kills the loop.
3. Weekly eval harness runs show no measurable accuracy improvement after 8 weeks of correction ingestion.

---

## What Already Exists

The codebase has a **substantial training data pipeline** already built:

| Component | File | Status |
|-----------|------|--------|
| `TrainingDataService` (consent-gated pipeline) | `lib/services/training_data_service.dart` | ✅ Complete |
| `TrainingConsent` model | `lib/models/user_profile.dart` | ✅ With policy versioning |
| `TrainingReviewCandidate` + review queue | same service | ✅ Enqueue + review + eligibility |
| `ClassificationFeedback` model | `lib/models/classification_feedback.dart` | ✅ Correction + reason capture |
| `CorrectionDialog` widget | `lib/widgets/correction_dialog.dart` | ✅ User-facing correction UI |
| Cloud Functions for training data | `functions/src/training_data.ts` | ✅ `enqueueTrainingCandidate`, `attachTrainingLabelFeedback` |
| Dataset export tool | `tools/training_dataset_export.py` | ✅ Export to standard ML format |
| `TrainingDataService` tests | `test/services/training_data_service_test.dart` | ✅ |
| Eval harness | `eval/` directory | ✅ Flywheel built |
| Confidence calibration | `lib/services/confidence_calibration_service.dart` | ✅ Calibration bins |

**What's missing**: The *closing loop* — from collected corrections → model/prompt evaluation → measured improvement → deployment.

---

## The Learning Loop

```
┌──────────────────────────────────────────────────────────┐
│                                                          │
│  1. User classifies item                                  │
│       ↓                                                   │
│  2. User corrects (or confirms) via CorrectionDialog      │
│       ↓                                                   │
│  3. TrainingDataService captures:                         │
│     - Original prediction (category, confidence, model)   │
│     - User correction (new category, reason)              │
│     - Image metadata (resolution, lighting, angle)        │
│     - Consent status                                      │
│       ↓                                                   │
│  4. Cloud Function enqueues to review queue               │
│       ↓                                                   │
│  5. Human reviewer validates (is correction legit?)        │
│       ↓                                                   │
│  6. Validated corrections feed:                            │
│     a. Golden set expansion (new hard examples)            │
│     b. Prompt improvement (systematic error patterns)      │
│     c. Confidence calibration (per-category drift)         │
│     d. On-device model retraining (Phase C, L1)            │
│       ↓                                                   │
│  7. Eval harness validates: did change improve golden set? │
│       ↓                                                   │
│  8. Deploy if improved, revert if not                     │
│       ↓                                                   │
│  └─── Back to 1 ──────────────────────────────────────────┘
│                                                          │
└──────────────────────────────────────────────────────────┘
```

---

## Phase Plan

### Phase 1 — Signal Collection (MOSTLY DONE)

What's already built: `TrainingDataService` captures metadata and labels with consent gating. `CorrectionDialog` captures user corrections.

**Remaining**:
- [ ] Add correction reason taxonomy to `ClassificationFeedback` (currently free-text). Proposed:
  ```dart
  enum CorrectionReason {
    wrongCategory,     // "This is actually Wet Waste"
    wrongSubcategory,  // "This is HDPE, not PET"
    wrongDisposal,     // "Should be composted, not recycled"
    notWaste,          // "This isn't waste at all"
    otherItem,         // "This is a different item than identified"
  }
  ```
- [ ] Distinguish "correction" from "user changed their mind" — add `timeToCorrection` metric. Corrections within 2 seconds of seeing the result are likely "changed mind" or accidental taps.

### Phase 2 — Review Pipeline

- [ ] Admin review tool (web dashboard or in-app admin mode)
- [ ] Reviewer workflow: see original prediction, user correction, confidence, image thumbnail → approve/reject/uncertain
- [ ] Inter-reviewer agreement tracking (two reviewers, flag disagreements)
- [ ] Review priority: high-confidence corrections first (model was confident but wrong = most valuable signal)

### Phase 3 — Evaluation Loop

- [ ] Weekly automated eval harness run: classify golden set with current model/prompt
- [ ] Compare against baseline (previous week's results)
- [ ] Flag categories with accuracy regression > 5%
- [ ] Generate "hardest examples" report (items consistently misclassified)

### Phase 4 — Improvement Actions

Based on eval harness results, take concrete actions:

| Finding | Action | Owner |
|---------|--------|-------|
| Systematic category confusion (e.g., medical ↔ hazardous) | Prompt refinement or add few-shot examples | AI engineer |
| Consistently wrong disposal for a category | Ruleset update | Content |
| Low-confidence cluster (all items from a specific angle/lighting) | Add to golden set, consider image preprocessing improvement | ML engineer |
| New waste type appearing frequently | Add category/subcategory to taxonomy | Product |

### Phase 5 — On-Device Model Update

Once L1 (on-device inference) ships:
- [ ] Fine-tune on-device model with validated corrections
- [ ] Push updated model via `ModelDownloadService`
- [ ] A/B test new model against old model on golden set before full rollout

---

## Correction Signal Quality

### Filtering Strategy

Not all corrections are equal. Quality filters:

1. **Consent gate**: Only corrections from users with `trainingConsent.enabled == true`. ✅ Already implemented.
2. **Time gate**: Ignore corrections made < 2 seconds after seeing the result (accidental).
3. **Confidence gate**: Prioritize corrections where the model was confident but wrong (high-value signal).
4. **User trust gate**: Weight corrections from users with > 20 classifications and > 80% confirmation rate higher.
5. **Consensus gate**: If multiple users correct the same item type to the same category, that's strong signal.

### Expected Volume

Based on similar apps:
- ~5–10% of classifications receive a correction
- Of those, ~70–80% are legitimate corrections (rest is noise/user experimentation)
- With 1,000 active users classifying 5 items/day: ~250–500 legitimate corrections/week
- This is sufficient for weekly prompt refinement and golden set expansion

---

## Privacy Architecture

The existing `TrainingDataService` already handles the core privacy requirements:

| Requirement | Implementation | Status |
|-------------|---------------|--------|
| Explicit consent | `TrainingConsent` with policy versioning | ✅ |
| Revocation | `revokeConsentAndRequestDeletion()` | ✅ |
| Child protection | Skip child profiles | ✅ |
| Image handling | V1: metadata only; images in later phase behind same consent | ✅ |
| EXIF stripping | `EnhancedImageService` strips EXIF before any upload | ✅ |
| User hashing | `userIdHash` — no raw user IDs in training data | ✅ |

**Additional requirement for the loop**: Audit trail. Every correction used for model improvement must be traceable to a consent record that was active at the time of collection.

---

## Concrete Next Steps

1. **Correction reason taxonomy** — Add structured `CorrectionReason` enum to `ClassificationFeedback`.
2. **Time-to-correction metric** — Track delay between result display and correction.
3. **Review dashboard MVP** — Minimal admin surface to validate queued corrections.
4. **Golden set expansion** — Add high-value corrections to eval harness golden set.
5. **Weekly eval cadence** — Automate weekly eval harness run + regression report.
6. **Prompt improvement pipeline** — Systematic process for prompt updates based on correction patterns.

## Open Questions

- **Image phase timing**: When do we start collecting images (not just metadata) for training? What's the consent + review burden?
- **Correction fatigue**: Will users stop correcting if we don't close the feedback loop visibly ("Your correction helped improve our AI!")?
- **Cross-region corrections**: A correction valid in Bangalore may not be valid in Mumbai (different disposal rules). How to handle?
- **On-device model retraining frequency**: How often can we push model updates without user annoyance?

## Downstream Artefacts

- Updated `ClassificationFeedback` with structured correction reasons
- Admin review dashboard (web or in-app)
- `docs/exploration/EVAL_HARNESS_WEEKLY_CADENCE.md` — weekly evaluation SOP
- Prompt versioning system (track prompt changes + eval results)
- `docs/exploration/CONTINUOUS_LEARNING_SIGNAL_QUALITY.md` — correction signal quality report (after 4 weeks of collection)
