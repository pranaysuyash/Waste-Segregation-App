import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { FieldValue } from 'firebase-admin/firestore';
import cors from 'cors';
import { getQuotaConfig } from './rate_limit_config';

export const asiaSouth1 = functions.region('asia-south1');

export const corsHandler = cors({ origin: true });

export const getBearerToken = (authHeader: string | undefined): string | null => {
  if (!authHeader) return null;
  if (!authHeader.startsWith('Bearer ')) return null;
  const token = authHeader.slice('Bearer '.length).trim();
  return token.length > 0 ? token : null;
};

export const parseBoolEnv = (value: string | undefined, fallback = false): boolean => {
  if (value == null) return fallback;
  const normalized = value.trim().toLowerCase();
  if (['true', '1', 'yes', 'on'].includes(normalized)) return true;
  if (['false', '0', 'no', 'off'].includes(normalized)) return false;
  return fallback;
};

export const isProductionRuntime = (): boolean => {
  if (process.env.FUNCTIONS_EMULATOR === 'true') return false;
  if (parseBoolEnv(process.env.HERMES_FORCE_PROD_GUARDRAILS, false)) return true;
  return Boolean(process.env.K_SERVICE) || process.env.NODE_ENV === 'production';
};

export const validateAppCheckProductionGuardrails = (): void => {
  if (!isProductionRuntime()) return;

  const violations: string[] = [];
  if (!parseBoolEnv(process.env.REQUIRE_APPCHECK_CALLABLE, false)) {
    violations.push('REQUIRE_APPCHECK_CALLABLE must be true in production.');
  }
  if (!parseBoolEnv(process.env.REQUIRE_APPCHECK_HTTP, false)) {
    violations.push('REQUIRE_APPCHECK_HTTP must be true in production.');
  }

  if (violations.length === 0) return;

  functions.logger.warn(
    `App Check production guardrail: ${violations.join(' ')} ` +
    'Set REQUIRE_APPCHECK_CALLABLE=true and REQUIRE_APPCHECK_HTTP=true ' +
    'as Cloud Functions runtime environment variables to enforce App Check. ' +
    'Functions will boot but App Check is not enforced.'
  );
};

export const getClientIp = (req: functions.Request): string => {
  const xfwd = req.headers['x-forwarded-for'];
  if (typeof xfwd === 'string' && xfwd.trim().length > 0) {
    return xfwd.split(',')[0].trim();
  }
  return req.ip || 'unknown';
};

export const shouldEnforceHttpAppCheck = (): boolean => {
  const requireAppCheck = parseBoolEnv(process.env.REQUIRE_APPCHECK_HTTP, false);
  if (!requireAppCheck) return false;
  if (process.env.FUNCTIONS_EMULATOR === 'true') {
    return parseBoolEnv(process.env.ENFORCE_APPCHECK_IN_EMULATOR, false);
  }
  return true;
};

export const shouldEnforceCallableAppCheck = (): boolean => {
  const requireAppCheck = parseBoolEnv(process.env.REQUIRE_APPCHECK_CALLABLE, false);
  if (!requireAppCheck) return false;
  if (process.env.FUNCTIONS_EMULATOR === 'true') {
    return parseBoolEnv(process.env.ENFORCE_APPCHECK_IN_EMULATOR, false);
  }
  return true;
};

export const getRateLimitConfig = () => {
  const cfg = getQuotaConfig();
  return {
    windowSeconds: cfg.disposal.windowSeconds,
    disposalMax: cfg.disposal.maxRequests,
    spendTokensMax: cfg.tokenSpend.maxRequests,
  };
};

export const enforceRateLimit = async ({
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

export const bumpOpsMetric = async (
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

export const verifyHttpAppCheck = async (req: functions.Request): Promise<boolean> => {
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
