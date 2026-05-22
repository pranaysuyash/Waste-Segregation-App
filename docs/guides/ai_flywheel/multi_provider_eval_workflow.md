# Multi-provider Eval Workflow

## Purpose
Build side-by-side provider snapshots for backend, openai, gemini, and local route prototypes.

## Recorded fixtures
- `test/fixtures/ai_eval/recorded_outputs/recorded_backend.jsonl`
- `test/fixtures/ai_eval/recorded_outputs/recorded_openai.jsonl`
- `test/fixtures/ai_eval/recorded_outputs/recorded_gemini.jsonl`
- `test/fixtures/ai_eval/recorded_outputs/recorded_local.jsonl`

## Merge command

```bash
dart run tool/ai_eval_merge_records.dart --inputs test/fixtures/ai_eval/recorded_outputs/recorded_backend.jsonl,test/fixtures/ai_eval/recorded_outputs/recorded_openai.jsonl,test/fixtures/ai_eval/recorded_outputs/recorded_gemini.jsonl,test/fixtures/ai_eval/recorded_outputs/recorded_local.jsonl --out build/reports/ai_eval/merged_records.jsonl
```

## Next step
Convert merged records to eval outcome JSON and run `tool/router_compare_report.dart` for provider-level comparison metrics.

## Direct per-provider eval runs

```bash
dart run tool/ai_eval_runner.dart --mode recorded --recorded-file test/fixtures/ai_eval/recorded_outputs/recorded_backend.jsonl --provider-label backend/classifyImage
dart run tool/ai_eval_runner.dart --mode recorded --recorded-file test/fixtures/ai_eval/recorded_outputs/recorded_openai.jsonl --provider-label openai/direct
dart run tool/ai_eval_runner.dart --mode recorded --recorded-file test/fixtures/ai_eval/recorded_outputs/recorded_gemini.jsonl --provider-label gemini/direct
dart run tool/ai_eval_runner.dart --mode recorded --recorded-file test/fixtures/ai_eval/recorded_outputs/recorded_local.jsonl --provider-label local/stub
```
