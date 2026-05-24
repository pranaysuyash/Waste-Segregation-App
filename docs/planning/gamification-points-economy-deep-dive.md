# Points Economy — Deep Dive

**Status**: Deep-dive spec  
**Parent**: [Gamification Redesign Spec](gamification-redesign-spec.md) §4 (v2 Points System) and §8 (Points Economy & Sinks)  
**Purpose**: Concrete economic model — earn rates, sink costs, budget projections, inflation guardrails, and dual-currency separation  
**Date**: 2026-05-23  
**Sources**: MMO economy design patterns, Duolingo dual-currency system, Strava social economy, behavioral economics (loss aversion, endowment effect, mental accounting)

---

## 1. Economic Model Overview

### 1.1 Core Principles

1. **Perceived scarcity**: Points must feel earned, not given. Users should naturally spend faster than they earn at high engagement levels.
2. **Invisible guardrails**: The economy self-regulates through progressive sink costs, diminishing returns, and time-gated earn caps — no visible inflation-fighting mechanics.
3. **Sink > Earn at ceiling**: At maximum engagement, total sink costs should slightly exceed total earn rates, forcing trade-off decisions between sinks.
4. **Dual separation**: Points (engagement) and Tokens (AI usage metering) are separate ledgers. The current runtime includes a general points-to-tokens conversion path with a daily cap; if we later want event-only crossover, that should be an explicit product restriction instead of an implied assumption.

### 1.2 Dual-Currency Contract

| Currency | Purpose | Earned Via | Spent On | Storage |
|----------|---------|-----------|----------|---------|
| **Points** | Engagement, achievement, community | Classifications (quality-scaled), corrections, education, streaks, challenges, community contributions | Eco-impact, cosmetics, streak protection, custom challenges | GamificationProfile.points |
| **Tokens** | AI usage metering, premium | Daily login (2/day), purchase, special event crossover | AI analysis beyond free tier, premium features | TokenWallet |

**Crossover rules** (current runtime):
- One-way in the current app: points → tokens via `TokenService.convertPointsToTokens(...)`
- General conversion exists today with a daily cap
- If we later want event-only crossover, that should be a future gating decision
- No code path converts tokens → points

---

## 2. Detailed Earn Rates

### 2.1 Per-Action Points

| Action | Base | Conditions | Max/Day |
|--------|------|-----------|---------|
| Classification (high confidence, >85%) | 15 | Correct category, good image quality | 60 (unlimited for premium) |
| Classification (medium, 70–85%) | 10 | Correct category | 60 |
| Classification (low, <70%) | 5 | Correct category | 60 |
| User correction (verified) | 10 | Correction accepted by system or community | 20 |
| Batch analysis (bonus) | +5 | Per item in batch (applied on top of per-item points) | +30 |
| Educational content (completed) | 5 | Per lesson/quiz | 15 |
| Community contribution | 5–10 | Scaled by trust score | 20 |
| Daily login | 2 tokens (not points) | First session of the day | 2 tokens |
| Streak maintenance | +2 | Must classify ≥1 item | 2 |
| Challenge completion | 15–100 | Scaled by challenge difficulty | Varies |

### 2.2 Multipliers

| Condition | Multiplier | Stacking | Max Effective |
|-----------|-----------|----------|---------------|
| First scan of the day | 2× | Yes, with others | 2× base only (not compounding with other multipliers) |
| New category explored | 1.5× | No | Multiplier applies to that scan only |
| Correct disposal verified | 1.5× | Yes, with first-scan | 2.25× (applied after first-scan) |
| Safety-critical correct | 2× | Yes | Replaces base multiplier for safety items |
| Community-verified disposal | 1.2× | Yes | Stacks multiplicatively |
| Silver tier | 1.1× | Permanent | All points |
| Gold tier | 1.2× | Permanent | All points |
| Platinum tier | 1.3× | Permanent | All points |

### 2.3 Daily Earn Ceilings

