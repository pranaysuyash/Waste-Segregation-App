# Firebase Task Execution — Phase A Hardening (2026-05-22)

Scope: Implement concrete launch-critical improvements from `firebase_task.md` and prior strategy report without migration work.

## What was implemented now

1) Storage security policy was missing and is now added
- Added: `storage.rules`
- Policy:
  - allow authenticated user read/write only in:
    - `batch_images/{uid}/**`
    - `contribution_photos/{uid}/**`
  - deny all other storage paths by default.

2) Firebase config now declares storage rules + storage emulator
- Updated: `firebase.json`
  - added `storage.rules` binding
  - added storage emulator port (`9199`) for repeatable rules testing.

3) Storage rules test lane added (new capability)
- Added: `firestore-rules-test/storage-rules-test.spec.js`
- Updated: `firestore-rules-test/package.json`
  - `test:storage`
  - `test:storage:emulator`
- Coverage in tests:
  - owner can upload under own path
  - cross-user upload denied
  - unauthenticated upload denied
  - owner list own contribution path, cross-user listing denied
  - non-whitelisted paths denied

4) Legacy `functions.config()` fallback removed from batch processor
- Updated: `functions/batch_processor.js`
- `getOpenAiApiKey()` is now env-only (`OPENAI_API_KEY`/`OPENAI_KEY`).

5) spendUserTokens entitlement authority improved
- Updated: `functions/src/index.ts` (`spendUserTokens` transaction block)
- Premium eligibility now derives from canonical Firestore entitlement first:
  - `users/{uid}.billing.entitlements.pro_subscription`
- Claims are fallback-only for propagation lag.
- Premium discount for instant spend is now server-configurable:
  - `SPEND_PREMIUM_DISCOUNT_PERCENT` (default 40)
  - server computes canonical premium instant cost from free baseline.

## Verification evidence (commands run)

1) Functions TypeScript build
- `npm --prefix functions run build`
- Result: PASS

2) Functions emulator integration (auth/callable/money gate)
- `npm --prefix functions run test:http-guards:emulator`
- Result: PASS (6/6)

3) Storage rules emulator tests (new)
- `npm --prefix firestore-rules-test run test:storage:emulator`
- Result: PASS (5/5)

4) Firebase config validity check
- JSON parse of `firebase.json`
- Result: PASS

## Files changed in this execution slice

- `storage.rules` (new)
- `firebase.json`
- `firestore-rules-test/storage-rules-test.spec.js` (new)
- `firestore-rules-test/package.json`
- `functions/batch_processor.js`
- `functions/src/index.ts`

## Important notes about repository state

- There are additional pre-existing modified files in working tree unrelated to this slice (UI/state/test files). They were not modified by this execution.
- No push was performed in this execution slice.

## Remaining high-value next improvements (no migration)

1) Eliminate release-exposed direct provider client pathways around batch AI creation (`AiJobService`) by routing creation through authenticated callable endpoints only.
2) Add explicit regression tests for entitlement mismatch cases in `spendUserTokens`:
   - billing entitlement true + stale subscriptionTier free
   - claims fallback path behavior
3) Add CI gate for `test:storage:emulator` so storage policy drift cannot merge silently.
4) Add explicit observability fields for spend path decisions (billing vs claims source) in spend ledger metadata.

## Phase B addendum — backend-authoritative batch flow + CI integration (2026-05-22)

This addendum closes the remaining execution tasks (`t1..t5`) under `motto_v2`.

### Implemented

1) Backend-authoritative batch callable path completed
- `functions/src/index.ts`
  - `createBatchAiJob` callable enforces:
    - auth required
    - App Check gate (`shouldEnforceCallableAppCheck`)
    - owner-only `batch_images/{uid}/` URL validation
    - per-user rate limit bucket
    - server-side token debit ledger
    - refund on OpenAI submission failure
    - canonical Firestore `ai_jobs` write

2) Client batch service refactor completed
- `lib/services/ai_job_service.dart`
  - removed direct client OpenAI batch submission path
  - `createBatchJob` now calls backend callable (`createBatchAiJob`)
  - client-side token debit/refund path removed from this flow

3) Mixed status compatibility retained across old/new records
- `lib/models/ai_job.dart`
- `lib/providers/token_providers.dart`
- `functions/src/index.ts` poller query + status mapping

4) New emulator regression tests for callable + entitlement fallback
- `functions/test/http_guards.emulator.test.js`
  - added claims-fallback premium spend test
  - added `createBatchAiJob` auth + owner-path validation test

5) Storage rules lane integrated into main CI
- `.github/workflows/ci.yml`
  - added `firebase_rules` job
  - runs Firestore + Storage rules tests in emulators
  - added gate to `automerge` dependencies
- `firestore-rules-test/package.json`
  - added `test:all`
  - added `test:all:emulator`

6) Artifact safety update before commit/push
- `.gitignore`
  - added Hive lock artifact patterns:
    - `/*box.lock`
    - `/classification_queue.lock`

### Verification evidence (Phase B)

1) Functions build
- `npm --prefix functions run build`
- Result: PASS

2) Functions callable/auth regression suite (updated)
- `npm --prefix functions run test:http-guards:emulator`
- Result: PASS (8/8)
- Includes the new tests:
  - `spendUserTokens applies claims-based premium fallback ...`
  - `createBatchAiJob callable enforces auth and user-owned batch image path`

