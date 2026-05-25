# Real-World Impact Personalization

**Status**: Exploration doc — open research
**Last Updated**: 2026-05-25
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) (P1 #11)
**Related**: [MOTIVATION_ARCHETYPES.md](MOTIVATION_ARCHETYPES.md), [GAMIFICATION_MOMENT_QUALITY.md](GAMIFICATION_MOMENT_QUALITY.md), [PERSONAL_IMPACT_DASHBOARD_UX.md](../planning/../exploration/PERSONAL_IMPACT_DASHBOARD_UX.md) (when created)

---

## Why This Matters

Not all users are motivated by the same impact metric. One user cares about CO₂, another about plastic bottles saved, another about local civic progress, another about family achievement. Showing the wrong metric is worse than showing none — it signals the app doesn't understand the user.

Impact personalization is about **learning which framing resonates with each user** and adapting the impact dashboard, notifications, and challenge language accordingly.

---

## Research Summary

### Impact Metrics Taxonomy

| Metric | What It Measures | Emotional Weight | Best For |
|--------|-----------------|------------------|----------|
| **kg CO₂ equivalent** | Carbon footprint reduction | Abstract, scientific | Data-driven users, corporate/ESG |
| **Plastic bottles saved** | Tangible visual proxy | Concrete, relatable | General consumers, visual learners |
| **Trees equivalent** | Air/forestry comparison | Aspirational, hopeful | Idealists, eco-conscious users |
| **Landfill contamination prevented** | Harm reduction | Negative framing, urgent | Users who respond to loss aversion |
| **Hazardous waste safely diverted** | Safety impact | Protective, responsible | Parents, safety-conscious users |
| **Local civic impact** | Community improvement | Collective, pride | Community-driven users |
| **Family/household progress** | Group achievement | Shared, accountability | Family users, group accounts |
| **Learning mastery** | Knowledge gained | Competence, growth | Achievement-driven users |
| **Streak/consistency** | Habit formation | Personal discipline | Habit-formers, daily users |

### Matching Framing to User Segment

From Self-Determination Theory (SDT), different users are driven by different core needs:

| SDT Need | Motivation Style | Framing That Works | Example |
|----------|-----------------|--------------------|---------|
| **Autonomy** | Self-directed, utility | "You chose to sort 47 items" | Personal stats, freedom focus |
| **Competence** | Mastery, achievement | "You're in the top 10% of sorters" | Rankings, skill badges, level-up |
| **Relatedness** | Community, belonging | "Together we diverted 230kg" | Group stats, community impact |
| **Competition** | Status, comparison | "You're #3 in your neighbourhood" | Leaderboards, social comparison |
| **Identity** | Values, ethics | "You're protecting your community" | Mission framing, moral appeal |

**Key finding**: Applied research on environmental messaging consistently shows that **one-size-fits-all framing underperforms** personalized framing by 20-40% on engagement metrics.

### Industry Examples

- **Ecosia**: Connects routine search with tangible tree-planting outcomes. Impact is personal ("search trees planted by you") and collective ("total trees planted by everyone"). The framing bridges digital action → physical impact beautifully.

- **Too Good To Go**: Frames food rescue as "hero" behaviour — saving food from waste, not buying second-hand goods. Identity-shifting framing makes users feel like environmental heroes, not bargain hunters.

- **Olio**: Uses dual framing — "food shared" (generosity) and "waste prevented" (environmental). Users can toggle between social impact and environmental impact views.

- **JouleBug**: Social comparison + gamification. Shows "your impact vs your friends'" and "your city's ranking." Taps into relatedness and competition simultaneously.

### A/B Testing Impact Framing

To learn what resonates with each user:

1. **Test framing not features** — Same action, different metric presentation:
   - Group A: "You saved 2kg of CO₂"
   - Group B: "You prevented 10 bottles from entering landfills"
   - Group C: "Your community diverted 45kg today"

2. **Test motivational triggers**:
   - Individual: "Your personal impact this month"
   - Collective: "Our community's impact together"
   - Competitive: "You sorted 20% more than average"

3. **Track what matters**:
   - Primary: engagement with impact dashboard, return rate
   - Secondary: sharing rate, upgrade conversion, challenge completion

4. **Adapt over time**:
   - New users: start with broad default (tangible metric)
   - After N sessions: test alternative framings
   - After M weeks: converge on best-performing framing per user

---

## Adaptive Impact Personalization Flow

```
User signs up
    ↓
Start with balanced default metric (plastic bottles equivalent — most tangible)
    ↓
First 5 sessions: show different impact framings, track engagement
    ↓
Analyze: which framing got the most dashboard views, shares, return visits?
    ↓
Converge on top performer for this user
    ↓
Periodically re-test (quarterly) in case motivation shifts
    ↓
Allow manual override in settings — user can pick their preferred metric
```

### Signal Collection

| Signal | What It Reveals |
|--------|----------------|
| Which impact screen user visits most | Preferred framing category |
| Which notification gets clicked | Motivational trigger that works |
| Shared impact cards (if any) | What the user wants to show others |
| Challenge completion by reward type | Whether intrinsic (impact) or extrinsic (points) works |
| Explicit setting choice (if available) | Direct preference signal |

---

## Design Principles

1. **Default to tangible** — Start with plastic bottles / kg comparison. Abstract CO₂ is hard to internalise.

2. **Let users choose** — Settings should have an "impact metric preference" option with previews.

3. **Layer personalization** — Surface the preferred metric prominently on the dashboard, but keep other metrics accessible in detail views.

4. **Honest uncertainty** — Never fabricate precision. "Estimated ~2kg CO₂ saved" not "2.34kg CO₂ saved."

5. **Celebrate collective + individual** — Show both "your impact" and "our impact." Different users are motivated differently.

6. **A/B test everything** — Framing preferences are not intuitive. Test before committing.

---

## Open Questions

1. How many sessions before we can reliably detect framing preference? (Hypothesis: 5-10)
2. Should we ask explicitly during onboarding ("What motivates you most?") or learn implicitly?
3. How does impact personalization interact with archetype detection? Should impact preference inform archetype or vice versa?
4. Do different waste categories benefit from different framings? (Hazardous → safety framing, compost → CO₂ framing)
5. Should premium users get more detailed impact metrics as a benefit?

---

## What Could Kill This

- Users don't care about any impact framing → core loop needs redesign
- Personalization is too subtle to measure → A/B results inconclusive
- Wrong framing at the wrong time actively disengages users
- Engineering complexity outweighs retention gain

---

## Next Steps

1. Audit current impact dashboard — what metrics are shown, how are they framed?
2. Design A/B test comparing 3 framings (bottles vs CO₂ vs community)
3. Implement engagement tracking per framing variant
4. Run test for 2 weeks minimum, analyse results
5. Build adaptive impact selection based on findings
