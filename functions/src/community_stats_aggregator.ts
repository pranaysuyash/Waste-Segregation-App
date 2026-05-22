/**
 * Community Stats Aggregator Cloud Function
 * 
 * Scheduled function that runs hourly to aggregate community feed statistics
 * and cache them in Firestore for fast reads.
 * 
 * Phase 5 Implementation: Batch Aggregation for Scaling
 * Purpose: When community feed exceeds 100k items, this function reduces
 * load from O(n) in-memory aggregation to O(1) cached document read.
 * 
 * Configuration:
 * - Trigger: Cloud Scheduler (hourly: "0 * * * *")
 * - Region: us-central1 (same as other functions)
 * - Memory: 512MB
 * - Timeout: 540s (9 minutes)
 * 
 * Cost Impact:
 * - Invocation: 0.40 USD / million invocations → ~$0.29/month (730 invocations/month)
 * - Firestore reads: 1 read per invocation for listing ~10-100k items
 *   (when paginating with batches of 1000)
 * - Firestore writes: 1 write per invocation (stats document)
 * - Total: ~$0.35/month (negligible)
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const firestore = admin.firestore();

interface CommunityFeedItem {
  id: string;
  userId: string;
  userName?: string;
  activityType: string; // 'classification' | 'achievement' | 'streak' | 'challenge' | 'milestone' | 'educational'
  title: string;
  description: string;
  timestamp: admin.firestore.Timestamp;
  points: number;
  metadata: Record<string, any>;
  isAnonymous?: boolean;
}

interface CommunityStats {
  totalUsers: number;
  totalClassifications: number;
  totalPoints: number;
  categoryBreakdown: Record<string, number>;
  lastUpdated: admin.firestore.Timestamp;
  lastAggregationDuration?: number; // milliseconds (for monitoring)
}

/**
 * Aggregates community feed data and caches in Firestore
 * 
 * This function:
 * 1. Reads all feed items from Firestore (with pagination for scale)
 * 2. Aggregates stats in memory
 * 3. Writes cached stats to community_stats/main
 * 4. Logs aggregation metrics for monitoring
 * 
 * Pagination strategy:
 * - Fetches in batches of 1000 items to avoid memory bloat
 * - Processes each batch incrementally
 * - Scales to 1M+ items with minimal memory footprint
 * 
 * Trigger: Cloud Pub/Sub topic (firebase-schedule-aggregateCommunityStats-us-central1)
 * Created by Cloud Scheduler with cron schedule: 0 * * * * (hourly)
 */
export const aggregateCommunityStats = functions
  .region('us-central1')
  .pubsub.schedule('0 * * * *') // Every hour at minute 0
  .onRun(async (context) => {
    const startTime = Date.now();

    try {
      functions.logger.info(
        '🔄 Community Stats Aggregator: Starting aggregation job',
      );

      // Step 1: Aggregate stats from feed with pagination
      const stats = await aggregateFeedStats();

      // Step 2: Write aggregated stats to cache document
      const statsRef = firestore.collection('community_stats').doc('main');
      const aggregationDuration = Date.now() - startTime;

      const statsData: CommunityStats = {
        totalUsers: stats.totalUsers,
        totalClassifications: stats.totalClassifications,
        totalPoints: stats.totalPoints,
        categoryBreakdown: stats.categoryBreakdown,
        lastUpdated: admin.firestore.Timestamp.now(),
        lastAggregationDuration: aggregationDuration,
      };

      await statsRef.set(statsData);

      functions.logger.info(
        `✅ Community Stats Aggregator: Completed in ${aggregationDuration}ms`,
        {
          totalUsers: stats.totalUsers,
          totalClassifications: stats.totalClassifications,
          totalPoints: stats.totalPoints,
          feedItems: stats.feedItemsProcessed,
          durationMs: aggregationDuration,
        },
      );
    } catch (error) {
      functions.logger.error(
        '❌ Community Stats Aggregator: Failed to aggregate stats',
        error,
      );
      // Do not throw — let the function complete gracefully
      // Failed aggregations will not update the cache, and clients will use stale data
      // This is safer than crashing and blocking the schedule
    }
  });

