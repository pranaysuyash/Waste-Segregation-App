#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

mkdir -p build/reports/ai_eval build/reports/ai_dataset/latest build/reports/ai_review

echo "[1/11] Running flywheel foundation tests"
flutter test test/ai_flywheel/flywheel_foundation_test.dart

echo "[2/11] Offline eval run"
dart run tool/ai_eval_runner.dart --mode offline
cp build/reports/ai_eval/latest.json build/reports/ai_eval/offline_latest.json

echo "[3/11] Provider eval runs"
dart run tool/ai_eval_runner.dart --mode recorded --recorded-file test/fixtures/ai_eval/recorded_outputs/recorded_backend.jsonl --provider-label backend/classifyImage
cp build/reports/ai_eval/latest.json build/reports/ai_eval/recorded_backend_latest.json

dart run tool/ai_eval_runner.dart --mode recorded --recorded-file test/fixtures/ai_eval/recorded_outputs/recorded_openai.jsonl --provider-label openai/direct
cp build/reports/ai_eval/latest.json build/reports/ai_eval/recorded_openai_latest.json

dart run tool/ai_eval_runner.dart --mode recorded --recorded-file test/fixtures/ai_eval/recorded_outputs/recorded_gemini.jsonl --provider-label gemini/direct
cp build/reports/ai_eval/latest.json build/reports/ai_eval/recorded_gemini_latest.json

dart run tool/ai_eval_runner.dart --mode recorded --recorded-file test/fixtures/ai_eval/recorded_outputs/recorded_local.jsonl --provider-label local/stub
cp build/reports/ai_eval/latest.json build/reports/ai_eval/recorded_local_latest.json

echo "[4/11] Merge multi-provider records"
dart run tool/ai_eval_merge_records.dart --inputs test/fixtures/ai_eval/recorded_outputs/recorded_backend.jsonl,test/fixtures/ai_eval/recorded_outputs/recorded_openai.jsonl,test/fixtures/ai_eval/recorded_outputs/recorded_gemini.jsonl,test/fixtures/ai_eval/recorded_outputs/recorded_local.jsonl --out build/reports/ai_eval/merged_records.jsonl

echo "[5/11] Router comparison report"
dart run tool/router_compare_report.dart --input build/reports/ai_eval/recorded_backend_latest.json --out build/reports/ai_eval/router_compare_backend.json

echo "[6/11] Dataset export"
dart run tool/ai_dataset_exporter.dart --input=test/fixtures/ai_eval/recorded_outputs/training_candidates_sample.jsonl --out=build/reports/ai_dataset/latest --version=waste-v0.1

echo "[7/11] Annotation workflow export/apply/report"
dart run tool/ai_review_workflow.dart --mode export --input test/fixtures/ai_eval/recorded_outputs/training_candidates_sample.jsonl --out build/reports/ai_review/review_template.jsonl

dart run tool/ai_review_workflow.dart --mode apply --input test/fixtures/ai_eval/recorded_outputs/training_candidates_sample.jsonl --decisions tool/templates/review_decisions_template.jsonl --out build/reports/ai_review/updated_candidates.jsonl --reviewer reviewer@example.com

dart run tool/ai_review_workflow.dart --mode report --out build/reports/ai_review/updated_candidates.jsonl
dart run tool/ai_review_dashboard.dart --input build/reports/ai_review/updated_candidates.jsonl --out-json build/reports/ai_review/dashboard.json --out-md build/reports/ai_review/dashboard.md


echo "[8/11] Seed coverage report"
dart run tool/ai_eval_seed_coverage_report.dart --input test/fixtures/ai_eval/golden_cases.jsonl --out build/reports/ai_eval/seed_coverage_report.json

echo "[9/11] Evidence summary"
dart run tool/ai_flywheel_evidence_summary.dart --out build/reports/ai_flywheel/FINAL_EVIDENCE_SUMMARY.md

echo "[10/11] Acceptance report"
dart run tool/ai_flywheel_acceptance_report.dart --out build/reports/ai_flywheel/acceptance_report.json

