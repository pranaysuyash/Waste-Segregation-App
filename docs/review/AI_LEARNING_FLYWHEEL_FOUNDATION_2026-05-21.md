# AI Learning Flywheel Foundation (Phase 1 Scaffold)

## Current gap
Backend routing exists, but truth-eval + consented training candidate lifecycle was fragmented.

## What this adds
- Golden eval dataset scaffold: `test/fixtures/ai_eval/`
- Eval schema + scoring classes: `lib/ai_flywheel/eval_models.dart`, `lib/ai_flywheel/eval_scoring.dart`
- Offline/recorded/live-safe eval runner: `lib/ai_flywheel/eval_runner.dart`, `tool/ai_eval_runner.dart`
- Consent-aware training candidate gating + review state contract: `lib/ai_flywheel/training_candidate_policy.dart`
- Dataset export/versioning scaffold: `lib/ai_flywheel/dataset_exporter.dart`, `tool/ai_dataset_exporter.dart`
- Router metrics comparison shape: `lib/ai_flywheel/router_metrics.dart`
- Foundation tests: `test/ai_flywheel/flywheel_foundation_test.dart`

## Architecture flow
classification result -> user feedback -> consent-gated candidate -> review status -> golden/training eligibility -> dataset export -> eval and router threshold tuning.

```text
Capture/Classification
  -> ResultPipeline + CorrectionDialog feedback
  -> TrainingDataService (consent gate)
  -> training_candidates + training_labels (backend)
  -> Admin review state machine
      unreviewed -> needs_redaction|rejected|approved|golden|training_eligible|deleted
  -> Dataset manifest build (excluded-by-default policy)
  -> Eval runner (offline/recorded/live-explicit)
  -> Router metrics comparison and threshold tuning
```

## Consent and deletion rules
- Training candidate creation only when `trainingConsent.enabled == true` and not revoked.
- Export excludes by default: no consent, revoked, deleted, unreviewed, rejected, redaction pending/failed.
- Firestore client access for flywheel internal collections is admin-only; candidate/label writes remain Cloud Functions-owned.

## Review states
`unreviewed`, `approved`, `rejected`, `needs_redaction`, `golden`, `training_eligible`, `deleted`.

Reviewer actions in `reviewTrainingCandidate` now accept `groundTruth` payload
(`category`, `subcategory`, `itemName`, `material`, `confidence`) and persist
it under `training_labels.reviewerVerified.groundTruth` for golden/training rows.

## Unlock path
- Local ML readiness: controlled golden + training-eligible data.
- Segmentation readiness: multi-item placeholders now represented in eval set.
- Global/local rule readiness: `mustNot` + `localRuleCritical` scoring dimensions.
- Active learning loop: corrected examples become candidates, then reviewed truth.

## Risks and next phases
- Live mode is intentionally blocked unless `AI_EVAL_ENABLE_LIVE=true`.
- Firestore rules and Cloud Functions review/admin collections are not yet wired here.
- Next: add explicit reviewer-verified `groundTruth` fields in review callable so golden/training labels are always traceable to reviewer assertions.

## Operational workflows
- Reusable tools index: `tools/README.md`
- One-shot verification script: `tools/verify_ai_flywheel_foundation.sh`
- Multi-provider recorded eval workflow: `docs/guides/ai_flywheel/multi_provider_eval_workflow.md`
- Annotation/review JSONL workflow: `docs/guides/ai_flywheel/annotation_review_workflow.md`
- Router comparison workflow: `docs/guides/ai_flywheel/router_comparison_workflow.md`

Tooling commands:
- `dart run tool/ai_review_workflow.dart --mode export`
- `dart run tool/ai_review_workflow.dart --mode apply`
- `dart run tool/ai_review_workflow.dart --mode report`
- `dart run tool/router_compare_report.dart --input build/reports/ai_eval/latest.json`
