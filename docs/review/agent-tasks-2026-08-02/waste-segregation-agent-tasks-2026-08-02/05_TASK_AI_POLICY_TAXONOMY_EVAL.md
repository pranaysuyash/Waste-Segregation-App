> **Review baseline:** `pranaysuyash/Waste-Segregation-App`, branch `main`, commit `d7a9c73f75779ddcbf9f22f4ce2fba9a0280b171`
>
> **Remote commit date:** 2026-05-25
>
> **Review date:** 2026-08-02
>
> **Hard limitation:** This review does not include local, uncommitted, or unpushed work. Run `02_TASK_LOCAL_CHANGE_RECONCILIATION.md` before implementing any other task. Existing local work is authoritative where it is newer and intentional.

# Task: AI Taxonomy, Local Policy and Evaluation

## Priority

P1 after P0 trust work. Required before a credible pilot.

## Objective

Align the classification system with Solid Waste Management Rules, 2026, establish one canonical schema, and create an evaluation gate based on reviewed real images and safety-weighted errors.

## Regulatory baseline

From 1 April 2026, the national framework uses four source-segregation streams:

1. wet waste;
2. dry waste;
3. sanitary waste;
4. special-care waste.

The current repository largely uses Wet, Dry, Hazardous and Medical categories and carries BBMP 2024 provenance. This must be migrated deliberately rather than renamed casually.

## Primary files

- `functions/src/classify_image.ts`
- `lib/services/ai_service.dart`
- `lib/services/enhanced_ai_api_service.dart`
- `lib/services/providers/**`
- `lib/services/local_policy_engine.dart`
- `lib/services/local_guidelines_plugin.dart`
- `lib/services/city_policy_data.dart`
- `lib/services/local_policy_rule_packs.dart`
- `lib/models/waste_classification.dart`
- `eval/classification/**`
- prompts and parsers
- classification/result screens
- analytics schema

## Canonical model

Separate three concepts:

### 1. Regulatory stream

```text
wet
dry
sanitary
special_care
not_solid_waste
unknown
```

### 2. Material/item taxonomy

Examples:

- food residue;
- paper;
- PET;
- multilayer packaging;
- diaper;
- expired medicine;
- battery;
- broken lamp;
- sharp;
- e-waste.

### 3. Handling attributes

- clean/dry;
- contaminated;
- sharp;
- leaking;
- pressurised;
- infectious;
- mercury-containing;
- requires authorised drop-off;
- requires wrapping;
- uncertain.

Do not overload one category field with all three concepts.

## Safety model

Define severity by error type.

Examples:

- battery classified as ordinary dry waste: hard fail;
- used needle classified as dry waste: hard fail;
- sanitary item classified as dry recyclables: hard fail;
- clean PET subcategory mismatch: warning if stream remains correct;
- wording/formatting difference: non-blocking unless instructions become unsafe.

## Work breakdown

### T1. Produce taxonomy decision record

Create:

`docs/architecture/ADR_SWMR_2026_CLASSIFICATION_TAXONOMY.md`

Include:

- official source and effective date;
- canonical enum values;
- aliases for old data;
- migration mapping;
- unsupported/ambiguous cases;
- city-specific override boundaries;
- version identifier, for example `in-swm-2026-v1`.

### T2. Migrate the schema

Add explicit fields:

- `regulatoryStream`
- `materialCategory`
- `handlingFlags`
- `policyPackId`
- `policyVersion`
- `policyVerifiedAt`
- `taxonomyVersion`
- `modelProvider`
- `modelVersion`
- `promptVersion`
- `confidence`
- `uncertaintyReason`
- `requiresUserConfirmation`

Maintain a temporary compatibility adapter for historical records. Do not make old aliases the new core.

### T3. Update prompts and parser

The model should:

- identify visible evidence;
- distinguish object recognition from legal disposal guidance;
- return `unknown` when evidence is insufficient;
- avoid inventing local collection schedules;
- return safety flags conservatively;
- expose alternatives and clarification questions;
- never treat confidence as calibrated unless calibration is measured.

### T4. Update local policy packs

- replace BBMP 2024 labels with a verified SWM 2026 pack;
- record authority, source URL, effective date and review date;
- support national baseline plus local overlay;
- do not hard-code unsupported collection schedules;
- create a policy update process and owner;
- add tests for all four streams and special handling.

### T5. Build a real-image golden set

Minimum initial set should cover:

- each four-stream class;
- common household items;
- soiled vs clean packaging;
- mixed-material items;
- transparent/reflective/low-light images;
- multiple objects;
- ambiguous items;
- medicines;
- batteries;
- bulbs;
- sharps;
- diapers/sanitary products;
- e-waste;
- non-waste images;
- adversarial or irrelevant images.

Every case needs:

- image rights/provenance;
- reviewer;
- label source;
- review status;
- safety severity;
- expected stream;
- acceptable alternatives;
- must-not outputs.

Synthetic descriptions can supplement, not replace, real visual evidence.

### T6. Calibrate and gate

Report:

- per-stream precision/recall;
- confusion matrix;
- safety-critical false negatives;
- abstention rate;
- user-confirmation rate;
- provider latency and cost;
- policy-application errors;
- performance by image quality and language.

Recommended release rule:

```text
Ship only if:
- zero known safety-critical must-not violations in the release set;
- no regression beyond the approved class-specific threshold;
- schema validity is 100%;
- policy provenance is present;
- unknown/abstain behaviour remains within target range.
```

Do not gate solely on one aggregate score.

### T7. Human-in-the-loop workflow

For uncertain or high-risk outputs:

- require user confirmation;
- show visible evidence and the reason for uncertainty;
- offer safe handling while uncertain;
- capture correction separately from ground truth;
- route candidate to review;
- do not automatically train on the correction.

### T8. Align analytics

Track:

- predicted stream;
- corrected stream;
- confidence band;
- uncertainty reason;
- policy pack;
- model/prompt/taxonomy version;
- safety flag;
- escalation;
- latency;
- cost;
- cache hit;
- user confirmation.

Do not log raw image or sensitive label text without consent.

## Required tests

- schema contract tests;
- parser malformed-output tests;
- old-record migration tests;
- all four-stream policy tests;
- must-not safety tests;
- low-confidence abstention tests;
- multiple-object behaviour;
- provider fallback equivalence;
- local-policy provenance;
- language consistency;
- real-image regression suite.

## Acceptance criteria

- Four-stream taxonomy is canonical across backend, client, UI and analytics.
- Historical records remain readable.
- Policy provenance is current and visible.
- Real-image golden data exists and is reviewed.
- Safety-critical must-not violations are blocking.
- Uncertain high-risk outputs do not silently produce confident disposal advice.
- A release report compares the candidate against the approved baseline.

## Deferred work

On-device inference is a separate model-delivery project. Do not advertise it or route production users to placeholder output. Start it only after the cloud/policy eval harness can evaluate a local candidate against the same dataset.
