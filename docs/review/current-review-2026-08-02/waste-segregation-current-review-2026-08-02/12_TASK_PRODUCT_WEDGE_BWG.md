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

## PMF-first recurring-core update (2026-08-03)

This scope makes the feedback route in
`20_TASK_CHATGPT_FEEDBACK_PMFMODEL_AND_CONFIDENCE_HARDENING_2026-08-02.md`
concrete without changing the pre-handover quality wedge. It is a product
scope and task-allocation update, not an implementation-completion claim.

### PMF hypothesis

The first hypothesis to test is a Bengaluru household plus housekeeping
workflow: when a person can see the next source-qualified disposal action for
their selected area, prepare the right stream, and close or flag the handover
outcome, the app earns recurring use from disposal itself rather than from a
one-off scan or gamification loop.

The BWG path remains the sellable extension of the same loop: the buyer sees
whether recurring preparation, handover and issue closure improve stream
quality before the authorised processor takes custody.

### Recurring core contract

| Layer | Required product contract | Explicit boundary |
|---|---|---|
| Area collection schedule | A selected site/area resolves to a stream-specific next action only when the schedule has an area scope, source reference, policy-pack/version reference, review status and effective window. The interface must show `unavailable` when those facts are absent. | Do not infer an exact local collection window from a broad city frequency or an unreviewed source. |
| Pickup event | An expected handover event records the applicable stream, expected window, schedule/source reference, state, actor/time and reason when it is missed or unconfirmed. | It is not a booking, dispatch, vehicle-tracking or collection-operator record. |
| Completion layer | The resident or operator can record preparation and a handover outcome, attach permitted evidence or create an issue. The record preserves whether the outcome is self-reported, witnessed or integration-supplied. | A completion record is not an official municipal, processor or statutory certificate. It must never be inferred merely because a reminder was sent or a time window elapsed. |
| Special-care action | The loop gives conservative containment guidance first, then offers a schedule or handover step only when the applicable pack supports it. | Never turn an unavailable or low-confidence schedule into ordinary-bin guidance. |

### Pickup-event states

- `upcoming`: a source-qualified event is expected in the displayed window;
- `preparation_confirmed`: the stream is prepared for handover;
- `handover_confirmed`: a user, operator or permitted integration recorded the outcome and its source;
- `missed_or_unconfirmed`: the window passed or the user reported a problem, without inferring a collection failure;
- `unavailable_or_cancelled`: the source does not support an event, the schedule changed, or the event no longer applies.

These states deliberately distinguish the schedule from the observed outcome.
They are the minimum completion layer needed for repeat use and buyer evidence.

### Current implementation boundary

Static source inspection shows a city/category `collectionSchedule` map in
`lib/services/city_policy_data.dart`, consumed by
`lib/services/local_policy_engine.dart`. That is generic policy-guide data,
not an area-qualified schedule, pickup-event model, reminder trigger or
completion workflow. The feedback task records area calendars, events and the
completion layer as design-only. They remain design-only until the linked tasks
below are implemented and release evidence is captured.

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

### 1A. Area collection schedule

- explicit site/area selection, rather than a silent location guess;
- next expected stream/window only from a reviewed, area-scoped schedule;
- policy-pack, source, effective-date and review-status visibility;
- an honest unavailable state with safe interim handling;
- reminder eligibility only when the schedule is current enough to support it.

### 1B. Pickup event and completion layer

- create or surface a source-qualified expected handover event;
- confirm preparation separately from handover;
- record self-report, witness or integration source for a completion;
- flag missed or unconfirmed outcomes without asserting collector fault;
- connect the outcome to a contamination, safety or training issue when needed;
- retain only consented evidence under the privacy and retention gates.

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
- missed or unconfirmed pickup event;
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
- schedule coverage and unavailable-state rate;
- expected pickup events by stream;
- preparation and handover completion rate;
- missed or unconfirmed event rate;
- special-care action completion without a false collection claim.

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
- area/schedule reference and schedule-source status;
- pickup-event state and outcome source;
- completion/issue linkage where present.

## Non-goals

- vehicle routing;
- pickup marketplace;
- pickup dispatch, booking or collector support;
- live vehicle or collector tracking;
- invoicing processor services;
- official certification;
- treating self-reported completion as statutory, municipal or processor proof;
- publishing an area schedule or reminder from an unreviewed source;
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
10. select a pilot area and see either a source-qualified next action or an honest unavailable state;
11. prepare the due stream and record a handover outcome with its source;
12. turn a missed or unconfirmed event into an accountable issue without claiming a collector failure.

