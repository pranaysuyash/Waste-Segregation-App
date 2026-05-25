# Negative Mechanics Research & A/B Experiment Framework

**Decision it unblocks**: Whether to introduce negative reinforcement mechanics (streak breaks, progress decay, challenge failure consequences) into the app, and if so, under what ethical guardrails and experimental design.

**Status**: Active — 2026-05-21  
**Key questions open**: 5 of 9 resolved  
**Kill criteria**: see below  

---

## 1. Why This Exploration

The gamification A/B design spec proposes experiments with negative mechanics — specifically, whether introducing consequences for missed activity (beyond losing a streak) can improve long-term retention without causing anxiety, guilt, or churn.

This exploration assesses:
1. What industry evidence exists for negative mechanics in habit apps?
2. What are the documented risks and failure modes?
3. What ethical guardrails should constrain any experiment?
4. What sample sizes, durations, and metrics are needed?

---

## 2. Key Research Findings

### 2.1 The Evidence Base for Negative Mechanics

**Streak mechanics** are the most-studied negative-adjacent mechanic in consumer apps. Key findings:

| Finding | Source | Quality |
|---------|--------|---------|
| Streaks increase DAU 15–30% in language learning | Duolingo (von Ahn, various talks) | Industry report (credible) |
| Streak-freeze (mitigation) increases long-term retention | Duolingo A/B test results | Industry (published) |
| Users who lose streaks have higher churn in following 7 days | Multiple app studies | Correlational |
| Loss aversion is ~2× stronger motivator than equivalent gain | Kahneman, Tversky (1979) + replications | Academic (gold standard) |

**However**, the evidence for *introducing* negative mechanics (adding them where none existed) is weaker:

- **Decay mechanics** (progress decreasing over time): Studied in games (EVE Online, FarmVille). Evidence shows they drive short-term re-engagement but increase long-term churn. Users who experience decay are 20–40% more likely to quit within 30 days (various game industry postmortems).
- **Challenge failure penalties**: No published studies on habit apps. In gamified learning, penalty-based challenge systems show mixed results — some users are motivated, others disengage. The effect depends heavily on perceived fairness (was the penalty avoidable?) and magnitude (small penalty = engagement, large penalty = churn).

**Bottom line**: The strongest evidence supports **streak maintenance as a soft negative mechanic** (you lose your streak if you miss a day, but can freeze it). There is **no strong evidence** that adding harder negative mechanics (decay, penalties) improves long-term retention in utility/habit apps.

### 2.2 Ethical Landscape and Dark Pattern Risk

**Negative mechanics that are commonly classified as dark patterns**:

| Mechanic | Dark Pattern Classification | Industry Guidance |
|----------|---------------------------|-------------------|
| Streak break (lose progress) | 🟡 Borderline — depends on severity | Acceptable if user can recover |
| Progress decay (points decrease) | 🔴 High — loss of earned value | Strongly advised against |
| Challenge failure penalty (lose points) | 🟡 Borderline — depends on consent | Acceptable if opt-in and avoidable |
| Notification guilt-tripping | 🔴 High — emotional manipulation | Avoid |
| Artificial urgency (24h timer) | 🟡 Borderline — depends on context | Acceptable for optional challenges |

**Key ethical principle from research**: Negative mechanics are acceptable when:
1. **Opt-in transparently**: User knows the consequences before engaging
2. **Avoidable through normal use**: Consistent users never experience penalty
3. **Recoverable**: Lost progress can be regained (not permanently destroyed)
4. **Proportional**: Cost of failure scales reasonably to the benefit of success
5. **Vulnerable-user-safe**: No mechanics that could harm users with anxiety disorders, OCD, or addiction vulnerability

**Recommendation**: Default position: **Points never decrease**. Any loss mechanic must pass all five criteria above and be gated behind an explicit opt-in challenge system (not applied to the core experience).

### 2.3 What Production Apps Actually Do

