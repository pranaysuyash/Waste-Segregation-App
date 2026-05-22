import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';
import { FieldValue, Timestamp } from 'firebase-admin/firestore';

const asiaSouth1 = functions.region('asia-south1');

const parseBoolEnv = (value: string | undefined, fallback = false): boolean => {
  if (value == null) return fallback;
  const normalized = value.trim().toLowerCase();
  if (['true', '1', 'yes', 'on'].includes(normalized)) return true;
  if (['false', '0', 'no', 'off'].includes(normalized)) return false;
  return fallback;
};

const getNested = (obj: unknown, path: string[]): unknown => {
  let current: unknown = obj;
  for (const key of path) {
    if (!current || typeof current !== 'object') return undefined;
    current = (current as Record<string, unknown>)[key];
  }
  return current;
};

const toBoolean = (value: unknown): boolean => value === true;

const getBillingEntitlement = (docData: Record<string, unknown> | undefined): boolean => {
  if (!docData) return false;
  return toBoolean(getNested(docData, ['billing', 'entitlements', 'pro_subscription']));
};

const timestampToIso = (value: unknown): string | null => {
  if (value instanceof Timestamp) return value.toDate().toISOString();
  if (value instanceof Date) return value.toISOString();
  if (typeof value === 'string') {
    const parsed = new Date(value);
    if (!Number.isNaN(parsed.getTime())) return parsed.toISOString();
  }
  return null;
};

/**
 * Keeps Firebase Auth custom claims aligned with canonical billing entitlement.
 * Authority remains Firestore users/{uid}.billing.entitlements.pro_subscription.
 */
export const syncEntitlementClaims = asiaSouth1.firestore
  .document('users/{uid}')
  .onWrite(async (change, context) => {
    const uid = context.params.uid as string;
    const afterData = change.after.exists
      ? (change.after.data() as Record<string, unknown>)
      : undefined;
    const beforeData = change.before.exists
      ? (change.before.data() as Record<string, unknown>)
      : undefined;

    if (!afterData) {
      return null;
    }

    const beforeEntitlement = getBillingEntitlement(beforeData);
    const afterEntitlement = getBillingEntitlement(afterData);

    if (beforeEntitlement === afterEntitlement) {
      return null;
    }

    try {
      const userRecord = await admin.auth().getUser(uid);
      const existingClaims = (userRecord.customClaims ?? {}) as Record<string, unknown>;

      const mergedClaims: Record<string, unknown> = {
        ...existingClaims,
        premium: afterEntitlement,
        pro: afterEntitlement,
        pro_subscription: afterEntitlement,
        entitlement_source: 'billing_entitlements',
        entitlement_synced_at: new Date().toISOString(),
      };

      await admin.auth().setCustomUserClaims(uid, mergedClaims);

      await change.after.ref.set({
        billing: {
          claimsSync: {
            lastSyncedAt: FieldValue.serverTimestamp(),
            lastSyncedIso: new Date().toISOString(),
            source: 'billing_entitlements',
            targetPremium: afterEntitlement,
          },
        },
      }, { merge: true });

      functions.logger.info('syncEntitlementClaims: updated custom claims', {
        uid,
        beforeEntitlement,
        afterEntitlement,
      });
    } catch (error) {
      functions.logger.error('syncEntitlementClaims: failed to sync claims', {
        uid,
        beforeEntitlement,
        afterEntitlement,
        error: error instanceof Error ? error.message : String(error),
      });
    }

    return null;
  });

/**
 * Reconciles stale classification token reservations and logs operational alerts.
 * It does not auto-refund because reservation->refund must remain explicit to avoid double-credit races.
 */
