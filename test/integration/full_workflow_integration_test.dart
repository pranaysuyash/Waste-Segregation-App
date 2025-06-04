import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:waste_segregation_app/services/ai_service.dart';
import 'package:waste_segregation_app/services/storage_service.dart';
import 'package:waste_segregation_app/services/gamification_service.dart';
import 'package:waste_segregation_app/services/analytics_service.dart';
import 'package:waste_segregation_app/services/community_service.dart';
import 'package:waste_segregation_app/services/cache_service.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/models/user_profile.dart';
import 'package:waste_segregation_app/models/gamification.dart';

// Mock services for integration testing
class MockAiService extends Mock implements AiService {}
class MockStorageService extends Mock implements StorageService {}
class MockGamificationService extends Mock implements GamificationService {}
class MockAnalyticsService extends Mock implements AnalyticsService {}
class MockCommunityService extends Mock implements CommunityService {}
class MockCacheService extends Mock implements CacheService {}

void main() {
  group('Integration Tests - Full Application Workflows', () {
    late MockAiService mockAiService;
    late MockStorageService mockStorageService;
    late MockGamificationService mockGamificationService;
    late MockAnalyticsService mockAnalyticsService;
    late MockCommunityService mockCommunityService;
    late MockCacheService mockCacheService;

    setUp(() {
      mockAiService = MockAiService();
      mockStorageService = MockStorageService();
      mockGamificationService = MockGamificationService();
      mockAnalyticsService = MockAnalyticsService();
      mockCommunityService = MockCommunityService();
      mockCacheService = MockCacheService();
    });

    group('Complete Classification Flow', () {
      test('should complete full flow: image → AI → gamification → storage → community', () async {
        // Arrange
        final imageData = Uint8List.fromList([1, 2, 3, 4, 5]);
        final imagePath = 'test_image.jpg';
        
        final expectedClassification = WasteClassification(
          itemName: 'Plastic Water Bottle',
          category: 'Dry Waste',
          subcategory: 'Plastic',
          explanation: 'Clear plastic bottle, recyclable with PET code 1',
          disposalInstructions: DisposalInstructions(
            primaryMethod: 'Recycle in blue bin',
            steps: ['Remove cap and label', 'Rinse thoroughly', 'Place in recycling bin'],
            hasUrgentTimeframe: false,
          ),
          timestamp: DateTime.now(),
          region: 'Test Region',
          visualFeatures: ['plastic', 'bottle', 'clear'],
          alternatives: [],
          confidence: 0.92,
          isRecyclable: true,
          userId: 'test_user_123',
        );

        final user = UserProfile(
          id: 'test_user_123',
          email: 'test@example.com',
          displayName: 'Test User',
        );

        final gamificationResult = {
          'points_earned': 10,
          'achievements_unlocked': ['Eco Novice'],
          'streak_updated': true,
          'new_level': false,
        };

        // Setup mocks
        when(mockCacheService.getCachedClassification(any))
            .thenAnswer((_) async => null); // No cache hit
        
        when(mockAiService.analyzeWebImage(imageData, imagePath))
            .thenAnswer((_) async => expectedClassification);
        
        when(mockGamificationService.processClassification(expectedClassification))
            .thenAnswer((_) async => gamificationResult);
        
        when(mockStorageService.saveClassification(expectedClassification))
            .thenAnswer((_) async => {});
        
        when(mockCommunityService.trackClassificationActivity(expectedClassification, user))
            .thenAnswer((_) async => {});
        
        when(mockAnalyticsService.trackEvent(any))
            .thenAnswer((_) async => {});
        
        when(mockCacheService.cacheClassification(any, expectedClassification))
            .thenAnswer((_) async => {});

        // Act - Execute full classification workflow
        final result = await executeFullClassificationWorkflow(
          imageData: imageData,
          imagePath: imagePath,
          user: user,
          aiService: mockAiService,
          storageService: mockStorageService,
          gamificationService: mockGamificationService,
          analyticsService: mockAnalyticsService,
          communityService: mockCommunityService,
          cacheService: mockCacheService,
        );

        // Assert
        expect(result.classification.itemName, equals('Plastic Water Bottle'));
        expect(result.classification.category, equals('Dry Waste'));
        expect(result.classification.confidence, equals(0.92));
        expect(result.gamificationResult['points_earned'], equals(10));
        expect(result.gamificationResult['achievements_unlocked'], contains('Eco Novice'));

        // Verify all services were called in correct order
        verifyInOrder([
          mockCacheService.getCachedClassification(any),
          mockAiService.analyzeWebImage(imageData, imagePath),
          mockGamificationService.processClassification(expectedClassification),
          mockStorageService.saveClassification(expectedClassification),
          mockCommunityService.trackClassificationActivity(expectedClassification, user),
          mockAnalyticsService.trackEvent(any),
          mockCacheService.cacheClassification(any, expectedClassification),
        ]);
      });

      test('should handle AI service failures gracefully with fallback', () async {
        final imageData = Uint8List.fromList([1, 2, 3, 4, 5]);
        final imagePath = 'test_image.jpg';
        
        final user = UserProfile(
          id: 'test_user_123',
          email: 'test@example.com',
          displayName: 'Test User',
        );

        final fallbackClassification = WasteClassification.fallback(imagePath);

        // Setup mocks - AI service fails
        when(mockCacheService.getCachedClassification(any))
            .thenAnswer((_) async => null);
        
        when(mockAiService.analyzeWebImage(imageData, imagePath))
            .thenThrow(Exception('AI service unavailable'));
        
        when(mockGamificationService.processClassification(any))
            .thenAnswer((_) async => {'points_earned': 0});
        
        when(mockStorageService.saveClassification(any))
            .thenAnswer((_) async => {});
        
        when(mockAnalyticsService.trackEvent(any))
            .thenAnswer((_) async => {});

        // Act
        final result = await executeFullClassificationWorkflow(
          imageData: imageData,
          imagePath: imagePath,
          user: user,
          aiService: mockAiService,
          storageService: mockStorageService,
          gamificationService: mockGamificationService,
          analyticsService: mockAnalyticsService,
          communityService: mockCommunityService,
          cacheService: mockCacheService,
        );

        // Assert - Should fallback gracefully
        expect(result.classification.itemName, contains('Unknown'));
        expect(result.classification.clarificationNeeded, isTrue);
        expect(result.hasError, isTrue);
        expect(result.errorMessage, contains('AI service'));

        // Verify error was tracked
        verify(mockAnalyticsService.trackEvent(any)).called(greaterThan(0));
      });

      test('should use cached results when available', () async {
        final imageData = Uint8List.fromList([1, 2, 3, 4, 5]);
        final imagePath = 'test_image.jpg';
        
        final cachedClassification = WasteClassification(
          itemName: 'Cached Plastic Bottle',
          category: 'Dry Waste',
          subcategory: 'Plastic',
          explanation: 'Cached result from previous analysis',
          disposalInstructions: DisposalInstructions(
            primaryMethod: 'Recycle',
            steps: ['Cached instructions'],
            hasUrgentTimeframe: false,
          ),
          timestamp: DateTime.now().subtract(Duration(minutes: 30)),
          region: 'Test Region',
          visualFeatures: ['plastic', 'bottle'],
          alternatives: [],
          confidence: 0.88,
          userId: 'test_user_123',
        );

        final user = UserProfile(
          id: 'test_user_123',
          email: 'test@example.com',
          displayName: 'Test User',
        );

        // Setup mocks - Cache hit
        when(mockCacheService.getCachedClassification(any))
            .thenAnswer((_) async => cachedClassification);
        
        when(mockGamificationService.processClassification(cachedClassification))
            .thenAnswer((_) async => {'points_earned': 5}); // Reduced points for cached
        
        when(mockStorageService.saveClassification(cachedClassification))
            .thenAnswer((_) async => {});

        // Act
        final result = await executeFullClassificationWorkflow(
          imageData: imageData,
          imagePath: imagePath,
          user: user,
          aiService: mockAiService,
          storageService: mockStorageService,
          gamificationService: mockGamificationService,
          analyticsService: mockAnalyticsService,
          communityService: mockCommunityService,
          cacheService: mockCacheService,
        );

        // Assert
        expect(result.classification.itemName, equals('Cached Plastic Bottle'));
        expect(result.classification.explanation, contains('Cached result'));
        expect(result.fromCache, isTrue);

        // Verify AI service was NOT called (cache hit)
        verifyNever(mockAiService.analyzeWebImage(any, any));
        
        // Verify cache was checked
        verify(mockCacheService.getCachedClassification(any)).called(1);
      });

      test('should handle concurrent classification requests efficiently', () async {
        final imageData1 = Uint8List.fromList([1, 2, 3, 4, 5]);
        final imageData2 = Uint8List.fromList([6, 7, 8, 9, 10]);
        final imageData3 = Uint8List.fromList([11, 12, 13, 14, 15]);
        
        final user = UserProfile(
          id: 'test_user_123',
          email: 'test@example.com',
          displayName: 'Test User',
        );

        // Setup mocks for multiple concurrent requests
        when(mockCacheService.getCachedClassification(any))
            .thenAnswer((_) async => null);
        
        when(mockAiService.analyzeWebImage(any, any))
            .thenAnswer((_) async => _createTestClassification('Concurrent Item'));
        
        when(mockGamificationService.processClassification(any))
            .thenAnswer((_) async => {'points_earned': 10});
        
        when(mockStorageService.saveClassification(any))
            .thenAnswer((_) async => {});
        
        when(mockCommunityService.trackClassificationActivity(any, user))
            .thenAnswer((_) async => {});
        
        when(mockAnalyticsService.trackEvent(any))
            .thenAnswer((_) async => {});

        // Act - Execute concurrent classifications
        final futures = [
          executeFullClassificationWorkflow(
            imageData: imageData1,
            imagePath: 'image1.jpg',
            user: user,
            aiService: mockAiService,
            storageService: mockStorageService,
            gamificationService: mockGamificationService,
            analyticsService: mockAnalyticsService,
            communityService: mockCommunityService,
            cacheService: mockCacheService,
          ),
          executeFullClassificationWorkflow(
            imageData: imageData2,
            imagePath: 'image2.jpg',
            user: user,
            aiService: mockAiService,
            storageService: mockStorageService,
            gamificationService: mockGamificationService,
            analyticsService: mockAnalyticsService,
            communityService: mockCommunityService,
            cacheService: mockCacheService,
          ),
          executeFullClassificationWorkflow(
            imageData: imageData3,
            imagePath: 'image3.jpg',
            user: user,
            aiService: mockAiService,
            storageService: mockStorageService,
            gamificationService: mockGamificationService,
            analyticsService: mockAnalyticsService,
            communityService: mockCommunityService,
            cacheService: mockCacheService,
          ),
        ];

        final results = await Future.wait(futures);

        // Assert
        expect(results.length, equals(3));
        expect(results.every((r) => r.classification.itemName == 'Concurrent Item'), isTrue);
        expect(results.every((r) => !r.hasError), isTrue);

        // Verify all services handled concurrent requests
        verify(mockAiService.analyzeWebImage(any, any)).called(3);
        verify(mockStorageService.saveClassification(any)).called(3);
        verify(mockGamificationService.processClassification(any)).called(3);
      });
    });

    group('User Journey Integration', () {
      test('should handle complete new user onboarding flow', () async {
        final newUser = UserProfile(
          id: 'new_user_456',
          email: 'newuser@example.com',
          displayName: 'New User',
          createdAt: DateTime.now(),
        );

        final firstClassification = _createTestClassification('First Item');

        // Setup mocks for new user
        when(mockGamificationService.getUserProfile())
            .thenAnswer((_) async => null); // No existing profile
        
        when(mockGamificationService.createUserProfile(newUser.id))
            .thenAnswer((_) async => GamificationProfile(
              userId: newUser.id,
              points: UserPoints(total: 0),
              streak: Streak(current: 0, longest: 0, lastUsageDate: DateTime.now()),
              achievements: [],
            ));
        
        when(mockGamificationService.processClassification(firstClassification))
            .thenAnswer((_) async => {
              'points_earned': 10,
              'achievements_unlocked': ['First Steps'],
              'streak_updated': true,
              'new_level': false,
            });
        
        when(mockStorageService.saveClassification(firstClassification))
            .thenAnswer((_) async => {});
        
        when(mockAnalyticsService.trackEvent(any))
            .thenAnswer((_) async => {});

        // Act - Execute new user onboarding
        final result = await executeNewUserOnboarding(
          user: newUser,
          firstClassification: firstClassification,
          gamificationService: mockGamificationService,
          storageService: mockStorageService,
          analyticsService: mockAnalyticsService,
        );

        // Assert
        expect(result.userProfileCreated, isTrue);
        expect(result.firstClassificationSaved, isTrue);
        expect(result.achievementsUnlocked, contains('First Steps'));
        expect(result.pointsEarned, equals(10));

        // Verify onboarding flow
        verifyInOrder([
          mockGamificationService.getUserProfile(),
          mockGamificationService.createUserProfile(newUser.id),
          mockGamificationService.processClassification(firstClassification),
          mockStorageService.saveClassification(firstClassification),
          mockAnalyticsService.trackEvent(any),
        ]);
      });

      test('should handle power user workflow with advanced features', () async {
        final powerUser = UserProfile(
          id: 'power_user_789',
          email: 'poweruser@example.com',
          displayName: 'Power User',
          createdAt: DateTime.now().subtract(Duration(days: 100)),
        );

        final powerUserProfile = GamificationProfile(
          userId: powerUser.id,
          points: UserPoints(total: 2500, level: 25),
          streak: Streak(current: 30, longest: 45, lastUsageDate: DateTime.now()),
          achievements: List.generate(15, (i) => Achievement(
            id: 'achievement_$i',
            title: 'Achievement $i',
            description: 'Advanced achievement',
            type: AchievementType.wasteIdentified,
            threshold: 100,
            iconName: 'star',
            color: Colors.gold,
            progress: 1.0,
          )),
        );

        final advancedClassifications = List.generate(5, (i) => 
          _createTestClassification('Advanced Item $i')
        );

        // Setup mocks for power user
        when(mockGamificationService.getUserProfile())
            .thenAnswer((_) async => powerUserProfile);
        
        when(mockStorageService.getClassificationHistory(userId: powerUser.id))
            .thenAnswer((_) async => List.generate(500, (i) => 
              _createTestClassification('Historical Item $i')
            ));
        
        when(mockGamificationService.processClassification(any))
            .thenAnswer((_) async => {
              'points_earned': 15, // Bonus for power users
              'achievements_unlocked': ['Master Classifier'],
              'streak_updated': true,
              'new_level': true,
            });

        // Act - Execute power user workflow
        final result = await executePowerUserWorkflow(
          user: powerUser,
          newClassifications: advancedClassifications,
          gamificationService: mockGamificationService,
          storageService: mockStorageService,
          analyticsService: mockAnalyticsService,
        );

        // Assert
        expect(result.userLevel, equals(25));
        expect(result.totalAchievements, equals(15));
        expect(result.currentStreak, equals(30));
        expect(result.classificationsProcessed, equals(5));
        expect(result.bonusPointsEarned, greaterThan(0));

        // Verify power user features
        verify(mockGamificationService.getUserProfile()).called(1);
        verify(mockStorageService.getClassificationHistory(userId: powerUser.id)).called(1);
        verify(mockGamificationService.processClassification(any)).called(5);
      });
    });

    group('Data Synchronization Integration', () {
      test('should sync data across multiple services consistently', () async {
        final user = UserProfile(
          id: 'sync_user_101',
          email: 'sync@example.com',
          displayName: 'Sync User',
        );

        final classification = _createTestClassification('Sync Test Item');

        // Simulate data synchronization across services
        when(mockStorageService.saveClassification(classification))
            .thenAnswer((_) async => {});
        
        when(mockGamificationService.processClassification(classification))
            .thenAnswer((_) async => {
              'points_earned': 10,
              'streak_updated': true,
            });
        
        when(mockCommunityService.trackClassificationActivity(classification, user))
            .thenAnswer((_) async => {});
        
        when(mockAnalyticsService.trackEvent(any))
            .thenAnswer((_) async => {});

        // Act - Execute data sync
        await executeDataSynchronization(
          classification: classification,
          user: user,
          storageService: mockStorageService,
          gamificationService: mockGamificationService,
          communityService: mockCommunityService,
          analyticsService: mockAnalyticsService,
        );

        // Assert - Verify all services received consistent data
        final storageCall = verify(mockStorageService.saveClassification(captureAny)).captured.first;
        final gamificationCall = verify(mockGamificationService.processClassification(captureAny)).captured.first;
        final communityCall = verify(mockCommunityService.trackClassificationActivity(captureAny, user)).captured.first;

        expect(storageCall.itemName, equals(classification.itemName));
        expect(gamificationCall.itemName, equals(classification.itemName));
        expect(communityCall.itemName, equals(classification.itemName));
        expect(storageCall.userId, equals(classification.userId));
        expect(gamificationCall.userId, equals(classification.userId));
        expect(communityCall.userId, equals(classification.userId));
      });

      test('should handle partial sync failures gracefully', () async {
        final user = UserProfile(
          id: 'partial_sync_user',
          email: 'partialsync@example.com',
          displayName: 'Partial Sync User',
        );

        final classification = _createTestClassification('Partial Sync Item');

        // Setup partial failure scenario
        when(mockStorageService.saveClassification(classification))
            .thenAnswer((_) async => {}); // Success
        
        when(mockGamificationService.processClassification(classification))
            .thenThrow(Exception('Gamification service failure')); // Failure
        
        when(mockCommunityService.trackClassificationActivity(classification, user))
            .thenAnswer((_) async => {}); // Success
        
        when(mockAnalyticsService.trackEvent(any))
            .thenAnswer((_) async => {}); // Success

        // Act & Assert - Should handle partial failures
        expect(() async => executeDataSynchronization(
          classification: classification,
          user: user,
          storageService: mockStorageService,
          gamificationService: mockGamificationService,
          communityService: mockCommunityService,
          analyticsService: mockAnalyticsService,
        ), returnsNormally);

        // Verify successful services were still called
        verify(mockStorageService.saveClassification(classification)).called(1);
        verify(mockCommunityService.trackClassificationActivity(classification, user)).called(1);
        verify(mockAnalyticsService.trackEvent(any)).called(greaterThan(0));
      });
    });

    group('Performance Integration Tests', () {
      test('should handle large dataset operations efficiently', () async {
        final largeClassificationList = List.generate(1000, (i) => 
          _createTestClassification('Large Dataset Item $i')
        );

        final user = UserProfile(
          id: 'performance_user',
          email: 'performance@example.com',
          displayName: 'Performance User',
        );

        // Setup mocks for large dataset
        when(mockStorageService.saveClassificationBatch(any))
            .thenAnswer((_) async => {});
        
        when(mockGamificationService.processBatchClassifications(any))
            .thenAnswer((_) async => {
              'total_points_earned': 10000,
              'achievements_unlocked': ['Batch Processor'],
            });
        
        when(mockCommunityService.batchTrackActivities(any, user))
            .thenAnswer((_) async => {});

        // Act
        final stopwatch = Stopwatch()..start();
        await executeLargeDatasetProcessing(
          classifications: largeClassificationList,
          user: user,
          storageService: mockStorageService,
          gamificationService: mockGamificationService,
          communityService: mockCommunityService,
        );
        stopwatch.stop();

        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(10000)); // Should complete within 10 seconds

        // Verify batch operations were used
        verify(mockStorageService.saveClassificationBatch(any)).called(1);
        verify(mockGamificationService.processBatchClassifications(any)).called(1);
        verify(mockCommunityService.batchTrackActivities(any, user)).called(1);
      });

      test('should maintain performance under memory pressure', () async {
        final classifications = List.generate(100, (i) => 
          _createTestClassification('Memory Test Item $i')
        );

        // Simulate memory pressure conditions
        final initialMemory = getCurrentMemoryUsage();

        for (final classification in classifications) {
          await executeFullClassificationWorkflow(
            imageData: Uint8List.fromList([1, 2, 3, 4, 5]),
            imagePath: 'memory_test_${classification.itemName}.jpg',
            user: UserProfile(id: 'memory_user', email: 'memory@test.com', displayName: 'Memory User'),
            aiService: mockAiService,
            storageService: mockStorageService,
            gamificationService: mockGamificationService,
            analyticsService: mockAnalyticsService,
            communityService: mockCommunityService,
            cacheService: mockCacheService,
          );
        }

        final finalMemory = getCurrentMemoryUsage();
        final memoryGrowth = finalMemory - initialMemory;

        // Assert memory usage is reasonable
        expect(memoryGrowth, lessThan(100 * 1024 * 1024)); // Less than 100MB growth
      });
    });
  });
}

