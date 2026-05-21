# Multi-Model AI Stack — Phase 1 Execution

**Last Updated**: 2026-05-21  
**Status**: Seed (ready for implementation planning)

## Objective

Phase 1 is to reduce dependence on full cloud inference while improving cost and accuracy through:

- deterministic quality/PII gates,
- duplicate suppression,
- confidence-aware routing,
- high-value data capture for future model training.

## Scope for phase 1

- Data foundation:
  - explicit training consent capture
  - image redaction policy
  - correction capture schema
  - dataset metadata + versioning
  - evaluation baseline and golden set draft
- Routing and quality:
  - image quality precheck
  - duplicate precheck
  - confidence calibration
  - small local vs cloud routing policy
- Safety boundaries:
  - privacy gate before any training/eval reuse
  - policy/rules determinism preserved for disposal-critical classes

## Workstream A — Product-ready gates

- [ ] Add quality gate in capture pipeline with user guidance states.
- [ ] Add duplicate hash + similarity metadata in ingestion path.
- [ ] Add per-image PII risk scoring output to classification payload.
- [ ] Emit unified route decision fields (`cache/local/cloud/manual`) in all inference runs.
- [ ] Add `needs_review` + reason to uncertain cases before UI handoff.
- [ ] Add route audit log entry with provider, latency, cost, and confidence.

## Workstream B — Data readiness

- [ ] Define and store training candidate schema in a single source of truth.
- [ ] Capture correction events with accepted/rejected labels and reason.
- [ ] Add golden/eval set metadata schema and ingestion process.
- [ ] Mark and exclude non-consented images from all long-term training pools.
- [ ] Add dataset version tag to every eval run.

## Workstream C — Model and router readiness

- [ ] Add local quality model stub contract (even if initially rules-based).
- [ ] Add duplicate detector stub with hash + threshold config.
- [ ] Add confidence calibration wrapper around current classifier outputs.
- [ ] Implement route policy v1:
  - if poor quality → ask re-capture,
  - if duplicate and already high-confidence recent hit → cache answer,
  - if low confidence / policy risk → cloud path,
  - else local-first path where available.
- [ ] Track per-route outcomes for calibration and cost.

## Workstream D — Validation and release safety

- [ ] Add phase-1 evaluation matrix:
  - accuracy change,
  - re-capture rate,
  - manual review rate,
  - reward abuse indicators.
- [ ] Add rollback gates:
  - max cost regression,
  - max accuracy drop on high-priority classes,
  - max unsafe disposal misroute rate.
- [ ] Add one-page operations checklist for disabling phase-1 route if thresholds fail.

## Delivery order

1. Finish route and schema contracts.
2. Implement gates and telemetry fields.
3. Add correction/eval capture.
4. Enable phase-1 router and calibrate thresholds.
5. Run comparative eval against current single-cloud baseline.
6. Publish decision packet before phase-2 model expansion.

## Implementation task list

- [docs/review/MULTI_MODEL_AI_STACK_PHASE1_IMPLEMENTATION_TASK_LIST_2026-05-21.md](/Users/pranay/Projects/LLM/image/waste_seg/waste_segregation_app/docs/review/MULTI_MODEL_AI_STACK_PHASE1_IMPLEMENTATION_TASK_LIST_2026-05-21.md)
  - concrete file targets
  - ordered implementation steps
  - verification checkpoints
  - handoff notes for the next engineer / agent

## Acceptance criteria (minimum)

- At least 20% of obvious bad photos blocked before cloud call.
- At least 10% duplicate suppression in repeated upload scenarios.
- Stable routing telemetry covering every inference path.
- No training pool includes non-consented or high-PII images.
- Golden eval pass/fail available per route version.

## Exit condition

Phase 1 exits when routing and gating evidence is stable for two consecutive eval cycles and team agrees on phase-2 expansion confidence.
