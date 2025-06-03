# Gamification Phase 1: Implementation Plan

## 1. Introduction

This document details the technical implementation plan for Phase 1 of the Gamification and Engagement System for the Waste Segregation App. It builds upon the strategies outlined in `docs/project/enhancements/gamification_engagement_strategy.md` and focuses on delivering the Core Mechanics & Foundational Engagement (MVP).

**Phase 1 Goals:** Implement essential gamification elements to reward core app behaviors (classification, learning), encourage consistency (streaks), provide basic progress tracking (points, badges, leaderboard), and gather initial user feedback.

## 2. Data Model Refinements for Phase 1

Based on `gamification_engagement_strategy.md` (Section 6.1) and focusing only on Phase 1 requirements.

### 2.1. `UserProfile.gamificationProfile` (Embedded in `users/{userId}`)

*   `points`: (Number) Total accumulated engagement points. Initialized to 0.
*   `current_streaks`:
    *   `daily_classification_streak`: { `count`: Number, `last_activity_date`: Timestamp } - Tracks consecutive days with at least one classification.
    *   `daily_learning_streak`: { `count`: Number, `last_activity_date`: Timestamp } - Tracks consecutive days with at least one educational content engagement.
*   `earned_badges`: (Map<String, Timestamp>) Stores `badgeId: timestamp_earned`.
*   `active_challenges`: (Array of Objects) - *Initially, for Phase 1 daily challenges, this might be simplified. We might not need to store active daily challenges on the user profile if they are generic and reset daily globally. However, if a user "accepts" or starts a specific instance of a daily challenge, then we would store its `challenge_id` and current `progress` here. For MVP, let's assume daily challenges are checked implicitly based on daily actions rather than explicit user acceptance.* Consider if a specific daily challenge instance needs to be stored or if user's daily actions are evaluated against global daily challenge definitions.
*   `completed_daily_challenge_dates`: (Map<String, String>) - Stores `YYYY-MM-DD: challengeId` to track which daily challenge was completed on a specific date, preventing re-completion of the *same* daily challenge if it were to persist due to an issue. More robustly, this could be a subcollection if more data per completion is needed.

### 2.2. Global `badges` Collection (`badges/{badgeId}`)

*   `badgeId`: (String) Document ID (e.g., "plastic_pro_1", "learning_starter_1").
*   `name`: (String) e.g., "Plastic Pro - Tier 1"
*   `description`: (String) How to earn it.
*   `criteria`: (Object) Specific conditions for Phase 1 badges (see Section 4.1 for examples).
    *   Example: `{ "action": "classify_material", "params": { "material": "plastic", "count": 25 } }`
    *   Example: `{ "action": "complete_educational_content", "params": { "type": "quiz", "count": 1 } }`
    *   Example: `{ "action": "maintain_streak", "params": { "type": "daily_classification_streak", "days": 3 } }`
*   `icon_url`: (String) Path to the badge image asset in Firebase Storage.
*   `points_bonus`: (Number) Points awarded when this badge is unlocked (e.g., 25, 50).
*   `category`: (String) e.g., "Classification", "Learning", "Consistency".

### 2.3. Global `daily_challenges` Collection (`daily_challenges/{challengeId}`)

*   `challengeId`: (String) Document ID (e.g., "daily_classify_3_plastics", "daily_read_any_article").
*   `name`: (String) e.g., "Daily Plastic Classifier"
*   `description`: (String) e.g., "Classify 3 plastic items today for a bonus!"
*   `goal`: (Object) Definition of completion.
    *   Example: `{ "action": "classify_material", "params": { "material": "plastic", "count": 3, "time_window": "today" } }`
    *   Example: `{ "action": "complete_educational_content", "params": { "count": 1, "time_window": "today" } }`
*   `rewards`: { `points`: Number } (e.g., 20 points).
*   `is_active`: (Boolean) Whether this challenge template is currently in rotation for users.
*   `ai_assisted_text`: (Boolean) True if AI helped generate the text (for admin tracking).

## 3. Point Earning Logic (Phase 1)

This section defines how users earn engagement points in Phase 1.

### 3.1. Point-Earning Actions & Initial Values

