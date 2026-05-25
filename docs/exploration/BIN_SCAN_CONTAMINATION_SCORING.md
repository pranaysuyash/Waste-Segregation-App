# Bin-Scan Contamination Scoring

**Status**: Exploration | P2 | Advanced Classification Modalities
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) — Entry 58
**Last Updated**: 2026-05-25

---

## Why This Matters

The highest-leverage intervention for recycling quality is **at the bin** — catching contamination before it enters the collection system. A bin-scan feature lets users (or building managers) photograph a full recycling/compost bin and get a contamination score with specific feedback: "3 items in this bin shouldn't be here — here they are."

This transforms the app from a per-item assistant into a **household/community waste quality tool** with direct economic and environmental impact.

---

## Core Feature

```
User takes photo of open bin
    │
    ▼
Multi-object detection → identify all items in the frame
    │
    ▼
Per-item classification → recyclable / compostable / waste / hazardous
    │
    ▼
Contamination calculation
├── % wrong items by count
├── % wrong items by estimated volume
└── Critical contaminant detection (batteries, sharps, hazardous)
    │
    ▼
Grade assignment (A through F)
    │
    ▼
Results: visual overlay + per-contaminant highlights + grade
```

---

## Contamination Calculation

### Count-Based
```
Contamination % = (Non-target items / Total items) × 100

Example: 3 contaminants in 30 items = 10% contamination → Grade D
```

### Volume-Weighted (Advanced)
```
Contamination % = Weighted by estimated volume of each contaminant
A single pizza box contaminating a paper bin = higher impact than one straw in plastic
```

---

## Grading Scale (Aligned with MRF Standards)

| Grade | Contamination | MRF Impact | User Message |
|-------|--------------|------------|--------------|
| A+ | < 1% | Perfect — zero rejection risk | "Perfect! This bin is ready for collection." |
| A | 1–3% | Minimal impact | "Great job — just a couple of small items." |
| B | 3–5% | Low risk of discounting | "Good — 3 items need attention (see below)." |
| C | 5–10% | Risk of load rejection | "This batch needs sorting — X items are wrong." |
| D | 10–20% | High chance of rejection | "This would likely be rejected. Please re-sort." |
| F | > 20% | Almost certain rejection | "This batch would go to landfill as-is. Let's fix it." |
| ❌ Critical | Any battery/hazardous | Immediate safety risk | "⚠️ A battery or hazardous item found — REMOVE immediately!" |

---

## Visual Feedback

```
┌──────────────────────────────────────────────────┐
│  📊 Bin Score: C  (3 contaminant items found)   │
├──────────────────────────────────────────────────┤
│                                                  │
│  [Photo of bin with overlay]                     │
│                                                  │
│  🔴 Item 1: Pizza box in paper bin               │
│     → "Grease makes paper unrecyclable.          │
│        Dispose greasy boxes in general waste."   │
│                                                  │
│  🔴 Item 2: Plastic bag in compost bin           │
│     → "Plastic doesn't compost.                  │
│        Put plastic bags in grocery drop-off."    │
│                                                  │
│  🔴 Item 3: Glass jar in plastic bin             │
│     → "Glass goes in the glass bin."             │
│                                                  │
│  ✅ 27 items correctly sorted!                   │
│                                                  │
│  [Tips to improve]     [This bin is ready]       │
└──────────────────────────────────────────────────┘
```

---

## Privacy Considerations

A photo of an open bin is more revealing than a single item — it may show:

- Envelopes with addresses
- Product packaging revealing purchase habits
- Medication containers
- Personal documents

**Mitigations**:
1. **On-device processing**: All analysis runs locally — no bin photo transmitted to cloud
2. **No saved image**: Process → score → discard the raw image. Save only the metadata (item count, contamination %, per-item class labels)
3. **Optional save**: User can choose to save the annotated result (no raw photo) for historical tracking
4. **Blur by default**: If image is displayed in-app, blur/redact text regions

---

## Household & Team Challenge Integration

| Context | Feature |
|---------|---------|
| Household | "Your kitchen bin: Grade B this week — up from C last week!" |
| Apartment/RWA | "Building C wing: Average Grade B across 12 bins" |
| School classroom | "Grade competition — Ms. Sharma's class vs Mr. Rao's class" |
| Corporate office | "Floor 3 contest: Best recycling score wins the Green Cup" |
| Community | "Neighbourhood ranking: Your street scores A- average" |

**Design**:
- Weekly snapshots (not daily — avoids micromanaging)
- Trend: "Your bin score has improved 15% over 3 weeks"
- Anomaly detection: "Score dropped 2 grades this week — need investigation?"
- Positive framing: highlight what's correct, not just what's wrong

---

## Detection Challenges

| Challenge | Mitigation |
|-----------|------------|
| Overlapping objects in bin | Multiple-angle guidance ("take photo from directly above"), accept partial detection |
| Low light (indoor bin) | Flash guidance, accept lower detection count |
| Small items (bottle caps, straws) | May not be visible — flag in results ("small items may not be counted") |
| Messy/very full bin | "Your bin looks very full — items may be hard to count" |
| Reflection / glare | Angle guidance |

---

## Integration Points

| Surface | What to Show |
|---------|-------------|
| Scan screen | "Scan your whole bin" mode toggle (vs single-item) |
| Result screen | Bin score card with overlay |
| Home screen | "Your bin this week" widget (if opted in) |
| Impact dashboard | Contamination trend over time |
| Community | Building/neighbourhood leaderboard |
| Gamification | "Zero-contamination streak" badge |
| Family mode | Per-family-member contribution to bin score |

---

## Open Questions

1. **Detection accuracy**: How many items in a cluttered bin photo can a YOLO-scale model reliably detect and classify?
2. **User adoption**: Will users clean out their bin to take a photo? Friction analysis needed.
3. **Privacy backlash risk**: Even with on-device processing, announcing "we can photograph your bin" may trigger privacy concerns.
4. **MRF alignment**: Are MRFs using similar grading? Could the app issue a "pre-collection certificate" accepted by waste haulers?

---

## Phasing

| Phase | Scope | Key Dependency |
|-------|-------|----------------|
| 0 | Single-item detection in bin context + manual contaminant tagging | Object detection model |
| 1 | Multi-object detection + automatic scoring from a single photo | Multi-object detection pipeline |
| 2 | Annotated overlay + per-contaminant feedback | Detection + image overlay pipeline |
| 3 | Household trend tracking + improvement over time | History storage + analytics |
| 4 | Team/neighbourhood leaderboard + challenges | Community/gamification integration |
