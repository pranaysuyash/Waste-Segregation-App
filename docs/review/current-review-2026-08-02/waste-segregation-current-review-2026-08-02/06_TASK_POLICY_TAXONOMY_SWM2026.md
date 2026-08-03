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

# Task: SWM Rules 2026 Policy and Taxonomy

## Priority

P1, but required before any compliance claim or paid BWG pilot.

## Objective

Separate item/material recognition from the legally relevant four-stream disposal model and establish verified, versioned policy sources.

## Feedback-driven implementation update (2026-08-02)

- Low-confidence municipal policy is now still evaluated instead of being skipped, while non-safety violations are softened to warnings.
- Safety-critical category patterns are held as violations even under low confidence.
- This is a partial safety-hardening step toward the SWM 2026 conservative policy model, but the full taxonomy migration (`wet`, `dry`, `sanitary`, `special_care`) is still pending.

## PMF recurring-core policy boundary (2026-08-03)

The feedback identifies area collection schedules, pickup events and a completion
layer as the recurring-use hypothesis. This task owns the policy facts that can
make a schedule safe to show. It does not own calendar UI, reminders, an event
lifecycle, collector operations or a completion claim.

In the master plan, this file owns P1-01 through P1-03: canonical streams,
reviewed policy provenance and conservative handling under uncertainty. Those
three task IDs are prerequisites for the P1-08 through P1-10 workflow scope in
`12_TASK_PRODUCT_WEDGE_BWG.md`.

Static source inspection finds a generic city/category `collectionSchedule` map
in `lib/services/city_policy_data.dart`, which
`lib/services/local_policy_engine.dart` consumes. It has neither the
area-specific provenance nor the four-stream migration required here. Per
`20_TASK_CHATGPT_FEEDBACK_PMFMODEL_AND_CONFIDENCE_HARDENING_2026-08-02.md`,
area calendars, events and the completion layer are design-only, not current
implementation.

### Policy-to-product boundary

| PMF layer | This task owns | Linked task owner | Required acceptance boundary |
|---|---|---|---|
| Area collection schedule | The stream binding, area scope, source reference, policy-pack/version, effective window and review status of a schedule fact. | P1-08/P1-09 in `12_TASK_PRODUCT_WEDGE_BWG.md` own the displayed next action and workflow. | An absent, stale or unreviewed fact produces `unavailable`, not an inferred local pickup window. |
| Pickup event | The event's canonical stream and reference to the schedule/policy fact. | P1-09 in `12_TASK_PRODUCT_WEDGE_BWG.md` owns state transitions; P1-07 in `08_TASK_RUNTIME_ARCHITECTURE_CONVERGENCE.md` owns idempotent effects. | No event state can reclassify a stream, erase a safety flag or claim collection occurred. |
| Completion layer | Conservative handling when a schedule or exact local instruction is unknown. | P1-10 in `12_TASK_PRODUCT_WEDGE_BWG.md` owns observed-outcome handoff; P0-07 in `09_TASK_OFFLINE_QUEUE_PRIVACY.md` owns evidence treatment. | A user/operator outcome remains an attributed observation, never policy verification or official proof. |

### Schedule-fact contract for the future policy projection

When a reviewed policy pack contains a schedule, its projected fact needs:

```text
areaRef
regulatoryStream
serviceWindow
scheduleSourceRef
policyPackId
policyVersion
scheduleEffectiveDate
scheduleVerifiedAt
scheduleReviewStatus
```

These are schedule facts, not pickup events. A future operational event may
reference them, but `pickupCompleted`, collector identity and outcome evidence
must not be written into or inferred from the policy pack.

## Current problem

The new material taxonomy is useful but does not replace a regulatory stream model.

Current top-level categories still include old concepts such as hazardous and medical waste. Official SWM Rules 2026 mandate:

- wet;
- dry;
- sanitary;
- special-care.

The production BBMP pack remains `BBMP-2024.1`, and its source manifest has no verification hashes or dates.

## Canonical schema

Add explicit fields:

