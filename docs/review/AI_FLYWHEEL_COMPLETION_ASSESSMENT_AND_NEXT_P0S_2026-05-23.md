# AI Flywheel Completion Assessment + Next P0s

Date: 2026-05-23  
Mode: exploration / assessment / recommendation, not implementation  
Instruction basis: `motto_v2.md`, `goal1.txt`, prior thread `T-019e4f1e-03ee-7041-8f84-a22980a1169b`

## Executive verdict

The AI learning flywheel foundation is **code-ready at scaffold/foundation level**, but it is **not yet model-quality-ready or runtime-decision-ready**.

What is genuinely done:

- Eval dataset schema and 110 seed cases exist.
- Offline/recorded eval runner exists and is reproducible.
- Safety, must-not, local-rule, confidence, multi-item, cost, latency, fallback, and provider metrics are represented.
- Consent-gated training candidate flow exists on client and backend.
- Dataset export excludes revoked/deleted/rejected/unreviewed/stale/no-consent records.
- Review workflow exists both as CLI/JSONL workflow and as a callable-backed admin/developer queue.
- A one-shot verifier passes and emits evidence artifacts.

What is **not** done:

- Offline mode currently uses synthetic fallback predictions and intentionally fails 30/110 cases; that is useful as a scorer smoke test but misleading if treated as product quality.
- Recorded provider snapshots are fixtures, not proof of live provider quality.
- The local model path is still a stub / recommendation target, not production inference.
- Router strategy recommendations are generated as docs/artifacts, but app runtime does not enforce these eval-derived thresholds as a canonical policy.
- Admin review UX is usable as a developer/admin scaffold, not a full operator-grade annotation dashboard.

My opinion: the next move should **not** be “train a model” and should **not** be “add more eval cases” as busywork. The highest leverage is to convert this foundation into a truthful product gate: make eval reports unambiguous, then wire router threshold policy into runtime behavior behind safe flags.

---

## Current-state evidence

### Verification run

Command:

```bash
./tools/verify_ai_flywheel_foundation.sh
```

Result: **pass**.

Key output:

- `flutter test test/ai_flywheel/flywheel_foundation_test.dart`: 12/12 pass
- Offline eval: 110 cases, 80 strict pass, 30 fail, 14 safety-critical failures, 30 must-not violations, 11 local-rule failures
- Recorded backend eval: 110 strict pass, 0 fail
- Recorded OpenAI eval: 110 strict pass, 0 fail
- Recorded Gemini eval: 110 strict pass, 0 fail
- Recorded local stub eval: 98 strict pass, 5 acceptable pass, 7 fail, 7 safety-critical failures
- Seed coverage: 9/9 rules pass
- Acceptance report: 12/12 pass, `allPassed=true`

Primary artifacts:

- `build/reports/ai_flywheel/acceptance_report.json`
- `build/reports/ai_flywheel/FINAL_EVIDENCE_SUMMARY.md`
- `build/reports/ai_eval/offline_latest.json`
- `build/reports/ai_eval/recorded_backend_latest.json`
- `build/reports/ai_eval/recorded_openai_latest.json`
- `build/reports/ai_eval/recorded_gemini_latest.json`
- `build/reports/ai_eval/recorded_local_latest.json`
- `build/reports/ai_eval/router_compare_backend.json`
- `build/reports/ai_eval/router_strategy_recommendations.md`
- `build/reports/ai_eval/seed_coverage_report.json`

### Code/docs inspected

