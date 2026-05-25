# Label Ontology Governance

**Status**: Seed — `recycling_code.dart` exists, but no formal ontology governance
**Priority**: 🔴 (P1 — label ontology is the join key between models, rulesets, and user experience)
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) — P1/P2 Technical Architecture (topic 88)
**Related**: [RECYCLING_CODE_TAXONOMY.md](RECYCLING_CODE_TAXONOMY.md), [MODEL_REGISTRY_AND_VERSIONING.md](MODEL_REGISTRY_AND_VERSIONING.md), [EVAL_LEADERBOARD_AND_MODEL_CARDS.md](EVAL_LEADERBOARD_AND_MODEL_CARDS.md)

---

## Overview

The label ontology defines the set of categories, materials, and sub-materials that the AI stack can output. It is the **join key** between:
- Classification model outputs (what the AI sees)
- Disposal rulesets (what the local rules say)
- User-facing labels (what the user reads)
- Evaluation datasets (what we test against)

Without governance, the ontology drifts silently — new categories appear ad-hoc, labels become inconsistent, and eval sets fall out of sync with production categories.

---

## Ontology Structure

```
Level 1 (Category)        Level 2 (Material)         Level 3 (Sub-material)
──────────────────────────────────────────────────────────────────────────
Category
  ├── Recyclable
  │     ├── Plastic
  │     │     ├── PET (#1)
  │     │     ├── HDPE (#2)
  │     │     ├── PVC (#3)
  │     │     ├── LDPE (#4)
  │     │     ├── PP (#5)
  │     │     ├── PS (#6)
  │     │     └── Other (#7)
  │     ├── Paper/Cardboard
  │     │     ├── Newspaper
  │     │     ├── Corrugated cardboard
  │     │     └── Mixed paper
  │     ├── Glass
  │     │     ├── Clear
  │     │     ├── Green
  │     │     └── Brown
  │     └── Metal
  │           ├── Aluminum
  │           ├── Steel/Tin
  │           └── Copper
  │
  ├── Organic/Wet
  │     ├── Food waste
  │     ├── Garden waste
  │     └── Compostable packaging
  │
  ├── Hazardous
  │     ├── Batteries
  │     ├── Chemicals
  │     ├── Medical waste
  │     ├── E-waste
  │     ├── Aerosols
  │     └── Sharps
  │
  └── Non-recyclable
        ├── Mixed material
        ├── Contaminated items
        └── Polystyrene foam
```

Each node has:
- `id`: stable, unique, never reused (e.g., `mat_plastic_pet_001`)
- `label`: user-facing, localized (e.g., "PET Plastic (#1)")
- `level`: 1/2/3
- `parent_id`: reference to parent node
- `aliases`: alternative names (e.g., "PETE", "Polyethylene Terephthalate")
- `recycling_code`: link to RIC or equivalent standard
- `risk_flags`: `hazardous`, `medical`, `sharp`, `pressurized`, `electronic`
- `valid_from`: date this label became valid
- `valid_to`: date this label was deprecated (null if active)
- `superseded_by`: if deprecated, the node that replaces it

---

## Versioning Strategy

### Immutable Snapshots

The ontology is versioned as a whole. Each version is an immutable snapshot:

```
ontology_v2025_01.json
ontology_v2025_02.json  (added "Biodegradable plastic" as sub-category)
ontology_v2025_03.json  (deprecated "Polystyrene foam" → merged into "Non-recyclable plastic")
```

**Semantic versioning**:
- Major: structure change (level added/removed, hierarchy rearranged)
- Minor: new nodes added, deprecated (backward-compatible)
- Patch: label text fixes, alias additions, typo corrections

### Deprecation vs Deletion

Nodes are **deprecated**, never deleted:
- `valid_to` set on the deprecated node
- `superseded_by` points to the replacement node
- Eval datasets with the deprecated label are flagged but not invalidated
- Production models still receive the deprecated label? Yes, but pipeline auto-maps to replacement

### Temporal Labeling

Some materials are valid only for certain periods:
- "Single-use plastic ban items" — valid from 2022, may be renamed/restructured later
- "COVID-specific medical waste" — valid during pandemic period, now deprecated

Each node carries `valid_from` / `valid_to` so time-travel queries are possible.

---

## Canonical Mapping Layer

### Problem

The AI model outputs "clear plastic bottle" but:
- The user sees "Plastic Bottle (Recyclable)"
- The disposal ruleset references "PET (#1)"
- The EU DPP references "EWC 15 01 02"
- The Indian SWM rules reference "Category 1: Plastic"

### Solution: Mediator Layer

