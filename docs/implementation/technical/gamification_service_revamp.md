# GamificationService Revamp: Implementation Details

This document outlines the planned changes and enhancements to `lib/services/gamification_service.dart` to implement the dynamic point system and AI-driven discovery features as defined in the main `gamification_engagement_strategy.md`.

**Current Status:** The app presently uses a fixed `_pointValues` map for all rewards. The dynamic system described below is not yet live in the codebase or user interface.

## 1. Service Dependencies and Initialization

No major changes anticipated to the constructor or `initGamification()` other than ensuring any new Hive boxes or configurations are handled if needed.

## 2. Point Configuration

The existing `_pointValues` map will be refined and potentially augmented.

*   **`_basePointValues` (Map<String, int>):**
    *   Rename or repurpose `_pointValues` to store base points for atomic actions.
    *   New keys to be added based on `gamification_engagement_strategy.md`:
        *   `'daily_engagement_bonus'`: e.g., 5-10 points
        *   `'view_personal_stats'`: e.g., 5-10 points
        *   `'classification_base'`: e.g., 5-10 points (base for any classification)
        *   `'first_item_discovery'`: e.g., 10-50 points
        *   `'streak_daily_maintenance'`: e.g., 5 points (per streak type, per day)
    *   Adjust existing values as per strategy (e.g., `'educational_content_article'`, `'educational_content_video'`, `'quiz_completed_base'`, `'quiz_high_score_bonus'`, `'badge_earned_generic'`, `'challenge_complete_base'`).
*   **`_streakMilestoneBonuses` (Map<StreakType, Map<int, int>>):**
    *   A new configuration to store escalating streak milestone rewards.
    *   Example: `StreakType.dailyClassification: {3: 15, 7: 35, 14: 75, 30: 150}`.
    *   This will be used by the revamped `updateStreak` logic.
*   **Consider storing these configurations in Firestore** (e.g., `app_config/gamification_points_config`) for easier remote tuning, as suggested in `gamification_phase1_implementation_plan.md`. The service would fetch and cache this config.

## 3. Core Point Awarding & Logging

*   **Private `Future<void> _awardPoints(String userId, int points, String reason, {String? RrelatedEntityId, Map<String, dynamic>? metadata})`:**
    *   Central method to update `GamificationProfile.points.total` (and potentially other point aggregates like weekly/monthly if maintained).
    *   Atomically increments points.
    *   Calls `_logPointTransaction`.
    *   Handles potential errors gracefully.
*   **Private `Future<void> _logPointTransaction(String userId, int points, String reason, String? relatedEntityId, Map<String, dynamic>? metadata)`:**
    *   Creates a detailed log entry for every point transaction.
    *   Stored in a Firestore subcollection like `users/{userId}/point_transactions/{transactionId}`.
    *   Log includes: `timestamp`, `pointsAwarded`, `reasonCode` (e.g., "CLASSIFICATION_BONUS_RARITY", "STREAK_MILESTONE_7D"), `humanReadableReason`, `relatedEntityId` (e.g., `itemId`, `badgeId`, `challengeId`), `currentTotalPointsAfter`.

## 4. Point Earning Event Handlers (Public Methods)

These methods will be called from other parts of the app (e.g., UI, other services) when a gamifiable action occurs. They will calculate appropriate points and use `_awardPoints`.

*   **`Future<void> recordDailyEngagement(String userId)`:**
    *   Awards `_basePointValues['daily_engagement_bonus']`.
    *   Must implement "once per day" logic for the user (e.g., check `GamificationProfile.lastDailyEngagementBonusAwardedDate`).
*   **`Future<void> recordViewPersonalStats(String userId)`:**
    *   Awards `_basePointValues['view_personal_stats']`.
    *   Must implement "once per day" logic.
*   **`Future<void> recordEducationalContentCompleted(String userId, String contentId, ContentType contentType, {int? lengthMinutes, double? quizScore})`:**
    *   Calculates points based on `contentType` (article, video, quiz).
    *   For articles/videos: `_basePointValues['educational_content_article']` or `_basePointValues['educational_content_video']`. Could vary by `lengthMinutes`.
    *   For quizzes: `_basePointValues['quiz_completed_base']`. If `quizScore` meets high score threshold, also calls `recordQuizHighScore`.
*   **`Future<void> recordQuizHighScore(String userId, String quizId, double scorePercentage)`:**
    *   Awards `_basePointValues['quiz_high_score_bonus']`.
*   **`Future<void> recordChallengeCompleted(String userId, String challengeId, int basePointsOverride)`:**
    *   Awards `basePointsOverride` (as challenges have variable points).
*   **`Future<void> recordBadgeEarned(String userId, String badgeId, int pointsBonus)`:**
    *   Awards `pointsBonus` (as badges have variable points).

## 5. Enhanced Classification Rewards

