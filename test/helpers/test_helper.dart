import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart' as provider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:waste_segregation_app/services/storage_service.dart';
import 'package:waste_segregation_app/services/cloud_storage_service.dart';
import 'package:waste_segregation_app/services/gamification_service.dart';
import 'package:waste_segregation_app/services/community_service.dart';
import 'package:waste_segregation_app/models/gamification.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/models/user_profile.dart';
import 'package:waste_segregation_app/models/filter_options.dart';

/// Mock Storage Service for testing
class MockStorageService extends StorageService {
  @override
  Future<List<WasteClassification>> getAllClassifications({FilterOptions? filterOptions}) async {
    return [];
  }

  @override
  Future<UserProfile?> getCurrentUserProfile() async {
    return UserProfile(
      id: 'test-user',
      email: 'test@example.com',
      displayName: 'Test User',
      gamificationProfile: GamificationProfile(
        userId: 'test-user',
        points: const UserPoints(total: 100, level: 2),
        achievements: [],
        streaks: {},
        discoveredItemIds: {},
        unlockedHiddenContentIds: {},
      ),
    );
  }
}

/// Mock Cloud Storage Service for testing that extends CloudStorageService but avoids Firebase
class MockCloudStorageService extends CloudStorageService {
  MockCloudStorageService._() : super(MockStorageService());

  factory MockCloudStorageService() {
    return MockCloudStorageService._();
  }

  @override
  Future<void> saveUserProfileToFirestore(UserProfile profile) async {
    // Mock implementation - do nothing
  }

  @override
  Future<void> saveClassificationWithSync(
    WasteClassification classification,
    bool isGoogleSyncEnabled, {
    bool processGamification = true,
  }) async {
    // Mock implementation - just save locally
    await localStorageService.saveClassification(classification);
  }
}

/// Mock Gamification Service for testing
class MockGamificationService extends GamificationService {
  MockGamificationService() : super(MockStorageService(), MockCloudStorageService());

  @override
  Future<GamificationProfile> getProfile({bool forceRefresh = false}) async {
    return GamificationProfile(
      userId: 'test-user',
      points: const UserPoints(total: 100, level: 2),
      achievements: [],
      streaks: {},
      discoveredItemIds: {},
      unlockedHiddenContentIds: {},
    );
  }
}

/// Mock Community Service for testing
class MockCommunityService extends CommunityService {
  @override
  Future<void> initCommunity() async {
    // Mock implementation - do nothing
  }
}

/// Setup Firebase for testing
Future<void> setupFirebaseForTesting() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with test configuration
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'test-api-key',
        appId: 'test-app-id',
        messagingSenderId: 'test-sender-id',
        projectId: 'test-project-id',
      ),
    );
  } catch (e) {
    // Firebase already initialized
  }
}

/// Create a test widget with minimal providers for golden tests
Widget createTestWidget({
  required Widget child,
  ThemeData? theme,
}) {
  return MaterialApp(
    theme: theme ?? ThemeData.light(),
    home: child,
    debugShowCheckedModeBanner: false,
  );
}

/// Create a test widget with Riverpod providers for golden tests
Widget createRiverpodTestWidget({
  required Widget child,
  ThemeData? theme,
  List<Override>? overrides,
}) {
  final defaultOverrides = [
    // Mock the providers that depend on Firebase
    storageServiceProvider.overrideWithValue(MockStorageService()),
    cloudStorageServiceProvider.overrideWithValue(MockCloudStorageService()),
    gamificationServiceProvider.overrideWithValue(MockGamificationService()),
    communityServiceProvider.overrideWithValue(MockCommunityService()),
  ];

  return ProviderScope(
    overrides: [...defaultOverrides, ...(overrides ?? [])],
    child: MaterialApp(
      theme: theme ?? ThemeData.light(),
      home: child,
      debugShowCheckedModeBanner: false,
    ),
  );
}

// Provider definitions for testing
final storageServiceProvider = Provider<StorageService>((ref) => MockStorageService());
final cloudStorageServiceProvider = Provider<CloudStorageService>((ref) => MockCloudStorageService());
final gamificationServiceProvider = Provider<GamificationService>((ref) => MockGamificationService());
final communityServiceProvider = Provider<CommunityService>((ref) => MockCommunityService());
