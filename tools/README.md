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
- router calibration + disagreement report
- dataset export
- annotation workflow export/apply/report
- review dashboard generation

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

## 10) `../tool/ai_review_dashboard.dart`
Generates operational review queue analytics from reviewed candidate JSONL.

Usage:
```bash
dart run tool/ai_review_dashboard.dart --input build/reports/ai_review/updated_candidates.jsonl --out-json build/reports/ai_review/dashboard.json --out-md build/reports/ai_review/dashboard.md
```

## 11) `check_policy_sources.dart`
Monitors policy source URLs for drift using ETag + SHA-256 hash and updates
`tools/policy_source_manifest.json`.

Usage:

```bash
dart run tools/check_policy_sources.dart
```

Inputs/outputs:
- Manifest: `tools/policy_source_manifest.json`
- Report: `build/reports/policy_source_check/latest.json`

## 12) `sim_drive.py`
iOS-simulator persona-flow driver over WebDriverAgent (W3C actions API). Used by the
runtime persona sims (see `docs/review/RUNTIME_FLOW_TEST_REPORT_2026-10-05.md`) to
tap/swipe/type when neither Simulator.app GUI nor idb HID are available (trimmed
Xcode installs). Coordinates are screen points (393x852 for iPhone 16).

One-time WDA setup:
```bash
git clone --depth 1 https://github.com/appium/WebDriverAgent.git /tmp/wda
cd /tmp/wda && xcodebuild build-for-testing -scheme WebDriverAgentRunner \
  -destination 'platform=iOS Simulator,id=<UDID>' \
  -derivedDataPath /tmp/wda-dd CODE_SIGNING_ALLOWED=NO
xcodebuild test-without-building \
  -xctestrun /tmp/wda-dd/Build/Products/WebDriverAgentRunner_*.xctestrun \
  -destination 'platform=iOS Simulator,id=<UDID>' &   # serves http://127.0.0.1:8100
```

Driver usage:
```bash
python3 tools/sim_drive.py tap 198 520
python3 tools/sim_drive.py swipe 300 700 90 700 --ms 350
python3 tools/sim_drive.py type "Sharma Family"
python3 tools/sim_drive.py source dump.xml
```

Screenshots stay on `xcrun simctl io <UDID> screenshot <path>` (faster, no session).

