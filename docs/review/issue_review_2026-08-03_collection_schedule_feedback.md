# Issue Review: Area-Timetable Surface and Evidence-Ready Collection Guidance

**Date:** 2026-08-03
**Severity:** Medium (P1)
**Scope:** `lib/services/city_policy_data.dart`, `lib/widgets/result_screen/disposal_decision_card.dart`, `lib/widgets/result_screen/local_rules_card.dart`, `test/services/local_policy_engine_test.dart`, `test/widgets/result_screen/disposal_decision_card_test.dart`, `test/enhanced_ai_analysis_v2_test.dart`

## Problem Framing
The feedback review showed collection schedules are a key PMF lever for repeat usage, but current output mostly exposes high-level recommendations and does not expose a clear, verified timetable in the same local-result surface where users make disposal decisions.

## Why this matters
Users can act more reliably when they get:
- what stream the item belongs to,
- what the practical collection window is,
- whether the guidance has policy-source provenance.

That directly supports recurring household routines and reduces dead-end uncertainty.

## Implemented corrections
1. Enriched city policy merge in `CityPolicyData.applyDefaults`
   - Added explicit schedule-derived regulation fields into `localRegulations`:
     - `collection_frequency`
     - `collection_time_window`
     - `collection_notes`
   - Added provenance fields in the same local-regulations payload:
     - `policy_authority_name`
     - `policy_source_status`
     - `policy_authority_status`
     - `policy_governance_stage`
     - `policy_guidelines_version`
     - `policy_source_title`
     - `policy_source_url`
     - `policy_helpline`
     - `policy_last_verified`
     - `policy_next_review`
   - Added `policy_pack_reference` + stable `localGuidelinesReference` context.

2. Local rules rendering
   - Expanded `local_rules_card.dart` label map and order to surface collection fields and provenance metadata in the Local Rules card.

3. Disposal action card
   - Added formatted collection window summary row in `DisposalDecisionCard` when schedule provenance is present.

## Validation performed
- `test/services/local_policy_engine_test.dart`: verified BBMP policy application now includes collection schedule fields and policy source status in enriched regulations.
- `test/enhanced_ai_analysis_v2_test.dart`: verified BBMP `applyLocalGuidelines` emits expected schedule frequency + verified policy source status.
- `test/widgets/result_screen/disposal_decision_card_test.dart`: verified collection-window row is visible in actionable recommendation path.

## Open gaps after this slice
- No operator workflow exists yet for manual schedule edits, pickup exceptions, or area-level schedule overrides.
- No community event/event-feed surface is introduced in this slice.
- No pickup-zone discovery UI exists beyond existing map/collection-tag foundations.

## Next-step recommendation
Use this as P1 foundation and proceed to:
1. schedule verification workflow (collector confirmation + refresh timestamp SLA),
2. schedule exceptions/events layer, and
3. zone-aware “next pickup” home surface.

## Follow-up status (2026-08-03)

### Completed in this pass
- Finalized home-screen PMF wiring for area schedule surfaces by implementing missing `HomeScreen` helper methods used by `_buildAreaScheduleCard`.
- Added zone coverage chips for BBMP pickup metadata (`service_area`, `zone`, `collector`, `confidence`).
- Added rendered cards for community notices (`CommunityOperationNotice`) and shared helper rendering for schedule exception cards.
- Updated `test/screens/home_screen_test.dart` to cover home schedule rendering, zone coverage, community notice, and schedule exception visibility.

### Remaining
- Operator controls for corrections/updates are still missing in this surface.
- Zone-aware completion reminders and pickup-booking follow-through are not yet implemented and remain follow-up work.
