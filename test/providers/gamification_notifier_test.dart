import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter/material.dart';

import '../../lib/models/gamification.dart';
import '../../lib/providers/gamification_notifier.dart';
import '../../lib/providers/gamification_repository.dart';
import '../../lib/services/storage_service.dart';
import '../../lib/services/cloud_storage_service.dart';
import '../../lib/utils/constants.dart';

// Generate mocks
@GenerateMocks([
  GamificationRepository,
  StorageService,
  CloudStorageService,
])
import 'gamification_notifier_test.mocks.dart';

void main() {
  group('GamificationNotifier Tests', () {
    late MockGamificationRepository mockRepository;
    late ProviderContainer container;
    late GamificationProfile testProfile;

    setUp(() {
      mockRepository = MockGamificationRepository();
      
      // Create test profile
      testProfile = GamificationProfile(
        userId: 'test_user_123',
        streaks: {
          StreakType.dailyClassification.toString(): StreakDetails(
            type: StreakType.dailyClassification,
            currentCount: 5,
            longestCount: 10,
            lastActivityDate: DateTime.now().subtract(const Duration(days: 1)),
          ),
        },
        points: const UserPoints(total: 100, level: 2),
        achievements: [
          Achievement(
            id: 'test_achievement_1',
            title: 'First Steps',
            description: 'Complete your first classification',
            type: AchievementType.firstClassification,
            threshold: 1,
            iconName: 'eco',
            color: const Color(0xFF4CAF50),
            tier: AchievementTier.bronze,
            pointsReward: 10,
            progress: 1.0,
            claimStatus: ClaimStatus.unclaimed,
            earnedOn: DateTime.now(),
          ),
          Achievement(
            id: 'test_achievement_2',
            title: 'Waste Hunter',
            description: 'Identify 10 waste items',
            type: AchievementType.wasteIdentified,
            threshold: 10,
            iconName: 'search',
            color: const Color(0xFF2196F3),
            tier: AchievementTier.silver,
            pointsReward: 25,
            progress: 0.5,
            claimStatus: ClaimStatus.ineligible,
          ),
        ],
        discoveredItemIds: {'item1', 'item2'},
        unlockedHiddenContentIds: {'content1'},
      );

      // Setup container with mocked repository
      container = ProviderContainer(
        overrides: [
          gamificationRepositoryProvider.overrideWithValue(mockRepository),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('Initial Load', () {
      test('should load profile successfully', () async {
        // Arrange
        when(mockRepository.getProfile()).thenAnswer((_) async => testProfile);

        // Act
        final notifier = container.read(gamificationNotifierProvider.notifier);
        final state = await container.read(gamificationNotifierProvider.future);

        // Assert
        expect(state, equals(testProfile));
        verify(mockRepository.getProfile()).called(1);
      });

      test('should handle load error gracefully', () async {
        // Arrange
        final error = AppException.storage('Failed to load profile');
        when(mockRepository.getProfile()).thenThrow(error);

        // Act & Assert
        expect(
          () => container.read(gamificationNotifierProvider.future),
          throwsA(isA<AppException>()),
        );
      });
    });

    group('Refresh', () {
      test('should refresh profile data', () async {
        // Arrange
        when(mockRepository.getProfile()).thenAnswer((_) async => testProfile);
        when(mockRepository.getProfile(forceRefresh: true))
            .thenAnswer((_) async => testProfile.copyWith(
              points: const UserPoints(total: 150, level: 3),
            ));

        // Act
        final notifier = container.read(gamificationNotifierProvider.notifier);
        await container.read(gamificationNotifierProvider.future); // Initial load
        await notifier.refresh();

        // Assert
        final state = container.read(gamificationNotifierProvider).value!;
        expect(state.points.total, equals(150));
        expect(state.points.level, equals(3));
        verify(mockRepository.getProfile(forceRefresh: true)).called(1);
      });

      test('should handle refresh error', () async {
        // Arrange
        when(mockRepository.getProfile()).thenAnswer((_) async => testProfile);
        when(mockRepository.getProfile(forceRefresh: true))
            .thenThrow(AppException.network('Network error'));

        // Act
        final notifier = container.read(gamificationNotifierProvider.notifier);
        await container.read(gamificationNotifierProvider.future); // Initial load
        await notifier.refresh();

        // Assert
        final state = container.read(gamificationNotifierProvider);
        expect(state.hasError, isTrue);
        expect(state.error, isA<AppException>());
      });
    });

    group('Claim Reward', () {
      test('should claim achievement reward successfully', () async {
        // Arrange
        when(mockRepository.getProfile()).thenAnswer((_) async => testProfile);
        when(mockRepository.claimReward('test_achievement_1', any))
            .thenAnswer((_) async => testProfile.achievements.first.copyWith(
              claimStatus: ClaimStatus.claimed,
            ));
        when(mockRepository.getProfile(forceRefresh: true))
            .thenAnswer((_) async => testProfile.copyWith(
              points: const UserPoints(total: 110, level: 2),
              achievements: [
                testProfile.achievements.first.copyWith(
                  claimStatus: ClaimStatus.claimed,
                ),
                testProfile.achievements.last,
              ],
            ));

        // Act
        final notifier = container.read(gamificationNotifierProvider.notifier);
        await container.read(gamificationNotifierProvider.future); // Initial load
        await notifier.claimReward('test_achievement_1');

        // Assert
        final state = container.read(gamificationNotifierProvider).value!;
        expect(state.points.total, equals(110));
        expect(
          state.achievements.first.claimStatus,
          equals(ClaimStatus.claimed),
        );
        verify(mockRepository.claimReward('test_achievement_1', any)).called(1);
      });

      test('should handle claim error with optimistic update rollback', () async {
        // Arrange
        when(mockRepository.getProfile()).thenAnswer((_) async => testProfile);
        when(mockRepository.claimReward('test_achievement_1', any))
            .thenThrow(AppException.storage('Claim failed'));

        // Act
        final notifier = container.read(gamificationNotifierProvider.notifier);
        await container.read(gamificationNotifierProvider.future); // Initial load
        
        expect(
          () => notifier.claimReward('test_achievement_1'),
          throwsA(isA<AppException>()),
        );

        // Assert - state should be reverted
        final state = container.read(gamificationNotifierProvider).value!;
        expect(state.points.total, equals(100)); // Original value
        expect(
          state.achievements.first.claimStatus,
          equals(ClaimStatus.unclaimed), // Original status
        );
      });

      test('should reject claim for ineligible achievement', () async {
        // Arrange
        when(mockRepository.getProfile()).thenAnswer((_) async => testProfile);

        // Act
        final notifier = container.read(gamificationNotifierProvider.notifier);
        await container.read(gamificationNotifierProvider.future); // Initial load

        // Assert
        expect(
          () => notifier.claimReward('test_achievement_2'), // Ineligible achievement
          throwsA(isA<AppException>()),
        );
      });
    });

    group('Update Streak', () {
      test('should update streak successfully', () async {
        // Arrange
        when(mockRepository.getProfile()).thenAnswer((_) async => testProfile);
        when(mockRepository.saveProfile(any)).thenAnswer((_) async {});

        // Act
        final notifier = container.read(gamificationNotifierProvider.notifier);
        await container.read(gamificationNotifierProvider.future); // Initial load
        await notifier.updateStreak(StreakType.dailyClassification);

        // Assert
        final state = container.read(gamificationNotifierProvider).value!;
        final streak = state.streaks[StreakType.dailyClassification.toString()]!;
        expect(streak.currentCount, equals(6)); // Incremented from 5
        verify(mockRepository.saveProfile(any)).called(1);
      });

      test('should not update streak on same day', () async {
        // Arrange
        final todayProfile = testProfile.copyWith(
          streaks: {
            StreakType.dailyClassification.toString(): StreakDetails(
              type: StreakType.dailyClassification,
              currentCount: 5,
              longestCount: 10,
              lastActivityDate: DateTime.now(), // Today
            ),
          },
        );
        when(mockRepository.getProfile()).thenAnswer((_) async => todayProfile);

        // Act
        final notifier = container.read(gamificationNotifierProvider.notifier);
        await container.read(gamificationNotifierProvider.future); // Initial load
        await notifier.updateStreak(StreakType.dailyClassification);

        // Assert
        final state = container.read(gamificationNotifierProvider).value!;
        final streak = state.streaks[StreakType.dailyClassification.toString()]!;
        expect(streak.currentCount, equals(5)); // No change
        verifyNever(mockRepository.saveProfile(any));
      });

      test('should reset streak after gap', () async {
        // Arrange
        final gapProfile = testProfile.copyWith(
          streaks: {
            StreakType.dailyClassification.toString(): StreakDetails(
              type: StreakType.dailyClassification,
              currentCount: 5,
              longestCount: 10,
              lastActivityDate: DateTime.now().subtract(const Duration(days: 3)), // 3 days ago
            ),
          },
        );
        when(mockRepository.getProfile()).thenAnswer((_) async => gapProfile);
        when(mockRepository.saveProfile(any)).thenAnswer((_) async {});

        // Act
        final notifier = container.read(gamificationNotifierProvider.notifier);
        await container.read(gamificationNotifierProvider.future); // Initial load
        await notifier.updateStreak(StreakType.dailyClassification);

        // Assert
        final state = container.read(gamificationNotifierProvider).value!;
        final streak = state.streaks[StreakType.dailyClassification.toString()]!;
        expect(streak.currentCount, equals(1)); // Reset to 1
        expect(streak.longestCount, equals(10)); // Longest preserved
      });
    });

    group('Add Classification Points', () {
      test('should add points and update achievements', () async {
        // Arrange
        when(mockRepository.getProfile()).thenAnswer((_) async => testProfile);
        when(mockRepository.saveProfile(any)).thenAnswer((_) async {});

        // Act
        final notifier = container.read(gamificationNotifierProvider.notifier);
        await container.read(gamificationNotifierProvider.future); // Initial load
        await notifier.addClassificationPoints('Dry Waste', 'Plastic');

        // Assert
        final state = container.read(gamificationNotifierProvider).value!;
        expect(state.points.total, equals(110)); // 100 + 10
        verify(mockRepository.saveProfile(any)).called(1);
      });

      test('should update achievement progress', () async {
        // Arrange
        when(mockRepository.getProfile()).thenAnswer((_) async => testProfile);
        when(mockRepository.saveProfile(any)).thenAnswer((_) async {});

        // Act
        final notifier = container.read(gamificationNotifierProvider.notifier);
        await container.read(gamificationNotifierProvider.future); // Initial load
        await notifier.addClassificationPoints('Dry Waste', 'Plastic');

        // Assert
        final state = container.read(gamificationNotifierProvider).value!;
        final wasteAchievement = state.achievements.firstWhere(
          (a) => a.type == AchievementType.wasteIdentified,
        );
        expect(wasteAchievement.progress, equals(0.6)); // 0.5 + 0.1
      });
    });

    group('Convenience Providers', () {
      test('should provide correct points', () async {
        // Arrange
        when(mockRepository.getProfile()).thenAnswer((_) async => testProfile);

        // Act
        await container.read(gamificationNotifierProvider.future);
        final points = container.read(gamificationPointsProvider);

        // Assert
        expect(points, equals(100));
      });

      test('should provide correct achievements', () async {
        // Arrange
        when(mockRepository.getProfile()).thenAnswer((_) async => testProfile);

        // Act
        await container.read(gamificationNotifierProvider.future);
        final achievements = container.read(gamificationAchievementsProvider);

        // Assert
        expect(achievements.length, equals(2));
        expect(achievements.first.id, equals('test_achievement_1'));
      });

      test('should provide claimable achievements', () async {
        // Arrange
        when(mockRepository.getProfile()).thenAnswer((_) async => testProfile);

        // Act
        await container.read(gamificationNotifierProvider.future);
        final claimableAchievements = container.read(claimableAchievementsProvider);

        // Assert
        expect(claimableAchievements.length, equals(1));
        expect(claimableAchievements.first.id, equals('test_achievement_1'));
        expect(claimableAchievements.first.claimStatus, equals(ClaimStatus.unclaimed));
      });

      test('should provide streaks', () async {
        // Arrange
        when(mockRepository.getProfile()).thenAnswer((_) async => testProfile);

        // Act
        await container.read(gamificationNotifierProvider.future);
        final streaks = container.read(gamificationStreaksProvider);

        // Assert
        expect(streaks.length, equals(1));
        expect(streaks[StreakType.dailyClassification.toString()]?.currentCount, equals(5));
      });
    });

    group('Error Handling', () {
      test('should handle loading state correctly', () {
        // Arrange
        when(mockRepository.getProfile()).thenAnswer(
          (_) => Future.delayed(const Duration(milliseconds: 100), () => testProfile),
        );

        // Act
        final state = container.read(gamificationNotifierProvider);

        // Assert
        expect(state.isLoading, isTrue);
        expect(state.hasValue, isFalse);
        expect(state.hasError, isFalse);
      });

      test('should provide fallback values during loading', () {
        // Arrange
        when(mockRepository.getProfile()).thenAnswer(
          (_) => Future.delayed(const Duration(milliseconds: 100), () => testProfile),
        );

        // Act
        final points = container.read(gamificationPointsProvider);
        final achievements = container.read(gamificationAchievementsProvider);
        final streaks = container.read(gamificationStreaksProvider);

        // Assert
        expect(points, equals(0));
        expect(achievements, isEmpty);
        expect(streaks, isEmpty);
      });

      test('should provide fallback values during error', () {
        // Arrange
        when(mockRepository.getProfile()).thenThrow(AppException.storage('Error'));

        // Act
        final points = container.read(gamificationPointsProvider);
        final achievements = container.read(gamificationAchievementsProvider);
        final streaks = container.read(gamificationStreaksProvider);

        // Assert
        expect(points, equals(0));
        expect(achievements, isEmpty);
        expect(streaks, isEmpty);
      });
    });
  });

  group('Performance Tests', () {
    late MockGamificationRepository mockRepository;
    late ProviderContainer container;

    setUp(() {
      mockRepository = MockGamificationRepository();
      container = ProviderContainer(
        overrides: [
          gamificationRepositoryProvider.overrideWithValue(mockRepository),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('should handle large achievement lists efficiently', () async {
      // Arrange
      final largeProfile = GamificationProfile(
        userId: 'test_user',
        streaks: {},
        points: const UserPoints(total: 1000),
        achievements: List.generate(100, (index) => Achievement(
          id: 'achievement_$index',
          title: 'Achievement $index',
          description: 'Description $index',
          type: AchievementType.wasteIdentified,
          threshold: 10,
          iconName: 'star',
          color: const Color(0xFF4CAF50),
          tier: AchievementTier.bronze,
          pointsReward: 10,
          progress: index % 2 == 0 ? 1.0 : 0.5,
          claimStatus: index % 2 == 0 ? ClaimStatus.unclaimed : ClaimStatus.ineligible,
        )),
        discoveredItemIds: {},
        unlockedHiddenContentIds: {},
      );

      when(mockRepository.getProfile()).thenAnswer((_) async => largeProfile);

      // Act
      final stopwatch = Stopwatch()..start();
      await container.read(gamificationNotifierProvider.future);
      final claimableAchievements = container.read(claimableAchievementsProvider);
      stopwatch.stop();

      // Assert
      expect(claimableAchievements.length, equals(50)); // Half are claimable
      expect(stopwatch.elapsedMilliseconds, lessThan(100)); // Should be fast
    });
  });
} 