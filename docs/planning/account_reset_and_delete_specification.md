## Reset & Delete Account Flow Specification

This document specifies three related flows for our waste-identification Flutter app:

1. **Reset Account**: Archive & delete all user data, but keep their Firebase Auth credential so they can sign back in.
2. **Delete Account**: Archive & delete all user data, then delete their Firebase Auth account to prevent future sign-ins.
3. **Inactive Account Auto-Deletion**: Automatically archive & delete any account inactive for over 6 months via a scheduled backend job.

> **All data**, including both user-scoped and global collections, must first be archived to our **admin database** before any deletion occurs.

---

### 1. Common Principles

* **Archive before delete**: Copy all profile, subcollections, and global collections into `archived_*` collections in the **admin DB**, with PII stripped.
* **Anonymization**: Remove `email`, `displayName`, and `photoURL` from user profiles; add `anonId` (UUID v5 of UID) and `archivedAt` timestamp.
* **Batched operations**: Use Firestore batch writes/deletes to handle large datasets.
* **Guard rails**: Only run these flows in `kDebugMode` or when a feature-flag (`enable_account_cleanup`) is enabled via Remote Config.

---

### 2. Archive Targets

| Source Collection              | Archive Destination (Admin DB)                  |
| ------------------------------ | ----------------------------------------------- |
| `users/{uid}`                  | `admin_archived_users/{uid}`                    |
| `users/{uid}/classifications`  | `admin_archived_classifications/{uid}/{docId}`  |
| `users/{uid}/achievements`     | `admin_archived_achievements/{uid}/{docId}`     |
| `users/{uid}/settings`         | `admin_archived_settings/{uid}/{docId}`         |
| `users/{uid}/analytics`        | `admin_archived_analytics/{uid}/{docId}`        |
| `users/{uid}/content_progress` | `admin_archived_content_progress/{uid}/{docId}` |
| **Global Collections**         | **Archive then delete**                         |
| `community_feed`               | `admin_archived_community_feed/{docId}`         |
| `community_stats`              | `admin_archived_community_stats/{docId}`        |
| `families`                     | `admin_archived_families/{docId}`               |
| `invitations`                  | `admin_archived_invitations/{docId}`            |
| `shared_classifications`       | `admin_archived_shared_classifications/{docId}` |
| `analytics_events`             | `admin_archived_analytics_events/{docId}`       |
| `family_stats`                 | `admin_archived_family_stats/{docId}`           |
| `disposal_locations`           | `admin_archived_disposal_locations/{docId}`     |
| `recycling_facilities`         | `admin_archived_recycling_facilities/{docId}`   |
| `facility_reviews`             | `admin_archived_facility_reviews/{docId}`       |
| `content_library`              | `admin_archived_content_library/{docId}`        |
| `daily_challenges`             | `admin_archived_daily_challenges/{docId}`       |
| `user_achievements`            | `admin_archived_user_achievements/{docId}`      |
| `badges`                       | `admin_archived_badges/{docId}`                 |
| `leaderboard_allTime`          | `admin_archived_leaderboard_allTime/{docId}`    |
| `leaderboard_weekly`           | `admin_archived_leaderboard_weekly/{docId}`     |
| `leaderboard_monthly`          | `admin_archived_leaderboard_monthly/{docId}`    |

---

### 3. Reset Account Flow

#### 3.1 Archive Phase

1. `_archiveUserProfile(uid, adminDB)`
2. Loop `_archiveSubcollection(uid, subName, adminDB)` for each user-scoped subcollection.
3. Loop `_archiveGlobalCollection(collectionName, adminDB)` for each global collection.

#### 3.2 Deletion Phase

* `_clearCurrentUserData(uid)` deletes `users/{uid}` and user subcollections in main DB.
* `_deleteGlobalCollection(collectionName)` deletes every document in each global collection in main DB.

#### 3.3 Local Storage Cleanup

* Clear all Hive boxes listed in `_hiveBoxesToClear` and any additional boxes.
* Revoke FCM tokens: `FirebaseMessaging.instance.deleteToken()`.

#### 3.4 Community Stats Reset