## Metrics

- verified segregation actions/site/week;
- contamination per 100 checks;
- unresolved high-risk issues;
- median resolution time;
- repeated-error reduction;
- operator completion;
- evidence coverage;
- buyer weekly return.
- schedule-to-preparation conversion;
- expected-event-to-handover completion;
- special-care action completion;
- missed/unconfirmed event recurrence by site/area.

## Acceptance criteria

- one signed buyer/job brief;
- tenant isolation;
- daily workflow usable in field;
- report answers buyer's current question;
- processor integration boundary documented;
- pilot success and conversion decision agreed before start;
- no unsupported compliance claim.
- every displayed area schedule has a visible source, scope, version and review status, or is shown as unavailable;
- schedule expectation, preparation and handover outcome are distinct states with actor/time and outcome source;
- missed/unconfirmed events create a recoverable issue path rather than an unsubstantiated collection claim;
- special-care guidance remains conservative when no verified schedule is available;
- completion evidence uses the P0 privacy/retention boundary and tenant isolation rather than a parallel store.

## PMF hypothesis to task ownership and acceptance path

This table assigns existing review tasks only. It does not allocate source-code
ownership or assert that any recurring-core feature is implemented.

| Dependency | Canonical review-file owner | PMF contribution | Acceptance criterion for the recurring loop |
|---|---|---|---|
| P0-03 | `docs/review/current-review-2026-08-02/waste-segregation-current-review-2026-08-02/04_TASK_AUTHORIZATION_FIRESTORE.md` | Tenant/site/operator access | A schedule, event, completion and issue are readable or mutable only by the intended tenant roles. |
| P0-07 | `docs/review/current-review-2026-08-02/waste-segregation-current-review-2026-08-02/09_TASK_OFFLINE_QUEUE_PRIVACY.md` | Event evidence privacy | Consent, retention, deletion and offline recovery apply to any event evidence before it is captured. |
| P1-01 to P1-03 | `docs/review/current-review-2026-08-02/waste-segregation-current-review-2026-08-02/06_TASK_POLICY_TAXONOMY_SWM2026.md` | Four-stream, provenance and conservative safety | Each schedule/event is bound to the canonical stream and verified policy facts; unavailable scheduling cannot weaken safe handling. |
| P1-04 to P1-05 | `docs/review/current-review-2026-08-02/waste-segregation-current-review-2026-08-02/07_TASK_SOCIETY_POLICY_AUTHORITY.md` | Site operational detail | A society may add a reviewed pickup window or internal location but cannot replace statutory stream/safety guidance or self-verify it. |
| P1-06 to P1-07 | `docs/review/current-review-2026-08-02/waste-segregation-current-review-2026-08-02/08_TASK_RUNTIME_ARCHITECTURE_CONVERGENCE.md` | Reliable event effects | Retry, offline sync and notification paths cannot create duplicate completion, issue, training or reward effects. |
| P1-08 | This file: `docs/review/current-review-2026-08-02/waste-segregation-current-review-2026-08-02/12_TASK_PRODUCT_WEDGE_BWG.md` | Product contract | One recurring buyer/job/non-goal contract preserves the pre-handover position. |
| P1-09 | This file: `docs/review/current-review-2026-08-02/waste-segregation-current-review-2026-08-02/12_TASK_PRODUCT_WEDGE_BWG.md` | Area and operator workflow | A design partner can move from a source-qualified next action to preparation, outcome and issue closure. |
| P1-10 | This file: `docs/review/current-review-2026-08-02/waste-segregation-current-review-2026-08-02/12_TASK_PRODUCT_WEDGE_BWG.md` | Processor handoff boundary | An integration can receive evidence and observed outcome state without making this product the collector. |
| P1-11 | `docs/review/current-review-2026-08-02/waste-segregation-current-review-2026-08-02/13_TASK_GTM_SALEABILITY.md` | PMF test | A qualified buyer validates that recurring schedule/event completion reduces a costly, repeated pre-handover problem. |
| P2-02 | `docs/review/current-review-2026-08-02/waste-segregation-current-review-2026-08-02/16_TASK_ANALYTICS_EVAL_EVIDENCE.md` | Measurement | Exposure, schedule availability, event outcome and paid-pilot facts are attributable and do not rely on client-only claims. |

## Anything else?

The code's society policy layer should not be the first buyer-facing feature. Daily checks, evidence and issue closure create value even before custom society rules are mature. The existing city-level schedule maps also must not be mistaken for the recurring core: area provenance and observed completion are the missing product contract.
