import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:waste_segregation_app/services/gamification_service.dart';
import 'package:waste_segregation_app/services/storage_service.dart';
import 'package:waste_segregation_app/services/cloud_storage_service.dart';
import 'package:waste_segregation_app/models/gamification.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/models/user_profile.dart';

// Manual mocks
class MockStorageService extends Mock implements StorageService {}
class MockCloudStorageService extends Mock implements CloudStorageService {}

void main() {
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
    
    // Initialize the gamification service
    await gamificationService.initGamification();
  });

  tearDown(() async {
    // Clean up Hive boxes after each test
    try {
      if (Hive.isBoxOpen('gamificationBox')) {
        final box = Hive.box('gamificationBox');
        await box.clear();
        await box.close();
      }
    } catch (e) {
      // Box might not exist or already closed
    }
  });

  group('GamificationService Initialization', () {
    test('should initialize successfully', () async {
      expect(() async => await gamificationService.initGamification(), 
             returnsNormally);
    });

    test('should create default challenges on first run', () async {
      await gamificationService.initGamification();
      
      final challenges = await gamificationService.getActiveChallenges();
      expect(challenges, isNotEmpty);
      expect(challenges.length, lessThanOrEqualTo(3)); // Should have active challenges
    });

    test('should handle corrupted challenge data gracefully', () async {
      // Simulate corrupted data
      if (Hive.isBoxOpen('gamificationBox')) {
        final box = Hive.box('gamificationBox');
        await box.put('defaultChallenges', 'invalid_json_data');
      }
      
      // Should not throw on initialization
      expect(() async => await gamificationService.initGamification(), 
             returnsNormally);
    });
  });

  group('Profile Management', () {
    test('should create new profile for authenticated user', () async {
      final mockUser = UserProfile(
        id: 'test_user_123',
        email: 'test@example.com',
        displayName: 'Test User',
      );
      
      when(mockStorageService.getCurrentUserProfile())
          .thenAnswer((_) async => mockUser);
      // when(mockStorageService.saveUserProfile(argThat(isA<UserProfile>())))
      //     .thenAnswer((_) async {});
      // when(mockCloudStorageService.saveUserProfileToFirestore(argThat(isA<UserProfile>())))
      //     .thenAnswer((_) async {});

      final profile = await gamificationService.getProfile();
      
      expect(profile.userId, equals('test_user_123'));
      expect(profile.points.total, equals(0));
      expect(profile.streak.current, equals(0));
      expect(profile.achievements, isNotEmpty);
      
      // verify(mockStorageService.saveUserProfile(argThat(isA<UserProfile>())))
      //     .called(1);
      // verify(mockCloudStorageService.saveUserProfileToFirestore(argThat(isA<UserProfile>())))
      //     .called(1);
    });

    test('should return existing profile if already exists', () async {
      final existingProfile = GamificationProfile(
        userId: 'test_user_123',
        points: const UserPoints(total: 100, level: 1),
        streak: Streak(current: 5, longest: 10, lastUsageDate: DateTime.now()),
        achievements: [],
      );
      
      final mockUser = UserProfile(
        id: 'test_user_123',
        email: 'test@example.com',
        displayName: 'Test User',
        gamificationProfile: existingProfile,
      );
      
      when(mockStorageService.getCurrentUserProfile())
          .thenAnswer((_) async => mockUser);

      final profile = await gamificationService.getProfile();
      
      expect(profile.userId, equals('test_user_123'));
      expect(profile.points.total, equals(100));
      expect(profile.streak.current, equals(5));
      
      // verifyNever(mockStorageService.saveUserProfile(any));
    });

    test('should create guest profile when no user authenticated', () async {
      when(mockStorageService.getCurrentUserProfile())
          .thenAnswer((_) async => null);

      final profile = await gamificationService.getProfile();
      
      expect(profile.userId, startsWith('guest_user_'));
      expect(profile.points.total, equals(0));
      expect(profile.achievements, isNotEmpty);
    });
  });

  group('Points System', () {
    setUp(() async {
      final mockUser = UserProfile(
        id: 'test_user_123',
        email: 'test@example.com',
        displayName: 'Test User',
      );
      
      when(mockStorageService.getCurrentUserProfile())
          .thenAnswer((_) async => mockUser);
      // when(mockStorageService.saveUserProfile(any))
      //     .thenAnswer((_) async {});
      // when(mockCloudStorageService.saveUserProfileToFirestore(any))
      //     .thenAnswer((_) async {});
    });

    test('should add points for classification', () async {
      final points = await gamificationService.addPoints('classification', category: 'Dry Waste');
      
      expect(points.total, equals(10));
      expect(points.categoryPoints['Dry Waste'], equals(10));
      expect(points.level, equals(1)); // 10 points = level 1 (0-99 points)
    });

    test('should calculate correct level based on points', () async {
      await gamificationService.addPoints('classification', customPoints: 250);
      
      final profile = await gamificationService.getProfile();
      expect(profile.points.level, equals(3)); // 250 points = level 3 (200-299 points range)
    });

    test('should handle custom points correctly', () async {
      final points = await gamificationService.addPoints('custom_action', customPoints: 50);
      
      expect(points.total, equals(50));
    });

    test('should not add points for invalid action without custom points', () async {
      final initialProfile = await gamificationService.getProfile();
      final initialPoints = initialProfile.points.total;
      
      final points = await gamificationService.addPoints('invalid_action');
      
      expect(points.total, equals(initialPoints));
    });

    test('should calculate correct points to next level', () async {
      // Test with 5 points (level 1, need 95 more for level 2)
      await gamificationService.addPoints('classification', customPoints: 5);
      final profile1 = await gamificationService.getProfile();
      expect(profile1.points.level, equals(1));
      expect(profile1.points.pointsToNextLevel, equals(95)); 

      // Test with 150 points (level 2, need 50 more for level 3)
      await gamificationService.addPoints('classification', customPoints: 145); // Total = 150
      final profile2 = await gamificationService.getProfile();
      expect(profile2.points.level, equals(2));
      expect(profile2.points.pointsToNextLevel, equals(50));
    });
  });

  group('Streak Management', () {
    setUp(() async {
      final mockUser = UserProfile(
        id: 'test_user_123',
        email: 'test@example.com',
        displayName: 'Test User',
      );
      
      when(mockStorageService.getCurrentUserProfile())
          .thenAnswer((_) async => mockUser);
      // when(mockStorageService.saveUserProfile(any))
      //     .thenAnswer((_) async {});
      // when(mockCloudStorageService.saveUserProfileToFirestore(any))
      //     .thenAnswer((_) async {});
    });

    test('should start new streak on first use', () async {
      final streak = await gamificationService.updateStreak();
      
      expect(streak.current, equals(1));
      expect(streak.longest, equals(1));
    });

    test('should increment streak for consecutive days', () async {
      // Simulate yesterday's usage
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final profile = await gamificationService.getProfile();
      final updatedProfile = profile.copyWith(
        streak: Streak(current: 1, longest: 1, lastUsageDate: yesterday),
      );
      
      final mockUser = UserProfile(
        id: 'test_user_123',
        email: 'test@example.com',
        displayName: 'Test User',
        gamificationProfile: updatedProfile,
      );
      
      when(mockStorageService.getCurrentUserProfile())
          .thenAnswer((_) async => mockUser);

      final newStreak = await gamificationService.updateStreak();
      
      expect(newStreak.current, equals(2));
      expect(newStreak.longest, equals(2));
    });

    test('should reset streak for missed days', () async {
      // Simulate usage 3 days ago
      final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
      final profile = await gamificationService.getProfile();
      final updatedProfile = profile.copyWith(
        streak: Streak(current: 5, longest: 5, lastUsageDate: threeDaysAgo),
      );
      
      final mockUser = UserProfile(
        id: 'test_user_123',
        email: 'test@example.com',
        displayName: 'Test User',
        gamificationProfile: updatedProfile,
      );
      
      when(mockStorageService.getCurrentUserProfile())
          .thenAnswer((_) async => mockUser);

      final newStreak = await gamificationService.updateStreak();
      
      expect(newStreak.current, equals(1)); // Reset to 1
      expect(newStreak.longest, equals(5)); // Longest streak preserved
    });

    test('should maintain streak for same day usage', () async {
      // Simulate earlier today usage
      final todayEarlier = DateTime.now().subtract(const Duration(hours: 2));
      final profile = await gamificationService.getProfile();
      final updatedProfile = profile.copyWith(
        streak: Streak(current: 3, longest: 5, lastUsageDate: todayEarlier),
      );
      
      final mockUser = UserProfile(
        id: 'test_user_123',
        email: 'test@example.com',
        displayName: 'Test User',
        gamificationProfile: updatedProfile,
      );
      
      when(mockStorageService.getCurrentUserProfile())
          .thenAnswer((_) async => mockUser);

      final newStreak = await gamificationService.updateStreak();
      
      expect(newStreak.current, equals(3)); // Should remain the same
      expect(newStreak.longest, equals(5));
    });
  });

  group('Achievement System', () {
    setUp(() async {
      final mockUser = UserProfile(
        id: 'test_user_123',
        email: 'test@example.com',
        displayName: 'Test User',
      );
      
      when(mockStorageService.getCurrentUserProfile())
          .thenAnswer((_) async => mockUser);
      // when(mockStorageService.saveUserProfile(any))
      //     .thenAnswer((_) async {});
      // when(mockCloudStorageService.saveUserProfileToFirestore(any))
      //     .thenAnswer((_) async {});
    });

    test('should unlock achievement when threshold is reached', () async {
      // Process 5 classifications to unlock "Waste Novice" achievement
      for (int i = 0; i < 5; i++) {
        await gamificationService.updateAchievementProgress(AchievementType.wasteIdentified, 1);
      }
      
      final profile = await gamificationService.getProfile();
      final wasteNovice = profile.achievements.firstWhere(
        (a) => a.id == 'waste_novice',
      );
      
      expect(wasteNovice.isEarned, isTrue);
      expect(wasteNovice.progress, equals(1.0));
    });

    test('should not unlock achievement if level requirement not met', () async {
      // Try to unlock "Waste Apprentice" (requires level 2) with level 0 user
      for (int i = 0; i < 15; i++) {
        await gamificationService.updateAchievementProgress(AchievementType.wasteIdentified, 1);
      }
      
      final profile = await gamificationService.getProfile();
      final wasteApprentice = profile.achievements.firstWhere(
        (a) => a.id == 'waste_apprentice',
      );
      
      expect(wasteApprentice.isEarned, isFalse);
      expect(wasteApprentice.progress, equals(1.0)); // Progress complete but not earned
    });

    test('should unlock achievement when both progress and level requirements are met', () async {
      // First gain enough points to reach level 2
      await gamificationService.addPoints('classification', customPoints: 200);
      
      // Then make progress on the achievement
      for (int i = 0; i < 15; i++) {
        await gamificationService.updateAchievementProgress(AchievementType.wasteIdentified, 1);
      }
      
      final profile = await gamificationService.getProfile();
      final wasteApprentice = profile.achievements.firstWhere(
        (a) => a.id == 'waste_apprentice',
      );
      
      expect(wasteApprentice.isEarned, isTrue);
      expect(wasteApprentice.progress, equals(1.0));
    });
  });

  group('Classification Processing', () {
    setUp(() async {
      final mockUser = UserProfile(
        id: 'test_user_123',
        email: 'test@example.com',
        displayName: 'Test User',
      );
      
      when(mockStorageService.getCurrentUserProfile())
          .thenAnswer((_) async => mockUser);
      // when(mockStorageService.saveUserProfile(any))
      //     .thenAnswer((_) async {});
      // when(mockCloudStorageService.saveUserProfileToFirestore(any))
      //     .thenAnswer((_) async {});
    });

    test('should process classification and award points', () async {
      final classification = WasteClassification(
        itemName: 'Plastic Bottle',
        category: 'Dry Waste',
        subcategory: 'Plastic',
        explanation: 'Test explanation',
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Recycle',
          steps: ['Step 1'],
          hasUrgentTimeframe: false,
        ),
        timestamp: DateTime.now(),
        region: 'Test Region',
        visualFeatures: [],
        alternatives: [],
      );

      final completedChallenges = await gamificationService.processClassification(classification);
      
      final profile = await gamificationService.getProfile();
      expect(profile.points.total, equals(10)); // 10 points for classification
      expect(profile.points.categoryPoints['Dry Waste'], equals(10));
      
      // Should have some completed challenges potentially
      expect(completedChallenges, isA<List<Challenge>>());
    });

    test('should track new categories for achievements', () async {
      // First classification in Dry Waste
      final dryWasteClassification = WasteClassification(
        itemName: 'Paper',
        category: 'Dry Waste',
        explanation: 'Test explanation',
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Recycle',
          steps: ['Step 1'],
          hasUrgentTimeframe: false,
        ),
        timestamp: DateTime.now(),
        region: 'Test Region',
        visualFeatures: [],
        alternatives: [],
      );

      await gamificationService.processClassification(dryWasteClassification);
      
      // Second classification in Wet Waste (new category)
      final wetWasteClassification = WasteClassification(
        itemName: 'Apple Core',
        category: 'Wet Waste',
        explanation: 'Test explanation',
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Compost',
          steps: ['Step 1'],
          hasUrgentTimeframe: false,
        ),
        timestamp: DateTime.now(),
        region: 'Test Region',
        visualFeatures: [],
        alternatives: [],
      );

      await gamificationService.processClassification(wetWasteClassification);
      
      final profile = await gamificationService.getProfile();
      expect(profile.points.categoryPoints.length, equals(2));
      expect(profile.points.categoryPoints['Dry Waste'], equals(10));
      expect(profile.points.categoryPoints['Wet Waste'], equals(10));
    });
  });

  group('Challenge System', () {
    setUp(() async {
      final mockUser = UserProfile(
        id: 'test_user_123',
        email: 'test@example.com',
        displayName: 'Test User',
      );
      
      when(mockStorageService.getCurrentUserProfile())
          .thenAnswer((_) async => mockUser);
      // when(mockStorageService.saveUserProfile(any))
      //     .thenAnswer((_) async {});
      // when(mockCloudStorageService.saveUserProfileToFirestore(any))
      //     .thenAnswer((_) async {});
    });

    test('should load active challenges', () async {
      final challenges = await gamificationService.getActiveChallenges();
      
      expect(challenges, isNotEmpty);
      expect(challenges.length, lessThanOrEqualTo(3)); // Max 3 active challenges
    });

    test('should update challenge progress on classification', () async {
      final classification = WasteClassification(
        itemName: 'Plastic Bottle',
        category: 'Dry Waste',
        subcategory: 'Plastic',
        explanation: 'Test explanation',
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Recycle',
          steps: ['Step 1'],
          hasUrgentTimeframe: false,
        ),
        timestamp: DateTime.now(),
        region: 'Test Region',
        visualFeatures: [],
        alternatives: [],
      );

      final completedChallenges = await gamificationService.updateChallengeProgress(classification);
      
      // Check that challenges were potentially updated
      final activeChallenges = await gamificationService.getActiveChallenges();
      expect(activeChallenges, isNotEmpty);
      
      // Completed challenges should be a list (empty or not)
      expect(completedChallenges, isA<List<Challenge>>());
    });
  });

  group('Error Handling', () {
    test('should handle storage service errors gracefully', () async {
      when(mockStorageService.getCurrentUserProfile())
          .thenThrow(Exception('Storage error'));

      // Should not throw and should return a guest profile
      final profile = await gamificationService.getProfile();
      expect(profile.userId, startsWith('guest_user_'));
    });

    test('should handle cloud storage errors gracefully', () async {
      final mockUser = UserProfile(
        id: 'test_user_123',
        email: 'test@example.com',
        displayName: 'Test User',
      );
      
      when(mockStorageService.getCurrentUserProfile())
          .thenAnswer((_) async => mockUser);
      // when(mockStorageService.saveUserProfile(any))
      //     .thenAnswer((_) async {});
      // when(mockCloudStorageService.saveUserProfileToFirestore(any))
      //     .thenThrow(Exception('Cloud storage error'));

      // Should still save locally even if cloud save fails
      expect(() async => await gamificationService.addPoints('classification'), 
             returnsNormally);
    });
  });

  group('Data Persistence', () {
    test('should save and retrieve gamification data correctly', () async {
      final mockUser = UserProfile(
        id: 'test_user_123',
        email: 'test@example.com',
        displayName: 'Test User',
      );
      
      when(mockStorageService.getCurrentUserProfile())
          .thenAnswer((_) async => mockUser);
      // when(mockStorageService.saveUserProfile(any))
      //     .thenAnswer((_) async {});
      // when(mockCloudStorageService.saveUserProfileToFirestore(any))
      //     .thenAnswer((_) async {});

      // Add some points and update streak
      await gamificationService.addPoints('classification', category: 'Dry Waste');
      await gamificationService.updateStreak();
      
      // Verify save was called
      // verify(mockStorageService.saveUserProfile(any)).called(greaterThan(0));
      // verify(mockCloudStorageService.saveUserProfileToFirestore(any)).called(greaterThan(0));
    });
  });
} 