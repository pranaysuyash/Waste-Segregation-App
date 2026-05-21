# Classification Eval Harness (v1)

Purpose
- Provide a repeatable quality gate for waste classification changes (provider/model/router/prompt/rules).
- Convert user correction feedback into reviewed candidate labels for future golden set updates.

Artifacts
- `eval/classification/schema/golden_case.schema.json`
  - Canonical schema for each golden case.
- `eval/classification/golden/golden_cases_v1.jsonl`
  - Seed golden set (36 cases) with expected labels and guardrails.
- `eval/classification/fixtures/provider_outputs_v1.jsonl`
  - Recorded fixture outputs for router/provider comparison in offline mode.
- `eval/classification/reports/`
  - Generated evaluation reports.
- `eval/classification/feedback_exports/`
  - Exported correction candidates from `classification_feedback`.

Runner
- Script: `scripts/eval/run_classification_eval.py`
- Modes:
  - `offline`: evaluate fixture outputs only (no network).
  - `recorded`: same as offline; explicit for CI naming clarity.
  - `live`: call providers/router adapters (adapter stubs included; wire credentials before use).

Correction export
- Script: `scripts/eval/export_feedback_candidates.py`
- Input: JSON export of `classification_feedback` docs.
- Output:
  - `*_review_queue.jsonl` (manual review queue)
  - `*_approved_candidates.jsonl` (approved-only training/eval candidates)

Contract
- Do not treat raw user corrections as truth.
- Only `approved` entries can be promoted into golden candidates.
- Always preserve provenance fields (`source_type`, `review_status`, reviewer/timestamp).

Quick start
1) Run offline harness:
   `python3 scripts/eval/run_classification_eval.py --mode offline --golden eval/classification/golden/golden_cases_v1.jsonl --fixtures eval/classification/fixtures/provider_outputs_v1.jsonl --output eval/classification/reports/eval_report_offline_v1.json`

2) Export correction candidates (example):
   `python3 scripts/eval/export_feedback_candidates.py --input path/to/classification_feedback_export.json --output-dir eval/classification/feedback_exports`
