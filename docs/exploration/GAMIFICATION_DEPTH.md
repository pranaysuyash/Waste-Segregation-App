# Gamification Depth

**Date**: 2026-05-23
**Status**: Exploration — v2 gamification system design; redesign spec complete after interview synthesis
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) entry 16
**Decision this unblocks**: v2 gamification tied to disposal correctness, not scan volume, with adaptive engine, challenge system, and points sinks
**Kill criteria**: If gamification has no measurable impact on week-3 retention, simplify to streaks + badges only

> **Full redesign spec**: [`docs/planning/gamification-redesign-spec.md`](../planning/gamification-redesign-spec.md) — comprehensive specification from the gamification interview recovery + 3 follow-up interview rounds. This exploration doc covers the v2 point/achievement foundation; the redesign spec adds the adaptive engine, challenge system, points sinks, negative mechanics research, and phased rollout plan.

---

## 1. Current System

### What exists

| Component | Location | Status |
|-----------|----------|--------|
| Points engine | `lib/services/points_engine.dart` | 10 points per classification, bonus for streaks |
| Achievements | 50+ across 5 tiers (Bronze → Platinum) | Static definitions |
| Streaks | Daily streak with fire emoji | Visual only, no functional impact |
| Challenges | Plastic Hunter, Food Waste Warrior, etc. | Category-specific goals |
| Leaderboard | `leaderboard_allTime` Firestore collection | Global ranking |
| Family achievements | Related achievements grouped | Weak grouping |

### What rewards wrong behaviour

| Problem | Current | Should Be |
|---------|---------|-----------|
| Points per classification | Fixed 10 points | Quality-scaled: high confidence = more points |
| No disposal correctness check | Any scan = points | Points tied to correct disposal |
| No penalty for bad scans | Rushed photos rewarded | Blurry/dark photos get fewer points |
| Batch vs instant parity | Same points regardless | Batch = bonus (cost-saving behaviour) |
| Streak maintenance | Just open the app | Must scan + classify to maintain |

---

## 2. v2 Design Principles

1. **Reward quality, not quantity**: Points scale with AI confidence, user corrections, and disposal accuracy
2. **Reward cost-saving behaviour**: Batch analysis earns bonus points (saves AI cost)
3. **Reward learning**: Completing educational content earns points
4. **Reward community**: Helping others (corrections, contributions) earns trust + points
5. **Don't reward spam**: Rate-limited point earning, diminishing returns

---

## 3. v2 Point System

### Base points

| Action | Points | Conditions |
|--------|--------|-----------|
| Classification | 5–15 | Scaled by AI confidence (low=5, high=15) |
| User correction | 10 | Only when correction is verified correct |
| Batch analysis | +5 bonus | Encourages cost-saving behaviour |
| Educational content completed | 5 | Per lesson/quiz completion |
| Community contribution | 5–10 | Scaled by trust score |
| Daily login | 2 tokens (not points) | Separate from point system |
| Streak maintenance | +2 per day | Must classify at least 1 item |

### Multipliers

| Condition | Multiplier | Rationale |
|-----------|-----------|-----------|
| First scan of the day | 2× | Encourage daily use |
| New category explored | 1.5× | Encourage breadth of learning |
| Correct disposal verified | 1.5× | Encourage follow-through |
| Safety-critical correct | 2× | Reward correct hazardous handling |
| Community-verified | 1.2× | Community endorsement |

---

## 4. Achievement Redesign

### Reduce from 50+ to 20 meaningful achievements

| Achievement | Trigger | Reward |
|-------------|---------|--------|
| First Step | First classification | 10 bonus points |
| Quick Learner | 5 correct classifications | Badge |
| Category Master | 10 correct in one category | Badge + 50 points |
| Safety First | Correctly handle 3 hazardous items | Badge + safety icon |
| Streak Starter | 7-day streak | Badge + 25 points |
| Streak Champion | 30-day streak | Badge + 100 points |
| Batch Saver | 20 batch analyses | Badge + 25 points |
| Community Helper | 5 verified corrections | Badge + trust boost |
| Waste Wizard | 100 correct classifications | Platinum badge + 200 points |
| Educator | Complete all learning modules | Badge + 50 points |
| Explorer | Classify items from all 5 categories | Badge + 25 points |
| Eco Warrior | 30-day streak + correct disposal | Badge + title |

### Achievement tiers

| Tier | Points Required | Benefits |
|------|----------------|----------|
| Bronze | 0–500 | Base rewards |
| Silver | 501–2000 | +10% point multiplier, profile badge |
| Gold | 2001–5000 | +20% point multiplier, custom themes |
| Platinum | 5001+ | +30% point multiplier, exclusive content |

---

## 5. Redesign Spec — What's Beyond v2

The [redesign spec](../planning/gamification-redesign-spec.md) extends the v2 foundation described above with the following major additions, all derived from the gamification interview (5 recovered rounds + 3 follow-up rounds):

### Adaptive Motivation Engine

- Collects **6 signals**: interaction frequency, completion patterns, time-of-day, category breadth, challenge engagement, social participation
- Detects **5 archetypes**: Achiever, Explorer, Socialite, Habit-former, Impact-driven
- Adaptation is **invisible + optional reveal** — system adapts silently; users can view their profile
- **Detection cadence**: short-term nudges (3–5 sessions), sustained profile shifts (7–14 days)

### Challenge System

- **6 challenge types**: Daily, Weekly, Discovery, Counterbalance, Amplification, Community
- **Rebalancing**: system detects behavioral narrowing and suggests counterbalancing challenges
- **Selection algorithm** uses: user archetype + recent narrowing + category gaps + time of week + rebalancing role

### Points Sinks (all ship together in v1)

| Sink | Purpose |
|------|---------|
| Eco-impact spending | Fund real tree planting / waste cleanup |
| Cosmetic rewards | Themes, badges, emoji reactions, virtual items |
| Streak protection | Buy streak freezes or extra challenge slots |
| Custom challenges | Create custom challenges for self or group |

### Negative Mechanics (Deferred)

- All negative mechanics (streak reset, point decay, challenge failure cost, level demotion) deferred to v2 A/B experiment
- v1 is pure positive reinforcement

### Phased Onboarding

- **First visit**: minimal (points + streak tracking invisible)
- **Return visit**: streak shown, achievements introduced
- **Week 1+**: challenges, full achievement list, adaptive adjustments begin

### Token Economy Separation

- Keep separate ledgers: points for engagement, tokens for AI usage metering
- One-way + event-only crossover (points can earn tokens on special occasions)
- No general conversion path

### Phasing & Release

- **v1**: Core implementation (2–3 weeks) — v2 points, ~20 achievements, streak overhaul, challenges, points sinks, signal collection
- **v2**: Adaptive engine (1 week) — archetype detection, adaptive challenge selection, rebalancing, visible profile
- **v3**: Polish & launch (1 week) — full suite testing, baseline metrics, UI polish

---

## 6. Related

- [Gamification Redesign — Full Spec](../planning/gamification-redesign-spec.md) — comprehensive specification (adaptive engine, challenges, points sinks, phasing)
- [Habit Formation Loop](HABIT_FORMATION_LOOP.md) — behavioural mechanics
- [Token Economy & Pricing Coherence](TOKEN_ECONOMY_AND_PRICING_COHERENCE.md) — point/token relationship
- [Onboarding & Activation](ONBOARDING_AND_ACTIVATION.md) — first-achievement design
- [Family Dashboard UI](FAMILY_DASHBOARD_UI.md) — household mode (separate v2 effort)
