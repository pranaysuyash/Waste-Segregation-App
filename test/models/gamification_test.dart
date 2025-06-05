import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/gamification.dart';

void main() {
  group('AchievementType', () {
    test('should have all expected enum values', () {
      expect(AchievementType.values, hasLength(19));
      expect(AchievementType.values, contains(AchievementType.wasteIdentified));
      expect(AchievementType.values, contains(AchievementType.ecoWarrior));
      expect(AchievementType.values, contains(AchievementType.educationalContent));
    });
  });

  group('AchievementTier', () {
    test('should have all expected enum values', () {
      expect(AchievementTier.values, hasLength(4));
      expect(AchievementTier.values, contains(AchievementTier.bronze));
      expect(AchievementTier.values, contains(AchievementTier.silver));
      expect(AchievementTier.values, contains(AchievementTier.gold));
      expect(AchievementTier.values, contains(AchievementTier.platinum));
    });
  });

  group('ClaimStatus', () {
    test('should have all expected enum values', () {
      expect(ClaimStatus.values, hasLength(3));
      expect(ClaimStatus.values, contains(ClaimStatus.claimed));
      expect(ClaimStatus.values, contains(ClaimStatus.unclaimed));
      expect(ClaimStatus.values, contains(ClaimStatus.ineligible));
    });
  });

  group('Achievement', () {
    test('should create with required parameters', () {
      final achievement = Achievement(
        id: 'test_achievement',
        title: 'Test Achievement',
        description: 'A test achievement',
        type: AchievementType.wasteIdentified,
        threshold: 10,
        iconName: 'star',
        color: Colors.blue,
      );

      expect(achievement.id, equals('test_achievement'));
      expect(achievement.title, equals('Test Achievement'));
      expect(achievement.description, equals('A test achievement'));
      expect(achievement.type, equals(AchievementType.wasteIdentified));
      expect(achievement.threshold, equals(10));
      expect(achievement.iconName, equals('star'));
      expect(achievement.color, equals(Colors.blue));
      expect(achievement.isSecret, isFalse);
      expect(achievement.progress, equals(0.0));
      expect(achievement.tier, equals(AchievementTier.bronze));
    });

    test('should handle all optional parameters', () {
      final earnedDate = DateTime.now();
      final achievement = Achievement(
        id: 'full_achievement',
        title: 'Full Achievement',
        description: 'Achievement with all parameters',
        type: AchievementType.ecoWarrior,
        threshold: 100,
        iconName: 'trophy',
        color: Colors.gold,
        isSecret: true,
        earnedOn: earnedDate,
        progress: 0.75,
        tier: AchievementTier.gold,
        achievementFamilyId: 'family_1',
        unlocksAtLevel: 5,
        claimStatus: ClaimStatus.unclaimed,
        metadata: {'bonus': true},
        pointsReward: 200,
        relatedAchievementIds: ['related_1', 'related_2'],
        clues: ['Hint 1', 'Hint 2'],
      );

      expect(achievement.isSecret, isTrue);
      expect(achievement.earnedOn, equals(earnedDate));
      expect(achievement.progress, equals(0.75));
      expect(achievement.tier, equals(AchievementTier.gold));
      expect(achievement.achievementFamilyId, equals('family_1'));
      expect(achievement.unlocksAtLevel, equals(5));
      expect(achievement.claimStatus, equals(ClaimStatus.unclaimed));
      expect(achievement.metadata, equals({'bonus': true}));
      expect(achievement.pointsReward, equals(200));
      expect(achievement.relatedAchievementIds, hasLength(2));
      expect(achievement.clues, hasLength(2));
    });

    test('should serialize to and from JSON correctly', () {
      final achievement = Achievement(
        id: 'json_test',
        title: 'JSON Test',
        description: 'Test JSON serialization',
        type: AchievementType.recyclingExpert,
        threshold: 50,
        iconName: 'recycle',
        color: Colors.green,
        isSecret: true,
        progress: 0.6,
        tier: AchievementTier.silver,
        pointsReward: 150,
      );

      final json = achievement.toJson();
      final fromJson = Achievement.fromJson(json);

      expect(fromJson.id, equals(achievement.id));
      expect(fromJson.title, equals(achievement.title));
      expect(fromJson.description, equals(achievement.description));
      expect(fromJson.type, equals(achievement.type));
      expect(fromJson.threshold, equals(achievement.threshold));
      expect(fromJson.iconName, equals(achievement.iconName));
      expect(fromJson.color.value, equals(achievement.color.value));
      expect(fromJson.isSecret, equals(achievement.isSecret));
      expect(fromJson.progress, equals(achievement.progress));
      expect(fromJson.tier, equals(achievement.tier));
      expect(fromJson.pointsReward, equals(achievement.pointsReward));
    });

    test('should handle fromJson with defaults', () {
      final achievement = Achievement.fromJson({
        'id': 'minimal',
        'title': 'Minimal',
        'description': 'Minimal achievement',
        'type': 'wasteIdentified',
        'threshold': 1,
        'iconName': 'icon',
        'color': Colors.blue.value,
      });

      expect(achievement.isSecret, isFalse);
      expect(achievement.progress, equals(0.0));
      expect(achievement.tier, equals(AchievementTier.bronze));
      expect(achievement.claimStatus, equals(ClaimStatus.ineligible));
      expect(achievement.pointsReward, equals(50));
    });

    test('should calculate getters correctly', () {
      final earnedAchievement = Achievement(
        id: 'earned',
        title: 'Earned',
        description: 'Earned achievement',
        type: AchievementType.wasteIdentified,
        threshold: 10,
        iconName: 'star',
        color: Colors.blue,
        earnedOn: DateTime.now(),
        claimStatus: ClaimStatus.unclaimed,
      );

      expect(earnedAchievement.isEarned, isTrue);
      expect(earnedAchievement.isClaimable, isTrue);

      final lockedAchievement = Achievement(
        id: 'locked',
        title: 'Locked',
        description: 'Locked achievement',
        type: AchievementType.wasteIdentified,
        threshold: 10,
        iconName: 'lock',
        color: Colors.grey,
        unlocksAtLevel: 5,
      );

      expect(lockedAchievement.isLocked, isTrue);
    });

    test('should get tier colors correctly', () {
      final bronzeAchievement = Achievement(
        id: 'bronze',
        title: 'Bronze',
        description: 'Bronze achievement',
        type: AchievementType.wasteIdentified,
        threshold: 10,
        iconName: 'medal',
        color: Colors.brown,
        tier: AchievementTier.bronze,
      );

      expect(bronzeAchievement.getTierColor(), equals(const Color(0xFFCD7F32)));

      final goldAchievement = bronzeAchievement.copyWith(tier: AchievementTier.gold);
      expect(goldAchievement.getTierColor(), equals(const Color(0xFFDAA520)));
    });

    test('should get tier names correctly', () {
      final silverAchievement = Achievement(
        id: 'silver',
        title: 'Silver',
        description: 'Silver achievement',
        type: AchievementType.wasteIdentified,
        threshold: 10,
        iconName: 'medal',
        color: Colors.grey,
        tier: AchievementTier.silver,
      );

      expect(silverAchievement.tierName, equals('Silver'));

      final platinumAchievement = silverAchievement.copyWith(tier: AchievementTier.platinum);
      expect(platinumAchievement.tierName, equals('Platinum'));
    });

    test('should copyWith correctly', () {
      final original = Achievement(
        id: 'original',
        title: 'Original',
        description: 'Original achievement',
        type: AchievementType.wasteIdentified,
        threshold: 10,
        iconName: 'star',
        color: Colors.blue,
      );

      final updated = original.copyWith(
        title: 'Updated',
        progress: 0.5,
        tier: AchievementTier.gold,
      );

      expect(updated.title, equals('Updated'));
      expect(updated.progress, equals(0.5));
      expect(updated.tier, equals(AchievementTier.gold));
      expect(updated.id, equals('original')); // Unchanged
      expect(original.title, equals('Original')); // Original unchanged
    });
  });

  group('Streak', () {
    test('should create with required parameters', () {
      final lastUsage = DateTime.now();
      final streak = Streak(
        current: 5,
        longest: 10,
        lastUsageDate: lastUsage,
      );

      expect(streak.current, equals(5));
      expect(streak.longest, equals(10));
      expect(streak.lastUsageDate, equals(lastUsage));
    });

    test('should create with defaults', () {
      final streak = Streak(lastUsageDate: DateTime.now());

      expect(streak.current, equals(0));
      expect(streak.longest, equals(0));
    });

    test('should serialize to and from JSON correctly', () {
      final lastUsage = DateTime.now();
      final streak = Streak(
        current: 7,
        longest: 15,
        lastUsageDate: lastUsage,
      );

      final json = streak.toJson();
      final fromJson = Streak.fromJson(json);

      expect(fromJson.current, equals(streak.current));
      expect(fromJson.longest, equals(streak.longest));
      expect(fromJson.lastUsageDate.difference(streak.lastUsageDate).inMilliseconds.abs(), lessThan(1000));
    });

    test('should copyWith correctly', () {
      final original = Streak(
        current: 3,
        longest: 8,
        lastUsageDate: DateTime.now(),
      );

      final updated = original.copyWith(
        current: 5,
        longest: 12,
      );

      expect(updated.current, equals(5));
      expect(updated.longest, equals(12));
      expect(updated.lastUsageDate, equals(original.lastUsageDate));
      expect(original.current, equals(3));
    });
  });

  group('Challenge', () {
    test('should create with required parameters', () {
      final startDate = DateTime.now();
      final endDate = startDate.add(const Duration(days: 7));
      
      final challenge = Challenge(
        id: 'challenge_1',
        title: 'Weekly Challenge',
        description: 'Complete 20 classifications',
        startDate: startDate,
        endDate: endDate,
        pointsReward: 100,
        iconName: 'target',
        color: Colors.orange,
        requirements: {'classificationsNeeded': 20},
      );

      expect(challenge.id, equals('challenge_1'));
      expect(challenge.title, equals('Weekly Challenge'));
      expect(challenge.pointsReward, equals(100));
      expect(challenge.requirements['classificationsNeeded'], equals(20));
      expect(challenge.isCompleted, isFalse);
      expect(challenge.progress, equals(0.0));
      expect(challenge.participantIds, isEmpty);
    });

    test('should calculate active/expired status correctly', () {
      final now = DateTime.now();
      final pastChallenge = Challenge(
        id: 'past',
        title: 'Past Challenge',
        description: 'Past challenge',
        startDate: now.subtract(const Duration(days: 10)),
        endDate: now.subtract(const Duration(days: 3)),
        pointsReward: 50,
        iconName: 'history',
        color: Colors.grey,
        requirements: {},
      );

      final activeChallenge = Challenge(
        id: 'active',
        title: 'Active Challenge',
        description: 'Active challenge',
        startDate: now.subtract(const Duration(days: 1)),
        endDate: now.add(const Duration(days: 5)),
        pointsReward: 100,
        iconName: 'play',
        color: Colors.green,
        requirements: {},
      );

      final futureChallenge = Challenge(
        id: 'future',
        title: 'Future Challenge',
        description: 'Future challenge',
        startDate: now.add(const Duration(days: 2)),
        endDate: now.add(const Duration(days: 9)),
        pointsReward: 150,
        iconName: 'schedule',
        color: Colors.blue,
        requirements: {},
      );

      expect(pastChallenge.isExpired, isTrue);
      expect(pastChallenge.isActive, isFalse);
      expect(activeChallenge.isActive, isTrue);
      expect(activeChallenge.isExpired, isFalse);
      expect(futureChallenge.isActive, isFalse);
      expect(futureChallenge.isExpired, isFalse);
    });

    test('should serialize to and from JSON correctly', () {
      final startDate = DateTime.now();
      final endDate = startDate.add(const Duration(days: 5));
      
      final challenge = Challenge(
        id: 'json_test',
        title: 'JSON Test',
        description: 'Test JSON',
        startDate: startDate,
        endDate: endDate,
        pointsReward: 75,
        iconName: 'test',
        color: Colors.purple,
        requirements: {'type': 'streak', 'days': 5},
        isCompleted: true,
        progress: 1.0,
        participantIds: ['user1', 'user2'],
      );

      final json = challenge.toJson();
      final fromJson = Challenge.fromJson(json);

      expect(fromJson.id, equals(challenge.id));
      expect(fromJson.title, equals(challenge.title));
      expect(fromJson.pointsReward, equals(challenge.pointsReward));
      expect(fromJson.requirements, equals(challenge.requirements));
      expect(fromJson.isCompleted, equals(challenge.isCompleted));
      expect(fromJson.progress, equals(challenge.progress));
      expect(fromJson.participantIds, equals(challenge.participantIds));
    });
  });

  group('UserPoints', () {
    test('should create with defaults', () {
      const points = UserPoints();

      expect(points.total, equals(0));
      expect(points.weeklyTotal, equals(0));
      expect(points.monthlyTotal, equals(0));
      expect(points.level, equals(1));
      expect(points.categoryPoints, isEmpty);
    });

    test('should create with custom values', () {
      const points = UserPoints(
        total: 1250,
        weeklyTotal: 120,
        monthlyTotal: 480,
        level: 13,
        categoryPoints: {'Recyclable': 600, 'Organic': 400, 'Hazardous': 250},
      );

      expect(points.total, equals(1250));
      expect(points.level, equals(13));
      expect(points.categoryPoints['Recyclable'], equals(600));
    });

    test('should calculate points to next level correctly', () {
      const level5Points = UserPoints(total: 450, level: 5);
      expect(level5Points.pointsToNextLevel, equals(50)); // 500 - 450 = 50

      const level10Points = UserPoints(total: 999, level: 10);
      expect(level10Points.pointsToNextLevel, equals(1)); // 1000 - 999 = 1
    });

    test('should get correct rank names', () {
      const rookie = UserPoints(level: 3);
      expect(rookie.rankName, equals('Recycling Rookie'));

      const warrior = UserPoints(level: 7);
      expect(warrior.rankName, equals('Waste Warrior'));

      const specialist = UserPoints(level: 12);
      expect(specialist.rankName, equals('Segregation Specialist'));

      const champion = UserPoints(level: 17);
      expect(champion.rankName, equals('Eco Champion'));

      const sage = UserPoints(level: 22);
      expect(sage.rankName, equals('Sustainability Sage'));

      const master = UserPoints(level: 30);
      expect(master.rankName, equals('Waste Management Master'));
    });

    test('should serialize to and from JSON correctly', () {
      const points = UserPoints(
        total: 750,
        weeklyTotal: 85,
        monthlyTotal: 320,
        level: 8,
        categoryPoints: {'Electronic': 200, 'Plastic': 350, 'Paper': 200},
      );

      final json = points.toJson();
      final fromJson = UserPoints.fromJson(json);

      expect(fromJson.total, equals(points.total));
      expect(fromJson.weeklyTotal, equals(points.weeklyTotal));
      expect(fromJson.monthlyTotal, equals(points.monthlyTotal));
      expect(fromJson.level, equals(points.level));
      expect(fromJson.categoryPoints, equals(points.categoryPoints));
    });
  });

  group('WeeklyStats', () {
    test('should create with required parameters', () {
      final weekStart = DateTime.now();
      final stats = WeeklyStats(
        weekStartDate: weekStart,
        itemsIdentified: 25,
        challengesCompleted: 2,
        streakMaximum: 7,
        pointsEarned: 150,
        categoryCounts: {'Recyclable': 15, 'Organic': 8, 'Hazardous': 2},
      );

      expect(stats.weekStartDate, equals(weekStart));
      expect(stats.itemsIdentified, equals(25));
      expect(stats.challengesCompleted, equals(2));
      expect(stats.streakMaximum, equals(7));
      expect(stats.pointsEarned, equals(150));
      expect(stats.categoryCounts['Recyclable'], equals(15));
    });

    test('should serialize to and from JSON correctly', () {
      final weekStart = DateTime.now();
      final stats = WeeklyStats(
        weekStartDate: weekStart,
        itemsIdentified: 30,
        challengesCompleted: 3,
        streakMaximum: 5,
        pointsEarned: 200,
        categoryCounts: {'Glass': 10, 'Metal': 12, 'Textile': 8},
      );

      final json = stats.toJson();
      final fromJson = WeeklyStats.fromJson(json);

      expect(fromJson.itemsIdentified, equals(stats.itemsIdentified));
      expect(fromJson.challengesCompleted, equals(stats.challengesCompleted));
      expect(fromJson.pointsEarned, equals(stats.pointsEarned));
      expect(fromJson.categoryCounts, equals(stats.categoryCounts));
    });
  });

  group('StreakType', () {
    test('should have all expected enum values', () {
      expect(StreakType.values, hasLength(4));
      expect(StreakType.values, contains(StreakType.dailyClassification));
      expect(StreakType.values, contains(StreakType.dailyLearning));
      expect(StreakType.values, contains(StreakType.dailyEngagement));
      expect(StreakType.values, contains(StreakType.itemDiscovery));
    });
  });

  group('StreakDetails', () {
    test('should create with required parameters', () {
      final lastActivity = DateTime.now();
      final streak = StreakDetails(
        type: StreakType.dailyClassification,
        currentCount: 5,
        longestCount: 12,
        lastActivityDate: lastActivity,
        lastMilestoneAwardedLevel: 2,
      );

      expect(streak.type, equals(StreakType.dailyClassification));
      expect(streak.currentCount, equals(5));
      expect(streak.longestCount, equals(12));
      expect(streak.lastActivityDate, equals(lastActivity));
      expect(streak.lastMilestoneAwardedLevel, equals(2));
    });

    test('should serialize to and from JSON correctly', () {
      final lastActivity = DateTime.now();
      final lastMaintenance = DateTime.now().subtract(const Duration(days: 1));
      
      final streak = StreakDetails(
        type: StreakType.dailyLearning,
        currentCount: 8,
        longestCount: 15,
        lastActivityDate: lastActivity,
        lastMaintenanceAwardedDate: lastMaintenance,
        lastMilestoneAwardedLevel: 3,
      );

      final json = streak.toJson();
      final fromJson = StreakDetails.fromJson(json);

      expect(fromJson.type, equals(streak.type));
      expect(fromJson.currentCount, equals(streak.currentCount));
      expect(fromJson.longestCount, equals(streak.longestCount));
      expect(fromJson.lastMilestoneAwardedLevel, equals(streak.lastMilestoneAwardedLevel));
    });
  });

  group('FamilyReactionType', () {
    test('should have all expected enum values', () {
      expect(FamilyReactionType.values, hasLength(6));
      expect(FamilyReactionType.values, contains(FamilyReactionType.like));
      expect(FamilyReactionType.values, contains(FamilyReactionType.love));
      expect(FamilyReactionType.values, contains(FamilyReactionType.helpful));
      expect(FamilyReactionType.values, contains(FamilyReactionType.amazing));
      expect(FamilyReactionType.values, contains(FamilyReactionType.wellDone));
      expect(FamilyReactionType.values, contains(FamilyReactionType.educational));
    });
  });

  group('FamilyReaction', () {
    test('should create with required parameters', () {
      final timestamp = DateTime.now();
      final reaction = FamilyReaction(
        userId: 'user123',
        displayName: 'John Doe',
        type: FamilyReactionType.love,
        timestamp: timestamp,
      );

      expect(reaction.userId, equals('user123'));
      expect(reaction.displayName, equals('John Doe'));
      expect(reaction.type, equals(FamilyReactionType.love));
      expect(reaction.timestamp, equals(timestamp));
      expect(reaction.photoUrl, isNull);
      expect(reaction.comment, isNull);
    });

    test('should serialize to and from JSON correctly', () {
      final timestamp = DateTime.now();
      final reaction = FamilyReaction(
        userId: 'user456',
        displayName: 'Jane Smith',
        photoUrl: 'https://example.com/photo.jpg',
        type: FamilyReactionType.helpful,
        timestamp: timestamp,
        comment: 'Great classification!',
      );

      final json = reaction.toJson();
      final fromJson = FamilyReaction.fromJson(json);

      expect(fromJson.userId, equals(reaction.userId));
      expect(fromJson.displayName, equals(reaction.displayName));
      expect(fromJson.photoUrl, equals(reaction.photoUrl));
      expect(fromJson.type, equals(reaction.type));
      expect(fromJson.comment, equals(reaction.comment));
    });
  });

  group('FamilyComment', () {
    test('should create with create factory', () {
      final comment = FamilyComment.create(
        userId: 'user789',
        displayName: 'Alice Johnson',
        text: 'This is a great example!',
      );

      expect(comment.id, isNotEmpty);
      expect(comment.userId, equals('user789'));
      expect(comment.displayName, equals('Alice Johnson'));
      expect(comment.text, equals('This is a great example!'));
      expect(comment.isReply, isFalse);
      expect(comment.isEdited, isFalse);
    });

    test('should identify replies correctly', () {
      final parentComment = FamilyComment.create(
        userId: 'parent',
        displayName: 'Parent User',
        text: 'Original comment',
      );

      final replyComment = FamilyComment.create(
        userId: 'child',
        displayName: 'Child User',
        text: 'Reply to comment',
        parentCommentId: parentComment.id,
      );

      expect(parentComment.isReply, isFalse);
      expect(replyComment.isReply, isTrue);
    });

    test('should calculate total replies correctly', () {
      final reply1 = FamilyComment.create(
        userId: 'user1',
        displayName: 'User 1',
        text: 'Reply 1',
      );

      final reply2 = FamilyComment.create(
        userId: 'user2',
        displayName: 'User 2',
        text: 'Reply 2',
      );

      final nestedReply = FamilyComment.create(
        userId: 'user3',
        displayName: 'User 3',
        text: 'Nested reply',
      );

      final commentWithReplies = FamilyComment(
        id: 'parent',
        userId: 'parent_user',
        displayName: 'Parent User',
        text: 'Parent comment',
        timestamp: DateTime.now(),
        replies: [
          reply1,
          reply2.copyWith(replies: [nestedReply]),
        ],
      );

      expect(commentWithReplies.totalReplies, equals(3)); // 2 direct + 1 nested
    });

    test('should serialize to and from JSON correctly', () {
      final timestamp = DateTime.now();
      final editedAt = timestamp.add(const Duration(minutes: 5));
      
      final comment = FamilyComment(
        id: 'comment123',
        userId: 'user123',
        displayName: 'Test User',
        photoUrl: 'https://example.com/avatar.jpg',
        text: 'Edited comment text',
        timestamp: timestamp,
        parentCommentId: 'parent123',
        isEdited: true,
        editedAt: editedAt,
        replies: [],
      );

      final json = comment.toJson();
      final fromJson = FamilyComment.fromJson(json);

      expect(fromJson.id, equals(comment.id));
      expect(fromJson.userId, equals(comment.userId));
      expect(fromJson.displayName, equals(comment.displayName));
      expect(fromJson.text, equals(comment.text));
      expect(fromJson.parentCommentId, equals(comment.parentCommentId));
      expect(fromJson.isEdited, equals(comment.isEdited));
    });
  });

  group('GamificationProfile', () {
    test('should create with required parameters', () {
      final profile = GamificationProfile(
        userId: 'user123',
        streaks: {},
        points: const UserPoints(),
      );

      expect(profile.userId, equals('user123'));
      expect(profile.achievements, isEmpty);
      expect(profile.activeChallenges, isEmpty);
      expect(profile.completedChallenges, isEmpty);
      expect(profile.weeklyStats, isEmpty);
      expect(profile.discoveredItemIds, isEmpty);
      expect(profile.unlockedHiddenContentIds, isEmpty);
    });

    test('should create with comprehensive data', () {
      final achievement = Achievement(
        id: 'ach1',
        title: 'First Achievement',
        description: 'First achievement description',
        type: AchievementType.firstClassification,
        threshold: 1,
        iconName: 'first',
        color: Colors.green,
        earnedOn: DateTime.now(),
      );

      final challenge = Challenge(
        id: 'challenge1',
        title: 'Test Challenge',
        description: 'Test challenge description',
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 7)),
        pointsReward: 100,
        iconName: 'challenge',
        color: Colors.blue,
        requirements: {'count': 10},
      );

      final profile = GamificationProfile(
        userId: 'user456',
        achievements: [achievement],
        streaks: {
          'daily': StreakDetails(
            type: StreakType.dailyClassification,
            currentCount: 5,
            longestCount: 10,
            lastActivityDate: DateTime.now(),
          ),
        },
        points: const UserPoints(total: 500, level: 5),
        activeChallenges: [challenge],
        discoveredItemIds: {'item1', 'item2', 'item3'},
        unlockedHiddenContentIds: {'content1', 'content2'},
      );

      expect(profile.achievements, hasLength(1));
      expect(profile.streaks, hasLength(1));
      expect(profile.points.total, equals(500));
      expect(profile.activeChallenges, hasLength(1));
      expect(profile.discoveredItemIds, hasLength(3));
      expect(profile.unlockedHiddenContentIds, hasLength(2));
    });

    test('should serialize to and from JSON correctly', () {
      final profile = GamificationProfile(
        userId: 'json_user',
        streaks: {
          'learning': StreakDetails(
            type: StreakType.dailyLearning,
            currentCount: 3,
            longestCount: 8,
            lastActivityDate: DateTime.now(),
          ),
        },
        points: const UserPoints(total: 250, level: 3),
        discoveredItemIds: {'discover1', 'discover2'},
        lastDailyEngagementBonusAwardedDate: DateTime.now(),
      );

      final json = profile.toJson();
      final fromJson = GamificationProfile.fromJson(json);

      expect(fromJson.userId, equals(profile.userId));
      expect(fromJson.streaks, hasLength(1));
      expect(fromJson.points.total, equals(profile.points.total));
      expect(fromJson.discoveredItemIds, equals(profile.discoveredItemIds));
      expect(fromJson.lastDailyEngagementBonusAwardedDate, isNotNull);
    });

    test('should copyWith correctly', () {
      final original = GamificationProfile(
        userId: 'original_user',
        streaks: {},
        points: const UserPoints(total: 100),
      );

      final newPoints = const UserPoints(total: 200, level: 2);
      final updated = original.copyWith(
        points: newPoints,
        discoveredItemIds: {'new_item'},
      );

      expect(updated.userId, equals('original_user'));
      expect(updated.points.total, equals(200));
      expect(updated.discoveredItemIds, equals({'new_item'}));
      expect(original.points.total, equals(100));
      expect(original.discoveredItemIds, isEmpty);
    });
  });

  group('AnalyticsEvent', () {
    test('should create with create factory', () {
      final event = AnalyticsEvent.create(
        userId: 'user123',
        eventType: AnalyticsEventTypes.classification,
        eventName: AnalyticsEventNames.classificationCompleted,
        parameters: {'category': 'Recyclable', 'confidence': 0.95},
      );

      expect(event.id, isNotEmpty);
      expect(event.userId, equals('user123'));
      expect(event.eventType, equals(AnalyticsEventTypes.classification));
      expect(event.eventName, equals(AnalyticsEventNames.classificationCompleted));
      expect(event.parameters['category'], equals('Recyclable'));
      expect(event.timestamp, isNotNull);
    });

    test('should serialize to and from JSON correctly', () {
      final event = AnalyticsEvent.create(
        userId: 'analytics_user',
        eventType: AnalyticsEventTypes.userAction,
        eventName: AnalyticsEventNames.buttonClick,
        parameters: {'button': 'capture', 'screen': 'home'},
        sessionId: 'session123',
        deviceInfo: 'iOS 15.0',
      );

      final json = event.toJson();
      final fromJson = AnalyticsEvent.fromJson(json);

      expect(fromJson.id, equals(event.id));
      expect(fromJson.userId, equals(event.userId));
      expect(fromJson.eventType, equals(event.eventType));
      expect(fromJson.eventName, equals(event.eventName));
      expect(fromJson.parameters, equals(event.parameters));
      expect(fromJson.sessionId, equals(event.sessionId));
      expect(fromJson.deviceInfo, equals(event.deviceInfo));
    });
  });

  group('StringExtension', () {
    test('should capitalize strings correctly', () {
      expect('hello'.capitalize(), equals('Hello'));
      expect('WORLD'.capitalize(), equals('WORLD'));
      expect('test_string'.capitalize(), equals('Test_string'));
      expect('a'.capitalize(), equals('A'));
    });
  });

  group('Edge Cases and Integration', () {
    test('should handle empty and null values in JSON parsing', () {
      final emptyAchievement = Achievement.fromJson({
        'id': '',
        'title': '',
        'description': '',
        'type': 'wasteIdentified',
        'threshold': 0,
        'iconName': '',
        'color': Colors.transparent.value,
      });

      expect(emptyAchievement.id, isEmpty);
      expect(emptyAchievement.threshold, equals(0));
      expect(emptyAchievement.pointsReward, equals(50)); // Default
    });

    test('should handle invalid enum values gracefully', () {
      final achievementWithInvalidType = Achievement.fromJson({
        'id': 'test',
        'title': 'Test',
        'description': 'Test',
        'type': 'invalidType',
        'threshold': 1,
        'iconName': 'test',
        'color': Colors.blue.value,
      });

      expect(achievementWithInvalidType.type, equals(AchievementType.wasteIdentified));
    });

    test('should handle large datasets', () {
      final largeProfile = GamificationProfile(
        userId: 'large_user',
        achievements: List.generate(100, (i) => Achievement(
          id: 'ach_$i',
          title: 'Achievement $i',
          description: 'Description $i',
          type: AchievementType.wasteIdentified,
          threshold: i + 1,
          iconName: 'icon_$i',
          color: Colors.blue,
        )),
        streaks: Map.fromEntries(List.generate(10, (i) => MapEntry(
          'streak_$i',
          StreakDetails(
            type: StreakType.dailyClassification,
            currentCount: i,
            longestCount: i * 2,
            lastActivityDate: DateTime.now(),
          ),
        ))),
        points: const UserPoints(total: 10000, level: 100),
        discoveredItemIds: Set.from(List.generate(1000, (i) => 'item_$i')),
      );

      expect(largeProfile.achievements, hasLength(100));
      expect(largeProfile.streaks, hasLength(10));
      expect(largeProfile.discoveredItemIds, hasLength(1000));

      // Test serialization with large data
      final json = largeProfile.toJson();
      final fromJson = GamificationProfile.fromJson(json);
      expect(fromJson.achievements, hasLength(100));
      expect(fromJson.discoveredItemIds, hasLength(1000));
    });

    test('should maintain data integrity through multiple serialization cycles', () {
      final originalProfile = GamificationProfile(
        userId: 'integrity_test',
        streaks: {
          'daily': StreakDetails(
            type: StreakType.dailyClassification,
            currentCount: 15,
            longestCount: 25,
            lastActivityDate: DateTime.now(),
          ),
        },
        points: const UserPoints(
          total: 1500,
          level: 15,
          categoryPoints: {'Plastic': 500, 'Metal': 600, 'Paper': 400},
        ),
      );

      // Multiple serialization cycles
      var json = originalProfile.toJson();
      var deserialized = GamificationProfile.fromJson(json);
      json = deserialized.toJson();
      deserialized = GamificationProfile.fromJson(json);
      json = deserialized.toJson();
      final finalDeserialized = GamificationProfile.fromJson(json);

      expect(finalDeserialized.userId, equals(originalProfile.userId));
      expect(finalDeserialized.points.total, equals(originalProfile.points.total));
      expect(finalDeserialized.points.categoryPoints, equals(originalProfile.points.categoryPoints));
      expect(finalDeserialized.streaks['daily']?.currentCount, equals(15));
    });
  });
}
