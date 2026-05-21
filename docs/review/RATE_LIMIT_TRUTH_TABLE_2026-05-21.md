# Rate Limit Truth Table — 2026-05-21

_Source of truth derived from direct code inspection of `functions/src/index.ts`
and the new `functions/src/rate_limit_config.ts` (created this session).
All line numbers reference the post-edit file state._

---

## 1. Executive Summary

Three documents claim "50 requests/day, 10 requests/minute" for the
`generateDisposal` endpoint.  The actual backend enforces **25 requests / 60
seconds** (IP-scoped token bucket) with no daily counter at all.  The stale
numbers appear only in aspirational code samples inside an archived doc; they
have never been deployed.

Key discrepancies:

| Claim | Source | Reality |
|---|---|---|
| 50 req / day for classification | `api_key_management_and_security.md` line 326 | No daily counter exists in deployed code |
| 10 req / min cap | `api_key_management_and_security.md` line 334 | Default is 25 / min for disposal; 40 / min for token spend |
| classifyImage Cloud Function has rate limits | multiple planning docs | `classifyImage` does not exist as a Cloud Function — classification is client-side Flutter |
| Per-user IP tracking | — | Backend tracks IP for `generateDisposal`, UID for `spendUserTokens`; no cross-user IP grouping |

---

## 2. Current Rate Limit Truth Table

| Endpoint | Kind | Limit Key | Window | Max Requests | Algorithm | Env Var Override | Firestore Key Pattern |
|---|---|---|---|---|---|---|---|
| `generateDisposal` | HTTP (onRequest) | Client IP (`x-forwarded-for` → `req.ip`) | 60 s | 25 | Token bucket (sliding, Firestore-backed) | `RATE_LIMIT_DISPOSAL_MAX_REQUESTS` | `rate_limits/generateDisposal:ip:{ip}` |
| `spendUserTokens` | Callable (onCall) | Firebase UID | 60 s | 40 | Token bucket (sliding, Firestore-backed) | `RATE_LIMIT_SPENDTOKENS_MAX_REQUESTS` | `rate_limits/spendUserTokens:uid:{uid}` |
| `healthCheck` | HTTP | — | — | unlimited | none | — | — |
| `testOpenAI` | HTTP | — | — | unlimited* | none | — | — |
| `clearAllData` | Callable | — | — | unlimited* | none | — | — |
| `processBatchJobs` | Pub/Sub scheduled | — | — | n/a (scheduled) | none | — | — |
| `getBatchStats` | HTTP | — | — | unlimited | none | — | — |
| classifyImage | **does not exist** | — | — | — | — | — | — |

*`testOpenAI` requires `ENABLE_DIAGNOSTIC_ENDPOINTS=true` + admin token; `clearAllData` requires `CLEAR_ALL_DATA_ENABLED=true` + admin custom claim — effectively kill-switched, not rate-limited.

### Shared window constant

`RATE_LIMIT_WINDOW_SECONDS` (default `60`) is the single shared window for
both endpoints.  It is read via `getQuotaConfig()` in `rate_limit_config.ts`
and delegated through the `getRateLimitConfig()` adapter in `index.ts`.

### How the token bucket works (`enforceRateLimit`, index.ts:151–199)

```
1. Read (or create) a Firestore doc at rate_limits/{bucket}:{safeSubject}
   inside a transaction.
2. If the stored windowStartMs is within windowSeconds of now, increment
   count. If count >= maxRequests, return retryAfterSeconds > 0 (429).
3. If the window has expired, reset count to 1 and advance windowStartMs.
4. Write back the new state with serverTimestamp for audit.
```

There is no external in-memory state; the bucket is fully Firestore-backed,
so it is consistent across multiple function instances but adds a Firestore
read+write per request.

---

## 3. Token Wallet Model

### Initial balance

New users receive **50 tokens** as a welcome bonus.

- Server side (`spendUserTokens`, index.ts:537): `const currentBalance = Number(walletRaw.balance ?? 50)` — the `?? 50` default means an account with no tokenWallet sub-document is treated as having 50 tokens.
- Client side (`TokenWallet.newUser()`, `lib/models/token_wallet.dart:32`): `balance: 50`, `totalEarned: 50`.
- `lib/services/token_service.dart:41`: `static const int welcomeBonus = 50` (with comment noting a prior inconsistency of 10 that was reconciled).

