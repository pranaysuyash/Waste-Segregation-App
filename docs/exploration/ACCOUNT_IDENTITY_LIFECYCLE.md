# Account / Identity Lifecycle

**Status**: Exploration — patterns and decisions documented  
**Date**: 2026-05-25  
**Why this matters**: The account lifecycle (anonymous → guest → email-verified → social-linked → premium → deleted) determines what data persists, what survives a reinstall, and what an attacker can do. Today these transitions are implicit.

---

## 1. Current State

**What exists:**
- `lib/screens/auth_screen.dart` — authentication screen
- Firebase Anonymous Auth → Email/Social linking flows
- `lib/services/firebase_cleanup_service.dart` — cleanup service
- `lib/services/fresh_start_service.dart` — fresh start/reset service
- `docs/planning/account_reset_and_delete_specification.md` — existing spec

**What's missing:**
- Explicit lifecycle state machine
- Anonymous-to-identified merge contract
- Account deletion cascade rules
- Multi-device semantics
- Grace period / recovery policy

---

## 2. Account Lifecycle State Machine

```
                    ┌──────────────┐
                    │  Unauthenticated │
                    │  (fresh install) │
                    └───────┬──────┘
                            │
                            ▼
                    ┌──────────────┐
             ┌──────│  Anonymous   │◄────────────┐
             │      │  (device UID) │              │
             │      └──────┬──────┘              │
             │             │                      │
             │             ▼                      │
             │      ┌──────────────┐              │
             │      │  Registered  │──────────────┘
             │      │  (email/Social)│  (logout → anonymous)
             │      └──────┬──────┘
             │             │
             │             ▼
             │      ┌──────────────┐
             │      │   Premium    │
             │      │  (subscription)│
             │      └──────┬──────┘
             │             │
             │             ▼
             │      ┌──────────────┐
             │      │  Deactivated │  (soft delete, grace period)
             │      │  (30-day)    │
             │      └──────┬──────┘
             │             │
             │             ▼
             │      ┌──────────────┐
             │      │   Deleted    │  (hard delete after grace)
             └──────│  (irreversible)│
                    └──────────────┘
```

---

## 3. Anonymous-to-Identified Merge Contract

### What Carries Over on Merge

| Data | Carries over? | Notes |
|---|---|---|
| Classification history | ✅ Yes | Full history with images, results, corrections |
| Gamification points | ✅ Yes | Points balance merges into registered account |
| Tokens (earned) | ✅ Yes | Token balance carries over |
| Streaks | ✅ Yes | Streak count preserved |
| Achievements/badges | ✅ Yes | All unlocked badges |
| Profile (avatar, name) | ✅ Yes | Anonymous profile replaced by registered profile |
| Community contributions | ✅ Yes | Posts, comments, contributions attributed to new identity |
| Family connections | ✅ Yes | Family group membership carries over |
| Social connections | 🟡 Partial | Re-scan contacts after registration to find friends |
| Premium subscription | ⚠️ Reconcile | Verify via StoreKit/Play Billing against new UID |
| Offline queue | ✅ Yes | Pending offline scans attached to new identity |

### Merge Implementation (Firebase)

```dart
// Firebase Auth: link anonymous to credential
final credential = EmailAuthProvider.credential(email: email, password: password);
await user.linkWithCredential(credential);

// Data merge: update Firestore documents to use the new UID
// - ClassificationHistory: update userId field
// - GamificationProfile: update userId field
// - Community contributions: update authorId field
// - Do NOT delete anonymous data until merge confirmed
```

### Conflict Handling

If the user tries to sign in with an email already associated with another account:
1. Check if the other account has data. If so, **prompt** user to choose which profile to keep
2. If user chooses "merge", the anonymous data is appended to the existing registered account
3. If user chooses "keep existing", anonymous data is discarded and existing account is used

---

## 4. Multi-Device Semantics

### Conflict Resolution: Last-Writer-Wins (Timestamps)

For an offline-capable app with <100k MAU, last-writer-wins (LWW) with timestamp-based conflict resolution is sufficient. CRDTs are unnecessary complexity at this scale.

| Data | Conflict resolution | Notes |
|---|---|---|
| Classification history | LWW (by createdAt) | Each classification is an independent document |
| Gamification points | Accumulative (set union) | Points earned are additive; no conflict |
| Streaks | Server-authoritative | Streak calculations run on the server from daily aggregates |
| Profile | LWW (by lastUpdated field) | Last save wins |
| Tokens | Server-authoritative | Token balance calculated from transaction log, never from client state |

### Multi-Device Flow

```
User logs in on Device B:
1. Device B syncs latest data from Firestore (pull)
2. Device B checks if it has local offline data
3. If local data exists and cloud data exists:
   - Prompt: "We found data on this device. Merge it with your cloud data?"
4. Merge operation appends new classifications, adds points, reconciles tokens
```

