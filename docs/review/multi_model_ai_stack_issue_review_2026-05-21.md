# Multi-Model AI Stack Issue Review

Date: 2026-05-21  
Repo: `/Users/pranay/Projects/LLM/image/waste_seg/waste_segregation_app`  
Scope: Exploration + execution packet for the long-term model stack lane

## 1) Summary

The app should not treat waste classification as a single-model problem. The correct long-term shape is a model stack that handles:

- capture quality / privacy gating,
- object detection / segmentation,
- waste/material classification,
- region-aware disposal policy,
- user correction capture,
- eval + dataset admission,
- route selection across local, cloud, and review paths.

This packet converts that direction into a concrete execution artifact.

## 2) Source docs

- [docs/EXPLORATION_TOPICS.md](/Users/pranay/Projects/LLM/image/waste_seg/waste_segregation_app/docs/EXPLORATION_TOPICS.md)
- [docs/exploration/MULTI_MODEL_AI_STACK.md](/Users/pranay/Projects/LLM/image/waste_seg/waste_segregation_app/docs/exploration/MULTI_MODEL_AI_STACK.md)
- [docs/exploration/MULTI_MODEL_AI_STACK_CONTRACTS.md](/Users/pranay/Projects/LLM/image/waste_seg/waste_segregation_app/docs/exploration/MULTI_MODEL_AI_STACK_CONTRACTS.md)
- [docs/exploration/MULTI_MODEL_AI_STACK_PHASE1_EXECUTION.md](/Users/pranay/Projects/LLM/image/waste_seg/waste_segregation_app/docs/exploration/MULTI_MODEL_AI_STACK_PHASE1_EXECUTION.md)
- [docs/exploration/MULTI_MODEL_AI_STACK_DATA_AND_CONSENT_READINESS.md](/Users/pranay/Projects/LLM/image/waste_seg/waste_segregation_app/docs/exploration/MULTI_MODEL_AI_STACK_DATA_AND_CONSENT_READINESS.md)

## 3) Owners

### Product / Exploration owner
- Owns the product framing, sequencing, and acceptance gates.
- Keeps this lane aligned with the broader app roadmap and user-visible outcomes.

### ML / Vision owner
- Owns model boundaries, telemetry contracts, routing policy, and evaluation definitions.
- Decides what is deterministic policy versus probabilistic prediction.

### Platform / Backend owner
- Owns data storage, routing events, consent metadata, redaction, and auditability.
- Ensures model outputs flow through one canonical event envelope.

### Privacy / Trust owner
- Owns PII rejection rules, reuse consent, data minimization, and retention boundaries.
- Signs off before any training or eval reuse path opens.

## 4) Execution slices

### Slice A: Model contracts
- Define input/output contracts for each lane.
- Add shared telemetry fields for route, latency, cost, confidence, and provenance.
- Keep contracts stable enough for replay and audit.

### Slice B: Phase-1 readiness
- Implement image quality gate, duplicate detection, confidence calibration, and route policy v1.
- Keep cloud classification as fallback, not the permanent default.

### Slice C: Data and consent
- Separate inference-only from training-reuse consent.
- Add redaction and tombstoning rules.
- Make dataset admission explicit and versioned.

### Slice D: Eval and gating
- Build golden set and benchmark criteria.
- Require pass/fail evidence before model route changes are promoted.

## 5) Acceptance criteria

This lane is ready for phase-2 implementation when all of the following are true:

1. Every model lane has a documented contract and telemetry shape.
2. Every inference event records route, confidence, latency, and provenance.
3. Reusable training data requires explicit consent and privacy gating.
4. The phase-1 router can block low-quality images before cloud calls.
5. Duplicate suppression is active and traceable.
6. Golden eval coverage exists for the major waste classes and the top safety edge cases.
7. The canonical docs link to each other so future work can start from a single entrypoint.

## 6) Risks / watchouts

- Full VLM fine-tuning too early will create cost and data-quality risk without reliable gains.
- Privacy failures will poison the training pool if consent and redaction are not enforced first.
- If route telemetry is incomplete, later regressions will be hard to attribute.
- If disposal policy and image classification stay coupled, evaluation will remain noisy.

## 7) Handoff checklist

- [ ] Confirm `docs/EXPLORATION_TOPICS.md` still contains the `1a` stack entry.
- [ ] Confirm `docs/exploration/MULTI_MODEL_AI_STACK.md` remains the stack overview.
- [ ] Confirm the three support docs remain the phase split:
  - contracts
  - phase-1 execution
  - data/consent readiness
- [ ] Keep all future implementation work additive and route-safe.
- [ ] Preserve the distinction between inference-only data and training-reuse data.
- [ ] Add new model lanes only through the existing stack doc and the issue review packet.

## 8) Next implementation trigger

Start implementation only after the team chooses the first phase-1 slice to build. Recommended starting point is:

`quality gate -> duplicate detection -> confidence calibration -> route policy v1`

That sequence gives the fastest cost reduction and the cleanest audit trail.

