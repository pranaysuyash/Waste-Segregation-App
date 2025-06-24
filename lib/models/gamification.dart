import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:hive/hive.dart';

part 'gamification.g.dart';

/// Custom TypeAdapter for Flutter Color class
class ColorAdapter extends TypeAdapter<Color> {
  @override
  final int typeId = 15;

  @override
  Color read(BinaryReader reader) {
    return Color(reader.readUint32());
  }

  @override
  void write(BinaryWriter writer, Color obj) {
    // Use proper color serialization without deprecated methods
    final alpha = (obj.a * 255).round();
    final red = (obj.r * 255).round();
    final green = (obj.g * 255).round();
    final blue = (obj.b * 255).round();
    writer.writeUint32((alpha << 24) | (red << 16) | (green << 8) | blue);
  }
}

/// Represents the types of achievements available in the app
@HiveType(typeId: 5)
enum AchievementType {
  // Category-based achievements
  @HiveField(0)
  wasteIdentified,      // Identify waste items
  @HiveField(1)
  categoriesIdentified, // Identify different categories
  @HiveField(2)
  streakMaintained,     // Maintain a usage streak
  @HiveField(3)
  challengesCompleted,  // Complete challenges
  @HiveField(4)
  perfectWeek,          // Use app every day for a week
  @HiveField(5)
  knowledgeMaster,      // Complete educational content
  @HiveField(6)
  quizCompleted,        // Complete quizzes
  @HiveField(7)
  specialItem,          // Identify special or rare items
  @HiveField(8)
  communityContribution, // Contribute to community challenges
  @HiveField(9)
  metaAchievement,      // Achievements for earning other achievements
  @HiveField(10)
  specialEvent,         // Limited-time or event-based achievements
  @HiveField(11)
  userGoal,             // User-defined goal achievements
  @HiveField(12)
  collectionMilestone,  // Milestone in waste type collection
  @HiveField(13)
  firstClassification,
  @HiveField(14)
  weekStreak,
  @HiveField(15)
  monthStreak,
  @HiveField(16)
  recyclingExpert,
  @HiveField(17)
  compostMaster,
  @HiveField(18)
  ecoWarrior,
  @HiveField(19)
  familyTeamwork,
  @HiveField(20)
  helpfulMember,
  @HiveField(21)
  educationalContent,
}

/// Represents the tiers of achievements (increasing difficulty/rarity)
@HiveType(typeId: 6)
enum AchievementTier {
  @HiveField(0)
  bronze,
  @HiveField(1)
  silver,
  @HiveField(2)
  gold,
  @HiveField(3)
  platinum
}

/// Represents the claim status of an achievement
@HiveType(typeId: 7)
enum ClaimStatus {
  @HiveField(0)
  claimed,      // User has claimed the reward
  @HiveField(1)
  unclaimed,    // User is eligible but hasn't claimed the reward
  @HiveField(2)
  ineligible    // User is not yet eligible to claim
}

