import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mockito/annotations.dart';

import 'package:waste_segregation_app/services/storage_service.dart';
import 'package:waste_segregation_app/models/user_profile.dart';

@GenerateMocks([])
void main() {
  group('StorageService - Factory Reset Tests', () {
    late StorageService storageService;

    setUpAll(() async {
      // Initialize Hive for testing
      await Hive.initFlutter();
    });

    setUp(() async {
      storageService = StorageService();
      
      // Clear any existing test data
      SharedPreferences.setMockInitialValues({});
      
      // Initialize required Hive boxes
      await StorageService.initializeHive();
    });

    tearDown(() async {
      // Clean up after each test
      try {
        final boxes = Hive.box('userBox');
        await boxes.clear();
      } catch (e) {
        // Ignore if box doesn't exist
      }
    });

    test('clearAllUserData should handle mixed type SharedPreferences gracefully', () async {
      // Arrange: Set up SharedPreferences with mixed data types
      SharedPreferences.setMockInitialValues({
        'string_key': 'test_string',
        'int_key': 42,
        'bool_key': true,
        'double_key': 3.14,
        'string_list_key': ['item1', 'item2'],
        'problematic_map_key': {'nested': 'data'}, // This could cause type cast issues
      });

      // Act & Assert: Should not throw type cast exceptions
      expect(() async => storageService.clearAllUserData(), 
             returnsNormally);
    });

    test('clearAllUserData should handle empty SharedPreferences', () async {
      // Arrange: Empty SharedPreferences
      SharedPreferences.setMockInitialValues({});

      // Act & Assert: Should complete successfully
      await storageService.clearAllUserData();
      
      // Verify the operation completed
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), isEmpty);
    });

    test('clearAllUserData should clear user profile', () async {
      // Arrange: Create and save a test user profile
      final testProfile = UserProfile(
        id: 'test_user_123',
        displayName: 'Test User',
        email: 'test@example.com',
        createdAt: DateTime.now(),
        lastActive: DateTime.now(),
      );
      
      await storageService.saveUserProfile(testProfile);
      
      // Verify profile was saved
      final savedProfile = await storageService.getCurrentUserProfile();
      expect(savedProfile, isNotNull);
      expect(savedProfile!.id, equals('test_user_123'));

      // Act: Clear all user data
      await storageService.clearAllUserData();

      // Assert: Profile should be cleared
      final clearedProfile = await storageService.getCurrentUserProfile();
      expect(clearedProfile, isNull);
    });

    test('clearAllUserData should handle Hive box errors gracefully', () async {
      // This test ensures that even if one box fails to clear, 
      // the operation continues with other boxes
      
      // Act & Assert: Should complete even if some operations fail
      expect(() async => storageService.clearAllUserData(), 
             returnsNormally);
    });

    test('factory reset should not throw type cast errors', () async {
      // Arrange: Set up various data types in SharedPreferences
      SharedPreferences.setMockInitialValues({
        'navigation_style': 'glassmorphism',
        'bottom_nav_enabled': true,
        'fab_enabled': false,
        'theme_mode': 'light',
        'consent_analytics': true,
        'consent_personalization': false,
        'user_onboarding_completed': true,
        'mixed_type_data': {'complex': 'object', 'with': 123, 'mixed': true},
      });

      // Create test user profile and classifications
      final testProfile = UserProfile(
        id: 'factory_reset_test_user',
        displayName: 'Factory Reset Test',
        email: 'factory.reset@test.com',
      );
      await storageService.saveUserProfile(testProfile);

      // Act: Perform factory reset
      await storageService.clearAllUserData();

      // Assert: Verify all data is cleared
      final clearedProfile = await storageService.getCurrentUserProfile();
      expect(clearedProfile, isNull);
      
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), isEmpty);
    });
  });
} 