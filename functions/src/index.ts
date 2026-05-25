import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { FieldValue } from 'firebase-admin/firestore';
import { OpenAI } from 'openai';
import { toFile } from 'openai/uploads';
import axios from 'axios';
import { QUOTA_TIER_MULTIPLIERS, QuotaTier } from './rate_limit_config';
import {
  asiaSouth1, corsHandler, shouldEnforceCallableAppCheck,
  getBearerToken, getRateLimitConfig, enforceRateLimit,
  bumpOpsMetric, isProductionRuntime,
  validateAppCheckProductionGuardrails,
} from './helpers';

// Re-export all module functions
export { generateDisposal } from './disposal';
export { createCheckoutSession } from './create_checkout_session';
export { createTokenPurchaseSession } from './create_token_purchase';
export { dodopaymentsWebhook } from './dodopayments_webhook';
export { getR2UploadUrl } from './r2_storage';
export { createReferralCode, redeemReferralCode, getReferralStats } from './referrals';
export { aggregateFamilyDashboardAnalytics } from './family_dashboard_analytics';
export { migrateLegacyUserData } from './migrate_legacy_user_data';

// Initialize Firebase Admin
admin.initializeApp();

export const getOpenAiApiKey = (): string | undefined => {
  return process.env.OPENAI_API_KEY
    || process.env.OPENAI_KEY;
};

// Initialize OpenAI (conditional)
let openai: OpenAI | null = null;
try {
  const apiKey = getOpenAiApiKey();
  if (apiKey) {
    openai = new OpenAI({ apiKey });
    functions.logger.info('OpenAI initialized successfully');
  } else {
    functions.logger.warn('OpenAI API key not configured - functions will use fallback responses');
  }
} catch (error) {
  functions.logger.warn('Failed to initialize OpenAI', { error });
}

validateAppCheckProductionGuardrails();

export const __testables = {
  isProductionRuntime,
  validateAppCheckProductionGuardrails,
};

const verifyAdminHttpRequest = async (req: functions.Request): Promise<boolean> => {
  const token = getBearerToken(req.headers.authorization);
  if (!token) return false;
  try {
    const decoded = await admin.auth().verifyIdToken(token);
    return decoded.admin === true;
  } catch {
    return false;
  }
};