/// Represents a badge or trophy that can be earned
@HiveType(typeId: 8)
class Achievement {   // For meta-achievements

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.threshold,
    required this.iconName,
    required this.color,
    this.isSecret = false,
    this.earnedOn,
    this.progress = 0.0,
    this.tier = AchievementTier.bronze,
    this.achievementFamilyId,
    this.unlocksAtLevel,
    this.claimStatus = ClaimStatus.ineligible,
    this.metadata = const {},
    this.pointsReward = 50,
    this.relatedAchievementIds = const [],
    this.clues = const [],
  });
  
  // For deserialization
  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      type: AchievementType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => AchievementType.wasteIdentified,
      ),
      threshold: json['threshold'],
      iconName: json['iconName'],
      color: Color(json['color']),
      isSecret: json['isSecret'] ?? false,
      earnedOn: json['earnedOn'] != null ? DateTime.parse(json['earnedOn']) : null,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      tier: json['tier'] != null 
          ? AchievementTier.values.firstWhere(
              (e) => e.toString() == json['tier'],
              orElse: () => AchievementTier.bronze,
            )
          : AchievementTier.bronze,
      achievementFamilyId: json['achievementFamilyId'],
      unlocksAtLevel: json['unlocksAtLevel'],
      claimStatus: json['claimStatus'] != null
          ? ClaimStatus.values.firstWhere(
              (e) => e.toString() == json['claimStatus'],
              orElse: () => ClaimStatus.ineligible,
            )
          : ClaimStatus.ineligible,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : {},
      pointsReward: json['pointsReward'] ?? 50,
      relatedAchievementIds: json['relatedAchievementIds'] != null
          ? List<String>.from(json['relatedAchievementIds'])
          : [],
      clues: json['clues'] != null ? List<String>.from(json['clues']) : const [],
    );
  }
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String description;
  @HiveField(3)
  final AchievementType type;
  @HiveField(4)
  final int threshold;  // Number required to earn this achievement
  @HiveField(5)
  final String iconName;
  @HiveField(6)
  final Color color;
  @HiveField(7)
  final bool isSecret;  // Whether this is a hidden achievement
  @HiveField(8)
  final DateTime? earnedOn;
  @HiveField(9)
  final double progress; // Progress from 0.0 to 1.0
  
  // New properties for enhanced gamification
  @HiveField(10)
  final AchievementTier tier;                 // Bronze, Silver, Gold, Platinum
  @HiveField(11)
  final String? achievementFamilyId;          // Groups related tiered achievements
  @HiveField(12)
  final int? unlocksAtLevel;                  // Level required to unlock this achievement
  @HiveField(13)
  final ClaimStatus claimStatus;              // Whether the achievement reward is claimed
  @HiveField(14)
  final Map<String, dynamic> metadata;        // Additional achievement-specific data
  @HiveField(15)
  final int pointsReward;                     // Points earned when achievement is completed
  @HiveField(16)
  final List<String> relatedAchievementIds;
  @HiveField(17)
  final List<String> clues;
  
  bool get isEarned => earnedOn != null;
  
  bool get isClaimable => isEarned && claimStatus == ClaimStatus.unclaimed;
  
  bool get isLocked => unlocksAtLevel != null && unlocksAtLevel! > 0;
  
  // Get tier-specific text color for visual distinction
  Color getTierColor() {
    switch (tier) {
      case AchievementTier.bronze:
        return const Color(0xFFCD7F32); // Bronze
      case AchievementTier.silver:
        return const Color(0xFF8C8C8C); // Darker Silver for better contrast
      case AchievementTier.gold:
        return const Color(0xFFDAA520); // Darker Gold for better contrast
      case AchievementTier.platinum:
        return const Color(0xFF71797E); // Darker Platinum for better contrast
    }
  }
  
  // Get tier-specific name
  String get tierName {
    return tier.toString().split('.').last.capitalize();
  }
  
  // For serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.toString().split('.').last,
      'threshold': threshold,
      'iconName': iconName,
      'color': ((color.a * 255).round() << 24) | ((color.r * 255).round() << 16) | ((color.g * 255).round() << 8) | (color.b * 255).round(),
      'isSecret': isSecret,
      'earnedOn': earnedOn?.toIso8601String(),
      'progress': progress,
      'tier': tier.toString(),
      'achievementFamilyId': achievementFamilyId,
      'unlocksAtLevel': unlocksAtLevel,
      'claimStatus': claimStatus.toString(),
      'metadata': metadata,
      'pointsReward': pointsReward,
      'relatedAchievementIds': relatedAchievementIds,
      'clues': clues,
    };
  }
  
  // Create a copy with updated values
  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    AchievementType? type,
    int? threshold,
    String? iconName,
    Color? color,
    bool? isSecret,
    DateTime? earnedOn,
    double? progress,
    AchievementTier? tier,
    String? achievementFamilyId,
    int? unlocksAtLevel,
    ClaimStatus? claimStatus,
    Map<String, dynamic>? metadata,
    int? pointsReward,
    List<String>? relatedAchievementIds,
    List<String>? clues,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      threshold: threshold ?? this.threshold,
      iconName: iconName ?? this.iconName,
      color: color ?? this.color,
      isSecret: isSecret ?? this.isSecret,
      earnedOn: earnedOn ?? this.earnedOn,
      progress: progress ?? this.progress,
      tier: tier ?? this.tier,
      achievementFamilyId: achievementFamilyId ?? this.achievementFamilyId,
      unlocksAtLevel: unlocksAtLevel ?? this.unlocksAtLevel,
      claimStatus: claimStatus ?? this.claimStatus,
      metadata: metadata ?? this.metadata,
      pointsReward: pointsReward ?? this.pointsReward,
      relatedAchievementIds: relatedAchievementIds ?? this.relatedAchievementIds,
      clues: clues ?? this.clues,
    );
  }
}

