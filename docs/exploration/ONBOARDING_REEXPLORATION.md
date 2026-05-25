# Onboarding & First-Run Experience (Re-Exploration)

**Date**: 2026-05-24
**Status**: Re-exploration — updated from `docs/exploration/ONBOARDING_AND_ACTIVATION.md`
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) entry 19
**Decision this unblocks**: Whether the current onboarding plan (3-screen swipeable intro → forced first scan) is still best practice

---

## 1. Why Re-Explore

The existing exploration doc (`docs/exploration/ONBOARDING_AND_ACTIVATION.md`, 2026-05-23) proposed a 4-step flow:
1. 3-screen swipeable intro
2. Forced first scan
3. Celebration overlay
4. Progressive home screen

Industry research (May 2026) reveals that some of these patterns are now considered obsolete or suboptimal. This doc re-examines each assumption.

---

## 2. What Changed in Industry Best Practices

### 2.1 The 3-Screen Swipeable Intro is Obsolete ⚠️

**Previous assumption**: "Quick intro (3 screens, swipeable)"

**Current research**: Users have developed "onboarding blindness" — they aggressively skip or ignore swipeable feature tours. For utility apps, the industry has moved to **"learn-by-doing"** — users encounter features organically during first use, not through a slide deck.

**Recommendation**: Replace the 3-screen intro with a single **value proposition screen** (1 screen, not swipable) that shows:
- The app purpose in 5 words
- One clear CTA: "Snap your first item"

No "Know your waste," no "Snap → Learn → Dispose" tutorial — these are learned through use.

### 2.2 Immediate Plunge Beats Progressive Reveal

**Previous assumption**: Auth → Intro → Camera → Result → Home (4 steps after launch)

**Current research**: Mobile onboarding research consistently shows that **immediate plunge** (reducing steps to first value) outperforms progressive reveal for retention. Duolingo's redesign dropped users directly into a lesson; Strava opens to the record button.

**Recommendation**: **Remove the auth screen from the first-run flow.** Let users take their first photo as guest. Only prompt for auth when they want to save/ share results.

### 2.3 Forced First Scan: Effective, But Not Forced Auth

**Previous assumption**: "After auth, immediately open camera"

**Current research**: Forced first actions ARE effective if they are **clearly valuable** (scanning an item). But forcing account creation FIRST is a known dark pattern.

**Recommendation**: 
- Auto-open camera on first launch (skip auth)
- Let user scan immediately
- After result shows, prompt: "Save your results? Create a free account"
- This preserves the forced-first-scan benefit without the auth friction

### 2.4 Privacy-Preserving Onboarding Boosts Conversion

**Evidence**: Allowing anonymous use until a "save" event creates a natural, high-intent trigger point for registration. This reduces churn-at-the-door by 15-30% in published case studies.

**Recommendation**: Guest mode as default first-run experience. Auth gate moves to after first result.

---

## 3. Revised Onboarding Flow

### Step 1: Zero-friction launch (1 second to camera)
```
App Launch → Camera opens immediately
```
- No auth screen
- No intro screens
- Camera viewfinder with overlay: "Point at any waste item"
- Small hint: "Plastic bottle or banana peel work best"
- Auth button in corner: "Sign in to save results" (subtle)

**Time-to-first-action: ~3 seconds** (was ~22-47s in current flow)

### Step 2: First scan (3 seconds)
```
User captures photo → Processing → Result appears
```
- Minimal loading state
- Result shows category, disposal instructions, confidence

### Step 3: Celebration + auth prompt (post-value)
```
Result screen → "Great first sort!" celebration
→ "Create an account to save your history"
```
- Award "First Classification" achievement
- Show stats streak: Day 1
- Auth prompt is contextual (user has already received value)
- Google Sign-In is primary option
- "Continue as guest" remains available

### Step 4: Home screen (with data)
```
Home screen shows: 1 classification, 1 achievement, Day 1 streak
```
- Not empty — feels alive
- "Scan another item" CTA prominently visible
- Token balance with explanation banner (optional, collapsible)

---

## 4. Updated Funnel Metrics

| Metric | Previous Target | Revised Target | Measurement |
|---|---|---|---|
| Time-to-first-action | < 15s | < 5s | Launch to camera displayed |
| Time-to-first-classification | < 15s | < 10s | Launch to result displayed |
| First-scan completion rate | > 80% | > 85% | Camera opened → classification_completed |
| Guest → Auth conversion | N/A (forced auth) | > 40% | Auth event within 24h of first scan |
| Day-1 retention | > 50% | > 55% | DAU/installs |
| Day-7 retention | > 25% | > 30% | WAU/installs |

---

## 5. Comparison: Old Flow vs New Flow

### Old Flow (pre-re-exploration)
```
Launch → 3 intro screens → Auth screen → Home (empty) → Discover scan tab
→ Navigate to scan → Camera permission → Capture → Result
Total: 8+ taps, 22-47 seconds
```

### New Flow (post-re-exploration)
```
Launch → Camera → Capture → Result → Auth prompt (optional) → Home (with data)
Total: 2 taps, 5-10 seconds
```

### Key differences
1. **No intro screens** — learn-by-doing replaces swipeable feature tours
2. **No forced auth** — guest-first, auth after value
3. **Camera-first** — not home-first
4. **Result before home** — first screen after launch is not empty
5. **Auth is contextual** — after receiving value, not before

---

## 6. Risks and Mitigations

| Risk | Likelihood | Mitigation |
|---|---|---|
| Guest users churn before auth | Medium | Nudge at strategic moments (3rd scan, first achievement, streak day 3) |
| Camera permission prompts before value | Medium | Show permission rationale overlay before system dialog ("We need camera access to identify your waste") |
| Users confused without intro | Low | First-time overlay tooltips on key UI elements (learn-by-doing with hints) |
| Data loss between guest and auth | Medium | Save guest data locally; merge on auth; show merge indicator |
| Abandonment if camera fails | Low | Graceful fallback: file picker for existing photos |

---

## 7. Implementation Sequence

1. **Camera-first launch**: Move camera initialization to app boot, not after auth
2. **Guest-first auth**: Remove auth requirement from first-run flow; add guest mode as default
3. **Post-result auth prompt**: Add contextual sign-in prompt after first classification
4. **Guest data merge**: Implement local persistence + merge on auth
5. **Remove intro screens**: Delete or feature-flag the 3-screen swipeable intro
6. **Instrument revised funnel**: Track time-to-camera, time-to-result, guest-to-auth conversion
7. **A/B test**: Zero-friction vs old flow — measure TTV, retention, auth conversion

---

## 8. Open Questions

1. Should we show the existing "Welcome! 50 tokens" banner at all, or skip token education entirely on first run?
2. For iOS, does camera permission timing (before vs after first scan) affect permission grant rate?
3. Should guest data sync to Firebase anonymously (for cross-device) or stay purely local?
4. Is there a middle ground — 1-screen intro vs zero intro — worth A/B testing?

---

## 9. Related

- [Original Onboarding Exploration](ONBOARDING_AND_ACTIVATION.md) — previous analysis (now superseded for some recommendations)
- [Habit Formation Loop](HABIT_FORMATION_LOOP.md) — what happens after first scan
- [Gamification Redesign Spec](../planning/gamification-redesign-spec.md#7-onboarding-flow) — phased onboarding
- [Token Economy & Pricing Coherence](TOKEN_ECONOMY_AND_PRICING_COHERENCE.md) — token visibility
