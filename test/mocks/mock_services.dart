import 'package:mockito/mockito.dart';
import 'package:waste_segregation_app/services/ai_service.dart';
import 'package:waste_segregation_app/services/storage_service.dart';
import 'package:waste_segregation_app/services/gamification_service.dart';
import 'package:waste_segregation_app/services/premium_service.dart';
import 'package:waste_segregation_app/services/analytics_service.dart';
import 'package:waste_segregation_app/services/community_service.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/models/user_profile.dart';
import 'package:waste_segregation_app/models/achievement.dart';
import 'package:waste_segregation_app/models/challenge.dart';
import 'package:waste_segregation_app/models/community_post.dart';
import 'package:waste_segregation_app/models/educational_content.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

// Mock AI Service
class MockAiService extends Mock implements AiService {
  @override
  Future<WasteClassification> analyzeImage(XFile imageFile) async {
    return WasteClassification(
      id: 'mock-id',
      itemName: 'Mock Item',
      category: 'Mock Category',
      confidence: 0.95,
      timestamp: DateTime.now(),
      imageRelativePath: 'images/mock_image.jpg',
      userId: 'mock-user',
    );
  }

  @override
  Future<WasteClassification> analyzeImageFromBytes(Uint8List imageBytes, String fileName) async {
    return WasteClassification(
      id: 'mock-id',
      itemName: 'Mock Item',
      category: 'Mock Category',
      confidence: 0.95,
      timestamp: DateTime.now(),
      imageRelativePath: 'images/$fileName',
      userId: 'mock-user',
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
  Future<List<WasteClassification>> getAllClassifications() async {
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
  Future<UserProfile?> getProfile() async {
    return UserProfile(
      userId: 'mock-user',
      totalPoints: 100,
      level: 1,
      achievements: [],
      challenges: [],
      streakCount: 1,
      lastActivityDate: DateTime.now(),
    );
  }

  @override
  Future<void> processClassification(WasteClassification classification) async {
    // Mock implementation
  }

  @override
  Future<void> addPoints(String reason, {int? customPoints}) async {
    // Mock implementation
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