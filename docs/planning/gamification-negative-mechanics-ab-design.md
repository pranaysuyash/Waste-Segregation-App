# Negative Mechanics — A/B Experiment Design

**Status**: Deep-dive spec — experiment design (not implementation)  
**Parent**: [Gamification Redesign Spec](gamification-redesign-spec.md) §11 (Negative Mechanics) and §3.5 (explore more)  
**Purpose**: Design a rigorous A/B experiment to determine whether negative mechanics improve long-term retention without harming user trust  
**Date**: 2026-05-23  
**Sources**: Duolingo streak freeze data, Habitica damage system, Yu-kai Chou Octalysis (Black Hat drives), behavioral economics (loss aversion, endowment effect)

---

## 1. Research Question

**Primary**: Do negative mechanics (streak-only reset, passive point decay, challenge failure cost) improve 30-day and 90-day retention compared to a pure positive system?

**Secondary**: 
- Do negative mechanics increase daily active usage at the cost of session quality?
- Do negative mechanics disproportionately affect certain motivation archetypes?
- What is the churn cliff impact of a negative event (e.g., losing a streak, decaying below a tier threshold)?

---

## 2. Experiment Design

### 2.1 Phase Structure

The experiment runs in **3 phases** over 6 months:

| Phase | Duration | Purpose | Participants |
|-------|----------|---------|--------------|
| Phase 0: Baseline | 30 days (pre-experiment) | Measure baseline retention, churn, and engagement metrics | All users |
| Phase 1: Single-variant | 60 days | Test Streak-Only Reset (lowest risk negative mechanic) vs Control | New users only (to avoid history effects) |
| Phase 2: Multi-variant | 60 days | Test 3 negative variants + Control | Phase 1 users continue; new cohort added |

**Total experiment duration**: 5 months (1 month baseline + 2 months Phase 1 + 2 months Phase 2)

### 2.2 Variants

#### Phase 1: Streak-Only Reset (A/B)

| Variant | Description | Users |
|---------|-------------|-------|
| **Control** (A) | Pure positive v1 gamification. Streaks break silently — no notification, no penalty. New streak starts from 1 on next visit. Points never decrease. | 50% |
| **Streak Reset** (B) | Streaks break after 1 day of inactivity. User receives notification: "Your 14-day streak has ended." Streak counter shows last length. New streak starts from 1. Points never decrease. | 50% |

#### Phase 2: Multi-Variant

| Variant | Description | Users |
|---------|-------------|-------|
| **Control** (A) | Same as Phase 1 Control | 25% |
| **Streak Reset** (B) | Same as Phase 1 B | 25% |
| **Streak Reset + Decay** (C) | Streak breaks after 1 day. Additionally, points decay 5% per week of inactivity (14+ days inactive, points decay by 5% per week, max decay 50% of current total). Tier never decays (cannot lose tier). | 25% |
| **Streak Reset + Challenge Cost** (D) | Streak breaks after 1 day. Additionally: accepting a challenge costs 10 points (returned if completed within deadline). Challenge failure (deadline missed) costs additional 10 points. | 25% |

### 2.3 Phase 2 Selection Criteria

Users from Phase 1 roll into Phase 2 with their same variant (A stays A, B stays B). New cohort is randomly assigned to A/B/C/D.

This creates a clean within-subjects continuation for A/B and a between-subjects comparison for C/D.

---

## 3. Hypotheses

| Hypothesis | Variant | Expected Direction | Minimum Detectable Effect |
|-----------|---------|-------------------|--------------------------|
| H1: Streak reset notification increases 30-day retention | B | +5% vs A | 3% (α=0.05, β=0.80) |
| H2: Streak reset notification increases 7-day return rate after break | B | +10% vs A | 5% |
| H3: Point decay increases 14-day re-engagement after inactivity | C | +8% vs A | 5% |
| H4: Challenge cost increases challenge completion rate | D | +15% vs A | 10% |
| H5: Challenge cost decreases challenge acceptance rate | D | -20% vs A | 10% |
| H6: All negative variants decrease NPS (Net Promoter Score) | B/C/D | -5 points vs A | 3 points |
| H7: All negative variants increase app uninstall rate | B/C/D | +2% vs A | 1% |
| H8: Point decay disproportionately harms Impact-driven users | C | -10% retention for Impact vs other archetypes | 5% |
| H9: Streak reset disproportionately harms Habit-formers but increases their return rate | B | Habit-formers: -5% retention but +15% return rate after break | 5% |

---

## 4. Success Metrics

### 4.1 Primary Metrics

