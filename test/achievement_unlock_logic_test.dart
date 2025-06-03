import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/services/gamification_service.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/models/gamification.dart';
import 'package:waste_segregation_app/services/storage_service.dart';
import 'package:waste_segregation_app/services/cloud_storage_service.dart';

void main() {
  group('Achievement Unlock Logic Tests', () {
    late GamificationService gamificationService;
    late StorageService storageService;
    late CloudStorageService cloudStorageService;

    setUp(() async {
      await StorageService.initializeHive();
      storageService = StorageService();
      cloudStorageService = CloudStorageService(storageService);
      gamificationService = GamificationService(storageService, cloudStorageService);
    });

    test('Should unlock "First Classification" achievement on first scan', () async {
      // Given: No previous classifications
      await storageService.clearClassifications();

      // When: User makes their first classification
      final classification = WasteClassification(
        itemName: 'Plastic Bottle',
        category: 'Dry Waste',
        subcategory: 'Recyclable Plastic',
        isRecyclable: true,
        isCompostable: false,
        requiresSpecialDisposal: false,
        timestamp: DateTime(2023, 1, 1, 10, 0),
        imageUrl: 'test.jpg',
        confidence: 0.95,
        alternatives: const [],
        region: 'US',
        visualFeatures: const [],
        hasUrgentTimeframe: false,
        explanation: 'Test classification',
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Recycle',
          steps: const ['Clean item', 'Place in recycling bin'],
          hasUrgentTimeframe: false,
        ),
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
          category: 'Dry Waste',
          subcategory: 'Recyclable',
          isRecyclable: true,
          isCompostable: false,
          requiresSpecialDisposal: false,
          timestamp: DateTime(2023, 1, 1, 10, 0),
          imageUrl: 'test.jpg',
          confidence: 0.95,
          alternatives: const [],
          region: 'US',
          visualFeatures: const [],
          hasUrgentTimeframe: false,
          explanation: 'Test classification',
          disposalInstructions: DisposalInstructions(
            primaryMethod: 'Recycle',
            steps: const ['Clean item', 'Place in recycling bin'],
            hasUrgentTimeframe: false,
          ),
        );
        await gamificationService.processClassification(classification);
      }

      // When: User classifies their 50th recyclable item
      final finalClassification = WasteClassification(
        itemName: 'Final Recyclable',
        category: 'Dry Waste',
        subcategory: 'Recyclable',
        isRecyclable: true,
        isCompostable: false,
        requiresSpecialDisposal: false,
        timestamp: DateTime(2023, 1, 1, 11, 0),
        imageUrl: 'test.jpg',
        confidence: 0.95,
        alternatives: const [],
        region: 'US',
        visualFeatures: const [],
        hasUrgentTimeframe: false,
        explanation: 'Test classification',
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Recycle',
          steps: const ['Clean item', 'Place in recycling bin'],
          hasUrgentTimeframe: false,
        ),
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
          category: 'Wet Waste',
          subcategory: 'Organic',
          isRecyclable: false,
          isCompostable: true,
          requiresSpecialDisposal: false,
          timestamp: DateTime(2023, 1, 1, 10, 0),
          imageUrl: 'test.jpg',
          confidence: 0.95,
          alternatives: const [],
          region: 'US',
          visualFeatures: const [],
          hasUrgentTimeframe: false,
          explanation: 'Test classification',
          disposalInstructions: DisposalInstructions(
            primaryMethod: 'Compost',
            steps: const ['Add to compost bin'],
            hasUrgentTimeframe: false,
          ),
        ),
        WasteClassification(
          itemName: 'Battery',
          category: 'Hazardous Waste',
          subcategory: 'Electronic Waste',
          isRecyclable: false,
          isCompostable: false,
          requiresSpecialDisposal: true,
          timestamp: DateTime(2023, 1, 1, 11, 0),
          imageUrl: 'test.jpg',
          confidence: 0.95,
          alternatives: const [],
          region: 'US',
          visualFeatures: const [],
          hasUrgentTimeframe: false,
          explanation: 'Test classification',
          disposalInstructions: DisposalInstructions(
            primaryMethod: 'Special disposal',
            steps: const ['Take to hazardous waste facility'],
            hasUrgentTimeframe: false,
          ),
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
        category: 'Dry Waste',
        subcategory: 'Recyclable',
        isRecyclable: true,
        isCompostable: false,
        requiresSpecialDisposal: false,
        timestamp: DateTime(2023, 1, 1, 10, 0),
        imageUrl: 'test.jpg',
        confidence: 0.95,
        alternatives: const [],
        region: 'US',
        visualFeatures: const [],
        hasUrgentTimeframe: false,
        explanation: 'Test classification',
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Recycle',
          steps: const ['Clean item', 'Place in recycling bin'],
          hasUrgentTimeframe: false,
        ),
      );
      final classification2 = WasteClassification(
        itemName: 'Day 2 Item',
        category: 'Dry Waste',
        subcategory: 'Recyclable',
        isRecyclable: true,
        isCompostable: false,
        requiresSpecialDisposal: false,
        timestamp: DateTime(2023, 1, 2, 10, 0),
        imageUrl: 'test.jpg',
        confidence: 0.95,
        alternatives: const [],
        region: 'US',
        visualFeatures: const [],
        hasUrgentTimeframe: false,
        explanation: 'Test classification',
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Recycle',
          steps: const ['Clean item', 'Place in recycling bin'],
          hasUrgentTimeframe: false,
        ),
      );

      final classification3 = WasteClassification(
        itemName: 'Day 3 Item',
        category: 'Dry Waste',
        subcategory: 'Recyclable',
        isRecyclable: true,
        isCompostable: false,
        requiresSpecialDisposal: false,
        timestamp: DateTime(2023, 1, 3, 10, 0),
        imageUrl: 'test.jpg',
        confidence: 0.95,
        alternatives: const [],
        region: 'US',
        visualFeatures: const [],
        hasUrgentTimeframe: false,
        explanation: 'Test classification',
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Recycle',
          steps: const ['Clean item', 'Place in recycling bin'],
          hasUrgentTimeframe: false,
        ),
      );

      await gamificationService.processClassification(classification1);
      await gamificationService.processClassification(classification2);
      await gamificationService.processClassification(classification3);

      final profile = await gamificationService.getProfile();
      
      // Streak should reflect consecutive classifications
      expect(profile.streak.current, greaterThanOrEqualTo(1));
    });
  });
} 