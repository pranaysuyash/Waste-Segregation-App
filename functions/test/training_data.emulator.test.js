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

const { __testables } = require('../lib/training_data.js');

async function signInWithPassword(email, password) {
  const response = await fetch(
    `http://${AUTH_EMULATOR_HOST}/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=fake-api-key`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password, returnSecureToken: true }),
    },
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
    // ignore missing
  }

  await admin.auth().createUser({ uid, email, password });
  if (adminClaim) {
    await admin.auth().setCustomUserClaims(uid, { admin: true });
  }
  return signInWithPassword(email, password);
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

async function putUserProfile(uid, role = 'guest') {
  await admin.firestore().collection('users').doc(uid).set({
    id: uid,
    role,
    trainingConsent: {
      enabled: true,
      policyVersion: 'training-data-v1',
      grantedAt: new Date().toISOString(),
      revokedAt: null,
      source: 'test',
    },
  }, { merge: true });
}

test('training callable flow enforces consent/admin and updates candidate lifecycle', async () => {
  const userToken = await createOrResetUser({
    uid: 'it-training-user',
    email: 'it-training-user@example.com',
    password: 'Test1!',
    adminClaim: false,
  });
  const adminToken = await createOrResetUser({
    uid: 'it-training-admin',
    email: 'it-training-admin@example.com',
    password: 'Test1!',
    adminClaim: true,
  });

  await putUserProfile('it-training-user', 'guest');
  await putUserProfile('it-training-admin', 'admin');
  await putUserProfile('it-training-child', 'child');

  const classificationId = 'it-training-classification-001';
  const enqueue = await invokeCallable('enqueueTrainingCandidate', userToken, {
    captureSource: 'classification_completed',
    classification: {
      classificationId,
      itemName: 'Pizza box',
      category: 'Dry Waste',
      subcategory: 'Cardboard',
      confidence: 0.81,
      modelSource: 'backend',
      modelVersion: 'test-v1',
      region: 'Bangalore, IN',
      barcodePresent: false,
    },
    consent: {
      enabled: true,
      policyVersion: 'training-data-v1',
      grantedAt: new Date().toISOString(),
      source: 'test',
    },
    image: {
      contentHash: 'hash-test-001',
      width: 640,
      height: 480,
      exifStripped: true,
      redactionStatus: 'not_collected_metadata_only',
      rawRetentionDays: 0,
    },
  });
  assert.equal(enqueue.response.status, 200);
  const candidateId = enqueue.body?.result?.candidateId ?? enqueue.body?.candidateId;
  assert.ok(candidateId && candidateId.startsWith('candidate_'));

  const candidateBefore = await admin.firestore().collection('training_candidates').doc(candidateId).get();
  assert.equal(candidateBefore.exists, true);
  assert.equal(candidateBefore.get('dataset.eligible'), false);

  const feedback = await invokeCallable('attachTrainingLabelFeedback', userToken, {
    classificationId,
    feedback: {
      id: 'fb-001',
      userSuggestedCategory: 'Wet Waste',
      userSuggestedItemName: 'Greasy pizza box',
      userSuggestedMaterial: 'cardboard',
      userNotes: 'Correction with contact me at me@example.com',
      feedbackTimestamp: new Date().toISOString(),
    },
  });
  assert.equal(feedback.response.status, 200);
  const labelAfterFeedback = await admin.firestore().collection('training_labels').doc(candidateId).get();
  assert.equal(labelAfterFeedback.get('labelState'), 'user_corrected');
  assert.equal(labelAfterFeedback.get('userCorrection.correctedCategory'), 'Wet Waste');
  const candidateAfterFeedback = await admin.firestore().collection('training_candidates').doc(candidateId).get();
  assert.equal(candidateAfterFeedback.get('review.status'), 'needs_redaction');

  const childToken = await createOrResetUser({
    uid: 'it-training-child',
    email: 'it-training-child@example.com',
    password: 'Test1!',
    adminClaim: false,
  });
  const childDenied = await invokeCallable('enqueueTrainingCandidate', childToken, {
    captureSource: 'classification_completed',
    classification: {
      classificationId: 'it-training-child-classification-001',
      itemName: 'Bottle',
      category: 'Dry Waste',
      subcategory: 'Plastic',
      confidence: 0.7,
      modelSource: 'backend',
      modelVersion: 'test-v1',
      region: 'Bangalore, IN',
      barcodePresent: false,
    },
    consent: {
      enabled: true,
      policyVersion: 'training-data-v1',
      grantedAt: new Date().toISOString(),
      source: 'test',
    },
    image: {
      contentHash: 'hash-test-child',
      width: 640,
      height: 480,
      exifStripped: true,
      redactionStatus: 'not_collected_metadata_only',
      rawRetentionDays: 0,
    },
  });
  assert.equal(childDenied.response.status, 400);
  assert.match(JSON.stringify(childDenied.body), /guardian consent flow/i);

  const queueDenied = await invokeCallable('getTrainingReviewQueue', userToken, {
    status: 'unreviewed',
    limit: 10,
  });
  assert.equal(queueDenied.response.status, 403);

  const queueOk = await invokeCallable('getTrainingReviewQueue', adminToken, {
    status: 'needs_redaction',
    limit: 20,
  });
  assert.equal(queueOk.response.status, 200);
  const items = queueOk.body?.result?.items ?? queueOk.body?.items ?? [];
  assert.ok(Array.isArray(items));
  assert.ok(items.some((item) => item.id === candidateId));

  const review = await invokeCallable('reviewTrainingCandidate', adminToken, {
    candidateId,
    status: 'training_eligible',
    notes: 'verified in emulator test',
  });
  assert.equal(review.response.status, 200);
  const reviewed = await admin.firestore().collection('training_candidates').doc(candidateId).get();
  assert.equal(reviewed.get('review.status'), 'training_eligible');
  assert.equal(reviewed.get('dataset.eligible'), true);

  const revoke = await invokeCallable('revokeTrainingConsent', userToken, {
    policyVersion: 'training-data-v1',
    source: 'test',
  });
  assert.equal(revoke.response.status, 200);
  const revokedCandidate = await admin.firestore().collection('training_candidates').doc(candidateId).get();
  assert.equal(revokedCandidate.get('review.status'), 'deleted');
  assert.equal(revokedCandidate.get('dataset.eligible'), false);
  assert.equal(revokedCandidate.get('deletion.requested'), true);

  const auditRows = await admin.firestore().collection('training_review_audit').limit(20).get();
  const actions = auditRows.docs.map((d) => d.get('action'));
  assert.ok(actions.includes('review_training_candidate'));
  assert.ok(actions.includes('revoke_training_consent'));
});

