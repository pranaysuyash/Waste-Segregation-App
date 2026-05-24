# Consolidated Risk Register (3 Screens)

**Date:** 2026-05-24  
**Screens covered:**
- `HomeScreen`
- `WasteDashboardScreen`
- `ResultScreen`

Source audits:
- `SCREEN_AUDIT_HOME_2026-05-24.md`
- `SCREEN_AUDIT_WASTE_DASHBOARD_2026-05-24.md`
- `SCREEN_AUDIT_RESULT_2026-05-24.md`

---

## 1) Executive synthesis

Across all three screens, the dominant systemic risk is **metric-truth and state-truth inconsistency**:
- similar concepts computed in multiple places,
- mixed async/provider freshness,
- overlapping state abstractions in key pipeline paths.

This is a trust problem first, maintainability problem second.

---

## 2) Top consolidated risks

| ID | Risk | Screens | Severity | Likelihood | Priority |
|---|---|---|---|---|---|
| CR-01 | Impact/progress metrics derived separately across surfaces | Home + Dashboard + Result | P1 | High | Immediate |
| CR-02 | Daily-goal/nudge truth can derive from proxy stats | Home + Result (shared nudge source) | P1 | Medium | Immediate |
| CR-03 | Dashboard empty-transition can leave stale aggregates | Dashboard | P1 | Medium | Immediate |
| CR-04 | Overlapping state models (pipeline state vs lifecycle machine) | Result | P1 | Medium | Immediate |
| CR-05 | Placeholder sync intent (`_ensureDataSync`) | Dashboard | P1 | High | Immediate |
| CR-06 | Mixed navigation policy (named + direct) | All three | P2 | High | Near-term |
| CR-07 | Multi-concern oversized screen files | Dashboard + Result (+ Home secondary) | P2 | Medium | Near-term |
| CR-08 | Mixed-freshness UI from independent async sources | Home + Dashboard | P2 | High | Near-term |
| CR-09 | Action semantics mismatch (“reanalyze” vs behavior) | Result | P2 | Medium | Near-term |

---

## 3) Root-cause clusters

### Cluster A — Metric contract fragmentation
- No single metric contract layer for impact/progress/streak semantics.
- UI surfaces compute and frame values independently.

### Cluster B — State abstraction overlap
- Result flow combines lifecycle state machine + simplified pipeline state object.
- Harder to guarantee one authoritative status model.

### Cluster C — Architecture growth without decomposition guardrails
- Large screen files accumulate concerns over time.
- Increased regression risk and slower confidence in changes.

### Cluster D — Navigation and refresh consistency drift
- Mixed routing conventions and partial refresh invalidation.
- UI can show mixed-age data after refresh.

---

## 4) Recommended implementation order (when coding resumes)

## Wave 1 (Trust & correctness)
1. **Unify metric contracts** across Home/Dashboard/Result (CR-01).
2. **Fix dashboard stale aggregate reset** on empty transitions (CR-03).
3. **Correct nudge daily-goal source** to true day-level truth (CR-02).
4. **Resolve result state authority policy** (single source for user-visible flow status) (CR-04).
5. **Implement or remove placeholder sync intent** (CR-05).

## Wave 2 (Consistency hardening)
1. Standardize route policy across audited screens (CR-06).
2. Add explicit freshness indicators for trust-sensitive cards (CR-08).
3. Align action labels/semantics for result reanalyze path (CR-09).

## Wave 3 (Maintainability)
1. Decompose Dashboard and Result into concern-based modules (CR-07).
2. Introduce audit tests for metric consistency across screens.

---

## 5) Practical acceptance checks

- Same classification dataset yields consistent impact summary across Home, Dashboard, and Result-derived metrics.
- Daily-goal nudge always reflects true today count.
- Dashboard clears all aggregate maps/series when classifications become empty.
- Result screen status labels align with authoritative lifecycle state.
- Route usage follows declared policy with documented exceptions.

---

## 6) Final recommendation

Before adding more UX features, execute Wave 1. It yields the highest reduction in user-trust risk per unit effort and prevents “looks polished, feels inconsistent” failure modes.
