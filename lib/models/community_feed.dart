import 'package:flutter/material.dart';

/// Represents a community feed item showing user activities
class CommunityFeedItem {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final CommunityActivityType activityType;
  final String title;
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;
  final int likes;
  final List<String> likedBy;
  final bool isAnonymous;
  final int points;

  const CommunityFeedItem({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.activityType,
    required this.title,
    required this.description,
    required this.timestamp,
    this.metadata = const {},
    this.likes = 0,
    this.likedBy = const [],
    this.isAnonymous = false,
    this.points = 0,
  });

  factory CommunityFeedItem.fromJson(Map<String, dynamic> json) {
    return CommunityFeedItem(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? 'Anonymous User',
      userAvatar: json['userAvatar'],
      activityType: CommunityActivityType.values.firstWhere(
        (type) => type.name == json['activityType'],
        orElse: () => CommunityActivityType.classification,
      ),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      likes: json['likes'] ?? 0,
      likedBy: List<String>.from(json['likedBy'] ?? []),
      isAnonymous: json['isAnonymous'] ?? false,
      points: json['points'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'activityType': activityType.name,
      'title': title,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
      'likes': likes,
      'likedBy': likedBy,
      'isAnonymous': isAnonymous,
      'points': points,
    };
  }

  CommunityFeedItem copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userAvatar,
    CommunityActivityType? activityType,
    String? title,
    String? description,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
    int? likes,
    List<String>? likedBy,
    bool? isAnonymous,
    int? points,
  }) {
    return CommunityFeedItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      activityType: activityType ?? this.activityType,
      title: title ?? this.title,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
      likes: likes ?? this.likes,
      likedBy: likedBy ?? this.likedBy,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      points: points ?? this.points,
    );
  }

  /// Get display name (respects anonymity)
  String get displayName {
    if (isAnonymous) {
      return 'Anonymous User';
    }
    return userName.isNotEmpty ? userName : 'User';
  }

  /// Get relative time string
  String get relativeTime {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }

  /// Get activity icon
  IconData get activityIcon {
    switch (activityType) {
      case CommunityActivityType.classification:
        return Icons.camera_alt;
      case CommunityActivityType.achievement:
        return Icons.emoji_events;
      case CommunityActivityType.streak:
        return Icons.local_fire_department;
      case CommunityActivityType.challenge:
        return Icons.task_alt;
      case CommunityActivityType.milestone:
        return Icons.star;
      case CommunityActivityType.educational:
        return Icons.school;
    }
  }

  /// Get activity color
  Color get activityColor {
    switch (activityType) {
      case CommunityActivityType.classification:
        return Colors.blue;
      case CommunityActivityType.achievement:
        return Colors.amber;
      case CommunityActivityType.streak:
        return Colors.orange;
      case CommunityActivityType.challenge:
        return Colors.green;
      case CommunityActivityType.milestone:
        return Colors.purple;
      case CommunityActivityType.educational:
        return Colors.indigo;
    }
  }
}

/// Types of community activities
enum CommunityActivityType {
  classification,
  achievement,
  streak,
  challenge,
  milestone,
  educational,
}

/// Community feed statistics
class CommunityStats {
  final int totalUsers;
  final int totalClassifications;
  final int totalAchievements;
  final int totalPoints;
  final int activeToday;
  final int activeUsers;
  final int weeklyClassifications;
  final Map<String, int> categoryBreakdown;
  final DateTime lastUpdated;

  const CommunityStats({
    required this.totalUsers,
    required this.totalClassifications,
    required this.totalAchievements,
    this.totalPoints = 0,
    required this.activeToday,
    this.activeUsers = 0,
    this.weeklyClassifications = 0,
    required this.categoryBreakdown,
    required this.lastUpdated,
  });

  factory CommunityStats.fromJson(Map<String, dynamic> json) {
    return CommunityStats(
      totalUsers: json['totalUsers'] ?? 0,
      totalClassifications: json['totalClassifications'] ?? 0,
      totalAchievements: json['totalAchievements'] ?? 0,
      totalPoints: json['totalPoints'] ?? 0,
      activeToday: json['activeToday'] ?? 0,
      activeUsers: json['activeUsers'] ?? 0,
      weeklyClassifications: json['weeklyClassifications'] ?? 0,
      categoryBreakdown: Map<String, int>.from(json['categoryBreakdown'] ?? {}),
      lastUpdated: DateTime.tryParse(json['lastUpdated'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalUsers': totalUsers,
      'totalClassifications': totalClassifications,
      'totalAchievements': totalAchievements,
      'totalPoints': totalPoints,
      'activeToday': activeToday,
      'activeUsers': activeUsers,
      'weeklyClassifications': weeklyClassifications,
      'categoryBreakdown': categoryBreakdown,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  /// Get top categories as a map for display
  Map<String, int> get topCategories {
    final sorted = categoryBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted.take(5));
  }
} 