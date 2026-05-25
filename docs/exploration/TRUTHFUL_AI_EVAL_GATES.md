# Truthful AI Evaluation Gates and Report Semantics

**Status**: Exploration doc — open research
**Last Updated**: 2026-05-25
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) (P0 #1)
**Related**: [EVAL_HARNESS_AND_GOLDEN_SETS.md](EVAL_HARNESS_AND_GOLDEN_SETS.md) (when created), [SAFETY_CRITICAL_AUTONOMY_RULES.md](SAFETY_CRITICAL_AUTONOMY_RULES.md), [CANONICAL_ROUTER_POLICY.md](CANONICAL_ROUTER_POLICY.md) (when created), [BACKEND_CLASSIFICATION_PROXY.md](BACKEND_CLASSIFICATION_PROXY.md)

---

## Why This Matters

Current eval reports can pass acceptance while offline synthetic scoring shows safety/must-not failures — this must be impossible to misread. Without truthful evaluation semantics, every model upgrade or routing change is a trust gamble.

The goal: build evaluation gates that are **impossible to bypass, impossible to misread, and impossible to ignore**.

---

## Research Summary

### The Problem with Current Eval Semantics

| Anti-Pattern | Why It's Dangerous | Example |
|-------------|-------------------|---------|
| Aggregate-only metrics | Hides per-category failures | 95% overall accuracy masks 40% accuracy on hazardous waste |
| Single "pass/fail" gate | Binary signal loses nuance | Pass = 51% on a 100-case set |
| Self-reported confidence | Model judges its own correctness | "I'm 95% confident" doesn't mean 95% accurate |
| No held-out test set | Model may be overfit to eval cases | Perfect eval, poor production performance |
| No safety-specific tests | Safety failures averaged into general scores | Hazardous misclassification hidden in overall pass rate |

### The "Split-Gate" Architecture

**Core insight**: One eval gate is not enough. The system needs **three independent gates**:

```
┌─────────────────────────────────────────────────────────────────┐
│                    EVAL SUITE PIPELINE                          │
│                                                                 │
│   [Golden Cases] → [Gate 1: Smoke] → [Gate 2: Safety]          │
│                                         ↓                       │
│   [Real Data] → [Gate 3: Production Drift Monitor] → [Verdict] │
│                                                                 │
│   Gate 1 = minimal bar: model responds and parses correctly     │
│   Gate 2 = safety bar: must-not-fail categories pass at 100%    │
│   Gate 3 = statistical bar: production accuracy within bounds   │
└─────────────────────────────────────────────────────────────────┘
```

#### Gate 1: Smoke/Integration Gate

**Purpose**: Verify the model responds, returns parseable output, and doesn't crash.

**Tests**: 10-20 golden cases spanning all major categories. Must pass at 100% for any provider to be considered "deployable."

**Fail behavior**: Block CI/CD. Report exact failure case and error type.

#### Gate 2: Safety Gate (P0)

**Purpose**: Verify that safety-critical categories never fail. This gate is **independent** of the accuracy gate — a model can pass accuracy with 70% but fail safety with a single misclassification.

**Tests**: Minimum 20 golden cases per safety-critical category (battery, medical, sharp, chemical, e-waste, aerosol, hazardous). Plus adversarial cases (battery-like objects, medical-looking packaging).

**Metrics**:
- **Safety recall**: 100% required for safety-critical categories
- **Safety precision**: >95% (false positives waste trust but don't cause harm)
- **Must-not-be-wrong**: Zero tolerance for hazardous → non-hazardous misclassification

**Fail behavior**: Block deployment. Report exact safety failures with images, predictions, and confidence scores. Require explicit human sign-off to override.

#### Gate 3: Production Drift Monitor

**Purpose**: Detect when model quality degrades over time — silent regressions from provider model changes, prompt drift, or distribution shift.

**Mechanism**: Continuous eval on production traffic:
1. Sample N classifications per day (stratified by category)
2. Human reviewers verify a subset
3. Track accuracy, confidence calibration, and per-category performance over time
4. Alert when any metric drops below threshold

**Alert thresholds**:
- Overall accuracy drop > 5% in 7-day rolling window
- Any safety-critical category recall < 98%
- Average confidence calibration error > 10%
- Provider disagreement rate > 15%

### Report Semantics: Preventing False Confidence

Reports must be designed to induce **healthy skepticism**:

#### Anti-Pattern: Single Accuracy Percentage ❌
> "Model X achieves 95% accuracy on the golden set"

#### Pattern: Confidence-Interval Breakdown ✅
> "Model X on golden set (n=200): overall 95% (±3%). Per-category: Plastic: 97% (±2%), Hazardous: 88% (±5%), Organic: 94% (±3%). Safety-critical pass rate: 100% (n=40). 3 categories below 90% threshold: Hazardous (88%), E-waste (86%), Medical (82%) — flagged for review."

#### Required Report Sections

1. **Executive Summary** — One-line verdict (PASS / FAIL / CONDITIONAL PASS)
2. **Safety Gate Results** — Must pass at 100%. If not, FAIL.
3. **Per-Category Breakdown** — Accuracy, precision, recall, F1 per category with confidence intervals
4. **Confusion Matrix** — Which categories are confused with which
5. **Adversarial Results** — Performance on intentionally difficult/confusable cases
6. **Confidence Calibration** — Reliability diagram: does 90% confidence mean 90% accuracy?
7. **Provider Comparison** (if multi-provider) — Per-category win/loss/tie
8. **Failure Cases** — Links to specific failing examples with images
9. **Coverage Gaps** — Which categories/conditions have insufficient test data
10. **Trend View** — Performance over last N eval runs (detect drift)

#### Required Report Semantics

| Concept | Current (Dangerous) | Required (Truthful) |
|---------|-------------------|-------------------|
| Pass/fail | Single binary | Split: smoke | safety | accuracy |
| Confidence intervals | None | 95% CI for all metrics |
| Safety metrics | Averaged in overall | Independent gate, 100% required |
| Coverage gaps | Not reported | Explicitly reported as untested cases |
| Drift detection | None | Rolling 7-day trend line |
| Human override | Not tracked | Logged and reported |
| Failure examples | Not linked | Links to specific cases |

### Canonical Router Policy (Shared Eval/Runtime)

The same policy object that controls runtime routing must also drive eval simulation:

```yaml
# runtime_policy.yaml — single source of truth
version: "1.2"
updated: "2026-05-25"

safety_critical:
  always_escalate: [battery, medical_waste, sharp, chemical_hazardous, aerosol, asbestos]
  high_risk: [e_waste, hazardous_waste, flammable, corrosive]

confidence_thresholds:
  layer0_pass: 0.90
  layer1_pass: 0.75
  layer2_pass: 0.60
  safety_critical_min: 0.95
  manual_review: 0.80

escalation:
  on_provider_disagreement: escalate_to_manual
  on_safety_below_threshold: escalate_to_cloud
  on_parse_failure: retry_with_provider

eval_gates:
  smoke:
    min_cases: 10
    pass_threshold: 1.0
  safety:
    min_cases_per_category: 20
    pass_threshold: 1.0
  accuracy:
    min_cases: 200
    pass_threshold: 0.85
    per_category_min: 0.75
```

**Enforcement**: Eval tooling reads this policy to determine:
- Which categories are safety-critical (must never fail)
- What confidence thresholds apply to each layer
- What conditions trigger escalation
- What pass/fail criteria apply to each gate

---

## Implementation Considerations

### Eval Pipeline Architecture

```
[Golden Cases JSONL] → [Eval Runner] → [Provider/Model API] → [Results JSONL] → [Report Generator]
                                  ↑                                     ↓
                          [Policy YAML]                        [Human Review UI]
                                  ↓
                          [Gate Verdict]
```

### CI/CD Integration

- Smoke gate: runs on every PR (2-3 min)
- Safety gate: runs on every PR but slower (5-10 min)
- Full eval: runs on merge to main (15-30 min)
- Production drift: runs daily, alerts on dev Slack

### Human Override Protocol

When a safety gate fails but deployment is urgent:
1. Override must be logged with named approver
2. Override has expiration (max 48 hours)
3. Expired override = blocked deployment
4. Override history reported in next eval run

---

## Code Anchors

- `tool/ai_eval_runner.dart` — existing eval runner (needs gate separation)
- `docs/review/AI_FLYWHEEL_COMPLETION_ASSESSMENT_AND_NEXT_P0S_2026-05-23.md` — source of this requirement
- `test/fixtures/ai_eval/golden_cases.jsonl` — existing golden set (needs safety-specific cases)
- `lib/services/classification_router_guardrails.dart` — first-pass routing guardrails

---

## Open Questions

1. Who owns the golden set? How do we add/update cases responsibly?
2. Should safety gate failures auto-create P0 issues in the tracker?
3. How do we handle provider-specific safety issues? (E.g., Gemini passes safety but OpenAI doesn't)
4. Should there be a "watch list" mode where a non-blocking eval alert is raised for known-limitation categories?
5. How do we version policy changes — is every policy change its own eval run?

---

## What Could Kill This

- Eval pipeline adds 10+ minutes to CI → developers work around it
- Safety gate failures are always overridden → gate loses meaning
- Golden set becomes stale → eval accuracy diverges from production
- No dedicated owner for eval infrastructure → gates rot

---

## Next Steps

1. Split existing eval runner into three independent gates (smoke, safety, accuracy)
2. Create minimum 20 safety-specific golden cases per hazard category
3. Implement shared policy YAML format
4. Wire eval pipeline to read policy for gate configuration
5. Build report template with required semantic sections
6. Add drift monitoring to production pipeline
7. Implement human override protocol with logging and expiration
