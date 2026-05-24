# Motivation Archetypes — Deep Dive

**Status**: Deep-dive spec  
**Parent**: [Gamification Redesign Spec](gamification-redesign-spec.md) §6 (Adaptive System Design)  
**Purpose**: Concrete definitions, scoring heuristics, detection algorithm, and system responses for each motivation archetype  
**Date**: 2026-05-23  
**Sources**: Bartle's Taxonomy, Marczewski's HEXAD, Yee's Model, Yukai Chou's Octalysis, BJ Fogg Behavior Model

---

## 1. Frameworks Mapped

| This Spec | HEXAD | Bartle | Yee | Octalysis |
|-----------|-------|--------|-----|-----------|
| **Achiever** | Achiever + Player | Achiever | Achievement | Development & Accomplishment |
| **Explorer** | Free Spirit | Explorer | Immersion | Empowerment & Feedback |
| **Socialite** | Socialiser | Socialiser | Social | Social Influence |
| **Habit-former** | (cross-cutting) | (n/a) | (n/a) | Avoidance (Black Hat) |
| **Impact-driven** | Philanthropist | (n/a) | (n/a) | Meaning & Calling |

### Key Insight

**Habit-former** is not a standard archetype in any framework — it is a *cross-cutting behavioral mode* that any user can enter when the system is working well. It maps closest to the **Avoidance** core drive in Octalysis (fear of losing progress), but with a positive orientation (desire for consistency rather than fear). The spec treats it as a primary archetype because daily habit is the #1 outcome goal — the system should recognize and reward this mode explicitly.

**Impact-driven** maps to **Philanthropist** / **Meaning** — the user seeks purpose and real-world contribution. This is the highest-retention archetype when cultivated, but also the hardest to trigger.

---

## 2. Archetype Definitions

### 2.1 Achiever

**Core drive**: Mastery, progression, status. Wants to complete everything and be recognised.

**Behavioral signals (weighted scoring)**:

| Signal | Weight | Threshold | Notes |
|--------|--------|-----------|-------|
| Achievement completion rate | 0.25 | >60% of available achievements earned | Strong signal |
| Challenge acceptance rate | 0.20 | >70% of offered challenges accepted | High engagement with structured goals |
| Points-per-session ratio | 0.20 | Top 25% of users by points earned/session | Efficiency-focused play |
| Leaderboard check frequency | 0.15 | >1 check per 3 sessions | Social comparison drive |
| Category breadth vs depth | 0.10 | Depth >2× breadth | Prefers mastering one area over exploring |
| Correction rate (teaching others) | 0.10 | >1 correction provided per 10 classifications | Sharing mastery knowledge |

**System response**:
- Surface incomplete achievements with clear progress bars
- Offer "mastery" challenges (e.g., "50 correct plastics")
- Show leaderboard rank with next-tier nudge
- Highlight threshold: "You're 300 points from Silver tier"
- Weekly recap showing achievements earned vs peers

**Risk signals**: Declining achievement completion rate, ignoring leaderboard, skipping challenges for 7+ days → may signal demotivation or archetype shift.

---

### 2.2 Explorer

**Core drive**: Discovery, autonomy, novelty. Wants to find new things and understand the full system.

**Behavioral signals**:

| Signal | Weight | Threshold | Notes |
|--------|--------|-----------|-------|
| Category breadth (unique categories scanned) | 0.30 | >4 categories in first 10 scans | Strong early signal |
| Educational content consumption | 0.20 | >50% of available content viewed | Learning-driven |
| Hidden feature discovery rate | 0.15 | Interacts with non-obvious UI elements | System explorer |
| Scanning of unfamiliar/lower-confidence items | 0.15 | Scans items with <70% AI confidence | Boundary-pushing |
| Settings/profile exploration | 0.10 | Visits settings, help, about screens | System understanding |
| Batch analysis usage | 0.10 | Uses batch mode >1×/week | Power-user curiosity |

**System response**:
- Surface discovery challenges ("Scan a medical waste item")
- Show category completion map ("You've explored 3/5 categories")
- Highlight unvisited features with gentle "Did you know?" prompts
- Offer hidden/emergent achievements (v2)
- Recommend educational content for categories not yet scanned

