/**
 * classify_image.ts
 *
 * Firebase HTTPS Callable function that proxies image classification through the
 * backend. This enables:
 *   - App Check enforcement (fail-closed when REQUIRE_APPCHECK_CALLABLE=true)
 *   - Firebase Auth requirement (unauthenticated requests are rejected)
 *   - Per-UID rate limiting (10 req/min free tier — images are expensive)
 *   - Server-side SHA-256 hashing for cache keying (client-supplied hash is
 *     accepted as a deduplication hint only, never trusted as a cache key)
 *   - Result caching in Firestore `classifications` collection
 *   - Cost telemetry in Firestore `ai_cost_events` collection
 *   - Privacy-preserving design: image bytes are NEVER stored; only the hash
 *
 * Provider routing:
 *   Primary:  OpenAI gpt-4.1-nano  (cheap, fast vision model)
 *   Fallback: Gemini 2.0 Flash     (via Generative Language API)
 *
 * Environment variables:
 *   OPENAI_API_KEY / OPENAI_KEY          — OpenAI secret (required for primary)
 *   GEMINI_API_KEY                       — Google AI key (required for fallback)
 *   REQUIRE_APPCHECK_CALLABLE            — set "true" to enforce App Check
 *   ENFORCE_APPCHECK_IN_EMULATOR         — set "true" to also enforce in emulator
 *   CLASSIFY_IMAGE_MAX_REQUESTS          — per-window request cap (default: 10)
 *   CLASSIFY_IMAGE_WINDOW_SECONDS        — rate-limit window in seconds (default: 60)
 *   CLASSIFY_CACHE_TTL_SECONDS           — cache TTL for results (default: 86400)
 *   FUNCTIONS_EMULATOR                   — set by the Firebase emulator automatically
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { FieldValue } from 'firebase-admin/firestore';
import { createHash } from 'crypto';
import axios from 'axios';

// ---------------------------------------------------------------------------
// Re-use helpers from index.ts — imported to keep patterns consistent.
// We declare local copies here so this file can be independently imported;
// index.ts also imports the same utilities from the same runtime module cache.
// ---------------------------------------------------------------------------

const parseBoolEnv = (value: string | undefined, fallback = false): boolean => {
  if (value == null) return fallback;
  const normalized = value.trim().toLowerCase();
  if (['true', '1', 'yes', 'on'].includes(normalized)) return true;
  if (['false', '0', 'no', 'off'].includes(normalized)) return false;
  return fallback;
};

const shouldEnforceCallableAppCheck = (): boolean => {
  const requireAppCheck = parseBoolEnv(process.env.REQUIRE_APPCHECK_CALLABLE, false);
  if (!requireAppCheck) return false;
  if (process.env.FUNCTIONS_EMULATOR === 'true') {
    return parseBoolEnv(process.env.ENFORCE_APPCHECK_IN_EMULATOR, false);
  }
  return true;
};

const getOpenAiApiKey = (): string | undefined => {
  return process.env.OPENAI_API_KEY
    || process.env.OPENAI_KEY;
};

const getGeminiApiKey = (): string | undefined => {
  return process.env.GEMINI_API_KEY;
};

const enforceRateLimit = async ({
  bucket,
  subject,
  maxRequests,
  windowSeconds,
}: {
  bucket: string;
  subject: string;
  maxRequests: number;
  windowSeconds: number;
}): Promise<{ remaining: number; retryAfterSeconds: number }> => {
  const db = admin.firestore();
  const safeSubject = subject.replace(/[^a-zA-Z0-9_:\-.]/g, '_').slice(0, 120);
  const docRef = db.collection('rate_limits').doc(`${bucket}:${safeSubject}`);
  const nowMs = Date.now();

  return db.runTransaction(async (tx) => {
    const snap = await tx.get(docRef);
    const existing = snap.exists ? (snap.data() ?? {}) : {};

    const currentCount = Number(existing.count ?? 0);
    const windowStartMs = Number(existing.windowStartMs ?? nowMs);
    const windowDurationMs = Math.max(1, windowSeconds) * 1000;
    const inWindow = nowMs - windowStartMs < windowDurationMs;

    if (inWindow && currentCount >= maxRequests) {
      const elapsedMs = nowMs - windowStartMs;
      const retryAfterSeconds = Math.max(1, Math.ceil((windowDurationMs - elapsedMs) / 1000));
      return { remaining: 0, retryAfterSeconds };
    }

    const nextCount = inWindow ? currentCount + 1 : 1;
    const nextWindowStartMs = inWindow ? windowStartMs : nowMs;

    tx.set(docRef, {
      bucket,
      subject: safeSubject,
      count: nextCount,
      windowStartMs: nextWindowStartMs,
      windowSeconds,
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });

    return {
      remaining: Math.max(0, maxRequests - nextCount),
      retryAfterSeconds: 0,
    };
  });
};

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

/** Request payload sent by the Flutter BackendProxyProvider. */
interface ClassifyImageRequest {
  /** Base64-encoded raw image bytes. Max 4 MB before encoding (~5.4 MB base64). */
  imageBase64: string;
  /** MIME type declared by client — validated server-side. */
  mimeType: 'image/jpeg' | 'image/png' | 'image/webp';
  /**
   * Client-computed content hash (optional deduplication hint).
   * NOT trusted as a cache key. The server independently hashes the received
   * bytes and uses that server-side SHA-256 as the authoritative key.
   */
  clientHash?: string;
  /** User's region for local guidelines context (e.g. "Bangalore, IN"). */
  region?: string;
  /** BCP-47 language code for response language (e.g. "en", "hi", "kn"). */
  lang?: string;
  /**
   * Optional idempotency key generated by the client for request retries.
   * If present, repeated requests with the same key will not be double-charged.
   */
  requestId?: string;
}

