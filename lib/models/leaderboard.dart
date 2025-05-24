// Import the required models
import '../models/gamification.dart'; // For Achievement class

/// Types of leaderboards available in the app.
enum LeaderboardType {
  /// Global leaderboard across all users.
  global,
  /// Family-specific leaderboard.
  family,
  /// Weekly leaderboard (resets every week).
  weekly,
  /// Monthly leaderboard (resets every month).
  monthly,
  /// All-time leaderboard.
  allTime,
  /// Friends leaderboard (connected users).
  friends,
  /// Regional leaderboard (same geographic area).
  regional,
}

/// Time period for leaderboard filtering.
enum LeaderboardPeriod {
  /// Today's activity only.
  today,
  /// This week's activity.
  thisWeek,
  /// This month's activity.
  thisMonth,
  /// This year's activity.
  thisYear,
  /// All-time activity.
  allTime,
}

/// Types of rewards that can be given.
enum RewardType {
  /// Digital badge or achievement.
  badge,
  /// Bonus points.
  points,
  /// Physical prize or gift.
  physical,
  /// Premium features unlock.
  premium,
  /// Recognition/title.
  recognition,
}

/// Represents a single entry in a leaderboard.
class LeaderboardEntry {
  /// The user ID for this entry.
  final String userId;

  /// Display name of the user.
  final String displayName;

  /// Profile photo URL (if available).
  final String? photoUrl;

  /// Total points for this user.
  final int points;

  /// Current rank/position in the leaderboard.
  final int rank;

  /// Previous rank (for showing rank changes).
  final int? previousRank;

  /// Breakdown of points by waste category.
  final Map<String, int> categoryBreakdown;

  /// Recent achievements earned by this user.
  final List<Achievement> recentAchievements;

  /// Additional statistics for this user.
  final UserLeaderboardStats stats;

  /// Whether this entry represents the current user.
  final bool isCurrentUser;

  /// Family ID if this is a family leaderboard entry.
  final String? familyId;

  /// Family name if this is a family leaderboard entry.
  final String? familyName;

  LeaderboardEntry({
    required this.userId,
    required this.displayName,
    this.photoUrl,
    required this.points,
    required this.rank,
    this.previousRank,
    this.categoryBreakdown = const {},
    this.recentAchievements = const [],
    required this.stats,
    this.isCurrentUser = false,
    this.familyId,
    this.familyName,
  });

  /// Creates a copy of this LeaderboardEntry with the given fields replaced.
  LeaderboardEntry copyWith({
    String? userId,
    String? displayName,
    String? photoUrl,
    int? points,
    int? rank,
    int? previousRank,
    Map<String, int>? categoryBreakdown,
    List<Achievement>? recentAchievements,
    UserLeaderboardStats? stats,
    bool? isCurrentUser,
    String? familyId,
    String? familyName,
  }) {
    return LeaderboardEntry(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      points: points ?? this.points,
      rank: rank ?? this.rank,
      previousRank: previousRank ?? this.previousRank,
      categoryBreakdown: categoryBreakdown ?? this.categoryBreakdown,
      recentAchievements: recentAchievements ?? this.recentAchievements,
      stats: stats ?? this.stats,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
      familyId: familyId ?? this.familyId,
      familyName: familyName ?? this.familyName,
    );
  }

  /// Converts this LeaderboardEntry instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'points': points,
      'rank': rank,
      'previousRank': previousRank,
      'categoryBreakdown': categoryBreakdown,
      'recentAchievements': recentAchievements.map((a) => a.toJson()).toList(),
      'stats': stats.toJson(),
      'isCurrentUser': isCurrentUser,
      'familyId': familyId,
      'familyName': familyName,
    };
  }

  /// Creates a LeaderboardEntry instance from a JSON map.
  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      photoUrl: json['photoUrl'] as String?,
      points: json['points'] as int,
      rank: json['rank'] as int,
      previousRank: json['previousRank'] as int?,
      categoryBreakdown: Map<String, int>.from(json['categoryBreakdown'] as Map? ?? {}),
      recentAchievements: (json['recentAchievements'] as List<dynamic>?)
              ?.map((a) => Achievement.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
      stats: UserLeaderboardStats.fromJson(json['stats'] as Map<String, dynamic>),
      isCurrentUser: json['isCurrentUser'] as bool? ?? false,
      familyId: json['familyId'] as String?,
      familyName: json['familyName'] as String?,
    );
  }

  /// Gets the rank change compared to previous ranking.
  int? get rankChange {
    if (previousRank == null) return null;
    return previousRank! - rank; // Positive means improved rank
  }

  /// Gets the percentage of points in the top category.
  double get topCategoryPercentage {
    if (categoryBreakdown.isEmpty || points == 0) return 0.0;
    final maxPoints = categoryBreakdown.values.reduce((a, b) => a > b ? a : b);
    return maxPoints / points;
  }
}

