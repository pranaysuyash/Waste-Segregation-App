# API Patterns Improvement Review — 2026-06-17

## Executive Summary

Implemented a first-principles API hardening pass aligned to `api-patterns` guidance for response shape consistency, status mapping, and reusable validation helpers. The change keeps current user behavior intact by adding a backward-compatible envelope parser in the Flutter disposal client.

## Scope

- Reused shared helper layer for API response contracts in Firebase Functions.
- Standardized `generateDisposal` HTTP responses and errors.
- Removed duplicated callable App Check parser logic from payment endpoints.
- Updated disposal client parsing to unwrap success envelopes safely.
- Completed remaining Firebase HTTP handlers on shared envelope contract:
  - `aggregateCommunityStatsHttp`
  - `dodopaymentsWebhook`
  - `getBatchStats`
  - `getClassifyReservationDashboard`
- Added documentation in API specification for the contract and migration expectations.

## Files Changed

- `functions/src/helpers.ts`
- `functions/src/disposal.ts`
- `functions/src/index.ts`
- `functions/src/create_checkout_session.ts`
- `functions/src/create_token_purchase.ts`
- `functions/src/community_stats_aggregator.ts`
- `functions/src/dodopayments_webhook.ts`
- `functions/src/ops_hardening.ts`
- `lib/services/disposal_instructions_service.dart`
- `docs/reference/api_documentation/api_specification.md`
- `functions/test/http_guards.emulator.test.js`
- `functions/test/http_response_contracts.test.js`

## Pattern Decisions

### 1) Shared contract over per-handler JSON shapes
- Introduced reusable types/helpers in `helpers.ts`:
  - `ApiResponseEnvelope<T>`
  - `ApiFailureEnvelope`
  - `ApiVersion`
  - `respondWithApiSuccess`
  - `respondWithApiError`
- This prevents a future drift where each route invents its own error payload.

### 2) HTTP status and transport headers as explicit contract
- Standardized `401/403/405/429/503` handling in disposal route.
- Added request metadata (`x-request-id`, `x-api-version`) and rate-limit headers where relevant.

### 3) Canonical helper reuse for callable App Check
- Removed duplicate local `parseBoolEnv` and `shouldEnforceCallableAppCheck` implementations in payment callables.
- Reused canonical helper versions from `helpers.ts`.

### 4) Client-side compatibility strategy
- Added `_unwrapApiEnvelope` in `DisposalInstructionsService` so envelope and legacy response formats are both supported.
- This avoids hard migration of older app paths and supports staged rollout.

## Behavior Changes

### User-facing/API behavior
- `generateDisposal` now returns envelope responses while still exposing disposal payload fields through the enveloped data object.
- Retry and throttling are now explicitly encoded with status-based envelopes.

### Internal operational behavior
- Error responses now carry request correlation metadata.
- Rate-limit responses include explicit limit headers expected by clients.
- API response handling logic is centralized and discoverable.

## Validation

- Backend verification:
  - `npm --prefix functions run build` passed after lockfile sync.
  - `npm --prefix functions run test:http-guards` passed (6 passed, 0 failed).
- Test coverage in this pass is limited to the touched HTTP contract path:
  - `functions/src/disposal.ts`, `functions/src/helpers.ts`, `functions/src/community_stats_aggregator.ts`, `functions/src/dodopayments_webhook.ts`, `functions/src/index.ts`, `functions/test/http_guards.test.js`, and `functions/test/http_guards.emulator.test.js`.
- Static review performed on all edited files.
- No route duplication introduced; existing route names retained.

## Residual Risk / Follow-ups

1. Client surfaces that parse direct status codes should explicitly consume `success`/`error` fields for richer diagnostics in future.
2. `generateDisposal` now uses envelope shape in the primary path; all in-repo consumers are verified via the test + compatibility parsing path.
3. Expand contract tests to a shared schema test for helper-driven responses across remaining HTTP functions.
4. Enforce helper-level envelope regression checks for all newly updated HTTP handlers.

## Evidence Snapshot

- Disposal contract and helper usage: `functions/src/disposal.ts`, `functions/src/helpers.ts`
- Shared response wrappers in helper layer: `functions/src/helpers.ts`
- Client compatibility handling: `lib/services/disposal_instructions_service.dart`
- Contract documentation update: `docs/reference/api_documentation/api_specification.md`
- Additional endpoint migration evidence:
  - `functions/src/community_stats_aggregator.ts`
  - `functions/src/dodopayments_webhook.ts`
  - `functions/src/index.ts` (`getBatchStats`)
- Emulator contract assertions: `functions/test/http_guards.emulator.test.js`
