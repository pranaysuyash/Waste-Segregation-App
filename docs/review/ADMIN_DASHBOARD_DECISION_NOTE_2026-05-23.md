# Admin Dashboard Decision Note

Date: 2026-05-23
Context: AI learning flywheel foundation

## Decision (current phase)
A full admin dashboard is **not required yet**.

## Why
Current flywheel operations are already possible through:
- Admin-gated backend callables (`getTrainingReviewQueue`, `reviewTrainingCandidate`, `buildTrainingDatasetManifest`)
- JSONL-first reviewer workflow tools
- Generated analytics/evidence artifacts under `build/reports/`

This is sufficient for the foundation phase and keeps scope focused on truth/eval/data quality gates.

## What exists now
- Review queue + review-state transitions via backend callables
- Ground-truth capture path in review flow
- Dataset manifest/version generation
- Eval/reporting pipeline (offline/recorded/provider comparison)
- Acceptance and evidence summary reports

## When to build an admin dashboard
Build dashboard when one or more of these become true:
1. Multi-reviewer concurrent operations are needed.
2. Real-time queue triage and SLA tracking are required.
3. Role-based UI workflows (reviewer/ops/owner) are needed in-product.
4. Continuous monitoring of quality/cost/fallback metrics is needed without manual report runs.
5. Non-technical operators must run review/export/version tasks without CLI/JSONL workflows.

## Recommended future scope (if triggered)
- Review queue UI with filters and bulk actions
- Candidate detail view (prediction, correction, reviewer truth, redaction status)
- Dataset/version management UI
- Router/eval analytics panels (safety fails, must-not violations, provider deltas, cost/latency)
- Audit log + role/permission controls

## Principle alignment
This follows motto_v2 + first principles:
- avoid premature UI complexity,
- ship truth and safety infrastructure first,
- add dashboard only when operational load justifies it.
