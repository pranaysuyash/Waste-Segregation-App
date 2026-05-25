import * as functions from 'firebase-functions';
import { DodoPayments } from 'dodopayments';

const asiaSouth1 = functions.region('asia-south1');

const getDodoClient = (): DodoPayments => {
  const apiKey = process.env.DODO_PAYMENTS_API_KEY;
  if (!apiKey) {
    throw new Error('DODO_PAYMENTS_API_KEY not configured');
  }
  return new DodoPayments({ bearerToken: apiKey });
};

const parseBoolEnv = (value: string | undefined, fallback = false): boolean => {
  if (value == null) return fallback;
  const normalized = value.trim().toLowerCase();
  return ['true', '1', 'yes', 'on'].includes(normalized);
};

const shouldEnforceCallableAppCheck = (): boolean => {
  const requireAppCheck = parseBoolEnv(process.env.REQUIRE_APPCHECK_CALLABLE, false);
  if (!requireAppCheck) return false;
  if (process.env.FUNCTIONS_EMULATOR === 'true') {
    return parseBoolEnv(process.env.ENFORCE_APPCHECK_IN_EMULATOR, false);
  }
  return true;
};

const TOKEN_PACKS: Record<string, { tokens: number; label: string }> = {
  'token_pack_small': { tokens: 25, label: 'Small Pack' },
  'token_pack_medium': { tokens: 100, label: 'Medium Pack' },
  'token_pack_large': { tokens: 500, label: 'Large Pack' },
};

interface CreateTokenPurchaseData {
  pack_id: string;
  return_url?: string;
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

    const packId = data?.pack_id;
    if (!packId) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Missing pack_id. Options: token_pack_small, token_pack_medium, token_pack_large',
      );
    }

    const pack = TOKEN_PACKS[packId];
    if (!pack) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        `Unknown pack_id: ${packId}. Options: ${Object.keys(TOKEN_PACKS).join(', ')}`,
      );
    }

    const returnUrl = data?.return_url ||
      'https://waste-segregation-app-df523.web.app/wallet';

    const client = getDodoClient();
    const session = await client.checkoutSessions.create({
      product_cart: [
        {
          product_id: packId,
          quantity: 1,
        },
      ],
      customer: email ? { email, name: name ?? null } : undefined,
      return_url: returnUrl,
      metadata: {
        firebase_uid: uid,
        product_type: 'token_pack',
        pack_id: packId,
        tokens: String(pack.tokens),
        source: 'waste_segregation_app',
      },
    });

    functions.logger.info('Token purchase session created', {
      uid,
      sessionId: session.session_id,
      packId,
      tokens: pack.tokens,
    });

    return {
      session_id: session.session_id,
      checkout_url: session.checkout_url ?? '',
      tokens: pack.tokens,
      pack_label: pack.label,
    };
  },
);