// Helper extension for string capitalization
extension StringExtension on String {
  String capitalize() {
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

/// Represents a daily streak of app usage
class Streak {
  
  const Streak({
    this.current = 0,
    this.longest = 0,
    required this.lastUsageDate,
  });
  
  // For deserialization
  factory Streak.fromJson(Map<String, dynamic> json) {
    return Streak(
      current: json['current'] ?? 0,
      longest: json['longest'] ?? 0,
      lastUsageDate: json['lastUsageDate'] != null 
          ? DateTime.parse(json['lastUsageDate'])
          : DateTime.now(),
    );
  }
  final int current;
  final int longest;
  final DateTime lastUsageDate;
  
  // For serialization
  Map<String, dynamic> toJson() {
    return {
      'current': current,
      'longest': longest,
      'lastUsageDate': lastUsageDate.toIso8601String(),
    };
  }
  
  // Create a copy with updated values
  Streak copyWith({
    int? current,
    int? longest,
    DateTime? lastUsageDate,
  }) {
    return Streak(
      current: current ?? this.current,
      longest: longest ?? this.longest,
      lastUsageDate: lastUsageDate ?? this.lastUsageDate,
    );
  }
}

/// Represents a challenge that can be completed for rewards
@HiveType(typeId: 10)
class Challenge { // For team challenges
  
  const Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.pointsReward,
    required this.iconName,
    required this.color,
    required this.requirements,
    this.isCompleted = false,
    this.progress = 0.0,
    this.participantIds = const [],
  });

  // For deserialization
  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      pointsReward: json['pointsReward'],
      iconName: json['iconName'],
      color: Color(json['color']),
      requirements: json['requirements'],
      isCompleted: json['isCompleted'] ?? false,
      progress: json['progress'] ?? 0.0,
      participantIds: json['participantIds'] != null 
          ? List<String>.from(json['participantIds'])
          : [],
    );
  }
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String description;
  @HiveField(3)
  final DateTime startDate;
  @HiveField(4)
  final DateTime endDate;
  @HiveField(5)
  final int pointsReward;
  @HiveField(6)
  final String iconName;
  @HiveField(7)
  final Color color;
  @HiveField(8)
  final Map<String, dynamic> requirements; // Flexible requirements structure
  @HiveField(9)
  final bool isCompleted;
  @HiveField(10)
  final double progress; // Progress from 0.0 to 1.0
  @HiveField(11)
  final List<String> participantIds;
  
  bool get isActive => 
      DateTime.now().isAfter(startDate) && 
      DateTime.now().isBefore(endDate);
  
  bool get isExpired => DateTime.now().isAfter(endDate);
  
  // For serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'pointsReward': pointsReward,
      'iconName': iconName,
      'color': ((color.a * 255).round() << 24) | ((color.r * 255).round() << 16) | ((color.g * 255).round() << 8) | (color.b * 255).round(),
      'requirements': requirements,
      'isCompleted': isCompleted,
      'progress': progress,
      'participantIds': participantIds,
    };
  }
  
  // Create a copy with updated values
  Challenge copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    int? pointsReward,
    String? iconName,
    Color? color,
    Map<String, dynamic>? requirements,
    bool? isCompleted,
    double? progress,
    List<String>? participantIds,
  }) {
    return Challenge(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      pointsReward: pointsReward ?? this.pointsReward,
      iconName: iconName ?? this.iconName,
      color: color ?? this.color,
      requirements: requirements ?? this.requirements,
      isCompleted: isCompleted ?? this.isCompleted,
      progress: progress ?? this.progress,
      participantIds: participantIds ?? this.participantIds,
    );
  }
}

/// Represents a user's points and rank
@HiveType(typeId: 11)
class UserPoints { // Points per waste category
  
  const UserPoints({
    this.total = 0,
    this.weeklyTotal = 0,
    this.monthlyTotal = 0,
    this.level = 1,
    this.categoryPoints = const {},
  });

  // For deserialization
  factory UserPoints.fromJson(Map<String, dynamic> json) {
    return UserPoints(
      total: json['total'] ?? 0,
      weeklyTotal: json['weeklyTotal'] ?? 0,
      monthlyTotal: json['monthlyTotal'] ?? 0,
      level: json['level'] ?? 1,
      categoryPoints: json['categoryPoints'] != null 
          ? Map<String, int>.from(json['categoryPoints'])
          : {},
    );
  }
  @HiveField(0)
  final int total;
  @HiveField(1)
  final int weeklyTotal;
  @HiveField(2)
  final int monthlyTotal;
  @HiveField(3)
  final int level;
  @HiveField(4)
  final Map<String, int> categoryPoints;
  
