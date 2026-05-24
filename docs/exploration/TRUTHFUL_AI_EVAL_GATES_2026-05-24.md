# Truthful AI Eval Gates — Exploration Note

**Date**: 2026-05-24  
**Status**: Exploration / no-code audit  
**Parent context**: AI learning flywheel foundation  
**Scope**: Identify what was implemented, how it behaves, and where eval reporting can be misread.  
**Non-goal**: No code changes in this pass.

## Why this matters

The AI learning flywheel now has the right foundation pieces: golden cases, recorded provider outputs, an offline runner, CI regression checks, training candidate review, and dataset-manifest concepts. The next risk is not absence of tooling; it is **truth labeling**. A smoke pass over recorded outputs must not be interpreted as proof that a live provider, router, or local model is safe for production routing.

The current system is useful, but its output needs stronger readiness semantics.

## Evidence reviewed

- `goal1.txt` — original AI learning flywheel task and acceptance shape.
- `eval/classification/README.md` — current harness entrypoint and command contract.
- `scripts/eval/run_classification_eval.py` — runner modes, report shape, live/fixture behavior.
- `docs/exploration/EVAL_HARNESS_AND_GOLDEN_SETS.md` — architecture, gate strategy, status.
- `docs/exploration/TRAINING_DATA_ANNOTATION_TOOL.md` — golden/training/review state model.
- `.github/workflows/ci.yml` — current CI eval gate.
- Probe command: `python3 scripts/eval/run_classification_eval.py --mode offline --golden eval/classification/golden/golden_cases_v1.jsonl --fixtures eval/classification/fixtures/provider_outputs_v1.jsonl --output /tmp/waste_eval_probe.json`.

## What exists now

### Eval harness

The canonical eval harness lives under `eval/classification/` with:

- `eval/classification/golden/golden_cases_v1.jsonl` — 36 seed cases.
- `eval/classification/fixtures/provider_outputs_v1.jsonl` — recorded/fixture outputs.
- `scripts/eval/run_classification_eval.py` — offline, recorded, and live modes.
- `eval/classification/reports/` — generated reports.

The runner scores providers on:

- strict pass rate,
- acceptable pass rate,
- must-not violations,
- safety-critical failures,
- high-confidence wrong predictions,
- latency,
- cost,
- composite score,
- per-category accuracy.

### CI gate

`.github/workflows/ci.yml` runs the offline harness and blocks only if:

- the harness itself emits errors,
- no providers are evaluated,
- best strict pass rate regresses by more than 5 points from the router_v1 baseline.

It prints safety failures and must-not violations, but does not block on them yet.

### Annotation pipeline relationship

`docs/exploration/TRAINING_DATA_ANNOTATION_TOOL.md` defines the intended path from consented classification → candidate → reviewer state → golden/training eligibility → dataset manifest.

Important contract:

- raw user corrections are not truth,
- `review.status == 'golden'` is eval-set membership,
- `dataset.eligible == true` is training-set membership,
- golden implies training-eligible,
- rejected, revoked, deleted, and unreviewed data must not enter manifests.

## Probe result

The offline probe completed with no runner errors:

```text
mode: offline
golden_cases: 36
providers_evaluated: 4
errors: 0
top_rank: router_v1 / openai_then_gemini_then_local
strict_pass_rate: 0.9444
safety_failures: 1
must_not_violations: 2
routing_recommendation: review_required
```

Provider ranking from the generated report:

| Rank | Provider | Strict pass | Safety failures | Must-not violations |
|---:|---|---:|---:|---:|
| 1 | `router_v1` | 0.9444 | 1 | 2 |
| 2 | `gemini` | 0.7778 | 2 | 6 |
| 3 | `openai` | 0.8333 | 4 | 5 |
| 4 | `local_small` | 0.5278 | 7 | 10 |

The runner correctly emits `review_required` for the top-ranked provider because it still has safety failures.

## Key discovery: current eval is a harness/regression check, not provider readiness

The current offline eval answers this question:

> Given the checked-in golden set and checked-in fixture outputs, did the scoring harness and fixture baseline regress?

It does **not** answer these questions:

- Is the live OpenAI path safe today?
- Is the live Gemini fallback safe today?
- Is `router_v1` safe to promote for runtime routing?
- Is local/on-device inference ready?
- Did model confidence calibrate correctly against current providers?
- Are safety-critical and must-not cases acceptable for deployment?

That distinction exists in prose across docs, but it is not encoded strongly enough in the machine-readable report or CI naming.

## Caveats and risks

### 1. Offline mode report can be over-trusted

