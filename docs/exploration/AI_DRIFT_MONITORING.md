# AI Drift Monitoring

**Status**: Seed — concept only, no implementation
**Priority**: 🔴 (P1 — maintains trust in deployed AI stack)
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) — P1/P2 Technical Architecture (topic 86)
**Related**: [MODEL_REGISTRY_AND_VERSIONING.md](MODEL_REGISTRY_AND_VERSIONING.md), [EVAL_LEADERBOARD_AND_MODEL_CARDS.md](EVAL_LEADERBOARD_AND_MODEL_CARDS.md), [AI_COST_TELEMETRY_AND_GUARDRAILS.md](AI_COST_TELEMETRY_AND_GUARDRAILS.md)

---

## Overview

AI models in production drift. Providers silently update model behavior (OpenAI `gpt-4o` alias). User upload patterns shift seasonally. City rule changes alter downstream accuracy. Drift monitoring is the safety net that detects when "what the model is doing" diverges from "what we tested."

Without drift monitoring:
- A silent provider update could halve accuracy on e-waste classification before anyone notices
- Rising user correction rate goes undetected for days
- City rule changes break disposal advice for an entire region
- Cost anomalies are caught at billing time, not in real-time

---

## Metrics to Monitor

### 1. Per-Category Accuracy (Proxy)

Since ground truth labels aren't available for every classification in production, use **proxy metrics**:

| Metric | Source | What It Detects |
|--------|--------|-----------------|
| User correction rate | `CorrectionDialog` events | Model getting it wrong enough for users to correct |
| Correction → confirm ratio | Correction history | Are users correcting more or confirming less? |
| Provider agreement rate | Multi-provider race mode | When providers diverge, likely drift signal |
| Confidence vs outcome | Logged confidence + user action | Calibration drift |

**Per-category tracking**: Aggregate these by waste category (plastic, paper, hazardous, e-waste, etc.). A drift in one category is masked by aggregate accuracy.

### 2. Confidence Calibration Error

**Expected Calibration Error (ECE)**: Measure the difference between model confidence and empirical accuracy.

- If model says 90% confidence but is only correct 70% of the time → ECE = 0.20 (calibration drift)
- Compute ECE per provider, per model version, per category
- Alert on ECE increase >0.05 from 7-day rolling baseline

**Example calibration check**:
```
Provider: Gemini Flash
Period: Last 7 days
ECE: 0.12 (baseline 0.08)
Delta: +0.04 — watch, not yet alert
Categories driving drift: hazardous (ECE 0.22), e-waste (ECE 0.18)
```

### 3. Provider Latency and Availability

| Metric | Alert Threshold | Action |
|--------|----------------|--------|
| P95 latency | >3s for cloud providers | Auto-fallback to secondary provider |
| Error rate (5xx, timeout) | >2% over 5 min window | Provider swap via FRC |
| Empty/refusal responses | >1% of total | Investigation ticket |

### 4. Cost per Classification

| Metric | Alert Threshold | Action |
|--------|----------------|--------|
| Cost per classification | >150% of budgeted | Investigate prompt bloat or provider change |
| Total daily AI spend | >120% of daily budget | Cap or provider downgrade |
| Token usage per call | >200% of typical | Prompt efficiency review |

### 5. User Correction Rate Changes

The single most actionable drift signal:

- 7-day rolling average of correction rate per provider
- Per-category correction rate (e-waste correction rate spike = model confused about e-waste)
- Correction → confirm ratio (if users correct more and confirm less, trust is declining)

---

## Statistical Methods

| Method | Best For | Alert Threshold |
|--------|----------|----------------|
| **Population Stability Index (PSI)** | Input distribution shift (user uploads changing over time) | PSI > 0.25 → significant shift |
| **KL Divergence** | Detecting subtle distribution changes in tail categories | >0.1 from baseline |
| **Kolmogorov-Smirnov test** | Continuous feature drift (image brightness, size, etc.) | p < 0.01 |
| **Chi-squared test** | Categorical feature drift (category distribution changes) | p < 0.01 |
| **Rolling Z-score** | Cost and latency anomalies | |z| > 3 |

