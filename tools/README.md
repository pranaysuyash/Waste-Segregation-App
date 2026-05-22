# Reusable Tools

This folder contains reusable flywheel verification and workflow tools.

## 1) `verify_ai_flywheel_foundation.sh`
One-shot verification script for the AI learning flywheel foundation.

Runs:
- flywheel tests
- offline eval
- recorded provider evals (backend/openai/gemini/local)
- recorded merge
- router comparison report
- dataset export
- annotation workflow export/apply/report

Usage:
```bash
./tools/verify_ai_flywheel_foundation.sh
```

Outputs:
- `build/reports/ai_eval/*`
- `build/reports/ai_dataset/latest/*`
- `build/reports/ai_review/*`

## 2) `../tool/ai_eval_runner.dart`
Runs eval harness in `offline|recorded|live` mode.

Usage:
```bash
dart run tool/ai_eval_runner.dart --mode offline
dart run tool/ai_eval_runner.dart --mode recorded --recorded-file test/fixtures/ai_eval/recorded_outputs/recorded_backend.jsonl --provider-label backend/classifyImage
```

## 3) `../tool/ai_dataset_exporter.dart`
Exports reviewed and eligible candidates into dataset artifacts.

Usage:
```bash
dart run tool/ai_dataset_exporter.dart --input=test/fixtures/ai_eval/recorded_outputs/training_candidates_sample.jsonl --out=build/reports/ai_dataset/latest --version=waste-v0.1
```

## 4) `../tool/ai_review_workflow.dart`
JSONL-first review/annotation workflow helper.

Modes:
- `export`
- `apply`
- `report`

Usage:
```bash
dart run tool/ai_review_workflow.dart --mode export
dart run tool/ai_review_workflow.dart --mode apply --decisions tool/templates/review_decisions_template.jsonl
dart run tool/ai_review_workflow.dart --mode report --out build/reports/ai_review/updated_candidates.jsonl
```

## 5) `../tool/router_compare_report.dart`
Builds provider-level comparison report from eval outcomes.

Usage:
```bash
dart run tool/router_compare_report.dart --input build/reports/ai_eval/latest.json --out build/reports/ai_eval/router_compare.json
```

## 6) `../tool/ai_eval_merge_records.dart`
Merges multiple provider recorded JSONL files into one deterministic output.

Usage:
```bash
dart run tool/ai_eval_merge_records.dart --inputs test/fixtures/ai_eval/recorded_outputs/recorded_backend.jsonl,test/fixtures/ai_eval/recorded_outputs/recorded_openai.jsonl,test/fixtures/ai_eval/recorded_outputs/recorded_gemini.jsonl,test/fixtures/ai_eval/recorded_outputs/recorded_local.jsonl --out build/reports/ai_eval/merged_records.jsonl
```

## 7) `../tool/ai_flywheel_acceptance_report.dart`
Generates criterion-by-criterion acceptance report using generated artifacts.

Usage:
```bash
dart run tool/ai_flywheel_acceptance_report.dart --out build/reports/ai_flywheel/acceptance_report.json
```

## 8) `../tool/ai_eval_seed_coverage_report.dart`
Validates seed-case semantic coverage against goal-required case families.

Usage:
```bash
dart run tool/ai_eval_seed_coverage_report.dart --input test/fixtures/ai_eval/golden_cases.jsonl --out build/reports/ai_eval/seed_coverage_report.json
```

## 9) `../tool/ai_flywheel_evidence_summary.dart`
Builds a single markdown summary from generated verification artifacts.

Usage:
```bash
dart run tool/ai_flywheel_evidence_summary.dart --out build/reports/ai_flywheel/FINAL_EVIDENCE_SUMMARY.md
```
