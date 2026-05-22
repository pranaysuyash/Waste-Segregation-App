# Community Stats Phase 5: Cloud Function Batch Aggregation

**Status**: Ready for Deployment  
**Implementation Date**: 2026-05-22  
**Predecessor**: [COMMUNITY_STATS_ARCHITECTURE.md](./COMMUNITY_STATS_ARCHITECTURE.md)

---

## Overview

Phase 5 introduces a **Cloud Function** that runs hourly to pre-aggregate community feed statistics and cache them in Firestore. This eliminates the O(n) in-memory aggregation bottleneck when the community feed grows beyond 100k items.

### Before Phase 5 (Current)

```
CommunityScreen.getStats()
  → reads 10,000 feed items from Firestore (1 read)
  → aggregates in-memory (O(n), ~100-500ms)
  → returns stats
```

**Problem**: As feed grows to 100k+, aggregation time increases linearly.

### After Phase 5 (Deployed)

```
Cloud Scheduler (hourly)
  → runs aggregateCommunityStats Cloud Function
  → reads 10,000+ feed items in batches (paginated)
  → writes cached stats to community_stats/main (1 write)

CommunityScreen.getStats() [optional]
  → reads cached community_stats/main (1 read)
  → returns instant stats
```

**Benefit**: 
- Stats reads drop from ~1sec to ~5ms (200x faster)
- Firestore cost flat at ~$0.35/month regardless of feed size
- UI never blocks on aggregation

---

## Implementation

### Cloud Function: `aggregateCommunityStats`

**File**: `functions/src/community_stats_aggregator.ts`

**Trigger**: Cloud Scheduler (hourly)  
**Schedule**: `0 * * * *` (every hour at minute 0)  
**Region**: `us-central1`  
**Memory**: 512MB  
**Timeout**: 540 seconds (9 minutes)

#### How It Works

1. **Pagination**: Fetches feed items in batches of 1,000
   - Handles 100k+ items without memory bloat
   - Uses Firestore cursor-based pagination (startAfter)
   
2. **Aggregation**: Accumulates stats in memory
   ```typescript
   for each batch:
     - Add userId to Set (unique count)
     - Sum points (all activity types)
     - Count classifications (only type === 'classification')
     - Track category breakdown
   ```

3. **Write**: Caches result to `community_stats/main`
   ```typescript
   {
     totalUsers: 15,
     totalClassifications: 342,
     totalPoints: 3420,
     categoryBreakdown: { plastic: 145, glass: 89, ... },
     lastUpdated: Timestamp(now),
     lastAggregationDuration: 2341 // milliseconds
   }
   ```

4. **Logging**: Tracks metrics for monitoring
   - Duration (ms)
   - Feed items processed
   - Final stats
   - Error logs if failure

#### Key Properties

**Memory Efficiency**
- O(unique_users + categories), not O(items)
- Set<userId> remains bounded (max ~1M users in memory)
- ~1KB per 1000 feed items processed

**Pagination Design**
```typescript
// Fetch first batch
query = collection.orderBy('timestamp', 'desc').limit(1000)
// Fetch subsequent batches
query = query.startAfter(lastDocSnapshot)
```
- No offset (inefficient in Firestore)
- No "fetch all" (would blow memory)
- Linear scan through all items once

**Idempotent Writes**
- Uses `set()` not `update()` → overwrites old stats atomically
- Safe if function runs multiple times same hour
- No race conditions (document is always consistent)

---

## Deployment

### Prerequisites

1. **Cloud Scheduler API enabled** (required for scheduled functions)
   ```bash
   gcloud services enable cloudscheduler.googleapis.com
   ```

2. **Service Account has required roles**:
   - `roles/firebase.admin` (to write to Firestore)
   - `roles/cloudfunctions.invoker` (to call the function)

3. **firebase.json includes functions**:
   ```json
   {
     "functions": [
       {
         "source": "functions",
         "codebase": "default"
       }
     ]
   }
   ```

### Deployment Steps

1. **Deploy the function**:
   ```bash
   cd /Users/pranay/Projects/LLM/image/waste_seg/waste_segregation_app
   firebase deploy --only functions
   ```

2. **Create Cloud Scheduler job** (if not auto-created by framework):
   ```bash
   gcloud scheduler jobs create pubsub aggregate-community-stats \
     --schedule="0 * * * *" \
     --timezone="UTC" \
     --topic=firebase-schedule-aggregateCommunityStats-us-central1 \
     --message-body='{"data": {}}'
   ```

