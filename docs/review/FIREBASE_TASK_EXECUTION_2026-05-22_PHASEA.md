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