| Action                                       | Points Awarded | Notes                                                                                                |
| :------------------------------------------- | :------------- | :--------------------------------------------------------------------------------------------------- |
| **Classification**                           |                |                                                                                                      |
| Successful item classification (any type)    | 5              | Base points for any correct classification.                                                          |
| Bonus: Correctly classify a "Hard to Identify" item | +5             | Future: Could be a flag on item definitions. For Phase 1, might be omitted or manually defined for a few items. |
| **Educational Content**                      |                |                                                                                                      |
| Complete an educational article (read to end) | 10             | Requires tracking scroll depth or a "Mark as Read" button.                                           |
| Complete an educational video (watch to end) | 10             | Requires tracking video completion.                                                                  |
| Successfully complete a quiz                 | 25             | Awarded for meeting the quiz's pass mark.                                                            |
| Bonus: Score 90%+ on a quiz                  | +15            | Additional bonus for high performance.                                                               |
| **Badge Unlocks**                            | Variable       | Points awarded when a badge is earned (defined in `badges/{badgeId}.points_bonus`). See Section 4.1. |
| **Daily Challenge Completion**               | Variable       | Points awarded upon completing a daily challenge (defined in `daily_challenges/{challengeId}.rewards.points`). See Section 6. |
| **Streak Milestones (Implicit)**             |                | While streaks themselves are tracked, explicit point bonuses for *hitting* streak milestones (e.g. 7-day, 30-day) will be part of Badge criteria for Phase 1, not direct point awards. For example, a "7-Day Streak" badge will have its own `points_bonus`. |

### 3.2. Cloud Function Design for Awarding Points

*   **Primary Function:** A single, versatile Cloud Function, say `awardPoints`, triggered by various events or called by other functions.
    *   **Trigger/Caller:** Could be Firestore triggers (e.g., on creation of a `classification_log` document, `quiz_attempt` document) or direct calls from other Cloud Functions that manage specific actions (e.g., a function that processes educational content completion).
    *   **Parameters:** `userId`, `actionType` (e.g., "CLASSIFICATION_SUCCESS", "QUIZ_COMPLETE_HIGH_SCORE", "BADGE_UNLOCKED"), `relatedEntityId` (optional, e.g., `quizId`, `badgeId`), `pointsToAward` (if determined by caller, otherwise looked up by `actionType`).
    *   **Logic:**
        1.  Validates `userId` and `actionType`.
        2.  Determines the number of points to award based on `actionType` (either passed in or from a configuration). For badge/challenge completion, the points might be part of the badge/challenge definition.
        3.  Atomically updates `UserProfile.gamificationProfile.points` for the user using Firestore transaction or FieldValue.increment().
        4.  (Important) Creates a log entry in a new subcollection like `users/{userId}/point_transactions/{transactionId}` with details: `{ timestamp, actionType, pointsAwarded, relatedEntityId, description }`. This log is crucial for debugging, user history, and potential future display to the user.
*   **Supporting Functions/Triggers:**
    *   **On Classification:** A Cloud Function triggered when a new successful classification is logged. This function will call `awardPoints` with `actionType: "CLASSIFICATION_SUCCESS"`.
    *   **On Educational Content Completion:** Cloud Functions triggered when an article/video is marked complete, or a quiz attempt is successfully saved. These will call `awardPoints` with appropriate `actionType` (e.g., "ARTICLE_COMPLETE", "QUIZ_COMPLETE", "QUIZ_COMPLETE_HIGH_SCORE").
*   **Configuration for Point Values:** Point values for basic actions (like classification, article read) can be stored in a configuration document in Firestore (e.g., `app_config/gamification_settings`) that the `awardPoints` function can read. This allows for easier tuning via the Admin Panel later without re-deploying functions.

## 4. Badge Implementation (Phase 1)

This section details the initial set of badges for Phase 1 and the backend logic to award them.

### 4.1. Phase 1 Badge List

Below are the initial ~10-15 badges focusing on classification, learning, and consistency.

**Classification Badges:**

1.  **`badgeId: classifier_initiate_1`**
    *   `name`: "Recycling Rookie"
    *   `description`: "Successfully classified your first item."
    *   `category`: "Classification"
    *   `criteria`: `{ "action": "classify_any_item", "params": { "count": 1 } }`
    *   `icon_url`: "gs://your-bucket/badges/rookie_classifier.png" (Placeholder)
    *   `points_bonus`: 10
