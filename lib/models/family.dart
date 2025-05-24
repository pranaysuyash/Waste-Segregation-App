/// Represents a family or team group in the waste segregation app.
///
/// This model stores information about family groups, their members,
/// settings, and aggregate statistics.
class Family {
  /// The unique identifier for the family.
  final String id;

  /// The display name of the family.
  final String name;

  /// Optional URL for family photo/avatar.
  final String? photoUrl;

  /// User ID of the family creator.
  final String createdBy;

  /// When the family was created.
  final DateTime createdAt;

  /// Last time family data was updated.
  final DateTime lastUpdated;

  /// List of family members with their roles and details.
  final List<FamilyMember> members;

  /// Family-specific settings and preferences.
  final FamilySettings settings;

  /// Aggregate statistics for the family.
  final FamilyStats stats;

  /// Whether the family is active.
  final bool isActive;

  Family({
    required this.id,
    required this.name,
    this.photoUrl,
    required this.createdBy,
    required this.createdAt,
    required this.lastUpdated,
    this.members = const [],
    required this.settings,
    required this.stats,
    this.isActive = true,
  });

  /// Creates a copy of this Family with the given fields replaced.
  Family copyWith({
    String? id,
    String? name,
    String? photoUrl,
    String? createdBy,
    DateTime? createdAt,
    DateTime? lastUpdated,
    List<FamilyMember>? members,
    FamilySettings? settings,
    FamilyStats? stats,
    bool? isActive,
  }) {
    return Family(
      id: id ?? this.id,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      members: members ?? this.members,
      settings: settings ?? this.settings,
      stats: stats ?? this.stats,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Converts this Family instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'photoUrl': photoUrl,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'members': members.map((m) => m.toJson()).toList(),
      'settings': settings.toJson(),
      'stats': stats.toJson(),
      'isActive': isActive,
    };
  }

  /// Creates a Family instance from a JSON map.
  factory Family.fromJson(Map<String, dynamic> json) {
    return Family(
      id: json['id'] as String,
      name: json['name'] as String,
      photoUrl: json['photoUrl'] as String?,
      createdBy: json['createdBy'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      members: (json['members'] as List<dynamic>?)
              ?.map((m) => FamilyMember.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
      settings: FamilySettings.fromJson(json['settings'] as Map<String, dynamic>),
      stats: FamilyStats.fromJson(json['stats'] as Map<String, dynamic>),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  /// Gets admin members of the family.
  List<FamilyMember> get admins => 
      members.where((m) => m.role == UserRole.admin).toList();

  /// Gets the total number of active members.
  int get activeMemberCount => 
      members.where((m) => m.isActive).length;

  /// Checks if a user is a member of this family.
  bool hasMember(String userId) => 
      members.any((m) => m.userId == userId);

  /// Gets a specific member by user ID.
  FamilyMember? getMember(String userId) => 
      members.where((m) => m.userId == userId).firstOrNull;
}

/// Represents a member of a family with their role and statistics.
class FamilyMember {
  /// The user ID of the family member.
  final String userId;

  /// The role of the member within the family.
  final UserRole role;

  /// When the member joined the family.
  final DateTime joinedAt;

  /// Whether the member is currently active.
  final bool isActive;

  /// Individual statistics for this member.
  final UserStats individualStats;

  /// Display name for the member (cached for performance).
  final String? displayName;

  /// Photo URL for the member (cached for performance).
  final String? photoUrl;

  FamilyMember({
    required this.userId,
    required this.role,
    required this.joinedAt,
    this.isActive = true,
    required this.individualStats,
    this.displayName,
    this.photoUrl,
  });

  /// Creates a copy of this FamilyMember with the given fields replaced.
  FamilyMember copyWith({
    String? userId,
    UserRole? role,
    DateTime? joinedAt,
    bool? isActive,
    UserStats? individualStats,
    String? displayName,
    String? photoUrl,
  }) {
    return FamilyMember(
      userId: userId ?? this.userId,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      isActive: isActive ?? this.isActive,
      individualStats: individualStats ?? this.individualStats,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  /// Converts this FamilyMember instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'role': role.toString().split('.').last,
      'joinedAt': joinedAt.toIso8601String(),
      'isActive': isActive,
      'individualStats': individualStats.toJson(),
      'displayName': displayName,
      'photoUrl': photoUrl,
    };
  }

  /// Creates a FamilyMember instance from a JSON map.
  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      userId: json['userId'] as String,
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == json['role'],
        orElse: () => UserRole.member,
      ),
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
      individualStats: UserStats.fromJson(json['individualStats'] as Map<String, dynamic>),
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
    );
  }
}

/// Settings and preferences for a family.
class FamilySettings {
  /// Whether the family data is public (for leaderboards).
  final bool isPublic;

  /// Whether to allow children to classify waste.
  final bool allowChildClassification;

  /// Whether to require PIN for user switching.
  final bool requirePinForSwitching;

  /// Family goal for weekly waste classifications.
  final int weeklyGoal;

  /// Notification preferences for the family.
  final NotificationSettings notifications;

  /// Privacy settings for data sharing.
  final PrivacySettings privacy;

  /// Challenge preferences.
  final ChallengeSettings challenges;

  FamilySettings({
    this.isPublic = false,
    this.allowChildClassification = true,
    this.requirePinForSwitching = false,
    this.weeklyGoal = 50,
    required this.notifications,
    required this.privacy,
    required this.challenges,
  });

