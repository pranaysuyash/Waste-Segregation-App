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
  const isEligible = status === 'training_eligible' || status === 'golden';
  const isDeleted = status === 'deleted';
  const groundTruthInput = asObject(data?.groundTruth);
  const groundTruth = {
    category: groundTruthInput.category ?? null,
    subcategory: groundTruthInput.subcategory ?? null,
    itemName: groundTruthInput.itemName ?? null,
    material: groundTruthInput.material ?? null,
    confidence: typeof groundTruthInput.confidence === 'number'
      ? groundTruthInput.confidence
      : null,
  };
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
        groundTruth: (status === 'golden' || status === 'training_eligible')
          ? groundTruth
          : null,
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

export interface ManifestRowInput {
  candidateId: string | null;
  reviewStatus: string | null;
  labelState: string | null;
  modelPrediction: Record<string, unknown> | null;
  userFeedback: Record<string, unknown> | null;
  reviewerVerified: Record<string, unknown> | null;
  imageContentHash: string | null;
  imageStoragePath: string | null;
  classificationId: string | null;
  consentPolicyVersion: string | null;
  reviewer: string | null;
  createdAt: unknown;
}

export function resolveAuthoritativeLabel(input: ManifestRowInput): {
  category: string | null;
  subcategory: string | null;
  itemName: string | null;
  material: string | null;
  confidence: number | null;
  labelSource: string;
  provider: string | null;
  model: string | null;
  imageHash: string | null;
  imagePath: string | null;
  provenance: Record<string, unknown>;
} {
  const rawPrediction = input.modelPrediction ?? null;
  const userCorrection = input.userFeedback ?? null;
  const reviewerVerified = input.reviewerVerified ?? null;
  const gt = (reviewerVerified?.groundTruth ?? null) as Record<string, unknown> | null;

  const category = (gt?.category as string | null)
    ?? (userCorrection?.correctedCategory as string | null)
    ?? (rawPrediction?.category as string | null)
    ?? null;

  const itemName = (gt?.itemName as string | null)
    ?? (userCorrection?.correctedItemName as string | null)
    ?? (rawPrediction?.itemName as string | null)
    ?? null;

  const material = (gt?.material as string | null)
    ?? (userCorrection?.correctedMaterial as string | null)
    ?? (rawPrediction?.material as string | null)
    ?? null;

  const subcategory = (gt?.subcategory as string | null)
    ?? (userCorrection?.correctedSubcategory as string | null)
    ?? (rawPrediction?.subcategory as string | null)
    ?? null;

  const confidence = (gt?.confidence as number | null)
    ?? (rawPrediction?.confidence as number | null)
    ?? null;

  let labelSource = input.reviewStatus ?? 'raw_prediction';
  if (input.labelState && ['golden', 'training_eligible', 'policy_verified', 'user_corrected'].includes(input.labelState)) {
    labelSource = input.labelState;
  }

  return {
    category, subcategory, itemName, material, confidence,
    labelSource,
    provider: (rawPrediction?.provider as string | null) ?? null,
    model: (rawPrediction?.model as string | null) ?? null,
    imageHash: input.imageContentHash,
    imagePath: input.imageStoragePath,
    provenance: {
      classificationId: input.classificationId ?? null,
      consentVersion: input.consentPolicyVersion ?? null,
      reviewer: input.reviewer ?? null,
    },
  };
}

export function buildManifestRow(
  cand: Record<string, unknown>,
  rawPrediction: Record<string, unknown> | null,
  userCorrection: Record<string, unknown> | null,
  reviewerVerified: Record<string, unknown> | null,
  datasetVersion: string,
): Record<string, unknown> | null {
  const candId = (cand.candidateId as string | null) ?? null;
  if (!candId) return null;

  const input: ManifestRowInput = {
    candidateId: candId,
    reviewStatus: ((cand.review as Record<string, unknown> | null)?.status as string | null) ?? null,
    labelState: null,
    modelPrediction: rawPrediction,
    userFeedback: userCorrection,
    reviewerVerified,
    imageContentHash: ((cand.image as Record<string, unknown> | null)?.contentHash as string | null) ?? null,
    imageStoragePath: ((cand.image as Record<string, unknown> | null)?.storagePath as string | null) ?? null,
    classificationId: (cand.classificationId as string | null) ?? null,
    consentPolicyVersion: ((cand.consent as Record<string, unknown> | null)?.policyVersion as string | null) ?? null,
    reviewer: ((cand.review as Record<string, unknown> | null)?.reviewer as string | null) ?? null,
    createdAt: cand.createdAt ?? null,
  };

  const resolved = resolveAuthoritativeLabel(input);

  return {
    candidateId: candId,
    labelSource: resolved.labelSource,
    category: resolved.category,
    subcategory: resolved.subcategory,
    itemName: resolved.itemName,
    material: resolved.material,
    confidence: resolved.confidence,
    imageHash: resolved.imageHash,
    imagePath: resolved.imagePath,
    provider: resolved.provider,
    model: resolved.model,
    datasetVersion,
    provenance: resolved.provenance,
    createdAt: input.createdAt,
  };
}

