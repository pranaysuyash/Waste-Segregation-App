# Canonical Runtime Router Policy — Exploration Note

**Date**: 2026-05-24  
**Status**: Exploration / no-code audit  
**Parent context**: AI learning flywheel foundation, truthful eval gates  
**Scope**: Identify whether runtime routing, guardrails, eval tooling, and recommendation docs share one policy source.  
**Non-goal**: No code changes in this pass.

## Why this matters

The app is moving from “call one AI provider” to a layered routing system: deterministic local checks, local/on-device inference, cheap cloud, strong cloud, reviewer escalation, and future continuous learning. That only works if runtime routing and eval tooling use the same policy vocabulary.

A router policy split is dangerous: the app might accept a local result while the eval harness would have blocked it, or the eval harness might recommend a route the runtime cannot actually enforce.

## Evidence reviewed

- `docs/exploration/TRUTHFUL_AI_EVAL_GATES_2026-05-24.md` — prior no-code finding: eval is L1 recorded regression, not provider readiness.
- `docs/exploration/MULTI_MODEL_AI_ROUTING.md` — target routing architecture and status.
- `docs/exploration/MULTI_MODEL_AI_STACK_CONTRACTS.md` — route/escalation model contract.
- `lib/services/classification_router.dart` — strategy and confidence-based routing controller.
- `lib/services/classification_router_guardrails.dart` — local/cloud acceptance guardrails.
- `lib/services/ai_router_policy_config.dart` — Remote Config policy pack shape and defaults.
- `lib/ai_flywheel/router_policy_recommendations.dart` — textual recommendations from policy pack.
- `lib/providers/classification_pipeline_providers.dart` — policy config is loaded from Remote Config and used to build guardrails.
- `test/ai_flywheel/flywheel_foundation_test.dart` — tests for guardrails, provider quality gate, policy recommendation text.

## What exists now

### Runtime policy pieces

| Piece | Location | Behavior |
|---|---|---|
| Strategy enum | `lib/services/classification_router.dart` | `costFirst`, `qualityFirst`, `latencyFirst`, `balanced` |
| Confidence router | `lib/services/classification_router.dart` | Calibrates raw confidence and chooses target layer |
| Local/cloud guardrails | `lib/services/classification_router_guardrails.dart` | Accept/escalate local and cloud results based on thresholds and safety categories |
| Remote policy pack | `lib/services/ai_router_policy_config.dart` | Holds threshold defaults and Remote Config parsing |
| Recommendation text | `lib/ai_flywheel/router_policy_recommendations.dart` | Generates Markdown-style recommendations from a policy pack |
| Provider quality gate | `lib/ai_flywheel/provider_quality_gate.dart` | Fails summaries with safety/must-not/local-rule issues |

### Current default policy

`AiRouterPolicyConfig.defaults` defines:

```text
policyPackVersion: router-policy-v1
localAcceptanceThreshold: 0.85
localEscalationThreshold: 0.70
localSafetyThreshold: 0.97
blockCacheOnRuleVersionChange: true
enforceSafetyEscalation: true
```

`ClassificationRouterGuardrails.alwaysEscalateCategories` includes:

```text
Chemical / Chemical Waste
E-Waste / Electronic Waste
Hazardous Waste
Medical / Medical Waste
Pharmaceutical / Pharmaceutical Waste
Sharps
```

`ClassificationRouterGuardrails.manualReviewCategories` includes:

```text
Unknown
Requires Manual Review
```

### Eval/tooling pieces

The eval side has scoring and gates, including:

- must-not violation detection,
- safety-critical failure detection,
- local-rule overclaim detection,
- multi-item failure detection,
- provider quality gate tests that fail on safety/must-not violations.

This is directionally aligned with runtime guardrails, but not yet a single shared policy object.

## Main discovery: there are policy components, but no canonical router policy contract yet

The project has several good building blocks. The missing piece is a **single canonical policy schema** that can be used by:

1. runtime routing,
2. eval report generation,
3. provider quality gates,
4. CI gates,
5. router recommendation docs,
6. Remote Config rollout,
7. future scheduled drift monitoring.

Today, the policy is partly split across:

- `AiRouterPolicyConfig` thresholds,
- `ClassificationRouter` layer thresholds and strategy behavior,
- `ClassificationRouterGuardrails` safety categories,
- eval scoring rules,
- docs in `MULTI_MODEL_AI_ROUTING.md`,
- report/recommendation generators.

That split is manageable now, but it will drift as soon as live provider gating, local model gating, and Remote Config A/B tests start moving independently.

## Policy gaps to close before runtime promotion

### 1. Layer thresholds are duplicated conceptually

`ClassificationRouter` hardcodes layer thresholds:

```text
L0: 0.90
L1: 0.75
L2: 0.60
L3: 0.00
```

`AiRouterPolicyConfig` separately defines local thresholds:

```text
localAcceptanceThreshold: 0.85
localEscalationThreshold: 0.70
localSafetyThreshold: 0.97
```

These are not necessarily contradictory, but they are two vocabularies. Future agents could tune one and forget the other.

### 2. Safety category taxonomy appears in multiple places

Docs use broader conceptual categories such as Hazardous, Medical, E-Waste, policy risk, safety-critical. Runtime guardrails use display strings. Eval golden cases use `safety.safety_critical` and `must_not_categories`.

A canonical policy should normalize these into stable category IDs, then map UI strings/provider labels into those IDs.

