# Home Smart-Bin Scale, Compost Monitoring & Fridge Integration — Exploration Doc

**Track**: P3 — Deep Frontier
**Status**: 🟢 Exploration
**Last Updated**: 2026-05-24
**Parent**: [EXPLORATION_TOPICS.md #81](../EXPLORATION_TOPICS.md#81-home-smart-bin-scale--compost--fridge-integration-)
**Sibling topics**: Smart-Bin / QR-Bin (#24 / F5), Disposal Facilities Directory (A20), Pickup Booking (#77), Local Reuse Marketplace (#22)

---

## Decision This Unblocks

Whether to invest in consumer-facing hardware integrations (smart bins, compost sensors, fridge expiry tracking) as a product differentiator — and whether the market is ready for this or it's a solution looking for a problem.

---

## Overview

Three distinct home-hardware integration surfaces exist:

1. **Smart-bin scale**: A bin that weighs disposed items and logs weight per category.
2. **Compost monitoring**: Sensors measuring temperature, moisture, pH, and fill level in a home compost bin.
3. **Fridge integration**: Expiry tracking via smart labels, barcode scanning, or camera-based expiry recognition.

Each has different market readiness, integration complexity, and user value.

---

## 1. Smart-Bin Scale

### Existing Products

| Product | Price | What It Measures | Integration | Status |
|---------|-------|-----------------|-------------|--------|
| GeniCan | $99 | Weight + barcode scan of disposed items | Wi-Fi → proprietary app | Discontinued |
| Simplehuman sensor bin (C series) | $150-300 | Weight only | Bluetooth → Simplehuman app | Active |
| Bintel | $79 (subscription) | Fill level (ultrasonic) | Wi-Fi → Bintel dashboard | Active |
| Pico | Unreleased | Weight + fill level | Kickstarter | Uncertain |
| DIY (ESP8266 + load cell) | $20-30 | Weight only | MQTT/HTTP | Community |

### Assessment

**The smart-bin market has not achieved mass adoption.** GeniCan (Y Combinator, 2015-2020) was the most prominent consumer smart-bin product; it was discontinued. The fundamental problem: **the bin is a multi-user device** — who put what in it is not known from weight alone.

**Viable scope for this app**:

- **Do not build hardware**. Hardware product development is a different discipline (supply chain, returns, FCC/CE compliance, warranty).
- **Do not require hardware**. The app should work fully without any smart bin.
- **Weight estimation from classification** is more reliable: if we know a user classified 3 plastic bottles, 2 cans, and 1 newspaper today, we estimate weight from average item weights (plastic bottle ≈ 30g, can ≈ 15g, newspaper ≈ 100g). No hardware needed.

### Weight Estimation from Classification (No Hardware)

```dart
// Estimated item weights in grams (EPA averages)
const Map<String, double> averageItemWeight = {
  'plastic_bottle_500ml': 30.0,
  'aluminum_can_330ml': 14.5,
  'newspaper': 100.0,
  'cardboard_box_small': 50.0,
  'glass_bottle_500ml': 300.0,
  'tetra_pak_200ml': 25.0,
  'food_waste_per_item': 200.0, // rough per-disposal
};
```

**Accuracy**: ±30-50% per item, but cancels out at household-week aggregate. Sufficient for "Your household generated 2.3 kg of waste this week" — the primary use case.

---

## 2. Compost Monitoring

### Existing Products

| Product | Price | What It Measures | App |
|---------|-------|-----------------|-----|
| PlantLink | $59 | Moisture + temp only | PlantLink |
| Xiaomi MiFlora | $20 | Moisture, temp, light, fertility | Mi Home |
| LaskaKit compost sensor | DIY €25 | Temp, moisture (deep insert) | MQTT |
| Commercial compost probes | $200+ | Temp, O2, CO2, CH4, pH | Various |

### Assessment

**Compost monitoring is niche within a niche.** Users who actively monitor compost temperature are the < 5% of composters who use smart sensors. The vast majority compost by "look and smell."

**Viable scope**:

- **Minimum viable**: A "compost readiness checklist" in the app (text-based guide). "Is it brown enough? Does it smell? Is it warm? Turn it if > 140°F.")
- **Intermediate**: Photo-based compost quality check (upload a photo of compost, model estimates maturity/stage).
- **Advanced**: Integration with existing smart sensor APIs (read MiFlora sensor → display temp/moisture in app).

**Recommendation**: Text-based guide now. Photo assessment when image classification pipeline matures. Skip sensor integration.

---

## 3. Fridge Integration / Expiry Tracking

### Existing Products

| Product | Approach | Users | Status |
|---------|----------|-------|--------|
| NoWaste | Manual entry + barcode scan | ~1M+ | ✅ Active |
| Fridge Pal | Manual entry by receipt photo | ~500K+ | ✅ Active |
| Samsung Family Hub | Built-in fridge camera | Hardware owners only | ✅ Active |
| LG InstaView | Built-in camera | Hardware owners only | ✅ Active |
| Amazon Dash Wand | Barcode scanner + Alexa | Discontinued | ❌ Killed |

### Assessment

**Fridge integration has the highest user value** of the three categories — food waste is the largest component of household waste by weight (per EPA, ~24% of municipal waste).

**Key insight**: The fridge tracking space is occupied by dedicated apps (NoWaste) that haven't achieved breakout success. The value is real but intermittent — users update the inventory when they buy groceries, then forget about it.

**Viable integration for this app**:

- **After classification**: If a user classifies food waste, prompt "Would you like to log this item's expiry date so we can remind you before it spoils?"
- **Barcode or expiry-OCR pipeline**: Use the existing classification camera pipeline to detect expiry dates on food packaging.
- **Minimal fridge mode**: Simple "add item → set expiry → get reminder" surface. Doesn't need a full inventory system.
- **Shared household fridge**: Tie into family mode (#64) — all family members can see the shared fridge status.

### Opportunity: Expiry Detection at Classification Time

When a user scans a food item for disposal, the app could also:

1. Detect the expiry date if readable on the packaging (OCR from classification image).
2. Ask: "This item expired on [date]. Do you want to track expiry dates for future purchases?"
3. If yes, add barcode-based expiry tracking.

**Privacy must be explicit**: Fridge inventory is highly personal. Never share or sync without clear consent per item type.

---

## Recommended Path

| Phase | Feature | Effort | Hardware | 
|-------|---------|--------|----------|
| Phase 1 (Now) | Weight estimation from classification counts | 2-3 days | None |
| Phase 1 (Now) | Compost readiness guide (text) | 1 day | None |
| Phase 2 (Next) | Expiry date OCR on food classification images | 1-2 weeks | None |
| Phase 2 (Next) | Barcode-based pantry tracking (minimal) | 1-2 weeks | None |
| Phase 3 (Deferred) | Photo-based compost quality check | 1-2 weeks | None |
| Phase 4 (Frontier) | Smart-bin scale API integration | 2-4 weeks | Partner product |
| Phase 4 (Frontier) | Fridge camera/API integration | 2-4 weeks | Partner product |

---

## Kill Criteria

1. **Weight estimation**: If users never click "See your weekly waste weight" after implementation, kill weight feature.
2. **Compost**: If < 1% of users access the compost guide and < 10% of those return, kill compost features.
3. **Fridge tracking**: If pantry item creation rate is < 0.5 items per active user per week after 4 weeks, kill fridge tracking.
4. **Hardware integrations**: Do not start any hardware integration without a confirmed partner pilot (a smart-bin company wanting integration).

---

## Concrete Next Steps

1. ✅ Do not invest in hardware.
2. ✅ Weight estimation from classification counts — trivial to implement (avg item weight table + sum).
3. Add compost section to education content (text-only checklist).
4. Monitor classification rate of food items — if it exceeds 25% of all classifications, prioritize expiry-OCR pipeline.
5. If family mode (#64) ships, add shared pantry as a future tie-in.

---

## Research Sources

- GeniCan post-mortem analyses (consumer smart-bin market failure lessons).
- Simplehuman SDK documentation (Bluetooth weight integration available).
- NoWaste app store reviews (fridge tracking UX strengths and gaps).
- EPA factsheet: "Food: Material-Specific Data" (food waste is 24% of landfill by weight).
- Xiaomi MiFlora BLE protocol — existing reverse-engineered API for compost/plant sensors.
