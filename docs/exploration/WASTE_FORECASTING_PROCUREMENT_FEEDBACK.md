# Waste Forecasting & Procurement Feedback — Exploration Doc

**Track**: P3 — Deep Frontier
**Status**: 🟢 Exploration
**Last Updated**: 2026-05-24
**Parent**: [EXPLORATION_TOPICS.md #83](../EXPLORATION_TOPICS.md#83-waste-forecasting-and-procurement-feedback-)
**Sibling topics**: Personal Impact Dashboard (A9), Classification History (#12), Smart Suggestions (A6), Continuous Learning Loop (F3), Brand Closed-Loop Data (F8)

---

## Decision This Unblocks

Whether to build predictive models that forecast an individual's or household's waste generation — and whether procurement feedback ("based on your waste, you should buy differently") is helpful or intrusive.

---

## Overview

Two related but distinct products:

### 1. Waste Forecasting

Predict future waste generation based on:

- Classification history (seasonal patterns, consumption trends).
- Calendar events (festivals, holidays, parties).
- Lifecycle data (purchases logged via barcode or receipt).
- Demographics (household size, location, income proxy by neighbourhood).

**Use cases**:

- **Individual**: "Based on your history, you'll generate ~20% more waste during Diwali. Prepare: set up extra bins."
- **Household**: "Your food waste has been increasing for 3 months. Notable spike after every weekend delivery."
- **RWA/society**: "Block A recycles 3x more than Block B. Collection needs for Block A are growing 10%/month."
- **Municipal**: Aggregated forecasting for collection route planning (B2G play).

### 2. Procurement Feedback

After detecting patterns, suggest procurement changes:

- **Individual**: "You dispose of plastic bottles most frequently. Consider a reusable bottle — these 50 bottles could have been avoided."
- **Household**: "Pre-packaged snack wrappers are your #1 waste category. Bulk-buying snacks would reduce packaging by 70%."
- **School / corporate**: "The office generates 15 kg of coffee cup waste per week. Installing a cup-washing station would divert ~780 kg/year."

---

## Data Requirements

| Signal | Source | Privacy Sensitivity | Forecast Value |
|--------|--------|--------------------|---------------|
| Classification history | Existing | Low (anonymizable) | High — primary signal |
| Time of day / day of week | Classification timestamp | Low | Medium — routine patterns |
| Seasonal events | Calendar API (festival dates) | Low (public data) | Medium — event spikes |
| Barcode data | Purchase scan | High (shopping detail) | High — consumption signal |
| Location (city) | GPS / manual selection | Medium | Medium — city-specific patterns |
| Household size | User profile | Low | Medium — scale factor |
| Weather data | Public API | Low | Low-Medium — stay-at-home vs going out |

**Constraint**: Forecasting from classification history alone (no purchase data) is viable but limited. Purchase data adds significant accuracy but at a higher privacy cost.

---

## Forecasting Methods (Ranked)

### Method 1: Simple Trend Analysis (Minimum Viable)

```
Weekly_total_weight(t+1) = moving_average(weekly_total_weight, last_4_weeks)
Seasonal_spike(t+1) = historical_spike_for(event, last_3_years)
Forecast(t+1) = trend(t+1) + seasonal_spike(t+1)
```

- **Accuracy**: ±30-50% for individual, ±15-25% for aggregated (RWA/municipal).
- **Effort**: 2-3 days to implement.
- **No ML required**: Simple statistical methods on aggregated history.

### Method 2: Causal Model with Calendar Events

```
Forecast(t+1) = baseline(t+1) + event_effect(t+1) + weather_effect(t+1) + trend(t+1)
```

- Add festival/holiday dummies as known event effects.
- Fit via linear regression or Gradient Boosted Trees.
- **Accuracy**: ±20-30% for individual, ±10-15% for aggregated.
- **Effort**: 1-2 weeks (requires feature engineering and eval).

### Method 3: Full Consumption-Based Model

- Requires barcode purchase data (receipt scan or order email integration).
- Purchase data is the strongest predictor of future waste (what you buy = what you'll dispose).
- **Accuracy**: ±15-25% for individual, ±5-10% for aggregated.
- **Privacy**: Highest sensitivity — requires explicit, granular consent.

**Recommendation**: Start with Method 1. Aggregate to Method 2 if RWA/corporate partners need higher accuracy. Method 3 only if purchase data is a product feature (not a forecasting input).

---

## Procurement Feedback Design

### Principles

1. **Never shame**. Procurement feedback framed as "here are alternatives" not "you're wasting too much."
2. **Timing matters**. Show immediately after a classification of the offending item ("This plastic bottle could have been avoided — here's a reusable alternative"). In a weekly digest ("You disposed 15 plastic bottles this week — 10 more than average").
3. **Actionable**. Every recommendation must include a concrete next step: link to buy reusable, recipe for using leftovers, bulk-buying guide.
4. **Privacy-safe**. Recommendations are personal and visible to the user only. Never share individual procurement data in community feeds or aggregated reports without explicit consent.

### Recommendation Types

| Pattern | Trigger | Suggestion | Sensitivity |
|---------|---------|------------|-------------|
| Frequent single-use item | > 3 same category/week | Reusable alternative | Low |
| Peak-week waste | Holiday season forecast | "Stock up on reusable containers" | Low |
| Brand-specific packaging | Same brand appearing repeatedly in waste | "Contact [brand] about packaging" | Medium (brand-specific) |
| Food waste after bulk purchase | Purchase → spoilage pattern | "Buy smaller quantities" | High (purchase detail) |
| Missed collection day | Classification times correlate with missed pickup | "Your collection is Thursday, not Friday" | Low |

---

## Aggregation for RWA/Corporate Partners

Anonymized, aggregated forecasting is the B2B wedge:

```
Block A monthly waste forecast (Aug):
- Dry waste: 320 kg (↑ 8% from Jul — festival season)
- Wet waste: 410 kg (stable)
- Hazardous: 12 kg (↑ 3% — e-waste collection drive)
- Recycling accuracy: 87% (↑ 2% from Jul)
- Forecast: Prepare extra dry waste capacity for Sep (festival season peaks)
```

**Data boundaries**: Never share individual household data. Show only block/floor/wing aggregates at minimum 5 households per bucket.

---

## Kill Criteria

1. **Forecasting**: If simple trend analysis (±30-50% for individual) does not drive any measurable behavior change (reduction in waste per user), skip advanced models.
2. **Procurement feedback**: If click-through on procurement recommendations is < 2% and no user explicitly requests more recommendations, kill procurement feedback.
3. **B2B forecasting**: If no RWA or corporate partner requests forecast data within 6 months of offering it, deprioritize aggregated forecasting.

---

## Concrete Next Steps

1. ✅ Do not build forecasting models yet.
2. Start collecting weekly waste pattern telemetry (existing history data is sufficient).
3. Build a simple dashboard for the team: "Average waste per user by week, category breakdown, holiday spikes."
4. When weekly dashboard shows clear seasonal patterns, prototype per-city forecasting for one metro (Bangalore).
5. Only if a partner (RWA, corporate, school) asks for forecast data, build the aggregated forecasting export.

---

## Research Sources

- EPA WARM model — emission factors per material.
- Eurostat municipal waste generation data — seasonal patterns observed across EU.
- Papalexiou et al. (2020) — waste generation time-series forecasting methods review.
- Indian festival calendar data — public Ical files for Diwali, Holi, Ganesh Chaturthi, Pongal, Onam.
- Google Trends "waste management" seasonality — proxy signal for municipal waste interest cycles.
- OpenWeatherMap API — weather data for stay-at-home vs going-out correlation.
