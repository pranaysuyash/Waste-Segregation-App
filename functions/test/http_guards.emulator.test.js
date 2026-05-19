const test = require('node:test');
const assert = require('node:assert/strict');
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

async function createOrResetUser({ uid, email, password, adminClaim }) {
  try {
    await admin.auth().deleteUser(uid);
  } catch {
    // Ignore missing user in emulator.
  }

  await admin.auth().createUser({ uid, email, password });
  if (adminClaim) {
    await admin.auth().setCustomUserClaims(uid, { admin: true });
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
