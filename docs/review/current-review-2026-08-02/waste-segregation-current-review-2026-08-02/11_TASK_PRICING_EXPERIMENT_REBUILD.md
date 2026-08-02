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

# Task: Rebuild Pricing Validation

## Priority

P2. Do not execute before billing integrity and truthful product packaging.

## Objective

Replace the current local scaffolding and invalid sample plan with a server-observed, statistically defensible willingness-to-pay test.

## Why current plan is invalid

### Implementation

- provider has no call sites;
- anonymous assignment uses the test ID, assigning all such users identically;
- Dart `hashCode` is not a durable experiment hash;
- assignment is local-only;
- events are logs;
- completion can be client-reported;
- variants promise unfinished features.

### Statistics

For baseline conversion 2% versus 5%, two-sided alpha 0.05 and 80% power, a standard two-proportion calculation needs approximately 562 users per arm before:

- multiple-arm correction;
- attrition;
- eligibility filtering;
- sequential-analysis adjustment.

100 per arm is underpowered.

## Decision before code

Choose one question.

Recommended first question:

> Will a qualified society/processor buyer pay for a segregation-quality pilot?

This can be answered with founder-led offers at far lower traffic than a four-arm consumer checkout experiment.

Do not run three consumer pricing models simultaneously without meaningful user volume.

## Commit/decision units

### Decision 1: B2B offer test versus consumer A/B

Recommended:

1. paid pilot price/packaging interviews;
2. proposal conversion;
3. only then consumer smoke test if consumer value remains strategic.

### Decision 2: truthful packages

Remove claims not delivered:

- EPR compliance;
- official certification;
- offline classification;
- advanced segmentation;
- unlimited AI without margin guardrails.

Package observable outcomes.

### Commit 1: experiment assignment service

Server assigns using a cryptographic stable hash of:

- experiment ID/version;
- stable user/account ID;
- salt.

Persist exposure server-side.

Handle:

- anonymous-to-auth merge;
- exclusion;
- holdout;
- re-randomisation policy;
- experiment end.

### Commit 2: analytics facts

Server facts:

- exposure;
- checkout created;
- provider-authorised payment;
- entitlement activated;
- refund;
- churn.

Client facts:

- screen view;
- selection;
- abandonment.

Revenue reconciles to billing ledger.

### Decision 3: analysis design

Options:

- two-arm frequentist with precomputed sample;
- Bayesian sequential model;
- switchback/account-level B2B test;
- qualitative paid-offer test.

Pre-register:

- hypothesis;
- primary metric;
- guardrails;
- sample;
- stopping;
- exclusions;
- correction;
- decision rule.

### Commit 3: remote config and kill switch

Pricing display and enforcement are separately controlled.

Never use a pricing exposure to silently alter an already-promised free entitlement without clear user communication.

## B2B pricing discovery

Test packages such as:

- paid baseline audit;
- single-site pilot;
- monthly per-site software;
- processor white-label/portfolio licence;
- implementation/support fee.

Ask:

- budget owner;
- current cost;
- approval path;
- contract/procurement;
- measurable outcome;
- renewal trigger.

## Acceptance criteria

- one decision question;
- stable server assignment;
- provider-verified conversion;
- statistically valid plan;
- truthful packages;
- guardrail/rollback;
- result linked to a product decision.

## Anything else?

A sophisticated experiment cannot compensate for insufficient traffic or an unclear value proposition. Use sales evidence before multivariate consumer pricing.
