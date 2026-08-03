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

# Task: Society Policy Authority and Governance

## Priority

P1. Blocks society/BWG pilot.

## Objective

Keep the useful society-override abstraction while preventing private operational preferences from replacing statutory or safety guidance.

## Feedback-driven implementation update (from 2026-08-02)

- `LocalPolicyEngine.applyPolicy` no longer skips municipal policy entirely below the old 0.50 threshold.
- A confidence band now gates severity only:
  - < 0.70: warnings for non-safety outcomes
  - ≥ 0.70: normal severity
- Safety-critical municipal categories/visual signals stay as violations even at low confidence.
- Society overrides for city safety fields (bin color, collection frequency, disposal method, collection location) are now blocked when they weaken high-risk municipal guidance.
- A new conservative-warning message is added whenever policy is confidence-gated.

## Current contradictions

ADR says society rules are additive and cannot weaken city safety.

Implementation can replace disposal method/location, bin colour and schedule, then records the conflict while returning the mutated result.

The client service can set verification fields. No matching Firestore rules exist. Proximity math is invalid.

## Authority hierarchy

Define explicit levels:

1. national statutory rule;
2. state/local statutory rule;
3. authorised processor requirement;
4. site operational mapping;
5. user preference.

Lower levels may:

- add operational detail;
- map internal bin labels;
- add collection location;
- add stricter containment/training;
- record a conflict.

Lower levels may not:

- reclassify a statutory stream;
- remove a safety flag;
- replace authorised disposal with ordinary disposal;
- override legal packaging/containment;
- claim verification.

## Override types

Split current enum into:

### Safe operational additions

- internal bin label/colour alias;
- internal room/location;
- pickup window;
- custom instruction;
- banned item;
- contact/escalation.

### Controlled authoritative changes

- processor-accepted stream mapping;
- municipal exception;
- disposal method.

Controlled changes require a reviewed source and authority role, not normal society admin access.

## Commit units

### Commit 1: superseding ADR

Record:

- authority hierarchy;
- non-overridable fields;
- conflict semantics;
- verification roles;
- source requirements;
- fallback behaviour.

Do not rewrite the accepted ADR in place. Append/supersede per motto v4.

### Commit 2: immutable versioned policy model

```text
society_policy_drafts
society_policy_versions
society_policy_public_projection
policy_review_events
```

Published versions are immutable and effective-dated.

### Commit 3: server-side publication

Client submits draft.

Server validates:

- membership/role;
- base policy version;
- permitted override types;
- no weakened safety;
- source/approver;
- effective date.

Only server publishes and verifies.

### Commit 4: correct geospatial discovery

Use a standard geospatial library/index.

Do not implement custom sine/cosine/atan2 approximations.

Validate:

- antimeridian;
- poles;
- small radius;
- malformed coordinates;
- index/query completeness.

Or remove proximity discovery from MVP and use explicit society code/invitation.

### Commit 5: UI semantics

Show separate sections:

- statutory stream and safe handling;
- local/processor guidance;
- society internal instruction;
- conflict requiring administrator resolution.

Never tell an end user to choose between statutory safety and society preference.

### Commit 6: rules/tests

- only members read private policy;
- public projection contains no member/PII;
- admin creates draft;
- reviewer/server publishes;
- client cannot self-verify;
- society cannot weaken special-care handling;
- old policy remains auditable;
- expiry/review state visible.

## Acceptance criteria

- society additions cannot alter statutory stream or weaken safety;
- verification is server/reviewer controlled;
- policy versions are immutable and auditable;
- geospatial discovery is standard or removed;
- Firestore rules support the intended roles;
- conflicts stop unsafe mutation rather than merely logging it.

### Follow-up from this feedback cycle

- Still open: full immutable server-published society policy version tables.
- Still open: complete authority ladder mapping for facility > city > society with explicit exception fields.
- Still open: end-to-end server checks so clients cannot weaken safety by local config state.

## Anything else?

For the first pilot, an explicit site invite/code is safer and simpler than automatic nearby-society discovery. Keep proximity out until there is evidence users need it.