The report has `mode: offline`, but it does not include explicit fields like:

- `readiness_level: harness_smoke_only`,
- `uses_live_provider_calls: false`,
- `uses_fixture_predictions: true`,
- `production_readiness: not_assessed`,
- `safety_gate_status: failed_warn_only`.

A downstream dashboard, agent, or human could see `strict_pass_rate: 0.9444` and infer model quality. That inference would be wrong.

### 2. `recorded` mode is an alias of offline

`recorded` is useful for CI language clarity, but behaviorally it currently calls the same path as `offline`. If the label is used in reports without an explicit fixture/live distinction, it may sound more empirical than it is.

### 3. Safety failures are visible but not blocking

The docs say safety/must-not violations are WARN until golden v2. The CI implementation follows that. This is reasonable for a seed set, but any production-routing decision must treat safety failures as a hard stop.

### 4. Live adapters are partially misleading

The runner has live adapter classes, but `RouterV1Adapter` and `LocalSmallAdapter` return expected answers in live mode. That is useful scaffolding, but dangerous if someone treats a live run as a full live-runtime comparison before those adapters are real.

### 5. Golden v1 is too small for model-quality claims

36 cases are enough for smoke/regression scaffolding. They are not enough for confident routing policy changes, model selection, or safety sign-off. Existing docs target 100, 200, and 500 case growth; that remains the right path.

## Recommended truth model

Adopt explicit eval readiness levels:

| Level | Name | Meaning | Allowed decisions |
|---:|---|---|---|
| L0 | Schema smoke | Golden/fixture files parse; scoring runs | Harness health only |
| L1 | Recorded regression | Checked-in fixtures preserve baseline | Detect accidental scoring/fixture regressions |
| L2 | Live provider spot check | Real backend/provider calls against real images | Catch provider/API drift, not enough for routing changes |
| L3 | Live safety gate | Real images, safety/must-not cases, no critical failures | Block/promote safety-sensitive provider changes |
| L4 | Runtime router gate | Live provider + router + calibration + telemetry agreement | Runtime routing policy promotion |
| L5 | Continuous production monitor | Scheduled eval + correction feedback + drift alerts | Ongoing threshold/routing governance |

Current state is mostly **L1**, with design intent for L2-L5.

## Recommended next implementation task, when coding is allowed

**Task**: Add machine-readable truth labels to eval reports and CI output.

Minimum fields:

```json
{
  "readiness_level": "L1_RECORDED_REGRESSION",
  "production_readiness": "not_assessed",
  "uses_fixture_predictions": true,
  "uses_live_provider_calls": false,
  "uses_real_images": false,
  "safety_gate": {
    "status": "warn_only_failed",
    "blocking": false,
    "reason": "golden_v1 seed set; safety failures present"
  },
  "allowed_decisions": [
    "verify harness health",
    "detect fixture regression"
  ],
  "disallowed_decisions": [
    "promote provider",
    "promote router policy",
    "claim model safety",
    "enable local-first routing"
  ]
}
```

Also rename the CI step output from “PASS: No significant regression detected” to something like:

```text
PASS: Offline fixture regression gate passed. Production/model readiness not assessed.
```

## Open questions

1. Should safety failures become blocking before golden v2 if they occur in already-known safety-critical seed cases?
2. Should `live` mode refuse to run router/local adapters until they are real, instead of returning expected answers?
3. Should report consumers require a minimum readiness level before router recommendations are displayed?
4. Should golden v2 be generated only from reviewed candidates, or can manually curated synthetic cases remain in the benchmark with provenance labels?
5. Should CI have two separate jobs: `eval_fixture_regression` and `eval_live_readiness_manual`?

## Missed-anything sweep

- **Instruction compliance**: This was a no-code exploration pass; repo-local documentation was updated as requested.
- **Canonical paths**: No duplicate eval harness was created. This note points back to `eval/classification/` and `scripts/eval/run_classification_eval.py` as canonical.
- **End-to-end flow checked**: Golden cases → fixture/live predictions → scoring → report → CI gate → annotation manifest path.
- **User value**: Prevents false confidence in AI safety and waste-routing correctness.
- **Business/team value**: Makes model/router promotion decisions auditable and less likely to regress into unsafe claims.
- **Operational value**: Gives future agents and maintainers a clear readiness vocabulary before changing gates.
- **Unclosed gaps**: Machine-readable truth labels are not implemented yet; live router/local adapters still need hardening before readiness claims.
- **Confidence**: High confidence in the documentation-level finding because it is based on direct runner, CI, and docs inspection plus an offline probe. Not claiming production model behavior because no live provider run was performed.