// Health check endpoint
export const healthCheck = asiaSouth1.https.onRequest((req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Test endpoint to verify OpenAI configuration
export const testOpenAI = asiaSouth1.https.onRequest((req, res) => {
  const diagnosticsEnabled = process.env.ENABLE_DIAGNOSTIC_ENDPOINTS === 'true';
  if (!diagnosticsEnabled) {
    res.status(403).json({ error: 'Diagnostics disabled' });
    return;
  }

  verifyAdminHttpRequest(req).then((isAdmin) => {
    if (!isAdmin) {
      res.status(403).json({ error: 'Forbidden: admin token required' });
      return;
    }
    const apiKey = getOpenAiApiKey();
    res.json({
      status: 'ok',
      openaiConfigured: !!apiKey,
      timestamp: new Date().toISOString()
    });
  }).catch(() => {
    res.status(500).json({ error: 'Failed to verify request' });
  });
});

export const spendUserTokens = asiaSouth1.https.onCall(async (data, context) => {
  if (!context.auth?.uid) {
    await bumpOpsMetric('spendUserTokens_unauthenticated', {
      route: 'spendUserTokens',
    });
    throw new functions.https.HttpsError('unauthenticated', 'Authentication required.');
  }

  if (shouldEnforceCallableAppCheck() && !context.app) {
    await bumpOpsMetric('spendUserTokens_appcheck_missing', {
      route: 'spendUserTokens',
      uid: context.auth.uid,
    });
    throw new functions.https.HttpsError(
      'failed-precondition',
      'App Check token required for spendUserTokens.'
    );
  }

  const rateLimitConfig = getRateLimitConfig();
  const rateLimitState = await enforceRateLimit({
    bucket: 'spendUserTokens',
    subject: `uid:${context.auth.uid}`,
    maxRequests: Math.max(1, rateLimitConfig.spendTokensMax),
    windowSeconds: Math.max(1, rateLimitConfig.windowSeconds),
  });
  if (rateLimitState.retryAfterSeconds > 0) {
    await bumpOpsMetric('spendUserTokens_rate_limited', {
      route: 'spendUserTokens',
      uid: context.auth.uid,
      retryAfterSeconds: rateLimitState.retryAfterSeconds,
    });
    throw new functions.https.HttpsError(
      'resource-exhausted',
      'Rate limit exceeded for spendUserTokens.',
      { retryAfterSeconds: rateLimitState.retryAfterSeconds }
    );
  }

  const clientAmount = Number(data?.amount);
  const description = String(data?.description ?? '').trim();
  const reference = data?.reference ? String(data.reference) : null;
  const metadata = (data?.metadata && typeof data.metadata === 'object')
    ? data.metadata as Record<string, unknown>
    : {};

  // operationType may be supplied as a top-level field OR inside metadata.
  // Top-level takes precedence; metadata.analysis_speed is a legacy fallback.
  const rawOperationType = data?.operationType
    ?? (typeof metadata.analysis_speed === 'string' ? metadata.analysis_speed : undefined);
  const operationType: 'instant' | 'batch' | null =
    rawOperationType === 'instant' || rawOperationType === 'batch'
      ? (rawOperationType as 'instant' | 'batch')
      : null;

  if (!Number.isFinite(clientAmount) || clientAmount <= 0 || !Number.isInteger(clientAmount)) {
    throw new functions.https.HttpsError('invalid-argument', 'amount must be a positive integer.');
  }
  if (!description) {
    throw new functions.https.HttpsError('invalid-argument', 'description is required.');
  }

  const uid = context.auth.uid;
  const db = admin.firestore();
  const userRef = db.collection('users').doc(uid);

  const result = await db.runTransaction(async (tx) => {
    const userSnap = await tx.get(userRef);
    if (!userSnap.exists) {
      throw new functions.https.HttpsError('not-found', 'User profile not found.');
    }

    const userData = userSnap.data() ?? {};
    const walletRaw = (userData.tokenWallet && typeof userData.tokenWallet === 'object')
      ? userData.tokenWallet as Record<string, unknown>
      : {};

    const currentBalance = Number(walletRaw.balance ?? 50);
    const totalEarned = Number(walletRaw.totalEarned ?? 50);
    const totalSpent = Number(walletRaw.totalSpent ?? 0);
    const dailyConversionsUsed = Number(walletRaw.dailyConversionsUsed ?? 0);
    const lastConversionDate = walletRaw.lastConversionDate ?? null;

    // -------------------------------------------------------------------------
    // Server-side subscription tier verification.
    //
    // Canonical entitlement authority is Firestore:
    //   users/{uid}.billing.entitlements.pro_subscription
    //
    // We still accept auth claims as fallback to avoid hard user breakage during
    // propagation delays, but the client payload is never trusted.
    // -------------------------------------------------------------------------
    const billing = (userData.billing && typeof userData.billing === 'object')
      ? (userData.billing as Record<string, unknown>)
      : {};
    const billingEntitlements =
      (billing.entitlements && typeof billing.entitlements === 'object')
        ? (billing.entitlements as Record<string, unknown>)
        : {};
    const hasBillingPremium = billingEntitlements.pro_subscription === true;

    const authClaims = (context.auth?.token && typeof context.auth.token === 'object')
      ? (context.auth.token as Record<string, unknown>)
      : {};
    const claimEntitlements =
      (authClaims.entitlements && typeof authClaims.entitlements === 'object')
        ? (authClaims.entitlements as Record<string, unknown>)
        : {};
    const hasClaimsPremium =
      authClaims.pro_subscription === true ||
      authClaims.premium === true ||
      authClaims.pro === true ||
      claimEntitlements.pro_subscription === true;

    const hasPremiumEntitlement = hasBillingPremium || hasClaimsPremium;
    const spendAuthoritySource: 'billing_entitlement' | 'claims_fallback' | 'none' = hasBillingPremium
      ? 'billing_entitlement'
      : (hasClaimsPremium ? 'claims_fallback' : 'none');

    const rawTierValue = String(
      userData.subscriptionTier ?? userData.tier ?? 'free'
    ).toLowerCase().trim();
    const normalizedTier: QuotaTier = (rawTierValue in QUOTA_TIER_MULTIPLIERS)
      ? (rawTierValue as QuotaTier)
      : 'free';

    const tier: QuotaTier = hasPremiumEntitlement
      ? (normalizedTier === 'enterprise' ? 'enterprise' : 'premium')
      : normalizedTier;

    if (!hasBillingPremium && hasClaimsPremium) {
      functions.logger.warn('spendUserTokens: premium derived from claims fallback', {
        uid,
        normalizedTier,
      });
      await bumpOpsMetric('spendUserTokens_claims_fallback', {
        route: 'spendUserTokens',
        uid,
        normalizedTier,
      });
    }

    // -------------------------------------------------------------------------
    // Server-side canonical cost computation.
    //
    // Base costs (mirror token_wallet.dart / token_service.dart):
    //   batch   = 1 token
    //   instant = 5 tokens (free)
    //
    // Premium/enterprise instant discount is server-configurable via
    // SPEND_PREMIUM_DISCOUNT_PERCENT (default 50, matching Flutter's
    // TokenService.premiumInstantDiscountPercent = 50) and is always computed
    // on server-authoritative entitlement.
    // Math.floor matches Dart's ~/ (truncating integer division) so that
    // server-computed cost == client-computed cost for identical inputs.
    // -------------------------------------------------------------------------
    const INSTANT_COST_FREE = 5;
    const premiumDiscountPercentRaw = Number(
      process.env.SPEND_PREMIUM_DISCOUNT_PERCENT ?? 50,
    );
    const premiumDiscountPercent = Number.isFinite(premiumDiscountPercentRaw)
      ? Math.max(0, Math.min(100, premiumDiscountPercentRaw))
      : 50;
    const INSTANT_COST_PREMIUM = Math.max(
      1,
      Math.floor(INSTANT_COST_FREE * (1 - premiumDiscountPercent / 100)),
    );
    const BATCH_COST = 1;

    let authorizedAmount = clientAmount;
    let serverComputedMinimum: number | null = null;

    if (operationType !== null) {
      const serverMin: number = (operationType === 'batch')
        ? BATCH_COST
        : (tier === 'free' ? INSTANT_COST_FREE : INSTANT_COST_PREMIUM);
      serverComputedMinimum = serverMin;

      if (clientAmount < serverMin) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          `Token spend ${clientAmount} is below the server-computed minimum ` +
            `${serverMin} for ${operationType} analysis (tier: ${tier}). ` +
            'Discounts are applied server-side based on verified subscription tier.'
        );
      }

      if (clientAmount > serverMin) {
        functions.logger.warn('spendUserTokens: client amount exceeds server minimum', {
          uid,
          clientAmount,
          serverMin,
          operationType,
          tier,
        });
        authorizedAmount = serverMin;
      } else {
        authorizedAmount = serverMin;
      }
    }

    const amount = authorizedAmount;
    const spendObservabilityMetadata = {
      ...metadata,
      operationType,
      spendAuthoritySource,
      serverTier: tier,
      requestedClientAmount: clientAmount,
      authorizedAmount: amount,
      serverComputedMinimum,
      spendComputationMode: operationType === null ? 'client_declared' : 'server_computed',
    };

    if (!Number.isFinite(currentBalance) || currentBalance < amount) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        `Insufficient tokens. Need ${amount}, have ${Number.isFinite(currentBalance) ? currentBalance : 0}.`
      );
    }

    const nowIso = new Date().toISOString();
    const nextWallet = {
      balance: currentBalance - amount,
      totalEarned,
      totalSpent: totalSpent + amount,
      lastUpdated: nowIso,
      dailyConversionsUsed,
      lastConversionDate,
    };

    const txId = db.collection('_tmp').doc().id;
    const ledgerRef = db.collection('token_spend_ledger').doc(txId);
    const transaction = {
      id: txId,
      delta: -amount,
      type: 'TokenTransactionType.spend',
      timestamp: nowIso,
      description,
      reference,
      metadata: spendObservabilityMetadata,
    };

    const currentTransactions = Array.isArray(userData.tokenTransactions)
      ? userData.tokenTransactions as unknown[]
      : [];
    const updatedTransactions = [transaction, ...currentTransactions].slice(0, 200);

    tx.update(userRef, {
      tokenWallet: nextWallet,
      tokenTransactions: updatedTransactions,
      lastActive: nowIso,
    });

    tx.set(ledgerRef, {
      id: txId,
      uid,
      amount,
      description,
      reference,
      metadata: spendObservabilityMetadata,
      subscriptionTier: tier,
      createdAtIso: nowIso,
      createdAt: FieldValue.serverTimestamp(),
      walletBalanceAfter: nextWallet.balance,
      walletSpentAfter: nextWallet.totalSpent,
    });

    return {
      wallet: nextWallet,
      transaction,
      ledgerId: txId,
    };
  });

  return {
    success: true,
    wallet: result.wallet,
    transaction: result.transaction,
    ledgerId: result.ledgerId,
  };
});

