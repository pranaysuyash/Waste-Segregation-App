import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_profile.dart';
import '../utils/constants.dart';
import '../utils/waste_app_logger.dart';
import 'dart:convert';

/// ⚠️ CONTAINED EXTRACTION — see StorageService for primary write path.
///
/// This service was extracted from StorageService during Phase 4 architecture
/// work. It is NOT wired into the app's core profile write path.
///
/// Format mismatch:
///   - StorageService writes via Hive TypeAdapter (binary UserProfile)
///   - This service writes via jsonEncode(profile.toJson())
///   - Both write to the same Hive box (StorageKeys.userBox)
///   - Naive delegation would create dual-format writes in the same box.
///
/// Key mismatch (CRITICAL):
///   - StorageService stores current profile under StorageKeys.userProfileKey
///     (the constant string 'userProfile')
///   - This service stores under userProfile.id (a UUID)
///   - These are NOT equivalent: StorageService.getCurrentUserProfile()
///     looks for the constant key and would NOT find a record written here.
///   - This means a naive wire would silently "log out" the current user.
///
/// Safe usage:
///   - Read/helper methods (`getSetting<T>`, isGoogleSyncEnabled, CSV export)
///     are format-safe because both services handle multi-format reads.
///   - Do NOT call saveUserProfile / getCurrentUserProfile from app code —
///     use StorageService which is the canonical write path.
///
/// Roadmap:
///   A true fix requires unifying on one serialization format (TypeAdapter)
///   AND resolving the keying difference. That is a migration, not a
///   refactor, and should not be attempted as a quick fix.
///
/// See also: StorageService.profileStorage
class UserProfileStorageService {
  static const String _userProfileBoxName = StorageKeys.userBox;
  static const String _settingsBoxName = StorageKeys.settingsBox;

  /// Save user profile
  @Deprecated(
    'Do not use for primary app persistence. StorageService.saveUserProfile '
    'is the source of truth. Key mismatch: StorageService writes under '
    'StorageKeys.userProfileKey (\'userProfile\'); this method writes under '
    'userProfile.id (UUID). Using this for current-user persistence would '
    'silently log the user out because getCurrentUserProfile() looks for '
    'the constant key.',
  )
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
      WasteAppLogger.severe('Error saving user profile',
          error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Get current user profile
  @Deprecated(
    'Key mismatch: StorageService reads from StorageKeys.userProfileKey; '
    'this method reads the first entry in the box (which may be stored under '
    'userProfile.id). Use StorageService.getCurrentUserProfile instead.',
  )
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
        return UserProfile.fromJson(data is Map<String, dynamic>
            ? data
            : Map<String, dynamic>.from(data));
      }

      return null;
    } catch (e, s) {
      WasteAppLogger.severe('Error getting current user profile',
          error: e, stackTrace: s);
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
        return UserProfile.fromJson(data is Map<String, dynamic>
            ? data
            : Map<String, dynamic>.from(data));
      }

      return null;
    } catch (e, s) {
      WasteAppLogger.severe('Error getting user profile by ID',
          error: e, stackTrace: s, context: {'userId': userId});
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
      WasteAppLogger.severe('Error deleting user profile',
          error: e, stackTrace: s, context: {'userId': userId});
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
      WasteAppLogger.severe('Error clearing user profiles',
          error: e, stackTrace: s);
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
      WasteAppLogger.severe('Error saving settings', error: e, stackTrace: s);
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
      WasteAppLogger.severe('Error getting settings', error: e, stackTrace: s);
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
      WasteAppLogger.severe('Error getting setting',
          error: e, stackTrace: s, context: {'key': key});
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
      WasteAppLogger.severe('Error clearing settings', error: e, stackTrace: s);
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
        WasteAppLogger.warning('Cannot update non-existent user profile',
            context: {
              'userId': userId,
            });
        return;
      }

      // Merge updates with current data
      final updatedData = currentProfile.toJson()..addAll(updates);
      final updatedProfile = UserProfile.fromJson(updatedData);

      await saveUserProfile(updatedProfile);
    } catch (e, s) {
      WasteAppLogger.severe('Error updating user profile',
          error: e, stackTrace: s, context: {'userId': userId});
      rethrow;
    }
  }
}