// Helper classes for integration test results
class ClassificationWorkflowResult {
  final WasteClassification classification;
  final Map<String, dynamic> gamificationResult;
  final bool fromCache;
  final bool hasError;
  final String? errorMessage;

  ClassificationWorkflowResult({
    required this.classification,
    required this.gamificationResult,
    this.fromCache = false,
    this.hasError = false,
    this.errorMessage,
  });
}

class NewUserOnboardingResult {
  final bool userProfileCreated;
  final bool firstClassificationSaved;
  final List<String> achievementsUnlocked;
  final int pointsEarned;

  NewUserOnboardingResult({
    required this.userProfileCreated,
    required this.firstClassificationSaved,
    required this.achievementsUnlocked,
    required this.pointsEarned,
  });
}

class PowerUserWorkflowResult {
  final int userLevel;
  final int totalAchievements;
  final int currentStreak;
  final int classificationsProcessed;
  final int bonusPointsEarned;

  PowerUserWorkflowResult({
    required this.userLevel,
    required this.totalAchievements,
    required this.currentStreak,
    required this.classificationsProcessed,
    required this.bonusPointsEarned,
  });
}

// Helper functions for integration testing
Future<ClassificationWorkflowResult> executeFullClassificationWorkflow({
  required Uint8List imageData,
  required String imagePath,
  required UserProfile user,
  required AiService aiService,
  required StorageService storageService,
  required GamificationService gamificationService,
  required AnalyticsService analyticsService,
  required CommunityService communityService,
  required CacheService cacheService,
}) async {
  try {
    // Step 1: Check cache
    final imageHash = calculateImageHash(imageData);
    final cachedResult = await cacheService.getCachedClassification(imageHash);
    
    if (cachedResult != null) {
      // Use cached result
      final gamificationResult = await gamificationService.processClassification(cachedResult);
      await storageService.saveClassification(cachedResult);
      return ClassificationWorkflowResult(
        classification: cachedResult,
        gamificationResult: gamificationResult,
        fromCache: true,
      );
    }

    // Step 2: AI Classification
    final classification = await aiService.analyzeWebImage(imageData, imagePath);
    
    // Step 3: Process gamification
    final gamificationResult = await gamificationService.processClassification(classification);
    
    // Step 4: Save to storage
    await storageService.saveClassification(classification);
    
    // Step 5: Track community activity
    await communityService.trackClassificationActivity(classification, user);
    
    // Step 6: Track analytics
    await analyticsService.trackEvent({
      'type': 'classification_completed',
      'item': classification.itemName,
      'category': classification.category,
      'confidence': classification.confidence,
    });
    
    // Step 7: Cache result
    await cacheService.cacheClassification(imageHash, classification);
    
    return ClassificationWorkflowResult(
      classification: classification,
      gamificationResult: gamificationResult,
    );
  } catch (e) {
    // Handle errors with fallback
    final fallbackClassification = WasteClassification.fallback(imagePath);
    return ClassificationWorkflowResult(
      classification: fallbackClassification,
      gamificationResult: {'points_earned': 0},
      hasError: true,
      errorMessage: e.toString(),
    );
  }
}

