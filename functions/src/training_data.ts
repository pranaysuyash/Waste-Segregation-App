import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { FieldValue } from 'firebase-admin/firestore';
import { createHash, createHmac } from 'crypto';

const asiaSouth1 = functions.region('asia-south1');
const TRAINING_POLICY_VERSION = 'training-data-v1';
const REVIEWABLE_STATUSES = new Set([
  'unreviewed',
  'approved',
  'rejected',
  'needs_redaction',
  'golden',
  'training_eligible',
  'deleted',
]);

const getHmacSecret = (): string => {
  const secret = process.env.TRAINING_DATA_HMAC_SECRET;
  if (secret && secret.trim().length >= 16) {
    return secret;
  }

  if (process.env.FUNCTIONS_EMULATOR === 'true') {
    functions.logger.warn(
      'TRAINING_DATA_HMAC_SECRET is not configured in emulator; using local fallback secret.'
    );
    return 'local-dev-training-data-hmac-secret';
  }

  throw new Error('TRAINING_DATA_HMAC_SECRET is required in production.');
};

const hmacUserId = (uid: string): string =>
  createHmac('sha256', getHmacSecret()).update(uid).digest('hex');

const candidateIdFor = (uid: string, classificationId: string): string =>
  `candidate_${createHash('sha256')
    .update(`${uid}:${classificationId}`)
    .digest('hex')
    .slice(0, 32)}`;

const requireAuth = (
  context: functions.https.CallableContext,
): { uid: string } => {
  if (!context.auth?.uid) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Authentication is required for training-data operations.',
    );
  }
  return { uid: context.auth.uid };
};

const asObject = (value: unknown): Record<string, unknown> =>
  value != null && typeof value === 'object' && !Array.isArray(value)
    ? value as Record<string, unknown>
    : {};

const parseImageBase64 = (value: unknown): Buffer | null => {
  if (typeof value !== 'string' || value.length === 0) return null;
  try {
    return Buffer.from(value, 'base64');
  } catch {
    return null;
  }
};

const maybeIsoMonthPath = (): { yyyy: string; mm: string } => {
  const now = new Date();
  const yyyy = `${now.getUTCFullYear()}`;
  const mm = `${now.getUTCMonth() + 1}`.padStart(2, '0');
  return { yyyy, mm };
};

const likelySensitiveFromSignals = (signals: {
  category?: string | null;
  subcategory?: string | null;
  barcodePresent?: boolean;
  hasPotentialText?: boolean;
}): { flags: string[]; redactionStatus: string; reviewStatus: string } => {
  const joined = `${signals.category ?? ''} ${signals.subcategory ?? ''}`.toLowerCase();
  const flags: string[] = [];
  const riskyCategoryKeywords = ['medical', 'prescription', 'medicine', 'hazard'];

  if (signals.barcodePresent === true) flags.push('barcode_or_label_detected');
  if (signals.hasPotentialText === true) flags.push('potential_text_detected');
  if (riskyCategoryKeywords.some((k) => joined.includes(k))) {
    flags.push('risky_category_keyword');
  }

  if (flags.length > 0) {
    return {
      flags,
      redactionStatus: 'needs_redaction',
      reviewStatus: 'needs_redaction',
    };
  }

  return {
    flags,
    redactionStatus: 'pending_review',
    reviewStatus: 'unreviewed',
  };
};

const detectSensitiveTextInNotes = (notes: string): string[] => {
  const findings: string[] = [];
  const emailLike = /\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b/i;
  const phoneLike = /\b(?:\+?\d{1,3}[-\s]?)?(?:\d{3}[-\s]?){2}\d{4}\b/;
  const addressLike = /\b(?:street|st|road|rd|avenue|ave|lane|ln|apartment|apt|block)\b/i;
  if (emailLike.test(notes)) findings.push('email_like_text');
  if (phoneLike.test(notes)) findings.push('phone_like_text');
  if (addressLike.test(notes)) findings.push('address_like_text');
  return findings;
};