// FIXED: Clear all data function that properly awaits all deletions
export const clearAllData = asiaSouth1.https.onCall(async (data, context) => {
  try {
    functions.logger.info('Starting COMPLETE Firestore data clearing...');

    // Security check - must be authenticated
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    // Security gate - explicit runtime kill switch required.
    const clearAllDataEnabled = process.env.CLEAR_ALL_DATA_ENABLED === 'true';
    if (!clearAllDataEnabled) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'clearAllData is disabled. Set CLEAR_ALL_DATA_ENABLED=true only for controlled environments.'
      );
    }

    // Security gate - admin claim required.
    const isAdmin = context.auth.token?.admin === true;
    if (!isAdmin) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Only admin users can invoke clearAllData.'
      );
    }

    const db = admin.firestore();
    const projectId = process.env.GCLOUD_PROJECT;

    if (!projectId) {
      throw new functions.https.HttpsError('internal', 'Project ID not available');
    }

    functions.logger.info('Clearing all data for project', { projectId });

    // Get all root-level collections
    const collections = await db.listCollections();
    functions.logger.info('Found root collections', { count: collections.length });

    // Delete each collection recursively and await ALL deletions
    const deletePromises = collections.map(async (collection) => {
      const collectionPath = collection.path;
      functions.logger.info('Deleting collection', { collectionPath });

      try {
        await deleteCollectionRecursively(db, collectionPath);
        functions.logger.info('Deleted collection', { collectionPath });
      } catch (error) {
        functions.logger.error('Error deleting collection', { collectionPath, error });
        throw error;
      }
    });

    // CRITICAL: Wait for ALL deletions to complete before returning
    await Promise.all(deletePromises);

    functions.logger.info('All Firestore collections deleted successfully');

    // Reset community stats to zero
    await db.collection('community_stats').doc('main').set({
      totalUsers: 0,
      totalClassifications: 0,
      totalPoints: 0,
      categoryBreakdown: {},
      lastUpdated: FieldValue.serverTimestamp(),
      createdAt: FieldValue.serverTimestamp(),
    });

    functions.logger.info('Community stats reset to zero');
    functions.logger.info('COMPLETE Firestore data clearing finished successfully');

    return {
      success: true,
      message: 'All data cleared successfully',
      timestamp: new Date().toISOString(),
      collectionsDeleted: collections.length
    };

  } catch (error) {
    functions.logger.error('Error during data clearing', { error });
    throw new functions.https.HttpsError('internal', `Data clearing failed: ${error}`);
  }
});

