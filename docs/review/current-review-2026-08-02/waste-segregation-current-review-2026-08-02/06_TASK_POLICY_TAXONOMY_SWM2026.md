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

## Anything else?

The app's pricing documents use “EPR compliance.” Replace this with the exact applicable concept, such as Extended Bulk Waste Generator Responsibility, only after the product actually supports the required workflow.
