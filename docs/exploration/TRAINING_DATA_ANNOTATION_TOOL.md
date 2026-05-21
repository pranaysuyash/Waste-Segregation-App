# Training Data Annotation Tool — Design Exploration

**Decision it unblocks**: What admin workflow to build (and when) for reviewing user-contributed training candidates before they enter model improvement pipelines.

**Key questions**:
- What review states does the reviewer workflow need beyond what exists in `review.status`?
- How do golden (eval), training-eligible, and needs-redaction interact as separate concerns?
- What format should the reviewer tool take given team size, budget, and existing infra?
- How do we export reviewed candidates into versioned dataset manifests?

**Kill criteria**: Existing pipeline (`training_data.ts`, `training_candidates` collection) is sufficient for MVP without a dedicated reviewer UI; a Firestore-console-driven manual review process may suffice for < 50 candidates.

**Status**: SEED — 2026-05-22

**Links**:
- [Backend addressables: data model](../EXPLORATION_TOPICS.md#12-classification-history-schema-)
- [Eval Harness & Golden Sets](../EXPLORATION_TOPICS.md#5-eval-harness--golden-sets-)
- [Multi-Model AI Stack Contracts](../exploration/MULTI_MODEL_AI_STACK_CONTRACTS.md)
- [Multi-Model AI Stack — Phase 1 Execution](../exploration/MULTI_MODEL_AI_STACK_PHASE1_EXECUTION.md)
- [Continuous Learning Loop (Frontier F3)](../EXPLORATION_FRONTIER.md#f3-continuous-learning-loop-from-user-corrections)

---

## 1. Existing Pipeline Baseline

The app already has a server-side training data pipeline (`functions/src/training_data.ts`) with:

| Component | Status |
|-----------|--------|
| `training_candidates` collection | **Live** — full schema with image, modelPrediction, pipeline, review, dataset, deletion |
| `training_labels` collection | **Live** — raw_prediction → user_corrected → reviewer_verified → golden/training_eligible |
| `training_dataset_versions` collection | **Live** — schema defined, no export function yet |
| `training_review_audit` collection | **Live** — audit log for all review actions |
| `enqueueTrainingCandidate` function | **Live** — creates candidate + label on classification completion |
| `attachTrainingLabelFeedback` function | **Live** — attaches user corrections to candidates |
| `revokeTrainingConsent` function | **Live** — marks candidates deleted, removes images |
| `getTrainingReviewQueue` function | **Live** — admin paginated list by status |
| `reviewTrainingCandidate` function | **Live** — admin review action |
| `cleanupTrainingReviewImages` pubsub | **Live** — 30-day retention cleanup |
| Heuristic PII scanner | **Live** — category keywords, barcode/text, email/phone/address regex |

**What is missing**: A reviewer-facing tool to browse candidates, view images, compare model output to user corrections, and take review actions. Today the reviewer must call Cloud Functions directly or manipulate Firestore documents by hand.

---

## 2. Review State Machine

The existing `review.status` values are correct but the transitions between them need formal definition.

### States

```
                  ┌─────────────────────────────────────┐
                  │           unreviewed                 │
                  │ (default on enqueue)                 │
                  └──────────┬──────────────────────────┘
                             │
              ┌──────────────┼──────────────┐
              ▼              ▼              ▼
      ┌────────────┐ ┌────────────┐ ┌────────────────┐
      │  approved  │ │  rejected  │ │ needs_redaction │
      └─────┬──────┘ └─────┬──────┘ └───────┬─────────┘
            │              │                │
            ├──────────────┤                │
            ▼              │                ▼
   ┌───────────────┐       │      ┌────────────────┐
   │    golden     │       │      │ needs_redaction │
   │ (eval set)    │       │      │ (re-scan PII,  │
   └───────┬───────┘       │      │  re-submit)    │
           │               │      └────────┬───────┘
           ▼               │               │
   ┌───────────────┐       │               │ (if PII cleared)
   │training_eligible│      │               ▼
   │ (train set)   │       │        ┌────────────┐
   └───────┬───────┘       │        │ approved   │
           │               │        └─────┬──────┘
           │               │              │
           │               │              ├──────────────┐
           │               │              ▼              ▼
           │               │      ┌────────────┐ ┌───────────────┐
           │               │      │  golden    │ │training_eligible│
           │               │      └────────────┘ └───────────────┘
           │               │
           ▼               ▼
    ┌──────────────────────────┐
    │         deleted          │
    │ (consent revoke or       │
    │  admin hard delete)      │
    └──────────────────────────┘
```

### Transition rules

| From | To | Allowed by | Notes |
|------|----|------------|-------|
| unreviewed | approved | Reviewer | Basic pass — no issues found |
| unreviewed | rejected | Reviewer | Wrong label, garbage image, spam |
| unreviewed | needs_redaction | Reviewer | PII suspected |
| unreviewed | deleted | System/Revoke | Consent revoked before review |
| approved | golden | Reviewer | Eval-grade: must be verified ground truth |
| approved | training_eligible | Reviewer | Training-grade: good label, not perfect |
| approved | rejected | Reviewer | Reconsideration |
| rejected | deleted | System/Cleanup | 30-day TTL cleanup |
| needs_redaction | approved | Reviewer | PII cleared; candidate is clean |
| needs_redaction | rejected | Reviewer | PII cannot be cleared; discard |
| needs_redaction | deleted | System/Cleanup | 30-day TTL cleanup |
| golden | training_eligible | Reviewer | Downgrade: eval → train |
| training_eligible | golden | Reviewer | Upgrade: train → eval |
| any | deleted | System | Consent revoked at any time |

### Constraint: golden and training_eligible

- `golden` implies `training_eligible` (every golden candidate is also training-eligible)
- `training_eligible` does **not** imply `golden`
- The `dataset.eligible` flag on the candidate doc mirrors this: true for both `golden` and `training_eligible`, false for all other states
- Downstream manifest builders should query `dataset.eligible == true` for train sets, and additionally filter `review.status == 'golden'` for eval sets

### Comparison: review.status vs labelState

| Layer | Field | Values | Purpose |
|-------|-------|--------|---------|
| Candidate doc | `review.status` | See above | Reviewer workflow state |
| Label doc | `labelState` | `raw_prediction` → `user_corrected` → `policy_verified` → `golden` → `training_eligible` | Label provenance — what signal established the ground truth |
| Candidate doc | `dataset.eligible` | `true`/`false` | Manifest inclusion gate — derived from review |

These three axes are intentionally decoupled. A candidate can have:
- `review.status = 'golden'` AND `labelState = 'golden'` AND `dataset.eligible = true`
- `review.status = 'needs_redaction'` AND `labelState = 'user_corrected'` AND `dataset.eligible = false`

---

## 3. Reviewer Fields

When a reviewer acts on a candidate, the following fields are set on `training_candidates/{candidateId}/review`:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `review.status` | string | yes | One of the state enum values |
| `review.reviewer` | string | yes | Firebase Auth UID of reviewer |
| `review.reviewedAt` | Timestamp | yes | Server timestamp of review action |
| `review.reviewNotes` | string | no | Free-text reviewer notes |
| `review.qualityFlags` | string[] | no | Quality issues: `['blurry', 'wrong_crop', 'multiple_items', 'metadata_only_no_training_image']` |
| `review.piiFlags` | string[] | no | PII findings: `['barcode_or_label_detected', 'potential_text_detected', 'risky_category_keyword', 'email_like_text', 'phone_like_text', 'address_like_text']` |
| `review.reviewSessionId` | string | no | Batch session identifier for grouping reviews |

Corresponding fields on `training_labels/{candidateId}/reviewerVerified`:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `reviewerVerified.reviewer` | string | yes | Same as review.reviewer |
| `reviewerVerified.reviewedAt` | Timestamp | yes | Same as review.reviewedAt |
| `reviewerVerified.status` | string | yes | Same as review.status |
| `reviewerVerified.notes` | string | no | Same as review.reviewNotes |
| `reviewerVerified.groundTruth` | Map | no | If reviewer provides a corrected ground truth: `{ category, itemName, material, confidence: 1.0 }` |

The `groundTruth` field deserves emphasis: when a reviewer overrides the model prediction (and any user correction), the authoritative label is recorded here. This is the highest-confidence signal in the system.

---

## 4. Privacy / PII Rejection Flow

### Detection triggers

```
enqueueTrainingCandidate
  ├── Category-based heuristic: medical/hazard keywords → 'needs_redaction'
  ├── Barcode/text signals from client metadata → 'needs_redaction'
  └── Result: redactionStatus + piiFlags set on candidate

attachTrainingLabelFeedback
  └── Regex scan of user notes (email/phone/address) → 'needs_redaction'
```

### Reviewer's role in PII handling

```
  needs_redaction
       │
       ├── Reviewer inspects image + metadata + user notes
       │
       ├── "Looks clean" → approved (reclassify)
       │
       ├── "Can be fixed" → needs_redaction + reviewer notes "redact text in top-left"
       │    (future automated redaction pipeline would consume this)
       │
       └── "Too sensitive / can't unsee" → rejected
                  ↓
            deleted after 30 days
```

### What the reviewer sees for PII

- `piiScan.methodVersion`: which heuristic version ran
- `piiScan.flags`: list of what was detected
- `piiScan.scannedAt`: when the scan ran
- `image.redactionStatus`: `pending_scan` | `needs_redaction` | `not_collected_metadata_only`
- The raw image (for visual inspection)

### PII escalation path

If the reviewer confirms PII that the heuristic missed:
1. Reviewer flags candidate as `needs_redaction`
2. Reviewer adds the missed PII type to `piiFlags` manually
3. The missing signal feeds back into the heuristic model versioning

---

## 5. Golden, Eval, Training — Separate Tracks

These are three distinct eligibility concepts that share a review surface:

| Concept | Flag | Field | Downstream use |
|---------|------|-------|----------------|
| **Golden** | `review.status == 'golden'` | Candidate doc | High-certainty benchmark set. Used in eval harness to score model versions. Hand-curated, low volume (target: 200–500). Unchanged once labelled. |
| **Training-eligible** | `dataset.eligible == true` | Candidate doc | Training set inclusion. Higher volume (target: 2000–10000). Includes all golden candidates plus bulk training-eligible ones. |
| **Eval set** | `review.status == 'golden'` | Candidate doc | The golden set is the eval set. Same documents, same flag. Eval set is a **subset** of the training-eligible set. |

### Why not separate flags?

A reviewer should not need to set `isGolden`, `isEval`, `isTrainingEligible` independently. The state machine is:

1. `approved` → candidate is clean but unclassified for downstream use
2. `golden` → **both** eval and training: `dataset.eligible = true`
3. `training_eligible` → training only: `dataset.eligible = true`
4. `rejected` / `deleted` → nothing

If later we need a separate `eval_eligible` pool beyond the golden set (e.g. for model selection, not benchmark), add an `eval` field to `dataset`:

```json
{
  "dataset": {
    "eligible": true,
    "evalEligible": true,
    "includedInVersions": ["v1.0", "v1.1"]
  }
}
```

This is not needed at current scale but the schema should allow it.

### Versioned dataset manifests

The `training_dataset_versions` collection stores export manifests:

```json
{
  "datasetVersion": "v2026-05-22",
  "manifestStoragePath": "training/manifests/v2026-05-22.jsonl",
  "goldenCount": 42,
  "trainingCount": 318,
  "exclusions": {
    "revokedConsent": ["userHash_a", "userHash_b"],
    "deletedCount": 12,
    "redactedCount": 5
  },
  "createdAt": Timestamp,
  "createdBy": "reviewer_uid",
  "generatorVersion": "manifest-builder-v1"
}
```

The JSONL manifest at `manifestStoragePath` contains one candidate export per line:

```jsonl
{"candidateId":"candidate_abc...","category":"dry_waste","itemName":"plastic_bottle","material":"PET","confidence":0.95,"labelSource":"golden","datasetVersion":"v2026-05-22"}
{"candidateId":"candidate_def...","category":"wet_waste","itemName":"banana_peel","labelSource":"training_eligible","datasetVersion":"v2026-05-22"}
```

Each line includes:
- `candidateId` (not userIdHash — no PII in manifests)
- The **reviewer-verified ground truth** (if `userCorrection` or `reviewerVerified.groundTruth` exists, use that; fall back to `rawPrediction`)
- `labelSource`: `golden` | `training_eligible` | `raw_prediction` | `user_corrected`
- `datasetVersion`
- Optional: `image.storagePath`, `image.contentHash`, `pipeline.qualityScore`, `pipeline.calibratedConfidence`

---

## 6. Candidate List — Required View

The reviewer's primary view is a filtered, sortable, paginated list.

### Columns

| Column | Data source | Type | Filterable | Sortable |
|--------|-------------|------|------------|----------|
| Candidate ID | `candidateId` (short hash) | string | no | no |
| Created | `createdAt` | datetime | date range | yes |
| Status | `review.status` | enum | yes (multiselect) | yes |
| Capture source | `captureSource` | enum | yes | yes |
| Category (predicted) | `modelPrediction.category` | string | yes | yes |
| Category (user) | `userFeedback.correctedCategory` | string | yes | yes |
| Confidence | `modelPrediction.confidence` | number | range | yes |
| PII flags | `review.piiFlags` | string[] | yes (has any) | no |
| Quality flags | `review.qualityFlags` | string[] | yes | no |
| Has correction | `userFeedback != null` | boolean | yes | no |
| Eligible | `dataset.eligible` | boolean | yes | yes |
| Reviewer | `review.reviewer` | string | yes | no |
| Image exists | `image.storagePath != null` | boolean | yes | no |

### Default sort

`createdAt DESC` — newest candidates first.

### Preset filters (one-click buttons)

- **Queue**: `status == 'unreviewed'`
- **Needs review**: `status == 'unreviewed' OR status == 'needs_redaction'`
- **PII flagged**: `status == 'needs_redaction'`
- **Has corrections**: `userFeedback != null AND status == 'unreviewed'`
- **Ready for golden**: `status == 'approved' AND confidence >= 0.9 AND piiFlags empty`
- **Eligible**: `dataset.eligible == true`

---

## 7. Detail / Review View

When the reviewer opens a candidate, they see:

```
┌─────────────────────────────────────────────────────────────┐
│ [Back to queue]  Candidate abc12345...                      │
├──────────────────────────────┬──────────────────────────────┤
│  ┌────────────────────┐      │  Model Prediction            │
│  │                    │      │  ┌────────────────────────┐  │
│  │   IMAGE PREVIEW    │      │  │ Item:  plastic bottle  │  │
│  │   (clickable zoom)  │      │  │ Cat:   dry_waste      │  │
│  │                    │      │  │ Conf:  0.94            │  │
│  │   Storage path:    │      │  │ Prov:  gpt-4.1-nano    │  │
│  │   training/review/  │      │  └────────────────────────┘  │
│  │   2026/05/abc...jpg│      │                              │
│  └────────────────────┘      │  User Correction              │
│                              │  ┌────────────────────────┐  │
│  Image metadata:             │  │ Item:  PET bottle      │  │
│  ─ 1280×720 JPEG             │  │ Cat:   dry_waste       │  │
│  ─ EXIF stripped: yes        │  │ Notes: "it's PET not   │  │
│  ─ Content hash: sha256...   │  │        generic plastic" │  │
│  ─ PII scan: heuristic-v1    │  └────────────────────────┘  │
│  ─ PII flags: none           │                              │
│                              │  Pipeline                    │
│  Quality flags:              │  ┌────────────────────────┐  │
│  ─ metadata_only_no_training │  │ Quality: 0.82          │  │
│    _image (no image stored)  │  │ Duplicate: 0.01        │  │
│                              │  │ Route: cloud_primary    │  │
│                              │  │ Latency: 1423ms        │  │
│                              │  │ Cost: $0.0004          │  │
│                              │  └────────────────────────┘  │
├──────────────────────────────┴──────────────────────────────┤
│  Review Action Panel                                        │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  [✓ Approve]  [✗ Reject]  [⚠ Needs redaction]       │  │
│  │  [★ Mark golden]  [📐 Mark training-eligible]       │  │
│  │                                                      │  │
│  │  Reviewer notes:                                      │  │
│  │  ┌────────────────────────────────────────────────┐  │  │
│  │  │ User correction is correct. Mark golden.       │  │  │
│  │  └────────────────────────────────────────────────┘  │  │
│  │                                                      │  │
│  │  Ground truth override (optional):                   │  │
│  │  Category: [dry_waste    ▼] Item: [PET bottle  ]   │  │
│  │                                                      │  │
│  │  [Submit review]                                    │  │
│  └──────────────────────────────────────────────────────┘  │
├──────────────────────────────────────────────────────────────┤
│  History / Audit                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  2026-05-21 10:23  enqueued (raw_prediction)         │  │
│  │  2026-05-21 10:25  user_corrected                    │  │
│  │  2026-05-22 14:01  ← current (unreviewed)            │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## 8. Implementation Options

Ranked by speed-to-value:

### Option A: Firebase Console + Manual JSONL (NOW)

**What**: Reviewer queries `training_candidates` in Firebase console, inspects images via Storage URL, takes notes externally, calls `reviewTrainingCandidate` via shell script or Functions playground.

**Pros**: Zero dev time. Works today.
**Cons**: No image preview in console (URL copy-paste). No workflow enforcement. Error-prone at scale. No batch actions.
**Scale limit**: ~50–100 candidates total.

### Option B: Web Admin Dashboard (Flutter web / Next.js) (RECOMMENDED)

**What**: Standalone web app (Flutter Web reusing existing models, or lightweight Next.js with Firestore Admin SDK) that provides the full candidate list + detail + review panel.

**Pros**: Proper UX. Reuses existing Flutter model classes if Flutter Web. Batch actions. Filter presets. Image preview with zoom. Ground truth override. Session grouping. Export trigger.
**Cons**: Requires build + deploy. Hosting needed (Firebase Hosting trivial). Auth setup (admin only).
**Effort**: ~3-5 days for MVP (list + detail + review). ~1-2 days for manifest export.
**Scale**: 1000s of candidates.

### Option C: Admin Screen Inside Mobile App

**What**: Admin-only route in the Flutter app (gated by `UserRole.admin`).

**Pros**: No new deployment target. Reuses existing image loading, caching, UI patterns.
**Cons**: Mobile screen real estate limits the review panel. Image zoom vs PII inspection awkward on phone. Not designed for batch throughput.
**Use case**: Quick triage of urgent PII flags on the go, not primary review.
**Effort**: ~2 days for a basic list + approve/reject.

### Option D: Exported JSONL + Local Script Review

**What**: Script exports unreviewed candidates to JSONL. Reviewer views images locally (images downloaded alongside). Edits JSONL with labels. Script imports results.

**Pros**: No UI to build. Works offline. Maximum control.
**Cons**: No image preview integration. Manual file management. No audit trail without git. Hard to share across reviewers.
**Scale limit**: ~200 candidates before the friction dominates.

### Option E: Python/Streamlit Admin Panel

**What**: Quick Streamlit app using Firebase Admin SDK. Image loading, simple grid, review buttons.

**Pros**: Fast to prototype (hours). Python ecosystem for future ML integration.
**Cons**: Another language in the stack. Streamlit auth story weak. Not production-grade for multi-reviewer use.

### Recommendation

| Phase | What | When |
|-------|------|------|
| **Phase 0 (NOW)** | Option A — Manual Firebase console + shell scripts | While candidate volume is < 100 |
| **Phase 1 (NEXT)** | Option B — Web admin dashboard | At 100+ candidates, before any model training pass |
| **Phase 2 (LATER)** | Option C — Mobile admin screen | Only if urgent PII triage need emerges |
| **Future** | Options D/E — JSONL script or Streamlit | Only if Python ML pipeline is built and needs tight integration |

---

## 9. Data Export to Dataset Manifests

### Export function specification

New Cloud Function: `buildTrainingDatasetManifest`

```
buildTrainingDatasetManifest({ datasetVersion: "v2026-05-22", dryRun: true })
  → { version, goldenCount, trainingCount, eligibleCount, excludedCount, outputPath }
```

Logic:
1. Query `training_candidates` where `dataset.eligible == true` AND `deletion.deletedAt == null`
2. Join with `training_labels` on `candidateId`
3. Determine authoritative label: `reviewerVerified.groundTruth` > `userCorrection` > `rawPrediction`
4. Write JSONL to `training/manifests/{datasetVersion}.jsonl`
5. Write metadata to `training_dataset_versions/{datasetVersion}` doc
6. If `dryRun: true`, log counts but write nothing

### Manifest schema (JSONL line)

```json
{
  "candidateId": "candidate_abc...",
  "labelSource": "golden",
  "category": "dry_waste",
  "subcategory": "plastic_bottle",
  "itemName": "PET bottle",
  "material": "PET",
  "confidence": 0.95,
  "imageHash": "sha256...",
  "imagePath": "training/review/2026/05/candidate_abc....jpg",
  "provider": "openai",
  "model": "gpt-4.1-nano",
  "datasetVersion": "v2026-05-22",
  "provenance": {
    "classificationId": "uuid...",
    "consentVersion": "training-data-v1",
    "reviewer": "admin_uid"
  }
}
```

No PII. No `userIdHash`. No user notes text that might contain residual PII.

### Multiple manifest types

| Manifest | Filter | Contains |
|----------|--------|----------|
| `train.jsonl` | `dataset.eligible == true` | All eligible candidates |
| `eval.jsonl` | `review.status == 'golden'` | Golden candidates only |
| `full.jsonl` | All non-deleted | Everything including unreviewed (for analysis) |

### Exports as CI artifact

Once manifests are generated, they should be:
1. Stored in Firebase Storage (`training/manifests/`) for durable archival
2. Optionally pushed to a git tag (`dataset-v2026-05-22`) in a private dataset repo
3. Referenced by the eval harness as its input

---

## 10. Future Extensions

### Automated redaction pipeline

When `review.status == 'needs_redaction'` and the PII is localised (text overlay, barcode in corner):
- An automated pipeline (Cloud Run + OpenCV/TensorFlow) could apply blur/redaction
- Re-submit the candidate as the redacted version
- Reviewer only sees pre/post comparison and approves

### Reviewer consensus

For golden candidates, require 2+ reviewers to independently confirm. Until then, golden status is provisional.

### Active learning priority

The review queue should surface candidates where a review has the highest information gain:
- Lowest calibrated confidence among unreviewed
- Highest disagreement between model prediction and user correction
- From underrepresented categories (e_waste, medical, hazardous)
- User made a correction AND confidence was high (model was confidently wrong)

### Eval set versioning

```
eval-v1 (50 golden, 2026-05)
eval-v2 (200 golden, 2026-06)
```

Each version is a snapshot. Old versions are retained for regression testing.

---

## Summary

| AC | Status | Notes |
|----|--------|-------|
| Review states defined | ✓ | State machine with 7 states, transition rules, and 3-axes label model |
| Reviewer fields defined | ✓ | reviewer, reviewedAt, reviewNotes, qualityFlags, piiFlags, groundTruth override |
| Privacy/PII rejection | ✓ | needs_redaction state, heuristic scan, manual confirmation, escalation path |
| Golden/eval/training separation | ✓ | golden == eval set; dataset.eligible for training; separate manifest queries |
| Future export to dataset manifests | ✓ | buildTrainingDatasetManifest spec, JSONL schema, 3 manifest types, CI artifact plan |