// Helper function to recursively delete a collection
async function deleteCollectionRecursively(db: admin.firestore.Firestore, collectionPath: string): Promise<void> {
  const collectionRef = db.collection(collectionPath);
  const batchSize = 100;

  let query = collectionRef.limit(batchSize);
  let snapshot = await query.get();

  while (!snapshot.empty) {
    const batch = db.batch();

    for (const doc of snapshot.docs) {
      const subcollections = await doc.ref.listCollections();
      for (const subcollection of subcollections) {
        await deleteCollectionRecursively(db, subcollection.path);
      }

      batch.delete(doc.ref);
    }

    await batch.commit();
    functions.logger.info('Deleted batch', { count: snapshot.docs.length, collectionPath });

    // Get next batch
    snapshot = await query.get();
  }
}

// ===== BATCH PROCESSING FUNCTIONS =====

const normalizeOpenAIBatchStatus = (openAiStatus: string, fallback: string): string => {
  const statusMapping: Record<string, string> = {
    validating: 'queued',
    in_progress: 'processing',
    finalizing: 'processing',
    completed: 'completed',
    failed: 'failed',
    expired: 'failed',
    cancelled: 'failed',
  };

  return statusMapping[openAiStatus] ?? fallback;
};

const isUserOwnedBatchImageUrl = (imageUrl: string, uid: string): boolean => {
  const raw = imageUrl.trim();
  if (!raw.startsWith('https://') && !raw.startsWith('http://')) return false;

  try {
    const decoded = decodeURIComponent(raw);
    if (decoded.includes(`/batch_images/${uid}/`)) return true;
  } catch {
    // Ignore decode errors and continue with raw checks.
  }

  return raw.includes(`/batch_images/${uid}/`) ||
    raw.includes(`%2Fbatch_images%2F${uid}%2F`);
};

const getBatchClassificationPrompt = (): string => {
  return [
    'You are an expert waste classification AI.',
    'Classify the waste item from the image and return STRICT JSON only.',
    'Required JSON keys: itemName, category, confidence, disposalInstructions, environmentalImpact, tips.',
    'confidence must be a number between 0 and 1.',
    'tips must be an array of strings.',
    'Do not include markdown or extra prose.',
  ].join(' ');
};

async function createOpenAIBatchSubmission(jobId: string, imageUrl: string): Promise<{ batchId: string; batchFileId: string }> {
  if (!openai) {
    throw new Error('OpenAI not configured on server');
  }

  const batchRequest = {
    custom_id: `job-${jobId}`,
    method: 'POST',
    url: '/v1/chat/completions',
    body: {
      model: process.env.BATCH_OPENAI_MODEL || 'gpt-4o-mini',
      messages: [
        {
          role: 'system',
          content: getBatchClassificationPrompt(),
        },
        {
          role: 'user',
          content: [
            { type: 'text', text: 'Classify this waste item for proper disposal.' },
            {
              type: 'image_url',
              image_url: {
                url: imageUrl,
                detail: 'high',
              },
            },
          ],
        },
      ],
      max_tokens: 900,
      temperature: 0.1,
      response_format: {
        type: 'json_object',
      },
    },
  };

  const jsonl = `${JSON.stringify(batchRequest)}\n`;
  const file = await openai.files.create({
    file: await toFile(Buffer.from(jsonl, 'utf8'), `batch_${jobId}.jsonl`),
    purpose: 'batch',
  });

  const batch = await openai.batches.create({
    input_file_id: file.id,
    endpoint: '/v1/chat/completions',
    completion_window: '24h',
  });

  return {
    batchId: batch.id,
    batchFileId: file.id,
  };
}

