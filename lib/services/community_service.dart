import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/community_feed.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import '../models/user_profile.dart';
import '../models/gamification.dart';
import 'package:waste_segregation_app/utils/waste_app_logger.dart';
import 'firestore_schema_registry.dart';

/// Service for managing community feed and social features
class CommunityService {
  CommunityService({FirebaseFirestore? firestore}) : _firestore = firestore;

  final FirebaseFirestore? _firestore;
  FirebaseFirestore get _firestoreOrNull =>
      _firestore ?? FirebaseFirestore.instance;

  static const String _feedCollection = FirestoreCollections.communityFeed;
  static const String _statsCollection = FirestoreCollections.communityStats;
  static const String _mainStatsDoc = 'main';

  static const int _canonicalFeedLimit = 10000;
  static const Duration _statsFreshnessWindow = Duration(minutes: 15);

  /// Initialize with Firestore
  Future<void> initCommunity() async {
    // No more Hive initialization needed
    // The stats document will be created on-the-fly if it doesn't exist
    WasteAppLogger.info('CommunityService initialized with Firestore.');
  }

  /// Add a feed item to Firestore
  Future<void> addFeedItem(CommunityFeedItem item) async {
    try {
      final data = item.toJson();
      // Convert timestamp from ISO 8601 String to Firestore Timestamp
      // Model stores as String for Hive compatibility; Firestore rules require Timestamp
      data['timestamp'] = FieldValue.serverTimestamp();

      // Validate required fields before writing (catches schema drift early)
      final errors = FirestoreSchemaValidator.validateRequiredFields(
        FirestoreCollections.communityFeed,
        data,
      );
      if (errors.isNotEmpty) {
        WasteAppLogger.warning(
          'Community feed schema validation warnings: $errors',
        );
        // Continue writing - validation is advisory, not blocking
      }

      // Apply privacy guard for anonymous posts
      if (item.isAnonymous) {
        data['userName'] = 'Anonymous User';
        data.remove('userAvatar');
      }

      await _firestoreOrNull.collection(_feedCollection).add(data);
      await _updateCommunityStatsOnActivity(item);
      WasteAppLogger.info(
        '🌍 Firestore: Community feed item added: ${item.title}',
      );
    } catch (e) {
      WasteAppLogger.severe('❌ Error adding Firestore feed item: $e');
    }
  }

