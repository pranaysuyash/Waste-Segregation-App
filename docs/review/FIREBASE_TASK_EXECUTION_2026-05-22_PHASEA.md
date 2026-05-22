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
