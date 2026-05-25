# Scrap Rates & Recyclable Value Engine

**Status**: Seed — P2, not yet funded
**Last Updated**: 2026-05-26
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) — Item 76
**Related**: PICKUP_BOOKING_LOGISTICS.md, LOCALITY_COLLECTION_DATA.md, CIVIC_AUTHORITY_SHARING.md

---

## 1. Why This Matters

Knowing "what is this?" is one half of the user's job. Knowing "how much is this worth?" is the other. A scrap-value engine:

- **Incentivises correct sorting**: Users see that mixed/contaminated materials lose value.
- **Bridges to informal recyclers**: Kabadiwalas and scrap dealers use price, not policy — the app must speak that language.
- **Enables pickup booking**: Value estimate drives whether a user schedules a pickup or self-delivers.
- **Differentiates the app**: Most waste apps tell you where it goes. Few tell you what it's worth.

---

## 2. Understanding Scrap Economics

### 2.1 Material Price Drivers

| Material | Volatility | Primary Driver | Household-Level Sensitivity |
|----------|------------|----------------|----------------------------|
| **Metal (steel, aluminium)** | High | Global LME prices | High — price per kg is meaningful ($0.30–1.50/kg) |
| **Copper** | Very high | Global demand + purity | High — $4–8/kg for clean wire |
| **E-waste** | Moderate | Gold/copper yield, component reusability | Low — user doesn't know yield; trust-based |
| **Plastic (#1, #2)** | Moderate | Oil prices, local recycling demand | Low — $0.05–0.15/kg |
| **Mixed plastic** | Low-to-negative | Recycling cost vs virgin resin | Near zero — often not worth collecting |
| **Paper/cardboard** | Moderate | Global pulp prices | Low — $0.02–0.10/kg |
| **Glass** | Low-to-negative | Transport cost vs raw material | Near zero — heavy, low value per kg |

### 2.2 The Kakadiwala Economics

Informal recyclers (kabadiwalas) are the backbone of Indian material recovery. Their model:

- **Buy low** from households (or collect for free).
- **Sort/segregate** (value-add step).
- **Sell higher** to aggregators or specialised recyclers.
- **Trust**: Built on neighbourhood longevity and reliable cash payments.
- **Price setting**: Bottom-up — the kabadiwala knows the selling price and subtracts margin + handling.

**Implication for the app**: The app's value estimate must reflect local kabadiwala buying prices, not global commodity spot prices. A household wants to know "how much will the person on the street pay for this?" not "what's the LME price of aluminium?"

---

## 3. Scrap Value Calculator Design Patterns

### 3.1 Ingestion Methods (Ranked by Feasibility)

| Method | Quality | Effort | Notes |
|--------|---------|--------|-------|
| **Manual input** ⭐ | High | Low | User picks material + estimates weight from dropdown |
| **Photo weight estimation** | Medium | High | CV estimates volume → density lookup table → weight estimate |
| **Barcode lookup** | High (for packaged goods) | Medium | Standardised consumer products (bottles, cans) have known weights |
| **Voice input** | Medium | Medium | "Two kg of newspaper" — voice-to-text → manual weight field |

### 3.2 MVP Design

1. **Static price table**: Admin-curated prices for common materials (newspaper, PET bottles, aluminium cans, cardboard, mixed plastic, e-waste categories).
2. **User-reported verification**: After a scrap sale, user reports the price they received → table refines over time.
3. **Weight input**: Simple slider or number input ("How many kg?") with visual aids ("this is roughly the weight of 10 plastic bottles").

---

## 4. Regional Data Sources

### 4.1 Current Reality (India)
- **No public APIs**: No municipal government APIs for scrap rates (BBMP, BMC, etc.).
- **Private aggregators**: Apps like The Kabadiwala, ScrapMart, iScrap aggregate rates but keep them proprietary.
- **Trade associations**: Some publish periodic rate sheets, but rarely in machine-readable format.

### 4.2 Alternative Approaches
- **Crowdsourced**: Let users report prices received. Requires verification to prevent gaming.
- **Partner-supplied**: Scrap dealer networks or aggregators supply rate feeds in exchange for referral traffic.
- **Manual curation**: Admin updates static rates weekly based on known market movements.

---

## 5. UX Considerations

### 5.1 When to Show Value
- **After classification**: "This is an aluminium can — worth approximately ₹3–5 as scrap."
- **In the disposal facility result**: "Scrap value at [Facility]: ₹3/can."
- **In pickup booking**: "Estimated value of your items: ₹120–150."
- **In impact dashboard**: "You've recycled ₹2,400 worth of materials this year."

### 5.2 Honest Pricing
- Show a **range**, not a fixed price: "₹3–5/kg" rather than "₹4/kg".
- Label the uncertainty source: "Based on last week's local scrap rate."
- When user reports a price, show how it compares: "Other users in your area report ₹3–6/kg."

### 5.3 Material Condition Adjustments
- Clean sorted material = higher value.
- Contaminated/dirty = lower or zero value.
- Mixed materials = lowest value.
- Show the value uplift of proper cleaning and separation.

---

## 6. Minimum Viable Engine

**Phase 1**: Static lookup table + user-reported verification
- Cover top 15 materials by volume (newspaper, PET, aluminium, steel, cardboard, mixed plastic, glass, e-waste categories).
- Admin update frequency: weekly.
- User "price check" feature to report actual received prices.

**Phase 2**: Dynamic rate feeds
- Partner with 1–2 scrap aggregators for rate data.
- Semi-automated price adjustments based on market signals.
- Regional price differentiation (Bangalore vs Mumbai vs Delhi).

**Phase 3**: Predictive pricing
- Use historical data + market signals to forecast near-term price changes.
- "Prices for aluminium have been rising — best to sell this week."
- Requires significant data accumulation.

---

## 7. Kill Criteria

- After 3 months, scrap value feature does not measurably increase classification frequency or sorting correctness.
- User-submitted price data is too noisy/sparse to build a credible price signal.
- Scrap dealers show no interest in partnership.
- Regulatory risk: providing scrap price estimates without a broker license?