2.  **`badgeId: plastic_novice_1`**
    *   `name`: "Plastic Explorer"
    *   `description`: "Successfully classified 10 plastic items."
    *   `category`: "Classification"
    *   `criteria`: `{ "action": "classify_material", "params": { "material": "plastic", "count": 10 } }`
    *   `icon_url`: "gs://your-bucket/badges/plastic_novice.png" (Placeholder)
    *   `points_bonus`: 20
3.  **`badgeId: paper_novice_1`**
    *   `name`: "Paper Pathfinder"
    *   `description`: "Successfully classified 10 paper items."
    *   `category`: "Classification"
    *   `criteria`: `{ "action": "classify_material", "params": { "material": "paper", "count": 10 } }`
    *   `icon_url`: "gs://your-bucket/badges/paper_novice.png" (Placeholder)
    *   `points_bonus`: 20
4.  **`badgeId: general_classifier_adept_1`**
    *   `name`: "Sorting Star"
    *   `description`: "Successfully classified 50 items in total."
    *   `category`: "Classification"
    *   `criteria`: `{ "action": "classify_any_item", "params": { "count": 50 } }`
    *   `icon_url`: "gs://your-bucket/badges/sorting_star.png" (Placeholder)
    *   `points_bonus`: 50
5.  **`badgeId: variety_classifier_1`**
    *   `name`: "Diversity Detective"
    *   `description`: "Successfully classified items from at least 3 different material categories (e.g., plastic, paper, glass)."
    *   `category`: "Classification"
    *   `criteria`: `{ "action": "classify_variety", "params": { "distinct_material_categories": 3 } }`
    *   `icon_url`: "gs://your-bucket/badges/diversity_detective.png" (Placeholder)
    *   `points_bonus`: 30

**Learning Badges:**

6.  **`badgeId: learner_initiate_1`**
    *   `name`: "Curious Mind"
    *   `description`: "Completed your first educational content (article or quiz)."
    *   `category`: "Learning"
    *   `criteria`: `{ "action": "complete_educational_content", "params": { "count": 1 } }`
    *   `icon_url`: "gs://your-bucket/badges/curious_mind.png" (Placeholder)
    *   `points_bonus`: 15
7.  **`badgeId: quiz_starter_1`**
    *   `name`: "Quiz Whiz Kid"
    *   `description`: "Successfully completed your first quiz."
    *   `category`: "Learning"
    *   `criteria`: `{ "action": "complete_educational_content", "params": { "type": "quiz", "count": 1 } }`
    *   `icon_url`: "gs://your-bucket/badges/quiz_whiz_kid.png" (Placeholder)
    *   `points_bonus`: 25
8.  **`badgeId: article_reader_1`**
    *   `name`: "Page Turner"
    *   `description`: "Read 3 educational articles."
    *   `category`: "Learning"
    *   `criteria`: `{ "action": "complete_educational_content", "params": { "type": "article", "count": 3 } }`
    *   `icon_url`: "gs://your-bucket/badges/page_turner.png" (Placeholder)
    *   `points_bonus`: 20
9.  **`badgeId: learning_buff_1`**
    *   `name`: "Knowledge Seeker"
    *   `description`: "Completed 5 pieces of educational content (articles or quizzes)."
    *   `category`: "Learning"
    *   `criteria`: `{ "action": "complete_educational_content", "params": { "count": 5 } }`
    *   `icon_url`: "gs://your-bucket/badges/knowledge_seeker.png" (Placeholder)
    *   `points_bonus`: 40

**Consistency Badges:**

10. **`badgeId: streak_classify_3day_1`**
    *   `name`: "Steady Sorter"
    *   `description`: "Maintained a 3-day classification streak."
    *   `category`: "Consistency"
    *   `criteria`: `{ "action": "maintain_streak", "params": { "type": "daily_classification_streak", "days": 3 } }`
    *   `icon_url`: "gs://your-bucket/badges/steady_sorter.png" (Placeholder)
    *   `points_bonus`: 25
