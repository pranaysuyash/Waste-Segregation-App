/**
 * Server-owned product catalogue.
 *
 * Clients submit a logical SKU. The server resolves it to provider-specific
 * product IDs, amounts, and eligibility rules. This prevents clients from
 * manipulating pricing or accessing products they shouldn't see.
 */

export interface ProductEntry {
  /** Logical SKU the client submits. */
  logicalSku: string;
  /** DodoPayments product ID (for web checkout). */
  dodoProductId: string;
  /** Product type: subscription or token_pack. */
  productType: 'subscription' | 'token_pack';
  /** Fixed amount in minor currency units (null = dynamic from provider). */
  amountMinor: number | null;
  /** ISO currency code. */
  currency: string;
  /** Token quantity for token_pack products (0 for subscriptions). */
  tokens: number;
  /** Eligible platforms: 'all', 'web_only', 'android_only', 'ios_only'. */
  eligiblePlatforms: 'all' | 'web_only' | 'android_only' | 'ios_only';
  /** The entitlement granted on purchase. */
  entitlement: string;
  /** Refund/reversal policy label. */
  refundPolicy: 'no_refund' | 'grace_period' | 'prorated';
  /** Human-readable label. */
  label: string;
}

/**
 * Canonical product catalogue.
 *
 * To add a new product:
 * 1. Add an entry here with a unique logicalSku
 * 2. Create the corresponding product in DodoPayments dashboard
 * 3. Set DODO_PREMIUM_PRODUCT_ID env var or add the Dodo product ID here
 */
export const PRODUCT_CATALOGUE: Record<string, ProductEntry> = {
  // --- Subscription products ---
  waste_premium_monthly: {
    logicalSku: 'waste_premium_monthly',
    dodoProductId: process.env.DODO_PREMIUM_PRODUCT_ID ?? '',
    productType: 'subscription',
    amountMinor: null, // Dynamic from DodoPayments
    currency: 'INR',
    tokens: 0,
    eligiblePlatforms: 'all',
    entitlement: 'pro_subscription',
    refundPolicy: 'grace_period',
    label: 'ReLoop Premium — Monthly',
  },

  // --- Token pack products ---
  token_pack_small: {
    logicalSku: 'token_pack_small',
    dodoProductId: 'token_pack_small',
    productType: 'token_pack',
    amountMinor: null,
    currency: 'INR',
    tokens: 25,
    eligiblePlatforms: 'all',
    entitlement: 'token_pack',
    refundPolicy: 'no_refund',
    label: 'Small Token Pack (25 tokens)',
  },
  token_pack_medium: {
    logicalSku: 'token_pack_medium',
    dodoProductId: 'token_pack_medium',
    productType: 'token_pack',
    amountMinor: null,
    currency: 'INR',
    tokens: 100,
    eligiblePlatforms: 'all',
    entitlement: 'token_pack',
    refundPolicy: 'no_refund',
    label: 'Medium Token Pack (100 tokens)',
  },
  token_pack_large: {
    logicalSku: 'token_pack_large',
    dodoProductId: 'token_pack_large',
    productType: 'token_pack',
    amountMinor: null,
    currency: 'INR',
    tokens: 500,
    eligiblePlatforms: 'all',
    entitlement: 'token_pack',
    refundPolicy: 'no_refund',
    label: 'Large Token Pack (500 tokens)',
  },
};

/**
 * Resolves a logical SKU to a product entry.
 * Throws if the SKU is unknown.
 */
export function resolveProduct(logicalSku: string): ProductEntry {
  const product = PRODUCT_CATALOGUE[logicalSku];
  if (!product) {
    throw new Error(
      `Unknown product SKU: ${logicalSku}. ` +
      `Valid SKUs: ${Object.keys(PRODUCT_CATALOGUE).join(', ')}`
    );
  }
  return product;
}

/**
 * Checks if a product is eligible for the given platform.
 */
export function isProductEligibleForPlatform(
  product: ProductEntry,
  platform: string,
): boolean {
  if (product.eligiblePlatforms === 'all') return true;

  const normalized = platform.toLowerCase().trim();
  switch (product.eligiblePlatforms) {
    case 'web_only':
      return normalized === 'web' || normalized === 'browser';
    case 'android_only':
      return normalized === 'android';
    case 'ios_only':
      return normalized === 'ios';
    default:
      return false;
  }
}

/**
 * Server-allowlisted return URLs.
 * Clients cannot specify arbitrary return URLs.
 */
const ALLOWED_RETURN_URLS: Record<string, string> = {
  premium_success: 'https://waste-segregation-app-df523.web.app/premium/success',
  wallet: 'https://waste-segregation-app-df523.web.app/wallet',
};

/**
 * Resolves a return URL key to a full URL.
 * Falls back to premium_success if key is unknown.
 */
export function resolveReturnUrl(key: string | undefined): string {
  if (!key) return ALLOWED_RETURN_URLS.premium_success;
  return ALLOWED_RETURN_URLS[key] ?? ALLOWED_RETURN_URLS.premium_success;
}
