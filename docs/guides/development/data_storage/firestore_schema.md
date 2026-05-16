# Firestore Schema

> **Canonical source:** `lib/services/firestore_schema_registry.dart`
> This document is derived from the schema registry. If they diverge, the registry wins.
> Last verified: 2026-05-16

This document describes the collections and data structures used in Firebase Firestore, aligned with the actual model classes and service code.

## Schema Governance

All Firestore collection names, field definitions, and privacy classifications are defined in `FirestoreCollections`, `*Schema` classes, and `PrivacyGuardConfig` in `lib/services/firestore_schema_registry.dart`.

**When adding a new collection or field:**
1. Add it to the schema registry first
2. Update Firestore security rules to match
3. Regenerate this document from the registry

**When modifying an existing field:**
1. Update the schema registry
2. Update Firestore security rules
3. Update this document
4. Add a migration path if the field is renamed or removed

---

## 1. Users (`users`)

* **Document ID**: `userId` (same as Firebase Auth UID)
* **Source model**: `UserProfile.toJson()` from `lib/models/user_profile.dart`
* **Privacy**: User-owned; each user can only read/write their own document

| Field | Type | Classification | Required | Notes |
|-------|------|---------------|----------|-------|
| `id` | String | system | yes | Firebase Auth UID, same as document ID |
| `displayName` | String? | **PII** | no | User-chosen display name |
| `email` | String? | **PII** | no | Consider redacting before Firestore write; available via Firebase Auth |
| `photoUrl` | String? | **PII** | no | Profile photo URL; also written to leaderboard — needs opt-out |
| `familyId` | String? | private | no | ID of the family the user belongs to |
| `role` | String? | private | no | UserRole enum as string (guest, member, admin) |
| `createdAt` | String? | system | no | ISO 8601 timestamp |
| `lastActive` | String? | system | no | ISO 8601 timestamp |
| `preferences` | Map? | private | no | User preferences map (NOT a separate UserSettings class) |
| `gamificationProfile` | Map? | private | no | Embedded `GamificationProfile.toJson()` |
| `tokenWallet` | Map? | private | no | Embedded `TokenWallet.toJson()` |
| `tokenTransactions` | List? | private | no | Embedded token transaction history |

### GamificationProfile Structure

Embedded in the user document, NOT a separate class called `UserPreferences` or `DailyStreak`. The actual structure:

| Field | Type | Notes |
|-------|------|-------|
| `userId` | String | User ID |
| `achievements` | List<Map> | From `Achievement.toJson()` |
| `streaks` | Map<String, Map> | `Map<String, StreakDetails>` — NOT a `DailyStreak` class |
| `points` | Map | From `UserPoints.toJson()`: total, weeklyTotal, monthlyTotal, level, categoryPoints |
| `activeChallenges` | List<Map> | From `Challenge.toJson()` |
| `completedChallenges` | List<Map> | From `Challenge.toJson()` |
| `weeklyStats` | List<Map> | From `WeeklyStats.toJson()` |
| `discoveredItemIds` | List<String> | Waste item IDs the user has identified |
| `lastDailyEngagementBonusAwardedDate` | String? | ISO 8601 |
| `lastViewPersonalStatsAwardedDate` | String? | ISO 8601 |
| `unlockedHiddenContentIds` | List<String> | Content IDs |

---

## 2. Classifications (`users/{userId}/classifications`)

* **Subcollection of**: `users`
* **Document ID**: Auto-generated UUID or `WasteClassification.id`
* **Source model**: `WasteClassification.toJson()` from `lib/models/waste_classification.dart`
* **Privacy**: User-owned; only the owning user can read/write

This model has 70+ fields. Key fields:

| Field | Type | Classification | Notes |
|-------|------|---------------|-------|
| `id` | String | system | UUID |
| `itemName` | String | userContent | Name of classified waste item |
| `category` | String | userContent | Waste category |
| `confidence` | double? | system | AI confidence score 0.0-1.0 (**NOT "accuracy"**) |
| `timestamp` | String | system | ISO 8601 |
| `userId` | String? | private | Owning user ID |
| `imageUrl` | String? | private | Cloud storage URL |
| `subcategory` | String? | userContent | **Deprecated** — use `subCategory` (AI v2.0) |
| `materialType` | String? | userContent | **Deprecated** — use `materials` list (AI v2.0) |

Full field list: see `WasteClassification.fromJson()` in `waste_classification.dart`.

---

## 3. Community Feed (`community_feed`)

