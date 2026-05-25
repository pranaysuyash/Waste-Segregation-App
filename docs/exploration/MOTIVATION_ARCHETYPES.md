# Motivation Archetype Detection for Habit-Forming Apps

**Decision it unblocks**: Whether to build an adaptive motivation profiling system that detects user archetypes from behavior, and if so which model(s) to use, how many archetypes, and how to validate.

**Status**: Active — 2026-05-21  
**Key questions open**: 3 of 7 resolved  
**Kill criteria**: see below  

---

## 1. Why This Exploration

The gamification redesign spec proposes a motivation archetype system that personalizes challenges, notifications, and rewards based on user motivation drivers. Before building this, we need to understand:

1. Which existing research / frameworks are credible versus vibes?
2. What's the evidence that personalizing by archetype improves retention?
3. What's the simplest profiling mechanism — self-report quiz, behavioral inference, or hybrid?

---

## 2. Key Research Findings

### 2.1 Established Frameworks — Credibility Assessment

| Framework | Origin | Validated? | Applicability |
|-----------|--------|------------|---------------|
| **Bartle's Taxonomy** (1996) | MUD player study, N ~dozens | ❌ Small sample, single context, not replicated for mobile/utility apps | Weak — use only as conceptual inspiration |
| **Marczewski's HEXAD** (2015) | Gamification-specific, 24-item scale | ✅ Validated across multiple studies (e.g., Tondello et al. 2016, 2017) | Strong — purpose-built for gamification, has validated psychometric scale |
| **Yee's Motivation Model** (Quantic Foundry) | Large-scale gamer surveys (N > 250k) | ✅ Robust — factor analysis holds across cultures | Partial — built for games, but the 10-motif model is more nuanced than 4-type taxonomies |
| **Chou's Octalysis** (2015) | Design toolkit, not a measurement instrument | ❌ No psychometric validation — it's a design heuristic | Weak for profiling; useful as a design checklist |
| **Fogg's Behavior Model** (B=MAP) | Behavioral science | ✅ Widely cited, well-evidenced mechanism model | Not a type model — explains *why behavior happens*, not *who the user is* |

**Implication**: If we build an archetype system, **HEXAD is the strongest academic foundation**. Yee's model is a credible secondary reference for granularity.

### 2.2 Does Personalization by Archetype Work?

**Short answer**: Yes — but the evidence is nuanced.

**Studies found**:
- **Personalization Improves Gamification** (Orji et al., 2017, 2019, 2023, via ResearchGate/ACM): users who received gamification elements matched to their HEXAD type showed higher engagement, task performance, and satisfaction than users who received mismatched or non-personalized elements.
- **One-size-fits-all (OSFA) gamification** performs worse than personalized in multiple RCTs across health, education, and sustainability domains.
- **Effect size varies**: personalization helps most for "Disruptor" and "Socializer" types (HEXAD) because these are underserved by default achievement-focused designs.

**Caveats**:
- Most studies are short-term (1–4 weeks); long-term retention effects are less studied.
- Self-report profiling (quiz) at onboarding has ~40–60% accuracy at predicting actual in-app behavior — users don't always know their own motivations.

**Implication**: Personalization is worth doing. But **behavioral inference** (detecting archetype from actions) likely outperforms self-report over time.

### 2.3 How Production Apps Handle This

| App | Approach | Mechanism |
|-----|----------|-----------|
| **Duolingo** | Behavioral profiling (no quiz) | Tracks streak sensitivity, leaderboard engagement, lesson types, time-of-day patterns → adapts notifications and difficulty |
| **Habitica** | Self-selected class (quiz at signup) | User picks Warrior/Mage/Healer/Rogue → class-specific rewards and stat bonuses |
| **Headspace** | No explicit profiling | Single path with optional branching by topic interest |
| **Nike Run Club** | No explicit archetypes | Behavior-agnostic achievement progression (all mileage) |

**Pattern**: Most mature apps **don't use explicit archetype quizzes**. They infer motivation from behavior signals.

### 2.4 Behavioral Signals for Archetype Inference

Based on research and production patterns, the following signals correlate with motivation types:

| Signal | What it reveals | Archetype Correlation |
|--------|----------------|----------------------|
| Streak length / freeze usage | Loss-aversion vs casual | Achiever / Free Spirit |
| Challenge acceptance rate | Competition vs intrinsic | Achiever / Philanthropist |
| Share / social features usage | Social motivation | Socializer |
| Correction rate / feedback quality | Learning/mastery motivation | Philanthropist / Free Spirit |
| Time-of-day usage pattern | Habit vs opportunistic | All (context signal) |
| Feature breadth (how many features used) | Explorer vs focused | Free Spirit (explorer subtype) |
| Points/tokens balance behavior | Saver vs spender | Achiever / Player |
| Educational content consumption | Knowledge motivation | Philanthropist |
| Community contributions | Altruism motivation | Philanthropist |

---

## 3. Proposed Archetype Model (Synthesis)

From the research, I propose we adopt a **5-archetype model** aligned with HEXAD but simplified for implementation:

