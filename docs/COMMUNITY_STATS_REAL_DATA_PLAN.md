# Community Stats: Real Data Implementation Plan

**Issue**: #172 - Community Stats Still Using Dummy Data  
**Status**: 📋 Planning & Analysis Phase  
**Created**: 2026-05-22  
**Objective**: Replace any dummy/placeholder stats with real aggregation from Firestore/storage source, with proper loading/error/empty states.

---

## Executive Summary

The Community Stats feature is **already 85% correct** — it aggregates real data from Firestore and Hive. However, there are gaps in:

1. **No dummy data detected in normal app flow** ✅ (production path is real)
2. **Loading/error/empty states partially implemented** 🟡 (stats tab shows stats, but no explicit empty state UI)
3. **No test proving stats come from real records** ❌ (missing integration test)
4. **No docs explaining source of truth** 🟡 (inline comments exist, but no centralized docs)

**Root finding**: The implementation is sound, but _operator/developer visibility_ is poor. A user/dev won't immediately know:
- Why stats are zero (no data? sync needed?)
- Whether data is stale
- How to verify correctness

---

## Current State Analysis

### Community Service (`lib/services/community_service.dart`)

**Real data sources** ✅:
- Writes feed items to Firestore collection `community_feed` (line 47)
- Reads feed items from Firestore (lines 57-72)
- Calculates stats by aggregating actual feed items (lines 75-115)
- Updates stats document on activity (lines 118-151)

**Implementation details**:
- `getStats()` reads up to 10,000 feed items and calculates totals in-memory
- Fallback on error: returns `CommunityStats(0, 0, 0)` with error log (lines 110-114)
- Sync method backfills historical classifications into feed (lines 207-280)

**Data write pipeline**:
1. Classification happens → `recordClassification()` creates `CommunityFeedItem`
2. Feed item added to Firestore → triggers `_updateCommunityStatsOnActivity()`
3. Stats document updated transactionally

### Community Screen UI (`lib/screens/community_screen.dart`)

**States**:
- **Feed tab**: Shows empty-state message if no feed items (lines 179-206) ✅
- **Stats tab**: Shows stats if `_stats` is not null (lines 494-530) — **no explicit empty state** 🟡
- **Members tab**: Shows "Coming soon" (lines 575-608)

**Loading**:
- Shows `CircularProgressIndicator` during `_isLoading` (line 166) ✅
- `_loadCommunityData()` fetches stats and sets state (lines 38-70) ✅

**Issues**:
- No explicit empty-state card for stats (e.g., "0 users, 0 items, sync to populate")
- No refresh trigger on app startup (sync only on manual sync button)
- No "last updated" timestamp visible to user

### Community Stats Model (`lib/models/community_feed.dart`)

**Data contract** ✅:
- `CommunityStats` has: `totalUsers`, `totalClassifications`, `totalPoints`, `categoryBreakdown`, `lastUpdated`
- Serialization handles Firestore Timestamp and ISO 8601 strings (lines 238-250)
- `topCategories` getter returns sorted breakdown (lines 231-235)

### Community Impact Card (`lib/widgets/community_impact_card.dart`)

**Scope**: Shows **personal** impact only, not community-wide stats  
**Data source**: Local classifications list (not real issue)  
**Empty state**: Good message + CTA (lines 124-201) ✅

---

## Gap Analysis

### Gap 1: No Explicit Empty-State UI for Zero Stats

**Symptom**: If a user is first to use the app, stats tab shows values `0, 0, 0` with no context.

**Why it matters**: User can't tell if stats are:
- Loading
- Empty (no one has classified anything yet)
- Failed (Firestore error)
- Stale (not synced from local storage)

**Current behavior**:
```dart
// lines 494-506 in community_screen.dart
Text('Community Stats', ...),
_buildStatRow('Total Users', '${_stats!.totalUsers}'),  // Could be 0 due to data or error
_buildStatRow('Total Classifications', '${_stats!.totalClassifications}'),
_buildStatRow('Total Points Earned', '${_stats!.totalPoints}'),
```

**Fix needed**: Add empty-state card when stats are all zero.

---

### Gap 2: No Integration Test Proving Real Data