/**
 * Cached / returned classification result.
 *
 * This is the JSON shape stored in Firestore `classifications` and returned
 * to the Flutter client. It intentionally matches the fields parsed by
 * WasteClassification.fromJson() in the Flutter model so the client can
 * pass rawResponseMap directly to that factory.
 */
interface ClassificationResult {
  // Core identification
  itemName: string;
  category: string;
  subcategory?: string;
  materialType?: string;
  recyclingCode?: number;
  explanation: string;
  disposalMethod?: string;
  // Nested object — matches DisposalInstructions.fromJson
  disposalInstructions: {
    primaryMethod: string;
    steps: string[];
    timeframe?: string;
    location?: string;
    warnings?: string[];
    tips?: string[];
    recyclingInfo?: string;
    estimatedTime?: string;
    hasUrgentTimeframe: boolean;
  };
  region: string;
  visualFeatures: string[];
  isRecyclable?: boolean;
  isCompostable?: boolean;
  requiresSpecialDisposal?: boolean;
  isSingleUse?: boolean;
  colorCode?: string;
  riskLevel?: string;
  requiredPPE?: string[];
  brand?: string;
  product?: string;
  confidence?: number;
  clarificationNeeded?: boolean;
  alternatives: Array<{
    category: string;
    subcategory?: string;
    confidence: number;
    reason: string;
  }>;
  suggestedAction?: string;
  hasUrgentTimeframe?: boolean;
  instructionsLang?: string;
  environmentalImpact?: string;
  // Enhanced AI v2.0 fields
  recyclability?: string;
  hazardLevel?: number;
  co2Impact?: number;
  decompositionTime?: string;
  properEquipment?: string[];
  materials?: string[];
  subCategory?: string;
  commonUses?: string[];
  alternativeOptions?: string[];
  localRegulations?: Record<string, string>;
  waterPollutionLevel?: number;
  soilContaminationRisk?: number;
  biodegradabilityDays?: number;
  recyclingEfficiency?: number;
  bbmpComplianceStatus?: string;
  localGuidelinesVersion?: string;
  generatesMicroplastics?: boolean;
  humanToxicityLevel?: number;
  wildlifeImpactSeverity?: number;
  resourceScarcity?: string;
  // Provenance
  modelSource?: string;
  modelVersion?: string;
  pointsAwarded?: number | null;
}

/** Metadata written to Firestore for cost tracking. */
interface AiCostEvent {
  uid: string;
  timestamp: admin.firestore.FieldValue;
  provider: string;
  model: string;
  inputTokens: number | null;
  outputTokens: number | null;
  estimatedCostUsd: number | null;
  imageHash: string;
  success: boolean;
  cacheHit: boolean;
}

interface ServerTokenWallet {
  balance: number;
  totalEarned: number;
  totalSpent: number;
  lastUpdated: string;
  dailyConversionsUsed: number;
  lastConversionDate: unknown;
}

interface ServerTokenTransaction {
  id: string;
  delta: number;
  type: string;
  timestamp: string;
  description: string;
  reference: string | null;
  metadata: Record<string, unknown>;
}

interface TokenReservationResult {
  wallet: ServerTokenWallet;
  transaction: ServerTokenTransaction;
  tokenCost: number;
  premiumApplied: boolean;
  reservationId: string;
  status: 'reserved' | 'consumed' | 'refunded';
  reusedExistingReservation: boolean;
}

interface EntitlementResolution {
  hasPremium: boolean;
  source: 'billing_entitlements' | 'auth_claims' | 'none';
}

type ReservationStatus = 'reserved' | 'consumed' | 'refunded';

// ---------------------------------------------------------------------------
// Rate limit config
// ---------------------------------------------------------------------------

const getClassifyRateLimitConfig = () => ({
  maxRequests: Number(process.env.CLASSIFY_IMAGE_MAX_REQUESTS ?? 10),
  windowSeconds: Number(process.env.CLASSIFY_IMAGE_WINDOW_SECONDS ?? 60),
});

const getCacheTtlSeconds = (): number =>
  Number(process.env.CLASSIFY_CACHE_TTL_SECONDS ?? 86400);

const getClassifyTokenCost = (): number =>
  Math.max(1, Number(process.env.CLASSIFY_IMAGE_TOKEN_COST ?? 5));

const getClassifyPremiumDiscountPercent = (): number => {
  const value = Number(process.env.CLASSIFY_IMAGE_PREMIUM_DISCOUNT_PERCENT ?? 50);
  if (!Number.isFinite(value)) return 50;
  return Math.min(90, Math.max(0, value));
};

const isTokenSpendEnforced = (): boolean =>
  parseBoolEnv(process.env.CLASSIFY_ENFORCE_TOKEN_SPEND, true);