**Risk signals**: Scanning only one category for 5+ consecutive sessions, ignoring educational prompts → may need a discovery challenge intervention.

---

### 2.3 Socialite

**Core drive**: Connection, belonging, social proof. Wants to interact, compare, and contribute to the community.

**Behavioral signals**:

| Signal | Weight | Threshold | Notes |
|--------|--------|-----------|-------|
| Community feed interaction frequency | 0.25 | >1 interaction per 2 sessions | Posting, commenting, reacting |
| Leaderboard/social screen views | 0.20 | Views social screens >30% of sessions | Comparison drive |
| Corrections provided to others | 0.20 | >1 correction per 5 classifications | Teaching/helping behavior |
| Sharing rate (results, achievements) | 0.15 | >1 share per 10 sessions | External social validation |
| Family/household activity (v2) | 0.10 | Participates in group features | Team motivation |
| Referral/signup invites | 0.10 | Invites friends to app | Network growth behavior |

**System response**:
- Surface community challenges ("Help 3 users with corrections")
- Show leaderboard milestones and position changes
- Offer "friend" leaderboard (compare with people you know)
- Prompt sharing on achievement unlock
- Highlight community contributions ("Your corrections helped 5 people")

**Risk signals**: Leaderboard-only engagement with no contributions, excessive comparison without participation → may be passive socialite; needs community challenge nudge.

---

### 2.4 Habit-former

**Core drive**: Consistency, routine, progress preservation. Cares most about not breaking the chain.

**Behavioral signals**:

| Signal | Weight | Threshold | Notes |
|--------|--------|-----------|-------|
| Daily return rate | 0.35 | >80% of days active in past 14 days | Core signal |
| Streak reactivation speed | 0.20 | Returns to app within 48 hours after streak break | Resilience signal |
| Session timing consistency | 0.15 | Visit times vary <2 hours day-to-day | Fixed routine |
| Streak screen views | 0.10 | Views streak/progress screen daily | Actively tracking |
| Notification response rate | 0.10 | Opens app within 30 min of notification | Prompt-responsive |
| Minimal session depth | 0.10 | Completes minimum engagement (1 scan) then leaves | Efficiency — doing the minimum to maintain |

**System response**:
- Surface streak protections (freeze, shield) prominently
- Show streak milestones with clear progress ("7 days → 14 days → 30 days")
- Offer streak-based achievements
- Provide daily reminders at user's typical time
- Display "streak saved" confirmation after each session
- Weekly summary: "You classified 7 days in a row this week"

**Risk signals**: Missed 2+ consecutive days, streak freeze not activated → may be at risk of churn; intervene with reduced-commitment prompt ("Just 1 scan to save your streak").

---

### 2.5 Impact-driven

**Core drive**: Meaning, purpose, contribution to something larger than themselves.

**Behavioral signals**:

| Signal | Weight | Threshold | Notes |
|--------|--------|-----------|-------|
| Impact/environmental screen views | 0.30 | Views impact stats >1×/week | Seeking meaning |
| Eco-impact spending (points sink) | 0.25 | >30% of points spent on eco-impact | Values real-world action |
| Result screen "impact saved" engagement | 0.15 | Actively reads impact narrative | Engagement with metrics |
| Safety-critical classification accuracy | 0.15 | Correctly handles hazardous items | Values correct disposal |
| Educational content completion rate | 0.10 | Learns about environmental impact | Knowledge-seeking |
| Sharing of impact data | 0.05 | Shares "I diverted X kg of waste" | External purpose validation |

**System response**:
- Surface eco-impact metrics prominently on profile
- Show real-world impact narrative ("Your sorting prevented 2.3kg of contamination")
- Offer impact leaderboard (carbon diverted, not points)
- Highlight safety-critical achievements ("Safety First badge")
- Recommend educational content on environmental impact of waste
- Seasonal eco-challenges ("30-day carbon reduction challenge")

**Risk signals**: Declining eco-impact spending, ignoring impact screens → may be transitioning to a different archetype. Don't force impact narrative; let the user rediscover it.

---

## 3. Detection Algorithm

### 3.1 Signal Collection