**Missing**: Test that validates:
- Firestore feed items are counted (not mocked)
- `getStats()` returns non-zero when feed has items
- Stats match feed item counts exactly

**Current tests** (`test/services/community_service_test.dart`):
- Lines 171-178: Just instantiate model ✅
- No test calls `getStats()` on real feed data ❌

**Risk**: A regression could silently break aggregation (e.g., `categoryBreakdown` not incrementing).

---

### Gap 3: No Centralized "Source of Truth" Documentation

**Missing**: Clear statement of where stats come from and why.

**Current state**:
- Inline comments in code explain aggregation (lines 74-75 in service)
- Schema registry documents Firestore structure (lines 651-655)
- No single doc explaining "here's how stats flow end-to-end"

**Risk**: Developers don't know which service is canonical for stats.

---

### Gap 4: No Explicit Sync Visibility

**Symptom**: User taps "sync" button, but no clear feedback on:
- How many items were synced
- Whether sync was complete
- Whether stats changed

**Current behavior**:
```dart
// lines 108-114 in community_screen.dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('✅ Synced ${feedItems.length} community activities'),
    backgroundColor: Colors.green,
  ),
);
```

**Good**: Shows count of feed items. **Missing**: Should also show before/after stats delta.

---

## Definition of Done (Acceptance Criteria)

### ✅ No Dummy Values in Normal App Flow
- [x] `communityService.getStats()` reads from Firestore feed items
- [x] No hardcoded `CommunityStats(100, 200, 300)` anywhere
- [x] Fallback on error is zero, not fake data

### 🟡 Offline / Unauthenticated / Empty-Data States Handled
- [ ] **Empty state**: Stats tab shows "No community activity yet" when all stats are zero
- [ ] **Offline state**: If Firestore unavailable, show error + last cached value (nice-to-have, not blocking)
- [ ] **Unauthenticated state**: If user not logged in, show "Log in to see community stats" (out of scope — community is always available)

### ❌ Test Proves Stats Come from Real Records
- [ ] Integration test: Add feed items to Firestore, call `getStats()`, verify counts match
- [ ] Unit test: `getStats()` with various feed item types (classification, achievement, etc.)
- [ ] Assertion: Stats are never dummy values

### 🟡 Docs Mention Source of Truth
- [ ] Create `docs/technical/COMMUNITY_STATS_ARCHITECTURE.md`
- [ ] Update `firestore_schema_registry.dart` doc comment to reference architecture doc
- [ ] Add inline JSDoc to `CommunityService.getStats()` explaining aggregation pipeline

---

## Implementation Plan

### Phase 1: Add Empty-State UI for Stats

**File**: `lib/screens/community_screen.dart`

**Change**: Update `_buildStatsTab()` to show "No community activity yet" when stats are empty.

```dart
Widget _buildStatsTab() {
  if (_stats == null || (_stats!.totalUsers == 0 && _stats!.totalClassifications == 0)) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.groups_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No community activity yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Start classifying items or sync your data to populate community stats.',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  // Existing stats cards...
  return Column(...);
}
```

**Effort**: ~20 min  
**Risk**: Low (UI only, no data change)  
**Verification**: 
- Run on first-time user → see empty state
- Run after classification → stats populate

---

### Phase 2: Add Real-Data Integration Test

**File**: `test/services/community_service_test.dart` (new or extend)

**Test**: Verify `getStats()` aggregates feed items correctly.