  // Fixed: Calculate points needed to reach next level
  int get pointsToNextLevel {
    final pointsForNextLevel = level * 100;
    return pointsForNextLevel - total;
  }
  
  // Get level name based on points
  String get rankName {
    if (level < 5) return 'Recycling Rookie';
    if (level < 10) return 'Waste Warrior';
    if (level < 15) return 'Segregation Specialist';
    if (level < 20) return 'Eco Champion';
    if (level < 25) return 'Sustainability Sage';
    return 'Waste Management Master';
  }
  
  // For serialization
  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'weeklyTotal': weeklyTotal,
      'monthlyTotal': monthlyTotal,
      'level': level,
      'categoryPoints': categoryPoints,
    };
  }
  
  // Create a copy with updated values
  UserPoints copyWith({
    int? total,
    int? weeklyTotal,
    int? monthlyTotal,
    int? level,
    Map<String, int>? categoryPoints,
  }) {
    return UserPoints(
      total: total ?? this.total,
      weeklyTotal: weeklyTotal ?? this.weeklyTotal,
      monthlyTotal: monthlyTotal ?? this.monthlyTotal,
      level: level ?? this.level,
      categoryPoints: categoryPoints ?? this.categoryPoints,
    );
  }
}

/// Represents weekly statistics for leaderboards
@HiveType(typeId: 12)
class WeeklyStats { // Count per waste category
  
  const WeeklyStats({
    required this.weekStartDate,
    this.itemsIdentified = 0,
    this.challengesCompleted = 0,
    this.streakMaximum = 0,
    this.pointsEarned = 0,
    this.categoryCounts = const {},
  });

  // For deserialization
  factory WeeklyStats.fromJson(Map<String, dynamic> json) {
    return WeeklyStats(
      weekStartDate: DateTime.parse(json['weekStartDate']),
      itemsIdentified: json['itemsIdentified'] ?? 0,
      challengesCompleted: json['challengesCompleted'] ?? 0,
      streakMaximum: json['streakMaximum'] ?? 0,
      pointsEarned: json['pointsEarned'] ?? 0,
      categoryCounts: json['categoryCounts'] != null 
          ? Map<String, int>.from(json['categoryCounts'])
          : {},
    );
  }
  @HiveField(0)
  final DateTime weekStartDate;
  @HiveField(1)
  final int itemsIdentified;
  @HiveField(2)
  final int challengesCompleted;
  @HiveField(3)
  final int streakMaximum;
  @HiveField(4)
  final int pointsEarned;
  @HiveField(5)
  final Map<String, int> categoryCounts;
  
  // For serialization
  Map<String, dynamic> toJson() {
    return {
      'weekStartDate': weekStartDate.toIso8601String(),
      'itemsIdentified': itemsIdentified,
      'challengesCompleted': challengesCompleted,
      'streakMaximum': streakMaximum,
      'pointsEarned': pointsEarned,
      'categoryCounts': categoryCounts,
    };
  }
  
  // Create a copy with updated values
  WeeklyStats copyWith({
    DateTime? weekStartDate,
    int? itemsIdentified,
    int? challengesCompleted,
    int? streakMaximum,
    int? pointsEarned,
    Map<String, int>? categoryCounts,
  }) {
    return WeeklyStats(
      weekStartDate: weekStartDate ?? this.weekStartDate,
      itemsIdentified: itemsIdentified ?? this.itemsIdentified,
      challengesCompleted: challengesCompleted ?? this.challengesCompleted,
      streakMaximum: streakMaximum ?? this.streakMaximum,
      pointsEarned: pointsEarned ?? this.pointsEarned,
      categoryCounts: categoryCounts ?? this.categoryCounts,
    );
  }
}

/// User's gamification profile containing all gamification data
@HiveType(typeId: 9)
class GamificationProfile {
  
  const GamificationProfile({
    required this.userId,
    this.achievements = const [],
    required this.streaks,
    required this.points,
    this.activeChallenges = const [],
    this.completedChallenges = const [],
    this.weeklyStats = const [],
    this.discoveredItemIds = const {},
    this.lastDailyEngagementBonusAwardedDate,
    this.lastViewPersonalStatsAwardedDate,
    this.unlockedHiddenContentIds = const {},
  });

