// Emulator integration tests for the DodoPayments webhook (C-09/C-10).
//
// Run via: npm run test:emulator  (globbing test/*.emulator.test.js)
// Requires DODO_WEBHOOK_SECRET in the emulator env — set in package.json's
// test:emulator script prefix so the functions runtime sees the same value.
//
// Covers:
//   1. Duplicate delivery credits tokens exactly once (atomic billing_events gate).
//   2. subscription.active grants premium entitlement + records subscription
//      (round-3 finding #4: the case had no switch handler).
//   3. subscription.cancelled revokes premium.
//   4. Invalid signature -> 401, no side effects, no gate doc.
const test = require('node:test');
const assert = require('node:assert/strict');
const admin = require('firebase-admin');
const { Webhook } = require('standardwebhooks');

const PROJECT_ID = process.env.GCLOUD_PROJECT || 'waste-segregation-app-df523';
const FIRESTORE_EMULATOR_HOST = process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080';
const FUNCTIONS_BASE = `http://127.0.0.1:5001/${PROJECT_ID}/asia-south1`;

process.env.FIRESTORE_EMULATOR_HOST = FIRESTORE_EMULATOR_HOST;

if (!admin.apps.length) {
  admin.initializeApp({ projectId: PROJECT_ID });
}

// Must match DODO_WEBHOOK_SECRET in the test:emulator npm script env prefix.
// IMPORTANT: after the `whsec_` prefix the SDK base64-decodes the remainder,
// so the suffix MUST be valid base64 (32 hex chars here). An invalid suffix
// (e.g. underscores or non-multiple-of-4 length) throws at `new Webhook()`
// construction on BOTH the test and the functions runtime.
const WEBHOOK_SECRET = process.env.DODO_WEBHOOK_SECRET || 'whsec_0123456789abcdef0123456789abcdef';

async function resetUser(uid) {
  try {
    await admin.firestore().collection('users').doc(uid).delete();
  } catch {
    // Ignore missing doc in emulator.
  }
  await admin.firestore().collection('users').doc(uid).set({
    id: uid,
    tokenWallet: { balance: 0, totalEarned: 0, totalSpent: 0 },
    lastActive: new Date().toISOString(),
  });
}

function makeTokenPackEvent({ eventId, uid, sku = 'token_pack_medium' }) {
  return {
    type: 'payment.succeeded',
    data: {
      id: eventId,
      payment_id: `pay_${eventId}`,
      subscription_id: null,
      customer: { customer_id: `cus_${eventId}`, email: 'buyer@example.com', name: 'Buyer' },
      metadata: { firebase_uid: uid, logical_sku: sku, product_type: 'token_pack' },
      total_amount: 499,
      currency: 'INR',
      status: 'succeeded',
    },
  };
}

function makeSubscriptionActiveEvent({ eventId, subId, uid, sku = 'waste_premium_monthly' }) {
  return {
    type: 'subscription.active',
    data: {
      id: eventId,
      subscription_id: subId,
      customer: { customer_id: `cus_${eventId}`, email: 'buyer@example.com', name: 'Buyer' },
      metadata: { firebase_uid: uid, logical_sku: sku, product_type: 'subscription' },
      status: 'active',
      current_period_start: '2026-08-01T00:00:00Z',
      current_period_end: '2026-09-01T00:00:00Z',
    },
  };
}

function signWebhook(secret, msgId, timestamp, payload) {
  const wh = new Webhook(secret);
  return wh.sign(msgId, timestamp, payload); // "v1,<hmac>"
}

async function deliverWebhook({ payload, webhookId, signatureOverride }) {
  // Sign the EXACT bytes we send; the function verifies over req.rawBody.
  const rawBody = JSON.stringify(payload);
  const ts = new Date();
  const signature = signatureOverride ?? signWebhook(WEBHOOK_SECRET, webhookId, ts, rawBody);

  const response = await fetch(`${FUNCTIONS_BASE}/dodopaymentsWebhook`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'webhook-id': webhookId,
      'webhook-timestamp': String(Math.floor(ts.getTime() / 1000)),
      'webhook-signature': signature,
    },
    body: rawBody,
  });
  const body = await response.json();
  return { response, body };
}

test('duplicate webhook delivery credits tokens exactly once (C-09/C-10 atomic gate)', async () => {
  const uid = 'it-dodo-token-user';
  const eventId = 'txn_dup_delivery_001';
  await resetUser(uid);

  const payload = makeTokenPackEvent({ eventId, uid });
  const webhookId = 'msg_dup_delivery_001';

  const first = await deliverWebhook({ payload, webhookId });
  assert.equal(first.response.status, 200);
  assert.equal(first.body.success, true);
  assert.equal(first.body.data.status, 'accepted');

  // Same event.id + same webhookId = classic provider redelivery.
  const second = await deliverWebhook({ payload, webhookId });
  assert.equal(second.response.status, 200);
  assert.equal(second.body.data.status, 'duplicate');

  const userSnap = await admin.firestore().collection('users').doc(uid).get();
  const wallet = userSnap.data()?.tokenWallet ?? {};
  assert.equal(wallet.balance, 100, 'tokens must be credited exactly once, not twice');
  assert.equal(wallet.totalEarned, 100);

  const gateSnap = await admin.firestore().collection('billing_events').doc(eventId).get();
  assert.equal(gateSnap.exists, true);
  const gate = gateSnap.data() ?? {};
  assert.equal(gate.uid, uid);
  assert.equal(gate.sku, 'token_pack_medium');
});

