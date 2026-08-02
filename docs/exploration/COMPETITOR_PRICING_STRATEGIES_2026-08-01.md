# Competitor Pricing Strategies — ReLoop Monetization Research

> **Date**: August 1, 2026
> **Purpose**: Inform ReLoop's monetization strategy by analyzing competitor pricing models
> **Basis**: Competitor landscape research, web research, existing token economy doc

---

## Executive Summary

Competitor pricing falls into **5 distinct models**: (1) B2B hardware lease/purchase, (2) marketplace commission, (3) enterprise SaaS subscription, (4) freemium consumer apps, and (5) transactional service fees. No competitor combines AI classification + gamification + city-specific policies in a consumer app — ReLoop's pricing model will be novel. The closest analog is Recyclebank's points-to-rewards model, but ReLoop's token economy adds a layer of complexity.

---

## 1. Hardware-Based AI Sorting Pricing

### Oscar Sort (Intuitive AI)

| Attribute | Details |
|-----------|---------|
| **Pricing Model** | B2B enterprise subscription / hardware deployment |
| **Model Type** | Custom enterprise pricing (no public rates) |
| **Contract Terms** | Multi-year contracts typical for hardware deployments |
| **What's Included** | Hardware station, AI software, enterprise dashboard, ongoing support |
| **Target Customer** | Large commercial facilities, universities, transit hubs |
| **Evidence** | No public pricing; custom quotes for enterprise clients |

### CleanRobotics (TrashBot)

| Attribute | Details |
|-----------|---------|
| **Pricing Model** | Zero-down, zero-interest lease program |
| **Model Type** | Hardware lease with monthly payments |
| **Contract Terms** | 36-60 month typical lease terms |
| **What's Included** | TrashBot unit, AI software, maintenance, data dashboard |
| **Target Customer** | Airports, shopping malls, corporate campuses |
| **Evidence** | EPA SBIR grant funding; commercial partnerships (RiverRoad Waste Solutions) |

### AMP Robotics

| Attribute | Details |
|-----------|---------|
| **Pricing Model** | Sortation-as-a-service / pay-per-ton |
| **Model Type** | Recurring revenue based on throughput |
| **Contract Terms** | Enterprise contracts with volume commitments |
| **What's Included** | Robotic sortation system, AI software, maintenance, performance guarantees |
| **Target Customer** | Material recovery facilities, waste management conglomerates |
| **Evidence** | $91M Series D (Dec 2024); partnership with Waste Connections |

---

## 2. B2B Marketplace Commission Pricing

### Recykal (CircularNet)

| Attribute | Details |
|-----------|---------|
| **Pricing Model** | Marketplace commission + enterprise SaaS |
| **Model Type** | Transaction-based commission on marketplace trades |
| **Commission Rate** | Estimated 5-15% per transaction (industry standard for B2B marketplaces) |
| **EPR SaaS** | Separate subscription for compliance dashboards |
| **Target Customer** | Waste aggregators, scrap dealers, brand owners |
| **Evidence** | Asia's largest circular economy marketplace; $10M Series A |

### Rubicon

| Attribute | Details |
|-----------|---------|
| **Pricing Model** | Software platform subscription + hauling marketplace |
| **Model Type** | SaaS subscription + transaction fees on hauling |
| **Contract Terms** | Annual enterprise contracts |
| **What's Included** | Route optimization, cost control, sustainability metrics, technical advisory |
| **Target Customer** | Commercial enterprises, national retail brands, municipalities |
| **Evidence** | $285M+ venture funding; public via $1.7B SPAC (2022) |

---

## 3. Consumer App Pricing Models

### Litterati

| Attribute | Details |
|-----------|---------|
| **Pricing Model** | Freemium |
| **Free Tier** | Photo classification, community challenges, basic data |
| **Premium Tier** | Advanced analytics, enterprise/municipal licensing |
| **Monetization** | Enterprise licensing for municipalities and NGOs |
| **Target Customer** | Eco-conscious individuals (free); municipalities (paid) |

### Scrapp

| Attribute | Details |
|-----------|---------|
| **Pricing Model** | Free app |
| **Free Tier** | AI recycling guidance, barcode scanning, location-based rules |
| **Premium Tier** | None currently |
| **Monetization** | Unknown (likely data or partnerships) |
| **Target Customer** | Eco-conscious consumers in US/Europe |

### JouleBug

| Attribute | Details |
|-----------|---------|
| **Pricing Model** | Free with brand partnerships |
| **Free Tier** | Gamified sustainability challenges, social sharing |
| **Premium Tier** | None currently |
| **Monetization** | Brand sponsorships and partnerships |
| **Target Customer** | Sustainability-conscious consumers |

### Recyclebank

| Attribute | Details |
|-----------|---------|
| **Pricing Model** | Points-to-rewards (B2B2C) |
| **Model Type** | Brands pay Recyclebank; consumers earn points for recycling |
| **Consumer Cost** | Free for consumers |
| **Monetization** | Brand partnerships, retailer rewards programs |
| **Target Consumer** | Households participating in recycling programs |
| **Evidence** | Historical model: points redeemable at partner retailers |

---

## 4. Indian Market Pricing Models

### Aakri (Aakri Impact)

