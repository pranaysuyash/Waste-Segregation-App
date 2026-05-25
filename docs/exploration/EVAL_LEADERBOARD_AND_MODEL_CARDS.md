# Eval Leaderboard & Model Cards

**Status**: Seed — eval harness exists (`tool/ai_eval_runner.dart`, `golden_cases.jsonl`), but no structured leaderboard or model cards
**Priority**: 🟡 (P2 — enables trust in AI stack changes)
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) — P1/P2 Technical Architecture (topic 87)
**Related**: [TRUTHFUL_AI_EVAL_GATES.md](TRUTHFUL_AI_EVAL_GATES.md), [MODEL_REGISTRY_AND_VERSIONING.md](MODEL_REGISTRY_AND_VERSIONING.md), [AI_DRIFT_MONITORING.md](AI_DRIFT_MONITORING.md)

---

## Overview

When the team asks "which model should we use for classification?" or "did this prompt change help?", there must be a single source of truth that answers with data — not opinion. The eval leaderboard provides that.

Model cards (inspired by Google's model cards framework) document each AI path's intended use, performance characteristics, known limitations, and safety assessment.

---

## Eval Leaderboard Design

### Dimensions

| Dimension | Weight | Metrics | Why It Matters |
|-----------|--------|---------|---------------|
| **Accuracy** | High | Top-1 accuracy, top-3 accuracy, F1 per category | Core job: classify correctly |
| **Safety** | Critical | Pass rate on safety-critical categories, hazardous false negative rate | Must not misclassify hazardous as safe |
| **Local Rule** | High | Disposal advice correctness vs city rulesets | Wrong advice erodes trust |
| **Calibration** | Medium | ECE, reliability diagram | Confidence must mean something |
| **Cost** | Medium | Cost per classification, cost per accurate classification | Economics of scale |
| **Latency** | Low-Medium | P50, P95, P99 time to first token | UX perception |

### Leaderboard Table

```
┌──────────────────────────────────────────────────────────────────────────────┐
│  EVAL LEADERBOARD                                   Snapshot: 2026-05-25     │
├──────────────────────────────────────────────────────────────────────────────┤
│  Rank │ Provider+Model    │ Accuracy │ Safety │ Rules │ Cost (¢) │ Latency  │
├───────┼───────────────────┼──────────┼────────┼───────┼──────────┼──────────┤
│  1    │ Gemini Flash 2.0  │  89.4%   │  ✅   │ 91%  │  0.12¢   │  0.8s    │
│  2    │ OpenAI GPT-4o-mini│  91.2%   │  ✅   │ 93%  │  0.45¢   │  1.5s    │
│  3    │ OpenAi GPT-4o     │  93.1%   │  ✅   │ 94%  │  1.20¢   │  2.1s    │
│  4    │ On-device (L1)    │  72.3%   │  ❌   │ 68%  │  0.00¢   │  0.3s    │
│  5    │ Gemini Pro 2.0    │  94.2%   │  ✅   │ 96%  │  2.50¢   │  2.8s    │
├───────┴───────────────────┴──────────┴────────┴───────┴──────────┴──────────┤
│  Safety Gate: ALL entries pass (FAIL = auto-block from production)          │
└──────────────────────────────────────────────────────────────────────────────┘
```

### Per-Category Drilldown

Clicking a provider shows accuracy per waste category:

```
Gemini Flash 2.0 — Per-Category Accuracy
┌──────────────────────┬────────┬──────────┬──────────┐
│ Category             │ Accuracy│ Precision│ Recall   │
├──────────────────────┼────────┼──────────┼──────────┤
│ Plastic bottles      │  96.2% │   95.8%  │  96.5%   │
│ Paper/Cardboard      │  94.1% │   93.7%  │  94.4%   │
│ Glass                │  91.5% │   92.0%  │  91.0%   │
│ Organic/Wet waste    │  88.3% │   87.5%  │  89.0%   │
│ E-waste              │  82.1% │   84.2%  │  80.0%   │ ← Lowest
│ Hazardous            │  97.8% │   98.5%  │  97.0%   │ ← Safest
│ Medical waste        │  95.0% │   96.0%  │  94.0%   │
└──────────────────────┴────────┴──────────┴──────────┘
```

### Safety Gate Visualization

Safety is not a score — it's a gate. Each entry displays:

- **🟢 PASS**: All safety-critical categories meet minimum thresholds
- **🔴 FAIL**: One or more safety-critical categories below threshold

**FAIL = auto-blocked from production rollout**. Cannot be overridden by aggregate accuracy.

**Safety threshold table** (example):
| Critical Category | Min Recall | Min Precision | Min Accuracy |
|-------------------|-----------|--------------|-------------|
| Hazardous (chemical) | 99.0% | 95.0% | 97.0% |
| Medical waste | 98.0% | 95.0% | 96.0% |
| Batteries | 99.5% | 98.0% | 98.0% |
| Sharps | 99.0% | 97.0% | 97.0% |

---

## Model Card Template

Each AI path (provider + model + prompt version) should have a model card stored alongside it in the registry.

```markdown
# Model Card: [Provider] [Model Name] [Version]

## Intended Use
- Primary: Waste material classification from smartphone photos
- Secondary: Disposal advice generation (via ruleset RAG)
- Out of scope: Hazard material identification for regulatory compliance, medical diagnosis

## Performance Summary
- Overall accuracy: XX%
- Safety gate: PASS / FAIL
- ECE (calibration error): XX
- Inference cost: $X.XX per 1k classifications

## Per-Category Performance
[Table — see above]

## Known Limitations
1. [Limitation 1, e.g., "Poor performance on mixed-material items (e.g., greasy pizza box)"]
2. [Limitation 2, e.g., "Struggles with low-light images below 50 lux"]
3. [Limitation 3, e.g., "Confuses clear PET and clear glass in 8% of cases"]

## Safety Assessment
- Hazardous false negative rate: XX%
- Safety-critical recall: XX%
- Known failure modes: [List of known misclassification pairs]

## Training & Evaluation Data
- Training set: [description, size, sources]
- Eval set: [golden set version, size, category distribution]

## Prompt Version
- Prompt ID: [link to registry entry]
- Prompt hash: [SHA256]

## Router Policy
- Escalation rules: [link to policy version]
- Confidence thresholds: Layer 0/X, Layer 1/X, Layer 2/X

## Deployment History
- First deployed: [date]
- Current rollout: [canary/production/retired]
- Rollback count: N
```

---

## Snapshot Versioning

Every leaderboard view is tied to:
1. **Eval dataset hash** (immutable snapshot of golden cases)
2. **Eval runner version** (code used to evaluate)
3. **Timestamp** (when evaluation ran)

These three form a composite key. Any change to the eval dataset or runner produces a new snapshot lineage.

**Use case**: "Show me the leaderboard from last week" should replay the exact same evaluation as it ran then, not re-evaluate with current models.

---

## Implementation Path

1. **Phase 0** (JSON-based): Script that runs golden set through all providers, outputs JSON. Manual review.
2. **Phase 1** (dashboard): Simple web dashboard showing the leaderboard table. CI posts snapshot to Slack on every eval run.
3. **Phase 2** (model cards): Auto-generate model cards from eval results + registry metadata. Store alongside models.
4. **Phase 3** (CI gate): Safety gate must pass before deployment. Leaderboard snapshot attached to every release artifact.

---

## Open Questions

- Should the leaderboard be publicly accessible (transparency) or internal only (competitive)?
- How do we handle "regression debt" — when a new model is better overall but worse on one category?
- Should we weight categories by frequency in production (weighted accuracy) or treat all categories equally (unweighted)?
- What is the minimum safety gate threshold before a provider can serve ANY production traffic?