  // For deserialization
  factory GamificationProfile.fromJson(Map<String, dynamic> json) {
    return GamificationProfile(
      userId: json['userId'],
      achievements: json['achievements'] != null 
          ? List<Map<String, dynamic>>.from(json['achievements'])
              .map((a) => Achievement.fromJson(a))
              .toList()
          : [],
      streaks: (json['streaks'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, StreakDetails.fromJson(value as Map<String, dynamic>)),
          ) ?? const {},
      points: json['points'] != null 
          ? UserPoints.fromJson(json['points'])
          : const UserPoints(),
      activeChallenges: json['activeChallenges'] != null 
          ? List<Map<String, dynamic>>.from(json['activeChallenges'])
              .map((c) => Challenge.fromJson(c))
              .toList()
          : [],
      completedChallenges: json['completedChallenges'] != null 
          ? List<Map<String, dynamic>>.from(json['completedChallenges'])
              .map((c) => Challenge.fromJson(c))
              .toList()
          : [],
      weeklyStats: json['weeklyStats'] != null 
          ? List<Map<String, dynamic>>.from(json['weeklyStats'])
              .map((s) => WeeklyStats.fromJson(s))
              .toList()
          : [],
      discoveredItemIds: Set<String>.from(json['discoveredItemIds'] as List<dynamic>? ?? []),
      lastDailyEngagementBonusAwardedDate:
          json['lastDailyEngagementBonusAwardedDate'] != null
              ? DateTime.parse(json['lastDailyEngagementBonusAwardedDate'])
              : null,
      lastViewPersonalStatsAwardedDate:
          json['lastViewPersonalStatsAwardedDate'] != null
              ? DateTime.parse(json['lastViewPersonalStatsAwardedDate'])
              : null,
      unlockedHiddenContentIds: Set<String>.from(json['unlockedHiddenContentIds'] as List<dynamic>? ?? []),
    );
  }
  @HiveField(0)
  final String userId;
  @HiveField(1)
  final List<Achievement> achievements;
  @HiveField(2)
  final Map<String, StreakDetails> streaks;
  @HiveField(3)
  final UserPoints points;
  @HiveField(4)
  final List<Challenge> activeChallenges;
  @HiveField(5)
  final List<Challenge> completedChallenges;
  @HiveField(6)
  final List<WeeklyStats> weeklyStats;
  @HiveField(7)
  final Set<String> discoveredItemIds;
  @HiveField(8)
  final DateTime? lastDailyEngagementBonusAwardedDate;
  @HiveField(9)
  final DateTime? lastViewPersonalStatsAwardedDate;
  @HiveField(10)
  final Set<String> unlockedHiddenContentIds;
  
  // For serialization
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'achievements': achievements.map((a) => a.toJson()).toList(),
      'streaks': streaks.map((key, value) => MapEntry(key, value.toJson())),
      'points': points.toJson(),
      'activeChallenges': activeChallenges.map((c) => c.toJson()).toList(),
      'completedChallenges': completedChallenges.map((c) => c.toJson()).toList(),
      'weeklyStats': weeklyStats.map((s) => s.toJson()).toList(),
      'discoveredItemIds': discoveredItemIds.toList(),
      'lastDailyEngagementBonusAwardedDate': lastDailyEngagementBonusAwardedDate?.toIso8601String(),
      'lastViewPersonalStatsAwardedDate': lastViewPersonalStatsAwardedDate?.toIso8601String(),
      'unlockedHiddenContentIds': unlockedHiddenContentIds.toList(),
    };
  }
  
  // Create a copy with updated values
  GamificationProfile copyWith({
    String? userId,
    List<Achievement>? achievements,
    Map<String, StreakDetails>? streaks,
    UserPoints? points,
    List<Challenge>? activeChallenges,
    List<Challenge>? completedChallenges,
    List<WeeklyStats>? weeklyStats,
    Set<String>? discoveredItemIds,
    DateTime? lastDailyEngagementBonusAwardedDate,
    DateTime? lastViewPersonalStatsAwardedDate,
    Set<String>? unlockedHiddenContentIds,
  }) {
    return GamificationProfile(
      userId: userId ?? this.userId,
      achievements: achievements ?? this.achievements,
      streaks: streaks ?? this.streaks,
      points: points ?? this.points,
      activeChallenges: activeChallenges ?? this.activeChallenges,
      completedChallenges: completedChallenges ?? this.completedChallenges,
      weeklyStats: weeklyStats ?? this.weeklyStats,
      discoveredItemIds: discoveredItemIds ?? this.discoveredItemIds,
      lastDailyEngagementBonusAwardedDate: lastDailyEngagementBonusAwardedDate ?? this.lastDailyEngagementBonusAwardedDate,
      lastViewPersonalStatsAwardedDate: lastViewPersonalStatsAwardedDate ?? this.lastViewPersonalStatsAwardedDate,
      unlockedHiddenContentIds: unlockedHiddenContentIds ?? this.unlockedHiddenContentIds,
    );
  }
}

