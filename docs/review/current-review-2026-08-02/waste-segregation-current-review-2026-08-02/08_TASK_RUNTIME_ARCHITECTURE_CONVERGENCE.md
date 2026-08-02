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

# Task: Runtime Architecture Convergence

## Priority

P1 after P0 gates are protected by tests.

## Objective

Finish the convergence started by `ScanOrchestrator`: one production entry point, one dependency instance per runtime scope and idempotent downstream effects.

## Preserve

- `ScanOrchestrator`;
- `ClassificationResultProcessor`;
- Riverpod composition-root direction;
- context-aware cache key;
- queue using canonical scan workflow;
- state-machine lifecycle improvements.

Do not restart architecture from scratch.

## Remaining duplication

- offline queue constructs fresh services;
- providers can create fallback instances;
- `ApiManagementService` constructs legacy `EnhancedAiApiService`;
- manual bootstrap remains large;
- result pipeline combines unrelated side effects;
- mutable singleton queue carries runtime dependency configuration.

## Commit units

### Commit 1: runtime call graph and ownership table

Document exact production paths for:

- startup;
- scan;
- re-analysis;
- queue;
- result save;
- reward;
- sync;
- training capture;
- payment;
- policy;
- cache.

Mark legacy/dead/test-only paths.

### Commit 2: explicit composition root

Create typed containers:

```text
AppCoreServices
ScanServices
BillingServices
OrganisationServices
```

All production services receive dependencies. No `StorageService()` or `AnalyticsService()` construction inside workflow methods.

Providers must fail loudly in tests if a required override is absent, rather than silently constructing a second state owner.

### Commit 3: retire legacy AI management path

Determine whether `ApiManagementService` is used.

If not required:

- remove it;
- remove production construction of `EnhancedAiApiService`;
- keep only focused test compatibility until deleted.

If required for a developer screen, make it diagnostics-only and read data from canonical gateway telemetry rather than constructing another route.

### Commit 4: durable result outbox

Replace sequential side effects with events:

```text
classification_saved
reward_requested
cloud_sync_requested
training_candidate_requested
community_post_requested
analytics_requested
```

Each consumer stores a processed event ID.

Local save is the transaction boundary. Optional effects retry independently.

Ads are presentation policy, not persistence logic.

### Commit 5: queue dependency injection

Queue receives:

- orchestrator;
- token authority;
- storage;
- analytics;
- retention service.

Remove service construction and mutable configure-after-init risk.

Do not clear all pending items for one safety exception. Quarantine with reason and preserve user control unless data must be deleted by policy.

### Commit 6: model immutability truth

Either:

- make `WasteClassification` actually immutable/domain value plus persistence adapter; or
- correct `CONTEXT.md` and establish controlled mutation boundaries.

Do not claim immutability while exposing public mutable Hive fields.

## Required tests

- same service identity foreground/queue;
- app restart during each outbox stage;
- no duplicate reward;
- no duplicate training candidate;
- no duplicate community post;
- sync retry;
- queue safety failure preserves unrelated items;
- missing provider override fails in test;
- legacy AI path cannot process production scan.

## Acceptance criteria

- one production classification gateway;
- one service instance per state owner;
- no hidden constructor fallback in critical workflows;
- downstream effects are independently idempotent;
- offline and foreground paths produce equivalent persisted semantics;
- dead legacy paths are removed or explicitly diagnostics-only.

## Anything else?

`main.dart` size is not itself the problem. Hidden ownership and duplicate instances are. Refactor around ownership evidence, not file-length aesthetics.
