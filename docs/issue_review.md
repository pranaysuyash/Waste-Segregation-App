# Issue Review: Actionable Area Schedule and Pickup-Community Surface

**Date:** 2026-08-03
**Severity:** P1 product utility, low runtime risk
**Scope:** `CityPolicyData`, `LocalGuidelinesPlugin`, `HomeScreen`, and the home-screen contract tests.

## Problem

The earlier PMF slice exposed area schedules, pickup-zone chips, community
notices, and schedule exceptions, but the home card still read like static
reference material. It did not answer the household's immediate question:
"What can I prepare today or tomorrow, and what should I do when an area notice
changes the normal path?"

## Decision

Extend the existing canonical policy data and `home_area_schedule_card` in place.
Do not add a second schedule route, a persistence migration, a booking workflow,
or a new plugin type. Exact `Today` and `Tomorrow` windows are rendered only for
daily/immediate schedules or entries with explicit weekday data. All other
configured schedules remain visible under `Upcoming windows` without an invented
date.

The latest PMF follow-up adds a dedicated Home reminder surface that computes
the next confirmed collection windows from those same schedule entries and shows
`Today`, `Tomorrow`, and next-weekday reminders so households can act ahead of
pickup windows.

Pickup metadata uses the existing string map with additive keys for
`last_verified` and source context. The UI shows confidence, last verified date,
and source together. Notice cards retain their existing `CommunityOperationNotice`
shape and add a conditional `Next step` instruction derived from the notice type.
The instruction is operational guidance, not evidence that a collector accepted
or completed a pickup.

## Changes

- `lib/services/city_policy_data.dart`
  - Added optional pickup last-verified metadata for the BBMP seed data.
  - Added exact dry-waste weekdays and additive policy-enrichment keys for pickup
    confidence, verification date, and source.
- `lib/services/local_guidelines_plugin.dart`
  - Preserved plugin IDs and manager mapping while delegating the new schedule
    metadata through the existing city-data path.
  - Included configured collection weekdays in BBMP recommendations.
  - Kept superseded private helpers as compatibility references with explicit
    analyzer rationale.
- `lib/screens/home_screen.dart`
  - Added `Today`, `Tomorrow`, and `Upcoming windows` schedule buckets.
  - Added `home_pickup_reminder_card` and reminder extraction from schedule maps
    with deterministic friendly date labels.
  - Added pickup confidence, last-verified, and source context.
  - Added next-step instructions to community notices, schedule exceptions, and
    special-program entries.
  - Preserved the area card key and existing action tile keys.
- `test/screens/home_screen_test.dart`
  - Covers the three schedule states, pickup metadata, operational notice actions,
    and direct plugin/data delegation.

## Verification evidence

- Tier 2 targeted widget evidence: the home-screen suite passes with the updated
  PMF assertions.
- Tier 2 targeted policy evidence: the local policy engine suite passes, showing
  the additive data changes do not regress policy application.
- Tier 1 analyzer evidence: the requested scoped analyzer completes with no
  issues.

Final command results from 2026-08-03:

- `flutter test test/screens/home_screen_test.dart --reporter=expanded`:
  `00:02 +18: All tests passed!`
- `flutter test test/services/local_policy_engine_test.dart --reporter=expanded`:
  `00:00 +31: All tests passed!`
- `flutter analyze lib/services/local_guidelines_plugin.dart
  lib/services/city_policy_data.dart lib/screens/home_screen.dart`:
  `No issues found! (ran in 2.1s)`

## Open gaps and closure criteria

1. **Static source refresh:** There is no operator workflow to edit, refresh, or
   expire area schedules. Close when an authorized source-refresh path records
   effective dates, reviewer, and audit history and the home card consumes it.
2. **Reminder delivery:** The card does not schedule notifications. Close when a
   reminder path has permission handling, retry/idempotency behavior, and an
   opt-out surface.
3. **Pickup outcome:** The card does not book or confirm a collector. Close when
   an external event-backed workflow records an observed outcome and keeps it
   distinct from the schedule expectation.

These are explicit boundaries, not claims that the static seed data is live or
officially current. The current UI preserves uncertainty through source status,
confidence, and verification context.

### Anything else?

No pricing, token engine, persistent storage, plugin type ID, or plugin-manager
mapping was changed. Existing concurrent work outside the owned files remains
untouched.

## PMF framing answer to your question

Your instincts are right: this is not a pure scan-product argument.

The most reliable PMF loop is:

1. identify the item,
2. prepare it for correct disposal,
3. map to local stream and pickup window,
4. offer alternatives when the routine path is blocked,
5. track completion.

Area-wise timetables and pickup zones are still the highest-priority user pull,
because they preserve value after short-term novelty of scanning is gone.
Community surfaces only work if they are operationally grounded (missed-pickup
alerts, drive notices, closures, special-collection events), not as a generic
social feed.

## Name direction

For this thesis, brands should communicate completion and completion support, not
only recycling:

- `SortCue` (strong default for execution-first positioning)
- `SahiSort` (India-first alternative)
- backups: `KoodaKahan`, `MaterialRoute`, `BinBatao`

## Immediate next build slice (recommended)

If you want a concrete narrow implementation next:

- add a home completion action to completion-history editing (already partially
  wired),
- add reminder delivery with explicit opt-out in existing notification settings,
- add a schedule exception/update acceptance path so schedule views stay auditable.


## PMF reset decision from pasted feedback (2026-08-03)

The feedback is valid on the core thesis: the long-term loop should be a
"completion loop," not a "recognition loop."

### What to keep and what to trim

What is core for household PMF:

- locate item quickly (scan, search, barcode, voice)
- show preparation and local stream
- show pickup/collection timing and zone
- show what to do when that route is blocked
- capture completion outcome (put out, booked, handed off)

What is secondary right now:

- pure scan retention and novelty mechanics (tokens, frequent challenges)
- broad social/community pages that are not operationally grounded
- speculative impact dashboards and extra environmental fields without data

### Strongest immediate wedge from this feedback

Area schedules and pickup zones are correct as a PMF anchor for recurring use.
Community becomes valuable only when it carries operational action signals such as:
missed pickups, schedule changes, special drives, and verified facility notices.

### Immediate implementation direction

1. Keep home primary flow to a five-part job:
   - identify item
   - prepare it
   - map local stream
   - map next collection or special drop-off
   - mark completion

2. Convert reminders into a real completion loop instead of static display:
   - reminder list → reminder persistence key/value in settings/profile
   - schedule reminders with explicit opt-in and quiet-hours behavior
   - completion action on reminder items (scheduled/picked up/needs retry)

3. Introduce a "completion truth" layer:
   - evidence-supported pickup status
   - facility acceptance state and freshness
   - outcome status transitions (expected vs completed)

4. Treat unsupported claims as release defects:
   - any production-readiness, policy coverage, or accuracy statement must be traceable to the current SHA artifact
   - otherwise label as hypothesis or target.

5. Name direction:
   - keep shortlist names, but do full statutory and app-store checks before final brand choice
   - preliminary public-name signals found:
     - `ReLoop` exists in multiple markets and app ecosystems
     - `SortCue` appears under existing unrelated contexts and should be cleared with trademark/App Store checks
     - `MaterialRoute` appears as a Flutter package term in results
   - no final decision yet; a naming decision is blocked until IP/legal and store checks are complete.

### Suggested next execution slice

- close reminder delivery gap from the current card (actual scheduling/dispatch + completion)
- create completion history state on result/history screens
- add source authority + verification date on special-waste and zone-specific guidance
- keep everything free for core guidance; charge for operations tools (RWA/bulk reporting, pickup management, exports)

This keeps the product coherent: one job, one repeated surface, one evidence layer.

## Pasted feedback (2026-08-03) status snapshot

### Implemented in this pass

- Offline queue privacy contradiction is closed at the code-doc boundary:
  - queue/image storage comments now describe the shipped sandbox-file strategy,
    not app-level encryption.
  - ADR 0006 states platform-level protection and defers AES-256-GCM as a future
    enhancement.
  - offline queue tests now assert that files are actually written and deleted.

### Deferred for planned slices

- Taxonomy alignment to SWM-2026 four-stream top-level structure.
- Safety semantics that force conservative handling under uncertainty for hazardous classes.
- Unsupported customer-facing claims cleanup and evidence labeling (`measured/target/hypothesis`).
- Product scope collapse and monetization reset; naming/trademark validation; release proof bundle.

### Closure criteria

- Each deferred item is closed only when behavior, contract, operator workflow, and
  evidence artifacts are updated together in the same scope slice and validated in
  runtime-relevant checks.

## Additional 2026-08-03 follow-up: policy pack metadata provenance hardening

### Implemented

- `lib/services/local_policy_rule_packs.dart`
  - Added explicit source- and authority-status fields to rule-pack definitions.
  - Replaced BBMP technical label `production` with `deployed` to avoid implying
    official legal approval.
  - Set BBMP source metadata to `verified` and authority metadata to
    `reviewed_by_expert` so the confidence chain is represented without overclaim.
- `lib/services/local_policy_engine.dart`
  - Updated rule-pack assembly to prefer pack-level `sourceStatus`/`authorityStatus`
    when available, with city data as fallback.
- `test/services/local_policy_rule_packs_test.dart`
  - Updated stage assertions to align with the new technical/provenance split.

### Verification

- `dart format lib/services/local_policy_rule_packs.dart lib/services/local_policy_engine.dart test/services/local_policy_rule_packs_test.dart`
- `flutter test test/services/local_policy_rule_packs_test.dart`
- `flutter test test/services/local_policy_engine_test.dart`

### Notes / gaps

- The authority path still clearly signals non-official status for BBMP by using
  `reviewed_by_expert`.
- If your intent is to make BBMP fully authoritative in-app, the next step should
  be a provenance source package with authority-issued status and reviewer,
  version, and signature metadata, then update the trust-policy thresholds.