echo "[11/11] Verification complete"
echo "Artifacts:"
echo "  build/reports/ai_eval/latest.json"
echo "  build/reports/ai_eval/offline_latest.json"
echo "  build/reports/ai_eval/recorded_backend_latest.json"
echo "  build/reports/ai_eval/recorded_openai_latest.json"
echo "  build/reports/ai_eval/recorded_gemini_latest.json"
echo "  build/reports/ai_eval/recorded_local_latest.json"
echo "  build/reports/ai_eval/merged_records.jsonl"
echo "  build/reports/ai_eval/router_compare_backend.json"
echo "  build/reports/ai_eval/router_strategy_recommendations.md"
echo "  build/reports/ai_eval/calibration_report.json"
echo "  build/reports/ai_eval/seed_coverage_report.json"
echo "  build/reports/ai_dataset/latest/manifest.jsonl"
echo "  build/reports/ai_dataset/latest/labels.jsonl"
echo "  build/reports/ai_dataset/latest/datasheet.md"
echo "  build/reports/ai_dataset/latest/excluded.jsonl"
echo "  build/reports/ai_dataset/latest/version.json"
echo "  build/reports/ai_review/review_template.jsonl"
echo "  build/reports/ai_review/updated_candidates.jsonl"
echo "  build/reports/ai_review/dashboard.json"
echo "  build/reports/ai_review/dashboard.md"
echo "  build/reports/ai_flywheel/acceptance_report.json"
echo "  build/reports/ai_flywheel/FINAL_EVIDENCE_SUMMARY.md"

echo "Post-run artifact assertions"
required_artifacts=(
  "build/reports/ai_eval/latest.json"
  "build/reports/ai_eval/offline_latest.json"
  "build/reports/ai_eval/recorded_backend_latest.json"
  "build/reports/ai_eval/recorded_openai_latest.json"
  "build/reports/ai_eval/recorded_gemini_latest.json"
  "build/reports/ai_eval/recorded_local_latest.json"
  "build/reports/ai_eval/merged_records.jsonl"
  "build/reports/ai_eval/router_compare_backend.json"
  "build/reports/ai_eval/router_strategy_recommendations.md"
  "build/reports/ai_eval/calibration_report.json"
  "build/reports/ai_eval/seed_coverage_report.json"
  "build/reports/ai_dataset/latest/manifest.jsonl"
  "build/reports/ai_dataset/latest/labels.jsonl"
  "build/reports/ai_dataset/latest/datasheet.md"
  "build/reports/ai_dataset/latest/excluded.jsonl"
  "build/reports/ai_dataset/latest/version.json"
  "build/reports/ai_review/review_template.jsonl"
  "build/reports/ai_review/updated_candidates.jsonl"
  "build/reports/ai_review/dashboard.json"
  "build/reports/ai_review/dashboard.md"
  "build/reports/ai_flywheel/acceptance_report.json"
  "build/reports/ai_flywheel/FINAL_EVIDENCE_SUMMARY.md"
)

missing_count=0
for path in "${required_artifacts[@]}"; do
  if [[ ! -f "$path" ]]; then
    echo "Missing required artifact: $path" >&2
    missing_count=$((missing_count + 1))
  fi
done

if [[ $missing_count -gt 0 ]]; then
  echo "Verification failed: $missing_count required artifacts missing." >&2
  exit 1
fi

echo "Verification artifacts complete."

echo "Post-run acceptance assertions"
python3 - <<'PY'
import json, sys
path = 'build/reports/ai_flywheel/acceptance_report.json'
with open(path) as f:
    report = json.load(f)
if report.get('allPassed') is not True:
    print('Verification failed: acceptance_report.json has allPassed != true', file=sys.stderr)
    print(f"passed={report.get('passed')} total={report.get('total')}", file=sys.stderr)
    sys.exit(1)
print('Acceptance report allPassed=true')
PY

echo "Post-run release gate assertions"
python3 - <<'PY'
import json, sys

acceptance = json.load(open('build/reports/ai_flywheel/acceptance_report.json'))
router = json.load(open('build/reports/ai_eval/router_compare_backend.json'))
cal = json.load(open('build/reports/ai_eval/calibration_report.json'))

provider_gate = acceptance.get('providerQualityGate', {}) or {}
provider_rows = provider_gate.get('evaluatedProviders', {}) or {}
backend_gate = provider_rows.get('backend', {}) or {}
if backend_gate and backend_gate.get('passed') is not True:
    print('Release gate failed: backend provider quality gate did not pass', file=sys.stderr)
    print(f"failureReasons={backend_gate.get('failureReasons')}", file=sys.stderr)
    sys.exit(1)

pair_disagree = cal.get('providerPairDisagreement', {}) or {}
max_pair = max(pair_disagree.values()) if pair_disagree else 0
if max_pair > 80:
    print(f'Release gate failed: providerPairDisagreement max={max_pair} > 80', file=sys.stderr)
    sys.exit(1)

providers = router.get('providers', {}) or {}
backend = providers.get('backend', {})
if backend:
    acc = float(backend.get('accuracy', 0))
    if acc < 0.95:
        print(f'Release gate failed: backend accuracy={acc:.3f} < 0.95', file=sys.stderr)
        sys.exit(1)

print('Release gates passed')
PY