| Attribute | Details |
|-----------|---------|
| **Pricing Model** | Transactional per kg/item |
| **Consumer Cost** | Free app; pay per pickup |
| **Pricing** | Dynamic pricing based on item type and weight |
| **Special Waste** | Premium pricing for biomedical waste (diapers, sanitary napkins) |
| **Target Customer** | Residential households, offices in Kerala |

### ScrapUncle / Attero

| Attribute | Details |
|-----------|---------|
| **Pricing Model** | Free app with commodity resale |
| **Consumer Cost** | Free (consumers get paid for scrap) |
| **Monetization** | Resale of recovered raw materials to recyclers |
| **Pricing** | Instant price quotes based on category and weight |
| **Target Customer** | Urban middle-class households |

---

## 5. ReLoop Token Economy (Existing)

From `TOKEN_ECONOMY_AND_PRICING_COHERENCE.md`:

| Component | Status |
|-----------|--------|
| TokenWallet | Live (balance, daily conversion, analysis speeds) |
| TokenService | Live (spending, earning, daily login bonuses, premium discounts) |
| CostGuardrailService | Live (per-tier caps, daily scan limits) |
| DynamicPricingService | Live (remote config pricing) |
| Enforcement | Disabled by default (kill switch off) |
| Premium Discount | Instant drops from 5 to 2 tokens |

### Core Contradiction
Tokens are displayed in UI but enforcement is disabled. Users see costs while soft-launch operates without penalties.

### Three-Territory Pricing Problem
- **Instant mode**: 5 tokens displayed / 0 actual / 2 for premium
- **Batch mode**: 1 token displayed / 0 actual
- **Premium**: Subscription-based, separate from token ledger

---

## 6. Pricing Strategy Recommendations for ReLoop

### Option 1: Freemium + Token Economy

| Tier | Price | Features |
|------|-------|----------|
| **Free** | ₹0 | 10 classifications/day, basic disposal info, community feed |
| **Pro** | ₹99/month | Unlimited classifications, advanced analytics, priority support |
| **Premium** | ₹299/month | Everything + family sharing, society dashboard, EPR compliance |

**Psychology**: Anchoring (show Premium first), Zero-Price Effect (free tier drives adoption), Mental Accounting ("less than ₹3.3/day").

### Option 2: Freemium + Society Model

| Tier | Price | Features |
|------|-------|----------|
| **Individual Free** | ₹0 | Basic classification, limited history |
| **Individual Pro** | ₹99/month | Unlimited classifications, full history |
| **Society Basic** | ₹499/month | Up to 100 households, society leaderboard, basic analytics |
| **Society Premium** | ₹999/month | Unlimited households, advanced analytics, EPR compliance |

**Psychology**: Network Effects (society adoption drives individual adoption), Switching Costs (society data locked in).

### Option 3: Token Economy (Refined)

| Token Package | Price | Per Token |
|---------------|-------|-----------|
| **Starter** | ₹49 | 50 tokens (₹0.98/token) |
| **Value** | ₹149 | 180 tokens (₹0.83/token) |
| **Premium** | ₹299 | 400 tokens (₹0.75/token) |
| **Subscription** | ₹99/month | 200 tokens/month + 2x earning rate |

**Psychology**: Charm Pricing (₹49, ₹149, ₹299), Rule of 100 (percentage discounts for <₹100), Bundling (subscription + tokens).

---

## 7. Competitive Pricing Comparison

| Company | Model | Consumer Cost | B2B Cost | Revenue Stream |
|---------|-------|---------------|----------|----------------|
| Oscar Sort | Hardware lease | N/A | Custom enterprise | Hardware + SaaS |
| CleanRobotics | Hardware lease | N/A | Zero-down lease | Lease payments |
| AMP Robotics | Pay-per-ton | N/A | Volume-based | Recurring revenue |
| Recykal | Marketplace commission | N/A | 5-15% per trade | Commission + SaaS |
| Rubicon | SaaS subscription | N/A | Annual contracts | Subscription + marketplace |
| Litterati | Freemium | Free | Enterprise licensing | Enterprise deals |
| Scrapp | Free | Free | N/A | Unknown |
| JouleBug | Brand partnerships | Free | N/A | Sponsorships |
| Recyclebank | Points-to-rewards | Free | Brand partnerships | B2B2C |
| Aakri | Transactional | Per pickup | N/A | Transaction fees |
| ScrapUncle | Commodity resale | Free (get paid) | N/A | Resale margin |
| **ReLoop** | **Freemium + tokens** | **₹0-299/month** | **Future** | **Subscription + tokens + B2B** |

---

## Sources

- Oscar Sort: https://www.intuitiveai.com/
- CleanRobotics: https://cleanrobotics.com/
- AMP Robotics: https://ampsortation.com/
- Recykal: https://recykal.com/
- Rubicon: https://www.rubicon.com/
- Litterati: https://litterati.org/
- Scrapp: https://scrappapp.com/
- JouleBug: https://joulebug.com/
- Recyclebank: https://www.recyclebank.com/
- Aakri: https://aakriimpact.com/
- Existing: `docs/exploration/TOKEN_ECONOMY_AND_PRICING_COHERENCE.md`