/// Types of reactions that can be added to family content.
enum FamilyReactionType {
  like,
  love,
  helpful,
  amazing,
  wellDone,
  educational,
}

/// A reaction that a family member can give to shared content.
class FamilyReaction {

  const FamilyReaction({
    required this.userId,
    required this.displayName,
    this.photoUrl,
    required this.type,
    required this.timestamp,
    this.comment,
  });

  /// Creates a reaction from a JSON map.
  factory FamilyReaction.fromJson(Map<String, dynamic> json) {
    return FamilyReaction(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      photoUrl: json['photoUrl'] as String?,
      type: FamilyReactionType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => FamilyReactionType.like,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      comment: json['comment'] as String?,
    );
  }
  final String userId;
  final String displayName;
  final String? photoUrl;
  final FamilyReactionType type;
  final DateTime timestamp;
  final String? comment;

  /// Converts this reaction to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'type': type.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
      'comment': comment,
    };
  }
}

/// A comment that a family member can add to shared content.
class FamilyComment {

  const FamilyComment({
    required this.id,
    required this.userId,
    required this.displayName,
    this.photoUrl,
    required this.text,
    required this.timestamp,
    this.parentCommentId,
    this.isEdited = false,
    this.editedAt,
    this.replies = const [],
  });

  /// Creates a new comment with auto-generated ID.
  factory FamilyComment.create({
    required String userId,
    required String displayName,
    String? photoUrl,
    required String text,
    String? parentCommentId,
  }) {
    return FamilyComment(
      id: const Uuid().v4(),
      userId: userId,
      displayName: displayName,
      photoUrl: photoUrl,
      text: text,
      timestamp: DateTime.now(),
      parentCommentId: parentCommentId,
    );
  }

  /// Creates a comment from a JSON map.
  factory FamilyComment.fromJson(Map<String, dynamic> json) {
    return FamilyComment(
      id: json['id'] as String,
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      photoUrl: json['photoUrl'] as String?,
      text: json['text'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      parentCommentId: json['parentCommentId'] as String?,
      isEdited: json['isEdited'] as bool? ?? false,
      editedAt: json['editedAt'] != null
          ? DateTime.parse(json['editedAt'] as String)
          : null,
      replies: (json['replies'] as List<dynamic>?)
              ?.map((r) => FamilyComment.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
  final String id;
  final String userId;
  final String displayName;
  final String? photoUrl;
  final String text;
  final DateTime timestamp;
  final String? parentCommentId; // For threaded comments
  final bool isEdited;
  final DateTime? editedAt;
  final List<FamilyComment> replies;

  /// Checks if this is a reply to another comment.
  bool get isReply => parentCommentId != null;

  /// Gets the total number of replies (including nested replies).
  int get totalReplies {
    var count = replies.length;
    for (final reply in replies) {
      count += reply.totalReplies;
    }
    return count;
  }

  /// Creates a copy of this FamilyComment with the given fields replaced.
  FamilyComment copyWith({
    String? id,
    String? userId,
    String? displayName,
    String? photoUrl,
    String? text,
    DateTime? timestamp,
    String? parentCommentId,
    bool? isEdited,
    DateTime? editedAt,
    List<FamilyComment>? replies,
  }) {
    return FamilyComment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      replies: replies ?? this.replies,
    );
  }

  /// Converts this comment to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'parentCommentId': parentCommentId,
      'isEdited': isEdited,
      'editedAt': editedAt?.toIso8601String(),
      'replies': replies.map((r) => r.toJson()).toList(),
    };
  }
}

/// Classification location information for context.
class ClassificationLocation {

  const ClassificationLocation({
    this.latitude,
    this.longitude,
    this.address,
    this.locationName,
    this.city,
    this.country,
  });

  /// Creates a location from a JSON map.
  factory ClassificationLocation.fromJson(Map<String, dynamic> json) {
    return ClassificationLocation(
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      address: json['address'] as String?,
      locationName: json['locationName'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
    );
  }
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? locationName;
  final String? city;
  final String? country;

  /// Converts this location to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'locationName': locationName,
      'city': city,
      'country': country,
    };
  }
}