/// Represents a complete leaderboard with multiple entries.
class Leaderboard {
  /// The type of this leaderboard.
  final LeaderboardType type;

  /// The time period this leaderboard covers.
  final LeaderboardPeriod period;

  /// List of entries in this leaderboard (ordered by rank).
  final List<LeaderboardEntry> entries;

  /// When this leaderboard was last updated.
  final DateTime lastUpdated;

  /// Metadata about this leaderboard.
  final LeaderboardMetadata metadata;

  /// The current user's entry (may not be in the top entries).
  final LeaderboardEntry? currentUserEntry;

  /// Total number of participants in this leaderboard.
  final int totalParticipants;

  /// Family ID if this is a family-specific leaderboard.
  final String? familyId;

  Leaderboard({
    required this.type,
    required this.period,
    required this.entries,
    required this.lastUpdated,
    required this.metadata,
    this.currentUserEntry,
    required this.totalParticipants,
    this.familyId,
  });

  /// Creates a copy of this Leaderboard with the given fields replaced.
  Leaderboard copyWith({
    LeaderboardType? type,
    LeaderboardPeriod? period,
    List<LeaderboardEntry>? entries,
    DateTime? lastUpdated,
    LeaderboardMetadata? metadata,
    LeaderboardEntry? currentUserEntry,
    int? totalParticipants,
    String? familyId,
  }) {
    return Leaderboard(
      type: type ?? this.type,
      period: period ?? this.period,
      entries: entries ?? this.entries,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      metadata: metadata ?? this.metadata,
      currentUserEntry: currentUserEntry ?? this.currentUserEntry,
      totalParticipants: totalParticipants ?? this.totalParticipants,
      familyId: familyId ?? this.familyId,
    );
  }

  /// Converts this Leaderboard instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'type': type.toString().split('.').last,
      'period': period.toString().split('.').last,
      'entries': entries.map((e) => e.toJson()).toList(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'metadata': metadata.toJson(),
      'currentUserEntry': currentUserEntry?.toJson(),
      'totalParticipants': totalParticipants,
      'familyId': familyId,
    };
  }

  /// Creates a Leaderboard instance from a JSON map.
  factory Leaderboard.fromJson(Map<String, dynamic> json) {
    return Leaderboard(
      type: LeaderboardType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => LeaderboardType.global,
      ),
      period: LeaderboardPeriod.values.firstWhere(
        (e) => e.toString().split('.').last == json['period'],
        orElse: () => LeaderboardPeriod.allTime,
      ),
      entries: (json['entries'] as List<dynamic>)
          .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      metadata: LeaderboardMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
      currentUserEntry: json['currentUserEntry'] != null
          ? LeaderboardEntry.fromJson(json['currentUserEntry'] as Map<String, dynamic>)
          : null,
      totalParticipants: json['totalParticipants'] as int,
      familyId: json['familyId'] as String?,
    );
  }

  /// Gets the top N entries from the leaderboard.
  List<LeaderboardEntry> getTopEntries(int count) {
    return entries.take(count).toList();
  }

  /// Finds an entry by user ID.
  LeaderboardEntry? getEntryByUserId(String userId) {
    try {
      return entries.firstWhere((entry) => entry.userId == userId);
    } catch (e) {
      return null;
    }
  }

  /// Gets entries within a specific rank range.
  List<LeaderboardEntry> getEntriesInRange(int startRank, int endRank) {
    return entries
        .where((entry) => entry.rank >= startRank && entry.rank <= endRank)
        .toList();
  }

  /// Gets the minimum score to be in the top N.
  int? getMinimumScoreForTopN(int n) {
    if (entries.length < n) return null;
    return entries[n - 1].points;
  }
}

/// Metadata about a leaderboard.
class LeaderboardMetadata {
  /// The title/name of this leaderboard.
  final String title;

  /// Description of the leaderboard.
  final String description;

  /// When this leaderboard period started.
  final DateTime periodStart;

  /// When this leaderboard period ends.
  final DateTime periodEnd;

  /// Whether this leaderboard is currently active.
  final bool isActive;

  /// Rewards/prizes for top performers.
  final List<LeaderboardReward> rewards;

  /// Minimum points required to appear on leaderboard.
  final int minimumPoints;

  /// Maximum number of entries to display.
  final int maxEntries;

  /// Whether to show detailed statistics.
  final bool showDetailedStats;

  LeaderboardMetadata({
    required this.title,
    required this.description,
    required this.periodStart,
    required this.periodEnd,
    this.isActive = true,
    this.rewards = const [],
    this.minimumPoints = 0,
    this.maxEntries = 100,
    this.showDetailedStats = true,
  });

