# Recycling Code Taxonomy

**Status**: Exploration doc
**Last Updated**: 2026-05-25
**Category**: Data & Standards / Disposal Knowledge
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md#a22-recycling-code-taxonomy-)
**Related**: Region-Aware Rulesets (#4), Disposal Reasoning Stage (#3), EU Digital Product Passport (A23), Deterministic Classifier (G1)

---

## Why This Is a Topic

The app speaks multiple classification languages: resin identification codes (#1–#7), material categories (plastic, glass, paper, metal, organic), waste types (hazardous, e-waste, compostable), and user-facing names ("milk carton", "shampoo bottle", "yogurt tub"). These taxonomies are the **join key** that connects visual classification → material identification → regional disposal rule → user-facing advice.

Currently the taxonomy is implicit (defined in prompts and model training data, not as a first-class data model). As the rules corpus grows and multi-provider routing expands, an explicit, versioned taxonomy becomes load-bearing infrastructure.

---

## Key Questions

1. **Which taxonomies are first-class** — resin codes (RIC #1–#7), WEEE categories, material families, GTIN/barcode mappings, EU DPP material codes?
2. **Hierarchical vs flat** — should the taxonomy be a tree (Plastic → PET → Bottle → Brand) or flat list?
3. **Translation layer** — how does the app map user-facing language ("shampoo bottle") to internal categories ("HDPE #2") to disposal rules?
4. **Versioning** — what happens when a city reclassifies a category or the EU updates its code system?
5. **Cross-walk tables** — how does a label in one taxonomy (e.g., "PP #5" from visual classification) map to the same label in the rules corpus taxonomy?
6. **GTIN/barcode → material mapping** — can the app resolve a barcode to a material classification?

---

## Research Summary

### Resin Identification Codes (RIC #1–#7)

| Code | Material | Common Items | Recyclability Note |
|------|----------|-------------|-------------------|
| #1 PET | Polyethylene Terephthalate | Water bottles, soda bottles, food jars | Widely recycled, but degrade with each cycle |
| #2 HDPE | High-Density Polyethylene | Milk jugs, detergent bottles, shampoo bottles | Widely recycled, high market value |
| #3 PVC | Polyvinyl Chloride | Pipes, some food wrap | Difficult to recycle, often landfilled |
| #4 LDPE | Low-Density Polyethylene | Plastic bags, shrink wrap, squeeze bottles | Technically recyclable but often rejected by curbside |
| #5 PP | Polypropylene | Yogurt containers, medicine bottles, straws | Increasingly recyclable, infrastructure growing |
| #6 PS | Polystyrene / Styrofoam | Takeout containers, cup lids | Generally not recycled via curbside |
| #7 Other | Mixed, bioplastic, multi-layer | Baby bottles, CD cases, compostable plastics | Caught-all code — check local rules |

**Critical insight**: RICs identify resin type, NOT recyclability. Recyclability is determined by local infrastructure and market demand — a fact the app must communicate to avoid misleading users.

### WEEE Marking Categories (E-Waste)

EU WEEE Directive categories (simplified to 6):
1. Temperature exchange equipment (fridges, ACs)
2. Screens, monitors (screens >100cm²)
3. Lamps (fluorescent, LED)
4. Large equipment (>50cm external dimension)
5. Small equipment (<50cm)
6. Small IT and telecom (phones, routers, cables)

**Implication for app**: The app should map scanned e-waste to these categories for disposal routing. The WEEE crossed-out bin symbol is the universal identifier.

### Glass & Paper Classifications

**Glass**: Sorting by colour (clear, green, brown) affects recycling value. EU glass codes 70–72 map to colours. Most consumer apps simplify to "clear glass" / "coloured glass."

**Paper/Cardboard**: Grades based on fibre length and contamination:
- OCC (Old Corrugated Cardboard) — high grade
- Mixed paper — lower grade
- Office paper — premium grade
- Contaminated paper (grease, food) — non-recyclable

**Implication**: The app needs to distinguish "paper" from "contaminated paper" (pizza box, paper towel) at the first classification layer.

### EU Digital Product Passport (DPP) Material Categories

The ESPR mandates DPPs with machine-readable material composition, starting 2026 (iron/steel) and rolling through 2029. Battery passports mandatory Feb 2027.

**DPP implications for taxonomy**:
- DPP material codes will become an authoritative taxonomy layer
- The app's taxonomy should be compatible with emerging DPP standards
- When a DPP-encoded product is scanned (QR/NFC), the material code is known directly — no visual classification needed
- The app needs a resolver: DPP code → internal material category → regional disposal rule

### How Other Apps Model This

| App | Taxonomy Approach |
|-----|-------------------|
| Recycle Coach | Hierarchical: Location → Item → Instruction. Items tagged with attribute metadata (is_recyclable, has_special_instruction). |
| iRecycle | Flat list of ~350 materials, each with per-location disposal instructions. Simple but doesn't scale to multi-city rules. |
| Scrapp | GTIN/barcode → product lookup → material classification. Uses centralized product database. |

**Best practice**: Hybrid model — hierarchical material taxonomy (Plastic → PET → Bottle) with attribute tagging for edge cases (is_contaminated, has_lid, is_multi_material).

---

## Design Recommendations

### Proposed Taxonomy Structure

```
MaterialFamily (top level)
  ├── Plastic
  │   ├── PET (#1)
  │   ├── HDPE (#2)
  │   ├── PVC (#3)
  │   ├── LDPE (#4)
  │   ├── PP (#5)
  │   ├── PS (#6)
  │   ├── Other (#7)
  │   │   ├── Bioplastic
  │   │   ├── Multi-layer laminate
  │   │   └── Compostable plastic (certified / not certified)
  │   └── Composite plastic
  ├── Glass
  │   ├── Clear (code 70)
  │   ├── Green (code 71)
  │   └── Brown (code 72)
  ├── Paper & Cardboard
  │   ├── Corrugated cardboard (OCC)
  │   ├── Mixed paper
  │   ├── Office paper
  │   └── Contaminated paper
  ├── Metal
  │   ├── Aluminum
  │   ├── Tin/Steel
  │   ├── Copper
  │   └── Mixed metal
  ├── Organic
  │   ├── Food waste
  │   ├── Yard waste
  │   └── Compostable certified
  ├── E-Waste (with WEEE category mapping)
  ├── Hazardous
  │   ├── Batteries (with chemistry sub-type)
  │   ├── Chemicals (paint, solvents, pesticides)
  │   ├── Medical (sharps, pharmaceuticals)
  │   ├── Aerosols / pressurized
  │   └── Light bulbs (CFL/LED)
  ├── Textiles
  └── Special / Other
      ├── Mattresses
      ├── Large appliances
      └── Construction debris
```

### Translation Layer

```
User-facing term → Internal Category ID → Material Code → Regional Rule
      │                    │                     │              │
  "milk jug"         plastic.hdpe.2          RIC #2       Check city(HDPE,
                                                           current location)
```

The translation layer maintains a `canonical_names` table mapping common user terms to Category IDs. Multi-language support at this layer: each term has per-locale synonyms.

### Versioning Strategy

- Taxonomy versions are semver (1.0.0, 1.1.0, 2.0.0)
- New material categories are minor increments (backward-compatible)
- Renaming or removing categories is major (breaking change)
- Each classification result carries `taxonomy_version` in its metadata
- Rules corpus entries reference taxonomy version at time of creation
- Deprecated categories remain in the taxonomy as `SUNSET` with redirects to current equivalent

### Cross-walk Tables

Maintain mapping tables between:
- RIC → MaterialFamily → DisposalRule
- WEEE category → E-waste category → DisposalRule
- GTIN (from barcode) → Product → PackagingMaterial → Category
- EU DPP material code → Internal Category (future)
- User-facing synonyms → Canonical Category ID

### Implementation Path

1. Define the taxonomy as a versioned YAML/JSON file in the repo: `lib/data/recycling_taxonomy.yaml`
2. Create `RecyclingTaxonomy` service that loads and validates the taxonomy
3. Generate Dart types from the taxonomy for type-safe references
4. Map the existing classification output categories to the new taxonomy
5. Add `taxonomyVersion` to `WasteClassification` metadata
6. Create cross-walk resolvers for:
   - RIC code → Disposal rule
   - User-facing term → Category ID (synonym lookup)
   - Barcode GTIN → Material (if product DB available)
7. Wire the taxonomy into `CityPolicyData` so rules reference taxonomy IDs, not hardcoded strings

### Kill Criteria

- If taxonomy maintenance (keeping cross-walk tables current) costs more than the accuracy improvement it enables
- If the taxonomy becomes so complex that it's faster to rely on LLM classification than taxonomy-based routing

---

## Open Questions

- Should the taxonomy be an internal-only tool, or should parts of it be exposed to users (e.g., showing RIC codes on result cards)?
- How should the app handle material claims from manufacturers that may be misleading (e.g., "compostable" plastic that isn't home-compostable)?
- When EU DPP rollout reaches consumer products, should the app prioritise DPP resolver integration over vision-based classification for labelled items?