| User Type | Points Cap/Day | Rationale |
|-----------|---------------|-----------|
| Free tier | 200 points | Anti-farming. Prevents bot-driven point accumulation. |
| Premium tier | 500 points | Higher ceiling as premium benefit. Still bounded to prevent runaway. |
| Event periods | 2× normal ceiling | Temporary increase during special events. |

### 2.4 Monthly Projection (Average User)

| User Type | Daily Avg | Monthly Base | With Streaks | With Challenges | Total/Month |
|-----------|-----------|-------------|-------------|-----------------|-------------|
| Casual (2×/week) | ~20 | ~160 | ~16 | ~30 | **~206** |
| Regular (daily, 2 scans) | ~40 | ~1,200 | ~60 | ~100 | **~1,360** |
| Power user (daily, batch) | ~80 | ~2,400 | ~60 | ~200 | **~2,660** |
| Premium power user | ~120 | ~3,600 | ~60 | ~300 | **~3,960** |

---

## 3. Detailed Sink Costs

### 3.1 Eco-Impact Spending

| Action | Point Cost | Real-World Impact | Frequency |
|--------|-----------|-------------------|-----------|
| Plant a tree | 500 | 1 tree planted via verified partner | One-time per tree |
| Offset 1kg CO₂ | 200 | Carbon offset credit | One-time |
| Cleanup fund donation | 100–1000 | Supports verified cleanup orgs | Any amount |
| Adopt a bin | 300 | Supports bin maintenance in locality | Monthly recurring |

**Design principle**: Costs are intentionally high (1–4 days of casual earning for 1 tree). Eco-impact is a meaningful commitment, not a casual spend. This maintains the psychological weight of the action.

**Partnership dependency**: Requires verified partner for execution. Until partnerships exist, eco-impact sink is disabled in the UI (stub ready for v2).

### 3.2 Cosmetic Rewards

| Item | Point Cost | Type | Notes |
|------|-----------|------|-------|
| Profile theme (basic) | 150 | One-time | Color scheme change |
| Profile theme (premium) | 400 | One-time | Animated/pattern theme |
| Badge frame | 200 | One-time | Frame for achievement badges |
| Emoji reaction pack | 100 | One-time | Unlock 5 new emojis for results |
| Virtual pin set | 250 | One-time | Display on profile |
| Avatar accessory | 300 | One-time | Hat, glasses, etc. |
| Impact counter style | 350 | One-time | New visual style for impact numbers |
| Seasonal badge | 200 | Time-limited | Available only during events |

**Design principle**: Cosmetics are aspirational but achievable. A regular user can afford 1–2 cosmetic items per month. A casual user can afford 1 every 2 months. This creates medium-term engagement goals.

**Inflation control**: Seasonal/time-limited items create urgency to spend. New items added quarterly. Old items may rotate back, maintaining value.

### 3.3 Streak Protection

| Item | Point Cost | Effect | Limit |
|------|-----------|--------|-------|
| Streak Freeze | 50 | Freeze 1 day — streak not lost if you miss it | 1 active at a time |
| Streak Shield | 120 | Protect 3-day window. Miss up to 3 days without losing streak. | 1 active at a time |
| Streak Reset Skip | 200 | Recover a broken streak (once per quarter for free users) | 1 per quarter |

**Design principle**: Streak protection is the most frequently purchased sink. At 50 points for a freeze (roughly 1 good scan), the cost is low enough to be accessible but high enough to feel like a choice. The 1-at-a-time limit prevents hoarding.

**Behavioral note**: The act of *buying* a streak freeze is itself a engagement signal — the user is actively choosing to protect their streak, which reinforces commitment.

### 3.4 Custom Challenges

| Feature | Point Cost | Notes |
|---------|-----------|-------|
| Create a challenge | 100 | Define goal, duration, stakes |
| Challenge prize pool | Variable | User sets the prize pool (min 50, max 500) |
| Challenge entry fee | 20 | Entry to someone else's custom challenge |
| Challenge visibility boost | 50 | Featured placement for 24 hours |

**Design principle**: Custom challenges create emergent engagement and user-generated content. The entry fee (20 points) is small enough to be a no-brainer for active users, but adds up across many entries.

---

