# Deposit-Return & Refund Systems

**Status**: Exploration | P2 | Circular Economy & Pre-Waste Intervention
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) — Entry 52
**Last Updated**: 2026-05-25

---

## Why This Matters

Deposit Return Systems (DRS) are one of the most effective policy instruments for beverage container recovery (Germany: 98% return rate). As more jurisdictions mandate DRS and as Digital DRS (app-based) emerges, the app has a natural role: **being the consumer's DRS interface** — identifying eligible containers, locating return points, tracking refunds, and reconciling a recycling wallet.

In India, EPR-based e-waste rules and informal scrap-value systems create a parallel opportunity: the app can bridge formal DRS and informal recycler economics.

---

## Global DRS Landscape

| Market | DRS Status | Container Types | Refund Value | Digital Ready? |
|--------|-----------|----------------|--------------|----------------|
| Germany (Pfand) | Mature | Plastic, glass, cans | €0.08-0.25 | Partial (store loyalty apps) |
| Norway | Mature | Plastic, metal | NOK 1-3 | Emerging |
| US bottle bill states | Existing | Plastic, glass | $0.05-0.10 | Legacy — RVM-dependent |
| EU (mandate) | Rolling out 2026-2029 | Beverage containers | TBD per state | Aiming for Digital DRS |
| India (E-Waste Rules) | EPR-based | Electronics only | Scrap-value based | Informal — no standard |
| India (Plastic) | Emerging discussions | PET bottles | TBD | Opportunity to define |

---

## Core Feature Set

### 1. DRS Eligibility Check

- **Input**: Barcode scan of container
- **Output**: Is this item part of an active DRS in the user's region?
- **Data source**: DRS registry API or curated database
- **Secondary**: Refund value display (per container type and material)

### 2. Return Point Locator

- **Map view**: Nearest RVMs or manual redemption centres
- **Status**: "Machine full" / "Maintenance" / "Open 8 AM-10 PM" (crowdsourced)
- **Directions**: Integration with Google Maps / Apple Maps

### 3. Digital Verification

Two emerging patterns:

| Pattern | How It Works | Maturity |
|---------|-------------|----------|
| Receipt scan | User scans RVM-issued paper voucher → app digitzes credit | Live (Lidl, SPAR apps) |
| QR-linked account | User scans QR at RVM → refund auto-deposits to app wallet | Live (Europe) |
| Serialized container QR | Each container has unique ID → scan before disposal → credit on return | Prototype (Digital DRS) |

### 4. Recycling Wallet

- **Balance**: Aggregated refunds from multiple return trips
- **History**: Transaction log (item, date, location, amount)
- **Payout options**: Store credit, bank transfer, UPI, charity donation, token conversion
- **Pending reconciliation**: "You returned 15 bottles — 12 verified, 3 pending review"

### 5. E-Waste & Scrap Value (India)

- **Dynamic scrap rates**: Current market prices for paper, metal, e-waste categories
- **Nearest kabadiwala/informal recycler**: Estimated value for the scanned item
- **Compare options**: "Dispose at municipal drop-off (free) vs sell to kabadiwala (Rs. 5-10/unit)"

---

## UX Flow

```
1. User scans container
   │
   ├─ DRS registered? → Show refund value + nearest return point
   │
   ├─ Scrap value (India)? → Show estimated value + nearest buyer
   │
   └─ Neither → "This item has no deposit value. Dispose normally."

2. At RVM → Scan receipt or QR → Credit to wallet

3. Wallet → View balance → Choose payout
```

---

## Trust & Anti-Fraud

| Attack Vector | Mitigation |
|--------------|------------|
| False receipt scan | Receipt format verification, max daily scans, photo + location |
| Duplicate claim on same container | Barcode + timestamp dedup, serialized QR where available |
| Fake RVM location | Verified by user check-ins, moderator review of new listings |
| Wallet balance manipulation | Server-authoritative ledger, no client-side balance overrides |
| Cross-border fraud (claim deposit in two countries) | Region-enforced wallet (one active region at a time) |

---

## Integration Points

| Surface | What to Show |
|---------|-------------|
| Scan result — beverage container | "This bottle has a Rs. 2 deposit — nearest return: 200m" |
| Scan result — e-waste | "Estimated scrap value: Rs. 50 — find a buyer" |
| Home screen wallet widget | "Recycling balance: Rs. 85 — withdraw or donate" |
| History screen | "Your recycling wallet" transaction log |
| Impact dashboard | "Value recovered: Rs. 340 total — equivalent to 170 bottles" |

---

## Open Questions

1. **DRS coverage**: How many Indian states have active DRS for beverage containers? Is this useful enough to warrant the integration?
2. **E-Waste EPR**: Can we integrate with Indian EPR portals for manufacturer take-back programs?
3. **Scrap data freshness**: Scrap rates fluctuate daily — what's the data pipeline for current prices?
4. **Regulatory risk**: Are there legal constraints on aggregating deposit refunds as an app intermediary?
5. **Wallet economics**: Does the app take a fee on wallet payouts, or is this a value-add feature?

---

## Phasing

| Phase | Scope | Key Dependency |
|-------|-------|----------------|
| 0 | Informational — barcode DRS check + return point map | DRS database per region |
| 1 | Receipt scan → wallet credit | Receipt OCR, server-authoritative ledger |
| 2 | QR-linked account integration (where available) | RVM partner agreements |
| 3 | Scrap rate engine for non-DRS markets | Scrap price data pipeline |
| 4 | Full wallet → payout (donation, token, bank) | Payment gateway, regulatory compliance |
