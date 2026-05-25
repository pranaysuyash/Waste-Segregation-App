# Personal Impact Dashboard UX

**Purpose**: Explore how to present environmental impact data (kg diverted, CO2, trees, etc.) to users in a way that motivates without misleading.
**Status**: Exploration — `impact_dashboard_screen.dart` exists; no UX research doc
**Last Updated**: 2026-05-25
**Related**: [GAMIFICATION_DEPTH.md](GAMIFICATION_DEPTH.md), [HABIT_FORMATION_LOOP.md](HABIT_FORMATION_LOOP.md), [REAL_WORLD_IMPACT_PERSONALIZATION.md](REAL_WORLD_IMPACT_PERSONALIZATION.md)

---

## Problem Statement

The app tracks environmental impact (waste diverted, categories sorted, hazardous items removed) but:

1. **Metrics are abstract**: "5 kg diverted" doesn't feel real to most users
2. **No personalization**: The same metrics shown to all users regardless of motivation type
3. **Uncertainty not communicated**: Users see precise numbers ("3.2 kg CO2") that are actually estimates
4. **Comparison framing**: Personal vs household vs community — which drives retention?

---

## Research Summary

### Cross-Cultural Comparison Metaphors

| Metaphor | Works Best For | Risk |
|----------|---------------|------|
| **Trees planted equivalent** | Environmentalists | Can feel generic (every app uses it) |
| **Km driven avoided** | Transit users | Alienates non-drivers |
| **Water bottles saved** | Developed nations | Less meaningful in water-scarce regions |
| **Meals rescued** | Food waste focus | Not applicable for non-food |
| **Lightbulb hours** | Universal | Abstract — no emotional connection |
| **Local context** (city garbage trucks, local landmarks) | All users | Needs per-region customization |

**Recommendation**: Allow users to toggle between metaphors. Or use machine learning to learn which metaphor drives engagement for each user.

### Communicating Honest Uncertainty

Environmental data is estimated. Over-precision destroys trust.

| Treatment | UX | Trust Impact |
|-----------|-----|-------------|
| "You saved 10 kg CO2" | Precise number | Low — user will question accuracy |
| "Estimated 8-12 kg CO2" | Range | Medium — honest |
| "About 10 kg CO2 — equivalent to..." | Rounded + metaphor | High — relatable + honest |
| "Trend: You're saving more this month" | Direction > precision | Highest — focuses on improvement |

### Framing Comparison

| Frame | Initial Hook | Long-Term Retention |
|-------|-------------|-------------------|
| **Personal** | High ("I did this") | Medium — can become stale |
| **Household/Family** | Medium ("We did this") | High — shared accountability |
| **Community** | Low ("Look at everyone") | Medium — social pressure can demotivate |

**Recommendation**: Nested dashboard — personal first (hook), expand to household (retention), then community (comparison).

---

## Dashboard Design

### Metric Tiers

| Tier | Metrics | Frequency |
|------|---------|-----------|
| **Primary** (hero) | Items diverted, categories sorted, top material | Daily glance |
| **Secondary** | Weight diverted (kg), CO2 equivalent | Weekly review |
| **Tertiary** | Hazardous items removed, contamination prevented, learning score | Monthly |
| **Social** | Community rank, household progress, challenges completed | On-demand |

### Visualization Patterns

- **Progress rings**: Fill as user nears goals
- **Sparklines**: Show trend direction (up = good)
- **Comparison bars**: "You vs average user"
- **Heat map**: Day-by-day activity density
- **Celebration card**: Animated milestone (every 100 items, 10 kg, etc.)

---

## Key Decisions Needed

1. **Default metaphor**: What's the primary impact unit — items, kg, CO2, or trees?
2. **Uncertainty display**: Show ranges, trends, or precise numbers?
3. **Sharing surface**: What's the shareable artifact — impact card, streak badge, milestone?
4. **Community comparison**: Show leaderboard position, or only "you're in the top X%"?

---

## Open Questions

- Do impact metrics drive action, or just feel-good measurement?
- Should the dashboard be a separate tab or integrated into home screen?
- Does showing community comparison increase or decrease engagement for low-performing users?
- How do we handle negative impact metrics (e.g., a month with only 1 scan)?

---

## Next Steps

1. A/B test impact metaphors (trees vs kg vs items — which drives re-engagement?)
2. Design uncertainty communication UI (ranges, trends, confidence indicators)
3. Implement nested dashboard: Personal → Household → Community
4. Build shareable impact card generator
