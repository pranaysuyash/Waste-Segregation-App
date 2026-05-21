# Privacy & Data Retention Audit
**Date:** 2026-05-21  
**Auditor:** Claude Code (automated trace)  
**Scope:** waste_segregation_app — Flutter client + Firebase backend  
**Status:** Initial audit — findings unverified in production environment

---

## 1. Executive Summary

The app stores waste-item images **permanently on-device before any AI call is made**. Those image files are **never deleted** by the user-facing "Clear Data" or "Factory Reset" flows. Only `FirebaseCleanupService.clearAllDataForFreshInstall()` (a developer-mode path) deletes the Firebase Auth account; neither flow touches the `images/` or `thumbnails/` directories under the app documents folder.

Beyond the image-file gap, three additional risks stand out:

1. **Local device paths leak to Firestore.** `WasteClassification.toJson()` includes `imageUrl` (which holds the on-device absolute path or, in some flows, the Firebase Storage public URL) and `imageHash`. When Google Sync is enabled, the full classification JSON — including `imageUrl` / `imageRelativePath` / `thumbnailRelativePath` — is written to `users/{uid}/classifications` in Firestore.

2. **Firebase Storage images for batch jobs and contributions have no deletion path.** `batch_images/{userId}/` and `contribution_photos/{userId}/` buckets are written but never explicitly deleted by any user-triggered flow or Cloud Function.

3. **Admin ML-training collection (`admin_classifications`) is not cleared by the standard "Clear Data" / "Factory Reset" path** (`StorageService.clearAllUserData`). Only the developer-only `clearAllDataForFreshInstall` covers it. A regular user who taps "Factory Reset" in Settings has no way to remove their anonymized classifications from the ML training pipeline.

---

## 2. On-Device Storage Map

All paths are under `getApplicationDocumentsDirectory()` on iOS/Android.

| Directory | Content | Created by | Deleted by | Retention |
|---|---|---|---|---|
| `<appDocs>/images/` | Full-resolution waste images (UUID-named JPG/PNG/WebP) | `EnhancedImageService.saveFilePermanently` / `saveImagePermanently` | **Nothing in user-facing flows** | Indefinite |
| `<appDocs>/thumbnails/` | 256px JPEG thumbnails | `EnhancedImageService.saveThumbnail` | LRU eviction when >4,000 files or >100 MB; orphan cleanup in `StorageService.cleanUpOrphanedThumbnails` (manual trigger only) | LRU-capped; orphans only removed on explicit call |
| `<appDocs>/` (Hive boxes) | `classificationsBox`, `userBox`, `settingsBox`, `gamificationBox`, `cacheBox`, `classificationFeedbackBox`, `familiesBox`, `invitationsBox` | Hive via StorageService | `StorageService.clearAllUserData` (user-facing); `FirebaseCleanupService._resetLocalHive` (dev only) | Until factory reset or fresh-install |
| `SharedPreferences` | Consent flags, theme, analytics consent, `justDidFreshInstall` flag | Various services | `StorageService.clearAllUserData` → `prefs.clear()` | Until factory reset |
| `<tmpDir>/app_temp_images/` | Camera/gallery temp copies | Implicitly created by file pickers | `EnhancedImageService.cleanUpTempImages` (only cleans files older than 1 day; must be explicitly called) | Up to 1 day; not cleared on factory reset |

### Key finding — image save happens BEFORE analysis

At `ai_service.dart:751`, `ai_service.dart:927`, and `ai_service.dart:1104`:

```dart
// ai_service.dart:751 (analyzeImage)
final permanentPath = await _imageService.saveFilePermanently(imageFile);

// ai_service.dart:927 (analyzeWebImage)
savedImagePath = await _imageService.saveImagePermanently(imageBytes, fileName: imageName);

// ai_service.dart:1104 (analyzeImageRegion)
final permanentPath = await _imageService.saveFilePermanently(imageFile);
```

