# AI Eval Harness + Correction Loop Implementation Packet
Date: 2026-05-21
Status: Implemented (offline path production-ready, live adapters scaffolded)
Scope: Phase/P0 tasks from firebase_task.md for evaluation infra and correction-loop export

## 1) Direct outcome
Completed all requested execution tasks:
- Canonical eval schema and artifact structure defined.
- Eval runner implemented with `offline`, `recorded`, `live` modes.
- Golden set seeded with 36 cases.
- Recorded fixture predictions seeded with 144 provider rows.
- Correction feedback export pipeline implemented with privacy scrubbing.
- Offline harness executed and JSON report artifact generated.

## 2) Files created
1. `eval/classification/README.md`
2. `eval/classification/schema/golden_case.schema.json`
3. `eval/classification/golden/golden_cases_v1.jsonl`
4. `eval/classification/fixtures/provider_outputs_v1.jsonl`
5. `eval/classification/reports/eval_report_offline_v1.json`
6. `scripts/eval/run_classification_eval.py`
7. `scripts/eval/export_feedback_candidates.py`
8. `eval/classification/feedback_exports/sample_feedback_input.json` (validation sample)
9. `eval/classification/feedback_exports/classification_feedback_review_queue_20260521T094421Z.jsonl` (sample run output)
10. `eval/classification/feedback_exports/classification_feedback_approved_candidates_20260521T094421Z.jsonl` (sample run output)
11. `eval/classification/feedback_exports/classification_feedback_export_summary_20260521T094421Z.json` (sample run output)

## 3) Contract audit summary (t1)
Code contracts audited against current implementation:
- Classification object contract: `lib/models/waste_classification.dart`
- Feedback contract + lifecycle states: `lib/models/classification_feedback.dart`
- Feedback write/read surface: `lib/services/result_pipeline.dart`, `lib/services/storage_service.dart`, `lib/services/cloud_storage_service.dart`
- Firestore schema definitions: `lib/services/firestore_schema_registry.dart`
- Backend classification callable + metadata behavior: `functions/src/classify_image.ts`

Canonical eval schema decisions:
- Primary label: `expected.category` in fixed set: Wet, Dry, Hazardous, Medical, Non-Waste.
- Acceptance policy split:
  - `acceptable_categories` (for tolerant match)
  - `must_not_categories` (hard safety violations)
  - `strict_fields` (exact-match fields)
- Safety-critical dimension (`safety.safety_critical`) is first-class in scoring.
- Provenance is mandatory for future promotion of user-correction-derived cases.

## 4) Harness implementation details (t2)
Script: `scripts/eval/run_classification_eval.py`

Supported modes:
- `offline`: evaluate fixture outputs, no network calls.
- `recorded`: alias of offline for CI naming clarity.
- `live`: adapter interface present; explicit TODO to wire provider/backend calls.

Provider adapter interface:
- `ProviderAdapter` protocol defined.
- `LiveAdapterNotImplemented` included to fail loudly until explicit integration.

Metrics emitted per provider:
- strict pass count/rate
- acceptable pass count/rate
- must-not violations
- safety-critical failures
- high-confidence wrong predictions
- latency avg/p50/p90
- cost total/avg
- composite score + ranking

## 5) Golden + fixtures (t3)
Golden dataset:
- File: `eval/classification/golden/golden_cases_v1.jsonl`
- Count: 36 cases
- Coverage:
  - Wet waste: 6
  - Dry waste: 6
  - Hazardous waste: 6
  - Medical waste: 6
  - Non-waste/reuse: 6
  - Edge/ambiguous/high-risk: 6

Fixture predictions:
- File: `eval/classification/fixtures/provider_outputs_v1.jsonl`
- Count: 144 rows (36 cases × 4 provider lanes)
- Provider lanes: `openai`, `gemini`, `local_small`, `router_v1`
- Includes latency, cost estimate, confidence, fallback flag.

## 6) Correction feedback export pipeline (t4)
Script: `scripts/eval/export_feedback_candidates.py`

Pipeline behavior:
1. Ingests JSON array, `{documents:[...]}`, or JSONL exports of `classification_feedback`.
2. Normalizes into candidate rows with stable deterministic `candidate_id`.
3. Privacy scrubbing:
   - Hashes `userId` to `user_id_hash`
   - Drops raw `userNotes`, `barcode`, `deviceInfo` from candidate payload
   - Adds explicit privacy flags documenting dropped sensitive fields
4. Writes:
   - review queue JSONL (all rows)
   - approved candidates JSONL (approved statuses only)
   - summary JSON with counts and output paths

Approved statuses recognized:
- `approved`
- `reviewed_accepted_impacted_ai`
- `reviewed_accepted_informational`

## 7) Offline execution evidence (t5)
Command executed:
`python3 scripts/eval/run_classification_eval.py --mode offline --golden eval/classification/golden/golden_cases_v1.jsonl --fixtures eval/classification/fixtures/provider_outputs_v1.jsonl --output eval/classification/reports/eval_report_offline_v1.json`

Result:
- Exit code: 0
- Report path: `eval/classification/reports/eval_report_offline_v1.json`
- Golden cases evaluated: 36
- Providers evaluated: 4
- Top rank:
  - provider: `router_v1`
  - model: `openai_then_gemini_then_local`
  - strict pass rate: `0.9444`
  - safety failures: `1`
  - must-not violations: `2`

Sanity checks executed:
- `python3 -m py_compile scripts/eval/run_classification_eval.py scripts/eval/export_feedback_candidates.py` (pass)
- Row-count check:
  - golden rows: 36
  - fixture rows: 144

## 8) Practical recommendations
1. Do not switch to `live` mode until adapter wiring is complete and credential handling is centralized in backend callable path.
2. Keep `must_not_categories` strict and explicit for medical/hazardous cases; these should be hard fails in CI.
3. Promote user-correction rows into golden set only after manual approval; no auto-promotion.
4. Add prompt/version fields to live predictions once adapters are wired so regressions can be attributed cleanly.

## 9) Remaining gaps (intentional)
- Live adapters are scaffolds, not implemented.
- Fixture set is seeded synthetic data; replace progressively with field-captured + reviewed cases.
- CI workflow invocation (GitHub Actions) not added in this pass.

## 10) Verification update (ResultScreen compile blocker status)
Initial verification run had surfaced a constructor parse issue in `lib/services/result_pipeline.dart`.

Current state re-validated:
- Constructor now uses named optional parameter form (`TrainingDataService? trainingDataService`) and compiles.
- Re-run command:
  - `flutter test test/screens/result_screen_test.dart test/screens/result_screen_widget_test.dart test/golden/result_screen_v2_golden_test.dart`
- Result: all targeted ResultScreen tests passed.

Conclusion:
- The earlier blocker note is historical context, not current runtime state.

## 11) Next minimal step
Wire one live adapter first (backend callable route to `classifyImage`), run 10-case smoke eval in `live` mode, compare against offline fixtures, then lock CI gate thresholds.