11. **`badgeId: streak_learn_3day_1`**
    *   `name`: "Consistent Learner"
    *   `description`: "Maintained a 3-day learning streak."
    *   `category`: "Consistency"
    *   `criteria`: `{ "action": "maintain_streak", "params": { "type": "daily_learning_streak", "days": 3 } }`
    *   `icon_url`: "gs://your-bucket/badges/consistent_learner.png" (Placeholder)
    *   `points_bonus`: 25
12. **`badgeId: daily_challenge_starter_1`**
    *   `name`: "Challenger Approaching"
    *   `description`: "Completed your first daily challenge."
    *   `category`: "Consistency"
    *   `criteria`: `{ "action": "complete_daily_challenge", "params": { "count": 1 } }`
    *   `icon_url`: "gs://your-bucket/badges/challenger_approaching.png" (Placeholder)
    *   `points_bonus`: 15

### 4.2. Cloud Function Design for Checking & Awarding Badges

*   **Function Name:** `evaluateAndAwardBadges`
*   **Trigger:** This function will likely be called by other Cloud Functions after a relevant user action that might contribute to a badge criteria has been processed. Examples:
    *   After `awardPoints` (as points often correlate with actions like classification or content completion).
    *   After a streak is updated by the `updateStreaks` function.
    *   After a daily challenge is completed.
    *   A dedicated Firestore trigger on `users/{userId}/activity_logs/{logId}` (if we implement such fine-grained activity logging) could also work but might be too chatty. A more controlled invocation is preferred initially.
*   **Parameters:** `userId`, `actionType` (the action that triggered this evaluation, e.g., "CLASSIFICATION_SUCCESS", "STREAK_UPDATED", "DAILY_CHALLENGE_COMPLETED"), `actionDetails` (optional object with details of the action, e.g., `{ material: "plastic", count: 1 }` or `{ streakType: "daily_classification_streak", days: 3 }`).
*   **Logic:**
    1.  Fetch the user's profile: `users/{userId}` to get `gamificationProfile.earned_badges` and other relevant stats (like total classifications, completed content types, streak counts, etc. These stats might need to be explicitly tracked in `gamificationProfile` or aggregated from logs if not directly available).
    2.  Fetch all badge definitions from the global `badges` collection.
    3.  Iterate through each badge definition:
        *   If the user has already earned this badge (check `earned_badges`), skip.
        *   Evaluate the `badge.criteria` against the user's current stats and the `actionDetails` that triggered the function.
            *   **Example - `classify_material` badge:** If `criteria.action` is "classify_material", check if the user has a running count of classifications for `criteria.params.material` in their `gamificationProfile` (or query their classification logs). If this count meets or exceeds `criteria.params.count`, the badge is earned.
            *   **Example - `maintain_streak` badge:** If `criteria.action` is "maintain_streak", check the relevant streak count in `user.gamificationProfile.current_streaks`. If it meets or exceeds `criteria.params.days`, the badge is earned.
            *   **Example - `classify_variety` badge:** This is more complex. It might require checking the distinct material types the user has classified, which might necessitate storing a list of classified material types in `gamificationProfile` or querying classification logs.
        *   If the criteria are met:
            *   Add the `badgeId` and `timestamp_earned` to `user.gamificationProfile.earned_badges`.
            *   If the badge has a `points_bonus`, call the `awardPoints` function with `actionType: "BADGE_UNLOCKED"`, `relatedEntityId: badgeId`, and `pointsToAward: badge.points_bonus`.
            *   Send a notification to the user (details TBD in UI/UX section).
            *   Log the badge award in a user-specific subcollection like `users/{userId}/badge_awards/{awardId}` with `{ badgeId, timestamp, pointsAwarded }`.
*   **Helper Stats in `gamificationProfile`:** To make badge evaluation efficient and avoid complex queries inside the `evaluateAndAwardBadges` function, consider adding specific counters or aggregated stats to `UserProfile.gamificationProfile`. For example:
    *   `classification_counts_by_material`: `{ plastic: 10, paper: 5, glass: 2 }`
    *   `total_classifications`: 17
    *   `completed_content_counts_by_type`: `{ article: 3, quiz: 1 }`
    *   `total_completed_content`: 4
    *   `distinct_materials_classified`: `["plastic", "paper", "glass"]` (or a count)
    *   `completed_daily_challenges_count`: 1
    These would be updated by the respective action-handling Cloud Functions (e.g., classification function updates `classification_counts_by_material`).
