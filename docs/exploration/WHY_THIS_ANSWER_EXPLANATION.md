# Why-This-Answer Explanation Panel

**Status**: Exploration — pre-design
**Priority**: P2 (🟡)
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) — Topic #59
**Related docs**: `CLASSIFICATION_CONFIDENCE.md`, `DISPOSAL_REASONING_STAGE.md`, `CONFIDENCE_THRESHOLD_TUNING.md`

---

## Why This Matters

Users trust AI classification results more when they understand *why* the model reached its conclusion — and they trust less when the answer is opaque. For a waste classification app, the "why" has three distinct dimensions:

1. **Visual evidence**: What in the image drove the model's decision? (shape, color, texture, label)
2. **Confidence calibration**: How sure is the model, and what does "80% confident" mean for disposal?
3. **Policy override**: When local rules contradict the visual classification, why does the city rule exist?

A well-designed explanation panel reduces corrections, builds long-term trust, and educates users about waste classification — turning every scan into a learning moment.

---

## Key Questions

- What level of explanation is useful for a user standing at a bin (brief) vs a curious user at home (detailed)?
- How do we present evidence without overwhelming non-technical users?
- When should explanations show alternatives ("could also be paper") vs commit to a single answer?
- How do we explain policy overrides without undermining confidence in the AI?
- Do explanations improve retention, or are they a distraction from the disposal task?

---

## Research Findings

### 1. Confidence Visualization Patterns

Research across Yuka, PictureThis, Google Lens shows three tiers:

| Confidence | Visual Pattern | Copy Tone | Suggested Action |
|---|---|---|---|
| ≥ 90% | Solid green checkmark, bold result | Assertive: "This is plastic" | Show disposal instruction directly |
| 60-89% | Dashed border, muted color, (?) icon | Provisional: "We think this is plastic" | Show alternatives; prompt confirmation |
| < 60% | Yellow/amber warning, (?) icon | Uncertain: "We're not sure" | Clarification flow: "Is it shiny or matte?" |
| Hazardous any % | Red border + pulsing warning | Imperative: "This is hazardous" | Show disposal instruction; no alternatives |

### 2. Evidence Presentation Models

Three competing approaches, each with trade-offs:

**Model A: Feature Highlighting (heatmap overlay)**
- Show the image with a heatmap overlay indicating which pixels drove the decision.
- Pros: Visually obvious; works for any category.
- Cons: Requires saliency map generation; may look like noise to non-technical users.
- Best for: Users who want to understand *what the AI saw*.

**Model B: Reference Images ("It looks like this")**
- Show 2-3 reference images from the training set that the model matches to.
- Pros: Intuitive — "your bottle looks like these bottles."
- Cons: Reference images may not match well; privacy concern if reference images are user-uploaded.
- Best for: Casual users who want quick reassurance.