  /// Converts this LeaderboardMetadata instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'periodStart': periodStart.toIso8601String(),
      'periodEnd': periodEnd.toIso8601String(),
      'isActive': isActive,
      'rewards': rewards.map((r) => r.toJson()).toList(),
      'minimumPoints': minimumPoints,
      'maxEntries': maxEntries,
      'showDetailedStats': showDetailedStats,
    };
  }

  /// Creates a LeaderboardMetadata instance from a JSON map.
  factory LeaderboardMetadata.fromJson(Map<String, dynamic> json) {
    return LeaderboardMetadata(
      title: json['title'] as String,
      description: json['description'] as String,
      periodStart: DateTime.parse(json['periodStart'] as String),
      periodEnd: DateTime.parse(json['periodEnd'] as String),
      isActive: json['isActive'] as bool? ?? true,
      rewards: (json['rewards'] as List<dynamic>?)
              ?.map((r) => LeaderboardReward.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
      minimumPoints: json['minimumPoints'] as int? ?? 0,
      maxEntries: json['maxEntries'] as int? ?? 100,
      showDetailedStats: json['showDetailedStats'] as bool? ?? true,
    );
  }

  /// Checks if the leaderboard period is currently active.
  bool get isCurrentlyActive {
    final now = DateTime.now();
    return isActive && 
           now.isAfter(periodStart) && 
           now.isBefore(periodEnd);
  }

  /// Gets the remaining time in the current period.
  Duration get timeRemaining {
    final now = DateTime.now();
    if (now.isAfter(periodEnd)) return Duration.zero;
    return periodEnd.difference(now);
  }
}

/// Statistics for a user on the leaderboard.
class UserLeaderboardStats {
  /// Total classifications made.
  final int totalClassifications;

  /// Current streak of consecutive days.
  final int currentStreak;

  /// Best streak achieved.
  final int bestStreak;

  /// Average points per classification.
  final double averagePointsPerClassification;

  /// Most active day of the week.
  final String mostActiveDay;

  /// Most classified category.
  final String topCategory;

  /// Percentage of correct classifications.
  final double accuracyPercentage;

  /// Total time spent in the app (in minutes).
  final int totalTimeSpent;

  UserLeaderboardStats({
    required this.totalClassifications,
    required this.currentStreak,
    required this.bestStreak,
    required this.averagePointsPerClassification,
    required this.mostActiveDay,
    required this.topCategory,
    required this.accuracyPercentage,
    required this.totalTimeSpent,
  });

  /// Converts this UserLeaderboardStats instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'totalClassifications': totalClassifications,
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
      'averagePointsPerClassification': averagePointsPerClassification,
      'mostActiveDay': mostActiveDay,
      'topCategory': topCategory,
      'accuracyPercentage': accuracyPercentage,
      'totalTimeSpent': totalTimeSpent,
    };
  }

  /// Creates a UserLeaderboardStats instance from a JSON map.
  factory UserLeaderboardStats.fromJson(Map<String, dynamic> json) {
    return UserLeaderboardStats(
      totalClassifications: json['totalClassifications'] as int,
      currentStreak: json['currentStreak'] as int,
      bestStreak: json['bestStreak'] as int,
      averagePointsPerClassification: (json['averagePointsPerClassification'] as num).toDouble(),
      mostActiveDay: json['mostActiveDay'] as String,
      topCategory: json['topCategory'] as String,
      accuracyPercentage: (json['accuracyPercentage'] as num).toDouble(),
      totalTimeSpent: json['totalTimeSpent'] as int,
    );
  }
}

/// Represents a reward for leaderboard performance.
class LeaderboardReward {
  /// The rank range this reward applies to (e.g., "1-3" for top 3).
  final String rankRange;

  /// Name of the reward.
  final String name;

  /// Description of the reward.
  final String description;

  /// Icon or image URL for the reward.
  final String? iconUrl;

  /// Type of reward (badge, points, physical prize, etc.).
  final RewardType type;

  /// Value of the reward (if applicable).
  final int? value;

  LeaderboardReward({
    required this.rankRange,
    required this.name,
    required this.description,
    this.iconUrl,
    required this.type,
    this.value,
  });

  /// Converts this LeaderboardReward instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'rankRange': rankRange,
      'name': name,
      'description': description,
      'iconUrl': iconUrl,
      'type': type.toString().split('.').last,
      'value': value,
    };
  }

  /// Creates a LeaderboardReward instance from a JSON map.
  factory LeaderboardReward.fromJson(Map<String, dynamic> json) {
    return LeaderboardReward(
      rankRange: json['rankRange'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      iconUrl: json['iconUrl'] as String?,
      type: RewardType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => RewardType.badge,
      ),
      value: json['value'] as int?,
    );
  }
}