const isAdminContext = (context: functions.https.CallableContext): boolean => {
  if (context.auth?.token?.admin === true) return true;
  if (process.env.FUNCTIONS_EMULATOR === 'true') {
    return process.env.ALLOW_TRAINING_REVIEW_NON_ADMIN === 'true';
  }
  return false;
};

const deleteTrainingImageIfPresent = async (storagePath: unknown): Promise<void> => {
  if (typeof storagePath !== 'string' || storagePath.length === 0) return;
  if (process.env.FUNCTIONS_EMULATOR === 'true'
    && !process.env.FIREBASE_STORAGE_EMULATOR_HOST
    && !process.env.STORAGE_EMULATOR_HOST) {
    functions.logger.info('Skipping training image deletion because storage emulator is not configured', {
      storagePath,
    });
    return;
  }
  try {
    await admin.storage().bucket().file(storagePath).delete({ ignoreNotFound: true });
  } catch (error) {
    functions.logger.warn('Failed to delete training image during revocation/deletion flow', {
      storagePath,
      error: `${error}`,
    });
  }
};

const validateConsent = async (
  uid: string,
  requestConsent: Record<string, unknown>,
): Promise<Record<string, unknown>> => {
  const enabled = requestConsent.enabled === true;
  const policyVersion = String(requestConsent.policyVersion ?? '');
  if (!enabled || policyVersion !== TRAINING_POLICY_VERSION) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'Explicit training-data consent is required.',
    );
  }

  const profileSnap = await admin.firestore().collection('users').doc(uid).get();
  const profile = profileSnap.exists ? profileSnap.data() ?? {} : {};
  const role = profile.role;
  if (role === 'child') {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'Child profiles require a guardian consent flow before training data collection.',
    );
  }

  return {
    enabledAtCapture: true,
    policyVersion,
    consentSnapshotId: `${uid}:${policyVersion}:${requestConsent.grantedAt ?? 'local'}`,
    grantedAt: requestConsent.grantedAt ?? null,
    source: requestConsent.source ?? null,
  };
};

