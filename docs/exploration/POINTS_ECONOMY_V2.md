# Points Economy v2 — Dual Currency, Sinks, Caps, and Inflation Control

**Decision it unblocks**: Whether to adopt a dual-currency model (Points + Tokens), what sink types to prioritize, daily cap design, and inflation/hoarding prevention strategy for the gamification economy.

**Status**: Active — 2026-05-21  
**Key questions open**: 4 of 8 resolved  
**Kill criteria**: see below  

---

## 1. Why This Exploration

The gamification redesign spec proposes a v2 economy with:
- **Points** — experience/progress currency (earn by scanning, challenges)
- **Tokens** — premium/scarce currency (earn by quality contributions, purchase, rewards)

Before designing earn rates, sink prices, and caps, we need to understand what actually works in production apps — and what causes economy collapse.

---

## 2. Key Research Findings

### 2.1 Dual-Currency Systems in Production Apps

| App | Primary (Soft) | Secondary (Hard) | Separation Logic |
|-----|---------------|-----------------|------------------|
| **Duolingo** | Gems | None (single currency) | Single currency — streak freezes, heart refills, timer boosts all paid in gems |
| **Habitica** | Experience (XP) | Gold + Gems | XP tracks level; Gold buys cosmetics; Gems (premium) buy exclusive items |
| **Nike Run Club** | Miles/Levels | None | Pure progression — no spendable economy |
| **Strava** | Kudos (social) | None | Kudos = engagement signal, not a currency |
| **Candy Crush** | Gold bars | Boosters | Gold = premium for extra lives/boosters |

**Key pattern**: Simpler economies (single currency) correlate with habit apps. Dual-currency systems (soft + hard) are more common in games than utility/habit apps. The risk of dual currency is **cognitive overhead** — users must learn two currencies with different values.

**Implication for our app**: A dual-currency system (Points + Tokens) may be too complex for a utility app where the core loop is "scan → learn → dispose." Consider a **single currency (Points) with spend categories** — points are earned by all actions, but some premium sinks require a high point balance (not a separate currency).

### 2.2 Sink Effectiveness: What Users Actually Spend On

| Sink Type | Example | Engagement Impact | Implementation Cost | Risk |
|-----------|---------|------------------|-------------------|------|
| **Cosmetic** (themes, avatars, badges) | High engagement, infinite capacity | ✅ Medium-high | Low-Medium | Must keep producing new cosmetics |
| **Functional** (streak freezes, extra scans, hints) | Convenience utility | ✅ High (Duolingo streak freeze) | Low | Can break core loop if too valuable |
| **Altruistic** (donate to eco-cause, plant tree) | Emotional satisfaction | ✅ Medium (lower than functional) | Low-Medium | Requires credible donation partner |
| **Progress accelerator** (XP boost, skip levels) | Power-up utility | ✅ High (short-term) | Low | Can devalue progression system |
| **Social recognition** (gift to family, community awards) | Social currency | ✅ Medium (depends on community size) | Medium | Requires active community |
| **Information access** (advanced stats, export) | Utility for power users | 🟡 Medium (niche) | Low | Niche audience |
| **Collectible** (limited-time items, seasonal) | FOMO-driven | ✅ High (episodic engagement) | Medium | Requires content creation pipeline |

**Key insight from Duolingo**: The **Streak Freeze** is the single most effective sink in habit apps. Users will spend currency to *not lose progress* — it's a loss-aversion-based sink that directly protects the core habit.

**Recommendation**: Prioritize sinks in this order:
1. **Streak protection** (functional) — highest value, protects retention
2. **Cosmetics** (themes, result card styles) — infinite demand, no utility pressure
3. **Altruistic** (eco-donations) — mission-aligned, emotional satisfaction
4. **Information** (data export, advanced stats) — power user retention

### 2.3 Daily Caps: Retention Impact

Research on daily earn caps reveals:

| Cap Type | Effect | Risk |
|----------|--------|------|
| **Soft cap** (diminishing returns after X actions) | Encourages daily return, prevents burnout | Users may feel penalized for high activity |
| **Hard cap** (max earn per day) | Clear expectation, prevents hoarding | Power users feel blocked |
| **Streak-protected cap** (cap increases with streak length) | Rewards consistency, mitigates power-user frustration | More complex to implement |

**Production patterns**:
- **Duolingo**: Soft cap on XP via daily quests (3 quests per day = 3× bonus). No hard cap on lesson XP.
- **Habitica**: No daily cap — self-regulated by task availability.
- **Fitness apps**: Typically no caps (you can run as much as you want).

**Recommendation**: **No hard cap on points**. Points measuring effort should never be capped — it punishes your most engaged users. Instead:
- **Soft cap** on bonus points per day (e.g., first 3 scans get 1.5× multiplier)
- **Streak multiplier**: 1× base, bonus per consecutive day (day 1 = 1×, day 7 = 1.25×, day 30 = 1.5×)
- **Sink-driven inflation control**: The economy is balanced by sinks consuming points, not by limiting earn

### 2.4 Inflation and Hoarding Prevention