export const reconcileStaleClassifyReservations = asiaSouth1.pubsub
  .schedule('every 15 minutes')
  .timeZone('UTC')
  .onRun(async () => {
    const db = admin.firestore();
    const staleMinutes = Number(process.env.CLASSIFY_RESERVATION_STALE_MINUTES ?? '30');
    const staleThresholdMs = Date.now() - Math.max(1, staleMinutes) * 60_000;

    const reservedSnap = await db
      .collection('classify_token_reservations')
      .where('status', '==', 'reserved')
      .limit(1000)
      .get();

    const staleReservations: Array<{
      reservationId: string;
      uid: string;
      tokenCost: number;
      reservedAtIso: string | null;
      ageMinutes: number;
      requestId: string | null;
    }> = [];

    reservedSnap.docs.forEach((doc) => {
      const data = doc.data();
      const reservedAtIso = timestampToIso(data.reservedAt) ?? timestampToIso(data.reservedAtIso);
      if (!reservedAtIso) return;

      const reservedAtMs = Date.parse(reservedAtIso);
      if (Number.isNaN(reservedAtMs)) return;
      if (reservedAtMs > staleThresholdMs) return;

      staleReservations.push({
        reservationId: doc.id,
        uid: String(data.uid ?? 'unknown'),
        tokenCost: Number(data.tokenCost ?? 0),
        reservedAtIso,
        ageMinutes: Math.round((Date.now() - reservedAtMs) / 60000),
        requestId: typeof data.requestId === 'string' ? data.requestId : null,
      });
    });

    const snapshotDoc = {
      checkedAt: FieldValue.serverTimestamp(),
      checkedAtIso: new Date().toISOString(),
      staleMinutesThreshold: Math.max(1, staleMinutes),
      reservedScanned: reservedSnap.size,
      staleCount: staleReservations.length,
      staleReservations: staleReservations.slice(0, 50),
      requiresOperatorAction: staleReservations.length > 0,
    };

    await db.collection('ops_monitoring').doc('classify_reservation_reconciliation').set(snapshotDoc, { merge: true });

    if (staleReservations.length > 0) {
      functions.logger.error('reconcileStaleClassifyReservations: stale reservations detected', {
        staleCount: staleReservations.length,
        staleMinutesThreshold: Math.max(1, staleMinutes),
        sample: staleReservations.slice(0, 10),
      });
    } else {
      functions.logger.info('reconcileStaleClassifyReservations: no stale reservations', {
        reservedScanned: reservedSnap.size,
        staleMinutesThreshold: Math.max(1, staleMinutes),
      });
    }

    return null;
  });

const buildThresholdAlerts = (input: {
  counters: Record<string, unknown>;
  refundRate: number;
}): Array<{
  alertType: string;
  value: number;
  threshold: number;
  severity: 'warning' | 'critical';
}> => {
  const claimsFallback = Number(input.counters.spendUserTokens_claims_fallback ?? 0);
  const appCheckMissing = Number(input.counters.appcheck_missing ?? 0);
  const classifyRateLimited = Number(input.counters.classifyImage_rate_limited ?? 0);

  const thresholds = {
    claimsFallback: Math.max(1, Number(process.env.OPS_ALERT_CLAIMS_FALLBACK_THRESHOLD ?? 25)),
    appCheckMissing: Math.max(1, Number(process.env.OPS_ALERT_APPCHECK_MISSING_THRESHOLD ?? 10)),
    classifyRateLimited: Math.max(1, Number(process.env.OPS_ALERT_CLASSIFY_RATE_LIMITED_THRESHOLD ?? 150)),
    refundRate: Math.min(1, Math.max(0, Number(process.env.OPS_ALERT_REFUND_RATE_THRESHOLD ?? 0.15))),
  };

  const alerts: Array<{
    alertType: string;
    value: number;
    threshold: number;
    severity: 'warning' | 'critical';
  }> = [];

  if (claimsFallback >= thresholds.claimsFallback) {
    alerts.push({
      alertType: 'claims_fallback_spike',
      value: claimsFallback,
      threshold: thresholds.claimsFallback,
      severity: 'warning',
    });
  }

  if (appCheckMissing >= thresholds.appCheckMissing) {
    alerts.push({
      alertType: 'appcheck_missing_spike',
      value: appCheckMissing,
      threshold: thresholds.appCheckMissing,
      severity: 'critical',
    });
  }

  if (classifyRateLimited >= thresholds.classifyRateLimited) {
    alerts.push({
      alertType: 'classify_rate_limit_spike',
      value: classifyRateLimited,
      threshold: thresholds.classifyRateLimited,
      severity: 'warning',
    });
  }

  if (input.refundRate >= thresholds.refundRate) {
    alerts.push({
      alertType: 'refund_rate_spike',
      value: Number(input.refundRate.toFixed(4)),
      threshold: thresholds.refundRate,
      severity: 'critical',
    });
  }

  return alerts;
};

