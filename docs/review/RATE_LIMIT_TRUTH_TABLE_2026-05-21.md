# Rate Limit Truth Table - 2026-05-21

_Source of truth derived from direct code inspection of `functions/src/index.ts` and `functions/src/classify_image.ts`._

---

## 1. Executive Summary

The deployed backend now has three meaningful request gates:

- `generateDisposal`: IP-scoped Firestore token bucket at **25 requests / 60 seconds**.
- `spendUserTokens`: UID-scoped Firestore token bucket at **40 requests / 60 seconds**.
- `classifyImage`: UID-scoped Firestore token bucket at **10 requests / 60 seconds**.

There is still **no daily counter** in the backend. All three limits are rolling-window limits.

---

## 2. Current Rate Limit Truth Table

| Endpoint | Kind | Limit Key | Window | Max Requests | Algorithm | Env Var Override | Firestore Key Pattern |
|---|---|---|---|---|---|---|---|
| `generateDisposal` | HTTP (onRequest) | Client IP (`x-forwarded-for` -> `req.ip`) | 60 s | 25 | Token bucket (Firestore-backed) | `RATE_LIMIT_DISPOSAL_MAX_REQUESTS` | `rate_limits/generateDisposal:ip:{ip}` |
| `spendUserTokens` | Callable (onCall) | Firebase UID | 60 s | 40 | Token bucket (Firestore-backed) | `RATE_LIMIT_SPENDTOKENS_MAX_REQUESTS` | `rate_limits/spendUserTokens:uid:{uid}` |
| `classifyImage` | Callable (onCall) | Firebase UID | 60 s | 10 | Token bucket (Firestore-backed) | `CLASSIFY_IMAGE_MAX_REQUESTS` | `rate_limits/classifyImage:uid:{uid}` |
| `healthCheck` | HTTP | - | - | unlimited | none | - | - |
| `testOpenAI` | HTTP | - | - | unlimited* | none | - | - |
| `clearAllData` | Callable | - | - | unlimited* | none | - | - |
| `processBatchJobs` | Pub/Sub scheduled | - | n/a | n/a | none | - | - |
| `getBatchStats` | HTTP | - | - | unlimited | none | - | - |

*`testOpenAI` and `clearAllData` are kill-switched through environment flags and admin gating.

---

## 3. Shared Window Constant

`RATE_LIMIT_WINDOW_SECONDS` defaults to `60` and is used by the shared rate limit helpers for the rolling bucket logic.

---

## 4. Token Wallet Model

This section is unchanged from the existing client-side wallet model: the server still trusts the token spend request amount, and the client persists the returned wallet state. The new callable classification route adds a separate server-side request gate for image analysis, but it does not replace the token wallet model.

---

## 5. Stale Doc Discrepancies

### `docs/implementation/ai/api_key_management_and_security.md`

This file still contains aspirational code snippets that do not match the deployed backend. In particular, the old daily-counter sample is not implemented, and the old client-only classification assumption is no longer true.

### `docs/review/AI_PIPELINE_TRUTH_MAP_2026-05-21.md`

This document is now the canonical AI truth map for the current state. Older notes should be treated as historical context only.

---

## 6. Missing: Daily Quota

**Current state:** No daily counter is implemented anywhere in the backend. The limits are rolling windows only.

**Why this matters:** A client can still consume a large number of requests over a day if it stays under the rolling window cap.

**Implementation path when needed:** add a second daily Firestore document keyed by UTC date for each bucket and check it transactionally alongside the rolling window.

---

## 7. Missing: Per-User Classification Quota

**Current state:** The backend now does have a per-UID classification gate via `classifyImage`, but it is a rolling-window gate, not a daily quota.

If the product needs a stronger per-day cap, add a daily bucket on top of the callable rate limit and keep the client token economy as the front-door UX control.

---

## 8. Recommended Quota Configuration

### Free tier

| Endpoint | Window | Max per window |
|---|---|---|
| `generateDisposal` (per IP) | 60 s | 25 |
| `spendUserTokens` (per UID) | 60 s | 40 |
| `classifyImage` (per UID) | 60 s | 10 |

### Premium tier

Any premium tier expansion should be applied in the shared quota helper, not by duplicating new endpoint logic.

---

## 9. Canonical Environment Variable Reference

| Variable | Default | Affects |
|---|---|---|
| `RATE_LIMIT_WINDOW_SECONDS` | `60` | Shared rolling window |
| `RATE_LIMIT_DISPOSAL_MAX_REQUESTS` | `25` | `generateDisposal` |
| `RATE_LIMIT_SPENDTOKENS_MAX_REQUESTS` | `40` | `spendUserTokens` |
| `CLASSIFY_IMAGE_MAX_REQUESTS` | `10` | `classifyImage` |
| `CLASSIFY_IMAGE_WINDOW_SECONDS` | `60` | `classifyImage` |

---
