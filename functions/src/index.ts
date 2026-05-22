import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { FieldValue } from 'firebase-admin/firestore';
import { OpenAI } from 'openai';
import { toFile } from 'openai/uploads';
import cors from 'cors';
import * as fs from 'fs';
import * as path from 'path';
import axios from 'axios';
import { getQuotaConfig, QUOTA_TIER_MULTIPLIERS, QuotaTier } from './rate_limit_config';

// Initialize Firebase Admin
admin.initializeApp();

// Configure region for better performance in Asia
const asiaSouth1 = functions.region('asia-south1');

export const getOpenAiApiKey = (): string | undefined => {
  return process.env.OPENAI_API_KEY
    || process.env.OPENAI_KEY;
};

// Initialize OpenAI (conditional)
let openai: OpenAI | null = null;
try {
  // Resolve the secret from the process environment only.
  const apiKey = getOpenAiApiKey();

  if (apiKey) {
    openai = new OpenAI({
      apiKey: apiKey,
    });
    functions.logger.info('OpenAI initialized successfully');
  } else {
    functions.logger.warn('OpenAI API key not configured - functions will use fallback responses');
  }
} catch (error) {
  functions.logger.warn('Failed to initialize OpenAI', { error });
}

// CORS configuration
const corsHandler = cors({ origin: true });

// Load disposal prompt template
const getDisposalPrompt = (): string => {
  try {
    const promptPath = path.join(__dirname, '../../prompts/disposal.txt');
    return fs.readFileSync(promptPath, 'utf8');
  } catch (error) {
    functions.logger.error('Error loading disposal prompt', { error });
    // Fallback prompt
    return `You are a waste management expert. Generate disposal instructions for the given material.
    
Input: {"material":"$MATERIAL","lang":"$LANG"}

Generate a JSON object with: steps (array), primaryMethod, timeframe, location, warnings (array), tips (array), recyclingInfo, estimatedTime, hasUrgentTimeframe (boolean).

Provide 4-6 specific, actionable steps for proper disposal.`;
  }
};

interface DisposalRequest {
  materialId: string;
  material: string;
  category?: string;
  subcategory?: string;
  lang?: string;
}

interface DisposalInstructions {
  steps: string[];
  primaryMethod: string;
  timeframe?: string;
  location?: string;
  warnings?: string[];
  tips?: string[];
  recyclingInfo?: string;
  estimatedTime?: string;
  hasUrgentTimeframe: boolean;
}