const hasPremiumFromAuthClaims = (authToken: Record<string, unknown> | undefined): boolean => {
  if (!authToken) return false;
  const entitlements = authToken.entitlements;
  if (entitlements && typeof entitlements === 'object') {
    const entitlementMap = entitlements as Record<string, unknown>;
    return entitlementMap.pro_subscription === true;
  }
  return false;
};

const resolvePremiumEntitlement = (
  userData: Record<string, unknown>,
  authToken: Record<string, unknown> | undefined,
): EntitlementResolution => {
  const billing = userData.billing;
  if (billing && typeof billing === 'object') {
    const billingMap = billing as Record<string, unknown>;
    const entitlements = billingMap.entitlements;
    if (entitlements && typeof entitlements === 'object') {
      const entitlementMap = entitlements as Record<string, unknown>;
      if (entitlementMap.pro_subscription === true) {
        return { hasPremium: true, source: 'billing_entitlements' };
      }
    }
  }

  if (hasPremiumFromAuthClaims(authToken)) {
    return { hasPremium: true, source: 'auth_claims' };
  }

  return { hasPremium: false, source: 'none' };
};

const computeClassifyTokenCost = (
  baseCost: number,
  hasPremiumEntitlement: boolean,
): { tokenCost: number; premiumApplied: boolean } => {
  if (!hasPremiumEntitlement) {
    return { tokenCost: baseCost, premiumApplied: false };
  }
  const discountPercent = getClassifyPremiumDiscountPercent();
  const discountedCost = Math.max(1, Math.floor((baseCost * (100 - discountPercent)) / 100));
  return { tokenCost: discountedCost, premiumApplied: true };
};

const buildReservationId = (uid: string, requestId: string): string => {
  const normalized = requestId.trim();
  return createHash('sha256')
    .update(`classifyImage|${uid}|${normalized}`)
    .digest('hex')
    .slice(0, 48);
};

const normalizeRequestId = (requestId: unknown): string | null => {
  if (typeof requestId !== 'string') return null;
  const trimmed = requestId.trim();
  if (trimmed.length < 8 || trimmed.length > 160) return null;
  return trimmed;
};

async function reserveClassificationTokens(params: {
  uid: string;
  authToken?: Record<string, unknown>;
  imageHash: string;
  region: string;
  lang: string;
  requestId?: string | null;
}): Promise<TokenReservationResult> {
  const { uid, authToken, imageHash, region, lang, requestId } = params;
  const db = admin.firestore();
  const userRef = db.collection('users').doc(uid);
  const normalizedRequestId = normalizeRequestId(requestId);
  const reservationId = normalizedRequestId
    ? buildReservationId(uid, normalizedRequestId)
    : `adhoc_${db.collection('_tmp').doc().id}`;
  const reservationRef = db.collection('classify_token_reservations').doc(reservationId);

  return db.runTransaction(async (tx) => {
    const [userSnap, reservationSnap] = await Promise.all([
      tx.get(userRef),
      tx.get(reservationRef),
    ]);

    if (!userSnap.exists) {
      throw new functions.https.HttpsError('failed-precondition', 'User profile missing; cannot charge tokens.');
    }

    const userData = (userSnap.data() ?? {}) as Record<string, unknown>;
    const walletRaw = (userData.tokenWallet && typeof userData.tokenWallet === 'object')
      ? (userData.tokenWallet as Record<string, unknown>)
      : {};

    const entitlement = resolvePremiumEntitlement(userData, authToken);
    const { tokenCost, premiumApplied } = computeClassifyTokenCost(
      getClassifyTokenCost(),
      entitlement.hasPremium,
    );

    const currentBalance = Number(walletRaw.balance ?? 50);
    const totalEarned = Number(walletRaw.totalEarned ?? 50);
    const totalSpent = Number(walletRaw.totalSpent ?? 0);
    const dailyConversionsUsed = Number(walletRaw.dailyConversionsUsed ?? 0);
    const lastConversionDate = walletRaw.lastConversionDate ?? null;

    if (reservationSnap.exists && normalizedRequestId) {
      const existing = reservationSnap.data() as Record<string, unknown>;
      const existingStatus = (existing.status as ReservationStatus | undefined) ?? 'reserved';
      const existingTokenCost = Number(existing.tokenCost ?? tokenCost);
      const existingPremiumApplied = existing.premiumApplied === true;
      const existingTxId = String(existing.reservationTransactionId ?? 'existing_reservation');

      if (existingStatus === 'reserved' || existingStatus === 'consumed') {
        return {
          wallet: {
            balance: currentBalance,
            totalEarned,
            totalSpent,
            lastUpdated: String(walletRaw.lastUpdated ?? new Date().toISOString()),
            dailyConversionsUsed,
            lastConversionDate,
          },
          transaction: {
            id: existingTxId,
            delta: -Math.abs(existingTokenCost),
            type: 'TokenTransactionType.spend',
            timestamp: String(existing.createdAtIso ?? new Date().toISOString()),
            description: 'Instant AI image classification (idempotent retry)',
            reference: `classifyImage:${imageHash.slice(0, 12)}:${region}:${lang}`,
            metadata: {
              source: 'classifyImage',
              tokenCost: existingTokenCost,
              premiumApplied: existingPremiumApplied,
              reusedReservation: true,
            },
          },
          tokenCost: existingTokenCost,
          premiumApplied: existingPremiumApplied,
          reservationId,
          status: existingStatus,
          reusedExistingReservation: true,
        };
      }

      if (existingStatus === 'refunded') {
        throw new functions.https.HttpsError(
          'failed-precondition',
          'Request already finalized with refunded reservation. Use a new requestId.',
        );
      }
    }

    if (!Number.isFinite(currentBalance) || currentBalance < tokenCost) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        `Insufficient tokens for classification. Need ${tokenCost}, have ${Number.isFinite(currentBalance) ? currentBalance : 0}.`,
      );
    }

    const nowIso = new Date().toISOString();
    const txId = db.collection('_tmp').doc().id;

    const nextWallet: ServerTokenWallet = {
      balance: currentBalance - tokenCost,
      totalEarned,
      totalSpent: totalSpent + tokenCost,
      lastUpdated: nowIso,
      dailyConversionsUsed,
      lastConversionDate,
    };

    const transaction: ServerTokenTransaction = {
      id: txId,
      delta: -tokenCost,
      type: 'TokenTransactionType.spend',
      timestamp: nowIso,
      description: 'Instant AI image classification',
      reference: `classifyImage:${imageHash.slice(0, 12)}:${region}:${lang}`,
      metadata: {
        source: 'classifyImage',
        tokenCost,
        premiumApplied,
        entitlementSource: entitlement.source,
        region,
        lang,
        reservationId,
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

    tx.set(reservationRef, {
      uid,
      requestId: normalizedRequestId,
      imageHashPrefix: imageHash.slice(0, 16),
      region,
      lang,
      tokenCost,
      premiumApplied,
      entitlementSource: entitlement.source,
      status: 'reserved',
      reservationTransactionId: txId,
      createdAtIso: nowIso,
      updatedAtIso: nowIso,
      consumedAtIso: null,
      refundedAtIso: null,
      refundTransactionId: null,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });

    return {
      wallet: nextWallet,
      transaction,
      tokenCost,
      premiumApplied,
      reservationId,
      status: 'reserved',
      reusedExistingReservation: false,
    };
  });
}

