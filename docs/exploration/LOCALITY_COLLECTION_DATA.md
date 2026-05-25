# Locality Collection Data

**Status**: Seed — no implementation
**Priority**: 🟢 (P2 — civic intelligence track)
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) — Section F: Locality & Civic Waste Intelligence (L1)
**Related**: [DISPOSAL_FACILITIES_DIRECTORY.md](DISPOSAL_FACILITIES_DIRECTORY.md), [REGION_RULES_AND_CITY_EXPANSION_MAP.md](REGION_RULES_AND_CITY_EXPANSION_MAP.md), [NOTIFICATION_STRATEGY.md](NOTIFICATION_STRATEGY.md)

---

## Overview

The disposal facilities directory (entry A20) answers "where do I take it?". The locality collection data layer answers the complementary question: **"when does collection come to me, and what does it pick up?"**

This includes:
- Collection schedule per address/zone (day of week, frequency, material type)
- Route data (which collector serves which area)
- Disruption alerts (missed pickups, holiday changes, weather delays)
- Collector contact information (public channels only)
- Source-of-truth provenance (municipal API vs crowdsourced vs partner-supplied)

---

## Why This Matters

1. **Retention hook**: collection reminders are a daily-utility use case that drives app opens outside of scan events.
2. **Civic wedge**: collection data is the lowest-risk civic entry point — read-only display needs no moderation pipeline.
3. **Data flywheel**: user-reported disruption ("pickup missed today") is high-value civic data that feeds L2 (issue reporting) and L5 (authority dashboards).
4. **Competitive differentiation**: no major waste app in India provides reliable per-address collection schedules with disruption alerts.

---

## Key Research Areas

### 1. Data Sourcing

| Source | Reliability | Cost | Maintenance | Coverage (India) |
|--------|-------------|------|-------------|------------------|
| Municipal open data API | High where available | Free | Low | <5% of cities |
| Scraping municipal portals | Medium | Engineering cost | High (brittle) | ~20% of cities |
| Partnership (municipality/contractor) | High | Negotiation | Low | Limited |
| Crowdsourced (user reports) | Low → Medium | Moderation | Medium | Anywhere |
| Third-party aggregator (e.g., Opencity.in) | Medium | API fees | Medium | Growing |

**Recommendation**: Hybrid model — start with crowdsourced + third-party aggregator for coverage, add municipal partnerships for verified data in pilot cities.

### 2. Indian Municipal Data Landscape

- **BBMP (Bengaluru)**: No public API for collection schedules. Ward-level data available as PDFs on website. Some data on [opencity.in](https://opencity.in).
- **BMC (Mumbai)**: Ward-wise dry/wet collection schedule published as PDF maps. No structured API.
- **MCD (Delhi)**: Zone-wise collection routes published on portal, not in machine-readable format.
- **GHMC (Hyderabad)**: Swachh Bharat app integration, but no open API for third-party consumption.
- **Pilot cities**: Use the existing city plugin infrastructure (7 cities) to cross-reference.

**Legal note**: Assume "All Rights Reserved" unless explicitly licensed as open data (CC-BY or similar). Do not republish municipal data without verifying terms of use or establishing a partnership.

### 3. UX Patterns for Collection Reminders

**Timing options** (user-configurable):
- Night before (8:00 PM) — default for most users
- Morning of (7:00 AM) — for users who take bins out on collection day
- Custom time

**Frequency**:
- Per-schedule (weekly/biweekly) — single notification per collection event
- Digest mode — weekly summary of upcoming collections (reduces notification fatigue)

**Quiet hours**: Respect system DND. Queue notifications for delivery when DND ends.

### 4. Disruption Alert Design

**Proactive notifications**:
- "Your area's wet waste pickup is delayed by 1 day due to [reason]"
- "Holiday adjustment: no dry waste pickup this Thursday. Next pickup: Monday."

**Status banner on home screen**:
- 🟢 Green: "On schedule"
- 🟡 Orange: "Minor delay"
- 🔴 Red: "Service disruption" with explanation

**Source attribution**: Label disruption source clearly — "Reported by BBMP" vs "Reported by 3 neighbors" vs "Estimated based on history".

### 5. Offline Architecture

Collection schedules are inherently slow-changing (weekly cadence). Use **stale-while-revalidate**:

```
App launch → read from local cache (instant) → background sync check → update if stale
```

- Cache TTL: 24 hours for schedules, 2 hours for disruption status
- Preload next 4 weeks on first sync
- Recovery: if sync fails, show cached data with "(last updated [time])"

### 6. Data Freshness Signals

- **Version tag**: Include `collection_data_version` in payload. Compare on sync.
- **HTTP ETag/Last-Modified**: Standard caching headers on API responses.
- **Auto-expiry**: Any disruption report older than 48h without confirmation is auto-cleared.
- **Seasonal/reset handling**: Collection schedules may change seasonally (e.g., summer vs monsoon). Track effective date ranges.

### 7. User Contribution for Schedule Corrections

**Pattern**: Community consensus model — require N confirmations from distinct users in same zone before surfacing a correction.

- Minimum 3 confirmations from 3 distinct devices in same ward/zone
- Clearly label as "Reported by neighbors" — never "Official"
- Display mandatory disclaimer: "Information is based on community reports. Please check [official portal] for latest updates."
- Cooldown: once a correction is confirmed, no new correction prompts for 7 days (prevents ping-pong)

---

## Risk & Mitigation

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Stale schedule data misleads users | Medium | Medium | Auto-expiry + freshness badges + user correction loop |
| Municipal legal action for data republishing | Low | High | Verify terms of use; partner not scrape |
| False disruption reports (spam/farming) | Medium | Medium | Community consensus model + per-user rate caps |
| Users depend on unofficial data for critical decisions | Low | High | Offboarding copy: "not official — confirm with municipality" |

---

## Pilot Path

1. **Phase 0 (read-only)**: Display collection schedules for pilot wards using crowdsourced + aggregator data. No notifications yet.
2. **Phase 1 (reminders)**: Add collection day notifications with user-configurable timing. Disruption alerts for known holidays only.
3. **Phase 2 (crowdsourced disruptions)**: Enable user-reported disruption with consensus model. Rate caps + disclaimer.
4. **Phase 3 (partner verified)**: Onboard municipal partners for verified schedule + disruption data. Label verified vs crowdsourced.

---

## Research Gaps

- Which Indian cities have machine-readable collection schedule data we can legally access?
- What is the minimum viable coverage for a pilot (single ward / single zone)?
- Can we reuse the existing city plugin infrastructure (7 cities) for schedule data sourcing?
- What notification frequency cap maximizes retention without triggering uninstall for utility notifications?

---

## Decision Needed

- **Go/no-go on collection data as a product surface**: requires confirming at least one pilot city's data is accessible and legally republishable.
- **Notification strategy**: separate from existing notification system, or extend the same framework with collection-specific opt-in?
