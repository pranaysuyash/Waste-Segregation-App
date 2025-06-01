import 'package:uuid/uuid.dart';
import 'family_invitation.dart';

/// Enhanced Family model for Firebase Firestore with social features.
class Family {
  final String id;
  final String name;
  final String? description;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<FamilyMember> members;
  final FamilySettings settings;
  final String? imageUrl;
  final bool isPublic;

  const Family({
    required this.id,
    required this.name,
    this.description,
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
    this.members = const [],
    this.settings = const FamilySettings(),
    this.imageUrl,
    this.isPublic = false,
  });

  /// Creates a new family with default values.
  factory Family.create({
    required String name,
    required String createdBy,
    required FamilyMember admin,
  }) {
    final now = DateTime.now();
    return Family(
      id: const Uuid().v4(),
      name: name,
      createdBy: createdBy,
      createdAt: now,
      updatedAt: now,
      members: [admin],
      settings: FamilySettings.defaultSettings(),
      imageUrl: null,
    );
  }

  /// Checks if a user is a member of this family.
  bool hasMember(String userId) {
    return members.any((member) => member.userId == userId);
  }

  /// Gets a specific member by user ID.
  FamilyMember? getMember(String userId) {
    try {
      return members.firstWhere((member) => member.userId == userId);
    } catch (e) {
      return null;
    }
  }

  /// Gets the admin member(s).
  List<FamilyMember> getAdmins() {
    return members.where((member) => member.role == UserRole.admin).toList();
  }

  /// Creates a copy of this family with updated fields.
  Family copyWith({
    String? id,
    String? name,
    String? description,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<FamilyMember>? members,
    FamilySettings? settings,
    String? imageUrl,
    bool? isPublic,
  }) {
    return Family(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      members: members ?? this.members,
      settings: settings ?? this.settings,
      imageUrl: imageUrl ?? this.imageUrl,
      isPublic: isPublic ?? this.isPublic,
    );
  }

  /// Converts this family to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'members': members.map((m) => m.toJson()).toList(),
      'settings': settings.toJson(),
      'imageUrl': imageUrl,
      'isPublic': isPublic,
    };
  }

  /// Creates a family from a JSON map.
  factory Family.fromJson(Map<String, dynamic> json) {
    final settingsJson = json['settings'] as Map<String, dynamic>?;
    return Family(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      createdBy: json['createdBy'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
      members: (json['members'] as List<dynamic>? ?? [])
          .map((e) => FamilyMember.fromJson(e as Map<String, dynamic>))
          .toList(),
      settings: settingsJson != null ? FamilySettings.fromJson(settingsJson) : const FamilySettings(),
      imageUrl: json['imageUrl'] as String?,
      isPublic: json['isPublic'] as bool? ?? settingsJson?['isPublic'] as bool? ?? false,
    );
  }
}

/// Represents a member of a family with their role and stats.
class FamilyMember {
  final String userId;
  final UserRole role;
  final DateTime joinedAt;
  final UserStats individualStats;
  final String? displayName;
  final String? photoUrl;

  const FamilyMember({
    required this.userId,
    required this.role,
    required this.joinedAt,
    required this.individualStats,
    this.displayName,
    this.photoUrl,
  });

  /// Creates a copy of this member with updated fields.
  FamilyMember copyWith({
    UserRole? role,
    UserStats? individualStats,
    String? displayName,
    String? photoUrl,
  }) {
    return FamilyMember(
      userId: userId,
      role: role ?? this.role,
      joinedAt: joinedAt,
      individualStats: individualStats ?? this.individualStats,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  /// Converts this member to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'role': role.toString().split('.').last,
      'joinedAt': joinedAt.toIso8601String(),
      'individualStats': individualStats.toJson(),
      'displayName': displayName,
      'photoUrl': photoUrl,
    };
  }

  /// Creates a member from a JSON map.
  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      userId: json['userId'] as String,
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == json['role'],
        orElse: () => UserRole.member,
      ),
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      individualStats: UserStats.fromJson(json['individualStats'] as Map<String, dynamic>),
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
    );
  }
}

/// Settings and preferences for a family.
class FamilySettings {
  final bool isPublic;
  final bool? allowChildInvites;
  final bool? shareClassifications;
  final bool? showMemberActivity;
  final NotificationSettings? notifications;
  final PrivacySettings? privacy;
  final Map<String, dynamic> customSettings;
  final bool shareClassificationsPublicly;
  final bool showMemberActivityInFeed;
  final FamilyLeaderboardVisibility leaderboardVisibility;

