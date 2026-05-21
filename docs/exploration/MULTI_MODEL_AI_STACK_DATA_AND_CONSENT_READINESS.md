# Multi-Model AI Stack — Data, Consent, and Privacy Readiness

**Last Updated**: 2026-05-21  
**Status**: SEED

## Why this is phase-1 gating

No model stack work is production-safe until training/eval data handling is explicitly consented, versioned, and privacy-filtered. This document defines the minimum bar before any image is used beyond on-device classification.

## Consent and reuse policy

- Capture consent for classification inference is separate from training reuse consent.
- Training reuse consent is opt-in and revocable.
- Users can revoke reuse consent; legacy stored training candidates must be marked tombstoned.
- Consent timestamp and source string must be stored with every reusable image record.

## Data paths

- `analysis_only`: image used for immediate classification only, not retained.
- `transient_cache`: short-lived storage for UX retries and short-term de-duplication.
- `training_candidate_pool`: only after privacy and consent checks pass.
- `golden_eval_pool`: manually reviewed, versioned, and immutable benchmark set.
- `abuse_investigation_pool`: contains minimal fields and strict access controls.

## Privacy rejection rules

- Reject from training if high-confidence PII exists and redaction is not possible.
- Reject if identifiable person remains after redaction budget.
- Reject if readable addresses or phone-like numbers are present and high confidence.
- Reject household/private interior scenes unless explicit consent includes reuse for model improvement.

## Redaction and minimization requirements

- Blur/overlay sensitive regions before training upload where feasible.
- Prefer metadata stripping:
  - capture timestamp minimization,
  - exact GPS removal unless required for civic routing use-case.
- Store only hashes where raw images are not needed.

## Governance fields to persist

- `consent_type`: `inference_only` or `training_reuse`.
- `consent_version`: policy version hash at time of capture.
- `pii_risk_score`
- `redaction_applied`: boolean
- `training_eligible`
- `training_eligible_reason`
- `dataset_version`
- `revoked_at` (nullable)
- `correction_id` (if corrected by user)
- `reviewer_id` (if manual review applied)

## Golden set governance

- Every eval sample gets:
  - source provenance,
  - expected label source (`user`, `reviewer`, `policy_pack`),
  - must-not constraints,
  - failure class taxonomy tag.
- Golden labels can only change through approved review pass with rationale.

## Operational controls

- Data retention windows per bucket with automatic expiry.
- Right-to-be-forgotten handling for training/eval pools.
- Internal admin evidence report per quarter: consent rate, redaction rate, rejected training candidates, and training pool size.
- No training candidate write should occur when route is in incident rollback mode.

## Verification checklist before opening phase-2 training jobs

- 100% of reused images have valid `consent_type = training_reuse`.
- 100% of training candidates include governance fields above.
- Duplicate candidates dedupe policy documented and enforced.
- Golden set and eval pipeline reference explicit dataset versions.
- Privacy team signs off on PII failure rates and redaction controls.

