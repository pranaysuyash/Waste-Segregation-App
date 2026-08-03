import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { DocumentSnapshot, FieldValue } from 'firebase-admin/firestore';
import * as crypto from 'crypto';
import {
  enforceRateLimit,
  getRateLimitConfig,
  shouldEnforceCallableAppCheck,
} from './helpers';

const asiaSouth1 = functions.region('asia-south1');

const REFERRAL_REWARD_SCANS = 5;
const REFERRAL_CODE_PREFIX = 'WS';
const REFERRAL_CODE_HASH_LENGTH = 6;
const MAX_CODE_GENERATION_ATTEMPTS = 32;

const referralCodesCollection = 'referral_codes';
const referralCodeIndexCollection = 'referral_code_index';
const referralRedemptionsCollection = 'referral_redemptions';

function generateReferralCode(uid: string, attempt = 0): string {
  const seed = attempt === 0 ? uid : `${uid}:${attempt}`;
  const hash = crypto
    .createHash('sha256')
    .update(seed)
    .digest('hex')
    .slice(0, REFERRAL_CODE_HASH_LENGTH)
    .toUpperCase();
  return `${REFERRAL_CODE_PREFIX}${hash}`;
}

function normalizeReferralCode(value: unknown): string {
  if (typeof value !== 'string') {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Referral code is required.',
    );
  }

  const code = value.trim().toUpperCase();
  if (!/^[A-Z0-9]{4,32}$/.test(code)) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Referral code has an invalid format.',
    );
  }
  return code;
}

function redemptionDocumentId(uid: string): string {
  // The UID is already a Firestore document-id-safe value. Keeping the
  // redemption key deterministic makes retries and concurrent calls one
  // idempotent event instead of generating a new reward document each time.
  return uid;
}

async function enforceReferralRequestGuards(
  uid: string,
  context: functions.https.CallableContext,
): Promise<void> {
  if (shouldEnforceCallableAppCheck() && !context.app) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'App Check token required.',
    );
  }

  const rateLimitConfig = getRateLimitConfig();
  const rateLimitState = await enforceRateLimit({
    bucket: 'referrals',
    subject: `uid:${uid}`,
    maxRequests: Math.max(1, rateLimitConfig.disposalMax),
    windowSeconds: Math.max(1, rateLimitConfig.windowSeconds),
  });

  if (rateLimitState.retryAfterSeconds > 0) {
    throw new functions.https.HttpsError(
      'resource-exhausted',
      'Referral request rate limit exceeded. Try again later.',
      { retryAfterSeconds: rateLimitState.retryAfterSeconds },
    );
  }
}

interface CreateReferralCodeData {
  code?: string;
}

interface CreateReferralCodeResponse {
  code: string;
}

