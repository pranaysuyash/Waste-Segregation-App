# Unified Observability Dashboard — Crash, Performance, Cost & AI Quality

**Status**: Exploration — pre-design
**Priority**: P2 (🟡)
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) — Topic #41
**Related docs**: `AI_COST_TELEMETRY_AND_GUARDRAILS.md`, `AI_DRIFT_MONITORING.md`, `ANALYTICS_SCHEMA_GOVERNANCE.md`, `FIRESTORE_COST_AND_INDEXING.md`

---

## Why This Matters

The app has multiple observability surfaces — Firebase Crashlytics, Performance Monitoring, Firestore usage, AI cost tracking, and custom analytics — but no single view that correlates them. When AI costs spike, is that correlated with a specific provider model change, an onboarding campaign, a crash regression, or a bot attack? Today, answering that requires context-switching across 3-4 tools.

A unified observability dashboard answers:
- **Cost**: What is our per-classification cost trending? Which provider/category is most expensive?
- **Quality**: Is classification accuracy drifting? Is the correction rate increasing?
- **Performance**: Are scan times increasing? Which provider has the best latency?
- **Reliability**: Is any provider failing more than usual? What failure modes dominate?
- **Safety**: Are safety-critical categories maintaining accuracy? Are hazardous items ever misclassified?

---

## Key Questions

- What's the minimum useful set of metrics for a startup team (no dedicated SRE)?
- How do we correlate AI spend changes with model version changes or user behavior changes?
- What alerting thresholds catch real problems without generating alert fatigue?
- How should the dashboard compose Firebase tools with AI-specific observability data?
- What is the operator workflow: daily check, alert response, weekly review, release comparison?

---

## Research Findings

### 1. Metric Taxonomy

| Category | Key Metrics | Source |
|---|---|---|
| **Stability** | Crash-free rate, ANR rate, OOM rate | Firebase Crashlytics |
| **Performance** | App start time, screen render time, scan end-to-end latency | Firebase Performance |
| **AI Cost** | Cost/classification, cost/provider, cost/category, daily burn | `ai_cost_tracker.dart` + Firestore |
| **AI Quality** | Classification accuracy (correction rate), confidence calibration error, top-1/3 accuracy | Eval harness + user feedback |
| **AI Reliability** | Provider error rate (by type), timeout rate, safety refusal rate | `ai_failure.dart` records |
| **Firestore Cost** | Document reads/writes/day, per-collection cost, index usage | Firestore Usage / GCP console |
| **User Behavior** | DAU, scans/user, correction rate, premium conversion | Analytics events |
| **Drift** | Per-category accuracy trend, confidence score trend, latency trend | Eval comparisons |

### 2. Dashboard Composition Strategy

**Layered approach** (recommended for a small team):

**Layer 1: Firebase Console** (daily pulse check)
- Crashlytics crash-free rate + top errors
- Performance Monitoring key traces (scan flow)
- Remote Config current values
- **Cost to maintain**: $0 (included in Firebase plan)

**Layer 2: Custom metrics in Google Cloud Monitoring**
- AI cost per classification (export Firestore cost records to BigQuery)
- Provider error rates (export event data)
- User correction trends
- **Cost to maintain**: $0-30/month (BigQuery free tier covers small volumes)

**Layer 3: AI-specific observability tool** (for model/prompt evaluation)
- Langfuse, Braintrust, or similar — trace each classification, compare providers, track prompt versions
- Eval leaderboard with per-category accuracy slices
- Drift detection alerts
- **Cost to maintain**: $0-100/month (self-hosted Langfuse is free)

**Layer 4: Unified dashboard view** (Grafana or Looker Studio)
- Compose metrics from all layers into a single view
- Alerting across metrics (e.g., "cost spike AND accuracy drop AND no crash regression")
- **Cost to maintain**: $0 (Grafana Cloud free tier, or self-hosted)

### 3. Alerting Philosophy

| Severity | Response Time | Examples |
|---|---|---|
| **Critical (P0)** | < 15 minutes | Classification pipeline 100% failure, safety-critical category accuracy < 80% |
| **High (P1)** | < 1 hour | Cost > 200% daily budget, provider error rate > 10%, correction rate spike > 20% |
| **Medium (P2)** | < 24 hours | Single provider latency degradation, moderate cost increase |
| **Low (P3)** | < 1 week | Gradual drift trends, minor accuracy changes in non-critical categories |

**Avoid**:
- Alerting on every API error (noisy, normal when user has bad connectivity).
- Static thresholds — use dynamic baselines (3 standard deviations from 7-day rolling average).
- Alerting without actionable guidance — every alert should say "What to check" and "Who to ping."

### 4. Key Dashboard Panels

