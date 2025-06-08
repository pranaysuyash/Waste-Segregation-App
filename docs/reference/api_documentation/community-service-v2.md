# Community Service API Documentation v2.0

**Service Version:** 2.0  
**Last Updated:** December 2024  
**Compatibility:** Flutter 3.32.2+  

## 📋 Overview

The Community Service manages social features, community feed, and user activity synchronization. Version 2.0 introduces real-time data sync capabilities and enhanced community statistics.

## 🔧 Core Methods

### Community Initialization

#### `initCommunity()`
Initializes the community service and creates default statistics.

```dart
Future<void> initCommunity() async
```

**Parameters:** None  
**Returns:** `Future<void>`  
**Throws:** `HiveError` if storage initialization fails

**Usage:**
```dart
final communityService = CommunityService();
await communityService.initCommunity();
```

---

### Feed Management

#### `addFeedItem(CommunityFeedItem item)`
Adds a new activity to the community feed.

```dart
Future<void> addFeedItem(CommunityFeedItem item) async
```

**Parameters:**
- `item` (`CommunityFeedItem`): The feed item to add

**Returns:** `Future<void>`  
**Side Effects:** 
- Updates community statistics
- Maintains feed size limit (100 items)

**Example:**
```dart
final feedItem = CommunityFeedItem(
  id: 'classification_${DateTime.now().millisecondsSinceEpoch}',
  userId: userProfile.id,
  userName: userProfile.displayName ?? 'Anonymous',
  activityType: CommunityActivityType.classification,
  title: 'Classified Plastic Bottle',
  description: 'Identified item as recyclable plastic',
  timestamp: DateTime.now(),
  points: 10,
  metadata: {
    'category': 'Dry Waste',
    'subcategory': 'Plastic',
  },
);

await communityService.addFeedItem(feedItem);
```

#### `getFeedItems({int limit = 20})`
Retrieves community feed items with optional limit.

```dart
Future<List<CommunityFeedItem>> getFeedItems({int limit = 20}) async
```

**Parameters:**
- `limit` (`int`, optional): Maximum number of items to return (default: 20)

**Returns:** `Future<List<CommunityFeedItem>>`

---

### Statistics & Analytics

#### `getCommunityStats()`
Calculates and returns comprehensive community statistics.

```dart
Future<CommunityStats> getCommunityStats() async
```

**Returns:** `Future<CommunityStats>`

**Calculated Metrics:**
- Total users (excluding sample data)
- Total classifications and achievements
- Active users today and this week
- Category breakdown
- Top contributors
- Environmental impact metrics

**Example Response:**
```dart
CommunityStats(
  totalUsers: 42,
  totalClassifications: 1337,
  totalAchievements: 89,
  totalPoints: 15420,
  activeToday: 8,
  activeUsers: 42,
  weeklyClassifications: 156,
  categoryBreakdown: {
    'Dry Waste': 892,
    'Wet Waste': 445,
    'Hazardous Waste': 23,
  },
  averagePointsPerUser: 367.1,
  lastUpdated: DateTime.now(),
)
```

---

### Data Synchronization (New in v2.0)

#### `syncWithUserData(List<WasteClassification> classifications, UserProfile? userProfile)`
Synchronizes user's classification history with the community feed.

```dart
Future<void> syncWithUserData(
  List<WasteClassification> classifications, 
  UserProfile? userProfile
) async
```

**Parameters:**
- `classifications` (`List<WasteClassification>`): User's classification history
- `userProfile` (`UserProfile?`): User's profile information

**Returns:** `Future<void>`

**Behavior:**
- Only adds new classifications not already in feed
- Maintains feed size limit
- Updates community statistics
- Respects user anonymity preferences

**Usage:**
```dart
final classifications = await storageService.getAllClassifications();
final userProfile = await storageService.getCurrentUserProfile();

await communityService.syncWithUserData(classifications, userProfile);
```

#### `clearSampleData()`
Removes all sample/test data from the community feed.

```dart
Future<void> clearSampleData() async
```

**Returns:** `Future<void>`

**Removes:**
- Items with `userId` starting with `'sample_user_'`
- Items with `metadata['isSample'] == true`
- Development test data

---

### Activity Recording

#### `recordClassification(String category, String subcategory, int points)`
Records a classification activity in the community feed.

```dart
Future<void> recordClassification(
  String category, 
  String subcategory, 
  int points
) async
```

**Parameters:**
- `category` (`String`): Waste category
- `subcategory` (`String`): Waste subcategory
- `points` (`int`): Points earned

**Auto-generates:**
- Unique item ID
- Timestamp
- User identification
- Activity metadata

#### `recordStreak(int streakDays, int points)`
Records a daily streak achievement.

```dart
Future<void> recordStreak(int streakDays, int points) async
```

**Parameters:**
- `streakDays` (`int`): Number of consecutive days
- `points` (`int`): Points earned for streak

#### `recordAchievement(String title, int points)`
Records an achievement unlock.

```dart
Future<void> recordAchievement(String title, int points) async
```

**Parameters:**
- `title` (`String`): Achievement title
- `points` (`int`): Points earned

---

## 📊 Data Models

### CommunityFeedItem

```dart
class CommunityFeedItem {
  final String id;
  final String userId;
  final String userName;
  final CommunityActivityType activityType;
  final String title;
  final String description;
  final DateTime timestamp;
  final int points;
  final bool isAnonymous;
  final Map<String, dynamic> metadata;
}
```

