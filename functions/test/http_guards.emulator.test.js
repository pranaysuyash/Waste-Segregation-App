const test = require('node:test');
const assert = require('node:assert/strict');
const { createHash } = require('node:crypto');
const admin = require('firebase-admin');

const PROJECT_ID = process.env.GCLOUD_PROJECT || 'waste-segregation-app-df523';
const AUTH_EMULATOR_HOST = process.env.FIREBASE_AUTH_EMULATOR_HOST || '127.0.0.1:9099';
const FIRESTORE_EMULATOR_HOST = process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080';
const FUNCTIONS_BASE = `http://127.0.0.1:5001/${PROJECT_ID}/asia-south1`;

process.env.FIREBASE_AUTH_EMULATOR_HOST = AUTH_EMULATOR_HOST;
process.env.FIRESTORE_EMULATOR_HOST = FIRESTORE_EMULATOR_HOST;

if (!admin.apps.length) {
  admin.initializeApp({ projectId: PROJECT_ID });
}

async function signInWithPassword(email, password) {
  const response = await fetch(
    `http://${AUTH_EMULATOR_HOST}/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=fake-api-key`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password, returnSecureToken: true }),
    }
  );

  const data = await response.json();
  if (!response.ok) {
    throw new Error(`signInWithPassword failed: ${response.status} ${JSON.stringify(data)}`);
  }
  return data.idToken;
}

async function createOrResetUser({ uid, email, password, adminClaim, customClaims }) {
  try {
    await admin.auth().deleteUser(uid);
  } catch {
    // Ignore missing user in emulator.
  }

  await admin.auth().createUser({ uid, email, password });

  const mergedClaims = {
    ...(customClaims && typeof customClaims === 'object' ? customClaims : {}),
    ...(adminClaim ? { admin: true } : {}),
  };

  if (Object.keys(mergedClaims).length > 0) {
    await admin.auth().setCustomUserClaims(uid, mergedClaims);
  }

  return signInWithPassword(email, password);
}

async function upsertUserProfile(uid, tokenBalance) {
  await admin.firestore().collection('users').doc(uid).set({
    id: uid,
    tokenWallet: {
      balance: tokenBalance,
      totalEarned: tokenBalance,
      totalSpent: 0,
      lastUpdated: new Date().toISOString(),
      dailyConversionsUsed: 0,
      lastConversionDate: null,
    },
    tokenTransactions: [],
    lastActive: new Date().toISOString(),
  }, { merge: true });
}

