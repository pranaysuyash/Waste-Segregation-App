> **Review baseline:** `pranaysuyash/Waste-Segregation-App`, branch `main`, commit `d7a9c73f75779ddcbf9f22f4ce2fba9a0280b171`
>
> **Remote commit date:** 2026-05-25
>
> **Review date:** 2026-08-02
>
> **Hard limitation:** This review does not include local, uncommitted, or unpushed work. Run `02_TASK_LOCAL_CHANGE_RECONCILIATION.md` before implementing any other task. Existing local work is authoritative where it is newer and intentional.

# Task: Security, Authorisation and Firestore Trust Boundaries

## Priority

P0. Blocks payment, pilot data and public launch.

## Objective

Make all server-owned state unwriteable by clients, restrict sensitive reads to the correct user or tenant, and add emulator tests that prove the intended security properties.

## Primary files

- `firestore.rules`
- `storage.rules`, if present locally
- `firestore-rules-test/**`
- `functions/src/r2_storage.ts`
- `functions/src/referrals.ts`
- `functions/src/index.ts`
- schema registry files under `lib/services/`
- security and environment documentation

## Findings to address

### SEC-01: user documents allow arbitrary non-wallet fields

`validateGamificationUpdate` validates only gamification and token-wallet transitions. It does not constrain changes to other keys. Protect at least:

- `billing`
- `subscriptionTier`
- `entitlements`
- `tokenWallet` server-credit fields
- `bonusScans`
- admin flags and roles
- audit timestamps and “updatedBy” fields
- training consent audit fields where server ownership is required.

Prefer a deny-by-default field-diff policy.

### SEC-02: family records are broadly readable

Current rules allow any authenticated user to read `families/{familyId}` and `invitations/{invitationId}`. Invitations can expose email addresses. Shared classifications are also readable by any authenticated user.

Restrict:

- family reads to members or explicit public projections;
- invitations to inviter, invited email/user and server admins;
- shared classifications to members of the referenced family;
- family updates to role-authorised members, not any member;
- member-list mutations to owner/admin paths.

### SEC-03: community and gamification integrity

- Users can write their own leaderboard entries and gamification collection.
- Community update rules do not implement safe cross-user likes.
- Analytics events have no ownership/schema constraints.
- Points and achievements should be derived server-side if they have economic, ranking or reward value.

### SEC-04: subscription document mismatch

Firestore rules require `subscriptions/{id}.userId`, while `SubscriptionRecord` does not write `userId`.

### SEC-05: R2 upload abuse surface

The signed upload callable needs:

- App Check;
- per-user and per-IP quota;
- allowlisted MIME types;
- maximum byte size bound;
- server-owned object-key prefix;
- rejected executable/vector formats unless explicitly supported;
- metadata containing owner, purpose and retention class;
- checksum/content-length conditions where supported;
- no unconditional public URL;
- signed read or controlled CDN access;
- deletion and lifecycle policy.

### SEC-06: referral race and accounting defects

- redemption uniqueness is checked outside the transaction;
- referrer reward is not actually granted;
- stats query reads a subcollection that is never written;
- a referral document stores only one `redeemedBy`;
- deterministic short codes need collision handling;
- App Check, rate limiting and abuse detection are absent.

## Design requirements

### Server-owned field policy

Define a canonical list:

```text
Client writable:
- display/profile preferences
- explicit consent choices, subject to version and audit rules
- user-authored content through constrained paths

Server writable only:
- billing and entitlements
- token credits and debits
- subscription state
- roles/admin claims
- rewards with monetary or ranking value
- webhook/audit state
- moderation state
```

Do not mix server-owned and freely writable fields in one map without field-diff rules.

### Tenant isolation

For the planned BWG product, introduce or reserve a structure such as:

```text
organisations/{organisationId}
organisations/{organisationId}/members/{uid}
organisations/{organisationId}/sites/{siteId}
organisations/{organisationId}/events/{eventId}
```

Membership and role checks must be explicit and reusable.

## Work breakdown

### T1. Write a security matrix

Create `docs/security/FIRESTORE_ACCESS_MATRIX.md`.

For every collection:

- data sensitivity;
- allowed readers;
- allowed creators;
- allowed updaters;
- server-owned fields;
- retention class;
- emulator test IDs.

### T2. Rewrite user update validation

Use `diff().affectedKeys()` or equivalent rules logic to:

- allow only explicit profile/preferences fields;
- reject billing and entitlement changes;
- reject token credits from clients;
- preserve server-owned fields;
- constrain deletion according to the account-deletion workflow.

### T3. Repair family and invitation rules

Add membership and role helper functions. Do not rely only on client-provided arrays without validating mutation authority.

### T4. Move economic gamification to the server

At minimum:

- prevent arbitrary point inflation;
- prevent arbitrary leaderboard totals;
- make reward creation idempotent;
- record source event IDs.

### T5. Lock down R2

Implement upload intent records and finalisation:

1. client requests upload intent;
2. server validates purpose, MIME and quota;
3. server issues constrained URL;
4. client uploads;
5. server verifies object metadata/size;
6. application stores only a controlled object reference;
7. lifecycle job deletes expired raw images.

### T6. Repair referral transactions

Use a unique redemption document keyed by redeemer UID or a transaction-enforced uniqueness key. Credit both sides exactly once. Make stats query the actual redemption collection.

### T7. Add emulator tests

Required negative tests:

- user grants themselves premium;
- user edits `billing.entitlements`;
- user increments token balance;
- user reads another family;
- user reads an invitation not addressed to them;
- user modifies another family's shared classification;
- non-admin reads training labels;
- duplicate referral redemption;
- self-referral;
- concurrent referral redemption;
- subscription owner can read their subscription after schema fix;
- non-owner cannot read it.

## Verification

```bash
npm --prefix firestore-rules-test ci
npm --prefix firestore-rules-test run test:all:emulator
npm --prefix functions ci
npm --prefix functions run build
npm --prefix functions test
```

Run a staging smoke test with two normal users, one organisation admin and one non-member.

## Acceptance criteria

- No client can create or modify paid entitlement.
- No client can credit tokens or economic rewards.
- Family, invitation and shared-content reads are correctly scoped.
- Subscription records and rules agree.
- R2 objects are private by default and bounded by size/type/quota.
- Referral rewards are exactly-once and stats are correct.
- All negative tests fail closed.
- The deployed staging rules hash is recorded in a release-evidence document.

## Rollback

- Keep prior rules and functions artifacts versioned.
- Use a feature flag to disable R2 and referrals if migration fails.
- Do not loosen rules as an emergency fix. Route broken writes through a server function instead.
