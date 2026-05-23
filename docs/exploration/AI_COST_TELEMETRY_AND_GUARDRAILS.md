# AI Cost Telemetry & Guardrails

**Date**: 2026-05-23
**Status**: Exploration — documenting existing system + gaps
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) entry 10
**Decision this unblocks**: Per-tier soft/hard caps, automatic provider downgrade, free-tier fair-use enforcement
**Kill criteria**: If AI costs are < $0.01/MAU/month regardless of usage, guardrails are unnecessary overhead

---

## 1. Current System

The cost management system is already substantial. Three services form a layered stack:

### Dynamic Pricing Service (`lib/services/dynamic_pricing_service.dart`)

- **Purpose**: Central pricing data source, loaded from Remote Config with local fallbacks
- **Pricing model**: Per-1K-token costs for each model (input + output separately)
- **Models tracked**: gpt-4.1-nano, gpt-4o-mini, gpt-4.1-mini, gemini-2.0-flash
- **Budget tiers**: Daily ($5), Weekly ($30), Monthly ($100)
- **Batch discount**: 50% (configurable via Remote Config)
- **Spending tracking**: In-memory maps for daily/weekly/monthly spend per model
- **Gap**: Spending data is in-memory only — lost on app restart. No persistence to Hive/Firestore.

### Cost Guardrail Service (`lib/services/cost_guardrail_service.dart`)

- **Purpose**: Real-time budget monitoring, alerting, and automatic batch mode enforcement
- **Monitoring**: 1-minute periodic check against all budget periods
- **Warning thresholds**: 50% (info), 75% (warning), 90% (high), 100% (exceeded)
- **Batch mode enforcement**: When threshold exceeded, force all analyses to batch mode
- **Streams**: `batchModeEnforced`, `costAlerts`, `budgetUtilization` — reactive UI updates
- **Emergency override**: `temporarilyDisableGuardrails(duration, reason)` with auto-re-enable
- **Gap**: Alerts are in-memory only (last 50). No server-side cost recording.

### AI Cost Tracker (`lib/services/ai_cost_tracker.dart`)

- **Purpose**: Per-operation cost estimation and recording
- **Flow**: `estimateCost()` before operation → `recordActualCost()` after
- **Cost estimate includes**: model cost, batch savings, affordability, recommended speed, budget utilization
- **Gap**: Recording is local only. No Firestore/cloud sync of actual costs.

---

## 2. Cost Model Per Classification

| Provider | Model | Input Tokens | Output Tokens | Cost (Instant) | Cost (Batch) |
|----------|-------|-------------|--------------|----------------|--------------|
| OpenAI | gpt-4.1-nano | ~1500 | ~800 | ~$0.000735 | ~$0.000368 |
| OpenAI | gpt-4o-mini | ~1500 | ~800 | ~$0.000735 | ~$0.000368 |
| OpenAI | gpt-4.1-mini | ~1500 | ~800 | ~$0.001365 | ~$0.000683 |
| Gemini | gemini-2.0-flash | ~1500 | ~800 | ~$0.000353 | ~$0.000176 |
| Backend | classifyImage proxy | ~1500 | ~800 | Same as provider | Same as provider |
| Layer 0 | Deterministic | 0 | 0 | $0 | $0 |
| Layer 1 | SmolVLM (future) | 0 | 0 | $0 | $0 |

### Per-MAU cost envelope

| Usage Pattern | Monthly Classifications | Provider Cost | After Layer 0 (30%) | After Layer 1 (30% more) |
|--------------|------------------------|---------------|---------------------|-------------------------|
| Light user | 10 | ~$0.007 | ~$0.005 | ~$0.002 |
| Average user | 60 | ~$0.044 | ~$0.031 | ~$0.013 |
| Power user | 200 | ~$0.147 | ~$0.103 | ~$0.044 |
| Heavy user | 500 | ~$0.368 | ~$0.257 | ~$0.110 |

---

## 3. Gaps

### Critical: No server-side cost recording

The client tracks spending in memory, but there is **no server-side record** of actual AI costs. The `classifyImage` backend proxy should record costs in Firestore, but the current implementation relies on the client calling `recordActualCost()`. A malicious or buggy client can report $0 for every call.

**Fix**: The `classifyImage` Firebase Function should record actual provider costs server-side, independent of client reporting.

### Critical: No per-user cost cap enforcement

Budget limits ($5/day, $30/week, $100/month) are **global**, not per-user. A single heavy user can exhaust the entire budget. Free-tier users have no separate cap.

**Fix**: Per-user spending counters in Firestore. Free tier gets lower caps (e.g., $0.50/day). Premium gets higher caps.

### High: Spending data lost on restart

`DynamicPricingService` stores spending in memory (`Map<String, double>`). App restart resets all counters. A user who spends $4.99 and restarts starts fresh — the daily budget is never truly enforced.

**Fix**: Persist spending to Hive with daily/weekly/monthly reset logic.

### Medium: No provider cost comparison dashboard

The cost tracker records per-operation costs but has no aggregation or comparison view. Operators cannot see "OpenAI cost $X this week vs Gemini cost $Y."

**Fix**: Aggregate costs in Firestore, build a simple operator view or CLI report.

### Low: No cost anomaly detection

The `CostAlertType.anomalyDetected` enum value exists but is never triggered. There is no statistical anomaly detection.

**Fix**: Simple threshold-based detection: if hourly spend > 2× the rolling average, trigger anomaly alert.

---

## 4. Recommendations

### Phase 1: Server-side cost recording (P0)

In `functions/src/index.ts`, the `classifyImage` function should:
1. Record actual provider cost in a `ai_costs/{userId}` Firestore document
2. Enforce per-user daily/weekly/monthly caps server-side
3. Return HTTP 429 when cap exceeded, not just client-side blocking

### Phase 2: Persistent spending tracking (P1)

- `DynamicPricingService` should persist spending to Hive (daily/weekly/monthly buckets)
- Reset logic: clear daily at midnight, weekly on Monday, monthly on 1st
- Recover state on app restart

### Phase 3: Per-tier cost caps (P1)

| Tier | Daily Cap | Weekly Cap | Monthly Cap | Batch-Only Threshold |
|------|-----------|------------|-------------|---------------------|
| Anonymous | $0.50 | $2.00 | $5.00 | 80% |
| Free (registered) | $1.00 | $5.00 | $15.00 | 80% |
| Premium | $5.00 | $30.00 | $100.00 | 90% |

### Phase 4: Operator dashboard (P2)

- Firestore `ai_costs` collection aggregated by day/week/month
- Per-provider cost breakdown
- Top-spending users (anonymised)
- Cost trend charts

---

## 5. Related

- [Token Economy & Pricing Coherence](TOKEN_ECONOMY_AND_PRICING_COHERENCE.md) — token-level cost representation
- [Backend Classification Proxy](../EXPLORATION_TOPICS.md#g4-backend-classification-proxy-) — server-side cost recording point
- [AI Cost Telemetry](../EXPLORATION_TOPICS.md#10-ai-cost-telemetry--guardrails-) — parent index entry
- `lib/services/cost_tracking_interceptor.dart` — HTTP interceptor for cost logging
