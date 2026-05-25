# Packaging Alternative Recommendations

**Status**: Exploration | P2 | Circular Economy & Pre-Waste Intervention
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) — Entry 51
**Last Updated**: 2026-05-25

---

## Why This Matters

Every time a user scans a hard-to-recycle package, the app has an opportunity: not just "this is hard to recycle," but **"here's what to buy next time instead."** This transforms a moment of frustration into actionable education — and creates a recurring engagement loop between scans.

However, this surface is also the highest-risk greenwashing and trust-erosion zone. Done wrong, it's an ad network with an environmental veneer.

---

## Design Principles

1. **Neutrality first**: Recommendations must prioritise genuine environmental improvement, not affiliate revenue
2. **Evidence-based**: Every claim must cite a source (label standard, municipal rule, independent database)
3. **Opt-in learning**: No product swaps without understanding *why* the current packaging is problematic
4. **User-controlled values**: Let users decide which criteria matter (plastic-free, locally sourced, certified compostable)
5. **Full disclosure**: Any paid/sponsored recommendation is explicitly labelled — no hidden affiliate links

---

## Recommendation Modalities

### 1. Material Comparison (Lowest Trust Risk)

```
Your scan:  Biscuit packet — Plastic #7 (Mixed)
Not recyclable in your city.

Alternative: Parle-G comes in wax-paper packaging
             — recyclable where paper is collected.
             [Why this matters] [Find in stores]
```

- **Trigger**: User scans item with packaging that local rules flag as not recyclable
- **Format**: Direct side-by-side material comparison of the specific product category
- **Trust signal**: Cites the specific city rule and the alternative material's recyclability

### 2. Refill / Bulk-Buy Discovery

- **Map view**: Nearby zero-waste/bulk stores where user can BYO containers
- **Category support**: Which stores accept which container types
- **User verification**: "Is this refill station still active?" Waze-style freshness

### 3. Category-Level Switch Suggestions

- **Trigger**: User scans hard-to-recycle packaging in the same category 3+ times
- **Format**: "You've scanned 3 plastic shampoo bottles this month — here are bars/powder alternatives with less packaging"
- **Tone**: Informational, not promotional

### 4. Brand Feedback Channel

- **"Send feedback to brand"**: One-tap message to manufacturer: "Your packaging is not recyclable in my city"
- **Aggregate signal**: "123 other users in your area flagged this brand's packaging — brands respond to volume"
- **Public pressure**: Optional public report card per brand

---

## Greenwashing Guardrails

| Anti-Pattern | Why It's Dangerous | Guardrail |
|-------------|-------------------|-----------|
| "This alternative is eco-friendly" | Vague, unverifiable | Must cite specific standard (FSC, ASTM D6400, etc.) |
| Sponsored alternative without disclosure | Destroys trust | Explicit "Sponsored recommendation" badge |
| Recommend minor improvement | Better ≠ good — may discourage structural change | Prioritise highest-impact switch per category |
| Rebranding landfill as "circular" | Misleading | Use local rules as ground truth, not marketing claims |
| Pay-for-placement | Compromises recommendation quality | No paid placement in recommendation engine |

---

## Recommendation Quality Scoring

| Dimension | Weight | Data Source |
|-----------|--------|-------------|
| Recyclability improvement | 40% | Local policy engine — recyclable in user's city? |
| Total packaging reduction | 25% | Weight or volume comparison |
| Material toxicity avoidance | 20% | Hazardous materials not present |
| Brand transparency score | 15% | Public brand sustainability reports |

---

## Integration Points

| Surface | What to Show |
|---------|-------------|
| Scan result — non-recyclable | Material comparison card: "Here's a recyclable alternative" |
| Scan result — always recyclable | No alternative — item is good (avoid false improvement) |
| History screen | "Your packaging impact" summary — what you've switched |
| Impact dashboard | "Waste prevented by better choices" |
| Community / challenges | "Refill challenge" — use refill stores 5 times this month |

---

## Data Sources

| Source | Type | Reliability |
|--------|------|-------------|
| Open Food Facts | Open product DB | Medium — community maintained |
| Local policy engine (own) | City-specific rules | High — verified per city |
| User correction data | Crowdsourced | Medium — needs moderation |
| Brand sustainability reports | Self-reported | Low — needs verification |
| EU DPP resolver (future) | Regulatory | High — mandated accuracy |

---

## Open Questions

1. **Monetisation boundary**: Should product recommendations ever be sponsored? If so, how to label without undermining trust?
2. **Coverage**: Will the product DB have enough alternatives in Indian markets (local brands, unbranded goods)?
3. **User values**: Should users configure which criteria matter to them (plastic-free, local, fair trade, certified compostable)?
4. **Anti-spam**: How to prevent brands from astroturfing positive recommendations?
5. **Efficacy measurement**: Does recommending alternatives actually change buying behaviour?

---

## Phasing

| Phase | Scope | Key Risk |
|-------|-------|----------|
| 0 | Material comparison only — no product DB, just "try paper/cardboard alternatives" | Low — generic advice, no data dependency |
| 1 | Product DB integration (Open Food Facts) — specific alternative suggestions for scanned UPCs | Medium — DB coverage in India |
| 2 | Refill/bulk directory launch | Medium — requires facility data freshness |
| 3 | Brand feedback aggregation + public report card | Medium — legal, brand reaction |
| 4 | User-configured value preferences drive recommendations | Low — opt-in |
