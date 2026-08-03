import test from 'node:test';
import assert from 'node:assert/strict';
import * as admin from 'firebase-admin';
import { __testables } from '../src/referrals.ts';
import { createReferralCode, getReferralStats, redeemReferralCode } from '../src/referrals.ts';

let initializedTestApp: admin.app.App | undefined;

function callableContext(uid: string) {
  return { auth: { uid, token: {} } };
}

test('generated referral codes are deterministic and normalized', () => {
  const first = __testables.generateReferralCode('uid-referrer-1');
  const second = __testables.generateReferralCode('uid-referrer-1');
  const collisionFallback = __testables.generateReferralCode('uid-referrer-1', 1);

  assert.equal(first, second);
  assert.notEqual(first, collisionFallback);
  assert.match(first, /^WS[A-F0-9]{6}$/);
  assert.equal(__testables.normalizeReferralCode(`  ${first.toLowerCase()} `), first);
});

test('redemption document id is stable per user for retry idempotency', () => {
  const uid = 'uid-redeemer-1';

  assert.equal(__testables.redemptionDocumentId(uid), uid);
  assert.equal(__testables.redemptionDocumentId(uid), __testables.redemptionDocumentId(uid));
});

test('invalid referral code formats are rejected', () => {
  assert.throws(
    () => __testables.normalizeReferralCode('not valid!'),
    (error: unknown) =>
      error instanceof Error &&
      'code' in error &&
      error.code === 'invalid-argument',
  );
});

test('callables atomically account for distinct redeemers and retry idempotency', {
  skip: !process.env.FIRESTORE_EMULATOR_HOST,
}, async () => {
  const projectId = process.env.GCLOUD_PROJECT ?? 'waste-segregation-app-df523';
  initializedTestApp = admin.initializeApp({ projectId });
  const db = admin.firestore(initializedTestApp);
  const suffix = String(Date.now());
  const referrerUid = `it-referrer-${suffix}`;
  const redeemerAUid = `it-redeemer-a-${suffix}`;
  const redeemerBUid = `it-redeemer-b-${suffix}`;

  const created = await createReferralCode.run({}, callableContext(referrerUid));
  const repeated = await createReferralCode.run({}, callableContext(referrerUid));
  assert.equal(repeated.code, created.code);

  const first = await redeemReferralCode.run(
    { code: created.code },
    callableContext(redeemerAUid),
  );
  const duplicate = await redeemReferralCode.run(
    { code: created.code },
    callableContext(redeemerAUid),
  );
  const second = await redeemReferralCode.run(
    { code: created.code },
    callableContext(redeemerBUid),
  );

  assert.equal(first.success, true);
  assert.equal(duplicate.success, false);
  assert.equal(second.success, true);

  const stats = await getReferralStats.run({}, callableContext(referrerUid));
  const referrer = (await db.collection('users').doc(referrerUid).get()).data() ?? {};
  const redeemer = (await db.collection('users').doc(redeemerAUid).get()).data() ?? {};
  const redemptions = await db.collection('referral_redemptions')
    .where('code', '==', created.code)
    .get();

  assert.equal(stats.totalRedemptions, 2);
  assert.equal(referrer.bonusScans, 10);
  assert.equal(referrer.referralSuccessfulRedemptions, 2);
  assert.equal(redeemer.bonusScans, 5);
  assert.equal(redemptions.size, 2);
});

test.after(async () => {
  await initializedTestApp?.delete();
});
