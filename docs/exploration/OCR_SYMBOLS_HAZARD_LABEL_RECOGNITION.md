# OCR, Symbols & Hazard-Label Understanding

**Status**: Exploration | P2 | Advanced Classification Modalities
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) — Entry 53
**Last Updated**: 2026-05-25

---

## Why This Matters

Not everything the app needs to classify is a visual material category. Real-world packaging carries symbols, codes, and marks that contain authoritative data: resin identification codes (#1–#7), WEEE e-waste symbols, GHS hazard diamonds, compostability certifications, and expiry dates. Extracting these symbols with OCR/symbol recognition unlocks classification paths that are:

- **More accurate** than pure vision (a resin code is ground truth, not a guess)
- **More actionable** (hazard diamonds tell the user exactly what disposal precautions are needed)
- **More trustworthy** (users see the actual evidence, not an AI guess)

---

## Symbol Categories

### 1. Resin Identification Codes (#1–#7)

| Code | Name | Common Uses | Recyclability |
|------|------|------------|---------------|
| #1 PET | Polyethylene Terephthalate | Bottles, food jars | Widely recycled |
| #2 HDPE | High-Density Polyethylene | Detergent bottles, milk jugs | Widely recycled |
| #3 PVC | Polyvinyl Chloride | Pipes, shrink wrap | Rarely recycled |
| #4 LDPE | Low-Density Polyethylene | Bags, squeeze bottles | Increasingly collected |
| #5 PP | Polypropylene | Bottle caps, yogurt tubs | Widely recycled |
| #6 PS | Polystyrene | Takeout containers, foam | Rarely recycled |
| #7 Other | Mixed / Other | Multi-layer, polycarbonate | Usually not recycled |

**Challenge**: Codes are often embossed (monochrome, zero contrast) into curved surfaces. Standard OCR fails.

**Pipeline**: Object detection → ROI crop + perspective transform → CLAHE contrast enhancement → custom-trained OCR.

### 2. WEEE Marking (Crossed-Out Wheeled Bin)

- **Symbol**: Standardised crossed-out wheeled bin icon
- **Mandatory on**: All electronic/electrical products sold in EU (and many other markets)
- **Signals**: "Do not dispose in unsorted waste — take to e-waste collection"
- **Detection**: Straightforward — distinctive shape, CNN classifier
- **E-waste category mapping**: Once detected, map to local e-waste rules

### 3. GHS Hazard Diamonds

9 standardised pictograms with red diamond border:

| Symbol | Hazard | Disposal Implication |
|--------|--------|---------------------|
| Skull & crossbones | Acute toxicity | Hazardous waste — never landfill |
| Flame | Flammable | Special handling — no general waste |
| Exploding bomb | Explosive | Extreme hazard — licensed disposal only |
| Corrosion | Corrosive | Neutralise or special containers |
| Gas cylinder | Pressurised gas | Puncture hazard — return to dealer |
| Health hazard | Respiratory/carcinogen | Hazardous waste |
| Exclamation mark | Irritant | Usually hazardous |
| Environment (dead tree/fish) | Environmental toxicity | Never flush/landfill |
| Flame over circle | Oxidising | Fire risk — special storage/disposal |

**Detection**: Standardised, high-contrast, red-bordered — ideal for CNN-based classification. Well-suited for on-device deployment.

### 4. Compostability Certifications

| Mark | Standards | Recognition |
|------|-----------|-------------|
| BPI (Biodegradable Products Institute) | ASTM D6400 (industrial) | Logo + certification number |
| OK Compost HOME | EN 13432 (home compostable) | Critical — home vs industrial distinction |
| OK Compost INDUSTRIAL | EN 13432 (industrial only) | Will NOT break down in home compost |
| Seedling (European Bioplastics) | EN 13432 | Common on compostable packaging |
| TÜV Austria | EN 13432 | OK Compost variants |

**Home vs Industrial distinction is critical** — an item marked "compostable" but requiring industrial heat will not break down in a backyard pile and contaminates home compost.

### 5. Expiry Dates

- **Format variance**: "Best By", "Use By", "BBE", "EXP", varied date formats (DD/MM/YY, MM/DD/YY, YYYY-MM-DD)
- **Surface challenges**: Do-matrix printing, thermal labels, curved bottles, low contrast
- **Pipeline**: Dual-engine OCR + heuristic date validation (reject "13/13/2025") + user confirmation

### 6. Greenwashing Detection

Automated detection of misleading claims uses a combined approach:

- **Whitelist/blacklist**: Verified certifications vs generic "eco-friendly" / "natural" / "green" claims
- **Cross-reference**: Claimed certifications (e.g., "compostable") checked against official registries via certification number
- **Heuristic flagging**: Products using natural imagery + vague claims without certification links

---

## Image Processing Pipeline

```
Input image
    │
    ▼
Frame quality check (blur/lighting rejection)
    │
    ▼
Object detection → general category (bottle, electronics, label)
    │
    ▼
Symbol region detection (resin code area, hazard diamond area)
    │
    ▼
Per-region cropping → perspective correction → contrast enhancement
    │
    ▼
Parallel recognition:
├── Resin code OCR (custom model)
├── GHS symbol CNN classifier
├── Certification mark detection + OCR
├── Expiry date OCR
└── WEEE symbol detection
    │
    ▼
Cross-reference extracted data against local policy engine
    │
    ▼
Combine with vision classification → final disposal decision
```

---

## Integration Points

| Surface | What Changes |
|---------|-------------|
| Scan pipeline | Add symbol extraction step after quality gate, before vision classification |
| Result screen | "We identified this as #1 PET plastic" — cite the actual code on the package |
| Hazard alert | "GHS hazard diamond detected: corrosive — DO NOT handle without gloves" |
| Compostability | "Certified OK Compost HOME — safe for home compost" vs "Industrial compost only" |
| History | Extracted symbols stored alongside classification for audit |

---

## Open Questions

1. **On-device vs cloud**: Can resin code OCR run on-device (TFLite), or does it require cloud GPU?
2. **Coverage**: What % of Indian packaging carries legible resin codes vs unmarked plastics?
3. **Reliability threshold**: When should the app trust a detected symbol over the vision model?
4. **Greenwashing liability**: If we flag a product as greenwashing and the manufacturer pushes back, what's the legal risk?

---

## Phasing

| Phase | Scope | Key Dependency |
|-------|-------|----------------|
| 0 | GHS hazard diamond detection (CNN, highest reliability) | On-device model training |
| 1 | WEEE symbol detection + e-waste rule mapping | WEEE symbol training data |
| 2 | Resin code OCR from clear, direct images | Custom OCR training dataset |
| 3 | Compostability certification recognition | Certification logo + number dataset |
| 4 | Expiry date OCR | Date format coverage |
| 5 | Combination — all symbols extracted in one pipeline pass | Pipeline integration |
