> **Repository:** `pranaysuyash/Waste-Segregation-App`
>
> **Reviewed branch:** `main`
>
> **Reviewed commit:** `e48a66bd6c9116e939a3eddfa5cc48c5d2171e6a`
>
> **Commit timestamp:** 2026-08-02T03:40:33Z
>
> **Review timestamp:** 2026-08-02
>
> **Previous review baseline:** `d7a9c73f75779ddcbf9f22f4ce2fba9a0280b171`
>
# Task: ChatGPT Feedback Closure (PMF + Confidence/Safety)

## Priority

P0 safety correction, P1 product-focus clarification.

## Objective

Apply the most urgent feedback from the pasted review without waiting for a full product reset.

## What has been implemented now

- Policy engine no longer bypasses municipal rules below 0.50 confidence.
- Confidence gating is now explicit asymmetry:
  - `< 0.70` -> warning-only for ordinary flows
  - safety-critical flows keep violation severity.
- `safetyOverrideAlways` remains `violation` regardless of confidence.
- Society overrides that weaken high-risk municipal fields are blocked and surfaced as conflicts.
- Local policy decisions and warnings are still returned for low-confidence cases so users can be guided conservatively.
- SWM-2026 stream derivation is now canonical in the model via `WasteStreamClassifier`, with:
  - explicit stream keys (`wet_waste`, `dry_waste`, `sanitary_waste`, `special_care_waste`, `unknown`)
  - legacy category normalization for legacy labels like `Wet Waste` and `Sanitary Waste`
  - derived `WasteClassification.householdWasteStream` and `isSpecialCareCategory` on the classification object
- Policy provenance is now split across technical/source/authority status:
  - `CityPolicyData` now carries `sourceStatus` + `authorityStatus`
  - `LocalPolicyRulePack` and `LocalPolicyDecision` now carry and propagate `technicalStatus`, `sourceStatus`, and `authorityStatus`
  - unknown source status no longer falls back to technical stage

## Validation run

- `flutter test test/services/local_policy_engine_test.dart`
- Result: all policy tests passed, including new/updated cases for low-confidence ordinary vs safety-critical behavior and blocked high-risk overrides.
- `flutter test test/models/waste_classification_test.dart`
- `dart format lib/models/waste_classification.dart lib/services/local_policy_engine.dart test/models/waste_classification_test.dart test/services/local_policy_engine_test.dart`
- Result: new stream-derived classification tests passed in `test/models/waste_classification_test.dart`.

## High-confidence PMF route to test first

1. **Bengaluru household + housekeeping workflow** around recurring disposal
   - daily schedule visibility
   - local pickup reminders
   - special-waste completion
2. **Society/BWG operations wedge**
   - action tracking, collection logs, and evidence bundle
   - not per-scan monetization
3. **Consumer loop**
   - recurring usefulness from schedule/events, not gamification-only engagement.

## Remaining work from broader feedback

- 4-stream SWM-2026 taxonomy migration and evidence fields remain pending.
- Naming/legal/market checks still need a formal run.
- Offline retention/encryption contradiction remains unresolved in current broader architecture.
- Unsupported public claims and release-readiness statements still require a full evidence packet.
- Area calendars, events, and completion-layer features are still design-level recommendations, not yet implemented.

## PMF interpretation from pasted feedback

- The strongest commercial loop for this codebase today is the **recurring completion loop**, not isolated scans:
  - area-aware collection calendar and pickup windows
  - actionable completion for exceptions (missed pickup, special waste, temporary diversions)
  - facility/facility-hour updates and pickup confirmations
  - household profile of frequently misclassified/repeated items
- In other words, "What do I do now this week?" should outrank leaderboard/gamification in first-screen hierarchy.
- A cleaner naming and positioning direction should avoid locking the product into only recycling language.
  - `SortCue` / `SahiSort` were suggested in feedback as plausible options that better match a guidance/completion flow.
- `waste item metadata + environmental estimate fields` should remain in an **EvidenceRecord** model unless each field has method, source, confidence, and version.
  - keep only values that change an action, and render them as "estimate + uncertainty."
- Product wedge priority for implementation should be:
  1) Bangalore household + housekeeping weekly routine
  2) RWA/BWG compliance reporting for staff workflows
  3) transaction layer only after the completion loop proves it saves time/contamination.

## Late feedback addendum (from pasted-text replay)

- The user’s appended follow-up was to challenge the first PMF conclusion and argue that the feedback should be actionable, not dismissive.
- The same thread proposes a stronger loop:
  - identify the item
  - prepare it for disposal
  - map to one of four SWM-2026 household streams
  - determine where/when collection is available
  - handle overflow/exception through pickup events or drop-off options
  - record whether collection/disposition was completed
- The same feedback accepts that area-wise timetables and pickup zones are likely the strongest near-term retention driver.
- Community surfaces are still useful only if they support operational outcomes (e.g., e-waste drives, missed-pickup alerts, capacity updates), not social-feed mechanics.
- The environmental/impact field set is still valuable in principle, but only if each metric is evidence-backed:
  - explicit source
  - methodology
  - uncertainty/validity range
  - decision impact
- The same file contains the name shortlist and "SortCue" recommendation as the current strongest candidate:
  - SortCue (consumer utility orientation)
  - SahiSort (India-first utility orientation)
  - BinBatao, KoodaKahan, SortSaathi, MaterialRoute
- Recommended naming/positioning path:
  - Keep the consumer loop "scan/ask + schedule + completion" free of per-scan charges
  - Add a paid B2B/B2B2C layer for operational workflow and reporting
- To avoid confusion with "recycling-only" framing, product copy should describe disposal completion and schedule reliability rather than only category prediction.

## 2026-08-03 follow-up implementation (continuation)

### Work completed in repo

- Home screen now exposes the completion loop to users as an explicit recurring surface:
  - Added `home_completion_summary_card` to `HomeScreen` using `UserPreferenceKeys.disposalCompletionLast`.
  - Added status normalization for completion outcomes (`prepared`, `pickup_booked`, `handed_off`, `completed`, `blocked`, `not_recorded`).
  - Included optional classification id, recorded timestamp, and notes in the card.
- The area schedule card now shows `cityData.specialPrograms` as operationally relevant area updates/events (e.g., bulk-waste or special collection notes), replacing part of the old purely informational copy.
- Added a focused home screen test for completion summary visibility when persisted preference data is present.

### Rationale against feedback comments

- This is the first concrete PMF loop improvement from the pasted review: recurring utility over one-off scan behavior.
- It turns completion data from a latent result-screen setting into a home-level reminder of open disposal responsibility.
- It also keeps community-like data grounded in verified municipal program entries rather than generic social-feed interactions.

### Next practical step

- Add a dedicated home action to navigate to a completion history/filter screen and allow manual state changes from home.
- Add operator-level area feed for temporary schedule exceptions/holidays when schedule authority data becomes versioned over time.