## 4. Budget Model

### 4.1 Monthly Summary (All Users)

| Category | Earn/Month | Sink Spend/Month | Net |
|----------|-----------|-----------------|-----|
| Casual | ~206 | ~100 (cosmetics + 1 streak freeze) | +106 |
| Regular | ~1,360 | ~800 (1 eco-impact + 2 streak freezes + 1 cosmetic) | +560 |
| Power user | ~2,660 | ~2,200 (1 eco-impact + 3 freezes + 2 cosmetics + 1 challenge) | +460 |
| Premium power | ~3,960 | ~3,500 (2 eco-impact + 4 freezes + 3 cosmetics + 2 challenges) | +460 |

**Net positive across all tiers**. This is intentional — points are not meant to be drained to zero. Accumulation represents progress toward tiers (Silver/Gold/Platinum). Sinks are about *choice and meaning*, not forced depletion.

### 4.2 Inflation Risk Assessment

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| Point inflation from high-volume batch users | Low | Daily cap (200/500) limits max earn rate. Batch bonus is fixed +5, not multiplicative. |
| Streak freeze too cheap → no scarcity | Medium | 50 points × 30 days = 1,500 points/month if user uses freze daily. Most users don't miss that many days. Monitor usage; adjust cost if >30% of regular users always have a freeze active. |
| Cosmetic items too expensive → no spend | Low | Starting costs are intentionally modest (150 for a theme). Monitor purchase rates; add cheaper items (50 pts) if needed. |
| Economic stagnation (no new sinks added) | Medium | Quarterly sink additions: new cosmetics, seasonal items, limited-time event sinks. Continuous refresh maintains spend pressure. |
| Tier multiplier creates compounding inflation | Medium | Multiplier applies to base points only, not multiplied by other multipliers. Platinum tier's 1.3× on 200 ceiling = 260 effective cap/day — manageable. |

### 4.3 Adjustment Mechanism

All point values, sink costs, and daily caps are defined in a single configuration object stored in Firebase Remote Config:

```dart
class GamificationEconomyConfig {
  // Earn rates — per action type
  Map<String, int> basePointsPerAction;
  
  // Multipliers
  Map<String, double> multipliers; 
  
  // Sink costs — per item type
  Map<String, int> sinkCosts;
  
  // Caps
  int dailyPointsCap;
  int dailyTokenCap;
  
  // Tier thresholds
  Map<String, int> tierThresholds;
  
  // Streak parameters
  int streakFreezeCost;
  int maxActiveFreezes;
}
```

**Update cadence**:
- No changes in first 30 days after v1 ship (establish baseline)
- Monthly review: compare earn/spend ratio, sink purchase rates, tier progression speed
- Adjustments gated behind Remote Config rollout (50% → 100%) with 7-day observation window
- Never adjust more than 20% in one go (avoid shock to perceived value)

---

## 5. Sink Design Principles (Deep)

### 5.1 Eco-Impact Sink

**Psychology**: Taps into **meaning and calling** (Octalysis Core Drive 1). The user isn't spending points — they're converting game progress into real-world action. This is the highest-retention sink when activated.

**Risk**: If partnership costs make the conversion rate feel unfair (e.g., 5,000 points = $1 donation), users will perceive it as exploitative.

**Guardrail**: The eco-impact sink is **disabled by default** and gated behind two conditions:
1. A verified partner agreement exists (tree planting org, cleanup fund, etc.)
2. The conversion rate is published transparently (e.g., "500 points = 1 tree planted via [Partner Name]")

### 5.2 Cosmetic Sink

**Psychology**: Taps into **ownership and identity** (Endowment Effect). Users who buy a theme or badge feel more connected to the app. The item becomes part of their identity.

**Design patterns**:
- New items released quarterly (seasonal rotation)
- Limited-time items create urgency (FOMO)
- Rare/expensive items (1,000+ pts) for aspirational goals
- Some items are achievement-gated (unlockable only after specific achievement)

### 5.3 Streak Protection Sink

