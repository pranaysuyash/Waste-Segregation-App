# Issue Review: PMF Reframe — What likely improves adoption (2026-08-03)

## One-line verdict
The PMF framing is mostly correct: **the hardest gap is not recognition accuracy, but completion utility**.

## What to focus on first
Area-wise timetables/pickup context is the correct high-impact first loop.

- Add location-aware next-pickup guidance into the “Today/Home” flow.
- Make pickup timing, zone and collector context a first-class action state (not only recommendation text).
- Add exception/special-event surface (missed pickup, temporary closure, drives).
- Keep guidance free at the core loop; avoid per-scan paywalls and frequent re-scan nudges.

Community should be useful only when operationally grounded.

- Useful community = events, closures, alerts, verified reports.
- Low-value community = broad social feed disconnected from service reality.

## Key PMF design correction
The loop should be:
1. Identify
2. Prepare correctly
3. Assign to stream and collector context
4. Show when it can be collected
5. Provide alternative disposal completion path
6. Capture completion outcome

This gives recurring, high-intent usage (households + helpers + RWA residents) even after common objects are no longer novel.

## Four-stream alignment note
The SWM-2026 direction in India strongly supports surfacing wet/dry/sanitary/special-care as household framing first, with special-care subflows for batteries, medicines, electronics, sharps, etc. This improves regulatory realism without blocking the existing model taxonomy.

## Environmental/impact metric correction
Fields like CO2, contamination toxicity, disposal cost, decomposition and similar fields should remain only where evidence + method + confidence are explicit.

For each such metric, persist:
- value range + unit
- evidence source + methodology version
- uncertainty/confidence
- geography/validity window + last verified timestamp
- decision impact (what behavior it changes)

Otherwise present as “informed estimate” or remove from decision-critical paths.

## Immediate implementation sequence (P1)
1) `Collection context first-classing`
- Add zone/area-aware next collection to home + result surfaces
- Add policy provenance and exception confidence states

2) `Completion layer (MVP)`
- Add “where/when else to dispose” alternatives for non-routine streams
- Add lightweight completion mark (took to pickup/facility/drop-off)

3) `Community as signal, not feed`
- Add verified event and pickup-notice card stream per area
- Keep social/reward content secondary

4) `Monetization safety`
- Keep core disposal guidance free
- Gate premium for household-level extras (multi-home/family sharing, advanced reminders, facility-level tools, compliance exports)

## Documentation and evidence requirements (for trust)
- Mark any operational claims with explicit evidence evidence source and date.
- Avoid “production-ready” wording until CI/build/install and runtime smoke evidence is consistently current.
- Add a recurring checklist for any public-facing metrics claims.

## Addendum (2026-08-03): PMF Home-Surface test hardening slice

### What was completed in this pass
- Reworked the home-screen smoke behavior for PMF flow by emphasizing:
  - area-aware collection schedule card (`home_area_schedule_card`),
  - primary action rail (`home_action_scan`, `home_action_upload`, `home_action_guidance`, `home_action_history`),
  - pending special-handling card (`home_pending_special_card`),
  - guidance-first completion copy.
- Added deterministic action-rail testability by assigning `home_action_rail` key to the horizontal action `ListView`.
- Hardened hero-header layout in `HomeScreen` to avoid overflow under narrow viewport and larger text scale by:
  - increasing header height margin,
  - reducing header vertical paddings,
  - compressing text style and line limits.
- Removed heuristic environmental claims from `CommunityImpactCard`:
  - CO₂ totals now require evidence-backed environmental metrics (`co2_avoidance` / `co2Impact`).
  - Added numeric extraction path via `WasteClassification.getEnvironmentalMetricNumericValue` for safe aggregation.
  - `test/widgets/community_impact_card_test.dart` was updated to only assert verified impact rows.

### Evidence run
- Executed: `flutter test test/screens/home_screen_test.dart`
- Result: all tests in the file passed.
- Executed: `flutter test test/widgets/community_impact_card_test.dart`
- Result: all tests in the file passed.

### Remaining PMF-relevant gaps
- This pass does not yet implement schedule exception/events management, pickup confirmation, or completion outcomes from home into collector workflows.
- Community surface still needs operator-grounded event feeds before this can claim end-to-end habit-loop support.
- Environmental metric evidence controls are still pending outside this slice.

## Addendum (2026-08-03): completion layer follow-through

The P1 completion layer now has a concrete screen-level loop:

- Result handover shows policy-backed alternatives for scheduled collection, pickup area/zone, collector, authority helpline, and recorded collection locations.
- A selected alternative becomes an explicit follow-up action with its source policy key. Blocked handoffs remain visible as unresolved follow-up work.
- Completion history exposes status, follow-up state, policy key, next step, and filters for all, follow-up, and blocked records.
- Editing a history record preserves the policy snapshot and alternative routes, so the audit context is not lost when a user updates notes or status.

This advances PMF steps 4 through 6, from “show when it can be collected” to “provide an alternative completion path” and “capture completion outcome,” while keeping the existing profile preference store as the single persistence path.

### Evidence and boundaries
- Focused widget coverage passed 15 tests and scoped analysis passed with no issues.
- This is not yet a full habit-loop integration: reminders, pickup confirmation, exception/event management, live collector updates, and home-surface completion outcomes remain open.
- The hardening path is an event-backed completion workflow with policy refresh timestamps, operator visibility, retry/idempotency handling, and integration/device verification.

## Addendum (2026-08-03): Confidence and schedule metadata hardening follow-up

### What was just completed from the missing feedback pass
- Updated environmental score and point attribution to require evidence-backed metrics in `waste_classification.dart` and `interactive_classification_tags.dart`, ensuring raw pseudo-metrics no longer inflate score or public impact signals.
- Updated `test/models/waste_classification_test.dart` to validate that raw legacy metric fields are ignored for verified score display and that evidence-backed records are accepted only when source/confidence metadata exists.
- Updated BBMP guideline application in `lib/services/local_guidelines_plugin.dart` to use the shared policy enrichment path so local regulations now consistently include governance and collection metadata in one output map.
- Updated `test/enhanced_ai_analysis_v2_test.dart` to assert the actual source-status contract exposed by `CityPolicyData` (`unverified` by default) and verified schedule metadata flow through `localRegulations`.

### Commands and outcomes
- `flutter test test/models/waste_classification_test.dart test/enhanced_ai_analysis_v2_test.dart test/widgets/community_impact_card_test.dart`
- Result: all targeted tests passed.

## Addendum (2026-08-03): Home completion history CTA follow-through

### What was implemented

- On the home completion summary card, added a new action:
  - `Open completion history`
- The CTA now opens `DisposalCompletionHistoryScreen` directly, even when users only want a quick audit sweep instead of editing one record.
- The existing `Update this item` action is preserved for item-level follow-up continuity.
- This creates a clearer one-screen completion workflow in line with the PMF loop: identify, prepare, hand off, and then confirm completion from a recurring surface.

### Commands and outcomes
- `dart format lib/screens/home_screen.dart test/screens/home_screen_test.dart`
- `flutter test test/screens/home_screen_test.dart`
- Result: all targeted tests passed.