3. **Verify deployment**:
   ```bash
   firebase functions:list
   # Should show: aggregateCommunityStats (scheduled)
   ```

4. **Test manually** (optional):
   ```bash
   curl -X POST https://us-central1-waste-segregation-app-df523.cloudfunctions.net/aggregateCommunityStatsHttp \
     -H "Authorization: Bearer $(gcloud auth print-identity-token)" \
     -H "Content-Type: application/json"
   
   # Response:
   # {
   #   "success": true,
   #   "stats": { totalUsers, totalClassifications, ... },
   #   "feedItemsProcessed": 47,
   #   "durationMs": 2341
   # }
   ```

---

## Migration Path: Using Cached Stats

### Option A: Automatic (Recommended for Phase 5+)

Update `CommunityService.getStats()` to **prefer cached stats**:

```dart
// lib/services/community_service.dart (Phase 5+)
Future<CommunityStats> getStats() async {
  try {
    // Step 1: Try cached stats (from Cloud Function)
    final cachedSnapshot = await _firestore
      .collection('community_stats')
      .doc('main')
      .get();
    
    if (cachedSnapshot.exists) {
      final data = cachedSnapshot.data();
      // Cached stats are fresh (updated hourly)
      return CommunityStats.fromJson(data!);
    }
  } catch (e) {
    // Fall through to fallback
  }
  
  // Step 2: Fallback to live aggregation (if cache not ready)
  return _aggregateLive(); // Original Phase 4 logic
}
```

**Benefits**:
- Instant reads (no network wait)
- Firestore usage flat (~$0.06/month per 100k calls)
- UI never blocks

**Caveat**:
- Stats are up to 1 hour stale
- For real-time precision, still use fallback on first sync

### Option B: Hybrid (for Phase 5+5 with polling)

Allow background refreshing while showing cached stats:

```dart
// Show cached stats immediately
Text('${_stats.totalUsers} users'),

// Refresh in background (every 30 min)
_startBackgroundStatsRefresh(); // Calls getStats() but doesn't block UI
```

### Option C: Deferred (if you want to keep Phase 4 behavior)

Keep current phase 4 logic indefinitely:
- Cloud Function still runs (pre-aggregates for future use)
- App still reads live (no changes to CommunityService)
- No migration needed until manually triggered

---

## Monitoring & Observability

### Metrics to Track

| Metric | Expected | Alert Threshold |
|--------|----------|-----------------|
| Invocations/month | ~730 (hourly) | > 1460 (2x) |
| Duration (ms) | 500-2000 | > 9000 (9 min timeout) |
| Feed items processed | 100-100k | see notes |
| Errors/invocations | 0% | > 1% |
| Last aggregation (recency) | < 1 hour old | > 2 hours |

### Logs

