# Smart-Bin / QR-Bin Integration — Exploration Doc

**Track**: L2
**Phase**: LATER — Scale + Frontier
**Status**: 🟢 Exploration
**Last Updated**: 2026-05-24
**Frontier dependency**: [F5. Smart-Bin / QR-Bin Aggregation Layer](../EXPLORATION_FRONTIER.md#f5-smart-bin--qr-bin-aggregation-layer)
**Parent**: [EXPLORATION_TOPICS.md #24](../EXPLORATION_TOPICS.md#24-smart-bin-integration--frontier)
**Sibling topics**: Municipal APIs (#25), Disposal Facilities (#D1)

---

## Decision This Unblocks

Whether to invest in a QR-based "smart-enough bin" layer that gives 80% of smart-bin value (verified disposal, location-aware guidance) at 1% of the hardware cost — and whether it earns its keep with one RWA or school.

## De-Risk Question

Can the cheapest possible "smart bin" (a printed QR code) generate enough engagement and data value to justify the build, and can non-technical admins (RWA secretaries, school coordinators) operate it?

## Kill Criteria

1. After two pilots, admins won't maintain the QR layer (codes damaged/removed/not replaced).
2. Users won't bother scanning after the novelty wears off (< 10% scan rate on repeat visits).
3. Disposal verification (scan = disposal happened) is too gameable to gate rewards credibly.

---

## What Already Exists

| Component | File/Location | Status |
|-----------|--------------|--------|
| `FamilyInvitation` with QR method | `lib/models/family_invitation.dart` | ✅ QR invitation framework |
| Family invite screen | `lib/screens/family_invite_screen.dart` | ✅ QR code display |
| Disposal facilities screen | `lib/screens/disposal_facilities_screen.dart` | ✅ Location-based facility finder |
| Disposal instructions service | `lib/services/disposal_instructions_service.dart` | ✅ Per-item guidance |
| Region-aware rulesets | `lib/services/waste_rules_engine.dart` | ✅ 7 cities covered |
| Gamification points engine | `lib/services/gamification_service.dart` | ✅ Points + achievements |
| Community feed | `lib/screens/community_screen.dart` | ✅ Social features |

**What's missing**: Bin registration, QR generation for bins, scan-to-log flow, admin dashboard, anti-cheating verification.

---

## Architecture Proposal

### 1. Bin Registration (Admin-Side)

```
Admin creates bin → generates QR → prints sticker → attaches to physical bin
```

**Data model**:
```dart
class SmartBin {
  final String id;
  final String name;          // "Block A - Blue Recycle Bin"
  final String location;      // "Near elevator, 3rd floor"
  final String organizationId; // RWA / school / corporate
  final List<String> acceptedCategories; // ["Dry Waste", "Recyclable"]
  final GeoPoint? location;
  final String qrCodeId;      // links to QR code
  final DateTime registeredAt;
  final String registeredBy;
}
```

**Admin surface**: Minimal web dashboard or in-app admin mode. Key operations:
- Register bin (name, location, accepted categories)
- Generate + download QR (printable on any printer)
- View scan analytics (disposal volume, time distribution)
- Disable/replace damaged QR codes

### 2. Scan-to-Log Flow (User-Side)

```
User classifies item → gets disposal instructions → "Find a bin" → scans QR → logs disposal
```

**User flow**:
1. After classification, user sees disposal instructions.
2. "Find a bin nearby" CTA shows bins registered near them (or all bins for their building/RWA).
3. User goes to bin, scans QR.
4. App confirms bin accepts that waste category. If mismatch → warning ("This bin accepts Dry Waste only").
5. Disposal logged: timestamp, bin ID, classification ID, user ID.
6. Points awarded for verified disposal (higher points than unverified).

### 3. Anti-Cheating

The biggest trust question. Strategies (layered):

| Strategy | Effectiveness | Cost |
|----------|--------------|------|
| GPS proximity check | Medium | Low |
| Time-between-scans minimum (30s) | Low | None |
| BLE beacon on bin (Phase 2) | High | Medium (hardware) |
| Photo verification (Phase 3) | High | High (review cost) |
| Aggregate anomaly detection | Medium | Low |

**V1 recommendation**: GPS proximity check only. Accept that some gaming exists; optimize for engagement, not airtight verification. Add BLE beacons in Phase 2 for high-value bins (school competitions, corporate challenges).

### 4. Reward Gating

```dart
// Points tiers
enum DisposalVerification { unverified, qrScanned, photoVerified }

int pointsForDisposal(DisposalVerification verification) {
  switch (verification) {
    case DisposalVerification.unverified: return 1;
    case DisposalVerification.qrScanned: return 3;
    case DisposalVerification.photoVerified: return 5;
  }
}
```

### 5. Data Model (Firestore)

```
smart_bins/{binId}
  ├── id, name, location, organizationId
  ├── acceptedCategories, qrCodeId
  └── registeredAt, registeredBy

disposal_logs/{logId}
  ├── userId, binId, classificationId
  ├── category, timestamp
  ├── gpsVerified, verificationMethod
  └── pointsAwarded

organizations/{orgId}
  ├── name, type (rwa/school/corporate)
  ├── adminUserIds
  ├── binIds[]
  └── memberUserIds
```

---

## Pilot Plan

### Pilot 1: RWA / Apartment Complex

- **Target**: 1 apartment complex, 5–10 bins, 20–50 users
- **Duration**: 4 weeks
- **Success criteria**:
  - > 50% of registered users scan at least once in week 2
  - Admin can replace a QR code without developer help
  - Scan-to-disposal correlation > 60% (users classify → then scan)
- **Failure criteria**: < 20% repeat usage after week 1

### Pilot 2: School

- **Target**: 1 school, 4 bins (one per waste category), 2 classrooms
- **Duration**: 3 weeks
- **Success criteria**:
  - Teacher can manage bins from admin surface
  - Inter-classroom competition drives > 70% participation
- **Failure criteria**: Teacher abandons after first week

---

## Concrete Next Steps

1. **Firestore schema** — Add `smart_bins`, `disposal_logs`, `organizations` collections.
2. **QR generation** — Use `qr_flutter` package. QR payload: `reloop://bin/{binId}`.
3. **Deep link handler** — Register `reloop://bin/` scheme, handle incoming scans.
4. **Admin MVP** — In-app "Manage Bins" screen (register, generate QR, view stats).
5. **Scan flow** — Camera scan → parse bin ID → verify category → log disposal → award points.
6. **Pilot** — Recruit one RWA, run 4-week pilot, measure engagement.

## Open Questions

- **QR durability**: What's the cheapest weather-resistant QR sticker? (Laminate + outdoor adhesive ≈ ₹5/qr.)
- **Offline scanning**: Can we cache bin metadata locally so scan works without connectivity?
- **Privacy**: "User X disposed at bin Y at time T" — retention policy, access controls?
- **Competitive landscape**: Has any Indian waste app tried QR bins? (Swachhata app does complaint-based, not verification-based.)

## Downstream Artefacts

- `lib/models/smart_bin.dart` — bin data model
- `lib/services/smart_bin_service.dart` — registration + scan logging
- `lib/screens/smart_bin_admin_screen.dart` — admin surface
- `lib/screens/bin_scan_screen.dart` — user scan flow
- `docs/exploration/SMART_BIN_PILOT_RESULTS.md` — pilot report
