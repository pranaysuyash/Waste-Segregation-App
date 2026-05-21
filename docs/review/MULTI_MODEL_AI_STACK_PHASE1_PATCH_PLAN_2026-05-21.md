# Multi-Model AI Stack Phase 1 Patch Plan

Date: 2026-05-21  
Repo: `/Users/pranay/Projects/LLM/image/waste_seg/waste_segregation_app`  
Status: planning artifact, not yet implemented

## 1) Objective

Convert the phase-1 stack from documentation into a concrete code path that:

- blocks bad images earlier,
- logs duplicate and confidence metadata,
- records route decisions canonically,
- enforces training consent and redaction,
- keeps the eval harness aligned with the new route metadata.

## 2) Patch sequence

### Patch A — Canonical result envelope

**Files to change**
- `lib/models/waste_classification.dart`
- `lib/services/result_pipeline.dart`
- `lib/services/firestore_schema_registry.dart`
- `lib/services/storage_service.dart`
- `lib/services/cloud_storage_service.dart`

**Code changes**
- Add canonical fields for:
  - `qualityScore`
  - `qualityReasons`
  - `duplicateScore`
  - `duplicateClusterId`
  - `rawConfidence`
  - `calibratedConfidence`
  - `needsReview`
  - `reviewReason`
  - `routeDecision`
  - `routeReason`
  - `policyPackId`
  - `modelRoute`
  - `routeLatencyMs`
  - `routeCostUsd`
- Preserve backwards compatibility in JSON parsing by defaulting missing fields.
- Store the new fields through the local save path and the cloud sync path.

**Data shape additions**
```json
{
  "qualityScore": 0.0,
  "qualityReasons": [],
  "duplicateScore": 0.0,
  "duplicateClusterId": null,
  "rawConfidence": 0.0,
  "calibratedConfidence": 0.0,
  "needsReview": false,
  "reviewReason": null,
  "routeDecision": "local_first",
  "routeReason": null,
  "policyPackId": null,
  "modelRoute": null,
  "routeLatencyMs": null,
  "routeCostUsd": null
}
```

### Patch B — Capture UI quality gate

**Files to change**
- `lib/screens/image_capture_screen.dart`
- `lib/screens/result_screen.dart`
- `lib/screens/combined_result_screen.dart`
- `lib/services/result_pipeline.dart`

**Code changes**
- Surface a retake flow when image quality is too poor.
- Show reason codes when the image is blocked or downgraded.
- Preserve the quality result in the output state so the UI can explain the decision.

**Data shape additions**
- `captureQualityState`
- `captureQualityReason`
- `retakeSuggested`

### Patch C — Duplicate detection metadata

**Files to change**
- `lib/services/result_pipeline.dart`
- `lib/services/storage_service.dart`
- `lib/services/cloud_storage_service.dart`
- `functions/src/classify_image.ts`

**Code changes**
- Add hash/similarity metadata into the canonical classification record.
- Reuse prior answers when a duplicate is high-confidence and safe.
- Log duplicate cluster IDs for repeated uploads and training suppression.

**Data shape additions**
- `imageHash`
- `perceptualHash`
- `duplicateHash`
- `duplicateClusterId`
- `duplicateHit`

### Patch D — Confidence calibration wrapper

**Files to change**
- `lib/models/waste_classification.dart`
- `lib/services/result_pipeline.dart`
- `functions/src/classify_image.ts`

**Code changes**
- Separate raw model confidence from calibrated confidence.
- Add `needsReview` / `reviewReason` to the model output contract.
- Keep the ambiguous state through serialization and deserialization.

**Data shape additions**
- `rawConfidence`
- `calibratedConfidence`
- `needsReview`
- `reviewReason`
- `uncertaintyBucket`

### Patch E — Route policy v1

**Files to change**
- `lib/services/result_pipeline.dart`
- `lib/services/storage_service.dart`
- `lib/services/cloud_storage_service.dart`
- `lib/providers/app_providers.dart`
- `functions/src/classify_image.ts`

**Code changes**
- Implement a deterministic escalation ladder:
  - low quality -> retake
  - duplicate safe hit -> reuse
  - low confidence / policy risk -> cloud escalation
  - otherwise current baseline or local-first path
- Log provider name, cost estimate, latency, and route reason.

**Data shape additions**
- `routeDecision`
- `routeReason`
- `routeProvider`
- `routeLatencyMs`
- `routeCostUsd`

### Patch F — Consent and training data gating

**Files to change**
- `lib/services/training_data_service.dart`
- `lib/models/classification_feedback.dart`
- `lib/services/result_pipeline.dart`
- `lib/services/storage_service.dart`
- `functions/src/training_data.ts`
- `functions/src/index.ts`

**Code changes**
- Ensure inference-only data is never silently mixed with training-reuse data.
- Require explicit reuse consent before enqueueing training candidates.
- Persist consent version, revocation markers, and redaction state.
- Keep child-profile handling blocked until guardian flow exists.

**Data shape additions**
- `trainingConsent.policyVersion`
- `trainingConsent.grantedAt`
- `trainingConsent.revokedAt`
- `trainingConsent.source`
- `candidate.review.status`
- `candidate.review.piiFlags`
- `candidate.dataset.eligible`
- `candidate.dataset.includedInVersions`

### Patch G — Eval and route telemetry

**Files to change**
- `eval/classification/schema/golden_case.schema.json`
- `eval/classification/golden/golden_cases_v1.jsonl`
- `eval/classification/fixtures/provider_outputs_v1.jsonl`
- `eval/classification/README.md`
- `scripts/eval/run_classification_eval.py`
- `scripts/eval/export_feedback_candidates.py`

**Code changes**
- Add golden cases for bad-photo, duplicate, low-confidence, and privacy-reject paths.
- Make eval reports route-version aware.
- Ensure route telemetry and eval output use the same field names.

**Data shape additions**
- `routeDecision`
- `routeReason`
- `qualityScore`
- `duplicateScore`
- `calibratedConfidence`
- `privacyStatus`
- `datasetVersion`

## 3) Verification commands

Run these after the patch series:

```bash
flutter test test/services/firestore_schema_registry_test.dart test/models/user_profile_test.dart
dart analyze lib/models/waste_classification.dart lib/services/result_pipeline.dart lib/services/training_data_service.dart
npm --prefix functions test
npm --prefix functions run build
python3 scripts/eval/run_classification_eval.py --mode offline --golden eval/classification/golden/golden_cases_v1.jsonl --fixtures eval/classification/fixtures/provider_outputs_v1.jsonl --output eval/classification/reports/eval_report_offline_v2.json
```

If the capture UI is patched, also run the focused widget tests that cover result and capture flow.

## 4) Risks to watch

- Adding fields to the result envelope can break Hive/JSON compatibility if defaults are missing.
- Route telemetry becomes useless if it is not emitted from the same canonical save path as the classification result.
- Consent gating must not block user classification when training enqueue fails.
- Eval changes should stay additive so the existing offline report remains comparable.

## 5) Immediate next build slice

Start with Patch A, Patch D, and Patch F in that order.

Reason:

1. patch A gives the canonical envelope,
2. patch D gives uncertainty semantics,
3. patch F prevents accidental data misuse.

Then wire Patch E so the route decision is actually enforced, followed by Patch B/C to improve UX and duplicate handling.

