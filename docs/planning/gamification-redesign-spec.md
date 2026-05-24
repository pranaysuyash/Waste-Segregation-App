# Gamification Redesign — Full Specification

**Status**: Draft spec  
**Date**: 2026-05-23  
**Source**: [Freebuff Gamification Interview Recovery](docs/reports/freebuff_gamification_interview_recovery_2026-05-23.md) + 3 follow-up interview rounds  
**Scope**: Full transformation (3–4+ weeks of implementation)  
**Target persona**: General consumers  
**Design principle**: All of the above in phases — retention, accuracy, education, community  

---

## 1. Vision Statement

Waste segregation should feel rewarding because it *is* rewarding — not through artificial point inflation, but through quality recognition, learning progression, community connection, and real-world impact. The gamification system dynamically adapts to each user's natural motivation style, gently counterbalancing when behavior narrows, and celebrating breadth as much as depth.

---

## 2. Design Principles (from v2 Exploration)

1. **Reward quality, not quantity**: Points scale with AI confidence, user corrections, and disposal accuracy
2. **Reward cost-saving behaviour**: Batch analysis earns bonus points (saves AI cost)
3. **Reward learning**: Completing educational content earns points
4. **Reward community**: Helping others (corrections, contributions) earns trust + points
5. **Don't reward spam**: Rate-limited point earning, diminishing returns
6. **Adapt automatically**: The system learns motivation profile and adjusts weight, challenges, and recommendations
7. **Invisible by default**: Adaptation happens silently — users can optionally explore their profile

---

## 3. Interview Decisions Log

### 3.1 Target & Scope

| Question | Decision | Notes |
|----------|----------|-------|
| Primary target persona | **General consumers** | Broad audience, fun and accessible |
| Most important outcome | **All of the above in phases** | Retention, accuracy, education, community — phased rollout across all dimensions |
| Effort scope | **Full transformation** | 3–4+ weeks. Not a small patch. |
| User types across sets | **Can have different for different sets** | Documented but needs careful design to avoid over-complication |

### 3.2 Token Economy & Anti-Farming

| Question | Decision | Notes |
|----------|----------|-------|
| Token integration | **Keep separate, room for later** | Points are for engagement. Tokens are for AI usage metering. One-way earn path + event-only crossovers in v1 (points can earn tokens on special occasions) |
| Anti-farming | **Phase 2 or later** | Defer server pHash dedup + daily cap |
| Kill switch | **Keep for now** | Token enforcement kill switch stays during transition |

### 3.3 Social vs Solo & Dynamic Weights

| Question | Decision | Notes |
|----------|----------|-------|
| Social vs solo balance | **Balanced, dynamic** | Both have unique value; system adapts weights as user behavior shifts |
| Behavior detection | **Hybrid approach** | Signals: interaction frequency + completion patterns + time-of-day + anything else that identifies behaviour |
| Detection cadence | **Hybrid/sustained** | Quick initial nudge for strong signals, only commit after sustained pattern. Prevents ping-ponging |
| Profile visibility | **Invisible + optional reveal** | Adaptation happens silently. Users can optionally explore their profile on a dedicated screen |

### 3.4 Points & Economy

| Question | Decision | Notes |
|----------|----------|-------|
| Points sink | **Mix of all four** | Eco-impact spending + cosmetic rewards + streak protection + custom challenges — all ship together in v1 |
| Negative mechanics | **Phase it later** | Skip for v1. Explore as an A/B experiment once the positive system is stable |
| Token crossover | **One-way + event-only** | Points can earn tokens on special occasions (Gamification Week events). No general conversion in either direction |

### 3.5 Achievements & Challenges

| Question | Decision | Notes |
|----------|----------|-------|
| Achievement style | **Static first, emergent later** | Start with ~20 visible, well-designed achievements. Add adaptive hidden achievements in v2 after we have user data |
| Challenge rebalancing | **Counterbalance + discovery + amplification** | Combination of all three, chosen based on user's current motivation profile |
| Negative exploration | **Explore more** | Unsure if negatives help retention — defer to A/B experiment |
| Real-world impact | **Yes, but learn what resonates** | Adapt impact metrics to the user. Not the core loop |

### 3.6 Phasing & Onboarding

