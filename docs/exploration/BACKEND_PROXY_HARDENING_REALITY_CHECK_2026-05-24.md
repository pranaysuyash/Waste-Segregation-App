# Backend Proxy Hardening Reality Check

**Date**: 2026-05-24  
**Status**: Exploration / no-code audit  
**Parent context**: AI learning flywheel foundation, truthful eval gates, canonical router policy  
**Scope**: Identify what backend proxy hardening already exists and what remains open.  
**Non-goal**: No code changes in this pass.

## Why this matters

Earlier exploration framed “backend proxy hardening” as a P0 because classification is the expensive, privacy-sensitive trust boundary. If release builds can bypass the proxy, or if the proxy does not enforce auth, App Check, rate limits, token accounting, cost telemetry, and refund semantics, the AI flywheel can be abused and its metrics become untrustworthy.

This pass checks the current reality against that P0 framing.

## Evidence reviewed

- `docs/exploration/AI_COST_TELEMETRY_AND_GUARDRAILS.md` — cost/guardrail exploration, now partially stale.
- `functions/src/classify_image.ts` — callable classification proxy implementation.
- `functions/src/ops_hardening.ts` — reservation/refund operational monitoring and alerts.
- `functions/test/http_guards.emulator.test.js` — emulator coverage for classify token/free quota/idempotency behavior.
- `functions/test/classify_image.test.js` — classify helper and reservation tests.
- `firestore.rules` — user perceptual hash index rules.
- `docs/audit/RANDOM_DOC_AUDIT_2026-05-23_ai_pipeline_truth_map.md` — prior audit observations, including stale docs and remaining direct-client risk.
- `docs/architecture/CURRENT_AI_ARCHITECTURE.md` — current high-level AI architecture claims.

## What exists now

`functions/src/classify_image.ts` is not a stub. It is a substantial Firebase Callable backend proxy with:

| Area | Current behavior |
|---|---|
| Auth | Requires `context.auth.uid`; unauthenticated calls fail. |
| App Check | Enforced when `REQUIRE_APPCHECK_CALLABLE=true`; emulator enforcement separately gated by `ENFORCE_APPCHECK_IN_EMULATOR`. |
| Input validation | Requires base64 image, allowed MIME types, and max 4 MB pre-encoding image size. |
| Server cache key | Computes server-side SHA-256 and does not trust client hash as cache key. |
| Exact cache | Uses `classifications/{serverHash::region::lang}` with TTL. |
| Near-duplicate protection | Uses client-provided perceptual hash as a server-side per-user duplicate index. |
| Rate limiting | Per-UID `classifyImage` window rate limit, default 10 requests / 60 seconds. |
| Token reservation | Reserves classification tokens before paid provider calls. |
| Free quota | Supports daily free scan quota before charging tokens. |
| Premium discount | Computes premium classification discount server-side from billing/auth entitlement. |
| Idempotency | `requestId` maps to a stable reservation ID to avoid duplicate deductions on retries. |
| Refund | If both providers fail, reserved tokens are refunded unless already consumed. |
| Provider routing | OpenAI primary, Gemini fallback. |
| Cost telemetry | Writes `ai_cost_events` with provider/model/tokens/cost/cache/failure metadata. |
| Cache savings telemetry | Writes zero-cost cache-hit events. |
| Image storage | Does not store raw image bytes in classification cache. |

This means the older blanket claim “no server-side cost recording” in `docs/exploration/AI_COST_TELEMETRY_AND_GUARDRAILS.md` is now stale for `classifyImage`.

## Important discovered nuance

The backend proxy is materially hardened, but it is not equivalent to complete trust-boundary closure.

The current system protects the `classifyImage` path. It does **not automatically prove** every app path uses `classifyImage`, especially specialized flows such as multi-item/region analysis or debug/profile direct-provider paths.

Prior audit notes already flagged this risk: release multi-item region analysis may bypass the backend proxy and expose API keys / lose rate limiting / lose cost tracking. That needs direct verification before launch claims.

## Remaining gaps / risks

### 1. App Check is conditional, not universally fail-closed

`classifyImage` only requires App Check when `REQUIRE_APPCHECK_CALLABLE=true`. That is flexible for dev, but launch readiness depends on production environment configuration. A code audit alone cannot prove prod is fail-closed.

**Closure path**: document and verify production env config; add deploy/preflight check that fails if production callable App Check is disabled.

### 2. Per-user daily hard cost caps are token/quota-based, not USD-cost based

The proxy enforces token reservations and daily free quotas. It writes estimated USD cost events. It does not appear to block based on per-user daily/weekly/monthly USD spend directly.

This may be acceptable if token economics are the canonical cost governor, but it should be stated clearly. If the goal is actual provider-dollar caps, add server-side USD buckets.

### 3. `CLASSIFY_ENFORCE_TOKEN_SPEND` is a kill switch

