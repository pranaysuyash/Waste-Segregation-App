import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

type MigrateLegacyUserDataRequest = {
  legacyUserId: string;
};

const TRACKED_COLLECTIONS = [
  'classification_feedback',
  'community_posts',
  'ai_jobs',
  'family_analytics_events',
  'activity_feed',
  'user_contributions',
] as const;

const isLikelyValidUserId = (value: string): boolean => {
  return /^[a-zA-Z0-9._:-]{8,128}$/.test(value);
};

export const migrateLegacyUserData = functions
  .region('asia-south1')
  .https.onCall(async (data: MigrateLegacyUserDataRequest, context) => {
    if (!context.auth?.uid) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'Authentication required.',
      );
    }
    const uid = context.auth.uid;
    const legacyUserId = `${data?.legacyUserId ?? ''}`.trim();

    if (!isLikelyValidUserId(legacyUserId)) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'legacyUserId is invalid.',
      );
    }
    if (legacyUserId === uid) {
      return {
        migrated: false,
        reason: 'legacy_id_matches_uid',
      };
    }

    const db = admin.firestore();
    let migratedDocs = 0;
    let skippedDocs = 0;

    await db.runTransaction(async (tx) => {
      const legacyUserRef = db.collection('users').doc(legacyUserId);
      const uidUserRef = db.collection('users').doc(uid);

      const [legacyUserSnap, uidUserSnap] = await Promise.all([
        tx.get(legacyUserRef),
        tx.get(uidUserRef),
      ]);

      if (legacyUserSnap.exists) {
        const legacyData = legacyUserSnap.data() ?? {};
        const existingUidData = uidUserSnap.data() ?? {};
        tx.set(uidUserRef, {
          ...legacyData,
          ...existingUidData,
          id: uid,
          migratedFromLegacyId: legacyUserId,
          migratedAt: admin.firestore.FieldValue.serverTimestamp(),
          lastActive: new Date().toISOString(),
        }, { merge: true });
        tx.delete(legacyUserRef);
        migratedDocs++;
      }
    });

    for (const collectionName of TRACKED_COLLECTIONS) {
      const query = await db
        .collection(collectionName)
        .where('userId', '==', legacyUserId)
        .get();
      if (query.empty) continue;

      const batch = db.batch();
      query.docs.forEach((doc) => {
        const payload = doc.data();
        batch.set(doc.ref, {
          ...payload,
          userId: uid,
          migratedFromLegacyId: legacyUserId,
          migratedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
      });
      await batch.commit();
      migratedDocs += query.docs.length;
    }

    const legacyLeaderboardRef = db.collection('leaderboard_allTime').doc(legacyUserId);
    const uidLeaderboardRef = db.collection('leaderboard_allTime').doc(uid);
    const legacyLeaderboardSnap = await legacyLeaderboardRef.get();
    if (legacyLeaderboardSnap.exists) {
      const data = legacyLeaderboardSnap.data() ?? {};
      await uidLeaderboardRef.set({
        ...data,
        userId: uid,
        migratedFromLegacyId: legacyUserId,
        migratedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
      await legacyLeaderboardRef.delete();
      migratedDocs++;
    } else {
      skippedDocs++;
    }

    functions.logger.info('migrateLegacyUserData completed', {
      uid,
      legacyUserId,
      migratedDocs,
      skippedDocs,
    });

    return {
      migrated: migratedDocs > 0,
      migratedDocs,
      skippedDocs,
      uid,
      legacyUserId,
    };
  });
