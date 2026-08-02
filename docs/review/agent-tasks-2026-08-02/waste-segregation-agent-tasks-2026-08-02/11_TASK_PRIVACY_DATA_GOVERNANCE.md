> **Review baseline:** `pranaysuyash/Waste-Segregation-App`, branch `main`, commit `d7a9c73f75779ddcbf9f22f4ce2fba9a0280b171`
>
> **Remote commit date:** 2026-05-25
>
> **Review date:** 2026-08-02
>
> **Hard limitation:** This review does not include local, uncommitted, or unpushed work. Run `02_TASK_LOCAL_CHANGE_RECONCILIATION.md` before implementing any other task. Existing local work is authoritative where it is newer and intentional.

# Task: Privacy, Consent, Retention and Training Data Governance

## Priority

P0 for image/evidence storage and child/family use. P1 for training-data growth.

## Objective

Create a data system that can explain why each datum exists, who can access it, how long it remains, how it is deleted, and whether it may be used for analytics, product operations or model training.

## Regulatory context

India notified the Digital Personal Data Protection Rules, 2025, with principles including consent/transparency, purpose limitation, minimisation, accuracy, storage limitation, security safeguards and accountability. The product also contemplates families, schools and children, increasing the need for verifiable parental consent and conservative defaults.

This task is an engineering and product-control plan, not legal advice. Obtain counsel before claiming compliance.

## Data classes

Create a complete inventory for:

- account/profile;
- authentication;
- raw waste images;
- site evidence images;
- classification result;
- correction/feedback;
- location;
- family membership and invitations;
- organisation/site membership;
- analytics;
- billing;
- support;
- training candidates;
- reviewed labels;
- model/eval datasets;
- exports and backups;
- logs.

## Purpose separation

A user image captured to answer a classification request is not automatically authorised for:

- history;
- community sharing;
- site evidence;
- analytics;
- support debugging;
- model evaluation;
- model training.

Represent these as separate purposes and consent choices.

## Consent record

Store:

- user/guardian;
- purpose;
- policy version;
- notice version;
- granted/withdrawn timestamp;
- region;
- capture surface;
- evidence of verifiable parental consent where required;
- deletion effect;
- processing status.

Never infer training consent from generic terms acceptance.

## Retention matrix

Create `docs/privacy/DATA_RETENTION_MATRIX.md`.

Example categories:

| Data | Default retention | Owner control | Training eligible |
|---|---|---|---|
| transient classification image | delete after response or short failure window | explicit history opt-in | no |
| user history image | user-selected | delete item/account | separate opt-in |
| organisation audit evidence | contractual period | organisation policy | no by default |
| correction metadata | defined product period | delete/withdraw | candidate only |
| training candidate | limited review window | consent withdrawal | yes only after review |
| billing ledger | statutory/contractual | restricted | no |

Do not copy example periods without legal and buyer validation.

## Privacy pipeline for images

Before persistence:

- strip EXIF;
- detect/reject or redact faces;
- detect address, receipt, medicine label and other sensitive text;
- calculate retention class;
- encrypt in transit and at rest;
- store private object reference;
- log purpose and consent;
- prevent public sharing by default.

For unsafe-to-retain images, classification can still be performed transiently where policy permits, then deleted.

## Training-data lifecycle

```text
captured for classification
  -> explicit training consent?
  -> privacy scan
  -> candidate
  -> human review
  -> accepted/rejected/redacted
  -> frozen dataset version
  -> model/eval linkage
  -> revocation/deletion propagation
```

A user correction is evidence, not ground truth.

Every dataset version needs:

- immutable manifest;
- rights and consent status;
- label provenance;
- reviewer;
- exclusions;
- known bias;
- class distribution;
- intended use;
- revocation mechanism;
- model versions trained/evaluated on it.

## Child/family safeguards

- do not build behavioural advertising for child users;
- separate guardian and child roles;
- obtain verifiable guardian consent before processing child personal data where required;
- minimise display name/avatar exposure;
- prevent public community sharing by default;
- provide guardian deletion and export;
- avoid precise location retention.

## Account deletion

Build and test a deletion orchestrator covering:

- Auth;
- user document;
- subcollections;
- organisation memberships;
- family/invitations;
- images;
- analytics identifiers where deletion is required;
- training candidates;
- exports;
- support attachments;
- billing state where retention is legally required;
- backups and delayed deletion.

Return a deletion receipt with completed, retained-with-basis and pending items.

## Incident readiness

- data-flow diagram;
- access logging;
- breach detection;
- incident runbook;
- contact and escalation;
- object-access audit;
- secret rotation;
- user notification decision process.

## Required tests

- consent not granted;
- consent withdrawn;
- image deleted before review;
- accepted training item later revoked;
- child account without guardian consent;
- organisation retention expiry;
- account deletion with partial provider failure;
- re-run deletion idempotently;
- non-owner object access;
- logs do not contain raw image/base64/PII.

## Acceptance criteria

- Every stored field/object has a declared purpose and retention class.
- Training use requires separate explicit consent.
- Raw images are private and metadata-stripped.
- Child/family defaults are conservative.
- Deletion is complete, idempotent and auditable.
- Dataset manifests support revocation propagation.
- Privacy notices describe actual system behaviour.
