# Router Metrics Guide

```bash
dart run tool/router_compare_report.dart --input build/reports/ai_eval/latest.json --out build/reports/ai_eval/router_compare.json
```

Use a policy pack file to keep recommendations aligned with runtime guardrails:
```bash
dart run tool/router_compare_report.dart \
  --input build/reports/ai_eval/latest.json \
  --out build/reports/ai_eval/router_compare.json \
  --policy-pack-file path/to/ai_router_policy_pack.json
```

Also writes:
- `build/reports/ai_eval/router_strategy_recommendations.md`
- `build/reports/ai_eval/calibration_report.json`

Includes:
- accuracy
- safety failures
- must-not violations
- local-rule failures
- multi-item failures
- confidence behavior flags
- latency/cost/cache/fallback/failure
- disagreement case matrix
- provider pair disagreement counts
- confidence calibration bins per provider