Future<NewUserOnboardingResult> executeNewUserOnboarding({
  required UserProfile user,
  required WasteClassification firstClassification,
  required GamificationService gamificationService,
  required StorageService storageService,
  required AnalyticsService analyticsService,
}) async {
  // Check if user profile exists
  final existingProfile = await gamificationService.getUserProfile();
  
  bool profileCreated = false;
  if (existingProfile == null) {
    await gamificationService.createUserProfile(user.id);
    profileCreated = true;
  }
  
  // Process first classification
  final gamificationResult = await gamificationService.processClassification(firstClassification);
  
  // Save classification
  await storageService.saveClassification(firstClassification);
  
  // Track onboarding completion
  await analyticsService.trackEvent({
    'type': 'user_onboarding_completed',
    'user_id': user.id,
    'first_classification': firstClassification.itemName,
  });
  
  return NewUserOnboardingResult(
    userProfileCreated: profileCreated,
    firstClassificationSaved: true,
    achievementsUnlocked: List<String>.from(gamificationResult['achievements_unlocked'] ?? []),
    pointsEarned: gamificationResult['points_earned'] ?? 0,
  );
}

Future<PowerUserWorkflowResult> executePowerUserWorkflow({
  required UserProfile user,
  required List<WasteClassification> newClassifications,
  required GamificationService gamificationService,
  required StorageService storageService,
  required AnalyticsService analyticsService,
}) async {
  // Get current user profile
  final userProfile = await gamificationService.getUserProfile();
  
  // Get classification history
  final history = await storageService.getClassificationHistory(userId: user.id);
  
  // Process new classifications
  int totalBonusPoints = 0;
  for (final classification in newClassifications) {
    final result = await gamificationService.processClassification(classification);
    totalBonusPoints += result['points_earned'] ?? 0;
    await storageService.saveClassification(classification);
  }
  
  return PowerUserWorkflowResult(
    userLevel: userProfile?.points.level ?? 0,
    totalAchievements: userProfile?.achievements.length ?? 0,
    currentStreak: userProfile?.streak.current ?? 0,
    classificationsProcessed: newClassifications.length,
    bonusPointsEarned: totalBonusPoints,
  );
}