*   **Idempotency:** Ensure that if the function is accidentally triggered multiple times for the same event, a badge is not awarded multiple times (the check for already `earned_badges` handles this).

## 5. Daily Streak Logic (Phase 1)

This section outlines the logic for implementing daily classification and daily learning streaks.

### 5.1. Definition of Daily Activity

*   **Daily Classification Streak:** A user performs at least one successful item classification within a 24-hour day (based on UTC or a user-defined timezone, TBD - UTC is simpler for MVP).
*   **Daily Learning Streak:** A user completes at least one piece of educational content (e.g., marks an article as read, successfully completes a quiz, watches a video to completion) within a 24-hour day (UTC for MVP).
*   A "day" is considered to be from 00:00:00 to 23:59:59 in the chosen timezone (UTC for Phase 1).

### 5.2. Cloud Function Design for Streak Management

*   **Function Name:** `updateStreaks`
*   **Trigger:** This function should be called after a user successfully performs an action that could contribute to a streak:
    *   After a successful classification log.
    *   After an educational content item is marked as completed.
*   **Parameters:** `userId`, `streakType` ("daily_classification_streak" or "daily_learning_streak"), `activityTimestamp` (the server timestamp of the activity).
*   **Logic:**
    1.  Fetch the user's `gamificationProfile` document.
    2.  Get the specific streak object (e.g., `current_streaks.daily_classification_streak`).
    3.  Let `today` be the date part of `activityTimestamp` (e.g., YYYY-MM-DD in UTC).
    4.  Let `lastActivityDate` be the date part of `streak.last_activity_date` (if it exists).
    5.  **If `streak.last_activity_date` does not exist OR `today` is exactly one day after `lastActivityDate`:**
        *   The streak continues or starts.
        *   Increment `streak.count` by 1.
        *   Update `streak.last_activity_date` to `activityTimestamp`.
    6.  **Else if `today` is the same as `lastActivityDate`:**
        *   The user has already performed this type of activity today. No change to `streak.count`.
        *   Update `streak.last_activity_date` to `activityTimestamp` (to record the latest activity for that day, though not strictly necessary for streak logic itself).
    7.  **Else (`today` is more than one day after `lastActivityDate`, or an unexpected condition):**
        *   The streak is broken.
        *   Reset `streak.count` to 1 (as the current activity starts a new streak of 1).
        *   Update `streak.last_activity_date` to `activityTimestamp`.
    8.  Save the updated `gamificationProfile`.
    9.  After updating the streak, call `evaluateAndAwardBadges` as streak changes might unlock new badges (e.g., "3-Day Streak" badge).
*   **Scheduled Streak Check (Optional but Recommended for Robustness):**
    *   Consider a daily scheduled Cloud Function (e.g., running at 00:05 UTC) that iterates through users (or users active in the last X days to manage scale).
    *   For each user, it checks their `last_activity_date` for each streak type against the previous day (current day - 1).
    *   If `current_day_UTC - 1` is not equal to `last_activity_date_UTC` AND `current_day_UTC` is not equal to `last_activity_date_UTC`, then the streak was broken on `current_day_UTC - 1`.
    *   In this case, reset `streak.count` to 0 and clear `streak.last_activity_date` (or set count to 0, keep `last_activity_date` as is, and let the direct `updateStreaks` function handle a new activity starting a streak of 1). This scheduled function ensures streaks are reset even if a user doesn't perform an action on the day their streak breaks.
    *   For Phase 1 MVP, relying solely on the direct `updateStreaks` function might be sufficient, and the scheduled check can be a Phase 2 enhancement if needed for greater accuracy with inactive users.
*   **Timezone Consideration for MVP:** Using server timestamps (Firestore Timestamps, which are UTC) and performing date comparisons in UTC simplifies Phase 1. User-specific timezones add significant complexity and can be a future enhancement.

## 6. Leaderboard Implementation (Phase 1)

This section details the implementation of the all-time points leaderboard for Phase 1.

