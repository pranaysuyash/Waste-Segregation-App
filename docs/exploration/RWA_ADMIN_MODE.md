# Apartment / RWA Admin Mode

**Status**: Draft — no code surface for RWA mode exists yet.
**Priority**: P2 (pilot-ready after core classification + local rules mature)
**Related**: [CIVIC_B2B_B2G_VALIDATION.md](CIVIC_B2B_B2G_VALIDATION.md), [CIVIC_AUTHORITY_SHARING.md](CIVIC_AUTHORITY_SHARING.md), [LOCALITY_COLLECTION_DATA.md](LOCALITY_COLLECTION_DATA.md), [HOUSEHOLD_ROLES_AND_PERMISSIONS.md](HOUSEHOLD_ROLES_AND_PERMISSIONS.md)
**Last Updated**: 2026-05-25

---

## Why This Is a Topic

Apartment complexes and Residential Welfare Associations (RWAs) in India are a natural unit for waste management:

1. **Bulk waste** — apartment buildings generate significant volumes of mixed waste. Segregation at source is often mandated but poorly enforced.
2. **Shared infrastructure** — common bins, centralized composting, e-waste collection drives.
3. **Collective action** — RWAs can set building-level rules that override city defaults.
4. **B2B revenue** — RWAs have budgets for waste management services and compliance.

However, RWA waste management is complex: different building layouts, varying municipal compliance requirements, mixed resident engagement levels, and the need for non-technical admin interfaces.

---

## RWA Mode: Core Concepts

### What Makes RWA Different

| Aspect | Individual Mode | RWA Mode |
|--------|----------------|----------|
| User | Single person | Admin for a complex of 50–500+ families |
| Rules | City-level defaults | Building-level overrides + city defaults |
| Impact | Personal diversion | Building-level diversion, per-wing comparison |
| Moderation | None | Report issues, manage waste vendor |
| Data | Private | Aggregated building data, anonymized |
| Goals | Personal streaks | Building challenges, inter-wing competitions |

### Admin Persona

The RWA admin is typically a non-technical volunteer (retired resident, part-time secretary, or facility manager). The interface must work in Hindi and English, on mid-range Android phones, with minimal training.

---

## Feature Surface

### Phase 1: Read-Only Dashboard

| Feature | Description |
|---------|-------------|
| **Building overview** | Total families enrolled, total items classified, diversion estimate |
| **Wing/floor breakdown** | Participation rate per wing, top material by wing |
| **Collection schedule** | View current municipal pickup schedule, disruption alerts |
| **Reports** | Monthly PDF — waste audit, participation rate, diversion trends |

### Phase 2: Active Management

| Feature | Description |
|---------|-------------|
| **Society rule overrides** | Edit building-specific disposal rules (e.g., "compostable liners accepted here", "e-waste collection every Saturday") |
| **Announcements** | Post verified announcements to residents (e-waste drive, schedule change, compost workshop) |
| **Issue ticketing** | Residents report overflowing bins, missed pickups → admin sees, routes to vendor |
| **Wing challenges** | Create inter-wing competition (e.g., "Wing with best segregation wins flower budget for Diwali") |
| **Compliance reports** | Auto-generated reports for municipal compliance (BBMP, BMC) showing segregation rates, waste volume |

### Phase 3: Vendor & Logistics Integration

| Feature | Description |
|---------|-------------|
| **Vendor directory** | Rated list of waste vendors, kabadiwalas, e-waste recyclers serving the area |
| **Pickup scheduling** | Coordinate bulk waste pickups (e-waste, bulk reject, green waste) |
| **Proof-of-pickup** | Vendor marks pickup complete, admin confirms. Photo evidence. |
| **Weight tracking** | Track monthly waste output by bin type (wet, dry, reject, e-waste) |

---

## Society Rule Override Model

RWAs need to override city-level disposal rules with building-specific ones. The existing `SocietyPolicyOverride` model (from [REGION_RULES_AND_CITY_EXPANSION_MAP.md](REGION_RULES_AND_CITY_EXPANSION_MAP.md) and `lib/models/society_policy_override.dart`) already provides the framework.

### Override Types

| Override | Example | Priority |
|----------|---------|----------|
| **Acceptance** | "This building DOES accept #6 polystyrene" | Overrides city default |
| **Rejection** | "This building DOES NOT accept glass" | More restrictive than city |
| **Exception** | "Batteries accepted only on 1st Saturday" | Time/event-gated |
| **Location** | "E-waste goes to bin B-3, not the ground floor bin" | Directs user to different facility |

### Override Lifecycle

1. Admin proposes override via RWA settings.
2. Override goes into "pending review" — optionally verified by a waste expert or the app team.
3. Once approved, it becomes active for all building residents.
4. Override is auto-expired after 1 year (or earlier if admin updates city rules version).
5. Override changes are logged and visible to residents in the classification result.

---

## Verification & Trust

RWA data must be trustworthy for compliance and decision-making:

- **Classification data**: aggregated from individual resident scans. Anonymized — no per-resident detail shown to admin.
- **Participation rate**: % of building residents who have classified 1+ item in the last 30 days.
- **Diversion estimate**: kg of material correctly sorted vs kg sent to landfill. Calculated from classification history + bin weigh-ins (if available).
- **Accuracy proxy**: correction rate tracked but not exposed — admin sees only positive metrics.

---

## Language and Accessibility

- RWA interface must be available in Hindi, Kannada, and English for Indian market.
- Admin reports should be printable PDFs usable in monthly RWA meetings.
- Simple, icon-supported navigation. No jargon. ("Paper to dry bin" not "cellulosic fraction to organic waste stream".)

---

## Pilot Hypothesis

### Shortest Path to Paid Pilot (from [CIVIC_B2B_B2G_VALIDATION.md](CIVIC_B2B_B2G_VALIDATION.md))

1. **Pilot buyer**: RWA secretary of a 200+ apartment complex in Bengaluru (BBMP area).
2. **Value prop**: "Know your building's waste baseline, improve segregation, avoid municipal fines, get compliance reports."
3. **Sales cycle**: 1–2 meetings, no procurement department. Small annual fee (₹5k–₹15k/year per building).
4. **Free-to-paid**: Free tier = read-only dashboard + society rule overrides. Paid = reports export, vendor management, weight tracking.

---

## Open Questions

1. **Who enrolls the building?** Admin self-service (app-based) or requires app team setup (higher trust)?
2. **Data accuracy**: is resident self-reporting via scans accurate enough for building-level compliance reports? Or does the building need physical bin weigh-ins?
3. **Resident privacy**: admin should not see individual resident scan history. How to enforce this technically while still allowing per-wing aggregation?
4. **Moderation**: what if an admin sets harmful override rules (e.g., "all plastics go to reject bin")? Is there a review gate?

---

## Related Work

- [CIVIC_B2B_B2G_VALIDATION.md](CIVIC_B2B_B2G_VALIDATION.md) — buyer matrix and pilot validation
- [CIVIC_AUTHORITY_SHARING.md](CIVIC_AUTHORITY_SHARING.md) — data sharing with authorities
- [LOCALITY_COLLECTION_DATA.md](LOCALITY_COLLECTION_DATA.md) — collection schedules for the building
- [HOUSEHOLD_ROLES_AND_PERMISSIONS.md](HOUSEHOLD_ROLES_AND_PERMISSIONS.md) — per-resident role within the building
- [REGION_RULES_AND_CITY_EXPANSION_MAP.md](REGION_RULES_AND_CITY_EXPANSION_MAP.md) — city-level rules that society overrides sit above