3) Firestore + Storage rules full emulator suite
- `npm --prefix firestore-rules-test run test:all:emulator`
- Result: PASS
  - Firestore rules: 83 passing
  - Storage rules: 5 passing

4) Targeted Flutter static analysis for touched Dart paths
- `flutter analyze lib/services/ai_job_service.dart lib/models/ai_job.dart lib/providers/token_providers.dart`
- Result: PASS (No issues found)

5) Targeted Flutter tests for touched service behavior
- `flutter test test/services/batching_service_test.dart test/services/enhanced_ai_api_service_safety_test.dart`
- Result: PASS (All tests passed)

### Git execution performed per explicit user instruction

User explicitly requested `git add -A`, commit, and push before continuing work.

Executed:
- `git add -A`
- `git commit -m "feat: enforce motto_v2 hardening and backend-authoritative AI batch flow"`
- `git push`

Result:
- Pushed commit: `59d6cb0` to `main`
- Post-push status: clean (`main...origin/main`)

## Phase C addendum — regression/CI commit after verification (2026-05-22)

Additional commit created after completing emulator + Flutter verification and CI wiring:
- Commit: `da9b945`
- Message: `test: add callable/rules regressions and wire storage rules lane into CI`
- Includes:
  - `.github/workflows/ci.yml`
  - `firestore-rules-test/package.json`
  - `functions/test/http_guards.emulator.test.js`
  - `lib/models/ai_job.dart`
  - `lib/services/ai_job_service.dart`
  - `docs/review/FIREBASE_TASK_EXECUTION_2026-05-22_PHASEA.md`

Push result:
- `da9b945` pushed to `main` successfully.

Current repo note:
- Working tree currently has additional unrelated local changes/untracked files from parallel work (settings/home/navigation files and docs). Those were intentionally not staged in this commit slice.

## Phase D addendum — observability + fail-closed regression strengthening (2026-05-22)

### Implemented

1) Backend observability counters for callable risk paths
- `functions/src/index.ts`
- Added `bumpOpsMetric(metricName, tags)` helper writing to:
  - `ops_metrics/{yyyy-mm-dd}`
  - `counters.<metricName>` (increment)
  - `lastEvent.<metricName>` (latest tagged sample)
- Instrumented counters:
  - `spendUserTokens_unauthenticated`
  - `spendUserTokens_appcheck_missing`
  - `spendUserTokens_rate_limited`
  - `spendUserTokens_claims_fallback`
  - `createBatchAiJob_unauthenticated`
  - `createBatchAiJob_appcheck_missing`
  - `createBatchAiJob_owner_path_denied`
  - `createBatchAiJob_rate_limited`
  - `createBatchAiJob_refund_openai_submission_failed`

2) Spend-path metadata enrichment in token ledger and transaction history
- `functions/src/index.ts` (`spendUserTokens`, `createBatchAiJob`)
- Added spend authority and computation visibility fields:
  - `spendAuthoritySource` (`billing_entitlement` | `claims_fallback` | `none` / `fixed_batch_cost`)
  - `serverTier`
  - `requestedClientAmount`
  - `authorizedAmount`
  - `serverComputedMinimum`
  - `spendComputationMode` (`server_computed` | `client_declared`)
- Added refund metadata fields for batch submission failure:
  - `refundReason: openai_submission_failed`
  - `originalLedgerId`

3) Regression test expansion for ledger observability correctness
- `functions/test/http_guards.emulator.test.js`
- Extended claims-fallback test to assert:
  - callable response transaction metadata carries `spendAuthoritySource=claims_fallback`
  - ledger document metadata has matching authority + premium tier indicators

4) Release fail-closed behavior made explicitly testable
- `lib/services/enhanced_ai_api_service.dart`
- Added test-only override:
  - `overrideBackendFailClosedForTest(bool?)`
- Added new test:
  - `non-terminal backend failure is terminal when fail-closed is forced`
- File: `test/services/enhanced_ai_api_service_safety_test.dart`

### Verification evidence (Phase D)

1) Functions build
- `npm --prefix functions run build`
- Result: PASS

2) Functions emulator auth/callable regression suite
- `npm --prefix functions run test:http-guards:emulator`
- Result: PASS (8/8)
- Includes updated claims-fallback + ledger metadata assertions.

3) Firestore + Storage rules full suite
- `npm --prefix firestore-rules-test run test:all:emulator`
- Result: PASS (Firestore 83, Storage 5)

4) Targeted Flutter static analysis for modified release-safety service + tests
- `flutter analyze lib/services/enhanced_ai_api_service.dart test/services/enhanced_ai_api_service_safety_test.dart`
- Result: PASS

5) Additional targeted Flutter test
- `flutter test test/services/batching_service_test.dart`
- Result: PASS

### Known verification blocker outside this scope

- `flutter test test/services/enhanced_ai_api_service_safety_test.dart` currently fails to compile due pre-existing breakage in `lib/services/ai_service.dart` (syntax and missing symbol errors unrelated to this Phase D slice).
- This blocker predates/exists outside the files changed for this addendum and should be handled as a dedicated stabilization task before full Flutter suite sign-off.