/// Leaderboard entry for family competitions.
class LeaderboardEntry {

  const LeaderboardEntry({
    required this.userId,
    required this.displayName,
    this.photoUrl,
    required this.points,
    required this.classificationsCount,
    required this.rank,
    required this.achievements,
    required this.lastActive,
  });

  /// Creates an entry from a JSON map.
  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String,
      photoUrl: json['photoUrl'] as String?,
      points: json['points'] as int,
      classificationsCount: json['classificationsCount'] as int,
      rank: json['rank'] as int,
      achievements: (json['achievements'] as List<dynamic>)
          .map((a) => a as String)
          .toList(),
      lastActive: DateTime.parse(json['lastActive'] as String),
    );
  }
  final String userId;
  final String displayName;
  final String? photoUrl;
  final int points;
  final int classificationsCount;
  final int rank;
  final List<String> achievements;
  final DateTime lastActive;

  /// Converts this entry to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'points': points,
      'classificationsCount': classificationsCount,
      'rank': rank,
      'achievements': achievements,
      'lastActive': lastActive.toIso8601String(),
    };
  }
}

/// Analytics data for tracking user behavior and app usage.
class AnalyticsEvent {

  const AnalyticsEvent({
    required this.id,
    required this.userId,
    required this.eventType,
    required this.eventName,
    required this.parameters,
    required this.timestamp,
    this.sessionId,
    this.deviceInfo,
  });

  /// Creates a new analytics event.
  factory AnalyticsEvent.create({
    required String userId,
    required String eventType,
    required String eventName,
    Map<String, dynamic> parameters = const {},
    String? sessionId,
    String? deviceInfo,
  }) {
    return AnalyticsEvent(
      id: const Uuid().v4(),
      userId: userId,
      eventType: eventType,
      eventName: eventName,
      parameters: parameters,
      timestamp: DateTime.now(),
      sessionId: sessionId,
      deviceInfo: deviceInfo,
    );
  }

  /// Creates an event from a JSON map.
  factory AnalyticsEvent.fromJson(Map<String, dynamic> json) {
    return AnalyticsEvent(
      id: json['id'] as String,
      userId: json['userId'] as String,
      eventType: json['eventType'] as String,
      eventName: json['eventName'] as String,
      parameters: json['parameters'] as Map<String, dynamic>,
      timestamp: DateTime.parse(json['timestamp'] as String),
      sessionId: json['sessionId'] as String?,
      deviceInfo: json['deviceInfo'] as String?,
    );
  }
  final String id;
  final String userId;
  final String eventType;
  final String eventName;
  final Map<String, dynamic> parameters;
  final DateTime timestamp;
  final String? sessionId;
  final String? deviceInfo;

  /// Converts this event to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'eventType': eventType,
      'eventName': eventName,
      'parameters': parameters,
      'timestamp': timestamp.toIso8601String(),
      'sessionId': sessionId,
      'deviceInfo': deviceInfo,
    };
  }
}

/// Common analytics event types.
class AnalyticsEventTypes {
  // Core lifecycle
  static const String session = 'session';
  static const String pageView = 'page_view';
  
  // Existing types
  static const String userAction = 'user_action';
  static const String screenView = 'screen_view';
  static const String classification = 'classification';
  static const String social = 'social';
  static const String achievement = 'achievement';
  static const String error = 'error';
  
  // New comprehensive types
  static const String interaction = 'interaction';
  static const String performance = 'performance';
  static const String errorDetailed = 'error_detailed';
  static const String engagement = 'engagement';
  static const String gamification = 'gamification';
  static const String content = 'content';
  static const String navigation = 'navigation';
}

/// Common analytics event names.
class AnalyticsEventNames {
  // Session lifecycle
  static const String sessionStart = 'session_start';
  static const String sessionEnd = 'session_end';
  static const String pageView = 'page_view';
  
  // Core interactions
  static const String click = 'click';
  static const String linkClick = 'link_click';
  static const String rageClick = 'rage_click';
  static const String scrollDepth = 'scroll_depth';
  static const String longPress = 'long_press';
  
  // User Actions (existing)
  static const String buttonClick = 'button_click';
  static const String screenSwipe = 'screen_swipe';
  static const String searchPerformed = 'search_performed';
  
  // Screen Views (existing)
  static const String homeScreenView = 'home_screen_view';
  static const String cameraScreenView = 'camera_screen_view';
  static const String resultsScreenView = 'results_screen_view';
  static const String familyScreenView = 'family_screen_view';
  