### CommunityStats

```dart
class CommunityStats {
  final int totalUsers;
  final int totalClassifications;
  final int totalAchievements;
  final int totalPoints;
  final int activeToday;
  final int activeUsers;
  final int weeklyClassifications;
  final int weeklyActiveUsers;
  final Map<String, int> categoryBreakdown;
  final double averagePointsPerUser;
  final List<Map<String, dynamic>> topContributors;
  final int anonymousContributions;
  final DateTime lastUpdated;
}
```

### CommunityActivityType

```dart
enum CommunityActivityType {
  classification,
  achievement,
  streak,
  milestone,
  challenge,
}
```

---

## 🔄 Data Flow Integration

### With DataSyncProvider

```dart
// DataSyncProvider integration
class DataSyncProvider extends ChangeNotifier {
  Future<void> _syncCommunityData() async {
    await _communityService.initCommunity();
    await _communityService.clearSampleData();
    
    if (_cachedClassifications != null) {
      final userProfile = await _storageService.getCurrentUserProfile();
      await _communityService.syncWithUserData(_cachedClassifications!, userProfile);
    }
    
    _cachedCommunityFeed = await _communityService.getFeedItems();
  }
}
```

### With Classification Flow

```dart
// Automatic feed update on new classification
Future<void> handleNewClassification(WasteClassification classification) async {
  // 1. Save classification
  await storageService.saveClassification(classification);
  
  // 2. Update gamification
  await gamificationService.processClassification(classification);
  
  // 3. Add to community feed
  await communityService.recordClassification(
    classification.category,
    classification.subcategory ?? '',
    classification.pointsAwarded ?? 10,
  );
  
  // 4. Trigger sync
  await dataSyncProvider.forceSyncAllData();
}
```

---

## 🛡️ Privacy & Security

### User Anonymity

The service respects user privacy preferences:

```dart
// Privacy-aware feed item creation
final feedItem = CommunityFeedItem(
  // ...
  userName: userProfile.preferences?['isAnonymous'] == true 
      ? 'Anonymous User' 
      : userProfile.displayName ?? 'User',
  isAnonymous: userProfile.preferences?['isAnonymous'] == true,
  // ...
);
```

### Data Filtering

- **Sample Data Removal**: Automatic filtering of test data
- **User Consent**: Respects sharing preferences
- **Data Retention**: 100-item feed limit for performance

---

## ⚡ Performance Considerations

### Caching Strategy

```dart
// Efficient caching with TTL
class CommunityService {
  CommunityStats? _cachedStats;
  DateTime? _lastStatsUpdate;
  
  Future<CommunityStats> getCommunityStats() async {
    final now = DateTime.now();
    if (_cachedStats != null && 
        _lastStatsUpdate != null &&
        now.difference(_lastStatsUpdate!).inMinutes < 5) {
      return _cachedStats!;
    }
    
    // Recalculate stats
    _cachedStats = await _calculateStats();
    _lastStatsUpdate = now;
    return _cachedStats!;
  }
}
```

### Batch Operations

```dart
// Efficient batch sync
Future<void> syncWithUserData(
  List<WasteClassification> classifications, 
  UserProfile? userProfile
) async {
  // Process in batches to avoid memory issues
  const batchSize = 50;
  for (int i = 0; i < classifications.length; i += batchSize) {
    final batch = classifications.skip(i).take(batchSize);
    await _processBatch(batch, userProfile);
  }
}
```

---

## 🧪 Testing

### Unit Tests

```dart
// Example test coverage
void main() {
  group('CommunityService Tests', () {
    test('should sync user data correctly', () async {
      final service = CommunityService();
      await service.initCommunity();
      
      final classifications = [mockClassification1, mockClassification2];
      final userProfile = mockUserProfile;
      
      await service.syncWithUserData(classifications, userProfile);
      
      final feed = await service.getFeedItems();
      expect(feed.length, equals(2));
      expect(feed.first.userId, equals(userProfile.id));
    });
  });
}
```

### Integration Tests

```dart
// DataSync integration test
testWidgets('should maintain data consistency across sync', (tester) async {
  final app = TestApp();
  await tester.pumpWidget(app);
  
  // Trigger classification
  await tester.tap(find.byKey(Key('classify_button')));
  await tester.pumpAndSettle();
  
  // Verify community feed update
  final communityStats = await app.communityService.getCommunityStats();
  expect(communityStats.totalClassifications, greaterThan(0));
});
```

---

## 📈 Monitoring & Analytics

### Performance Metrics

- **Sync Duration**: Target < 500ms for 100 classifications
- **Memory Usage**: < 10MB for feed operations
- **Storage Size**: Bounded to prevent unlimited growth

### Error Tracking

```dart
// Error handling with telemetry
Future<void> addFeedItem(CommunityFeedItem item) async {
  try {
    // Implementation
  } catch (e, stackTrace) {
    debugPrint('❌ Error adding community feed item: $e');
    // Log to analytics service
    await AnalyticsService.logError('community_feed_error', e, stackTrace);
  }
}
```

---

**API Version:** 2.0  
**Backward Compatibility:** Maintained with v1.x  
**Breaking Changes:** None  
**Deprecations:** `getStats()` (use `getCommunityStats()`)  

---

**Maintainers:** Development Team  
**Review Schedule:** Quarterly  
**Support:** Create GitHub issue for API questions 