export const createReferralCode = asiaSouth1.https.onCall(
  async (
    _data: CreateReferralCodeData,
    context,
  ): Promise<CreateReferralCodeResponse> => {
    if (!context.auth?.uid) {
      throw new functions.https.HttpsError('unauthenticated', 'Authentication required.');
    }

    const uid = context.auth.uid;
    await enforceReferralRequestGuards(uid, context);

    const db = admin.firestore();
    const referralRef = db.collection(referralCodesCollection).doc(uid);
    const indexCollection = db.collection(referralCodeIndexCollection);

    const code = await db.runTransaction(async (tx) => {
      const existing = await tx.get(referralRef);

      if (existing.exists) {
        const existingCode = existing.data()?.code;
        if (typeof existingCode !== 'string' || existingCode.length === 0) {
          throw new functions.https.HttpsError(
            'failed-precondition',
            'Existing referral code is invalid.',
          );
        }

        const normalizedExistingCode = normalizeReferralCode(existingCode);
        const indexRef = indexCollection.doc(normalizedExistingCode);
        const indexSnap = await tx.get(indexRef);
        const indexedUid = indexSnap.data()?.referrerUid;
        if (indexSnap.exists && indexedUid !== uid) {
          throw new functions.https.HttpsError(
            'already-exists',
            'Referral code ownership conflict detected.',
          );
        }

        const conflictingCodes = await tx.get(
          db.collection(referralCodesCollection)
            .where('code', '==', normalizedExistingCode),
        );
        const hasOtherOwner = conflictingCodes.docs.some((doc) => {
          const ownerUid = doc.data().referrerUid ?? doc.id;
          return ownerUid !== uid;
        });
        if (hasOtherOwner) {
          throw new functions.https.HttpsError(
            'already-exists',
            'Referral code ownership conflict detected.',
          );
        }

        if (!indexSnap.exists) {
          tx.create(indexRef, {
            code: normalizedExistingCode,
            referrerUid: uid,
            referralDocId: uid,
            createdAt: FieldValue.serverTimestamp(),
          });
        }
        return normalizedExistingCode;
      }

      for (let attempt = 0; attempt < MAX_CODE_GENERATION_ATTEMPTS; attempt += 1) {
        const candidate = generateReferralCode(uid, attempt);
        const indexRef = indexCollection.doc(candidate);
        const indexSnap = await tx.get(indexRef);
        const conflictingCodes = await tx.get(
          db.collection(referralCodesCollection)
            .where('code', '==', candidate),
        );

        const indexedOwner = indexSnap.data()?.referrerUid;
        const legacyOwners = conflictingCodes.docs.map(
          (doc) => typeof doc.data().referrerUid === 'string'
            ? doc.data().referrerUid as string
            : doc.id,
        );
        const occupiedByOtherUser =
          (indexSnap.exists && indexedOwner !== uid) ||
          legacyOwners.some((ownerUid) => ownerUid !== uid);

        if (occupiedByOtherUser) continue;

        if (!indexSnap.exists) {
          tx.create(indexRef, {
            code: candidate,
            referrerUid: uid,
            referralDocId: uid,
            createdAt: FieldValue.serverTimestamp(),
          });
        }
        tx.set(referralRef, {
          id: uid,
          referrerUid: uid,
          code: candidate,
          createdAt: FieldValue.serverTimestamp(),
          rewardTier: 'free',
        }, { merge: true });
        return candidate;
      }

      throw new functions.https.HttpsError(
        'resource-exhausted',
        'Could not allocate a unique referral code. Try again later.',
      );
    });

    functions.logger.info('Referral code created or reused', { uid, code });
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
  async (
    data: RedeemReferralCodeData,
    context,
  ): Promise<RedeemReferralCodeResponse> => {
    if (!context.auth?.uid) {
      throw new functions.https.HttpsError('unauthenticated', 'Authentication required.');
    }

    const uid = context.auth.uid;
    await enforceReferralRequestGuards(uid, context);
    const code = normalizeReferralCode(data?.code);
    const db = admin.firestore();
    const redemptionRef = db
      .collection(referralRedemptionsCollection)
      .doc(redemptionDocumentId(uid));
    const codeIndexRef = db.collection(referralCodeIndexCollection).doc(code);
    const codeQuery = db.collection(referralCodesCollection)
      .where('code', '==', code);
    const legacyRedemptionQuery = db.collection(referralRedemptionsCollection)
      .where('redeemedByUid', '==', uid)
      .limit(1);

    const redemptionResult = await db.runTransaction(async (tx) => {
      // Every read occurs before any write so Firestore retries the complete
      // decision if a competing redemption changes one of these documents.
      const [indexSnap, legacyCodesSnap, existingRedemption, legacyRedemption] =
        await Promise.all([
          tx.get(codeIndexRef),
          tx.get(codeQuery),
          tx.get(redemptionRef),
          tx.get(legacyRedemptionQuery),
        ]);

      if (existingRedemption.exists || !legacyRedemption.empty) {
        return 'already_redeemed' as const;
      }

      let referralDoc: DocumentSnapshot | undefined = legacyCodesSnap.docs[0];
      const legacyOwners = legacyCodesSnap.docs.map(
        (doc) => typeof doc.data().referrerUid === 'string'
          ? doc.data().referrerUid as string
          : doc.id,
      );
      if (indexSnap.exists) {
        const indexedReferrerUid = indexSnap.data()?.referrerUid;
        const indexedDocId = indexSnap.data()?.referralDocId;
        if (typeof indexedReferrerUid !== 'string' || typeof indexedDocId !== 'string') {
          throw new functions.https.HttpsError(
            'failed-precondition',
            'Referral code index is invalid.',
          );
        }
        const indexedDocSnap = await tx.get(
          db.collection(referralCodesCollection).doc(indexedDocId),
        );
        if (indexedDocSnap.exists) {
          referralDoc = indexedDocSnap;
        }
        if (legacyOwners.some((ownerUid) => ownerUid !== indexedReferrerUid)) {
          throw new functions.https.HttpsError(
            'failed-precondition',
            'Referral code has conflicting owners.',
          );
        }
      } else if (new Set(legacyOwners).size > 1) {
        throw new functions.https.HttpsError(
          'failed-precondition',
          'Referral code has conflicting owners.',
        );
      }

      if (!referralDoc) {
        return 'invalid' as const;
      }

      const referralData = referralDoc.data();
      if (!referralData) {
        throw new functions.https.HttpsError(
          'failed-precondition',
          'Referral code document is invalid.',
        );
      }
      const referrerUid = referralData.referrerUid ?? referralData.id ?? referralDoc.id;
      if (typeof referrerUid !== 'string' || referrerUid.length === 0) {
        throw new functions.https.HttpsError(
          'failed-precondition',
          'Referral code owner is invalid.',
        );
      }

      if (typeof referralData.code !== 'string' ||
          referralData.code.trim().toUpperCase() !== code) {
        throw new functions.https.HttpsError(
          'failed-precondition',
          'Referral code document does not match its index.',
        );
      }

      if (indexSnap.exists && indexSnap.data()?.referrerUid !== referrerUid) {
        throw new functions.https.HttpsError(
          'failed-precondition',
          'Referral code ownership index does not match its document.',
        );
      }

      if (referrerUid === uid) {
        return 'self' as const;
      }

      tx.create(redemptionRef, {
        id: redemptionRef.id,
        sourceEventId: `referral_redemption:${uid}`,
        code,
        referrerUid,
        redeemedByUid: uid,
        rewardScans: REFERRAL_REWARD_SCANS,
        referrerRewardScans: REFERRAL_REWARD_SCANS,
        redeemedAt: FieldValue.serverTimestamp(),
      });

      const redeemerRef = db.collection('users').doc(uid);
      tx.set(redeemerRef, {
        bonusScans: FieldValue.increment(REFERRAL_REWARD_SCANS),
        referralRedeemedAt: FieldValue.serverTimestamp(),
        referralCode: code,
      }, { merge: true });

      const referrerRef = db.collection('users').doc(referrerUid);
      tx.set(referrerRef, {
        bonusScans: FieldValue.increment(REFERRAL_REWARD_SCANS),
        referralSuccessfulRedemptions: FieldValue.increment(1),
        lastReferralRedemptionAt: FieldValue.serverTimestamp(),
      }, { merge: true });

      // Keep aggregate observability on the legacy code document, while the
      // redemption collection remains the stats source of truth.
      tx.set(referralDoc.ref, {
        redemptionCount: FieldValue.increment(1),
        lastRedeemedAt: FieldValue.serverTimestamp(),
      }, { merge: true });

      return 'created' as const;
    });

    if (redemptionResult === 'already_redeemed') {
      return {
        success: false,
        message: 'You have already used a referral code.',
        bonusScans: 0,
      };
    }

    if (redemptionResult === 'invalid') {
      return { success: false, message: 'Invalid referral code.', bonusScans: 0 };
    }

    if (redemptionResult === 'self') {
      return {
        success: false,
        message: 'You cannot use your own referral code.',
        bonusScans: 0,
      };
    }

    functions.logger.info('Referral code redeemed', {
      referrerUid: 'stored_in_redemption_record',
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
  async (
    _data: ReferralStatsData,
    context,
  ): Promise<ReferralStatsResponse> => {
    if (!context.auth?.uid) {
      throw new functions.https.HttpsError('unauthenticated', 'Authentication required.');
    }

    const uid = context.auth.uid;
    await enforceReferralRequestGuards(uid, context);
    const db = admin.firestore();
    const referralRef = db.collection(referralCodesCollection).doc(uid);
    const referralSnap = await referralRef.get();

    if (!referralSnap.exists) {
      return { code: '', totalRedemptions: 0 };
    }

    const code = normalizeReferralCode(referralSnap.data()?.code);
    const redemptionsSnap = await db.collection(referralRedemptionsCollection)
      .where('code', '==', code)
      .count()
      .get();

    return {
      code,
      totalRedemptions: redemptionsSnap.data().count,
    };
  },
);

// Kept out of the callable surface so focused tests can verify the pure
// correctness rules without changing the deployed function exports.
export const __testables = {
  generateReferralCode,
  normalizeReferralCode,
  redemptionDocumentId,
};