```text
recognisedItem
materialFamily
materialCategory
regulatoryStream
handlingFlags
jurisdiction
policyPackId
policyVersion
policyEffectiveDate
policyVerifiedAt
taxonomyVersion
model/prompt/schema versions
confidence/uncertainty
```

For a schedule-enabled policy projection, retain the separate schedule-fact
contract above. Do not overload `regulatoryStream`, `policyVersion` or a
free-text local instruction to imply an exact area window or pickup outcome.

Canonical stream enum:

```text
wet
dry
sanitary
special_care
non_solid_waste
unknown
```

`hazardous`, `medical`, `battery`, `medicine`, `sharp`, `e-waste` become material/handling concepts mapped primarily to `special_care`, subject to official exceptions.

## Commit units

### Commit 1: ADR and migration map

Create ADR:

- official sources;
- effective date;
- stream definitions;
- old-to-new mapping;
- ambiguity rules;
- city overlay boundary;
- data migration;
- UI implications;
- analytics versioning.

### Commit 2: schema migration

- add regulatory stream;
- preserve old records through adapter;
- migrate historical category values;
- never silently default missing category to `Dry Waste`;
- add `unknown`/manual review path;
- version JSON/Hive/Firestore schema.

### Commit 3: prompts/parsers/backend contracts

Require the model to return:

- visible item evidence;
- material;
- regulatory stream;
- handling flags;
- uncertainty;
- alternatives;
- clarification;
- safe interim handling.

The backend, client parser and eval schema must agree.

### Commit 4: conservative safety under uncertainty

Low confidence should not skip safety.

Policy model:

- uncertain identity -> conservative handling flags;
- suspected sharp/battery/medicine/chemical -> special-care interim guidance;
- user confirmation before ordinary-bin disposal;
- policy can abstain from exact local schedule while still giving safe containment advice.

Safety rules must be non-demotable where the consequence of a miss is high.

### Commit 5: verified policy packs

For production packs:

- source must be official or reviewed authoritative;
- record retrieved content hash/ETag;
- reviewer and date;
- effective/expiry/review date;
- trust tier;
- scope;
- unsupported claims removed.

For a pack that exposes an area collection schedule, also record:

- area scope rather than a city-wide assumption;
- stream-specific service window and effective dates;
- schedule source reference, reviewer and review status;
- an explicit unavailable/stale state;
- the distinction between a policy schedule fact and an observed pickup outcome.

Do not generate a local reminder or expected pickup event from an unreviewed
schedule fact. A city-level frequency alone is insufficient for an exact
area-level window.

Do not mark a pack production when `lastVerified` is null.

### Commit 6: real-image evaluation

Create reviewed cases for:

- all four streams;
- clean versus contaminated packaging;
- sanitary items;
- batteries/lamps/paint/medicines/sharps;
- mixed objects;
- ambiguous/no-waste;
- low light/blur;
- multilingual instructions;
- local policy overlays.

Gate:

- zero known safety must-not violations;
- class-specific precision/recall;
- abstention;
- policy correctness;
- provenance completeness;
- latency/cost.

## Acceptance criteria

- four streams are canonical across app/backend/policy/analytics;
- material taxonomy remains a separate useful dimension;
- historical records remain readable;
- policy sources are verified and versioned;
- uncertainty cannot suppress safe handling;
- real-image evaluation blocks safety regressions;
- “SWM 2026” appears in marketing only after this gate and domain/legal review.
- any future area schedule is stream-bound, source-qualified, effective-dated and visibly reviewable, or unavailable;
- missing schedule data preserves conservative containment guidance rather than defaulting to ordinary disposal;
- a policy pack cannot store or imply a pickup-completed outcome, collector performance or official completion proof;
- the PMF workflow links to P1-08 to P1-10 in `12_TASK_PRODUCT_WEDGE_BWG.md` without turning policy data into a collector workflow.

## Anything else?

The app's pricing documents use “EPR compliance.” Replace this with the exact applicable concept, such as Extended Bulk Waste Generator Responsibility, only after the product actually supports the required workflow. A recurring schedule and user-reported completion loop is not, by itself, a municipal, processor or statutory compliance claim.
