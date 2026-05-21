# Firebase Task P0 Execution (motto_v2)

Date: 2026-05-21
Owner: Hermes
Scope: Complete remaining P0 money-gate and release safety hardening in firebase_task.md using architecture-level fixes (not local patches).

## 1) What was still open (state review summary)

Mapped surfaces before implementation:

1. Client routing surface
- `lib/services/ai_service.dart` used backend path only when `USE_BACKEND_CLASSIFICATION=true`.
- In release, direct provider paths were blocked by safety guard, but backend routing was not hard invariant in routing logic.
- Result: release behavior depended on mixed flags and fallback branches, not a single enforced routing invariant.

2. Backend monetization surface
- `functions/src/classify_image.ts` enforced Auth + optional App Check + UID rate limit + cache.
- It did not enforce token spend before paid provider execution.
- Result: caller could potentially execute paid classify path without server-side wallet deduction.

3. Entitlement linkage surface
- No authoritative classify-time entitlement adjustment was applied server-side.
- Premium discount logic existed client-side in token UX, but classify callable did not apply it.

## 2) Implemented architecture-level changes

### A) Release-safe server-authoritative routing in client AI service
File: `lib/services/ai_service.dart`

Changes:
- Added `_backendRoutingEnabled` and `_backendRoutingFailClosed` invariants.
- Classification routing now:
  - release: backend classify path is mandatory (fail-closed)
  - debug/profile: backend path optional via `USE_BACKEND_CLASSIFICATION`
- Backend failure fallback to direct provider now allowed only in non-release path.
- Updated warnings to make fallback scope explicit.

Why this is architectural, not patchwork:
- Converts routing from “optional feature flag” to “release invariant”.
- Removes ambiguous mixed path behavior in production.

### B) Server-side token + entitlement enforcement before paid classify execution
File: `functions/src/classify_image.ts`

Changes:
- Added classify-time token economy controls:
  - `CLASSIFY_ENFORCE_TOKEN_SPEND` (default true, fail-closed)
  - `CLASSIFY_IMAGE_TOKEN_COST` (default 5)
  - `CLASSIFY_IMAGE_PREMIUM_DISCOUNT_PERCENT` (default 50)
- Added server-side premium detection sources:
  - Firebase auth claims (`premium`, `pro_subscription`, `entitlements.pro_subscription`)
  - Firestore user doc fields (`billing.entitlements.pro_subscription`, `premium.*` legacy variants)
- Added atomic token reservation before provider call:
  - `reserveClassificationTokens(...)`
- Added refund-on-total-failure path:
  - `refundReservedClassificationTokens(...)`
- Added classify success metadata for observability:
  - `tokenSpendEnforced`, `tokensCharged`, `premiumApplied`, `tokenReservationTransactionId`

Why this is architectural, not patchwork:
- Enforcement moved into callable execution boundary.
- Paid path is gated at server authority, independent of client honesty.
- Failure compensation (refund) is first-class in backend transaction flow.

### C) Production safety docs updated to match real behavior
Files:
- `lib/utils/production_safety_config.dart`
- `docs/config/environment_variables.md`

Changes:
- Removed stale TODO stating backend release routing was unwired.
- Updated env contract and classify monetization controls.
- Documented release fail-closed backend routing and relevant flags.

## 3) Tests added/adjusted (server enforcement behavior)

File: `functions/test/http_guards.emulator.test.js`

Added tests:
1. `classifyImage denies execution when token wallet is insufficient`
- Verifies classify callable fails with FAILED_PRECONDITION semantics when balance is insufficient.

2. `classifyImage cache hit does not charge tokens when classification is already cached`
- Seeds Firestore cache for computed server hash.
- Verifies classify callable returns cached classification and wallet balance remains unchanged.

These tests directly validate money-gate ordering:
- cache short-circuit before spend
- spend enforcement before paid provider execution

## 4) Verification evidence (commands run)

1. TypeScript compile
- Command: `npm --prefix functions run build`
- Result: PASS (`tsc` success)

2. Functions HTTP guard unit tests
- Command: `npm --prefix functions run test:http-guards`
- Result: PASS (6/6)

3. Functions emulator integration tests (including new classify tests)
- Command: `npm --prefix functions run test:http-guards:emulator`
- Result: PASS (5/5)
- Includes both new classify enforcement tests passing.

4. Key resolution tests
- Command: `npm --prefix functions run test:key-resolution`
- Result: PASS (3/3)

5. Flutter service tests
- Command: `flutter test test/services/ai_service_test.dart`
- Result: PASS (all tests passed)

6. Flutter analyze (touched client files)
- Command: `flutter analyze lib/services/ai_service.dart lib/utils/production_safety_config.dart`
- Result: warnings only (unused private declarations pre-existing); no new hard errors from this change set.

## 5) Files changed in this execution slice

- `functions/src/classify_image.ts`
- `functions/test/http_guards.emulator.test.js`
- `lib/services/ai_service.dart`
- `lib/utils/production_safety_config.dart`
- `docs/config/environment_variables.md`

## 6) Risks / remaining gaps

1. Entitlement source-of-truth
- Current classify entitlement check supports claims + Firestore fields.
- Recommended: unify on single server-managed entitlement contract and remove legacy field ambiguity.

2. Refund reliability
- Refund currently runs on provider-total-failure path.
- Recommended: idempotent reservation ledger with explicit reservation status transitions (`reserved -> consumed|refunded`) for stronger recovery semantics.

3. App Check enforcement policy
- `REQUIRE_APPCHECK_CALLABLE` is env-gated.
- Recommended: set true in production and keep emulator override explicit.

## 7) Opinionated recommendation (next action)

Next highest-value move is to harden entitlement authority (single schema + claim propagation pipeline) and attach classify spend events to an auditable billing ledger collection.
That removes the last meaningful ambiguity in monetization integrity and makes post-incident reconciliation straightforward.
