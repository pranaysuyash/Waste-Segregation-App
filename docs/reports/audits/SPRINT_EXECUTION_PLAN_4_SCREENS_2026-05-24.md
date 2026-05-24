# Sprint Execution Plan (4-Screen Audit Remediation)

**Date:** 2026-05-24  
**Inputs:**
- `docs/reports/audits/SCREEN_AUDIT_WASTE_DASHBOARD_2026-05-24.md`
- `docs/reports/audits/SCREEN_AUDIT_HOME_2026-05-24.md`
- `docs/reports/audits/SCREEN_AUDIT_RESULT_2026-05-24.md`
- `docs/reports/audits/SCREEN_AUDIT_HISTORY_2026-05-24.md`
- `docs/reports/audits/MASTER_REMEDIATION_BACKLOG_4_SCREENS_2026-05-24.md`

---

## 1) Delivery objective

Convert audited trust/consistency findings into a production-safe, verifiable sequence with minimal disruption and maximal user-facing correctness.

---

## 2) Scope boundaries

### In scope
- Contract-level consistency fixes (metrics, route semantics, filter ingress contract).
- Trust-critical UX correctness fixes (stale resets, daily goal truth source, state authority clarity).
- Test coverage additions for touched contract surfaces.

### Out of scope (this cycle)
- Full visual redesign implementation from `docs/design/UI_REVAMP_MASTER_PLAN.md`.
- Large modular decomposition/refactors unless required by a P1 defect.

---

## 3) Sprint structure

## Sprint 1 (Stability + contract quick wins)

### Ticket S1-01 — History subcategory ingress contract
- **Backlog link:** B-06
- **Owner:** Mobile App Engineer
- **Targets:** `lib/screens/history_screen.dart`, filter plumbing tests
- **Acceptance criteria:**
  - Opening History with `filterSubcategory` applies filter immediately.
  - Existing category prefilter behavior preserved.
- **Verification:**
  - Unit/widget tests for startup filter state.
  - Manual path verification from deep-link/caller route.

### Ticket S1-02 — Dashboard stale aggregate reset
- **Backlog link:** B-02
- **Owner:** Mobile App Engineer
- **Targets:** dashboard aggregate load/reset logic
- **Acceptance criteria:**
  - Non-empty to empty transitions clear stale visuals and counters.
- **Verification:**
  - Regression test around empty dataset transitions.
  - Manual refresh + clear-state scenario.

### Ticket S1-03 — Daily-goal source correctness
- **Backlog link:** B-03
- **Owner:** Product Engineer
- **Targets:** goal/nudge source logic used by Home/Result
- **Acceptance criteria:**
  - Daily nudge computed from day-level records, not weekly proxy.
- **Verification:**
  - Deterministic test fixture with day-boundary cases.
  - Manual date-rollover sanity check.

### Ticket S1-04 — Taxonomy canonicalization baseline
- **Backlog link:** B-07
- **Owner:** Platform/UI Engineer
- **Targets:** shared category constants + chip/dialog consumers
- **Acceptance criteria:**
  - Category labels and route/filter enums all resolve from one canonical source.
- **Verification:**
  - Static reference search shows no hardcoded divergent label remnants for audited surfaces.

---

## Sprint 2 (State truth + semantics)

### Ticket S2-01 — Result state authority unification
- **Backlog link:** B-04
- **Owner:** Senior Mobile Engineer
- **Targets:** `ResultScreen` state mapping and user-visible state rendering
- **Acceptance criteria:**
  - One authoritative state abstraction drives status UI.
  - No contradictory status text across flows.
- **Verification:**
  - State transition tests (success/fallback/retry/corrected).

### Ticket S2-02 — Reanalyze action semantic alignment
- **Backlog link:** B-10
- **Owner:** Product Engineer
- **Targets:** result action labels + behavior hooks
- **Acceptance criteria:**
  - Label/action semantics are consistent with actual execution behavior.
- **Verification:**
  - UI assertion tests + manual smoke.

### Ticket S2-03 — Data freshness indicators
- **Backlog link:** B-09
- **Owner:** UX Engineer
- **Targets:** trust-sensitive Home/Dashboard/Result cards
- **Acceptance criteria:**
  - Timestamp/freshness cue appears where stale interpretation risk exists.
- **Verification:**
  - Snapshot/widget assertions for stale/fresh states.

---

## Sprint 3 (Platform consistency + debt paydown)

### Ticket S3-01 — Sync contract decision for `_ensureDataSync`
- **Backlog link:** B-05
- **Owner:** Platform Engineer
- **Targets:** dashboard sync utility and callsites
- **Acceptance criteria:**
  - Placeholder path is either fully implemented or removed with explicit policy.
- **Verification:**
  - Integration test around sync-triggered screen refresh path.

### Ticket S3-02 — Route policy standardization
- **Backlog link:** B-08
- **Owner:** Architecture Owner
- **Targets:** route entry points across audited screens
- **Acceptance criteria:**
  - Single route policy documented and adopted on touched flows.
- **Verification:**
  - Route map doc + static checks.

### Ticket S3-03 — History sync-mode retrieval parity
- **Backlog link:** B-11
- **Owner:** Data/Storage Engineer
- **Targets:** history pagination/filter logic under local/cloud modes
- **Acceptance criteria:**
  - Equivalent user-visible filtering + pagination semantics regardless of sync mode.
- **Verification:**
  - paired-mode test fixtures and contract assertions.

---

## 4) Risk controls and guardrails

- Do not change business semantics and UI wording in the same PR unless explicitly coupled.
- Add or update tests in the same change set for all contract-level fixes.
- For each ticket, include a “verified vs inferred” note in PR body.
- Require before/after screenshots for UI semantic changes.

---

## 5) Recommended sequencing policy

1. Ship **S1-01, S1-02, S1-03** first (highest trust gain / lowest complexity).  
2. Gate Sprint 2 on successful metric parity checks from Sprint 1.  
3. Ship Sprint 3 only after state/semantics are stable and test debt is reduced.

---

## 6) Exit criteria (program-level)

Program is considered complete when:
- No audited P1 findings remain open.
- Metric/state/filter contracts are explicitly test-covered.
- Route/taxonomy consistency is centralized and documented.
- User-facing trust artifacts (stale values, mismatched semantics, ignored ingress params) are removed.

---

## 7) Practical owner matrix

- **Architecture owner:** B-01, B-04, B-08  
- **Dashboard owner:** B-02, B-05  
- **History owner:** B-06, B-11  
- **UX/Product owner:** B-03, B-09, B-10  
- **Shared platform/constants owner:** B-07

This owner model minimizes cross-PR contention while preserving contract alignment.