export const enqueueTrainingCandidate = asiaSouth1.https.onCall(async (data, context) => {
  const auth = requireAuth(context);
  const uid = auth.uid;
  const classification = asObject(data?.classification);
  const consent = await validateConsent(uid, asObject(data?.consent));
  const image = asObject(data?.image);
  const classificationId = String(classification.classificationId ?? '');
  if (!classificationId) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'classification.classificationId is required.',
    );
  }

  const candidateId = candidateIdFor(uid, classificationId);
  const userIdHash = hmacUserId(uid);
  const db = admin.firestore();
  const candidateRef = db.collection('training_candidates').doc(candidateId);
  const labelRef = db.collection('training_labels').doc(candidateId);
  const imageBuffer = parseImageBase64(image.base64);
  const { yyyy, mm } = maybeIsoMonthPath();
  const reviewStoragePath = imageBuffer
    ? `training/review/${yyyy}/${mm}/${candidateId}.jpg`
    : null;

  const modelPrediction = {
    provider: classification.modelSource ?? null,
    model: classification.modelVersion ?? null,
    itemName: classification.itemName ?? null,
    category: classification.category ?? null,
    subcategory: classification.subcategory ?? null,
    confidence: classification.confidence ?? null,
    region: classification.region ?? null,
  };
  const qualityReasons = Array.isArray(classification.qualityReasons)
    ? classification.qualityReasons
    : [];
  const pipeline = {
    qualityScore: classification.qualityScore ?? null,
    qualityReasons,
    duplicateScore: classification.duplicateScore ?? null,
    duplicateClusterId: classification.duplicateClusterId ?? null,
    rawConfidence: classification.rawConfidence ?? classification.confidence ?? null,
    calibratedConfidence: classification.calibratedConfidence ?? classification.confidence ?? null,
    needsReview: classification.needsReview ?? null,
    reviewReason: classification.reviewReason ?? null,
    routeDecision: classification.routeDecision ?? null,
    routeReason: classification.routeReason ?? null,
    policyPackId: classification.policyPackId ?? null,
    modelRoute: classification.modelRoute ?? classification.modelSource ?? null,
    routeLatencyMs: classification.routeLatencyMs ?? classification.processingTimeMs ?? null,
    routeCostUsd: classification.routeCostUsd ?? null,
  };
  const riskSignals = likelySensitiveFromSignals({
    category: modelPrediction.category as string | null,
    subcategory: modelPrediction.subcategory as string | null,
    barcodePresent: classification.barcodePresent === true,
    hasPotentialText: image.hasPotentialText === true,
  });

  if (imageBuffer) {
    const bucket = admin.storage().bucket();
    await bucket.file(reviewStoragePath!).save(imageBuffer, {
      contentType: 'image/jpeg',
      resumable: false,
      metadata: {
        metadata: {
          candidateId,
          userIdHash,
          purpose: 'training_review',
          policyVersion: TRAINING_POLICY_VERSION,
        },
      },
    });
  }

  await db.runTransaction(async (tx) => {
    tx.set(candidateRef, {
      candidateId,
      userIdHash,
      classificationId,
      consent,
      captureSource: data?.captureSource ?? 'classification_completed',
      image: {
        storagePath: reviewStoragePath ?? null,
        thumbnailPath: image.thumbnailPath ?? null,
        contentHash: image.contentHash ?? (
          imageBuffer ? createHash('sha256').update(imageBuffer).digest('hex') : null
        ),
        perceptualHash: image.perceptualHash ?? null,
        mimeType: image.mimeType ?? (imageBuffer ? 'image/jpeg' : null),
        width: image.width ?? null,
        height: image.height ?? null,
        exifStripped: image.exifStripped ?? null,
        redactionStatus: imageBuffer
          ? riskSignals.redactionStatus
          : (image.redactionStatus ?? 'not_collected_metadata_only'),
        rawRetentionDays: imageBuffer ? 30 : (image.rawRetentionDays ?? 0),
        piiScan: {
          methodVersion: 'heuristic-v1',
          flags: riskSignals.flags,
          scannedAt: FieldValue.serverTimestamp(),
        },
      },
      modelPrediction,
      pipeline,
      userFeedback: null,
      review: {
        status: riskSignals.reviewStatus,
        reviewer: null,
        reviewedAt: null,
        qualityFlags: imageBuffer ? [] : ['metadata_only_no_training_image'],
        piiFlags: riskSignals.flags,
      },
      dataset: {
        eligible: false,
        includedInVersions: [],
      },
      deletion: {
        requested: false,
        requestedAt: null,
        deletedAt: null,
        excludedFromTrainingAt: null,
      },
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });

    tx.set(labelRef, {
      candidateId,
      rawPrediction: modelPrediction,
      userCorrection: null,
      reviewerVerified: null,
      labelState: 'raw_prediction',
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
  });

  return { candidateId };
});