---

## Detecting Silent Provider Updates

Since OpenAI/Gemini can update model behavior without version bumps:

1. **Shadow evaluation**: Every N minutes, run a golden dataset (50-200 fixed inputs) through the production provider endpoint. Compare outputs against cached expected outputs.
   - **Semantic similarity**: Use embeddings to compare current vs cached outputs. Cosine similarity drop >0.05 → possible model update.
   - **Structural checks**: JSON structure, field presence, output length.
   - **Safety checks**: Run safety-critical categories through golden set; any failure is a P0 incident.

2. **Response metadata monitoring**: Track provider response metadata (finish reason, token usage, latency patterns). Shifts often precede behavioral changes.

3. **Cross-provider consistency**: If racing two providers, track their agreement rate over time. A sudden drop in agreement = likely one provider changed.

---

## Local Rule Error Spikes

City-specific accuracy monitoring:

- **Slice by ruleset_version**: Track correction rate per city plugin version
- **Cross-city comparison**: If BBMP_v3 error rate spikes but BMC_v2 stays flat → problem is BBMP_v3, not model-wide
- **Rule coverage tests**: For each city ruleset version, periodically test known-must-pass cases (e.g., "batteries are hazardous in BBMP")

---

## Dashboard Design

### One-Glance View

```
┌─────────────────────────────────────────────────────────┐
│  AI Stack Health                      Status: 🟢 ALL GOOD │
├─────────────────────────────────────────────────────────┤
│  Accuracy Proxy (correction rate): 3.2% (baseline 3.5%)  OK │
│  Calibration Error: 0.09 (baseline 0.08)                 OK │
│  AI Cost Today: $4.32 (budget $6.00)                     OK │
│  Provider Latency (P95): 1.2s Gemini, 2.1s OpenAI        OK │
│  Active Incidents: 0                                      │
├─────────────────────────────────────────────────────────┤
│  Category Drilldown:                                      │
│  🟢 Plastic     2.1% correction rate                     │
│  🟢 Paper       1.8% correction rate                     │
│  🟡 Hazardous   5.2% correction rate (baseline 4.1%)     │
│  🔴 E-waste     8.7% correction rate (baseline 4.5%)     │
│  🟢 Organic     2.3% correction rate                     │
└─────────────────────────────────────────────────────────┘
```

### Drill-Down View

Clicking a category shows:
- Trend chart (correction rate over 30 days, with deployment annotations)
- Top-3 misclassification pairs (e.g., "e-waste classified as general waste 40% of corrections")
- Provider breakdown (which provider is performing worse on this category)
- Sample images from corrections (privacy-safe, anonymized)

---

## Alert Tiers

| Tier | Threshold | Response SLA | Action |
|------|-----------|-------------|--------|
| **P0** | Safety-critical category correction rate >10% | 15 min | Auto-rollback model, page on-call |
| **P1** | Overall correction rate up >5% from baseline | 1 hour | Investigation, canary revert |
| **P2** | ECE up >0.05, PSI >0.25 | 4 hours | Investigation ticket, no auto-action |
| **P3** | Latency up 50%, cost up 20% | 24 hours | Investigation, no auto-action |

---

## Implementation Path

1. **Phase 0** (lightweight): Add correction rate logging per category + provider. Dashboard in Google Data Studio or similar. Manual review cadence (weekly).
2. **Phase 1** (automated alerts): PSI monitoring on input distribution. ECE computation. Threshold-based alerts to Slack.
3. **Phase 2** (shadow eval): Golden dataset shadow evaluation scheduled every 6 hours. Silent provider change detection.
4. **Phase 3** (auto-rollback): Wire drift alerts to FRC kill switches. Auto-rollback for P0 thresholds. Audit trail for every action.

---

## Open Questions

- How large should the shadow evaluation golden set be? (100 cases × both providers = 200 API calls per run)
- Should drift monitoring be a Firebase Cloud Function or a separate cron job?
- How do we handle drift in local rule accuracy separately from model accuracy?
- What is the minimum viable monitoring before it's "production grade"?
- Should we store sample inputs from production for post-hoc analysis? (Privacy implications)
