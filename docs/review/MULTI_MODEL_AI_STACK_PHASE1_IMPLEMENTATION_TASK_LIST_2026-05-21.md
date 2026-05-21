# Multi-Model AI Stack Phase 1 Implementation Task List

Date: 2026-05-21  
Repo: `/Users/pranay/Projects/LLM/image/waste_seg/waste_segregation_app`  
Scope: concrete implementation order for the phase-1 slice of the multi-model AI stack

## 1) Goal

Turn the phase-1 concept into a buildable slice with real file targets:

- quality gate
- duplicate suppression
- confidence calibration
- route policy v1
- consent / redaction / training-data readiness
- golden eval and route telemetry

This list is ordered so each step reduces risk for the next one.

## 2) Baseline references

- [docs/EXPLORATION_TOPICS.md](/Users/pranay/Projects/LLM/image/waste_seg/waste_segregation_app/docs/EXPLORATION_TOPICS.md)
- [docs/exploration/MULTI_MODEL_AI_STACK.md](/Users/pranay/Projects/LLM/image/waste_seg/waste_segregation_app/docs/exploration/MULTI_MODEL_AI_STACK.md)
- [docs/exploration/MULTI_MODEL_AI_STACK_CONTRACTS.md](/Users/pranay/Projects/LLM/image/waste_seg/waste_segregation_app/docs/exploration/MULTI_MODEL_AI_STACK_CONTRACTS.md)
- [docs/exploration/MULTI_MODEL_AI_STACK_PHASE1_EXECUTION.md](/Users/pranay/Projects/LLM/image/waste_seg/waste_segregation_app/docs/exploration/MULTI_MODEL_AI_STACK_PHASE1_EXECUTION.md)
- [docs/exploration/MULTI_MODEL_AI_STACK_DATA_AND_CONSENT_READINESS.md](/Users/pranay/Projects/LLM/image/waste_seg/waste_segregation_app/docs/exploration/MULTI_MODEL_AI_STACK_DATA_AND_CONSENT_READINESS.md)
- [docs/review/AI_EVAL_HARNESS_IMPLEMENTATION_PACKET_2026-05-21.md](/Users/pranay/Projects/LLM/image/waste_seg/waste_segregation_app/docs/review/AI_EVAL_HARNESS_IMPLEMENTATION_PACKET_2026-05-21.md)

## 3) Ordered implementation steps

### Step 1 — Quality gate contract and UI handoff

**Target outcome**: bad images stop earlier, before cloud spend.

**Primary files**
- `lib/services/result_pipeline.dart`
- `lib/models/waste_classification.dart`
- `lib/screens/image_capture_screen.dart`
- `lib/screens/result_screen.dart`

**Supporting files**
- `lib/services/storage_service.dart`
- `lib/services/cloud_storage_service.dart`
- `lib/services/firestore_schema_registry.dart`

**Work**
- Add a canonical quality-gate result shape.
- Add quality-block reason codes.
- Surface a user-facing retake state when quality is below threshold.
- Preserve the quality result in the result pipeline event payload.

**Acceptance**
- Poor images can be rejected before classification completes.
- Quality reason is visible in the stored result record.

### Step 2 — Duplicate suppression and image similarity metadata

**Target outcome**: repeated uploads do not create duplicate work or training noise.

**Primary files**
- `lib/services/result_pipeline.dart`
- `lib/services/storage_service.dart`
- `lib/services/cloud_storage_service.dart`
- `lib/services/firestore_schema_registry.dart`

**Supporting files**
- `functions/src/classify_image.ts`
- `eval/classification/*` if the eval packet is extended to include duplicate cases

**Work**
- Add hash/similarity metadata to the classification payload.
- Track exact duplicate vs near-duplicate outcomes.
- Add a canonical cluster/id field for repeat item traces.
- Ensure duplicate matches can reuse prior high-confidence outcomes safely.

**Acceptance**
- Duplicate detection is logged in the same event envelope as the classification.
- Duplicate hits can bypass unnecessary cloud calls.

### Step 3 — Confidence calibration and explicit review routing

**Target outcome**: the app stops pretending uncertainty is certainty.

**Primary files**
- `lib/models/waste_classification.dart`
- `lib/services/result_pipeline.dart`
- `lib/services/firestore_schema_registry.dart`
- `functions/src/classify_image.ts`

