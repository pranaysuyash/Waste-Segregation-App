# B2B / School Wedge — Exploration Doc

**Track**: L3
**Phase**: LATER — Scale + Frontier
**Status**: 🟢 Exploration
**Last Updated**: 2026-05-24
**Frontier dependency**: [F10. Education-First White-Label for Schools](../EXPLORATION_FRONTIER.md#f10-education-first-white-label-for-schools)
**Parent**: [EXPLORATION_TOPICS.md #29](../EXPLORATION_TOPICS.md#29-b2b--enterprise-wedge-)
**Sibling topics**: Persona Journeys (#15), Carbon / Impact Accounting (#30), Smart-Bin (#24)

---

## Decision This Unblocks

Which B2B segment (school, RWA, corporate ESG, hospitality) to target first, and what's the minimum admin surface that earns the deal — enabling a revenue path that doesn't depend on consumer app monetization alone.

## De-Risk Question

Which segment is the cleanest first wedge, and can a pilot validate that the organization's admin will actually use it beyond a one-week novelty period?

## Kill Criteria

1. Two pilots in any segment show admins don't sustain usage beyond novelty.
2. The admin surface required to earn the deal is so complex it needs a dedicated support team.
3. Privacy/consent posture for organizational use (employer knows employee's waste) is legally untenable.

---

## Segment Analysis

### S1. Schools (Recommended First Wedge)

**Why first**:
- **Distribution multiplier**: 1 teacher → 30 kids → 30 families. Word-of-mouth built into the structure.
- **Mission-aligned**: Waste education IS the curriculum hook. Teachers are already motivated.
- **Low admin bar**: Teacher creates classroom → shares code → kids join. That's it for MVP.
- **Competition gap**: No waste education app has cracked the school distribution in India.
- **Gamification-ready**: Inter-classroom competitions, leaderboards, school-wide challenges are native to the domain.

**Minimum admin surface**:
- Create/manage classroom(s)
- View aggregate classroom stats (scans, accuracy, categories breakdown)
- Reset/graduate students between academic years
- Export report for school administration

**Revenue model**:
- Free for up to 2 classrooms
- Paid per-school: ₹5,000–15,000/year for unlimited classrooms + analytics + curriculum alignment
- District/municipality deals at scale

**Pilot plan**:
- 2 schools, 2 teachers each, 3 weeks
- Success: teacher uses it ≥ 2x/week in week 3; > 60% of students classify ≥ 5 items/week

### S2. Apartments / RWAs

**Why second**:
- **Physical anchor**: Waste segregation bins are already in every apartment. The QR-bin layer (L2) is the natural bridge.
- **Decision-maker**: RWA secretary is the buyer. Low budget, high visibility pressure.
- **Community dynamics**: Inter-building competitions, "cleanest society" awards.

**Minimum admin surface**:
- Register society + buildings
- Manage smart bins (see L2)
- View aggregate society stats
- Broadcast waste-related announcements

**Revenue model**:
- Free for < 50 units
- ₹2,000–5,000/year per society for analytics + smart-bin integration

### S3. Corporate ESG

**Why later**:
- **Budget**: Real budgets exist for sustainability programs.
- **Complexity**: Needs SSO integration, privacy audits, compliance reporting, HR system hooks.
- **Sales cycle**: 3–6 months minimum.
- **Competition**: Established players (JLL, CBRE) offer waste audit services.

**Minimum admin surface**: Admin dashboard + SSO + compliance export.
**Revenue model**: ₹50,000–2,00,000/year per campus.

### S4. Hospitality / Food Service

**Why later**:
- **Strong use case**: Bulk food waste, packaging classification, grease contamination.
- **Operational nature**: Staff, not guests, are the users. Different UX entirely.
- **Revenue**: Per-location subscription.

---

## School Wedge Architecture

### Data Model

```dart
class Organization {
  final String id;
  final String name;
  final OrgType type; // school, rwa, corporate, hospitality
  final String adminUserId;
  final List<String> memberUserIds;
  final Map<String, dynamic> metadata; // type-specific fields
}

class Classroom {
  final String id;
  final String organizationId;
  final String teacherUserId;
  final String name; // "7A - Science"
  final String joinCode; // "RELOOP-7A-SCI"
  final List<String> studentUserIds;
  final int academicYear;
}

enum OrgType { school, rwa, corporate, hospitality }
```

### Firestore Schema

```
organizations/{orgId}
  ├── name, type, adminUserId
  ├── memberUserIds[]
  ├── settings (notification preferences, privacy)
  └── subscription (tier, status, expiresAt)

classrooms/{classroomId}
  ├── organizationId, teacherUserId
  ├── name, joinCode, academicYear
  ├── studentUserIds[]
  └── stats (aggregate scans, accuracy, streak)

organization_stats/{orgId}/daily/{date}
  ├── totalScans, correctDisposals
  ├── categoryBreakdown: Map<String, int>
  └── activeUsers
```

### Admin Surface (MVP)

**Screen 1: Dashboard**
- Total scans this week/month
- Accuracy rate
- Top categories
- Active users chart

**Screen 2: Classrooms**
- List of classrooms with teacher name + student count
- Aggregate stats per classroom
- Create/edit/delete classroom

**Screen 3: Students**
- Student list with individual stats
- Flag inactive students
- Remove/transfer students

**Screen 4: Challenges**
- Create inter-classroom challenge
- Set target (scans, accuracy, specific categories)
- View leaderboard

### User Flow

1. Teacher downloads app → registers as "Teacher" role.
2. Creates organization (school) → creates classroom → gets join code.
3. Shares join code with students.
4. Students download app → enter join code → linked to classroom.
5. Students classify normally. App links classifications to classroom.
6. Teacher sees aggregate stats in admin surface.
7. Gamification: classroom leaderboards, inter-classroom challenges.

### Privacy Guardrails

- Teacher sees **aggregate** stats only — not individual student classifications.
- Students' personal history is private (same as consumer app).
- No photo data shared with organization (metadata only: category, timestamp, confidence).
- Parent consent required for students under 13 (COPPA-equivalent for India).
- Organization data retention: delete after academic year unless explicitly retained.

---

## Concrete Next Steps

1. **Role extension** — Add `teacher`, `orgAdmin` roles to `UserProfile` (already has `UserRole.child`).
2. **Firestore schema** — `organizations`, `classrooms` collections with security rules.
3. **Join code flow** — Generate unique join codes, validate on entry, link user to classroom.
4. **Admin dashboard MVP** — In-app organization/classroom management screen.
5. **Aggregate stats** — Cloud Function that computes daily/weekly organization stats from individual classifications.
6. **Pilot recruitment** — Find 2 Bangalore schools willing to pilot for 3 weeks.

## Open Questions

- **COPPA / Indian equivalent**: What are the actual consent requirements for under-13 users in Indian schools?
- **Content moderation**: Kid-safe community feed — does the existing `ModerationService` suffice, or do we need stricter filters for school surfaces?
- **Teacher training**: What onboarding do teachers need? Is a 5-minute video sufficient?
- **Offline in schools**: Many Indian schools have poor connectivity. Does the offline queue handle a classroom of 30 simultaneous users?

## Downstream Artefacts

- `lib/models/organization.dart` — org data model
- `lib/models/classroom.dart` — classroom data model
- `lib/services/organization_service.dart` — CRUD + stats
- `lib/screens/organization_admin_screen.dart` — admin dashboard
- `lib/screens/classroom_join_screen.dart` — student join flow
- `docs/exploration/SCHOOL_WEDGE_PILOT_RESULTS.md` — pilot report
