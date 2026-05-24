# Screen Audit Report: `WasteDashboardScreen`

**Date:** 2026-05-24  
**Scope:** Single-screen deep audit (components + flows)  
**Screen audited:** `lib/screens/waste_dashboard_screen.dart`  
**Method:** Code-path audit aligned with `motto_v2.md` (first-principles, long-term architecture, no superficial patching)

---

## 1) Why this screen was selected

`WasteDashboardScreen` is a high-leverage product surface because it is:
- a user trust screen (impact claims, trends, category intelligence),
- a behavior loop screen (scan more, learn more, reflect on outcomes), and
- reachable from multiple high-intent paths (home, result, settings).

This makes it ideal for a full component + flow audit with business impact.

---

## 2) Entry flow map (all known ingress paths)

### 2.1 Named-route ingress
- `Routes.wasteDashboard` in `lib/utils/routes.dart`
- Registered in `lib/main.dart` to `const WasteDashboardScreen()`

### 2.2 Direct navigation ingress
- Home screen community card → dashboard: `lib/screens/home_screen.dart`
- Result screen “View analytics” action → dashboard: `lib/screens/result_screen.dart`
- Settings feature tile “Analytics” → route `Routes.wasteDashboard`: `lib/widgets/settings/features_section.dart`
- Legacy settings screen analytics tile → route `Routes.wasteDashboard`: `lib/screens/settings_screen.dart`
- Community impact card fallback tap route: `lib/widgets/community_impact_card.dart`

### 2.3 Exit flow map (from dashboard)
- Quick action: **Scan Waste** → `ImageCaptureScreen`
- Quick action: **Learn** → `EducationalContentScreen`
- AppBar refresh button → reloads same screen state (`_loadData`)
- Recent card tap → details dialog only (no deep-link to classification detail screen)

---

## 3) Runtime/lifecycle flow (inside dashboard)

1. `initState()`
   - Initializes chart animation controller.
   - Calls `_ensureDataSync(context)` in post-frame callback.
   - Calls `_loadData()`.

2. `_loadData()`
   - sets loading true,
   - attempts gamification sync,
   - fetches classifications from `StorageService.getAllClassifications()`,
   - processes metrics via `_processClassifications(...)`,
   - sets screen state and restarts chart animation.

3. `build()`
   - `loading` → spinner
   - `empty classifications` → empty state card
   - `non-empty` → full dashboard stack (`_buildDashboard()`)

4. `buildDashboard()` section ordering
   - Mission Control header
   - Quick Actions
   - Daily Highlight
   - Category Spotlight
   - Summary Stats
   - Activity + Daily/Weekly toggle charts
   - Category Distribution
   - Top Waste Types
   - Recent Classifications
   - Environmental Impact
   - Gamification Progress

---

## 4) Component-by-component audit

## 4.1 Scaffold/AppBar/Loading gates

**Component(s):** `Scaffold`, `AppBar`, loading and empty-state gating in `build()`  
**Strengths:**
- Clear tri-state rendering (loading / empty / populated).
- Refresh affordance in app bar is explicit and discoverable.

**Risks / concerns:**
- No explicit retry CTA in error state besides snackbar during load failure.
- Potential async state lifecycle risk: `_loadData()` performs async then `setState` without explicit `mounted` check before final state writes.

---

## 4.2 Mission Control header

**Component(s):** `_buildMissionControlHeader()`, `ImpactVisualizationRing`, `StatsCard`s  
**Strengths:**
- Strong visual hierarchy and KPI-at-a-glance density.
- Motivational framing (target progress) supports habit loop.

**Risks / concerns:**
- Goal math uses generated target (`+10` heuristic), which may appear arbitrary to users.
- If a user expects stable weekly goals, this shifting denominator can reduce trust.

---

## 4.3 Quick Actions block

**Component(s):** `_buildQuickActions()`, `ModernButton`s  
**Strengths:**
- Converts analytics surface into action surface (scan + learn).
- Good directional loop back into core workflow.

**Risks / concerns:**
- Uses direct `MaterialPageRoute` navigation rather than centralized route policy.
- No explicit protection against rapid repeated taps causing route stacking.

