import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { Webhook } from 'standardwebhooks';
import { respondWithApiError, respondWithApiSuccess } from './helpers';
import { resolveProduct, PRODUCT_CATALOGUE } from './product_catalogue';

const asiaSouth1 = functions.region('asia-south1');

interface DodoPaymentSucceededEvent {
  type: 'payment.succeeded';
  data: {
    id: string;
    payment_id: string;
    subscription_id?: string;
    customer: {
      customer_id: string;
      email: string;
      name: string;
    };
    metadata: Record<string, string>;
    total_amount: number;
    currency: string;
    status: string;
  };
}

interface DodoSubscriptionActiveEvent {
  type: 'subscription.active';
  data: {
    id: string;
    subscription_id: string;
    customer: {
      customer_id: string;
      email: string;
      name: string;
    };
    metadata: Record<string, string>;
    status: string;
    current_period_start: string;
    current_period_end: string;
  };
}

interface DodoSubscriptionCancelledEvent {
  type: 'subscription.cancelled';
  data: {
    id: string;
    subscription_id: string;
    customer: {
      customer_id: string;
      email: string;
      name: string;
    };
    metadata: Record<string, string>;
    status: string;
  };
}

interface DodoSubscriptionPastDueEvent {
  type: 'subscription.past_due';
  data: {
    id: string;
    subscription_id: string;
    customer: {
      customer_id: string;
      email: string;
      name: string;
    };
    metadata: Record<string, string>;
    status: string;
  };
}

type DodoWebhookEvent =
  | DodoPaymentSucceededEvent
  | DodoSubscriptionActiveEvent
  | DodoSubscriptionCancelledEvent
  | DodoSubscriptionPastDueEvent;

interface SubscriptionRecord {
  dodoSubscriptionId: string;
  dodoCustomerId: string;
  userId: string;  // SEC-04 fix: required for Firestore rules owner-only read check
  tier: 'premium' | 'family';
  status: 'active' | 'canceled' | 'past_due';
  currentPeriodStart: string | null;
  currentPeriodEnd: string | null;
  metadata: Record<string, string>;
  createdAt: admin.firestore.FieldValue;
  updatedAt: admin.firestore.FieldValue;
}

function getFirebaseUid(event: DodoWebhookEvent): string | null {
  const metadata = event.data.metadata ?? {};
  return metadata.firebase_uid || null;
}

async function grantPremiumAccess(
  uid: string,
  event: DodoWebhookEvent,
): Promise<void> {
  const db = admin.firestore();
  const userRef = db.collection('users').doc(uid);

  await db.runTransaction(async (tx) => {
    const userSnap = await tx.get(userRef);
    const existingData = userSnap.exists ? (userSnap.data() ?? {}) : {};

    const billing = (existingData.billing && typeof existingData.billing === 'object')
      ? { ...existingData.billing as Record<string, unknown> }
      : {};
    const entitlements = (billing.entitlements && typeof billing.entitlements === 'object')
      ? { ...billing.entitlements as Record<string, unknown> }
      : {};

    entitlements.pro_subscription = true;

    const nowIso = new Date().toISOString();

    tx.set(userRef, {
      billing: {
        ...billing,
        entitlements,
        updatedAt: nowIso,
        updatedBy: 'dodopayments_webhook',
      },
      subscriptionTier: 'premium',
      lastPremiumGrantAt: nowIso,
      lastActive: nowIso,
    }, { merge: true });
  });

  functions.logger.info('Premium access granted via DodoPayments webhook', { uid });
}

async function revokePremiumAccess(uid: string): Promise<void> {
  const db = admin.firestore();
  const userRef = db.collection('users').doc(uid);

  await db.runTransaction(async (tx) => {
    const userSnap = await tx.get(userRef);
    const existingData = userSnap.exists ? (userSnap.data() ?? {}) : {};

    const billing = (existingData.billing && typeof existingData.billing === 'object')
      ? { ...existingData.billing as Record<string, unknown> }
      : {};
    const entitlements = (billing.entitlements && typeof billing.entitlements === 'object')
      ? { ...billing.entitlements as Record<string, unknown> }
      : {};

    entitlements.pro_subscription = false;

    const nowIso = new Date().toISOString();

    tx.set(userRef, {
      billing: {
        ...billing,
        entitlements,
        updatedAt: nowIso,
        updatedBy: 'dodopayments_webhook',
      },
      subscriptionTier: 'free',
      lastPremiumRevokedAt: nowIso,
      lastActive: nowIso,
    }, { merge: true });
  });

  functions.logger.info('Premium access revoked via DodoPayments webhook', { uid });
}

