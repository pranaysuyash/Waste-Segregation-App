# Disposal Reasoning Stage

**Purpose**: Explore separating disposal advice (where does this go?) from visual classification (what is this material?) as distinct reasoning stages.
**Status**: Exploration — currently coupled; needs separation design
**Last Updated**: 2026-05-25
**Related**: [REGION_RULES_AND_CITY_EXPANSION_MAP.md](REGION_RULES_AND_CITY_EXPANSION_MAP.md), [CLASSIFICATION_CONFIDENCE.md](CLASSIFICATION_CONFIDENCE.md), [SAFETY_CRITICAL_AUTONOMY_RULES.md](SAFETY_CRITICAL_AUTONOMY_RULES.md)

---

## Problem Statement

Today, classification ("this is plastic") and disposal advice ("put it in the blue bin") are coupled in the same prompt and model call. This creates several problems:

1. **Brittle regional logic**: The same plastic film is recyclable in Bangalore (BBMP) but not in Mumbai (BMC). Changing a region's rules requires prompt changes and re-deployment.
2. **No audit trail**: When disposal advice is wrong, we can't tell if it was a classification error, a rules error, or a reasoning error.
3. **Hard to localise**: Each new city needs its own prompt customisation, not just a new rules entry.
4. **Can't version independently**: Updating the rules corpus shouldn't require model re-inference on the image.

---

## Research Summary

### Why Separate Classification from Disposal Reasoning

| Aspect | Coupled (Current) | Separated (Target) |
|--------|-------------------|-------------------|
| Regional change | Requires prompt/model update | Requires rules corpus update only |
| Audit trace | Single opaque call | Classification + Rules Version + Reasoning trace |
| Error isolation | Any failure = full retry | Can retry reasoning alone (cheaper) |
| Explainability | Black box | "I identified X, and per [city] rule Y, it goes in bin Z" |
| Cost | Full vision call per classification | Text-only RAG for disposal (cheaper) |

### RAG-Based Disposal Reasoning

The ideal architecture uses Retrieval-Augmented Generation:

1. **Classification output**: `{material: "plastic", category: "film", confidence: 0.92}`
2. **Region lookup**: Resolve user's location → city rules pack
3. **Vector search**: Query rules corpus with material + category + region
4. **LLM synthesis**: Generate disposal advice grounded in retrieved rules
5. **Provenance**: Attach `rule_pack_version`, `retrieved_sources`, `reasoning_steps`

This approach:
- Avoids hallucination by constraining the LLM to retrieved context
- Makes rules updates independent of model releases
- Enables versioned audit trails per classification

### Regulatory Hierarchy Model

Disposal rules follow a nested override pattern:

```
Tier 1: National/Federal     (EPA RCRA, safety standards)
Tier 2: State/Provincial     (Recycling mandates, diversion goals)
Tier 3: Local/Municipal      (Actual disposal stream — which bin)
Tier 4: Society/Apartment    (Override: e.g., "building doesn't have compost")
```

**Override logic**: Lower tier always wins. If city rule exists for item X, use it regardless of state/federal. If society override exists, use it regardless of city.

---

## Architecture Design

```
[Image] → Vision Model → {material, category, confidence, attributes}
                              ↓
                    [Classification Record]
                    (versioned, with model ID)
                              ↓
                    [Disposal Reasoning Service]
                    ↓          ↓          ↓
              Region Rules   Material    Attributes
              Corpus (RAG)   Taxonomy    (hazardous?, 
                    ↓          ↓          clean?)
                    [LLM Synthesis]
                    ↓
              {disposal_instruction,
               bin_color, 
               special_handling,
               alternative_paths,
               rule_provenance}
```

---

## Key Decisions Needed

1. **Model selection**: Should disposal reasoning use the same LLM as classification, or a cheaper text-only model?
2. **Rules corpus format**: Structured (JSON rules) vs unstructured (PDFs + vector search) vs hybrid?
3. **Caching**: Can we cache disposal results per (material + city) — 95% hit rate expected?
4. **Fallback when rules corpus doesn't cover city**: Show generic advice with disclaimer, or block?

---

## Open Questions

- When should the app re-process historical classifications with updated rules?
- How do we handle the case where the user corrects the classification after disposal advice was already shown?
- Should the reasoning stage also accept user-provided attributes ("this bottle is crushed", "this is greasy pizza box")?

---

## Next Steps

1. Design the disposal reasoning service interface
2. Prototype RAG pipeline with existing city rules packs
3. Estimate cache hit rate from classification history
4. Design disposal provenance schema (versioned, auditable)
