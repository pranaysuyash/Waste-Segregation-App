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

# Task: BWG Segregation-Quality Product Wedge

## Priority

P1 after trust and policy foundations.

## Objective

Turn the app into a narrowly sellable pre-handover segregation-quality system that complements authorised processors and compliance platforms rather than cloning them.

## Product statement

> Help a site prove and improve correct four-stream segregation before waste handover.

## Buyer hypotheses

1. authorised waste processor;
2. apartment/facility operator;
3. society-management platform;
4. institution/hotel/hospital/campus.

## Core roles

### Buyer/compliance owner

Needs:

- evidence;
- recurring problem visibility;
- vendor/operator accountability;
- report;
- measurable improvement.

### Operator

Needs:

- fast checks;
- uncertain-item answer;
- issue assignment;
- closure;
- low-friction offline/delayed sync.

### Resident/staff user

Needs:

- correct stream;
- safe handling;
- short local training;
- correction.

## MVP modules

### 1. Site and tenancy

- organisation;
- site;
- area/bin station;
- roles;
- processor/vendor;
- jurisdiction/policy;
- retention settings.

### 2. Daily four-stream check

For wet, dry, sanitary and special-care:

- bin available/labelled;
- contamination;
- evidence;
- approximate quantity/status;
- action required.

### 3. Uncertain-item assistant

Use canonical scan/policy gateway.

Output:

- item/material;
- four-stream result;
- safe handling;
- uncertainty;
- user/operator confirmation;
- site context.

### 4. Issue workflow

- contamination;
- missing/incorrect bin;
- unsafe item;
- overflow;
- missed pickup;
- equipment/process issue;
- training need.

Assign, due, resolve, evidence, recurrence.

### 5. Training loop

Recommend micro-training from actual repeated issues, not generic content volume.

Measure recurrence after training.

### 6. Buyer evidence

Dashboard:

- check completion;
- contamination incidents;
- unresolved safety issues;
- repeated item errors;
- resolution time;
- training completion;
- evidence coverage.

Export:

- period;
- site;
- policy/taxonomy version;
- immutable event IDs;
- unresolved risks;
- evidence references;
- report version/hash.

Do not call it an official statutory return until confirmed.

### 7. Processor/platform handoff

Initial integration:

- CSV/PDF;
- webhook;
- API contract.

Fields:

- site;
- pickup period;
- stream;
- contamination;
- evidence;
- issue state;
- policy version;
- actor/time.

## Non-goals

- vehicle routing;
- pickup marketplace;
- invoicing processor services;
- official certification;
- full EPR platform;
- smart-bin hardware;
- citywide complaint system;
- broad society ERP.

## Pilot acceptance

A design partner must be able to:

1. onboard site;
2. invite operator;
3. perform daily check;
4. resolve uncertain item;
5. create/close contamination issue;
6. run training;
7. export evidence;
8. remove operator access;
9. compare baseline and end state.

## Metrics

- verified segregation actions/site/week;
- contamination per 100 checks;
- unresolved high-risk issues;
- median resolution time;
- repeated-error reduction;
- operator completion;
- evidence coverage;
- buyer weekly return.

## Acceptance criteria

- one signed buyer/job brief;
- tenant isolation;
- daily workflow usable in field;
- report answers buyer's current question;
- processor integration boundary documented;
- pilot success and conversion decision agreed before start;
- no unsupported compliance claim.

## Anything else?

The code's society policy layer should not be the first buyer-facing feature. Daily checks, evidence and issue closure create value even before custom society rules are mature.