`isTokenSpendEnforced()` defaults true, but can be disabled. The gamification/token interview explicitly said “keep kill switch for now,” so this is intentional. The caveat is that disabling it makes token economics non-authoritative during that window.

**Closure path**: production changes to the kill switch should be auditable; ops dashboard should show enforcement state.

### 4. Perceptual hash is client-provided

The server validates/sanitizes and indexes the provided pHash, but does not compute pHash from raw image bytes itself. That is useful for honest-client duplicate suppression, not a robust anti-farming guarantee against malicious clients.

This matches the recovered gamification interview decision to defer stronger anti-farming to Phase 2 or later. Do not overclaim this as server-side pHash hardening.

### 5. Cache-hit duplicate path may bypass token charge

Exact cache hits return before token reservation, with a zero-cost event. That is good for cost. It also means the product must decide whether cache hits should earn points/rewards. If rewards are awarded downstream as if it were a fresh scan, users can farm rewards via cached/duplicate scans even without provider cost.

**Closure path**: reward/gamification policy should receive `cachedResult` / duplicate metadata and suppress or reduce rewards.

### 6. Cost events are fire-and-forget

`writeCostEvent()` logs failures but does not block classification if telemetry write fails. This is the right UX choice, but not a perfect accounting ledger.

**Closure path**: keep token reservation ledger as the authoritative user-charge ledger; treat `ai_cost_events` as telemetry, then add reconciliation jobs for missing telemetry if needed.

### 7. Docs are stale in multiple places

`docs/exploration/AI_COST_TELEMETRY_AND_GUARDRAILS.md` still says no server-side cost recording. `docs/EXPLORATION_TOPICS.md` still contains text claiming no equivalent `classifyImage` function exists in a backend proxy section. Those claims conflict with current code.

This matters because future agents may follow stale docs and duplicate or re-plan work that already exists.

## Recommended trust-boundary model

Split backend proxy hardening into four states:

| State | Meaning | Current estimate |
|---|---|---|
| H0 | No backend proxy | Not current. |
| H1 | Proxy exists but advisory | Not current. |
| H2 | Proxy enforces auth/rate/token/cache/cost on its own path | Current for `classifyImage`. |
| H3 | All release classification paths are forced through proxy | Not proven in this pass. |
| H4 | Production config verified fail-closed + ops monitoring reconciles ledgers | Not proven in this pass. |

Current best label: **H2 implemented, H3/H4 need verification**.

## Recommended next exploration task

**Release classification path audit**.

Goal: prove whether every release classification path goes through backend proxy.

Evidence to inspect next:

- `lib/services/ai_service.dart`
- `lib/services/providers/backend_proxy_provider.dart`
- direct OpenAI/Gemini provider classes
- multi-item analysis paths
- production safety config / direct-client guardrails
- tests that assert release mode cannot call direct provider APIs

Acceptance for the audit:

1. List every code path that can classify an image.
2. Mark each as backend-proxy, local-only, debug-only direct provider, or release-risk direct provider.
3. Identify any path that bypasses App Check/rate/token/cost controls in release.
4. Document the smallest implementation fix if a bypass remains.

## Recommended later implementation tasks

1. Update stale docs so they no longer say `classifyImage` is missing or cost recording is client-only.
2. Add a production preflight/assertion for required App Check env toggles.
3. Add a release-mode test proving direct provider classification is blocked or unreachable.
4. Add reward suppression/reduction rules for exact cache hits and near-duplicates.
5. Decide whether USD cost caps are needed in addition to token ledger caps.
6. If anti-farming moves into scope, compute perceptual hash server-side or introduce server-verified image feature signatures.

## Open questions

1. Is the token ledger intended to be the canonical cost cap, or do we also want hard USD spend caps per user/tier?
2. Should cached classifications cost zero tokens, reduced tokens, or no rewards but no cost?
3. Should near-duplicate responses be visible to users as “already classified” or silently reuse cached result?
4. Should `CLASSIFY_ENFORCE_TOKEN_SPEND=false` be allowed in production, or only in emulator/staging?
5. Which path, if any, still performs multi-item region analysis directly from the client in release?

## Missed-anything sweep

- **Instruction compliance**: No code changed; documented repo-local exploration as requested.
- **Canonical paths**: No duplicate backend route proposed. The existing `classifyImage` function remains canonical.
- **End-to-end flow checked**: Auth/App Check → input validation → cache/pHash → rate limit → token reservation → provider fallback → refund/cost/cache response.
- **User value**: Reduces abuse risk and avoids surprise token/cost failures.
- **Business/team value**: Clarifies what is already built so future work does not duplicate backend proxy hardening.
- **Operational value**: Separates user-charge ledger, provider-cost telemetry, and ops alerting responsibilities.
- **Unclosed gaps**: Release-wide path audit still needed; production App Check config not verified; stale docs still need cleanup.
- **Confidence**: High confidence that `classifyImage` is H2-hardened based on direct code inspection. Not claiming H3/H4 because release path and production env were not fully verified in this no-code pass.
