# Region Rules & City Expansion Map

**Decision this unblocks**: City expansion order, plugin contract prototyping, and minimum data schema for adding a new Indian city without app branching.

**Key questions**:
- What is the minimum data contract a city must provide before its plugin ships?
- How do we resolve conflicts when municipal, state, and society rules disagree?
- Which city-order maximises real-user impact vs research cost?
- How do we surface rule provenance to users without overwhelming them?

**Kill criteria**:
- Too few Indian cities publish machine-readable waste rules → crowdcore sourcing cost outweighs benefit.
- All metros converge on identical SWM rules → city plugin abstraction is over-engineering.
- A national SWM framework harmonises rules before we ship → shift to state-level plugins.

**Status**: Active Research (2026-05-22)
**Links**: EXPLORATION_TOPICS.md#4 (Region-Aware Rulesets), EXPLORATION_TOPICS.md#4a (Global Municipal Policy Engine), EXPLORATION_TOPICS.md#F (Locality & Civic Waste Intelligence), GLOBAL_MUNICIPAL_POLICY_ENGINE.md

---

## 1. Why Local Rules Must Be Deterministic Policy, Not Only Prompt Text

The app's classification pipeline has two stages:
1. **ML classification** (`AiService` / `UnifiedApiClient`) — identifies the item and its category. Non-deterministic by nature (model may change, prompt may drift, provider swap may shift output).
2. **Disposal resolution** — converts "this is an empty paint can" into "put it in the red bin on the 1st Saturday of the month, take it to the ward collection point."

Today disposal instructions are generated in the same AI prompt as classification. This is the problem.

### Why deterministic policy is required

| Concern | Prompt-text approach | Deterministic policy approach |
|---------|---------------------|-------------------------------|
| **Reproducibility** | Same photo → different answer with model update | Same photo → same answer (rule lookup, not model inference) |
| **Safety-critical rules** | Hazardous/medical rules embedded in a prompt that can be edited without review | Hazardous rules versioned, code-reviewed, tested, signed |
| **Audit trail** | "Which prompt version caused this advice?" requires prompt diffing | `rulePackId + guidelineVersion` stamped on every decision |
| **Local override** | Society rules must be re-prompted with every classification | Society rules loaded once, applied as override layer |
| **Offline availability** | Requires cloud AI call for every classification | Policy pack cached locally in Hive; offline-capable by design |
| **Liability** | "The AI told me to put batteries in the wet bin" is hard to defend | "The Bangalore BBMP v2024.1 rule pack requires batteries → hazardous disposal" is auditable |
| **Testing** | Prompt changes tested via eval harness (expensive, slow) | Rule changes tested via unit tests (instant, deterministic) |

### Architecture principle

```
ML Classification (non-deterministic)
  │
  ▼
Category + Item Name + Visual Features
  │
  ▼
Policy Engine (deterministic)
  ├── City plugin selected by region
  ├── Rule pack loaded (versioned)
  ├── Society override applied if available
  └── Compliance evaluated
  │
  ▼
Disposal Instruction (deterministic, auditable)
```

The ML stage answers "what is this?". The policy stage answers "what should I do with it here?".

The policy stage must be deterministic because the answer to "what should I do" carries more safety and compliance weight than "what is this."

---

## 2. Plugin Architecture for Cities

### Current state

`lib/services/local_guidelines_plugin.dart` defines an abstract `LocalGuidelinesPlugin` with 8 methods. Three implementations exist:

| Plugin | City | Stage | Rules | Rule-pack tests |
|--------|------|-------|-------|-----------------|
| `BBMPBangalorePlugin` | Bengaluru | `production` | 4 rules | Yes |
| `BMCMumbaiPlugin` | Mumbai | `pilot` | 3 rules | `local_policy_engine_test.dart` |
| `MCDDelhiPlugin` | Delhi | `pilot` | 3 rules | `local_policy_engine_test.dart` |

### Proposed plugin contract (expansion-ready)

