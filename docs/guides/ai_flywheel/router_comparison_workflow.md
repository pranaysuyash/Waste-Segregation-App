# Router Comparison Workflow

## Purpose
Compare backend/local/provider routes on quality, safety, cost, latency, and fallback behavior.

## Input
- `build/reports/ai_eval/latest.json` from eval runner.

## Command

```bash
dart run tool/router_compare_report.dart --input build/reports/ai_eval/latest.json --out build/reports/ai_eval/router_compare.json
```

## Output metrics
- accuracy by provider
- safety-critical failures
- must-not violations
- local-rule failures
- average latency
- average estimated cost
- cache hit rate
- fallback rate
- provider failure rate

## Intended threshold usage
- prefer local when confidence high and no safety-rule risk
- escalate uncertain or safety-critical cases to backend
- mark disagreement cases for reviewer queue