The image is committed to `<appDocs>/images/` **unconditionally**, even if the subsequent AI call fails, is cancelled, or returns a fallback classification. There is no cleanup on failure.

---

## 3. Cloud Storage Map

### 3a. Firestore Collections

| Collection | What is stored | Contains image data? | Deleted by user flow? |
|---|---|---|---|
| `users/{uid}` | UserProfile (displayName, photoUrl, gamificationProfile). Email is stripped before write by `_applyUserProfilePrivacyGuard` | No | `FirebaseCleanupService` only |
| `users/{uid}/classifications` | Full `WasteClassification.toJson()` including **`imageUrl`** (on-device absolute path or Firebase Storage URL), `imageHash`, `imageRelativePath`, `thumbnailRelativePath` | **Yes — device path leaks to cloud** | `CloudStorageService.clearCloudData()` — but this is **not called** by either user-facing clear flow; only by `FirebaseCleanupService` |
| `admin_classifications` | Anonymized classification data keyed by `${hashedUserId}_${classificationId}`. Fields: `itemName`, `category`, `subcategory`, `hashedUserId`, `mlTrainingData: true`. No direct PII. | No | `FirebaseCleanupService._wipeCloudAndFirestoreCache` only. **NOT cleared by user-facing factory reset.** |
| `admin_user_recovery` | `{lastBackup, classificationCount, appVersion}` keyed by `hashedUserId` | No | `FirebaseCleanupService` only |
| `leaderboard_allTime/{uid}` | `{userId, displayName, photoUrl, points, lastUpdated}`. Can be anonymized via opt-out setting. | No | `FirebaseCleanupService` only |
| `rate_limits` | Sliding-window counters keyed by `{bucket}:{subject}` (subject is user ID or IP). Stores `count`, `windowStartMs`. | No | Never deleted (window expiry is logical only) |
| `ai_jobs` | Batch job records including `imagePath` (Firebase Storage gs:// path) and `thumbnailPath` | **Yes — Firebase Storage path** | Never explicitly deleted |
| `classifications` (root) | Batch-processing results added by `addToClassificationHistory()` in Cloud Function (`functions/src/index.ts:980`). Contains `imagePath`, `thumbnailPath`, `userId`. | **Yes — Firebase Storage path** | Never explicitly deleted |
| `notifications` | Job-completion notifications containing embedded classification result objects. Contains `jobId`, `classification` object. | No image bytes, but classification metadata | Never explicitly deleted |
| `disposal_instructions` | Cached disposal data, no user content | No | N/A |
| `community_stats` | Aggregate counters only | No | Reset by `clearAllData` admin function |

### 3b. Firebase Storage Buckets

| Path | Content | Deleted by? |
|---|---|---|
| `batch_images/{userId}/batch_image_{timestamp}.jpg` | Full-resolution images uploaded for batch AI processing | **Never deleted** — no Storage deletion call exists anywhere in `lib/` or `functions/src/` |
| `contribution_photos/{userId}/contribution_{timestamp}_{i}.jpg` | User-submitted facility photos | **Never deleted** — `contribution_submission_screen.dart:849` uploads but no deletion code exists |

**Confirmed:** grepping for `storage.ref().delete()`, `ref.delete()`, `deleteObject` across both `lib/` and `functions/src/` returns zero results.

---

## 4. Third-Party Data Transmission

### OpenAI (primary AI provider)

- **What is sent:** Base64-encoded JPEG bytes (compressed, target quality 80) plus a system prompt and classification prompt containing the region (`defaultRegion = 'Bangalore, IN'`) and language.
- **No user ID is sent** in the API body. The image is sent as inline `data:image/jpeg;base64,…` in the `messages[].content` array.
- **When:** Debug and profile builds always; release builds only when `ALLOW_CLIENT_AI_IN_RELEASE=true` is set at build time (blocked by default via `ProductionSafetyConfig.guardClientAiCall`).
- **Reference:** `ai_service.dart:1231–1253` (`_analyzeWithOpenAI`)
- **OpenAI data retention:** Subject to OpenAI's API data usage policy (30-day default retention for abuse monitoring; zero data retention requires enterprise agreement). **The app has no mechanism to enforce zero-retention on OpenAI's side.**

### Google Gemini (fallback AI provider)

- **What is sent:** Base64-encoded JPEG bytes as `inline_data` in the Gemini `contents[].parts` array. Same system/classification prompts as OpenAI.
- **No user ID is sent.**
- **When:** Same build-mode guard as OpenAI. Triggered as fallback when OpenAI fails, returns an image-too-large error, or exceeds max retries.
- **Reference:** `ai_service.dart:1408–1421` (`_analyzeWithGemini`)
- **Google data retention:** Subject to Google's Gemini API terms. By default, Google may use API inputs for model improvement unless the user opts out or uses a paid tier with data processing terms.

### Firebase (Google) — Firestore, Storage, Auth, Crashlytics

- Firebase Auth stores UID, email, display name, photo URL, creation/last-sign-in timestamps.
- Firestore stores all collections described in Section 3a.
- Firebase Storage stores images described in Section 3b.
- Firebase Crashlytics receives crash reports including device platform info (`_getDeviceInfo()` returns `TargetPlatform.toString()_timestamp`) and Flutter error stack traces.
- **Analytics:** `AnalyticsService.trackEvent` saves `AnalyticsEvent` records to Firestore (when `_isFirestoreAvailable`). Each event includes `userId`, `deviceInfo`, `sessionId`, `appVersion`, `platform`, `parameters`. These records accumulate in Firestore with no TTL.

---

## 5. Retention Policy Reality

| Data | Stated policy | Actual behavior |
|---|---|---|
| On-device images (`images/`) | Permanent (by design) | Permanent — **no code path deletes these on user request** |
| On-device thumbnails (`thumbnails/`) | LRU-capped at 4000 files / 100 MB | LRU eviction runs on every `saveThumbnail` call; orphan cleanup requires explicit `cleanUpOrphanedThumbnails()` trigger |
| On-device classification records (Hive) | Until factory reset | Cleared by `StorageService.clearAllUserData` |
| Firestore `users/{uid}/classifications` | Until account deletion | `clearCloudData()` exists but is **not wired to any user-facing button** |
| Firestore `admin_classifications` | Indefinite (ML training) | Only cleared by admin or developer fresh-install flow |
| Firebase Storage `batch_images/` | Indefinite | **No deletion code exists anywhere** |
| Firebase Storage `contribution_photos/` | Indefinite | **No deletion code exists anywhere** |
| OpenAI API inputs | OpenAI's terms (30 days default) | App has no mechanism to enforce deletion |
| Gemini API inputs | Google's terms | App has no mechanism to enforce deletion |
| Analytics events (Firestore) | Indefinite | No TTL or purge mechanism |
| `rate_limits` (Firestore) | Logical window expiry only | Documents accumulate indefinitely |

---

## 6. User Deletion Capability

### What users can currently do

**Settings → "Clear Data" (`settings_screen.dart:903–943`)**  
Calls `StorageService.clearAllUserData()`.  
Clears: Hive boxes (classifications, user, settings, gamification, cache, feedback), SharedPreferences.  
Does NOT clear: on-device image files, Firestore cloud data, Firebase Storage blobs, admin_classifications.

**Settings → "Factory Reset" (`settings_screen.dart:1612–1665`)**  
Calls `StorageService.clearAllUserData()` plus `PremiumService.resetPremiumFeatures()`.  
Same scope as "Clear Data" — **same gaps apply**.

**Developer-only: `FirebaseCleanupService.clearAllDataForFreshInstall()` (`settings_screen.dart:2026`)**  
This is the most complete deletion path. It:
- Deletes Firestore docs from `admin_classifications`, `admin_user_recovery`, `users/{uid}`, `users/{uid}/classifications`, `leaderboard_allTime`, and other collections (via `_wipeCloudAndFirestoreCache`).
- Deletes all Hive boxes from disk.
- Clears SharedPreferences.
- Deletes the Firebase Auth account.
- Sets `justDidFreshInstall = true` in SharedPreferences to prevent re-sync.

**Still not covered even by the dev flow:**
- On-device image files (`<appDocs>/images/`) — NOT deleted.
- Firebase Storage `batch_images/{userId}/` — NOT deleted.
- Firebase Storage `contribution_photos/{userId}/` — NOT deleted.

### What `clearAllData` Cloud Function does

`functions/src/index.ts:596` — **Admin-only, requires `admin` custom claim AND `CLEAR_ALL_DATA_ENABLED=true` environment variable.** This deletes every root Firestore collection recursively. It is a full-database wipe, not a per-user deletion. Not accessible to end users.

---

## 7. GDPR / Privacy Gaps

| ID | Gap | Severity | File(s) |
|---|---|---|---|
| P1 | **Right to erasure not implemented for on-device images.** Images in `<appDocs>/images/` accumulate indefinitely. Factory reset and Clear Data do not delete them. | Critical | `lib/services/enhanced_image_service.dart`, `lib/services/storage_service.dart` |
| P2 | **Right to erasure not implemented for Firebase Storage images.** `batch_images/{userId}/` and `contribution_photos/{userId}/` are never deleted. | Critical | `lib/services/cloud_storage_service.dart`, `lib/screens/contribution_submission_screen.dart` |
| P3 | **Firestore cloud data not cleared by user-facing delete flows.** `CloudStorageService.clearCloudData()` exists but is not called from any user-accessible button. | Critical | `lib/screens/settings_screen.dart`, `lib/services/cloud_storage_service.dart:845` |
| P4 | **On-device absolute path (`imageUrl`) is synced to Firestore.** `WasteClassification.toJson()` includes `imageUrl` (the device path), which is then written to `users/{uid}/classifications`. This leaks device filesystem layout to the cloud. | High | `lib/models/waste_classification.dart:847`, `lib/services/cloud_storage_service.dart:368` |
| P5 | **Admin ML-training data (`admin_classifications`) not removable by end users.** The anonymized data uses a SHA-256 hash of `userId + salt`, which is reversible if the salt is known. Salt is hardcoded in source code (`'waste_segregation_app_salt_2024'` at `cloud_storage_service.dart:467`). | High | `lib/services/cloud_storage_service.dart:465–469` |
| P6 | **No user-facing data deletion for Firestore cloud data exists in production.** "Factory Reset" in Settings does not call `clearCloudData()` or `FirebaseCleanupService`. The complete deletion path is only accessible via the developer menu. | High | `lib/screens/settings_screen.dart:1645–1660` |
| P7 | **No retention policy for analytics events in Firestore.** `AnalyticsEvent` records accumulate with no TTL or scheduled purge. | Medium | `lib/services/analytics_service.dart:170–176` |
| P8 | **Third-party AI providers receive image data without explicit per-session consent.** The consent dialog (`consent_dialog_screen.dart`) and `UserConsentService` track analytics and data-processing consent, but there is no specific consent toggle for image transmission to OpenAI/Gemini. | Medium | `lib/services/user_consent_service.dart`, `lib/services/ai_service.dart` |
| P9 | **Hardcoded salt for user ID hashing reduces anonymization strength.** The salt `'waste_segregation_app_salt_2024'` is in plain source code, making the hash reversible for anyone with the APK. | Medium | `lib/services/cloud_storage_service.dart:467` |
| P10 | **`rate_limits` documents accumulate indefinitely.** These documents contain the user ID (or a sanitized version) as the document key and never expire. | Low | `functions/src/index.ts:158` |
| P11 | **Temp image files not purged on factory reset.** `<tmpDir>/app_temp_images/` cleanup requires explicit call to `EnhancedImageService.cleanUpTempImages()`. | Low | `lib/services/enhanced_image_service.dart:382` |

---

## 8. Recommended Fixes

### Fix P1 — Add `deleteAllImages()` to `EnhancedImageService` and call it on reset

**File:** `lib/services/enhanced_image_service.dart`

Add a method:

```dart
Future<void> deleteAllImages() async {
  if (kIsWeb) return;
  final dir = await getApplicationDocumentsDirectory();
  for (final subDir in [_imagesDirName, _thumbnailsDirName]) {
    final d = Directory(p.join(dir.path, subDir));
    if (await d.exists()) {
      await d.delete(recursive: true);
    }
  }
}
```

**File:** `lib/services/storage_service.dart` — inside `clearAllUserData()`:

```dart
final imageService = EnhancedImageService();
await imageService.deleteAllImages();
await imageService.cleanUpTempImages(olderThan: Duration.zero);
```

---

### Fix P2 — Delete Firebase Storage images when user data is cleared

**File:** `lib/services/cloud_storage_service.dart` — extend `clearCloudData()`:

```dart
Future<void> _deleteUserStorageFiles(String userId) async {
  final storage = FirebaseStorage.instance;
  for (final prefix in ['batch_images/$userId/', 'contribution_photos/$userId/']) {
    final ref = storage.ref().child(prefix);
    try {
      final listResult = await ref.listAll();
      for (final item in listResult.items) {
        await item.delete();
      }
    } catch (e) {
      WasteAppLogger.warning('Failed to delete storage files at $prefix', error: e);
    }
  }
}
```

Call `await _deleteUserStorageFiles(userProfile.id);` at the top of `clearCloudData()`.

---

### Fix P3 — Wire `clearCloudData()` into the user-facing factory reset

**File:** `lib/screens/settings_screen.dart` — in both "Clear Data" (line ~917) and "Factory Reset" (line ~1645) handlers:

```dart
// After storageService.clearAllUserData():
final cloudService = Provider.of<CloudStorageService>(context, listen: false);
await cloudService.clearCloudData();
```

This will delete `users/{uid}/classifications` in Firestore. Also add an `admin_classifications` deletion step (see Fix P5).

---

### Fix P4 — Strip device path from Firestore writes

**File:** `lib/services/cloud_storage_service.dart` — in `_syncClassificationToCloud()` and `updateClassificationInCloud()`, strip local path fields before writing:

```dart
final cloudData = {
  ...cloudClassification.toJson(),
  'imageUrl': null,           // Never store device path in cloud
  'imageRelativePath': null,  // Strip local relative path
  'thumbnailRelativePath': null,
  'syncedAt': FieldValue.serverTimestamp(),
};
```

---

### Fix P5 — Add user-facing deletion of `admin_classifications` records

**File:** `lib/services/cloud_storage_service.dart` — add to `clearCloudData()`:

```dart
// Delete from admin_classifications (keyed by hashedUserId prefix)
final hashedUid = _hashUserId(userProfile.id);
// Query by hashed prefix — note: requires a Firestore composite query or full scan
// Recommended: store hashedUserId as a field and add where('hashedUserId', isEqualTo: hashedUid)
final adminDocs = await _firestore
    .collection(FirestoreCollections.adminClassifications)
    .where('hashedUserId', isEqualTo: hashedUid)
    .get();
for (final doc in adminDocs.docs) {
  batch.delete(doc.reference);
}
```

This requires adding a `hashedUserId` field index in Firestore (it is already stored as a field at `cloud_storage_service.dart:419`).

Also: move the salt to Firebase Remote Config or Secret Manager so it is not hardcoded in source. The current hardcoded salt (`cloud_storage_service.dart:467`) makes the SHA-256 hash reversible for anyone who decompiles the APK.

---

### Fix P6 — Add a proper user-facing "Delete My Account & Data" flow

**New screen or dialog** — implement a complete erasure flow:

1. Delete Firebase Storage files (Fix P2).
2. Delete Firestore `users/{uid}` and subcollections (existing `clearCloudData()`).
3. Delete `admin_classifications` for this user (Fix P5).
4. Clear local image files (Fix P1).
5. Clear Hive boxes.
6. Sign out + delete Firebase Auth account.

This is what GDPR Article 17 requires. Currently, users have no path to accomplish this without developer mode.

---

### Fix P7 — Add TTL to analytics events in Firestore

**File:** `lib/services/analytics_service.dart` and/or Cloud Functions.

Add a `expiresAt` field when writing analytics events:

```dart
await _firestore.collection('analytics_events').add({
  ...event.toJson(),
  'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(days: 90))),
});
```

Set up a Firestore TTL policy on `analytics_events.expiresAt` via the Firebase console (Firestore TTL auto-deletes expired documents).

---

### Fix P8 — Add explicit AI image-transmission consent

**File:** `lib/services/user_consent_service.dart` — add a `aiImageTransmissionConsent` key.

**File:** `lib/screens/consent_dialog_screen.dart` — add a checkbox:

> "I consent to my images being sent to Google Gemini / OpenAI for waste classification. Images are not stored by the app after classification."

Make this a prerequisite before the first `AiService.analyzeImage()` call. This also requires updating the privacy policy to accurately describe the AI providers used.

---

### Fix P9 — Move user ID salt to Secret Manager

**File:** `lib/services/cloud_storage_service.dart:467`

Replace the hardcoded salt with a value fetched from Firebase Remote Config (acceptable for non-critical data) or, for better security, move hashing server-side to a Cloud Function where the salt can be stored in Google Secret Manager.

---

### Fix P10 — Add TTL to `rate_limits` documents

**File:** `functions/src/index.ts` — in `enforceRateLimit`, add a Firestore TTL field:

```typescript
tx.set(docRef, {
  count: nextCount,
  windowStartMs: nextWindowStartMs,
  expiresAt: admin.firestore.Timestamp.fromMillis(nowMs + windowDurationMs * 2),
});
```

Enable Firestore TTL policy on `rate_limits.expiresAt`.

---

## Appendix: Confirmed File References

| Finding | File | Lines |
|---|---|---|
| `saveFilePermanently` called before AI | `lib/services/ai_service.dart` | 751, 927, 1104 |
| `saveImagePermanently` implementation (permanent, no TTL) | `lib/services/enhanced_image_service.dart` | 31–62 |
| `clearAllUserData` — no image file deletion | `lib/services/storage_service.dart` | 954–1000 |
| `imageUrl` / `imageRelativePath` in Firestore JSON | `lib/models/waste_classification.dart` | 847, 885–886 |
| Firebase Storage upload, no corresponding delete | `lib/services/cloud_storage_service.dart` | 951–1001 |
| Contribution photo upload, no corresponding delete | `lib/screens/contribution_submission_screen.dart` | 843–895 |
| `clearCloudData()` not called from user-facing reset | `lib/screens/settings_screen.dart` | 922, 1653 |
| `admin_classifications` ML data collection | `lib/services/cloud_storage_service.dart` | 396–442 |
| Hardcoded hash salt | `lib/services/cloud_storage_service.dart` | 467 |
| `clearAllDataForFreshInstall` (developer only) | `lib/services/firebase_cleanup_service.dart` | 71–108 |
| `clearAllData` Cloud Function (admin + kill-switch only) | `functions/src/index.ts` | 596–681 |
| `ai_jobs` stores `imagePath` / `thumbnailPath` | `functions/src/index.ts` | 973–974 |
| Root `classifications` collection stores `imagePath` | `functions/src/index.ts` | 967–981 |
| AI transmission to OpenAI (base64 inline, no user ID) | `lib/services/ai_service.dart` | 1231–1253 |
| AI transmission to Gemini (inline_data, no user ID) | `lib/services/ai_service.dart` | 1408–1421 |
| `ProductionSafetyConfig` guards AI in release builds | `lib/utils/production_safety_config.dart` | 20–23 |
