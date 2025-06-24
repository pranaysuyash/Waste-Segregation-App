import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/services/points_engine.dart';
import 'package:waste_segregation_app/services/storage_service.dart';
import 'package:waste_segregation_app/services/cloud_storage_service.dart';
import 'package:waste_segregation_app/models/gamification.dart';
import 'package:waste_segregation_app/models/user_profile.dart';

// Simple mock implementations for testing
class TestStorageService implements StorageService {
  UserProfile? _userProfile;

  @override
  Future<UserProfile?> getCurrentUserProfile() async {
    return _userProfile ??= UserProfile(
      id: 'test_user',
      displayName: 'Test User',
      email: 'test@example.com',
      gamificationProfile: _createTestProfile(),
    );
  }

  @override
  Future<void> saveUserProfile(UserProfile profile) async {
    _userProfile = profile;
  }

  GamificationProfile _createTestProfile() {
    return GamificationProfile(
      userId: 'test_user',
      streaks: {},
      points: const UserPoints(total: 100, level: 2),
      achievements: [
        Achievement(
          id: 'claimable_achievement',
          title: 'Test Achievement',
          description: 'A test achievement',
          type: AchievementType.wasteIdentified,
          threshold: 10,
          iconName: 'star',
          color: const Color(0xFF4CAF50),
          pointsReward: 50,
          claimStatus: ClaimStatus.unclaimed,
          earnedOn: DateTime.now(),
          progress: 1.0,
        ),
        Achievement(
          id: 'already_claimed',
          title: 'Already Claimed',
          description: 'Already claimed achievement',
          type: AchievementType.wasteIdentified,
          threshold: 5,
          iconName: 'trophy',
          color: const Color(0xFF2196F3),
          pointsReward: 25,
          claimStatus: ClaimStatus.claimed,
          earnedOn: DateTime.now(),
          progress: 1.0,
        ),
        Achievement(
          id: 'not_claimable',
          title: 'Not Claimable',
          description: 'Not yet claimable',
          type: AchievementType.wasteIdentified,
          threshold: 20,
          iconName: 'badge',
          color: const Color(0xFFFF9800),
          pointsReward: 75,
          claimStatus: ClaimStatus.ineligible,
          progress: 0.5,
        ),
      ],
      discoveredItemIds: {},
      unlockedHiddenContentIds: {},
    );
  }