  /// Creates a copy of this FamilySettings with the given fields replaced.
  FamilySettings copyWith({
    bool? isPublic,
    bool? allowChildClassification,
    bool? requirePinForSwitching,
    int? weeklyGoal,
    NotificationSettings? notifications,
    PrivacySettings? privacy,
    ChallengeSettings? challenges,
  }) {
    return FamilySettings(
      isPublic: isPublic ?? this.isPublic,
      allowChildClassification: allowChildClassification ?? this.allowChildClassification,
      requirePinForSwitching: requirePinForSwitching ?? this.requirePinForSwitching,
      weeklyGoal: weeklyGoal ?? this.weeklyGoal,
      notifications: notifications ?? this.notifications,
      privacy: privacy ?? this.privacy,
      challenges: challenges ?? this.challenges,
    );
  }

  /// Converts this FamilySettings instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'isPublic': isPublic,
      'allowChildClassification': allowChildClassification,
      'requirePinForSwitching': requirePinForSwitching,
      'weeklyGoal': weeklyGoal,
      'notifications': notifications.toJson(),
      'privacy': privacy.toJson(),
      'challenges': challenges.toJson(),
    };
  }

  /// Creates a FamilySettings instance from a JSON map.
  factory FamilySettings.fromJson(Map<String, dynamic> json) {
    return FamilySettings(
      isPublic: json['isPublic'] as bool? ?? false,
      allowChildClassification: json['allowChildClassification'] as bool? ?? true,
      requirePinForSwitching: json['requirePinForSwitching'] as bool? ?? false,
      weeklyGoal: json['weeklyGoal'] as int? ?? 50,
      notifications: NotificationSettings.fromJson(json['notifications'] as Map<String, dynamic>),
      privacy: PrivacySettings.fromJson(json['privacy'] as Map<String, dynamic>),
      challenges: ChallengeSettings.fromJson(json['challenges'] as Map<String, dynamic>),
    );
  }

  /// Creates default family settings.
  factory FamilySettings.defaultSettings() {
    return FamilySettings(
      notifications: NotificationSettings.defaultSettings(),
      privacy: PrivacySettings.defaultSettings(),
      challenges: ChallengeSettings.defaultSettings(),
    );
  }
}

/// Aggregate statistics for a family.
class FamilyStats {
  /// Total items classified by the family.
  final int totalClassifications;

  /// Total points earned by the family.
  final int totalPoints;

  /// Current streak (days with at least one classification).
  final int currentStreak;

  /// Best streak achieved by the family.
  final int bestStreak;

  /// Breakdown by waste category.
  final Map<String, int> categoryBreakdown;

  /// Environmental impact metrics.
  final EnvironmentalImpact environmentalImpact;

  /// Weekly progress data.
  final List<WeeklyProgress> weeklyProgress;

  /// Achievement count.
  final int achievementCount;

  /// Last updated timestamp.
  final DateTime lastUpdated;

  FamilyStats({
    this.totalClassifications = 0,
    this.totalPoints = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.categoryBreakdown = const {},
    required this.environmentalImpact,
    this.weeklyProgress = const [],
    this.achievementCount = 0,
    required this.lastUpdated,
  });

  /// Creates a copy of this FamilyStats with the given fields replaced.
  FamilyStats copyWith({
    int? totalClassifications,
    int? totalPoints,
    int? currentStreak,
    int? bestStreak,
    Map<String, int>? categoryBreakdown,
    EnvironmentalImpact? environmentalImpact,
    List<WeeklyProgress>? weeklyProgress,
    int? achievementCount,
    DateTime? lastUpdated,
  }) {
    return FamilyStats(
      totalClassifications: totalClassifications ?? this.totalClassifications,
      totalPoints: totalPoints ?? this.totalPoints,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      categoryBreakdown: categoryBreakdown ?? this.categoryBreakdown,
      environmentalImpact: environmentalImpact ?? this.environmentalImpact,
      weeklyProgress: weeklyProgress ?? this.weeklyProgress,
      achievementCount: achievementCount ?? this.achievementCount,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Converts this FamilyStats instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'totalClassifications': totalClassifications,
      'totalPoints': totalPoints,
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
      'categoryBreakdown': categoryBreakdown,
      'environmentalImpact': environmentalImpact.toJson(),
      'weeklyProgress': weeklyProgress.map((w) => w.toJson()).toList(),
      'achievementCount': achievementCount,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  /// Creates a FamilyStats instance from a JSON map.
  factory FamilyStats.fromJson(Map<String, dynamic> json) {
    return FamilyStats(
      totalClassifications: json['totalClassifications'] as int? ?? 0,
      totalPoints: json['totalPoints'] as int? ?? 0,
      currentStreak: json['currentStreak'] as int? ?? 0,
      bestStreak: json['bestStreak'] as int? ?? 0,
      categoryBreakdown: Map<String, int>.from(json['categoryBreakdown'] as Map? ?? {}),
      environmentalImpact: EnvironmentalImpact.fromJson(json['environmentalImpact'] as Map<String, dynamic>),
      weeklyProgress: (json['weeklyProgress'] as List<dynamic>?)
              ?.map((w) => WeeklyProgress.fromJson(w as Map<String, dynamic>))
              .toList() ??
          [],
      achievementCount: json['achievementCount'] as int? ?? 0,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  /// Creates empty family stats.
  factory FamilyStats.empty() {
    return FamilyStats(
      environmentalImpact: EnvironmentalImpact.empty(),
      lastUpdated: DateTime.now(),
    );
  }
}

// Import statements for the required enums and classes
import '../models/user_profile.dart'; // For UserRole
import '../models/gamification.dart'; // For UserStats, NotificationSettings, etc.

// Supporting classes would be defined in separate files:
// - NotificationSettings
// - PrivacySettings  
// - ChallengeSettings
// - EnvironmentalImpact
// - WeeklyProgress
// These would be in gamification.dart or separate files as needed