### Spend per call

`lib/models/token_wallet.dart:202–215` defines the `AnalysisSpeed` enum:

| Speed | Token cost | Description |
|---|---|---|
| `batch` | 1 token | Queued for batch processing, 2–6 h |
| `instant` | 5 tokens | Real-time analysis |

Premium users get a 50% discount on `instant` calls (`premiumInstantDiscountPercent = 50` in `token_service.dart:47`), reducing it from 5 → 3 tokens (minimum 1).

### Refill / earn policy

There is no automatic token refill.  Tokens are earned via:

- `earnTokens()` called explicitly by the app (daily login bonus, achievements, etc.)
- Daily login bonus: 2 tokens (`TokenService.dailyLoginBonus = 2`, `token_service.dart:42`)
- Points-to-tokens conversion: 100 points = 1 token, max 5 conversions / day (`token_service.dart:38–39`)

### Server-side vs client-side enforcement

- When `TokenService.enableServerSideValidation == true` (default) and Firebase is available, `spendTokens()` calls the `spendUserTokens` Cloud Function, which runs the Firestore transaction and returns the updated wallet. The client then persists the server response.
- When Firebase is unavailable or the user is unauthenticated (guest session), the client falls back to local wallet deduction.
- `enableTokenEnforcement = true` controls whether the balance check blocks analysis at all; setting it `false` bypasses blocking but still logs the skip (Phase 0 telemetry pattern).

### Premium vs free

- `PremiumService.hasActivePremiumPlan()` (`lib/services/premium_service.dart:92`) checks `pro_subscription` or legacy `remove_ads` signal in Hive.
- Premium status affects token cost (instant discount) and future rate-limit tier (multiplier defined in `rate_limit_config.ts` but not yet applied server-side).
- There is currently **no server-side premium verification** before `spendUserTokens`. The Cloud Function trusts the client-supplied `amount` field and only checks balance, not tier.

---

## 4. Stale Doc Discrepancies

### `docs/implementation/ai/api_key_management_and_security.md`

The file already carries a stale banner added 2026-05-21 but the underlying
code samples have not been removed.

**Line 326 (aspirational code sample):**
```javascript
const MAX_DAILY_REQUESTS = 50; // Can be adjusted per user tier
if (userData.count >= MAX_DAILY_REQUESTS) {
```
Reality: No daily counter exists in `functions/src/index.ts`. `enforceRateLimit()` resets on a per-minute window only.

**Line 334–340 (aspirational code sample):**
```javascript
// Check rate limiting (max 10 requests per minute)
const lastRequest = userData.lastRequest.toDate();
const requestsInLastMinute = userData.requestsInLastMinute || 0;
if (requestsInLastMinute >= 10 && ...)
```
Reality: The deployed default is 25/min for disposal (env var `RATE_LIMIT_DISPOSAL_MAX_REQUESTS`), not 10/min. The code in this doc is a different, never-deployed implementation using a different data shape.

**Stale claim — classifyImage rate limits:**
Multiple planning docs (e.g., `APPCHECK_RATE_LIMIT_IMPLEMENTATION_PACKET_2026-05-21.md`) describe rate-limiting a `classifyImage` Cloud Function. That function does not exist. Classification is fully Flutter client-side via `lib/services/ai_service.dart` and peers.

---

## 5. Missing: Daily Quota

**Current state:** No daily counter is implemented anywhere in `functions/src/index.ts`. The rate limiter is purely a per-minute sliding window.

**Why this matters:** Without a daily cap, a client that spaces requests one second apart can consume 25 × 60 × 24 = 36,000 disposal API calls per day from a single IP. The only external cost gate is the OpenAI API quota.

**Implementation path (when needed):**

Add a second Firestore document per subject keyed to the UTC date:

```typescript
// In rate_limit_config.ts — add to QuotaConfig:
dailyDisposalMax?: number;  // default undefined (disabled)

// In enforceRateLimit — additional daily check:
const dayKey = new Date().toISOString().slice(0, 10); // "2026-05-21"
const dailyRef = db.collection('rate_limits_daily').doc(`${bucket}:${subject}:${dayKey}`);
// Transactionally increment and check against cfg.dailyDisposalMax
```

Recommended daily caps when enabled:

| Tier | Disposal / day | Token spends / day |
|---|---|---|
| free | 50 | 200 |
| premium | 200 | unlimited |
| enterprise | custom | custom |