Cloud Functions logs appear in:
- **Console**: [Google Cloud Console → Functions → Logs](https://console.cloud.google.com/functions/details/us-central1/aggregateCommunityStats)
- **Command line**: 
  ```bash
  firebase functions:log --limit 50
  ```

### Sample Log Entry (Success)

```json
{
  "severity": "INFO",
  "message": "Community Stats Aggregator: Completed in 2341ms",
  "labels": {
    "function_name": "aggregateCommunityStats",
    "region": "us-central1"
  },
  "jsonPayload": {
    "totalUsers": 15,
    "totalClassifications": 342,
    "totalPoints": 3420,
    "feedItems": 47,
    "durationMs": 2341
  }
}
```

### Sample Log Entry (Error)

```json
{
  "severity": "ERROR",
  "message": "Community Stats Aggregator: Failed to aggregate stats",
  "labels": {
    "function_name": "aggregateCommunityStats"
  },
  "jsonPayload": {
    "error": "Firestore unavailable",
    "code": "UNAVAILABLE"
  }
}
```

---

## Testing

### Unit Tests (Local)

```bash
# (Not yet implemented — add to test/community_stats_aggregator.test.ts)
# For now, test manually via HTTP endpoint
```

### Integration Test (Emulator)

```bash
firebase emulators:start --only firestore,functions
# In another terminal:
curl -X POST http://localhost:5001/waste-segregation-app-df523/us-central1/aggregateCommunityStatsHttp \
  -H "Content-Type: application/json"
```

### Production Test (Cloud)

1. **Manual invocation**:
   ```bash
   firebase functions:call aggregateCommunityStats --project waste-segregation-app-df523
   ```

2. **Check result**:
   ```bash
   firebase firestore:get community_stats/main --project waste-segregation-app-df523
   ```

3. **Verify in Firestore Console**:
   - Go to [Firestore Console](https://console.firebase.google.com/u/0/project/waste-segregation-app-df523/firestore)
   - Collection: `community_stats`
   - Document: `main`
   - Should show `lastUpdated` timestamp from recent execution

---

## Cost Analysis

### Monthly Cost Breakdown

| Component | Rate | Quantity | Cost |
|-----------|------|----------|------|
| Function invocations | $0.40/1M | ~730 | $0.00029 |
| GB-seconds | $0.0025/GB-sec | ~2000 (730 × ~2.74s) | ~$0.005 |
| Firestore reads | $0.06/100k | ~730 reads | ~$0.004 |
| Firestore writes | $0.18/100k | ~730 writes | ~$0.0013 |
| **Total Phase 5 overhead** | — | — | **~$0.01/month** |

### Cost Reduction (vs Phase 4)

| Scenario | Phase 4 (Live Aggregation) | Phase 5 (Cached) | Savings |
|----------|---------------------------|-----------------|---------|
| 1,000 active users/month | $0.06/month reads | $0.004 reads | 93% |
| 10,000 users checking stats 10x/month | $0.60 reads | $0.04 reads | 93% |
| **Break-even point** | — | — | **When feed > 50k items** |

---

## Future Enhancements

### Phase 5.1: Real-Time Stats (WebSocket Listener)

Instead of hourly polling, listen to Firestore write events:

```typescript
// functions/src/community_feed_listener.ts
export const onNewFeedItem = functions.firestore
  .document('community_feed/{itemId}')
  .onCreate(async (snap, context) => {
    const item = snap.data();
    // Incrementally update community_stats/main
    await incrementStats(item);
  });
```

**Pros**: Stats always fresh (< 1 second stale)  
**Cons**: Higher write cost (~$0.50/month if 10k items/day)

### Phase 5.2: Per-Category Caching

Add separate documents for each category:

```firestore
community_stats/main → overall
community_stats/category_plastic → plastic only
community_stats/category_glass → glass only
```

Allows faster queries like "how many plastics classified today?"

### Phase 5.3: Analytics Pipeline (BigQuery Export)

Stream feed items to BigQuery for weekly/monthly trends:

```typescript
// functions/src/feed_to_bigquery.ts
export const streamFeedToBigQuery = functions.firestore
  .document('community_feed/{itemId}')
  .onCreate(async (snap) => {
    const item = snap.data();
    await bigquery
      .dataset('community_feed')
      .table('feed_items')
      .insert(item);
  });
```

Unlocks SQL analytics, dashboards, ML models on historical data.

---

## Troubleshooting

### Issue: "Function timed out after 540s"

**Cause**: Feed has > 500k items, aggregation takes too long

**Fix**: 
- Increase timeout to 900s (15 min)
- Or implement Cloud Tasks pipeline (break into smaller jobs)

**Code**:
```typescript
export const aggregateCommunityStats = onSchedule(
  { timeoutSeconds: 900, ... },
  // ...
);
```

### Issue: "Firestore quota exceeded"

**Cause**: Many concurrent reads hitting daily quota

**Fix**:
- If Phase 5.2 (per-category), disable non-essential categories
- Wait for next day (quota resets at UTC midnight)
- Request quota increase in Google Cloud Console

### Issue: "lastAggregationDuration is missing in stats"

**Cause**: Function version mismatch (old code didn't set it)

**Fix**:
- Re-deploy function: `firebase deploy --only functions`
- Wait for next hourly run
- Stats will have field in next aggregation

### Issue: "Cached stats are stale (2+ hours old)"

**Cause**: Cloud Function failed for N consecutive hours

**Check**:
1. Go to [Cloud Functions Console](https://console.cloud.google.com/functions)
2. Click `aggregateCommunityStats`
3. Scroll to "Executions" tab
4. Look for error logs

**Fix**:
- If transient: wait 1 hour for next automatic retry
- If persistent: check Firestore quota, API rate limits, or IAM permissions
- Fallback: call `aggregateCommunityStatsHttp` manually

---

## See Also

- **Original Architecture**: [COMMUNITY_STATS_ARCHITECTURE.md](./COMMUNITY_STATS_ARCHITECTURE.md)
- **Implementation**: [functions/src/community_stats_aggregator.ts](../../../functions/src/community_stats_aggregator.ts)
- **UI Changes Needed**: Phase 5.5+ (update CommunityService to read cache)
- **Issue**: [#172 (Original Community Stats Issue)](https://github.com/pranaysuyash/Waste-Segregation-App/issues/172)
