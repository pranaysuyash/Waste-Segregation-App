/**
 * rate_limit_config.ts
 *
 * Single source of truth for all rate-limit and quota configuration.
 *
 * Values are read from environment variables at call time so that they can be
 * overridden per-deployment (e.g. staging vs production) without redeploying
 * the function binary.  Defaults match the values that were previously
 * hard-coded in getRateLimitConfig() inside index.ts.
 *
 * Usage:
 *   import { getQuotaConfig } from './rate_limit_config';
 *   const cfg = getQuotaConfig();
 *   await enforceRateLimit({ ..., maxRequests: cfg.disposal.maxRequests,
 *                                  windowSeconds: cfg.disposal.windowSeconds });
 */

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export interface RateLimitConfig {
  /** Length of the rate-limit window in seconds. */
  windowSeconds: number;
  /** Maximum number of requests allowed within windowSeconds. */
  maxRequests: number;
  /** Firestore collection used to persist window state. */
  firestoreCollection: string;
}

export interface QuotaConfig {
  /** Rate-limit config for the generateDisposal HTTP endpoint (IP-keyed). */
  disposal: RateLimitConfig;
  /** Rate-limit config for the spendUserTokens callable function (UID-keyed). */
  tokenSpend: RateLimitConfig;
  // NOTE: classifyImage is deployed as a callable function and consumes this bucket.
  // Classification is currently Flutter client-side. Add here when added.
}

// ---------------------------------------------------------------------------
// Public factory
// ---------------------------------------------------------------------------

/**
 * Returns the current quota configuration, reading env vars each time it is
 * called so that hot-deployed env changes are picked up without a cold start.
 *
 * Environment variable override map:
 *   RATE_LIMIT_WINDOW_SECONDS          — shared window length (default 60)
 *   RATE_LIMIT_DISPOSAL_MAX_REQUESTS   — generateDisposal max (default 25)
 *   RATE_LIMIT_SPENDTOKENS_MAX_REQUESTS — spendUserTokens max (default 40)
 */
export function getQuotaConfig(): QuotaConfig {
  const windowSeconds = Math.max(
    1,
    Number(process.env.RATE_LIMIT_WINDOW_SECONDS ?? 60),
  );

  return {
    disposal: {
      windowSeconds,
      maxRequests: Math.max(
        1,
        Number(process.env.RATE_LIMIT_DISPOSAL_MAX_REQUESTS ?? 25),
      ),
      firestoreCollection: 'rate_limits',
    },
    tokenSpend: {
      windowSeconds,
      maxRequests: Math.max(
        1,
        Number(process.env.RATE_LIMIT_SPENDTOKENS_MAX_REQUESTS ?? 40),
      ),
      firestoreCollection: 'rate_limits',
    },
  };
}

// ---------------------------------------------------------------------------
// Tier-based quota multipliers (for future premium-tier support)
// ---------------------------------------------------------------------------

/**
 * Per-tier multipliers that scale the base maxRequests values.
 *
 * These are NOT yet applied automatically — they are documented here as the
 * authoritative planned config so that the implementation step is a
 * straightforward application of QUOTA_TIER_MULTIPLIERS[tier] * base.
 *
 * Rationale for values:
 *   free       — 1× baseline, matches current defaults
 *   premium    — 4× to support power users and justify subscription price
 *   enterprise — 10× for B2B / municipal integrations
 */
export const QUOTA_TIER_MULTIPLIERS = {
  free: 1.0,
  premium: 4.0,
  enterprise: 10.0,
} as const;

export type QuotaTier = keyof typeof QUOTA_TIER_MULTIPLIERS;

/**
 * Convenience helper: compute an effective maxRequests for a given base config
 * and user tier.  Not yet called from index.ts; ready to wire in.
 */
export function applyTierMultiplier(
  base: RateLimitConfig,
  tier: QuotaTier,
): RateLimitConfig {
  return {
    ...base,
    maxRequests: Math.ceil(base.maxRequests * QUOTA_TIER_MULTIPLIERS[tier]),
  };
}
