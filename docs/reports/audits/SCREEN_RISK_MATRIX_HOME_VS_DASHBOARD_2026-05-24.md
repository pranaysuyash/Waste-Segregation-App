# Comparative Risk Matrix: `HomeScreen` vs `WasteDashboardScreen`

**Date:** 2026-05-24  
**Inputs:**
- `docs/reports/audits/SCREEN_AUDIT_HOME_2026-05-24.md`
- `docs/reports/audits/SCREEN_AUDIT_WASTE_DASHBOARD_2026-05-24.md`

---

## 1) Executive summary

Both screens are high-impact and well-designed, but they share a core systemic weakness: **metric-truth inconsistency risk across surfaces**.

If only one cluster is prioritized first, prioritize:
1) metric contract unification,
2) nudge truth correctness,
3) stale-state prevention in dashboard processing.

---

## 2) Side-by-side risk matrix

| Risk ID | Risk | Screen(s) | Severity | Likelihood | User Impact | Notes |
|---|---|---|---|---|---|---|
| M-01 | Impact metrics computed separately in multiple surfaces | Home + Dashboard | P1 | High | High | Can present conflicting environmental outcomes |
| M-02 | Daily-goal nudge computed from weekly proxy logic | Home | P1 | Medium | High | Habit-loop trust risk |
| M-03 | Stale aggregate maps when dataset transitions to empty | Dashboard | P1 | Medium | High | Incorrect charts/stats possible |
| M-04 | `_ensureDataSync` exists as placeholder/no-op | Dashboard | P1 | High | Medium | Architectural intent drift |
| M-05 | Mixed route policy (named + direct push) | Both | P2 | High | Medium | Navigation consistency/maintainability debt |
| M-06 | Async mixed-freshness metrics without explicit freshness cue | Home (primary), Dashboard (secondary) | P2 | High | Medium | User confidence erosion |
| M-07 | Oversized mixed-concern screen files | Dashboard (high), Home (medium) | P2 | Medium | Medium | Slower safe iteration |
| M-08 | Recent-item interaction mismatch (no deep-link details) | Home + Dashboard | P3 | Medium | Low-Med | UX expectation gap |

---

## 3) Cross-screen root causes

1. **No canonical analytics metric contract layer**
   - Same conceptual metrics implemented at UI-surface level.

2. **Presentation layer performs business-like calculations**
   - Home and dashboard each derive impact/progress semantics.

3. **Distributed async state without freshness model**
   - Multiple providers/services resolve independently.

4. **Incremental growth without strict route/data architecture guardrails**
   - Mixed navigation patterns and placeholder sync hooks.

---

## 4) Recommended implementation sequence (when coding resumes)

## Wave 1 (P1 Trust Stabilization)
1. Unify metric computation contracts for impact/progress across home/dashboard.
2. Fix dashboard empty-transition aggregate reset behavior.
3. Replace placeholder `_ensureDataSync` intent with implemented sync or explicit removal.
4. Correct home daily-goal nudge source to true day-level calculation.

## Wave 2 (P2 Consistency Hardening)
1. Standardize route policy for home/dashboard ingress/egress.
2. Add freshness indicators for trust-sensitive cards.
3. Expand refresh invalidation to all relevant home providers or central refresh coordinator.

## Wave 3 (P2/P3 Maintainability + UX polish)
1. Decompose oversized screen files by concern (view, transform, adapters).
2. Add item-detail deep-links from recent cards.
3. Improve compact-width behavior for action chips/charts labels.

---

## 5) Confidence labels

- **High confidence:** M-01, M-03, M-04, M-05 (direct code evidence)
- **Medium confidence:** M-02, M-06 (logic/effect relation is clear; runtime frequency requires telemetry)
- **Medium/Low confidence:** M-08 (UX expectation inferred; needs user testing)

---

## 6) Final priority call

If you want maximum user-trust gain per unit effort, start with:
1) **M-01 unified metric truth**,
2) **M-03 dashboard stale-state correctness**,
3) **M-02 nudge truth correction**,
4) **M-04 sync intent cleanup**.

This sequence reduces the chance that users see contradictory or misleading progress/impact signals while preserving current UX momentum.
