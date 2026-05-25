# Dynamic Challenge Weighting & Counterbalance Loop

**Status**: Exploration doc — open research
**Last Updated**: 2026-05-25
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) (P1 #7)
**Related**: [MOTIVATION_ARCHETYPES.md](MOTIVATION_ARCHETYPES.md), [GAMIFICATION_DEPTH.md](GAMIFICATION_DEPTH.md), [HABIT_FORMATION_LOOP.md](HABIT_FORMATION_LOOP.md)

---

## Why This Matters

If the adaptive motivation system detects a user tipping too far in one direction (e.g., obsessive social competition, volume-only scanning, avoiding education), the challenge system can rebalance engagement by introducing counterbalancing challenges. Without this, the adaptive system reinforces existing biases instead of promoting holistic waste-sorting competence.

The counterbalance loop is the **active steering mechanism** of the adaptive gamification engine — the archetype detection is the compass, challenges are the rudder.

---

## Research Summary

### Detection of Behavioral Imbalance

Real-world adaptive systems use continuous profiling to detect drift:

| Signal | What It Indicates | Source |
|--------|------------------|--------|
| Feature visit frequency | Which motivation channel the user favours | Duolingo, Strava |
| Completion patterns | Whether user finishes tasks or hops | Habitica quest logs |
| Session length & time-of-day | When and how deeply they engage | Academic flow research |
| Error rate trends | Boredom (too easy) vs frustration (too hard) | Knowledge Tracing (Duolingo) |
| Social interaction ratio | Solo vs social tilt | Strava kudos/comments vs personal stats |

**Academic foundation**: Csikszentmihalyi's Flow Theory — users in flow have optimal challenge-skill balance; drift to either extreme triggers churn.

### Challenge Types for Counterbalancing

| Imbalance Direction | Counterbalance | Example |
|-------------------|----------------|---------|
| Too social (leaderboard-obsessed) | Solo deep-work goals | "Classify 5 hazardous items correctly" |
| Too solo (never engages community) | Low-risk social injection | "Share a classification tip" |
| Too volume-focused (easy scans) | Quality/hard-category push | "Identify 3 e-waste items" |
| Too education-heavy (reads but doesn't scan) | Action challenges | "Scan 3 items from your kitchen" |
| Too streak-anxious (opens just to maintain) | Meaningful engagement | "Complete one challenge today" |
| Too competition-avoidant | Passive social cues | "See how your neighbourhood sorts" |

### Industry Evidence

- **Duolingo**: Adaptive difficulty scaling maintains flow — too-easy users get rapid-fire challenges; too-hard users get scaffolded content. Internal metrics show this reduces "quit moments" by a measurable margin.
- **Habitica**: Quest system provides natural counterbalance — social users must complete personal tasks to advance group goals; solo users benefit from party buffs.
- **Strava**: Nudges solo runners toward group challenges and club participation without forcing it.
- **Academic research**: Dynamic Difficulty Adjustment (DDA) consistently outperforms static difficulty in both retention and skill acquisition across domains.

---

## Ethical Guardrails

| Guardrail | Why |
|-----------|-----|
| User can decline any challenge | Preserve autonomy — counterbalance is a nudge, not a mandate |
| No punishment for ignoring suggestions | Avoid anxiety from perceived system pressure |
| Toggle intensity mode | "Relaxed / Normal / Intense" lets user set the adaptation speed |
| Transparency on dedicated screen | Show "The system noticed you're X — here's why we suggested Y" |
| Never weaponize competition | Avoid toxic comparison loops; frame as personal growth |
| Rate-limit adaptation suggestions | Max 1 counterbalance challenge per day to avoid nagging |

---

## Implementation Considerations

### Loop Architecture

```
[Monitor] → [Compare vs ideal model] → [Select counterbalance] → [Present challenge] → [Observe response] → [Update model]
```

### Key Design Decisions

1. **What is the "ideal engagement model"?** — How balanced should a user be? Equal social/solo? Heavy on quality? This must be learnable from archetype profiles.
2. **When does counterbalance trigger?** — After N sessions of detected imbalance? Only when below threshold in an area?
3. **How visible is the adaptation?** — Interview answer: **invisible + optional reveal** on a dedicated screen.
4. **Cold start** — Interview answer: start balanced, experiment in first week, context-based initial guess.

---

## Open Questions

1. Should counterbalance challenges be explicit ("We noticed you haven't classified hazardous waste — try this challenge") or implicit (show different challenges on the screen)?
2. How do we measure whether a counterbalance succeeded? Next-week archetype score shift? Retention improvement?
3. What's the minimum data required before counterbalancing begins? 1 week? 10 sessions?
4. Should counterbalancing be archetype-specific? (Achievement-driven users get different rebalance than impact-driven users.)
5. How do we prevent the system from ping-ponging the user between extremes?

---

## What Could Kill This

- Users find the system manipulative or creepy
- Counterbalancing adds complexity without measurable retention improvement
- Cold-start guesses are wrong too often, undermining trust early
- Engineering cost exceeds retention benefit

---

## Next Steps

1. Validate archetype detection first (this depends on it)
2. Run a simple A/B test on one counterbalance type (e.g., solo challenges for social-heavy users)
3. Measure retention impact over 2-week window
4. Design the dedicated "adaptive profile" screen for optional reveal