export const createBatchAiJob = asiaSouth1.https.onCall(async (data, context) => {
  if (!context.auth?.uid) {
    await bumpOpsMetric('createBatchAiJob_unauthenticated', {
      route: 'createBatchAiJob',
    });
    throw new functions.https.HttpsError('unauthenticated', 'Authentication required.');
  }

  if (shouldEnforceCallableAppCheck() && !context.app) {
    await bumpOpsMetric('createBatchAiJob_appcheck_missing', {
      route: 'createBatchAiJob',
      uid: context.auth.uid,
    });
    throw new functions.https.HttpsError(
      'failed-precondition',
      'App Check token required for createBatchAiJob.'
    );
  }

  const uid = context.auth.uid;
  const imageUrl = String(data?.imageUrl ?? '').trim();

  if (!imageUrl) {
    throw new functions.https.HttpsError('invalid-argument', 'imageUrl is required.');
  }

  if (imageUrl.length > 2048) {
    throw new functions.https.HttpsError('invalid-argument', 'imageUrl is too long.');
  }

  if (!isUserOwnedBatchImageUrl(imageUrl, uid)) {
    await bumpOpsMetric('createBatchAiJob_owner_path_denied', {
      route: 'createBatchAiJob',
      uid,
    });
    throw new functions.https.HttpsError(
      'permission-denied',
      'imageUrl must reference an authenticated user-owned batch_images path.'
    );
  }

  const rateLimitConfig = getRateLimitConfig();
  const rateLimitState = await enforceRateLimit({
    bucket: 'createBatchAiJob',
    subject: `uid:${uid}`,
    maxRequests: Math.max(1, rateLimitConfig.spendTokensMax),
    windowSeconds: Math.max(1, rateLimitConfig.windowSeconds),
  });

  if (rateLimitState.retryAfterSeconds > 0) {
    await bumpOpsMetric('createBatchAiJob_rate_limited', {
      route: 'createBatchAiJob',
      uid,
      retryAfterSeconds: rateLimitState.retryAfterSeconds,
    });
    throw new functions.https.HttpsError(
      'resource-exhausted',
      'Rate limit exceeded for createBatchAiJob.',
      { retryAfterSeconds: rateLimitState.retryAfterSeconds }
    );
  }

  const db = admin.firestore();
  const userRef = db.collection('users').doc(uid);
  const jobsRef = db.collection('ai_jobs');
  const tokenCost = 1;
  const jobId = jobsRef.doc().id;
  const spendReference = `batch_job:${jobId}`;
  const nowIso = new Date().toISOString();

  const spendResult = await db.runTransaction(async (tx) => {
    const userSnap = await tx.get(userRef);
    if (!userSnap.exists) {
      throw new functions.https.HttpsError('not-found', 'User profile not found.');
    }

    const userData = userSnap.data() ?? {};
    const walletRaw = (userData.tokenWallet && typeof userData.tokenWallet === 'object')
      ? userData.tokenWallet as Record<string, unknown>
      : {};

    const currentBalance = Number(walletRaw.balance ?? 50);
    const totalEarned = Number(walletRaw.totalEarned ?? 50);
    const totalSpent = Number(walletRaw.totalSpent ?? 0);
    const dailyConversionsUsed = Number(walletRaw.dailyConversionsUsed ?? 0);
    const lastConversionDate = walletRaw.lastConversionDate ?? null;

    if (!Number.isFinite(currentBalance) || currentBalance < tokenCost) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        `Insufficient tokens. Need ${tokenCost}, have ${Number.isFinite(currentBalance) ? currentBalance : 0}.`
      );
    }

    const nextWallet = {
      balance: currentBalance - tokenCost,
      totalEarned,
      totalSpent: totalSpent + tokenCost,
      lastUpdated: nowIso,
      dailyConversionsUsed,
      lastConversionDate,
    };

    const txId = db.collection('_tmp').doc().id;
    const ledgerRef = db.collection('token_spend_ledger').doc(txId);
    const transaction = {
      id: txId,
      delta: -tokenCost,
      type: 'TokenTransactionType.spend',
      timestamp: nowIso,
      description: 'Batch AI analysis',
      reference: spendReference,
      metadata: {
        operationType: 'batch',
        source: 'createBatchAiJob',
        spendAuthoritySource: 'fixed_batch_cost',
        requestedClientAmount: tokenCost,
        authorizedAmount: tokenCost,
        jobId,
      },
    };

    const currentTransactions = Array.isArray(userData.tokenTransactions)
      ? userData.tokenTransactions as unknown[]
      : [];
    const updatedTransactions = [transaction, ...currentTransactions].slice(0, 200);

    tx.update(userRef, {
      tokenWallet: nextWallet,
      tokenTransactions: updatedTransactions,
      lastActive: nowIso,
    });

    tx.set(ledgerRef, {
      id: txId,
      uid,
      amount: tokenCost,
      description: 'Batch AI analysis',
      reference: spendReference,
      metadata: {
        operationType: 'batch',
        source: 'createBatchAiJob',
        spendAuthoritySource: 'fixed_batch_cost',
        requestedClientAmount: tokenCost,
        authorizedAmount: tokenCost,
        jobId,
      },
      subscriptionTier: 'batch',
      createdAtIso: nowIso,
      createdAt: FieldValue.serverTimestamp(),
      walletBalanceAfter: nextWallet.balance,
      walletSpentAfter: nextWallet.totalSpent,
    });

    return {
      wallet: nextWallet,
      transaction,
      ledgerId: txId,
    };
  });

  let batchSubmission: { batchId: string; batchFileId: string };

  try {
    batchSubmission = await createOpenAIBatchSubmission(jobId, imageUrl);
  } catch (error) {
    functions.logger.error('createBatchAiJob: OpenAI submission failed, refunding token', {
      uid,
      jobId,
      error,
    });
    await bumpOpsMetric('createBatchAiJob_refund_openai_submission_failed', {
      route: 'createBatchAiJob',
      uid,
      jobId,
    });

    const refundIso = new Date().toISOString();

    await db.runTransaction(async (tx) => {
      const userSnap = await tx.get(userRef);
      if (!userSnap.exists) return;

      const userData = userSnap.data() ?? {};
      const walletRaw = (userData.tokenWallet && typeof userData.tokenWallet === 'object')
        ? userData.tokenWallet as Record<string, unknown>
        : {};

      const currentBalance = Number(walletRaw.balance ?? 0);
      const totalEarned = Number(walletRaw.totalEarned ?? 0);
      const totalSpent = Number(walletRaw.totalSpent ?? 0);
      const dailyConversionsUsed = Number(walletRaw.dailyConversionsUsed ?? 0);
      const lastConversionDate = walletRaw.lastConversionDate ?? null;

      const refundedWallet = {
        balance: currentBalance + tokenCost,
        totalEarned,
        totalSpent: Math.max(0, totalSpent - tokenCost),
        lastUpdated: refundIso,
        dailyConversionsUsed,
        lastConversionDate,
      };

      const refundTxId = db.collection('_tmp').doc().id;
      const refundTx = {
        id: refundTxId,
        delta: tokenCost,
        type: 'TokenTransactionType.refund',
        timestamp: refundIso,
        description: 'Batch AI submission failed - token refund',
        reference: `${spendReference}:refund`,
        metadata: {
          operationType: 'batch',
          source: 'createBatchAiJob',
          spendAuthoritySource: 'fixed_batch_cost',
          refundReason: 'openai_submission_failed',
          originalLedgerId: spendResult.ledgerId,
          jobId,
        },
      };

      const currentTransactions = Array.isArray(userData.tokenTransactions)
        ? userData.tokenTransactions as unknown[]
        : [];
      const updatedTransactions = [refundTx, ...currentTransactions].slice(0, 200);

      tx.update(userRef, {
        tokenWallet: refundedWallet,
        tokenTransactions: updatedTransactions,
        lastActive: refundIso,
      });
    });

    throw new functions.https.HttpsError(
      'internal',
      'Failed to create OpenAI batch submission. Token has been refunded.'
    );
  }

  await jobsRef.doc(jobId).set({
    id: jobId,
    userId: uid,
    imagePath: imageUrl,
    speed: 'batch',
    status: 'queued',
    openAIBatchId: batchSubmission.batchId,
    batchFileId: batchSubmission.batchFileId,
    tokensSpent: tokenCost,
    createdAtIso: nowIso,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
    metadata: {
      source: 'createBatchAiJob',
      spendLedgerId: spendResult.ledgerId,
    },
  });

  return {
    success: true,
    jobId,
    status: 'queued',
    openAIBatchId: batchSubmission.batchId,
    tokensCharged: tokenCost,
    walletBalance: spendResult.wallet.balance,
    ledgerId: spendResult.ledgerId,
  };
});

