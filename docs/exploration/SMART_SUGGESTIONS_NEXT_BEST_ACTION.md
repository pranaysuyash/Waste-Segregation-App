# Smart Suggestions / Next-Best-Action

**Status**: Exploration doc — open research
**Last Updated**: 2026-05-25
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) (A6)
**Related**: [NOTIFICATION_STRATEGY.md](NOTIFICATION_STRATEGY.md), [HABIT_FORMATION_LOOP.md](HABIT_FORMATION_LOOP.md), [GAMIFICATION_DEPTH.md](GAMIFICATION_DEPTH.md), [MOTIVATION_ARCHETYPES.md](MOTIVATION_ARCHETYPES.md)

---

## Why This Matters

After a classification, the app can do many things: educate, gamify, suggest disposal, prompt community share, route to facility, link to reuse marketplace, etc. Which to surface, when, and why is its own design problem.

Without an intentional suggestion ranking model, the app either shows everything (overwhelming) or nothing (missed engagement opportunity).

---

## Research Summary

### Suggestion Types and Their Roles

| Suggestion | Job | Best For | When |
|-----------|-----|----------|------|
| **Disposal instructions** | Primary utility | All users | Every classification result |
| **Educational content** | Learning / mastery | Achievement, learning archetypes | Non-obvious items |
| **Next scan prompt** | Habit loop | All users | After result viewed |
| **Related challenge** | Engagement | Gamers, social archetypes | When no active challenge |
| **Facility/dropoff lookup** | Practical follow-up | New users, unusual items | Non-bin items |
| **Community share** | Social connection | Social archetypes | Interesting/unusual items |
| **Correction prompt** | Quality improvement | Accurate users | After N correct classifications |
| **Premium prompt** | Conversion | Engaged free users | Rarely (1x/month max) |
| **Impact update** | Value reinforcement | Impact, learning archetypes | Weekly coalesced summary |

### Suggestion Ranking Model

Use a multi-factor scoring model:

```
Score(suggestion) = w₁×Propensity(u, suggestion) + w₂×Value(suggestion) + w₃×Urgency(suggestion) + w₄×Recency(suggestion)
```

Where:
- **Propensity(u, s)**: How likely this user is to engage with this suggestion type (learned over time)
- **Value(s)**: How much value this suggestion provides (educational value > premium prompt)
- **Urgency(s)**: Time sensitivity (safety alert > educational tip > premium prompt)
- **Recency(s)**: How recently this suggestion was shown to this user (avoid repetition)

### Ranking Maturity Curve

| Stage | Method | Implementation |
|-------|--------|----------------|
| **1. Rule-based** (MVP) | Hardcoded heuristics | "After scan: always show disposal → education → challenge" |
| **2. Lightweight learned** | Coarse user segments | Segments derived from archetype + history bucket |
| **3. Context-aware** | Real-time signals | Time of day, session length, recent actions, device state |
| **4. Reinforcement learning** | Continuous optimization | Bandit algorithm adapts per-user suggestion mix |

**Recommendation**: Start at Stage 1 (rule-based), move to Stage 2 after archetype detection data accumulates, skip to Stage 4 only if A/B testing shows significant improvement over Stage 2.

### Graceful Degradation (Thin Context)

When the system knows nothing about the user:

| Context Level | Strategy |
|---------------|----------|
| **Anonymous / first scan** | Show only disposal instructions + "create account to save" prompt |
| **1-5 scans** | Add educational content + basic scan prompt |
| **5-20 scans** | Add challenge suggestions, impact update |
| **20-100 scans** | Full suggestion set, weighted by observed engagement |
| **100+ scans** | Personalized ranking based on archetype + history |

### Anti-Pattern Guardrails

| Anti-Pattern | Guardrail |
|-------------|-----------|
| Nagging with same suggestion | Per-suggestion type cooldown (7 days between premium prompts) |
| Showing too many suggestions | Max 3 suggestions per result screen (4 only on milestone events) |
| Suggesting irrelevant content | Category-matching filter (don't suggest compost tips for electronics) |
| Interrupting the primary flow | Suggestions are **below** the classification result, not modal/popups |
| Premium upsell after first scan | Gate premium prompts behind minimum 20 scans and 7 days of activity |

---

## Suggestion Layout Design

```
┌─────────────────────────────────────┐
│ 📸 Plastic Bottle — PET             │
│ Confidence: 94% · Region: BBMP      │
│                                     │
│ [View Disposal Instructions →]      │  ← Primary action (always shown)
├─────────────────────────────────────┤
│ 💡 Did You Know?                     │  ← Suggestion 1 (education)
│ PET bottles can become fleece jackets│
│ [Learn more]                         │
├─────────────────────────────────────┤
│ 🏆 Active Challenge: Zero Waste Week  │  ← Suggestion 2 (challenge)
│ You've completed 3/7 days           │
│ [View progress]                      │
├─────────────────────────────────────┤
│ 🌍 Impact this session               │  ← Suggestion 3 (impact)
│ +0.2kg diverted · +2 items learned  │
└─────────────────────────────────────┘
```

---

## Open Questions

1. Should suggestions be server-driven (Remote Config) so we can A/B test mixes?
2. How do we track suggestion engagement (dismissal, click, completion)?
3. Should we allow users to customize which suggestion types they see?
4. How does suggestion ranking interact with premium status? (More suggestions for premium?)
5. Should suggestion placement differ by archetype? (Social archetypes get community share higher)

---

## What Could Kill This

- Users find suggestions distracting → ignore or dismiss → valuable suggestions buried with irrelevant ones
- Too many suggestions slow down the result screen → users want fast exit
- Personalization is too subtle to measure → A/B results inconclusive
- Premium prompts reduce trust in suggestion neutrality

---

## Next Steps

1. Implement Stage 1 rule-based ranking (disposal → education → challenge → impact)
2. Add suggestion engagement tracking (view, click, dismiss)
3. Build suggestion cooldown system (per-type, per-user)
4. Design suggestion layout for result screen
5. Wire suggestions into post-classification result view
6. A/B test suggestion count (2 vs 3 vs 4)