**Panel 1: System Health (top row)**
```
┌─────────────────────┬─────────────────────┬─────────────────────┐
│ Crash-free rate     │ AI pipeline uptime  │ Cost today (vs avg) │
│ 99.7% (target 99.5) │ 99.9%              │ $12.40 (-8% vs avg) │
└─────────────────────┴─────────────────────┴─────────────────────┘
```

**Panel 2: AI Cost Breakdown (area chart)**
- Stacked area: cost per provider (OpenAI, Gemini, local) over time.
- Overlay: number of classifications.
- Goal: see cost-per-classification trend regardless of volume changes.

**Panel 3: Quality & Drift (dual-axis chart)**
- Left axis: Top-1 accuracy trend (from user correction rate, smoothed).
- Right axis: Average confidence score trend.
- Overlay: model/prompt version deployment markers.
- Goal: see if a model version change affected accuracy.

**Panel 4: Error Rate by Type (stacked bar)**
- Stacked by failure type (timeout, parse error, safety refusal, low confidence, provider 5xx).
- Drill-down: per provider, per category.
- Goal: identify if a specific provider or category is degrading.

**Panel 5: User Behavior Correlation (scatter)**
- X-axis: scans per day. Y-axis: correction rate.
- Size: number of active users.
- Goal: detect if volume changes correlate with quality changes (bot attack? onboarding surge?).

### 5. Firestore Cost Monitoring

Firestore cost can grow silently — each classification writes a history document, records cost, and may update user stats.

**Key cost metrics**:
- Reads/classification: target < 10 reads.
- Writes/classification: target < 5 writes.
- Per-collection cost breakdown.
- Index usage (are compound indexes being used effectively?).

**Dashboard integration**:
- Export Firestore usage to BigQuery (built-in Firebase integration).
- Create BigQuery views that calculate cost per collection per day.
- Alert on cost anomalies: > 3 standard deviations from 7-day average.

### 6. Operator Workflow Design

The dashboard should enable specific workflows, not just display data:

| Workflow | Frequency | Steps |
|---|---|---|
| **Daily pulse check** | Every morning | Check crash rate, cost vs budget, error rate. If all green, done. |
| **Alert response** | As needed | Check alert → correlate with other metrics → decide rollback or investigate. |
| **Weekly review** | Every Monday | Review trends: cost, accuracy, error rate. Check drift. Plan any changes. |
| **Release comparison** | After each release | Compare metrics 3 days before vs 3 days after. Did anything change? |
| **Monthly cost review** | Every month | Review total cost, cost/category, cost/provider. Re-evaluate provider mix. |

---

## Implementation Recommendations

### Phase 1 (Week 1-2) — Firebase-native baseline
- Ensure Crashlytics + Performance Monitoring cover all key flows.
- Add custom trace for scan end-to-end latency.
- Add Firestore cost logging to BigQuery export.
- Set up daily email digest of key metrics.

### Phase 2 (Week 3-4) — AI observability layer
- Integrate Langfuse or Braintrust for AI trace logging.
- Configure eval test to run daily and push results to a Firestore collection.
- Create basic Grafana dashboard composing Firebase metrics + AI metrics.

### Phase 3 (Month 2) — Alerting & automation
- Set up alerts for P0/P1 conditions.
- Create weekly trends report (automated email or Slack notification).
- Add drift detection: automatic comparison of last 7 days vs previous 7 days.

---

## Anti-Patterns to Avoid

| Anti-Pattern | Why |
|---|---|
| Building a custom dashboard before Firebase tools are exhausted | Building and maintaining a dashboard is expensive — use existing tools first |
| All-metrics-everywhere approach | More metrics = more noise. Start with 5-10 key signals |
| No correlation model | Individual metrics lie. "Cost up" can be "volume up" or "price up" |
| Alerting without runbooks | Every alert needs a "what to do" — without it, alerts get ignored |
| Dashboard by one person | The dashboard dies when that person leaves — make it team-owned |
| Ignoring business context | A 5% cost increase with 20% user growth is good, not bad |

---

## Open Questions

1. Should the dashboard be internal-only or also provide a trimmed view for investor/partner reporting?
2. What is the right alerting channel — Slack, email, PagerDuty, in-app to developer?
3. How do we handle alert fatigue for a small team without dedicated on-call?
4. Should we build an in-app operator dashboard or rely on external tools?
5. Who owns the dashboard — engineering lead, or rotate weekly?

---

## Next Steps

1. Audit current Firebase tool usage — what's instrumented, what's missing.
2. Export Firestore usage to BigQuery (enable the integration).
3. Add custom Performance Monitoring trace for scan flow.
4. Set up basic alerts for crash-free rate and AI cost.
5. Evaluate Langfuse vs Braintrust for AI trace logging.
6. Design the minimum viable unified dashboard in Looker Studio or Grafana.
