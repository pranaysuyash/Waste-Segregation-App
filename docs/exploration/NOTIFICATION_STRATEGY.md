# Notification Strategy

**Status**: Exploration doc — open research
**Last Updated**: 2026-05-25
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) (A11)
**Related**: [ONBOARDING_AND_ACTIVATION.md](ONBOARDING_AND_ACTIVATION.md), [HABIT_FORMATION_LOOP.md](HABIT_FORMATION_LOOP.md), [SMART_SUGGESTIONS_NEXT_BEST_ACTION.md](SMART_SUGGESTIONS_NEXT_BEST_ACTION.md)

---

## Why This Matters

Push notifications are the single highest-leverage retention surface — and the single fastest path to uninstall if abused. The design space is wide and currently unowned.

Without a deliberate notification strategy, the app risks either:
- **Under-notifying**: users forget to return, streaks break, habit doesn't form
- **Over-notifying**: users uninstall within the first week, notification permission revoked

---

## Research Summary

### Notification Types: Retention vs Uninstall Drivers

| Type | Drives Retention | Triggers Uninstall | Examples |
|------|-----------------|-------------------|----------|
| **Transactional** | High — immediate utility | Low — expected | "Your classification is ready" |
| **Coaching** | Medium — educational value | Medium — if too frequent | "Did you know plastic bags go to dropoff?" |
| **Streak** | High — loss aversion | High — if felt as pressure | "Your 7-day streak is at risk!" |
| **Community** | Medium — social belonging | Medium — if irrelevant | "Your neighbour sorted 3 items today" |
| **Re-engagement** | Low — depends on offer | High — "We miss you!" generic | "Come back and scan!" |
| **Marketing** | Low — depends on offer | High — perceived spam | "Premium is now available" |

**Key insight**: Transactional and coaching notifications earn their keep. Streak, community, re-engagement, and marketing must be used sparingly and personalized.

### Notification Design Patterns

