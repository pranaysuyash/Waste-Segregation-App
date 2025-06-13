import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mockito/mockito.dart';
import 'package:waste_segregation_app/services/gamification_service.dart';
import 'package:waste_segregation_app/services/storage_service.dart';
import 'package:waste_segregation_app/services/cloud_storage_service.dart';
import 'package:waste_segregation_app/models/user_profile.dart';
import 'package:waste_segregation_app/models/gamification.dart';

class MockStorageService extends Mock implements StorageService {}
class MockCloudStorageService extends Mock implements CloudStorageService {}

void main() {
  group('GamificationService', () {
    late GamificationService gamificationService;
    late MockStorageService mockStorageService;
    late MockCloudStorageService mockCloudStorageService;

    setUpAll(() async {
      // Initialize Hive for testing
      await Hive.initFlutter();
    });

    setUp(() async {
      mockStorageService = MockStorageService();
      mockCloudStorageService = MockCloudStorageService();
      gamificationService = GamificationService(mockStorageService, mockCloudStorageService);
      
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

    test('getProfile should return guest profile when no user profile exists', () async {
      // Arrange
      when(mockStorageService.getCurrentUserProfile()).thenAnswer((_) async => null);

      // Act
      final profile = await gamificationService.getProfile();

      // Assert
      expect(profile, isNotNull);
      expect(profile.userId, startsWith('guest_user_'));
      expect(profile.achievements, isNotEmpty);
      expect(profile.points, isNotNull);
    });

    test('getProfile should return existing gamification profile when user profile exists', () async {
      // Arrange
      final existingGamificationProfile = GamificationProfile(
        userId: 'test_user_123',
        streaks: {},
        points: const UserPoints(total: 100, level: 2),
        achievements: [],
        discoveredItemIds: {},
        unlockedHiddenContentIds: {},
      );
      
      final userProfile = UserProfile(
        id: 'test_user_123',
        email: 'test@example.com',
        displayName: 'Test User',
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
        gamificationProfile: existingGamificationProfile,
      );

      when(mockStorageService.getCurrentUserProfile()).thenAnswer((_) async => userProfile);

      // Act
      final profile = await gamificationService.getProfile();

      // Assert
      expect(profile, isNotNull);
      expect(profile.userId, equals('test_user_123'));
      expect(profile.points.total, equals(100));
      expect(profile.points.level, equals(2));
    });

    test('getProfile should create new profile for authenticated user without gamification profile', () async {
      // Arrange
      final userProfile = UserProfile(
        id: 'test_user_456',
        email: 'test2@example.com',
        displayName: 'Test User 2',
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
        gamificationProfile: null, // No gamification profile yet
      );

      when(mockStorageService.getCurrentUserProfile()).thenAnswer((_) async => userProfile);

      // Act
      final profile = await gamificationService.getProfile();

      // Assert
      expect(profile, isNotNull);
      expect(profile.userId, equals('test_user_456'));
      expect(profile.achievements, isNotEmpty);
      expect(profile.points, isNotNull);
    });

    test('getProfile should handle errors gracefully and return emergency profile', () async {
      // Arrange
      when(mockStorageService.getCurrentUserProfile()).thenThrow(Exception('Storage error'));

      // Act
      final profile = await gamificationService.getProfile();

      // Assert
      expect(profile, isNotNull);
      expect(profile.userId, startsWith('emergency_user_'));
      expect(profile.achievements, isEmpty); // Emergency profile has empty achievements
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
  });
} 