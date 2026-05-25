# Civic Privacy, Safety & Moderation Foundation

**Status**: Seed — no implementation
**Priority**: 🔴 (gates all other L-entries)
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) — Section F: Locality & Civic Waste Intelligence (L6)
**Related**: [PRIVACY_PHOTO_PII.md](PRIVACY_PHOTO_PII.md), [MODERATION_AND_SAFETY.md](MODERATION_AND_SAFETY.md), [CONSENT_ARCHITECTURE.md](CONSENT_ARCHITECTURE.md), [CIVIC_ISSUE_REPORTING.md](CIVIC_ISSUE_REPORTING.md)

---

## Overview

Civic photos can contain faces, license plates, children, and private residences. Civic reports can defame workers, harass contractors, or map unsafe neighborhoods. False reports can cause real-world harm. **No L-entry ships beyond pilot scope until this foundation is in place.**

This doc covers the privacy, safety, and moderation infrastructure that gates every other civic surface.

---

## Hard Gates

The following must be implemented before any civic surface ships beyond invite-only pilot:

| Gate | Requirement | Verification |
|------|------------|-------------|
| On-device EXIF strip | All photos stripped of EXIF before upload | Test: upload original → check server copy has no EXIF |
| On-device face/plate blur | Auto-detect and blur faces + license plates before upload | Test: known-image suite passes blur threshold |
| Coarse-public coordinate model | Public map shows jittered coords; exact coords ACL-gated | Test: public query returns different coords than admin query |
| Photo retention policy | Active photos retained until resolved + 30d; rejected photos deleted 24h | Test: Firestore TTL + scheduled cleanup function |
| Abuse report flow | Subject of report can contest it | Test: abuse flow processes within 24h SLA |
| Takedown SLA | Moderator reviews takedown requests within 24h | Test: alerting + escalation defined |
| Terms of Service update | Explicitly states app does not guarantee accuracy, is not an enforcement tool | Legal review |

---

## On-Device Privacy Pipeline

### 1. EXIF Stripping

All photos uploaded from civic reporting must have EXIF data stripped before transmission:

- Location coordinates
- Device model and OS version
- Camera settings (aperture, shutter speed, etc.)
- Timestamp (applies its own timestamp)
- Any embedded thumbnails

**Implementation**: Use `exif` or `flutter_exif` package to strip EXIF in Dart before upload. Verify server-side that no EXIF leaked.

### 2. Face and License Plate Blur

**Capability question**: Is on-device face/license plate blur feasible on current minimum target device?

**Requirements analysis**:
- Android: min 4GB RAM, Android 12+ — Google ML Kit face detection runs in ~50ms on mid-range
- iOS: iPhone XR+ (A12 Bionic) — Vision framework runs in ~30ms
- Processing budget: <200ms added to upload flow (including blur rendering)

**Implementation options**:
| Option | Accuracy | Performance | Privacy | 
|--------|----------|-------------|---------|
| Google ML Kit (on-device) | Good (faces), No (plates) | Fast | ✅ Fully on-device |
| Apple Vision (on-device) | Good (faces), Good (plates via text detection) | Fast (iOS) | ✅ Fully on-device |
| Custom TensorFlow Lite model | Medium | Medium | ✅ Fully on-device |
| Server-side processing | Excellent | Slow | ❌ Transmits unblurred image |

**Recommendation**: Use platform-native face detection (ML Kit on Android, Vision on iOS) for faces. For license plates, use text detection with pattern matching (look for alphanumeric patterns typical of Indian plates: `[A-Z]{2}[0-9]{2}[A-Z]{1,2}[0-9]{4}`).

**Edge cases**:
- User wears sunglasses or mask → detection may fail; offer manual blur brush
- Multiple faces in frame → blur all detected
- Very dark images → skip blur, flag for moderator attention
- User can skip blur entirely (with warning: "This photo may contain private information")

### 3. Two-Fidelity Coordinate Model

**Schema**:
```typescript
interface CivicReport {
  // Public view (readable by anyone)
  coords_public: GeoPoint;     // snapped to nearest intersection + 2-10m jitter
  address_hint: string;        // "Near 5th Cross, Indiranagar" (generated, not stored as PII)
  
  // Internal view (readable by {owner, moderator, authority} only)
  coords_exact: GeoPoint;      // original GPS coordinate
  property_reference?: string; // optional: apartment name, house number (if user chooses to share)
  
  // Metadata
  location_fidelity: 'coarse' | 'exact_acl';
}
```

**Jitter algorithm**: Add random offset of 2-10m in random direction to coords_public. Seed jitter with report ID so same report always shows same position. Different reports from same location show slightly different positions.