async function markReservationConsumed(params: {
  reservationId: string;
  provider: string;
  model: string;
}): Promise<void> {
  const { reservationId, provider, model } = params;
  const db = admin.firestore();
  const reservationRef = db.collection('classify_token_reservations').doc(reservationId);

  await db.runTransaction(async (tx) => {
    const reservationSnap = await tx.get(reservationRef);
    if (!reservationSnap.exists) {
      functions.logger.warn('markReservationConsumed: reservation missing', { reservationId });
      return;
    }

    const reservationData = reservationSnap.data() as Record<string, unknown>;
    const status = (reservationData.status as ReservationStatus | undefined) ?? 'reserved';
    if (status === 'consumed') {
      return;
    }
    if (status === 'refunded') {
      throw new functions.https.HttpsError(
        'failed-precondition',
        'Cannot consume refunded classification reservation.',
      );
    }

    const nowIso = new Date().toISOString();
    tx.update(reservationRef, {
      status: 'consumed',
      consumedAtIso: nowIso,
      updatedAtIso: nowIso,
      provider,
      model,
      updatedAt: FieldValue.serverTimestamp(),
    });
  });
}

async function refundReservedClassificationTokens(params: {
  uid: string;
  tokenCost: number;
  reason: string;
  reservationTransactionId: string;
  reservationId: string;
  imageHash: string;
}): Promise<void> {
  const { uid, tokenCost, reason, reservationTransactionId, reservationId, imageHash } = params;
  const db = admin.firestore();
  const userRef = db.collection('users').doc(uid);
  const reservationRef = db.collection('classify_token_reservations').doc(reservationId);

  await db.runTransaction(async (tx) => {
    const [userSnap, reservationSnap] = await Promise.all([
      tx.get(userRef),
      tx.get(reservationRef),
    ]);

    if (!userSnap.exists) {
      functions.logger.warn('refundReservedClassificationTokens: user profile missing', { uid, reservationId });
      return;
    }

    if (reservationSnap.exists) {
      const reservationData = reservationSnap.data() as Record<string, unknown>;
      const reservationStatus = (reservationData.status as ReservationStatus | undefined) ?? 'reserved';
      if (reservationStatus === 'refunded') {
        return;
      }
      if (reservationStatus === 'consumed') {
        functions.logger.warn('refundReservedClassificationTokens: consume already finalized; skipping refund', {
          uid,
          reservationId,
        });
        return;
      }
    }

    const userData = (userSnap.data() ?? {}) as Record<string, unknown>;
    const walletRaw = (userData.tokenWallet && typeof userData.tokenWallet === 'object')
      ? (userData.tokenWallet as Record<string, unknown>)
      : {};

    const nowIso = new Date().toISOString();
    const balance = Number(walletRaw.balance ?? 0);
    const totalEarned = Number(walletRaw.totalEarned ?? 0);
    const totalSpent = Number(walletRaw.totalSpent ?? 0);
    const dailyConversionsUsed = Number(walletRaw.dailyConversionsUsed ?? 0);
    const lastConversionDate = walletRaw.lastConversionDate ?? null;

    const refundTx: ServerTokenTransaction = {
      id: db.collection('_tmp').doc().id,
      delta: tokenCost,
      type: 'TokenTransactionType.refund',
      timestamp: nowIso,
      description: reason,
      reference: `refund:${reservationTransactionId}`,
      metadata: {
        source: 'classifyImage',
        reservationTransactionId,
        reservationId,
        imageHashPrefix: imageHash.slice(0, 12),
      },
    };

    const currentTransactions = Array.isArray(userData.tokenTransactions)
      ? userData.tokenTransactions as unknown[]
      : [];
    const updatedTransactions = [refundTx, ...currentTransactions].slice(0, 200);

    tx.update(userRef, {
      tokenWallet: {
        balance: balance + tokenCost,
        totalEarned,
        totalSpent: Math.max(0, totalSpent - tokenCost),
        lastUpdated: nowIso,
        dailyConversionsUsed,
        lastConversionDate,
      },
      tokenTransactions: updatedTransactions,
      lastActive: nowIso,
    });

    tx.set(reservationRef, {
      status: 'refunded',
      refundedAtIso: nowIso,
      updatedAtIso: nowIso,
      refundTransactionId: refundTx.id,
      refundReason: reason,
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
  });
}

// ---------------------------------------------------------------------------
// Model names (kept consistent with constants.dart defaults)
// ---------------------------------------------------------------------------
const OPENAI_VISION_MODEL = process.env.OPENAI_VISION_MODEL ?? 'gpt-4.1-nano';
const GEMINI_VISION_MODEL = process.env.GEMINI_VISION_MODEL ?? 'gemini-2.0-flash';

// Rough cost estimates (USD per 1K tokens) for telemetry — not for billing.
const COST_PER_1K_INPUT: Record<string, number> = {
  'gpt-4.1-nano': 0.000_1,
  'gpt-4o-mini': 0.000_15,
  'gemini-2.0-flash': 0.000_075,
};
const COST_PER_1K_OUTPUT: Record<string, number> = {
  'gpt-4.1-nano': 0.000_4,
  'gpt-4o-mini': 0.000_6,
  'gemini-2.0-flash': 0.0003,
};

function estimateCostUsd(
  model: string,
  inputTokens: number | null,
  outputTokens: number | null,
): number | null {
  if (inputTokens == null && outputTokens == null) return null;
  const inCost = ((inputTokens ?? 0) / 1000) * (COST_PER_1K_INPUT[model] ?? 0);
  const outCost = ((outputTokens ?? 0) / 1000) * (COST_PER_1K_OUTPUT[model] ?? 0);
  return Math.round((inCost + outCost) * 1_000_000) / 1_000_000; // 6 decimals
}

// ---------------------------------------------------------------------------
// Classification prompt (server-side copy of ai_service.dart's prompt)
// ---------------------------------------------------------------------------
const buildClassificationPrompt = (region: string, lang: string): string => `
You are an expert in international waste classification, recycling, and proper disposal practices.
You are familiar with global and local waste management rules (including ${region}), brand-specific packaging, and recycling codes.
Your goal is to provide accurate, actionable, and safe waste sorting guidance based on the latest environmental standards.

Analyze the provided waste item and return a comprehensive JSON object. Language for descriptions: ${lang}.

Return ONLY a valid JSON object (no markdown, no explanation outside JSON) with these fields:
itemName, category (one of: Wet Waste, Dry Waste, Hazardous Waste, Medical Waste, Non-Waste),
subcategory, materialType, recyclingCode, explanation, disposalMethod,
disposalInstructions (object with: primaryMethod, steps (array), timeframe, location, warnings (array), tips (array), recyclingInfo, estimatedTime, hasUrgentTimeframe (boolean)),
region, visualFeatures (array), isRecyclable, isCompostable, requiresSpecialDisposal, isSingleUse,
colorCode, riskLevel, requiredPPE (array), brand, product, confidence (0.0-1.0), clarificationNeeded,
alternatives (array of {category, subcategory, confidence, reason}), suggestedAction, hasUrgentTimeframe,
instructionsLang, environmentalImpact, recyclability, hazardLevel (1-5), co2Impact, decompositionTime,
properEquipment (array), materials (array), subCategory, commonUses (array), alternativeOptions (array),
localRegulations (object), waterPollutionLevel (1-5), soilContaminationRisk (1-5),
biodegradabilityDays, recyclingEfficiency (0-100), bbmpComplianceStatus, localGuidelinesVersion,
generatesMicroplastics (boolean), humanToxicityLevel (1-5), wildlifeImpactSeverity (1-5),
resourceScarcity, pointsAwarded (null — calculated dynamically by the client).

Set pointsAwarded to null always. Return ONLY the JSON object.
`;

// ---------------------------------------------------------------------------
// OpenAI Vision call
// ---------------------------------------------------------------------------
async function callOpenAiVision(
  imageBase64: string,
  mimeType: string,
  region: string,
  lang: string,
): Promise<{ result: ClassificationResult; inputTokens: number | null; outputTokens: number | null }> {
  const apiKey = getOpenAiApiKey();
  if (!apiKey) {
    throw new functions.https.HttpsError('failed-precondition', 'OpenAI API key not configured.');
  }

  const prompt = buildClassificationPrompt(region, lang);

  const response = await axios.post(
    'https://api.openai.com/v1/chat/completions',
    {
      model: OPENAI_VISION_MODEL,
      messages: [
        {
          role: 'system',
          content: prompt,
        },
        {
          role: 'user',
          content: [
            { type: 'text', text: 'Classify this waste item and return the JSON object.' },
            {
              type: 'image_url',
              image_url: { url: `data:${mimeType};base64,${imageBase64}` },
            },
          ],
        },
      ],
      max_tokens: 2000,
      temperature: 0.1,
    },
    {
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${apiKey}`,
      },
      timeout: 30_000,
    },
  );

  const usage = response.data?.usage;
  const rawContent: string = response.data?.choices?.[0]?.message?.content ?? '';

  // Strip potential markdown code fences before parsing
  const jsonText = rawContent
    .replace(/^```json\s*/i, '')
    .replace(/^```\s*/i, '')
    .replace(/```\s*$/i, '')
    .trim();

  let parsed: ClassificationResult;
  try {
    parsed = JSON.parse(jsonText);
  } catch {
    throw new functions.https.HttpsError(
      'internal',
      `OpenAI returned non-JSON response: ${rawContent.slice(0, 200)}`,
    );
  }

  return {
    result: {
      ...parsed,
      modelSource: `openai-${OPENAI_VISION_MODEL}`,
      modelVersion: OPENAI_VISION_MODEL,
    },
    inputTokens: usage?.prompt_tokens ?? null,
    outputTokens: usage?.completion_tokens ?? null,
  };
}

// ---------------------------------------------------------------------------
// Gemini Vision call (fallback)
// ---------------------------------------------------------------------------
async function callGeminiVision(
  imageBase64: string,
  mimeType: string,
  region: string,
  lang: string,
): Promise<{ result: ClassificationResult; inputTokens: number | null; outputTokens: number | null }> {
  const apiKey = getGeminiApiKey();
  if (!apiKey) {
    throw new functions.https.HttpsError('failed-precondition', 'Gemini API key not configured.');
  }

  const prompt = buildClassificationPrompt(region, lang);
  const baseUrl = 'https://generativelanguage.googleapis.com/v1beta';

  const response = await axios.post(
    `${baseUrl}/models/${GEMINI_VISION_MODEL}:generateContent`,
    {
      contents: [
        {
          parts: [
            { text: `${prompt}\n\nClassify this waste item and return the JSON object.` },
            {
              inline_data: {
                mime_type: mimeType,
                data: imageBase64,
              },
            },
          ],
        },
      ],
      generationConfig: {
        temperature: 0.1,
        maxOutputTokens: 2000,
      },
    },
    {
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': apiKey,
      },
      timeout: 30_000,
    },
  );

  const usage = response.data?.usageMetadata;
  const rawContent: string =
    response.data?.candidates?.[0]?.content?.parts?.[0]?.text ?? '';

  const jsonText = rawContent
    .replace(/^```json\s*/i, '')
    .replace(/^```\s*/i, '')
    .replace(/```\s*$/i, '')
    .trim();

  let parsed: ClassificationResult;
  try {
    parsed = JSON.parse(jsonText);
  } catch {
    throw new functions.https.HttpsError(
      'internal',
      `Gemini returned non-JSON response: ${rawContent.slice(0, 200)}`,
    );
  }

  return {
    result: {
      ...parsed,
      modelSource: `gemini-${GEMINI_VISION_MODEL}`,
      modelVersion: GEMINI_VISION_MODEL,
    },
    inputTokens: usage?.promptTokenCount ?? null,
    outputTokens: usage?.candidatesTokenCount ?? null,
  };
}

// ---------------------------------------------------------------------------
// Cost telemetry writer (fire-and-forget, non-blocking for caller)
// ---------------------------------------------------------------------------
async function writeCostEvent(event: AiCostEvent): Promise<void> {
  try {
    const db = admin.firestore();
    await db.collection('ai_cost_events').add(event);
  } catch (err) {
    // Cost events are non-critical — log but don't surface to caller.
    functions.logger.warn('Failed to write ai_cost_event', { error: String(err) });
  }
}

// ---------------------------------------------------------------------------
// Exported callable function
// ---------------------------------------------------------------------------

/**
 * classifyImage — Firebase HTTPS Callable
 *
 * Accepts a base64 image from an authenticated Flutter client,
 * classifies it via OpenAI Vision (primary) or Gemini Flash (fallback),
 * caches the result in Firestore, and returns the classification JSON.
 *
 * The caller should pass this as the `rawResponseMap` of an AiProviderResponse
 * so that AiService._processAiResponseData can parse it into WasteClassification.
 */
export const classifyImage = functions
  .region('asia-south1')
  .https.onCall(async (data: ClassifyImageRequest, context) => {

  // ------------------------------------------------------------------
  // 1. Auth — hard requirement; no unauthenticated access
  // ------------------------------------------------------------------
  if (!context.auth?.uid) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Authentication required to classify images.',
    );
  }
  const uid = context.auth.uid;

  // ------------------------------------------------------------------
  // 2. App Check — fail-closed when env var is set
  // ------------------------------------------------------------------
  if (shouldEnforceCallableAppCheck() && !context.app) {
    throw new functions.https.HttpsError(
      'failed-precondition',
      'App Check token required for classifyImage.',
    );
  }

  // ------------------------------------------------------------------
  // 3. Input validation
  // ------------------------------------------------------------------
  const { imageBase64, mimeType, clientHash, region, lang, requestId } = data;

  if (!imageBase64 || typeof imageBase64 !== 'string' || imageBase64.length === 0) {
    throw new functions.https.HttpsError('invalid-argument', 'imageBase64 is required.');
  }

  const allowedMimeTypes: string[] = ['image/jpeg', 'image/png', 'image/webp'];
  if (!mimeType || !allowedMimeTypes.includes(mimeType)) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      `mimeType must be one of: ${allowedMimeTypes.join(', ')}`,
    );
  }

  // Base64 character count maps to ~0.75x bytes; 4 MB * (4/3) ≈ 5_592_406 chars.
  const MAX_BASE64_CHARS = Math.ceil(4 * 1024 * 1024 * (4 / 3));
  if (imageBase64.length > MAX_BASE64_CHARS) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Image exceeds 4 MB limit. Compress before sending.',
    );
  }

  const analysisRegion = (typeof region === 'string' && region.trim().length > 0)
    ? region.trim()
    : 'Bangalore, IN';
  const analysisLang = (typeof lang === 'string' && lang.trim().length > 0)
    ? lang.trim()
    : 'en';

  // ------------------------------------------------------------------
  // 4. Server-side hash (authoritative cache key)
  //    We hash the raw base64 string itself — deterministic, cheap,
  //    and avoids decoding the buffer just to re-hash the bytes.
  //    NOTE: Never log imageBase64 or imageBytes.
  // ------------------------------------------------------------------
  const serverHash = createHash('sha256').update(imageBase64).digest('hex');

  functions.logger.info('classifyImage: request received', {
    uid,
    serverHash: serverHash.slice(0, 16) + '…', // partial hash only in logs
    clientHashMatch: clientHash
      ? createHash('sha256').update(clientHash).digest('hex').slice(0, 8)
      : null,
    mimeType,
    base64Length: imageBase64.length,
  });

  // ------------------------------------------------------------------
  // 5. Cache check — by server-side hash + region + lang
  // ------------------------------------------------------------------
  const db = admin.firestore();
  const cacheDocId = `${serverHash}::${analysisRegion}::${analysisLang}`;
  const cacheRef = db.collection('classifications').doc(cacheDocId);

  const cachedSnap = await cacheRef.get();
  const nowEpoch = Math.floor(Date.now() / 1000);
  const cacheTtl = getCacheTtlSeconds();

  if (cachedSnap.exists) {
    const cached = cachedSnap.data() ?? {};
    const cachedAt: number = Number(cached.cachedAtEpoch ?? 0);
    const isExpired = nowEpoch - cachedAt > cacheTtl;

    if (!isExpired) {
      functions.logger.info('classifyImage: cache hit', {
        uid,
        serverHash: serverHash.slice(0, 16) + '…',
      });

      // Record a cache-hit cost event so we can measure savings.
      void writeCostEvent({
        uid,
        timestamp: FieldValue.serverTimestamp(),
        provider: cached.provider ?? 'cache',
        model: cached.model ?? 'cache',
        inputTokens: null,
        outputTokens: null,
        estimatedCostUsd: 0,
        imageHash: serverHash,
        success: true,
        cacheHit: true,
      });

      // Return the cached result payload (strip internal storage fields).
      const { cachedAtEpoch: _1, provider: _2, model: _3, ...resultPayload } = cached;
      return { classification: resultPayload };
    }
  }

  // ------------------------------------------------------------------
  // 6. Rate limit — per UID, 10 req/min (configurable)
  // ------------------------------------------------------------------
  const rateLimitConfig = getClassifyRateLimitConfig();
  const rateLimitState = await enforceRateLimit({
    bucket: 'classifyImage',
    subject: `uid:${uid}`,
    maxRequests: Math.max(1, rateLimitConfig.maxRequests),
    windowSeconds: Math.max(1, rateLimitConfig.windowSeconds),
  });

  if (rateLimitState.retryAfterSeconds > 0) {
    throw new functions.https.HttpsError(
      'resource-exhausted',
      'Rate limit exceeded for classifyImage. Try again later.',
      { retryAfterSeconds: rateLimitState.retryAfterSeconds },
    );
  }

  // ------------------------------------------------------------------
  // 7. Token spend and entitlement enforcement (before paid provider calls)
  // ------------------------------------------------------------------
  let tokenReservation: TokenReservationResult | null = null;
  if (isTokenSpendEnforced()) {
    tokenReservation = await reserveClassificationTokens({
      uid,
      authToken: context.auth.token as Record<string, unknown> | undefined,
      imageHash: serverHash,
      region: analysisRegion,
      lang: analysisLang,
      requestId,
    });
  }

  // ------------------------------------------------------------------
  // 8. Primary provider: OpenAI Vision
  // ------------------------------------------------------------------
  let classificationResult: ClassificationResult | null = null;
  let usedProvider = 'openai';
  let usedModel = OPENAI_VISION_MODEL;
  let inputTokens: number | null = null;
  let outputTokens: number | null = null;
  let providerError: unknown = null;

  try {
    const openAiResult = await callOpenAiVision(
      imageBase64,
      mimeType,
      analysisRegion,
      analysisLang,
    );
    classificationResult = openAiResult.result;
    inputTokens = openAiResult.inputTokens;
    outputTokens = openAiResult.outputTokens;
    usedProvider = 'openai';
    usedModel = OPENAI_VISION_MODEL;
  } catch (err) {
    providerError = err;
    functions.logger.warn('classifyImage: OpenAI primary failed, trying Gemini fallback', {
      uid,
      error: err instanceof Error ? err.message : String(err),
    });
  }

  // ------------------------------------------------------------------
  // 8. Fallback provider: Gemini Flash
  // ------------------------------------------------------------------
  if (!classificationResult) {
    try {
      const geminiResult = await callGeminiVision(
        imageBase64,
        mimeType,
        analysisRegion,
        analysisLang,
      );
      classificationResult = geminiResult.result;
      inputTokens = geminiResult.inputTokens;
      outputTokens = geminiResult.outputTokens;
      usedProvider = 'gemini';
      usedModel = GEMINI_VISION_MODEL;
    } catch (fallbackErr) {
      functions.logger.error('classifyImage: both providers failed', {
        uid,
        openAiError: providerError instanceof Error ? providerError.message : String(providerError),
        geminiError: fallbackErr instanceof Error ? fallbackErr.message : String(fallbackErr),
      });

      if (tokenReservation) {
        try {
          await refundReservedClassificationTokens({
            uid,
            tokenCost: tokenReservation.tokenCost,
            reason: 'Classification failed — auto refund',
            reservationTransactionId: tokenReservation.transaction.id,
            reservationId: tokenReservation.reservationId,
            imageHash: serverHash,
          });
        } catch (refundErr) {
          functions.logger.error('classifyImage: token refund failed after provider failure', {
            uid,
            reservationTransactionId: tokenReservation.transaction.id,
            error: refundErr instanceof Error ? refundErr.message : String(refundErr),
          });
        }
      }

      // Record failure cost event
      void writeCostEvent({
        uid,
        timestamp: FieldValue.serverTimestamp(),
        provider: 'none',
        model: 'none',
        inputTokens: null,
        outputTokens: null,
        estimatedCostUsd: null,
        imageHash: serverHash,
        success: false,
        cacheHit: false,
      });

      throw new functions.https.HttpsError(
        'unavailable',
        'Classification service temporarily unavailable. Both AI providers failed. Please try again.',
      );
    }
  }

  // ------------------------------------------------------------------
  // 9. Finalize reservation state (consume on successful provider completion)
  // ------------------------------------------------------------------
  if (tokenReservation && tokenReservation.status === 'reserved') {
    await markReservationConsumed({
      reservationId: tokenReservation.reservationId,
      provider: usedProvider,
      model: usedModel,
    });
  }

  // ------------------------------------------------------------------
  // 10. Cost telemetry
  // ------------------------------------------------------------------
  const estimatedCostUsd = estimateCostUsd(usedModel, inputTokens, outputTokens);
  void writeCostEvent({
    uid,
    timestamp: FieldValue.serverTimestamp(),
    provider: usedProvider,
    model: usedModel,
    inputTokens,
    outputTokens,
    estimatedCostUsd,
    imageHash: serverHash,
    success: true,
    cacheHit: false,
  });

  // ------------------------------------------------------------------
  // 10. Cache result
  //     Image bytes are NEVER stored — only the hash and JSON result.
  // ------------------------------------------------------------------
  try {
    await cacheRef.set({
      ...classificationResult,
      cachedAtEpoch: nowEpoch,
      provider: usedProvider,
      model: usedModel,
      imageHash: serverHash,
      region: analysisRegion,
      lang: analysisLang,
      createdAt: FieldValue.serverTimestamp(),
    });
  } catch (cacheErr) {
    // Non-fatal — result was still computed; just won't be cached.
    functions.logger.warn('classifyImage: failed to write cache', {
      error: String(cacheErr),
    });
  }

  // ------------------------------------------------------------------
  // 11. Return result to client
  // ------------------------------------------------------------------
  functions.logger.info('classifyImage: success', {
    uid,
    provider: usedProvider,
    model: usedModel,
    serverHash: serverHash.slice(0, 16) + '…',
    tokenSpendEnforced: isTokenSpendEnforced(),
    tokenCost: tokenReservation?.tokenCost ?? 0,
    premiumApplied: tokenReservation?.premiumApplied ?? false,
    reservationId: tokenReservation?.reservationId ?? null,
    reservationStatus: tokenReservation?.status ?? null,
    reservationReused: tokenReservation?.reusedExistingReservation ?? false,
  });

  return {
    classification: classificationResult,
    meta: {
      provider: usedProvider,
      model: usedModel,
      serverImageHash: serverHash,
      cachedResult: false,
      remainingRequests: rateLimitState.remaining,
      tokenSpendEnforced: isTokenSpendEnforced(),
      tokensCharged: tokenReservation?.tokenCost ?? 0,
      premiumApplied: tokenReservation?.premiumApplied ?? false,
      tokenReservationId: tokenReservation?.reservationId ?? null,
      tokenReservationStatus: tokenReservation?.status ?? null,
      tokenReservationReused: tokenReservation?.reusedExistingReservation ?? false,
      tokenReservationTransactionId: tokenReservation?.transaction.id ?? null,
    },
  };
});
