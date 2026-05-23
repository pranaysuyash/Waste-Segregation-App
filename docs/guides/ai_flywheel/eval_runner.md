# Eval Runner Guide

Run offline:
```bash
dart run tool/ai_eval_runner.dart --mode offline
```

Run recorded provider snapshots:
```bash
dart run tool/ai_eval_runner.dart --mode recorded --recorded-file test/fixtures/ai_eval/recorded_outputs/recorded_backend.jsonl --provider-label backend/classifyImage
```

Live mode is disabled unless:
```bash
AI_EVAL_ENABLE_LIVE=true dart run tool/ai_eval_runner.dart --mode live
```