- `goal1.txt`
- `motto_v2.md`
- `docs/review/AI_LEARNING_FLYWHEEL_COMPLETION_AUDIT_2026-05-23.md`
- `docs/review/AI_LEARNING_FLYWHEEL_EXPANSION.md`
- `docs/review/AI_FLYWHEEL_RUNTIME_VERIFICATION.md`
- `tools/verify_ai_flywheel_foundation.sh`
- `tool/ai_eval_runner.dart`
- `tool/ai_flywheel_acceptance_report.dart`
- `tool/router_compare_report.dart`
- `lib/ai_flywheel/eval_runner.dart`
- `lib/ai_flywheel/eval_scoring.dart`
- `lib/ai_flywheel/router_metrics.dart`
- `lib/services/providers/local_vlm_provider.dart`
- `lib/services/providers/backend_proxy_provider.dart`
- `lib/services/model_selection_service.dart`
- `lib/services/result_pipeline.dart`
- `lib/services/training_data_service.dart`
- `functions/src/training_data.ts`
- `lib/screens/training_review_queue_screen.dart`

---

## Acceptance criteria status

| Area | Status | Evidence | Notes |
|---|---:|---|---|
| Golden eval schema | ✅ Done | `test/fixtures/ai_eval/schema.md`, `lib/ai_flywheel/eval_models.dart` | Structured enough for current scaffold. |
| Seed dataset | ✅ Done | `test/fixtures/ai_eval/golden_cases.jsonl` | 110 rows; coverage report passes 9/9 rules. |
| Offline runner | ✅ Done / ⚠️ semantic risk | `lib/ai_flywheel/eval_runner.dart` | It runs without API keys, but fallback predictions create expected failures. Needs clearer “scorer smoke test” framing. |
| Recorded provider eval | ✅ Done | `test/fixtures/ai_eval/recorded_outputs/*.jsonl` | Fixture quality, not live proof. |
| Live eval guard | ✅ Done | `AI_EVAL_ENABLE_LIVE=true` gate | Correctly disabled by default. |
| Safety/must-not scoring | ✅ Done | `lib/ai_flywheel/eval_scoring.dart` | Useful dimensions exist. |
| Consent-gated candidate creation | ✅ Done | `lib/services/training_data_service.dart`, `functions/src/training_data.ts` | Client and backend gates exist. |
| Review workflow | ✅ Done / 🟡 operator-light | `tool/ai_review_workflow.dart`, `TrainingReviewQueueScreen` | Good for internal use; not full annotation platform. |
| Dataset export/versioning | ✅ Done | `tool/ai_dataset_exporter.dart`, backend manifest builder | Exclusion counters exist. |
| Router metrics | ✅ Done | `lib/ai_flywheel/router_metrics.dart`, `tool/router_compare_report.dart` | Report exists; runtime enforcement not canonical yet. |
| Runtime router threshold enforcement | ❌ Not done | Search across runtime services | `ModelSelectionService` has confidence fallback, but not eval-derived safety/local-rule router policy. |
| Real local VLM / segmentation | ❌ Not done | `LocalVlmProvider` throws `UnimplementedError` | Stub only. |

---

## Gap analysis

### P0-A — Eval report semantics are ambiguous

The same verifier says acceptance is 12/12 while the offline eval snapshot contains:

- 30 failures
- 14 safety-critical failures
- 30 must-not violations
- 11 local-rule failures

This is not contradictory in code terms: `offline` uses fallback/synthetic predictions when no recorded file is present. But it is dangerous in product terms because a future agent or human may read “verification passed” and miss that “offline_latest.json” is not a quality result.

**Why it matters**: this project needs the eval system to be the truth layer. A truth layer cannot have ambiguous pass semantics.

**Recommendation**: split report semantics into two explicit classes:

1. `offline_scorer_smoke` — expected to include synthetic failures and validate scorer behavior.
2. `provider_quality_eval` — real recorded/live provider outputs with thresholds and go/no-go criteria.

Acceptance should continue validating harness existence, but product-quality gates should be separate and fail if safety/must-not violations exceed thresholds.

### P0-B — Router recommendations are not runtime policy

`build/reports/ai_eval/router_strategy_recommendations.md` recommends:

- local only when confidence >= 0.85 and not safety-critical
- batteries/medical/e-waste always escalate until local safety-critical fail rate < 1%
- backend escalation when local confidence < 0.70
- ask clarification + enqueue review on safety disagreement
- avoid cache reuse when local-rule version changes

