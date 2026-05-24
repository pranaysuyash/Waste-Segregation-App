# Onboarding & Activation

**Date**: 2026-05-23
**Status**: Exploration — funnel analysis and activation strategy
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) entry 19
**Decision this unblocks**: Any growth/acquisition spend; without this, install $$ leaks immediately
**Kill criteria**: If organic activation rate already exceeds 40% without intervention, skip optimization

---

## 1. Current Flow

```
App Launch → Auth Screen (Google Sign-In or Guest Mode) → Home Screen
```

That's it. No tutorial, no walkthrough, no first-scan prompt. User lands on home screen and must discover the scan tab themselves.

### Time-to-first-classification estimate

| Step | Action | Time |
|------|--------|------|
| 1 | Launch app | 2s |
| 2 | Choose auth method | 5s |
| 3 | Auth complete | 3s |
| 4 | Home screen loads | 1s |
| 5 | Discover scan tab | Variable (5–30s) |
| 6 | Navigate to scan | 1s |
| 7 | Grant camera permission | 5s |
| 8 | Capture image | 3s |
| 9 | Classification returns | 2s |
| **Total** | | **22–47s** |

Target: ≤2 taps, ≤15 seconds. Currently 3–8 taps.

---

## 2. Funnel Gaps

### Missing onboarding tutorial
No interactive walkthrough. User doesn't learn about:
- Instant vs batch analysis
- Token system
- Achievements and streaks
- Community features
- Correct disposal for their city

### Cold start problem
Home screen shows empty state — no classifications, no streaks, no achievements. First-time user sees "Welcome!" and four stat chips showing zeros. This is demotivating, not engaging.

### No first-scan prompt
User must self-discover the scan tab. There is no "Scan your first item!" prompt or contextual hint.

### Token confusion
Welcome bonus displays 50 tokens but token enforcement is off. User sees token cost on analysis but nothing is deducted. Creates distrust.

---

## 3. Recommended Onboarding Flow

### Step 1: Quick intro (3 screens, swipeable)

1. **"Know your waste"** — app purpose in 10 words. Single image.
2. **"Snap → Learn → Dispose"** — the core loop. Visual of the 3-step flow.
3. **"Choose how to start"** — Google Sign-In or Guest Mode (same as current auth screen, but framed as choice, not barrier)

### Step 2: First scan (forced, but delightful)

After auth, immediately open camera with overlay:
- "Point at any waste item"
- Real-time camera viewfinder
- Hint: "Try a plastic bottle or banana peel for best results"

### Step 3: First result (celebration)

After first classification:
- Show full result screen (category, disposal instructions, tips)
- Award "First Classification" achievement immediately
- Show "Welcome to waste sorting!" celebration overlay
- Reveal token balance (50 tokens) with explanation

### Step 4: Home screen reveal (progressive)

After first scan, home screen shows:
- 1 classification (not zero)
- 1 achievement (not zero)
- Streak: Day 1 (not zero)
- Token balance: 49 (after first instant scan)

---

## 4. Activation Metrics

| Metric | Target | Current | Measurement |
|--------|--------|---------|-------------|
| Time-to-first-scan | < 15s | ~30s | Analytics event timestamp delta |
| First-scan completion rate | > 80% | Unknown | `classification_completed` event |
| Day-1 retention | > 50% | Unknown | DAU/installs |
| Day-7 retention | > 25% | Unknown | WAU/installs |
| First-achievement rate | > 90% | Unknown | Achievement unlock event |

---

## 5. Implementation Sequence

1. Add onboarding screens (3-screen swipeable intro)
2. Auto-open camera after first auth
3. Award "First Classification" achievement on first scan
4. Show celebration overlay on first result
5. Instrument activation funnel with analytics events
6. A/B test: forced first-scan vs optional

---

## 6. Related

- [Habit Formation Loop](HABIT_FORMATION_LOOP.md) — what happens after activation
- [Gamification Depth](GAMIFICATION_DEPTH.md) — reward system for first actions
- [Gamification Redesign Spec](../planning/gamification-redesign-spec.md#7-onboarding-flow) — phased onboarding flow (§7: minimal first visit, progressive reveal on return, week-by-week unlock cadence)
- [Token Economy & Pricing Coherence](TOKEN_ECONOMY_AND_PRICING_COHERENCE.md) — token visibility