| Question | Decision | Notes |
|----------|----------|-------|
| Implementation phasing | **All at once** | Design everything together, test holistically, ship as one big release |
| Family features | **Phase separately** | Gamification v1 is purely individual. Family/household features are a separate v2 effort |
| Onboarding approach | **Phased reveal + wait until return** | Minimal gamification on first visit. Full system activates progressively when user returns for a second visit |
| Success metrics | **Don't set targets yet** | Ship first, measure baseline, then set targets based on real data |

### 3.7 Technical & Architecture

| Question | Decision | Notes |
|----------|----------|-------|
| Profile storage | **Don't know yet** | Needs prototyping to determine what data needs to be server-side vs on-device |
| Adaptive onboarding | **Balanced default, adapt slowly** | Start with balanced defaults, adapt gradually as signals accumulate |
| Premium intersection | **Not discussed — needs separate exploration** | Left open for future decision |

---

## 4. v2 Points System

### 4.1 Base Points

| Action | Points | Conditions |
|--------|--------|-----------|
| Classification | 5–15 | Scaled by AI confidence (low=5, medium=10, high=15) |
| User correction | 10 | Only when correction is verified correct |
| Batch analysis | +5 bonus | Encourages cost-saving behaviour |
| Educational content completed | 5 | Per lesson/quiz completion |
| Community contribution | 5–10 | Scaled by trust score |
| Daily login | 2 tokens (not points) | Separate from point system |
| Streak maintenance | +2 per day | Must classify at least 1 item |

### 4.2 Multipliers

| Condition | Multiplier | Rationale |
|-----------|-----------|-----------|
| First scan of the day | 2× | Encourage daily use |
| New category explored | 1.5× | Encourage breadth of learning |
| Correct disposal verified | 1.5× | Encourage follow-through |
| Safety-critical correct | 2× | Reward correct hazardous handling |
| Community-verified | 1.2× | Community endorsement |

### 4.3 Points Sinks (all ship in v1; eco-impact gated)

All four sink types ship in v1. Eco-impact is gated behind verified partnerships and disabled by default until active.

| Sink | Cost | Purpose | Availability |
|------|------|---------|-------------|
| Eco-impact spending | Variable | Fund real tree planting / waste cleanup — real-world impact | **Gated** — disabled until verified partnership exists (infra ships v1, activation in later phase) |
| Cosmetic rewards | Variable | Themes, badges, emoji reactions, virtual items | **Active at v1 launch** |
| Streak protection | Fixed | Buy streak freezes or extra challenge slots | **Active at v1 launch** |
| Custom challenges | Variable | Create custom challenges for self or group | **Active at v1 launch** |

---

## 5. Achievement System

### 5.1 Core Achievements (~20, visible)

Reduce from 50+ to ~20 meaningful, visible achievements:

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

### 5.2 Achievement Tiers

| Tier | Points Required | Benefits |
|------|----------------|----------|
| Bronze | 0–500 | Base rewards |
| Silver | 501–2000 | +10% point multiplier, profile badge |
| Gold | 2001–5000 | +20% point multiplier, custom themes |
| Platinum | 5001+ | +30% point multiplier, exclusive content |

### 5.3 Future: Emergent Achievements (v2)

After we have user data, add adaptive hidden achievements based on:
- Rare behaviors ("scan at midnight")
- Social patterns ("help 5 new users")
- Behavioral milestones unique to the user's journey

---

## 6. Adaptive System Design

### 6.1 Signals Collected

| Signal | Source | Purpose |
|--------|--------|---------|
| Interaction frequency | Which screens visited most | Detect motivation archetype |
| Completion patterns | What actions are completed (vs started but abandoned) | Identify friction vs flow |
| Time-of-day patterns | When the app is used | Segment casual vs committed users |
| Category breadth | How many waste categories scanned | Detect narrowing behavior |
| Challenge engagement | Which challenge types accepted/completed | Understand preferred challenge style |
| Social participation | Leaderboard views, shares, contributions | Measure social motivation |

### 6.2 Motivation Archetypes (Initial Guesses)

The system detects which archetype(s) a user leans toward and adjusts weights:

| Archetype | Signature Behaviors | System Response |
|-----------|-------------------|-----------------|
| **Achiever** | High completion rate, checks achievements, optimizes for points | Surface harder challenges, highlight remaining achievements, leaderboard rank |
| **Explorer** | Wide category breadth, scans unfamiliar items, reads educational content | Surface discovery challenges, new categories, hidden content |
| **Socialite** | Checks leaderboard, shares results, contributes to community | Surface community challenges, leaderboard milestones, sharing prompts |
| **Habit-former** | Consistent daily visits, cares about streak, focused on routine | Surface streak protection, streak milestones, daily reminders |
| **Impact-driven** | Checks environmental stats, engages with impact dashboard | Surface eco-impact metrics, real-world achievements, impact leaderboard |

### 6.3 Rebalancing Mechanisms

When the system detects behavioral narrowing (user tips too far in one direction):

| Narrowing Signal | System Response | Type |
|-----------------|-----------------|------|
| Only scans easiest category | Discovery challenge for new categories | Discovery |
| Only challenges same challenge type | Counterbalance challenge of opposite type | Counterbalance |
| Only scans, never learns | Educational content recommendation | Discovery |
| Only does solo work | Community contribution prompt | Counterbalance |
| Already mastering one area | Amplification: master-level badge | Amplification |

### 6.4 Detection Cadence

- **Short-term signals** (3–5 sessions): Quick nudges and suggestions
- **Sustained patterns** (7–14 days): Profile weight shifts; system commits to new emphasis
- **Onboarding period**: Balanced default, adapt slowly. Full system activates after user returns for second visit (not on first session)

---

## 7. Onboarding Flow

### 7.1 First Visit (Minimal)

- First scan triggers "First Step" achievement immediately
- Points and streak tracking active in background
- No challenge system visible yet
- No motivation profiling yet

### 7.2 After First Return Visit

- Streak counter shown (count starts at 2)
- Achievement system introduces first visible goals
- Challenge system progressively revealed
- Signal collection begins in earnest

### 7.3 Week 1 Progression

| Day | Unlock | Notes |
|-----|--------|-------|
| Day 0 | Points + streak activated | Invisible to user |
| Day 1 | First achievement earned | "First Step" + 10 pts |
| Day 2+ (return) | Streak visible, first badge | Encouragement |
| Day 3+ | Challenge system appears | First daily challenge |
| Day 7+ | Full achievement list visible | 20 achievements |
| Week 2+ | Adaptive adjustments begin | Based on 7+ days of signals |

---

## 8. Points Economy & Sinks (Detailed)

### 8.1 Points Budget Model

| User Type | Monthly Points Earned | Typical Spend |
|-----------|---------------------|---------------|
| Casual (scan ~2×/week) | ~200 | Cosmetic badges, occasional streak freeze |
| Regular (scan daily) | ~800 | 1 eco-impact contribution + 2 streak freezes |
| Power user (heavy + batch) | ~2000 | Custom challenges + eco-impact + cosmetics |
| Premium power user | ~3000 (with multiplier) | Everything |

### 8.2 Sink Design Principles

- **Eco-impact**: Points → real-world action (tree planting, cleanup fund). Partnership required for execution
- **Cosmetic**: Themes, profile badges, emoji reactions, virtual pins. One-time purchases, high perceived value
- **Streak protection**: Streak freeze (freeze one day), Streak shield (protect 3-day streak). Recurring spend
- **Custom challenges**: Create a challenge (define goal, duration, stakes). Points as entry fee or prize pool

---

## 9. Challenge System

### 9.1 Challenge Types

| Type | Examples | Purpose |
|------|----------|---------|
| **Daily Challenges** | "Classify 3 plastic items today" | Daily habit, variety |
| **Weekly Challenges** | "Scan 5 different categories this week" | Breadth, exploration |
| **Discovery Challenges** | "Find and scan one medical waste item" | Educational, counter-narrowing |
| **Counterbalance Challenges** | "Try hazardous sorting this week" | Counter behavioral narrowing |
| **Amplification Challenges** | "Master 50 correct plastics" | Go deeper in existing strength |
| **Community Challenges** | "Help 3 users with corrections" | Social engagement |

### 9.2 Challenge Selection Algorithm