  const FamilySettings({
    this.isPublic = false,
    this.allowChildInvites = false,
    this.shareClassifications = true,
    this.showMemberActivity = true,
    this.notifications,
    this.privacy,
    this.customSettings = const {},
    this.shareClassificationsPublicly = true,
    this.showMemberActivityInFeed = true,
    this.leaderboardVisibility = FamilyLeaderboardVisibility.membersOnly,
  });

  /// Creates default family settings.
  static FamilySettings defaultSettings() {
    return const FamilySettings(
      isPublic: false,
      allowChildInvites: false,
      shareClassifications: true,
      showMemberActivity: true,
      customSettings: {},
      shareClassificationsPublicly: true,
      showMemberActivityInFeed: true,
      leaderboardVisibility: FamilyLeaderboardVisibility.membersOnly,
    );
  }

  /// Creates a copy of these settings with updated fields.
  FamilySettings copyWith({
    bool? isPublic,
    bool? allowChildInvites,
    bool? shareClassifications,
    bool? showMemberActivity,
    NotificationSettings? notifications,
    PrivacySettings? privacy,
    Map<String, dynamic>? customSettings,
    bool? shareClassificationsPublicly,
    bool? showMemberActivityInFeed,
    FamilyLeaderboardVisibility? leaderboardVisibility,
  }) {
    return FamilySettings(
      isPublic: isPublic ?? this.isPublic,
      allowChildInvites: allowChildInvites ?? this.allowChildInvites,
      shareClassifications: shareClassifications ?? this.shareClassifications,
      showMemberActivity: showMemberActivity ?? this.showMemberActivity,
      notifications: notifications ?? this.notifications,
      privacy: privacy ?? this.privacy,
      customSettings: customSettings ?? this.customSettings,
      shareClassificationsPublicly: shareClassificationsPublicly ?? this.shareClassificationsPublicly,
      showMemberActivityInFeed: showMemberActivityInFeed ?? this.showMemberActivityInFeed,
      leaderboardVisibility: leaderboardVisibility ?? this.leaderboardVisibility,
    );
  }

  /// Converts these settings to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'isPublic': isPublic,
      'allowChildInvites': allowChildInvites,
      'shareClassifications': shareClassifications,
      'showMemberActivity': showMemberActivity,
      'notifications': notifications?.toJson(),
      'privacy': privacy?.toJson(),
      'customSettings': customSettings,
      'shareClassificationsPublicly': shareClassificationsPublicly,
      'showMemberActivityInFeed': showMemberActivityInFeed,
      'leaderboardVisibility': leaderboardVisibility.toString(),
    };
  }

  /// Creates settings from a JSON map.
  factory FamilySettings.fromJson(Map<String, dynamic> json) {
    return FamilySettings(
      isPublic: json['isPublic'] as bool? ?? false,
      allowChildInvites: json['allowChildInvites'] as bool? ?? false,
      shareClassifications: json['shareClassifications'] as bool? ?? true,
      showMemberActivity: json['showMemberActivity'] as bool? ?? true,
      notifications: json['notifications'] != null
          ? NotificationSettings.fromJson(json['notifications'] as Map<String, dynamic>)
          : null,
      privacy: json['privacy'] != null
          ? PrivacySettings.fromJson(json['privacy'] as Map<String, dynamic>)
          : null,
      customSettings: json['customSettings'] as Map<String, dynamic>? ?? {},
      shareClassificationsPublicly: json['shareClassificationsPublicly'] as bool? ?? true,
      showMemberActivityInFeed: json['showMemberActivityInFeed'] as bool? ?? true,
      leaderboardVisibility: FamilyLeaderboardVisibility.values.firstWhere(
        (e) => e.toString() == json['leaderboardVisibility'],
        orElse: () => FamilyLeaderboardVisibility.membersOnly,
      ),
    );
  }
}

/// Notification settings for a family.
class NotificationSettings {
  final bool newMemberJoined;
  final bool classificationShared;
  final bool achievementUnlocked;
  final bool weeklyReport;
  final bool invitationReceived;

  const NotificationSettings({
    required this.newMemberJoined,
    required this.classificationShared,
    required this.achievementUnlocked,
    required this.weeklyReport,
    required this.invitationReceived,
  });

  /// Creates default notification settings.
  factory NotificationSettings.defaultSettings() {
    return const NotificationSettings(
      newMemberJoined: true,
      classificationShared: true,
      achievementUnlocked: true,
      weeklyReport: true,
      invitationReceived: true,
    );
  }