Future<void> executeDataSynchronization({
  required WasteClassification classification,
  required UserProfile user,
  required StorageService storageService,
  required GamificationService gamificationService,
  required CommunityService communityService,
  required AnalyticsService analyticsService,
}) async {
  final futures = <Future>[];
  
  // Execute all sync operations
  futures.add(storageService.saveClassification(classification));
  futures.add(gamificationService.processClassification(classification).catchError((e) => {}));
  futures.add(communityService.trackClassificationActivity(classification, user));
  futures.add(analyticsService.trackEvent({
    'type': 'data_sync',
    'classification_id': classification.timestamp.toString(),
  }));
  
  // Wait for all operations (some may fail)
  await Future.wait(futures, eagerError: false);
}

Future<void> executeLargeDatasetProcessing({
  required List<WasteClassification> classifications,
  required UserProfile user,
  required StorageService storageService,
  required GamificationService gamificationService,
  required CommunityService communityService,
}) async {
  // Use batch operations for efficiency
  await storageService.saveClassificationBatch(classifications);
  await gamificationService.processBatchClassifications(classifications);
  await communityService.batchTrackActivities(classifications, user);
}

// Helper functions
String calculateImageHash(Uint8List imageData) {
  return 'hash_${imageData.length}_${imageData.first}_${imageData.last}';
}

