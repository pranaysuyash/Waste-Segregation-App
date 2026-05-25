# Local Reuse Marketplace — Exploration Doc

**Track**: L5
**Phase**: LATER — Scale + Frontier
**Status**: 🟢 Exploration
**Last Updated**: 2026-05-24
**Frontier dependency**: [F4. Neighbourhood Reuse Marketplace](../EXPLORATION_FRONTIER.md#f4-neighbourhood-reuse-marketplace)
**Parent**: [EXPLORATION_TOPICS.md #22](../EXPLORATION_TOPICS.md#22-local-reuse-marketplace-)
**Sibling topics**: Smart-Bin (#24), Community Feed (#20), B2B Wedge (#29)

---

## Decision This Unblocks

Whether to add a "give away / swap / sell" surface that intercepts items *before* they enter the waste stream — turning the classify-camera into a listing-camera and creating a second product surface beyond disposal guidance.

## De-Risk Question

Does the reuse surface complement or compete with the core classify loop? Can we run a marketplace experience with credible safety and moderation at a small enough scale (building/society) to be manageable?

## Kill Criteria

1. Pilot with two societies generates < 5 listings/week, or moderation overhead exceeds 2 hours/week for < 100 users.
2. Users go to the marketplace and never come back to the classify flow — the surface cannibalizes the core loop.
3. Liability/safety incidents (defective electronics, expired products) create unacceptable risk for a small team.

---

## Why This Matters

The highest-leverage waste intervention is **preventing the item from entering the waste stream at all**. Classification tells you *how* to dispose of something; reuse tells you *not to dispose of it*.

The data flywheel is the key insight:
- User opens camera to classify → app recognizes item → "Want to give this away?" prompt
- No extra friction — the same camera flow produces either a classification or a listing
- Every listing is also a classification (the app knows what the item is)

---

## Architecture Proposal

### 1. Scope: Building / Society Level

Don't compete with OLX/Quikr city-wide. Start at building/society level:

- **Trust**: You know the people. No anonymous transactions.
- **Logistics**: Same building = no shipping. Staircase pickup or lobby drop.
- **Moderation**: Smaller community = less abuse. RWA admin as moderator.
- **Privacy**: No location tracking needed. Building-scoped.

### 2. Data Model

```dart
class ReuseListing {
  final String id;
  final String title;
  final String description;
  final String category;        // "Electronics", "Books", "Clothing" etc.
  final WasteCategory? wasteCategory; // link to classification system
  final ListingType type;       // give, swap, sell
  final double? price;          // null for give/swap
  final String condition;       // new, likeNew, good, fair, poor
  final List<String> imageUrls;
  final String imageUrl;        // from classification camera
  final String userId;
  final String buildingId;      // scope to building/society
  final DateTime createdAt;
  final ListingStatus status;
  final String? classificationId; // link to original classification
}

enum ListingType { give, swap, sell }
enum ListingStatus { active, reserved, completed, expired, removed }
```

### 3. User Flow

**Flow A: Classify → Reuse Prompt**
```
1. User classifies item → sees result
2. If item is "Dry Waste" / "Recyclable" / "Non-Waste" AND in reusable condition:
   → "This looks reusable! Want to give it away instead?"
   → CTA: "Create Reuse Listing"
3. Pre-fills listing with classification data (item name, category, image)
4. User adds condition, price (optional), description
5. Listing goes live in building marketplace
```

**Flow B: Browse → Claim**
```
1. User opens "Reuse" tab in app
2. Sees listings from their building/society
3. Taps listing → sees details + photos
4. "I want this" → sends message to lister (in-app chat or WhatsApp link)
5. Lister confirms → marks as "reserved"
6. After pickup → both confirm → listing "completed"
```

### 4. Integration Points

| Existing Component | Reuse Integration |
|-------------------|-------------------|
| Classification camera | Pre-fills listing with recognized item data |
| Waste category system | Maps waste categories to reuse categories |
| Community screen | Reuse tab alongside community feed |
| Gamification service | Points for successful reuse (more than disposal) |
| Smart bins (L2) | "If nobody claims in 7 days, find a bin nearby" |
| Organization/school (L3) | School marketplace (kids swap books/supplies) |

### 5. Moderation

| Layer | Implementation |
|-------|---------------|
| Pre-listing | Category restrictions (no food, no hazardous items) |
| Image check | Face detection already built (`FaceDetectionService`) |
| Community reporting | Existing `ModerationService` + report flow |
| RWA admin | Admin can remove listings, ban users from marketplace |
| Auto-expiry | Listings expire after 14 days if no interaction |

### 6. Gamification

```dart
// Points for reuse > disposal
int pointsForAction(ReuseAction action) {
  switch (action) {
    case ReuseAction.listed: return 5;
    case ReuseAction.claimed: return 5;
    case ReuseAction.completed: return 15;  // both parties get this
    case ReuseAction.disposed: return 1;    // baseline
  }
}

// Achievements
"First Giveaway" — list your first item
"Reuse Champion" — complete 10 transactions
"Zero-Waste Week" — reuse 5 items in a week instead of disposing
```

---

## Pilot Plan

### Pilot 1: Single Apartment Building

- **Target**: 1 apartment building, 20–50 users
- **Duration**: 4 weeks
- **Scope**: Give-away only (no selling, no swapping). Simplest possible flow.
- **Success criteria**:
  - > 10% of weekly classifications generate a reuse prompt view
  - > 3 listings/week created
  - > 50% of listed items get claimed within 7 days
  - Zero moderation incidents
- **Failure criteria**: < 2 listings/week or any safety incident

### Pilot 2: School (via L3)

- **Target**: 1 school, 1 classroom
- **Scope**: Kids swap books, supplies, art materials
- **Success criteria**: > 5 swaps/week sustained for 3 weeks
- **Key advantage**: Teacher as moderator, trust built-in

---

## Risk Analysis

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Cannibalization of classify flow | Medium | High | Prompt appears *after* classification, never instead of it |
| Defective item liability | Low | High | Terms of service: "as-is", no warranty. Category restrictions for electronics. |
| Low listing volume | High | Medium | Seed with "items wanted" board; gamification drives listing |
| Harassment via messaging | Medium | High | In-app chat with reporting; or use WhatsApp (externalizes risk) |
| Competition with OLX/Quikr | Low | Low | Different scope (building-level, not city-level) |

---

## Concrete Next Steps

1. **Reuse listing model** — `lib/models/reuse_listing.dart` with Firestore schema.
2. **Classification → reuse prompt** — Add "Want to give this away?" CTA to result screen for reusable categories.
3. **Listing CRUD** — Create, browse, claim, complete listing flow.
4. **Building scoping** — Link users to building/society (reuse existing family/organization infrastructure from L3).
5. **Give-away only MVP** — No selling, no swapping in V1. Simplest possible transaction.
6. **Pilot recruitment** — Find 1 apartment building in Bangalore willing to pilot.

## Open Questions

- **Transaction mechanism**: In-app chat vs WhatsApp link vs in-person only? In-app chat is safer but more to build.
- **Scope creep**: When does "reuse marketplace" become "classifieds app"? How do we keep it waste-focused?
- **Seasonal items**: Festival decorations, seasonal clothing — these are high-value reuse items. How to surface them?
- **Metrics**: What's the right north-star metric for reuse? Items diverted from waste stream? User satisfaction? Transaction volume?

## Downstream Artefacts

- `lib/models/reuse_listing.dart` — listing data model
- `lib/services/reuse_marketplace_service.dart` — listing CRUD + matching
- `lib/screens/reuse_marketplace_screen.dart` — browse listings
- `lib/screens/create_reuse_listing_screen.dart` — create listing from classification
- `lib/widgets/reuse_prompt_card.dart` — "Want to give this away?" CTA
- `docs/exploration/REUSE_MARKETPLACE_PILOT_RESULTS.md` — pilot report