| App | Negative Mechanics | Outcome |
|-----|-------------------|---------|
| **Duolingo** | Streak break (no freeze = reset), Heart system (5 lives, lose one per mistake) | Both have mitigation (streak freeze, heart refill via practice). Hearts controversial — some users report anxiety. |
| **Habitica** | Health loss on missed dailies, death at zero HP (lose all gear progress) | Most hardcore negative mechanic among habit apps. Creates strong motivation but high churn for casual users. |
| **Headspace** | No negative mechanics | Deliberate design choice — positive reinforcement only |
| **Streaks (iOS)** | Streak break (resets counter) | No freeze — but also no penalty beyond counter reset |
| **Forest** | Tree dies if you leave the app | Strong guilt mechanic — but opt-in (you choose to plant) |

**Key observation**: Every major habit app that uses negative mechanics also provides **recovery paths**. No successful app uses pure punitive design without the ability to restore progress. The most sustainable pattern is **challenge → fail → recover → try again**, not **challenge → fail → lose permanently**.

---

## 3. Proposed Experiment Framework

### 3.1 Guiding Principles

1. **First, do no harm**: No experiment should degrade the user's core experience. Experiments are opt-in (or opt-out with clear disclosure).
2. **Points never decrease**: No mechanic removes earned points. Loss is limited to streak counters, challenge progress, or timer-based opportunities.
3. **Self-limiting duration**: Any negative-mechanics experiment runs max 4 weeks. After that, either promote to permanent (with user-facing opt-in) or kill.
4. **Guardrail metrics**: If any guardrail metric (see §3.4) triggers, auto-halt the experiment.

### 3.2 Experiment Candidates (Lowest Risk First)

#### Candidate A: Challenge Failure = Point Delay (Not Loss)
> User accepts a time-bound challenge (e.g., "scan 5 items this week"). If they fail, they don't lose points — they simply can't attempt a new challenge for 24 hours (cooldown).
- **Risk**: Very low — no loss of earned value, only opportunity cost
- **Expected effect**: May increase challenge completion rate by reducing overwhelm
- **Sample size needed**: ~500 users per variant (2 weeks)
- **Guardrail**: Challenge attempt rate doesn't drop > 20%

#### Candidate B: Streak Multiplier (Not Break)
> Instead of breaking the streak, points earned during a streak-protected day are not multiplied. No streak counter resets.
- **Risk**: Low — no loss, just missed bonus
- **Expected effect**: May maintain streak motivation without break-induced churn
- **Sample size**: ~1,000 users per variant (3 weeks)
- **Guardrail**: DAU doesn't drop > 5% in treatment group

#### Candidate C: Opt-In "Hard Mode" Challenges
> User explicitly opts into a challenge with real failure consequences (e.g., "I pledge to scan daily for 7 days. If I miss a day, I lose 50 points — but if I succeed, I earn 200 points").
- **Risk**: Medium — loss is real but user-consented
- **Expected effect**: Strengthens commitment for motivated users, may increase churn for marginal users
- **Sample size**: ~2,000 per variant (4 weeks)
- **Guardrail**: Opt-in rate > 5%; churn in treatment group not higher than control by > 3 percentage points

### 3.3 Power Analysis and Timeline

| Experiment | Minimum Sample (per variant) | Duration | Statistical Power |
|-----------|------------------------------|----------|-------------------|
| A (Delay) | 500 | 2 weeks | 80% @ 5% retention lift |
| B (Multiplier) | 1,000 | 3 weeks | 80% @ 5% retention lift |
| C (Hard Mode) | 2,000 | 4 weeks | 80% @ 10% retention lift |

**Note**: These assume current MAU of ~5,000–10,000. If MAU is lower, experiments must run longer or accept lower statistical power. At current MAU, only Experiment A is feasible in < 4 weeks.

### 3.4 Guardrail Metrics (Auto-Halt Conditions)

Any experiment auto-halts if:

| Metric | Threshold | Action |
|--------|-----------|--------|
| **Treatment churn rate** | > 3 percentage points above control at 7 days | Halt immediately |
| **Support/ticket volume** | > 2× baseline for "app is punishing me" category | Halt and review |
| **Negative review rate** | > 20% of treatment group reviews are 1–2 star | Halt and review |
| **Session length** | < 70% of control (treatment group) | Halt (guilt-induced rapid exit) |
| **Opt-out/disable rate** | > 15% of treatment users disable the feature | Halt (users actively rejecting it) |

### 3.5 Ethics Review Checklist

Before any negative-mechanics experiment launches:

- [ ] Does the mechanic violate the "points never decrease" principle?
- [ ] Is the mechanic opt-in (user chooses to engage)?
- [ ] Is the consequence transparently disclosed before user commits?
- [ ] Is there a recovery path (user can regain lost status)?
- [ ] Is the penalty proportional to the benefit of success?
- [ ] Is there a manual kill-switch for the operator?
- [ ] Has a human reviewed: could this harm vulnerable users?
- [ ] Is the experiment duration bounded (max 4 weeks)?
- [ ] Are at least 2 guardrail metrics tied to auto-halt logic?

---

## 4. Recommended Decision

**Default posture**: Ship only **Experiment A (challenge cooldown)** and **Experiment B (streak multiplier)**. The evidence does not support real point-loss mechanics in a utility/sustainability app whose primary goal is pro-social behavior change. The risk of guilt, churn, and negative reviews outweighs the uncertain retention benefit.

**Experiment C (Hard Mode)** should be deferred until the app has:
- ≥ 20,000 MAU (statistical power to detect realistic effects)
- A demonstrated positive retention baseline (so we're improving on good, not rescuing bad)
- A user trust signal (NPS > 30, app store rating > 4.0) that suggests users will interpret opt-in challenges fairly

---

## 5. Key Open Questions

1. **Does our current user base even want negative mechanics?** Before any experiment, run a small user survey (N = 50–100) asking about motivation: "What keeps you scanning? Would consequences for missing a day help or hurt?"
2. **What is the interaction with archetype?** The Motivation Archetypes exploration suggests Achievers and Players may respond positively to negative mechanics, while Learners and Impact-Seekers may respond negatively. Can we personalize which users see which mechanics?
3. **How do we measure "guilt" vs "motivation"?** Standard metrics (DAU, retention) can't distinguish. Need a sentiment signal — either post-experiment survey, app store review analysis, or session-level behavioral signals (rapid exit after notification).
4. **What about seasonal effects?** Holiday season (lower app engagement) could make any negative mechanic look worse than it is. Time the experiment for a "normal" engagement period.
5. **Can we A/B the perception, not the mechanic?** Before building expensive mechanics, test copy only — show users different messages about streak status and measure emotional response (survey) vs behavioral change.

---

## 6. Kill Criteria

- **User survey shows > 40% oppose any negative mechanic**: Don't experiment. Pure positive reinforcement path.
- **No signal from Experiments A+B**: If neither shows a statistically significant retention effect after running for the required duration, the entire negative mechanics track is abandoned. The app does not need this mechanic family.
- **Any guardrail metric triggered more than once**: If any experiment auto-halts, the next experiment requires a higher ethical bar and explicit CEO/PM approval.
- **Negative review spike during any experiment**: > 2× baseline negative reviews. This signals user backlash that no retention metric can justify.

---

## 7. Links

- **Parent index**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) — P1 entry #8 (Negative mechanics research)
- **Planning spec**: [planning/gamification-negative-mechanics-ab-design.md](../planning/gamification-negative-mechanics-ab-design.md)
- **Related**: [MOTIVATION_ARCHETYPES.md](MOTIVATION_ARCHETYPES.md), [POINTS_ECONOMY_V2.md](POINTS_ECONOMY_V2.md)
- **Existing exploration**: [GAMIFICATION_DEPTH.md](GAMIFICATION_DEPTH.md), [HABIT_FORMATION_LOOP.md](HABIT_FORMATION_LOOP.md)
- **Research references**: von Ahn (Duolingo); Kahneman & Tversky (Prospect Theory); various game industry postmortems on decay mechanics