### 3. Router recommendation is text-only

`buildRouterStrategyRecommendations()` produces useful Markdown, but it is not enforceable. Recommendation output should eventually include a machine-readable section like:

```json
{
  "policyPackVersion": "router-policy-v1",
  "allowedRoutes": ["local", "small_cloud", "large_cloud"],
  "blockedRoutes": [{"route": "local", "reason": "safety_category"}],
  "requiresReview": true
}
```

Text is good for humans; machines need a contract.

### 4. Eval readiness and router policy are not joined yet

The truthful-eval-gates pass found that offline eval is currently L1 recorded regression. Router recommendations should be gated by eval readiness level. Example:

- L1 can recommend only “do not regress fixtures.”
- L3 can recommend provider promotion for non-safety cases.
- L4 can recommend runtime router policy promotion.

### 5. Cache/rule freshness needs end-to-end policy semantics

`blockCacheOnRuleVersionChange` exists and guardrails can reject cloud/cache use when rules change. The wider policy still needs to define:

- what counts as a local-rule version change,
- how policy packs are versioned,
- whether old classifications are shown with a stale-policy banner,
- whether stale cached classifications can earn gamification/reputation rewards,
- whether stale results can enter training/eval candidates.

## Recommended canonical policy shape

When coding is allowed, create or evolve toward one policy object with this shape:

```json
{
  "policyPackVersion": "router-policy-v1",
  "readinessMinimums": {
    "localRoutePromotion": "L4_RUNTIME_ROUTER_GATE",
    "providerPromotion": "L3_LIVE_SAFETY_GATE",
    "fixtureRegressionOnly": "L1_RECORDED_REGRESSION"
  },
  "thresholds": {
    "layer0Accept": 0.90,
    "layer1Accept": 0.75,
    "layer2Accept": 0.60,
    "localAccept": 0.85,
    "localEscalateBelow": 0.70,
    "localSafetyAccept": 0.97
  },
  "safety": {
    "alwaysEscalateCategoryIds": [
      "hazardous",
      "medical",
      "e_waste",
      "chemical",
      "sharps",
      "pharmaceutical"
    ],
    "manualReviewCategoryIds": ["unknown", "requires_manual_review"],
    "mustNotViolationsBlockPromotion": true,
    "safetyFailuresBlockPromotion": true
  },
  "freshness": {
    "blockCacheOnRuleVersionChange": true,
    "stalePolicyResultCanEarnRewards": false,
    "stalePolicyResultCanEnterTraining": false
  },
  "telemetry": {
    "requiredFields": [
      "policyPackVersion",
      "route",
      "rawConfidence",
      "calibratedConfidence",
      "categoryId",
      "regionCode",
      "policyPackId",
      "decisionReason"
    ]
  }
}
```

## Recommended next implementation task, when coding is allowed

**Task**: unify runtime/eval router policy semantics without changing behavior.

Smallest safe implementation:

1. Extend `AiRouterPolicyConfig` to include canonical layer thresholds, safety category IDs, and readiness minimums.
2. Make `ClassificationRouter` and `ClassificationRouterGuardrails` derive thresholds/categories from the same config.
3. Make eval reports include the policy pack version and readiness level used for scoring.
4. Make router recommendations emit both Markdown and JSON-ready policy decisions.
5. Add tests that prove eval safety blockers and runtime safety guardrails agree on the same safety categories.

This is a long-term-path change because it does not add a parallel router. It consolidates the existing router, guardrails, eval gates, and docs around one source of truth.

## Open questions

1. Should local safety acceptance ever be allowed for E-Waste/Medical/Hazardous, even at 0.97 confidence, or should those categories always require cloud/reviewer verification for launch?
2. Should policy use display strings (`Hazardous Waste`) or stable IDs (`hazardous`) at the runtime boundary? I strongly prefer stable IDs with mapper functions.
3. Should Remote Config be allowed to lower safety thresholds, or only raise/tighten them unless a signed policy pack is deployed?
4. Should stale local-rule classifications be blocked from gamification points, token rewards, and training candidates by default?
5. Should provider disagreement automatically trigger a user clarification question, reviewer queue entry, or both?

## Exploration verdict

Proceed with a canonical router policy object before any runtime promotion. The current pieces are strong enough for scaffolding and tests, but not yet strong enough to govern live routing, eval gates, and Remote Config safely at scale.

## Missed-anything sweep

- **Instruction compliance**: No code was changed; this is a repo-local documentation artifact as requested.
- **Canonical paths**: No duplicate router or eval pipeline proposed. The recommended path extends `AiRouterPolicyConfig`, `ClassificationRouter`, `ClassificationRouterGuardrails`, and the existing eval report path.
- **End-to-end flow checked**: Remote Config policy → guardrails/router → classification pipeline → eval scoring → recommendation/reporting.
- **User value**: Safer classifications, fewer wrong local acceptances, clearer offline/cloud escalation behavior.
- **Business/team value**: One policy pack can govern cost, safety, and rollout decisions instead of relying on scattered thresholds.
- **Operational value**: Future agents can tune policy without accidentally diverging runtime and eval behavior.
- **Unclosed gaps**: No canonical policy schema exists yet; current readiness labels are still only documented, not machine-enforced.
- **Confidence**: High confidence in the drift risk because the policy thresholds/categories were verified directly in code. Not claiming runtime behavior is fully wired because this was a no-code audit and no app flow was executed.