  // Implement other required methods with minimal implementations
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestCloudStorageService implements CloudStorageService {
  @override
  Future<void> saveUserProfileToFirestore(UserProfile profile) async {
    // No-op for testing
  }

  // Implement other required methods with minimal implementations
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Achievement Claiming Atomic Operations Tests', () {
    late TestStorageService testStorageService;
    late TestCloudStorageService testCloudStorageService;

    setUp(() {
      testStorageService = TestStorageService();
      testCloudStorageService = TestCloudStorageService();

      // Reset singleton before each test
      PointsEngine.resetInstance();
    });

    tearDown(() {
      // Clean up singleton after each test
      PointsEngine.resetInstance();
    });

    test('should claim achievement atomically and update points', () async {
      final pointsEngine = PointsEngine.getInstance(testStorageService, testCloudStorageService);
      await pointsEngine.initialize();

      // Verify initial state
      expect(pointsEngine.currentPoints, equals(100));

      final initialProfile = pointsEngine.currentProfile!;
      final claimableAchievement = initialProfile.achievements.firstWhere(
        (a) => a.id == 'claimable_achievement',
      );
      expect(claimableAchievement.claimStatus, equals(ClaimStatus.unclaimed));
      expect(claimableAchievement.isClaimable, isTrue);

      // Claim the achievement
      final claimedAchievement = await pointsEngine.claimAchievementReward('claimable_achievement');

      // Verify achievement was claimed
      expect(claimedAchievement.claimStatus, equals(ClaimStatus.claimed));
      expect(claimedAchievement.id, equals('claimable_achievement'));

      // Verify points were added
      expect(pointsEngine.currentPoints, equals(150)); // 100 + 50 reward

      // Verify profile was updated
      final updatedProfile = pointsEngine.currentProfile!;
      final updatedAchievement = updatedProfile.achievements.firstWhere(
        (a) => a.id == 'claimable_achievement',
      );
      expect(updatedAchievement.claimStatus, equals(ClaimStatus.claimed));
    });

    test('should prevent double claiming of same achievement', () async {
      final pointsEngine = PointsEngine.getInstance(testStorageService, testCloudStorageService);
      await pointsEngine.initialize();

      // Claim achievement first time
      await pointsEngine.claimAchievementReward('claimable_achievement');
      expect(pointsEngine.currentPoints, equals(150));

      // Attempt to claim again - should throw exception
      expect(
        () => pointsEngine.claimAchievementReward('claimable_achievement'),
        throwsException,
      );

      // Points should remain the same
      expect(pointsEngine.currentPoints, equals(150));
    });

    test('should handle concurrent claim attempts atomically', () async {
      final pointsEngine = PointsEngine.getInstance(testStorageService, testCloudStorageService);
      await pointsEngine.initialize();

      // Start multiple concurrent claim operations
      final futures = List.generate(3, (index) => pointsEngine.claimAchievementReward('claimable_achievement'));

      // Only one should succeed, others should fail
      final results = await Future.wait(
        futures.map((f) => f.then<Object>((achievement) => achievement).catchError((e) => e)),
        eagerError: false,
      );

      // Count successful claims
      final successfulClaims = results.where((r) => r is Achievement).length;
      final failedClaims = results.where((r) => r is Exception).length;

      expect(successfulClaims, equals(1));
      expect(failedClaims, equals(2));

      // Points should only be added once
      expect(pointsEngine.currentPoints, equals(150)); // 100 + 50
    });

    test('should reject claim for already claimed achievement', () async {
      final pointsEngine = PointsEngine.getInstance(testStorageService, testCloudStorageService);
      await pointsEngine.initialize();

      // Attempt to claim already claimed achievement
      expect(
        () => pointsEngine.claimAchievementReward('already_claimed'),
        throwsException,
      );

      // Points should remain unchanged
      expect(pointsEngine.currentPoints, equals(100));
    });

    test('should reject claim for non-claimable achievement', () async {
      final pointsEngine = PointsEngine.getInstance(testStorageService, testCloudStorageService);
      await pointsEngine.initialize();

      // Attempt to claim non-claimable achievement
      expect(
        () => pointsEngine.claimAchievementReward('not_claimable'),
        throwsException,
      );

      // Points should remain unchanged
      expect(pointsEngine.currentPoints, equals(100));
    });

    test('should reject claim for non-existent achievement', () async {
      final pointsEngine = PointsEngine.getInstance(testStorageService, testCloudStorageService);
      await pointsEngine.initialize();

      // Attempt to claim non-existent achievement
      expect(
        () => pointsEngine.claimAchievementReward('non_existent'),
        throwsException,
      );

      // Points should remain unchanged
      expect(pointsEngine.currentPoints, equals(100));
    });

    test('should maintain consistency across multiple operations', () async {
      final pointsEngine = PointsEngine.getInstance(testStorageService, testCloudStorageService);
      await pointsEngine.initialize();

      // Perform mixed operations
      final operations = [
        () => pointsEngine.claimAchievementReward('claimable_achievement'),
        () => pointsEngine.addPoints('classification', customPoints: 10),
        () => pointsEngine.addPoints('daily_streak', customPoints: 5),
      ];

      // Execute all operations
      for (final operation in operations) {
        await operation();
      }

      // Verify final state
      expect(pointsEngine.currentPoints, equals(165)); // 100 + 50 + 10 + 5

      // Verify achievement was claimed
      final profile = pointsEngine.currentProfile!;
      final claimedAchievement = profile.achievements.firstWhere(
        (a) => a.id == 'claimable_achievement',
      );
      expect(claimedAchievement.claimStatus, equals(ClaimStatus.claimed));
    });

    test('should emit proper events during claim operation', () async {
      final pointsEngine = PointsEngine.getInstance(testStorageService, testCloudStorageService);
      await pointsEngine.initialize();

      var notificationCount = 0;
      pointsEngine.addListener(() {
        notificationCount++;
      });

      // Claim achievement
      await pointsEngine.claimAchievementReward('claimable_achievement');

      // Should notify listeners
      expect(notificationCount, greaterThan(0));
    });
  });
}
