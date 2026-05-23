# Data Retention & PII Strategy

**Date**: 2026-05-23
**Status**: Exploration — retention policy framework
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md) entry 14
**Decision this unblocks**: Sustainable data lifecycle, cost management at scale, regulatory compliance
**Kill criteria**: If the app never exceeds 10K MAU, retention complexity isn't justified — simple delete-on-request suffices.

---

## 1. Data Categories

| Category | Storage | Current Retention | Recommended Retention | Deletion Path |
|----------|---------|-------------------|----------------------|---------------|
| User profile | Firestore `users/{userId}` | Until account delete | Until account delete | `performCleanup()` |
| Classification history | Firestore `users/{userId}/classifications` | Until account delete | 12 months active, archive thereafter | TTL + archive |
| On-device images | Local `<appDocs>/images/` | Indefinite (broken) | 90 days or user delete | Auto-purge timer |
| Batch images | Firebase Storage `batch_images/` | Indefinite (broken) | 30 days after processing | Cloud Function cron |
| Contribution photos | Firebase Storage `contribution_photos/` | Indefinite (broken) | Until contribution resolved + 90 days | After moderation |
| Analytics events | Firestore `analytics_events` | Indefinite (broken) | 14 months | TTL policy |
| Training candidates | Firestore `training_candidates` | Until account delete | Until revoked + 30 days grace | Consent withdrawal |
| Rate limit documents | Firestore `rate_limits/{userId}` | Indefinite | 24 hours (rolling) | Auto-expire |
| Leaderboard entries | Firestore `leaderboard_allTime` | Until account delete | Until account delete | `performCleanup()` |
| Community feed | Firestore `community_feed` | Until account delete | 90 days | TTL policy |
| Offline queue | Hive local | Until processed + 30 days | 7 days unprocessed | Auto-purge |

---

## 2. Retention Policies

### Tier 1: Active data (hot)

Retention: Available immediately, no degradation.

- User profile
- Current month's classifications
- Token wallet and transactions
- Active streaks and gamification state

### Tier 2: Historical data (warm)

Retention: Available on request, paginated access.

- Classifications older than 3 months
- Past achievements
- Historical analytics (aggregated)

### Tier 3: Archived data (cold)

Retention: Stored but not surfaced in UI. Accessible via export.

- Classifications older than 12 months
- Expired community feed posts
- Aggregated analytics summaries

### Tier 4: Deleted

- Removed from all storage layers
- Backup retention: 30 days (for accidental deletion recovery)
- Training data: removed from all dataset versions within 30 days of consent withdrawal

---

## 3. Implementation

### Firestore TTL

```javascript
// Firebase Functions - scheduled cleanup
exports.scheduledCleanup = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async (context) => {
    const cutoff = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() - 14 * 30 * 24 * 60 * 60 * 1000) // 14 months
    );

    const snapshot = await admin.firestore()
      .collection('analytics_events')
      .where('timestamp', '<', cutoff)
      .get();

    const batch = admin.firestore().batch();
    snapshot.docs.forEach(doc => batch.delete(doc.ref));
    await batch.commit();
  });
```

### Local image auto-purge

```dart
// In StorageService
Future<void> purgeOldImages() async {
  final imagesDir = Directory('${appDocDir}/images');
  if (!imagesDir.existsSync()) return;

  final cutoff = DateTime.now().subtract(Duration(days: 90));
  for (final entity in imagesDir.listSync()) {
    if (entity is File) {
      final stat = await entity.stat();
      if (stat.modified.isBefore(cutoff)) {
        await entity.delete();
      }
    }
  }
}
```

---

## 4. PII Inventory

| PII Type | Where Stored | Purpose | Retention | Consent |
|----------|-------------|---------|-----------|---------|
| Email | `users/{userId}.email` | Auth, notifications | Account lifetime | Auth consent |
| Display name | `users/{userId}.displayName` | Community, leaderboard | Account lifetime | Profile consent |
| Device path | `classifications.imageUrl` | Local image reference | Classification lifetime | Implicit |
| Location | `classifications.region` | Disposal policy | Classification lifetime | Location consent |
| Photo | Firebase Storage, local | Classification | Per image policy | AI transmission consent |
| Usage patterns | `analytics_events` | Product improvement | 14 months | Analytics consent |
| Training data | `training_candidates` | ML improvement | Until revoked | Explicit training consent |

---

## 5. Related

- [Privacy / Photo PII](PRIVACY_PHOTO_PII.md) — PII protection mechanisms
- [Consent Architecture](../EXPLORATION_TOPICS.md#a19-consent-architecture-) — consent model
- `docs/legal/` — legal framework documents
- `docs/security/` — security documentation