### 6.1. Data Structure (`leaderboard_allTime` Collection)

As previously discussed and implemented for an earlier version, we will use a dedicated collection, for example, `leaderboard_allTime`. Each document in this collection will represent a user on the leaderboard.

*   **Document ID:** `userId`
*   **Fields:**
    *   `userId`: (String) - Redundant with ID, but useful for querying.
    *   `displayName`: (String) - The name to display on the leaderboard. This should respect user privacy choices (see 6.3).
    *   `points`: (Number) - The user's total engagement points.
    *   `profilePictureUrl`: (String, Optional) - URL to the user's profile picture, if available and privacy settings allow.
    *   `lastUpdated`: (Timestamp) - When this leaderboard entry was last updated.

### 6.2. Cloud Function Design for Leaderboard Updates

*   **Function Name:** `updateLeaderboardEntry`
*   **Trigger:** This function should be triggered whenever a user's total points change. This can be achieved by:
    *   A Firestore trigger on the `users/{userId}` document, specifically listening for changes to `gamificationProfile.points`.
    *   Alternatively, the `awardPoints` function could directly call `updateLeaderboardEntry` after successfully updating a user's points.
*   **Parameters:** `userId`, `newPointsValue`, `currentDisplayName` (fetched from user profile), `profilePictureUrl` (optional, fetched from user profile).
*   **Logic:**
    1.  Takes the `userId`, `newPointsValue`, `currentDisplayName`, and optionally `profilePictureUrl`.
    2.  Performs an upsert operation on the `leaderboard_allTime/{userId}` document:
        *   Sets `userId` to the user's ID.
        *   Sets `points` to `newPointsValue`.
        *   Sets `displayName` to `currentDisplayName` (respecting privacy, see 6.3).
        *   Sets `profilePictureUrl` if provided and allowed.
        *   Sets `lastUpdated` to the current server timestamp.
    3.  This ensures that if a user earns points for the first time, their entry is created. If they already exist, their points and other details are updated.
*   **Efficiency:** Directly updating a specific user's document in `leaderboard_allTime` is efficient. Clients will query this collection, ordering by `points` and limiting the results for display.

### 6.3. Privacy Considerations

*   **User Choice for Display Name:**
    *   During onboarding or in user profile settings, users should be able to choose how their name appears on the leaderboard:
        *   Actual display name.
        *   A self-chosen alias/nickname specifically for the leaderboard.
        *   Appear anonymously (e.g., "Eco Warrior #12345").
    *   The `UserProfile` should store this preference (e.g., `leaderboardDisplayNamePreference`: "actual", "alias", "anonymous" and `leaderboardAlias`: "UserChosenAlias").
    *   The `updateLeaderboardEntry` function must fetch and respect this preference when setting the `displayName` field in the `leaderboard_allTime` collection.
*   **Opt-Out:** Users should have a clear option to opt-out of appearing on the leaderboard entirely. If opted out, their entry should not be written to or should be removed from the `leaderboard_allTime` collection.
*   **Profile Pictures:** Displaying profile pictures should also be an explicit opt-in, respecting user privacy.
*   **Phase 1 Simplification:** For MVP (Phase 1), if full alias/anonymity system is too complex, a simpler approach could be: users can choose to participate with their default display name, or opt-out entirely. The more granular options can be Phase 2 enhancements.

## 7. Daily Challenge System (Phase 1)

This section details the implementation of the daily challenge system for Phase 1, using manually defined templates with AI-assisted text for names and descriptions.

### 7.1. Phase 1 Daily Challenge Templates

These templates are stored in the `daily_challenges` global collection (see Section 2.3 for schema). The Admin Panel will allow managing these definitions.

1.  **`challengeId: daily_classify_3_plastic`**
    *   `name`: "Plastic Roundup"
    *   `description`: "Help sort the synthetics! Classify 3 plastic items today and earn bonus points."
    *   `goal`: `{ "action": "classify_material", "params": { "material": "plastic", "count": 3 } }`
    *   `rewards`: `{ "points": 20 }`
    *   `is_active`: `true`, `ai_assisted_text`: `true`
