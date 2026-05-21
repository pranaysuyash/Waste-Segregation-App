# Waste Education Card System

**Date:** 2026-05-21  
**Status:** Design Review  
**Scope:** Educational content cards for post-classification result screen

---

## Problem

After classification, users see disposal instructions and technical data but lack the **why**. A user told "this is dry waste" does not learn **why greasy cardboard fails recycling** or **why batteries need a special drop-off**. Without the educational layer, the app is a labeler, not a teacher.

---

## Architecture

### Layered Model

```
WasteEducationCard (abstract)
├── EducationCard          — "Why this matters" story
├── MaterialImpactCard     — Environmental impact of this material
├── CommonMistakeCard      — Common errors for this category
├── LocalRuleExplainer     — Region-specific rules (BBMP, etc.)
└── AlternativeActionCard  — What to do instead (reuse, donate, etc.)
```

### Data Model

```dart
/// Single source of truth for all educational card content.
/// Cards are small, copy-compact, and region-scoped.
class WasteEducationCard {
  final String id;
  final String title;          // 3-8 words, punchy
  final String body;           // 1-3 sentences, ≤200 chars
  final String iconName;       // Material icon name
  final EducationCardVariant variant;
  final List<String> triggerCategories;   // e.g. ['dry waste', 'plastic']
  final List<String> triggerMaterials;    // e.g. ['cardboard', 'lithium']
  final List<String> triggerSubcategories;
  final List<String> applicableRegions;   // ['all'] or ['bangalore', 'mumbai']
  final int priority;           // lower = shown first when multiple match
  final bool requiresExplicitDismiss;  // true for safety-critical cards

  // Card is shown when:
  //   classification.category IN triggerCategories
  //   OR classification.materials HAS ANY triggerMaterials
  //   OR classification.subCategory IN triggerSubcategories
  //   AND (applicableRegions.contains('all') OR classification.region IN applicableRegions)
}

enum EducationCardVariant {
  story,           // EducationCard: "Did you know?"
  impact,          // MaterialImpactCard: environmental stats
  mistake,         // CommonMistakeCard: what people get wrong
  localRule,       // LocalRuleExplainer: BBMP-specific rules
  alternative,     // AlternativeActionCard: what to do instead
}
```

### Card Resolution

```
CardEngine.resolve(classification, region)
  → List<WasteEducationCard> matched
     (sorted by priority, filtered by region,
      max 1 returned to result screen)
```

Only **one card** shows on the result screen at a time. If multiple match, pick the highest-priority card the user has not already dismissed. This prevents educational overload and keeps the result screen from becoming a scroll wall.

### Dismissal Tracking

```dart
/// Tracks which cards a user has seen/dismissed so we rotate content.
class SeenEducationCard {
  final String cardId;
  final DateTime lastSeen;
  final int dismissCount;
  final bool permanentlyDismissed;
}
```

Persisted in Hive (`seenEducationCardsBox`). Cards rotate on repeat classifications: if the user classifies the same item again, they get a different card from the match set.

---

## Card Types

### 1. EducationCard (`variant: story`)

**Purpose:** A short "why this matters" story tied directly to the classified item.  
**Tone:** Curious, rewarding. Like a friend explaining something at the bin.  
**Constraints:** 1-3 sentences, no jargon.

**Seed cards:**