async function invokeCallable(functionName, token, data) {
  const response = await fetch(`${FUNCTIONS_BASE}/${functionName}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({ data }),
  });
  const body = await response.json();
  return { response, body };
}

function makeTinyPngBase64() {
  // 1x1 PNG
  return 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO6QmNsAAAAASUVORK5CYII=';
}

test('testOpenAI enforces admin token and returns minimal payload for admin', async () => {
  const adminToken = await createOrResetUser({
    uid: 'it-admin',
    email: 'it-admin@example.com',
    password: 'Test1!',
    adminClaim: true,
  });

  const nonAdminToken = await createOrResetUser({
    uid: 'it-user',
    email: 'it-user@example.com',
    password: 'Test1!',
    adminClaim: false,
  });

  const deniedRes = await fetch(`${FUNCTIONS_BASE}/testOpenAI`, {
    headers: { Authorization: `Bearer ${nonAdminToken}` },
  });
  const deniedBody = await deniedRes.json();
  assert.equal(deniedRes.status, 403);
  assert.equal(deniedBody.error, 'Forbidden: admin token required');

  const adminRes = await fetch(`${FUNCTIONS_BASE}/testOpenAI`, {
    headers: { Authorization: `Bearer ${adminToken}` },
  });
  const adminBody = await adminRes.json();
  assert.equal(adminRes.status, 200);
  assert.equal(adminBody.status, 'ok');
  assert.equal(typeof adminBody.openaiConfigured, 'boolean');
  assert.equal(typeof adminBody.timestamp, 'string');
  assert.equal('keySource' in adminBody, false);
  assert.equal('keyLength' in adminBody, false);
});

test('generateDisposal rejects missing token and accepts authenticated request through auth gate', async () => {
  const userToken = await createOrResetUser({
    uid: 'it-material-user',
    email: 'it-material@example.com',
    password: 'Test1!',
    adminClaim: false,
  });

  const noTokenRes = await fetch(`${FUNCTIONS_BASE}/generateDisposal`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ materialId: 'mat-1', material: 'paper' }),
  });
  const noTokenBody = await noTokenRes.json();
  assert.equal(noTokenRes.status, 401);
  assert.match(noTokenBody.error, /Bearer token required/);

  const authedRes = await fetch(`${FUNCTIONS_BASE}/generateDisposal`, {
    method: 'GET',
    headers: { Authorization: `Bearer ${userToken}` },
  });
  const authedBody = await authedRes.json();
  assert.equal(authedRes.status, 405);
  assert.equal(authedBody.error, 'Method not allowed');
});

test('spendUserTokens callable enforces auth and deducts from wallet server-side', async () => {
  const token = await createOrResetUser({
    uid: 'it-spend-user',
    email: 'it-spend-user@example.com',
    password: 'Test1!',
    adminClaim: false,
  });
  await upsertUserProfile('it-spend-user', 50);

  const unauthorized = await fetch(`${FUNCTIONS_BASE}/spendUserTokens`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ data: { amount: 3, description: 'Instant AI analysis' } }),
  });
  assert.equal(unauthorized.status, 401);

  const spendRes = await fetch(`${FUNCTIONS_BASE}/spendUserTokens`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({ data: { amount: 3, description: 'Instant AI analysis' } }),
  });
  const spendBody = await spendRes.json();
  assert.equal(spendRes.status, 200);
  const payload = spendBody.result ?? spendBody;
  assert.equal(payload.success, true);
  assert.equal(payload.wallet.balance, 47);
  assert.equal(payload.transaction.delta, -3);
});

test('spendUserTokens applies claims-based premium fallback when Firestore billing entitlement is absent', async () => {
  const token = await createOrResetUser({
    uid: 'it-premium-claims-fallback',
    email: 'it-premium-claims-fallback@example.com',
    password: 'Test1!',
    adminClaim: false,
    customClaims: { pro_subscription: true },
  });
  await upsertUserProfile('it-premium-claims-fallback', 10);

  const spendRes = await fetch(`${FUNCTIONS_BASE}/spendUserTokens`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({
      data: {
        amount: 4,
        description: 'Instant AI analysis',
        operationType: 'instant',
      },
    }),
  });

  const spendBody = await spendRes.json();
  assert.equal(spendRes.status, 200);

  const payload = spendBody.result ?? spendBody;
  assert.equal(payload.success, true);
  assert.equal(payload.wallet.balance, 7);
  assert.equal(payload.transaction.delta, -3);
  assert.equal(payload.transaction.metadata.spendAuthoritySource, 'claims_fallback');
  assert.equal(payload.transaction.metadata.serverTier, 'premium');
  assert.equal(payload.transaction.metadata.authorizedAmount, 3);

  const ledgerSnap = await admin
    .firestore()
    .collection('token_spend_ledger')
    .doc(payload.ledgerId)
    .get();
  assert.equal(ledgerSnap.exists, true);
  const ledger = ledgerSnap.data() ?? {};
  assert.equal(ledger.metadata?.spendAuthoritySource, 'claims_fallback');
  assert.equal(ledger.metadata?.serverTier, 'premium');
});

test('createBatchAiJob callable enforces auth and user-owned batch image path', async () => {
  const unauthorizedRes = await fetch(`${FUNCTIONS_BASE}/createBatchAiJob`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      data: {
        imageUrl: 'https://firebasestorage.googleapis.com/v0/b/demo/o/batch_images%2Fit-batch-user%2Fx.jpg?alt=media',
      },
    }),
  });
  assert.equal(unauthorizedRes.status, 401);

  const token = await createOrResetUser({
    uid: 'it-batch-user',
    email: 'it-batch-user@example.com',
    password: 'Test1!',
    adminClaim: false,
  });

  const forbiddenRes = await fetch(`${FUNCTIONS_BASE}/createBatchAiJob`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({
      data: {
        imageUrl: 'https://firebasestorage.googleapis.com/v0/b/demo/o/batch_images%2Fsomeone-else%2Fx.jpg?alt=media',
      },
    }),
  });

  const forbiddenBody = await forbiddenRes.json();
  assert.equal(forbiddenRes.status, 403);
  const message = forbiddenBody?.error?.message ?? '';
  assert.match(message, /imageUrl must reference an authenticated user-owned batch_images path/i);
});

test('classifyImage denies execution when token wallet is insufficient', async () => {
  const token = await createOrResetUser({
    uid: 'it-classify-no-tokens',
    email: 'it-classify-no-tokens@example.com',
    password: 'Test1!',
    adminClaim: false,
  });
  await upsertUserProfile('it-classify-no-tokens', 0);

  const { response, body } = await invokeCallable('classifyImage', token, {
    imageBase64: makeTinyPngBase64(),
    mimeType: 'image/png',
    region: 'Bangalore, IN',
    lang: 'en',
  });

  assert.equal(response.status, 400);
  const message = body?.error?.message ?? '';
  assert.match(message, /Insufficient tokens/i);
});

test('classifyImage cache hit does not charge tokens when classification is already cached', async () => {
  const token = await createOrResetUser({
    uid: 'it-classify-cache-hit',
    email: 'it-classify-cache-hit@example.com',
    password: 'Test1!',
    adminClaim: false,
  });
  await upsertUserProfile('it-classify-cache-hit', 12);

  const imageBase64 = makeTinyPngBase64();
  const region = 'Bangalore, IN';
  const lang = 'en';
  const serverHash = createHash('sha256').update(imageBase64).digest('hex');
  const cacheDocId = `${serverHash}::${region}::${lang}`;
  const nowEpoch = Math.floor(Date.now() / 1000);

  await admin.firestore().collection('classifications').doc(cacheDocId).set({
    itemName: 'Cached bottle',
    category: 'Dry Waste',
    explanation: 'Cached classification',
    disposalInstructions: {
      primaryMethod: 'Recycle',
      steps: ['Clean item', 'Place in dry waste bin'],
      hasUrgentTimeframe: false,
    },
    region,
    visualFeatures: ['transparent bottle'],
    alternatives: [],
    cachedAtEpoch: nowEpoch,
    provider: 'cache',
    model: 'cache',
  });

  const { response, body } = await invokeCallable('classifyImage', token, {
    imageBase64,
    mimeType: 'image/png',
    region,
    lang,
  });

  assert.equal(response.status, 200);
  const classification = body?.result?.classification ?? body?.classification;
  assert.equal(classification?.itemName, 'Cached bottle');

  const userSnap = await admin.firestore().collection('users').doc('it-classify-cache-hit').get();
  const wallet = userSnap.data()?.tokenWallet;
  assert.equal(wallet?.balance, 12);
});

test('classifyImage idempotency key prevents duplicate token deductions on retry', async () => {
  const token = await createOrResetUser({
    uid: 'it-classify-idempotent',
    email: 'it-classify-idempotent@example.com',
    password: 'Test1!',
    adminClaim: false,
  });
  await upsertUserProfile('it-classify-idempotent', 20);

  const requestId = 'retry-idempotency-key-0001';
  const payload = {
    imageBase64: makeTinyPngBase64(),
    mimeType: 'image/png',
    region: 'Idempotency-Test-Region-1',
    lang: 'en',
    requestId,
  };

  const first = await invokeCallable('classifyImage', token, payload);

  const firstWalletSnap = await admin.firestore().collection('users').doc('it-classify-idempotent').get();
  const firstBalance = Number(firstWalletSnap.data()?.tokenWallet?.balance ?? -1);

  const second = await invokeCallable('classifyImage', token, payload);

  const secondWalletSnap = await admin.firestore().collection('users').doc('it-classify-idempotent').get();
  const secondBalance = Number(secondWalletSnap.data()?.tokenWallet?.balance ?? -1);

  assert.equal(secondBalance, firstBalance);

  if (second.response.status === 200) {
    const meta = second.body?.result?.meta ?? second.body?.meta ?? {};
    const reused = meta.tokenReservationReused === true;
    const cacheHit = meta.cachedResult === true;
    assert.ok(reused || cacheHit);
  } else {
    assert.ok(second.response.status >= 400);
  }

  const reservationId = createHash('sha256')
    .update(`classifyImage|it-classify-idempotent|${requestId}`)
    .digest('hex')
    .slice(0, 48);
  const reservationSnap = await admin
    .firestore()
    .collection('classify_token_reservations')
    .doc(reservationId)
    .get();
  assert.equal(reservationSnap.exists, true);

  const firstMessage = first.body?.error?.message ?? '';
  assert.ok(!/Insufficient tokens/i.test(firstMessage));
});
