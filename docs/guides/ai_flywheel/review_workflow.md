# Review Workflow Guide

Export template:
```bash
dart run tool/ai_review_workflow.dart --mode export --input test/fixtures/ai_eval/recorded_outputs/training_candidates_sample.jsonl --out build/reports/ai_review/review_template.jsonl
```

Apply reviewer decisions:
```bash
dart run tool/ai_review_workflow.dart --mode apply --input test/fixtures/ai_eval/recorded_outputs/training_candidates_sample.jsonl --decisions tool/templates/review_decisions_template.jsonl --out build/reports/ai_review/updated_candidates.jsonl --reviewer reviewer@example.com
```

Validation gates:
- invalid decision => fail
- golden/training_eligible require verified category
- golden/training_eligible blocked by privacy blockers: `needs_redaction`, `pii_failed`, `rejected`, `deleted`
- delete marks deleted/excluded
- rejected marks `excludedFromTrainingAt`
- lifecycle state is materialized per candidate (`trainingEligible`, `golden`, `excluded`)