| ID | Title | Body | Triggers | Region |
|---|---|---|---|---|
| `edu_greasy_cardboard` | Why greasy cardboard is trash | "Cardboard fibers can't separate from oil during recycling. One greasy pizza box can contaminate an entire batch. Tear off the clean top, bin the oily bottom." | `material: cardboard`, `subcategory: paper` | all |
| `edu_battery_dropoff` | Batteries need their own bin | "Batteries contain metals that start fires in trucks and landfills. One crushed lithium battery = one garbage truck fire. Take them to the drop-off box at your nearest electronics store." | `category: hazardous`, `subcategory: battery` | all |
| `edu_medicine_strips` | Medicine strips are NOT normal plastic | "Medicine blister packs are made of mixed materials — plastic + aluminium — that recycling plants can't separate. They go in reject waste, not dry waste." | `material: medicine strip`, `category: dry waste` | all |
| `edu_rinsing_matters` | Rinse before you recycle | "A yogurt tub with residue spoils the whole recycling batch. A quick rinse is all it takes to keep the entire load recyclable. No soap needed — just water." | `category: dry waste`, `subcategory: plastic` | all |
| `edu_ewhat_is_ewaste` | What counts as e-waste | "E-waste isn't just phones and laptops. Chargers, old earphones, dead power banks, broken keyboards — anything with a plug or battery. Drop these at e-waste collection points, not your regular bin." | `category: e-waste` | all |

### 2. MaterialImpactCard (`variant: impact`)

**Purpose:** Quantify the environmental outcome of doing it right.  
**Tone:** Matter-of-fact, concrete numbers.  
**Constraints:** One hard number (kg CO₂, litres water, trees saved). Never abstract.

**Seed cards:**

| ID | Title | Body | Triggers | Region |
|---|---|---|---|---|
| `impact_plastic_savings` | One bottle, big difference | "Recycling one plastic bottle saves enough energy to run a 60W bulb for 6 hours. Do that every week and it's like planting 4 trees a year." | `subcategory: plastic` | all |
| `impact_compost_co2` | Composting cuts methane | "Food waste rotting in landfill releases methane — 25x stronger than CO₂. Composting it cuts those emissions to zero and gives you free fertiliser." | `category: wet waste` | all |

### 3. CommonMistakeCard (`variant: mistake`)

**Purpose:** Surface a specific, frequent mistake users make for this category.  
**Tone:** Gentle correction. "Heads up" not "you're wrong".  
**Constraints:** One mistake per card. Must include the fix.

**Seed cards:**

| ID | Title | Body | Triggers | Region |
|---|---|---|---|---|
| `mistake_containers_with_food` | Containers with food in them | "Throwing a half-eaten container in dry waste contaminates everything around it. Empty, rinse, then recycle. A quick rinse takes 5 seconds." | `subcategory: plastic` | all |
| `mistake_wet_paper` | Wet paper is not recyclable | "Wet paper fibres break down too much to be made into new paper. If it's wet or stained with food, it goes in wet waste, not dry." | `subcategory: paper` | all |
| `mistake_glass_ceramic` | Not all glass is the same | "Glass bottles and jars? Recycle. But drinking glasses, Pyrex, and window glass melt at different temperatures — they ruin the recycling batch. Those go in reject waste." | `material: glass` | all |

### 4. LocalRuleExplainer (`variant: localRule`)

**Purpose:** Explain a region-specific rule tied to this classification.  
**Tone:** Informative, authoritative.  
**Constraints:** Must cite the local body name (e.g. BBMP, BMC, etc.). Falls back silently when region has no rules.

**Seed cards:**

| ID | Title | Body | Triggers | Region |
|---|---|---|---|---|
| `bbmp_dry_days` | BBMP picks dry waste Mon/Wed/Fri | "Bangalore's BBMP collects dry waste on Monday, Wednesday, and Friday. Set it out by 7 AM. On other days, the truck won't take it — and it'll count as litter." | `category: dry waste` | bangalore |
| `bbmp_wet_daily` | BBMP wet waste is daily | "BBMP collects wet waste every day between 6-10 AM. Keep it in a closed bin to avoid attracting strays and odour." | `category: wet waste` | bangalore |
| `bbmp_hazardous_kspcb` | Hazardous waste needs KSPCB | "BBMP does not collect hazardous waste. Take batteries, paints, and chemicals to the KSPCB facility in Bidadi or your nearest collection drive." | `category: hazardous` | bangalore |

### 5. AlternativeActionCard (`variant: alternative`)

**Purpose:** Offer a better outcome than disposal — reuse, donate, repair.  
**Tone:** Encouraging, actionable.  
**Constraints:** Must include one concrete action the user can take today.

