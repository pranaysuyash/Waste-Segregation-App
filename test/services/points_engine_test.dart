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
      gamificationProfile: GamificationProfile(
        userId: 'test_user',
        streaks: {},
        points: const UserPoints(),
        achievements: [],
        discoveredItemIds: {},
        unlockedHiddenContentIds: {},
      ),
    );
  }
  
  @override
  Future<void> saveUserProfile(UserProfile profile) async {
    _userProfile = profile;
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
  group('PointsEngine Singleton & Race Condition Tests', () {
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

    test('should create singleton instance', () {
      final engine1 = PointsEngine.getInstance(testStorageService, testCloudStorageService);
      final engine2 = PointsEngine.getInstance(testStorageService, testCloudStorageService);
      
      expect(engine1, same(engine2));
      expect(engine1, isNotNull);
    });

    test('should initialize without errors', () async {
      final pointsEngine = PointsEngine.getInstance(testStorageService, testCloudStorageService);
      
      await pointsEngine.initialize();
      
      expect(pointsEngine.currentPoints, equals(0));
      expect(pointsEngine.currentLevel, equals(1));
    });

    test('should handle concurrent point operations without race conditions', () async {
      final pointsEngine = PointsEngine.getInstance(testStorageService, testCloudStorageService);
      await pointsEngine.initialize();
      
      // Create multiple concurrent point addition operations
      final futures = List.generate(5, (index) => 
        pointsEngine.addPoints('classification', customPoints: 10)
      );
      
      // Wait for all operations to complete
      final results = await Future.wait(futures);
      
      // Verify all operations completed successfully
      expect(results.length, equals(5));
      
      // Verify final points total is correct (5 operations × 10 points = 50)
      expect(pointsEngine.currentPoints, equals(50));
      
      // Verify all results have the correct final total
      expect(results.last.total, equals(50));
    });

    test('should handle multiple services using same singleton', () async {
      // Simulate GamificationService and PointsManager both using the same instance
      final engine1 = PointsEngine.getInstance(testStorageService, testCloudStorageService);
      final engine2 = PointsEngine.getInstance(testStorageService, testCloudStorageService);
      
      await engine1.initialize();
      
      // Add points through first reference
      await engine1.addPoints('classification', customPoints: 10);
      
      // Verify second reference sees the same data
      expect(engine2.currentPoints, equals(10));
      expect(engine1.currentPoints, equals(engine2.currentPoints));
    });

    test('should maintain consistency across async operations', () async {
      final pointsEngine = PointsEngine.getInstance(testStorageService, testCloudStorageService);
      await pointsEngine.initialize();
      
      // Start multiple async operations at the same time
      final operation1 = pointsEngine.addPoints('classification', customPoints: 10);
      final operation2 = pointsEngine.addPoints('daily_streak', customPoints: 5);
      final operation3 = pointsEngine.addPoints('quiz_completed', customPoints: 15);
      
      final results = await Future.wait([operation1, operation2, operation3]);
      
      // Final result should be sum of all operations
      expect(pointsEngine.currentPoints, equals(30));
      
      // Last operation should show the final total
      expect(results.last.total, equals(30));
    });
  });
} 