export const attachTrainingLabelFeedback = asiaSouth1.https.onCall(async (data, context) => {
  const auth = requireAuth(context);
  const uid = auth.uid;
  const classificationId = String(data?.classificationId ?? '');
  if (!classificationId) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'classificationId is required.',
    );
  }

  const candidateId = candidateIdFor(uid, classificationId);
  const feedback = asObject(data?.feedback);
  const feedbackNotes = `${feedback.userNotes ?? ''}`.trim();
  const feedbackSensitiveFindings = detectSensitiveTextInNotes(feedbackNotes);
  const userCorrection = {
    isCorrect: null,
    correctedCategory: feedback.userSuggestedCategory ?? null,
    correctedItemName: feedback.userSuggestedItemName ?? null,
    correctedMaterial: feedback.userSuggestedMaterial ?? null,
    notes: feedback.userNotes ?? null,
    feedbackId: feedback.id ?? candidateId,
    feedbackTimestamp: feedback.feedbackTimestamp ?? null,
  };

  const db = admin.firestore();
  await db.runTransaction(async (tx) => {
    tx.set(db.collection('training_candidates').doc(candidateId), {
      userFeedback: userCorrection,
      review: feedbackSensitiveFindings.length > 0
        ? {
          status: 'needs_redaction',
          piiFlags: feedbackSensitiveFindings,
        }
        : {},
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
    tx.set(db.collection('training_labels').doc(candidateId), {
      candidateId,
      userCorrection,
      labelState: 'user_corrected',
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
  });

  return { candidateId };
});

export const revokeTrainingConsent = asiaSouth1.https.onCall(async (data, context) => {
  const auth = requireAuth(context);
  const uid = auth.uid;
  const userIdHash = hmacUserId(uid);
  const db = admin.firestore();
  const now = FieldValue.serverTimestamp();

  await db.collection('users').doc(uid).set({
    trainingConsent: {
      enabled: false,
      policyVersion: data?.policyVersion ?? TRAINING_POLICY_VERSION,
      revokedAt: new Date().toISOString(),
      source: data?.source ?? 'settings',
    },
  }, { merge: true });

  const candidates = await db.collection('training_candidates')
    .where('userIdHash', '==', userIdHash)
    .limit(400)
    .get();

  const deleteTasks = candidates.docs.map((doc) => deleteTrainingImageIfPresent(doc.get('image.storagePath')));
  await Promise.all(deleteTasks);

  const batch = db.batch();
  candidates.docs.forEach((doc) => {
    batch.set(doc.ref, {
      review: { status: 'deleted' },
      dataset: { eligible: false },
      deletion: {
        requested: true,
        requestedAt: now,
        deletedAt: now,
        excludedFromTrainingAt: now,
      },
      updatedAt: now,
    }, { merge: true });
  });
  await batch.commit();

  await db.collection('training_review_audit').add({
    action: 'revoke_training_consent',
    actorUid: uid,
    actorRole: context.auth?.token?.admin === true ? 'admin' : 'user',
    userIdHash,
    markedCandidates: candidates.size,
    createdAt: FieldValue.serverTimestamp(),
  });

  return {
    markedCandidates: candidates.size,
  };
});

export const getTrainingReviewQueue = asiaSouth1.https.onCall(async (data, context) => {
  requireAuth(context);
  if (!isAdminContext(context)) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Admin role is required to access training review queue.',
    );
  }

  const limitRaw = Number(data?.limit ?? 50);
  const limit = Number.isFinite(limitRaw) ? Math.min(Math.max(limitRaw, 1), 100) : 50;
  const statusFilter = typeof data?.status === 'string' ? data.status : null;

  let query: FirebaseFirestore.Query = admin
    .firestore()
    .collection('training_candidates')
    .orderBy('createdAt', 'desc')
    .limit(limit);

  if (statusFilter) {
    query = admin
      .firestore()
      .collection('training_candidates')
      .where('review.status', '==', statusFilter)
      .orderBy('createdAt', 'desc')
      .limit(limit);
  }

  const snapshot = await query.get();
  const rows = snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
  return { items: rows };
});