  /// Converts these settings to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'newMemberJoined': newMemberJoined,
      'classificationShared': classificationShared,
      'achievementUnlocked': achievementUnlocked,
      'weeklyReport': weeklyReport,
      'invitationReceived': invitationReceived,
    };
  }

  /// Creates settings from a JSON map.
  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      newMemberJoined: json['newMemberJoined'] as bool? ?? true,
      classificationShared: json['classificationShared'] as bool? ?? true,
      achievementUnlocked: json['achievementUnlocked'] as bool? ?? true,
      weeklyReport: json['weeklyReport'] as bool? ?? true,
      invitationReceived: json['invitationReceived'] as bool? ?? true,
    );
  }
}

/// Privacy settings for a family.
class PrivacySettings {
  final bool showLastSeen;
  final bool showActivityStatus;
  final bool allowSearchByName;
  final List<String> blockedUsers;

  const PrivacySettings({
    required this.showLastSeen,
    required this.showActivityStatus,
    required this.allowSearchByName,
    this.blockedUsers = const [],
  });

  /// Creates default privacy settings.
  factory PrivacySettings.defaultSettings() {
    return const PrivacySettings(
      showLastSeen: true,
      showActivityStatus: true,
      allowSearchByName: true,
      blockedUsers: [],
    );
  }

  /// Converts these settings to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'showLastSeen': showLastSeen,
      'showActivityStatus': showActivityStatus,
      'allowSearchByName': allowSearchByName,
      'blockedUsers': blockedUsers,
    };
  }

  /// Creates settings from a JSON map.
  factory PrivacySettings.fromJson(Map<String, dynamic> json) {
    return PrivacySettings(
      showLastSeen: json['showLastSeen'] as bool? ?? true,
      showActivityStatus: json['showActivityStatus'] as bool? ?? true,
      allowSearchByName: json['allowSearchByName'] as bool? ?? true,
      blockedUsers: (json['blockedUsers'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}

/// Comprehensive statistics for a family.
class FamilyStats {
  final int totalClassifications;
  final int totalPoints;
  final int currentStreak;
  final int bestStreak;
  final Map<String, int> categoryBreakdown;
  final EnvironmentalImpact environmentalImpact;
  final List<WeeklyProgress> weeklyProgress;
  final int achievementCount;
  final DateTime lastUpdated;

  const FamilyStats({
    required this.totalClassifications,
    required this.totalPoints,
    required this.currentStreak,
    required this.bestStreak,
    required this.categoryBreakdown,
    required this.environmentalImpact,
    required this.weeklyProgress,
    required this.achievementCount,
    required this.lastUpdated,
  });

  /// Creates empty family stats.
  factory FamilyStats.empty() {
    return FamilyStats(
      totalClassifications: 0,
      totalPoints: 0,
      currentStreak: 0,
      bestStreak: 0,
      categoryBreakdown: {},
      environmentalImpact: EnvironmentalImpact.empty(),
      weeklyProgress: [],
      achievementCount: 0,
      lastUpdated: DateTime.now(),
    );
  }

  /// Creates a copy of these stats with updated fields.
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
      lastUpdated: lastUpdated ?? DateTime.now(),
    );
  }

  /// Converts these stats to a JSON map.
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

  /// Creates stats from a JSON map.
  factory FamilyStats.fromJson(Map<String, dynamic> json) {
    return FamilyStats(
      totalClassifications: json['totalClassifications'] as int? ?? 0,
      totalPoints: json['totalPoints'] as int? ?? 0,
      currentStreak: json['currentStreak'] as int? ?? 0,
      bestStreak: json['bestStreak'] as int? ?? 0,
      categoryBreakdown: Map<String, int>.from(json['categoryBreakdown'] as Map? ?? {}),
      environmentalImpact: EnvironmentalImpact.fromJson(
        json['environmentalImpact'] as Map<String, dynamic>? ?? {},
      ),
      weeklyProgress: (json['weeklyProgress'] as List<dynamic>?)
              ?.map((w) => WeeklyProgress.fromJson(w as Map<String, dynamic>))
              .toList() ??
          [],
      achievementCount: json['achievementCount'] as int? ?? 0,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }
}

/// Individual user statistics within a family.
class UserStats {
  final int totalPoints;
  final int totalClassifications;
  final int currentStreak;
  final int bestStreak;
  final Map<String, int> categoryBreakdown;
  final List<String> achievements;
  final DateTime lastActive;

  const UserStats({
    required this.totalPoints,
    required this.totalClassifications,
    required this.currentStreak,
    required this.bestStreak,
    required this.categoryBreakdown,
    required this.achievements,
    required this.lastActive,
  });

  /// Creates empty user stats.
  factory UserStats.empty() {
    return UserStats(
      totalPoints: 0,
      totalClassifications: 0,
      currentStreak: 0,
      bestStreak: 0,
      categoryBreakdown: {},
      achievements: [],
      lastActive: DateTime.now(),
    );
  }

  /// Creates a copy of these stats with updated fields.
  UserStats copyWith({
    int? totalPoints,
    int? totalClassifications,
    int? currentStreak,
    int? bestStreak,
    Map<String, int>? categoryBreakdown,
    List<String>? achievements,
    DateTime? lastActive,
  }) {
    return UserStats(
      totalPoints: totalPoints ?? this.totalPoints,
      totalClassifications: totalClassifications ?? this.totalClassifications,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      categoryBreakdown: categoryBreakdown ?? this.categoryBreakdown,
      achievements: achievements ?? this.achievements,
      lastActive: lastActive ?? DateTime.now(),
    );
  }

  /// Converts these stats to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'totalPoints': totalPoints,
      'totalClassifications': totalClassifications,
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
      'categoryBreakdown': categoryBreakdown,
      'achievements': achievements,
      'lastActive': lastActive.toIso8601String(),
    };
  }

  /// Creates stats from a JSON map.
  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalPoints: json['totalPoints'] as int? ?? 0,
      totalClassifications: json['totalClassifications'] as int? ?? 0,
      currentStreak: json['currentStreak'] as int? ?? 0,
      bestStreak: json['bestStreak'] as int? ?? 0,
      categoryBreakdown: Map<String, int>.from(json['categoryBreakdown'] as Map? ?? {}),
      achievements: (json['achievements'] as List<dynamic>?)
              ?.map((a) => a as String)
              .toList() ??
          [],
      lastActive: DateTime.parse(json['lastActive'] as String),
    );
  }
}