  // Waste classification events
  static const String fileClassified = 'file_classified';
  static const String classificationStarted = 'classification_started';
  static const String classificationCompleted = 'classification_completed';
  static const String classificationRetried = 'classification_retried';
  static const String classificationShared = 'classification_shared';
  static const String disposalGuidanceViewed = 'disposal_guidance_viewed';
  
  // Gamification events
  static const String pointsEarned = 'points_earned';
  static const String streakUpdated = 'streak_updated';
  static const String challengeCompleted = 'challenge_completed';
  
  // Achievements (existing - maintain compatibility)
  static const String achievementUnlocked = 'achievement_unlocked';
  static const String levelUp = 'level_up';
  
  // Educational content events
  static const String contentViewed = 'content_viewed';
  static const String contentCompleted = 'content_completed';
  static const String bookmarkAdded = 'bookmark_added';
  
  // Performance & error events
  static const String clientError = 'client_error';
  static const String apiError = 'api_error';
  static const String slowResource = 'slow_resource';
  static const String networkFailure = 'network_failure';
  
  // Social events (existing)
  static const String familyCreated = 'family_created';
  static const String familyJoined = 'family_joined';
  static const String invitationSent = 'invitation_sent';
  static const String reactionAdded = 'reaction_added';
  static const String commentAdded = 'comment_added';
  static const String classificationReacted = 'classification_reacted';
  static const String leaderboardViewed = 'leaderboard_viewed';
  
  // Legacy error events (maintain compatibility)
  static const String classificationError = 'classification_error';
  static const String networkError = 'network_error';
  static const String authError = 'auth_error';
}

/// Added StreakType Enum
@HiveType(typeId: 13)
enum StreakType {
  @HiveField(0)
  dailyClassification,
  @HiveField(1)
  dailyLearning,
  @HiveField(2)
  dailyEngagement,
  @HiveField(3)
  itemDiscovery,
  // Add more types as needed
}

/// New StreakDetails class
@HiveType(typeId: 14)
class StreakDetails {

  const StreakDetails({
    required this.type,
    this.currentCount = 0,
    this.longestCount = 0,
    required this.lastActivityDate,
    this.lastMaintenanceAwardedDate,
    this.lastMilestoneAwardedLevel = 0,
  });

  factory StreakDetails.fromJson(Map<String, dynamic> json) {
    return StreakDetails(
      type: StreakType.values.byName(json['type'] ?? StreakType.dailyClassification.name),
      currentCount: json['currentCount'] ?? 0,
      longestCount: json['longestCount'] ?? 0,
      lastActivityDate: DateTime.parse(json['lastActivityDate']),
      lastMaintenanceAwardedDate: json['lastMaintenanceAwardedDate'] != null
          ? DateTime.parse(json['lastMaintenanceAwardedDate'])
          : null,
      lastMilestoneAwardedLevel: json['lastMilestoneAwardedLevel'] ?? 0,
    );
  }
  @HiveField(0)
  final StreakType type;
  @HiveField(1)
  final int currentCount;
  @HiveField(2)
  final int longestCount;
  @HiveField(3)
  final DateTime lastActivityDate;
  @HiveField(4)
  final DateTime? lastMaintenanceAwardedDate;
  @HiveField(5)
  final int lastMilestoneAwardedLevel;

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'currentCount': currentCount,
    'longestCount': longestCount,
    'lastActivityDate': lastActivityDate.toIso8601String(),
    'lastMaintenanceAwardedDate': lastMaintenanceAwardedDate?.toIso8601String(),
    'lastMilestoneAwardedLevel': lastMilestoneAwardedLevel,
  };

  StreakDetails copyWith({
    StreakType? type,
    int? currentCount,
    int? longestCount,
    DateTime? lastActivityDate,
    DateTime? lastMaintenanceAwardedDate,
    int? lastMilestoneAwardedLevel,
  }) {
    return StreakDetails(
      type: type ?? this.type,
      currentCount: currentCount ?? this.currentCount,
      longestCount: longestCount ?? this.longestCount,
      lastActivityDate: lastActivityDate ?? this.lastActivityDate,
      lastMaintenanceAwardedDate: lastMaintenanceAwardedDate ?? this.lastMaintenanceAwardedDate,
      lastMilestoneAwardedLevel: lastMilestoneAwardedLevel ?? this.lastMilestoneAwardedLevel,
    );
  }
}