*   **`Future<GamificationUpdate?> awardPointsForClassification(String userId, ClassificationResult classificationResult, ItemDetails itemDetails)`:**
    *   `ClassificationResult` provides basic classification info.
    *   `ItemDetails` is the rich object from the new `item_database_schema.md` corresponding to `classificationResult.itemId` (or `itemName` if ID is not yet resolved). This needs to be fetched or passed in.
    *   **Calculate Total Points:**
        1.  Base classification points: `_basePointValues['classification_base']`.
        2.  **Dynamic Bonuses:**
            *   Rarity Bonus: If `itemDetails.rarityScore` > threshold, add bonus points.
            *   Confidence Bonus: If `classificationResult.confidence` > threshold, add bonus.
            *   Waste Type Bonus: (Optional) Small variation if certain waste types are prioritized.
            *   Accuracy Bonus: (If user corrected an AI suggestion accurately).
        3.  Call `_awardPoints` with the total and a detailed reason.
    *   **First Item Discovery:**
        *   Call `bool isFirstTime = await _checkAndRecordFirstItemDiscovery(userId, itemDetails.itemId)`.
        *   If `isFirstTime`:
            *   Award `_basePointValues['first_item_discovery']`.
            *   Call `_checkForHiddenUnlocks(userId, itemDetails)` (see Section 7).
    *   Return a `GamificationUpdate` object (similar to existing structure) with points breakdown, reasons, etc.

## 6. Overhauled Streak Logic

*   **`Future<StreakUpdateResult?> updateStreak(String userId, StreakType streakType, DateTime activityTimestamp)`:**
    *   `StreakType` enum: `dailyClassification`, `dailyLearning`, `dailyEngagement` (for Daily Engagement Bonus streak if desired), `itemDiscovery` (e.g., streak of discovering new items daily).
    *   Fetch `GamificationProfile`.
    *   Access the specific streak data (e.g., `profile.streaks[streakType]`).
    *   **Core Streak Update Logic (as previously discussed):**
        *   Determine if streak continues, starts, or breaks based on `activityTimestamp` and `lastActivityDate` of the streak.
        *   Update `currentCount`, `longestCount`, `lastActivityDate`.
    *   **Point Awarding for this Streak Update:**
        1.  **Daily Maintenance:**
            *   If streak continues or starts today AND maintenance points for this `streakType` haven't been awarded today:
                *   Award `_basePointValues['streak_daily_maintenance']`.
                *   Log/mark that maintenance for this `streakType` was awarded for today (e.g., update `GamificationProfile.streaks[streakType].lastMaintenanceAwardedDate`).
        2.  **Milestone Bonus:**
            *   If `currentCount` hits a milestone defined in `_streakMilestoneBonuses[streakType]`:
                *   Award the corresponding milestone bonus points.
                *   Ensure milestone bonus is awarded only once per milestone achievement (e.g., by checking if `profile.streaks[streakType].lastMilestoneAwardedLevel < currentCountMilestoneLevel`).
    *   Save `GamificationProfile`.
    *   Return a `StreakUpdateResult` with details of the update (new count, points awarded, etc.).

## 7. Discovery & Hidden Content Hooks

*   **Private `Future<void> _checkAndRecordFirstItemDiscovery(String userId, String itemId)`:**
    *   Fetches `GamificationProfile`.
    *   Checks if `itemId` is in `gamificationProfile.discoveredItemIds`.
    *   If not, adds it and saves the profile. Returns `true`. Else `false`.
*   **Private `Future<void> _checkForHiddenUnlocks(String userId, ItemDetails itemDetails)`:**
    *   **Placeholder for Phase 2+ AI integration.**
    *   This method will eventually:
        1.  Fetch AI-curated rules for hidden badges, map unlocks, etc. (e.g., from a Firestore collection of `HiddenContentRules`). These rules would specify trigger conditions (e.g., "discover item X," "discover 3 items with tag Y," "scan item Z after item Q").
        2.  Evaluate these rules against the `itemDetails` of the newly discovered item and the user's `GamificationProfile` (e.g., their `discoveredItemIds`, current badges).
        3.  If a hidden unlock is triggered:
            *   Update `GamificationProfile` (e.g., add a hidden badge ID to `earned_badges`, unlock a map area).
            *   Award any associated points/rewards via `_awardPoints`.
            *   Potentially trigger a notification or UI event.
*   **Personalized Discovery Quests/Hints (Future):**
    *   A separate mechanism, likely triggered periodically or on specific app events (e.g., app open, after several classifications).
    *   Would involve calling an AI service with user context to get quest/hint suggestions.
    *   Not directly part of the immediate point awarding flow but linked to the discovery theme.

## 8. Other Existing Methods

*   Review methods like `getProfile`, `saveProfile`, `getDefaultAchievements`, `_loadDefaultChallengesFromHive`, `processClassification` (which will be largely replaced/refactored by `awardPointsForClassification`), `updateAchievements`, `updateChallenges`, `getLeaderboardData`, etc.
*   Adapt or deprecate them as needed to fit the new structure. For example, `processClassification` will likely be heavily refactored. Achievement and challenge updates will still be needed but might be triggered after points are awarded.

This detailed plan should provide a good roadmap for refactoring `GamificationService`. 