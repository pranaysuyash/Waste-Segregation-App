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

# Task: Billing, Entitlements and Storefront Compliance

## Priority

P0.

## Objective

Replace client-authoritative premium flags with a provider-verified server ledger and expose only payment rails permitted for the user's platform, storefront and programme enrolment.

## Files owned

- `functions/src/create_checkout_session.ts`
- `functions/src/create_token_purchase.ts`
- `functions/src/dodopayments_webhook.ts`
- new billing verification/reconciliation Functions
- `lib/services/purchase_service.dart`
- `lib/services/premium_service.dart`
- `lib/services/web_checkout_service.dart`
- premium purchase UI
- billing tests/docs

## Canonical model

```text
billing_accounts/{uid}
billing_accounts/{uid}/transactions/{providerTransactionKey}
billing_accounts/{uid}/entitlements/{entitlementId}
billing_events/{providerEventId}
billing_reconciliation_runs/{runId}
```

Transaction records are immutable.

Entitlement projection contains:

- entitlement ID;
- provider;
- product;
- original transaction/subscription ID;
- environment;
- status;
- effective start/end;
- grace end;
- last provider verification;
- revocation reason;
- projection version.

## Commit units

### Commit 1: product catalogue and authority contract

Create server-owned catalogue:

- logical SKU;
- provider-specific product IDs;
- product type;
- amount/currency where fixed;
- token quantity;
- eligible platform/storefront;
- entitlement;
- refund/reversal policy.

Clients submit a logical SKU, not arbitrary provider product ID.

Return URLs are server allowlisted.

### Commit 2: idempotent billing event state machine

States:

```text
received
processing
applied
failed_retryable
failed_terminal
reversed
```

Do not mark applied before value mutation.

Use a Firestore transaction/outbox or resumable operation record.

### Commit 3: Dodo verification

- verify raw-body signature;
- validate event schema and environment;
- resolve product from server catalogue;
- verify amount/currency/customer/UID;
- handle `payment.succeeded`, `subscription.active`, renewal, cancelled, past_due, refund/chargeback;
- record `userId` on subscriptions;
- exactly-once token credit/reversal;
- reconcile active subscriptions on a schedule.

### Commit 4: Google Play verification

- use correct subscription/consumable API;
- send purchase token to backend;
- verify package/product/account binding;
- process Real-time Developer Notifications;
- acknowledge/consume correctly;
- reconcile expiry, pause, grace, cancellation and refund;
- restore from server projection.

### Commit 5: Apple verification

- StoreKit 2 transaction verification;
- App Store Server API/notifications;
- original transaction identity;
- storefront/environment/product validation;
- subscription lifecycle;
- restore from server projection.

If iOS is not in the next release, remove purchase UI and document scope rather than leaving a partial rail.

### Commit 6: client becomes cache only

`PremiumService` must:

- never grant durable entitlement from Hive;
- never write Firestore subscription state;
- observe server projection;
- cache state with verification timestamp and expiry;
- distinguish `active`, `pending_verification`, `grace`, `expired`, `unknown`;
- fail closed for paid server operations.

### Commit 7: storefront/payment-rail policy

Create a runtime eligibility service based on:

- platform;
- installation channel;
- user country/storefront;
- Play/Apple programme enrolment;
- remote kill switch.

Google Play India alternative billing requires programme enrolment, Play billing choice and transaction reporting.

Apple digital-feature unlocks generally require IAP, with specific storefront/entitlement exceptions.

Do not show “No app store required.”

### Commit 8: paid feature contracts

For every visible premium feature:

```yaml
feature:
promise:
supported_platforms:
production_implementation:
automated_tests:
manual_evidence:
safe_failure:
sellable: true|false
```

Hide all `sellable: false` claims.

## Required tests

- forged local premium flag;
- direct Firestore premium write;
- duplicate webhook;
- failure after event receipt;
- provider retry;
- mismatched product/amount/currency/environment;
- renewal;
- cancellation at period end;
- grace;
- past due;
- refund;
- chargeback;
- reinstall;
- second device;
- stale local cache;
- store sandbox purchase;
- token reversal;
- unsupported storefront hides external checkout.

## Acceptance criteria

- no client-only event grants premium;
- entitlement lifecycle matches provider state;
- retries cannot lose or duplicate value;
- transaction ledger explains every entitlement;
- only eligible payment rails render;
- premium copy matches actual capability;
- production monetisation remains kill-switched until Tier 3+ integration evidence exists.

## Anything else?

The current pricing experiment must consume server entitlements and server revenue events. Do not integrate it with local purchase-completed logs.
