# Screen Audit Report: `HistoryScreen`

**Date:** 2026-05-24  
**Scope:** Single-screen deep audit (component, flow, filters, data contracts)  
**Screen audited:** `lib/screens/history_screen.dart`  
**Method:** Evidence-first audit aligned with `motto_v2.md`

---

## 1) Screen role and criticality

`HistoryScreen` is the user’s source of truth for past classifications, feedback/corrections, and export workflows. It is a trust screen for data integrity and auditability.

---

## 2) Flow map (ingress/egress)

## 2.1 Ingress
- Reached via home/result/dashboard pathways (view-all and retrospective review).
- Optional pre-filter parameters: `filterCategory`, `filterSubcategory`.

## 2.2 Primary screen flows
1. `initState`:
   - analytics track,
   - apply initial category filter if provided,
   - load first page,
   - register infinite-scroll listener.
2. Data load path:
   - settings read,
   - optional cloud-sync fetch path,
   - local filter application,
   - pagination slice.
3. User interaction paths:
   - search,
   - filter chips/dialog,
   - sorting/date-range,
   - export CSV/share,
   - open classification details,
   - submit feedback from list item.

## 2.3 Egress
- Item tap (mobile): opens `ResultScreenWrapper` (details read mode).
- Item tap (wide layout): in-place side-by-side detail panel.
- Export path: share CSV file.

---

## 3) Component-by-component audit

## 3.1 Data load and pagination

**Strengths**
- Explicit page size and lazy loading for long histories.
- RefreshIndicator supports manual reload.

**Risks**
- Load path differs by sync mode:
  - cloud-enabled branch fetches all then filters/slices,
  - local branch can pre-filter at service layer.
- This asymmetry can produce subtle behavior/perf drift across user configurations.

---

## 3.2 Search/filter/sort UX

**Strengths**
- Good multi-modal filtering (chips + dialog + date range + text).
- Active-filter indicator and clear actions are clear.

**Risks**
- Filter consistency risk: `_filterChipLabels` includes `'Hazardous'` while canonical category naming elsewhere is `'Hazardous Waste'`.
- `filterSubcategory` constructor arg exists but is not applied in initialization flow.

---

## 3.3 Feedback gating and recency policy

**Strengths**
- Feedback availability respects settings and timeframe.
- Post-feedback refresh path exists.

**Risks**
- Feedback button visibility is gated in list screen but underlying detail flow may allow broader actions; cross-surface consistency should be explicitly defined.

---

## 3.4 Analytics + provider fallback

**Strengths**
- Screen action tracking is comprehensive.

**Risks**
- If analytics provider is missing, screen instantiates fallback `AnalyticsService(StorageService(), enableFirestore:false)` directly.
- This creates DI-policy inconsistency and can hide configuration wiring issues.

---

## 3.5 Export flow

**Strengths**
- Uses filtered dataset export semantics.
- Handles web limitation with explicit exception.

**Risks**
- Long-running export sets global loading state, potentially blocking list UX more than necessary.

---

## 3.6 List item rendering (`HistoryListItem`)

**Strengths**
- Rich semantic hints and status badges (confirmed/corrected/manual review).
- Fallback-safe image loading paths with placeholders.

**Risks**
- `HistoryListItem` includes heavy image resolution logic and feedback trigger logic in one widget; harder to test and maintain.
- Correction dialog result handling checks only non-null return, potentially conflating “dialog closed with payload vs no-op intent” depending on dialog contract.

---

## 4) Contract and architecture findings

## P1 findings

### HS-01: Category-label mismatch in chip filter taxonomy
- `'Hazardous'` chip label deviates from canonical `'Hazardous Waste'`.
- Risk: filter semantics and user expectation mismatch.

### HS-02: `filterSubcategory` parameter is not applied in startup filtering
- Constructor accepts subcategory filter, but initialization path only applies category filter.
- Risk: ingress contract is partially ignored.

## P2 findings

### HS-03: Dual data-path behavior by sync mode may drift
- Cloud path fetches all + in-screen filter; local path may pre-filter in storage service.
- Risk: inconsistent paging/filter semantics and performance.

### HS-04: Analytics fallback instantiation bypasses central provider policy
- Risk: hidden dependency/config issues.

### HS-05: Chip taxonomy and canonical categories are manually duplicated
- Risk: naming drift over time.

## P3 findings

### HS-06: Overloaded row widget concerns (image IO + status + feedback)
- Maintainability and test surface concern.

---

## 5) Verified vs inferred

## Verified
- Startup filtering applies category but not subcategory.
- Category chip label set includes non-canonical `'Hazardous'` token.
- Analytics fallback local instantiation exists.
- Cloud/local load branches are asymmetric.

## Inferred
- Degree of user-visible inconsistency due to asymmetry depends on dataset size and sync state.

---

## 6) No-code recommendations

1. Define canonical category taxonomy in one shared source for chips/dialogs/screens.
2. Document and enforce History ingress contract (`filterCategory` + `filterSubcategory`).
3. Define one data retrieval contract for paged history regardless of sync mode.
4. Document DI policy forbidding local service instantiation inside screens except explicit emergency modes.

---

## 7) Final assessment

`HistoryScreen` is functionally strong and user-valuable, but currently carries **taxonomy and contract-consistency debt** that can erode trust over time if left unaddressed.

**Overall status:** Good UX surface, medium consistency risk; prioritize contract unification and taxonomy hardening.
