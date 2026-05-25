# Transparency Log & Model Cards

**Status**: Exploration — pre-design
**Priority**: P2 (🟡)
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) — Topic #61
**Related docs**: `MODEL_REGISTRY_AND_VERSIONING.md`, `EVAL_LEADERBOARD_AND_MODEL_CARDS.md`, `AI_DRIFT_MONITORING.md`

---

## Why This Matters

A transparency log serves three distinct constituencies:

1. **Users**: "Why did the answer change?" — visible when the app updates a model or ruleset.
2. **Developers**: "What changed between versions?" — debugging accuracy regressions.
3. **Regulators**: "What was the system doing on date X?" — audit trail for compliance.

Model cards (model, prompt, ruleset version cards) document what each version of the AI pipeline was, what it was trained on, and how it performed. They're increasingly a regulatory expectation under the EU AI Act and similar frameworks.

---

## Key Questions

- What should a transparency log contain for a waste classification app?
- How do we present version changes without undermining user trust?
- Should the log be public (viewable by any user) or internal only?
- How do we track prompt changes alongside model version changes?
- What's the minimum viable logging until regulatory requirements crystalize?

---

## Research Findings

### 1. Transparency Log Components

A complete transparency record per model/prompt/ruleset deployment:

**Model version record**:
| Field | Example | Source |
|---|---|---|
| Version ID | `v2.3.1-2026-06-01` | Semver + date |
| Provider | `OpenAI` | Router config |
| Provider model ID | `gpt-4o-2026-05-15` | Provider release notes |
| Deployed date | `2026-06-01T10:00Z` | Deployment pipeline |
| Rollout % | `100%` | Remote config |
| Eval accuracy (overall) | `92.3%` | Eval harness |
| Eval accuracy (hazardous) | `97.1%` | Eval harness (subset) |
| Eval golden set version | `gs-2026-05-30` | Golden set registry |
| Prompt version | `pv-2026-05-25-a` | Prompt registry |
| City ruleset version | `rv-2026-05-20` | Ruleset registry |
| Rolled out by | `automated-ci` | Deployment trigger |
| Rolled back from | — | Rollback history |

**Prompt version record**:
| Field | Example |
|---|---|
| Version ID | `pv-2026-05-25-a` |
| Prompt hash | `sha256:abc123` |
| Prompt change summary | "Added explicit hazardous override instruction" |
| Eval diff (vs previous) | +1.2% hazardous accuracy, -0.3% overall |
| Review status | `approved` |
| Validator | `code-reviewer` |
| Deployed with model | `v2.3.1` |

### 2. How to Surface Version Changes

Three-tier visibility model:

**Tier 1: What's New (all users — optional notification)**
- Shown after a model/ruleset update.
- Brief, non-technical: "We updated our recycling rules for Bengaluru — dry waste rules have changed."
- See also: `CITY_RULES_CHANGE_SINCE_LAST_VISIT`.

**Tier 2: Changelog (Settings > About > Changelog)**
- Full version history of model deployments, prompt changes, ruleset updates.
- Technical enough for developers and privacy-conscious users.
- Includes eval score diffs for transparency.

**Tier 3: Raw data (API endpoint / downloadable JSON)**
- Machine-readable version record for auditors, regulators, researchers.
- Includes full metadata, rollback history, known limitations.
- Queryable by date range, version, provider, ruleset.

### 3. Versioning Strategy

**Models**: Provider version string (e.g., `gpt-4o-2026-05-15`) + app-side major.minor version tracking.

**Prompts**: Git-based, stored as Markdown templates in a `prompts/` directory in the repository.
- Each prompt change is a PR with diff review.
- Prompt version = commit hash + tag.

**Rulesets**: Firestore document per city with version field.
- Changes are append-only — old versions remain queryable.
- Ruleset version = date + incremental integer.

**Router policies**: YAML file in repository, versioned with the app.
- Evaluated before deployment via eval harness comparison.

### 4. Eval Score Presentation

Presenting accuracy scores in a transparency log requires framing:

```
┌─────────────────────────────────────┐
│ Model v2.3.1 (OpenAI gpt-4o)       │
│ Deployed: 2026-06-01                │
│                                     │
│ Accuracy vs previous version:       │
│ ✓ Hazardous items: 97.1% (+2.1%)   │
│ ✓ Organic waste: 94.5% (+0.8%)     │
│ ⚠ Plastic bottles: 91.2% (-0.5%)   │
│                                     │
│ Known limitations:                  │
│ • Mixed-material items (tetrapak)   │
│ • Very small items (< 1cm)          │
│ • Items with degraded labels        │
│                                     │
│ [Full model card ▸]                  │
└─────────────────────────────────────┘
```

