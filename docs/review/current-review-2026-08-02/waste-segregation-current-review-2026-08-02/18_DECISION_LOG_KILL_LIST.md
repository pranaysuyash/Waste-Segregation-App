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

# Decision Log and Kill List

## Required decisions

### D-01 Product

Recommended: pre-handover segregation-quality and evidence layer for BWGs/processors.

### D-02 Initial buyer

Recommended sequence: authorised processor, apartment/facility operator, society software.

### D-03 Jurisdiction

Bengaluru first, but national SWM 2026 stream model underneath.

### D-04 Classification authority

`ScanOrchestrator` plus one canonical `AiService`/gateway path.

### D-05 Entitlement authority

Server ledger/projection; local cache only.

### D-06 Policy authority

National/local statutory > authorised processor > site operational > user preference.

### D-07 Society discovery

Recommended: explicit invite/code for MVP. Defer geospatial discovery.

### D-08 Pricing validation

Recommended: paid B2B offer tests before multi-arm consumer A/B.

### D-09 Consumer payments

Disabled until billing P0 closes.

### D-10 Brand

ReLoop collision/trademark screen remains required before brand investment.

## Freeze list

Unless new buyer evidence and an ADR exist:

- new AI providers;
- new city policy packs;
- blockchain;
- smart-bin hardware;
- full pickup marketplace;
- logistics routing;
- generic community growth;
- new premium tiers;
- token-economy expansion;
- proximity-based society discovery;
- on-device production claim;
- broad EPR platform;
- carbon-savings claim;
- official compliance certification;
- referral growth rollout;
- more documentation layers without authority cleanup.

## Feature admission test

A feature requires:

1. named buyer/user;
2. repeated job;
3. evidence;
4. metric;
5. smallest valid test;
6. authority/security/privacy contract;
7. operational owner;
8. explicit displaced work.

## Claim registry

A claim requires evidence:

- offline -> real network-independent inference;
- compliant -> current verified rules and workflow;
- secure -> threat model plus tests;
- accurate -> disclosed evaluated dataset;
- production ready -> release evidence;
- premium active -> server entitlement;
- EPR/EBWGR -> exact supported regulatory workflow;
- audit ready -> immutable traceable evidence and reviewed report format.

## Anything else?

The new policy/pricing documents are useful exploration, but exploration language must not leak into production claims or paid packages.
