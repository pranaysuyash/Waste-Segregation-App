# Ads & Revenue Diversification

**Status**: Exploration doc
**Last Updated**: 2026-05-25
**Category**: Business & Growth
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md#a17-ads--revenue-diversification-)
**Related**: Token Economy (#27a), Monetization & Pricing Tiers (#28), Premium/Gamification Intersection

---

## Why This Is a Topic

Ads are revenue *and* a tax on UX. For a sustainability/education app, the trust cost of ads is higher than for entertainment apps — users who download a waste segregation app are likely to be sensitive to commercial messaging that contradicts the app's mission.

The current decision to include AdMob is implicit (not product-designed). The format mix, surface placement, and brand-safety posture are all open questions that affect both revenue and retention.

---

## Key Questions

1. **Format mix** — what ad formats belong in a sustainability app?
2. **Ad surfaces** — where can ads appear without undermining trust?
3. **Rewarded ads** — should the app offer "watch an ad, get a token/scan" as a Duolingo-style option?
4. **Ad-free zones** — which surfaces must never show ads (kid mode, classroom, education, result screen)?
5. **Brand safety** — how to prevent contradictory or misaligned ads from appearing?
6. **Premium interaction** — is "remove ads" the primary premium value proposition, or a secondary one?
7. **Ad network choice** — AdMob vs alternatives for <100k MAU?
8. **Impact on retention** — do ads measurably hurt Day-1 / Day-7 retention?

---

## Research Summary

### Format Trade-offs

| Format | Revenue | UX Risk | Fit for Sustainability App |
|--------|---------|---------|---------------------------|
| Banner | Low | High — clutters screen, looks cheap | Bad — avoid on main screens |
| Interstitial | Medium | High — interrupts flow, especially at success moment | Conditional — only during natural breaks, never after a scan result |
| Rewarded video | Medium-High | Low — user chooses to engage | **Best fit** — aligns with token economy, feels fair |
| Native | Medium | Low — blends into content | Good — sponsored tips, partner recommendations |

**Recommendation**: Rewarded video + native ads only. No banners. Interstitials only between sessions (never mid-flow).

### Ad-Free Zones

These must be 100% ad-free:
- **Scan result screen** — the moment of classification is sacred; no ad should interrupt this
- **Educational content** — learning modules, disposal guides, quiz screens
- **Kid mode** — COPPA / GDPR-K compliance
- **Classroom mode** — B2B customer expectation
- **Onboarding** — first-scan flow

### Rewarded Ads & Token Economy

The Duolingo model maps well here: "Watch a short ad to earn 1 token" or "Get an extra scan credit."

This creates a voluntary ad experience — users choose to engage when they want an extra boost rather than being interrupted. It also gives free users a path to premium-like features without paying, which can actually increase overall engagement.

**Design**: after a successful scan, offer a small banner option: "Need an extra scan? Watch an ad → get 1 token." Never interrupt the result to offer this.

### Brand Safety

For a sustainability/waste app, the following brand categories should be blocked or carefully reviewed:
- Single-use plastic products
- Fast fashion
- Airlines/cruises (high-carbon travel)
- Gambling / alcohol
- Cryptocurrency (unless green-proof-of-stake)
- Non-sustainable packaged goods

**Implementation**: Use AdMob category exclusions + managed placement whitelist if scale justifies it. Maintain a blocklist that grows with user reports.

### Premium Interaction

"Remove ads" should be a premium feature, but it should not be the *primary* premium value proposition. The primary should be quality-of-life features (offline mode, advanced impact stats, family sharing). Ad removal is the secondary, table-stakes premium benefit.

### Network Choice

For <100k MAU:
- **Start with AdMob** — simplest integration, high fill rates, built-in mediation
- **Add mediation** (AdMob Mediation or AppLovin MAX) when fill rate drops below 80% or eCPM needs improvement
- **Avoid** direct-sold ads until >500k MAU — unsold inventory will depress revenue

### Retention Impact

The research is clear: intrusive ads are a leading cause of churn in habit apps. Key metrics to watch:
- Day-1 retention: if this drops after ad format is introduced, format is too aggressive
- Session duration: if ads cause sessions to shorten, they're interrupting flow
- Premium conversion: if ad-avoidance drives premium purchase, the ad experience may be working *correctly* (users paying to remove pain)

---

## Design Recommendations

### Ad Surface Map

| Screen | Ad Type | Frequency | Notes |
|--------|---------|-----------|-------|
| Home screen | Native card (promoted tip) | Once per session, dismissible | "Sustainable product tip from [partner]" |
| Post-scan summary | Small rewarded banner | Once per scan session | "Watch ad → +1 token" |
| History list | Native card between items | Every 10 items | Low-interruption |
| Settings | None | — | Trust surface |
| Education | None | — | Ad-free zone |
| Result screen | None | — | Ad-free zone |
| Onboarding | None | — | Ad-free zone |
| Kid/Classroom mode | None | — | Policy compliance |

### Implementation Path

1. Audit current AdMob integration — which surfaces currently show ads?
2. Define ad-free zone enforcement in `AdService` with mode-aware gating
3. Implement rewarded video ad unit for token rewards
4. Implement native ad unit for home screen tip card
5. Add brand safety category blocklist
6. A/B test ad formats against retention (control = no ads, variant = current ad strategy)
7. Track eCPM, fill rate, and revenue per user

### Kill Criteria

- If ad revenue < $100/month at 10k MAU, the engineering and UX cost of ads outweighs the revenue — consider removing ads and going premium-only
- If Day-7 retention drops >5pp in any A/B test with ads vs without, the ad strategy needs fundamental redesign

---

## Open Questions

- Should rewarded ads offer tokens or scan credits? (Tokens are more flexible but easier to inflation-spiral.)
- Can native ads be sourced from eco-friendly brands through direct partnerships rather than programmatic networks?
- Is there an ethical conflict in showing any ads in a waste-sustainability product, even if brand-safe?