```dart
class MotivationSignalCollector {
  // Session-level signals — collected after every session
  Future<SessionSignals> collectSessionSignals(UserSession session) async {
    return SessionSignals(
      categoriesScanned: session.categoriesScanned,
      completionRate: session.completedActions / session.startedActions,
      sessionDepth: session.actionCount,
      screensVisited: session.screens,
      timeOfDay: session.startTime.hour,
      challengesAccepted: session.challengesAccepted,
      challengesCompleted: session.challengesCompleted,
      communityActions: session.communityInteractions,
      achievementsViewed: session.achievementScreenVisits,
      pointsEarned: session.pointsEarned,
      impactViews: session.impactScreenVisits,
      streakChecked: session.streakScreenVisits,
    );
  }
  
  // Aggregated profile — computed periodically
  MotivationProfile computeProfile(List<SessionSignals> recentSessions) {
    // Step 1: Calculate archetype scores based on weighted signals
    // Step 2: Apply confidence levels based on total session count
    // Step 3: Check for narrowing signals
    // Step 4: Return profile with dominant and secondary archetypes
  }
}
```

### 3.2 Scoring Formula

For each archetype A, score = Σ(weight_i × normalized_signal_i × recency_factor)

**Recency factor**: Exponential weighting — recent 7 days weighted 2×, days 8–14 weighted 1×, days 15+ weighted 0.5×. This prevents profiles from being locked in by old behavior.

**Normalization**: Each signal is normalized to a 0–1 range using percentile ranking against the global user base (clamped at P95 to avoid outlier skew).

### 3.3 Confidence Levels

| Sessions Collected | Confidence | Behavior |
|-------------------|------------|----------|
| 0–3 | None | Balanced default. No profiling. |
| 4–10 | Low | Tentative suggestions only. Do not commit to profile. |
| 11–21 | Medium | Profile updates applied. Lightweight adaptations. |
| 22–42 | High | Full adaptive system engaged. Profile is trusted. |
| 43+ | Sustained | Profile stable. Only gradual drift adjustments. |

### 3.4 Profile Structure

```dart
class MotivationProfile {
  // Primary archetype (highest confidence score)
  MotivationArchetype primary;
  
  // Secondary archetype (may be None if confidence is low)
  MotivationArchetype? secondary;
  
  // Raw scores for all archetypes (0.0–1.0)
  Map<MotivationArchetype, double> rawScores;
  
  // Confidence in the profile (based on session count + stability)
  ProfileConfidence confidence;
  
  // When the profile was last updated
  DateTime lastUpdate;
  
  // Detection history — for debugging and optional reveal
  List<ProfileSnapshot> history;
}

enum MotivationArchetype {
  achiever,
  explorer,
  socialite,
  habitFormer,
  impactDriven,
}

enum ProfileConfidence { none, low, medium, high, sustained }
```

### 3.5 Narrowing Detection

The system continuously monitors for behavioral narrowing — when a user's engagement contracts into a smaller range of actions than their baseline.

| Narrowing Type | Detection | Intervention |
|----------------|-----------|--------------|
| Category narrowing | Categories scanned per week drops >50% from baseline | Discovery challenge for untouched category |
| Challenge narrowing | Same challenge type accepted ≥3 consecutive times | Counterbalance challenge of opposite type |
| Social withdrawal | Community interactions drop >60% over 7 days | Light community contribution prompt |
| Impact disengagement | Impact screen views drop to 0 over 14 days | Re-surface impact narrative in result flow |
| Explorer contraction | Category breadth drops while depth increases | Discovery or amplification challenge |
| Habit fragility | Session consistency drops >30% | Streak protection prompt, reduce challenge load |

### 3.6 Re-Evaluation Cadence

| Trigger | Action |
|---------|--------|
| Every 7 sessions (minimum) | Recompute profile scores, check for shifts |
| After a streak break | Check if habit-former score drops significantly |
| After a major feature interaction | Immediately incorporate new signals |
| After 14 days of inactivity | Flag profile as stale; reset to balanced defaults on return |
| Manual override (optional reveal screen) | Let user explicitly adjust profile weights |

---

## 4. System Responses by Archetype

### 4.1 Home Screen Priority

