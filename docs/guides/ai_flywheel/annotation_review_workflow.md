# Annotation and Review Workflow (JSONL-first)

## Goal
Provide a lightweight internal reviewer workflow without requiring a full admin UI.

## Review states
- `unreviewed`
- `approved`
- `rejected`
- `needs_redaction`
- `golden`
- `training_eligible`
- `deleted`

## Workflow
1. Export candidate review template:

```bash
dart run tool/ai_review_workflow.dart --mode export --input test/fixtures/ai_eval/recorded_outputs/training_candidates_sample.jsonl --out build/reports/ai_review/review_template.jsonl
```

2. Fill review decisions in JSONL (`reviewDecision`, `groundTruth`, `notes`).

3. Apply decisions:

```bash
dart run tool/ai_review_workflow.dart --mode apply --input test/fixtures/ai_eval/recorded_outputs/training_candidates_sample.jsonl --decisions build/reports/ai_review/review_template.jsonl --out build/reports/ai_review/updated_candidates.jsonl --reviewer reviewer@example.com
```

4. Generate status report:

```bash
dart run tool/ai_review_workflow.dart --mode report --out build/reports/ai_review/updated_candidates.jsonl
```

## Ground-truth policy
- Model prediction is not truth.
- User correction is not automatically truth.
- Only reviewer-verified `groundTruth` can promote to `golden` or `training_eligible`.

## Dataset export safeguards
Candidates are excluded by default when:
- consent missing/revoked
- review state is `unreviewed`/`approved`/`rejected`
- redaction is pending/failed
- record is marked deleted/excluded