**Seed cards:**

| ID | Title | Body | Triggers | Region |
|---|---|---|---|---|
| `alt_old_phones` | Don't bin that old phone | "Old phones contain gold, silver, and rare minerals. Drop them at an e-waste kiosk or give them to a repair shop that recycles responsibly. Some brands even offer free take-back." | `category: e-waste` | all |
| `alt_clothes_donate` | Clothes are not trash | "Old clothes in landfill take 200+ years to break down and leak dyes into groundwater. Donate wearable items, use torn ones as rags, or find a textile recycler." | `material: textile`, `subcategory: textile` | all |

---

## Seed Card Inventory

**Total: 14 seed cards** (requirement: ≥8)

| Type | Count |
|---|---|
| EducationCard (story) | 5 |
| MaterialImpactCard (impact) | 2 |
| CommonMistakeCard (mistake) | 3 |
| LocalRuleExplainer (localRule) | 3 |
| AlternativeActionCard (alternative) | 2 |

---

## UI Component Specification

### Card Widget: `EducationCardWidget`

```dart
class EducationCardWidget extends StatelessWidget {
  const EducationCardWidget({
    super.key,
    required this.card,
    required this.classification,
    this.onDismiss,
    this.onLearnMore,
  });

  final WasteEducationCard card;
  final WasteClassification classification;
  final VoidCallback? onDismiss;
  final VoidCallback? onLearnMore;
}
```

**Layout (compact, result-screen native):**

```
┌──────────────────────────────────────┐
│ [icon]  Title                         │
│                                       │
│ Body copy — one to three short       │
│ sentences. No scroll, no overflow.    │
│                                       │
│                    [Dismiss] [Learn]  │
└──────────────────────────────────────┘
```

- **Visual style:** Card, elevation 0 (matches existing `local_rules_card.dart` pattern), uses `colorScheme.primaryContainer` at low opacity or a variant-specific tint.
- **Icon:** 20px Material icon from `card.iconName`, tinted to variant color.
- **Title:** `titleMedium`, bold.
- **Body:** `bodySmall`, `ReadMoreText` with max 3 lines (reuses existing `lib/widgets/responsive_text.dart`).
- **Actions:** "Got it" (dismiss) + "Learn more" (opens mini-lesson screen or educational content screen). "Got it" is subtle text button; "Learn more" is filled when the card has extended content.
- **Width:** full parent width, horizontal padding 16px.

### Variant Colors

| Variant | Container Tint | Icon/Accent |
|---|---|---|
| story | `primaryContainer` at 0.25 | `primary` |
| impact | green container at 0.15 | green |
| mistake | amber container at 0.15 | amber |
| localRule | blue container at 0.15 | blue |
| alternative | purple container at 0.15 | purple |

### Placement in Result Screen

Inserted at `result_screen.dart:343` (after `ExplanationPanel` + `_buildStoryCards`, before `_buildLearnMoreCard`):

```dart
// Education card (one relevant card picked by engine)
if (_educationCard != null) ...[
  const SizedBox(height: 16),
  EducationCardWidget(
    card: _educationCard!,
    classification: _classification,
    onDismiss: _dismissEducationCard,
    onLearnMore: _openMiniLesson,
  ),
],
```

This gives a natural reading order:
1. Category + confidence
2. Disposal instructions
3. Why this classification (explanation panel)
4. **Education card** ← here
5. Learn more / impact / local rules / materials

### State Management

```dart
// In _ResultScreenState:
WasteEducationCard? _educationCard;
Set<String>? _dismissedCardIds;

void _selectEducationCard() {
  final engine = EducationCardEngine(seedCards: allSeedCards);
  _educationCard = engine.bestCardFor(
    classification: _classification,
    region: _classification.region,
    dismissedIds: _dismissedCardIds ?? {},
  );
}

void _dismissEducationCard() {
  if (_educationCard == null) return;
  setState(() {
    _dismissedCardIds = {...?_dismissedCardIds, _educationCard!.id};
    _educationCard = null; // Collapses immediately
  });
  // Persist dismissal
}
```

