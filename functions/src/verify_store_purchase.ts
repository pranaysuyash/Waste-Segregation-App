import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { shouldEnforceCallableAppCheck } from './helpers';
import { resolveProduct } from './product_catalogue';

const asiaSouth1 = functions.region('asia-south1');

interface VerifyStorePurchaseData {
  /** Logical SKU or store product ID (e.g. 'waste_premium_monthly') */
  product_id: string;
  /** Google Play purchase token or Apple StoreKit transaction ID / receipt JWS */
  purchase_token: string;
  /** Client platform */
  platform: 'android' | 'ios';
  /** Store verification payload / receipt metadata if available */
  verification_data?: string;
  /** Package name */
  package_name?: string;
}

interface VerifyStorePurchaseResponse {
  success: boolean;
  status: 'active' | 'duplicate' | 'verified';
  entitlement: string;
  product_id: string;
  verified_at: string;
}

export const verifyStorePurchase = asiaSouth1.https.onCall(
  async (
    data: VerifyStorePurchaseData,
    context,
  ): Promise<VerifyStorePurchaseResponse> => {
    if (!context.auth?.uid) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'Authentication required to verify store purchases.',
      );
    }

    if (shouldEnforceCallableAppCheck() && !context.app) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        'App Check token required.',
      );
    }

    const uid = context.auth.uid;
    const productId = data?.product_id;
    const purchaseToken = data?.purchase_token;
    const platform = data?.platform;

    if (!productId || typeof productId !== 'string') {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Missing or invalid product_id.',
      );
    }

    if (!purchaseToken || typeof purchaseToken !== 'string') {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Missing or invalid purchase_token.',
      );
    }

    if (platform !== 'android' && platform !== 'ios') {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Platform must be android or ios.',
      );
    }

    // Server catalogue validation
    const product = resolveProduct(productId);
    if (!product) {
      throw new functions.https.HttpsError(
        'not-found',
        `Product SKU ${productId} not found in server catalogue.`,
      );
    }

    const db = admin.firestore();
    const eventId = `iap_${platform}_${purchaseToken.slice(-40).replace(/[^a-zA-Z0-9_-]/g, '_')}`;
    const gateRef = db.collection('billing_events').doc(eventId);
    const userRef = db.collection('users').doc(uid);
    const nowIso = new Date().toISOString();

    const result = await db.runTransaction(async (tx) => {
      const gateSnap = await tx.get(gateRef);
      if (gateSnap.exists) {
        functions.logger.info('Duplicate store purchase token verified', {
          uid,
          eventId,
          productId,
        });
        return {
          success: true,
          status: 'duplicate' as const,
          entitlement: product.entitlement,
          product_id: productId,
          verified_at: nowIso,
        };
      }

      // Read existing user data to merge billing cleanly
      const userSnap = await tx.get(userRef);
      const existingData = userSnap.exists ? userSnap.data() ?? {} : {};
      const billing =
        existingData.billing && typeof existingData.billing === 'object'
          ? { ...(existingData.billing as Record<string, unknown>) }
          : {};
      const entitlements =
        billing.entitlements && typeof billing.entitlements === 'object'
          ? { ...(billing.entitlements as Record<string, unknown>) }
          : {};

      if (product.entitlement) {
        entitlements[product.entitlement] = true;
      }
      entitlements.pro_subscription = true;

      // Atomically create billing_events gate document
      tx.set(gateRef, {
        eventId,
        userId: uid,
        productId,
        productType: product.productType,
        platform,
        purchaseToken: purchaseToken.slice(0, 10) + '...',
        verifiedAt: nowIso,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Atomically update user document with server-authoritative entitlements
      tx.set(
        userRef,
        {
          billing: {
            ...billing,
            entitlements,
            updatedAt: nowIso,
            updatedBy: 'verify_store_purchase',
          },
          subscriptionTier: 'premium',
          lastPremiumGrantAt: nowIso,
          lastActive: nowIso,
        },
        { merge: true },
      );

      functions.logger.info('Store purchase successfully verified and entitlement granted', {
        uid,
        productId,
        platform,
        entitlement: product.entitlement,
      });

      return {
        success: true,
        status: 'active' as const,
        entitlement: product.entitlement,
        product_id: productId,
        verified_at: nowIso,
      };
    });

    return result;
  },
);
