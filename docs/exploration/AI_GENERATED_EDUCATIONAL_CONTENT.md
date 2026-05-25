# AI-Generated Educational Content

**Purpose**: Explore the trade-offs between AI-generated, curated, and hybrid educational content for waste classification education.
**Status**: Exploration — `educational_content_service.dart` exists; no governance policy
**Last Updated**: 2026-05-25
**Related**: [KNOWLEDGE_VERIFICATION_QUIZ.md](KNOWLEDGE_VERIFICATION_QUIZ.md), [HABIT_FORMATION_LOOP.md](HABIT_FORMATION_LOOP.md), [AI_COST_TELEMETRY_AND_GUARDRAILS.md](AI_COST_TELEMETRY_AND_GUARDRAILS.md)

---

## Problem Statement

The app can generate educational content on demand (via LLM) or curate a fixed library. These are fundamentally different operating models with different cost, quality, freshness, and IP profiles. Today the app uses a hybrid approach without a clear governance policy.

---

## Content Model Comparison

| Dimension | Generated (AI) | Curated (Human) | Hybrid (Recommended) |
|-----------|---------------|-----------------|---------------------|
| **Scalability** | Infinite — any item, any language | Fixed library, slow to expand | High — AI drafts, human approves |
| **Accuracy** | Variable — hallucinations possible | High — human-vetted | High — AI in safe boundary |
| **Freshness** | Always current | Needs manual update | AI drafts updates, human approves |
| **Cost** | Variable (token-based) | Fixed (one-time creation) | Lower variable, some fixed |
| **Multilingual** | Native generation (risk: inconsistent across languages) | Translate source (consistent) | Generate in EN, translate (consistent) |
| **Personalization** | Per-user, per-context | One-size-fits-all | Hybrid — core static + AI personalization |

---

## Architecture

```
[Classification Result]
    ↓
[Educational Content Service]
    ↓              ↓
[Cache Layer]    [RAG Pipeline]
(Material+Lang)   (Curated DB + LLM)
    ↓              ↓
[Fallback] ← [Safety Moderation]
    ↓
[User-Facing Content Card]
```

### Caching Strategy

- **Request-response cache**: Keyed by (material, category, language, user_level)
- **Semantic cache**: Vector embeddings for similar queries — reuse past answers for semantically similar items
- **Prompt/context cache**: Gemini API context caching reduces input token costs for repeated system instructions

### Content Moderation Pipeline

1. **Input guardrails**: Sanitize user queries, prevent prompt injection
2. **Output moderation**: Secondary judge model or rule-based filters for misinformation, safety
3. **Human sampling**: Random X% of AI-generated content reviewed by moderator
4. **Kill switch**: Remote config flip disables AI generation, falls back to curated library

---

## Multilingual Strategy

**Recommendation**: Generate in English (ground-truth language), translate to target languages using validated MT engine.

This ensures factual consistency across all languages — native generation risks different facts per language due to training data variation.

---

## Key Decisions Needed

1. **Generation trigger**: Generate on every classification, or pre-generate and cache popular items?
2. **Moderation depth**: Safety-critical content (hazardous, medical) vs standard content (plastic, paper) — different moderation tiers?
3. **Source citation**: Should AI-generated content always cite sources? Which style?
4. **Fallback when generation fails**: Show curated content, offline copy, or nothing?

---

## Open Questions

- Does LLM-generated content match the app's educational voice and reading level consistently?
- How do we handle content liability — if AI-generated advice is wrong, who is responsible?
- Should users be told whether content is AI-generated vs curated?

---

## Next Steps

1. Design educational content cache schema
2. Implement RAG pipeline with curated knowledge base
3. Build content moderation pipeline (judge model + human sampling)
4. Define fallback hierarchy: Cached → Generated → Curated → Static