export const reviewTrainingCandidate = asiaSouth1.https.onCall(async (data, context) => {
  requireAuth(context);
  if (!isAdminContext(context)) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Admin role is required to review training candidates.',
    );
  }

  const candidateId = String(data?.candidateId ?? '');
  const status = String(data?.status ?? '');
  const notes = typeof data?.notes === 'string' ? data.notes : null;
  if (!candidateId) {
    throw new functions.https.HttpsError('invalid-argument', 'candidateId is required.');
  }
  if (!REVIEWABLE_STATUSES.has(status)) {
    throw new functions.https.HttpsError('invalid-argument', `Invalid review status: ${status}`);
  }

  const reviewerUid = context.auth?.uid ?? 'unknown_admin';
  const now = FieldValue.serverTimestamp();
  const isEligible = status === 'training_eligible' || status === 'golden' || status === 'approved';
  const isDeleted = status === 'deleted';
  const db = admin.firestore();
  const candidateRef = db.collection('training_candidates').doc(candidateId);
  const labelRef = db.collection('training_labels').doc(candidateId);
  const candidateSnap = await candidateRef.get();
  const existingStoragePath = candidateSnap.get('image.storagePath');
  if (isDeleted) {
    await deleteTrainingImageIfPresent(existingStoragePath);
  }

  await db.runTransaction(async (tx) => {
    tx.set(candidateRef, {
      review: {
        status,
        reviewer: reviewerUid,
        reviewedAt: now,
        reviewNotes: notes,
      },
      dataset: {
        eligible: isEligible,
      },
      deletion: isDeleted ? {
        requested: true,
        requestedAt: now,
        deletedAt: now,
        excludedFromTrainingAt: now,
      } : {
        excludedFromTrainingAt: isEligible ? null : now,
      },
      updatedAt: now,
    }, { merge: true });

    const nextLabelState = status === 'golden'
      ? 'golden'
      : (status === 'training_eligible' ? 'training_eligible' : 'policy_verified');
    tx.set(labelRef, {
      labelState: nextLabelState,
      reviewerVerified: {
        reviewer: reviewerUid,
        reviewedAt: now,
        status,
        notes,
      },
      updatedAt: now,
    }, { merge: true });
  });

  await db.collection('training_review_audit').add({
    action: 'review_training_candidate',
    actorUid: reviewerUid,
    actorRole: context.auth?.token?.admin === true ? 'admin' : 'unknown',
    candidateId,
    status,
    eligible: isEligible,
    notes: notes ?? null,
    createdAt: FieldValue.serverTimestamp(),
  });

  return { candidateId, status, eligible: isEligible };
});

const shouldCleanupCandidate = (
  data: FirebaseFirestore.DocumentData,
  cutoffMillis: number,
): boolean => {
  const status = `${data?.review?.status ?? ''}`;
  const updatedAt = data?.updatedAt;
  const updatedMillis =
    typeof updatedAt?.toMillis === 'function' ? updatedAt.toMillis() : null;
  if (updatedMillis == null || updatedMillis > cutoffMillis) return false;
  return status === 'deleted' || status === 'rejected';
};

export const runTrainingReviewCleanup = async (
  db: FirebaseFirestore.Firestore,
  options?: { retentionDays?: number },
): Promise<{ scanned: number; cleaned: number }> => {
  const retentionDaysRaw = Number(options?.retentionDays ?? process.env.TRAINING_REVIEW_RETENTION_DAYS ?? 30);
  const retentionDays = Number.isFinite(retentionDaysRaw) && retentionDaysRaw > 0
    ? retentionDaysRaw
    : 30;
  const cutoffMillis = Date.now() - (retentionDays * 24 * 60 * 60 * 1000);
  const cutoffDate = new Date(cutoffMillis);

  const snapshot = await db.collection('training_candidates')
    .where('updatedAt', '<=', cutoffDate)
    .limit(400)
    .get();

  let cleaned = 0;
  const batch = db.batch();
  for (const doc of snapshot.docs) {
    const data = doc.data();
    if (!shouldCleanupCandidate(data, cutoffMillis)) continue;
    const storagePath = data?.image?.storagePath;
    await deleteTrainingImageIfPresent(storagePath);
    batch.set(doc.ref, {
      image: {
        storagePath: null,
        cleanedUpAt: FieldValue.serverTimestamp(),
      },
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
    cleaned += 1;
  }

  if (cleaned > 0) {
    await batch.commit();
  }

  return { scanned: snapshot.size, cleaned };
};

export const cleanupTrainingReviewImages = asiaSouth1.pubsub
  .schedule('every 24 hours')
  .timeZone('UTC')
  .onRun(async () => {
    const db = admin.firestore();
    const result = await runTrainingReviewCleanup(db);

    functions.logger.info('Training review cleanup run complete', {
      scanned: result.scanned,
      cleaned: result.cleaned,
      retentionDays: Number(process.env.TRAINING_REVIEW_RETENTION_DAYS ?? 30) || 30,
    });
    return null;
  });

export const __testables = {
  detectSensitiveTextInNotes,
  isAdminContext,
  likelySensitiveFromSignals,
  shouldCleanupCandidate,
  runTrainingReviewCleanup,
};