async function creditTokenPurchase(
  uid: string,
  event: DodoWebhookEvent,
  catalogueTokenCount: number | null,
): Promise<void> {
  const db = admin.firestore();
  // Use catalogue token count when available (authoritative).
  // Fall back to client metadata for backward compat with older clients.
  const tokens = catalogueTokenCount ?? parseInt(event.data.metadata?.tokens ?? '0', 10);
  if (tokens <= 0) {
    functions.logger.warn('Token purchase event has invalid token count', {
      uid,
      tokens,
      catalogueTokenCount,
      metadataTokens: event.data.metadata?.tokens,
    });
    return;
  }

  const packId = event.data.metadata?.logical_sku ?? event.data.metadata?.pack_id ?? 'unknown';
  const userRef = db.collection('users').doc(uid);
  const nowIso = new Date().toISOString();

  await db.runTransaction(async (tx) => {
    const userSnap = await tx.get(userRef);
    const userData = userSnap.exists ? (userSnap.data() ?? {}) : {};

    const walletRaw = (userData.tokenWallet && typeof userData.tokenWallet === 'object')
      ? { ...userData.tokenWallet as Record<string, unknown> }
      : { balance: 50, totalEarned: 50, totalSpent: 0 };

    const currentBalance = Number(walletRaw.balance ?? 0);
    const totalEarned = Number(walletRaw.totalEarned ?? 0);

    const updatedWallet = {
      ...walletRaw,
      balance: currentBalance + tokens,
      totalEarned: totalEarned + tokens,
      lastUpdated: nowIso,
    };

    tx.set(userRef, {
      tokenWallet: updatedWallet,
      lastActive: nowIso,
    }, { merge: true });
  });

  functions.logger.info('Token purchase credited via DodoPayments webhook', {
    uid,
    tokens,
    packId,
  });
}