interface BatchJobStatus {
  status: string;
  output_file_id?: string;
  errors?: any;
}

interface ClassificationResult {
  itemName: string;
  category: string;
  confidence: number;
  disposalInstructions: string;
  environmentalImpact: string;
  tips: string[];
  timestamp: admin.firestore.FieldValue;
  analysisMethod: string;
  processingTime: number;
}

/**
 * Cloud Function to process OpenAI batch jobs
 * Scheduled to run every 10 minutes
 */
export const processBatchJobs = asiaSouth1.pubsub
  .schedule('*/10 * * * *')
  .timeZone('UTC')
  .onRun(async (context) => {
    const logger = functions.logger;

    try {
      logger.info('Starting batch job processing');

      // Get all active batch jobs from Firestore
      const db = admin.firestore();
      const activeJobs = await db.collection('ai_jobs')
        .where('status', 'in', ['queued', 'processing', 'AiJobStatus.queued', 'AiJobStatus.processing'])
        .get();

      if (activeJobs.empty) {
        logger.info('No active batch jobs found');
        return null;
      }

      logger.info(`Found ${activeJobs.size} active batch jobs`);

      // Process each job
      const processingPromises = activeJobs.docs.map(async (jobDoc) => {
        const jobData = jobDoc.data();
        const jobId = jobDoc.id;
        const openAIBatchId = jobData.openAIBatchId;

        if (!openAIBatchId) {
          logger.warn(`Job ${jobId} missing OpenAI batch ID`);
          return;
        }

        try {
          // Check OpenAI batch status
          const batchStatus = await checkOpenAIBatchStatus(openAIBatchId);

          if (batchStatus.status !== jobData.status) {
            await updateJobStatus(jobId, batchStatus, jobData);
          }

          // If completed, process results
          if (batchStatus.status === 'completed' && batchStatus.output_file_id) {
            await processCompletedJob(jobId, batchStatus.output_file_id, jobData);
          }

          // If failed, update with error
          if (batchStatus.status === 'failed') {
            await updateJobWithError(jobId, batchStatus.errors || 'Batch job failed');
          }

        } catch (error) {
          logger.error(`Error processing job ${jobId}:`, error);
          await updateJobWithError(jobId, (error as Error).message);
        }
      });

      await Promise.all(processingPromises);
      logger.info('Batch job processing completed');
      return null;

    } catch (error) {
      logger.error('Error in batch job processing:', error);
      throw error;
    }
  });