test('cleanup helper clears stale deleted and rejected candidates in emulator', async () => {
  const oldMillis = Date.now() - (35 * 24 * 60 * 60 * 1000);
  const freshMillis = Date.now() - (2 * 24 * 60 * 60 * 1000);
  const cutoffDays = 30;

  await admin.firestore().collection('training_candidates').doc('cleanup-deleted').set({
    candidateId: 'cleanup-deleted',
    review: { status: 'deleted' },
    image: { storagePath: 'training/review/2026/05/cleanup-deleted.jpg' },
    updatedAt: admin.firestore.Timestamp.fromMillis(oldMillis),
  });
  await admin.firestore().collection('training_candidates').doc('cleanup-rejected').set({
    candidateId: 'cleanup-rejected',
    review: { status: 'rejected' },
    image: { storagePath: 'training/review/2026/05/cleanup-rejected.jpg' },
    updatedAt: admin.firestore.Timestamp.fromMillis(oldMillis),
  });
  await admin.firestore().collection('training_candidates').doc('cleanup-approved').set({
    candidateId: 'cleanup-approved',
    review: { status: 'approved' },
    image: { storagePath: 'training/review/2026/05/cleanup-approved.jpg' },
    updatedAt: admin.firestore.Timestamp.fromMillis(oldMillis),
  });
  await admin.firestore().collection('training_candidates').doc('cleanup-fresh').set({
    candidateId: 'cleanup-fresh',
    review: { status: 'deleted' },
    image: { storagePath: 'training/review/2026/05/cleanup-fresh.jpg' },
    updatedAt: admin.firestore.Timestamp.fromMillis(freshMillis),
  });

  const result = await __testables.runTrainingReviewCleanup(admin.firestore(), {
    retentionDays: cutoffDays,
  });

  assert.equal(result.cleaned, 2);
  const deletedDoc = await admin.firestore().collection('training_candidates').doc('cleanup-deleted').get();
  const rejectedDoc = await admin.firestore().collection('training_candidates').doc('cleanup-rejected').get();
  const approvedDoc = await admin.firestore().collection('training_candidates').doc('cleanup-approved').get();
  const freshDoc = await admin.firestore().collection('training_candidates').doc('cleanup-fresh').get();

  assert.equal(deletedDoc.get('image.storagePath'), null);
  assert.equal(rejectedDoc.get('image.storagePath'), null);
  assert.equal(approvedDoc.get('image.storagePath'), 'training/review/2026/05/cleanup-approved.jpg');
  assert.equal(freshDoc.get('image.storagePath'), 'training/review/2026/05/cleanup-fresh.jpg');
});