---

## 4.4 Daily Highlight + Category Spotlight

**Component(s):** `_buildDailyHighlight()`, `_buildCategorySpotlight()`  
**Strengths:**
- Good summarization of recency and dominant behavior.
- Fast signal with low cognitive load.

**Risks / concerns:**
- If data freshness fails silently, cards may display stale insights without timestamp freshness indicator.

---

## 4.5 Summary stats strip

**Component(s):** `_buildSummaryStats()`, `_buildStatBox()`  
**Strengths:**
- Compact triad (total items, days tracking, recyclable count).
- Good iconography and color coding.

**Risks / concerns:**
- “Recyclable” metric is count-only; may be interpreted as quality score.
- No denominator context shown in the stat box itself.

---

## 4.6 Activity chart flow (daily/weekly)

**Component(s):** `_buildTimescaleToggle()`, `_buildDailyActivityChart()`, `_buildWeeklyActivityChart()`  
**Strengths:**
- Strong comparative view between day and week.
- Simple toggle avoids overloading users.

**Risks / concerns:**
- X-axis labels can crowd on long date spans (readability risk).
- No explicit empty-check messaging at chart level when maps are empty but screen has older state.

---

## 4.7 Category distribution pie

**Component(s):** `_buildCategoryDistribution()`, `WasteCategoryPieChart`  
**Strengths:**
- Uses accessibility-aware chart widget with semantic descriptions.
- Includes legend and percentages.

**Risks / concerns:**
- Potential category-color inconsistency if category naming drifts from canonical constants.
- User interpretation risk: percentages may hide low absolute counts.

---

## 4.8 Top subcategories bar chart

**Component(s):** `_buildTopSubcategories()`, `TopSubcategoriesBarChart`  
**Strengths:**
- Good “what you scan most” ranking.
- Accessible data table below chart improves screen-reader and non-visual interpretation.

**Risks / concerns:**
- Top-5 truncation is correct for scannability but can bias user interpretation without “view all” path.

---

## 4.9 Recent classifications grid + details dialog

**Component(s):** `_buildRecentClassifications()`, `_showClassificationDetails()`  
**Strengths:**
- Good visual recall of recent user actions.
- Includes confidence signal and recyclability marker.

**Risks / concerns:**
- Tapping a card opens a modal details dialog only; no persistent details route/deeplink.
- Image loading relies on network URL path only in this surface (`Image.network`), so local/offline behavior may degrade.

---

## 4.10 Environmental impact section

**Component(s):** `_buildImpactSection()`, `_buildImpactMetric()`  
**Strengths:**
- Good storytelling: recycling rate + CO₂ + water signals.

**Risks / concerns:**
- CO₂ and water calculations are explicitly simplified heuristics.
- If presented as definitive impact, can become trust risk (should be labeled estimate in UI language and docs).

---

## 4.11 Gamification section

**Component(s):** `_buildGamificationSection()`, `GamificationSummaryCard`  
**Strengths:**
- Connects analytics to progression loop (streak + points + level).
- Handles missing profile case safely.

**Risks / concerns:**
- Reads from current profile only; no explicit stale-data indicator.
- “Leaderboard coming soon” placeholder may become long-lived UX debt if not tracked.

---

## 4.12 Web chart fallback components in same file

**Component(s):** `WebChartWidget`, `WebPieChartWidget`  
**Strengths:**
- Defensive navigation restriction (`about:blank` + `data:` allowlist).

**Risks / concerns:**
- External CDN runtime dependency (`jsdelivr`) for chart scripts: reliability, privacy, and offline sensitivity.
- High file complexity: these web components are colocated with mobile/native dashboard logic.

---

## 5) Critical findings (prioritized)

## P0 / P1 findings

### F-01 (P1): `_processClassifications` early return can leave stale aggregates
- In `lib/screens/waste_dashboard_screen.dart`, `_processClassifications(...)` exits immediately on empty list **before** resetting aggregate maps.
- If the screen transitions from non-empty dataset to empty dataset in-session, prior chart/stat maps can remain stale in memory.
- This is a correctness/trust issue for analytics output.