/**
 * Checks the status of an OpenAI batch job
 */
async function checkOpenAIBatchStatus(batchId: string): Promise<BatchJobStatus> {
  const openaiApiKey = getOpenAiApiKey();

  if (!openaiApiKey) {
    throw new Error('OpenAI API key not configured');
  }

  const response = await axios.get(
    `https://api.openai.com/v1/batches/${batchId}`,
    {
      headers: {
        'Authorization': `Bearer ${openaiApiKey}`,
        'Content-Type': 'application/json',
      },
    }
  );

  return response.data;
}

/**
 * Downloads and processes results from completed OpenAI batch job
 */
async function processCompletedJob(jobId: string, outputFileId: string, jobData: any): Promise<void> {
  const logger = functions.logger;

  try {
    // Download results from OpenAI
    const results = await downloadOpenAIResults(outputFileId);

    // Parse the JSONL results
    const resultLines = results.split('\n').filter((line: string) => line.trim());

    for (const line of resultLines) {
      const result = JSON.parse(line);

      if (result.custom_id === `job-${jobId}`) {
        // Extract classification result
        const classification = parseClassificationResult(result);

        // Update Firestore with results
        const db = admin.firestore();
        await db.collection('ai_jobs').doc(jobId).update({
          status: 'completed',
          result: classification,
          completedAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        });

        // Add to user's classification history
        await addToClassificationHistory(jobData.userId, classification, jobData);

        // Trigger notification
        await triggerJobCompletionNotification(jobId, jobData.userId, classification);

        logger.info(`Successfully processed completed job ${jobId}`);
        break;
      }
    }

  } catch (error) {
    logger.error(`Error processing completed job ${jobId}:`, error);
    await updateJobWithError(jobId, `Failed to process results: ${(error as Error).message}`);
  }
}

/**
 * Downloads results from OpenAI Files API
 */
async function downloadOpenAIResults(fileId: string): Promise<string> {
  const openaiApiKey = getOpenAiApiKey();
  if (!openaiApiKey) {
    throw new Error('OpenAI API key not configured');
  }

  const response = await axios.get(
    `https://api.openai.com/v1/files/${fileId}/content`,
    {
      headers: {
        'Authorization': `Bearer ${openaiApiKey}`,
      },
    }
  );

  return response.data;
}

/**
 * Parses OpenAI response into WasteClassification format
 */
function parseClassificationResult(openaiResult: any): ClassificationResult {
  try {
    const response = openaiResult.response.body.choices[0].message.content;
    const parsed = JSON.parse(response);

    return {
      itemName: parsed.itemName || 'Unknown Item',
      category: parsed.category || 'general',
      confidence: parsed.confidence || 0.5,
      disposalInstructions: parsed.disposalInstructions || 'Dispose according to local guidelines',
      environmentalImpact: parsed.environmentalImpact || 'Environmental impact information not available',
      tips: parsed.tips || [],
      timestamp: FieldValue.serverTimestamp(),
      analysisMethod: 'batch_ai',
      processingTime: 0,
    };
  } catch (error) {
    functions.logger.error('Error parsing classification result:', error);

    return {
      itemName: 'Classification Error',
      category: 'general',
      confidence: 0.1,
      disposalInstructions: 'Unable to classify item. Please dispose according to local guidelines.',
      environmentalImpact: 'Classification failed - environmental impact unknown',
      tips: ['Contact local waste management for guidance'],
      timestamp: FieldValue.serverTimestamp(),
      analysisMethod: 'batch_ai_fallback',
      processingTime: 0,
    };
  }
}

