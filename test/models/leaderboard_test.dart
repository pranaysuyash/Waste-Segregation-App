import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/leaderboard.dart';
import 'package:waste_segregation_app/models/gamification.dart' hide LeaderboardEntry;

void main() {
  group('LeaderboardType', () {
    test('should have all expected enum values', () {
      expect(LeaderboardType.values, hasLength(7));
      expect(LeaderboardType.values, contains(LeaderboardType.global));
      expect(LeaderboardType.values, contains(LeaderboardType.family));
      expect(LeaderboardType.values, contains(LeaderboardType.weekly));
      expect(LeaderboardType.values, contains(LeaderboardType.monthly));
      expect(LeaderboardType.values, contains(LeaderboardType.allTime));
      expect(LeaderboardType.values, contains(LeaderboardType.friends));
      expect(LeaderboardType.values, contains(LeaderboardType.regional));
    });
  });

  group('LeaderboardPeriod', () {
    test('should have all expected enum values', () {
      expect(LeaderboardPeriod.values, hasLength(5));
      expect(LeaderboardPeriod.values, contains(LeaderboardPeriod.today));
      expect(LeaderboardPeriod.values, contains(LeaderboardPeriod.thisWeek));
      expect(LeaderboardPeriod.values, contains(LeaderboardPeriod.thisMonth));
      expect(LeaderboardPeriod.values, contains(LeaderboardPeriod.thisYear));
      expect(LeaderboardPeriod.values, contains(LeaderboardPeriod.allTime));
    });
  });

  group('RewardType', () {
    test('should have all expected enum values', () {
      expect(RewardType.values, hasLength(5));
      expect(RewardType.values, contains(RewardType.badge));
      expect(RewardType.values, contains(RewardType.points));
      expect(RewardType.values, contains(RewardType.physical));
      expect(RewardType.values, contains(RewardType.premium));
      expect(RewardType.values, contains(RewardType.recognition));
    });
  });

  group('UserLeaderboardStats', () {
    test('should create with required parameters', () {
      final stats = UserLeaderboardStats(
        totalClassifications: 150,
        currentStreak: 7,
        bestStreak: 15,
        averagePointsPerClassification: 8.5,
        mostActiveDay: 'Monday',
        topCategory: 'Recyclable',
        accuracyPercentage: 92.5,
        totalTimeSpent: 180,
      );

      expect(stats.totalClassifications, equals(150));
      expect(stats.currentStreak, equals(7));
      expect(stats.bestStreak, equals(15));
      expect(stats.averagePointsPerClassification, equals(8.5));
      expect(stats.mostActiveDay, equals('Monday'));
      expect(stats.topCategory, equals('Recyclable'));
      expect(stats.accuracyPercentage, equals(92.5));
      expect(stats.totalTimeSpent, equals(180));
    });

    test('should serialize to and from JSON correctly', () {
      final stats = UserLeaderboardStats(
        totalClassifications: 200,
        currentStreak: 10,
        bestStreak: 25,
        averagePointsPerClassification: 9.2,
        mostActiveDay: 'Wednesday',
        topCategory: 'Organic',
        accuracyPercentage: 95.8,
        totalTimeSpent: 240,
      );

      final json = stats.toJson();
      final fromJson = UserLeaderboardStats.fromJson(json);

      expect(fromJson.totalClassifications, equals(stats.totalClassifications));
      expect(fromJson.currentStreak, equals(stats.currentStreak));
      expect(fromJson.bestStreak, equals(stats.bestStreak));
      expect(fromJson.averagePointsPerClassification, equals(stats.averagePointsPerClassification));
      expect(fromJson.mostActiveDay, equals(stats.mostActiveDay));
      expect(fromJson.topCategory, equals(stats.topCategory));
      expect(fromJson.accuracyPercentage, equals(stats.accuracyPercentage));
      expect(fromJson.totalTimeSpent, equals(stats.totalTimeSpent));
    });

    test('should handle decimal precision correctly', () {
      final stats = UserLeaderboardStats(
        totalClassifications: 87,
        currentStreak: 3,
        bestStreak: 12,
        averagePointsPerClassification: 7.888888,
        mostActiveDay: 'Friday',
        topCategory: 'Hazardous',
        accuracyPercentage: 88.33333,
        totalTimeSpent: 156,
      );

      final json = stats.toJson();
      final fromJson = UserLeaderboardStats.fromJson(json);

      expect(fromJson.averagePointsPerClassification, closeTo(7.888888, 0.000001));
      expect(fromJson.accuracyPercentage, closeTo(88.33333, 0.000001));
    });
  });

  group('LeaderboardReward', () {
    test('should create with required parameters', () {
      final reward = LeaderboardReward(
        rankRange: '1-3',
        name: 'Gold Medal',
        description: 'Awarded to top 3 performers',
        type: RewardType.badge,
      );

      expect(reward.rankRange, equals('1-3'));
      expect(reward.name, equals('Gold Medal'));
      expect(reward.description, equals('Awarded to top 3 performers'));
      expect(reward.type, equals(RewardType.badge));
      expect(reward.iconUrl, isNull);
      expect(reward.value, isNull);
    });

    test('should create with optional parameters', () {
      final reward = LeaderboardReward(
        rankRange: '1',
        name: 'Champion Badge',
        description: 'Ultimate champion reward',
        iconUrl: 'https://example.com/champion.png',
        type: RewardType.premium,
        value: 1000,
      );

      expect(reward.rankRange, equals('1'));
      expect(reward.iconUrl, equals('https://example.com/champion.png'));
      expect(reward.type, equals(RewardType.premium));
      expect(reward.value, equals(1000));
    });

    test('should serialize to and from JSON correctly', () {
      final reward = LeaderboardReward(
        rankRange: '4-10',
        name: 'Silver Medal',
        description: 'Awarded to 4th-10th place',
        iconUrl: 'https://example.com/silver.png',
        type: RewardType.points,
        value: 500,
      );

      final json = reward.toJson();
      final fromJson = LeaderboardReward.fromJson(json);

      expect(fromJson.rankRange, equals(reward.rankRange));
      expect(fromJson.name, equals(reward.name));
      expect(fromJson.description, equals(reward.description));
      expect(fromJson.iconUrl, equals(reward.iconUrl));
      expect(fromJson.type, equals(reward.type));
      expect(fromJson.value, equals(reward.value));
    });

    test('should handle invalid reward type gracefully', () {
      final reward = LeaderboardReward.fromJson({
        'rankRange': '1-5',
        'name': 'Test Reward',
        'description': 'Test description',
        'type': 'invalidType',
      });

      expect(reward.type, equals(RewardType.badge)); // Default fallback
    });
  });

  group('LeaderboardMetadata', () {
    test('should create with required parameters', () {
      final start = DateTime.now();
      final end = start.add(const Duration(days: 7));
      
      final metadata = LeaderboardMetadata(
        title: 'Weekly Challenge',
        description: 'This week\'s leaderboard',
        periodStart: start,
        periodEnd: end,
      );

      expect(metadata.title, equals('Weekly Challenge'));
      expect(metadata.description, equals('This week\'s leaderboard'));
      expect(metadata.periodStart, equals(start));
      expect(metadata.periodEnd, equals(end));
      expect(metadata.isActive, isTrue);
      expect(metadata.rewards, isEmpty);
      expect(metadata.minimumPoints, equals(0));
      expect(metadata.maxEntries, equals(100));
      expect(metadata.showDetailedStats, isTrue);
    });

    test('should create with all optional parameters', () {
      final start = DateTime.now();
      final end = start.add(const Duration(days: 30));
      
      final rewards = [
        LeaderboardReward(
          rankRange: '1',
          name: 'First Place',
          description: 'Winner reward',
          type: RewardType.physical,
          value: 100,
        ),
      ];
      
      final metadata = LeaderboardMetadata(
        title: 'Monthly Championship',
        description: 'The ultimate monthly competition',
        periodStart: start,
        periodEnd: end,
        isActive: false,
        rewards: rewards,
        minimumPoints: 50,
        maxEntries: 50,
        showDetailedStats: false,
      );

      expect(metadata.isActive, isFalse);
      expect(metadata.rewards, hasLength(1));
      expect(metadata.minimumPoints, equals(50));
      expect(metadata.maxEntries, equals(50));
      expect(metadata.showDetailedStats, isFalse);
    });

    test('should calculate isCurrentlyActive correctly', () {
      final now = DateTime.now();
      
      // Active period
      final activeMetadata = LeaderboardMetadata(
        title: 'Active',
        description: 'Active period',
        periodStart: now.subtract(const Duration(days: 1)),
        periodEnd: now.add(const Duration(days: 1)),
        isActive: true,
      );

      // Expired period
      final expiredMetadata = LeaderboardMetadata(
        title: 'Expired',
        description: 'Expired period',
        periodStart: now.subtract(const Duration(days: 10)),
        periodEnd: now.subtract(const Duration(days: 3)),
        isActive: true,
      );

      // Future period
      final futureMetadata = LeaderboardMetadata(
        title: 'Future',
        description: 'Future period',
        periodStart: now.add(const Duration(days: 1)),
        periodEnd: now.add(const Duration(days: 8)),
        isActive: true,
      );

      // Inactive
      final inactiveMetadata = LeaderboardMetadata(
        title: 'Inactive',
        description: 'Inactive period',
        periodStart: now.subtract(const Duration(days: 1)),
        periodEnd: now.add(const Duration(days: 1)),
        isActive: false,
      );

      expect(activeMetadata.isCurrentlyActive, isTrue);
      expect(expiredMetadata.isCurrentlyActive, isFalse);
      expect(futureMetadata.isCurrentlyActive, isFalse);
      expect(inactiveMetadata.isCurrentlyActive, isFalse);
    });

    test('should calculate timeRemaining correctly', () {
      final now = DateTime.now();
      
      // 2 hours remaining
      final futureEnd = LeaderboardMetadata(
        title: 'Future End',
        description: 'Ends in 2 hours',
        periodStart: now.subtract(const Duration(hours: 1)),
        periodEnd: now.add(const Duration(hours: 2)),
      );

      // Already ended
      final pastEnd = LeaderboardMetadata(
        title: 'Past End',
        description: 'Already ended',
        periodStart: now.subtract(const Duration(days: 5)),
        periodEnd: now.subtract(const Duration(days: 1)),
      );

      expect(futureEnd.timeRemaining.inMilliseconds, closeTo(const Duration(hours: 2).inMilliseconds, 5000)); // Check within a 5s tolerance
      expect(pastEnd.timeRemaining, equals(Duration.zero));
    });

    test('should serialize to and from JSON correctly', () {
      final start = DateTime.parse('2023-12-01T00:00:00.000Z');
      final end = DateTime.parse('2023-12-31T23:59:59.999Z');
      
      final rewards = [
        LeaderboardReward(
          rankRange: '1-3',
          name: 'Top Three',
          description: 'Top three performers',
          type: RewardType.recognition,
        ),
      ];
      
      final metadata = LeaderboardMetadata(
        title: 'December Challenge',
        description: 'End of year challenge',
        periodStart: start,
        periodEnd: end,
        isActive: true,
        rewards: rewards,
        minimumPoints: 25,
        maxEntries: 75,
        showDetailedStats: true,
      );

      final json = metadata.toJson();
      final fromJson = LeaderboardMetadata.fromJson(json);

      expect(fromJson.title, equals(metadata.title));
      expect(fromJson.description, equals(metadata.description));
      expect(fromJson.periodStart, equals(metadata.periodStart));
      expect(fromJson.periodEnd, equals(metadata.periodEnd));
      expect(fromJson.isActive, equals(metadata.isActive));
      expect(fromJson.rewards, hasLength(1));
      expect(fromJson.minimumPoints, equals(metadata.minimumPoints));
      expect(fromJson.maxEntries, equals(metadata.maxEntries));
      expect(fromJson.showDetailedStats, equals(metadata.showDetailedStats));
    });
  });

  group('LeaderboardEntry', () {
    test('should create with required parameters', () {
      final entry = LeaderboardEntry(
        userId: 'user123',
        displayName: 'John Doe',
        points: 1500,
      );

      expect(entry.userId, equals('user123'));
      expect(entry.displayName, equals('John Doe'));
      expect(entry.points, equals(1500));
      expect(entry.photoUrl, isNull);
      expect(entry.rank, isNull);
      expect(entry.previousRank, isNull);
      expect(entry.categoryBreakdown, isEmpty);
      expect(entry.recentAchievements, isEmpty);
      expect(entry.stats, isNull);
      expect(entry.isCurrentUser, isFalse);
      expect(entry.familyId, isNull);
      expect(entry.familyName, isNull);
    });

    test('should create with all optional parameters', () {
      final achievement = Achievement(
        id: 'ach1',
        title: 'Test Achievement',
        description: 'Test description',
        type: AchievementType.wasteIdentified,
        threshold: 10,
        iconName: 'star',
        color: Colors.blue,
      );

      final stats = UserLeaderboardStats(
        totalClassifications: 100,
        currentStreak: 5,
        bestStreak: 10,
        averagePointsPerClassification: 7.5,
        mostActiveDay: 'Tuesday',
        topCategory: 'Plastic',
        accuracyPercentage: 90.0,
        totalTimeSpent: 120,
      );

      final entry = LeaderboardEntry(
        userId: 'user456',
        displayName: 'Jane Smith',
        photoUrl: 'https://example.com/avatar.jpg',
        points: 2500,
        rank: 3,
        previousRank: 5,
        categoryBreakdown: {'Plastic': 1000, 'Metal': 800, 'Paper': 700},
        recentAchievements: [achievement],
        stats: stats,
        isCurrentUser: true,
        familyId: 'family123',
        familyName: 'Smith Family',
      );

      expect(entry.photoUrl, equals('https://example.com/avatar.jpg'));
      expect(entry.rank, equals(3));
      expect(entry.previousRank, equals(5));
      expect(entry.categoryBreakdown, hasLength(3));
      expect(entry.recentAchievements, hasLength(1));
      expect(entry.stats, isNotNull);
      expect(entry.isCurrentUser, isTrue);
      expect(entry.familyId, equals('family123'));
      expect(entry.familyName, equals('Smith Family'));
    });

    test('should calculate rankChange correctly', () {
      final improvedEntry = LeaderboardEntry(
        userId: 'improved',
        displayName: 'Improved User',
        points: 1000,
        rank: 2,
        previousRank: 5,
      );

      final declinedEntry = LeaderboardEntry(
        userId: 'declined',
        displayName: 'Declined User',
        points: 800,
        rank: 8,
        previousRank: 3,
      );

      final noChangeEntry = LeaderboardEntry(
        userId: 'same',
        displayName: 'Same User',
        points: 600,
        rank: 10,
        previousRank: 10,
      );

      final newEntry = LeaderboardEntry(
        userId: 'new',
        displayName: 'New User',
        points: 400,
        rank: 15,
      );

      expect(improvedEntry.rankChange, equals(3)); // 5 - 2 = 3 (improved)
      expect(declinedEntry.rankChange, equals(-5)); // 3 - 8 = -5 (declined)
      expect(noChangeEntry.rankChange, equals(0)); // 10 - 10 = 0 (no change)
      expect(newEntry.rankChange, isNull); // No previous rank
    });

    test('should calculate topCategoryPercentage correctly', () {
      final entry = LeaderboardEntry(
        userId: 'test',
        displayName: 'Test User',
        points: 1000,
        categoryBreakdown: {'Category1': 500, 'Category2': 300, 'Category3': 200},
      );

      final emptyEntry = LeaderboardEntry(
        userId: 'empty',
        displayName: 'Empty User',
        points: 0,
      );

      final zeroPointsEntry = LeaderboardEntry(
        userId: 'zero',
        displayName: 'Zero User',
        points: 0,
        categoryBreakdown: {'Category1': 0},
      );

      expect(entry.topCategoryPercentage, equals(0.5)); // 500/1000 = 0.5
      expect(emptyEntry.topCategoryPercentage, equals(0.0));
      expect(zeroPointsEntry.topCategoryPercentage, equals(0.0));
    });

    test('should serialize to and from JSON correctly', () {
      final achievement = Achievement(
        id: 'json_ach',
        title: 'JSON Achievement',
        description: 'JSON description',
        type: AchievementType.recyclingExpert,
        threshold: 25,
        iconName: 'recycle',
        color: Colors.green,
      );

      final stats = UserLeaderboardStats(
        totalClassifications: 75,
        currentStreak: 3,
        bestStreak: 8,
        averagePointsPerClassification: 6.8,
        mostActiveDay: 'Sunday',
        topCategory: 'Glass',
        accuracyPercentage: 87.5,
        totalTimeSpent: 95,
      );

      final entry = LeaderboardEntry(
        userId: 'json_user',
        displayName: 'JSON User',
        photoUrl: 'https://example.com/json.jpg',
        points: 1750,
        rank: 7,
        previousRank: 9,
        categoryBreakdown: {'Glass': 700, 'Plastic': 600, 'Metal': 450},
        recentAchievements: [achievement],
        stats: stats,
        isCurrentUser: false,
        familyId: 'json_family',
        familyName: 'JSON Family',
      );

      final json = entry.toJson();
      final fromJson = LeaderboardEntry.fromJson(json);

      expect(fromJson.userId, equals(entry.userId));
      expect(fromJson.displayName, equals(entry.displayName));
      expect(fromJson.photoUrl, equals(entry.photoUrl));
      expect(fromJson.points, equals(entry.points));
      expect(fromJson.rank, equals(entry.rank));
      expect(fromJson.previousRank, equals(entry.previousRank));
      expect(fromJson.categoryBreakdown, equals(entry.categoryBreakdown));
      expect(fromJson.recentAchievements, hasLength(1));
      expect(fromJson.stats, isNotNull);
      expect(fromJson.isCurrentUser, equals(entry.isCurrentUser));
      expect(fromJson.familyId, equals(entry.familyId));
      expect(fromJson.familyName, equals(entry.familyName));
    });

    test('should handle JSON with defaults', () {
      final entry = LeaderboardEntry.fromJson({
        'userId': 'minimal',
        'displayName': 'Minimal User',
      });

      expect(entry.points, equals(0));
      expect(entry.rank, isNull);
      expect(entry.categoryBreakdown, isEmpty);
      expect(entry.recentAchievements, isEmpty);
      expect(entry.isCurrentUser, isFalse);
    });

    test('should copyWith correctly', () {
      final original = LeaderboardEntry(
        userId: 'original',
        displayName: 'Original User',
        points: 1000,
        rank: 5,
      );

      final updated = original.copyWith(
        displayName: 'Updated User',
        points: 1500,
        rank: 3,
        isCurrentUser: true,
      );

      expect(updated.userId, equals('original')); // Unchanged
      expect(updated.displayName, equals('Updated User')); // Changed
      expect(updated.points, equals(1500)); // Changed
      expect(updated.rank, equals(3)); // Changed
      expect(updated.isCurrentUser, isTrue); // Changed
      expect(original.displayName, equals('Original User')); // Original unchanged
    });
  });

  group('Leaderboard', () {
    test('should create with required parameters', () {
      final lastUpdated = DateTime.now();
      final entries = [
        LeaderboardEntry(userId: 'user1', displayName: 'User 1', points: 1000, rank: 1),
        LeaderboardEntry(userId: 'user2', displayName: 'User 2', points: 800, rank: 2),
      ];
      final metadata = LeaderboardMetadata(
        title: 'Test Board',
        description: 'Test description',
        periodStart: DateTime.now().subtract(const Duration(days: 7)),
        periodEnd: DateTime.now().add(const Duration(days: 7)),
      );

      final leaderboard = Leaderboard(
        type: LeaderboardType.weekly,
        period: LeaderboardPeriod.thisWeek,
        entries: entries,
        lastUpdated: lastUpdated,
        metadata: metadata,
        totalParticipants: 100,
      );

      expect(leaderboard.type, equals(LeaderboardType.weekly));
      expect(leaderboard.period, equals(LeaderboardPeriod.thisWeek));
      expect(leaderboard.entries, hasLength(2));
      expect(leaderboard.lastUpdated, equals(lastUpdated));
      expect(leaderboard.metadata, equals(metadata));
      expect(leaderboard.totalParticipants, equals(100));
      expect(leaderboard.currentUserEntry, isNull);
      expect(leaderboard.familyId, isNull);
    });

    test('should getTopEntries correctly', () {
      final entries = List.generate(10, (i) => LeaderboardEntry(
        userId: 'user$i',
        displayName: 'User $i',
        points: 1000 - (i * 100),
        rank: i + 1,
      ));

      final leaderboard = Leaderboard(
        type: LeaderboardType.global,
        period: LeaderboardPeriod.allTime,
        entries: entries,
        lastUpdated: DateTime.now(),
        metadata: LeaderboardMetadata(
          title: 'Global',
          description: 'Global leaderboard',
          periodStart: DateTime.now().subtract(const Duration(days: 365)),
          periodEnd: DateTime.now(),
        ),
        totalParticipants: 1000,
      );

      final top3 = leaderboard.getTopEntries(3);
      final top5 = leaderboard.getTopEntries(5);
      final tooMany = leaderboard.getTopEntries(20);

      expect(top3, hasLength(3));
      expect(top3[0].userId, equals('user0'));
      expect(top3[2].userId, equals('user2'));

      expect(top5, hasLength(5));
      expect(top5[4].userId, equals('user4'));

      expect(tooMany, hasLength(10)); // Limited by actual entries
    });

    test('should getEntryByUserId correctly', () {
      final entries = [
        LeaderboardEntry(userId: 'alice', displayName: 'Alice', points: 1000, rank: 1),
        LeaderboardEntry(userId: 'bob', displayName: 'Bob', points: 800, rank: 2),
        LeaderboardEntry(userId: 'charlie', displayName: 'Charlie', points: 600, rank: 3),
      ];

      final leaderboard = Leaderboard(
        type: LeaderboardType.family,
        period: LeaderboardPeriod.thisMonth,
        entries: entries,
        lastUpdated: DateTime.now(),
        metadata: LeaderboardMetadata(
          title: 'Family',
          description: 'Family leaderboard',
          periodStart: DateTime.now().subtract(const Duration(days: 30)),
          periodEnd: DateTime.now(),
        ),
        totalParticipants: 3,
      );

      final aliceEntry = leaderboard.getEntryByUserId('alice');
      final bobEntry = leaderboard.getEntryByUserId('bob');
      final nonExistentEntry = leaderboard.getEntryByUserId('david');

      expect(aliceEntry, isNotNull);
      expect(aliceEntry?.displayName, equals('Alice'));
      expect(bobEntry, isNotNull);
      expect(bobEntry?.displayName, equals('Bob'));
      expect(nonExistentEntry, isNull);
    });

    test('should getEntriesInRange correctly', () {
      final entries = List.generate(15, (i) => LeaderboardEntry(
        userId: 'user$i',
        displayName: 'User $i',
        points: 1500 - (i * 100),
        rank: i + 1,
      ));

      final leaderboard = Leaderboard(
        type: LeaderboardType.global,
        period: LeaderboardPeriod.allTime,
        entries: entries,
        lastUpdated: DateTime.now(),
        metadata: LeaderboardMetadata(
          title: 'Global',
          description: 'Global leaderboard',
          periodStart: DateTime.now().subtract(const Duration(days: 365)),
          periodEnd: DateTime.now(),
        ),
        totalParticipants: 15,
      );

      final top5 = leaderboard.getEntriesInRange(1, 5);
      final middle5 = leaderboard.getEntriesInRange(6, 10);
      final last3 = leaderboard.getEntriesInRange(13, 15);

      expect(top5, hasLength(5));
      expect(top5[0].rank, equals(1));
      expect(top5[4].rank, equals(5));

      expect(middle5, hasLength(5));
      expect(middle5[0].rank, equals(6));
      expect(middle5[4].rank, equals(10));

      expect(last3, hasLength(3));
      expect(last3[0].rank, equals(13));
      expect(last3[2].rank, equals(15));
    });

    test('should getMinimumScoreForTopN correctly', () {
      final entries = [
        LeaderboardEntry(userId: 'user1', displayName: 'User 1', points: 1000, rank: 1),
        LeaderboardEntry(userId: 'user2', displayName: 'User 2', points: 900, rank: 2),
        LeaderboardEntry(userId: 'user3', displayName: 'User 3', points: 800, rank: 3),
        LeaderboardEntry(userId: 'user4', displayName: 'User 4', points: 700, rank: 4),
        LeaderboardEntry(userId: 'user5', displayName: 'User 5', points: 600, rank: 5),
      ];

      final leaderboard = Leaderboard(
        type: LeaderboardType.global,
        period: LeaderboardPeriod.allTime,
        entries: entries,
        lastUpdated: DateTime.now(),
        metadata: LeaderboardMetadata(
          title: 'Global',
          description: 'Global leaderboard',
          periodStart: DateTime.now().subtract(const Duration(days: 365)),
          periodEnd: DateTime.now(),
        ),
        totalParticipants: 5,
      );

      expect(leaderboard.getMinimumScoreForTopN(3), equals(800)); // 3rd place score
      expect(leaderboard.getMinimumScoreForTopN(5), equals(600)); // 5th place score
      expect(leaderboard.getMinimumScoreForTopN(10), isNull); // Not enough entries
    });

    test('should serialize to and from JSON correctly', () {
      final entries = [
        LeaderboardEntry(userId: 'json1', displayName: 'JSON User 1', points: 500, rank: 1),
        LeaderboardEntry(userId: 'json2', displayName: 'JSON User 2', points: 400, rank: 2),
      ];

      final currentUser = LeaderboardEntry(
        userId: 'current',
        displayName: 'Current User',
        points: 300,
        rank: 15,
        isCurrentUser: true,
      );

      final metadata = LeaderboardMetadata(
        title: 'JSON Test',
        description: 'JSON test leaderboard',
        periodStart: DateTime.parse('2023-01-01T00:00:00.000Z'),
        periodEnd: DateTime.parse('2023-12-31T23:59:59.999Z'),
      );

      final leaderboard = Leaderboard(
        type: LeaderboardType.monthly,
        period: LeaderboardPeriod.thisMonth,
        entries: entries,
        lastUpdated: DateTime.parse('2023-06-15T12:00:00.000Z'),
        metadata: metadata,
        currentUserEntry: currentUser,
        totalParticipants: 500,
        familyId: 'json_family',
      );

      final json = leaderboard.toJson();
      final fromJson = Leaderboard.fromJson(json);

      expect(fromJson.type, equals(leaderboard.type));
      expect(fromJson.period, equals(leaderboard.period));
      expect(fromJson.entries, hasLength(2));
      expect(fromJson.lastUpdated, equals(leaderboard.lastUpdated));
      expect(fromJson.currentUserEntry, isNotNull);
      expect(fromJson.totalParticipants, equals(leaderboard.totalParticipants));
      expect(fromJson.familyId, equals(leaderboard.familyId));
    });

    test('should handle JSON with enum defaults', () {
      final leaderboard = Leaderboard.fromJson({
        'type': 'invalidType',
        'period': 'invalidPeriod',
        'entries': [],
        'lastUpdated': DateTime.now().toIso8601String(),
        'metadata': {
          'title': 'Test',
          'description': 'Test',
          'periodStart': DateTime.now().toIso8601String(),
          'periodEnd': DateTime.now().toIso8601String(),
        },
        'totalParticipants': 0,
      });

      expect(leaderboard.type, equals(LeaderboardType.global)); // Default
      expect(leaderboard.period, equals(LeaderboardPeriod.allTime)); // Default
    });

    test('should copyWith correctly', () {
      final original = Leaderboard(
        type: LeaderboardType.global,
        period: LeaderboardPeriod.allTime,
        entries: [],
        lastUpdated: DateTime.now(),
        metadata: LeaderboardMetadata(
          title: 'Original',
          description: 'Original description',
          periodStart: DateTime.now(),
          periodEnd: DateTime.now(),
        ),
        totalParticipants: 100,
      );

      final newEntry = LeaderboardEntry(
        userId: 'new',
        displayName: 'New User',
        points: 1000,
      );

      final updated = original.copyWith(
        type: LeaderboardType.family,
        entries: [newEntry],
        totalParticipants: 200,
        familyId: 'new_family',
      );

      expect(updated.type, equals(LeaderboardType.family));
      expect(updated.period, equals(LeaderboardPeriod.allTime)); // Unchanged
      expect(updated.entries, hasLength(1));
      expect(updated.totalParticipants, equals(200));
      expect(updated.familyId, equals('new_family'));
      expect(original.type, equals(LeaderboardType.global)); // Original unchanged
      expect(original.entries, isEmpty); // Original unchanged
    });
  });

  group('Edge Cases and Integration', () {
    test('should handle empty leaderboard', () {
      final emptyLeaderboard = Leaderboard(
        type: LeaderboardType.global,
        period: LeaderboardPeriod.today,
        entries: [],
        lastUpdated: DateTime.now(),
        metadata: LeaderboardMetadata(
          title: 'Empty',
          description: 'Empty leaderboard',
          periodStart: DateTime.now(),
          periodEnd: DateTime.now().add(const Duration(hours: 1)),
        ),
        totalParticipants: 0,
      );

      expect(emptyLeaderboard.getTopEntries(5), isEmpty);
      expect(emptyLeaderboard.getEntryByUserId('anyone'), isNull);
      expect(emptyLeaderboard.getEntriesInRange(1, 10), isEmpty);
      expect(emptyLeaderboard.getMinimumScoreForTopN(1), isNull);
    });

    test('should handle entries without ranks', () {
      final entriesWithoutRanks = [
        LeaderboardEntry(userId: 'user1', displayName: 'User 1', points: 1000),
        LeaderboardEntry(userId: 'user2', displayName: 'User 2', points: 800),
      ];

      final leaderboard = Leaderboard(
        type: LeaderboardType.global,
        period: LeaderboardPeriod.allTime,
        entries: entriesWithoutRanks,
        lastUpdated: DateTime.now(),
        metadata: LeaderboardMetadata(
          title: 'No Ranks',
          description: 'Leaderboard without ranks',
          periodStart: DateTime.now(),
          periodEnd: DateTime.now(),
        ),
        totalParticipants: 2,
      );

      expect(leaderboard.getEntriesInRange(1, 5), isEmpty); // No entries have ranks
      expect(entriesWithoutRanks[0].rankChange, isNull);
    });

    test('should handle very large leaderboards', () {
      final largeEntries = List.generate(10000, (i) => LeaderboardEntry(
        userId: 'user$i',
        displayName: 'User $i',
        points: 100000 - i,
        rank: i + 1,
        categoryBreakdown: {
          'Cat1': (100000 - i) ~/ 3,
          'Cat2': (100000 - i) ~/ 3,
          'Cat3': (100000 - i) ~/ 3,
        },
      ));

      final largeLeaderboard = Leaderboard(
        type: LeaderboardType.global,
        period: LeaderboardPeriod.allTime,
        entries: largeEntries,
        lastUpdated: DateTime.now(),
        metadata: LeaderboardMetadata(
          title: 'Large',
          description: 'Very large leaderboard',
          periodStart: DateTime.now().subtract(const Duration(days: 365)),
          periodEnd: DateTime.now(),
        ),
        totalParticipants: 10000,
      );

      expect(largeLeaderboard.entries, hasLength(10000));
      expect(largeLeaderboard.getTopEntries(100), hasLength(100));
      expect(largeLeaderboard.getEntryByUserId('user5000'), isNotNull);
      expect(largeLeaderboard.getMinimumScoreForTopN(1000), equals(99001));

      // Test serialization performance with large data
      final json = largeLeaderboard.toJson();
      expect(json['entries'], hasLength(10000));
    });

    test('should maintain consistency across serialization cycles', () {
      final achievement = Achievement(
        id: 'consistency_test',
        title: 'Consistency Achievement',
        description: 'Testing consistency',
        type: AchievementType.ecoWarrior,
        threshold: 50,
        iconName: 'eco',
        color: Colors.green,
      );

      final stats = UserLeaderboardStats(
        totalClassifications: 123,
        currentStreak: 7,
        bestStreak: 21,
        averagePointsPerClassification: 8.247,
        mostActiveDay: 'Thursday',
        topCategory: 'Electronic',
        accuracyPercentage: 94.2857,
        totalTimeSpent: 347,
      );

      final entry = LeaderboardEntry(
        userId: 'consistency_user',
        displayName: 'Consistency User',
        points: 1013,
        rank: 42,
        previousRank: 45,
        categoryBreakdown: {'Electronic': 400, 'Plastic': 350, 'Metal': 263},
        recentAchievements: [achievement],
        stats: stats,
      );

      // Multiple serialization cycles
      var json = entry.toJson();
      var deserialized = LeaderboardEntry.fromJson(json);
      json = deserialized.toJson();
      deserialized = LeaderboardEntry.fromJson(json);
      json = deserialized.toJson();
      final finalDeserialized = LeaderboardEntry.fromJson(json);

      expect(finalDeserialized.userId, equals(entry.userId));
      expect(finalDeserialized.points, equals(entry.points));
      expect(finalDeserialized.rankChange, equals(entry.rankChange));
      expect(finalDeserialized.categoryBreakdown, equals(entry.categoryBreakdown));
      expect(finalDeserialized.recentAchievements, hasLength(1));
      expect(finalDeserialized.stats?.averagePointsPerClassification, closeTo(8.247, 0.001));
      expect(finalDeserialized.topCategoryPercentage, closeTo(0.3950, 0.001));
    });
  });
}
