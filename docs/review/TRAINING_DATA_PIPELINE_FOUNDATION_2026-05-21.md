# Training Data Pipeline Foundation

Date: 2026-05-21

## Decision

WasteWise must not silently retain user images or corrections for model
training. Training use is a separate permission from app history, cloud sync,
analytics, or a generic privacy-policy checkbox.

No training image enters a dataset unless:

- user training consent exists;
- the consent policy version is captured;
- the record can be deleted or excluded later;
- label and provenance are tracked;
- PII/image safety risk is handled;
- dataset versions are frozen and reproducible.

## Consent UX

Recommended copy:

```text
Help improve waste recognition

Allow us to use your submitted waste photos and corrections to improve our
classification models.

We will:
- use photos only for waste-recognition improvement
- remove account identifiers from training records
- let you turn this off anytime
- let you request deletion of your contributed training data

[Allow] [Not now]
```

Children/family child profiles remain off by default. They require a future
guardian flow before collection.

Canonical profile field:

```json
{
  "trainingConsent": {
    "enabled": false,
    "policyVersion": "training-data-v1",
    "grantedAt": null,
    "revokedAt": null,
    "source": null
  }
}
```

Implemented default: `TrainingConsent.disabled()` in
`lib/models/user_profile.dart`.

## Collections

App history and training data are separated:

```text
users/{uid}/classifications/{classificationId}
training_candidates/{candidateId}
training_labels/{candidateId}
training_dataset_versions/{datasetVersion}
```

`admin_classifications` is legacy/admin-only and must not be used for silent ML
collection.

## Candidate Schema

`training_candidates/{candidateId}`:

```json
{
  "candidateId": "candidate_hash",
  "userIdHash": "server-side-hmac(uid)",
  "classificationId": "source-classification-id",
  "consent": {
    "enabledAtCapture": true,
    "policyVersion": "training-data-v1",
    "consentSnapshotId": "..."
  },
  "image": {
    "storagePath": null,
    "thumbnailPath": null,
    "contentHash": "...",
    "perceptualHash": null,
    "mimeType": null,
    "width": null,
    "height": null,
    "exifStripped": null,
    "redactionStatus": "not_collected_metadata_only",
    "rawRetentionDays": 0
  },
  "modelPrediction": {
    "provider": "openai|gemini|backend|local",
    "model": "...",
    "itemName": "...",
    "category": "...",
    "subcategory": "...",
    "confidence": 0.82
  },
  "userFeedback": null,
  "review": {
    "status": "unreviewed",
    "reviewer": null,
    "reviewedAt": null,
    "qualityFlags": [],
    "piiFlags": []
  },
  "dataset": {
    "eligible": false,
    "includedInVersions": []
  },
  "deletion": {
    "requested": false,
    "requestedAt": null,
    "deletedAt": null,
    "excludedFromTrainingAt": null
  }
}
```

`training_labels/{candidateId}`:

```json
{
  "candidateId": "...",
  "rawPrediction": {},
  "userCorrection": null,
  "reviewerVerified": null,
  "labelState": "raw_prediction"
}
```

## Image Pipeline

Phase 1 is metadata-only. No training image upload is enabled yet.

Planned image path:

```text
source image
  -> strip EXIF
  -> quality gate
  -> PII/safety scan
  -> compressed normalized copy
  -> training/review/{candidateId}.jpg
  -> training/approved/{candidateId}.jpg or training/rejected/{candidateId}.json
```

Retention:

- raw original: do not keep by default; if needed for review, max 30 days;
- review image: until approved/rejected/deletion request;
- approved processed image: until consent revoked or dataset retired;
- rejected: metadata-only, no image.

## Review States

Allowed candidate review states:

```text
unreviewed
approved
rejected
needs_redaction
golden
training_eligible
deleted
```

Label states:

```text
raw_prediction
user_corrected
reviewer_verified
policy_verified
golden
training_eligible
```

Model prediction is not ground truth. User correction is a candidate label, not
automatic ground truth.

## App Integration

Implemented foundation:

- `ResultPipeline.processClassification()` saves app history first, then
  best-effort enqueues a training candidate only if `trainingConsent.enabled`
  is true.
- `ResultPipeline.saveClassificationOnly()` uses the same consent-gated enqueue.
- `ResultPipeline.submitFeedback()` stores feedback first, then best-effort
  attaches it to the training label candidate.
- Failures in training enqueue/label attach do not block classification or
  feedback flows.
- Child profiles are skipped until a guardian flow exists.