```
┌──────────────────────────────────────────────┐
│                 City Plugin                    │
├──────────────────────────────────────────────┤
│ pluginId: String                              │
│ authorityName: String                         │
│ region: String (human-readable)               │
│ guidelinesVersion: semver                     │
│ governanceStage: draft|pilot|production       │
├──────────────────────────────────────────────┤
│ + applyLocalGuidelines(classification)        │
│ + validateCompliance(classification)           │
│ + getDisposalOverrides(category, subcategory)  │
│ + getColorCoding(): Map<category, binColor>    │
│ + getCollectionSchedule(): Schedule            │
│ + getRegulations(category): Regulations        │
│ + getSubcategoryOverrides(): Map               │
│ + getSpecialPrograms(): SpecialProgram[]       │
│ + getSourceAttribution(): ProvenanceCard       │
└──────────────────────────────────────────────┘
```

### Registration pattern

```dart
// Already established in LocalGuidelinesManager
LocalGuidelinesManager.registerPlugin(PunePMCPlugin());
LocalGuidelinesManager.registerPlugin(GHMCWardPlugin());  // Hyderabad
// ...
```

The manager resolves region aliases to plugin IDs (`"bengaluru"` → `"bbmp_bangalore"`). City aliases are additive.

### What should be data-driven vs code-driven

| Concern | Data-driven (rule-pack registry) | Code-driven (plugin class) |
|---------|----------------------------------|---------------------------|
| Category-to-bin colour mapping | ✅ Yes — JSON/map | ❌ |
| Collection schedule | ✅ Yes — structured data | ❌ |
| Disposal instructions per category | ✅ Yes — string table | ❌ |
| Subcategory overrides | ✅ Yes — map | ❌ |
| Helpline / contact info | ✅ Yes — simple KV | ❌ |
| Compliance check rules | Partial — rule pack pattern exists | Complex multi-field validation may need code |
| Points modifiers | ❌ | ✅ Plugin method (game design varies by city) |
| Compound compliance logic | ❌ | ✅ Plugin method (e.g. "wet waste from apartment with composter") |

### What a city plugin looks like when most logic is data-driven

```dart
class PunePMCPlugin extends LocalGuidelinesPlugin {
  @override String get pluginId => 'pmc_pune';
  @override String get authorityName => 'Pune Municipal Corporation';
  @override String get region => 'Pune, IN';
  @override String get guidelinesVersion => 'PMC-2025.1';

  static final _data = CityPolicyData(
    colorCoding: { 'wet': 'Green', 'dry': 'Blue', 'hazardous': 'Red' },
    collectionSchedule: { ... },
    disposalInstructions: { ... },
    subcategoryOverrides: { 'e_waste': { ... } },
    contactInfo: { 'helpline': '1800-...' },
    regulations: { ... },
    rulePack: [ /* LocalPolicyRule entries */ ],
    source: PolicySource(
      authority: 'PMC Solid Waste Management Department',
      url: 'https://pmc.gov.in/swm',
      lastVerified: '2025-03-15',
      nextReviewDue: '2026-03-15',
    ),
  );

  @override applyLocalGuidelines(...) => _data.applyDefaults(this, ...);
  @override validateCompliance(...) => _data.defaultCompliance(this, ...);
  // ... other methods delegate to _data, override only for city-specific logic
}
```

A `CityPolicyData` helper class can provide fallback implementations so that adding a city starts at 80% completeness with just a JSON-like data structure.

---

## 3. Minimum Data Needed per City

Every city plugin must provide these fields. A plugin may **not** ship to `pilot` without all required fields complete.

### Required (blocking)

| Field | Type | Example | Source |
|-------|------|---------|--------|
| `pluginId` | `String` | `ghmc_hyderabad` | Internal convention |
| `authorityName` | `String` | `Greater Hyderabad Municipal Corporation` | Official name |
| `region` | `String` | `Hyderabad, IN` | City + country |
| `guidelinesVersion` | `semver` | `GHMC-2025.1` | Source document date |
| `governanceStage` | `draft\|pilot\|production` | `pilot` | Internal |
| `colorCoding` | `Map<String, BinColor>` | wet → green, dry → blue | Municipal SWM by-law |
| `disposalInstructions` | `Map<String, DisposalDirective>` | wet → "compost or green bin" | Municipal guideline |
| `collectionSchedule` | `Map<String, Schedule>` | wet → daily 7-9am | Ward-level data |
| `contactInfo` | `Map<String, String>` | helpline, website | Official sources |
| `rulePack` | `List<LocalPolicyRule>` | see rule pack schema below | Derived from regulations |
| `source` | `PolicySource` | authority URL, last verified | Provenance |

