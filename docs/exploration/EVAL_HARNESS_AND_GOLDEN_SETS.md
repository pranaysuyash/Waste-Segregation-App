# Eval Harness & Golden Sets

**Decision it unblocks**: Whether a model version, prompt change, or routing update improves or regresses classification quality before it reaches users.

**Key questions**:
- What is the minimum golden set size and category coverage to trust eval results?
- How do golden candidates flow from the review pipeline into the eval harness?
- When does an eval run block a deployment vs merely report?
- How are live adapters wired without exposing API keys in the eval script?

**Kill criteria**: If golden set cannot reach 200+ high-certainty cases within 3 months of review pipeline operating, the eval harness is underpowered for regression detection.

**Status**: IMPLEMENTED (offline) / SEED (live adapters) — 2026-05-22

**Links**:
- [Master index: Eval Harness & Golden Sets](../EXPLORATION_TOPICS.md#5-eval-harness--golden-sets-)
- [Implementation packet](../review/AI_EVAL_HARNESS_IMPLEMENTATION_PACKET_2026-05-21.md) — full implementation details
- [Training Data Annotation Tool](./TRAINING_DATA_ANNOTATION_TOOL.md) — golden candidate review pipeline
- [Multi-Model AI Stack](../exploration/MULTI_MODEL_AI_STACK.md) — how eval fits the wider model fleet
- [Model Contracts](../exploration/MULTI_MODEL_AI_STACK_CONTRACTS.md) — eval contracts per model lane
- [Data & Consent Readiness](../exploration/MULTI_MODEL_AI_STACK_DATA_AND_CONSENT_READINESS.md) — golden_eval_pool concept
- [Continuous Learning Loop (Frontier F3)](../EXPLORATION_FRONTIER.md#f3-continuous-learning-loop-from-user-corrections)

---

## 1. What Exists

An offline eval harness is implemented and running:

| Component | Status | Location |
|-----------|--------|----------|
| Eval runner (Python) | **Live** — offline mode | `scripts/eval/run_classification_eval.py` |
| Golden cases v1 | **Seeded** — 36 cases across 6 categories | `eval/classification/golden/golden_cases_v1.jsonl` |
| Fixture predictions | **Seeded** — 144 rows (36×4 providers) | `eval/classification/fixtures/provider_outputs_v1.jsonl` |
| Offline report | **Generated** — router_v1 tops at 94.44% | `eval/classification/reports/eval_report_offline_v1.json` |
| Feedback export | **Live** — privacy-scrubbed JSONL export | `scripts/eval/export_feedback_candidates.py` |
| Provider adapters | **Scaffolded** — LiveAdapterNotImplemented stub | In `run_classification_eval.py` |

The implementation packet at `docs/review/AI_EVAL_HARNESS_IMPLEMENTATION_PACKET_2026-05-21.md` covers all details of the current implementation.

## 2. Architecture

```
                      ┌──────────────────┐
                      │  Golden cases     │
                      │  (golden_cases_   │
                      │   v1.jsonl)       │
                      └────────┬─────────┘
                               │ expected labels
                               ▼
┌────────────┐     ┌──────────────────────┐     ┌──────────────┐
│ Fixtures   │────▶│  Eval Runner         │────▶│ JSON Report  │
│ (JSONL)    │     │  (offline/recorded/  │     │ + scores     │
│            │     │   live)              │     │ + failures   │
├────────────┤     └──────────────────────┘     └──────────────┘
│ Live       │
│ adapters   │     Metrics per provider:
│ (stub)     │     - strict pass rate
└────────────┘     - acceptable pass rate
                   - must-not violations
                   - safety-critical failures
                   - high-confidence wrong
                   - latency avg/p50/p90
                   - cost total/avg
                   - composite score + rank
```

### Lanes

| Lane | Today | Tomorrow |
|------|-------|----------|
| `openai` | Fixture predictions | Wired to `classifyImage` callable |
| `gemini` | Fixture predictions | Wired to callable (already in fallback) |
| `local_small` | Fixture predictions | Wired to `LocalClassifier` |
| `router_v1` | Fixture predictions | Wired to pipeline route decision |

## 3. Golden Set Strategy

### Growth plan via annotation tool

```
┌──────────────────┐     ┌────────────────┐     ┌──────────────┐
│ Training review  │────▶│ Golden labeled │────▶│ Eval harness │
│ pipeline         │     │ candidates     │     │ manifest     │
│ (admin tool)     │     │ (review.status │     │ (eval.jsonl) │
│                  │     │  == 'golden')  │     │              │
└──────────────────┘     └────────────────┘     └──────────────┘
```

The `buildTrainingDatasetManifest` function generates an `eval.jsonl` from golden candidates — this IS the golden set input for the eval harness.

### Coverage targets

| Version | Count | Categories | Source | Status |
|---------|-------|------------|--------|--------|
| v1 | 36 | 6 (6 each) | Synthetic + field | Seeded |
| v2 | 100 | 6+ | Review pipeline golden labels | Pending |
| v3 | 200 | 8+ (add e-waste, reuse) | Review pipeline | 3-month target |
| v4 | 500 | 12+ | Review pipeline | 6-month target |

### Category schema

Fixed set used by both harness and annotation tool:
- `Wet`, `Dry`, `Hazardous`, `Medical`, `Non-Waste`
- Extended: `E-Waste`, `Reusable` (forthcoming)

Each case includes: `expected.category`, `expected.itemName`, `expected.material`, `acceptable_categories` (lenient match), `must_not_categories` (safety violation), and `safety.safety_critical` flag.

## 4. Scoring Model

| Metric | Weight | Description |
|--------|--------|-------------|
| Strict pass | Primary | expected.category matches exactly |
| Acceptable pass | Secondary | category in acceptable_categories |
| Must-not violation | Hard fail | category in must_not_categories |
| Safety-critical failure | Hard fail | safety_critical case where category is wrong |
| High-confidence wrong | Penalty | confidence > 0.9 but prediction wrong |
| Latency | Informational | p50/p90 ms |
| Cost | Informational | avg cost per prediction |

**Gate policy** (not yet wired to CI):
- `must_not_violations > 0` → BLOCK
- `safety_failures > 0` → BLOCK
- `strict_pass_rate < 0.80` → WARN
- `strict_pass_rate < 0.70` → BLOCK

## 5. Remaining Work

| Item | Status | Effort |
|------|--------|--------|
| Wire live adapter for `classifyImage` callable | TODO | 1 day |
| Wire live adapter for `LocalClassifier` | TODO | 1 day |
| Build `eval.jsonl` from golden candidates via manifest export | Pending annotation tool | 1 day |
| CI gate: run eval on golden set before deploy | TODO | 0.5 day |
| CI gate: block on must_not / safety failures | TODO | 0.5 day |
| Add `E-Waste` and `Reusable` to expected category set | TODO | 0.5 day |
| Grow golden set from 36 → 200+ via review pipeline | Ongoing | Ongoing |
| Add prompt/version fields to provider output contract | TODO | 0.5 day |

## 6. Relationship to Annotation Tool

```
Training candidate enqueued (enqueueTrainingCandidate)
       │
       ▼
Reviewer approves → 'approved'
       │
       ├── Reviewer marks 'golden' → dataset.eligible = true, eval-ready
       │       │
       │       ▼
       │   buildTrainingDatasetManifest({ version })
       │       │
       │       ▼
       │   eval/classification/golden/golden_cases_v2.jsonl
       │       │
       │       ▼
       │   run_classification_eval.py --mode offline --golden ...
       │
       └── Reviewer marks 'training_eligible' → dataset.eligible = true
               │
               ▼
           buildTrainingDatasetManifest → train.jsonl (training set)
```

Golden candidates flow from the annotation tool directly into the eval harness manifest. There is no separate golden-ingestion step — the `review.status == 'golden'` flag IS the eval set membership signal.
