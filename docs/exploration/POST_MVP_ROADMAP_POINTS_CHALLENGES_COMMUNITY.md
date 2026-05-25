# Post-MVP Roadmap: Points, Challenges, Community

**Date**: 2026-05-24
**Status**: Exploration — feature sequencing and dependency ordering
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md)
**Decision this unblocks**: Launch ordering for gamification features post-MVP

---

## 1. Current State

The app has existing gamification infrastructure:
- **Points engine** (v1) — basic earn rates, streak tracking, daily goals
- **Achievements** — unlock-based, some with tier progression
- **Streaks** — daily classification tracking
- **GamificationProfile** — user state model with points, level, streak data
- **GamificationService** — orchestrator for points/achievements/streaks
- **PointsManager** — provider for reactive UI updates

**What's planned but not built:**
- **Points Economy v2** — updated earn rates, multipliers, daily caps, sinks — see [POINTS_ECONOMY_V2.md](POINTS_ECONOMY_V2.md)
- **Motivation Archetypes** — personalized gamification — see [MOTIVATION_ARCHETYPES.md](MOTIVATION_ARCHETYPES.md)
- **Negative Mechanics A/B** — loss aversion experiments — see [NEGATIVE_MECHANICS_AB.md](NEGATIVE_MECHANICS_AB.md)
- **Challenges** — time-bound goals with rewards
- **Community** — leaderboards, teams, social features

---

## 2. Industry Evidence on Sequencing

### Case Study: Duolingo
- **Core habit loop first**: Lessons → XP — users learned without gamification
- **Streaks added next**: Daily anchor — drove 2x day-1 to day-7 retention
- **Leaderboards much later**: Only after large active user base — avoided empty-state problem
- **Friends/Quests latest**: Social layer on established community

Key lesson: **Do not launch social features until users have individual habit**. Empty leaderboards kill motivation.

### Case Study: Habitica
- **Built as game-first** from day 0 — the RPG engine was the core value
- **Parties/Guilds added after** individual habit tracking was proven
- **Challenges** as extension of social system — community-driven

Key lesson: **If your core product isn't game-like, don't gamify first**. Fix core utility, then layer game mechanics.

### Case Study: Strava
- **Core tracking first** — GPS run logging (relentlessly reliable)
- **Segments (leaderboards)** — turned personal data into social competition
- **Clubs/feed** — full social layer on established activity base

Key lesson: **Social features amplify existing behavior**. They don't create it.

---

## 3. Proposed Sequencing for ReLoop

### Phase 1: Foundation (Current + Next)
```
Core App → Solo Gamification → Points Economy v2
```

**What ships:**
- Core classification (already live)
- Updated earn rates with daily caps (Points Economy v2)
- Motivation archetype detection (personalized challenge weighting)
- Notification timing based on archetype

**Why first:**
- Points v2 fixes the current economy (inflation hoarding, missing sinks)
- Archetype detection enables personalization before community features
- Both are solo — no empty-state risk

**Estimated: 2-3 weeks from start**

### Phase 2: Engagement (After Phase 1 is stable)
```
Solo Gamification → Time-bound Challenges → Streak/Target Sinks
```

**What ships:**
- Time-bound challenges (e.g., "Classify 10 items this week")
- Challenge rewards from Points Economy v2 sink types
- Streak protection as a premium-purchase sink
- Eco-impact sinks (donate points to tree planting)

**Why second:**
- Challenges give goals beyond daily streaks
- Multiple challenge types (daily, weekly, archetype-specific)
- Sinks give points meaning — without them, earn rates don't matter
- No social comparison yet — still individual

**Estimated: 3-4 weeks from Phase 1 completion**

### Phase 3: Community (After critical mass)
```
Challenges → Opt-in Leaderboards → Teams/Families
```

**What ships:**
- Regional leaderboards (city-level, opt-in)
- Weekly challenge leaderboards
- Teams/cooperative challenges (tied to family feature)
- Community impact dashboard

**Why third:**
- Leaderboards need enough active users to avoid empty states
- Teams build on existing family feature
- Community features amplify existing habits — don't create them

**Estimated: 4-6 weeks from Phase 2 completion**

### Phase 4: Negative Mechanics A/B (After stable engagement)
```
Community → A/B Experiment: Loss Aversion → Full rollout or Kill
```

**What ships:**
- Streak decay / challenge failure consequences (A/B)
- Content gating by performance
- Progress decay for inactive users

**Why last:**
- These are the riskiest changes — could damage retention if wrong
- Requires solid baseline engagement metrics to measure against
- Should be A/B tested with ethical guardrails

**Estimated: 6-8 weeks from Phase 3 completion**

---

## 4. Dependency Graph

```
Core Classification
    └── Points Engine v1
        ├── Points Economy v2 (earn rates, caps, sinks)
        │   ├── Motivation Archetype Detection
        │   │   └── Personalized Challenge Weighting
        │   ├── Time-bound Challenges
        │   │   └── Challenge Leaderboards (Phase 3)
        │   ├── Point Sinks (eco-impact, cosmetics, streak protection)
        │   └── Premium Pricing Integration
        └── Streaks
            └── Streak Protection Sink (Phase 2)
                └── Negative Mechanics A/B (Phase 4)
```

**Hard dependencies:**
- Points Economy v2 must ship before Challenges (challenge rewards use updated economy)
- Archetypes must ship before challenge personalization
- Challenges must ship before Challenge Leaderboards
- Enough active users required before any leaderboard/community feature
- Negative mechanics require baseline retention metrics

**Soft dependencies:**
- Archetypes can ship independently of Challenges
- Streak sinks can ship before or after Challenges
- Eco-impact sinks can ship immediately with Points v2

---

## 5. Risk Assessment

| Risk | Phase | Mitigation |
|---|---|---|
| Empty leaderboard demotivates | 3 | Start opt-in only; use regional/city grouping; don't show empty |
| Points inflation before sinks ship | 1 | Launch sinks simultaneous with Points v2; daily caps are hard limit |
| Challenge difficulty unbalanced | 2 | Start with simple daily challenges; A/B difficulty after 1 week |
| Archetype misdetection ruins experience | 1 | Start with questionnaire (not inference); confidence state machine; allow manual override |
| Community features cannibalize solo motivation | 3 | Measure solo engagement before/after; kill-switch leaderboards per cohort |
| Negative mechanics cause churn | 4 | Strict A/B with guardrails (10% of users max); monitor retention weekly |
| Feature fatigue / notification overload | 2-3 | Archetype-based notification cadence; user-configurable frequency |

---

## 6. Metrics to Track Per Phase

| Phase | Leading Indicators | Lagging Indicators |
|---|---|---|
| Phase 1 (Foundation) | DAU, classifications/day | Day-7 retention, first-scan rate |
| Phase 2 (Engagement) | Challenge start rate, sink usage | Challenge completion rate, points velocity |
| Phase 3 (Community) | Leaderboard participation, team invites | Social referrals, retention improvement |
| Phase 4 (Negative) | A/B engagement deltas | Churn rate, support tickets, uninstall rate |

---

## 7. Related

- [Points Economy V2](POINTS_ECONOMY_V2.md) — earn rates, caps, sinks, monitoring
- [Motivation Archetypes](MOTIVATION_ARCHETYPES.md) — behavioral profiling
- [Negative Mechanics A/B](NEGATIVE_MECHANICS_AB.md) — loss aversion experiment design
- [Gamification Redesign Spec](../planning/gamification-redesign-spec.md) — redesign scope
- [Community Stats Completion Report](../../docs/review/COMMUNITY_STATS_COMPLETION_REPORT.md) — existing community foundations