**Presentation rules**:
- Don't show absolute accuracy without context (what test set?).
- Better to show "accuracy vs previous version" with direction arrows.
- Known limitations are not admissions of failure — they're calibration aids.
- Never compare accuracy between providers without stating the test set and conditions.

### 5. Legal Considerations

- Publishing a model card with accuracy claims creates a liability surface if the product is later sued over a misclassification.
- **Mitigation**: Always frame accuracy as "measured against our internal test set under controlled conditions" — never as 'product accuracy guarantee.'
- Transparency log should include a disclaimer stating the AI is an assistant, not a certified authority.
- The log itself should be reviewed by legal before first publication.

---

## Design Patterns

### Pattern 1: What's New Card
```
┌───────────────────────────────────────┐
│ 🎉 What's New in Waste Segregation    │
│                                       │
│ Bengaluru recycling rules updated!    │
│ → Dry waste: bubble wrap now accepted │
│ → Hazardous: new drop-off location    │
│                                       │
│ Model updated: Better at identifying  │
│ plastic types (+2% accuracy)          │
│                                       │
│ [See all changes] [Got it]            │
└───────────────────────────────────────┘
```

### Pattern 2: Changelog Screen
```
┌───────────────────────────────────────┐
│ Transparency Log                [Filter]│
│                                       │
│ ── Today ──                           │
│ Model v2.3.1 deployed — hazardous     │
│ accuracy improved to 97.1%            │
│                                       │
│ ── 3 days ago ──                      │
│ BBMP rules updated (v2026-05-28)      │
│ Prompt v2026-05-25 rolled out         │
│                                       │
│ ── 1 week ago ──                      │
│ Model v2.3.0 deployed                 │
│ New city: Delhi (MCD) ruleset         │
│                                       │
│ [Full details ▸]                       │
└───────────────────────────────────────┘
```

### Pattern 3: Model Card (Detailed)
```
┌───────────────────────────────────────┐
│ Model Card: v2.3.1                    │
│                                       │
│ Provider    │ OpenAI gpt-4o-2026-05-15│
│ Prompt      │ pv-2026-05-25-a        │
│ Ruleset     │ rv-2026-05-20 (7 cities)│
│ Eval set    │ gs-2026-05-30 (110 cases)│
│                                       │
│ Accuracy by category:                 │
│ ┌─────────────────────────────────┐   │
│ │ Plastic     ■■■■■■■■■□ 91%     │   │
│ │ Paper       ■■■■■■■■■■ 95%     │   │
│ │ Glass       ■■■■■■■■■□ 89%     │   │
│ │ Metal       ■■■■■■■■■■ 94%     │   │
│ │ Organic     ■■■■■■■■■□ 88%     │   │
│ │ E-waste     ■■■■■■■■■□ 87%     │   │
│ │ Hazardous   ■■■■■■■■■■ 97%     │   │
│ │ Medical     ■■■■■■■■■■ 96%     │   │
│ └─────────────────────────────────┘   │
│                                       │
│ Known limitations:                     │
│ • Multi-material items                │
│ • Poor lighting / motion blur         │
│ • Non-standard packaging              │
│                                       │
│ [Download JSON] [Share]               │
└───────────────────────────────────────┘
```

---

## Anti-Patterns

| Anti-Pattern | Why |
|---|---|
| Publishing accuracy without test set context | Misleading — different test sets give different scores |
| Hiding accuracy regressions | Users will notice quality changes — better to explain than be caught hiding |
| Version numbering that skips | Erodes trust — every version should be accounted for |
| Over-promising capabilities | "96% accurate on hazardous" sounds better than the reality of controlled conditions |
| No rollback information | Hides instability — users should see if a version was rolled back and why |

---

## Open Questions

1. Should the transparency log be public (visible to all users) or require authentication?
2. Do we need a machine-readable transparency endpoint for automated compliance reporting?
3. How granular should the log be — per-model-change or per-user-facing-change?
4. Should prompt changes be listed alongside model changes, or in a separate section?
5. Who approves changes for the transparency log — CI pipeline or human?

---

## Next Steps

1. Design changelog screen and add to Settings > About.
2. Implement version tracking for each deployment (model, prompt, ruleset).
3. Create "What's New" notification card triggered after version change.
4. Write first model card for current production stack.
5. Research EU AI Act transparency requirements for consumer AI classification.