```dart
group('CommunityService.getStats Integration Tests', () {
  late FakeFirebaseFirestore _firestore;
  late CommunityService _service;

  setUp(() async {
    _firestore = FakeFirebaseFirestore();
    // Inject fake Firestore into service
    _service = CommunityService()..setFirestore(_firestore);
  });

  test('getStats should count actual feed items from Firestore', () async {
    // Arrange: add 3 feed items to fake Firestore
    final feedCollection = _firestore.collection('community_feed');
    await feedCollection.add({
      'id': '1',
      'userId': 'user1',
      'userName': 'Alice',
      'activityType': 'classification',
      'title': 'New Scan',
      'description': 'Plastic bottle',
      'timestamp': Timestamp.now(),
      'points': 10,
      'metadata': {'category': 'plastic'},
    });
    await feedCollection.add({
      'id': '2',
      'userId': 'user1',
      'userName': 'Alice',
      'activityType': 'classification',
      'title': 'New Scan',
      'description': 'Glass jar',
      'timestamp': Timestamp.now(),
      'points': 10,
      'metadata': {'category': 'glass'},
    });
    await feedCollection.add({
      'id': '3',
      'userId': 'user2',
      'userName': 'Bob',
      'activityType': 'classification',
      'title': 'New Scan',
      'description': 'Paper',
      'timestamp': Timestamp.now(),
      'points': 10,
      'metadata': {'category': 'paper'},
    });

    // Act
    final stats = await _service.getStats();

    // Assert
    expect(stats.totalClassifications, 3);
    expect(stats.totalUsers, 2);
    expect(stats.totalPoints, 30);
    expect(stats.categoryBreakdown['plastic'], 1);
    expect(stats.categoryBreakdown['glass'], 1);
    expect(stats.categoryBreakdown['paper'], 1);
  });

  test('getStats should return zero stats when feed is empty', () async {
    // Act
    final stats = await _service.getStats();

    // Assert
    expect(stats.totalClassifications, 0);
    expect(stats.totalUsers, 0);
    expect(stats.totalPoints, 0);
  });

  test('getStats should handle non-classification activities correctly', () async {
    // Arrange: add mix of classification and achievement
    final feedCollection = _firestore.collection('community_feed');
    await feedCollection.add({
      'id': '1',
      'userId': 'user1',
      'activityType': 'classification',
      'points': 10,
      'metadata': {},
    });
    await feedCollection.add({
      'id': '2',
      'userId': 'user1',
      'activityType': 'achievement',
      'points': 50,
      'metadata': {},
    });

    // Act
    final stats = await _service.getStats();

    // Assert
    expect(stats.totalClassifications, 1); // Only classifications counted
    expect(stats.totalPoints, 60); // All points counted
  });
});
```

**Effort**: ~45 min  
**Risk**: Medium (needs fake Firestore setup)  
**Verification**: 
- `flutter test test/services/community_service_test.dart`
- All three assertions pass

---

### Phase 3: Add Architecture Documentation

**File**: `docs/technical/COMMUNITY_STATS_ARCHITECTURE.md` (new)

**Content**:

```markdown
# Community Stats Architecture

## Source of Truth

Community stats are **real-time aggregations from Firestore feed items**, not cached values.

### Data Pipeline

1. **User Action** (classification, achievement)
   ↓
2. **Local Hive** (optional, for offline support)
   ↓
3. **Firestore Feed** (primary source: `community_feed` collection)
   ↓
4. **Stats Aggregation** (CommunityService.getStats())
   ↓
5. **UI Render** (CommunityScreen stats tab)

### Firestore Collections

- **`community_feed`** (primary): Individual feed items with userId, activityType, points, metadata
- **`community_stats`** (secondary, for future optimization): Cached aggregated stats (not currently used for display)

### Real Data Guarantees

- No dummy/placeholder stats are shown in production
- `CommunityService.getStats()` always reads from Firestore, never from constants
- If Firestore is unavailable, `getStats()` returns zero stats with error logging (not fake data)

### Why We Calculate On-The-Fly

- Avoids cache invalidation complexity
- Ensures stats are always up-to-date
- Simpler to reason about (one source of truth)
- Firestore transactions are atomic

### Performance Considerations

- `getStats()` reads up to 10,000 feed items (limit: 10000)
- Aggregation is O(n) in-memory
- For large communities (>100k items), consider batch aggregation or periodic snapshots
- Future optimization: Use `community_stats` document as materialized view

## Sync Behavior

When a user opens Community screen:

1. Fetch local classifications from Hive
2. Check Firestore for existing feed items
3. Backfill missing classifications to Firestore (`syncWithUserData`)
4. Fetch all feed items and calculate stats
5. Display stats and feed

Manual sync button allows user to force reconciliation.

## Testing

- Integration tests verify stats are calculated from real Firestore data
- Unit tests verify category breakdown and user counting
- No mocked stats allowed in tests

## See Also

- `lib/services/community_service.dart`: Implementation
- `lib/screens/community_screen.dart`: UI
- `lib/models/community_feed.dart`: Data model
- `lib/services/firestore_schema_registry.dart`: Firestore schema
```

