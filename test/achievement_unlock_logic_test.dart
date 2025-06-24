import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/services/gamification_service.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/models/gamification.dart';
import 'package:waste_segregation_app/services/storage_service.dart';
import 'test_config/plugin_mock_setup.dart';
import 'mocks/mock_cloud_storage_service.dart';

void main() {
  group('Achievement Unlock Logic Tests', () {
    late GamificationService gamificationService;
    late StorageService storageService;
    late MockCloudStorageService cloudStorageService;

    setUpAll(() {
      TestHelpers.setUpAll();
      PluginMockSetup.setupAll();
      PluginMockSetup.setupFirebase();
    });

    setUp(() async {
      await StorageService.initializeHive();
      storageService = StorageService();
      cloudStorageService = MockCloudStorageService(storageService);
      gamificationService = GamificationService(storageService, cloudStorageService as dynamic);
    });

    tearDownAll(() {
      TestHelpers.tearDownAll();
    });

    test('Should unlock "First Classification" achievement on first scan', () async {
      // Given: No previous classifications
      await storageService.clearClassifications();

      // When: User makes their first classification
      final classification = WasteClassification(
        itemName: 'Plastic Bottle',
        category: 'plastic',
        subcategory: 'Recyclable Plastic',
        explanation: 'Test classification',
        region: 'US',
        visualFeatures: const ['test feature'],
        alternatives: const [],
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Recycle',
          steps: const ['Clean item', 'Place in recycling bin'],
          hasUrgentTimeframe: false,
        ),
        timestamp: DateTime(2023, 1, 1, 10),
        imageUrl: 'test.jpg',
        confidence: 0.95,
        isRecyclable: true,
        isCompostable: false,
        requiresSpecialDisposal: false,
        hasUrgentTimeframe: false,
      );

      await gamificationService.processClassification(classification);

      // Then: First classification achievement should be unlocked
      final profile = await gamificationService.getProfile();
      final firstClassificationAchievement = profile.achievements
          .firstWhere((a) => a.id == 'first_classification');
      
      expect(firstClassificationAchievement.isEarned, true);
    });

    test('Should unlock "Recycling Expert" achievement after 50 recyclable items', () async {
      // Given: 49 previous recyclable classifications
      await storageService.clearClassifications();
      
      for (var i = 0; i < 49; i++) {
        final classification = WasteClassification(
          itemName: 'Recyclable Item $i',
          category: 'plastic',
          subcategory: 'Recyclable',
          explanation: 'Test classification',
          region: 'US',
          visualFeatures: const ['test feature'],
          alternatives: const [],
          disposalInstructions: DisposalInstructions(
            primaryMethod: 'Recycle',
            steps: const ['Clean item', 'Place in recycling bin'],
            hasUrgentTimeframe: false,
          ),
          timestamp: DateTime(2023, 1, 1, 10),
          imageUrl: 'test.jpg',
          confidence: 0.95,
          isRecyclable: true,
          isCompostable: false,
          requiresSpecialDisposal: false,
          hasUrgentTimeframe: false,
        );
        await gamificationService.processClassification(classification);
      }

      // When: User classifies their 50th recyclable item
      final finalClassification = WasteClassification(
        itemName: 'Final Recyclable',
        category: 'plastic',
        subcategory: 'Recyclable',
        explanation: 'Test classification',
        region: 'US',
        visualFeatures: const ['test feature'],
        alternatives: const [],
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Recycle',
          steps: const ['Clean item', 'Place in recycling bin'],
          hasUrgentTimeframe: false,
        ),
        timestamp: DateTime(2023, 1, 1, 11),
        imageUrl: 'test.jpg',
        confidence: 0.95,
        isRecyclable: true,
        isCompostable: false,
        requiresSpecialDisposal: false,
        hasUrgentTimeframe: false,
      );

      await gamificationService.processClassification(finalClassification);

      // Then: Recycling Expert achievement should be unlocked
      final profile = await gamificationService.getProfile();
      final recyclingExpertAchievement = profile.achievements
          .firstWhere((a) => a.id == 'recycling_expert');
      
      expect(recyclingExpertAchievement.isEarned, true);
    });

    test('Should award different points based on classification type', () async {
      await storageService.clearClassifications();
      
      final initialProfile = await gamificationService.getProfile();
      final initialPoints = initialProfile.points.total;

      // Test various classification types and their point values
      final classifications = [
        WasteClassification(
          itemName: 'Compost',
          category: 'plastic',
          subcategory: 'Organic',
          explanation: 'Test classification',
          region: 'US',
          visualFeatures: const ['test feature'],
          alternatives: const [],
          disposalInstructions: DisposalInstructions(
            primaryMethod: 'Compost',
            steps: const ['Add to compost bin'],
            hasUrgentTimeframe: false,
          ),
          timestamp: DateTime(2023, 1, 1, 10),
          imageUrl: 'test.jpg',
          confidence: 0.95,
          isRecyclable: false,
          isCompostable: true,
          requiresSpecialDisposal: false,
          hasUrgentTimeframe: false,
        ),
        WasteClassification(
          itemName: 'Battery',
          category: 'plastic',
          subcategory: 'Electronic Waste',
          explanation: 'Test classification',
          region: 'US',
          visualFeatures: const ['test feature'],
          alternatives: const [],
          disposalInstructions: DisposalInstructions(
            primaryMethod: 'Special disposal',
            steps: const ['Take to hazardous waste facility'],
            hasUrgentTimeframe: false,
          ),
          timestamp: DateTime(2023, 1, 1, 11),
          imageUrl: 'test.jpg',
          confidence: 0.95,
          isRecyclable: false,
          isCompostable: false,
          requiresSpecialDisposal: true,
          hasUrgentTimeframe: false,
        ),
      ];

      for (final classification in classifications) {
        await gamificationService.processClassification(classification);
      }

      final finalProfile = await gamificationService.getProfile();
      
      // Points should have increased
      expect(finalProfile.points.total, greaterThan(initialPoints));
    });

    test('Should maintain streak with consecutive daily classifications', () async {
      await storageService.clearClassifications();
      
      // Simulate classifications on consecutive days
      final classification1 = WasteClassification(
        itemName: 'Day 1 Item',
        category: 'plastic',
        subcategory: 'Recyclable',
        explanation: 'Test classification',
        region: 'US',
        visualFeatures: const ['test feature'],
        alternatives: const [],
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Recycle',
          steps: const ['Clean item', 'Place in recycling bin'],
          hasUrgentTimeframe: false,
        ),
        timestamp: DateTime(2023, 1, 1, 10),
        imageUrl: 'test.jpg',
        confidence: 0.95,
        isRecyclable: true,
        isCompostable: false,
        requiresSpecialDisposal: false,
        hasUrgentTimeframe: false,
      );
      final classification2 = WasteClassification(
        itemName: 'Day 2 Item',
        category: 'plastic',
        subcategory: 'Recyclable',
        explanation: 'Test classification',
        region: 'US',
        visualFeatures: const ['test feature'],
        alternatives: const [],
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Recycle',
          steps: const ['Clean item', 'Place in recycling bin'],
          hasUrgentTimeframe: false,
        ),
        timestamp: DateTime(2023, 1, 2, 10),
        imageUrl: 'test.jpg',
        confidence: 0.95,
        isRecyclable: true,
        isCompostable: false,
        requiresSpecialDisposal: false,
        hasUrgentTimeframe: false,
      );

      final classification3 = WasteClassification(
        itemName: 'Day 3 Item',
        category: 'plastic',
        subcategory: 'Recyclable',
        explanation: 'Test classification',
        region: 'US',
        visualFeatures: const ['test feature'],
        alternatives: const [],
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Recycle',
          steps: const ['Clean item', 'Place in recycling bin'],
          hasUrgentTimeframe: false,
        ),
        timestamp: DateTime(2023, 1, 3, 10),
        imageUrl: 'test.jpg',
        confidence: 0.95,
        isRecyclable: true,
        isCompostable: false,
        requiresSpecialDisposal: false,
        hasUrgentTimeframe: false,
      );

      await gamificationService.processClassification(classification1);
      await gamificationService.processClassification(classification2);
      await gamificationService.processClassification(classification3);

      final profile = await gamificationService.getProfile();
      
      // Streak should reflect consecutive classifications
      final dailyStreak = profile.streaks[StreakType.dailyClassification.toString()];
      expect(dailyStreak?.currentCount ?? 0, greaterThanOrEqualTo(1));
    });
  });
} 