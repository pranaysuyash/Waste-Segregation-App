import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { Webhook } from 'standardwebhooks';

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
): Promise<void> {
  const db = admin.firestore();
  const tokens = parseInt(event.data.metadata?.tokens ?? '0', 10);
  if (tokens <= 0) {
    functions.logger.warn('Token purchase event has invalid token count', {
      uid,
      tokens: event.data.metadata?.tokens,
    });
    return;
  }

  const packId = event.data.metadata?.pack_id ?? 'unknown';
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
      res.status(405).json({ error: 'Method not allowed' });
      return;
    }

    const webhookSecret = process.env.DODO_WEBHOOK_SECRET;
    if (!webhookSecret) {
      functions.logger.error('DODO_WEBHOOK_SECRET not configured');
      res.status(500).json({ error: 'Webhook secret not configured' });
      return;
    }

    const webhookId = req.headers['webhook-id'] as string;
    const webhookTimestamp = req.headers['webhook-timestamp'] as string;
    const webhookSignature = req.headers['webhook-signature'] as string;

    if (!webhookId || !webhookTimestamp || !webhookSignature) {
      res.status(400).json({ error: 'Missing required webhook headers' });
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
      res.status(401).json({ error: 'Invalid webhook signature' });
      return;
    }

    const db = admin.firestore();

    // Idempotency: skip if we already processed this event
    const eventRef = db.collection('webhook_events').doc(webhookId);
    const existingEvent = await eventRef.get();
    if (existingEvent.exists) {
      functions.logger.info('Duplicate webhook event, skipping', { webhookId });
      res.status(200).json({ status: 'duplicate' });
      return;
    }

    await eventRef.set({
      eventId: webhookId,
      type: event.type,
      receivedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    const uid = getFirebaseUid(event);
    if (!uid) {
      functions.logger.warn('Webhook event missing firebase_uid in metadata', {
        eventType: event.type,
        webhookId,
      });
      res.status(200).json({ status: 'accepted', warning: 'No firebase_uid in metadata' });
      return;
    }

    const productType = event.data.metadata?.product_type;

    switch (event.type) {
      case 'payment.succeeded':
        if (productType === 'token_pack') {
          await creditTokenPurchase(uid, event);
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

    res.status(200).json({ status: 'accepted' });
  } catch (error: any) {
    functions.logger.error('Webhook processing error', { error });
    res.status(500).json({ error: 'Webhook processing failed' });
  }
});
