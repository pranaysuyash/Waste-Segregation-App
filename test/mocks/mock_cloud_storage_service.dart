import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/models/user_profile.dart';
import 'package:waste_segregation_app/services/storage_service.dart';

/// Mock CloudStorageService for testing that doesn't require Firebase
class MockCloudStorageService {
  MockCloudStorageService(this._localStorageService);
  final StorageService _localStorageService;

  /// Mock implementation - just saves locally
  Future<void> saveUserProfileToFirestore(UserProfile userProfile) async {
    // Mock: Just return success
    return;
  }

  /// Mock implementation - just saves locally
  Future<void> saveClassificationWithSync(
    WasteClassification classification,
    bool isGoogleSyncEnabled,
  ) async {
    // Always save locally (same as real implementation)
    await _localStorageService.saveClassification(classification);
    
    // Mock: Skip cloud sync
    return;
  }

  /// Mock implementation
  Future<List<WasteClassification>> getAllClassificationsWithCloudSync(
    bool isGoogleSyncEnabled,
  ) async {
    // Mock: Just return empty list
    return [];
  }

  /// Mock implementation
  Future<void> syncAllLocalToCloud() async {
    // Mock: Do nothing
    return;
  }

  /// Mock implementation
  Future<bool> isCloudSyncAvailable() async {
    // Mock: Always return false (offline mode)
    return false;
  }

  /// Mock implementation
  Future<Map<String, dynamic>> getCloudSyncStatus() async {
    // Mock: Return offline status
    return {
      'isConnected': false,
      'lastSync': null,
      'pendingUploads': 0,
      'cloudClassificationCount': 0,
    };
  }

  /// Mock implementation
  Future<void> deleteAllCloudData() async {
    // Mock: Do nothing
    return;
  }

  /// Mock implementation
  Future<List<UserProfile>> getLeaderboard({int limit = 100}) async {
    // Mock: Return empty leaderboard
    return [];
  }

  /// Mock implementation
  Future<void> deleteClassificationFromCloud(String classificationId) async {
    // Mock: Do nothing
    return;
  }
} 