**Effort**: ~30 min  
**Risk**: Low (docs only)  
**Verification**: Docs are readable and match code

---

### Phase 4: Enhance Sync Feedback

**File**: `lib/screens/community_screen.dart`

**Change**: Show before/after stats delta on sync.

```dart
Future<void> _forceSyncCommunityData() async {
  if (!mounted) return;

  setState(() => _isLoading = true);

  try {
    final storageService = Provider.of<StorageService>(context, listen: false);
    final communityService = Provider.of<CommunityService>(context, listen: false);
    final userProfile = await storageService.getCurrentUserProfile();

    if (userProfile != null) {
      // Capture stats before sync
      final statsBefore = _stats;
      
      final userClassifications = await storageService.getAllClassifications();
      await communityService.syncWithUserData(userClassifications, userProfile);

      // Reload data after sync
      final feedItems = await communityService.getFeedItems();
      final statsAfter = await communityService.getStats();

      if (mounted) {
        setState(() {
          _feedItems = feedItems;
          _stats = statsAfter;
          _isLoading = false;
        });

        // Enhanced feedback
        final userDelta = (statsAfter.totalUsers) - (statsBefore?.totalUsers ?? 0);
        final classDelta = (statsAfter.totalClassifications) - (statsBefore?.totalClassifications ?? 0);
        final pointsDelta = (statsAfter.totalPoints) - (statsBefore?.totalPoints ?? 0);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Synced! +$classDelta classifications, +$pointsDelta points, +$userDelta users',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  } catch (e) {
    WasteAppLogger.severe('❌ Error force syncing: $e');
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Sync failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
```

**Effort**: ~20 min  
**Risk**: Low (UI enhancement)  
**Verification**: Tap sync button → see delta message

---

## Validation & Verification

### Pre-Implementation Checklist

- [ ] No conflicting parallel work on community files
- [ ] Current tests pass: `flutter test`
- [ ] No breaking changes to data models

### Post-Implementation Checklist

- [ ] Flutter build succeeds: `flutter build apk`
- [ ] All new tests pass: `flutter test`
- [ ] Empty state appears when stats are zero
- [ ] Sync shows delta feedback
- [ ] Docs are accurate and linked
- [ ] No regressions in existing community tabs (feed, members)

### Manual Testing Scenarios

1. **First time user** (no classifications):
   - Open app → Community → Stats tab
   - **Expected**: Empty state message
   - **Actual**: _______________

2. **After one classification**:
   - Scan item → Community → Stats tab
   - **Expected**: Stats show 1 classification, 1 user, 10 points
   - **Actual**: _______________

3. **After sync**:
   - Add classifications locally, tap sync
   - **Expected**: Stats increase, delta message shows
   - **Actual**: _______________

4. **Multiple users** (if multi-user test available):
   - Two users add classifications each
   - **Expected**: Stats show 2 users, combined counts
   - **Actual**: _______________

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| UI state mismatch (loading vs empty) | Low | Medium | Tests on both states |
| Firestore read quota exceeded | Low | Medium | Monitor reads, add caching later |
| Stale stats on app start | Medium | Low | Document expected sync behavior |
| Test flakiness with fake Firestore | Medium | Low | Use `fake_cloud_firestore` package |

---

## Dependencies

- `fake_cloud_firestore` (already in pubspec.yaml for testing)
- No new external dependencies

---

## Timeline

| Phase | Task | Effort | Status |
|-------|------|--------|--------|
| 1 | Empty-state UI | 20 min | 📋 Planned |
| 2 | Integration test | 45 min | 📋 Planned |
| 3 | Architecture docs | 30 min | 📋 Planned |
| 4 | Sync feedback | 20 min | 📋 Planned |
| **Total** | | **115 min (~2 hrs)** | |

---

## Next Steps

1. Review this plan against actual codebase
2. Confirm no parallel work conflicts
3. Execute Phase 1–4 in order
4. Run full test suite and manual QA
5. Update issue #172 with completion evidence