**Firestore security rules**: Enforce ACL at read level — only moderators and the user who reported can read coords_exact.

### 4. Photo Retention Policy

| Photo State | Retention | Action |
|------------|-----------|--------|
| Active report | Until resolved + 30 days | Auto-delete via Cloud Function |
| Rejected report (moderator) | 24 hours | Delete from Storage + Firestore reference |
| Resolved report | 90 days post-resolution | Photo auto-deleted; text retained for audit trail |
| User deletion request | 7 days | Hard delete from all storage + databases |

**Implementation**: Firestore TTL policy (`ttl` field on report document) + scheduled Cloud Function that cleans up Storage bucket when report enters terminal state.

---

## Moderation Tiers

### Tier 1: Automated (target: handle 70% of reports)

| Signal | Action |
|--------|--------|
| Face/plate detected but not blurred | Hold for human review |
| Duplicate report (proximity + category + time) | Auto-merge with existing report |
| New user, no scan history | Hold for human review |
| Known spam keyword in description | Auto-reject |
| Photo contains adult/violent content (on-device NSFW classifier) | Flag for urgent review |

### Tier 2: Community (target: handle 25% of reports)

Trusted-tier users can:
- Confirm reports as genuine ("I saw this too")
- Flag reports as inaccurate ("This has been resolved")
- Verify photos as appropriate

**Community moderation does not replace human review** — it feeds the confidence formula for automated prioritization.

### Tier 3: Human Moderator (target: handle 5% of reports)

| Trigger | SLA |
|---------|-----|
| Unblurred face/plate detected | 4 hours |
| False report accusation (subject contests) | 24 hours |
| New user report (no history) | 24 hours |
| Appeal on moderator decision | 48 hours |
| Emergency (threat of harm, child safety) | 1 hour |

---

## Abuse Report Flow

**Who can submit an abuse report**:
- Subject of the report (person/location featured)
- Any user who sees the report on the map
- Automated detection systems

**Abuse report submission**:
1. Report has "Report this" button
2. User selects reason: "Inaccurate information" / "Contains private information" / "Harassment" / "Other"
3. Submit → creates abuse report tied to original report + user
4. Moderator dashboard shows queue sorted by severity + age

**Takedown process**:
1. Abuse report submitted → status: `Pending Review`
2. Moderator reviews within SLA (4-24h depending on severity)
3. Decision options:
   - **Approved**: Report removed from public view. Reporter reputation penalized. User notified.
   - **Denied**: Report remains. User can appeal within 7 days.
   - **Escalated**: Flagged for team lead review (ambiguous or high-stakes cases)
4. All decisions logged with moderator ID, timestamp, and rationale.

---

## Legal Risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| Defamation (report falsely accuses worker) | HIGH | All named-person reports held for review; takedown SLA <24h |
| Mapping of unsafe neighborhoods | MEDIUM | Coarse public coords only; blocklist for sensitive categories |
| Privacy violation (home interior photo) | MEDIUM | On-device blur; optional photo; "photo not required" as default |
| Reliance on unofficial data causing harm | LOW | Terms of Service + in-app disclaimers |
| Child safety (photo of minor) | HIGH | On-device face detection flags minors; immediate moderator review |
| Data protection law violation (DPDP Act) | MEDIUM | Consent ledger + retention limits + deletion drills |

---

## Implementation Order

1. **Phase 0** (pre-pilot, 2 weeks):
   - EXIF stripping on upload
   - On-device face detection + blur (platform-native)
   - Coarse-public coordinate model
   - Photo retention policy (Firestore TTL + cleanup function)

2. **Phase 1** (pilot launch, +1 week):
   - Abuse report flow
   - Moderator dashboard (basic — review queue + accept/reject)
   - Terms of Service update

3. **Phase 2** (scaling, +2 weeks):
   - License plate detection + blur
   - Moderation tiers (automated + community + human)
   - Takedown SLA enforcement (alerting + escalation)

4. **Phase 3** (automation, +4 weeks):
   - NSFW/abuse auto-detection
   - Reputation-weighted report visibility
   - Bulk operations for moderator dashboard

---

## Open Questions

- Can on-device face detection achieve acceptable recall on Indian skin tones with current ML Kit models?
- What is the false positive rate for license plate detection on Indian plates (different font, color schemes, placement)?
- Should we offer a "privacy mode" that automatically blurs all photos regardless of detection (slower but safer)?
- How do we handle reports where the reporter explicitly wants to be identified (e.g., complaint to municipality)?
- What is the legal liability for the app if a reporter uses the app to stalk or harass someone?
