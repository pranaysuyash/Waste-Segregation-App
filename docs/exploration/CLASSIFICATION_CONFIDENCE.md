# Classification Confidence & Uncertainty

**Purpose**: Define how the app models, calibrates, and communicates classification uncertainty to users and to the routing system.
**Status**: Exploration — not yet implemented as a formal layer
**Last Updated**: 2026-05-25
**Related**: [CONFIDENCE_THRESHOLD_TUNING.md](CONFIDENCE_THRESHOLD_TUNING.md), [MULTI_MODEL_AI_ROUTING.md](MULTI_MODEL_AI_ROUTING.md), [SAFETY_CRITICAL_AUTONOMY_RULES.md](SAFETY_CRITICAL_AUTONOMY_RULES.md)

---

## Problem Statement

The app surfaces a confidence score with each classification, but today this score is:

1. **Uncalibrated** — model-reported `confidence: 0.87` does not reliably mean 87% accuracy. Different providers (OpenAI, Gemini, on-device) report confidence on different scales.
2. **Not routed on** — no escalation logic reads confidence to decide whether to accept, escalate, or ask a clarifying question.
3. **Not user-facing** — the score exists in the data model but does not meaningfully shape UX (result certainty, ambiguous state, clarifying prompts).
4. **Not per-category** — the same threshold applies to plastic bottles and medical waste, despite vastly different safety consequences.

---

## Research Summary

### Confidence Calibration Methods

| Method | Description | Best For |
|--------|-------------|----------|
| Temperature Scaling | Single scalar parameter softens probability distribution; preserves ranking | Multi-class, post-hoc calibration |
| Platt Scaling | Logistic regression maps outputs to probabilities | Binary classification |
| Histogram Binning | Non-parametric — groups predictions into confidence bins, maps to accuracy rates | Sufficient validation data available |
| Isotonic Regression | Non-parametric, more flexible than binning | Large-held-out sets |

Modern VLM research (arXiv:2507.17383) recommends **action-wise scaling** — different calibration per output dimension — which maps to our per-category threshold need.

### Per-Category Thresholds — Not One-Size-Fits-All

Different waste categories have different risk profiles and visual signatures:

| Category | Risk Level | Recommended Min Confidence | Rationale |
|----------|-----------|---------------------------|-----------|
| Plastic bottle, Glass | Low | 0.70 | Low consequence of misclassification |
| Paper, Cardboard | Low | 0.70 | Typically visually unambiguous |
| Organic waste | Low | 0.75 | Some ambiguity (cooked vs raw) |
| E-waste | Medium | 0.85 | Higher contamination consequence |
| Batteries | High | 0.95 | Safety-critical — must not miss |
| Medical waste | High | 0.95 | Safety-critical — must not miss |
| Chemicals | High | 0.95 | Safety-critical — must not miss |
| Aerosols | High | 0.95 | Explosion risk if mis-sorted |
| Sharps | Critical | 1.0 (deterministic only) | Must never be resolved by uncertain local inference |

### Communicating Uncertainty in UX

- **High confidence (>85%)**: Show result outright with subtle confidence indicator
- **Medium confidence (50-85%)**: Show primary result + "Maybe [alternative]?" with clarification prompt
- **Low confidence (<50%)**: Show "I'm not sure — can you help?" with visual alternatives (Google Lens-style grid)
- **Ambiguous**: Highlight which alternatives would change the disposal advice (e.g., "If this is food waste vs compostable plastic, it goes to different bins")

---

## UX States for Uncertainty

| State | Confidence | UX Treatment | User Action |
|-------|-----------|--------------|-------------|
| `definitive` | >= 0.90 | Standard result card + subtle confidence badge | Optional correction |
| `suggested` | >= 0.70 | Result card + "Does this look right?" prompt | Confirm or correct |
| `clarify` | >= 0.50 | Show top 2-3 alternatives | Select correct answer |
| `ambiguous` | < 0.50 | "I can't identify this" + ask for more info | Retake photo or describe |
| `withheld` | Safety-critical < threshold | Always escalate or show "requires manual check" | Referral path |

---

## Calibration Methodology (Recommended)

1. **Collect eval data**: Use recorded provider outputs from the eval harness (110+ cases)
2. **Compute empirical accuracy per bin**: For each confidence decile, compute actual accuracy
3. **Build calibration curve**: Per-provider, per-category calibration maps
4. **Apply temperature scaling**: Find optimal T per provider using held-out set
5. **Publish uncertainty budget**: "When the model says 0.85, expect 80-90% accuracy"

---

## Key Decisions Needed

1. **Calibration ownership**: Should calibration be per-provider (OpenAI vs Gemini vs on-device) or unified?
2. **Clarify vs escalate**: When confidence is medium, should we ask the user or escalate to the next model tier?
3. **User-visible uncertainty**: Should users see exact confidence scores, or only qualitative buckets (High/Medium/Low)?
4. **Gamification tie-in**: Does correcting uncertain items earn more points than confirming certain ones?

---

## Open Questions

- How do we handle multi-object scenes where confidence varies per detected item?
- Should the uncertainty state persist in history for audit purposes?
- When the user clarifies an ambiguous result, does that become a training data candidate?
- How do offline (local) and cloud confidence compare — do we need separate calibration curves?

---

## Next Steps

1. Build per-provider calibration curves from existing eval data
2. Implement the per-category threshold matrix in the router policy
3. Design UX mockups for 5 uncertainty states
4. A/B test "suggested" vs "definitive" treatment for engagement and correction rate
