> **Review baseline:** `pranaysuyash/Waste-Segregation-App`, branch `main`, commit `d7a9c73f75779ddcbf9f22f4ce2fba9a0280b171`
>
> **Remote commit date:** 2026-05-25
>
> **Review date:** 2026-08-02
>
> **Hard limitation:** This review does not include local, uncommitted, or unpushed work. Run `02_TASK_LOCAL_CHANGE_RECONCILIATION.md` before implementing any other task. Existing local work is authoritative where it is newer and intentional.

# Task: Payments, Entitlements and Store Compliance

## Priority

P0. Blocks charging any user.

## Objective

Create one server-authoritative entitlement system that correctly handles purchase, renewal, restore, expiry, cancellation, refund, retry and cross-device access for each supported sales channel.

## Primary files

- `lib/services/purchase_service.dart`
- `lib/services/premium_service.dart`
- `lib/services/web_checkout_service.dart`
- `lib/screens/premium_features_screen.dart`
- `lib/models/premium_feature.dart`
- `functions/src/create_checkout_session.ts`
- `functions/src/create_token_purchase.ts`
- `functions/src/dodopayments_webhook.ts`
- `functions/src/index.ts`
- `firestore.rules`
- platform billing configuration and tests

## Non-negotiable architecture

### Canonical authority

The server is the authority.

Local Hive state is a cache used for responsive UI. It must never independently grant durable access.

Canonical model:

```text
billing_accounts/{uid}
billing_accounts/{uid}/purchases/{providerEventId}
billing_accounts/{uid}/entitlements/{entitlementId}
billing_accounts/{uid}/ledger/{entryId}
```

An entitlement should include:

- source provider;
- source transaction/subscription ID;
- product ID;
- status;
- effective start;
- effective end;
- grace period;
- last verified timestamp;
- revocation reason;
- environment;
- idempotency key.

### Platform/channel policy

Create an explicit matrix:

| Platform | Region | Allowed rail | Required programme/API | Product type |
|---|---|---|---|---|
| Android Play | India | Play Billing plus enrolled alternative billing, if chosen | Play alternative-billing APIs, reporting and UX | digital subscription/tokens |
| Android Play | other regions | Play Billing unless enrolled programme applies | region-specific | digital |
| iOS | storefront-specific | StoreKit, or approved external entitlement where eligible | Apple entitlement and disclosure | digital |
| Web | supported countries | DodoPayments or selected provider | web terms, tax, refunds | digital |

Do not show a payment rail merely because the code can open it.

## Findings to address

### PAY-01: local purchase events grant access

A client event is not a verified entitlement. Add server verification and reconciliation.

### PAY-02: subscription uses non-consumable purchase API

Use the correct store product type and lifecycle.

### PAY-03: webhook event is marked processed before side effects

Use a state machine:

```text
received -> processing -> applied
                    -> failed_retryable
                    -> failed_terminal
```

The idempotency record and business mutation must be transactionally coordinated or safely resumable.

### PAY-04: product and redirect values are client-influenced

- map logical product keys to provider product IDs server-side;
- allowlist return URLs;
- never trust token quantity from webhook metadata alone;
- verify product, price, currency and environment;
- prevent test events from granting production access.

### PAY-05: past-due and cancellation semantics are incomplete

Define:

- grace period;
- immediate vs period-end cancellation;
- past-due access;
- chargeback/refund;
- manual support override;
- renewal reconciliation.

### PAY-06: premium catalogue includes placeholder features

No paid product may promise offline inference or advanced segmentation until a feature contract passes.

## Work breakdown

### T1. Write an entitlement contract

Create `docs/billing/ENTITLEMENT_CONTRACT.md`.

Specify:

- entitlement IDs;
- product mapping;
- provider status mapping;
- source of truth;
- cache policy;
- transitions;
- cross-device restore;
- support override;
- audit events.

### T2. Implement the server ledger

Every purchase event creates an immutable ledger entry. Entitlement projection is derived from ledger and provider status.

Use exactly-once keys:

- provider event ID;
- original transaction ID;
- subscription ID;
- purchase token;
- order ID.

### T3. Implement provider verification

For store billing:

- send purchase token/receipt to the server;
- verify with the store server API;
- validate bundle/package, product, environment and ownership;
- process server notifications;
- periodically reconcile active subscriptions.

For Dodo:

- validate signature against raw body;
- validate event schema;
- verify product mapping;
- process retries safely;
- reconcile provider subscriptions on a schedule.

### T4. Remove client authority

`PremiumService` should:

- listen to server entitlement projection;
- cache last known state with expiry;
- fail safely when stale;
- never write `subscriptionTier` or `billing.entitlements`;
- expose “verification pending” separately from active access.

### T5. Correct web checkout UX

- show Dodo only where the platform/storefront policy permits it;
- enrol in required programmes before release;
- implement required Play APIs and transaction reporting;
- replace “No app store required” with compliant, factual copy;
- provide subscription management, refund and support links;
- prevent arbitrary return URL.

### T6. Correct token packs

- server-owned catalogue;
- real provider product IDs;
- expected amount/currency;
- exactly-once credit;
- reversal on refund/chargeback;
- purchase limit and abuse monitoring;
- clear expiry/non-expiry rules.

### T7. Add reconciliation jobs

At least:

- active subscription reconciliation;
- webhook stuck-event recovery;
- missing-entitlement recovery;
- ledger/projection consistency check;
- refund/reversal reconciliation.

### T8. Feature-contract paid claims

Create one contract per premium feature:

```markdown
Feature:
User-visible promise:
Platforms:
Implemented paths:
Automated tests:
Manual evidence:
Failure state:
Eligible for sale: yes/no
```

Hide all `no` features from production pricing.

## Required tests

- forged client premium write;
- replayed webhook;
- webhook fails after receipt but before entitlement;
- duplicate purchase update;
- refund;
- cancellation;
- renewal;
- past due;
- reinstall and restore;
- second device;
- test-environment receipt in production;
- mismatched product;
- mismatched amount/currency;
- token pack reversal;
- expired local cache;
- offline launch with stale entitlement.

## Verification

```bash
npm --prefix functions ci
npm --prefix functions run build
npm --prefix functions test
flutter test test/services/purchase_service_test.dart
flutter test test/services/premium_service_test.dart
flutter test
```

Run sandbox purchases for every supported platform and capture transaction IDs and server projections.

## Acceptance criteria

- Client-only actions cannot grant premium.
- Entitlement survives reinstall and multiple devices.
- Refund, cancellation and expiry remove access according to documented policy.
- Webhook retries cannot lose or duplicate value.
- Token credits reconcile to immutable provider events.
- Only policy-eligible payment rails appear.
- Every visible paid claim has evidence.
- Support can explain and audit any user's entitlement from the ledger.

## Launch decision

Until this task passes, keep all purchasing disabled in production via a remote kill switch.