export const evaluateOpsThresholdAlerts = asiaSouth1.pubsub
  .schedule('every 15 minutes')
  .timeZone('UTC')
  .onRun(async () => {
    const db = admin.firestore();
    const day = new Date().toISOString().slice(0, 10);

    const [opsMetricsSnap, monitorSnap] = await Promise.all([
      db.collection('ops_metrics').doc(day).get(),
      db.collection('ops_monitoring').doc('classify_reservation_reconciliation').get(),
    ]);

    const counters = (opsMetricsSnap.data()?.counters ?? {}) as Record<string, unknown>;
    const monitor = (monitorSnap.data() ?? {}) as Record<string, unknown>;

    const totalFinalized = Number(monitor.totalFinalized ?? 0);
    const refunded = Number(monitor.refundedCount ?? 0);
    const fallbackRefundRate = totalFinalized > 0 ? refunded / totalFinalized : 0;
    const monitorRefundRate = Number(monitor.refundRate ?? NaN);
    const refundRate = Number.isFinite(monitorRefundRate) ? monitorRefundRate : fallbackRefundRate;

    const alerts = buildThresholdAlerts({ counters, refundRate });

    await db.collection('ops_monitoring').doc('ops_threshold_alerts').set({
      evaluatedAt: FieldValue.serverTimestamp(),
      evaluatedAtIso: new Date().toISOString(),
      day,
      alertCount: alerts.length,
      alerts,
      counters,
      refundRate,
      runbook: 'docs/review/MONEY_FIRST_LAUNCH_CONFIG_CHECKLIST_2026-05-22.md',
    }, { merge: true });

    for (const alert of alerts) {
      const alertId = `${day}_${alert.alertType}`;
      await db.collection('ops_alerts').doc(alertId).set({
        day,
        alertType: alert.alertType,
        severity: alert.severity,
        value: alert.value,
        threshold: alert.threshold,
        status: 'open',
        source: 'evaluateOpsThresholdAlerts',
        createdAt: FieldValue.serverTimestamp(),
        createdAtIso: new Date().toISOString(),
      }, { merge: true });

      functions.logger.error('evaluateOpsThresholdAlerts: threshold breached', {
        alertType: alert.alertType,
        severity: alert.severity,
        value: alert.value,
        threshold: alert.threshold,
        day,
      });
    }

    if (alerts.length === 0) {
      functions.logger.info('evaluateOpsThresholdAlerts: no threshold breaches', { day });
    }

    return null;
  });

export const __testables = {
  buildThresholdAlerts,
};

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

/**
 * Admin dashboard endpoint for classify reservation outcomes/refund rates.
 */
export const getClassifyReservationDashboard = asiaSouth1.https.onRequest(async (req, res) => {
  if (req.method !== 'GET') {
    res.status(405).json({ error: 'Method not allowed' });
    return;
  }

  const diagnosticsEnabled = parseBoolEnv(process.env.ENABLE_DIAGNOSTIC_ENDPOINTS, false);
  if (!diagnosticsEnabled) {
    res.status(403).json({ error: 'Diagnostics disabled' });
    return;
  }

  const isAdmin = await verifyAdminHttpRequest(req);
  if (!isAdmin) {
    res.status(403).json({ error: 'Forbidden: admin token required' });
    return;
  }

  const db = admin.firestore();
  const staleMinutes = Number(process.env.CLASSIFY_RESERVATION_STALE_MINUTES ?? '30');
  const staleThresholdMs = Date.now() - Math.max(1, staleMinutes) * 60_000;

  const [reservedSnap, consumedSnap, refundedSnap, monitorSnap] = await Promise.all([
    db.collection('classify_token_reservations').where('status', '==', 'reserved').limit(1000).get(),
    db.collection('classify_token_reservations').where('status', '==', 'consumed').limit(1000).get(),
    db.collection('classify_token_reservations').where('status', '==', 'refunded').limit(1000).get(),
    db.collection('ops_monitoring').doc('classify_reservation_reconciliation').get(),
  ]);

  let staleReserved = 0;
  reservedSnap.docs.forEach((doc) => {
    const data = doc.data();
    const reservedAtIso = timestampToIso(data.reservedAt) ?? timestampToIso(data.reservedAtIso);
    if (!reservedAtIso) return;
    const reservedAtMs = Date.parse(reservedAtIso);
    if (!Number.isNaN(reservedAtMs) && reservedAtMs <= staleThresholdMs) {
      staleReserved += 1;
    }
  });

  const totalFinalized = consumedSnap.size + refundedSnap.size;
  const refundRate = totalFinalized > 0
    ? Number((refundedSnap.size / totalFinalized).toFixed(4))
    : 0;

  const monitorData = monitorSnap.exists ? monitorSnap.data() : null;

  res.json({
    generatedAtIso: new Date().toISOString(),
    staleMinutesThreshold: Math.max(1, staleMinutes),
    counts: {
      reserved: reservedSnap.size,
      consumed: consumedSnap.size,
      refunded: refundedSnap.size,
      staleReserved,
      totalFinalized,
    },
    rates: {
      refundRate,
    },
    monitoring: monitorData ?? null,
  });
});