/**
 * Updates job status in Firestore
 */
async function updateJobStatus(jobId: string, batchStatus: BatchJobStatus, currentJobData: any): Promise<void> {
  const db = admin.firestore();
  const currentStatus = String(currentJobData?.status ?? 'queued');
  const nextStatus = normalizeOpenAIBatchStatus(batchStatus.status, currentStatus);

  if (nextStatus === currentStatus && batchStatus.status === currentJobData?.openAIStatus) {
    return;
  }

  await db.collection('ai_jobs').doc(jobId).update({
    status: nextStatus,
    openAIStatus: batchStatus.status,
    updatedAt: FieldValue.serverTimestamp(),
    ...(nextStatus === 'processing' && !currentJobData.processingStartedAt && {
      processingStartedAt: FieldValue.serverTimestamp()
    })
  });

  functions.logger.info(`Updated job ${jobId} status: ${currentStatus} -> ${nextStatus}`, {
    openAIStatus: batchStatus.status,
  });
}

/**
 * Updates job with error information
 */
async function updateJobWithError(jobId: string, errorMessage: string): Promise<void> {
  const db = admin.firestore();

  await db.collection('ai_jobs').doc(jobId).update({
    status: 'failed',
    error: errorMessage,
    failedAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });

  functions.logger.error(`Job ${jobId} failed: ${errorMessage}`);
}

/**
 * Adds classification to user's history
 */
async function addToClassificationHistory(userId: string, classification: ClassificationResult, jobData: any): Promise<void> {
  const db = admin.firestore();

  const historyEntry = {
    ...classification,
    userId,
    imagePath: jobData.imagePath,
    thumbnailPath: jobData.thumbnailPath,
    createdAt: FieldValue.serverTimestamp(),
    source: 'batch_processing',
    jobId: jobData.id,
  };

  await db.collection('classifications').add(historyEntry);
  functions.logger.info(`Added classification to history for user ${userId}`);
}

/**
 * Triggers notification for job completion
 */
async function triggerJobCompletionNotification(jobId: string, userId: string, classification: ClassificationResult): Promise<void> {
  const db = admin.firestore();

  const notification = {
    userId,
    type: 'batch_job_completed',
    title: 'Analysis Complete!',
    message: `Your ${classification.itemName} has been analyzed`,
    data: {
      jobId,
      classification,
    },
    createdAt: FieldValue.serverTimestamp(),
    read: false,
  };

  await db.collection('notifications').add(notification);
  functions.logger.info(`Created notification for user ${userId} - job ${jobId}`);
}

// ---------------------------------------------------------------------------
// Backend classification gateway (image proxy with App Check + rate limit)
// ---------------------------------------------------------------------------
export { classifyImage, reanalyzeWithCorrection } from './classify_image';
export {
  evaluateOpsThresholdAlerts,
  getClassifyReservationDashboard,
  reconcileStaleClassifyReservations,
  syncEntitlementClaims,
} from './ops_hardening';
export {
  attachTrainingLabelFeedback,
  buildTrainingDatasetManifest,
  cleanupTrainingReviewImages,
  enqueueTrainingCandidate,
  getTrainingReviewQueue,
  reviewTrainingCandidate,
  revokeTrainingConsent,
} from './training_data';

// Phase 5 community stats scaling path: materialized aggregates with hourly batching
export {
  aggregateCommunityStats,
  aggregateCommunityStatsHttp,
} from './community_stats_aggregator';

/**
 * HTTP endpoint to get batch processing statistics
 */
export const getBatchStats = asiaSouth1.https.onRequest(async (req, res) => {
  return corsHandler(req, res, async () => {
    try {
      const db = admin.firestore();

      // Get job counts by status
      const [queuedJobs, processingJobs, completedJobs, failedJobs] = await Promise.all([
        db.collection('ai_jobs').where('status', '==', 'queued').get(),
        db.collection('ai_jobs').where('status', '==', 'processing').get(),
        db.collection('ai_jobs').where('status', '==', 'completed').get(),
        db.collection('ai_jobs').where('status', '==', 'failed').get(),
      ]);

      const stats = {
        queued: queuedJobs.size,
        processing: processingJobs.size,
        completed: completedJobs.size,
        failed: failedJobs.size,
        total: queuedJobs.size + processingJobs.size + completedJobs.size + failedJobs.size,
        timestamp: new Date().toISOString(),
      };

      res.json(stats);

    } catch (error) {
      functions.logger.error('Error getting batch stats', { error });
      res.status(500).json({ error: 'Failed to get batch statistics' });
    }
  });
});
