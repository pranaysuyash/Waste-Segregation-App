# Habit Formation Loop

**Date**: 2026-05-23
**Status**: Exploration — behavioural loop design
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) entry 17
**Decision this unblocks**: Week-3 retention cliff, long-term engagement beyond novelty
**Kill criteria**: If daily active users naturally sustain without nudges, habit engineering is unnecessary

---

## 1. Habit Loop Framework

Based on Nir Eyal's Hook Model:

```
Trigger → Action → Variable Reward → Investment
```

### Current triggers

| Trigger | Type | Effectiveness |
|---------|------|---------------|
| Push notification (if enabled) | External | Unknown — not instrumented |
| Streak fire emoji | Internal | Visual only, no functional impact |
| Home screen stats | Internal | Weak — zero state demotivates |
| Community feed | External | Weak — currently single-user |

### Current rewards

| Reward | Type | Effectiveness |
|--------|------|---------------|
| Classification result | Information | Strong initially, fades |
| Points (10 per scan) | Achievement | Weak — no quality differentiation |
| Achievements | Achievement | Moderate — but too many (50+) |
| Streak | Social | Weak — no social comparison |

### Current investment

| Investment | Type | Effectiveness |
|------------|------|---------------|
| Classification history | Data | Moderate — user builds personal dataset |
| Achievements | Reputation | Weak — no social visibility |
| Streaks | Time | Moderate — loss aversion kicks in |

---

## 2. Enhanced Habit Loop

### Trigger enhancements

1. **Time-based**: "It's waste collection day tomorrow — scan your items!"
2. **Location-based**: "You're near a recycling center — have items to sort?"
3. **Behavioural**: "You classified 3 items yesterday — can you beat your record?"
4. **Social**: "Your family member just sorted 5 items correctly!"

### Action improvements

- Reduce taps: scan tab should be persistent and prominent
- Auto-open camera when scan tab selected
- Batch mode: "Scan 5 items, analyze all at once"

### Variable reward design

- **Mystery**: Classification reveals category with animation
- **Achievement**: Random bonus achievements ("First battery classification!")
- **Social**: Family leaderboard with weekly challenges
- **Progress**: Visual progress bars toward next tier/achievement

### Investment mechanics

- **Data**: Personal waste profile builds over time
- **Reputation**: Community trust score grows with corrections
- **Skills**: User learns disposal rules (tracked by quiz performance)
- **Social**: Family/group challenges create social obligation

---

## 3. Week-3 Retention Cliff

### Problem

Users start with novelty (scanning is fun). By week 3, they've seen the result screen 20+ times. The classification feels repetitive. No new mechanic is introduced.

### Solution: Progressive disclosure

| Week | New Mechanic Unlocked | Purpose |
|------|----------------------|---------|
| 1 | Basic scan + result | Core loop |
| 2 | Achievements + streaks | Achievement hook |
| 3 | Challenges + family features | Social hook |
| 4 | Community feed + contributions | Social proof |
| 5 | Educational content + quizzes | Learning hook |
| 6+ | Premium features + advanced analytics | Monetization hook |

### Weekly challenges

| Day | Challenge | Reward |
|-----|-----------|--------|
| Monday | "Meatless Monday" — classify 2 food items | 10 bonus points |
| Wednesday | "Hump Day Hazard" — correctly handle a hazardous item | 20 bonus points |
| Friday | "Flash Friday" — 5 instant analyses | 15 bonus points |
| Weekend | "Family Sort" — family member also classifies | 25 bonus points |

---

## 4. Habit Stacking

Connect waste sorting to existing daily routines:

- **Morning**: "Before you throw away breakfast items, scan them!"
- **Cooking**: "Sorting food waste while cooking? Snap and sort!"
- **Evening**: "End-of-day waste review — scan anything you missed"
- **Trash day**: "Collection day reminder — have you sorted correctly?"

---

## 5. Relation to Redesign Spec

The progressive disclosure timeline described in §3 (week-by-week mechanic unlock) directly feeds into the [gamification redesign spec](../planning/gamification-redesign-spec.md#7-onboarding-flow)'s phased onboarding flow (§7), which starts minimal on first visit and progressively reveals streaks (return visit), challenges (day 3+), full achievements (week 1+), and adaptive adjustments (week 2+). The redesign spec further adds an adaptive system that adjusts habit loops based on the user's detected motivation archetype — reinforcing different triggers, rewards, and investments for Achievers vs Explorers vs Socialites vs Habit-formers vs Impact-driven users.

---

## 6. Related

- [Gamification Redesign — Full Spec](../planning/gamification-redesign-spec.md) — comprehensive specification (adaptive engine, challenges, points sinks, phased onboarding)
- [Gamification Depth](GAMIFICATION_DEPTH.md) — reward system design
- [Onboarding & Activation](ONBOARDING_AND_ACTIVATION.md) — first habit formation
- [Notification Strategy](../EXPLORATION_TOPICS.md#a11-notification-strategy-) — trigger delivery
