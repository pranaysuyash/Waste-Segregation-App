import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/models/user_profile.dart';
import 'package:waste_segregation_app/services/storage_service.dart';
import 'package:waste_segregation_app/services/cloud_storage_service.dart';

/// Mock CloudStorageService for testing that doesn't require Firebase
class MockCloudStorageService extends CloudStorageService {
  MockCloudStorageService(StorageService localStorageService) : super(localStorageService);

  @override
  Future<void> saveUserProfileToFirestore(UserProfile userProfile) async {
    // Mock: Just return success
    return;
  }

  @override
  Future<void> saveClassificationWithSync(
    WasteClassification classification,
    bool isGoogleSyncEnabled, {
    bool processGamification = true,
  }) async {
    // Always save locally (same as real implementation)
    await localStorageService.saveClassification(classification);
    // Mock: Skip cloud sync
    return;
  }

  @override
  Future<List<WasteClassification>> getAllClassificationsWithCloudSync(
    bool isGoogleSyncEnabled,
  ) async {
    // Mock: Just return empty list
    return [];
  }

  @override
  Future<void> syncAllLocalToCloud() async {
    // Mock: Do nothing
    return;
  }

  @override
  Future<bool> isCloudSyncAvailable() async {
    // Mock: Always return false (offline mode)
    return false;
  }

  @override
  Future<Map<String, dynamic>> getCloudSyncStatus() async {
    // Mock: Return offline status
    return {
      'isConnected': false,
      'lastSync': null,
      'pendingUploads': 0,
      'cloudClassificationCount': 0,
    };
  }

  @override
  Future<void> deleteAllCloudData() async {
    // Mock: Do nothing
    return;
  }

  @override
  Future<List<UserProfile>> getLeaderboard({int limit = 100}) async {
    // Mock: Return empty leaderboard
    return [];
  }

  @override
  Future<void> deleteClassificationFromCloud(String classificationId) async {
    // Mock: Do nothing
    return;
  }
} 