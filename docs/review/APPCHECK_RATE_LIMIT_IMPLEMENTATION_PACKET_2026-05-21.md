# App Check + Rate Limiting Implementation Packet (Phase 5)

Date: 2026-05-21
Repo: /Users/pranay/Projects/LLM/image/waste_seg/waste_segregation_app
Objective: close abuse/cost exposure on AI and token endpoints without broad architecture migration.

## 1) Current exposure snapshot
- HTTP endpoints (`generateDisposal`, `testOpenAI`) can be hammered if auth/diagnostics toggles are misconfigured.
- Callable endpoint (`spendUserTokens`) has auth checks but App Check verification is currently not enforced.
- Emulator logs show callable request verification with `app: MISSING` in local runs.

## 2) Target controls

### Control A: App Check enforcement
Scope:
- Enforce App Check at Firebase backend entry points for production traffic.

Implementation intent:
1. Client:
   - Initialize Firebase App Check for Android/iOS/Web in startup path.
   - Use debug provider only in dev/test builds.
2. Backend:
   - For callable: reject requests with missing/invalid app attestation in production mode.
   - For HTTP endpoints: require auth + app verification for cost-bearing routes.

Files likely touched:
- `lib/main.dart`
- `functions/src/index.ts`
- `firebase.json` (if needed for emulator behavior/config)
- docs: `docs/config/environment_variables.md`

### Control B: Rate limiting
Scope:
- Limit expensive endpoints by user and by IP/device fallback.

Recommended policy (initial):
- `generateDisposal`: burst 5/min per uid; sustained 60/hour per uid; anonymous fallback 10/hour per IP.
- `spendUserTokens`: 30/min per uid (anti-replay and abuse guard).
- `testOpenAI`, `clearAllData`: admin-only plus strict low-rate caps.

Implementation approach:
- Add a lightweight limiter service in functions layer:
  - key: `${route}:${uid-or-ip}:${window}`
  - storage: Firestore doc counters with TTL window fields
  - operation: transaction increment + threshold check
- Hard-fail with explicit 429-style response schema.

Files likely touched:
- `functions/src/index.ts`
- optional helper file under `functions/src/` for limiter logic

## 3) Response contract
All blocked requests should return explicit machine-readable payload:
- `error_code`: `APP_CHECK_REQUIRED` or `RATE_LIMITED`
- `retry_after_seconds` for throttled requests
- `request_id` for tracing

## 4) Rollout plan
1. Add instrumentation-only mode (log violations, do not block) for 48h.
2. Enable blocking on `testOpenAI` and `clearAllData` first.
3. Enable blocking on `generateDisposal` and `spendUserTokens`.
4. Monitor reject rates and false positives; tune windows.

## 5) Validation matrix
- Unit/integration:
  - valid app + valid auth => allowed
  - missing app token => blocked in prod mode
  - over limit => blocked with retry-after
- Commands:
  - `npm --prefix functions run test:http-guards`
  - `npm --prefix functions run test:http-guards:emulator`
  - add dedicated limiter tests once implemented

## 6) Non-goals
- No platform migration.
- No full billing redesign.
- No Firestore schema overhaul beyond minimal limiter docs.

## 7) Launch gate
Monetized launch should not proceed until:
- App Check enforcement is active for cost-bearing endpoints.
- Rate limits are active for AI and token spend paths.
- Monitoring dashboard confirms control effectiveness.