---

## 6. Missing: Per-User Classification Quota

**Current state:** Classification is entirely client-side (Flutter → OpenAI/Gemini direct call). There is no Cloud Function intercepting it, so there is no server-enforced per-user quota on classification calls.

The token economy (`spendUserTokens`) is the current indirect control: users run out of tokens and cannot initiate the analysis UI flow. But:

- `TokenService.enableTokenEnforcement` is a static bool that can be set to `false` at runtime, bypassing all balance checks.
- Guest users with no Firebase account fall back to local wallet deduction, which cannot be audited server-side.
- Nothing prevents a user from calling the underlying AI APIs directly if they extract credentials from the build.

**To add server-side per-user classification quota:** a `classifyImage` Cloud Function (or a token-gate function that must be called before the client can proceed) would be required. This is on the planning roadmap but not implemented.

---

## 7. Recommended Quota Configuration

The following values are proposed for the canonical config once tier-aware rate
limiting is wired into `enforceRateLimit`. They are documented here, not
yet deployed.

### Free tier (current production default)

| Endpoint | Window | Max per window | Daily cap (proposed) |
|---|---|---|---|
| `generateDisposal` (per IP) | 60 s | 25 | 50 |
| `spendUserTokens` (per UID) | 60 s | 40 | 200 |

Rationale: 25/min is sufficient for interactive use (one disposal request takes
~2 s to generate) while limiting programmatic abuse to ~1,500/hr per IP.

### Premium tier (4× multiplier defined in rate_limit_config.ts)

| Endpoint | Window | Max per window | Daily cap (proposed) |
|---|---|---|---|
| `generateDisposal` | 60 s | 100 | 200 |
| `spendUserTokens` | 60 s | 160 | unlimited |

### Post-launch / sustained load adjustment

Once Firestore transaction latency under load is measured, consider:

- Moving rate-limit state to Firebase Realtime Database (lower latency) or a dedicated Redis instance for high-frequency spends.
- Adding a circuit-breaker around `enforceRateLimit` so a Firestore outage does not cascade into blocking all requests.

### Environment variable reference (canonical, as of this session)

| Variable | Default | Affects |
|---|---|---|
| `RATE_LIMIT_WINDOW_SECONDS` | `60` | Both endpoints |
| `RATE_LIMIT_DISPOSAL_MAX_REQUESTS` | `25` | `generateDisposal` |
| `RATE_LIMIT_SPENDTOKENS_MAX_REQUESTS` | `40` | `spendUserTokens` |

---

## 8. Implementation Notes

### What changed in this session

**New file:** `functions/src/rate_limit_config.ts`
- Exports `RateLimitConfig`, `QuotaConfig` interfaces.
- Exports `getQuotaConfig()` — the single canonical factory that reads env vars.
- Exports `QUOTA_TIER_MULTIPLIERS` and `QuotaTier` for future tier-aware enforcement.
- Exports `applyTierMultiplier()` helper (not yet called from index.ts).

**Edit to `functions/src/index.ts`:**
- Line 9: Added `import { getQuotaConfig } from './rate_limit_config';`
- Lines 138–149: `getRateLimitConfig()` replaced with a thin adapter that delegates to `getQuotaConfig()`. The adapter's return shape (`windowSeconds`, `disposalMax`, `spendTokensMax`) is unchanged so its two call sites (lines ~254–260 and ~493–499) required no further edits.
- No logic was changed. TypeScript type-checks clean (`tsc --noEmit` reports 0 errors).

### What still needs to be done

1. **Wire tier multipliers server-side.** `applyTierMultiplier()` exists in `rate_limit_config.ts` but nothing calls it. To apply it, `spendUserTokens` needs to look up the caller's tier from their Firestore profile and pass it to the rate-limit check.

2. **Add daily quota.** See Section 5 above. Not currently implemented.

3. **Server-side premium verification.** `spendUserTokens` trusts the client-supplied `amount` without verifying the caller's premium status. A premium discount applied only client-side can be trivially circumvented.

4. **Retire the aspirational code samples** in `docs/implementation/ai/api_key_management_and_security.md` (lines 304–360) — they describe a never-deployed data shape and mislead anyone reading the doc.

5. **`classifyImage` Cloud Function.** If server-side per-user classification quota is required, this function needs to be created. Currently the token economy is the only soft gate.
