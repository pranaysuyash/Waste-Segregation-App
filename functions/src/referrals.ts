import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { FieldValue } from 'firebase-admin/firestore';
import * as crypto from 'crypto';

const asiaSouth1 = functions.region('asia-south1');

const REFERRAL_REWARD_SCANS = 5;
const REFERRAL_CODE_PREFIX = 'WS';

function generateReferralCode(uid: string): string {
  const hash = crypto.createHash('sha256').update(uid).digest('hex').slice(0, 6).toUpperCase();
  return `${REFERRAL_CODE_PREFIX}${hash}`;
}

interface CreateReferralCodeData {
  code?: string;
}

interface CreateReferralCodeResponse {
  code: string;
}

export const createReferralCode = asiaSouth1.https.onCall(
  async (data: CreateReferralCodeData, context): Promise<CreateReferralCodeResponse> => {
    if (!context.auth?.uid) {
      throw new functions.https.HttpsError('unauthenticated', 'Authentication required.');
    }

    const uid = context.auth.uid;
    const db = admin.firestore();
    const referralRef = db.collection('referral_codes').doc(uid);

    // Check if user already has a referral code
    const existing = await referralRef.get();
    if (existing.exists) {
      const existingData = existing.data()!;
      return { code: existingData.code as string };
    }

    const code = generateReferralCode(uid);

    await referralRef.set({
      id: uid,
      referrerUid: uid,
      code,
      createdAt: FieldValue.serverTimestamp(),
      rewardTier: 'free',
    });

    functions.logger.info('Referral code created', { uid, code });
    return { code };
  },
);

interface RedeemReferralCodeData {
  code: string;
}

interface RedeemReferralCodeResponse {
  success: boolean;
  message: string;
  bonusScans: number;
}

export const redeemReferralCode = asiaSouth1.https.onCall(
  async (data: RedeemReferralCodeData, context): Promise<RedeemReferralCodeResponse> => {
    if (!context.auth?.uid) {
      throw new functions.https.HttpsError('unauthenticated', 'Authentication required.');
    }

    const { code } = data;
    if (!code || typeof code !== 'string') {
      throw new functions.https.HttpsError('invalid-argument', 'Referral code is required.');
    }

    const uid = context.auth.uid;
    const db = admin.firestore();

    // Find the referral code document
    const codesSnap = await db.collection('referral_codes')
      .where('code', '==', code.toUpperCase())
      .limit(1)
      .get();

    if (codesSnap.empty) {
      return { success: false, message: 'Invalid referral code.', bonusScans: 0 };
    }

    const referralDoc = codesSnap.docs[0];
    const referrerData = referralDoc.data();
    const referrerUid = referrerData.referrerUid as string;

    if (referrerUid === uid) {
      return { success: false, message: 'You cannot use your own referral code.', bonusScans: 0 };
    }

    // Check if this user already redeemed a code
    const existingRedemption = await db.collection('referral_redemptions')
      .where('redeemedByUid', '==', uid)
      .limit(1)
      .get();

    if (!existingRedemption.empty) {
      return { success: false, message: 'You have already used a referral code.', bonusScans: 0 };
    }

    // Record redemption
    const redemptionRef = db.collection('referral_redemptions').doc();
    await db.runTransaction(async (tx) => {
      // Grant bonus scans to the new user
      const userRef = db.collection('users').doc(uid);
      tx.set(userRef, {
        bonusScans: FieldValue.increment(REFERRAL_REWARD_SCANS),
        referralRedeemedAt: FieldValue.serverTimestamp(),
        referralCode: code.toUpperCase(),
      }, { merge: true });

      // Mark referral as rewarded for the referrer
      tx.update(referralDoc.ref, {
        rewardedAt: FieldValue.serverTimestamp(),
        redeemedBy: uid,
      });

      // Record the redemption
      tx.set(redemptionRef, {
        id: redemptionRef.id,
        code: code.toUpperCase(),
        redeemedByUid: uid,
        redeemedAt: FieldValue.serverTimestamp(),
      });
    });

    functions.logger.info('Referral code redeemed', {
      referrerUid,
      newUserUid: uid,
      code,
      bonusScans: REFERRAL_REWARD_SCANS,
    });

    return {
      success: true,
      message: `You received ${REFERRAL_REWARD_SCANS} bonus scans!`,
      bonusScans: REFERRAL_REWARD_SCANS,
    };
  },
);

interface ReferralStatsData {
  code?: string;
}

interface ReferralStatsResponse {
  code: string;
  totalRedemptions: number;
}

export const getReferralStats = asiaSouth1.https.onCall(
  async (_data: ReferralStatsData, context): Promise<ReferralStatsResponse> => {
    if (!context.auth?.uid) {
      throw new functions.https.HttpsError('unauthenticated', 'Authentication required.');
    }

    const uid = context.auth.uid;
    const db = admin.firestore();

    const referralRef = db.collection('referral_codes').doc(uid);
    const referralSnap = await referralRef.get();

    if (!referralSnap.exists) {
      return { code: '', totalRedemptions: 0 };
    }

    const referralData = referralSnap.data()!;
    const code = referralData.code as string;

    const redemptionsSnap = await db.collection('referral_codes')
      .doc(uid)
      .collection('redemptions')
      .count()
      .get();

    const totalRedemptions = redemptionsSnap.data()?.count ?? 0;

    return { code, totalRedemptions };
  },
);