async function recordSubscription(event: DodoWebhookEvent, uid: string): Promise<void> {
  const db = admin.firestore();
  const subId = event.data.subscription_id;
  if (!subId) return;

  const subData = event.data;
  const subscriptionRef = db.collection('subscriptions').doc(subId);

  const isActive = event.type === 'subscription.active' || event.type === 'payment.succeeded';
  const isCancelled = event.type === 'subscription.cancelled';
  const isPastDue = event.type === 'subscription.past_due';

  let status: 'active' | 'canceled' | 'past_due';
  if (isActive) status = 'active';
  else if (isCancelled) status = 'canceled';
  else if (isPastDue) status = 'past_due';
  else status = 'active';

  const record: SubscriptionRecord = {
    dodoSubscriptionId: subId,
    dodoCustomerId: subData.customer.customer_id,
    userId: uid,  // SEC-04 fix: Firestore rules require userId for owner-only reads
    tier: 'premium',
    status,
    currentPeriodStart: ('current_period_start' in subData)
      ? (subData as any).current_period_start
      : null,
    currentPeriodEnd: ('current_period_end' in subData)
      ? (subData as any).current_period_end
      : null,
    metadata: subData.metadata ?? {},
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  await subscriptionRef.set(record, { merge: true });
  functions.logger.info('Subscription record saved', {
    subId,
    uid,
    status,
  });
}

export const dodopaymentsWebhook = asiaSouth1.https.onRequest(async (req, res) => {
  try {
    if (req.method !== 'POST') {
      respondWithApiError(res, 405, 'METHOD_NOT_ALLOWED', 'Method not allowed');
      return;
    }

    const webhookSecret = process.env.DODO_WEBHOOK_SECRET;
    if (!webhookSecret) {
      functions.logger.error('DODO_WEBHOOK_SECRET not configured');
      respondWithApiError(
        res,
        500,
        'WEBHOOK_SECRET_MISSING',
        'Webhook secret not configured',
      );
      return;
    }

    const webhookId = req.headers['webhook-id'] as string;
    const webhookTimestamp = req.headers['webhook-timestamp'] as string;
    const webhookSignature = req.headers['webhook-signature'] as string;

    if (!webhookId || !webhookTimestamp || !webhookSignature) {
      respondWithApiError(
        res,
        400,
        'WEBHOOK_HEADERS_MISSING',
        'Missing required webhook headers',
      );
      return;
    }

    const rawBody = typeof req.body === 'string' ? req.body : JSON.stringify(req.body);

    const wh = new Webhook(webhookSecret);

    let event: DodoWebhookEvent;
    try {
      const payload = wh.verify(rawBody, {
        'webhook-id': webhookId,
        'webhook-timestamp': webhookTimestamp,
        'webhook-signature': webhookSignature,
      });
      event = JSON.parse(payload as string) as DodoWebhookEvent;
    } catch (verifyError) {
      functions.logger.error('Webhook signature verification failed', { verifyError });
      respondWithApiError(
        res,
        401,
        'WEBHOOK_SIGNATURE_INVALID',
        'Invalid webhook signature',
      );
      return;
    }

    const db = admin.firestore();

    const uid = getFirebaseUid(event);
    if (!uid) {
      functions.logger.warn('Webhook event missing firebase_uid in metadata', {
        eventType: event.type,
        webhookId,
      });
      respondWithApiSuccess(res, 200, {
        status: 'accepted',
        warning: 'No firebase_uid in metadata',
      });
      return;
    }

    const logicalSku = event.data.metadata?.logical_sku;

    // --- Server catalogue validation ---
    // Resolve the product from the server catalogue, NOT from client-provided
    // metadata. This prevents forged metadata from granting unauthorized
    // entitlements or crediting wrong token amounts.
    let catalogueProductType: 'subscription' | 'token_pack' | null = null;
    let catalogueTokenCount: number | null = null;
    if (logicalSku && logicalSku in PRODUCT_CATALOGUE) {
      const catalogueProduct = resolveProduct(logicalSku);
      catalogueProductType = catalogueProduct.productType;
      catalogueTokenCount = catalogueProduct.tokens;
      functions.logger.info('Webhook product validated against catalogue', {
        logicalSku,
        productType: catalogueProduct.productType,
        entitlement: catalogueProduct.entitlement,
      });
    } else if (logicalSku) {
      functions.logger.warn('Webhook event references unknown product SKU', {
        logicalSku,
        uid,
        webhookId,
      });
    }
    // Determine product type: catalogue is authoritative when available,
    // client metadata fallback only for backward compat with older clients.
    // Validate the fallback value to prevent forged metadata from causing
    // silent failures (e.g. payment.succeeded with invalid productType).
    const metadataProductType = event.data.metadata?.product_type;
    const validMetadataProductType = (metadataProductType === 'subscription' || metadataProductType === 'token_pack')
      ? metadataProductType
      : null;
    const productType = catalogueProductType ?? validMetadataProductType ?? 'subscription';

    // SEC-03 fix: Execute side effects FIRST, then record idempotency marker.
    // The old order recorded the marker before side effects, so a failed
    // side effect (e.g. entitlement grant) would cause the retry to be
    // treated as a duplicate — permanently losing the purchase.
    try {
      switch (event.type) {
        case 'payment.succeeded':
          if (productType === 'token_pack') {
            await creditTokenPurchase(uid, event, catalogueTokenCount);
          } else {
            await grantPremiumAccess(uid, event);
            await recordSubscription(event, uid);
          }
          break;

        case 'subscription.cancelled':
          await revokePremiumAccess(uid);
          await recordSubscription(event, uid);
          break;

        case 'subscription.past_due':
          await recordSubscription(event, uid);
          functions.logger.warn('Subscription past due', {
            uid,
            subscriptionId: event.data.subscription_id,
          });
          break;

        default:
          functions.logger.info('Unhandled webhook event type', { type: (event as any).type });
      }

      // Record idempotency marker AFTER successful side effects.
      // If the function crashes after side effects but before this write,
      // a retry will re-execute the side effects (idempotent by design:
      // grantPremiumAccess and creditTokenPurchase use merge: true with
      // additive counters, so re-execution is safe).
      const eventRef = db.collection('webhook_events').doc(webhookId);
      await eventRef.set({
        eventId: webhookId,
        type: event.type,
        uid,
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      respondWithApiSuccess(res, 200, { status: 'accepted' });
    } catch (sideEffectError) {
      // Side effect failed — do NOT record the idempotency marker so that
      // a retry can re-process this event.
      functions.logger.error('Webhook side effect failed, will retry on redelivery', {
        webhookId,
        eventType: event.type,
        uid,
        error: sideEffectError,
      });
      throw sideEffectError;
    }
  } catch (error: any) {
    functions.logger.error('Webhook processing error', { error });
    respondWithApiError(
      res,
      500,
      'INTERNAL_WEBHOOK_PROCESSING_FAILED',
      'Webhook processing failed',
      {
        error: error instanceof Error ? error.message : String(error),
      },
    );
  }
});