| Metric | Collection Method | Evaluation Window |
|--------|------------------|-------------------|
| Day-30 retention (did user classify in days 28–32?) | Analytics event | 30 days post-enrollment |
| Day-90 retention | Analytics event | 90 days post-enrollment |
| 7-day return rate after streak break (Variant B/C/D) | Streak event + login | 7 days post-break |
| 14-day re-engagement after inactivity (Variant C) | Login + classify event | 14 days post-decay-trigger |

### 4.2 Secondary Metrics

| Metric | Purpose | Collection |
|--------|---------|------------|
| Sessions per week | Engagement volume | Session event |
| Points earned per session | Effort level | Points event |
| Challenge acceptance rate (Variant D) | Fear of cost | Challenge event |
| Challenge completion rate (Variant D) | Accountability effect | Challenge event |
| App uninstall rate | Churn from negativity | Firebase analytics |
| NPS (in-app survey, shown once after 30 days) | User sentiment | Survey response |
| Support contact rate (negative mechanics related) | User distress | Support ticket tag |
| Streak freeze purchase rate (if available) | Mitigation behavior | Purchase event |
| Category breadth | Quality of engagement | Classification event |
| Session time-of-day distribution | Routine formation | Session event |

### 4.3 Guardrail Metrics (Must Not Degrade)

| Metric | Threshold | Action if Breached |
|--------|-----------|-------------------|
| App uninstall rate | >+3% vs control for 7 consecutive days | Kill the variant immediately |
| NPS | >-10 points vs control | Kill the variant, email affected users |
| Support contact rate (negative mechanics) | >2× control on any day | Investigate, pause variant |
| Daily active users (variant segment) | >-10% for 3 consecutive days | Kill the variant |

---

## 5. Sample Size & Power Analysis

### 5.1 Phase 1

| Metric | Expected Control Rate | MDE | Required Users Per Arm | Total |
|--------|---------------------|-----|----------------------|-------|
| Day-30 retention | 25% | +5% (absolute) | 2,622 | 5,244 |
| Day-90 retention | 15% | +5% (absolute) | 1,768 | 3,536 |

**Phase 1 requires ~5,244 new users total (2,622 per arm)**. At current acquisition rates (~500 new users/week), Phase 1 enrollment period ≈ 10 weeks.

**Window**: If acquisition is slower, run Phase 1 for 60 days regardless of sample size (the data is still useful, just with wider confidence intervals).

### 5.2 Phase 2

| Metric | MDE | Required Users Per Arm | Total (4 arms) |
|--------|-----|----------------------|----------------|
| Day-30 retention | +7% (absolute vs control) | 1,343 | 5,372 |
| Day-90 retention | +7% | 907 | 3,628 |

**Phase 2 requires ~5,372 new users** (or continuation of Phase 1 users + new cohort).

---

## 6. Ethical Guardrails

### 6.1 Pre-Experiment Commitments

1. **Informed via privacy policy**: Gamification mechanics may involve performance-based feedback and progression systems
2. **No surprise negativity**: All negative mechanics are documented in the help center before the experiment begins
3. **Kill switch per variant**: Any variant can be killed instantly via Remote Config
4. **Opt-out**: Users who contact support about negative mechanics are opted out of their variant and moved to Control

### 6.2 During Experiment

1. **Daily monitoring**: Guardrail metrics checked daily. Any breach triggers investigation
2. **Weekly report**: Automated report comparing all variants on primary + secondary metrics
3. **Exit survey**: Users who uninstall during the experiment are shown a brief survey including the option "Gamification felt too punishing"

### 6.3 Post-Experiment

1. **Worst variant killed**: The variant with the worst combined retention + NPS is immediately deactivated
2. **Neutral/positive variants continue**: If a variant shows neutral or positive results, it continues while data accumulates
3. **Winner promoted**: If any variant significantly outperforms control after 90 days with no guardrail breach, it becomes the new default
4. **Transparency**: Experiment results published internally. Users are not individually informed (A/B tests are standard product practice)

### 6.4 Hard Kill Criteria

The entire negative mechanics experiment is killed if any of these occur:

| Criterion | Rationale |
|-----------|-----------|
| Any variant causes >5% uninstall rate increase sustained over 14 days | Unacceptable user harm |
| Support receives >50 negative-mechanics-related complaints in 1 week | User distress signal |
| App store rating drops by >0.5 stars (rolling 30-day) | External reputation damage |
| Negative press or social media backlash | Brand risk |

---

## 7. Analysis Plan

