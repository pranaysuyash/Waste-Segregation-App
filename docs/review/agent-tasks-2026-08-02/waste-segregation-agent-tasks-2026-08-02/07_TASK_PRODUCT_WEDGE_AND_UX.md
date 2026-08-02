> **Review baseline:** `pranaysuyash/Waste-Segregation-App`, branch `main`, commit `d7a9c73f75779ddcbf9f22f4ce2fba9a0280b171`
>
> **Remote commit date:** 2026-05-25
>
> **Review date:** 2026-08-02
>
> **Hard limitation:** This review does not include local, uncommitted, or unpushed work. Run `02_TASK_LOCAL_CHANGE_RECONCILIATION.md` before implementing any other task. Existing local work is authoritative where it is newer and intentional.

# Task: Product Wedge and User Experience

## Priority

P1 for a paid pilot.

## Objective

Replace the broad “AI recycling super-app” scope with one clear buyer, one repeated job and one measurable promise.

## Product decision

The scanner is a feature.

The initial product should be:

> A segregation-assurance and evidence system for Bengaluru Bulk Waste Generators, with a resident/staff scanning surface and an operator dashboard.

## Personas

### Buyer

- apartment association/management committee;
- school or campus administrator;
- hotel/restaurant operations head;
- facility manager;
- authorised waste processor or compliance service provider.

### Operator

- housekeeping supervisor;
- waste-room attendant;
- sustainability manager;
- vendor manager.

### End user

- resident;
- student;
- employee;
- kitchen/housekeeping staff.

Do not force one UI to serve all three roles.

## Core jobs

### Buyer job

“Show me whether segregation is improving and give me evidence I can use for compliance and vendor management.”

### Operator job

“Help my team resolve uncertain items quickly and record contamination without paperwork.”

### End-user job

“Tell me the correct stream in seconds and teach me the rule I keep getting wrong.”

## MVP user journeys

### Journey 1: uncertain-item scan

1. open camera;
2. capture one item;
3. receive four-stream result;
4. see handling instruction and confidence;
5. confirm or correct;
6. optionally attach site/bin context;
7. save evidence.

Target: no forced account creation before the first useful result unless policy requires it.

### Journey 2: daily site check

1. operator selects site/area;
2. records four-stream bin status;
3. photographs contamination or issue;
4. assigns action;
5. closes or escalates issue;
6. dashboard updates.

### Journey 3: micro-training

1. user sees a recurring error;
2. gets one short local rule;
3. answers a one-step check;
4. later behaviour is measured.

### Journey 4: buyer report

1. buyer selects date/site;
2. sees completion, contamination and unresolved issues;
3. reviews evidence;
4. exports report;
5. compares vendor or block performance.

## What to remove or hide

Until proven:

- generic community feed as primary navigation;
- unrelated challenges;
- premium features that are placeholders;
- token-wallet complexity in the main journey;
- multiple upgrade rails;
- broad city selector without verified policy coverage;
- unsupported impact/carbon numbers;
- developer toggles in production;
- “production-ready” claims.

## Information architecture

Recommended primary navigation by role.

### End user

- Scan
- Learn
- History

### Operator

- Today
- Check
- Issues
- Training

### Buyer/admin

- Overview
- Sites
- Reports
- People
- Settings

Role-switching should be explicit.

## Trust design

Result screen must show:

- regulatory stream;
- what evidence the model saw;
- local handling rule;
- policy version/source;
- confidence or uncertainty;
- “not sure”/correction action;
- safety warning before any reward copy.

Do not let gamification visually outrank safety.

## Premium/product truth task

For every visible feature, create a capability status:

- implemented and tested;
- beta;
- pilot-only;
- disabled;
- planned.

Production UI may show only implemented/tested capabilities as current value. Planned capability can appear only as clearly labelled roadmap research, not as a paid entitlement.

## Accessibility and multilingual requirements

Initial languages:

- English;
- Kannada;
- Hindi.

For every Kannada string, maintain native script and a reviewable transliteration glossary for QA. Do not machine-translate safety instructions without human review.

Test:

- large text;
- screen reader labels;
- camera permission denial;
- poor connectivity;
- colour-independent stream cues;
- one-handed use;
- low-light capture guidance.

## User research protocol

Run task-based tests with:

- 5 residents;
- 5 housekeeping/operators;
- 5 buyer/admin stakeholders.

Measure:

- first-result completion;
- time to correct stream;
- confidence understanding;
- correction discoverability;
- daily-check completion;
- report comprehension;
- willingness to use weekly;
- objection to image capture.

## Acceptance criteria

- One signed product brief defines buyer, operator, user, promise and non-goals.
- The first session reaches a useful result with minimal friction.
- Operator workflow can be completed without consumer gamification.
- Buyer report answers a real compliance/operations question.
- Every visible paid claim is implemented.
- Safety, uncertainty and policy source are understandable.
- Usability evidence is captured and ranked by severity.

## Handoff artifacts

- `docs/product/BWG_PRODUCT_BRIEF.md`
- `docs/product/ROLE_JOURNEYS.md`
- `docs/product/MVP_SCREEN_CONTRACTS.md`
- `docs/research/USABILITY_FINDINGS.md`
- annotated screenshots or recordings
- prioritised UX defects linked to task IDs
