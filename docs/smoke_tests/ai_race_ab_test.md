# AI Race A/B Test — Smoke Test Checklist

**Goal:** Compare behavior and performance of the existing sequential `analyzeWasteImage` flow vs. the new parallel `analyzeWithRace` flow.

Duration: 72 hours of continuous sampling is recommended for initial evaluation.

## Metrics to collect

- Success rate (per-method): number of successful classifications / total requests
- End-to-end latency (median, p50/p90/p99) from request start to classification ready
- Failure modes: parse errors, timeout, token errors, auth errors
- Cost signal: approximate added token consumption if both calls were sent
- Winner model distribution for race requests (OpenAI vs Gemini)

## How to run

1. Deploy staging build with new code.
2. Configure the service:
   ```dart
   aiService.setRacePercentage(0.5); // 50% routing to race method
   ```
3. Generate traffic: run 500–1000 classification requests across varied image sizes (3MB, 1MB, 200KB). Use a test harness or manual sampling.
4. Collect logs (grep):
   - `A/B routing: using race-based analysis` → verify ~50% routing
   - `Race analysis completed` → check `winner_model` and `duration_ms`
   - Any `Failed to parse` or `No JSON found` logs
5. Export metrics and compare sequential vs race samples.

## Acceptance criteria

- Latency: race method median latency < sequential method median latency OR success rate significantly improved under simulated partial outage.
- Success rate: no higher failure rate for race method.
- Cost: token consumption increase (if any) remains acceptable at experimental percentage. If costs spike, lower the percentage.

## Rollout plan

- If race method meets thresholds, increase `_racePercentage` gradually: 0.5 → 0.8 → 1.0 and promote to default (after cost assessment).
- Add a telemetry dashboard to compare `model_usage` and `model_costs` across methods.