* After global deletion, delete then recreate `community_stats/main` in main DB (if desired) or leave blank.

#### 3.5 Sign-Out

* `FirebaseAuth.instance.signOut()`

---

### 4. Delete Account Flow

#### 4.1 Archive Phase

* Same as **3.1** (archive both user and global to admin DB).

#### 4.2 Deletion Phase

* Perform **3.2** then call `FirebaseAuth.instance.currentUser?.delete()` to remove the Auth record.

#### 4.3 Local Storage Cleanup

* Same as **3.3**.

---

### 5. Inactive Account Auto-Deletion

#### 5.1 Firestore Schema Update

* Ensure `lastActiveAt: Timestamp` exists in each `users/{uid}`, updated on each sign-in or key action.

#### 5.2 Scheduled Cleanup Function

* Cron: `0 3 * * *` UTC. Run daily.

#### 5.3 Cleanup Logic

1. Compute `cutoff = now - 6 months`.
2. Query `users` < cutoff.
3. For each stale user:

   * Archive profile, subcollections, and global collections to admin DB.
   * Delete user data and subcollections (main DB).
   * Delete Auth record.
   * Append `cleanup_logs` in admin DB.

#### 5.4 Testing Checklist for Inactive Deletion

* [ ] Seed test users with `lastActiveAt` older than 6 months.
* [ ] Trigger the scheduled cleanup function (via emulator or dashboard).
* [ ] Confirm `admin_archived_users/{uid}` exists for each stale user.
* [ ] Confirm `admin_archived_{subcollection}` entries exist for each user's subcollections.
* [ ] Confirm `admin_archived_{globalCollection}` entries exist for all global collections.
* [ ] Verify original `users/{uid}` document and subcollections are deleted from main DB.
* [ ] Verify main DB global collections no longer contain deleted docs.
* [ ] Verify Firebase Auth entries are removed for each stale user.
* [ ] Verify `cleanup_logs` entries in admin DB include correct `userId`, `deletedAt`, and `reason`.

---

### 6. Implementation Notes

* **Admin DB connection**: Initialize a second Firestore instance for the admin project in your service.
* **Production Guards**: Use Remote Config or build flavors to enable/disable flows.
* **Error Handling**: Log errors to `admin_cleanup_errors` in admin DB, with retry metadata.
* **Idempotency**: Use `set()` with doc IDs in admin DB to avoid duplicates.
* **TTL Policies**: Configure TTL on admin DB archive collections.
* **Security Rules**: Restrict admin DB writes to service account only.
* **Batching & Backoff**: Process 500-doc batches with exponential backoff on retries.

---

### 7. Testing Checklist (Consolidated)

#### Reset Account

* [ ] Archive to admin DB for:

  * `admin_archived_users/{uid}`
  * `admin_archived_classifications/{uid}/*`
  * `admin_archived_achievements/{uid}/*`
  * `admin_archiv_settings/{uid}/*`
  * `admin_archived_analytics/{uid}/*`
  * `admin_archived_content_progress/{uid}/*`
* [ ] Archive global collections to admin DB:

  * `admin_archived_community_feed/*`, etc.
* [ ] Verify main DB `users/{uid}` and subcollections are deleted.
* [ ] Verify main DB global collections are empty.
* [ ] Verify Hive boxes cleared and FCM token revoked.
* [ ] Verify user can sign back in successfully.

#### Delete Account

* [ ] Repeat all **Reset Account** checks.
* [ ] After reset, call `FirebaseAuth.instance.currentUser?.delete()`.
* [ ] Verify Firebase Auth record is deleted and sign-in is prevented.

#### Inactive Auto-Deletion

* [ ] All **Delete Account** checks pass for each stale user.
* [ ] Confirm `cleanup_logs` entries exist for each.

---

### 8. Additional Considerations

* **Global Collections Audit**: Regularly review new collections to include in archive.
* **Hive Centralization**: Manage box names in a single util file.
* **Push Notifications**: Unsubscribe topics.
* **UI/UX**: Progress indicators, confirmations, summaries.
* **Team Training & Docs**: Update README and training materials.

---

*Spec updated: now archives all data to the admin DB before any deletion.* 