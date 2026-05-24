# Dataset Export Guide

```bash
dart run tool/ai_dataset_exporter.dart --input=test/fixtures/ai_eval/recorded_outputs/training_candidates_sample.jsonl --out=build/reports/ai_dataset/latest --version=waste-v0.1
```

Outputs:
- manifest.jsonl
- labels.jsonl
- datasheet.md
- version.json
- excluded.jsonl

Default exclusion notes:
- candidates without `reviewerVerified.reviewedAt` are excluded
- stale policy version excluded unless explicit override in policy layer
