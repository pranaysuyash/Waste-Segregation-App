# Gamification / Habit Loop Redesign

**Date:** 2026-05-21
**Status:** Audit Complete — Recommendations Ready
**Files Audited:** 25+ source files across lib/, functions/, test/, docs/

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [What Behavior Are We Actually Encouraging?](#2-what-behavior-are-we-actually-encouraging)
3. [Points System Audit](#3-points-system-audit)
4. [Achievements Audit](#4-achievements-audit)
5. [Streaks Audit](#5-streaks-audit)
6. [Feedback & Correction Rewards Audit](#6-feedback--correction-rewards-audit)
7. [Daily Challenges Audit](#7-daily-challenges-audit)
8. [Token Economy Audit](#8-token-economy-audit)
9. [Classification Accuracy Tracking](#9-classification-accuracy-tracking)
10. [Family & Community Features](#10-family--community-features)
11. [Duplicate Image & Farming Risk Analysis](#11-duplicate-image--farming-risk-analysis)
12. [UI Moment Inventory: Meaningful vs Noisy](#12-ui-moment-inventory-meaningful-vs-noisy)
13. [Proposed Implementation Phases](#13-proposed-implementation-phases)
14. [Appendix: Raw Findings](#14-appendix-raw-findings)

---

## 1. Executive Summary

The current gamification system has a **solid foundation** (points, streaks, achievements, challenges, token economy) but suffers from three structural problems:

1. **Quantity over quality.** Points are primarily earned per-classification (10 base pts). Nothing rewards insight, accuracy, learning, or correction quality more than brute-force volume.
2. **Corrections are underpriced.** A correction (10 pts) pays the same as a normal classification (10 pts) and only 2x a simple confirmation (5 pts). The user who fixes AI errors should earn disproportionately more — they are doing the most valuable work.
3. **Abuse/farming protections are incomplete.** Local dedup exists and is robust (perceptual hash + content hash + result pipeline idempotency), but it is purely client-side and survives neither data wipe nor cross-device use. Server-side hashing is byte-exact (SHA-256), so re-encoding the same image at a different quality setting produces a different hash and bypasses the cache entirely.
4. **Popups are noisy.** Points popup fires on *every* classification. Achievement celebration fires on *every* earn (including bronze). There is no rate-limiting, no suppression when the user is in flow, and no coalescing of multiple events into a single moment.

---

## 2. What Behavior Are We Actually Encouraging?

### 2.1 Current Incentive Map

| Action | Points | Behavior Encouraged | Aligned With Goal? |
|---|---|---|---|
| Classification (standard) | 10 (dynamic: 5–50) | Scan more items | ✅ Volume, but not quality |
| Feedback (confirm) | 5 | Confirm AI was right | ✅ Good data, low effort |
| Correction (wrong + detail) | 10 | Fix AI errors | 🔶 Should be higher |
| Daily streak | 5 | Open app daily | ✅ Retention |
| Perfect week | 50 | Use app 7 days | ✅ Retention |
| Challenge complete | 25 | Complete specific goals | ✅ Targeted behavior |
| Badge earned | 20 | Reach milestones | ✅ Long-term motivation |
| Quiz completed | 15 | Learn through quizzes | ✅ Education |
| Educational content | 5 | Read educational content | 🔶 Too low to motivate |
| Community challenge | 30 | Participate socially | ✅ Community |

### 2.2 The Gap

**We are not rewarding:**
- **Accuracy** — A user who corrects 10 AI errors and a user who blindly accepts 10 results both earn ~100 points. Accuracy is invisible in the reward system.
- **Learning** — Reading educational content (5 pts) is worth less than a single classification (10 pts). This actively discourages learning in favor of scanning.
- **Hazardous/e-waste knowledge** — These are the highest-stakes categories for safe disposal, but they pay the same base points as a banana peel.
- **Correction quality** — Providing a barcode, detailed notes, or specific material info pays the same as "it's wrong, category X."

### 2.3 Recommendation

Redefine the reward hierarchy from **volume** to **value**:

```
Low value:  Confirm correct classification (feedback)
Medium:     Standard classification, educational content view
High:       Correction with detailed data, hazardous item ID, quiz pass ≥90%
Premium:    Streak milestones, challenge completion, community contribution
```

---

## 3. Points System Audit

### 3.1 Current State

- **Static point values** defined in `GamificationService._pointValues` (hardcoded map in `lib/services/gamification_service.dart:51`)
- Isolated dynamic calculation in `PointsEngine.calculateEnhancedClassificationPoints()` (`lib/services/points_engine.dart:415`) but it uses arbitrary heuristics (dataFieldsCount, confidence, isComplexItem) that are inconsistently populated
- Points engine is a **singleton** (`PointsEngine.getInstance`) with good atomic operation locking
- But **4 concurrent mutation paths** were identified (see `scripts/points_system_audit.md`): GamificationService.processClassification, GamificationService.addPoints, CloudStorageService._updateLeaderboardEntry, widget-level manual computation

### 3.2 Key Issues

| Issue | Severity | Detail |
|---|---|---|
| Static point config | Medium | Point values are hardcoded; can't be tuned without app update |
| Race conditions | **High** | 4 concurrent mutation paths; no centralized PointsRepository |
| No quality multiplier | High | Volume-based only; no accuracy/quality bonus |
| Category parity | Medium | Hazardous waste (high-stakes) pays same as dry waste (low-stakes) |
| Dynamic calc inconsistent | Medium | `calculatedEnhancedClassificationPoints` uses fields that are often null |

### 3.3 Proposed Changes

1. **Phase 0 fix: implement `FieldValue.increment()`** for all Firestore point writes to eliminate race conditions (as recommended by the existing audit)
2. **Phase 1: Category-based point multipliers**
   - Hazardous waste: 1.5x base
   - E-waste: 1.3x base
   - Medical waste: 1.3x base
   - Wet/Dry/Non-waste: 1.0x base
3. **Phase 2: Quality bonus** — award +5 bonus points when a user's correction is later confirmed by another user or admin review
4. **Phase 3: Remote Config** — Migrate point values to Firebase Remote Config so tuning doesn't require app updates

---

## 4. Achievements Audit

### 4.1 Current State

- 22 `AchievementType` values in `lib/models/gamification.dart:26`
- Tiered families (bronze→silver→gold→platinum) for waste identification, categories, streaks, perfect week, challenges
- Auto-claim for bronze; manual claim for silver+ (points deposited at claim time)
- Meta-achievements track total achievements earned
- Secret/hidden achievements field exists but unused
- `NearMilestoneNudge` system checks for "one away" from targets

### 4.2 Key Issues

| Issue | Severity | Detail |
|---|---|---|
| No hazardous/e-waste badges | **High** | Critical knowledge gap not recognized |
| No accuracy-related achievements | High | No achievement for correction streaks, accuracy milestones |
| Bronze auto-claim is noisy | Medium | Every bronze achievement fires celebration + popup |
| Clue/hidden system unused | Low | `clues` field exists but no hidden achievements |
| Achievement ceiling: only 22 types | Medium | Power users exhaust these quickly |

### 4.3 Proposed New Achievements

**Hazardous & E-Waste Specialist** (tiered family):
- `hazardous_novice`: Identify 3 hazardous waste items (bronze)
- `hazardous_identifier`: Identify 15 hazardous items (silver)
- `hazardous_expert`: Identify 50 hazardous items (gold)
- `hazardous_master`: Identify 200 hazardous items (platinum)

**E-Waste Collector** (tiered family):
- `ewaste_spotter`: Identify 3 e-waste items (bronze)
- `ewaste_hunter`: Identify 10 e-waste items (silver)
- `ewaste_expert`: Identify 30 e-waste items (gold)

**Accuracy Champion** (new family):
- `accuracy_beginner`: Correct AI 5 times (bronze)
- `accuracy_adept`: Correct AI 25 times with detailed data (silver)
- `accuracy_master`: Achieve 90%+ acceptance rate over 100 classifications (gold)

**Learning Achievements** (existing but needs extension):
- `knowledge_seeker`: Complete 10 educational content pieces (existing, upgrade to silver)
- `safety_champion`: Complete all hazardous/e-waste educational content (new)

**Streak Extensions** (current cap is 100 days):
- Add `streak_immortal` at 365 days (platinum, 5000 pts)
- Streak freeze mechanic (earnable item that protects streak if you miss a day)

### 4.4 UI Improvement: Silent Bronze

Bronze-tier achievements should be silently granted (banner notification only, no full-screen confetti). Reserve the celebration for silver+ and significant milestones.

---

## 5. Streaks Audit

### 5.1 Current State

- `StreakType`: dailyClassification, dailyLearning, dailyEngagement, itemDiscovery (`lib/models/gamification.dart:1262`)
- Only `dailyClassification` is actively tracked
- Streak bonus points at milestones: 3 days (15pts), 7 days (35pts), 14 days (70pts), 30 days (150pts); daily maintenance = 5pts
- `_calculateNewStreak` in `PointsEngine` (line 340) correctly handles: same-day (no change), consecutive-day (increment), gap (reset to 1)
- Streak lock (`_isUpdatingStreak` flag) prevents concurrent updates
- `perfect_week` achievement awards 50 bonus points at each 7-day milestone

### 5.2 Key Issues

| Issue | Severity | Detail |
|---|---|---|
| Streak freeze not implemented | Medium | No mechanic to protect streak if user misses a day |
| Only classification streak active | Medium | dailyLearning, dailyEngagement, itemDiscovery have no tracking |
| Streak broken = frustration | Medium | All progress lost; no recovery mechanic |
| No streak grace period | Low | Midnight UTC boundary can be punishing |

### 5.3 Proposed Changes

1. **Implement streak freeze item** — Earnable (via tokens or achievement) that auto-applies when streak would break. User can hold up to 3 freezes.
2. **Activate dailyLearning streak** — Track days user views educational content. Award learning-specific badges.
3. **Add 48-hour grace window** — Streak only breaks after 2 full days of inactivity (not 1). Reduces friction for real-world usage patterns.
4. **Streak recovery** — If streak breaks, offer a one-time "restore" for tokens (e.g., 10 tokens to restore to previous count).

---

## 6. Feedback & Correction Rewards Audit

### 6.1 Current State

| Action | Points | File |
|---|---|---|
| `feedback_provided` (confirm correct) | 5 | `lib/services/gamification_service.dart:63` |
| `correction_provided` (wrong + detail) | 10 | `lib/services/gamification_service.dart:64` |

- Correction flow: `CorrectionDialog` → `ResultPipeline.submitFeedback()` → idempotency check (local + cloud) → save feedback → award points
- Re-analysis is triggered via `AiService.handleUserCorrection` after correction is submitted
- Idempotency is robust: stable dedup key (`feedback_${userId}_${classificationId}`) prevents double-awarding

### 6.2 Key Issues

| Issue | Severity | Detail |
|---|---|---|
| Correction = same as classification | **High** | Both 10 pts. Fixing errors should pay more than making a standard scan |
| No correction streak bonus | Medium | No reward for consistent corrections over time |
| No accuracy display anywhere | High | User never sees their correction/confirmation ratio or accuracy % |
| No educational follow-up | Medium | After correcting hazardous/e-waste, no targeted education shown |
| Barcode/material detail not rewarded | Low | Providing structured correction data pays same as clicking "wrong" + selecting category |

### 6.3 Proposed Point Rebalancing

| Action | Current | Proposed | Rationale |
|---|---|---|---|
| `feedback_provided` (confirm) | 5 | 3 | Low effort; reduces incentive to spam-confirm |
| `correction_provided` (basic) | 10 | 15 | High value; AI training data |
| `correction_provided` (with barcode) | 10 | 25 | Maximum value; ground-truth data for training |
| `correction_provided` (with detailed notes) | 10 | 20 | Semi-structured feedback |

### 6.4 Accuracy Tracking (New System)

Add a lightweight accuracy tracking model:

```dart
class AccuracyMetrics {
  final int totalClassifications;
  final int userConfirmedCount;
  final int userCorrectedCount;
  final double accuracyRate; // confirmed / (confirmed + corrected)

  // Calculate from profile data
  factory AccuracyMetrics.fromProfile(GamificationProfile profile) {
    // Sum userConfirmed + userCorrected from classifications
  }
}
```

Display in the Impact Dashboard as a new card. Drives the Accuracy Champion achievement family.

---

## 7. Daily Challenges Audit

### 7.1 Current State

- Challenges defined in `GamificationService._getDefaultChallenges()` (JSON templates in Hive)
- 3 concurrent active challenges; new ones generated when slots open
- Challenge types: category-specific, subcategory-specific, any-item
- Duration: 7 days
- Points reward: 25 (configurable per challenge template)
- If fewer than 3 active challenges, `_generateNewChallenges` picks random templates from Hive

### 7.2 Key Issues

| Issue | Severity | Detail |
|---|---|---|
| Challenge templates are static | Medium | Stored in Hive; no remote config for dynamic challenges |
| Duration always 7 days | Low | No variety (3-day mini-challenges, 14-day marathons) |
| No learning challenges | High | All challenges are about classification volume, not education |
| No correction challenges | Medium | "Correct 3 misclassifications this week" does not exist |
| No hazardous/e-waste specific | Medium | These categories need focused challenges |
| Participant tracking unused | Medium | `participantIds` field exists but no family/team challenges |

### 7.3 Proposed New Challenge Templates

**Learning-focused:**
- "Read 3 educational articles about hazardous waste disposal"
- "Score 100% on any quiz"
- "Complete the 'E-Waste Safety' learning module"

**Correction-focused:**
- "Correct 3 AI misclassifications this week"
- "Provide detailed corrections with barcodes for 5 items"

**Quality-focused:**
- "Achieve 100% confirmation rate on 10 classifications"
- "Identify 5 items with 95%+ AI confidence"

**Hazardous/E-Waste focused:**
- "Identify 5 hazardous waste items"
- "Correctly classify 3 electronic waste items"

---

## 8. Token Economy Audit

### 8.1 Current State

- Token system is a **separate economy** from points (not gamification — AI usage metering)
- 100 points = 1 token conversion rate
- Max 5 conversions/day
- Welcome bonus: 50 tokens
- Daily login bonus: 2 tokens
- Analysis costs: Batch = 1 token, Instant = 5 tokens
- Token enforcement kill switch (`enableTokenEnforcement`) exists but can be toggled
- Server-side validation for token spends via `spendUserTokens` Firebase Function

### 8.2 Key Issues

| Issue | Severity | Detail |
|---|---|---|
| Conversion rate is arbitrary | Medium | 100:1 was never validated against user behavior data |
| Token earning is limited | Medium | Only welcome bonus + daily login (2 tokens/day = 1 batch analysis/day after 50-token welcome runs out) |
| Points→token conversion is one-way | Low | Tokens cannot be converted back to points |
| Token balance not gamified | Medium | No streak-based token bonuses, no achievement token rewards |
| Enforcement kill switch | Low | Phase 0 crutch; should be removed once confident in token economy |

### 8.3 Proposed Changes

1. **Add token rewards to achievements** — Silver+ achievements award tokens in addition to points
2. **Add token rewards to streak milestones** — 7-day streak = 5 tokens, 30-day = 15 tokens
3. **Add token rewards for corrections** — detailed corrections earn 1 token per 5 corrections
4. **Consider lowering conversion rate** — 50:1 instead of 100:1 to make points feel more valuable
5. **Remove enforcement kill switch** once Phase 1 above is live and stable

---

## 9. Classification Accuracy Tracking

### 9.1 Current State: NOTHING

There is **no accuracy tracking system** anywhere in the codebase. The Impact Dashboard shows a "high confidence rate" (confidence-based, not correctness-based), but:
- No `userConfirmed` / `correctionCount` aggregation
- No accuracy percentage or trend
- No storage of accuracy data in Firestore or local storage
- No achievements or rewards for accuracy

### 9.2 Why This Matters

Without accuracy tracking, the gamification system cannot distinguish between:
- A user who scans 100 items and confirms 98 correct (high-quality contributor)
- A user who scans 100 items and corrects 40 (critical debugger)
- A user who scans 100 items and clicks through without engaging (volume-only)

All three earn the same points (~1,000). The reward system is blind to the most important signal.

### 9.3 Proposed Implementation

**Data model additions to `GamificationProfile`:**
```dart
int totalFeedbackGiven = 0;
int totalConfirmations = 0;
int totalCorrections = 0;
int detailedCorrections = 0; // with barcode or detailed notes
double? accuracyRate; // computed: confirmations / (confirmations + corrections)
```

**Firestore schema update:**
Add `gamification_profile.accuracy` sub-map with the same fields.

**UI:**
- New "Accuracy Score" card on Impact Dashboard
- Accuracy trend: mini sparkline showing last 30 days
- Color-coded: green (≥90%), yellow (70–89%), red (<70%)

**Achievements:**
- See Section 4.3 — Accuracy Champion family

---

## 10. Family & Community Features

### 10.1 Current State

- `FamilyReaction`, `FamilyComment` models exist (`lib/models/gamification.dart:764-937`)
- `LeaderboardEntry` model exists but **no active leaderboard screen** is wired up
- `CommunityService` records classification and achievement activities in the community feed
- `participantIds` field on challenges is never used
- No team or family challenge system

### 10.2 Key Issues

| Issue | Severity | Detail |
|---|---|---|
| Leaderboard screen not built | High | Model exists, provider exists (`leaderboardProvider`), no UI screen |
| Family teamwork achievement exists but can't be earned | Medium | `familyTeamwork` type defined in `AchievementType`, no trigger code |
| No shared family challenges | Low | Family groups exist but gamification is entirely individual |

### 10.3 Proposed Changes

1. **Build leaderboard screen** from existing data. Weekly/monthly/all-time views. This is low-hanging fruit — the data layer is ready.
2. **Implement family teamwork achievement** — Award when total family classifications reach thresholds (50/200/500/1000).
3. **Add family challenges** — "Your family identified 20 items this week" type goals. Use existing `participantIds` on Challenge model.

---

## 11. Duplicate Image & Farming Risk Analysis

### 11.1 Protection Layers

| Layer | Location | What It Prevents | Weakness |
|---|---|---|---|
| Perceptual hash cache | `lib/utils/image_utils.dart:210` | Same/near-same image re-analysis | Local only; cleared with app data |
| Content hash (storage dedup) | `lib/services/storage_service.dart:245` | Same save twice locally | Hash is AI-output-based (itemName_category_subcategory), not image-content-based. Bypassed if AI output differs |
| In-flight dedup | `lib/services/result_pipeline.dart:117` | Concurrent same-ID saves | Uses classification UUID; irrelevant for different images |
| Server SHA-256 cache | `functions/src/classify_image.ts:983` | Same exact bytes re-classified | Byte-exact: re-compress at different JPEG quality = different hash = bypass |
| Token idempotency | `functions/src/classify_image.ts:346` | Double charge on retry | Only applies to identical request IDs |

### 11.2 Farming Scenarios

| Scenario | Possible? | Impact |
|---|---|---|
| Same image, same quality, same user | **No** (blocked by pHash + content hash + server cache) | None |
| Same image, different quality (JPEG 90 vs 75) | **Yes** (server SHA-256 differs, local pHash may differ with compression artifacts) | Medium: user could earn 10 pts per variant |
| Same image, different device | **Yes** (client-side local state lost) | Medium: points earned again on new device |
| Same image, cross-user | **Yes** (no cross-user dedup exists) | Low: no direct benefit to user |
| Scripted bulk upload of similar-but-different images | **Potentially** (liveness check / CAPTCHA would be needed for extreme abuse) | High ceiling, but impractical without automation |

### 11.3 Recommended Protections (Phase 1)

1. **Server-side perceptual hash** — Compute pHash server-side (or accept from trusted client) and index by user in Firestore. Block classification if identical pHash exists within 24h. This is the single highest-impact fix.
2. **Daily classification cap per user** — Server-enforced max of ~50 classifications/day. Already partially supported by the rate limit system. Prevents large-scale farming.
3. **Strengthen content hash** — Use image-content-based hash (currently it's AI-output-based). Merge with the existing `_buildClassificationContentHash`.
4. **Cross-device hash persistence** — Sync pHash index to Firestore so device changes don't reset it. Already partially supported by Firestore cache (`classifications/{serverHash}`).

---

## 12. UI Moment Inventory: Meaningful vs Noisy

### 12.1 Every Gamification UI Moment

| Moment | Triggers | Frequency | Meaningful? | Recommendation |
|---|---|---|---|---|
| Points popup (`PointsEarnedPopup`) | Every classification | Per-scan | No — noise | **Suppress for <5 pts. Show only for milestones, achievements, and bonuses.** |
| Achievement celebration (full-screen confetti) | Every new achievement | Per-earn (could be multiple per session) | Yes for silver+, No for bronze | **Only show for silver+ or ≥100 pt rewards. Bronze = silent banner only.** |
| Streak indicator on home | Every home view | Per session | Yes — low-urgency utility | Keep as-is |
| Challenge card | Home screen | Per session | Yes — actionable | Keep as-is |
| Near-milestone nudge | "One away" from target | Occasional | Yes — timely motivation | Keep as-is |
| Correction dialog snackbar | After each correction/confirmation | Per-feedback | No — noise (redundant with pipeline) | **Keep only for points >10. Suppress for 3-5 pt confirmations.** |
| Points + level indicator (home header) | Every home view | Per session | Yes — ambient status | Keep as-is |
| Achievement notification banner | New achievement earned | Per-earn | Yes for new unlocks | Keep as-is but coalesce: if 2+ achievements earned simultaneously, show one combined notification |

### 12.2 Noise Reduction Principles

1. **Suppress low-value popups when user is in flow.** If a user submits 5 classifications in 2 minutes, coalesce points into a single summary popup ("+75 points from 5 classifications"). Use a debounce window of 3 seconds.
2. **Reserve full-screen for silver+.** Bronze achievements, 5-point streaks, and "educational content viewed" should never trigger a modal overlay. Use in-line indicators (badge shimmer, small toast).
3. **Batch notifications.** If 3 achievements are earned from a single classification (e.g., waste_novice + hazard_spotter + accuracy_beginner), show ONE combined card rather than 3 sequential popups.
4. **Respect context.** If user is on the result screen analyzing a new image, suppress all gamification popups until they leave that screen. Show notifications on the home screen or in a notification tray instead.

---

## 13. Proposed Implementation Phases

### Phase 0 (Quick Wins — 1-2 weeks)

| Item | Effort | Impact | Files Touched |
|---|---|---|---|
| Suppress bronze achievement celebrations | Small | Reduces noise significantly | `achievement_celebration.dart`, `achievement_wrapper.dart` |
| Suppress points popup for <5 pts | Small | Reduces per-classification noise | `points_popup.dart` |
| Add daily classification cap (server-side) | Medium | Stops large-scale farming | `classify_image.ts`, rate limit config |
| Add accuracy tracking data model | Small | Foundation for all accuracy features | `gamification.dart`, `gamification_profile` |

### Phase 1 (Core Loop Redesign — 2-3 weeks)

| Item | Effort | Impact | Files Touched |
|---|---|---|---|
| Rebalance point values (see Section 6.3) | Small | Corrects correction incentive | `gamification_service.dart`, `points_engine.dart` |
| Add hazardous/e-waste achievement family | Small | Recognizes critical categories | `gamification_service.dart` (getDefaultAchievements) |
| Add category-based point multipliers | Medium | Rewards high-stakes classification | `points_engine.dart` |
| Implement correction streak mechanic | Medium | Rewards sustained quality | `gamification_service.dart`, `points_engine.dart` |
| Build accuracy card on Impact Dashboard | Medium | Makes accuracy visible to user | `impact_dashboard_screen.dart` |

### Phase 2 (Anti-Farming & Persistence — 2-3 weeks)

| Item | Effort | Impact | Files Touched |
|---|---|---|---|
| Compute pHash server-side | Large | **Critical**: stops image re-encoding bypass | `classify_image.ts`, training data pipeline |
| Sync pHash index to Firestore per-user | Medium | Cross-device dedup | `cloud_storage_service.dart`, `storage_service.dart` |
| Strengthen storage content hash to be image-based | Medium | Fixes weak dedup key | `storage_service.dart` |
| Add FieldValue.increment() to all Firestore point writes | Medium | Eliminates race conditions | `cloud_storage_service.dart`, multiple providers |

### Phase 3 (Systemic Improvements — 3-4 weeks)

| Item | Effort | Impact | Files Touched |
|---|---|---|---|
| Migrate point values to Remote Config | Medium | Enables server-side tuning | New config service + `points_engine.dart` |
| Popup coalescing (batch + debounce) | Medium | Major noise reduction | New popup controller + `points_popup.dart` |
| Educational follow-up on corrections | Medium | Closes learning loop | `result_screen.dart`, new widget |
| Implement streak freeze tokens | Medium | Reduces streak frustration | `token_service.dart`, `points_engine.dart` |
| Build leaderboard screen | Medium | Completes existing work | New screen + existing providers |
| New challenge templates (learning + correction) | Small | Variety | `gamification_service.dart` (_getDefaultChallenges) |

### Phase 4 (Community & Polish — 2-3 weeks)

| Item | Effort | Impact | Files Touched |
|---|---|---|---|
| Family teamwork achievement | Small | Community motivation | `gamification_service.dart` |
| Family challenges | Medium | Shared goals | Challenge model, community service |
| Removal of token enforcement kill switch | Small | Cleanup | `token_service.dart` |
| Points→token rate validation & adjustment | Small | Economy balance | `token_service.dart` |
| Silent bronze achievement tier | Small | Noise reduction | `achievement_celebration.dart` |

---

## 14. Appendix: Raw Findings

### 14.1 All Files Touched During Audit

| File Path | Role in Gamification |
|---|---|
| `lib/models/gamification.dart` | All models: Achievement, Streak, Challenge, UserPoints, GamificationProfile, etc. |
| `lib/models/gamification.g.dart` | Hive TypeAdapter generated code |
| `lib/models/token_wallet.dart` | Token economy models |
| `lib/models/token_wallet.g.dart` | Hive TypeAdapter generated code |
| `lib/services/gamification_service.dart` | Primary gamification service (~1400 lines) |
| `lib/services/points_engine.dart` | Centralized points singleton (~514 lines) |
| `lib/services/token_service.dart` | Token economy service (~706 lines) |
| `lib/services/result_pipeline.dart` | Orchestration: classification + feedback pipeline |
| `lib/services/storage_service.dart` | Local persistence + dedup index |
| `lib/services/cloud_storage_service.dart` | Firestore sync + leaderboard writes |
| `lib/services/cache_service.dart` | Perceptual hash cache (local) |
| `lib/services/enhanced_cache_service.dart` | Enhanced cache with dual-layer lookup |
| `lib/providers/gamification_notifier.dart` | Riverpod state for profile |
| `lib/providers/points_manager.dart` | Riverpod state for points |
| `lib/providers/gamification_repository.dart` | Repository pattern |
| `lib/providers/gamification_provider.dart` | Legacy provider |
| `lib/providers/points_engine_provider.dart` | Provider wiring for PointsEngine |
| `lib/providers/token_providers.dart` | Token state providers |
| `lib/widgets/gamification_widgets.dart` | StreakIndicator, ChallengeCard, PointsIndicator, AchievementGrid, etc. |
| `lib/widgets/result_screen/points_popup.dart` | Points earned popup overlay (~467 lines) |
| `lib/widgets/result_screen/achievement_wrapper.dart` | Celebration controller + wrapper |
| `lib/widgets/advanced_ui/achievement_celebration.dart` | Confetti + 3D badge celebration (~546 lines) |
| `lib/widgets/correction_dialog.dart` | Thumbs up/down + correction form |
| `lib/utils/image_utils.dart` | pHash + content hash generation |
| `lib/utils/points_migration.dart` | Legacy migration code |
| `functions/src/classify_image.ts` | Server classification + SHA-256 cache |
| `functions/src/rate_limit_config.ts` | Rate limiting config |

### 14.2 Existing Documentation (Read for Context)

| Document | Key Findings Used in This Report |
|---|---|
| `docs/planning/gamification_engagement_strategy.md` | Original strategy; leveling, team challenges, AI personalization deferred |
| `docs/planning/gamification_phase1_implementation_plan.md` | Firestore config not implemented; static point values remain |
| `docs/design/user_experience/gamification/gamification_enhancement_plan.md` | WasteDex, environmental impact, virtual currency — aspirational only |
| `docs/reports/architecture/gamification_performance_optimization.md` | Riverpod migration complete; 90% rebuild reduction |
| `docs/implementation/features/achievement_celebration_integration.md` | Celebration widget implementation details |
| `docs/implementation/features/achievement_celebration_usage_guide.md` | Developer reference for celebrations |
| `scripts/points_system_audit.md` | Critical: 4 concurrent mutation paths; all TODO items still open |
| `TOKEN_ECONOMY_TODO.md` | Token economy phases; Phases 5-6 not started |
| `firebase_task.md` | Gamification as subsystem in larger platform review |

### 14.3 Test Files Supporting Audit

| Test File | What It Verifies |
|---|---|
| `test/services/result_pipeline_side_effects_test.dart` | Feedback idempotency, no double-points |
| `test/providers/gamification_notifier_test.dart` | Streak calculation, point addition |
| `test/providers/gamification_notifier_test.mocks.dart` | Mock setup |
| `test/providers/points_manager_test.dart` | Points manager correctness |
| `test/providers/points_manager_test.mocks.dart` | Mock setup |
| `test/models/gamification_test.dart` | Model serialization |
| `test/services/gamification_service_test.dart` | Service-level tests |
| `test/services/gamification_race_condition_test.dart` | Race condition scenarios |
| `test/services/points_engine_test.dart` | Points engine correctness |
| `test/services/token_service_test.dart` | Token service correctness |
| `test/screens/achievements_screen_test.dart` | Achievement screen |
| `test/achievement_unlock_logic_test.dart` | Unlock logic |
| `test/services/achievement_claiming_atomic_test.dart` | Atomic claims |
