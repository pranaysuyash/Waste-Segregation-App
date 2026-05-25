# Disassembly Guidance for Multi-Material Objects

**Status**: Exploration | P2 | Advanced Classification Modalities
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) — Entry 55
**Last Updated**: 2026-05-25

---

## Why This Matters

Many household waste items are multi-material — a plastic bottle with a metal spring, a coffee pod with plastic + aluminium + organic waste, an electronic toy with embedded battery. In their composite state, these items are "non-recyclable" and contaminate whichever stream they enter. Telling users how to separate components before disposal is the difference between landfill and recyclable.

---

## Common Multi-Material Items

| Item | Components | Separation Required? | Difficulty |
|------|-----------|---------------------|------------|
| Plastic bottle + cap + label | PET/HDPE body + PP cap + paper/plastic label | Preferred (cap + label separate) | Easy — twist off, peel |
| Beverage carton (Tetra Pak) | Paper + aluminium + plastic | No — MRF separates | N/A |
| Coffee pod | Plastic/aluminium + coffee grounds + filter | Yes — organic must be removed | Easy — open, empty |
| Electronic toy | Plastic + electronics + battery | Yes — battery ALWAYS must be removed | Moderate — screwdriver |
| Spray can / aerosol | Metal + pressurised contents + plastic cap | Cap: yes. Contents: never puncture | Easy (cap) + critical warning |
| Candle jar | Glass + wax + metal wick | Yes — wax must be removed | Moderate — hot water |
| Pringles can | Cardboard + metal + foil liner | Complex — components can be manually separated | Moderate — separate parts |
| Blister pack | Plastic shell + foil backing | No — MRF typically can't separate | N/A |
| E-waste with battery | Device + lithium battery | Yes — fire risk in recycling stream | Varies — critical safety |

---

## Disassembly Complexity Scale

| Level | Description | Time | Tools Required | Example |
|-------|-------------|------|----------------|---------|
| 1 | Twist/pull apart | < 5 seconds | None | Bottle cap, spray cap |
| 2 | Peel/tear off | < 10 seconds | Fingernail | Paper label |
| 3 | Open and empty | < 30 seconds | None | Empty food container |
| 4 | Screwdriver required | 1–2 minutes | Phillips/flathead | Battery compartment |
| 5 | Cut/snap apart | 1–5 minutes | Scissors, tool | Separating glued parts |
| 6 | "Bring to facility" | — | Specialised | Welded components, pressurised |

**Rule of thumb**: If disassembly takes > 2 minutes or requires tools the average household doesn't have, recommend "bring to facility" instead.

---

## UX: Step-by-Step Disassembly Flow

```
┌─────────────────────────────────────────────┐
│  This item has 3 parts to separate:         │
│                                             │
│  Step 1: Twist off the spray cap            │
│  [Image/gif of twisting off cap]            │
│  → Put cap in: ⬜ Plastic recycling         │
│                                             │
│  Step 2: Open and empty remaining liquid    │
│  [Image/gif of pouring out]                 │
│  → Dispose liquid at: 🚰 Sink (if water)    │
│     or ⚠️ Hazardous drop-off (if chemical)  │
│                                             │
│  Step 3: Recycle the metal can              │
│  [Image/gif of placing in bin]              │
│  → Put can in: 🥫 Metal recycling           │
│                                             │
│  ⚠️ CRITICAL: NEVER puncture the can        │
└─────────────────────────────────────────────┘
```

**Design principles**:

1. **Show, don't tell** — use images/animations over text walls
2. **Progressive disclosure** — show one step at a time; next step appears after completion tap
3. **Per-part destination** — every separated component needs a bin assignment
4. **Safety warnings INLINE** — next to the step that carries risk, not as a generic banner

---

## Required vs Optional Disassembly

| Label | Meaning | UX |
|-------|---------|-----|
| **Required** | Without separation, item is non-recyclable or dangerous | Red badge — "Must separate before disposal" |
| **Recommended** | Separation improves recyclability but not strictly required | Yellow badge — "Separate for better recycling" |
| **Optional** | Facility can separate; user effort is optional | Grey badge — hidden by default |

---

## Safety-Critical Disassembly Warnings

| Component | Warning | Display |
|-----------|---------|---------|
| Battery | Fire risk if punctured — remove before recycling | Red banner, do-not-puncture icon |
| Pressurised can | Explosion risk — never puncture | Red banner, warning icon |
| Broken glass | Laceration risk | Orange banner, wear gloves |
| Chemical residue | Do not rinse — take to hazardous waste | Red banner, hazardous symbol |
| Sharps | Extreme laceration risk — use tool | Red banner, sharp icon |

---

## Integration: Disposal vs Repair

| | Disassembly for Disposal | Disassembly for Repair |
|--------------------------|--------------------------|----------------------|
| **Goal** | Permanent material separation | Reversible access for fixing |
| **Tone** | "Ready to dispose — here's how" | "Let's fix it — here's how" |
| **Precision** | Low — just separate materials | High — track screw locations |
| **End state** | Parts in different bins | Device functional again |
| **UX colour** | 🌱 Green/blue theme | 🔧 Orange/tool theme |

**Recommendation**: After the initial scan, route to either "Disposal disassembly" or "Repair disassembly" based on user intent. These are related but distinct flows.

---

## Integration Points

| Surface | What to Show |
|---------|-------------|
| Scan result — multi-material item | "This item has 3 parts to separate — see guide" |
| Disposal guidance card | Step-by-step with per-part bin destination |
| History — archived | Save which components went where |
| Repair flow | "Need to fix this instead?" separate link |

---

## Open Questions

1. **Content creation**: Who creates the disassembly guides? AI-generated (risky — safety-critical), curated (costly), or community-sourced (trust)?
2. **Coverage**: How many common multi-material items need guides? 50? 200? 1000?
3. **Modelling disassembly in the pipeline**: Should the classification model output a "multi-material: true/component list" flag that triggers the disassembly guide?
4. **Liability**: If a disassembly instruction causes injury (broken glass, battery fire), does the app bear liability?

---

## Phasing

| Phase | Scope | Key Dependency |
|-------|-------|----------------|
| 0 | Static text-based guides for top-20 multi-material items (curated) | Content creation |
| 1 | Dynamic guide triggered by multi-material detection in pipeline | Classification pipeline — multi-material flag |
| 2 | Visual/image guides (static illustrations) | Illustration asset creation |
| 3 | Community-submitted guides with moderation | UGC pipeline |
| 4 | AI-generated guides with expert review | RAG + content moderation pipeline |
