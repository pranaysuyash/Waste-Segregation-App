# Gamification Engine: Complete Deep Dive

**Date**: 2026-05-25
**Status**: Completed audit
**Scope**: End-to-end trace of every gamification subsystem — points, achievements, streaks, challenges, levels, tokens, cooperative mechanics, data persistence, and UI surfacing.

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Architecture Overview](#architecture-overview)
3. [The Points System](#the-points-system)
4. [Achievement System](#achievement-system)
5. [Streak System](#streak-system)
6. [Challenge Lifecycle](#challenge-lifecycle)
7. [Level Ladder & Rank Names](#level-ladder--rank-names)
8. [Token Bridge (Points ↔ Tokens)](#token-bridge-points--tokens)
9. [Classification → GamificationResult Flow](#classification--gamificationresult-flow)
10. [Weekly Stats](#weekly-stats)
11. [Near-Milestone Nudges](#near-milestone-nudges)
12. [Data Persistence: Hive vs Firestore](#data-persistence-hive-vs-firestore)
13. [Cooperative Mechanics](#cooperative-mechanics)
14. [Orphaned Fields & Dead Code](#orphaned-fields--dead-code)
15. [Provider/Service Layer Map](#provider-service-layer-map)
16. [Quick Wins](#quick-wins)
17. [Open Questions](#open-questions)

---

## Executive Summary

The gamification engine is the largest undoc'd subsystem in the codebase. It spans **97+ files** across models, services, providers, screens, widgets, tests, and docs. Every classification triggers it. It manages two currencies (eco-points and tokens), 25 achievement types in tiered families, 4 streak types (3 dead), 15 challenge templates, a level ladder with 6 ranks, a points-to-tokens conversion bridge, and a full cooperative mechanics layer for families.

**Key findings**:

- **GamificationResult is dead code** — it's defined but never instantiated. The actual gamification data flows through `ResultPipelineState` via Riverpod, not through `Navigator.pop`.
- **3 of 4 streak types are never populated** — only `dailyClassification` is active. `dailyLearning`, `dailyEngagement`, and `itemDiscovery` have no code path that creates or updates them.
- **Token enforcement is disabled** (Phase 0) — the kill switch `enableTokenEnforcement = false` means token checks always pass. Telemetry is being collected.
- **Cooperative mechanics rewards are not bridged** — `FamilyGoal.rewardPoints`, `FamilyTask.pointsReward`, `CooperativeChallenge.rewardPoints`, and `ParentChildMission.bonusPoints` are data fields with no code path that credits them to the user's `GamificationProfile`.
- **`UserPoints.categoryPoints` is never shown in the UI** — populated by every classification but no screen renders it.
- **`WeeklyStats` is computed and stored but never surfaced** to users.
- **Two point value maps exist** with slight inconsistencies — `PointableAction` enum in `action_points.dart` vs `_pointValues` map in `gamification_service.dart` / `_getPointsForAction()` in `points_engine.dart`.
- **`_addPointsInternal` in `GamificationService` is dead code** — `addPoints` delegates to `PointsEngine`, but the internal method remains.

---

## Architecture Overview

```
┌──────────────────────────────────────────────────────────────────┐
│                       USER CLASSIFIES ITEM                       │
│                           (camera/gallery)                       │
└──────────────┬───────────────────────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────────────────────────┐
│                     ResultPipeline                               │
│  (lib/services/result_pipeline.dart)                             │
│                                                                  │
│  Stage 1: Save locally (duplicate detection)                     │
│  Stage 2: Gamification ──► GamificationService.processClassification()
│  Stage 3: Cloud sync                                             │
│  Stage 4: Community post                                         │
│  Stage 5: Maybe show ad                                          │
│                                                                  │
│  Output: ResultPipelineState {pointsEarned, newAchievements,     │
│           completedChallenge}                                     │
└──────────────┬───────────────────────────────────────────────────┘
               │ (Riverpod rebuild)
               ▼
┌──────────────────────────────────────────────────────────────────┐
│  ResultScreen reads ResultPipelineState                          │
│    ├── ResultHeader (shows pointsEarned)                         │
│    ├── PointsCard (shows "+N points earned")                     │
│    ├── CompletedChallengeCard                                     │
│    ├── PointsEarnedPopup (overlay)                                │
│    └── AchievementCelebration (overlay)                           │
└──────────────────────────────────────────────────────────────────┘

                     INDIVIDUAL GAMIFICATION LAYER
┌──────────────────────────────────────────────────────────────────┐
│  PointsEngine (singleton, ChangeNotifier)                         │
│    ├── addPoints() — atomic, locked                              │
│    ├── updateStreak() — atomic, locked                           │
│    ├── claimAchievementReward() — atomic, locked                 │
│    ├── _calculateNewPoints() — level calc, category tracking     │
│    ├── _calculateNewStreak() — freeze-aware streak calc          │
│    ├── _getPointsForAction() — action→point lookup               │
│    ├── _getCategoryMultiplier() — hazardous 1.5x, medical 1.3x  │
│    └── calculateEnhancedClassificationPoints() — AI richness     │
│                                                                  │
│  GamificationService (ChangeNotifier, delegates to PointsEngine)  │
│    ├── processClassification() — main entry after scan           │
│    ├── updateStreak() — legacy + new streak logic                │
│    ├── updateAchievementProgress() — progress + earn             │
│    ├── updateChallengeProgress() — challenge lifecycle           │
│    ├── processEducationalContent() — education gamification      │
│    ├── getDefaultAchievements() — 35 achievement definitions     │
│    ├── _getDefaultChallenges() — 15 challenge templates          │
│    ├── getNearMilestoneNudge() — "Almost there!" nudges          │
│    └── syncGamificationData() — full resync                      │
│                                                                  │
│  TokenService (ChangeNotifier, atomic)                            │
│    ├── convertPointsToTokens() — 100:1 rate, 5/day cap           │
│    ├── spendTokens() — server-validated when Firebase enabled    │
│    ├── earnTokens() — manual earn (login bonus, etc.)            │
│    ├── canAffordAnalysis() — kill-switch aware                   │
│    └── processDailyLogin() — 2 tokens/day                        │
└──────────────────────────────────────────────────────────────────┘

                     COOPERATIVE MECHANICS LAYER
┌──────────────────────────────────────────────────────────────────┐
│  CooperativeMechanicsService (Firestore CRUD + transactions)      │
│    ├── FamilyGoal — shared household goal with contributions     │
│    ├── FamilyTask — role-based task (admin/child/any)            │
│    ├── HouseholdStreak — collective streak (any member active)   │
│    ├── CooperativeChallenge — multi-member challenge              │
│    ├── ParentChildMission — paired adult+child mission           │
│    └── CooperativeMechanicSnapshot — kill criteria analytics     │
│                                                                  │
│  ⚠️ NOT BRIDGED: rewardPoints fields exist but never credited    │
└──────────────────────────────────────────────────────────────────┘
```

---

## The Points System

### PointableAction Enum (Golden Source)

**File**: `lib/models/action_points.dart`

| Action | Key | Default Points | Category | Custom Points? |
|--------|-----|---------------|----------|----------------|
| `classification` | `classification` | 10 | classification | No |
| `dailyStreak` | `daily_streak` | 5 | streak | No |
| `challengeComplete` | `challenge_complete` | 25 | challenge | No |
| `badgeEarned` | `badge_earned` | 20 | achievement | No |
| `achievementClaim` | `achievement_claim` | 0 | achievement | Yes |
| `quizCompleted` | `quiz_completed` | 15 | education | No |
| `educationalContent` | `educational_content` | 5 | education | No |
| `perfectWeek` | `perfect_week` | 50 | challenge | No |
| `communityChallenge` | `community_challenge` | 30 | challenge | No |
| `streakBonus` | `streak_bonus` | 0 | streak | Yes |
| `migrationSync` | `migration_sync` | 0 | system | Yes |
| `retroactiveSync` | `retroactive_sync` | 0 | system | Yes |
| `instantAnalysis` | `instant_analysis` | 10 | classification | No |
| `manualClassification` | `manual_classification` | 10 | classification | No |

### PointsEngine Internal Values (Actual Runtime)

**File**: `lib/services/points_engine.dart:425-438`

```dart
const pointValues = {
  'classification': 10,
  'daily_streak': 3,          // ← DIFFERENT from PointableAction (5)
  'challenge_complete': 30,   // ← DIFFERENT from PointableAction (25)
  'badge_earned': 25,         // ← DIFFERENT from PointableAction (20)
  'quiz_completed': 15,
  'educational_content': 10,  // ← DIFFERENT from PointableAction (5)
  'perfect_week': 75,         // ← DIFFERENT from PointableAction (50)
  'community_challenge': 30,
  'classification_sync': 10,  // ← NOT in PointableAction
  'feedback_provided': 3,     // ← NOT in PointableAction
  'correction_provided': 15,  // ← NOT in PointableAction
};
```

### GamificationService Internal Values (Dead Code Path)

**File**: `lib/services/gamification_service.dart:52-66`

```dart
static const Map<String, int> _pointValues = {
  'classification': 10,
  'daily_streak': 3,
  'challenge_complete': 30,
  'badge_earned': 25,
  'achievement_claim': 0,
  'quiz_completed': 15,
  'educational_content': 10,
  'perfect_week': 75,
  'community_challenge': 30,
  'feedback_provided': 3,
  'correction_provided': 15,
};
```

### Inconsistency Alert

Three separate point-value maps exist with **conflicting values**:

| Action | `PointableAction` | `PointsEngine` | `GamificationService` |
|--------|-------------------|----------------|----------------------|
| `daily_streak` | 5 | 3 | 3 |
| `challenge_complete` | 25 | 30 | 30 |
| `badge_earned` | 20 | 25 | 25 |
| `educational_content` | 5 | 10 | 10 |
| `perfect_week` | 50 | 75 | 75 |

**PointsEngine wins at runtime** since `GamificationService.addPoints()` delegates to `PointsEngine.addPoints()`. The `PointableAction` enum values are used by `PointsManager` provider but `PointsManager.addPoints()` also delegates to `PointsEngine`, passing `customPoints: action.defaultPoints` — so the `PointableAction` values **do** get used when calling through `PointsManager`, creating an inconsistency depending on which entry point is used.

### Dynamic Points Calculation (Enhanced AI Analysis v2.0)

**File**: `lib/models/waste_classification.dart:759-841`

Base: 10 points. Bonuses stack:

| Bonus | Max Points | Condition |
|-------|-----------|-----------|
| Data richness | +15 | Populated fields count × 1.5 |
| Environmental impact | +5 | `hasEnvironmentalData` true |
| Local compliance | +3 | `hasLocalCompliance` true |
| High confidence | +5 | confidence ≥ 0.9 |
| Medium-high confidence | +3 | confidence ≥ 0.8 |
| Low confidence penalty | -2 | confidence < 0.5 |
| Complexity bonus | +3 | `isComplexItem` true |

**Final range**: `points.clamp(5, 50)`

### Category Multipliers

**File**: `lib/services/points_engine.dart:446-455`

| Category | Multiplier |
|----------|-----------|
| Hazardous Waste | 1.5x |
| Medical Waste | 1.3x |
| Everything else | 1.0x |

**Important**: Category multiplier is only applied when `customPoints == null`. When AI calculates dynamic points (sets `classification.pointsAwarded`), the multiplier is already factored in by the AI's complexity assessment, so it's skipped.

---

## Achievement System

### AchievementType Enum (25 types)

**File**: `lib/models/gamification.dart:30-82`

| # | Type | Used in Code? | Description |
|---|------|--------------|-------------|
| 1 | `wasteIdentified` | **Yes** — `processClassification()` | Total items classified |
| 2 | `categoriesIdentified` | **Yes** — `processClassification()` | Unique categories found |
| 3 | `streakMaintained` | **Yes** — `updateStreak()` | Streak milestones |
| 4 | `challengesCompleted` | **Yes** — `updateChallengeProgress()` | Challenges finished |
| 5 | `perfectWeek` | **Yes** — `updateStreak()` | 7-day streaks |
| 6 | `knowledgeMaster` | **Yes** — `processEducationalContent()` | Educational content viewed |
| 7 | `quizCompleted` | **Yes** — `processEducationalContent()` | Quizzes completed |
| 8 | `specialItem` | Defined only | Special/rare items (eco_warrior secret achievement) |
| 9 | `communityContribution` | Defined only | Community challenges |
| 10 | `metaAchievement` | **Yes** — `_checkMetaAchievements()` | Achievement for earning achievements |
| 11 | `specialEvent` | Defined only | Limited-time events |
| 12 | `userGoal` | Defined only | User-defined goals |
| 13 | `collectionMilestone` | Defined only | Waste type collection |
| 14 | `firstClassification` | Defined only | First ever classification |
| 15 | `weekStreak` | Defined only | Weekly streak |
| 16 | `monthStreak` | Defined only | Monthly streak |
| 17 | `recyclingExpert` | Defined only | Recycling expertise |
| 18 | `compostMaster` | Defined only | Composting expertise |
| 19 | `familyTeamwork` | Defined only | Family cooperation |
| 20 | `helpfulMember` | Defined only | Helpful community member |
| 21 | `educationalContent` | Defined only | Educational engagement |
| 22 | `hazardousWasteExpert` | **Yes** — `processClassification()` | Hazardous waste items |
| 23 | `eWasteCollector` | **Yes** — `processClassification()` | E-waste items |
| 24 | `accuracyChampion` | Defined only | AI corrections |
| 25 | — | — | — |

**Active (has code path)**: 10 of 25
**Defined only (achievement exists, no trigger)**: 15 of 25

### Achievement Families (Tiered Progression)

**File**: `lib/services/gamification_service.dart:1201-1667`

| Family | Bronze | Silver | Gold | Platinum |
|--------|--------|--------|------|----------|
| **Waste Identifier** | Novice (5) | Apprentice (15, L2) | Expert (100, L5) | Master (500, L10) |
| **Category Expert** | Explorer (3) | Master (5) | Collector (50, L7) | — |
| **Streak Maintainer** | Starter (3) | Warrior (7) | Master (30, L4) | Legend (100, L8) |
| **Perfect Record** | Perfect Week (1) | Perfect Month (4, L3) | Perfect Quarter (12, L6) | — |
| **Challenge Conqueror** | Taker (1) | Champion (5) | Master (20, L5) | Legend (50, L10) |
| **Knowledge Explorer** | Seeker (5) | Adept (20) | Expert (50, L3) | — |
| **Quiz Champion** | Taker (1) | Enthusiast (5) | Master (10, L2) | — |
| **Hazardous Waste Expert** | Spotter (3) | Identifier (15, L2) | Expert (50, L5) | Master (200, L10) |
| **E-Waste Collector** | Spotter (3) | Hunter (15, L2) | Expert (50, L5) | — |
| **Accuracy Champion** | Beginner (3) | Adept (25, L3) | Master (100, L7) | — |
| **Special** | Eco Warrior (1, secret) | — | — | — |
| **Meta** | — | — | Achievement Hunter (10 earned, L4) | — |

**Total defined achievements**: 35

### Claim Flow

1. Achievement progress reaches 1.0 AND `unlocksAtLevel` requirement met
2. **Bronze**: auto-claimed (`ClaimStatus.claimed`), points added immediately
3. **Silver/Gold/Platinum**: set to `ClaimStatus.unclaimed`, user must manually claim
4. Manual claim via `PointsEngine.claimAchievementReward()` — adds `pointsReward` to user's total
5. Claim screen: `lib/screens/achievements_screen.dart`

### Level-Gated Unlocks

Achievements with `unlocksAtLevel` require the user to be at that level before they can be earned, even if progress is at 1.0. Progress tracking still happens for locked achievements.

---

## Streak System

### StreakType Enum (4 types)

**File**: `lib/models/gamification.dart:1277-1288`

| Type | Active? | Populated By | Notes |
|------|---------|-------------|-------|
| `dailyClassification` | **Yes** | `GamificationService.updateStreak()`, `PointsEngine.updateStreak()` | Only streak with code paths |
| `dailyLearning` | **No** | Nothing | Dead — would need educational content daily |
| `dailyEngagement` | **No** | Nothing | Dead — would need any daily interaction |
| `itemDiscovery` | **No** | Nothing | Dead — would need unique item discovery tracking |

### Why 3 Are Dead

Only `dailyClassification` is initialized in:
- `GamificationService.getProfile()` — new profiles get only `dailyClassification`
- `PointsEngine._createDefaultProfile()` — same
- `GamificationRepository._createDefaultProfile()` — same

No code path creates entries for `dailyLearning`, `dailyEngagement`, or `itemDiscovery` in the `streaks` map.

### Streak Calculation Logic

**File**: `lib/services/points_engine.dart:359-397`

```
Same day     → No change (return current streak)
1 day gap    → Increment streak (+1), update longestCount if needed
>1 day gap   → Check streak freezes:
                 If freezes available → consume one, keep streak alive
                 If no freezes        → Reset to 1
```

### Streak Freeze Mechanic

**File**: `lib/services/points_engine.dart:386-392`

- `StreakDetails.streakFreezesAvailable` (int, default 0)
- When a gap of 2+ days is detected AND freezes are available, the streak survives
- Freeze is consumed (decremented by 1)
- **No UI exists to acquire streak freezes** — the field exists but there's no purchase/earn path

### Streak Bonus Points

**File**: `lib/services/points_engine.dart:401-419`

| Streak Day | Bonus Points |
|-----------|-------------|
| Day 3 | +15 |
| Day 7 | +35 |
| Day 14 | +70 |
| Day 30 | +150 |
| Any other day | +5 (maintenance) |

### Streak Achievements

Triggered when `streakCount >= 3`:
- `AchievementType.streakMaintained` — thresholds at 3, 7, 30, 100 days
- `AchievementType.perfectWeek` — every 7th day (14, 21, 28, etc.)

---

## Challenge Lifecycle

### Challenge Templates (15 default)

**File**: `lib/services/gamification_service.dart:1671-1841`

| # | Title | Target | Points | Type |
|---|-------|--------|--------|------|
| 1 | Plastic Hunter | 5 Plastic items | 25 | subcategory |
| 2 | Food Waste Warrior | 3 Food Waste | 20 | subcategory |
| 3 | Recycling Champion | 5 Dry Waste | 25 | category |
| 4 | Compost Collector | 4 Wet Waste | 20 | category |
| 5 | Hazard Handler | 2 Hazardous Waste | 30 | category |
| 6 | Medical Material Monitor | 2 Medical Waste | 30 | category |
| 7 | Reuse Revolutionary | 3 Non-Waste | 25 | category |
| 8 | Paper Pursuer | 4 Paper | 20 | subcategory |
| 9 | Glass Gatherer | 3 Glass | 25 | subcategory |
| 10 | Metal Magnet | 3 Metal | 25 | subcategory |
| 11 | Electronic Explorer | 2 E-Waste | 30 | subcategory |
| 12 | Waste Wizard | 10 any | 40 | any_item |
| 13 | High Hazard Week | 5 Hazardous | 50 | category |
| 14 | E-Waste Roundup | 3 E-Waste | 35 | subcategory |
| 15 | Quality Eye | 8 any | 45 | any_item |

### Lifecycle

1. **Creation**: `_generateNewChallenges()` picks random templates, creates `Challenge` with 7-day expiry
2. **Activation**: Auto-triggered when `getActiveChallenges()` finds < 3 active challenges
3. **Progress**: `updateChallengeProgress(classification)` — matches by category, subcategory, or any_item
4. **Completion**: `progress >= 1.0` → moves to `completedChallenges`, awards `challenge_complete` points
5. **Expiry**: `DateTime.now().isAfter(endDate)` → filtered out on next `getActiveChallenges()`
6. **Cleanup**: Expired and completed challenges removed from active list

### Challenge Match Logic

```
requirements.category == classification.category       → category match
requirements.subcategory == classification.subcategory  → subcategory match
requirements.any_item == true                           → any classification counts
```

---

## Level Ladder & Rank Names

**File**: `lib/models/gamification.dart:517-529`

### Level Calculation

```dart
final newLevel = (totalPoints / 100).floor() + 1;
```

| Points Range | Level | Rank Name |
|-------------|-------|-----------|
| 0–99 | 1 | Recycling Rookie |
| 100–199 | 2 | Recycling Rookie |
| 200–299 | 3 | Recycling Rookie |
| 300–399 | 4 | Recycling Rookie |
| 400–499 | 5 | Waste Warrior |
| 500–999 | 6–9 | Waste Warrior |
| 1000–1499 | 10–14 | Segregation Specialist |
| 1500–1999 | 15–19 | Eco Champion |
| 2000–2499 | 20–24 | Sustainability Sage |
| 2500+ | 25+ | Waste Management Master |

### `pointsToNextLevel` (Bug)

```dart
int get pointsToNextLevel {
  final pointsForNextLevel = level * 100;
  return pointsForNextLevel - total;
}
```

This calculates `level * 100 - total`, which can go **negative** once a user exceeds the threshold. Example: level 5, 600 total → `5*100 - 600 = -100`. The calculation doesn't account for the fact that level advancement should show points to the *next* level, not the current one's ceiling.

---

## Token Bridge (Points ↔ Tokens)

**File**: `lib/services/token_service.dart`

### Conversion Rate

| Parameter | Value |
|-----------|-------|
| Rate | 100 points = 1 token |
| Daily conversion cap | 5 conversions/day |
| New user welcome bonus | 50 tokens |
| Daily login bonus | 2 tokens |

### Token Costs

| Analysis Type | Cost |
|--------------|------|
| Batch (queued 2-6h) | 1 token |
| Instant | 5 tokens |
| Instant (premium, 50% discount) | 3 tokens |

### Enforcement Status (Phase 0)

```dart
static bool enableTokenEnforcement = false;        // Kill switch OFF
static bool enableServerSideValidation = true;      // Server validation ON (when Firebase available)
```

- `canAffordAnalysis()` always returns `true` when enforcement is off
- Every check logs `enforcement_skipped` telemetry event
- `spendTokens()` calls server-side `spendUserTokens` Firebase Function when Firebase is available
- Local fallback for guest sessions in debug mode only

### Server-Side Validation Flow

```
spendTokens()
  → isFirebaseEnabled AND enableTokenEnforcement?
    → YES: _spendTokensWithServerValidation()
      → Firebase Function: spendUserTokens({amount, description, reference, metadata})
      → Returns: {success, wallet, transaction}
      → Persists server-returned wallet locally
    → NO: _spendTokensLocally()
      → Deducts locally, saves to Hive + Firestore sync
```

### Wallet Integrity

- SHA-256 integrity hash stored in `Hive.box('settingsBox')['wallet_integrity_$userId']`
- Hash computed via `WalletEncryption.computeIntegrityHash(walletJson, userId)`
- Verified on every wallet load; tampered wallets are replaced with fresh `TokenWallet.newUser()`

### Cross-Device Sync

- On load: `_syncWalletFromFirestore(userId)` — remote wallet wins if `lastUpdated` is newer
- On save: non-blocking Firestore sync via `unawaited(_cloudStorageService.saveUserProfileToFirestore(...))`

---

## Classification → GamificationResult Flow

### The Actual Flow (via ResultPipeline)

```
User captures image
      │
      ▼
ImageCaptureScreen → Navigator.pushReplacement → ResultScreen
      │
      ▼ (initState)
ResultScreen._processClassification()
      │
      ▼
ResultPipeline.processClassification(classification)
      │
      ├── Stage 1: Save locally (duplicate detection)
      │
      ├── Stage 2: Gamification
      │     ├── oldProfile = getProfile()
      │     ├── gamificationService.processClassification(classification)
      │     │     ├── dynamicPoints = classification.pointsAwarded ?? calculatePoints()
      │     │     ├── addPoints('classification', customPoints: dynamicPoints)
      │     │     ├── updateAchievementProgress(wasteIdentified, 1)
      │     │     ├── updateAchievementProgress(categoriesIdentified, N) [if new category]
      │     │     ├── updateAchievementProgress(hazardousWasteExpert, 1) [if applicable]
      │     │     ├── updateAchievementProgress(eWasteCollector, 1) [if applicable]
      │     │     ├── updateChallengeProgress(classification)
      │     │     └── return completedChallenges
      │     ├── newProfile = getProfile(forceRefresh: true)
      │     ├── pointsEarned = newProfile.points.total - oldProfile.points.total
      │     ├── newlyEarnedAchievements = diff
      │     └── completedChallenge = diff
      │
      ├── Stage 3: Cloud sync
      ├── Stage 4: Community post
      └── Stage 5: Maybe show ad
      │
      ▼
ResultPipelineState {pointsEarned, newAchievements, completedChallenge}
      │
      ▼ (Riverpod rebuild)
ResultScreen reads pipelineState
      ├── ResultHeader(pointsEarned)
      ├── PointsCard
      ├── CompletedChallengeCard
      ├── PointsEarnedPopup (overlay)
      └── AchievementCelebration (overlay)
```

### GamificationResult Is Dead Code

`GamificationResult` (`lib/models/gamification_result.dart`) is a data class that was intended to be passed back through `Navigator.pop()`. However:

1. **It is never instantiated** — no file calls `GamificationResult(...)`
2. **`Navigator.push<GamificationResult>` in `home_screen.dart` and `ultra_modern_home_screen.dart` always receives `null`** because `ImageCaptureScreen` uses `pushReplacement`, destroying the return path
3. **The `result.hasRewards` checks are always false** — the home-screen popup overlay from `_showPointsPopup(GamificationResult)` is unreachable code
4. **Actual gamification data flows through Riverpod's `ResultPipelineState`**

---

## Weekly Stats

**File**: `lib/models/gamification.dart:562-631`

### Fields

| Field | Type | Description |
|-------|------|-------------|
| `weekStartDate` | DateTime | Start of the week |
| `itemsIdentified` | int | Total classifications |
| `challengesCompleted` | int | Challenges finished |
| `streakMaximum` | int | Peak streak during week |
| `pointsEarned` | int | Total points this week |
| `categoryCounts` | Map<String, int> | Per-category classification count |

### Storage

- Stored in Hive box `gamificationBox` under key `weeklyStats`
- Also stored on `GamificationProfile.weeklyStats`
- Last 12 weeks retained

### Computation

Two code paths:
1. **Incremental**: `_updateWeeklyStats()` — called by `trackWeeklyAction()` (but this method is never called from the main classification flow)
2. **Full recalculation**: `syncWeeklyStatsWithClassifications()` — rebuilds from actual `WasteClassification` data, groups by week

### Not Surfaced

No screen renders `WeeklyStats` data to users. It's computed, stored, and synced, but never displayed.

---

## Near-Milestone Nudges

**File**: `lib/services/gamification_service.dart:2236-2363`

Priority-ordered nudge system that shows "Almost there!" when user is exactly 1 step away:

| Priority | Type | Condition |
|----------|------|-----------|
| 1 (high) | `dailyGoal` | 1 scan away from daily goal |
| 2 (high) | `challengeNearComplete` | 1 item away from challenge completion |
| 3 (medium) | `categoryAchievement` | 1 point away from category milestone (10/25/50/100) |
| 4 (medium) | `streakMilestone` | 1 day away from streak milestone (3/7/14/30/100) |
| 5 (low) | `pointsMilestone` | ≤5 points away from milestone (50/100/250/500/1000) |

Only returns 1 nudge at a time. Returns null if no milestone is near.

---

## Data Persistence: Hive vs Firestore

### Storage Locations

| Data | Primary | Sync Target | Notes |
|------|---------|-------------|-------|
| `GamificationProfile` | `UserProfile` in Hive | `Firestore users/{uid}` | Via `StorageService` + `CloudStorageService` |
| `TokenWallet` | `UserProfile.tokenWallet` in Hive | `Firestore users/{uid}` | With integrity hash |
| `TokenTransactions` | `UserProfile.tokenTransactions` in Hive | `Firestore users/{uid}` | Last 200 |
| Default Challenges | `gamificationBox['defaultChallenges']` in Hive | No | Templates only |
| Weekly Stats | `gamificationBox['weeklyStats']` in Hive + `GamificationProfile.weeklyStats` | Via profile sync | Last 12 weeks |
| Archived Points | `gamificationBox['archived_points_list']` | No | User data clear history |
| Wallet Integrity Hash | `settingsBox['wallet_integrity_$userId']` | No | SHA-256 |
| Cooperative Mechanics | Firestore only | `families/{familyId}/family_goals`, etc. | No local cache |
| Gamification Cache | `gamification_cache` box | N/A | `GamificationRepository` intermediate cache |

### Sync Strategy

1. **PointsEngine._saveProfile()**: Optimistic local save → non-blocking Firestore sync
2. **GamificationService.saveProfile()**: Local save → blocking Firestore sync
3. **GamificationRepository**: Cache → local → cloud (with offline queue)
4. **Conflict resolution**: Higher `points.total` wins between cloud and local
5. **TokenService**: Remote wallet wins if `lastUpdated` is newer (cross-device)

---

## Cooperative Mechanics

**Model file**: `lib/models/cooperative_mechanics.dart` (980 lines)
**Service file**: `lib/services/cooperative_mechanics_service.dart` (564 lines)
**UI widget**: `lib/widgets/family/cooperative_section.dart` (964 lines)

### Entity Map

| Entity | Firestore Collection | Key Fields | Reward Fields |
|--------|---------------------|------------|---------------|
| FamilyGoal | `family_goals` | targetValue, contributions[], deadline | `rewardPoints` |
| FamilyTask | `family_tasks` | targetRole, dueDate, status, linkedGoalId | `pointsReward` |
| HouseholdStreak | `household_streaks` (single doc `current`) | currentStreak, bestStreak, lastActiveDate | — |
| CooperativeChallenge | `cooperative_challenges` | memberProgress[], minParticipants, type | `rewardPoints` |
| ParentChildMission | `parent_child_missions` | adultTask, childTask, adultUserId, childUserId | `rewardPoints` + `bonusPoints` |

### Kill Criteria

| Criterion | Threshold | Consequence |
|-----------|-----------|-------------|
| Household participation rate | ≥50% active/week | Demote dashboard to presentation layer |
| Goal completion rate | ≥30% completed | Simplify goals (scan count only) or remove |
| Cooperative challenge join rate | ≥40% of active families | Remove cooperative challenges |
| Non-primary user 7-day return | ≥2 returns/week/family | Revert to individual-only gamification |

### Bridge Gap

Cooperative entities define `rewardPoints`/`pointsReward`/`bonusPoints` fields, but **no code path credits these to the user's `GamificationProfile`**. The `CooperativeMechanicsService` is not wired into `PointsEngine` or `GamificationService`.

---

## Orphaned Fields & Dead Code

### Critical Orphaned Fields

| Field | Location | Populated? | Surfaced? | Notes |
|-------|----------|-----------|-----------|-------|
| `StreakDetails.longestCount` | `gamification.dart:1321` | Yes | **No** | Tracked but never displayed |
| `StreakDetails.lastMaintenanceAwardedDate` | `gamification.dart:1326` | No | No | Never set in any code path |
| `StreakDetails.lastMilestoneAwardedLevel` | `gamification.dart:1328` | No | No | Never set in any code path |
| `StreakDetails.streakFreezesAvailable` | `gamification.dart:1330` | Consumed (decremented) | **No** | No earn/purchase path exists |
| `UserPoints.categoryPoints` | `gamification.dart:514` | Yes | **No** | Populated by every classification, never rendered |
| `UserPoints.weeklyTotal` | `gamification.dart:508` | Yes | **No** | Updated but never shown |
| `UserPoints.monthlyTotal` | `gamification.dart:509` | Yes | **No** | Updated but never shown |
| `WeeklyStats.*` (all fields) | `gamification.dart:562-631` | Yes | **No** | Entire model is computed and stored but never displayed |
| `Achievement.unlocksAtLevel` | `gamification.dart:203` | Yes (used for gating) | **No** | Not shown to user (they can't see what level unlocks an achievement) |
| `Achievement.clues` | `gamification.dart:213` | No | No | List exists in model, never populated |
| `Achievement.metadata` | `gamification.dart:208` | Partially | **No** | Only `eco_warrior` has metadata |
| `Achievement.achievementFamilyId` | `gamification.dart:202` | Yes | **No** | Groups tiered achievements, not shown |
| `GamificationResult` | `gamification_result.dart` | **Never instantiated** | N/A | Dead class |
| `TokenWallet.dailyConversionsUsed` | `token_wallet.dart:58` | Yes | No | Internal tracking only |
| `GamificationProfile.discoveredItemIds` | `gamification.dart:711` | No | No | Never populated |
| `GamificationProfile.unlockedHiddenContentIds` | `gamification.dart:717` | No | No | Never populated |
| `GamificationProfile.lastDailyEngagementBonusAwardedDate` | `gamification.dart:713` | No | No | Never used |
| `GamificationProfile.lastViewPersonalStatsAwardedDate` | `gamification.dart:715` | No | No | Never used |

### Dead AchievementType Values (15 of 25)

`specialItem` (partially used by eco_warrior), `communityContribution`, `specialEvent`, `userGoal`, `collectionMilestone`, `firstClassification`, `weekStreak`, `monthStreak`, `recyclingExpert`, `compostMaster`, `familyTeamwork`, `helpfulMember`, `educationalContent` — these enum values exist but have no `getDefaultAchievements()` entry AND no code path that calls `updateAchievementProgress()` with them.

### Dead Code

| Code | File | Lines | Notes |
|------|------|-------|-------|
| `GamificationResult` class | `gamification_result.dart` | 1-21 | Never instantiated |
| `_addPointsInternal()` | `gamification_service.dart` | 544-581 | Dead; `addPoints()` delegates to `PointsEngine` |
| `PointsManager.addPointsByKey()` | `points_manager.dart` | — | Deprecated method |
| `_showPointsPopup(GamificationResult)` | `home_screen.dart` | 134-172 | Never called because `GamificationResult` is always null |
| `_showPointsPopup(GamificationResult)` | `ultra_modern_home_screen.dart` | 109-147 | Same |

---

## Provider/Service Layer Map

```
PointsEngine (singleton, ChangeNotifier)
  ├── Used by: GamificationService, GamificationProvider, PointsManager,
  │            PointsEngineProvider, PointsMigration, AchievementsScreen,
  │            NavigationWrapper, WasteDashboardScreen
  └── Stream controllers: earnedStream, achievementStream

GamificationService (ChangeNotifier)
  ├── Used by: ResultPipeline, GamificationProvider, main.dart,
  │            HomeScreen, ImageCaptureScreen, various sync paths
  └── Delegates to: PointsEngine for point operations

GamificationNotifier (ChangeNotifier)
  └── Thin wrapper around GamificationService profile access

GamificationRepository
  └── Smart caching with Hive cache → local → cloud resolution

PointsManager (ChangeNotifier, provider)
  └── Wraps PointsEngine with PointableAction-typed API
  └── addPointsByKey() is deprecated

PointsEngineProvider (ChangeNotifier)
  └── Wraps PointsEngine singleton for widget tree injection
  └── Provides BuildContext extension: context.pointsEngine

TokenService (ChangeNotifier)
  └── Independent of PointsEngine; manages TokenWallet separately

CooperativeMechanicsService
  └── Firestore-only; no provider registration
  └── Directly instantiated in FamilyDashboardScreen
```

---

## Quick Wins

| # | What | Effort | Impact |
|---|------|--------|--------|
| 1 | Surface `UserPoints.categoryPoints` in a category breakdown widget | Trivial | F14 transparency |
| 2 | Show `StreakDetails.longestCount` in the streak display | Trivial | F14 transparency |
| 3 | Activate `dailyLearning` streak type when educational content is consumed daily | Small | More engagement vectors |
| 4 | Activate `itemDiscovery` streak type when unique items are classified | Small | Discovery incentive |
| 5 | Delete `GamificationResult` dead code (or wire it properly) | Small | Code health |
| 6 | Consolidate 3 point-value maps into 1 canonical source | Medium | Prevents bugs |
| 7 | Show `WeeklyStats` in a personal stats screen | Medium | F14 transparency |
| 8 | Add streak freeze earn path (e.g., premium or achievement reward) | Medium | Retention mechanic |
| 9 | Bridge cooperative mechanic rewards to PointsEngine | Medium | Closes feature gap |
| 10 | Fix `pointsToNextLevel` negative value bug | Trivial | Correctness |

---

## Open Questions

1. **Which point-value map is canonical?** `PointableAction` enum vs `PointsEngine._getPointsForAction()` vs `GamificationService._pointValues`. They disagree on 5 actions.

2. **Is `_addPointsInternal()` in GamificationService needed?** It's dead code since `addPoints()` delegates to `PointsEngine`. Can it be removed?

3. **Why does `GamificationService.updateStreak()` have its own streak logic separate from `PointsEngine.updateStreak()`?** Two independent streak calculators exist. Which is called when?

4. **Should `GamificationResult` be wired into the navigation flow or removed?** The `Navigator.push<GamificationResult>` pattern in home screens is dead.

5. **What triggers `trackWeeklyAction()`?** The method exists but appears to have no callers in the main classification pipeline. `syncWeeklyStatsWithClassifications()` is the actual computation path.

6. **How should cooperative rewards bridge to the gamification engine?** Design decision needed: per-user credit on goal/challenge completion, or household-level point pool.

7. **What happens to `StreakDetails.lastMaintenanceAwardedDate` and `lastMilestoneAwardedLevel`?** They're in the schema but never written. Were these intended for milestone-based bonus points?

8. **Should the 15 unused `AchievementType` values be activated or removed?** They exist as enum values with no templates and no trigger code.

---

*Document generated from source code analysis on 2026-05-25. All file paths and line numbers refer to the current `main` branch state.*