Runtime code has partial routing concepts (`ModelSelectionService`, `BackendProxyProvider`, result metadata), but I did not find a canonical eval-derived router policy object that app/runtime uses as the single source of truth.

**Why it matters**: without runtime enforcement, router reports are advisory. Advisory evals do not reduce production risk.

**Recommendation**: next implementation should introduce a canonical `ClassificationRoutingPolicy` / `AiRouterPolicy` used by both eval/report tools and runtime routing. Do not create a parallel router. Extend the current provider/model selection path.

### P0-C — Local model path must remain blocked from safety-critical autonomy

`LocalVlmProvider` is explicitly not bundled and throws `UnimplementedError`. Recorded local fixture still shows:

- 7 failures
- 7 safety-critical failures
- many underconfident correct cases

**Why it matters**: the local/on-device path is valuable for cost and privacy, but unsafe if it can answer high-risk categories alone.

**Recommendation**: local inference should be allowed only for low-risk, high-confidence, non-local-rule-critical cases until real local evals demonstrate <1% safety-critical fail rate. Safety-critical categories should force backend or human clarification.

### P0-D — Training data review exists, but operator readiness is still thin

There is more than CLI-only support: `TrainingReviewQueueScreen` and callable-backed queue functions exist. However the UX is still developer/admin scaffold, not a full annotation tool.

**Why it matters**: model training quality depends on reliable reviewer labels. Bad annotation UX creates bad ground truth.

**Recommendation**: do not build a giant dashboard yet. First build a reviewer-critical path checklist: queue filters, image preview/redaction state, model prediction vs user correction vs reviewer truth, approve/reject/delete, audit trail, and export preview.

### P1 — Seed dataset breadth is acceptable but still partly placeholder-heavy

Coverage passes and 110 cases exist, but many cases are named `placeholder_edge_*`. That is fine for scaffold completion; it is not enough for true quality claims.

**Recommendation**: after P0-A/P0-B, replace placeholders with reviewed real-world cases from consented corrections and known municipal/local-rule edge cases.

---

## Recommended next work order

### 1. Make eval gates truthful and non-ambiguous

Deliverable:

- Rename or document offline mode as scorer smoke mode.
- Add separate quality threshold report for recorded/live providers.
- Gate product-quality pass on safety/must-not/local-rule thresholds, not merely artifact existence.

Acceptance:

- A reader can tell in one glance whether the harness works vs whether a provider/model is safe.
- `acceptance_report.json` no longer appears to bless offline synthetic failures as product readiness.

### 2. Canonicalize router policy and wire runtime to it

Deliverable:

- One router policy source of truth used by eval tooling and runtime classification route decisions.
- Safety-critical and local-rule-critical cases escalate by policy.
- Local/on-device can only answer low-risk high-confidence cases.
- Disagreement/uncertainty creates review candidates where consent permits.

Acceptance:

- Runtime behavior matches `router_strategy_recommendations.md` or the recommendations become generated from the same policy object.
- Tests cover batteries/medical/e-waste, low-confidence local, stale local-rule cache, provider disagreement, and consent-gated review enqueue.

### 3. Harden annotation/review operator path

Deliverable:

- Minimal operator-ready training review flow, not a full admin suite.
- The screen must show enough information to prevent accidental bad labels.

Acceptance:

- Reviewer can distinguish model prediction, user correction, and verified ground truth.
- `golden` / `training_eligible` cannot be assigned without verified category and privacy/redaction pass.
- Audit trail remains complete.

### 4. Resume backend-authoritative AI batch flow only after policy gate is clear

The prior thread named this as a remaining next step. It should come after eval/router semantics are clear; otherwise the refactor can accidentally preserve unsafe fallback behavior.

Acceptance:

- Backend classification remains authoritative for paid/cloud calls.
- Client direct AI paths are disabled or explicitly dev-only in release.
- Token spend/refund, cache semantics, and route metadata remain auditable.

---

## 11-dimension audit

