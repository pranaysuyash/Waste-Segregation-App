> **Review baseline:** `pranaysuyash/Waste-Segregation-App`, branch `main`, commit `d7a9c73f75779ddcbf9f22f4ce2fba9a0280b171`
>
> **Remote commit date:** 2026-05-25
>
> **Review date:** 2026-08-02
>
> **Hard limitation:** This review does not include local, uncommitted, or unpushed work. Run `02_TASK_LOCAL_CHANGE_RECONCILIATION.md` before implementing any other task. Existing local work is authoritative where it is newer and intentional.

# Task: Bengaluru Bulk Waste Generator Compliance MVP

## Priority

P1 after core trust and taxonomy.

## Objective

Build the minimum organisation/site product that a Bengaluru Bulk Waste Generator or authorised waste processor can pilot and pay for.

## Product boundary

This MVP is not:

- a waste pickup marketplace;
- a municipal filing portal replacement;
- an EPR platform;
- a full facility-management suite;
- a smart-bin hardware system.

It is a **segregation assurance, issue-resolution, training and evidence layer**.

## Regulatory workflow assumptions to validate

The national SWM Rules, 2026 establish four-stream source segregation and specific Bulk Waste Generator responsibilities. Local implementation and report formats must be verified with current official sources and pilot buyers before being labelled compliant.

Do not encode legal interpretation solely from an LLM or competitor website.

## Domain model

### Organisation

- ID;
- legal/display name;
- organisation type;
- billing owner;
- compliance contact;
- timezone;
- policy jurisdiction.

### Site

- address and ward;
- site type;
- BWG criteria/declared status;
- streams handled;
- processor/vendor;
- processing method;
- evidence-retention policy.

### Membership

Roles:

- owner;
- admin;
- compliance manager;
- operator;
- trainer;
- viewer.

### Evidence event

- immutable ID;
- site/area/bin;
- event type;
- timestamp;
- actor;
- four-stream result;
- image/object reference;
- classification provenance;
- correction;
- issue status;
- retention class.

### Issue

- contamination;
- missed segregation;
- unsafe item;
- overflow;
- vendor pickup;
- equipment failure;
- training need.

### Training event

- topic;
- audience;
- completion;
- quiz result;
- related issue/category;
- follow-up outcome.

## MVP modules

### 1. Organisation onboarding

- invite members;
- assign roles;
- create one or more sites;
- record policy jurisdiction;
- choose retention and consent settings.

### 2. Daily four-stream checklist

For each stream:

- available;
- labelled;
- contamination present;
- approximate volume;
- evidence photo;
- operator note;
- action required.

### 3. Uncertain-item assistant

Reuse the canonical classification gateway. Add site context and operator confirmation.

### 4. Issue management

- create from scan/check;
- assign;
- set due date;
- resolve with evidence;
- track recurrence.

### 5. Training recommendations

Use actual issue data to recommend micro-training. Do not generate generic content without linking it to observed failures.

### 6. Dashboard

Minimum metrics:

- checklist completion rate;
- contamination incidents per 100 checks;
- unresolved high-risk issues;
- repeated category errors;
- training completion;
- median resolution time;
- evidence coverage.

### 7. Export

Generate a verifiable report with:

- site;
- reporting period;
- policy/taxonomy version;
- event counts;
- issue summary;
- evidence references;
- unresolved items;
- generated timestamp;
- report hash/version.

Do not call it an official statutory return until a legal/domain review confirms the format.

## Multi-tenancy and security

- organisation ID must be derived from authorised membership, not trusted from client input;
- every query must be tenant scoped;
- object paths must include tenant and owner;
- audit log is append-only;
- deleted members lose access immediately;
- support access requires explicit audited impersonation or a separate admin tool.

## Offline behaviour

Operators may work in poor connectivity.

Support:

- local draft queue;
- deterministic client event IDs;
- conflict-safe sync;
- visible pending state;
- retry without duplicate evidence;
- no false “submitted” state.

This is different from offline AI classification. Do not conflate them.

## Pilot configuration

Support feature flags per organisation:

- classification;
- evidence photos;
- daily checklist;
- issues;
- training;
- export;
- notifications.

This allows a narrow pilot without exposing unfinished modules.

## Verification

### Automated

- tenant isolation;
- role permissions;
- duplicate event retry;
- offline queue;
- report generation;
- audit immutability;
- image retention;
- member removal;
- policy version in every result/report.

### Manual pilot script

1. create organisation and site;
2. invite operator;
3. complete daily check;
4. scan uncertain item;
5. create contamination issue;
6. assign and resolve;
7. complete training;
8. generate report;
9. remove operator;
10. prove operator cannot access data.

## Acceptance criteria

- A non-technical buyer can create a site and invite an operator.
- An operator can complete the daily workflow in the field.
- Every record is tenant isolated and attributable.
- Offline retry does not duplicate records.
- The dashboard measures behaviour, not vanity points.
- The export is traceable and versioned.
- At least one design partner confirms the workflow addresses a current operational job.

## Recommended initial integration strategy

Offer CSV/PDF export and a simple webhook/API before building custom municipal integrations. Integrate with authorised processors or apartment-management platforms only after one pilot proves the data contract.