2.  **`challengeId: daily_classify_5_any`**
    *   `name`: "Sorting Spree"
    *   `description`: "Every bit counts! Classify any 5 items today to boost your score."
    *   `goal`: `{ "action": "classify_any_item", "params": { "count": 5 } }`
    *   `rewards`: `{ "points": 25 }`
    *   `is_active`: `true`, `ai_assisted_text`: `true`
3.  **`challengeId: daily_read_1_article`**
    *   `name`: "Knowledge Nibble"
    *   `description`: "Feed your brain! Read 1 educational article today for a quick point boost."
    *   `goal`: `{ "action": "complete_educational_content", "params": { "type": "article", "count": 1 } }`
    *   `rewards`: `{ "points": 15 }`
    *   `is_active`: `true`, `ai_assisted_text`: `true`
4.  **`challengeId: daily_complete_1_quiz`**
    *   `name`: "Quiz Quickfire"
    *   `description`: "Test your knowledge! Successfully complete 1 quiz today and prove your eco-smarts."
    *   `goal`: `{ "action": "complete_educational_content", "params": { "type": "quiz", "count": 1 } }`
    *   `rewards`: `{ "points": 30 }`
    *   `is_active`: `true`, `ai_assisted_text`: `true`
5.  **`challengeId: daily_classify_1_glass`**
    *   `name`: "Glass Act"
    *   `description`: "Handle with care! Classify 1 glass item today and be rewarded."
    *   `goal`: `{ "action": "classify_material", "params": { "material": "glass", "count": 1 } }`
    *   `rewards`: `{ "points": 15 }`
    *   `is_active`: `true`, `ai_assisted_text`: `true`

### 7.2. Daily Challenge Selection & Presentation

*   **"Challenges of the Day" Selection:**
    *   A scheduled Cloud Function (e.g., `selectDailyChallenges`) runs daily (e.g., 00:01 UTC).
    *   It queries `daily_challenges` for all where `is_active: true`.
    *   Randomly selects 2-3 of these to be the "Challenges of the Day".
    *   Writes their `challengeId`s to `app_config/current_daily_challenges` as: 
        `{ "date": "YYYY-MM-DD" (UTC), "challenges": ["id1", "id2", "id3"] }`.
*   **Client-Side Display:** App fetches `app_config/current_daily_challenges` for the current UTC date to display them.

### 7.3. User Progress Tracking for Daily Challenges

Modify `UserProfile.gamificationProfile` (Section 2.1) to include:
*   `daily_challenge_progress`: `Map<String, Object>`
    *   Key: `challengeId`
    *   Value: `{ "progress_count": Number, "date_for_progress": "YYYY-MM-DD" (String, UTC) }`
This map stores progress only for the current day's active challenges for that user.

### 7.4. Cloud Function for Checking & Completing Daily Challenges

*   **Function Name:** `processUserActionForDailyChallenges`
*   **Trigger:** Called by other functions after a core user action (classification, content completion).
*   **Parameters:** `userId`, `actionType`, `actionDetails` (e.g., `{ material: "plastic" }`).
*   **Logic:**
    1.  Get current UTC date string (`currentDateString`).
    2.  Fetch `app_config/current_daily_challenges`. If date mismatch or unavailable, handle gracefully (e.g., log, challenges may not be active/set).
    3.  Fetch `userProfile` from `users/{userId}`.
    4.  **Progress Reset:** Iterate `userProfile.daily_challenge_progress`. Remove entries where `date_for_progress` isn't `currentDateString`.
    5.  For each `challengeIdToEvaluate` in `app_config/current_daily_challenges.challenges`:
        a.  If `userProfile.completed_daily_challenge_dates[currentDateString] == challengeIdToEvaluate`, skip (already completed today).
        b.  Fetch `challengeDefinition` from `daily_challenges/{challengeIdToEvaluate}`.
        c.  Let `progress = userProfile.daily_challenge_progress[challengeIdToEvaluate]` (initialize if new: `{ progress_count: 0, date_for_progress: currentDateString }`).
        d.  If `actionType` and `actionDetails` match `challengeDefinition.goal` requirements:
            *   Increment `progress.progress_count` appropriately based on goal type (e.g., for `classify_material` if material matches, for `classify_any_item` always, for `complete_educational_content` if type matches).
        e.  Update `userProfile.daily_challenge_progress[challengeIdToEvaluate] = progress`.
        f.  If `progress.progress_count >= challengeDefinition.goal.params.count`:
            i.  Challenge Complete!
            ii. Call `awardPoints(userId, "DAILY_CHALLENGE_COMPLETED", challengeIdToEvaluate, challengeDefinition.rewards.points)`.
            iii. Set `userProfile.completed_daily_challenge_dates[currentDateString] = challengeIdToEvaluate`.
            iv. Call `evaluateAndAwardBadges(userId, "DAILY_CHALLENGE_COMPLETED", { challengeId: challengeIdToEvaluate })`.
            v. Send user notification.
    6.  Save updated `userProfile` (specifically `gamificationProfile`) in a transaction.