### Shareable Mini-Lessons Flag

Each `WasteEducationCard` has an optional `lessonUrl` or `extendedBody` field. When present, the "Learn more" button navigates to `MiniLessonScreen` — a scrollable page with the same card at top and deeper content below. This enables the **expand into mini-lessons later** requirement without cluttering the result screen.

```dart
class MiniLessonScreen extends StatelessWidget {
  /// Full-screen version of a WasteEducationCard with extended content,
  /// related tips, and a call to action.
}
```

---

## Future: Mini-Lessons

The card system is designed to expand into mini-lessons without changing the result screen:

1. Add `extendedBody: String?` to `WasteEducationCard`
2. Add `relatedCardIds: List<String>?` to chain cards into a lesson
3. `MiniLessonScreen` renders the extended body + related cards at bottom
4. The result screen never changes — it still shows one compact card

This means:
- Phase 1 (now): Cards on result screen, dismiss only
- Phase 2 (next): Tap "Learn more" → mini-lesson with extended content
- Phase 3 (future): Curated lesson paths, quiz integration

---

## Files to Create

| File | Purpose |
|---|---|
| `lib/models/education_card.dart` | `WasteEducationCard` model, `EducationCardVariant` enum, `SeenEducationCard` model |
| `lib/utils/education_card_engine.dart` | `EducationCardEngine` — card matching + priority resolution |
| `lib/data/seed_education_cards.dart` | All 14 seed card instances |
| `lib/widgets/education_card_widget.dart` | `EducationCardWidget` UI component |
| `lib/screens/mini_lesson_screen.dart` | (Phase 2) Mini-lesson detail screen |

### File to Modify

| File | Change |
|---|---|
| `lib/screens/result_screen.dart:343` | Insert education card widget between explanation panel and learn-more card, add state for card selection/dismissal |

---

## Acceptance Criteria Check

| Criterion | Status |
|---|---|
| At least 8 seed educational cards | ✅ 14 cards (5 story + 2 impact + 3 mistake + 3 localRule + 2 alternative) |
| Cards are connected to categories/materials | ✅ Each card has `triggerCategories`, `triggerMaterials`, `triggerSubcategories` with matching logic |
| UI component exists or is specified | ✅ `EducationCardWidget` fully specified with layout, colors, placement |
| Result screen can show one relevant card | ✅ `EducationCardEngine.bestCardFor()` picks exactly 1; placement specified at result_screen.dart:343 |
| Copy is user-friendly, not academic | ✅ All seed card copy is conversational, 1-3 sentences, no jargon |
| Short, simple copy | ✅ Body ≤200 chars per card |
| Region-aware | ✅ `applicableRegions` field; BBMP-specific cards for Bangalore; `['all']` for universal cards |
| Tied to classification result | ✅ Card engine takes `WasteClassification` + region as input |
| Does not overwhelm result screen | ✅ Single card, compact layout, dismissible, always collapsed |
| Can be expanded into mini-lessons later | ✅ `extendedBody` + `MiniLessonScreen` planned for Phase 2 |

---

## Decision Log

| Decision | Rationale |
|---|---|
| Only 1 card on result screen | Multiple cards compete for attention and scroll past viewport. One relevant card is read. |
| Variant-specific colors | Helps users visually categorise the *kind* of tip without reading the title. |
| Dismissal tracking | Prevents showing the same card repeatedly. Rotates through match set. |
| `triggerMaterials` uses `List<String>` | The classification already has `materials` as `List<String>`. Direct string match is simple and testable. |
| Local rules are a card variant (not a separate screen) | Keeps local content inline, visible without navigation. Existing `LocalRulesCard` widget remains for structured compliance data; this card variant is for **explanatory** local content. |
| Engine is sync, not async | Card data is static seed data loaded at init. No network fetch needed. |