* **Document ID**: Auto-generated
* **Source model**: `CommunityFeedItem.toJson()` from `lib/models/community_feed.dart`
* **Privacy**: Public within authenticated users; `isAnonymous` flag controls display

| Field | Type | Classification | Required | Notes |
|-------|------|---------------|----------|-------|
| `id` | String | system | yes | Feed item ID |
| `userId` | String | **PII** | yes | Author user ID — must match auth UID |
| `userName` | String | **PII** | yes | Display name — anonymized if `isAnonymous` |
| `userAvatar` | String? | **PII** | no | Avatar URL — omitted if `isAnonymous` |
| `activityType` | String | system | yes | One of: classification, achievement, streak, challenge, milestone, educational |
| `title` | String | userContent | yes | Feed item title |
| `description` | String | userContent | yes | Feed item description |
| `timestamp` | Timestamp | system | yes | Server timestamp |
| `metadata` | Map | userContent | no | Arbitrary metadata (category, confidence, etc.) |
| `likes` | int | aggregate | no | Like count, default 0 |
| `likedBy` | List<String> | private | no | User IDs who liked |
| `isAnonymous` | bool | system | no | Privacy flag — controls display |
| `points` | int | aggregate | no | Points awarded, default 0 |

---

## 4. Families (`families`)

* **Document ID**: Auto-generated UUID
* **Source model**: `Family.toJson()` from `lib/models/enhanced_family.dart`
* **Privacy**: Family members can read; creator can create

| Field | Type | Classification | Notes |
|-------|------|---------------|-------|
| `id` | String | system | UUID, same as document ID |
| `name` | String | userContent | Family name (**NOT "familyName"**) |
| `description` | String? | userContent | |
| `createdBy` | String | system | User ID who created the family (**NOT "familyAdminUids"**) |
| `createdAt` | String | system | ISO 8601 |
| `updatedAt` | String? | system | ISO 8601 |
| `members` | List<Map> | private | Embedded `FamilyMember` objects |
| `memberUids` | List<String> | system | Flat list of member user IDs for Firestore rules membership checks. Derived from `members[].userId`. Legacy docs without this field can derive it on read. |
| `settings` | Map | private | Embedded `FamilySettings` object (**NOT "familyLeaderboardSettings"**) |
| `imageUrl` | String? | private | |
| `isPublic` | bool | system | Default false |

---

## 5. All-Time Leaderboard (`leaderboard_allTime`)

* **Document ID**: `userId` (same as Firebase Auth UID)
* **Source model**: `LeaderboardEntry.toJson()` from `lib/models/leaderboard.dart` + `cloud_storage_service.dart` writes
* **Privacy**: Public read for all authenticated users; write-only for own entry

| Field | Type | Classification | Notes |
|-------|------|---------------|-------|
| `userId` | String | system | Auth UID |
| `displayName` | String | **PII** | Denormalized for leaderboard display — needs opt-out |
| `photoUrl` | String? | **PII** | Denormalized for leaderboard display — needs opt-out |
| `points` | int | aggregate | From `UserPoints.total` |
| `rank` | int? | aggregate | Optional, can be computed client-side |
| `weeklyPoints` | int? | aggregate | Weekly subtotal if stored |
| `lastUpdated` | Timestamp | system | `FieldValue.serverTimestamp()` |

**Note on ranks**: See leaderboard_service.dart — ranks are computed client-side by fetching top N entries ordered by points.

---

## 6. Weekly Leaderboard (`leaderboard_weekly`)

* **Document ID**: Week ID in format `YYYY-WNN` (e.g., `2025-W24`)
* **Source model**: Defined in Firestore rules but **not yet implemented in service code**
* **Status**: Rules exist but `LeaderboardService` only uses `leaderboard_allTime`

| Field | Type | Classification | Notes |
|-------|------|---------------|-------|
| `userId` | String | system | |
| `weeklyPoints` | int | aggregate | |
| `weekId` | String | system | Format: `YYYY-WNN` |
| `rank` | int? | aggregate | |
| `lastUpdated` | Timestamp | system | |

---

## 7. Community Stats (`community_stats`)

* **Document ID**: `main` (singleton)
* **Source model**: `CommunityStats.toJson()` from `lib/models/community_feed.dart`
* **Privacy**: Read-only for authenticated users; written by Cloud Functions / admin only

| Field | Type | Classification | Notes |
|-------|------|---------------|-------|
| `totalUsers` | int | aggregate | |
| `totalClassifications` | int | aggregate | |
| `totalPoints` | int | aggregate | |
| `categoryBreakdown` | Map<String, int> | aggregate | |
| `lastUpdated` | Timestamp | system | |