| Archetype | Home Card 1 | Home Card 2 | Home Card 3 |
|-----------|-------------|-------------|-------------|
| Achiever | Achievement progress | Leaderboard rank | Daily challenge |
| Explorer | New/unvisited category | Educational content | Discovery challenge |
| Socialite | Community feed highlights | Friend activity | Community challenge |
| Habit-former | Streak status | Quick scan (1-tap) | Daily reminder time |
| Impact-driven | Impact saved (today) | Eco-impact leaderboard | Safety highlights |

### 4.2 Notification Strategy

| Archetype | Best Send Time | Notification Content |
|-----------|---------------|---------------------|
| Achiever | Morning (7–9 AM) | "You're 50 points from Silver tier — 2 scans could do it" |
| Explorer | Afternoon (2–4 PM) | "You haven't scanned medical waste yet — want to try?" |
| Socialite | Evening (6–8 PM) | "Your friend Jane just passed you on the leaderboard" |
| Habit-former | User's typical time | "Don't break your 12-day streak — 1 scan saves it" |
| Impact-driven | Any time | "Your sorting saved 0.5kg of CO₂ this week" |

### 4.3 Challenge Preference

| Archetype | Preferred Challenge Type | Least Preferred |
|-----------|------------------------|-----------------|
| Achiever | Amplification, Weekly | Discovery (no points focus) |
| Explorer | Discovery, Daily (new items) | Amplification (too repetitive) |
| Socialite | Community, Weekly | Solo amplification |
| Habit-former | Daily (quick wins), Streak | Long-term Weekly |
| Impact-driven | Counterbalance (safety), Discovery | Pure point-chase |

---

## 5. Profile Detection State Machine

```
[No Profile] → (4+ sessions) → [Tentative]
                                    ↓
                          (11+ sessions)
                                    ↓
                           [Confirmed]
                            ↓        ↓
                  (stable for 14 days)  (large shift detected)
                           ↓                  ↓
                     [Sustained]      [Re-evaluating → Tentative]
```

**Transitions**:
- **No Profile → Tentative**: First suggestions appear. Everything is optional.
- **Tentative → Confirmed**: System begins adaptive weighting. Profile screen becomes available.
- **Confirmed → Sustained**: Profile is trusted. Only gradual drift adjustments. No major shifts without strong evidence.
- **Any → Re-evaluating**: Triggered by sustained behavioral change for 14+ days. Profile demotes back to Tentative until new pattern is confirmed.

---

## 6. Edge Cases

| Edge Case | Handling |
|-----------|----------|
| **New user has strong early signals (classifies 10 categories in first session)** | Profile stays Tentative until 11+ sessions. Quick observations create suggestions but not commitments. |
| **User clearly exhibits two archetypes equally** | Both are stored (primary/secondary). System blends responses from both with 60/40 weight split. |
| **User's behavior shifts gradually over weeks** | Drift tracking: compare rolling 7-day profile against 30-day baseline. If difference >20%, initiate re-evaluation. |
| **User returns after 3+ months away** | Profile reset to balanced defaults. Previous data archived but not applied. Start fresh with No Profile state. |
| **User explicitly overrides profile suggestion** | Record override. Adjust profile weights 15% toward user's choice. Do not override again for 30 days in same direction. |
| **User has no clear dominant archetype after 42 sessions** | Stay in "balanced" mode. The system supports all archetypes equally and just provides variety. Not every user needs a profile. |

---

## 7. Profile Visibility (Optional Reveal)

The dedicated profile screen shows:
- Current detected archetype(s) with confidence indicator
- Raw scores for all 5 archetypes
- Recent behavioral highlights that drove detection
- Manual override controls (tilt weights, lock profile, reset to balanced)
- "How this works" explanation (plain language)

**UI principle**: The screen exists but is deliberately one tap deep. Users who want to understand the system can find it; users who don't care never see it.

---

## 8. Related

- [Gamification Redesign Spec](gamification-redesign-spec.md) — parent specification
- [Points Economy Deep Dive](gamification-points-economy-deep-dive.md) — economic layer
- [Negative Mechanics A/B Design](gamification-negative-mechanics-ab-design.md) — deferred experiment
- [Gamification Depth](../exploration/GAMIFICATION_DEPTH.md) — v2 foundation
