import 'package:flutter/material.dart';

/// Represents the types of achievements available in the app
enum AchievementType {
  // Category-based achievements
  wasteIdentified,      // Identify waste items
  categoriesIdentified, // Identify different categories
  streakMaintained,     // Maintain a usage streak
  challengesCompleted,  // Complete challenges
  perfectWeek,          // Use app every day for a week
  knowledgeMaster,      // Complete educational content
  quizCompleted,        // Complete quizzes
  specialItem,          // Identify special or rare items
  communityContribution // Contribute to community challenges
}

/// Represents a badge or trophy that can be earned
class Achievement {
  final String id;
  final String title;
  final String description;
  final AchievementType type;
  final int threshold;  // Number required to earn this achievement
  final String iconName;
  final Color color;
  final bool isSecret;  // Whether this is a hidden achievement
  final DateTime? earnedOn;
  final double progress; // Progress from 0.0 to 1.0
  
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
  });
  
  bool get isEarned => earnedOn != null;
  
  // For serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.toString(),
      'threshold': threshold,
      'iconName': iconName,
      'color': color.value,
      'isSecret': isSecret,
      'earnedOn': earnedOn?.toIso8601String(),
      'progress': progress,
    };
  }
  
  // For deserialization
  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      type: AchievementType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => AchievementType.wasteIdentified,
      ),
      threshold: json['threshold'],
      iconName: json['iconName'],
      color: Color(json['color']),
      isSecret: json['isSecret'] ?? false,
      earnedOn: json['earnedOn'] != null ? DateTime.parse(json['earnedOn']) : null,
      progress: json['progress'] ?? 0.0,
    );
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
    );
  }
}

/// Represents a daily streak of app usage
class Streak {
  final int current;
  final int longest;
  final DateTime lastUsageDate;
  
  const Streak({
    this.current = 0,
    this.longest = 0,
    required this.lastUsageDate,
  });
  
  // For serialization
  Map<String, dynamic> toJson() {
    return {
      'current': current,
      'longest': longest,
      'lastUsageDate': lastUsageDate.toIso8601String(),
    };
  }
  
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
class Challenge {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final int pointsReward;
  final String iconName;
  final Color color;
  final Map<String, dynamic> requirements; // Flexible requirements structure
  final bool isCompleted;
  final double progress; // Progress from 0.0 to 1.0
  final List<String> participantIds; // For team challenges
  
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
      'color': color.value,
      'requirements': requirements,
      'isCompleted': isCompleted,
      'progress': progress,
      'participantIds': participantIds,
    };
  }
  
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
class UserPoints {
  final int total;
  final int weeklyTotal;
  final int monthlyTotal;
  final int level;
  final Map<String, int> categoryPoints; // Points per waste category
  
  const UserPoints({
    this.total = 0,
    this.weeklyTotal = 0,
    this.monthlyTotal = 0,
    this.level = 1,
    this.categoryPoints = const {},
  });
  
  int get pointsToNextLevel => level * 100 - total;
  
  // Get level name based on points
  String get rankName {
    if (level < 5) return "Recycling Rookie";
    if (level < 10) return "Waste Warrior";
    if (level < 15) return "Segregation Specialist";
    if (level < 20) return "Eco Champion";
    if (level < 25) return "Sustainability Sage";
    return "Waste Management Master";
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
class WeeklyStats {
  final DateTime weekStartDate;
  final int itemsIdentified;
  final int challengesCompleted;
  final int streakMaximum;
  final int pointsEarned;
  final Map<String, int> categoryCounts; // Count per waste category
  
  const WeeklyStats({
    required this.weekStartDate,
    this.itemsIdentified = 0,
    this.challengesCompleted = 0,
    this.streakMaximum = 0,
    this.pointsEarned = 0,
    this.categoryCounts = const {},
  });
  
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
class GamificationProfile {
  final String userId;
  final List<Achievement> achievements;
  final Streak streak;
  final UserPoints points;
  final List<Challenge> activeChallenges;
  final List<Challenge> completedChallenges;
  final List<WeeklyStats> weeklyStats;
  
  const GamificationProfile({
    required this.userId,
    this.achievements = const [],
    required this.streak,
    required this.points,
    this.activeChallenges = const [],
    this.completedChallenges = const [],
    this.weeklyStats = const [],
  });
  
  // For serialization
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'achievements': achievements.map((a) => a.toJson()).toList(),
      'streak': streak.toJson(),
      'points': points.toJson(),
      'activeChallenges': activeChallenges.map((c) => c.toJson()).toList(),
      'completedChallenges': completedChallenges.map((c) => c.toJson()).toList(),
      'weeklyStats': weeklyStats.map((s) => s.toJson()).toList(),
    };
  }
  
  // For deserialization
  factory GamificationProfile.fromJson(Map<String, dynamic> json) {
    return GamificationProfile(
      userId: json['userId'],
      achievements: json['achievements'] != null 
          ? List<Map<String, dynamic>>.from(json['achievements'])
              .map((a) => Achievement.fromJson(a))
              .toList()
          : [],
      streak: json['streak'] != null 
          ? Streak.fromJson(json['streak'])
          : Streak(lastUsageDate: DateTime.now()),
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
    );
  }
  
  // Create a copy with updated values
  GamificationProfile copyWith({
    String? userId,
    List<Achievement>? achievements,
    Streak? streak,
    UserPoints? points,
    List<Challenge>? activeChallenges,
    List<Challenge>? completedChallenges,
    List<WeeklyStats>? weeklyStats,
  }) {
    return GamificationProfile(
      userId: userId ?? this.userId,
      achievements: achievements ?? this.achievements,
      streak: streak ?? this.streak,
      points: points ?? this.points,
      activeChallenges: activeChallenges ?? this.activeChallenges,
      completedChallenges: completedChallenges ?? this.completedChallenges,
      weeklyStats: weeklyStats ?? this.weeklyStats,
    );
  }
}