### Strongly recommended (non-blocking for pilot)

| Field | Type | Why |
|-------|------|-----|
| `subcategoryOverrides` | `Map<String, Override>` | E-waste, batteries, CFL bulbs often have special rules |
| `specialPrograms` | `List<Program>` | Deposit schemes, exchange programs, drop-off events |
| `penaltyInfo` | `Map<String, String>` | "Non-compliance fine: Rs 100-500" — behaviour driver |
| `wardZones` | `Map<String, Ward>` | Collection days may differ by ward within the same city |
| `localAliases` | `Map<String, List<String>>` | "dustbin", "kabada", "kuppa" — local terminology |
| `societyCompostRule` | `bool` | Whether apartments above N units must compost on-site |

### Rule pack schema (per city)

```dart
// Each rule in the pack must declare:
{
  ruleId: 'ghmc_hazardous_special_disposal',
  categoryKey: 'hazardous_waste',
  severity: 'violation' | 'warning',
  checkType: 'requiresSpecialDisposalTrue' | 'hasUrgentTimeframeTrue'
            | 'isCompostableTrue' | 'isRecyclableTrue'
            | 'visualFeatureMustNotContain',
  message: 'Hazardous waste requires special disposal in Hyderabad.',
  targetValue: 'plastic', // only for visualFeatureMustNotContain
}
```

Minimum viable rules per city: at least one rule per category the city enforces (typically wet, dry, hazardous, medical). Pilot stage requires ≥2 rules. Production requires ≥4 covering at least 3 categories.

---

## 4. Rule Versioning

### Version scheme

`<AUTHORITY_CODE>-<YEAR>.<RELEASE_NUMBER>`

Examples: `BBMP-2024.1`, `BBMP-2025.1`, `PMC-2025.1`, `GHMC-2025.1`

- First release of a year gets `.1`
- Mid-year amendments get `.2`, `.3` (not patch bumps — mid-year changes may be substantive)
- Patch-level fixes (typos, broken links, formatting) use no version change; only substantive rule changes bump the release number

### Where version lives

| Layer | Version carried | How it's set |
|-------|----------------|--------------|
| Plugin class | `guidelinesVersion` field | Hardcoded in plugin |
| Rule pack registry | `rulePackId = "$pluginId:$guidelinesVersion"` | Built from plugin |
| Policy decision | `guidelinesVersion` on `LocalPolicyDecision` | Stamped by engine |
| User-facing UI | `"BBMP 2024 guidelines"` | Extracted from decision |
| Analytics event | `policy_version` dimension | Telemetry attribute |
| Firestore | `classification.policyMetadata.version` | Written on save |

### Release workflow

```
Draft ──(author)──▶ Pilot ──(review)──▶ Production
  │                    │                     │
  │ v1.0.0-draft       │ v1.0.0-pilot       │ v1.0.0
  ▼                    ▼                     ▼
Internal testing    Limited cohort        Full traffic

Rollback: switch to previous stable pack, emit telemetry event.
```

### Detection of stale rules

- Every `PolicySource` carries `nextReviewDue` date.
- If current date > `nextReviewDue`, the engine logs a warning and the UI shows "These rules were last reviewed on {date}. Official guidelines may have changed."
- Rules beyond 18 months without re-verification are demoted to `draft` automatically (safety default).

---

## 5. Conflict Handling

### Conflict types

| Type | Example | Resolution |
|------|---------|------------|
| **Municipal vs State** | State says "ban single-use plastic" but city has no enforcement mechanism | State-level rules take precedence for prohibitions; city rules for collection mechanics |
| **Society vs Municipal** | Society mandates on-site composting; city collects wet waste daily | Society rule wins (more specific); surface both in the decision with attribution |
| **Ward vs City-wide** | Ward 12 has Saturday dry collection; city schedule says Wednesday | Ward-level wins (more specific); warn if user is near boundary |
| **Cross-jurisdiction** | User lives in Bangalore but works in Delhi; scans in both locations | Per-scan region detected from GPS; separate decisions per scan |
| **Outdated vs Current** | User has cached BBMP-2023 rules; latest is BBMP-2025.1 | Stale rules demoted to `warning` severity; prompt update |