| Pattern | Goal | Frequency | Content |
|---------|------|-----------|---------|
| **Transactional** | Reduce friction, build trust | Per-action (as needed) | "Your photo has been classified as PET plastic" |
| **Coaching** | Increase proficiency | 1-2x/week | "Pro tip: Rinse containers before recycling" |
| **Streak** | Habit maintenance | 1x/day (at user's active time) | "You're on a 5-day streak! 🔥" |
| **Milestone** | Celebrate achievement | On event (rare) | "You've classified 100 items! 🎉" |
| **Challenge** | Goal-oriented engagement | When challenge active | "Your Zero Waste Week challenge starts tomorrow" |
| **Community** | Social connection | 1-2x/week max | "Your sorting tip helped a neighbour!" |
| **Re-engagement** | Win-back | Progressive cadence (see below) | 3 day: gentle. 7 day: value. 14 day: incentive |
| **Impact** | Value reinforcement | 1x/week | "This week you diverted 5kg from landfill" |
| **Premium** | Conversion | 1x/month max | "Unlock exclusive challenges with Premium" |

### Quiet Hours and Frequency Capping

| Cap | Recommendation | Rationale |
|-----|---------------|-----------|
| **Daily max** | 3 notifications | Above this → risk of uninstall |
| **Streak notifications** | 1x/day at user's typical active hour | Avoid pressure-anxiety |
| **Marketing/premium** | 1x/month (or opt-in only) | High uninstall risk |
| **Quiet hours** | 10PM-7AM (user-configurable) | Respect sleep schedules |
| **Burst protection** | No more than 1 notification in 60 minutes | Avoid notification fatigue |
| **Priority tiers** | Transactional > Coaching > Streak > Community > Marketing | Critical alerts bypass caps |

### Local-Time-Aware Scheduling

- Send notifications at the user's typical active hour (learned from interaction patterns)
- Default to morning (8-9 AM user local time) for streak/coaching
- Default to evening (6-7 PM) for impact summaries
- Never send during device Do Not Disturb hours

### Re-Engagement Cadence for Dormant Users

| Day Since Last Activity | Notification | Tone |
|------------------------|-------------|------|
| Day 3 | "Haven't scanned in a few days — anything new to sort?" | Gentle reminder |
| Day 7 | "Your streak is on hold. Ready to restart?" | Value-focused (streak) |
| Day 14 | "You've saved X kg from landfill so far. Let's keep going!" | Impact-focused |
| Day 30 | "Come back this week and earn double points!" | Incentive offer |
| Day 60+ | Stop messaging | Avoid spam classification |

### Industry Examples

**Duolingo** (Master of behavioral notifications):
- Uses personalized timing based on when user historically engages
- Streak loss aversion: "Your streak is at risk — practice for 3 minutes!"
- Playful tone, low barrier to entry ("only 3 minutes")
- Adaptive content based on user's position in the learning path

**Too Good To Go** (Utility-first, high-value):
- Only sends when a real-time event occurs (favorited shop has surplus bag)
- Low frequency, high value → notifications are seen as helpful, not spam
- Respects user context (local time, favorite shops)

**Ecosia** (Values-driven):
- Reinforces impact identity: "You've helped plant X trees"
- Acknowledges contribution before asking for more
- Anchors habit to pro-environmental identity, not just app features

---

## Notification Strategy for ReLoop

### Tier System

| Tier | Notification Types | Frequency Cap | Opt-in Model |
|------|-------------------|---------------|--------------|
| **Essential** | Transactional, Safety alerts | As needed | Always on |
| **Engagement** | Streak, Milestone, Impact | 2x/day max | Prompt at onboarding |
| **Social** | Community, Challenge | 1x/week max | Optional opt-in |
| **Marketing** | Premium upsell, Promotions | 1x/month max | Optional opt-in |

### Opt-In Flow

```
Onboarding:
1. Request "Essential" permission (transactional + safety) — always on
2. Day 3: Prompt for "Engagement" tier (streak, impact, milestone)
3. Day 7: Prompt for "Social" tier (community, challenges)
4. Never prompt for "Marketing" — gate behind Settings opt-in
```

### Notification Content Templates

| Type | Title | Body | Deep Link |
|------|-------|------|-----------|
| Transactional | "Classification Ready" | "Your [item] has been identified as [category]. See disposal options." | Result screen |
| Safety | "⚠️ Safety Alert" | "The item you scanned may be hazardous. Tap to see handling advice." | Safety details |
| Streak | "🔥 Streak Update" | "You're on a [N]-day streak! Keep it going" | Home screen |
| Milestone | "🎉 Achievement Unlocked" | "You've classified [N] items — that's [metric] of waste!" | Achievements |
| Impact | "🌍 Weekly Impact" | "This week: [N] items sorted, [X]kg diverted, [Y] items learned" | Impact dashboard |
| Challenge | "🏆 Challenge Active" | "Your [challenge name] challenge starts today. Ready?" | Challenge screen |
| Coaching | "💡 Did You Know?" | "Most [category] items can be recycled differently than you might think." | Education card |
| Dormant (3d) | "👋 Checking In" | "Anything new to sort? We're here when you need us." | Home |
| Dormant (7d) | "📊 Your Impact Report" | "Before you went quiet, you'd diverted [X]kg. That's [comparison]!" | Impact dashboard |
| Dormant (14d) | "⚡ Double Points Weekend" | "Scan this weekend for 2x points — your impact makes a difference." | Home |

---

## Open Questions

1. Should notifications support rich media (images of past achievements, streak visualizations)?
2. How do we handle users in different time zones with a single server?
3. Should we A/B test notification tone: playful (Duolingo) vs utilitarian (Too Good To Go) vs mission-driven (Ecosia)?
4. How do notifications interact with the offline queue? Notify when queued items are processed?
5. Should users be able to disable specific notification types (not just all-or-nothing)?

---

## What Could Kill This

- Users find any notification intrusive → revoke permission → lose all notification-based retention
- Over-notification during onboarding → high early uninstall rate
- Re-engagement notifications flagged as spam → app reputation damage
- Too conservative → users forget app exists

---

## Next Steps

1. Build notification tier system (Essential, Engagement, Social, Marketing)
2. Implement progressive opt-in flow (start with Essential, prompt for Engagement on Day 3)
3. Add user-configurable notification preferences per tier
4. Implement frequency capping on server side
5. Design notification content templates for each type
6. A/B test notification tone and timing
