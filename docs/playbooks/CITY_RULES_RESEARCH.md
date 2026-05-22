# City Rules Research Playbook

**Purpose**: Standardised process for researching a new city's solid waste management rules and translating them into a `CityPolicyData` plugin entry.

**Audience**: Any engineer or contributor adding a new city.

**Time estimate**: 2–5 days per city depending on source availability.

---

## 1. Find the Right Sources

### Primary sources (T0 — authoritative)

| Source type | Where to look | What to record |
|-------------|--------------|----------------|
| Municipal SWM by-law | City corporation website → "Solid Waste Management" or "Cleaning" section | PDF/URL, effective date, authority name |
| Gazette notification | State govt environment dept, municipal corporation gazette | Notification number, date, signed authority |
| Swachh Survekshan report | swachhsurvekshan2023.com (MoHUA) | City rank, reported compliance metrics |
| Municipal helpline | City website, Google | Phone number, hours, languages |

### Secondary sources (T1–T2 — verifying)

| Source | Trust level | Use for |
|--------|-------------|---------|
| News articles on recent SWM changes | T2 — community | Identifying rule changes, pilot programs |
| RWA / society group posts | T2 — community | Ground truth on what actually happens |
| Competitor app data (visible) | T2 — community | Cross-reference collection schedules |
| City-specific Wikipedia | T2 — community | Overview, authority structure, ward count |

### Minimum verification rule

For `pilot` stage: ≥1 primary source OR ≥2 secondary sources agreeing on each required field.

For `production` stage: ≥1 primary source per required field, with a verifiable URL or PDF reference.

---

## 2. Required Fields to Research

Fill this template for every city:

```
## City: [Name]

### Authority
- Name: [e.g. Pune Municipal Corporation]
- Abbreviation: [e.g. PMC]
- Website: [URL]
- SWM department page: [URL if separate]
- Helpline: [phone number]
- Source URL: [direct link to SWM rules PDF or page]

### Bin Color Coding
- Wet waste: [color]
- Dry waste: [color]
- Hazardous waste: [color]
- Medical waste: [color or note if merged]
- E-waste: [color or note about special handling]
- Sanitary waste: [color or note]
- Construction waste: [color or note]

### Collection Schedule
- Wet waste: [frequency, time window, notes]
- Dry waste: [frequency, time window, notes]
- Hazardous: [frequency, how to schedule]
- Medical: [frequency, handler type]
- Bulk waste: [how to arrange]

### Regulations by Category
For each category, record:
- Bin color requirement
- Any mandatory processing (composting, sorting)
- Penalty for non-compliance (amount and conditions)
- Special handling instructions

### Special Programs
- E-waste collection: [program name, locations, frequency]
- Composting support: [subsidised bins, community programs]
- Bulky waste: [booking process]
- Any city-specific initiatives

### Disposal Instructions
For each category, write the instruction that would appear to a user:
- Primary method
- Where to take/place it
- Timeframe
- City-specific note

### Subcategory Overrides
Which items have different handling than their parent category?
- E-waste: [different from hazardous in some cities]
- Batteries: [retail drop-off vs municipal collection]
- CFL bulbs: [hazardous vs dedicated drop-off]

### Penalty Model
- Amount: [range]
- Who enforces: [municipal staff, ward officer, fine spot]
- Conditions: [what triggers a fine]

### Notable Local Rules
Any rules that make this city different:
- Composting mandates (unit count threshold)
- Special bin programs (pink bins for sanitary waste)
- Informal sector role (kabadiwala integration)
- Digital tracking (RFID bins, GPS collection)
- Construction debris rules
```

---

## 3. Translate Research → `CityPolicyData`

Once research is complete, create a `static const` entry in `lib/services/city_policy_data.dart`.

### Mapping from research to code

| Research field | Code field | Notes |
|---------------|-----------|-------|
| Authority name | `authorityName` | Official name, not abbreviation |
| Abbreviation | `pluginId` | Format: `{lowercase_authority}_{city}` |
| Version | `guidelinesVersion` | `{AUTHORITY}-{YEAR}.{RELEASE}` |
| Helpline | `helpline` | String, may include multiple numbers |
| Source URL | `sourceUrl` | Direct link to SWM page |
| Bin colors | `colorCoding` | Key: `wet_waste`, `dry_waste`, etc. Value: human-readable bin description |
| Collection schedule | `collectionSchedule` | Per-category map with frequency, time, notes |
| Disposal instructions | `disposalInstructions` | Per-category with primaryMethod, location, timeframe |
| Regulations | `regulations` | Per-category key-value pairs |
| Subcategory overrides | `subcategoryOverrides` | Key: `e_waste`, `battery`, etc. |
| Special programs | `specialPrograms` | Key-value pairs |
| Penalty | `penaltyInfo` | String summary |

### Governance stage assignment

| Condition | Stage |
|-----------|-------|
| Primary source found, data complete for all required fields | `pilot` |
| Only secondary sources, or missing ≥2 required fields | `draft` |
| Has passed regression suite, live in app for ≥4 weeks without issues | `production` |

---

## 4. Validation Checklist

Before submitting a city plugin PR:

- [ ] All 10 required `CityPolicyData` fields populated
- [ ] At least 1 source URL documented for the data
- [ ] Rule pack in `local_policy_rule_packs.dart` created with ≥4 rules
- [ ] Safety override rules included for hazardous and medical categories
- [ ] Region alias added in `LocalGuidelinesManager._regionAliases`
- [ ] Plugin registered in `LocalGuidelinesManager.initializeDefaultPlugins()`
- [ ] Routing test added in `local_guidelines_manager_routing_test.dart`
- [ ] Rule pack test added in `local_policy_rule_packs_test.dart`
- [ ] Policy engine integration test added in `local_policy_engine_test.dart`
- [ ] `flutter test` passes for all policy tests
- [ ] This playbook followed; research sources archived in the PR description