| Archetype | Core Drive | Design Focus | Behavioral Signals |
|-----------|-----------|--------------|-------------------|
| **Achiever** | Mastery, progress, competition | Points, streaks, leaderboards, challenges | High scan frequency, challenge acceptance, streak defense |
| **Socializer** | Community, recognition, sharing | Feeds, badges, comparisons, family features | Share events, community visits, family engagement |
| **Learner** | Knowledge, understanding, curiosity | Education content, quizzes, disposal info | Education content consumption, quiz completion, correction use |
| **Impact-Seeker** | Making a difference, altruism | Environmental impact stats, carbon metrics | Impact dashboard visits, donation features, community contributions |
| **Player** | Fun, rewards, collection | Points economy, cosmetics, unlockables | Token balance activity, cosmetic purchases, challenge variety |

**Why 5 and not 6 (HEXAD) or 4 (Bartle)?**
- Drops HEXAD's "Disruptor" — in a waste-sorting app, disruption has limited healthy expression. If needed, can be a secondary label.
- Splits "Achiever" into Player vs Achiever — important distinction between points-hoarding and mastery-seeking, which have different churn profiles.
- Adds "Impact-Seeker" — unique to sustainability apps, not well-captured by existing frameworks.

**Design constraint**: Archetypes are **probabilities, not labels**. A user is 60% Achiever, 25% Learner, 15% Socializer. This enables hybrid personalization and graceful adaptation.

---

## 4. Implementation Strategy: Quiz vs Inference vs Hybrid

| Approach | Pros | Cons | Recommendation |
|----------|------|------|---------------|
| **Self-report quiz** | Easy to build, immediate profile, explicit | Low accuracy (40–60%), users dislike quiz at onboarding, stale | Use only as initial bootstrap |
| **Behavioral inference** | Accurate over time (80%+ after 2 weeks), no user friction, adapts | Cold-start problem (first week default), more complex to build | **Primary mechanism** — signals + Bayesian update |
| **Hybrid** | Best of both | Quiz required at onboarding or deferred | **Recommended** — optional "discovery quiz" (rewarded with bonus tokens) + behavioral inference refines over time |

**Recommended approach**: Start with a **default balanced profile** (equal archetype weights). Add a **deferred, rewarded "discovery quiz"** at day 3 or after 5 classifications. Use **Bayesian updating** from behavioral signals to refine archetype probabilities over the first 2–4 weeks.

---

## 5. Key Open Questions

1. **Validation methodology**: How do we know our archetype assignments are correct? User self-assessment? Retention correlation? A/B test of personalization vs non-personalized?
2. **Signal sparsity**: What archetype signals are available at low user activity (1–5 scans)? Cold start is the riskiest period.
3. **Archetype stability**: Do users change archetypes over time (e.g., Player → Achiever as they get serious)? How often should we re-evaluate?
4. **Granularity trade-off**: 5 archetypes × N challenges × personalization rules = combinatorial complexity. Can we ship with 3 primary archetypes (Achiever, Learner, Player) and iterate?
5. **Ethical risk**: Could knowing archetypes enable manipulation? (e.g., pushing vulnerable Impact-Seekers toward excessive action). What guardrails?
6. **Integration with existing gamification**: How does archetype selection affect points targets, challenge difficulty, streak goals?
7. **Premium / monetization**: Should archetype information gate premium feature suggestions? (e.g., Socializer → family features, Achiever → advanced stats)

---

## 6. Kill Criteria

This topic should be dropped or deferred if:

- **No signal at low activity**: After analyzing 500 real user sessions, fewer than 3 behavioral signals show statistically significant correlation with any archetype dimension during the first 7 days.
- **Personalization doesn't move retention**: An A/B test of personalized vs non-personalized challenge assignment shows < 2% retention lift at 4 weeks.
- **Quiz rejection > 60%**: If a self-report quiz is the only viable cold-start mechanism and > 60% of users skip it, behavioral inference alone can't bootstrap fast enough.
- **Development cost exceeds rewards**: If implementing a Bayesian inference engine + per-archetype rules + personalized UI is estimated at > 3 weeks of engineering time, consider starting with heuristic-only personalization (e.g., "if user shares often, show more social features").

---

## 7. Links

- **Parent index**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) — P1 entry #6 (Adaptive motivation profile)
- **Planning spec**: [planning/gamification-archetypes-deep-dive.md](../planning/gamification-archetypes-deep-dive.md)
- **Related**: [POINTS_ECONOMY_V2.md](POINTS_ECONOMY_V2.md), [NEGATIVE_MECHANICS_AB.md](NEGATIVE_MECHANICS_AB.md)
- **Existing exploration**: [GAMIFICATION_DEPTH.md](GAMIFICATION_DEPTH.md), [HABIT_FORMATION_LOOP.md](HABIT_FORMATION_LOOP.md)
- **Research references**: Tondello et al. (2016, 2017) — HEXAD validation; Orji et al. (2017, 2019) — personalization studies; Yee (2006) — player motivation model
