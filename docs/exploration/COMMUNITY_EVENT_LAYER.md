# Community Event Layer

**Status**: Draft — no code surface for community events exists yet.
**Priority**: P2 (builds on community feed and UGC pipeline maturity)
**Related**: [USER_CONTRIBUTION_UGC_PIPELINE.md](USER_CONTRIBUTION_UGC_PIPELINE.md), CIVIC_ISSUE_REPORTING.md, VIRTUAL_GARDEN_AND_MASCOT.md (separate doc)
**Last Updated**: 2026-05-25

---

## Why This Is a Topic

Community events are a natural extension of the waste/sustainability product:

1. **Cleanup drives** — users organize/join neighborhood cleanups, log waste collected.
2. **Collection events** — e-waste drives, bulk recyclable drop-offs, compost workshops.
3. **School campaigns** — inter-school waste sorting competitions, field trips to recycling facilities.
4. **Social accountability** — events create real-world moments where individual actions add up to visible community impact.

However, events require verification infrastructure, moderation, and anti-spam measures that don't exist in the current app.

---

## Event Types

| Type | Example | Verification Needed |
|------|---------|-------------------|
| **Cleanup drive** | "Sunday morning park cleanup at Cubbon Park" | GPS geofence + photo proof |
| **Collection event** | "E-waste drop-off at apartment complex, 10AM-2PM" | QR check-in at location |
| **Workshop** | "Composting for beginners — online session" | Attendance confirmation |
| **School campaign** | "Grade 5 waste sorting challenge" | Teacher sign-off |
| **Competition** | "Wing vs wing: who sorts best this month?" | Auto-tracked from classification data |

---

## Event Lifecycle

```
Draft → Review → Published → Open for RSVP → In Progress → Closed → Archived
```

1. **Draft**: Organizer creates event (title, date, location, type, capacity, description).
2. **Review**: Automated check (valid date, valid location, no prohibited content). For public events, optional human review.
3. **Published**: Event is discoverable in community feed, search, calendar.
4. **Open**: Users can RSVP, see who's attending, share event.
5. **In Progress**: Based on event time window. Check-in opens.
6. **Closed**: Event ends. Impact data is finalized.
7. **Archived**: Event moves to history. High-quality events can be promoted to template library.

---

## Verification Mechanics

### Tiered Approach

| Verification Level | Method | Trust |
|-------------------|--------|-------|
| **Low** (workshops, online) | Self-attestation + optional photo | Low |
| **Medium** (cleanup drives) | GPS geofence at location + optional photo | Medium |
| **High** (collection events, school) | Organizer QR sign-off + photo evidence | High |

### GPS Verification

- Organizer sets a geofence radius (e.g., 200m around park entrance).
- Participant must be within the fence at event time to check in.
- Anti-spoof: cross-street-level accuracy (GPS, not coarse network location).
- Fallback: if GPS fails, organiser can manually verify.

### QR Check-In

- Organizer generates a one-time QR code for the event.
- Participant scans to verify attendance.
- QR expires after event end time.
- Organizer can re-generate for late arrivals.

### Photo Evidence

- Participant uploads 1–3 photos of their contribution (collected waste, sorted items, compost pile).
- Photos are reviewed by organizer (or AI-moderation-filtered for obvious spam).
- Photos stored with event record, not in personal gallery.

---

## RSVP and No-Show Management

- **Free events** (default): RSVP via one tap. No payment required.
- **No-show rate** at free events is typically 40–60%.
- **Mitigations**:
  - 24hr pre-event reminder with "confirm attendance" button.
  - Waitlist auto-promotion when confirmed attendees drop.
  - For capacity-limited events: hold deposit (refunded on check-in).
  - "Three strikes" no-show flagging for users who habitually no-show.

---

## Recurring Events

- Organizer can create a "Series" — weekly, biweekly, monthly, custom schedule.
- Participants can "subscribe" to the series.
- Series events are auto-generated based on recurrence rule.
- Organizer can cancel individual instances without killing the series.

---

## Impact Calculation

After an event closes, the platform calculates:

| Metric | Source |
|--------|--------|
| **Participants** | Check-in count |
| **Total kg collected/donated** | Organizer report + participant input |
| **Material breakdown** | From classification data of items scanned at event |
| **Diversion estimate** | kg correctly sorted vs landfill-bound |
| **Volunteer hours** | Event duration × participants |

---

## Moderation & Safety

- **New organizers**: events from first-time organizers go through strict review (human check before publish).
- **Trusted organizers**: after 3+ successful events, auto-publish with rate limits.
- **Prohibited events**: political rallies, paid commercial events, dangerous activities.
- **Reporting**: participants can report inappropriate or unsafe events.
- **Cancellation**: organizer can cancel up to 24h before. Last-minute cancellation triggers trust score penalty.

---

## Pilot Scope

### Phase 0: Self-Organized Cleanups

- No platform coordination. User scans "Cleanup mode" → logs items as cleanup contributions.
- Verification: self-attestation + optional photo + GPS at location.
- Rewards: special cleanup badges, no token multiplier (anti-farming).

### Phase 1: Organizer-Created Events

- User creates event with title, date, location, description.
- RSVP + check-in via GPS or QR.
- Impact calculated from participant scans during event window.

### Phase 2: School & RWA Campaigns

- Events tied to organizations (school, apartment).
- Organizer role gated to verified admin.
- Post-event report cards and impact certificates.

---

## Open Questions

1. **Should events be visible to non-users?** E.g., shareable link to public event page. Proposal: yes for discovery, RSVP requires app user.
2. **Liability**: if a cleanup results in injury, does the platform have liability? Legal review needed.
3. **No-show penalties**: should no-shows affect the user's community trust score? Proposal: flag only (no trust score penalty) to keep participation low-friction.
4. **Waitlist**: manual or auto-promote? Auto-promote with notification.

---

## Related Work

- [USER_CONTRIBUTION_UGC_PIPELINE.md](USER_CONTRIBUTION_UGC_PIPELINE.md) — review pipeline for user-created content
- CIVIC_ISSUE_REPORTING.md — map-based reporting that shares infrastructure with event check-in
- VIRTUAL_GARDEN_AND_MASCOT.md — may use event participation as a growth trigger
- [CIVIC_TRUST_AND_VERIFICATION.md](CIVIC_TRUST_AND_VERIFICATION.md) — Waze-style verification loops for geo-tagged data
