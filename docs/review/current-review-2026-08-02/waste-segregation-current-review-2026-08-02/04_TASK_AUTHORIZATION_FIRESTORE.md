> **Repository:** `pranaysuyash/Waste-Segregation-App`
>
> **Reviewed branch:** `main`
>
> **Reviewed commit:** `e48a66bd6c9116e939a3eddfa5cc48c5d2171e6a`
>
> **Commit timestamp:** 2026-08-02T03:40:33Z
>
> **Review timestamp:** 2026-08-02
>
> **Previous review baseline:** `d7a9c73f75779ddcbf9f22f4ce2fba9a0280b171`
>
> **Evidence limit:** Static remote-code inspection plus current official/public-source research. The latest GitHub commit exposes no combined status checks or associated workflow runs, so build, test, deployment and runtime claims remain unverified until the release-proof task is executed.

# Task: Authorisation and Firestore Trust Boundary

## Priority

P0.

## Objective

Make client-write authority explicit and tenant-scoped. Protect billing, role, reward, verification and audit state from direct client mutation.

## Files owned

- `firestore.rules`
- `storage.rules`
- `firestore-rules-test/**`
- `lib/services/firestore_schema_registry.dart`
- authorisation contract docs

Coordinate Function changes with billing/society owners; this task owns final rule edits.

## Required access matrix

Create `docs/security/FIRESTORE_ACCESS_MATRIX.md` with:

- collection/path;
- sensitivity;
- reader;
- creator;
- updater;
- deletor;
- server-owned fields;
- tenant key;
- retention class;
- positive/negative test IDs.

## Critical rule changes

### Users

Use field diffs and a whitelist.

Client-writable examples:

- display name/photo, subject to validation;
- user preferences;
- explicit consent choices through a versioned contract.

Server-only:

- `billing`;
- `subscriptionTier`;
- entitlements;
- roles/admin;
- token credits/debits and ledger;
- bonus scans;
- verification flags;
- moderation state;
- server timestamps/audit actors;
- experiment exposure truth;
- policy verification.

Do not permit a generic user document update based only on gamification validation.

### Families/invitations/shared content

- family read: members only, or a separate public projection;
- invitation read: inviter, intended email/UID, authorised admin;
- shared classification: family members only;
- membership change: owner/admin only;
- role escalation: server transaction or strict role rule;
- email/private profile fields excluded from public records.

### Society policies

Add an explicit path model.

Recommended:

```text
societies/{societyId}
societies/{societyId}/members/{uid}
society_policy_drafts/{societyId}
society_policy_versions/{societyId}/versions/{versionId}
```

Roles:

- owner/admin can propose internal operational rules;
- designated reviewer can approve;
- client cannot set `isVerified`;
- published versions immutable;
- public/read access uses a sanitised projection if needed.

### Gamification and leaderboard

Any value tied to:

- rank;
- premium reward;
- token;
- referral;
- economic benefit;

must be server derived.

Client can submit an action/event, not a new total.

### Analytics

Require:

- authenticated or approved anonymous identity;
- schema/version;
- own UID/tenant;
- server receipt timestamp;
- event name allowlist where practical;
- no read access.

## Required negative tests

- write `billing.entitlements.pro_subscription = true`;
- write `subscriptionTier = premium`;
- increment token balance;
- grant own reward/points;
- set self as admin or policy verifier;
- read another family;
- read unrelated invitation;
- read another society private policy;
- publish society policy without reviewer role;
- modify immutable published policy;
- write another tenant's evidence;
- read another user's subscription;
- remove oneself from audit trail while preserving access.

## Required positive tests

- update allowed profile preference;
- invited user reads their invitation;
- family member reads family;
- society operator reads published operational policy;
- society admin creates draft;
- reviewer publishes version;
- subscription owner reads corrected server record.

## Data migration

Existing documents may contain mixed client/server fields.

Create a migration that:

- normalises schema;
- moves server-owned fields into protected maps/collections;
- stamps schema version;
- records migration ID;
- is idempotent;
- has a dry-run report.

## Acceptance criteria

- client cannot forge money, role, verification or reward state;
- all sensitive reads are user/member/tenant scoped;
- policy publication has reviewer authority;
- existing legitimate flows pass emulator tests;
- no rule is loosened to “make the app work”;
- deployed staging rule hash is recorded.

## Anything else?

Rules alone do not make client-created totals trustworthy. Move economic and compliance-relevant mutations behind callable/server operations.
