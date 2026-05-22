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

const DEFAULT_PRODUCT_ID = process.env.DODO_PREMIUM_PRODUCT_ID ?? '';

interface CreateCheckoutSessionData {
  product_id?: string;
  return_url?: string;
}

interface CreateCheckoutSessionResponse {
  session_id: string;
  checkout_url: string;
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

  const productId = data?.product_id || DEFAULT_PRODUCT_ID;
  if (!productId) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Missing product_id. Set DODO_PREMIUM_PRODUCT_ID env var or pass product_id in data.',
    );
  }

  const returnUrl = data?.return_url ||
    'https://waste-segregation-app-df523.web.app/premium/success';

  const client = getDodoClient();

  const session = await client.checkoutSessions.create({
    product_cart: [
      {
        product_id: productId,
        quantity: 1,
      },
    ],
    customer: email ? { email, name: name ?? null } : undefined,
    return_url: returnUrl,
    metadata: {
      firebase_uid: uid,
      source: 'waste_segregation_app',
    },
  });

  functions.logger.info('DodoPayments checkout session created', {
    uid,
    sessionId: session.session_id,
    productId,
  });

  return {
    session_id: session.session_id,
    checkout_url: session.checkout_url ?? '',
  };
});