**Supporting files**
- `lib/screens/result_screen.dart`
- `lib/screens/combined_result_screen.dart`

**Work**
- Add a calibrated confidence field separate from raw model confidence.
- Add `needsReview` and `reviewReason`.
- Normalize the same confidence contract across local/cloud routes.
- Preserve the ambiguity state through storage and retrieval.

**Acceptance**
- Low-confidence cases are visibly flagged rather than being forced into a single answer.
- The stored record distinguishes model uncertainty from image-quality failure.

### Step 4 — Route policy v1

**Target outcome**: the app follows a deterministic escalation ladder.

**Primary files**
- `lib/services/result_pipeline.dart`
- `lib/services/storage_service.dart`
- `lib/services/cloud_storage_service.dart`
- `functions/src/classify_image.ts`

**Supporting files**
- `lib/providers/app_providers.dart` if route config is injected there
- `lib/services/firestore_schema_registry.dart`

**Work**
- Implement a route policy with explicit branches:
  - poor quality -> retake
  - exact duplicate with safe cached answer -> cache
  - low confidence / policy risk -> cloud escalation
  - otherwise local-first or current baseline path
- Emit route name, cost estimate, latency, and provider used.

**Acceptance**
- Every inference run can be replayed from the stored route metadata.
- The policy decision is visible in telemetry.

### Step 5 — Training consent, redaction, and data readiness

**Target outcome**: reusable data is gated before it reaches any training or eval queue.

**Primary files**
- `lib/models/classification_feedback.dart`
- `lib/services/result_pipeline.dart`
- `lib/services/storage_service.dart`
- `lib/services/firestore_schema_registry.dart`

**Supporting files**
- `lib/services/training_data_service.dart`
- `functions/src/training_data.ts`
- `docs/exploration/MULTI_MODEL_AI_STACK_DATA_AND_CONSENT_READINESS.md`

**Work**
- Separate inference-only data from training-reuse data.
- Add consent version and revocation handling.
- Add redaction/minimization fields to reusable-image records.
- Make non-consented data non-admissible by default.

**Acceptance**
- No training pool entry is possible without explicit reuse consent.
- PII rejection and redaction status are persisted with the candidate.

### Step 6 — Golden eval and route telemetry

**Target outcome**: model/router changes can be measured and rolled back.

**Primary files**
- `eval/classification/README.md`
- `eval/classification/schema/golden_case.schema.json`
- `eval/classification/golden/golden_cases_v1.jsonl`
- `eval/classification/reports/`
- `scripts/eval/run_classification_eval.py`

**Supporting files**
- `scripts/eval/export_feedback_candidates.py`
- `docs/review/AI_EVAL_HARNESS_IMPLEMENTATION_PACKET_2026-05-21.md`

**Work**
- Add phase-1 evaluation cases for:
  - bad-photo rejection
  - duplicate suppression
  - uncertainty handling
  - route selection
  - privacy rejection
- Add route-version-aware comparisons.
- Ensure every route emits cost and latency telemetry for eval correlation.

**Acceptance**
- A phase-1 eval run can show whether quality gating and routing improved cost without harming accuracy.
- The same benchmark can be reused for later phase-2 model work.

## 4) Suggested implementation order inside the codebase

1. `lib/services/result_pipeline.dart`
2. `lib/models/waste_classification.dart`
3. `lib/services/firestore_schema_registry.dart`
4. `lib/services/storage_service.dart`
5. `lib/services/cloud_storage_service.dart`
6. `functions/src/classify_image.ts`
7. `functions/src/training_data.ts`
8. `lib/services/training_data_service.dart`
9. `eval/classification/*`
10. `scripts/eval/*`

## 5) Verification checkpoints

- Quality gate emits a stable reason code.
- Duplicate matches are surfaced in telemetry.
- Low-confidence cases preserve a review state.
- Route metadata is persisted in one canonical envelope.
- Reuse consent is required before training admission.
- Eval output can compare route versions without ad-hoc parsing.

## 6) Handoff notes

- Keep the changes additive.
- Do not fork a second route or a second classification envelope.
- Preserve the distinction between policy decisions and model predictions.
- If a file already owns a canonical record shape, extend it instead of adding a parallel one.

## 7) Next trigger

If this list is accepted, start with Step 1 and Step 4 together only if the quality gate and route policy share the same event envelope. Otherwise complete Step 1 first and use it to stabilize the route policy interface.