Cloud Functions own training writes:

- `enqueueTrainingCandidate`
- `attachTrainingLabelFeedback`
- `revokeTrainingConsent`

Firestore rules deny direct client access to `training_*` collections.

## Deletion And Revocation

Revocation must:

- disable future collection;
- mark existing candidates as deletion requested;
- set `deletedAt` and `excludedFromTrainingAt`;
- set `dataset.eligible = false`;
- move review status to `deleted`;
- remove pending/review images when image upload is enabled;
- exclude revoked rows from future manifests.

Implemented scaffold:

- `TrainingDataService.revokeConsentAndRequestDeletion()`
- callable `revokeTrainingConsent`
- dataset exporter excludes revoked/deleted rows.

## Dataset Versioning

Do not train from live Firestore queries.

Frozen bundle shape:

```text
datasets/waste-v0.1/manifest.jsonl
datasets/waste-v0.1/labels.jsonl
datasets/waste-v0.1/datasheet.md
```

Every model should record:

```text
modelVersion -> datasetVersion -> codeVersion -> promptVersion/evalVersion
```

Implemented offline scaffold:

```bash
python3 tools/training_dataset_export.py \
  --candidates-jsonl exports/training_candidates.jsonl \
  --labels-jsonl exports/training_labels.jsonl \
  --dataset-version waste-v0.1 \
  --out datasets/waste-v0.1 \
  --dry-run
```

Default exporter exclusions:

- no consent;
- revoked or deleted;
- rejected;
- PII-flagged;
- redaction not passed;
- unreviewed unless explicitly allowed.

## Future Local/Small VLM Plan

Do not fine-tune first. Build an eval harness first:

1. Collect metadata-only candidates behind consent.
2. Add opt-in processed image upload after EXIF stripping and PII scan.
3. Build review queue and produce `golden` labels.
4. Export `waste-v0.1` as a frozen evaluation dataset.
5. Compare prompt/model/routing changes against the golden set.
6. Only after enough reviewed examples exist, evaluate small local VLM
   fine-tuning or classifier-head training.

## Incremental Implementation Status (2026-05-21)

- Phase 1 (metadata pipeline): implemented.
- Phase 2 (opt-in image upload): implemented for consented users via client
  normalized JPEG payload, EXIF stripping by re-encode, and server upload to
  `training/review/{yyyy}/{mm}/{candidateId}.jpg`.
- Phase 3 (review queue): scaffolded with callable-backed queue retrieval and
  status mutation (`getTrainingReviewQueue`, `reviewTrainingCandidate`) plus
  in-app developer review screen access.
- Deletion/revocation behavior: callable revocation and `deleted` review
  actions now mark candidates excluded and attempt to remove review images from
  storage.
- Retention cleanup scaffold: scheduled function `cleanupTrainingReviewImages`
  runs daily and delegates to reusable helper `runTrainingReviewCleanup`; the
  helper is now emulator-tested against old deleted/rejected candidates.
- Reviewer audit trail: moderation/revocation actions are recorded in
  `training_review_audit` with actor, action, candidate/status context, and
  timestamp.

## Risks

- `TRAINING_DATA_HMAC_SECRET` must be configured before production deployment;
  otherwise functions use a dev fallback and log a warning.
- OCR/face/person detection is still heuristic-only; production must replace
  this with stronger CV/OCR moderation before broad rollout.
- Admin review should rely on strict admin claims in production; non-admin
  review override is emulator-only.
- Production env controls needed:
  - `TRAINING_DATA_HMAC_SECRET` (required)
  - `TRAINING_REVIEW_RETENTION_DAYS` (optional, default `30`)
  - `ALLOW_TRAINING_REVIEW_NON_ADMIN` should remain unset in production
- Existing historical docs still contain old ML-preservation language in
  archived sections; current policy pointers were added to the active risky
  docs.

## Tests Required

Current validation should cover:

- user profile default training consent is false;
- training collections exist in schema registry;
- direct client rules deny `training_*` collections;
- functions compile;
- training-data helper tests run in `functions/test/training_data.test.js`;
- emulator callable lifecycle test:
  `npm run test:training-data:emulator` (`enqueue -> queue(admin gate) -> review -> revoke`);
- dataset exporter dry-run excludes unsafe rows.

Next tests to add:

- callable emulator tests for consent enabled/disabled;
- revocation callable marks candidate deletion fields;
- image upload pipeline strips EXIF and rejects PII/unsafe images;
- dataset exporter golden fixtures for every exclusion reason.
