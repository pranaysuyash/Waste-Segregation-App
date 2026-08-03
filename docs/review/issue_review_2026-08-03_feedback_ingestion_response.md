# Issue Review: End-User Feedback Ingestion and Documentation Truth Alignment (2026-08-03)

## Context
User provided a detailed review via chat-paste. The focus was on:
- PMF direction around completion loops (collection schedules, pickup events, reminders)
- Safety/uncertainty semantics and authority hierarchy
- Evidence-backed claims and release truthfulness
- Policy taxonomy alignment
- Privacy/encryption documentation consistency

I used the sol-advisor orchestration guidance and the repository’s local conventions to focus on high-leverage, low-risk actions first.

## Scope Completed in This Pass
1. Reframed `docs/reference/END_USER_README.md` from marketing-style claims to evidence-safe project statements.
2. Removed unsupported metrics/claims in the user-facing doc, including:
   - fixed percentage/latency production-style assertions,
   - removed hardcoded retention/adoption figures,
   - removed overconfident production/privacy claims,
   - aligned status language to measured/target/hypothesis labels.
3. Updated queue storage comments in `lib/services/queue_image_storage.dart` to remove incorrect app-level encryption framing and align with sandbox-only temporary handling.

## Follow-up: PMF Guidance from Feedback
The feedback strongly suggests treating completion as the unit of value:
- Identify -> prepare -> stream match -> collectable path -> completion.
- Area schedules/pickup zones should be a first-class user loop, not a secondary feature.
- Community remains useful only when tied to operational actions (events, missed pickups, verified changes).
- Consumer loops should likely be free/low-friction; premium value should attach to operational workflows, reminders, family/household controls, and compliance tooling.

## Open Work (Next Pass)
- Define minimal PMF pilot surface for Bangalore households + helpers:
  - area map, schedule, exceptions, reminders, event alerts.
- Define authority hierarchy in policy docs:
  - statutory > city > collector/facility > RWA > user preference.
- Add evidence model for environmental fields:
  - keep only fields that change a user/ops decision, each with source, confidence, method, units, retention.
- Add one release-proof document tied to current SHA with commands and pass/fail checks.

## Verification Notes
- No production behavior changes were introduced in this pass.
- `lib/services/queue_image_storage.dart` comment changes are documentation-level and do not alter runtime logic.
- README is now aligned to implementation reality and avoids unsupported claims.

## Recommendation
Proceed with a narrow execution pass next: schedule/timetable + pickup completion workflows on home/result surfaces, then re-run this issue review after user-facing completion metrics and operator update workflows are live.

## Addendum (2026-08-03): completion-loop response implemented

The requested follow-through now covers the first actionable completion loop on the result and history surfaces:

1. Local policy keys are converted into visible collection and alternative pickup routes.
2. The user can mark a route as the next follow-up step, or leave a blocked handoff explicitly open.
3. The selected route, source policy snapshot, status, notes, and timestamps persist in the existing profile preference store.
4. History makes status and follow-up state visible and filterable, so unresolved handoffs do not disappear into an undifferentiated archive.

This keeps the user-facing claim conditional and evidence-safe: the app records a policy-backed next step, but does not claim that a collector has accepted a pickup or that a facility is available until an external workflow confirms it. The existing facility lookup path is recorded as `facility_lookup` and remains a discovery action, not a pickup guarantee.

### Verification update
- `result_screen_test.dart` covers persisted rendering and policy-route persistence.
- `disposal_completion_history_screen_test.dart` covers follow-up/blocked filtering, status visibility, update preservation, and facility-route visibility.
- The combined focused suite passed 15 tests; scoped analysis passed with no issues.

The next product decision remains whether reminders and collector confirmation belong in a new event-backed workflow. That is intentionally outside this two-screen, preference-persistence scope.

## Direct answer to your PMF framing question

Your framing is close to the right shape. Area-wise timetables, pickup zones, pickup/closure events, and practical alternatives are not secondary; they are the core repetition engine. A consumer who already knows common bins still needs:

1. `what should I prepare?`
2. `where should it go today or by this week?`
3. `what happened after I took action?`

That means this product loop is stronger as:

- Identify item  
- Give prep instructions  
- Resolve to local disposal stream (wet, dry, sanitary, special-care)  
- Show local collection window, collector/zone, and verified exceptions  
- Track completion outcome (pending, dropped, collected, failed, escalated)

So no, you are not framing it wrong. You are trimming toward one coherent job.  
Your current instinct to compare to narrow utility apps is useful: those apps earn usage from habitable, repeatable routine, not novelty. The same principle applies here, but only if the flow solves the end action, not just identification.

## Newest action plan (recommended now)

1. **P0 — completion reliability (build next)**  
   - Add one event-backed completion status service: `schedule_exception`, `handoff_initiated`, `handoff_completed`, `handoff_failed`, `escalated`.
   - Persist status with source authority, timestamps, and audit notes.
   - Add collector confirmation + SLA refresh fields.

2. **P1 — schedule/zone ops surface**  
   - Introduce a simple operator/admin patch route for verified schedule updates and temporary exceptions.
   - Add area-specific “next pickup” card on home and result surfaces from the same policy/versioned source.
   - Show exception and event cards only when verified and scoped to ward/zone.

3. **P1 — community as signal (not feed)**  
   - Convert community cards to event cards tied to actionable outcomes (missed pickup, e-waste drive, facility open/closed, bulk pickup changes).
   - Hide passive social engagement surfaces from the hot path.

4. **P2 — claims + naming discipline**  
   - Complete a staged naming scan:
     - app-store search results,
     - domains (including `.com`, `.in`, `.app`),
     - social handles,
     - India trademark database.
   - Keep this as a decision packet with outcomes and legal-signoff status.

5. **P2 — environmental evidence clean-up**  
   - Keep raw environmental values only in evidence-backed structures with:
     - source/method,
     - uncertainty,
     - units,
     - geography/time validity,
     - retention policy.
   - Remove non-evidenced fields from decision-critical UI paths.

## Name-signal note

I ran an initial broad web check for shortlisted names (`SortCue`, `SahiSort`, `BinBatao`, `KoodaKahan`, `SortSaathi`, `MaterialRoute`) to support naming sensitivity. Results were noisy and inconclusive and are **not legal clearance**. This is enough to avoid naming obvious duplicates in a first pass, but final clearance still needs a full trademark/legal process before launch decisions.
