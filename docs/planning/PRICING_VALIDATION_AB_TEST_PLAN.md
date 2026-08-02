# Pricing Validation A/B Test Plan — ReLoop

> **Date**: August 1, 2026
> **Purpose**: Validate willingness-to-pay before scaling token enforcement
> **Basis**: `docs/exploration/COMPETITOR_PRICING_STRATEGIES_2026-08-01.md`
> **Status**: Plan (not yet executed)

---

## Executive Summary

ReLoop's token economy is architecturally complete but commercially unvalidated. Enforcement is disabled (kill switch off), and pricing has never been tested with real users. This A/B test plan validates three pricing models against real user behavior to determine the optimal monetization strategy before scaling.

**Goal**: Validate willingness-to-pay for 100+ users per variant within 90 days of soft-launch.

---

## Background

### Current State (Phase 0)

| Component | Status | Notes |
|-----------|--------|-------|
| TokenWallet | Live | 50 welcome bonus, balance tracking |
| TokenService | Live | Earning, spending, daily login bonuses |
| DynamicPricingService | Live | Remote config pricing, budget tracking |
| CostGuardrailService | Live | Per-tier caps, daily scan limits |
| Enforcement | **OFF** | Kill switch disabled, tokens displayed but not enforced |
| Premium Discount | Live | Instant drops from 5 to 2 tokens |

### Core Contradiction

Users see token costs in the UI but are never actually charged. This creates a false sense of the pricing model's viability. **We cannot validate monetization until enforcement is enabled.**

---

## Test Variants

### Variant A: Freemium + Token Economy

| Tier | Price | Features |
|------|-------|----------|
| **Free** | ₹0 | 10 classifications/day, basic disposal info, community feed |
| **Pro** | ₹99/month | Unlimited classifications, advanced analytics, priority support |
| **Premium** | ₹299/month | Everything + family sharing, society dashboard, EPR compliance |

**Psychology**: Anchoring (show Premium first), Zero-Price Effect (free tier drives adoption), Mental Accounting ("less than ₹3.3/day").

**Token Costs**:
- Batch analysis: 1 token
- Instant analysis: 5 tokens
- Premium instant: 2 tokens (50% discount)

**Hypothesis**: Subscription model provides predictable revenue; token costs create urgency for upgrades.

### Variant B: Freemium + Society Model

| Tier | Price | Features |
|------|-------|----------|
| **Individual Free** | ₹0 | Basic classification, limited history |
| **Individual Pro** | ₹99/month | Unlimited classifications, full history |
| **Society Basic** | ₹499/month | Up to 100 households, society leaderboard, basic analytics |
| **Society Premium** | ₹999/month | Unlimited households, advanced analytics, EPR compliance |

**Psychology**: Network Effects (society adoption drives individual adoption), Switching Costs (society data locked in).

> **Market Validation Note**: ₹499-999/month for society tiers is preliminary. Indian apartment societies typically spend ₹2,000-5,000/month total on maintenance (security, cleaning, repairs). Waste management as a line item would need to fit within this budget. Consider testing lower price points (₹299/month) if conversion is low.

**Token Costs**: Same as Variant A (1 token batch, 5 tokens instant, 2 tokens premium instant).

**Hypothesis**: Society-level subscriptions create higher switching costs and LTV; individual users adopt because their society adopted.

### Variant C: Token Economy (Refined)

| Token Package | Price | Per Token |
|---------------|-------|-----------|
| **Starter** | ₹49 | 50 tokens (₹0.98/token) |
| **Value** | ₹149 | 180 tokens (₹0.83/token) |
| **Premium** | ₹299 | 400 tokens (₹0.75/token) |
| **Subscription** | ₹99/month | 200 tokens/month + 2x earning rate |

**Psychology**: Charm Pricing (₹49, ₹149, ₹299), Rule of 100 (percentage discounts for <₹100), Bundling (subscription + tokens).

**Token Costs**: Same as Variant A (1 token batch, 5 tokens instant).

**Hypothesis**: Pay-per-use model aligns costs with value; subscription provides baseline revenue.

---

## Test Design

### Population

| Attribute | Value |
|-----------|-------|
| **Target Users** | Active users (≥5 classifications in last 7 days) |
| **Minimum Sample** | 100 users per variant (300 total) |
| **Maximum Duration** | 90 days |
| **Geography** | India (all cities) |
| **Exclusions** | Beta testers, internal team, users <18 years |

### Assignment

| Method | Details |
|--------|---------|
| **Randomization** | User ID hash (deterministic, reproducible) |
| **Assignment Layer** | User-level (not session-level) |
| **Holdback** | 10% control group (no pricing shown, enforcement off) |
| **Stratification** | By city (BBMP, BMC, MCD, others) to ensure balanced distribution |

### Metrics

#### Primary Metrics

| Metric | Definition | Target |
|--------|-----------|--------|
| **Conversion Rate** | % of users who make first purchase | ≥5% |
| **Revenue Per User (ARPU)** | Total revenue / total users in variant | ≥₹10/month |
| **Token Utilization** | % of available tokens spent per user | ≥30% |

#### Secondary Metrics