/// Environmental impact metrics for tracking eco-friendly achievements.
class EnvironmentalImpact {
  final double co2Saved; // kg of CO2 saved
  final double treesEquivalent; // trees saved equivalent
  final double waterSaved; // liters of water saved
  final DateTime lastUpdated;

  const EnvironmentalImpact({
    required this.co2Saved,
    required this.treesEquivalent,
    required this.waterSaved,
    required this.lastUpdated,
  });

  /// Creates empty environmental impact.
  factory EnvironmentalImpact.empty() {
    return EnvironmentalImpact(
      co2Saved: 0.0,
      treesEquivalent: 0.0,
      waterSaved: 0.0,
      lastUpdated: DateTime.now(),
    );
  }

  /// Converts this impact to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'co2Saved': co2Saved,
      'treesEquivalent': treesEquivalent,
      'waterSaved': waterSaved,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  /// Creates impact from a JSON map.
  factory EnvironmentalImpact.fromJson(Map<String, dynamic> json) {
    return EnvironmentalImpact(
      co2Saved: (json['co2Saved'] as num?)?.toDouble() ?? 0.0,
      treesEquivalent: (json['treesEquivalent'] as num?)?.toDouble() ?? 0.0,
      waterSaved: (json['waterSaved'] as num?)?.toDouble() ?? 0.0,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }
}

/// Weekly progress tracking for family activities.
class WeeklyProgress {
  final DateTime weekStart;
  final DateTime weekEnd;
  final int classificationsCount;
  final int pointsEarned;
  final Map<String, int> categoryBreakdown;

  const WeeklyProgress({
    required this.weekStart,
    required this.weekEnd,
    required this.classificationsCount,
    required this.pointsEarned,
    required this.categoryBreakdown,
  });

  /// Converts this progress to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'weekStart': weekStart.toIso8601String(),
      'weekEnd': weekEnd.toIso8601String(),
      'classificationsCount': classificationsCount,
      'pointsEarned': pointsEarned,
      'categoryBreakdown': categoryBreakdown,
    };
  }

  /// Creates progress from a JSON map.
  factory WeeklyProgress.fromJson(Map<String, dynamic> json) {
    return WeeklyProgress(
      weekStart: DateTime.parse(json['weekStart'] as String),
      weekEnd: DateTime.parse(json['weekEnd'] as String),
      classificationsCount: json['classificationsCount'] as int? ?? 0,
      pointsEarned: json['pointsEarned'] as int? ?? 0,
      categoryBreakdown: Map<String, int>.from(json['categoryBreakdown'] as Map? ?? {}),
    );
  }
}

enum UserRole { admin, moderator, member }

enum InvitationStatus { pending, accepted, declined, expired }

enum FamilyLeaderboardVisibility { public, membersOnly, adminsOnly } 