### 7.1 Primary Analysis

- **Frequentist**: Chi-square test for retention rates between variants at 30 and 90 days
- **Bayesian**: Beta-Binomial model to estimate probability that each variant is best
- **Subgroup**: Pre-registered subgroup analysis by motivation archetype (after the archetype detection system is active)

### 7.2 Time-to-Event Analysis

- **Kaplan-Meier curves**: Survival analysis for time-to-churn for each variant
- **Cox proportional hazards**: Hazard ratio for each variant vs control, controlling for:
  - Active days in first week (engagement level)
  - Motivation archetype (once available)
  - App version
  - Device type

### 7.3 Heterogeneity Analysis

- **Archetype interaction**: Do negative mechanics affect Achievers differently than Habit-formers?
- **Engagement level**: Do high-engagement users handle negativity better than casual users?
- **Tenure**: Do users with 30+ days of history respond to negative mechanics differently than new users?

### 7.4 Decision Criteria

| Outcome | Decision |
|---------|----------|
| Variant significantly improves retention AND no guardrail breach | Promote to default |
| Variant not significantly different from control AND no guardrail breach | Continue running for additional 60 days or kill (cost-benefit) |
| Variant significantly improves retention BUT breaches guardrail | Do not promote. Document as cautionary finding. |
| Variant significantly harms retention OR breaches guardrail | Kill immediately. |

---

## 8. Implementation Requirements

### 8.1 Engineering Requirements to Run This Experiment

1. **Experiment framework**: A/B assignment at enrollment (new user signup), variant stored in user profile
2. **Sticky assignment**: User stays in same variant for the duration. No switching.
3. **Analytics instrumentation**:
   - Streak break event (when streak ends)
   - Point decay event (when decay is applied)
   - Challenge cost event (cost applied or returned)
   - All standard engagement events tagged with `experiment_variant`
4. **Guardrail monitoring dashboard**: Real-time or daily batch
5. **Kill switch**: Remote Config per variant (instant deactivation)
6. **Support escalation path**: Support agents can opt user out of experiment variant

### 8.2 What Must Ship in v1 Before This Experiment

- Pure positive gamification (v1 core)
- Achievement system + tiers
- Challenge system
- Points sinks (all 4)
- Streak tracking (without reset notification)
- Motivation archetype detection (needed for heterogeneity analysis)
- Analytics instrumentation for all engagement events

**Minimum viable experiment timing**: v1 core must ship first. Experiment cannot start until 30 days of baseline data are collected.

---

## 9. Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| Negative mechanics harm retention | Medium | High | Guardrails + kill criteria catch this early. Phase 1 tests lowest-risk variant first. |
| Experiment results are inconclusive (small sample size) | Medium | Medium | Pre-registered Bayesian analysis handles uncertainty. If inconclusive, extend enrollment. |
| Users notice and complain publicly | Low | Medium | Opt-out available. Kill criteria includes public backlash monitoring. |
| Streak reset causes Habit-former churn (opposite of intended) | Medium | High | Subgroup analysis catches this. If Habit-formers churn more, variant is killed. |
| Point decay (Phase 2, Variant C) feels like a bug | Medium | Medium | Show tooltip: "Points decay during inactivity. Return to maintain your balance." Communication is key. |
| Challenge cost (Phase 2, Variant D) reduces challenge participation to near zero | High | Medium | If acceptance rate drops below 10%, the mechanic has failed its purpose. Kill variant. |

---

## 10. Timeline

| Week | Event |
|------|-------|
| Pre-0 | Ship v1 pure positive gamification |
| 0–4 | Phase 0: Baseline data collection (all users) |
| 4–12 | Phase 1: Streak-Only Reset vs Control |
| Week 8 | Phase 1 interim analysis (4-week data) |
| Week 12 | Phase 1 final analysis. Gate decision: proceed to Phase 2? |
| 12–20 | Phase 2: Multi-variant (if Phase 1 was safe) |
| Week 16 | Phase 2 interim analysis (4-week data) |
| Week 20 | Phase 2 final analysis. Decision: promote variant or kill all. |

**Total**: 20 weeks from v1 ship.

---

## 11. Related

- [Gamification Redesign Spec](gamification-redesign-spec.md) — parent specification
- [Archetype Deep Dive](gamification-archetypes-deep-dive.md) — motivation profile layer (needed for heterogeneity analysis)
- [Points Economy Deep Dive](gamification-points-economy-deep-dive.md) — economic layer
- [Gamification Depth](../exploration/GAMIFICATION_DEPTH.md) — v2 foundation