```json
{
  "canonical_id": "mat_plastic_pet_001",
  "user_labels": {
    "en": "PET Plastic Bottle",
    "hi": "पीईटी प्लास्टिक की बोतल",
    "kn": "ಪಿಇಟಿ ಪ್ಲಾಸ್ಟಿಕ್ ಬಾಟಲ್"
  },
  "standard_mappings": {
    "ric": "1",
    "ewc": "15 01 02",
    "indian_swm": "Plastic - Category 1",
    "eu_dpp": "plastic_pet"
  },
  "disposal_relevance": {
    "recyclable": true,
    "hazardous": false,
    "compostable": false
  }
}
```

The model outputs `canonical_id`. The app resolves to user labels, standard mappings, and disposal rules at display/reasoning time.

---

## Label Validation Rules

### Incompatibility Constraints

Some combinations are impossible or dangerous:

| Rule | Example | Violation |
|------|---------|-----------|
| `hazardous` ≠ `recyclable` | Battery marked as recyclable | 🔴 Flag |
| `medical` ≠ `compostable` | Syringe marked as organic | 🔴 Flag |
| `sharp` ≠ `general_waste` | Blade in regular bin | 🔴 Flag |
| `pressurized` ≠ `recyclable` | Aerosol can in recycling | 🟡 Warn |
| `electronic` ≠ `wet_waste` | Circuit board in food waste | 🔴 Flag |

These rules are enforced at:
- **Eval set validation**: ensure golden labels don't violate constraints
- **Model output validation**: reject outputs that violate constraints
- **User correction intake**: verify correction submission doesn't violate constraints

### Dependency Rules

| Pattern | Example |
|---------|---------|
| If `material = X`, then `risk_flag` must be in `{Y, Z}` | If `material = battery`, then `risk_flag` must be `hazardous` |
| If `category = hazardous`, then `disposal_path` must be `special_collection` or `drop_off` |
| If `sub_material = PET`, then `material` must be `plastic` |

---

## Label Drift Management

### Sources of Drift

1. **New materials**: Bio-based plastics, compostable packaging, new composite materials
2. **Regulation changes**: Single-use plastic bans rename categories, new EWC codes
3. **Product evolution**: New packaging types that don't fit existing categories

### Detection

- Monitor model output distribution — if "Other (#7)" frequency rises, new material subtypes may exist
- Monitor "Other" / "I don't know" selections in user correction flow
- Monitor user-contributed label suggestions (UGC pipeline)

### Remediation

1. **Create placeholder**: Add `unsorted_new_material` as child of relevant parent
2. **Collect examples**: Pull 50-100 images from corrections tagged with this placeholder
3. **Review**: Human review of collected examples to define new canonical label
4. **Promote**: New label version in next ontology snapshot. Update mapping layer.
5. **Backfill**: Update eval datasets that hit this case. Retrain or reprompt.

---

## Governance Process

### Change Request Workflow

```
[Draft] → [Review] → [Approved] → [Released] → [Deployed]
```

1. **Draft**: Propose change (new label, deprecation, hierarchy change) with rationale and evidence
2. **Review**: Team review — does this break any existing eval sets? Are mapping updates needed?
3. **Approved**: Label owner signs off. Impact assessment complete.
4. **Released**: New ontology snapshot created (`v2025_major_minor_patch`)
5. **Deployed**: Model registry updated. Prompt templates updated. FRC keys updated.

### Release Cadence

- **Major**: Quarterly (or when regulation changes require it)
- **Minor/Micro**: As needed (treat as data change, not code change)
- **Emergency**: ASAP for safety-critical category changes (e.g., new hazardous classification)

### Owner

- One designated ontology owner
- Changes require review from: model team + ruleset team + eval team
- Emergency changes bypass review but must be ratified within 7 days

---

## Implementation Path

1. **Phase 0** (canonical JSON): Extract current labels into a single `ontology.json`. Version in git. Add validation script (check for incompatibility violations).
2. **Phase 1** (mapping layer): Build the mediator layer between canonical IDs and user labels + standard mappings. Update model output to emit canonical IDs.
3. **Phase 2** (governance tooling): Simple web UI for viewing and proposing ontology changes. Change request workflow.
4. **Phase 3** (drift detection): Automated monitoring of label distribution drift. Placeholder creation for emerging categories.

---

## Open Questions

- Should ontology be stored in Firestore (live-editable) or git + deployed as config (review-gated)?
- How do we handle ontology changes that require model retraining?
- What is the policy for user-contributed labels that don't fit the ontology — accept, reject, or queue for review?
- Should we maintain separate ontologies for different regions (India vs EU), or one universal ontology with region-specific mapping tables?
- How do we version the ontology when the change affects only one region's labels?
