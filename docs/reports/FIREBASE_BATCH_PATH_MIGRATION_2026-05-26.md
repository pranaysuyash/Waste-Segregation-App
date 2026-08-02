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
