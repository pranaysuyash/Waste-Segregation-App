# Review Dashboard Ops Runbook

Generate dashboard artifacts:

```bash
dart run tool/ai_review_dashboard.dart --input build/reports/ai_review/updated_candidates.jsonl --out-json build/reports/ai_review/dashboard.json --out-md build/reports/ai_review/dashboard.md
```

Daily operator checks:
- `statusCounts`: ensure `unreviewed` queue is trending down.
- `lifecycle.trainingEligible`: monitor candidate throughput for dataset growth.
- `lifecycle.excluded`: investigate spikes (privacy/rejection regressions).
- `reviewers`: verify balanced reviewer load and no stale assignee.
- `privacyFlagCounts`: triage `needs_redaction` and `pii_failed` immediately.

SLA recommendations:
- Safety-critical cases: review within 24 hours.
- Non-safety cases: review within 72 hours.
- Privacy-blocked cases: resolve redaction or hard reject within 24 hours.

Escalation rules:
- If `unreviewed` grows > 20% week-over-week, pause new dataset versioning.
- If `excluded` grows > 30% week-over-week, audit consent and policy versions.
- If reviewer throughput is concentrated in one reviewer, redistribute queue.