---

## 8. Classification Feedback (`classification_feedback`)

* **Source model**: `ClassificationFeedback` from `lib/models/classification_feedback.dart`
* **Privacy**: User-owned create and read; no delete (admin only)

| Field | Type | Classification | Notes |
|-------|------|---------------|-------|
| `userId` | String | PII | Must match auth UID |
| `originalClassificationId` | String | system | Reference to classification |
| `feedbackTimestamp` | Timestamp | system | |

---

## 9. Family Stats (`family_stats`)

* **Document ID**: `familyId`
* **Written by**: `FirebaseFamilyService` and Cloud Functions
* **Privacy**: Read-only for authenticated users; written by service/admin

---

## 10. Invitations (`invitations`)

* **Written by**: `FirebaseFamilyService`
* **Privacy**: Authenticated users can create and read; indexed by familyId and invitedEmail

---

## 11. Shared Classifications (`shared_classifications`)

* **Written by**: `FirebaseFamilyService`
* **Privacy**: Authenticated users can create; only the sharer can update/delete
* **Indexed**: By familyId and sharedAt (see `firestore.indexes.json`)

---

## 12. AI Jobs (`ai_jobs`)

* **Source model**: `AiJob` from `lib/models/ai_job.dart`
* **Privacy**: User-owned; each user can only access their own jobs

---

## 13. Token Wallets (`token_wallets`) & Token Transactions (`token_transactions`)

* **Source models**: `TokenWallet` and `TokenTransaction` from `lib/models/token_wallet.dart`
* **Privacy**: User-owned; each user can only access their own data

---

## 14. Analytics Events (`analytics_events`)

* **Validated by**: `AnalyticsSchemaValidator` in `lib/services/analytics_schema_validator.dart`
* **Privacy**: Users can create; no read access (admin only)

---

## 15. Disposal Instructions (`disposal_instructions`) & Disposal Locations (`disposal_locations`)

* **Privacy**: Read-only for authenticated users; written by admin/Cloud Functions only

---

## 16. Admin Collections (`admin`, `admin_classifications`, `admin_user_recovery`)

* **Privacy**: No user access; Cloud Functions and admin SDK only
* **Note**: `admin_classifications` stores anonymized classifications for ML training. `admin_user_recovery` stores hashed user IDs for recovery.

---

## 17. User Contributions (`user_contributions`)

* **Written by**: `contribution_submission_screen.dart`
* **Privacy**: Users can create their own; public contributions are readable by all

---

## 18. Gamification (`gamification`)

* **Document ID**: `userId`
* **Privacy**: User-owned; separate from the gamification profile embedded in the user document
* **Note**: May be used as an alternative storage location for gamification data

---

## Extensible Leaderboard Schema (Planned)

The multi-type leaderboard schema described in the previous version of this document (with `leaderboardType`, `period`, `category`, `groupId`, `region`) is **not yet implemented**. Only `leaderboard_allTime` is active. The `leaderboard_weekly` collection has rules defined but no service code writes to it.

When this is implemented, the schema should be added to `FirestoreCollections` and the registry, with corresponding rules updates.

---

## Privacy Considerations

### PII Fields and Collection Visibility

| Collection | PII Fields | Visibility | Mitigation |
|------------|-----------|------------|------------|
| `users` | email, displayName, photoUrl | User-owned | Email should be redacted before write; use Firebase Auth for email |
| `leaderboard_allTime` | displayName, photoUrl | Public (all auth) | Needs leaderboard opt-out mechanism |
| `community_feed` | userName, userAvatar | Public (all auth) | `isAnonymous` flag for display; PII still in data |
| `families` | members (contains UIDs) | Family members | Members list is private |
| `classification_feedback` | userId | User-owned | Only owner can read |

### Recommended Privacy Improvements

1. **Leaderboard opt-out**: Add `preferences.leaderboardOptOut` to `UserProfile`. Before writing to `leaderboard_allTime`, check this flag and anonymize/omit displayName and photoUrl.
2. **Community feed anonymization**: When `isAnonymous` is true, replace `userName` with "Anonymous User" and omit `userAvatar` before the Firestore write (not just in the UI layer).
3. **Email redaction**: Stop writing `email` to the `users` Firestore collection. It's available from Firebase Auth and doesn't need to be stored redundantly in Firestore.

---

*This document was regenerated from `lib/services/firestore_schema_registry.dart` on 2026-05-16.*