| Metric | Definition | Target |
|--------|-----------|--------|
| **Retention (D7)** | % of users active 7 days after first purchase | ≥60% |
| **Retention (D30)** | % of users active 30 days after first purchase | ≥40% |
| **Upgrade Rate** | % of Free users who upgrade to paid tier | ≥3% |
| **Churn Rate** | % of paid users who cancel within 30 days | ≤15% |
| **Classification Volume** | Avg classifications per user per day | ≥3 |

#### Guardrail Metrics

| Metric | Definition | Threshold |
|--------|-----------|-----------|
| **7-Day Active Retention** | % of users active 7 days after pricing exposure | ≥70% (proxy for uninstall rate; mobile apps don't reliably track uninstalls) |
| **Token Depletion Rate** | Avg days until user runs out of tokens (leading indicator of churn) | ≥7 days |
| **Support Tickets** | Pricing-related complaints per 1000 users | ≤10 |
| **App Store Rating** | Average rating during test period | ≥4.0 |

---

## Implementation Plan

### Phase 1: Preparation (Weeks 1-2)

| Task | Owner | Status |
|------|-------|--------|
| Enable token enforcement (kill switch ON) | Engineering | ⏳ |
| Implement A/B test framework (Firebase Remote Config) | Engineering | ⏳ |
| Create pricing UI screens for each variant | Design | ⏳ |
| Set up analytics tracking for pricing events | Analytics | ⏳ |
| Define user eligibility criteria | Product | ⏳ |
| Create control group (10% holdback) | Engineering | ⏳ |

### Phase 2: Soft Launch (Weeks 3-4)

| Task | Owner | Status |
|------|-------|--------|
| Deploy to 10% of users (100 per variant) | Engineering | ⏳ |
| Monitor guardrail metrics daily | Analytics | ⏳ |
| Collect qualitative feedback (in-app survey) | Product | ⏳ |
| Fix any critical issues | Engineering | ⏳ |

### Phase 3: Full Rollout (Weeks 5-12)

| Task | Owner | Status |
|------|-------|--------|
| Expand to 100% of eligible users | Engineering | ⏳ |
| Run statistical significance tests weekly | Analytics | ⏳ |
| Analyze conversion funnels per variant | Product | ⏳ |
| Document learnings | Product | ⏳ |

### Phase 4: Decision (Week 13)

| Task | Owner | Status |
|------|-------|--------|
| Statistical analysis of all variants | Analytics | ⏳ |
| Stakeholder presentation | Product | ⏳ |
| Go/no-go decision on scaling enforcement | Leadership | ⏳ |
| Document final pricing strategy | Product | ⏳ |

---

## Payment Gateway Integration

| Gateway | Support | Notes |
|---------|---------|-------|
| **Razorpay** | ✅ Recommended | UPI, cards, wallets; sandbox available; Indian-focused |
| **PhonePe** | ✅ Alternative | UPI-first; good adoption in India |
| **Google Pay** | ⚠️ Limited | No subscription support; one-time payments only |

**Failed Payment Handling**:
- Retry 3 times with exponential backoff
- Grace period: 7 days before downgrading tier
- Notify user via push notification + email
- Log failure reason for analytics

---

## Cohort Analysis Plan

| Cohort | Definition | Analysis Window |
|--------|------------|-----------------|
| **Early Adopters** | Users who saw pricing in Weeks 3-4 | Full 90-day analysis |
| **Mid-Test** | Users who joined in Weeks 5-8 | 60-day analysis |
| **Late-Test** | Users who joined in Weeks 9-12 | 30-day analysis |

**Rationale**: Mid-test and late-test cohorts may behave differently due to network effects (more societies adopting) or seasonal factors. Analyzing by cohort provides cleaner signals than mixing all users together.

---

## Technical Implementation

### A/B Test Configuration

```json
{
  "pricing_ab_test": {
    "enabled": true,
    "variants": {
      "control": {
        "weight": 10,
        "enforcement": false,
        "ui_shown": false
      },
      "variant_a": {
        "weight": 30,
        "model": "freemium_tokens",
        "tiers": ["free", "pro_99", "premium_299"],
        "enforcement": true
      },
      "variant_b": {
        "weight": 30,
        "model": "freemium_society",
        "tiers": ["individual_free", "individual_pro_99", "society_basic_499", "society_premium_999"],
        "enforcement": true
      },
      "variant_c": {
        "weight": 30,
        "model": "token_packages",
        "packages": ["starter_49", "value_149", "premium_299", "subscription_99"],
        "enforcement": true
      }
    }
  }
}
```

### Event Tracking

| Event | Parameters | Purpose |
|-------|-----------|---------|
| `pricing_screen_viewed` | variant, tier_shown | Track pricing exposure |
| `pricing_tier_selected` | variant, tier, price | Track tier selection |
| `purchase_initiated` | variant, tier, price, payment_method | Track purchase intent |
| `purchase_completed` | variant, tier, price, revenue | Track conversion |
| `purchase_failed` | variant, tier, error_reason | Track friction points |
| `token_spent` | variant, speed, cost, balance_after | Track token utilization |
| `subscription_cancelled` | variant, tier, tenure_days | Track churn |
| `upgrade_initiated` | variant, from_tier, to_tier | Track upgrades |

### Remote Config Rules

```dart
// Pricing variant assignment
String getPricingVariant(String userId) {
  final hash = userId.hashCode % 100;
  if (hash < 10) return 'control';
  if (hash < 40) return 'variant_a';
  if (hash < 70) return 'variant_b';
  return 'variant_c';
}
```

---

## Statistical Analysis

### Sample Size Calculation

| Parameter | Value |
|-----------|-------|
| **Baseline Conversion Rate** | 2% (industry average for freemium apps; ReLoop has no historical data) |
| **Minimum Detectable Effect** | 3% (absolute) |
| **Significance Level (α)** | 0.05 |
| **Power (1-β)** | 0.80 |
| **Required Sample Size** | ~100 per variant |

> **Note**: Since ReLoop has no historical pricing data, consider running a Bayesian analysis that doesn't require a fixed baseline. The 2% baseline is a conservative estimate based on industry averages for freemium apps in the sustainability/education space.

### Sample Size Contingency

| Scenario | Action |
|----------|--------|
| **100 users per variant not achievable in 90 days** | Extend test to 120 days; lower MDE to 2% (requires ~200 per variant) |
| **Insufficient traffic** | Consider geographic rollout (start with BBMP only, then expand) |
| **High variance between variants** | Switch to Bayesian analysis (no fixed sample size required) |

### Interim Analysis Rules

| Condition | Action |
|-----------|--------|
| **One variant clearly wins (p < 0.01 at 50% sample)** | Consider early stopping; require stakeholder approval |
| **All variants performing poorly (<1% conversion)** | Pause test; investigate pricing UI/UX issues |
| **Guardrail metric breached** | Immediate rollback; investigate root cause |

### Analysis Methods

| Analysis | Method | When |
|----------|--------|------|
| **Conversion Rate** | Chi-squared test | Weekly |
| **Revenue Per User** | Welch's t-test | Weekly |
| **Retention** | Kaplan-Meier survival analysis | At D30 |
| **Churn** | Cox proportional hazards | At D30 |
| **Multi-metric** | Bonferroni correction | Final analysis |

### Decision Criteria

| Outcome | Action |
|---------|--------|
| **Variant A wins** | Scale Freemium + Token Economy; deprecate token packages |
| **Variant B wins** | Scale Freemium + Society Model; prioritize society features |
| **Variant C wins** | Scale Token Economy (Refined); simplify to packages only |
| **No significant difference** | Choose based on secondary metrics (retention, LTV) |
| **All variants fail** | Revisit pricing research; consider free-only model with B2B monetization |

---

## Risk Mitigation

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Low sample size | Medium | High | Extend test duration; lower MDE threshold |
| User backlash from enforcement | Medium | High | Rollback kill switch within 24 hours |
| Payment gateway issues | Low | High | Test with sandbox first; have fallback |
| Statistical noise | Medium | Medium | Run for full 90 days; use Bayesian analysis |
| Cannibalization between variants | Low | Medium | Ensure variants are mutually exclusive |

---

## Success Criteria

### Minimum Viable Validation

| Criterion | Threshold |
|-----------|-----------|
| Sample size achieved | ≥100 per variant |
| Test duration | ≥30 days |
| Statistical significance | p < 0.05 for at least one variant |
| Guardrail metrics | All within thresholds |

### Optimal Validation

| Criterion | Threshold |
|-----------|-----------|
| Conversion rate | ≥5% in winning variant |
| ARPU | ≥₹10/month in winning variant |
| Retention D30 | ≥40% in winning variant |
| Churn rate | ≤15% in winning variant |

---

## Timeline

```
Week 1-2:   Preparation (enable enforcement, implement A/B framework)
Week 3-4:   Soft launch (10% rollout, 100 users per variant)
Week 5-8:   Full rollout (100% eligible users)
Week 9-12:  Data collection and analysis
Week 13:    Decision and documentation
```

---

## Ethical Considerations

| Concern | Mitigation |
|---------|------------|
| **Informed consent** | Users must acknowledge they're in a pricing test before first purchase |
| **Refund policy** | Full refund within 7 days of first purchase; no questions asked |
| **Low-income exclusion** | No income-based exclusion; all users see same pricing; use tiered pricing to ensure accessibility |
| **Pricing fairness** | Monitor for complaints about unfair pricing; adjust if needed |
| **Data privacy** | All pricing data anonymized; no PII shared with third parties |

---

## Cross-References

- **Pricing Research**: `docs/exploration/COMPETITOR_PRICING_STRATEGIES_2026-08-01.md`
- **Token Economy**: `docs/exploration/TOKEN_ECONOMY_AND_PRICING_COHERENCE.md`
- **SWOT Analysis**: `docs/exploration/RELOOP_SWOT_ANALYSIS_2026-08-01.md`
- **Domain Model**: `docs/exploration/DOMAIN_MODEL_RELATIONSHIPS.md`
- **Code**: `lib/services/token_service.dart`, `lib/services/dynamic_pricing_service.dart`, `lib/services/cost_guardrail_service.dart`
