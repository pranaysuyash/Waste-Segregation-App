# Disposal Facilities Directory

**Status**: Exploration — data sourcing and trust model assessment  
**Date**: 2026-05-25  
**Why this matters**: "What is this?" is half the user job. "Where do I take it?" is the other half — and the bridge into Smart-Bin and Municipal API integration.

---

## 1. Current State

**What exists:**
- `lib/screens/disposal_facilities_screen.dart` — facilities search screen (map + list)
- `lib/screens/facility_detail_screen.dart` — facility detail view
- `lib/models/disposal_location.dart` — facility data model
- `lib/services/local_guidelines_plugin.dart` — city guideline plugins (7 cities)
- Flutter map stack wired: `flutter_map`, `flutter_map_marker_cluster`, `flutter_map_heatmap`, `geoflutterfire_plus`, `flutter_map_tile_caching`

**What's missing:**
- Sourcing strategy (crowdsourced / scraped / partner / hybrid)
- Data freshness and verification model
- Offline cache strategy
- User contribution pipeline for facility updates
- Integration with collection schedule data
- Integration with region-aware rulesets (matching disposal advice to facilities)

---

## 2. Data Sourcing Model

### Recommended: Hybrid Model

```
Layer 1 — Static (municipal / partner-sourced)
├── City-run recycling centers (official lists)
├── Public drop-off locations (municipal websites)
├── Partner facility chains (e-waste recyclers, bulk pickup)
├── Verified by: initial scrape + periodic refresh
├── Fresheness: quarterly refresh (API or manual)

Layer 2 — Dynamic (crowdsourced + user-verified)
├── Local scrap dealers (kabadiwalas)
├── Community-run compost sites
├── Small recyclers / repair shops
├── Verified by: user reports + moderator review
├── Fresheness: continuous (user-updated, auto-expiry)

Layer 3 — Schedule-integrated (collection data)
├── Household pickup schedules (integration with L1 locality data)
├── Special collection events (e-waste drives, hazardous waste days)
├── Verified by: municipal sourcing
├── Fresheness: as published by municipality
```

### Sourcing Costs

| Source type | Setup effort | Maintenance effort | Accuracy | Coverage |
|---|---|---|---|---|
| Municipal scrape (cities with open data) | Medium | Low (quarterly refresh) | High | City-specific |
| Partner API (recycler networks) | Medium | Low (API key) | High | National/regional |
| User contribution | Low (build UI) | High (moderation) | Medium | Anywhere |
| Google Maps / OSM extraction | Low | Low | Medium | Global, but generic |
| Manual curation (per city) | High | High | Highest | Targeted cities only |

---

## 3. Data Freshness & Verification

### Freshness Signals

Each facility listing carries a `lastVerifiedAt` timestamp and a verification state:

```
verificationState: enum
├── pending             # New, unverified submission
├── verified_official   # Confirmed by municipal source or partner
├── verified_community  # Confirmed by ≥3 community reports
├── reported_stale      # Flagged as likely stale or closed
├── confirmed_stale     # Confirmed permanently closed by moderator
├── auto_expired        # No verification heartbeat in N months
```

### Auto-Expiry Policy

| Verification state | Auto-expiry period |
|---|---|
| `verified_official` | 12 months |
| `verified_community` | 6 months |
| `pending` | 3 months |
| `reported_stale` | 30 days (auto-remove if not re-verified) |

### "Report Issue" Toggle

Every facility card includes:
- "This location is closed" → marks `reported_stale`
- "Wrong address / directions" → opens correction form
- "Wrong disposal types" → opens category correction
- "This was helpful" → positive signal (+1 to freshness score)

### User Verification Incentive

- Verified facility update = +25 points (gamification)
- Three verified updates = "Facility Scout" badge
- Moderator role for high-reputation users (manual vetting process)

---

## 4. Offline Cache Strategy

### Tile-Based Loading

- Map tiles and facility markers cached per geographic bounding box
- When user moves map, download markers for visible area
- Cache persists for 24 hours, then stale (with "last updated X days ago" label)
- User can manually refresh per city/area

### Offline View

```
- Favorites list (manually saved facilities) — always cached
- Recent searches (last 5 cities/areas) — cached
- Full directory for current city (auto-cached when "home city" is set)
- Stale data shown with: "Last updated: May 20, 2026 — data may be outdated"
```

---

## 5. User Contribution Pipeline

### Contribution Flow

```
1. User taps "Add facility" on facility screen
2. Form: name, address, types accepted, contact info, hours, photos (optional)
3. GPS auto-fills coordinates (user can adjust)
4. Submitted → `pending` state → indexed on map with "New" badge
5. Moderator reviews within 48 hours (target)
6. Approved → `verified_community` → live on map
7. Reporter notified of approval (+25 points, +1 contribution count)
```

### Contribution Anti-Spam

- Max 5 pending contributions per user (prevents spam dumping)
- New user contributions (first 3) auto-flagged for moderator review
- Duplicate detection (address proximity + name similarity)
- Known shill accounts blocked after 2 accepted contributions that are reported as false

---

## 6. Integration with Region Rules & Disposal Advice

### Match Flow

```
1. User classifies item → "plastic bottle (PET-1)"
2. Region rules determine: "PET-1 → blue bin" OR "drop-off only in this city"
3. Disposal facilities screen:
   a. If drop-off: filter facilities that accept "plastic" or "PET"
   b. Show distance-sorted list
   c. Highlight facilities currently accepting (not full/stale)
4. If blue bin: show collection schedule (if available) or nearest bin location
```

### Facility Type Mapping

| Waste category | Facility types to show |
|---|---|
| Plastic bottles (PET, HDPE) | Blue bin, drop-off center, scrap dealer |
| E-waste | E-waste recycler, brand take-back, municipal e-waste drive |
| Hazardous (batteries, chemicals) | Hazardous waste facility, designated drop-off |
| Organic / compostable | Compost site, green bin, community compost |
| Textiles | Clothing donation bin, textile recycler |
| Glass | Glass-only container, drop-off center |
| Mixed recycling | MRF, sorting facility, blue bin |
| Bulky waste | Bulk pickup schedule, transfer station |

---

## 7. Open Questions

1. **Initial facility data**: Should we launch with scraped municipal data for 7 partner cities, or require user contributions to populate the directory?
2. **Scrap dealer integration**: Kabadiwala/private collector data — how to source, verify, and incentivize participation?
3. **Collection schedule integration**: Is BBMP / municipal schedule data legally republishable? What about other cities?
4. **Moderation capacity**: Crowdsourced facility data requires active moderation. What's the bandwidth for 1–2 community moderators?
5. **OpenStreetMap integration**: OSM has waste-related tags (amenity=recycling, etc.). Should we pull from OSM as a supplementary layer?

---

## 8. Related Docs

- `docs/exploration/REGION_RULES_AND_CITY_EXPANSION_MAP.md` — rule integration
- `docs/exploration/USER_CONTRIBUTION_UGC_PIPELINE.md` — contribution pipeline
- `docs/exploration/LOCALITY_COLLECTION_DATA.md` — collection schedules
- `docs/exploration/B2B_ENTERPRISE_WEDGE.md` — partner data sourcing
- `lib/models/disposal_location.dart` — data model
- `lib/screens/disposal_facilities_screen.dart` — current UI
