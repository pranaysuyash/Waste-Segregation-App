# Free vs Paid vs Premium — Behavior Matrix

**Date**: 2026-05-21
**Source**: Synthesised from `docs/review/MONEY_RAIL_TRUTH_TABLE_2026-05-21.csv`, code audit, and `MonetizationAiConfigKeys`.

---

## Tier definitions

| Tier | Identifier | How a user enters |
|------|------------|------------------|
| Free | `free` | Default — no purchase, no subscription |
| Premium | `premium` | Active subscription via in-app purchase or server-verified entitlement |
| Admin | `admin` | Manual Firestore `tier: "admin"` flag (debug/test only) |

---

## Capability matrix

| Capability | Free | Premium | Admin | Enforcement layer | Remote Config key |
|-----------|------|---------|-------|-------------------|-------------------|
| Daily AI classifications | Up to 5/day | Unlimited | Unlimited | Client preflight + server token check | `monetization.free_daily_scan_limit` (default: 5) |
| Token cost per classification | 5 tokens | 3 tokens (50% discount) | 0 tokens | Server `spendUserTokens` callable | `monetization.classify_image_token_cost` (default: 5) |
| Ads shown | Full ads | No ads | No ads | `AdService.shouldShowAds()` | `premium_ad_free_enabled` (default: true) |
| Classification history | Unlimited local | Unlimited local + cloud sync | Unlimited | Hive + Firestore | — |
| Re-analysis / reclassification | 1 free/day | Unlimited | Unlimited | Quota pre-flight check | — |
| Instant/batch analysis speed | Standard | Instant (50% token discount) | Instant | `TokenService.premiumInstantDiscountPercent` | — |
| Token earning from corrections | Yes | Yes (bonus multiplier) | N/A | Server `submitFeedback` callable | — |
| Achievement / gamification | Yes | Yes | Yes | Local + Firestore | — |
| Token wallet | Yes | Yes (refresh bonus) | N/A | `TokenService` + Firestore | — |
| Family / apartment mode | No | Yes | Yes | Firestore family collection | — |
| Community / leaderboard | Yes (username shown) | Yes (anonymous opt-out) | Yes | Firestore | — |
| Data export | No | Yes | Yes | Firestore export callable | — |
| Education / guide content | Yes | Yes | Yes | Local assets | — |
| Premium feature trial | No | No | N/A | `PremiumService` feature flags | — |

---

## Enforcement chain

```
User action
  → Client-side preflight (optional quota check)
    → Remote Config read (current limits)
      → Server-side callable (auth + AppCheck + rate-limit)
        → Token wallet balance check (spendUserTokens)
          → AI/disposal response returned
```

**Key enforcement points:**

1. **Remote Config defaults** — set in `MonetizationAiConfigKeys.defaultRemoteConfigValues()`
2. **Client preflight** — `CostGuardrailService` reads config, checks limits
3. **Server callable** — Firebase Functions with `enforceAuth`/`enforceCallableAppCheck`
4. **Server token spend** — `spendUserTokens` callable validates balance, reserves, deducts
5. **Server rate limit** — `enforceRateLimit()` per bucket (disposal, tokenSpend) with per-user window

---

## Current status

| Rail | Status | Next action |
|------|--------|-------------|
| Remote Config defaults | LIVE | Add advertising frequency / economy config keys |
| Daily scan limit enforcement | LIVE | Already server-enforced via quota config |
| Token spend | LIVE | Mandatory path when Firebase enabled |
| Premium entitlement checks | PARTIAL | Needs real purchase binding |
| Ad suppression for premium | PARTIAL | Tied to non-live premium purchase |
| Ad revenue (AdMob) | PENDING | Replace test IDs with production drop-in |
| IAP checkout | PENDING | Real store purchase (App Store + Play) |
| Token pack purchase | PENDING | SKU model + purchase + server credit |

---

## Key Remote Config keys

| Key | Type | Default | Purpose |
|-----|------|---------|---------|
| `ai.routing.backend_required_release` | bool | `true` | Require server-side AI in release builds |
| `monetization.free_daily_scan_limit` | int | `5` | Max free classifications per day |
| `monetization.classify_image_token_cost` | int | `5` | Token cost per classification |
| `monetization.classify_image_premium_discount_percent` | int | `50` | Premium discount on token cost |
| `premium_ad_free_enabled` | bool | `true` | Suppress ads for premium users |

---

## References

- `lib/config/monetization_ai_config_contract.dart` — canonical key definitions
- `lib/services/token_service.dart` — token wallet, spend, discount logic
- `lib/services/premium_service.dart` — entitlement model
- `lib/services/remote_config_service.dart` — Remote Config wrapper
- `lib/services/cost_guardrail_service.dart` — client-side quota enforcement
- `lib/services/ad_service.dart` — ad display control
- `functions/src/index.ts` — server-side enforcement endpoint
- `docs/review/MONEY_RAIL_TRUTH_TABLE_2026-05-21.csv` — status of each money rail