/**
 * Aggregates feed items using pagination to handle large datasets
 * 
 * Algorithm:
 * 1. Query feed items in batches of 1000, ordered by timestamp desc
 * 2. For each batch:
 *    - Add userId to set (for unique user count)
 *    - Sum points
 *    - Count classification activities
 *    - Track category breakdown
 * 3. Return aggregated totals
 * 
 * Memory efficiency: O(unique_users + categories) not O(items)
 * because we aggregate instead of storing all items
 */
async function aggregateFeedStats(): Promise<{
  totalUsers: number;
  totalClassifications: number;
  totalPoints: number;
  categoryBreakdown: Record<string, number>;
  feedItemsProcessed: number;
}> {
  const BATCH_SIZE = 1000;
  const feedCollection = firestore.collection('community_feed');

  let lastDocSnapshot: admin.firestore.DocumentSnapshot | null = null;
  let feedItemsProcessed = 0;

  // Aggregation accumulators
  const userIds = new Set<string>();
  let totalPoints = 0;
  let totalClassifications = 0;
  const categoryBreakdown: Record<string, number> = {};

  // Pagination loop: fetch batches until no more items
  while (true) {
    let query = feedCollection
      .orderBy('timestamp', 'desc')
      .limit(BATCH_SIZE);

    // Continue from last document (pagination cursor)
    if (lastDocSnapshot) {
      query = query.startAfter(lastDocSnapshot);
    }

    const snapshot = await query.get();

    if (snapshot.empty) {
      break; // No more items to process
    }

    // Process batch
    for (const doc of snapshot.docs) {
      const item = doc.data() as CommunityFeedItem;
      feedItemsProcessed++;

      // Track unique users
      userIds.add(item.userId);

      // Sum all points (classification + achievement + streak, etc.)
      totalPoints += item.points || 0;

      // Count classifications
      if (item.activityType === 'classification') {
        totalClassifications++;

        // Track category breakdown
        const category = item.metadata?.category;
        if (typeof category === 'string' && category) {
          categoryBreakdown[category] =
            (categoryBreakdown[category] || 0) + 1;
        }
      }
    }

    // Remember last document for pagination
    lastDocSnapshot = snapshot.docs[snapshot.docs.length - 1];

    // Log progress for long-running aggregations
    if (feedItemsProcessed % (BATCH_SIZE * 10) === 0) {
      functions.logger.info(
        `📊 Processed ${feedItemsProcessed} feed items...`,
      );
    }
  }

  return {
    totalUsers: userIds.size,
    totalClassifications,
    totalPoints,
    categoryBreakdown,
    feedItemsProcessed,
  };
}

/**
 * HTTP Endpoint (for manual triggering and testing)
 * 
 * Usage (Firebase CLI):
 * firebase functions:call aggregateCommunityStats:aggregateCommunityStatsHttp --project waste-segregation-app-df523
 * 
 * Usage (cURL, requires authentication):
 * curl -X POST https://region-project.cloudfunctions.net/aggregateCommunityStatsHttp \
 *   -H "Authorization: Bearer $(gcloud auth print-identity-token)" \
 *   -H "Content-Type: application/json"
 */
export const aggregateCommunityStatsHttp = functions
  .region('us-central1')
  .https.onRequest(async (req, res) => {
    // Only allow POST requests
    if (req.method !== 'POST') {
      res.status(405).json({ error: 'Method not allowed' });
      return;
    }

    // Optional: Verify authentication (for security)
    // In production, verify Firebase ID token or use IAM service account
    // For now, allow if cloud function has restrict-public-access policy

    try {
      const startTime = Date.now();
      const stats = await aggregateFeedStats();
      const durationMs = Date.now() - startTime;

      const statsRef = firestore.collection('community_stats').doc('main');
      const statsData: CommunityStats = {
        totalUsers: stats.totalUsers,
        totalClassifications: stats.totalClassifications,
        totalPoints: stats.totalPoints,
        categoryBreakdown: stats.categoryBreakdown,
        lastUpdated: admin.firestore.Timestamp.now(),
        lastAggregationDuration: durationMs,
      };

      await statsRef.set(statsData);

      res.status(200).json({
        success: true,
        stats: statsData,
        feedItemsProcessed: stats.feedItemsProcessed,
        durationMs,
      });
    } catch (error) {
      functions.logger.error(
        'Error in aggregateCommunityStatsHttp:',
        error,
      );
      res.status(500).json({
        error: 'Failed to aggregate community stats',
        message: error instanceof Error ? error.message : String(error),
      });
    }
  });
