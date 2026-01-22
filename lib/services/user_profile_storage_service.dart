import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_profile.dart';
import '../utils/constants.dart';
import '../utils/waste_app_logger.dart';
import 'dart:convert';

/// OPTIMIZATION: Focused service for user profile storage operations
/// 
/// Extracted from the 1300+ line StorageService god object.
/// Handles only user profile-related persistence operations.
/// 
/// Benefits:
/// - Single Responsibility Principle
/// - Easier to test in isolation
/// - Clear user profile management API
/// - Better maintainability
class UserProfileStorageService {
  static const String _userProfileBoxName = StorageKeys.userProfileBox;
  static const String _settingsBoxName = StorageKeys.settingsBox;

  /// Save user profile
  Future<void> saveUserProfile(UserProfile userProfile) async {
    try {
      final box = await Hive.openBox(_userProfileBoxName);
      await box.put(userProfile.id, jsonEncode(userProfile.toJson()));
      
      WasteAppLogger.info(
        'User profile saved',
        context: {
          'userId': userProfile.id,
          'displayName': userProfile.displayName,
        },
      );
    } catch (e, s) {
      WasteAppLogger.severe('Error saving user profile', e, s);
      rethrow;
    }
  }

  /// Get current user profile
  Future<UserProfile?> getCurrentUserProfile() async {
    try {
      final box = await Hive.openBox(_userProfileBoxName);
      
      if (box.isEmpty) {
        return null;
      }

      // Get the first (and should be only) user profile
      final key = box.keys.first;
      final data = box.get(key);

      if (data == null) {
        return null;
      }

      if (data is String) {
        final json = jsonDecode(data);
        return UserProfile.fromJson(json);
      } else if (data is Map) {
        return UserProfile.fromJson(
          data is Map<String, dynamic> ? data : Map<String, dynamic>.from(data)
        );
      }

      return null;
    } catch (e, s) {
      WasteAppLogger.severe('Error getting current user profile', e, s);
      return null;
    }
  }

  /// Get user profile by ID
  Future<UserProfile?> getUserProfileById(String userId) async {
    try {
      final box = await Hive.openBox(_userProfileBoxName);
      final data = box.get(userId);

      if (data == null) {
        return null;
      }

      if (data is String) {
        final json = jsonDecode(data);
        return UserProfile.fromJson(json);
      } else if (data is Map) {
        return UserProfile.fromJson(
          data is Map<String, dynamic> ? data : Map<String, dynamic>.from(data)
        );
      }

      return null;
    } catch (e, s) {
      WasteAppLogger.severe('Error getting user profile by ID', e, s, {'userId': userId});
      return null;
    }
  }

  /// Delete user profile
  Future<void> deleteUserProfile(String userId) async {
    try {
      final box = await Hive.openBox(_userProfileBoxName);
      await box.delete(userId);
      
      WasteAppLogger.info('User profile deleted', context: {'userId': userId});
    } catch (e, s) {
      WasteAppLogger.severe('Error deleting user profile', e, s, {'userId': userId});
      rethrow;
    }
  }

  /// Clear all user profiles
  Future<void> clearAllUserProfiles() async {
    try {
      final box = await Hive.openBox(_userProfileBoxName);
      await box.clear();
      
      WasteAppLogger.info('All user profiles cleared');
    } catch (e, s) {
      WasteAppLogger.severe('Error clearing user profiles', e, s);
      rethrow;
    }
  }

  /// Save user settings
  Future<void> saveSettings({
    bool? googleSyncEnabled,
    bool? notifications,
    bool? gamificationNotifications,
    String? language,
    Map<String, dynamic>? additionalSettings,
  }) async {
    try {
      final box = await Hive.openBox(_settingsBoxName);
      final settings = <String, dynamic>{};

      if (googleSyncEnabled != null) {
        settings['googleSyncEnabled'] = googleSyncEnabled;
      }
      if (notifications != null) {
        settings['notifications'] = notifications;
      }
      if (gamificationNotifications != null) {
        settings['gamificationNotifications'] = gamificationNotifications;
      }
      if (language != null) {
        settings['language'] = language;
      }
      if (additionalSettings != null) {
        settings.addAll(additionalSettings);
      }

      await box.putAll(settings);
      
      WasteAppLogger.info(
        'User settings saved',
        context: {'settings_count': settings.length},
      );
    } catch (e, s) {
      WasteAppLogger.severe('Error saving settings', e, s);
      rethrow;
    }
  }

  /// Get user settings
  Future<Map<String, dynamic>> getSettings() async {
    try {
      final box = await Hive.openBox(_settingsBoxName);
      
      // Return default settings if empty
      if (box.isEmpty) {
        return {
          'googleSyncEnabled': false,
          'notifications': true,
          'gamificationNotifications': true,
          'language': 'en',
        };
      }

      // Convert box to Map
      final settings = <String, dynamic>{};
      for (final key in box.keys) {
        settings[key.toString()] = box.get(key);
      }

      return settings;
    } catch (e, s) {
      WasteAppLogger.severe('Error getting settings', e, s);
      return {
        'googleSyncEnabled': false,
        'notifications': true,
        'gamificationNotifications': true,
        'language': 'en',
      };
    }
  }

  /// Get specific setting value
  Future<T?> getSetting<T>(String key, {T? defaultValue}) async {
    try {
      final box = await Hive.openBox(_settingsBoxName);
      final value = box.get(key, defaultValue: defaultValue);
      
      return value as T?;
    } catch (e, s) {
      WasteAppLogger.severe('Error getting setting', e, s, {'key': key});
      return defaultValue;
    }
  }

  /// Clear all settings
  Future<void> clearSettings() async {
    try {
      final box = await Hive.openBox(_settingsBoxName);
      await box.clear();
      
      WasteAppLogger.info('All settings cleared');
    } catch (e, s) {
      WasteAppLogger.severe('Error clearing settings', e, s);
      rethrow;
    }
  }

  /// Check if Google sync is enabled
  Future<bool> isGoogleSyncEnabled() async {
    final settings = await getSettings();
    return settings['googleSyncEnabled'] as bool? ?? false;
  }

  /// Update user profile with new data
  Future<void> updateUserProfile(
    String userId, 
    Map<String, dynamic> updates,
  ) async {
    try {
      final currentProfile = await getUserProfileById(userId);
      
      if (currentProfile == null) {
        WasteAppLogger.warning('Cannot update non-existent user profile', null, null, {
          'userId': userId,
        });
        return;
      }

      // Merge updates with current data
      final updatedData = currentProfile.toJson()..addAll(updates);
      final updatedProfile = UserProfile.fromJson(updatedData);
      
      await saveUserProfile(updatedProfile);
    } catch (e, s) {
      WasteAppLogger.severe('Error updating user profile', e, s, {'userId': userId});
      rethrow;
    }
  }
}
