# Screen Audit Report: `EducationalContentScreen`

**Date:** 2026-05-24  
**Scope:** Component-level review of educational discovery, filtering, bookmarks, and ad context behavior  
**Screen audited:** `lib/screens/educational_content_screen.dart`  
**Method:** Evidence-first static audit (no app code changes)

---

## 1) Screen role and criticality

`EducationalContentScreen` is the in-app learning and retention surface. It influences:
- content engagement,
- perceived app utility beyond classification,
- ad exposure context,
- bookmark return-loop behavior.

---

## 2) Flow map (ingress/egress)

## 2.1 Ingress
- Optional context:
  - `initialCategory`,
  - `initialSubcategory` (accepted by widget but not used in filtering logic),
  - `showBottomAd`.

## 2.2 Main flows
1. `initState`:
   - Initializes 6-tab controller,
   - Loads categories from `EducationalContentService.getAllContent()`,
   - Applies initial category,
   - Chooses initial tab based on most common content type in category.
2. Runtime filtering combines:
   - content type,
   - category,
   - search query,
   - bookmark-only toggle,
   - level filter.
3. Card tap opens `ContentDetailScreen(contentId: ...)`.
4. Bookmark action toggles service state and calls `setState`.

## 2.3 Egress
- Detail navigation only (`ContentDetailScreen`).

---

## 3) Component-level findings

## 3.1 Tab filtering logic

**Evidence:**
- `TabBarView(children: ContentType.values.map((contentType) { ... }))`
- Inside each child builder, content list is produced by `_getFilteredContent(context)`.
- `_getFilteredContent` resolves content type from `_tabController.index`, not the `contentType` of the mapped tab child.

**Risk (P1):**
- Each tab child is using global current index instead of explicit tab argument.
- This can cause all tab pages to compute from the same active tab state rather than each tab’s intended type when widget subtree lifecycles/cache differ.
- Semantically, this is a design bug: per-tab rendering should be derived from the tab child type parameter, not a mutable controller index inside shared helper.

---

## 3.2 Ingress contract mismatch (`initialSubcategory`)

**Evidence:**
- Widget constructor accepts `initialSubcategory`.
- No use of `initialSubcategory` in state/filter flow.

**Risk (P2):**
- Caller can pass subcategory expecting scoped content landing, but screen ignores it.
- This is contract drift similar to the History screen ingress issue class.

---

## 3.3 Category constant mismatch risk

**Evidence:**
- Category list initializes with `AppStrings.allCategories`.
- Filtering logic checks literal `'All'` in multiple places.

**Risk (P2):**
- If `AppStrings.allCategories != 'All'`, default/unset behavior can drift.
- This duplicates label semantics instead of using one canonical token.

---

## 3.4 Bookmark state ownership and async hydration

**Evidence:**
- `EducationalContentService` loads bookmarks via async `_loadBookmarks()` in constructor.
- Service is provided as plain `Provider<EducationalContentService>`, not notifier/stream.
- Screen uses `ref.read(...).isBookmarked(...)` inside card and relies on local `setState` after toggle.

**Risk (P2):**
- Initial bookmark hydration is async but does not notify consumers; first render may not reflect persisted bookmarks until incidental rebuild.
- Bookmark UI consistency depends on manual `setState` call patterns rather than reactive provider updates.

---

## 3.5 Ad context side effects in `build`

**Evidence:**
- `build()` sets:
  - `adService.setInClassificationFlow(false)`
  - `adService.setInEducationalContent(true)`
  - `adService.setInSettings(false)`

**Risk (P3):**
- Side-effectful service writes in build path increase render churn risk.
- `AdService` defers `notifyListeners` post-frame to mitigate, but this pattern still couples rendering with mutable global ad context toggles.

---

## 3.6 Content source model

**Evidence:**
- `EducationalContentService` uses in-memory seeded catalog and local `SharedPreferences` bookmarks.

**Strengths:**
- Stable offline-first educational catalog.
- Deterministic daily-tip helpers implemented.

**Risk (P3):**
- Catalog update path is code-push dependent; no dynamic backend feed contract in this screen/service.

---

## 4) Prioritized findings

## P1 findings

### EC-01: Tab content derivation tied to `_tabController.index` inside each tab child
- Should derive per-child content from `contentType` argument to avoid shared-index coupling.

## P2 findings

### EC-02: `initialSubcategory` ingress parameter is ignored
- Contract accepted by widget but not honored.

### EC-03: Mixed use of `AppStrings.allCategories` and literal `'All'`
- Label/token drift risk for filtering defaults.

### EC-04: Non-reactive bookmark hydration model
- Async bookmark load has no explicit consumer notification path.

## P3 findings

### EC-05: Ad context writes occur during build
- Side-effectful global state updates in render function.

### EC-06: Educational catalog is static and app-bundled only
- Update agility is limited without release.

---

## 5) Dependency map (screen-local)

- `educationalContentServiceProvider` (`app_providers.dart`) → `EducationalContentService`
- `adServiceProvider` → `AdService`
- `BannerAdWidget`
- `ContentDetailScreen`
- `EducationalContent` model (`ContentType`, `ContentLevel`)

---

## 6) Verified vs inferred

## Verified
- `initialSubcategory` is not consumed.
- Filtering helper relies on `_tabController.index`.
- Build path mutates ad context.
- Bookmark load is async and non-notifying by service design.

## Inferred
- User-visible tab inconsistency severity depends on how `TabBarView` child caching and rebuild timing interact in runtime.

---

## 7) No-code recommendations

1. Move per-tab content derivation to explicit `contentType` argument in tab child builder.
2. Either implement `initialSubcategory` filtering or remove parameter to restore contract honesty.
3. Replace literal `'All'` comparisons with a single canonical category token/source.
4. Make bookmark state reactive (notifier/stream/value-listenable) so hydration and toggles are predictable.
5. Shift ad context assignment out of build into lifecycle-aware screen-enter/exit policy.

---

## 8) Final assessment

`EducationalContentScreen` offers strong UX breadth, but it has **contract and reactivity debt** that can create subtle inconsistencies in what users see and what filter state promises.

**Overall status:** Feature-rich surface with medium logic-consistency risk; tab derivation and ingress contract should be prioritized first.
