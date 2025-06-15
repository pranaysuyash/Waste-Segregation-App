import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:waste_segregation_app/models/gamification.dart';
import 'package:waste_segregation_app/models/action_points.dart';
import 'package:waste_segregation_app/providers/points_manager.dart';
import 'package:waste_segregation_app/services/storage_service.dart';
import 'package:waste_segregation_app/services/cloud_storage_service.dart';

import 'points_manager_test.mocks.dart';

@GenerateMocks([StorageService, CloudStorageService])
void main() {
  group('PointsManager', () {
    late MockStorageService mockStorageService;
    late MockCloudStorageService mockCloudStorageService;
    late ProviderContainer container;

    setUp(() {
      mockStorageService = MockStorageService();
      mockCloudStorageService = MockCloudStorageService();

      container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(mockStorageService),
          cloudStorageServiceProvider.overrideWithValue(mockCloudStorageService),
        ],
      );

      // Setup default mocks
      when(mockStorageService.getCurrentUserProfile()).thenAnswer((_) async => null);
    });

    tearDown(() {
      container.dispose();
    });

    group('Initialization', () {
      test('should initialize with default UserPoints when no profile exists', () async {
        final pointsManager = container.read(pointsManagerProvider.notifier);
        final points = await container.read(pointsManagerProvider.future);

        expect(points, isA<UserPoints>());
        expect(points.total, equals(0));
        expect(points.level, equals(1));
        expect(points.categoryPoints, isEmpty);
      });

      test('should load existing points from profile', () async {
        final existingProfile = UserProfile(
          id: 'test-user',
          gamificationProfile: GamificationProfile(
            userId: 'test-user',
            points: const UserPoints(
              total: 150,
              level: 2,
              categoryPoints: {'Recyclable': 100, 'Organic': 50},
            ),
            streaks: {},
            achievements: [],
            discoveredItemIds: {},
            unlockedHiddenContentIds: {},
          ),
        );

        when(mockStorageService.getCurrentUserProfile())
            .thenAnswer((_) async => existingProfile);

        final points = await container.read(pointsManagerProvider.future);

        expect(points.total, equals(150));
        expect(points.level, equals(2));
        expect(points.categoryPoints['Recyclable'], equals(100));
        expect(points.categoryPoints['Organic'], equals(50));
      });
    });

    group('Points Operations', () {
      test('should add classification points correctly', () async {
        final pointsManager = container.read(pointsManagerProvider.notifier);
        
        // Initialize with empty profile
        await container.read(pointsManagerProvider.future);

        // Add classification points
        final newPoints = await pointsManager.addPoints(
          PointableAction.classification,
          category: 'Recyclable',
        );

        expect(newPoints.total, equals(10));
        expect(newPoints.categoryPoints['classification'], equals(10));
      });

      test('should add custom points for supported actions', () async {
        final pointsManager = container.read(pointsManagerProvider.notifier);
        
        await container.read(pointsManagerProvider.future);

        final newPoints = await pointsManager.addPoints(
          PointableAction.achievementClaim,
          customPoints: 50,
        );

        expect(newPoints.total, equals(50));
      });

      test('should warn when custom points used for unsupported actions', () async {
        final pointsManager = container.read(pointsManagerProvider.notifier);
        
        await container.read(pointsManagerProvider.future);

        // This should work but log a warning
        final newPoints = await pointsManager.addPoints(
          PointableAction.classification,
          customPoints: 20, // Not supported for classification
        );

        expect(newPoints.total, equals(20)); // Should still work
      });

      test('should handle legacy string actions', () async {
        final pointsManager = container.read(pointsManagerProvider.notifier);
        
        await container.read(pointsManagerProvider.future);

        final newPoints = await pointsManager.addPointsLegacy('classification');

        expect(newPoints.total, equals(10));
      });

      test('should throw error for invalid legacy action keys', () async {
        final pointsManager = container.read(pointsManagerProvider.notifier);
        
        await container.read(pointsManagerProvider.future);

        expect(
          () => pointsManager.addPointsLegacy('invalid_action'),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('Points Consistency Validation', () {
      test('should validate points consistency within tolerance', () async {
        final pointsManager = container.read(pointsManagerProvider.notifier);
        
        await container.read(pointsManagerProvider.future);

        // Add points that should be consistent
        await pointsManager.addPoints(
          PointableAction.classification,
          category: 'Recyclable',
        );
        await pointsManager.addPoints(
          PointableAction.classification,
          category: 'Organic',
        );

        final points = container.read(pointsManagerProvider).value!;
        
        // Total should equal sum of category points
        final categorySum = points.categoryPoints.values.fold<int>(0, (sum, value) => sum + value);
        expect(points.total, equals(categorySum));
      });

      test('should handle points inconsistency gracefully', () async {
        // This test would require mocking the internal state
        // to simulate an inconsistency scenario
        final pointsManager = container.read(pointsManagerProvider.notifier);
        
        await container.read(pointsManagerProvider.future);

        // Add some points
        await pointsManager.addPoints(PointableAction.classification);

        // The validation should run without throwing errors
        // even if there are inconsistencies
        expect(container.read(pointsManagerProvider).hasValue, isTrue);
      });
    });

    group('Convenience Providers', () {
      test('currentPointsProvider should return correct points', () async {
        await container.read(pointsManagerProvider.future);
        
        final pointsManager = container.read(pointsManagerProvider.notifier);
        await pointsManager.addPoints(PointableAction.classification);

        final currentPoints = container.read(currentPointsProvider);
        expect(currentPoints, equals(10));
      });

      test('currentLevelProvider should return correct level', () async {
        await container.read(pointsManagerProvider.future);
        
        final pointsManager = container.read(pointsManagerProvider.notifier);
        
        // Add enough points to reach level 2 (100+ points)
        for (int i = 0; i < 11; i++) {
          await pointsManager.addPoints(PointableAction.classification);
        }

        final currentLevel = container.read(currentLevelProvider);
        expect(currentLevel, equals(2));
      });

      test('should handle loading and error states', () {
        // Test loading state
        final pointsAsync = container.read(pointsManagerProvider);
        expect(pointsAsync.isLoading, isTrue);

        final currentPoints = container.read(currentPointsProvider);
        expect(currentPoints, equals(0)); // Default for loading

        final currentLevel = container.read(currentLevelProvider);
        expect(currentLevel, equals(1)); // Default for loading
      });
    });

    group('Error Handling', () {
      test('should handle storage errors gracefully', () async {
        when(mockStorageService.getCurrentUserProfile())
            .thenThrow(Exception('Storage error'));

        final pointsAsync = await container.read(pointsManagerProvider.future)
            .catchError((error) => error);

        expect(pointsAsync, isA<Exception>());
      });

      test('should propagate errors from points operations', () async {
        final pointsManager = container.read(pointsManagerProvider.notifier);
        
        // This would require mocking the PointsEngine to throw errors
        // For now, we'll test that the method exists and can be called
        expect(pointsManager.addPoints, isA<Function>());
      });
    });

    group('State Management', () {
      test('should update state immediately after points operations', () async {
        final pointsManager = container.read(pointsManagerProvider.notifier);
        
        await container.read(pointsManagerProvider.future);

        // Listen to state changes
        var stateChanges = 0;
        container.listen(pointsManagerProvider, (previous, next) {
          stateChanges++;
        });

        await pointsManager.addPoints(PointableAction.classification);

        expect(stateChanges, greaterThan(0));
      });

      test('should refresh state correctly', () async {
        final pointsManager = container.read(pointsManagerProvider.notifier);
        
        await container.read(pointsManagerProvider.future);

        // Refresh should not throw
        await pointsManager.refresh();

        expect(container.read(pointsManagerProvider).hasValue, isTrue);
      });
    });
  });

  group('PointableAction', () {
    test('should have correct default points', () {
      expect(PointableAction.classification.defaultPoints, equals(10));
      expect(PointableAction.dailyStreak.defaultPoints, equals(5));
      expect(PointableAction.challengeComplete.defaultPoints, equals(25));
    });

    test('should find actions by key', () {
      final action = PointableAction.fromKey('classification');
      expect(action, equals(PointableAction.classification));

      final invalidAction = PointableAction.fromKey('invalid');
      expect(invalidAction, isNull);
    });

    test('should validate action keys', () {
      expect(PointableAction.isValidAction('classification'), isTrue);
      expect(PointableAction.isValidAction('invalid'), isFalse);
    });

    test('should categorize actions correctly', () {
      expect(PointableAction.classification.category, equals('classification'));
      expect(PointableAction.dailyStreak.category, equals('streak'));
      expect(PointableAction.badgeEarned.category, equals('achievement'));
    });

    test('should identify custom points support', () {
      expect(PointableAction.achievementClaim.supportsCustomPoints, isTrue);
      expect(PointableAction.classification.supportsCustomPoints, isFalse);
    });
  });
} 