---

## 5. Account Deletion Contract

### Soft Delete → Grace Period → Hard Delete

| Phase | Duration | What happens | Reversible? |
|---|---|---|---|
| **Request** | Day 0 | User requests deletion via Settings → Delete Account | ✅ Yes (cancel request) |
| **Grace period** | Days 1–30 | Account deactivated, data not visible to others, user cannot log in but can cancel deletion | ✅ Yes (log in to cancel) |
| **Hard delete** | Day 31+ | All data permanently deleted from Firestore, Storage, Auth | ❌ No |

### Deletion Cascade

When account is hard-deleted, cascade affects:

| Data | Action | Timeline |
|---|---|---|
| Auth account (Firebase Auth) | Disabled immediately, hard delete after grace | 30 days |
| User profile (Firestore `users/{uid}`) | Deleted | Immediately after grace |
| Classification history (`classifications/{uid}/items/*`) | Batch delete | After grace |
| Classification images (Cloud Storage) | Batch delete | After grace (separate job to avoid timeout) |
| Gamification profile (`gamification/{uid}`) | Deleted | Immediately after grace |
| Token balance (`tokens/{uid}`) | Deleted | Immediately after grace |
| Community contributions | Anonymized (author set to `[deleted]`) | Immediately after grace |
| Family group membership | Removed from group | Immediately after grace |
| AI training data flagged as training candidate | **Anonymized** (remove userId, preserve feature data) | After grace |
| Analytics data | Already aggregated/anonymous | Not deleted (GDPR: pseudonymised data is OK) |
| Crashlytics data | Already aggregated | Not deleted |

### Subscription on Deletion

- Premium subscription remains active until end of current billing period (per Apple/Google policy)
- No automatic refund — redirect user to manage subscription in OS settings
- If user re-registers before subscription expiry, premium status restored

### UX Copy

```
"Your account will be deactivated immediately. Your data will be permanently deleted in 30 days. If you log in before then, deletion will be cancelled and your account restored.

The following will be deleted:
- Your classification history and photos
- Your points, tokens, and achievements
- Your community contributions (anonymized, not removed)
```

---

## 6. Grace Period & Recovery

### Recovery Flow

1. User opens app during grace period
2. App detects `deleted_at` field on user profile
3. Shows: "Your account is scheduled for deletion on [date]. Log in to cancel deletion."
4. User logs in → deletion cancelled → account restored (data still intact)
5. Analytics event: `account_deletion_cancelled`

### Cancellation Effects

- Deletion flag removed from Firestore documents
- Account reactivated (Auth account re-enabled)
- User can use app normally
- All data preserved (soft delete never touched data)

---

## 7. Account Data Portability

### Export Format

```json
{
  "exported_at": "2026-06-01T12:00:00Z",
  "user": {
    "created_at": "2026-01-15T08:30:00Z",
    "total_classifications": 342,
    "streak_days": 12,
    "total_points": 8500
  },
  "classifications": [
    {
      "id": "abc123",
      "image_url": "https://...",
      "result": "plastic_bottle_pet",
      "confidence": 0.94,
      "created_at": "2026-05-28T14:22:00Z",
      "was_corrected": false
    }
  ],
  "achievements": ["first_scan", "streak_7", "eco_warrior"],
  "community_contributions": [
    {
      "type": "post",
      "created_at": "2026-04-10T09:15:00Z",
      "content_preview": "Found this recycling center..."
    }
  ]
}
```

### Export Flow

1. User requests data export via Settings → Export My Data
2. Backend generates export JSON (Cloud Function)
3. Export stored in Cloud Storage as `exports/{uid}/export_{timestamp}.json`
4. Signed URL emailed to user (valid for 7 days)
5. Analytics event: `data_export_completed`

---

## 8. Open Questions

1. **Should anonymous users be able to export data before registering?** (Privacy: yes, technically feasible? Yes, export tied to anonymous UID.)
2. **How long should deleted-user data remain in analytics/crash reporting?** (GDPR: pseudonymised can be kept; policy: 90 days for crash data, 365 days for aggregated analytics.)
3. **Should we support account merging** (if user accidentally creates two accounts)? (Complex, high-risk; manual support process may be better at this stage.)
4. **Should anonymous-to-identified merge be automatic or require user confirmation?** (Automatic merge is lower friction; but user should be informed: "Your scan history and points will be saved to your new account.")

---

## 9. Related Docs

- `docs/exploration/CONSENT_ARCHITECTURE.md` — consent across account states
- `docs/exploration/DATA_RETENTION_AND_PII_STRATEGY.md` — data retention policies
- `docs/exploration/LAUNCH_AND_STORE_COMPLIANCE.md` — privacy compliance
- `docs/planning/account_reset_and_delete_specification.md` — existing spec
- `lib/services/firebase_cleanup_service.dart` — cleanup service
