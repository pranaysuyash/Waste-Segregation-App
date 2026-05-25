# Gamification Moment Quality

**Status**: Exploration doc — open research
**Last Updated**: 2026-05-25
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) (P1 #10)
**Related**: [HABIT_FORMATION_LOOP.md](HABIT_FORMATION_LOOP.md), [GAMIFICATION_DEPTH.md](GAMIFICATION_DEPTH.md), [DYNAMIC_CHALLENGE_WEIGHTING.md](DYNAMIC_CHALLENGE_WEIGHTING.md)

---

## Why This Matters

Gamification only works when rewards feel **earned**. Too many notifications, popups, and celebration animations create gamification fatigue — users learn to ignore or resent the system. The current app has noisy popups and celebration events that interrupt flow rather than enhance it.

Moment quality is about getting the **intensity, timing, and frequency** right so that every reward signal carries meaning.

---

## Research Summary

### The Layered Reward Model

Top apps layer rewards by intensity and frequency to avoid fatigue:

| Layer | Intensity | Frequency | Examples | Presentation |
|-------|-----------|-----------|----------|-------------|
| **Micro** | Subtle | Every action | Points increment, haptic buzz, progress bar fill | Inline, no interruption |
| **Medium** | Moderate | Per-session / daily | Streak update, daily goal reached, challenge completed | Banner, post-action snackbar |
| **Macro** | High | Rare (weekly+) | Level up, achievement unlock, badge earned | Modal/overlay, deliberate pause |

**Key insight**: Most apps over-use Macro celebrations for Micro achievements. Every popup devalues the next popup.

### Case Studies

**Strava (Coalesced Rewards)** — Industry gold standard. Instead of notifying after every mile, Strava presents a comprehensive **post-activity summary**. This turns raw data into a meaningful "report card" that validates effort after the work is complete. No interruptions during the run.

**Duolingo (Goal-Linked Rewards)** — Rewards are tied directly to lesson difficulty and completion. Harder lessons = more XP. Predictable rewards teach the system, but Duolingo uses variable rewards (chests, timed challenges) to keep engaged users surprised.

**Habitica (Deliberate Milestones)** — Quests and bosses create natural "session breaks" where celebrations happen. Minor task completions get a checkbox sound effect — no popup. The celebration cadence follows the user's own goal structure.

### Psychology of Reward Schedules

| Schedule | Effect | Best For |
|----------|--------|----------|
| **Fixed Ratio** | Predictable, builds habit | Onboarding new users, establishing basics |
| **Variable Ratio** | Engaging, dopamine-driven | Sustained engagement, habit maintenance |
| **Fixed Interval** | Predictable check-in | Daily/streak rewards |
| **Variable Interval** | Surprise delight | Occasional bonus rewards, rare achievements |

**Warning**: Variable rewards work — but overuse creates Skinner-box dynamics that users eventually resent.

### Flow-Friendly Presentation Patterns

| Pattern | Usage | Why |
|---------|-------|-----|
| **Inline banner** | Micro rewards | No interruption, stays within flow |
| **Post-action snackbar** | Medium rewards | Brief acknowledgement, auto-dismiss |
| **Session-end summary** | Multiple events coalesced | Rewards after work is done (Strava pattern) |
| **Deliberate modal** | Macro rewards only | Rare, meaningful, user pays attention |
| **Haptic pulse** | Immediate feedback | Bridges action → acknowledgement without visual shift |
| **Sound effect** | Optional feedback | Feels earned when tied to difficulty |

---

## Design Principles for ReLoop

### 1. Coalesce, Don't Sprinkle

Instead of celebrating each micro-action:
- **Bad**: Popup after every scan ("+10 points!")
- **Better**: Silent points increment on the result screen
- **Best**: Post-session summary ("You classified 5 items today — +50 points, 1 streak day maintained")

### 2. Reserve Celebration for Meaningful Moments

Celebrate only when:
- A streak milestone is reached (7, 30, 100 days)
- A badge/achievement is unlocked
- A level-up occurs
- First-time actions (first hazardous identification, first correction)

Never celebrate:
- Routine daily actions (scanning another plastic bottle)
- Maintaining the same streak count
- Minor point increments

### 3. Earned Feeling Over Spammy Popups

A reward feels earned when:
- The user understands *why* they got it
- The effort-to-reward ratio is proportional
- The moment is timed *after* the work, not before
- There's a clear progression narrative

### 4. Smart Celebration Thresholds

| Event | Celebration Intensity |
|-------|----------------------|
| First scan ever | Macro — onboarding complete! |
| First scan of the day | Micro — subtle animation |
| 10th scan (same session) | Banner — "Making progress!" |
| Streak day 7 | Medium — streak milestone card |
| Streak day 30 | Macro — badge unlock modal |
| First hazardous identification | Macro — safety champion badge |
| Daily goal reached | Medium — banner "Goal complete!" |
| Level up | Macro — level-up animation |
| Weekly summary | Banner — coalesced weekly stats |
| Challenge completed | Medium — challenge complete card |
| First correction submitted | Medium — quality contributor badge |

---

## Anti-Patterns to Avoid

| Anti-Pattern | Why It Fails | Fix |
|-------------|-------------|-----|
| Per-action popup | Interrupts flow, devalues rewards | Coalesce into session summary |
| Streak anxiety messaging | Users open app to maintain streak, not to engage | Gentle check-in, streak freeze option |
| Over-celebration of volume | Incentivizes meaningless scans | Reward quality + diversity, not just count |
| Random rewards without context | Users don't know why they got it | Always show cause + effort-proportionality |
| Celebration during scan | Interrupts camera/task flow | Postpone to result screen |

---

## Open Questions

1. Should celebration intensity be adaptive (sensitive users get quieter celebrations) or fixed?
2. How do we handle the "first time" celebration queue for a new user who does 5 things in their first session?
3. Should there be a "quiet mode" that suppresses all celebrations?
4. How do we measure whether a celebration pattern is working? Retention vs celebration-completion rate?

---

## What Could Kill This

- Users prefer more celebration, not less (need to test)
- Coalescing rewards reduces perceived frequency → users feel unrewarded
- Engineering cost of building coalesced session summaries

---

## Next Steps

1. Audit current celebration events in the app — classify each as Micro/Medium/Macro
2. Run A/B test: current celebration pattern vs coalesced post-session summary
3. Measure: session length, return rate, celebration dismissal rate
4. Implement layered reward infrastructure
