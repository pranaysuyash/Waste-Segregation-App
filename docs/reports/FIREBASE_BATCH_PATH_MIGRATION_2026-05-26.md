# Firebase Batch Path Migration - 2026-05-26

## Scope
- Source of truth callable: `functions/src/index.ts` -> `createBatchAiJob`
- Client migration target: `lib/services/batching_service.dart`
- Contract verification focus: auth, App Check, token spend, error propagation

## What changed
- Migrated `BatchingService` test/runtime seams away from placeholder-era assumptions by introducing injectable adapters for:
  - upload path (`BatchImageUploadFn`)
  - callable invocation (`BatchCallableFn`)
  - Firestore `ai_jobs/{jobId}` updates stream (`BatchJobUpdatesFn`)
- Preserved production default behavior:
  - upload to Cloud Storage batch path
  - call `createBatchAiJob` in `asia-south1`
  - listen to `ai_jobs/{jobId}` for completion
- Added explicit callable error propagation with contract surface in message:
  - `createBatchAiJob failed (<code>): <message>`

## Verification evidence
- Updated tests: `test/services/batching_service_test.dart`
  - Validates real callable-oriented flow (upload -> callable payload -> `ai_jobs` completion -> `WasteClassification` parse)
  - Validates error surfacing for guardrail failures (`failed-precondition` / App Check)
  - Validates cancellation path for pending jobs
- Backend contract inspected from source:
  - Auth required (`unauthenticated`) in `functions/src/index.ts`
  - App Check required (`failed-precondition`) in `functions/src/index.ts`
  - Rate limit (`resource-exhausted`, `retryAfterSeconds`) in `functions/src/index.ts`
  - Token debit (`token_spend_ledger`, `users/{uid}.tokenWallet`) transaction in `functions/src/index.ts`
  - Refund-on-submission-failure path in `functions/src/index.ts`
  - Job record creation in `ai_jobs` with `status=queued` and `tokensSpent=1`

## Remaining rollout blockers
1. No dedicated Functions unit/emulator test currently validates `createBatchAiJob` transaction + refund path end-to-end under emulator fixtures.
2. `functions/batch_processor.js` legacy duplicate still exists and can confuse operator ownership, even if not exported.
3. No user-facing completion notification path for batch jobs, increasing job abandonment risk.
4. No explicit cleanup retention path for Storage objects under `batch_images/{uid}/` tied to completed/failed jobs.

## Recommended next closure slice
1. Add `functions/test/create_batch_ai_job.test.js` with emulator-backed fixtures:
   - unauthenticated
   - appcheck missing (with enforcement flag)
   - insufficient tokens
   - success writes (ledger + wallet + ai_jobs)
   - OpenAI submission failure refund path
2. Consolidate/remove `functions/batch_processor.js` after parity check against `functions/src/index.ts`.
3. Add batch completion notification and storage retention cleanup policy in the same rollout with docs and tests.

## Verified Session Learning - 2026-09-12

This addendum salvages the durable findings from OpenCode exploration session
`ses_1a15bbf10ffepbgX0qCgpg3cOO` (`Find Firebase Storage upload patterns`).
The original report was checked against current source because its contribution
upload path had since moved.

### Current ownership and paths

- Batch processing is owned by `CloudStorageService`:
  `batch_images/{userId}/batch_image_{timestamp}.jpg`.
- Facility contribution uploads are now owned by
  `CommunityContributionService.uploadContributionPhotos`, called through
  `CommunityContributionService.submitContribution` from
  `contribution_submission_screen.dart`:
  `contribution_photos/{userId}/contribution_{timestamp}_{index}.jpg`.
- `CloudStorageService.deleteUserStorageBlobs` knows both path families, but
  the presence of a deletion method is not proof that scheduled retention is
  wired or that every caller invokes it.

### Privacy and retention learning

- The batch path calls `ImageUtils.stripExifData` before `putData`.
- The current contribution upload path reads the image bytes and calls
  `putData` directly; no EXIF-stripping call is present in that method. This
  is a concrete privacy gap, not merely a documentation concern.
- Both paths attach `userId`, `purpose`, and `uploadedAt` metadata and return a
  Firebase download URL. These fields and URLs should be treated as sensitive
  lifecycle-bearing data, not as disposable cache records.
- The existing design target remains explicit retention: batch objects should
  expire after processing, while contribution photos need moderation/resolution
  retention. Current client code does not establish an automatic TTL for
  either path.

### Source-drift guardrail

The exploration report's former reference to a private upload method in
`contribution_submission_screen.dart` is stale. Future audits should trace the
UI call into `CommunityContributionService` before documenting upload behavior;
otherwise a correct historical report can hide a changed privacy or retention
boundary.
