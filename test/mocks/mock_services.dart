import 'package:mockito/mockito.dart';
import 'package:waste_segregation_app/services/ai_service.dart';
import 'package:waste_segregation_app/services/storage_service.dart';
import 'package:waste_segregation_app/services/gamification_service.dart';
import 'package:waste_segregation_app/services/premium_service.dart';
import 'package:waste_segregation_app/services/analytics_service.dart';
import 'package:waste_segregation_app/services/community_service.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/models/user_profile.dart';
import 'package:waste_segregation_app/models/gamification.dart';
import 'package:waste_segregation_app/models/community_feed.dart';
import 'package:waste_segregation_app/models/educational_content.dart';
import 'package:waste_segregation_app/models/recycling_code.dart';
import 'dart:io';
import 'dart:typed_data';

// Mock AI Service
class MockAiService extends Mock implements AiService {
  @override
  Future<WasteClassification> analyzeImage(
    File imageFile, {
    int retryCount = 0,
    int maxRetries = 3,
    String? region,
    String? instructionsLang,
    String? classificationId,
  }) async {
    return WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
      id: 'mock-id',
      itemName: 'Mock Item',
      confidence: 0.95,
            region: 'Test Region',
            visualFeatures: ['test feature'],
            alternatives: [],
      timestamp: DateTime.now(),
      imageRelativePath: 'images/mock_image.jpg',
      userId: 'mock-user',
      explanation: 'Mock explanation',
      disposalInstructions: DisposalInstructions(
        primaryMethod: 'Mock disposal method',
        steps: ['Mock step 1', 'Mock step 2'],
        hasUrgentTimeframe: false,
      ),
    );
  }

  @override
  Future<WasteClassification> analyzeWebImage(
    Uint8List imageBytes, 
    String imageName, {
    int retryCount = 0,
    int maxRetries = 3,
    String? region,
    String? instructionsLang,
    String? classificationId,
  }) async {
    return WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
      id: 'mock-id',
      itemName: 'Mock Item',
      confidence: 0.95,
            region: 'Test Region',
            visualFeatures: ['test feature'],
            alternatives: [],
      timestamp: DateTime.now(),
      imageRelativePath: 'images/$imageName',
      userId: 'mock-user',
      explanation: 'Mock explanation',
      disposalInstructions: DisposalInstructions(
        primaryMethod: 'Mock disposal method',
        steps: ['Mock step 1', 'Mock step 2'],
        hasUrgentTimeframe: false,
      ),
    );
  }
}

// Mock Storage Service
class MockStorageService extends Mock implements StorageService {
  @override
  Future<void> saveClassification(WasteClassification classification) async {
    // Mock implementation
  }

  @override
  Future<List<WasteClassification>> getAllClassifications({Map<String, dynamic>? filterOptions}) async {
    return [];
  }

  @override
  Future<void> deleteClassification(String id) async {
    // Mock implementation
  }

  @override
  Future<void> initializeHive() async {
    // Mock implementation
  }
}

// Mock Gamification Service
class MockGamificationService extends Mock implements GamificationService {
  @override
  Future<GamificationProfile> getProfile({bool forceRefresh = false}) async {
    return GamificationProfile(
      userId: 'mock-user',
      points: UserPoints(total: 100, available: 100),
      level: 1,
      achievements: [],
      challenges: [],
      streakCount: 1,
      lastActivityDate: DateTime.now(),
    );
  }

  @override
  Future<List<Challenge>> processClassification(WasteClassification classification) async {
    return [];
  }

  @override
  Future<UserPoints> addPoints(String action, {String? category, int? customPoints}) async {
    return UserPoints(total: 110, available: 110);
  }

  @override
  Future<List<Achievement>> getAchievements() async {
    return [];
  }

  @override
  Future<List<Challenge>> getChallenges() async {
    return [];
  }
}

// Mock Premium Service
class MockPremiumService extends Mock implements PremiumService {
  @override
  Future<bool> isPremium() async {
    return false;
  }

  @override
  Future<void> purchasePremium() async {
    // Mock implementation
  }

  @override
  Future<void> restorePurchases() async {
    // Mock implementation
  }
}

// Mock Analytics Service
class MockAnalyticsService extends Mock implements AnalyticsService {
  @override
  Future<void> logEvent(String eventName, {Map<String, dynamic>? parameters}) async {
    // Mock implementation
  }

  @override
  Future<void> setUserProperty(String name, String value) async {
    // Mock implementation
  }

  @override
  Future<void> setUserId(String userId) async {
    // Mock implementation
  }
}

// Mock Community Service
class MockCommunityService extends Mock implements CommunityService {
  @override
  Future<List<CommunityPost>> getPosts() async {
    return [];
  }

  @override
  Future<void> createPost(CommunityPost post) async {
    // Mock implementation
  }

  @override
  Future<void> likePost(String postId) async {
    // Mock implementation
  }

  @override
  Future<void> commentOnPost(String postId, String comment) async {
    // Mock implementation
  }
} 