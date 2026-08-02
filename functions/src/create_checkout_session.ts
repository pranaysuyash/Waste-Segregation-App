import * as functions from 'firebase-functions';
import { DodoPayments } from 'dodopayments';
import { shouldEnforceCallableAppCheck } from './helpers';
import { resolveProduct, resolveReturnUrl, isProductEligibleForPlatform } from './product_catalogue';

const asiaSouth1 = functions.region('asia-south1');

const getDodoClient = (): DodoPayments => {
  const apiKey = process.env.DODO_PAYMENTS_API_KEY;
  if (!apiKey) {
    throw new Error('DODO_PAYMENTS_API_KEY not configured');
  }
  return new DodoPayments({ bearerToken: apiKey });
};

interface CreateCheckoutSessionData {
  /** Logical SKU from the product catalogue. Client cannot submit raw provider product IDs. */
  product_id?: string;
  /** Return URL key (must be in server allowlist). */
  return_url?: string;
  /** Client platform for eligibility check. */
  platform?: string;
}

interface CreateCheckoutSessionResponse {
  session_id: string;
  checkout_url: string;
  product_label: string;
  entitlement: string;
}

export const createCheckoutSession = asiaSouth1.https.onCall(async (data: CreateCheckoutSessionData, context): Promise<CreateCheckoutSessionResponse> => {
  if (!context.auth?.uid) {
    throw new functions.https.HttpsError('unauthenticated', 'Authentication required.');
  }

  if (shouldEnforceCallableAppCheck() && !context.app) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'App Check token required.',
    );
  }

  const uid = context.auth.uid;
  const email = context.auth.token?.email as string | undefined;
  const name = context.auth.token?.name as string | undefined;

  // --- Server catalogue validation ---
  // Default to the canonical premium subscription if no SKU provided.
  const logicalSku = data?.product_id || 'waste_premium_monthly';

  const product = resolveProduct(logicalSku);

  // Only subscription products can go through the premium checkout.
  if (product.productType !== 'subscription') {
    throw new functions.https.HttpsError(
      'invalid-argument',
      `Product ${logicalSku} is not a subscription. Use createTokenPurchaseSession for token packs.`,
    );
  }

  // Platform eligibility check.
  const platform = data?.platform ?? 'web';
  if (!isProductEligibleForPlatform(product, platform)) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      `Product ${logicalSku} is not available on ${platform}.`,
    );
  }

  // Resolve return URL from server allowlist.
  const returnUrl = resolveReturnUrl(data?.return_url);

  const client = getDodoClient();

  const session = await client.checkoutSessions.create({
    product_cart: [
      {
        product_id: product.dodoProductId,
        quantity: 1,
      },
    ],
    customer: email ? { email, name: name ?? null } : undefined,
    return_url: returnUrl,
    metadata: {
      firebase_uid: uid,
      logical_sku: logicalSku,
      source: 'waste_segregation_app',
    },
  });

  functions.logger.info('DodoPayments checkout session created', {
    uid,
    sessionId: session.session_id,
    logicalSku,
    dodoProductId: product.dodoProductId,
  });

  return {
    session_id: session.session_id,
    checkout_url: session.checkout_url ?? '',
    product_label: product.label,
    entitlement: product.entitlement,
  };
});