### F-02 (P1): `_ensureDataSync` is currently a no-op placeholder
- Function exists and is called in `initState`, but body is placeholder comment only.
- This creates an architectural smell: important sync intent appears present but is not implemented.
- High confusion risk for maintainers and agents.

### F-03 (P1): Impact metrics are heuristic but presented as concrete values
- CO₂/water are estimated via simple formulas.
- Without explicit confidence labeling and method transparency, this can weaken user trust in impact dashboard claims.

## P2 findings

### F-04 (P2): Mixed navigation policy (named route + direct MaterialPageRoute)
- Ingress/egress use both route styles.
- Not fatal, but increases policy drift and consistency debt.

### F-05 (P2): Dashboard file is too large and mixed-concern (~2k lines)
- Combines layout, data processing, dialogs, impact logic, chart wrappers, and web-chart HTML emitters.
- Refactorability and testability are constrained.

### F-06 (P2): Potential async `setState` lifecycle hazard
- `_loadData()` performs asynchronous work and updates state; lifecycle guard consistency should be validated to avoid set-after-dispose edge cases.

## P3 findings

### F-07 (P3): Chart readability under dense timelines
- Daily/weekly axis labels may become visually noisy on larger histories.

### F-08 (P3): Recent item detail lacks deep-link route
- Dialog is useful but ephemeral; no durable route for share/bookmark/testing paths.

---

## 6) Flow quality review (user journey perspective)

### Flow A: Home → Community Impact Card → Dashboard
- **Quality:** Strong (contextually relevant entry).
- **Strength:** Converts passive awareness into insight depth.
- **Gap:** Needs freshness indicator to reassure user that charts are current.

### Flow B: Result screen → View Analytics
- **Quality:** Strong (post-classification reflection).
- **Strength:** Excellent moment for reinforcement.
- **Gap:** Should ideally pre-highlight the newly classified category/date window.

### Flow C: Settings → Analytics
- **Quality:** Medium.
- **Strength:** Discoverable for power users.
- **Gap:** Entry is feature-oriented, not task-oriented; less natural than result/home context.

### Flow D: In-dashboard action loop (Scan / Learn)
- **Quality:** Strong.
- **Strength:** Keeps analytics from becoming dead-end reporting UI.
- **Gap:** Could include quick “Filter by category from spotlight” action for tighter loops.

---

## 7) Motto-v2 alignment assessment

### What aligns well
- Screen design is additive and comprehensive (not minimal).
- Multiple user value loops are present (insight + action + progression).
- Accessibility effort exists in chart widgets.

### Where motto-v2 flags risk
- Placeholder/ghost logic (`_ensureDataSync`) violates strong source-of-truth expectations.
- Heuristic impact math without explicit trust framing risks product integrity.
- Oversized mixed-concern file risks long-term architecture quality.

---

## 8) No-code action recommendations (documentation + product)

1. **Create an explicit “impact methodology” note** in product docs and link from dashboard UX copy.
2. **Document dashboard data freshness contract** (when data is recalculated, what is cached, what is synced).
3. **Track `_ensureDataSync` intent** as an explicit implementation task (or remove placeholder intent from docs if intentionally deferred).
4. **Define navigation policy** for analytics surfaces (named routes vs direct route objects) in one canonical doc.
5. **Create a decomposition plan doc** for dashboard refactor (presentation / data transform / chart adapters / web fallback).

---

## 9) Suggested verification checklist for next implementation pass

- [ ] Empty-after-non-empty transition produces zeroed charts/stats (no stale carryover).
- [ ] Dashboard values match `StorageService.getAllClassifications()` outputs under guest and signed-in states.
- [ ] Impact labels clearly indicate “estimated” methodology.
- [ ] All ingress flows land on consistent initial analytics state.
- [ ] Accessibility audit pass on every interactive card and chart legend/tooltip path.

---

## 10) Final assessment

`WasteDashboardScreen` is **product-valuable and structurally strong in UX intent**, but currently has **trust-sensitive correctness and maintainability gaps** that should be prioritized before deeper feature expansion.

**Overall status:** Good foundation, not yet “golden path” quality for long-term analytics trust.
