# Firestore Access Control Matrix

> **Purpose:** Canonical reference for every Firestore collection's security posture.
> Used by emulator tests (SEC-07) and as the source of truth for `firestore.rules`.
>
> **Last Updated:** 2026-08-02

## Legend

- **Sensitivity:** Public / Internal / Confidential / Restricted
- **Retention:** Permanent / Long-term / Session / Transient
- **RW** = Read + Write, **R** = Read-only, **W** = Write-only, **—** = No access

---

## User-Scoped Collections

| Collection | Sensitivity | Readers | Creators | Updaters | Server-Only Fields | Retention | Test IDs |
|---|---|---|---|---|---|---|---|
| `users/{uid}` | **Restricted** | Owner only | Owner (profile) | Owner (profile) + Server (billing, tokens, admin) | `billing`, `billing.entitlements`, `subscriptionTier`, `tokenWallet.*`, `bonusScans`, `admin`, `roles`, `lastPremiumGrantAt`, `lastPremiumRevokedAt`, `auditTimestamps`, `updatedBy` | Permanent | SEC-T2-01 to SEC-T2-06 |
| `users/{uid}/classifications/{id}` | Confidential | Owner | Owner | Owner | — | Long-term | SEC-T7-04 |
| `users/{uid}/classification_hashes/{id}` | Internal | Owner | Owner | Owner | — | Long-term | — |
| `users/{uid}/points/current` | Internal | — (subcollection) | Server only | Server only | `total`, `level`, `weeklyTotal`, `monthlyTotal` | Long-term | — |

## Token & Billing Collections

| Collection | Sensitivity | Readers | Creators | Updaters | Server-Only Fields | Retention | Test IDs |
|---|---|---|---|---|---|---|---|
| `subscriptions/{subId}` | **Restricted** | Owner (by `userId` field) | Server (webhook) | Server (webhook) | All fields — no client write | Permanent | SEC-T7-09, SEC-T7-10 |
| `webhook_events/{eventId}` | **Restricted** | — (no client access) | Server (webhook) | Server (webhook) | All fields | Long-term | — |
| `billing_events/{eventId}` | **Restricted** | — (no client access) | Server (webhook) | Server (webhook) | All fields | Long-term | C-09/C-10: atomic idempotency gate keyed on provider transaction ID (`event.data.id`) |
| `token_spend_ledger/{txId}` | **Restricted** | — (no client access) | Server (spendUserTokens) | — | All fields | Permanent | — |

## AI & Batch Processing

| Collection | Sensitivity | Readers | Creators | Updaters | Server-Only Fields | Retention | Test IDs |
|---|---|---|---|---|---|---|---|
| `ai_jobs/{jobId}` | Confidential | Owner (by `userId`) | Owner | Owner (status) | `result`, `openaiBatchId` | Long-term | — |

## Leaderboard Collections

| Collection | Sensitivity | Readers | Creators | Updaters | Server-Only Fields | Retention | Test IDs |
|---|---|---|---|---|---|---|---|
| `leaderboard_allTime/{uid}` | Internal | All authenticated | Owner | Owner (self) | — | Long-term | SEC-T7-08 |
| `leaderboard_weekly/{weekId}` | Internal | All authenticated | Owner | Owner (self) | — | Session | — |

## Community Collections

| Collection | Sensitivity | Readers | Creators | Updaters | Server-Only Fields | Retention | Test IDs |
|---|---|---|---|---|---|---|---|
| `community_feed/{postId}` | Internal | All authenticated | Owner | Owner | — | Long-term | — |
| `community_stats/{id}` | Public | All authenticated | — (server) | — (server) | All fields | Permanent | — |
| `community_challenges/{id}` | Public | All authenticated | — (server) | — (server) | All fields | Long-term | — |
| `community_reports/{id}` | **Restricted** | Admin | Owner (create) | Admin (review) | `status`, `adminReviewerId` | Long-term | — |

## Family Collections