The system selects challenges based on:
1. **User archetype** (detected motivation profile)
2. **Recent narrowing** (behavior has narrowed — suggest counterbalance)
3. **Category gaps** (user hasn't scanned certain categories — suggest discovery)
4. **Time of week** (weekend = deeper challenges, weekday = quick challenges)
5. **Role in rebalancing** (over-emphasis on social → solo work challenge; over-emphasis on solo → community challenge)

---

## 10. Data Model (Initial Sketch)

### 10.1 GamificationProfile (Embedded in UserProfile)

```dart
class GamificationProfile {
  int points;
  
  // Points breakdown
  int totalPointsEarned;
  int totalPointsSpent;
  Map<String, int> pointsBySource; // classification, education, community, etc.
  
  // Streaks
  Map<StreakType, StreakData> streaks;
  
  // Achievements
  Set<String> earnedBadges; // badge IDs
  List<DateTime> badgeEarnedTimestamps;
  
  // Discovery
  Set<String> discoveredItemIds; // for first-item bonuses
  
  // Adaptive profile (initial — signals are on-device first)
  MotivationArchetype? detectedArchetype;
  Map<String, double> archetypeConfidenceScores;
  DateTime lastProfileUpdate;
  
  // Challenges
  List<String> completedChallengeIds;
  Map<String, int> dailyChallengeProgress; // challengeId -> count
  DateTime lastChallengeProgression;
  
  // Points sinks
  int ecoImpactContributions;
  List<String> purchasedCosmetics;
  int streakFreezesUsed;
  int customChallengesCreated;
}
```

### 10.2 Signal Store (On-Device, TBD)

The raw behavioral signals that feed the motivation profile. Storage location TBD (need prototyping):

| Signal | Granularity | Retention |
|--------|-------------|-----------|
| Session timestamps | Per session | 90 days |
| Screen views | Per screen, per session | 90 days |
| Actions completed | Per action | 90 days |
| Category-by-category scan counts | Cumulative | Indefinite |
| Challenge acceptance/completion | Per challenge | Indefinite |
| Time spent per action | Per action | 30 days |
| Re-engagement patterns | Per visit after absence | Indefinite |

---

## 11. Negative Mechanics (Deferred to A/B Experiment)

Not shipping in v1. Design space for future exploration:

| Mechanic | Theory | Risk |
|----------|--------|------|
| Streak-only reset | Streak breaks after inactivity, points never decrease | Streak anxiety may cause app fatigue / uninstall |
| Passive point decay | Points slowly decay after 2+ weeks inactive | Creates urgency for returners, but feels punishing |
| Challenge failure cost | Accepting a challenge and failing costs small points | Increases commitment weight, but discourages trying |
| Level demotion | Lose a level if points drop below threshold | Highest risk, most punishing |

**Decision**: Defer all negative mechanics. Ship pure positive v1. Consider A/B testing streak-only reset in v2.

---

## 12. Integration Points

### 12.1 Token Economy Integration (One-Way + Events)

- **One-way path**: Points → tokens via special event conversions (e.g., "Gamification Week: convert 200 points to 2 bonus tokens")
- **No general conversion**: No always-available conversion between points and tokens
- **Event system**: Periodic themed events create temporary currency bridges
- **Separation enforced**: Two separate ledgers. No code path that creates tokens from points except through explicit event handlers

### 12.2 Classification Pipeline Integration

- Points scaled by AI confidence (from `WasteClassification.confidence`)
- Batch analysis bonus (from `AnalysisSpeed.batch`)
- Disposal correctness check (from `local_policy_engine.dart`)
- Image quality gate affects points (low quality = lower multiplier)

### 12.3 Premium Integration (Needs Separate Exploration)

Open questions for future:
- Do premium users get gamification advantages?
- Cosmetic premium perks (themes, animations)?
- Practical advantages (more challenge slots, streak freezes)?
- No advantages — keep gamification separate from monetization?

---

## 13. Phasing & Release Plan

### Phase 0: Design + Spec (1 week) ← CURRENT

- [ ] This spec document
- [ ] Architecture review with existing services
- [ ] Prototype signal storage approach (on-device vs server)
- [ ] Wireframes for key screens (achievements, profile, challenges)

### Phase 1: Core Implementation (2–3 weeks)

- [ ] v2 points system (quality-scaled, disposal-linked, bonuses)
- [ ] Achievement system (~20 static achievements + tiers)
- [ ] Streak overhaul (must classify to maintain, milestone bonuses)
- [ ] Challenge system (daily, weekly, discovery, counterbalance, amplification)
- [ ] Points sinks (eco-impact, cosmetic, streak protection, custom challenges)
- [ ] Signal collection infrastructure (on-device profiling)

### Phase 2: Adaptive Engine (1 week)

- [ ] Motivation archetype detection
- [ ] Adaptive challenge selection
- [ ] Rebalancing triggers
- [ ] Visible profile screen (optional reveal)
- [ ] Adaptive onboarding flow

### Phase 3: Polish & Launch (1 week)

- [ ] Full suite testing
- [ ] Baseline metrics measurement
- [ ] UI polish, animations, haptics
- [ ] Documentation

---

## 14. Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| Adaptive system makes wrong predictions | Medium | High | Invisible profile + optional override. System adapts slowly, not instantly |
| Points sink creates negative pressure | Medium | Medium | Monitor spent vs earned ratio. Kill switch for individual sinks via Remote Config |
| Onboarding feels overwhelming despite phased approach | Low | Medium | Phased reveal tested with 5 users before v1. Cut features if needed |
| Challenge system creates anxiety (too much to do) | Medium | Medium | Challenges are 1–3 active at a time. No overlapping deadlines. Auto-complete time-window challenges |
| Token economy and point economy cause confusion | Medium | Low | Clear visual separation in UI. Points = engagement/achievement, tokens = AI usage meter |
| Performance with on-device signal collection | Low | Medium | Signal writes are batched, async, non-blocking. Profile computation is periodic |

---

## 15. Open Questions for Further Exploration

### Resolved by Deep Dives

| # | Question | Resolution | Document |
|---|----------|------------|----------|
| 1 | Motivation archetypes — concrete definitions, scoring heuristics, detection algorithm | **Deep dive complete** — 5 archetypes defined with weighted signals, state machine, narrowing detection, and system responses | [`gamification-archetypes-deep-dive.md`](gamification-archetypes-deep-dive.md) |
| 2 | Points economy design — earn rates, sink costs, budget projections, inflation guardrails, dual-currency separation | **Deep dive complete** — detailed earn table, multiplier stacking rules, daily caps, 4 sink cost structures, monthly budget model, economic anti-patterns, monitoring dashboard | [`gamification-points-economy-deep-dive.md`](gamification-points-economy-deep-dive.md) |
| 3 | Negative mechanics — A/B experiment design to determine if they improve retention | **Deep dive complete** — 3-phase experiment (baseline → single-variant → multi-variant), 9 hypotheses, sample size analysis, ethical guardrails, hard kill criteria, analysis plan, timeline | [`gamification-negative-mechanics-ab-design.md`](gamification-negative-mechanics-ab-design.md) |

### Still Open

1. **Premium intersection**: Should premium users have gamification advantages? Cosmetic vs practical vs none? Needs separate exploration.
2. **Family/household mode**: Separate v2 effort — design spec needed separately.
3. **Profile storage location**: On-device vs server-side — needs prototyping to decide.
4. **Success metric targets**: To be defined after baseline measurement.
5. **Real-world impact partnerships**: Eco-impact spending requires partner relationships (tree planting, cleanup orgs).
6. **Signal privacy posture**: What level of signal collection needs explicit user consent?

---

## Appendix A: Interview Trail

This spec synthesizes:
- **Rounds 1–5** from the [Freebuff Recovery Document](docs/reports/freebuff_gamification_interview_recovery_2026-05-23.md)
- **Aborted Batch** (onboarding adaptation, premium intersection) — captured as open questions
- **Follow-up Rounds 1–3** (this session) — adaptive system, phasing, negative mechanics, sinks, technical architecture

## Appendix B: Related Documents

- [Gamification Depth](docs/exploration/GAMIFICATION_DEPTH.md) — v2 design principles and point system
- [Token Economy & Pricing Coherence](docs/exploration/TOKEN_ECONOMY_AND_PRICING_COHERENCE.md) — separate economy design
- [Habit Formation Loop](docs/exploration/HABIT_FORMATION_LOOP.md) — behavioral mechanics foundation
- [Onboarding & Activation](docs/exploration/ONBOARDING_AND_ACTIVATION.md) — first-achievement design
- [Gamification Phase 1 Implementation Plan](docs/planning/gamification_phase1_implementation_plan.md) — earlier planning
- [Gamification Service Revamp](docs/implementation/technical/gamification_service_revamp.md) — technical service design
- [Leaderboard System Design](docs/implementation/technical/leaderboard_system_design.md) — extensible leaderboards
