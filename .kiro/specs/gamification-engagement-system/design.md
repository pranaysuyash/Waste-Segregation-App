# Design Document: Gamification & Engagement System

## Overview

This design document outlines the architecture for implementing a comprehensive gamification system that transforms the Waste Segregation App from a utility tool into an engaging habit-forming platform. The system includes points, badges, streaks, challenges, and leaderboards designed to drive user engagement and retention.

### Goals

1. **Increase User Engagement** - Daily active users through streaks and challenges
2. **Drive Behavioral Change** - Consistent waste classification habits
3. **Build Community** - Social features and friendly competition
4. **Reward Progress** - Recognition through badges and achievements
5. **Ensure Consistency** - Atomic operations and real-time updates

## Architecture

### Gamification System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                        │
├─────────────────────────────────────────────────────────────┤
│  Profile Screen │ Leaderboard │ Achievements │ Challenges   │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                   State Management Layer                     │
├─────────────────────────────────────────────────────────────┤
│  GamificationProvider │ PointsNotifier │ BadgeNotifier      │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                      Service Layer                           │
├─────────────────────────────────────────────────────────────┤
│  PointsEngine │ BadgeService │ StreakService │ ChallengeService │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                       Data Layer                             │
├─────────────────────────────────────────────────────────────┤
│  Firestore (Cloud) │ Hive (Local) │ Transaction Logs        │
└─────────────────────────────────────────────────────────────┘
```

## Components and Interfaces

### 1. Points Engine

```dart
class PointsEngine {
  /// Award points for an action with atomic transaction
  Future<PointsTransaction> awardPoints({
    required String userId,
    required int points,
    required PointsAction action,
    Map<String, dynamic>? metadata,
  }) async {
    // Atomic Firestore transaction
    return await _firestore.runTransaction((transaction) async {
      final userRef = _firestore.collection('users').doc(userId);
      final snapshot = await transaction.get(userRef);
      
      final currentPoints = snapshot.data()?['points'] ?? 0;
      final newPoints = currentPoints + points;
      
      transaction.update(userRef, {
        'points': newPoints,
        'lastPointsUpdate': FieldValue.serverTimestamp(),
      });
      
      // Create transaction log
      final logRef = _firestore.collection('pointsTransactions').doc();
      transaction.set(logRef, {
        'userId': userId,
        'points': points,
        'action': action.toString(),
        'metadata': metadata,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      return PointsTransaction(
        id: logRef.id,
        userId: userId,
        points: points,
        action: action,
        timestamp: DateTime.now(),
      );
    });
  }
}
```

### 2. Badge Service

```dart
class BadgeService {
  /// Evaluate and award badges based on user stats
  Future<List<Badge>> evaluateBadges(String userId) async {
    final userStats = await _getUserStats(userId);
    final unearnedBadges = await _getUnearnedBadges(userId);
    final newlyEarnedBadges = <Badge>[];
    
    for (final badge in unearnedBadges) {
      if (await _meetsCriteria(badge, userStats)) {
        await _awardBadge(userId, badge);
        newlyEarnedBadges.add(badge);
      }
    }
    
    return newlyEarnedBadges;
  }
  
  Future<bool> _meetsCriteria(Badge badge, UserStats stats) async {
    switch (badge.type) {
      case BadgeType.classification:
        return stats.classificationCount >= badge.threshold;
      case BadgeType.learning:
        return stats.contentCompletionCount >= badge.threshold;
      case BadgeType.streak:
        return stats.maxStreak >= badge.threshold;
      case BadgeType.diversity:
        return stats.uniqueCategories >= badge.threshold;
      default:
        return false;
    }
  }
}
```

### 3. Streak Service

```dart
class StreakService {
  /// Update streak with grace period support
  Future<StreakUpdate> updateStreak({
    required String userId,
    required StreakType type,
  }) async {
    final now = DateTime.now();
    final streak = await _getCurrentStreak(userId, type);
    
    // Check if action already performed today
    if (_isToday(streak.lastUpdate)) {
      return StreakUpdate(
        streak: streak,
        updated: false,
        reason: 'Already updated today',
      );
    }
    
    // Check if within grace period (24 hours)
    final daysSinceLastUpdate = now.difference(streak.lastUpdate).inDays;
    
    if (daysSinceLastUpdate == 1) {
      // Consecutive day - increment streak
      return await _incrementStreak(userId, type, streak);
    } else if (daysSinceLastUpdate == 2 && !streak.graceUsedThisWeek) {
      // Grace period - preserve streak
      return await _useGracePeriod(userId, type, streak);
    } else {
      // Streak broken - reset
      return await _resetStreak(userId, type);
    }
  }
}
```

## Data Models

```dart
class GamificationProfile {
  final String userId;
  final int points;
  final List<String> badgeIds;
  final Map<String, int> streaks;
  final List<String> activeChallengeIds;
  final DateTime lastUpdated;
  
  // Computed properties
  int get level => (points / 100).floor() + 1;
  int get pointsToNextLevel => ((level * 100) - points);
}

class Badge {
  final String id;
  final String name;
  final String description;
  final String iconUrl;
  final BadgeType type;
  final BadgeTier tier;
  final int threshold;
  final int bonusPoints;
  final bool isSecret;
}

class Challenge {
  final String id;
  final String name;
  final String description;
  final ChallengeType type;
  final int goal;
  final int rewardPoints;
  final DateTime startDate;
  final DateTime endDate;
  final bool isDaily;
}

class PointsTransaction {
  final String id;
  final String userId;
  final int points;
  final PointsAction action;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;
}
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do.*

**Property 1: Points Atomicity**
*For any* points award operation, the user's point balance and transaction log should be updated atomically or not at all
**Validates: Requirements 1.5, 8.2**

**Property 2: Badge Uniqueness**
*For any* badge award, a user should receive each badge exactly once
**Validates: Requirements 2.1, 2.2**

**Property 3: Streak Consistency**
*For any* consecutive day activity, the streak count should increment by exactly 1
**Validates: Requirements 3.1, 3.2**

**Property 4: Challenge Progress Monotonicity**
*For any* challenge-related action, progress should only increase, never decrease
**Validates: Requirements 10.1, 10.2**

**Property 5: Leaderboard Ordering**
*For any* leaderboard query, users should be ordered by total points in descending order
**Validates: Requirements 5.2**

## Error Handling

```dart
class GamificationErrorHandler {
  static Future<T> withRetry<T>({
    required Future<T> Function() operation,
    int maxAttempts = 3,
  }) async {
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        return await operation();
      } catch (e) {
        if (attempt == maxAttempts - 1) rethrow;
        await Future.delayed(Duration(seconds: pow(2, attempt).toInt()));
      }
    }
    throw Exception('Max retries exceeded');
  }
}
```

## Testing Strategy

### Property-Based Testing
- Use `package:test` with custom generators
- Minimum 100 iterations per property test
- Test concurrent operations for race conditions

### Unit Testing
- Test badge criteria evaluation
- Test streak calculation logic
- Test points calculation formulas

### Integration Testing
- Test end-to-end gamification flows
- Test offline sync and conflict resolution
- Test real-time UI updates

This design provides a robust, scalable gamification system that drives user engagement while maintaining data consistency and real-time responsiveness.