const getBearerToken = (authHeader: string | undefined): string | null => {
  if (!authHeader) return null;
  if (!authHeader.startsWith('Bearer ')) return null;
  const token = authHeader.slice('Bearer '.length).trim();
  return token.length > 0 ? token : null;
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

const parseBoolEnv = (value: string | undefined, fallback = false): boolean => {
  if (value == null) return fallback;
  const normalized = value.trim().toLowerCase();
  if (['true', '1', 'yes', 'on'].includes(normalized)) return true;
  if (['false', '0', 'no', 'off'].includes(normalized)) return false;
  return fallback;
};

const isProductionRuntime = (): boolean => {
  if (process.env.FUNCTIONS_EMULATOR === 'true') return false;
  if (parseBoolEnv(process.env.HERMES_FORCE_PROD_GUARDRAILS, false)) return true;
  return Boolean(process.env.K_SERVICE) || process.env.NODE_ENV === 'production';
};

const validateAppCheckProductionGuardrails = (): void => {
  if (!isProductionRuntime()) return;

  const violations: string[] = [];
  if (!parseBoolEnv(process.env.REQUIRE_APPCHECK_CALLABLE, false)) {
    violations.push('REQUIRE_APPCHECK_CALLABLE must be true in production.');
  }
  if (!parseBoolEnv(process.env.REQUIRE_APPCHECK_HTTP, false)) {
    violations.push('REQUIRE_APPCHECK_HTTP must be true in production.');
  }

  if (violations.length === 0) return;

  const message = `App Check production guardrail violation: ${violations.join(' ')}`;

  if (parseBoolEnv(process.env.ALLOW_INSECURE_FUNCTIONS_BOOT, false)) {
    functions.logger.error(`${message} Boot allowed only because ALLOW_INSECURE_FUNCTIONS_BOOT=true.`);
    return;
  }

  throw new Error(message);
};

validateAppCheckProductionGuardrails();

export const __testables = {
  isProductionRuntime,
  validateAppCheckProductionGuardrails,
};

const getClientIp = (req: functions.Request): string => {
  const xfwd = req.headers['x-forwarded-for'];
  if (typeof xfwd === 'string' && xfwd.trim().length > 0) {
    return xfwd.split(',')[0].trim();
  }
  return req.ip || 'unknown';
};

const shouldEnforceHttpAppCheck = (): boolean => {
  const requireAppCheck = parseBoolEnv(process.env.REQUIRE_APPCHECK_HTTP, false);
  if (!requireAppCheck) return false;
  if (process.env.FUNCTIONS_EMULATOR === 'true') {
    return parseBoolEnv(process.env.ENFORCE_APPCHECK_IN_EMULATOR, false);
  }
  return true;
};

const shouldEnforceCallableAppCheck = (): boolean => {
  const requireAppCheck = parseBoolEnv(process.env.REQUIRE_APPCHECK_CALLABLE, false);
  if (!requireAppCheck) return false;
  if (process.env.FUNCTIONS_EMULATOR === 'true') {
    return parseBoolEnv(process.env.ENFORCE_APPCHECK_IN_EMULATOR, false);
  }
  return true;
};

/**
 * getRateLimitConfig — thin adapter kept for internal call-site compatibility.
 * All canonical values now live in rate_limit_config.ts via getQuotaConfig().
 */
const getRateLimitConfig = () => {
  const cfg = getQuotaConfig();
  return {
    windowSeconds: cfg.disposal.windowSeconds,
    disposalMax: cfg.disposal.maxRequests,
    spendTokensMax: cfg.tokenSpend.maxRequests,
  };
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
  const safeSubject = subject.replace(/[^a-zA-Z0-9_:\-\.]/g, '_').slice(0, 120);
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

const bumpOpsMetric = async (
  metricName: string,
  tags: Record<string, unknown> = {},
): Promise<void> => {
  try {
    const db = admin.firestore();
    const day = new Date().toISOString().slice(0, 10);
    const docRef = db.collection('ops_metrics').doc(day);
    const sanitizedTags = Object.fromEntries(
      Object.entries(tags).filter(([, value]) =>
        ['string', 'number', 'boolean'].includes(typeof value) || value === null,
      ),
    );

    await docRef.set(
      {
        date: day,
        updatedAt: FieldValue.serverTimestamp(),
        [`counters.${metricName}`]: FieldValue.increment(1),
        [`lastEvent.${metricName}`]: {
          atIso: new Date().toISOString(),
          ...sanitizedTags,
        },
      },
      { merge: true },
    );
  } catch (error) {
    functions.logger.warn('Failed to bump ops metric', { metricName, error });
  }
};

const verifyHttpAppCheck = async (req: functions.Request): Promise<boolean> => {
  const tokenHeader = req.headers['x-firebase-appcheck'];
  const token = Array.isArray(tokenHeader) ? tokenHeader[0] : tokenHeader;
  if (!token || token.trim().length === 0) return false;
  try {
    await admin.appCheck().verifyToken(token.trim());
    return true;
  } catch {
    return false;
  }
};

export const generateDisposal = asiaSouth1.https.onRequest(async (req, res) => {
  return corsHandler(req, res, async () => {
    try {
      if (shouldEnforceHttpAppCheck()) {
        const appCheckValid = await verifyHttpAppCheck(req);
        if (!appCheckValid) {
          res.status(401).json({
            error: 'Unauthorized: valid App Check token required',
            hint: 'Attach x-firebase-appcheck header from a Firebase App Check enabled client.',
          });
          return;
        }
      }

      const requireAuth = (process.env.DISPOSAL_API_REQUIRE_AUTH ?? 'true') === 'true';
      const allowAnonymous = process.env.ALLOW_ANONYMOUS_DISPOSAL === 'true';
      if (requireAuth && !allowAnonymous) {
        const token = getBearerToken(req.headers.authorization);
        if (!token) {
          res.status(401).json({
            error: 'Unauthorized: Bearer token required',
            hint: 'Set ALLOW_ANONYMOUS_DISPOSAL=true only for controlled environments.'
          });
          return;
        }
        try {
          await admin.auth().verifyIdToken(token);
        } catch {
          res.status(401).json({ error: 'Unauthorized: invalid token' });
          return;
        }
      }

      // Validate request method
      if (req.method !== 'POST') {
        res.status(405).json({ error: 'Method not allowed' });
        return;
      }

      // Parse request body
      const { materialId, material, category, subcategory, lang = 'en' }: DisposalRequest = req.body;

      if (!materialId || !material) {
        res.status(400).json({ error: 'Missing required fields: materialId, material' });
        return;
      }

      const rateLimitConfig = getRateLimitConfig();
      const rateLimitState = await enforceRateLimit({
        bucket: 'generateDisposal',
        subject: `ip:${getClientIp(req)}`,
        maxRequests: Math.max(1, rateLimitConfig.disposalMax),
        windowSeconds: Math.max(1, rateLimitConfig.windowSeconds),
      });
      if (rateLimitState.retryAfterSeconds > 0) {
        res.setHeader('Retry-After', String(rateLimitState.retryAfterSeconds));
        res.status(429).json({
          error: 'Rate limit exceeded',
          retryAfterSeconds: rateLimitState.retryAfterSeconds,
        });
        return;
      }

      // Check if instructions already exist in cache
      const db = admin.firestore();
      const cacheRef = db.collection('disposal_instructions').doc(materialId);
      const cachedDoc = await cacheRef.get();

      if (cachedDoc.exists) {
        functions.logger.info('Returning cached disposal instructions', { materialId });
        res.json(cachedDoc.data());
        return;
      }

      // Prepare material description
      let materialDescription = material;
      if (category) materialDescription += ` (${category}`;
      if (subcategory) materialDescription += ` - ${subcategory}`;
      if (category) materialDescription += ')';

      // Load and prepare prompt
      const promptTemplate = getDisposalPrompt();
      const prompt = promptTemplate
        .replace('$MATERIAL', materialDescription)
        .replace('$LANG', lang);

      functions.logger.info('Generating disposal instructions', { materialDescription });

      // Check if OpenAI is available
      if (!openai) {
        throw new Error('OpenAI not configured - using fallback');
      }

      // Call OpenAI API
      // DISPOSAL_MODEL env var allows per-deployment override without redeploying.
      // Default: gpt-4.1-mini — capable for structured disposal instructions and
      // cost-efficient compared to gpt-4.  The function-calling API used below
      // is fully compatible with gpt-4.1-mini.
      const disposalModel = process.env.DISPOSAL_MODEL ?? 'gpt-4.1-mini';
      const completion = await openai.chat.completions.create({
        model: disposalModel,
        messages: [
          {
            role: 'system',
            content: prompt
          },
          {
            role: 'user',
            content: JSON.stringify({ material: materialDescription, lang })
          }
        ],
        functions: [
          {
            name: 'generate_disposal_instructions',
            description: 'Generate structured disposal instructions for waste materials',
            parameters: {
              type: 'object',
              properties: {
                steps: {
                  type: 'array',
                  items: { type: 'string' },
                  description: 'Array of 4-6 specific disposal steps'
                },
                primaryMethod: {
                  type: 'string',
                  description: 'Brief summary of main disposal method'
                },
                timeframe: {
                  type: 'string',
                  description: 'When to dispose (e.g., Immediately, Within 24 hours)'
                },
                location: {
                  type: 'string',
                  description: 'Where to dispose (bin type, facility)'
                },
                warnings: {
                  type: 'array',
                  items: { type: 'string' },
                  description: 'Safety or environmental warnings'
                },
                tips: {
                  type: 'array',
                  items: { type: 'string' },
                  description: 'Helpful disposal tips'
                },
                recyclingInfo: {
                  type: 'string',
                  description: 'Additional recycling information'
                },
                estimatedTime: {
                  type: 'string',
                  description: 'Time needed for disposal process'
                },
                hasUrgentTimeframe: {
                  type: 'boolean',
                  description: 'True for hazardous/medical waste requiring immediate disposal'
                }
              },
              required: ['steps', 'primaryMethod', 'hasUrgentTimeframe']
            }
          }
        ],
        function_call: { name: 'generate_disposal_instructions' },
        temperature: 0.3,
        max_tokens: 1000
      });

      // Parse the function call response
      const functionCall = completion.choices[0]?.message?.function_call;
      if (!functionCall || !functionCall.arguments) {
        throw new Error('No function call response from OpenAI');
      }

      const disposalInstructions: DisposalInstructions = JSON.parse(functionCall.arguments);

      // Validate the response
      if (!disposalInstructions.steps || !Array.isArray(disposalInstructions.steps) || disposalInstructions.steps.length < 3) {
        throw new Error('Invalid disposal instructions format');
      }

      // Add metadata
      const result = {
        ...disposalInstructions,
        materialId,
        material: materialDescription,
        language: lang,
        generatedAt: FieldValue.serverTimestamp(),
        modelUsed: disposalModel,
        version: '1.0'
      };

      // Cache the result
      await cacheRef.set(result);

      functions.logger.info('Generated and cached disposal instructions', { materialId });
      res.json(result);

    } catch (error: any) {
      functions.logger.error('Error generating disposal instructions', { error });

      const isRetryableError = (
        error.code === 'rate_limit_exceeded' ||
        error.status === 429 ||
        error.status === 503 ||
        error.status === 502 ||
        error.status === 504 ||
        (error.message && error.message.includes('timeout'))
      );

      if (isRetryableError) {
        functions.logger.info('Retryable error detected, returning 503 with retry-after');
        res.status(503).json({ 
          error: 'Service temporarily unavailable',
          retryAfter: 30,
          fallback: true,
          code: 'retryable_error'
        });
        return;
      }
      
      // Return fallback instructions for non-retryable errors
      const fallbackInstructions = {
        steps: [
          'Identify the correct waste category for this item',
          'Clean the item if required (remove food residue, rinse if needed)',
          'Place in the appropriate disposal bin or take to designated facility',
          'Follow local waste management guidelines for collection'
        ],
        primaryMethod: 'Follow local waste guidelines',
        timeframe: 'As per local collection schedule',
        location: 'Appropriate waste bin or facility',
        warnings: ['Check local regulations for specific requirements'],
        tips: ['When in doubt, contact local waste management authorities'],
        hasUrgentTimeframe: false,
        materialId: req.body.materialId,
        material: req.body.material,
        language: req.body.lang || 'en',
        generatedAt: FieldValue.serverTimestamp(),
        modelUsed: 'fallback',
        version: '1.0',
        error: 'AI generation failed, using fallback instructions'
      };

      res.status(200).json(fallbackInstructions);
    }
  });
});

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
    // SPEND_PREMIUM_DISCOUNT_PERCENT (default 40) and is always computed on
    // server-authoritative entitlement.
    // -------------------------------------------------------------------------
    const INSTANT_COST_FREE = 5;
    const premiumDiscountPercentRaw = Number(
      process.env.SPEND_PREMIUM_DISCOUNT_PERCENT ?? 40,
    );
    const premiumDiscountPercent = Number.isFinite(premiumDiscountPercentRaw)
      ? Math.max(0, Math.min(100, premiumDiscountPercentRaw))
      : 40;
    const INSTANT_COST_PREMIUM = Math.max(
      1,
      Math.ceil(INSTANT_COST_FREE * (1 - premiumDiscountPercent / 100)),
    );
    const BATCH_COST = 1;

    let authorizedAmount = clientAmount; // default: trust client if no opType known
    let serverComputedMinimum: number | null = null;

    if (operationType !== null) {
      const serverMin: number = (operationType === 'batch')
        ? BATCH_COST
        : (tier === 'free' ? INSTANT_COST_FREE : INSTANT_COST_PREMIUM);
      serverComputedMinimum = serverMin;

      if (clientAmount < serverMin) {
        // Client is claiming a spend lower than what the server authorises for
        // this tier+operation — this is the fraud vector the fix is designed to
        // block (e.g. a free-tier user sending amount=3 pretending to be premium).
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
        // Deduct only the canonical server cost, not the over-specified client amount.
        authorizedAmount = serverMin;
      } else {
        authorizedAmount = serverMin;
      }
    }
    // -------------------------------------------------------------------------

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
  .schedule('*/10 * * * *') // Run every 10 minutes
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
      processingTime: 0, // Batch processing time is handled differently
    };
  } catch (error) {
    functions.logger.error('Error parsing classification result:', error);
    
    // Return fallback classification
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
export { classifyImage } from './classify_image';
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