export const buildTrainingDatasetManifest = asiaSouth1.https.onCall(async (data, context) => {
  requireAuth(context);
  if (!isAdminContext(context)) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Admin role is required to build dataset manifests.',
    );
  }

  const datasetVersion = String(data?.datasetVersion ?? '');
  if (!datasetVersion) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'datasetVersion is required (e.g. "v2026-05-22").',
    );
  }

  const dryRun = data?.dryRun === true;
  const db = admin.firestore();

  const candidates = await db.collection('training_candidates')
    .where('dataset.eligible', '==', true)
    .where('deletion.deletedAt', '==', null)
    .orderBy('createdAt', 'desc')
    .get();

  if (candidates.empty) {
    return { datasetVersion, goldenCount: 0, trainingCount: 0, eligibleCount: 0, manifestRows: [] };
  }

  const labelSnapshots = await Promise.all(
    candidates.docs.map((doc) => db.collection('training_labels').doc(doc.id).get()),
  );

  const labelMap = new Map<string, FirebaseFirestore.DocumentData>();
  labelSnapshots.forEach((snap) => {
    if (snap.exists) labelMap.set(snap.id, snap.data()!);
  });

  const rows: Record<string, unknown>[] = [];
  let excludedNoConsent = 0;
  let excludedRevoked = 0;
  let excludedUnreviewed = 0;
  let excludedRejected = 0;
  let excludedPii = 0;
  let excludedDeleted = 0;
  let goldenCount = 0;

  for (const doc of candidates.docs) {
    const cand = doc.data();
    const review = (cand.review as Record<string, unknown> | null) ?? {};
    const consent = (cand.consent as Record<string, unknown> | null) ?? {};
    const deletion = (cand.deletion as Record<string, unknown> | null) ?? {};
    const image = (cand.image as Record<string, unknown> | null) ?? {};
    const status = `${review.status ?? ''}`;
    const redactionStatus = `${image.redactionStatus ?? ''}`;
    const consentEnabled = consent.enabledAtCapture === true;
    const revokedAt = consent.revokedAt ?? null;
    const deletedAt = deletion.deletedAt ?? null;

    if (!consentEnabled) {
      excludedNoConsent += 1;
      continue;
    }
    if (revokedAt != null) {
      excludedRevoked += 1;
      continue;
    }
    if (deletedAt != null) {
      excludedDeleted += 1;
      continue;
    }
    if (status === 'unreviewed' || status === 'approved') {
      excludedUnreviewed += 1;
      continue;
    }
    if (status === 'rejected') {
      excludedRejected += 1;
      continue;
    }
    if (status !== 'golden' && status !== 'training_eligible') {
      excludedRejected += 1;
      continue;
    }
    if (
      redactionStatus.startsWith('pending')
      || redactionStatus == 'needs_redaction'
      || redactionStatus == 'rejected'
    ) {
      excludedPii += 1;
      continue;
    }

    const isGolden = status === 'golden';
    if (isGolden) goldenCount += 1;

    const label = labelMap.get(doc.id) ?? null;

    const row = buildManifestRow(
      cand,
      (label?.rawPrediction as Record<string, unknown> | null) ?? (cand.modelPrediction as Record<string, unknown> | null),
      (label?.userCorrection as Record<string, unknown> | null) ?? (cand.userFeedback as Record<string, unknown> | null),
      (label?.reviewerVerified as Record<string, unknown> | null) ?? null,
      datasetVersion,
    );

    if (row) rows.push(row);
  }

  if (dryRun) {
    return {
      datasetVersion,
      goldenCount,
      trainingCount: rows.length,
      eligibleCount: rows.length,
      excludedCounts: {
        noConsent: excludedNoConsent,
        revoked: excludedRevoked,
        pii: excludedPii,
        unreviewed: excludedUnreviewed,
        rejected: excludedRejected,
        deleted: excludedDeleted,
      },
      dryRun: true,
      sampleRows: rows.slice(0, 5),
    };
  }

  const jsonlContent = rows.map((r) => JSON.stringify(r)).join('\n');
  const bucket = admin.storage().bucket();
  const manifestPath = `training/manifests/${datasetVersion}.jsonl`;
  await bucket.file(manifestPath).save(jsonlContent, {
    contentType: 'application/jsonl',
    resumable: false,
    metadata: {
      metadata: {
        datasetVersion,
        generatedAt: new Date().toISOString(),
        generatorVersion: 'manifest-builder-v1',
        goldenCount,
        trainingCount: rows.length,
      },
    },
  });

  await db.collection('training_dataset_versions').doc(datasetVersion).set({
    datasetVersion,
    manifestStoragePath: manifestPath,
    goldenCount,
    trainingCount: rows.length,
    candidateCount: rows.length,
    excludedCounts: {
      noConsent: excludedNoConsent,
      revoked: excludedRevoked,
      pii: excludedPii,
      unreviewed: excludedUnreviewed,
      rejected: excludedRejected,
      deleted: excludedDeleted,
    },
    createdAt: FieldValue.serverTimestamp(),
    createdBy: context.auth?.uid ?? 'unknown_admin',
    generatorVersion: 'manifest-builder-v1',
  });

  await db.collection('training_review_audit').add({
    action: 'build_training_dataset_manifest',
    actorUid: context.auth?.uid ?? 'unknown_admin',
    actorRole: context.auth?.token?.admin === true ? 'admin' : 'unknown',
    datasetVersion,
    goldenCount,
    trainingCount: rows.length,
    manifestPath,
    createdAt: FieldValue.serverTimestamp(),
  });

  return {
    datasetVersion,
    goldenCount,
    trainingCount: rows.length,
    eligibleCount: rows.length,
    excludedCounts: {
      noConsent: excludedNoConsent,
      revoked: excludedRevoked,
      pii: excludedPii,
      unreviewed: excludedUnreviewed,
      rejected: excludedRejected,
      deleted: excludedDeleted,
    },
    manifestPath,
  };
});

export const __testables = {
  detectSensitiveTextInNotes,
  isAdminContext,
  likelySensitiveFromSignals,
  resolveAuthoritativeLabel,
  buildManifestRow,
  shouldCleanupCandidate,
  runTrainingReviewCleanup,
};
