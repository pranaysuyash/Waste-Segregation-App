# Contamination Detection

**Status**: Exploration | P2 | Advanced Classification Modalities
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) — Entry 54
**Last Updated**: 2026-05-25

---

## Why This Matters

Contamination is the single biggest reason recyclable batches get rejected and sent to landfill. A single greasy pizza box or unrinsed peanut butter jar can lower the value (or trigger rejection) of an entire recycling load. If the app can detect contamination and guide the user to clean/dispose correctly before the item enters the bin, it directly improves recycling economics.

---

## Contamination Types & Visual Cues

| Type | Visual Cues | Impact | Detection Feasibility |
|------|------------|--------|----------------------|
| Food residue | Visible grease, sauce remnants, food particles | High — greasy paper is unrecyclable | Medium — colour/texture change |
| Liquid residue | Standing liquid in container, wet paper | High — ruins entire bale | Medium — reflectivity, saturation |
| Mixed materials | Labels, caps, liners still attached | Medium — reduces material purity | High — multi-object detection |
| Non-target material | Wrong item in wrong bin (e.g., plastic in paper) | High — contaminates batch | High — classification already does this |
| Hazardous residue | Chemical residue, medical waste residue | Critical — health + batch | Low — mostly user-reported |
| Broken glass/sharps | Fracture lines, sharp edges | Critical — safety hazard | Medium — geometric analysis |
| Excessive moisture | Soggy cardboard, condensation | High — mould, weight, bale quality | Medium — texture + weight |

---

## Acceptable Contamination Levels

| Stream | Acceptable Level | Consequence of Excess |
|--------|-----------------|----------------------|
| Paper/cardboard | < 1% food contamination | Bale rejection, mould risk |
| Plastic bottles | < 5% residue (unrinsed) | Discounted price, load rejection |
| Glass | < 2% non-glass | Contaminates downstream sorting |
| Metal | < 3% non-metal | Furnace contamination risk |
| Compost | < 1% non-compostable | Batch failure, odour |

---

## Detection Approaches

### 1. Visual Inspection (On-Device)

- **Grease/food residue**: Trained classifier on cropped item images — looks for colour saturation shifts, texture changes (shiny vs matte)
- **Liquid residue**: Container orientation + reflectivity analysis
- **Mixed materials**: Multi-object detection for attached labels, caps, liners
- **Broken glass**: Edge detection for fracture lines, sharp vertices

### 2. User Guidance (When Detection Is Inconclusive)

| Item State | Message |
|------------|---------|
| Container with visible residue | "This container looks like it still has food residue. Please rinse and dry before recycling." |
| Paper with suspected grease | "Grease damages paper recycling. If this paper is greasy, please put it in general waste." |
| Mixed-material item | "Please separate the cap from the bottle before recycling both." |
| Questionable moisture | "Is this cardboard dry? Wet cardboard degrades the recycling batch." |

### 3. Post-Scan Correction Feedback

When a user corrects the classification (contamination-related):

- "Great catch! We'll remember that items with grease should go to waste, not recycling."
- This feeds the training data pipeline for the contamination classifier.

---

## User-Facing Grading

For bin-scan contamination scoring (see Bin-Scan doc), translate contamination level into a grade:

| Grade | Contamination Level | User Message |
|-------|-------------------|--------------|
| A | < 1% | "Perfect — this bin is ready for collection!" |
| B | 1–3% | "Great — just a few small items to fix." |
| C | 3–10% | "3 contaminant items found — see highlighted items below." |
| D | 10–20% | "This batch needs attention — X items shouldn't be here." |
| F | > 20% | "This batch would be rejected. Let's fix the sorting together." |

---

## Integration Points

| Surface | What to Show |
|---------|-------------|
| Scan result — contaminated item | "This item has food residue — please rinse before recycling" + visual guide |
| Scan result — mixed material | "Please separate the label from the bottle" + step-by-step |
| History — saved scan | Save contamination flag for aggregate analytics |
| Impact dashboard | "Contamination rate: 3% this month — down from 5%!" |
| Community — challenges | "Zero-contamination streak: 7 days! Keep it up" |

---

## Open Questions

1. **Detection reliability**: Can on-devide cameras reliably detect grease on paper, or is this always an approximation?
2. **User fatigue**: Will users get annoyed if the app repeatedly asks them to "rinse and dry" every container?
3. **Cultural adaptation**: In markets where waste is manually sorted at MRFs, contamination guidance may differ from fully automated MRFs.
4. **Measurement**: How do we know contamination detection is accurate? What's the eval set?

---

## Phasing

| Phase | Scope | Key Dependency |
|-------|-------|----------------|
| 0 | User-reported contamination ("Is this item clean?") + static guidance | No ML dependency |
| 1 | Grease/food residue classifier (on-device) | Contamination training dataset |
| 2 | Mixed-material detection (attached labels/caps) | Multi-object detection pipeline |
| 3 | Liquid residue detection | On-device classifier |
| 4 | Broken glass/sharps detection | Safety-critical — needs very high precision |
