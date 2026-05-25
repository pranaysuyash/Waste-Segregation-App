# Eval Runner Guide

Run offline:
```bash
dart run tool/ai_eval_runner.dart --mode offline
```

> Offline mode is a **scorer-smoke path** (harness validation), not a provider quality readiness signal by itself.

Run recorded provider snapshots:
```bash
dart run tool/ai_eval_runner.dart --mode recorded --recorded-file test/fixtures/ai_eval/recorded_outputs/recorded_backend.jsonl --provider-label backend/classifyImage
```

Generate the split harness vs provider-quality acceptance view:
```bash
dart run tool/ai_flywheel_acceptance_report.dart \
  --quality-min-accuracy 0.95 \
  --quality-max-must-not 0 \
  --quality-max-safety 0 \
  --quality-max-local-rule 0
```

Live mode is disabled unless:
```bash
AI_EVAL_ENABLE_LIVE=true dart run tool/ai_eval_runner.dart --mode live
```
