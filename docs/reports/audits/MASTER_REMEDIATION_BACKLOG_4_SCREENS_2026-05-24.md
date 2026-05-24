# Master Remediation Backlog (4 Audited Screens)

**Date:** 2026-05-24  
**Screens included:**
- `HomeScreen`
- `WasteDashboardScreen`
- `ResultScreen`
- `HistoryScreen`

Backlog objective: prioritize high-trust fixes first, then consistency, then maintainability.

---

## 1) Prioritization framework

Scoring:
- **Impact**: user trust/product correctness (1-5)
- **Effort**: engineering effort/risk (1-5)
- **Priority score**: $\text{Impact}^2 / \text{Effort}$ (higher = earlier)

---

## 2) Ranked backlog

| Rank | Backlog ID | Item | Screens | Impact | Effort | Score |
|---|---|---|---|---:|---:|---:|
| 1 | B-01 | Unify metric-truth contract for impact/progress/streak | Home + Dashboard + Result + History (exports/labels) | 5 | 3 | 8.33 |
| 2 | B-02 | Fix dashboard stale aggregate reset on empty transition | Dashboard | 5 | 2 | 12.5 |
| 3 | B-03 | Correct daily-goal/nudge source to true day-level data | Home + Result | 5 | 3 | 8.33 |
| 4 | B-04 | Resolve Result state authority (single user-visible state source) | Result | 5 | 4 | 6.25 |
| 5 | B-05 | Implement/remove `_ensureDataSync` placeholder intent | Dashboard | 4 | 2 | 8.0 |
| 6 | B-06 | Apply `filterSubcategory` ingress contract in History startup | History | 4 | 1 | 16.0 |
| 7 | B-07 | Canonicalize category taxonomy across chips/dialogs/routes | History + Home + Dashboard + Result | 4 | 2 | 8.0 |
| 8 | B-08 | Standardize navigation policy (named route vs direct push) | All | 3 | 3 | 3.0 |
| 9 | B-09 | Add freshness indicator for trust-sensitive cards | Home + Dashboard + Result | 3 | 2 | 4.5 |
|10 | B-10 | Align reanalyze action semantics/labeling | Result | 3 | 1 | 9.0 |
|11 | B-11 | Unify history paging/filter behavior across sync modes | History | 3 | 3 | 3.0 |
|12 | B-12 | Decompose oversized screens by concern modules | Dashboard + Result (+Home secondary) | 3 | 5 | 1.8 |

> Note: B-06 scores high due to tiny effort and clear contract fix.

---

## 3) Phase plan

## Phase 0 (Quick contract wins: 1–2 days)
- B-06 `filterSubcategory` startup application.
- B-10 result reanalyze semantic alignment.
- B-07 taxonomy canonicalization scaffolding (shared constants contract).

## Phase 1 (Trust stabilization: 3–5 days)
- B-02 dashboard stale reset fix.
- B-03 nudge truth-source correction.
- B-05 `_ensureDataSync` decision/implementation.

## Phase 2 (Cross-surface truth unification: 4–7 days)
- B-01 metric contract unification.
- B-04 result state-authority simplification.
- B-09 freshness UX hints.

## Phase 3 (Consistency + architecture: 1–2 sprints)
- B-08 route policy standardization.
- B-11 history cloud/local retrieval unification.
- B-12 decomposition/refactor for maintainability.

---

## 4) Suggested acceptance criteria (top 6)

### B-01 Metric contract unification
- Same dataset yields identical aggregate values wherever conceptually equivalent metrics are shown.
- All “estimated” values are explicitly labeled per product copy policy.

### B-02 Dashboard empty-reset
- Transition non-empty → empty clears all chart/stat aggregates with no stale values.

### B-03 Nudge truth-source
- Daily-goal nudge derives from true day-level classifications, not weekly proxy.

### B-04 Result state authority
- User-visible status text maps from one authoritative state abstraction.

### B-05 Sync placeholder
- `_ensureDataSync` is either implemented with contract tests or removed and replaced by explicit policy.

### B-06 History subcategory ingress
- Opening `HistoryScreen(filterSubcategory: X)` immediately applies subcategory filtering.

---

## 5) Risk controls

- Add regression tests for metric parity across Home/Dashboard/Result summaries.
- Add contract tests for history ingress filter parameters.
- Add navigation lint/checklist to prevent route-policy drift.

---

## 6) Final recommendation

Start with **B-06 + B-02 + B-03** as the immediate trio: fastest path to reducing user-facing inconsistency and trust risk before deeper refactors.