| Collection | Sensitivity | Readers | Creators | Updaters | Server-Only Fields | Retention | Test IDs |
|---|---|---|---|---|---|---|---|
| `families/{familyId}` | Confidential | Members + owner | Owner (create) | Owner/admin (role-gated) | — | Permanent | SEC-T3-01 to SEC-T3-05 |
| `invitations/{invitationId}` | **Restricted** | Inviter + invited email + admin | Inviter | Inviter + invited (by email) | `respondedAt` | Transient | SEC-T3-06 to SEC-T3-08 |
| `families/{familyId}/shared_classifications/{id}` | Confidential | **Family members only** (C-07: moved to subcollection so membership is enforced by rules) | Family member | Family members (reactions/comments only) | — | Long-term | SEC-T3-09 to SEC-T3-11 |
| `family_stats/{familyId}` | Internal | Per visibility setting | Family member | Family member | — | Long-term | — |

## Classification Feedback

| Collection | Sensitivity | Readers | Creators | Updaters | Server-Only Fields | Retention | Test IDs |
|---|---|---|---|---|---|---|---|
| `classification_feedback/{id}` | Internal | Owner | Owner | Owner | `adminReviewerId`, `adminReviewTimestamp`, `adminNotes` | Long-term | — |

## Training Data (Admin-Only)

| Collection | Sensitivity | Readers | Creators | Updaters | Server-Only Fields | Retention | Test IDs |
|---|---|---|---|---|---|---|---|
| `training_candidates/{id}` | **Restricted** | Admin | — (server) | — (server) | All fields | Permanent | SEC-T7-11 |
| `training_labels/{id}` | **Restricted** | Admin | — (server) | — (server) | All fields | Permanent | SEC-T7-12 |
| `training_dataset_versions/{id}` | **Restricted** | Admin | — (server) | — (server) | All fields | Permanent | — |
| `training_review_audit/{id}` | **Restricted** | Admin | — (server) | — (server) | All fields | Permanent | — |

## Reference Data

| Collection | Sensitivity | Readers | Creators | Updaters | Server-Only Fields | Retention | Test IDs |
|---|---|---|---|---|---|---|---|
| `disposal_instructions/{id}` | Public | All authenticated | — (server) | — (server) | All fields | Long-term | — |
| `disposal_locations/{id}` | Public | All authenticated | — (server) | — (server) | All fields | Long-term | — |

## User Contributions

| Collection | Sensitivity | Readers | Creators | Updaters | Server-Only Fields | Retention | Test IDs |
|---|---|---|---|---|---|---|---|
| `user_contributions/{id}` | Internal | Owner + public (approved) | Owner | Owner | `status` (approved by admin) | Long-term | — |

## Analytics

| Collection | Sensitivity | Readers | Creators | Updaters | Server-Only Fields | Retention | Test IDs |
|---|---|---|---|---|---|---|---|
| `analytics_events/{id}` | Confidential | — (server only) | Any authenticated | — (server only) | All fields except metadata | Session | — |

## Admin Collections

| Collection | Sensitivity | Readers | Creators | Updaters | Server-Only Fields | Retention | Test IDs |
|---|---|---|---|---|---|---|---|
| `admin/**` | **Restricted** | — (no client access) | — | — | All fields | Permanent | SEC-T7-11 |
| `admin_classifications/**` | **Restricted** | — (no client access) | — | — | All fields | Permanent | — |
| `admin_user_recovery/**` | **Restricted** | — (no client access) | — | — | All fields | Permanent | — |

## Gamification

| Collection | Sensitivity | Readers | Creators | Updaters | Server-Only Fields | Retention | Test IDs |
|---|---|---|---|---|---|---|---|
| `gamification/{uid}` | Internal | Owner | Owner | Owner (anti-cheat bounded) | — | Long-term | SEC-T7-08 |

## Referrals

| Collection | Sensitivity | Readers | Creators | Updaters | Server-Only Fields | Retention | Test IDs |
|---|---|---|---|---|---|---|---|
| `referral_codes/{uid}` | Confidential | Owner | — (server) | — (server) | All fields | Permanent | SEC-T7-13 to SEC-T7-16 |
| `referral_redemptions/{id}` | Confidential | Owner (by `redeemedByUid`) | — (server) | — (server) | All fields | Permanent | SEC-T7-13 to SEC-T7-16 |

---

## Server-Owned Field Catalog

The following fields MUST NEVER be writable by client SDKs. Only Cloud Functions (admin SDK) may modify them:

```
users/{uid}:
  billing                    — payment state
  billing.entitlements       — feature access flags
  subscriptionTier           — plan level
  tokenWallet.*              — token balance and ledger
  bonusScans                 — promotional scan credits
  admin                      — admin claim flag
  roles                      — role assignments
  lastPremiumGrantAt         — audit timestamp
  lastPremiumRevokedAt       — audit timestamp
  auditTimestamps            — audit trail
  updatedBy                  — last modifier identity
  trainingConsent            — server-validated consent state

subscriptions/{id}:
  (entire document — server-managed)

webhook_events/{id}:
  (entire document — server-managed)

token_spend_ledger/{id}:
  (entire document — server-managed)

referral_codes/{uid}:
  (entire document — server-managed)

referral_redemptions/{id}:
  (entire document — server-managed)
```

## Client-Writable Fields (User Document)

```
users/{uid} — client may write ONLY:
  displayName                — profile
  photoUrl                   — profile
  preferences                — user settings
  gamificationProfile.*      — anti-cheat bounded
  tokenTransactions          — append-only, bounded
  trainingConsent.*          — explicit consent toggles
  lastActive                 — timestamp refresh
```

---

## Emulator Test Coverage Map

| Test ID | Finding | Collection | What It Proves |
|---|---|---|---|
| SEC-T2-01 | SEC-01 | users | Client cannot write `billing` field |
| SEC-T2-02 | SEC-01 | users | Client cannot write `billing.entitlements` |
| SEC-T2-03 | SEC-01 | users | Client cannot write `subscriptionTier` |
| SEC-T2-04 | SEC-01 | users | Client cannot credit `tokenWallet.balance` directly |
| SEC-T2-05 | SEC-01 | users | Client cannot set `admin` flag |
| SEC-T2-06 | SEC-01 | users | Client cannot write `bonusScans` |
| SEC-T3-01 | SEC-02 | families | Non-member cannot read family |
| SEC-T3-02 | SEC-02 | families | Non-owner/admin cannot update family |
| SEC-T3-03 | SEC-02 | invitations | Non-invited cannot read invitation |
| SEC-T3-04 | SEC-02 | invitations | Non-inviter cannot create invitation |
| SEC-T3-05 | SEC-02 | families | Family update restricted to owner/admin (role-gated) |
| SEC-T3-06 | SEC-02 | invitations | Non-inviter cannot create invitation |
| SEC-T3-09 | SEC-02 | families/{familyId}/shared_classifications | Create requires familyId matching parent family |
| SEC-T3-09b | SEC-02 | families/{familyId}/shared_classifications | Non-member cannot create shared classification |
| SEC-T3-10 | SEC-02 | families/{familyId}/shared_classifications | Family member can read shared classification |
| SEC-T3-11 | SEC-02 | families/{familyId}/shared_classifications | Non-member cannot read shared classification |
| SEC-T3-07 | SEC-02 | family_stats | Non-public: non-member cannot read |
| SEC-T3-08 | SEC-02 | family_stats | Public: any auth user can read |
| SEC-T7-01 | SEC-03 | leaderboard_allTime | User cannot write another user's leaderboard entry |
| SEC-T7-02 | SEC-03 | leaderboard_allTime | Points exceed maximum bound |
| SEC-T7-03 | SEC-03 | gamification | User cannot inflate points beyond anti-cheat bounds |
| SEC-T7-04 | — | users/classifications | Owner can CRUD own classifications |
| SEC-T7-05 | — | users/classifications | Non-owner cannot read another's classifications |
| SEC-T7-06 | SEC-04 | subscriptions | Owner can read own subscription |
| SEC-T7-07 | SEC-04 | subscriptions | Non-owner cannot read subscription |
| SEC-T7-08 | SEC-03 | gamification | Client cannot write server-only gamification fields |
| SEC-T7-09 | SEC-04 | subscriptions | Client cannot create subscription document |
| SEC-T7-10 | SEC-04 | subscriptions | Client cannot update subscription document |
| SEC-T7-11 | — | training_candidates | Non-admin cannot read training data |
| SEC-T7-12 | — | training_labels | Non-admin cannot read training labels |
| SEC-T7-13 | SEC-06 | referral_redemptions | Duplicate redemption blocked |
| SEC-T7-14 | SEC-06 | referral_redemptions | Self-referral blocked |
| SEC-T7-15 | — | referral_codes | Non-owner cannot read referral code |
| SEC-T7-16 | — | referral_codes | Client cannot create referral code directly |
