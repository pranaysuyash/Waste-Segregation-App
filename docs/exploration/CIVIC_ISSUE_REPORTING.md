# Map-Based Civic Issue Reporting

**Status**: Seed — no implementation
**Priority**: 🟢 (P2 — civic intelligence track)
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) — Section F: Locality & Civic Waste Intelligence (L2)
**Related**: [CIVIC_TRUST_AND_VERIFICATION.md](CIVIC_TRUST_AND_VERIFICATION.md), [CIVIC_PRIVACY_SAFETY_REVIEW.md](CIVIC_PRIVACY_SAFETY_REVIEW.md), [USER_CONTRIBUTION_UGC_PIPELINE.md](USER_CONTRIBUTION_UGC_PIPELINE.md)

---

## Overview

Map-based civic issue reporting allows users to report waste-related problems in their neighborhood: missed pickups, illegal dumping, overflowing bins, contaminated recycling, and other civic issues.

This is a **pilot-scope surface only** until the moderation, privacy, and trust foundations (L6, L3/L4) are in place. Never launch as public surface before those gates pass.

---

## Why This Matters

1. **Natural product extension**: a user who just classified a pile of illegally dumped waste wants to report it.
2. **Civic data value**: aggregated issue data is the most valuable civic product for B2B/B2G buyers (L5).
3. **Community stickiness**: issue reporting + resolution status creates a closed-loop feedback that drives return visits.
4. **Competitive position**: no Indian waste app offers civic issue reporting with resolution tracking.

---

## Design Decisions

### 1. Issue Type Taxonomy

**Pilot scope categories** (expand only with moderation capacity):

| Category | Examples | Severity | Auto-routing |
|----------|----------|----------|-------------|
| Missed pickup | Scheduled collection not completed | Medium | Ward office |
| Illegal dumping | Bulk waste on roadside, empty lot dumping | High | Municipality / enforcement |
| Overflowing bin | Community bin not emptied for >48h | Medium | Collection contractor |
| Contamination | Recyclables in wet waste bin, hazardous visible | Medium | Education + enforcement |
| Damaged infrastructure | Broken bin, broken vehicle access road | Low | Maintenance department |
| Stray animals at waste | Dogs tearing bags, cattle eating waste | Low | Animal control / ward |

**Lifecycle states**: `Reported → Verified (auto/manual) → InProgress → Resolved → Closed`

### 2. Duplicate Detection

Multi-factor dedup before report submission:

- **Proximity**: coordinate radius check (50m default for dumping, 100m for infrastructure)
- **Category**: same category match required (pothole doesn't duck with graffiti)
- **Time window**: reports resolved/closed >30 days don't trigger dedup
- **Confidence formula**: if 3+ unconfirmed reports of same type within 50m in 48h, auto-flag as duplicate and consolidate

**UX**: On report submission, show "3 people already reported this issue near here. Add your report to confirm it." User's report becomes a confirmation vote, not a new report.

### 3. Photo Moderation

**On-device pre-processing**:
- Strip EXIF before upload (location, device, timestamp)
- Optional face/license-plate blur (detect → blur → confirm overlay — must be non-blocking, user can skip)

**Moderation tiers**:
- Auto-accepted: text-only reports, no photo
- Queued for moderator: any report with photo
- Flagged for review: photo with detected face/plate that wasn't blurred

**Storage retention**:
- Active reports + photos: retained until resolved + 30 days
- Rejected reports: deleted within 24h
- Resolved reports: photos retained 90 days for audit, then auto-delete (text retained)

### 4. Moderation Cost at <100k MAU

**Estimate**:
- At 100k MAU, ~1-2% of users report per month (~1,000-2,000 reports)
- ~30-50% include photos (~300-1,000 photo reports)
- Manual review time: ~30 seconds per photo report = 2.5-8 hours/month
- **Feasible for 1 part-time moderator at pilot scale**

**Scale breakpoint**: when reports exceed ~500/month with photos, need automated flagging + community moderation to avoid backlog.

### 5. Pilot-Scope Gating

**Must launch as pilot only** — never public surface on day one:

- **Ward-scoped**: single ward or zone from existing city plugin coverage
- **Invite-only**: beta code for pilot apartment/school participants
- **Community partner-led**: launch through an existing RWA, school, or NGO partner who validates reports before they reach municipality

**Expansion criteria** (must pass all):
- Moderation pipeline handles current volume with <24h turnaround
- Duplicate detection catches >80% of true duplicates
- False report rate <2% of total submissions
- Takedown request processed within 48h

### 6. Success Metrics

| Metric | Target | Why |
|--------|--------|-----|
| Resolution rate | >60% within 30 days | User sees issues get fixed |
| Time to first action | <48h for high-severity | Trust driver |
| User return rate | >25% submit >1 report | App perceived as effective |
| False report rate | <2% | Moderation quality |
| Duplicate catch rate | >80% | Reduces moderator load |

### 7. Privacy-Safe Coordinate Model

**Two-fidelity storage**:

| Field | Public visibility | Internal/ACL-gated |
|-------|------------------|-------------------|
| `coords_public` | Snapped to nearest intersection + 10m jitter | Stored in Firestore with public read rule |
| `coords_exact` | Never exposed | Stored in Firestore with `{owner, moderator, authority}` ACL |
| `address_hint` | "Near 5th Cross, Indiranagar" | Generated from exact coords, not stored |

**Rationale**: Public map view needs approximate location to avoid revealing reporter's exact position. Authority/contractor needs exact coordinates to dispatch.

---

## Risk & Mitigation

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| False reports (malicious/spam) | Medium | Medium | Rate caps per user, trust-weighted visibility, photo required for high-severity |
| Defamation (report against worker/contractor) | Low | High | Review all named-person reports before publication; takedown SLA <24h |
| Harassment (map of unsafe neighborhoods) | Low | Medium | Coarse public coordinates only; blocklist for sensitive locations |
| Low resolution rate kills trust | High | High | Start with pilot zone where we have a partner who commits to resolution SLA |
| Legal liability for unaddressed reports | Low | Medium | Terms of service: "we facilitate reporting, not resolve issues"; no implied duty of care |

---

## Implementation Path

1. **Phase 0 (scaffold)**: Issue type taxonomy, Firestore schema, duplicate detection logic, moderation queue. No public surface.
2. **Phase 1 (pilot)**: Single-ward launch with partner. Text-only reporting. Manual moderation. Basic status tracking.
3. **Phase 2 (photos)**: Add photo support with on-device EXIF strip + optional blur. Moderation queue scales.
4. **Phase 3 (map view)**: Public map with coarse coordinates, status colors, cluster markers. Notifications on status changes.
5. **Phase 4 (authority handoff)**: Automated report CSV/PDF generation for ward office. Escalation to L5.

---

## Open Questions

- Should issue reporting be a separate tab/screen or nested inside the community/feed surface?
- How do we handle reports that cross ward boundaries (e.g., dumped waste on ward border)?
- What is the minimum report-to-resolution SLA we need to advertise to earn user trust?
- Should resolved reports be publicly visible (transparency) or hidden (reduces noise)?