  /// Get feed items from Firestore
  Future<List<CommunityFeedItem>> getFeedItems({int limit = 50}) async {
    try {
      final snapshot = await _firestoreOrNull
          .collection(_feedCollection)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => CommunityFeedItem.fromJson(doc.data()))
          .toList();
    } catch (e) {
      WasteAppLogger.severe('❌ Error getting Firestore feed: $e');
      return [];
    }
  }

  Future<List<CommunityFeedItem>> _getUserFeedItemsByType(
    String userId,
    String activityType,
  ) async {
    try {
      final snapshot = await _firestoreOrNull
          .collection(_feedCollection)
          .where('userId', isEqualTo: userId)
          .where('activityType', isEqualTo: activityType)
          .get();

      return snapshot.docs
          .map((doc) => CommunityFeedItem.fromJson(doc.data()))
          .toList();
    } catch (e) {
      WasteAppLogger.severe(
        '❌ Error getting user feed items for $activityType: $e',
      );
      return [];
    }
  }

  /// Get community stats for UI consumption.
  ///
  /// Defaults to using the persisted `community_stats/main` doc when available
  /// and fresh. Falls back to full-feed recomputation when missing
  /// or explicitly requested. If stale, it returns cached stats immediately and
  /// refreshes in the background (best-effort) so UI stays fast.
  Future<CommunityStats> getStats({bool forceRecompute = false}) async {
    CommunityStats? storedStats;
    try {
      storedStats = await getStoredCommunityStats();

      if (storedStats != null &&
          !_isStatsDocumentFresh(storedStats.lastUpdated) &&
          !forceRecompute) {
        unawaited(_recomputeAndWriteStats(
          reason: 'background_stale_refresh',
        ));
      }

      if (!forceRecompute &&
          storedStats != null &&
          _isStatsDocumentFresh(storedStats.lastUpdated)) {
        return storedStats;
      }

      if (storedStats == null) {
        return await _recomputeAndWriteStats(reason: 'recompute');
      }

      if (!forceRecompute) {
        return storedStats;
      }

      return await _recomputeAndWriteStats(reason: 'recompute');
    } catch (e) {
      WasteAppLogger.severe('❌ Error calculating community stats: $e');
      if (storedStats != null) {
        return storedStats;
      }

      return const CommunityStats(
        totalUsers: 0,
        totalClassifications: 0,
        totalPoints: 0,
      );
    }
  }

  /// Optional debug/admin consistency check: recompute from feed vs stored community stats doc
  Future<CommunityStatsConsistencyReport> reconcileCommunityStats({
    bool repairDrift = false,
    bool logDrift = true,
    bool runDriftCheck = false,
  }) async {
    final storedStats = await getStoredCommunityStats();
    if (!runDriftCheck) {
      if (storedStats != null) {
        return CommunityStatsConsistencyReport(
          canonicalStats: storedStats,
          storedStats: storedStats,
          discrepancies: const [],
          isInSync: true,
          repaired: false,
          repairAttempted: false,
        );
      }

      return CommunityStatsConsistencyReport(
        canonicalStats: const CommunityStats(
          totalUsers: 0,
          totalClassifications: 0,
          totalPoints: 0,
        ),
        storedStats: null,
        discrepancies: const [],
        isInSync: true,
        repaired: false,
        repairAttempted: false,
      );
    }

    final computedStats = await getStats(forceRecompute: true);

    final discrepancies = findCommunityStatsDiscrepancies(
      computedStats: computedStats,
      storedStats: storedStats,
    );

    final isInSync = discrepancies.isEmpty;
    bool repaired = false;

    if (!isInSync && repairDrift && kDebugMode) {
      await _writeCommunityStats(computedStats, reason: 'reconcile');
      repaired = true;
    }

    if (!isInSync && logDrift) {
      for (final mismatch in discrepancies) {
        WasteAppLogger.warning(
          'Community stats drift: ${mismatch.field} (computed: ${mismatch.computedValue}, stored: ${mismatch.storedValue})',
        );
      }
    }

    return CommunityStatsConsistencyReport(
      canonicalStats: computedStats,
      storedStats: storedStats,
      discrepancies: discrepancies,
      isInSync: isInSync,
      repaired: repaired,
      repairAttempted: repairDrift,
    );
  }

  Future<CommunityStats> getStatsFromFeed() async {
    final feedItems = await getFeedItems(limit: _canonicalFeedLimit);

    if (feedItems.isEmpty) {
      return const CommunityStats(
        totalUsers: 0,
        totalClassifications: 0,
        totalPoints: 0,
      );
    }

    return aggregateStatsFromFeedItems(feedItems);
  }

  Future<CommunityStats> _recomputeAndWriteStats({
    required String reason,
  }) async {
    final recomputedStats = await getStatsFromFeed();
    await _writeCommunityStats(
      recomputedStats,
      reason: reason,
    );
    return recomputedStats;
  }

  bool _isStatsDocumentFresh(DateTime? lastUpdated) {
    if (lastUpdated == null) return false;

    return DateTime.now().difference(lastUpdated) <= _statsFreshnessWindow;
  }

  /// Get the persisted `community_stats/main` document when present.
  Future<CommunityStats?> getStoredCommunityStats() async {
    try {
      final doc = await _firestoreOrNull
          .collection(_statsCollection)
          .doc(_mainStatsDoc)
          .get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      final data = doc.data()!;
      return CommunityStats(
        totalUsers: _coerceIntValue(data['totalUsers']),
        totalClassifications: _coerceIntValue(data['totalClassifications']),
        totalPoints: _coerceIntValue(data['totalPoints']),
        categoryBreakdown: _coerceCategoryBreakdown(data['categoryBreakdown']),
        lastUpdated: _parseDateTime(data['lastUpdated']),
      );
    } catch (e) {
      WasteAppLogger.severe('❌ Error loading stored community stats doc: $e');
      return null;
    }
  }

  // Transactionally update stats
  Future<void> _updateCommunityStatsOnActivity(CommunityFeedItem item) async {
    final statsRef =
        _firestoreOrNull.collection(_statsCollection).doc(_mainStatsDoc);

    await _firestoreOrNull.runTransaction((transaction) async {
      final snapshot = await transaction.get(statsRef);

      if (!snapshot.exists) {
        transaction.set(statsRef, {
          'totalClassifications':
              item.activityType == CommunityActivityType.classification ? 1 : 0,
          'totalPoints': item.points,
          'categoryBreakdown': {
            if (item.metadata['category'] != null) item.metadata['category']: 1,
          },
          'lastUpdated': FieldValue.serverTimestamp(),
          'totalUsers': 1,
        });
      } else {
        final classificationIncrement =
            item.activityType == CommunityActivityType.classification ? 1 : 0;
        // Safe type extraction
        final categoryValue = item.metadata['category'];
        final categoryKey = categoryValue is String ? categoryValue : null;

        transaction.update(statsRef, {
          'totalClassifications': FieldValue.increment(classificationIncrement),
          'totalPoints': FieldValue.increment(item.points),
          if (categoryKey != null)
            'categoryBreakdown.$categoryKey': FieldValue.increment(1),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  /// Record classification - now writes to Firestore
  Future<void> recordClassification(
    WasteClassification classification,
    UserProfile user,
  ) async {
    // Use consistent points from PointsEngine standard (10 per classification)
    const standardClassificationPoints = 10;

    final item = CommunityFeedItem(
      id: classification.id,
      userId: user.id,
      userName: user.displayName ?? 'Anonymous',
      activityType: CommunityActivityType.classification,
      title: 'New Scan!',
      description:
          'Scanned a ${classification.itemName} (${classification.category})',
      timestamp: classification.timestamp,
      points: classification.pointsAwarded ?? standardClassificationPoints,
      metadata: {'category': classification.category},
    );
    await addFeedItem(item);
  }

  /// Record achievement - now writes to Firestore
  Future<void> recordAchievement(
    Achievement achievement,
    UserProfile user,
  ) async {
    final item = CommunityFeedItem(
      id: 'ach_${user.id}_${achievement.id}',
      userId: user.id,
      userName: user.displayName ?? 'Anonymous',
      activityType: CommunityActivityType.achievement,
      title: 'Achievement Unlocked!',
      description: 'Unlocked "${achievement.title}"',
      timestamp: DateTime.now(),
      points: achievement.pointsReward,
      metadata: {'achievementId': achievement.id},
    );
    await addFeedItem(item);
  }

  /// Record a streak event - now writes to Firestore
  Future<void> recordStreak(int streakDays, UserProfile user) async {
    final item = CommunityFeedItem(
      id: 'str_${user.id}_${DateTime.now().millisecondsSinceEpoch}',
      userId: user.id,
      userName: user.displayName ?? 'Anonymous',
      activityType: CommunityActivityType.streak,
      title: 'Kept the fire going!',
      description: 'Maintained a $streakDays-day streak!',
      timestamp: DateTime.now(),
      points: 5, // Standard points for a streak
      metadata: {'streakDays': streakDays},
    );
    await addFeedItem(item);
  }

  /// Sync user data to community feed - backfill historical data
  Future<void> syncWithUserData(
    List<WasteClassification> classifications,
    UserProfile? user,
  ) async {
    if (user == null) return;

    WasteAppLogger.info(
      '🔄 SYNC: Starting community feed sync for user ${user.id}',
    );
    WasteAppLogger.info(
      '🔄 SYNC: Found ${classifications.length} classifications to potentially sync',
    );

    try {
      // Use canonical dedupe path to avoid backfill double-counts.
      final existingClassificationItems = await _getUserFeedItemsByType(
        user.id,
        CommunityActivityType.classification.name,
      );
      final existingAchievementItems = await _getUserFeedItemsByType(
        user.id,
        CommunityActivityType.achievement.name,
      );

      final existingClassificationIds =
          extractClassificationIdsFromFeed(existingClassificationItems);
      final existingAchievementIds =
          extractAchievementIdsFromFeed(existingAchievementItems);

      final dedupedClassifications = dedupeClassificationsById(classifications);
      final classificationsToSync = dedupedClassifications
          .where(
            (classification) =>
                !existingClassificationIds.contains(classification.id),
          )
          .toList();

      WasteAppLogger.info(
        '🔄 SYNC: Found ${existingClassificationIds.length} existing classification feed items',
      );

      // Backfill missing classifications
      var syncedCount = 0;
      for (final classification in classificationsToSync) {
        await recordClassification(classification, user);
        syncedCount++;

        // Add small delay to avoid overwhelming Firestore
        if (syncedCount % 10 == 0) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }

      WasteAppLogger.info(
        '🔄 SYNC: Backfilled $syncedCount classification activities to community feed',
      );

      // Sync achievements if user has gamification profile
      if (user.gamificationProfile != null) {
        final achievements = user.gamificationProfile!.achievements;
        final unlockedAchievements =
            achievements.where((a) => a.isEarned).toList();
        final seenAchievementIds = <String>{};

        var achievementsSynced = 0;
        for (final achievement in unlockedAchievements) {
          if (!seenAchievementIds.add(achievement.id)) {
            continue;
          }
          if (!existingAchievementIds.contains(achievement.id)) {
            await recordAchievement(achievement, user);
            achievementsSynced++;
          }
        }

        WasteAppLogger.info(
          '🔄 SYNC: Backfilled $achievementsSynced achievement activities to community feed',
        );
      }

      WasteAppLogger.info('✅ SYNC: Community feed sync completed successfully');

      await reconcileCommunityStats(
        repairDrift: kDebugMode,
        runDriftCheck: true,
      );
    } catch (e) {
      WasteAppLogger.severe('❌ SYNC ERROR: Failed to sync community feed: $e');
    }
  }

  static CommunityStats aggregateStatsFromFeedItems(
    List<CommunityFeedItem> feedItems,
  ) {
    var totalClassifications = 0;
    var totalPoints = 0;
    final categoryBreakdown = <String, int>{};
    final userIds = <String>{};

    for (final item in feedItems) {
      userIds.add(item.userId);
      totalPoints += item.points;

      if (item.activityType == CommunityActivityType.classification) {
        totalClassifications++;
        final categoryValue = item.metadata['category'];
        final category = categoryValue is String ? categoryValue : null;
        if (category != null && category.isNotEmpty) {
          categoryBreakdown.update(
            category,
            (value) => value + 1,
            ifAbsent: () => 1,
          );
        }
      }
    }

    return CommunityStats(
      totalUsers: userIds.length,
      totalClassifications: totalClassifications,
      totalPoints: totalPoints,
      categoryBreakdown: categoryBreakdown,
      lastUpdated: DateTime.now(),
    );
  }

  static List<WasteClassification> dedupeClassificationsById(
    List<WasteClassification> items,
  ) {
    final seen = <String>{};
    final deduped = <WasteClassification>[];
    for (final item in items) {
      if (item.id.isEmpty) continue;
      if (!seen.add(item.id)) continue;
      deduped.add(item);
    }
    return deduped;
  }

  static Set<String> extractClassificationIdsFromFeed(
    List<CommunityFeedItem> feedItems,
  ) {
    return feedItems
        .where(
          (item) =>
              item.activityType == CommunityActivityType.classification &&
              item.id.isNotEmpty,
        )
        .map((item) => item.id)
        .toSet();
  }

  static Set<String> extractAchievementIdsFromFeed(
    List<CommunityFeedItem> feedItems,
  ) {
    final ids = <String>{};
    for (final item in feedItems) {
      if (item.activityType == CommunityActivityType.achievement) {
        final achievementIdValue = item.metadata['achievementId'];
        if (achievementIdValue is String && achievementIdValue.isNotEmpty) {
          ids.add(achievementIdValue);
        }
      }
    }
    return ids;
  }

  static List<CommunityStatsDiscrepancy> findCommunityStatsDiscrepancies({
    required CommunityStats computedStats,
    required CommunityStats? storedStats,
  }) {
    if (storedStats == null) {
      return [
        const CommunityStatsDiscrepancy(
          field: 'storedStats',
          computedValue: 0,
          storedValue: -1,
        ),
      ];
    }

    final discrepancies = <CommunityStatsDiscrepancy>[];
    if (computedStats.totalUsers != storedStats.totalUsers) {
      discrepancies.add(
        CommunityStatsDiscrepancy(
          field: 'totalUsers',
          computedValue: computedStats.totalUsers,
          storedValue: storedStats.totalUsers,
        ),
      );
    }
    if (computedStats.totalClassifications !=
        storedStats.totalClassifications) {
      discrepancies.add(
        CommunityStatsDiscrepancy(
          field: 'totalClassifications',
          computedValue: computedStats.totalClassifications,
          storedValue: storedStats.totalClassifications,
        ),
      );
    }
    if (computedStats.totalPoints != storedStats.totalPoints) {
      discrepancies.add(
        CommunityStatsDiscrepancy(
          field: 'totalPoints',
          computedValue: computedStats.totalPoints,
          storedValue: storedStats.totalPoints,
        ),
      );
    }

    final allCategoryKeys = <String>{
      ...computedStats.categoryBreakdown.keys,
      ...storedStats.categoryBreakdown.keys,
    };

    for (final category in allCategoryKeys) {
      final computedValue = computedStats.categoryBreakdown[category] ?? 0;
      final storedValue = storedStats.categoryBreakdown[category] ?? 0;
      if (computedValue != storedValue) {
        discrepancies.add(
          CommunityStatsDiscrepancy(
            field: 'category.$category',
            computedValue: computedValue,
            storedValue: storedValue,
          ),
        );
      }
    }

    return discrepancies;
  }

  static int _coerceIntValue(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static Map<String, int> _coerceCategoryBreakdown(dynamic value) {
    if (value is! Map) return const {};

    final categoryBreakdown = <String, int>{};
    for (final entry in value.entries) {
      final key = entry.key;
      if (key is String && key.isNotEmpty) {
        categoryBreakdown[key] = _coerceIntValue(entry.value);
      }
    }

    return categoryBreakdown;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  Future<void> _writeCommunityStats(
    CommunityStats stats, {
    required String reason,
  }) async {
    await _firestoreOrNull.collection(_statsCollection).doc(_mainStatsDoc).set({
      'totalUsers': stats.totalUsers,
      'totalClassifications': stats.totalClassifications,
      'totalPoints': stats.totalPoints,
      'categoryBreakdown': stats.categoryBreakdown,
      'lastUpdated': FieldValue.serverTimestamp(),
      'reconciledBy': reason,
    }, SetOptions(merge: true));

    WasteAppLogger.info('✅ Community stats document reconciled');
  }
}

class CommunityStatsConsistencyReport {
  const CommunityStatsConsistencyReport({
    required this.canonicalStats,
    required this.storedStats,
    required this.discrepancies,
    required this.isInSync,
    required this.repaired,
    required this.repairAttempted,
  });

  final CommunityStats canonicalStats;
  final CommunityStats? storedStats;
  final List<CommunityStatsDiscrepancy> discrepancies;
  final bool isInSync;
  final bool repaired;
  final bool repairAttempted;
}

class CommunityStatsDiscrepancy {
  const CommunityStatsDiscrepancy({
    required this.field,
    required this.computedValue,
    required this.storedValue,
  });

  final String field;
  final int computedValue;
  final int storedValue;

  int get delta => computedValue - storedValue;
}
