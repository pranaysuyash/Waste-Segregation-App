#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

mkdir -p build/reports/ai_eval build/reports/ai_dataset/latest build/reports/ai_review

echo "[1/10] Running flywheel foundation tests"
flutter test test/ai_flywheel/flywheel_foundation_test.dart

echo "[2/10] Offline eval run"
dart run tool/ai_eval_runner.dart --mode offline
cp build/reports/ai_eval/latest.json build/reports/ai_eval/offline_latest.json

echo "[3/10] Provider eval runs"
dart run tool/ai_eval_runner.dart --mode recorded --recorded-file test/fixtures/ai_eval/recorded_outputs/recorded_backend.jsonl --provider-label backend/classifyImage
cp build/reports/ai_eval/latest.json build/reports/ai_eval/recorded_backend_latest.json

dart run tool/ai_eval_runner.dart --mode recorded --recorded-file test/fixtures/ai_eval/recorded_outputs/recorded_openai.jsonl --provider-label openai/direct
cp build/reports/ai_eval/latest.json build/reports/ai_eval/recorded_openai_latest.json

dart run tool/ai_eval_runner.dart --mode recorded --recorded-file test/fixtures/ai_eval/recorded_outputs/recorded_gemini.jsonl --provider-label gemini/direct
cp build/reports/ai_eval/latest.json build/reports/ai_eval/recorded_gemini_latest.json

dart run tool/ai_eval_runner.dart --mode recorded --recorded-file test/fixtures/ai_eval/recorded_outputs/recorded_local.jsonl --provider-label local/stub
cp build/reports/ai_eval/latest.json build/reports/ai_eval/recorded_local_latest.json

echo "[4/10] Merge multi-provider records"
dart run tool/ai_eval_merge_records.dart --inputs test/fixtures/ai_eval/recorded_outputs/recorded_backend.jsonl,test/fixtures/ai_eval/recorded_outputs/recorded_openai.jsonl,test/fixtures/ai_eval/recorded_outputs/recorded_gemini.jsonl,test/fixtures/ai_eval/recorded_outputs/recorded_local.jsonl --out build/reports/ai_eval/merged_records.jsonl

echo "[5/10] Router comparison report"
dart run tool/router_compare_report.dart --input build/reports/ai_eval/recorded_backend_latest.json --out build/reports/ai_eval/router_compare_backend.json

echo "[6/10] Dataset export"
dart run tool/ai_dataset_exporter.dart --input=test/fixtures/ai_eval/recorded_outputs/training_candidates_sample.jsonl --out=build/reports/ai_dataset/latest --version=waste-v0.1

echo "[7/10] Annotation workflow export/apply/report"
dart run tool/ai_review_workflow.dart --mode export --input test/fixtures/ai_eval/recorded_outputs/training_candidates_sample.jsonl --out build/reports/ai_review/review_template.jsonl

dart run tool/ai_review_workflow.dart --mode apply --input test/fixtures/ai_eval/recorded_outputs/training_candidates_sample.jsonl --decisions tool/templates/review_decisions_template.jsonl --out build/reports/ai_review/updated_candidates.jsonl --reviewer reviewer@example.com

dart run tool/ai_review_workflow.dart --mode report --out build/reports/ai_review/updated_candidates.jsonl


echo "[8/10] Acceptance report"
dart run tool/ai_flywheel_acceptance_report.dart --out build/reports/ai_flywheel/acceptance_report.json


echo "[9/10] Seed coverage report"
dart run tool/ai_eval_seed_coverage_report.dart --input test/fixtures/ai_eval/golden_cases.jsonl --out build/reports/ai_eval/seed_coverage_report.json

echo "[10/10] Verification complete"
echo "Artifacts:"
echo "  build/reports/ai_eval/latest.json"
echo "  build/reports/ai_eval/offline_latest.json"
echo "  build/reports/ai_eval/recorded_backend_latest.json"
echo "  build/reports/ai_eval/recorded_openai_latest.json"
echo "  build/reports/ai_eval/recorded_gemini_latest.json"
echo "  build/reports/ai_eval/recorded_local_latest.json"
echo "  build/reports/ai_eval/merged_records.jsonl"
echo "  build/reports/ai_eval/router_compare_backend.json"
echo "  build/reports/ai_eval/seed_coverage_report.json"
echo "  build/reports/ai_dataset/latest/manifest.jsonl"
echo "  build/reports/ai_dataset/latest/labels.jsonl"
echo "  build/reports/ai_dataset/latest/datasheet.md"
echo "  build/reports/ai_dataset/latest/version.json"
echo "  build/reports/ai_review/review_template.jsonl"
echo "  build/reports/ai_review/updated_candidates.jsonl"
echo "  build/reports/ai_flywheel/acceptance_report.json"
