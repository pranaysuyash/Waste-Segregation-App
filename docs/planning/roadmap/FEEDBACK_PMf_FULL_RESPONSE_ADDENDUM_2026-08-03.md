# Feedback-Driven PMF Execution Addendum (2026-08-03)

## Decision
Keep moving ReLoop toward one clear user loop:
1. What is this?
2. How do I prepare it?
3. When and where can I dispose of it?
4. Was it actually completed?

This resolves the earlier ambiguity between consumer utility and social platform signals.

## What we changed now
- Enforced evidence-first environmental behavior in core classification scoring/display surfaces.
  - `lib/models/waste_classification.dart`:
    - added canonical metric keys
    - updated points calculation, impact score, score eligibility, and CO2 tag logic to use `environmentalImpactEvidence` only
  - `lib/screens/result_screen.dart`:
    - impact chip/reveal now reads CO2 from evidence keys only
    - decomposition row now labeled as a legacy estimate when only raw field exists
  - `lib/widgets/result_screen/result_header.dart`:
    - removed fallback to legacy CO2 key in hero KPI
  - `lib/widgets/community_impact_card.dart`:
    - CO2 aggregation now evidence-only
  - `lib/services/parsers/ai_response_parser.dart`:
    - added explicit comment: legacy environmental fields are compatibility-only, non-authoritative

## PMF execution priorities from your feedback
1. **Area-wise schedule layer (highest priority)**
   - Build a local collection graph: area/ward/zone → stream → collector/facility → pickup windows → exceptions.
   - Persist update provenance (authority, effective range, last_verified, confidence).
2. **Completion layer (highest priority)**
   - Add “where did this item actually end up” tracking to close the loop.
   - Collect proof signals (user check-in, photo, pickup note, or handover code).
3. **Operational community layer (supportive, not core engagement loop)**
   - Replace generic social feed with verified event/feed cards:
     - e-waste drives, bulk pickup changes, missed-collection alerts, local cleanup events.
4. **Scan-before-buy and household profile (second wave)**
   - Add barcode/label capture as pre-purchase planning input and family/home profile reminders.

## Why this matches your question
- Timetables and pickup zones are not a side feature: they are the repeatable retention loop.
- Community is useful when it improves reliability, not when it only adds social noise.

## Open evidence debts (explicit)
- No full source-backed release packet has been attached in this thread for:
  - runtime proof of schedule data freshness
  - end-to-end capture→completion flow
  - A/B evidence that collection-loop usage increases retention

## Next concrete work item list
- [ ] Wire verified schedule JSON schema + admin edit/review flow.
- [ ] Add collection exceptions and community event ingestion with source attribution.
- [ ] Add completion state persistence for items (planned, ready, picked, escalated).
- [ ] Add UI for “next pickup” and “urgent alternate handling” on the result screen.
- [ ] Publish one-date evidence packet proving each PMF step above.
