# AI Learning Flywheel Foundation — Completion Audit

Date: 2026-05-23
Scope: `goal1.txt` objective and acceptance criteria
Standard: motto_v2 + first-principles, evidence-first audit

## Acceptance criteria audit

1. Golden eval schema exists.
- Evidence: `test/fixtures/ai_eval/schema.md`, `lib/ai_flywheel/eval_models.dart`.
- Status: implemented.

2. At least 30 meaningful seed eval cases exist or are scaffolded.
- Evidence: `test/fixtures/ai_eval/golden_cases.jsonl` seeded with 35 cases including safety/local-rule edge cases.
- Status: implemented.

3. Offline eval runner produces a report without API keys.
- Evidence: `tool/ai_eval_runner.dart`, `lib/ai_flywheel/eval_runner.dart` supports `offline` with no live calls.
- Verification needed: run command and inspect `build/reports/ai_eval/latest.json`.
- Status: implemented, runtime evidence pending.

4. Safety-critical failures and must-not violations are separately scored.
- Evidence: `lib/ai_flywheel/eval_scoring.dart` (`safetyCriticalFailure`, `mustNotViolation`, `localRuleFailure`).
- Status: implemented.

5. Training candidate schema exists and is consent-aware.
- Evidence: backend candidate schema in `functions/src/training_data.ts`; consent model in `lib/models/user_profile.dart` and `lib/services/training_data_service.dart`.
- Status: implemented.

6. Candidate creation is gated by explicit training consent.
- Evidence: `validateConsent()` in `functions/src/training_data.ts`; client gate in `TrainingDataService.enqueueCandidateForClassification`.
- Status: implemented.

7. Review states are defined.
- Evidence: `REVIEWABLE_STATUSES` in `functions/src/training_data.ts`; documented in `docs/guides/ai_flywheel/annotation_review_workflow.md`.
- Status: implemented.

8. Dataset export/versioning is scaffolded.
- Evidence: `tool/ai_dataset_exporter.dart`, `lib/ai_flywheel/dataset_exporter.dart`; backend manifest callable `buildTrainingDatasetManifest` in `functions/src/training_data.ts`.
- Status: implemented.

9. Revoked/deleted/rejected/unreviewed candidates are excluded by default.
- Evidence: exclusion logic in `lib/ai_flywheel/dataset_exporter.dart` and backend exclusion counters + filtering in `buildTrainingDatasetManifest` (`functions/src/training_data.ts`).
- Status: implemented.

10. Router metrics can compare backend/local/future provider outputs.
- Evidence: `lib/ai_flywheel/router_metrics.dart`; `tool/router_compare_report.dart`.
- Added reproducible per-provider eval invocation path: `tool/ai_eval_runner.dart --recorded-file ... --provider-label ...`, documented in `docs/guides/ai_flywheel/multi_provider_eval_workflow.md`.
- Status: implemented.

11. Tests cover schema, scoring, consent gating, and export exclusion.
- Evidence: `test/ai_flywheel/flywheel_foundation_test.dart`.
- Verification needed: execute test run.
- Status: implemented, runtime evidence pending.

12. Documentation explains unlocks for local ML, segmentation, global rules, active learning, future training.
- Evidence: `docs/review/AI_LEARNING_FLYWHEEL_FOUNDATION_2026-05-21.md`, linked workflow docs under `docs/guides/ai_flywheel/` and references in `docs/EXPLORATION_TOPICS.md`.
- Status: implemented.

## Non-goals compliance

- No model training implementation added.
- No live eval by default (`AI_EVAL_ENABLE_LIVE=true` required).
- Review flow distinguishes model prediction, user correction, and reviewer ground truth.

## Remaining closure requirements

To claim completion with strong evidence:
1. Execute targeted tests and attach output.
2. Execute offline eval runner and inspect generated JSON report.
3. Execute dataset exporter and verify exclusion behavior outputs.
4. Execute router comparison report and verify metric file generation.

Until these runtime checks are captured, completion remains unproven.

## One-shot verification command

```bash
./tools/verify_ai_flywheel_foundation.sh
```

This command runs tests, evals, dataset export, annotation workflow steps, and emits final artifacts under `build/reports/`.

## Added test coverage (pending execution)
- `test/ai_flywheel/eval_runner_config_test.dart` validates provider-configurable recorded eval runs.
- `test/ai_flywheel/eval_merge_records_test.dart` validates deterministic merge semantics and JSONL output pattern.

## Acceptance report tool
- `tool/ai_flywheel_acceptance_report.dart` produces criterion-by-criterion audit JSON from generated evidence artifacts.

## Seed coverage validator
- `tool/ai_eval_seed_coverage_report.dart` verifies semantic seed coverage for required case families (not only case count).