### Conflict resolution policy

```
Priority order (highest wins):
  1. Society / building-level override (if user has registered their society)
  2. Ward / zone-specific rule (if user GPS maps to a known ward)
  3. Municipal rule (city authority)
  4. State-level framework (if no municipal rule exists)
  5. National guideline (fallback — generic "best practice")
```

### Society overrides

Apartment societies often have stricter or different rules than the municipal standard (e.g., on-site composting mandate, specific collection windows, banned items in common chute). These are represented as a **delta layer**:

```dart
class SocietyPolicyOverride {
  final String societyId;
  final String societyName;
  final String basePluginId;       // e.g. 'bbmp_bangalore'
  final List<RuleOverride> overrides;
  final String verifiedBy;         // Admin, RWA member, or self-registered
  final DateTime verifiedAt;
}
```

The engine applies the base city plugin first, then overlays society overrides on top. Conflicts are flagged in the decision's `warnings` list.

### User-facing conflict display

> "Your society (Green Acres) requires all wet waste to be composted on-site.
> BBMP offers daily wet waste collection, but your society rule takes priority.
> [Learn why]"

---

## 6. Source Credibility

### Trust tiers for rule sources

| Tier | Label | Who can submit | Verification | UI treatment |
|------|-------|---------------|--------------|--------------|
| T0 | **Authoritative** | Municipal corporation official | Gazette notification / official PDF linked | Badge: "Official BBMP rule" |
| T1 | **Partner-verified** | Verified RWA, verified NGO | Partnership agreement, cross-checked | Badge: "Verified by {partner}" |
| T2 | **Community-sourced** | Any authenticated user | N votes from same ward within 30 days | Badge: "Reported by neighbours" |
| T3 | **AI-extracted** | Automated scraper | Cross-referenced with ≥2 sources | Badge: "Sourced from public data" |

### What ships for P0/P1