**Psychology**: Taps into **loss aversion** — protecting a streak is about avoiding the pain of loss, not gaining a reward. This is the most reliable sink because the motivation is primal (loss aversion is ~2× stronger than gain seeking).

**Design patterns**:
- Freeze is cheap but must be *explicitly purchased* — the act of buying reinforces commitment
- Shield is 2.4× the cost of freeze (120 vs 50) — users naturally compare and value the upgrade
- Reset skip is expensive (200) and limited (1/quarter) — available for emergencies, not regular use

### 5.4 Custom Challenge Sink

**Psychology**: Taps into **autonomy and creativity** (Free Spirit). Users create their own goals and stake points on them. This is user-generated content for the economy.

**Risk**: Low adoption in v1 — most users won't create challenges. The 100-point creation cost is a filter to ensure only invested users participate.

---

## 6. Economic Anti-Patterns to Avoid

| Anti-Pattern | Why It Fails | Prevention |
|-------------|--------------|------------|
| **Sink costs > earn rates** for average user | Creates frustration. Users feel they can never afford anything. | Budget model ensures net positive for all user types. |
| **One sink dominates** (e.g., 80% of spend on streak freezes) | Other sinks become irrelevant. Economy feels like a single-purpose system. | Monitor sink distribution. Rebalance costs to maintain diversity. |
| **Infinite point accumulation** with no cap | Power users reach million-point territory. Points lose meaning. Better to cap and let them spend. | Daily caps + progressive achievement tiers at fixed points (not unbounded). |
| **Points → real money conversion** | Creates farming incentives and regulatory risk (gambling). | No external cash-out. Points are not purchasable and not convertible to money. |
| **Stealth nerfs** (reducing earn rates without notice) | Destroys trust. Users feel cheated. | All economic adjustments communicated. Increase sink costs rather than reducing earn rates. |
| **Over-engineering before launch** | Economy designed in a vacuum. Real user behaviour will differ. | Ship with conservative earn rates and costs. Adjust monthly based on real data. |

---

## 7. Monitoring Dashboard

| Metric | Goal | Alert Threshold |
|--------|------|----------------|
| Points earned per user per day | 20–80 (casual), 40–120 (regular) | <10 or >150 sustained |
| Points spent per user per month | >50% of earned | <30% or >90% |
| Sink distribution (diversity) | No sink >50% of total spend | Any sink >60% of total |
| Streak freeze purchase rate | 30–50% of users who have a streak break | <10% (too expensive) or >80% (too cheap) |
| Cosmetic items purchased per user | 0.5–1.5 per month | <0.2 or >3 |
| Tier progression speed | Bronze→Silver in 10–30 days | <7 days (too fast) or >60 days (too slow) |
| Eco-impact spend (when active) | >15% of total sink spend | <5% (not meaningful) or >40% (may be expensive) |

---

## 8. Token Economy Integration

### 8.1 Points → Tokens (Event-Only)

| Event | Frequency | Exchange Ratio | Max Exchanges | Purpose |
|-------|-----------|---------------|---------------|---------|
| Gamification Week | Quarterly | 200 points → 2 tokens | 5 per user | Engagement injection; rewards active users with bonus AI capacity |
| Earth Day Special | Annually | 150 points → 3 tokens | 3 per user | Mission-aligned boost |
| Streak Milestone | Achievement unlock | 500 points → 5 tokens | One-time | Long-term engagement reward |
| Community Champion | Monthly top-10 | 1,000 points → 10 tokens | 1 per winner | Competitive reward |

### 8.2 Token → Points (Not Allowed)

No code path converts tokens to points. This preserves the scarcity of tokens and prevents users from "buying" their way to achievement tiers.

---

## 9. Related

- [Gamification Redesign Spec](gamification-redesign-spec.md) — parent specification
- [Archetype Deep Dive](gamification-archetypes-deep-dive.md) — motivation profile layer
- [Negative Mechanics A/B Design](gamification-negative-mechanics-ab-design.md) — deferred experiment
- [Token Economy & Pricing Coherence](../exploration/TOKEN_ECONOMY_AND_PRICING_COHERENCE.md) — separate economy design