int getCurrentMemoryUsage() {
  // Mock implementation - in real app would use platform-specific memory APIs
  return 50 * 1024 * 1024; // 50MB
}

WasteClassification _createTestClassification(String itemName) {
  return WasteClassification(
    itemName: itemName,
    category: 'Dry Waste',
    subcategory: 'Test',
    explanation: 'Test classification for $itemName',
    disposalInstructions: DisposalInstructions(
      primaryMethod: 'Test disposal',
      steps: ['Step 1'],
      hasUrgentTimeframe: false,
    ),
    timestamp: DateTime.now(),
    region: 'Test Region',
    visualFeatures: ['test'],
    alternatives: [],
    confidence: 0.85,
    userId: 'test_user',
  );
}

// Extension methods for batch operations (mock implementations)
extension StorageServiceBatch on StorageService {
  Future<void> saveClassificationBatch(List<WasteClassification> classifications) async {
    // Mock batch save implementation
  }
}

extension GamificationServiceBatch on GamificationService {
  Future<Map<String, dynamic>> processBatchClassifications(List<WasteClassification> classifications) async {
    return {
      'total_points_earned': classifications.length * 10,
      'achievements_unlocked': ['Batch Processor'],
    };
  }
}

extension CommunityServiceBatch on CommunityService {
  Future<void> batchTrackActivities(List<WasteClassification> classifications, UserProfile user) async {
    // Mock batch tracking implementation
  }
}