| Dimension | Verdict | Finding |
|---|---:|---|
| Code | ✅ | Verifier and focused tests pass. |
| Operational | 🟡 | Review queue exists, but annotation UX is not yet operator-grade. |
| User Experience | 🟡 | End-user behavior is not improved by scaffold alone; value appears after runtime policy and safer routing. |
| Logical Consistency | 🟡 | Acceptance pass vs offline failures is semantically ambiguous. |
| Commercial | 🟡 | Foundation enables cheaper routing and training moat, but no direct monetization lift until runtime/router integration. |
| Data Integrity | ✅/🟡 | Consent and exclusion rules exist; image/PII review remains scaffolded. |
| Quality & Reliability | 🟡 | Harness reliable; model quality not proven by live eval. |
| Compliance | 🟡 | Consent/revocation exist; need stronger operator evidence for PII/redaction review. |
| Operational Readiness | 🟡 | CLI + developer screen enough for internal use, not launch operations. |
| Critical Path | ✅ | Clear next P0: truth gates → runtime router policy → review UX. |
| Final Verdict | 🟡 | Foundation-ready, not launch-ready as an AI quality system. |

---

## Final recommendation

Proceed, but with discipline:

1. **Do not train yet.**
2. **Do not let local/on-device answer safety-critical waste yet.**
3. **Do not claim model quality from scaffold acceptance.**
4. **Do convert router recommendations into runtime policy next.**
5. **Do keep the backend as the authoritative cloud AI path while the eval/router truth layer matures.**

Confidence: high for scaffold completion and identified gaps because it is backed by current verifier output and code inspection. Not 100% for live provider quality because live eval was intentionally not run and no external provider calls were made.

---

## Proposed waste-classification routing policy

This section captures the recommended product architecture for local/cloud/fallback routing. This should have been documented immediately with the assessment because it is the practical decision the flywheel work is meant to unlock.

### Core principle

Local inference is for **speed, privacy, and cost reduction**. Cloud inference is for **authority and safety**. Fallback is for **graceful degradation after failure**. The review loop is for **learning and improving future routing**.

Do not treat “local first” as “local is allowed to answer everything first.” That is wrong for waste classification because some categories are safety-critical and policy-sensitive. Local should perform cheap preflight and answer only low-risk, high-confidence cases until eval evidence proves otherwise.

### Recommended flow

```text
Capture
  ↓
Local preflight
  - image quality
  - likely PII / face / document risk
  - obvious non-waste
  - simple material/category hints
  - multi-item / clutter signal
  ↓
Risk gate
  ├─ Critical / uncertain / local-rule-sensitive → Cloud authoritative classify
  ├─ Simple + high-confidence + low-risk → Local provisional classify
  └─ Ambiguous / multi-item / low-confidence → Cloud classify
  ↓
Policy/disposal layer
  - category normalization
  - local disposal rules
  - region-specific instructions
  - safety warnings
  ↓
User correction / feedback
  ↓
Consent-gated training candidate
  ↓
Reviewer verification → golden/training-eligible dataset
```

### Routing vs fallback

Keep these separate:

| Concept | Meaning | Example |
|---|---|---|
| Routing | Planned decision before classification | “This looks safety-critical, send to cloud.” |
| Escalation | Planned upgrade because confidence/risk requires authority | “Local sees possible battery at 0.62 confidence, escalate to backend.” |
| Fallback | Recovery after a failure | “Cloud timed out, return safe generic critical-warning state.” |
| Review enqueue | Learning path after disagreement/uncertainty | “Provider disagreement on safety category; enqueue candidate if consent allows.” |

Fallback results must be labeled as fallback and carry lower trust. A fallback should never silently masquerade as an authoritative classification.

### Local may answer only low-risk, high-confidence cases

Local/on-device classification can return a user-visible result only when all of these hold:

- confidence >= `0.85`
- single obvious item
- not safety-critical
- not local-rule-critical
- no PII/redaction risk
- no provider/policy disagreement
- category is one of the safe/common families below