- **T0 only** for `production` stage plugins. Every `production` rule must have a linked source URL.
- **T2** accepted for `pilot` stage (allows community-driven data in cities we haven't formally researched yet).
- **T1** used for society/building overrides — the society admin or RWA secretary is a verifiable local authority.
- **T3** used only for `draft` stage; promoted only after human review confirms ≥1 T0/T1 source.

### Source attribution format in policy decisions

```dart
class PolicySource {
  final String authorityName;
  final String? url;
  final String? documentTitle;
  final String trustTier;
  final DateTime lastVerified;
  final DateTime nextReviewDue;
  final String? verifiedBy;
}
```

This is stamped into `LocalPolicyDecision` so every user-facing rule citation can include "Source: BBMP SWM By-law 2024 (last verified 2025-01-15)".

---

## 7. User-Facing Wording

### Principles

1. **Attribution without overload**: Show the authority name, not the plugin ID or version string. `"BBMP guidelines"` not `"bbmp_bangalore:BBMP-2024.1"`.
2. **Source on demand**: A tap-able "Why this?" badge on the disposal instruction expands the provenance card.
3. **Confidence in uncertainty**: When a rule is T2 or staleness-detected, preface with "This may have changed — check with your local collection."
4. **Society rules shown as personalisation**: "Your society has set a custom rule for wet waste." (Makes the user feel in control, not restricted.)

### Key UI copy patterns

| Situation | Wording |
|-----------|---------|
| Default — city rule | "As per BBMP guidelines: place in Green Bin." |
| With society override | "Your society (Green Acres) requires on-site composting. BBMP also accepts wet waste in Green Bins for daily collection." |
| T2 community-sourced | "Based on reports from your area: wet waste is collected Tue/Thu/Sat. Verify with your collector." |
| Stale rules (past review date) | "This guideline was last verified in March 2024. Official rules may have changed." |
| No plugin for city | "We don't have specific rules yet for your city. Follow general best practices for {category}." |
| Cross-border ambiguity | "Your location is near a ward boundary. Collection days may vary." |
| Hazardous rule with high confidence | "BBMP regulation (violation if not followed): Hazardous waste requires special collection. Call BBMP helpline 1800-425-1442." |

### Copy language

- All rule text should be localised via `l10n/` using the same ARB files as the rest of the app.
- City-specific content (authority names, helplines) is in the data layer, not in ARB files — data is language-independent; the template that renders it is in ARB.
- Regional language support (Kannada for Bangalore, Marathi for Mumbai, Telugu for Hyderabad, Tamil for Chennai, Bengali for Kolkata, Hindi for Delhi) means the `CityPolicyData` must include a `localName` field for each authority.

---

## 8. How Local Policy Interacts with ML Classification

### Pipeline

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────────┐
│   User captures │────▶│  ML Classifier    │────▶│   Local Policy      │
│   photo         │     │  (cloud or on-dev)│     │   Engine            │
└─────────────────┘     └──────────────────┘     └──────────┬──────────┘
                   Category + Item + Features               │
                                                             │
                                                             ▼
                                                  ┌─────────────────────┐
                                                  │  Policy Decision    │
                                                  │  - compliance check │
                                                  │  - colour coding    │
                                                  │  - disposal steps   │
                                                  │  - warnings         │
                                                  └──────────┬──────────┘
                                                             │
                                                             ▼
                                                  ┌─────────────────────┐
                                                  │  User-facing Result │
                                                  │  Screen             │
                                                  └─────────────────────┘
```

### Where policy can override ML

| ML output | Policy override | Example |
|-----------|----------------|---------|
| `category: "wet waste"` | Marked `violation` if visualFeatures contains "plastic" | "This has plastic packaging — remove it before wet disposal." (BBMP rule) |
| `disposalMethod: "landfill"` | Overridden to "compost" for wet waste in Bangalore | Bangalore mandates composting; landfill is a compliance violation. |
| `recyclable: true` | Demoted to `warning` if city has no recycling facility for that polymer | "Plastic #7 is collected but not currently recycled in Pune." |
| `riskLevel: "safe"` | Escalated to `violation` for hazardous category | "Paint thinner is always hazardous — labelled safe is likely an ML error under city rules." |

### Confidence gating for ML→policy handoff

The policy engine should NOT apply strict rules when ML confidence is low, because the category itself may be wrong. A low-confidence classification should produce a **softer policy response**:

| ML confidence | Policy behaviour |
|---------------|------------------|
| ≥ 0.90 | Full policy enforcement — compliance violations shown, override actively applied |
| 0.70 – 0.89 | Full policy enforcement on *safe* categories; `warning` (not `violation`) on hazardous/medical |
| 0.50 – 0.69 | Policy applied but all `violation` severity demoted to `warning`; message: "We're not certain this is {category}. Check before disposal." |
| < 0.50 | Policy not applied; fallback to generic safe-disposal advice |

This prevents the app from issuing a strong "VIOLATION — fine Rs 500" warning when the ML probably misidentified a banana peel as a plastic wrapper.

### Feedback loop

When a user corrects the classification, the policy engine should re-evaluate:
1. The new category gets fresh policy evaluation.
2. The old policy warnings are replaced by new ones.
3. The re-evaluation is logged as an analytics event for policy false-positive/negative tracking.

---

## 9. City Expansion Map — India

### Expansion priority

```
Tier 1 — Metro core (NOW)
  ├── Bengaluru / BBMP    [production]   ✅
  ├── Mumbai / BMC        [pilot]        ✅ scaffold
  ├── Delhi / MCD         [pilot]        ✅ scaffold
  │
Tier 2 — Next metros (NEXT — 2026 Q3)
  ├── Pune / PMC
  ├── Hyderabad / GHMC
  ├── Chennai / GCC
  ├── Kolkata / KMC
  │
Tier 3 — Tier-2 cities (LATER)
  ├── Ahmedabad / AMC
  ├── Surat / SMC
  ├── Jaipur / JMC
  ├── Lucknow / LMC
  ├── Nagpur / NMC
  ├── Indore / IMC
  ├── Bhopal / BMC (Bhopal)
  ├── Coimbatore / CCMC
  ├── Kochi / Cochin Corporation
  ├── Chandigarh / MCC
  │
Tier 4 — Apartment society layer (overlay on any city)
  ├── Society-specific override pack
  ├── RWA-verified rules
  ├── Builder-provided waste management policy
```

### City research difficulty estimate

| City | Authority | Rules public? | Difficulty | Special notes |
|------|-----------|---------------|------------|---------------|
| Pune | PMC | Partially (SWM by-law 2018, updated 2022) | Medium | Strong composting mandate; pioneer in decentralised waste processing |
| Hyderabad | GHMC | Published (GHMC SWM rules, 2020) | Low | Well-documented bin colour scheme; e-waste rules explicit |
| Chennai | GCC | Published (GCC SWM by-law, 2021) | Medium | Mandatory segregation; bio-mining of legacy waste underway |
| Kolkata | KMC | Limited public documents | High | Informal sector (kabadiwala) dominant; municipal collection less structured |
| Ahmedabad | AMC | Published | Low | Segregation mandate; GPS-tracked collection vehicles |
| Surat | SMC | Published | Low | Digital tracking; citizen app already exists for complaints |
| Jaipur | JMC | Limited | Medium | Swachh Survekshan rankings improved enforcement |
| Indore | IMC | Published (model city) | Low | Consistently #1 in Swachh Survekshan; best-documented system in India |
| Lucknow | LMC | Limited | Medium | Door-to-door collection mandated but uneven |
| Nagpur | NMC | Published | Medium | Public-private partnership model; well-documented |
| Bhopal | BMC Bhopal | Published | Medium | Segregation mandate; green/dry bins |
| Coimbatore | CCMC | Published | Medium | Zero-waste initiatives; high informal recycling rate |
| Kochi | Cochin Corp | Published | Medium | Backwater-sensitive disposal rules; tourism impact |
| Chandigarh | MCC | Published (model city) | Low | Well-organised; separate wet/dry/hazardous; high compliance |

### Distance from current plugin scaffold

```dart
// Development cost estimate per city (from scaffold to pilot):
// Low effort (≤ 2 days):  Hyderabad, Pune, Ahmedabad, Indore, Chandigarh
// Medium effort (3–5 days): Chennai, Nagpur, Surat, Coimbatore, Kochi
// High effort (1–2 weeks): Kolkata, Jaipur, Lucknow, Bhopal
```

---

## 10. Municipal Collection Differences — Rules Matrix

This table captures the key differences a city plugin must encode. Fields where a city matches Bangalore's BBMP rules may inherit defaults but should still be explicit.

| Dimension | Bengaluru (BBMP) | Mumbai (BMC) | Delhi (MCD) | Pune (PMC) |
|-----------|-----------------|-------------|-------------|------------|
| **Wet bin colour** | Green | Green | Green | Green |
| **Dry bin colour** | Blue | Blue | Blue | Blue |
| **Hazardous bin** | Red | Red | Red | Red |
| **Medical bin** | Yellow | Yellow | Yellow | — (with hazardous) |
| **Wet collection** | Daily | Daily | Daily | Daily (apartment compost mandate) |
| **Dry collection** | Alternate days | 2x/week | 2x/week | Weekly |
| **Hazardous collection** | Monthly | Quarterly | Quarterly | Bi-monthly |
| **E-waste** | BBMP exchange program | BMC drop-off centres | MCD authorised dealers | PMC e-waste drives |
| **Bulk waste** | Prior intimation required | Appointment needed | Ticket system | Online booking |
| **Compost mandate** | Apartments ≥10 units | No | No | Apartments ≥20 units |
| **Penalty model** | Rs 100–500 spot fine | Rs 100–500 | Rs 200–1000 | Rs 50–200 |
| **Helpline** | 1800-425-1442 | 1916 | 155308 | 1800-103-0503 |
| **Local name** | BBMP | BMC | MCD | PMC |
| **Language** | Kannada, English | Marathi, Hindi, English | Hindi, English | Marathi, English |

### Tier-2 city highlights

| Dimension | Indore (IMC) | Chandigarh (MCC) | Ahmedabad (AMC) |
|-----------|-------------|-----------------|-----------------|
| **Wet bin** | Green | Green | Green (also door-to-door composting support) |
| **Dry bin** | Blue | Blue | Blue |
| **Hazardous** | Red (special bin) | Red (separate pink bin for sanitary waste) | Red |
| **Wet collection** | Daily | Daily | Daily |
| **Dry collection** | Weekly | 2x/week | 2x/week |
| **Notable** | Star rating for housing societies; RFID-tagged bins | Pink bins for sanitary waste (progressive) | GPS-enabled collection tracking |
| **Penalty** | Rs 100–500 | Rs 500 first offence | Rs 200–1000 |

---

## 11. Special Waste Categories Across Cities

### E-waste

| City | Rules | Collection method |
|------|-------|-------------------|
| Bangalore | BBMP exchange program; authorised recyclers | Drop-off, scheduled pickup |
| Mumbai | BMC authorised e-waste collection centres | 27 centres across city |
| Delhi | MCD empanelled recyclers; EPR portal | Door-to-door on request |
| Pune | PMC quarterly e-waste drives; authorised dealers | Scheduled camps |
| Hyderabad | GHMC e-waste bins at select locations | Drop-off |

### Hazardous waste

- All metros: **separate red bin**, special collection required.
- Common items: paints, solvents, pesticides, CFL bulbs, batteries, used oil.
- Key difference: Some cities accept CFL bulbs in hazardous collection; others have separate CFL drop-off.
- App behaviour: If classification → "hazardous" category, policy engine must always set `requiresSpecialDisposal=true` regardless of ML confidence (safety override).

### Construction & demolition (C&D) waste

| City | Rule |
|------|------|
| Bangalore | Separate collection for >20kg; permit required |
| Mumbai | C&D waste to designated processing facility; fine for mixing with MSW |
| Delhi | C&D waste to specified plants; mandatory reporting for bulk generators |
| Pune | C&D waste processing mandate; "debris on call" service |

Not a P0 category but worth noting for future expansion. C&D rules differ significantly from MSW rules.

---

## 12. Apartment Society Layer

Apartments (RWAs, housing societies) are a distinct jurisdiction with their own waste rules that sit **on top of** municipal rules. This is especially important in Indian metros where many residents live in multi-unit buildings.

### Common society-level variations

| Variation | Prevalence | App impact |
|-----------|-----------|------------|
| On-site composting mandate | Bangalore (common), Pune (growing) | "Your society composts wet waste. Don't put it in the municipal green bin." |
| Specific collection windows | All metros | "Dry waste collection at your society: Tue 8-10 AM." |
| Banned items in common chute | Bangalore many societies | "Glass bottles must be handed separately to the caretaker, not dropped in the chute." |
| Third-party recycler tie-up | Premium societies | "Take newspapers to {kabadiwala} who visits every Saturday." |
| Different bin colour coding | Some societies use own system | Map society colours, warn when municipal colour conflicts. |
| Bulk waste scheduling | Society collects and arranges pickup | "Register bulk waste pickup with the association secretary 48h in advance." |

### Technical implications

- **Discovery**: How does the user identify their society? GPS proximity? Manual search? QR code at society entrance?
- **Verification**: Society rules need an RWA secretary or admin to verify them. A self-registered society without a verified admin gets a "unverified" badge.
- **Storage**: Society overrides stored in Firestore under `societies/{societyId}/policyOverrides/`. Cached locally via Hive.
- **Conflict surface**: Society rules often contradict municipal rules for specific items. The engine must handle this (see Section 5).

### Society onboarding flow (proposed)

```
1. User scans at home location
2. GPS resolves to a known society (or user selects from nearby list)
3. System checks: does this society have registered policy overrides?
   ├── Yes → apply overrides on top of city plugin
   └── No → offer "Is this a society?" prompt
         ├── Create society profile (name, location, size)
         └── Invite RWA secretary to verify rules
4. Decision: "Dry waste collected Tue/Thu at your society (RWA rule)"
```

---

## 13. Dry / Wet / Hazardous / E-Waste Category Handling

### Cross-city category taxonomy

All city plugins share a common category taxonomy. A city maps these categories to its local bin system.

```dart
// Canonical categories
enum WasteCategory {
  wet,            // Organic, kitchen, garden
  dry,            // Recyclables: paper, plastic, metal, glass
  hazardous,      // Paints, solvents, batteries, CFL, pesticides
  medical,        // Syringes, PPE, expired medicine
  eWaste,         // Electronics (may merge with hazardous in some cities)
  construction,   // C&D debris
  sanitary,       // Diapers, sanitary pads (varies: dry/hazardous/separate)
  bulky,          // Furniture, large appliances
  rejected,       // Non-recyclable, non-compostable (varies by city)
}
```

### Bin colour mapping by city

| Category | BBMP | BMC | MCD | PMC | GHMC | GCC | KMC |
|----------|------|-----|-----|-----|------|-----|-----|
| Wet | Green | Green | Green | Green | Green | Green | Green |
| Dry | Blue | Blue | Blue | Blue | Blue | Blue | Blue |
| Hazardous | Red | Red | Red | Red | Red | Red | Red |
| Medical | Yellow | Yellow | Yellow | [hazardous] | Yellow | Yellow | Yellow |
| E-waste | [hazardous] | Drop-off | [hazardous] | [hazardous] | [hazardous] | Drop-off | [hazardous] |
| Sanitary | [dry] | [dry] | Pink (MCC) | [dry] | [dry] | [dry] | [dry] |
| C&D | Separate | Separate | Separate | Separate | Separate | Separate | Separate |

`[hazardous]` = same bin as hazardous; `[dry]` = same bin as dry; `Separate` = dedicated stream

### ML→category→policy routing

```
ML says "waste motor oil"
  │
  ▼
Deterministic mapping: motor oil → hazardous → Red bin
  │
  ▼
Policy check: BBMP requires special disposal for hazardous
  │
  ▼
Result: "Motor oil → Red Bin (hazardous). BBMP requires special disposal.
         Contact helpline 1800-425-1442 for pickup. [violation if not followed]"
```

The ML-to-category mapping is a deterministic lookup table (not a prompt) so that "battery" always maps to "hazardous" regardless of which model classified it.

---

## 14. Open Questions

1. **Source freshness**: Who monitors municipal website changes and triggers rule pack updates? A manual process per city requires N city-watchers. Automated diff monitoring on municipal PDFs is technically possible but fragile.

2. **Enforcement reality vs published rules**: Many cities have published rules that differ from actual collection practice. Should the app surface "official rule" or "what actually happens"? The current proposal: show both. "Official BBMP rule: Green Bin. Reported reality in your ward: mixed collection."

3. **GPS vs manual region selection**: If GPS is off, denied, or inaccurate at ward boundaries, how does the user choose their region? A manual "Set your city" screen is the fallback, but ward-level rules add complexity.

4. **Plugin maintenance burden**: With 15+ cities, each requiring periodic rule review, who owns the India city-ops function? A dedicated team or a community-contribution model with moderation?

5. **Cross-border users**: Users who live in one city and work in another will generate scans in different jurisdictions. Should the policy engine use scan-location (GPS) or home-location (profile)? Current proposal: per-scan GPS, with an option to set a home default.

6. **How to test city plugins without visiting each city**: Synthetic test data for each city's rules. Ward-level test fixtures that exercise collection-schedule edge cases. But real validation requires in-city testing.

---

## 15. Recommended Next Actions

1. **Prototype `CityPolicyData` helper class** that provides fallback implementations for all plugin methods, reducing new-city cost to data entry + test writing.
2. **Build Pune plugin** as the test case for data-driven city expansion (medium difficulty, well-documented rules). Ship to `pilot`. Measure time from scaffold to pilot.
3. **Flesh out the society override layer** — Firestore schema, society registration flow, override application in the policy engine.
4. **Add confidence gating** to `LocalPolicyEngine.applyPolicy()` so it reads `classification.confidence` and adjusts severity accordingly.
5. **Ship provenance card** in the result screen — tap to see "BBMP 2024.1 | Source: BBMP SWM By-law | Last verified: 2025-01-15".
6. **Add `LocalPolicyRuleCheckType.safetyOverride`** — a check type that always escalates to `violation` regardless of confidence when the category is hazardous/medical. This is the deterministic safety floor.
7. **Document city research playbook** under `docs/playbooks/CITY_RULES_RESEARCH.md` — how to find the right municipal documents, what fields to fill, who to contact.
