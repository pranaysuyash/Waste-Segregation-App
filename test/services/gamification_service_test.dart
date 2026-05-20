import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mockito/mockito.dart';
import 'package:waste_segregation_app/services/gamification_service.dart';
import 'package:waste_segregation_app/services/storage_service.dart';
import 'package:waste_segregation_app/services/cloud_storage_service.dart';
import 'package:waste_segregation_app/services/points_engine.dart';
import 'package:waste_segregation_app/models/user_profile.dart';
import 'package:waste_segregation_app/models/gamification.dart';

class MockStorageService extends Mock implements StorageService {
  @override
  Future<UserProfile?> getCurrentUserProfile() =>
      super.noSuchMethod(
        Invocation.method(#getCurrentUserProfile, const []),
        returnValue: Future.value(null),
      ) as Future<UserProfile?>;
}
class MockCloudStorageService extends Mock implements CloudStorageService {}

void main() {
  group('GamificationService', () {
    late GamificationService gamificationService;
    late MockStorageService mockStorageService;
    late MockCloudStorageService mockCloudStorageService;
    late Directory hiveTestDir;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      hiveTestDir = await Directory.systemTemp.createTemp('hive_gamification_');
      Hive.init(hiveTestDir.path);
    });

    setUp(() async {
      mockStorageService = MockStorageService();
      mockCloudStorageService = MockCloudStorageService();
      gamificationService =
          GamificationService(mockStorageService, mockCloudStorageService);

      // Initialize the service
      await gamificationService.initGamification();
    });

    tearDown(() async {
      // Clean up Hive boxes after each test
      if (Hive.isBoxOpen('gamificationBox')) {
        await Hive.box('gamificationBox').clear();
        await Hive.box('gamificationBox').close();
      }
    });

    tearDownAll(() async {
      if (hiveTestDir.existsSync()) {
        await hiveTestDir.delete(recursive: true);
      }
    });

    test('getProfile should return guest profile when no user profile exists',
        () async {
      // Arrange
      when(mockStorageService.getCurrentUserProfile())
          .thenAnswer((_) async => null);

      // Act
      final profile = await gamificationService.getProfile();

      // Assert
      expect(profile, isNotNull);
      expect(profile.userId, equals('guest'));
      expect(profile.achievements, isA<List<Achievement>>());
      expect(profile.points, isNotNull);
    });

    test(
        'getProfile should return existing gamification profile when user profile exists',
        () async {
      // Arrange
      const existingGamificationProfile = GamificationProfile(
        userId: 'test_user_123',
        streaks: {},
        points: UserPoints(total: 100, level: 2),
      );

      final userProfile = UserProfile(
        id: 'test_user_123',
        email: 'test@example.com',
        displayName: 'Test User',
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
        gamificationProfile: existingGamificationProfile,
      );

      when(mockStorageService.getCurrentUserProfile())
          .thenAnswer((_) async => userProfile);

      // Act
      final profile = await gamificationService.getProfile();

      // Assert
      expect(profile, isNotNull);
      expect(profile.userId, isNotEmpty);
      expect(profile.points, isNotNull);
    });

    test(
        'getProfile should create new profile for authenticated user without gamification profile',
        () async {
      // Arrange
      final userProfile = UserProfile(
        id: 'test_user_456',
        email: 'test2@example.com',
        displayName: 'Test User 2',
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
        // No gamification profile yet
      );

      when(mockStorageService.getCurrentUserProfile())
          .thenAnswer((_) async => userProfile);

      // Act
      final profile = await gamificationService.getProfile();

      // Assert
      expect(profile, isNotNull);
      expect(profile.userId, isNotEmpty);
      expect(profile.achievements, isA<List<Achievement>>());
      expect(profile.points, isNotNull);
    });

    test(
        'getProfile should handle errors gracefully and return emergency profile',
        () async {
      // Arrange
      when(mockStorageService.getCurrentUserProfile())
          .thenThrow(Exception('Storage error'));

      // Act
      final profile = await gamificationService.getProfile();

      // Assert
      expect(profile, isNotNull);
      expect(profile.userId, equals('guest'));
      expect(profile.achievements, isA<List<Achievement>>());
      expect(profile.points, isNotNull);
    });

    test('getDefaultAchievements should return non-empty list', () {
      // Act
      final achievements = gamificationService.getDefaultAchievements();

      // Assert
      expect(achievements, isNotEmpty);
      expect(achievements.first.id, isNotEmpty);
      expect(achievements.first.title, isNotEmpty);
      expect(achievements.first.description, isNotEmpty);
    });

    group('getNearMilestoneNudge', () {
      late GamificationService freshService;

      setUp(() async {
        PointsEngine.resetInstance();
        freshService =
            GamificationService(mockStorageService, mockCloudStorageService);
        await freshService.initGamification();
      });

      test('returns null when no milestones are near', () async {
        final userProfile = UserProfile(
          id: 'nudge_test_user',
          email: 'nudge@test.com',
          displayName: 'Nudge Test User',
          createdAt: DateTime.now(),
          lastActive: DateTime.now(),
          gamificationProfile: GamificationProfile(
            userId: 'nudge_test_user',
            streaks: {},
            points: const UserPoints(total: 200, level: 3),
            achievements: [],
            discoveredItemIds: [],
            unlockedHiddenContentIds: [],
          ),
        );

        when(mockStorageService.getCurrentUserProfile())
            .thenAnswer((_) async => userProfile);

        final nudge = await freshService.getNearMilestoneNudge();
        expect(nudge, isNull);
      });

      test('returns daily goal nudge when 1 scan away from daily target',
          () async {
        final userProfile = UserProfile(
          id: 'daily_goal_user',
          email: 'daily@test.com',
          displayName: 'Daily Goal User',
          createdAt: DateTime.now(),
          lastActive: DateTime.now(),
          gamificationProfile: GamificationProfile(
            userId: 'daily_goal_user',
            streaks: {},
            points: const UserPoints(total: 50, level: 1),
            achievements: [],
            weeklyStats: [
              WeeklyStats(
                weekStartDate: DateTime.now().subtract(const Duration(days: 3)),
                itemsIdentified: 4,
                pointsEarned: 20,
              ),
            ],
            discoveredItemIds: [],
            unlockedHiddenContentIds: [],
          ),
        );

        when(mockStorageService.getCurrentUserProfile())
            .thenAnswer((_) async => userProfile);

        final nudge = await freshService.getNearMilestoneNudge();

        expect(nudge, isNotNull);
        expect(nudge!.type, equals(NudgeType.dailyGoal));
        expect(nudge.priority, equals(NudgePriority.high));
        expect(nudge.progress, equals(4));
        expect(nudge.target, equals(5));
      });

      test('returns challenge nudge when 1 away from challenge completion',
          () async {
        final challenge = Challenge(
          id: 'challenge_1',
          title: 'Plastic Warrior',
          description: 'Scan 5 plastic items',
          startDate: DateTime.now().subtract(const Duration(days: 1)),
          endDate: DateTime.now().add(const Duration(days: 6)),
          pointsReward: 50,
          iconName: 'eco',
          color: Colors.green,
          requirements: {'count': 5},
          progress: 0.8,
        );

        final userProfile = UserProfile(
          id: 'challenge_user',
          email: 'challenge@test.com',
          displayName: 'Challenge User',
          createdAt: DateTime.now(),
          lastActive: DateTime.now(),
          gamificationProfile: GamificationProfile(
            userId: 'challenge_user',
            streaks: {},
            points: const UserPoints(total: 30, level: 1),
            achievements: [],
            activeChallenges: [challenge],
            discoveredItemIds: [],
            unlockedHiddenContentIds: [],
          ),
        );

        when(mockStorageService.getCurrentUserProfile())
            .thenAnswer((_) async => userProfile);

        final nudge = await freshService.getNearMilestoneNudge();

        expect(nudge, isNotNull);
        expect(nudge!.type, equals(NudgeType.challengeNearComplete));
        expect(nudge.message, contains('Plastic Warrior'));
        expect(nudge.progress, equals(4));
        expect(nudge.target, equals(5));
      });

      test('returns category achievement nudge when 1 point away', () async {
        final userProfile = UserProfile(
          id: 'category_user',
          email: 'category@test.com',
          displayName: 'Category User',
          createdAt: DateTime.now(),
          lastActive: DateTime.now(),
          gamificationProfile: GamificationProfile(
            userId: 'category_user',
            streaks: {},
            points: const UserPoints(
              total: 50,
              level: 1,
              categoryPoints: {'Plastic': 9},
            ),
            achievements: [],
            discoveredItemIds: [],
            unlockedHiddenContentIds: [],
          ),
        );

        when(mockStorageService.getCurrentUserProfile())
            .thenAnswer((_) async => userProfile);

        final nudge = await freshService.getNearMilestoneNudge();

        expect(nudge, isNotNull);
        expect(nudge!.type, equals(NudgeType.categoryAchievement));
        expect(nudge.progress, equals(9));
        expect(nudge.target, equals(10));
      });

      test('returns streak milestone nudge when 1 day away', () async {
        final userProfile = UserProfile(
          id: 'streak_user',
          email: 'streak@test.com',
          displayName: 'Streak User',
          createdAt: DateTime.now(),
          lastActive: DateTime.now(),
          gamificationProfile: GamificationProfile(
            userId: 'streak_user',
            streaks: {
              'daily_classification': StreakDetails(
                type: StreakType.dailyClassification,
                currentCount: 2,
                longestCount: 5,
                lastActivityDate: DateTime.now(),
              ),
            },
            points: const UserPoints(total: 30, level: 1),
            achievements: [],
            discoveredItemIds: [],
            unlockedHiddenContentIds: [],
          ),
        );

        when(mockStorageService.getCurrentUserProfile())
            .thenAnswer((_) async => userProfile);

        final nudge = await freshService.getNearMilestoneNudge();

        expect(nudge, isNotNull);
        expect(nudge!.type, equals(NudgeType.streakMilestone));
        expect(nudge.progress, equals(2));
        expect(nudge.target, equals(3));
      });

      test('returns points milestone nudge when within 5 points', () async {
        final userProfile = UserProfile(
          id: 'points_user',
          email: 'points@test.com',
          displayName: 'Points User',
          createdAt: DateTime.now(),
          lastActive: DateTime.now(),
          gamificationProfile: GamificationProfile(
            userId: 'points_user',
            streaks: {},
            points: const UserPoints(total: 47, level: 1),
            achievements: [],
            discoveredItemIds: [],
            unlockedHiddenContentIds: [],
          ),
        );

        when(mockStorageService.getCurrentUserProfile())
            .thenAnswer((_) async => userProfile);

        final nudge = await freshService.getNearMilestoneNudge();

        expect(nudge, isNotNull);
        expect(nudge!.progress, equals(47));
        expect(nudge.target, equals(50));
      });

      test('prioritizes daily goal over challenge', () async {
        final challenge = Challenge(
          id: 'challenge_2',
          title: 'Test Challenge',
          description: 'Test',
          startDate: DateTime.now().subtract(const Duration(days: 1)),
          endDate: DateTime.now().add(const Duration(days: 6)),
          pointsReward: 25,
          iconName: 'eco',
          color: Colors.blue,
          requirements: {'count': 5},
          progress: 0.8,
        );

        final userProfile = UserProfile(
          id: 'priority_user',
          email: 'priority@test.com',
          displayName: 'Priority User',
          createdAt: DateTime.now(),
          lastActive: DateTime.now(),
          gamificationProfile: GamificationProfile(
            userId: 'priority_user',
            streaks: {},
            points: const UserPoints(total: 50, level: 1),
            achievements: [],
            weeklyStats: [
              WeeklyStats(
                weekStartDate: DateTime.now().subtract(const Duration(days: 3)),
                itemsIdentified: 4,
                pointsEarned: 20,
              ),
            ],
            activeChallenges: [challenge],
            discoveredItemIds: [],
            unlockedHiddenContentIds: [],
          ),
        );

        when(mockStorageService.getCurrentUserProfile())
            .thenAnswer((_) async => userProfile);

        final nudge = await freshService.getNearMilestoneNudge();

        expect(nudge, isNotNull);
        expect(nudge!.type, equals(NudgeType.dailyGoal));
      });
    });
  });
}