**Model C: Feature Checklist ("We checked these")**
- Show a checklist of visual features the model evaluated:
  - ✓ Shape: Cylindrical (bottle-like)
  - ✓ Material: Shiny, translucent (plastic)
  - ✓ Label detected: Yes (code #1 PET)
  - ✓ Contamination: None
- Pros: Educational — users learn what features matter.
- Cons: More text-heavy; requires structured feature extraction.
- Best for: Users who want to learn about waste classification.

**Recommended hybrid**: Show Model C (checklist) by default, with an option to expand to Model A (heatmap) for power users.

### 3. Confidence Language

Avoid raw percentages — they mislead without calibration context:

| Display | User Interpretation | Better Alternative |
|---|---|---|
| "Confidence: 87%" | "87% chance it's right" | "We're fairly sure this is Plastic" |
| "Confidence: 65%" | "Probably wrong" | "We think this is Plastic, but it could be Paper" |
| "Confidence: 95%" | "Absolutely certain" | "We're confident this is Plastic" |

**Recommended**: Use descriptive confidence tiers with color coding, not raw numbers. Show percentages only in a detail expandable for technically curious users.

### 4. Policy Override Explanation

When local policy overrides the model's classification:

```
┌────────────────────────────────────┐
│ 📋 Local Rule Applied              │
│                                    │
│ Even though this looks like        │
│ recyclable plastic, the city of    │
│ Bengaluru does not accept #6       │
│ (polystyrene) in blue bins.        │
│                                    │
│ Source: BBMP Solid Waste           │
│ Management Rules 2024              │
│                                    │
│ [Why this rule exists] [Details]   │
└────────────────────────────────────┘
```

The override explanation must:
- Acknowledge the model's classification ("Even though this looks like...").
- Cite the governing rule with source attribution.
- Explain *why* the rule exists (plant capability, market, regulation).
- Offer an alternative disposal path.

### 5. Alternative Suggestions

When the model is uncertain, show alternative classifications:

```
We think this is: PLASTIC (60%)
Could also be:
  - Paper (25%) — if it feels dry and fibrous
  - Metal (10%) — if it feels heavy and metallic
```

The alternatives serve three purposes:
1. Help the user self-correct without extra taps.
2. Calibrate the user's expectations ("the model isn't sure either").
3. Collect signal on which alternative the user chooses.

### 6. Error Disclosure

When the user corrects a classification, the acknowledgment sets the tone for future trust:

| Bad | Good |
|---|---|
| "Thanks for the correction" | "You're right — this is Paper, not Plastic. Thanks for catching that. We'll learn from this." |
| (no explanation of why it was wrong) | "We miscategorized this because the glossy label looked like plastic. We're improving our film-detectio |

---

## Design Patterns

### Pattern 1: Default Result (High Confidence, Non-Hazardous)
```
┌───────────────────────────────┐
│ ✓ Plastic (PET) #1           │ ← Green checkmark, bold
│                               │
│ Why:                          │
│ ✓ Shape: Bottle/cylindrical   │
│ ✓ Material: Translucent       │
│ ✓ Label code: #1 PET         │
│ ✓ No contamination detected   │
│                               │
│ [Disposal Instructions]       │
│ [Why-Not-Other] [Details ▸]   │
└───────────────────────────────┘
```

### Pattern 2: Uncertain Result (Medium Confidence)
```
┌───────────────────────────────┐
│ ? Plastic (PET) #1 (70%)     │ ← Dashed border, muted
│                               │
│ Could also be:                │
│  • Glass (20%) — if it's     │
│    heavier than expected      │
│  • Paper (10%) — if the      │
│    surface feels matte        │
│                               │
│ Is this correct? [Yes] [No]   │
└───────────────────────────────┘
```

### Pattern 3: Hazard Override (Safety-Critical)
```
┌───────────────────────────────┐
│ ⚠️ HAZARDOUS WASTE           │ ← Red border, pulsing
│                               │
│ Classification: Paint/        │
│ solvent container             │
│                               │
│ Model detection: Metal can    │
│ with flammable label          │
│                               │
│ Local rule: Bengaluru BBMP    │
│ → Hazardous drop-off only     │
│                               │
│ [Find nearest drop-off]       │
│ [Why hazardous] [Details]     │
└───────────────────────────────┘
```

---

## Anti-Patterns

| Anti-Pattern | Why |
|---|---|
| Raw confidence percentages without context | Misleading — users misinterpret calibration |
| Heatmap as default explanation | Distracting for most users; keep in expandable |
| No explanation for overrides | User loses trust when AI says one thing, policy says another |
| Dismissable explanations | Users who need them may not know they exist |
| Jargon ("CNN features", "embedding similarity") | Non-technical users disengage |

---

## Open Questions

1. Should explanations be on the result screen by default, or in an expandable panel?
2. How do we generate feature checklists (Model C) without a structured feature extraction pipeline?
3. Should the explanation vary by user persona (new user gets simpler → expert user gets detailed)?
4. How do we A/B test whether explanations improve or worsen correction rate?
5. Is there a privacy concern with presenting "matching reference images" if reference set contains user-uploaded corrections?

---

## Next Steps

1. Design 3 explanation panel variants for user testing.
2. Implement expandable explanation section on result screen.
3. Add policy override citation to city rules display.
4. A/B test explanation presence vs absence on correction rate.
5. Research saliency map generation for on-device or cloud classification.