## 8. Onboarding & UI/UX (Phase 1)

*   **Notification Management:** Keep notifications concise and avoid being overly spammy. Group notifications if multiple events happen close together (e.g., point + badge for one action).

## 9. Admin Panel Support (Phase 1)

This section outlines the minimum Admin Panel functionalities required to launch and manage Phase 1 of the gamification system. It refers to features detailed in `docs/technical/admin_panel_design.md` but focuses on the MVP subset.

### 9.1. Badge Management (MVP)
*   **Reference:** Admin Panel Design Spec (Section 7.3.1: Badge Definitions CRUD).
*   **Phase 1 Requirement:**
    *   Ability to **Create, Read, Update, and Delete (CRUD)** the 10-15 initial badge definitions in the global `badges` collection.
    *   Fields to manage: `badgeId`, `name`, `description`, `category`, `criteria` (as a structured object, initially input manually as JSON or through a simple form if feasible for MVP), `icon_url` (text input), `points_bonus`.
    *   The AI-assisted badge brainstorming (Admin Spec 7.3.2) is **not** part of Phase 1 app implementation but can be used by the admin *externally* to come up with ideas before manually inputting them.

### 9.2. Daily Challenge Template Management (MVP)
*   **Reference:** Admin Panel Design Spec (Section 7.2.1: Global Challenge Definitions CRUD & 7.2.3: Challenge Parameters).
*   **Phase 1 Requirement:**
    *   Ability to **CRUD** the 5-7 initial daily challenge templates in the `daily_challenges` collection.
    *   Fields to manage: `challengeId`, `name`, `description` (AI-assisted text can be pasted here), `goal` (structured object/JSON), `rewards` (points), `is_active` (boolean toggle), `ai_assisted_text` (boolean toggle for admin tracking).
    *   The AI-assisted challenge proposal *workflow* within the admin panel (Admin Spec 7.2.2) is **not** part of Phase 1 app implementation. Admin will define these manually for Phase 1.

### 9.3. Gamification Configuration Viewing (MVP)
*   **Reference:** Admin Panel Design Spec (Section 7.5: Points & Economy Tuning).
*   **Phase 1 Requirement:**
    *   Ability to **View** (Read-only for Phase 1 simplicity) the point values for basic actions (e.g., classification, article read). These might be stored in `app_config/gamification_settings`.
    *   Editing these directly via Admin Panel can be a Phase 2 enhancement; for Phase 1, direct Firestore edit by admin if tuning is urgently needed.

### 9.4. User Data Viewing (Basic)
*   **Reference:** Admin Panel Design Spec (Section 5.2.2: Gamification Data View).
*   **Phase 1 Requirement:**
    *   Ability to **View** a specific user's `gamificationProfile` (points, earned badges, streak counts, completed daily challenges map) for troubleshooting or support.
    *   Manual adjustment of points/badges via Admin Panel is **deferred to Phase 2** to keep Phase 1 simpler, unless critically needed for fixing an early bug (would require careful direct Firestore edits by admin).

### 9.5. Leaderboard Monitoring (Basic)
*   **Reference:** Admin Panel Design Spec (Section 7.4: Leaderboard Monitoring).
*   **Phase 1 Requirement:**
    *   Ability to **View** the current `leaderboard_allTime` collection (top N users, their points, display names) to ensure it's functioning correctly.

This minimal set of Admin Panel features will allow the administrator to define the core gamification content for Phase 1 and monitor basic system health. 