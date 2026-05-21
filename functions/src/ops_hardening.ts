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