test('same event.id under a DIFFERENT webhookId is still treated as duplicate', async () => {
  const uid = 'it-dodo-token-user-2';
  const eventId = 'txn_dup_webhook_id_002';
  await resetUser(uid);

  const payload = makeTokenPackEvent({ eventId, uid });

  const first = await deliverWebhook({ payload, webhookId: 'msg_a_002' });
  assert.equal(first.body.data.status, 'accepted');

  // Redelivery with a rotated webhookId but the same transaction id.
  const second = await deliverWebhook({ payload, webhookId: 'msg_b_002' });
  assert.equal(second.response.status, 200);
  assert.equal(second.body.data.status, 'duplicate');

  const userSnap = await admin.firestore().collection('users').doc(uid).get();
  const wallet = userSnap.data()?.tokenWallet ?? {};
  assert.equal(wallet.balance, 100, 'gate must key on event.data.id, not webhookId');
});

test('subscription.active grants premium entitlement and records subscription (finding #4)', async () => {
  const uid = 'it-dodo-premium-user';
  const eventId = 'evt_sub_active_001';
  const subId = 'sub_dodo_0001';
  await resetUser(uid);

  const payload = makeSubscriptionActiveEvent({ eventId, subId, uid });

  const res = await deliverWebhook({ payload, webhookId: 'msg_sub_active_001' });
  assert.equal(res.response.status, 200);
  assert.equal(res.body.data.status, 'accepted');

  const userSnap = await admin.firestore().collection('users').doc(uid).get();
  const user = userSnap.data() ?? {};
  assert.equal(user.billing?.entitlements?.pro_subscription, true);
  assert.equal(user.subscriptionTier, 'premium');

  const subSnap = await admin.firestore().collection('subscriptions').doc(subId).get();
  assert.equal(subSnap.exists, true);
  const sub = subSnap.data() ?? {};
  assert.equal(sub.userId, uid);
  assert.equal(sub.status, 'active');

  // Duplicate subscription.active must not re-grant (idempotent).
  const dup = await deliverWebhook({ payload, webhookId: 'msg_sub_active_001' });
  assert.equal(dup.body.data.status, 'duplicate');
});

test('subscription.cancelled revokes premium entitlement', async () => {
  const uid = 'it-dodo-cancel-user';
  const eventId = 'evt_sub_cancel_001';
  const subId = 'sub_dodo_0002';

  await admin.firestore().collection('users').doc(uid).set({
    id: uid,
    billing: { entitlements: { pro_subscription: true } },
    subscriptionTier: 'premium',
  });

  const payload = {
    type: 'subscription.cancelled',
    data: {
      id: eventId,
      subscription_id: subId,
      customer: { customer_id: 'cus_cancel_001', email: 'buyer@example.com', name: 'Buyer' },
      metadata: { firebase_uid: uid, logical_sku: 'waste_premium_monthly', product_type: 'subscription' },
      status: 'cancelled',
    },
  };

  const res = await deliverWebhook({ payload, webhookId: 'msg_sub_cancel_001' });
  assert.equal(res.response.status, 200);
  assert.equal(res.body.data.status, 'accepted');

  const userSnap = await admin.firestore().collection('users').doc(uid).get();
  const user = userSnap.data() ?? {};
  assert.equal(user.billing?.entitlements?.pro_subscription, false);
  assert.equal(user.subscriptionTier, 'free');
});

test('unknown event type is acknowledged as ignored WITHOUT creating an idempotency gate', async () => {
  const uid = 'it-dodo-unknown-type';
  const eventId = 'evt_unknown_type_001';
  await resetUser(uid);

  const payload = {
    type: 'subscription.updated',
    data: {
      id: eventId,
      subscription_id: 'sub_dodo_unknown',
      customer: { customer_id: 'cus_unknown_001', email: 'buyer@example.com', name: 'Buyer' },
      metadata: { firebase_uid: uid, logical_sku: 'waste_premium_monthly', product_type: 'subscription' },
      status: 'active',
    },
  };

  const res = await deliverWebhook({ payload, webhookId: 'msg_unknown_type_001' });
  assert.equal(res.response.status, 200);
  assert.equal(res.body.data.status, 'ignored');

  // No gate doc must exist — a future handler for this type must not be
  // blocked by a pre-created gate.
  const gateSnap = await admin.firestore().collection('billing_events').doc(eventId).get();
  assert.equal(gateSnap.exists, false);

  // No entitlement side effects either.
  const userSnap = await admin.firestore().collection('users').doc(uid).get();
  const user = userSnap.data() ?? {};
  assert.equal(user.billing?.entitlements?.pro_subscription, undefined);
});

test('invalid signature is rejected with 401 and no side effects', async () => {
  const uid = 'it-dodo-bad-sig';
  const eventId = 'evt_bad_sig_001';
  await resetUser(uid);

  const payload = makeTokenPackEvent({ eventId, uid });

  const res = await deliverWebhook({
    payload,
    webhookId: 'msg_bad_sig_001',
    signatureOverride: 'v1,ZmFrZXNpZ25hdHVyZWZha2VzaWduYXR1cmU=',
  });
  assert.equal(res.response.status, 401);
  assert.equal(res.body.success, false);
  assert.equal(res.body.error.code, 'WEBHOOK_SIGNATURE_INVALID');

  const userSnap = await admin.firestore().collection('users').doc(uid).get();
  const wallet = userSnap.data()?.tokenWallet ?? {};
  assert.equal(wallet.balance, 0, 'no credit on invalid signature');

  const gateSnap = await admin.firestore().collection('billing_events').doc(eventId).get();
  assert.equal(gateSnap.exists, false);
});
