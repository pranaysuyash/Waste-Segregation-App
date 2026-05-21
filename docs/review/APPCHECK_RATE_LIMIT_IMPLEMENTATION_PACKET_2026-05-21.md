# App Check + Rate Limiting Implementation Packet (Phase 5)

Date: 2026-05-21
Repo: /Users/pranay/Projects/LLM/image/waste_seg/waste_segregation_app
Objective: record the current abuse/cost posture on AI and token endpoints and capture the remaining hardening work without a broad architecture migration.

## 1) Current state snapshot
- `classifyImage` is live as a Firebase HTTPS callable and already enforces auth, optional App Check, Firestore rate limiting, token reservation, provider fallback, cache writes, and cost telemetry.
- `spendUserTokens` is live as a Firebase callable and already enforces auth, optional App Check, and a backend rate limit.
- `generateDisposal` is live as an HTTP route and already has auth gating plus rate limiting behavior in the function layer.
- `testOpenAI` and `clearAllData` are admin/diagnostic surfaces that remain intentionally gated by environment flags and admin checks.
- The main remaining risk is not "missing implementation" so much as rollout discipline, config drift, and making sure fallback or diagnostics states are never mistaken for healthy success.

## 2) Implemented controls

### Control A: App Check enforcement
Scope:
- Enforce App Check at Firebase backend entry points for production traffic.

Implementation state:
1. Client:
   - Client App Check initialization still needs verification in the startup path for each production platform.
   - Debug providers should stay limited to development and emulator flows.
2. Backend:
   - Callable and backend gates already reject or fail closed according to the configured production safety flags.
   - `classifyImage` and `spendUserTokens` already enforce App Check when the production flag requires it.
   - HTTP endpoints continue to use auth/role/env checks plus rate limiting rather than a second route fork.

Files likely touched:
- `lib/main.dart`
- `functions/src/index.ts`
- `firebase.json` (if needed for emulator behavior/config)
- docs: `docs/config/environment_variables.md`

### Control B: Rate limiting
Scope:
- Limit expensive endpoints by user and by IP/device fallback.

Implemented state:
- `classifyImage` has a rolling per-UID limit.
- `spendUserTokens` has a backend rate limit.
- `generateDisposal`, `testOpenAI`, and `clearAllData` are all guarded by explicit auth/admin/environment checks in the function layer.

Remaining hardening:
- Keep the current rate-limit windows documented in the canonical truth table.
- Add or update tests whenever a new expensive backend path is introduced.
- Preserve one response shape for rate-limit failures so clients can show a clear retry state.

Files likely touched:
- `functions/src/index.ts`
- optional helper file under `functions/src/` for limiter logic

## 3) Response contract
All blocked requests should return explicit machine-readable payload:
- `error_code`: `APP_CHECK_REQUIRED` or `RATE_LIMITED`
- `retry_after_seconds` for throttled requests
- `request_id` for tracing

Current note:
- Some routes already return structured error bodies or Firebase callable failures.
- Any new blocking behavior should match the existing response style rather than inventing a second error vocabulary.

## 4) Rollout plan
1. Verify the currently deployed App Check and rate-limit flags in the release environment.
2. Keep diagnostics/admin routes disabled outside controlled environments.
3. Monitor reject rates, fallback rates, and token-spend anomalies.
4. Tune only if the live traffic pattern shows false positives or cost leakage.

## 5) Validation matrix
- Unit/integration:
  - valid app + valid auth => allowed
  - missing app token => blocked in prod mode where enforcement is enabled
  - over limit => blocked with a clear retry path
- Commands:
  - `npm --prefix functions run test:http-guards`
  - `npm --prefix functions run test:http-guards:emulator`
  - add or refresh dedicated limiter tests whenever a new limit window is added

## 6) Non-goals
- No platform migration.
- No full billing redesign.
- No Firestore schema overhaul beyond minimal limiter docs.

## 7) Launch gate
Monetized launch should not proceed until:
- App Check enforcement is verified in the production configuration.
- Rate limits are active for AI and token spend paths.
- Monitoring confirms fallback, retry, and reject rates are within expected bounds.
