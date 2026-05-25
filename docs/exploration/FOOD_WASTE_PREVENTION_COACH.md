# Food Waste Prevention Coach

**Status**: Exploration | P2 | Circular Economy & Pre-Waste Intervention
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) — Entry 50
**Last Updated**: 2026-05-25

---

## Why This Matters

Food waste is the single largest category of household waste by weight. It also has the highest environmental impact per kg of any waste category (methane from landfills). A food waste prevention coach is a natural extension of the classification pipeline — if the app already identifies items, it can help users avoid wasting them.

This is also a high-retention surface: food expiry tracking creates daily engagement touchpoints ("what's expiring today?") that garbage classification alone does not.

---

## Core Features

### 1. Expiry Tracking

| Method | Friction | Reliability | Adoption Likelihood |
|--------|----------|-------------|---------------------|
| Manual entry | High | High | Low (requires habit) |
| Barcode scan + product DB average shelf life | Low | Medium | High |
| OCR of expiry date from packaging | Low | Medium (improving) | Highest |
| Digital receipt / order email parsing | Zero | Low-Medium | High (requires opt-in) |

**Recommendation**: Barcode scan as primary (user already scans items), expiry date OCR as stretch, email parsing as opt-in premium feature.

### 2. "Use It Up" Recipe Suggestions

The recipe engine is the bridge between tracking and action:

- **Trigger**: Item hits 20% remaining shelf life → recipe suggestion with that item as mandatory ingredient
- **Ingredients-first**: Recipes that treat expiring-soon items as base, fill rest from user's stated "staples" pantry
- **Dietary awareness**: Respect preferences (veg/vegan/gluten-free) via user profile
- **Zero-waste cooking**: "How to use the whole vegetable" tips (peels → stock, stems → stir fry)

### 3. Meal Planning Integration

- **Pre-shop planning**: "Check your fridge before you buy" — cross-reference planned meals against current inventory
- **Smart shopping list**: Excludes items already stocked, highlights items that will pair with soon-expiring produce
- **Portion planning**: "This recipe serves 4 — you can freeze half" for singles/small households

### 4. Compost & Food Scrap Guidance

| Scrap Type | Guidance |
|------------|----------|
| Fruit/veg peels | Home compost or community compost drop-off |
| Coffee grounds, eggshells | Compost — good for soil |
| Cooked food scraps | Depending on oil/salt content — check local rules |
| Meat/bones | Not home-compostable — check municipal organics rules |
| Dairy, oil, grease | Never compost — solid waste or specific collection |

### 5. Kitchen Routine Nudges

- **Quiet pre-shop nudge**: Sunday morning: "Check expiring items before your grocery run"
- **Portion awareness**: After logging food waste: "You wasted Rs. X this week — here's how to reduce"
- **Seasonal eating**: Highlight what's in season for longer shelf life and lower carbon
- **Storage tips**: "Onions last longer in a cool, dark place" — surface contextual knowledge

---

## Impact Metrics

| Metric | Description | User Facing |
|--------|-------------|-------------|
| Meals saved | Items logged as consumed before expiry | "You saved 12 meals this month" |
| Money saved | Estimated value of food not wasted | "You saved Rs. 850 — equivalent to 3 coffees" |
| CO₂ avoided | Emissions prevented by avoiding landfill | "Equivalent to planting 2 trees" |
| Compost diverted | Food scraps composted vs landfilled | "Your compost diverted 5kg this month" |
| Days streak | Consecutive days with zero logged food waste | Daily engagement metric |

---

## Competitive Landscape

| App | Strength | Weakness |
|-----|----------|----------|
| **NoWaste** | Good inventory management, barcode + manual expiry | No OCR, limited recipe engine, no compost guidance |
| **Too Good To Go** | Surplus marketplace, high engagement | Pre-consumer only — not home waste |
| **Olio** | Community redistribution | Passive — relies on user posts |
| **Fridge Pal** | Simple, lightweight, push reminders | No recipe engine, weak impact metrics |
| **Kitchen Pal / SuperCook** | Strong recipe engine, ingredients-first | No waste focus, no expiry tracking |

**Gap**: No app combines expiry tracking + recipe engine + compost guidance + impact metrics + local disposal rules in one flow. This is the wedge.

---

## Integration with Existing App

| Touchpoint | Current State | Target State |
|------------|---------------|--------------|
| Scan result — food item | Classification + disposal | "Track this item?" added to flow |
| Home screen | Stats + recent scans | "3 items expiring today" widget |
| Impact dashboard | Waste diversion | + Meals saved, money saved |
| History screen | Classification history | + Expiry timeline per food item |
| Community tab | Scans and challenges | + Recipe sharing, food waste challenges |

---

## Open Questions

1. **OCR accuracy**: Is expiry date OCR reliable enough on Indian food packaging (multilingual, non-standard formats)?
2. **Adoption threshold**: Will users manually add expiry dates, or is barcode-only (with average shelf-life heuristics) sufficient?
3. **Privacy**: Digital receipt parsing is highest value but highest privacy risk — what's the consent model?
4. **Monetisation**: Could advanced food waste prevention (receipt parsing, meal planning) be a premium feature?
5. **Compost data**: Can we integrate with local compost drop-off points from the Disposal Facilities Directory?

---

## Phasing

| Phase | Scope | Key Dependency |
|-------|-------|----------------|
| 0 | Barcode + product DB shelf life; manual expiry fallback | Product DB for average shelf life |
| 1 | Recipe suggestions via external API (spoonacular etc.) | Recipe API integration |
| 2 | Compost guidance + local drop-off points | Disposal Facilities Directory |
| 3 | OCR expiry date from package labels | Vision pipeline for OCR |
| 4 | Digital receipt parsing (opt-in) | Consent Architecture, on-device NLP |
