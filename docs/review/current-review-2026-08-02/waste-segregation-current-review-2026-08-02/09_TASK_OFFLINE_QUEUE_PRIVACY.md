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

# Task: Offline Queue, Dead Letter and Image Privacy

## Priority

P0 for any production beta storing user images.

## Objective

Make offline classification reliable without retaining raw personal imagery indefinitely or losing queued work during safety/configuration failures.

## Current risks

- full raw image bytes stored in active queue;
- full raw image bytes copied into dead-letter queue;
- no retention/expiry fields;
- no consent/purpose binding;
- queue clear on one `ProductionSafetyException`;
- error strings stored without redaction;
- queue analytics can be constructed outside canonical consent manager;
- token spend/refund path differs based on backend routing.

## Data contract

Every queued image requires:

- owner UID/device;
- purpose;
- consent/policy version;
- created time;
- expiry time;
- encrypted storage reference;
- content hash;
- state;
- retry schedule;
- deletion status;
- redaction/privacy scan status.

Prefer encrypted file storage with metadata over large raw Hive values.

## State machine

```text
queued
processing
completed
retry_wait
blocked_auth
blocked_budget
blocked_configuration
dead_letter_user_action
expired_deleted
cancelled_deleted
```

Configuration/safety failures do not consume retry count.

## Commit units

### Commit 1: privacy and retention ADR

Decide:

- maximum queue retention;
- dead-letter retention;
- whether raw images can be retained;
- encryption/key strategy;
- logout/account-switch behaviour;
- child/family handling;
- training exclusion.

### Commit 2: storage migration

Move image bytes out of metadata box.

Store:

- encrypted file/object reference;
- checksum;
- metadata.

Migrate or delete old queued entries through an idempotent versioned process.

### Commit 3: failure classification

Typed failures:

- retryable network/provider;
- authentication;
- insufficient credits;
- permanent invalid image;
- configuration/safety;
- user cancellation;
- privacy rejection.

Do not inspect error message strings to make core decisions.

### Commit 4: safe configuration failure

When client AI is disabled/misconfigured:

- mark item `blocked_configuration`;
- do not clear unrelated items;
- do not claim permanent failure;
- show operator/user action;
- server/backend route can resume later.

### Commit 5: token authority

Use the same server token reservation for foreground and queued scans.

Idempotency key = queue item/request ID.

A retry must reuse or reconcile reservation; no client-local spend/refund ledger.

### Commit 6: deletion and user controls

- list pending/blocked/dead items without exposing sensitive thumbnail by default;
- retry;
- delete;
- clear with confirmation;
- auto-expire;
- logout purge/transfer decision;
- account deletion hooks;
- metrics without raw error/PII.

## Required tests

- app crash after queue write;
- duplicate connectivity callback;
- account switch;
- token reservation retry;
- backend unavailable;
- safety configuration disabled;
- three independent failed items;
- expiry;
- user deletion;
- dead-letter privacy;
- corrupted encrypted file;
- consent withdrawal.

## Acceptance criteria

- no indefinite raw-image retention;
- queue items survive safe retry without duplicates;
- one configuration failure does not clear the queue;
- token charging is server-idempotent;
- deletion covers active/dead-letter/cache references;
- analytics respect consent;
- retention/deletion evidence exists.

## Anything else?

Offline queued cloud processing is not “offline classification.” Product copy must distinguish delayed processing from on-device inference.