Allowed local-answer families:

- clean plastic bottle
- clean cardboard / clean paper
- banana peel or obvious food waste
- intact glass bottle / jar
- obvious dry waste with no contamination risk
- obvious reject waste where no safer disposal path is needed

Even then, local result should be marked internally as `local_provisional` unless and until the app has live eval evidence proving production-grade local safety.

### Cloud must handle critical categories

Cloud/backend authoritative classification is mandatory for:

- batteries
- swollen batteries
- power banks
- e-waste
- chargers / cables when disposal route matters
- medicine strips
- expired medicine bottles
- sanitary waste
- medical masks when infection/biohazard context matters
- syringes / sharps
- broken glass
- aerosol cans
- paint / chemical containers
- pesticide / toxic containers
- anything with fire, toxicity, biohazard, injury, or regulatory risk
- multi-item images containing any critical item
- any case where local rules determine the disposal answer

If cloud fails on a critical case, do **not** confidently answer with local. Show a safe fallback state:

> “Treat this as potentially hazardous. Do not place it in regular bins. Keep it separate, avoid direct handling, and retry or consult local disposal guidance.”

### Cloud should also handle ambiguity

Cloud should handle:

- low local confidence (`< 0.70`)
- medium confidence in non-trivial cases (`0.70–0.85`)
- multi-item or cluttered photos
- contaminated recyclables
- compostable-looking plastics
- paper cups with plastic lining
- greasy pizza boxes
- mixed wet/dry/reject waste
- unknown region with specific local-rule claims
- user hints that conflict with visual prediction

### Runtime metadata required

Every classification should retain route metadata for audit, eval, and cost control:

```text
routeDecision: local_provisional | cloud_authoritative | cloud_escalated | safe_fallback | user_clarification
routeReason: high_confidence_low_risk | safety_critical | local_rule_critical | low_confidence | multi_item | provider_disagreement | provider_failure
rawConfidence
calibratedConfidence
riskGate
localRuleVersion
provider
model
fallbackUsed
fallbackReason
cacheHit
estimatedCostUsd
latencyMs
```

This metadata should flow into history, analytics, training candidates, and eval exports. Without it, the flywheel cannot explain why a model/router decision was better or worse.

### Suggested threshold policy v1

| Case type | Local threshold | Decision |
|---|---:|---|
| Low-risk obvious single item | >= 0.85 | Local provisional result allowed |
| Low-risk but medium confidence | 0.70–0.85 | Cloud classify unless user explicitly chose offline/cost-save mode |
| Low confidence | < 0.70 | Cloud classify |
| Safety-critical | any | Cloud authoritative classify |
| Local-rule-critical | any | Cloud + policy layer authoritative classify |
| Multi-item | any | Cloud classify until segmentation/local multi-item eval is proven |
| Provider disagreement on safety | any | Ask clarification + enqueue review if consent allows |
| Cloud failure on non-critical | any | Safe fallback + retry affordance |
| Cloud failure on critical | any | Hazard-safe fallback, no confident category unless already verified |

### Product stance

The app should feel fast, but never casual about dangerous waste. The right user promise is:

> “Fast when obvious, careful when it matters.”

That is better than a blanket “local-first” claim because it aligns with real waste-disposal stakes: wrong answers for plastic bottles are annoying; wrong answers for batteries, sharps, chemicals, or medicine are unsafe.

### Implementation implication for next P0

The next implementation should introduce a canonical router policy used by both runtime and eval tooling. Do not create a second router. Extend the existing provider/model-selection path so `router_strategy_recommendations.md` and runtime behavior are generated from, or validated against, the same policy.

Minimum acceptance for that implementation:

- tests for each mandatory cloud category
- tests for low-risk high-confidence local allowance
- tests for local low-confidence escalation
- tests for critical cloud failure safe fallback
- tests that fallback results are labeled and not treated as authoritative
- tests that route metadata is persisted into training candidates