**Causes of economy collapse**:
1. **Earn rate >> sink rate** → users accumulate points with nothing to spend on → points become worthless
2. **No recurring sinks** → users spend once on cosmetics, then hoard forever
3. **No sunk costs** → no reason to save, no reason to spend

**Proven prevention strategies**:

| Strategy | How It Works | Examples |
|----------|-------------|----------|
| **Recurring functional sinks** | Streak freeze (recurring), challenge entry fees | Duolingo streak freeze |
| **Limited-time sinks** | Seasonal cosmetics, event-only items | Evergreen games |
| **Expiring points** | Season resets (limited use) | Avoid in habit apps — punishing |
| **Tiered cosmetics** | New items unlock at point thresholds, not purchases | Habitica armor tiers |
| **Donation sinks** | Convert points to real-world impact at fixed rate | Tree-planting apps |

**Recommendation**: **No point expiration** — expiring progress points breaks trust in a habit app. Instead, use recurring functional sinks (streak freeze, challenge re-entry) and regular cosmetic drops (themes, badges) to maintain sink velocity.

---

## 3. Proposed Economy Design (Synthesis)

### 3.1 Single Currency with Spend Tiers

```yaml
Currency: Points (singular)

Earn model:
  Base scan: 10 pts
  First scan of day: +5 bonus
  Daily streak maintenance (3 consecutive): ×1.25 multiplier
  Challenge completion: 50-200 pts
  Community contribution (f verified): 25 pts
  Correction submitted: 10 pts

Cap model:
  No hard daily cap
  Bonus multiplier decays after 10 scans/day (soft diminishing)
  Daily challenge bonus pool: 3 challenges per day max

Sinks (prioritized):
  T1 — Streak Freeze (1 day): 100 pts
  T2 — Theme / Card style: 500-2000 pts
  T3 — Eco-donation (verified partner): 1000 pts per unit
  T4 — Data export / advanced stats: 500 pts
  T5 — Custom challenge creation: 300 pts
```

### 3.2 Premium Extension (Optional, No Dual Currency)

If premium monetization is desired, use **real money** not a second currency:
- Streak freeze limit: Free users get 1/week, Premium users get 3/week
- Cosmetic inventory: Premium users get exclusive themes
- No power-ups that affect classification quality

This avoids dual-currency complexity while preserving monetization surface.

### 3.3 Economy Monitoring

Before implementing any economy, establish monitoring:
- **Total points in circulation** (by cohort, by week) — detect inflation
- **Sink velocity** (points spent per user per week) — is it stable?
- **Hoarding rate** (% of users with > 90th percentile balance) — are sinks working?
- **Earn rate** (points per active day per user) — is it within design range?

**Alarm thresholds**:
- Average sink velocity < 1 per user per 7 days → add more recurring sinks
- Hoarding rate > 15% → introduce new cosmetic tier or donation sink
- Points in circulation growing > 10% week over week → review earn rates

---

## 4. Key Open Questions

1. **Should we have a separate "premium" currency at all?** Research suggests single-currency is simpler for habit apps. If we need premium separation, use real-money-gated cosmetics (Pay $X for exclusive theme) rather than a second virtual currency.
2. **What is the right streak freeze price?** Must be affordable enough to use regularly, expensive enough to feel like a choice. Duolingo charges ~200 gems (about 1-2 days of active earning). We need to calibrate after launch data.
3. **Do eco-donations actually motivate users?** Research on altruistic sinks is mixed. Some users love them, others ignore them entirely. Should be T3 priority (build after cosmetic sinks are validated).
4. **What are the anti-farming protections?** If corrections earn points, users may submit spam corrections. Need rate limiting, quality gating, or review before payout.
5. **Should seasonality / events affect the economy?** Holiday-themed cosmetics, double-points weekends, community challenge events — these create sink demand but require content production.

---

## 5. Kill Criteria

- **Sink indifference**: After launch, < 5% of active users engage with any sink within 30 days → the economy adds complexity without value. Revert to pure linear progression.
- **Inflation spiral**: Despite monitoring, average user point balance grows > 50% per month with no corrective action → the economy is broken. Hard-reset while user base is small.
- **Pay-to-win perception**: If functional sinks (streak freeze, boosters) are perceived as necessary to enjoy the app → remove or radically reduce pricing.
- **Dev cost exceeds benefit**: If implementing a full economy (sinks, caps, monitoring, anti-farming) is estimated at > 4 weeks → ship simpler progression (level-based + one cosmetic sink).

---

## 6. Links

- **Parent index**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) — P1 entry #9 (Points sinks and economy separation)
- **Planning spec**: [planning/gamification-points-economy-deep-dive.md](../planning/gamification-points-economy-deep-dive.md)
- **Related**: [MOTIVATION_ARCHETYPES.md](MOTIVATION_ARCHETYPES.md), [NEGATIVE_MECHANICS_AB.md](NEGATIVE_MECHANICS_AB.md)
- **Existing exploration**: [GAMIFICATION_DEPTH.md](GAMIFICATION_DEPTH.md), [HABIT_FORMATION_LOOP.md](HABIT_FORMATION_LOOP.md)
- **Token economy**: [TOKEN_ECONOMY_AND_PRICING_COHERENCE.md](TOKEN_ECONOMY_AND_PRICING_COHERENCE.md)
