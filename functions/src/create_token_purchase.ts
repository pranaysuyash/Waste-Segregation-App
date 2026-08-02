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

interface CreateTokenPurchaseData {
  /** Logical SKU from the product catalogue (e.g. token_pack_small). */
  pack_id: string;
  /** Return URL key (must be in server allowlist). */
  return_url?: string;
  /** Client platform for eligibility check. */
  platform?: string;
}

interface CreateTokenPurchaseResponse {
  session_id: string;
  checkout_url: string;
  tokens: number;
  pack_label: string;
}

export const createTokenPurchaseSession = asiaSouth1.https.onCall(
  async (data: CreateTokenPurchaseData, context): Promise<CreateTokenPurchaseResponse> => {
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
    const packId = data?.pack_id;
    if (!packId) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Missing pack_id. Must be a logical SKU from the product catalogue.',
      );
    }

    const product = resolveProduct(packId);

    // Only token_pack products can go through token purchase.
    if (product.productType !== 'token_pack') {
      throw new functions.https.HttpsError(
        'invalid-argument',
        `Product ${packId} is not a token pack. Use createCheckoutSession for subscriptions.`,
      );
    }

    // Platform eligibility check.
    const platform = data?.platform ?? 'web';
    if (!isProductEligibleForPlatform(product, platform)) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        `Product ${packId} is not available on ${platform}.`,
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
        logical_sku: packId,
        product_type: 'token_pack',
        tokens: String(product.tokens),
        source: 'waste_segregation_app',
      },
    });

    functions.logger.info('Token purchase session created', {
      uid,
      sessionId: session.session_id,
      logicalSku: packId,
      tokens: product.tokens,
    });

    return {
      session_id: session.session_id,
      checkout_url: session.checkout_url ?? '',
      tokens: product.tokens,
      pack_label: product.label,
    };
  },
);
