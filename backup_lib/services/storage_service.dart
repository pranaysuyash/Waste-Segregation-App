import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/waste_classification.dart';
import '../models/gamification.dart';
import '../models/educational_content.dart';
import '../utils/constants.dart'; // Import StorageKeys

class StorageService {

  // --- Box Names (moved from main.dart for better organization) ---
  // These are now defined in StorageKeys in constants.dart
  // static const String classificationsBoxName = 'classifications';
  // static const String gamificationBoxName = 'gamification';
  // static const String educationalContentBoxName = 'educationalContent';
  // static const String userInfoBoxName = 'userInfo';
  // static const String appSettingsBoxName = 'appSettings';

  // Check if boxes are open and ready
  bool areBoxesReady() {
    return Hive.isBoxOpen(StorageKeys.classificationsBox) &&
           Hive.isBoxOpen(StorageKeys.gamificationBox) &&
           Hive.isBoxOpen(StorageKeys.educationalContentBox) &&
           Hive.isBoxOpen(StorageKeys.userInfoBox) &&
           Hive.isBoxOpen(StorageKeys.appSettingsBox);
  }

  // --- User Info --- 
  Future<void> saveUserInfo(String userId, String email, String displayName) async {
    final userBox = Hive.box(StorageKeys.userInfoBox);
    await userBox.put(StorageKeys.userIdKey, userId);
    await userBox.put(StorageKeys.userEmailKey, email);
    await userBox.put(StorageKeys.userDisplayNameKey, displayName);
    debugPrint('User info saved: $userId, $displayName');
  }

  Future<Map<String, String?>> getUserInfo() async {
    final userBox = Hive.box(StorageKeys.userInfoBox);
    return {
      'userId': userBox.get(StorageKeys.userIdKey),
      'email': userBox.get(StorageKeys.userEmailKey),
      'displayName': userBox.get(StorageKeys.userDisplayNameKey),
    };
  }

  Future<void> clearUserInfo() async {
    final userBox = Hive.box(StorageKeys.userInfoBox);
    await userBox.clear();
    debugPrint('User info cleared.');
  }

  bool isUserLoggedIn() {
    final userBox = Hive.box(StorageKeys.userInfoBox);
    return userBox.get(StorageKeys.userIdKey) != null;
  }

  // --- Waste Classifications --- 
  Future<void> saveClassification(WasteClassification classification) async {
    final classificationsBox = Hive.box<WasteClassification>(StorageKeys.classificationsBox);
    // Use a unique key, e.g., timestamp
    await classificationsBox.put(DateTime.now().toIso8601String(), classification);
    debugPrint('Classification saved: ${classification.itemName}');
  }

  Future<List<WasteClassification>> getAllClassifications() async {
    final classificationsBox = Hive.box<WasteClassification>(StorageKeys.classificationsBox);
    final classifications = classificationsBox.values.toList();
    // Sort descending by timestamp before returning
    classifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return classifications;
  }
  
  Future<WasteClassification?> getClassification(String key) async {
     final classificationsBox = Hive.box<WasteClassification>(StorageKeys.classificationsBox);
     return classificationsBox.get(key);
  }

  Future<void> deleteClassification(String key) async {
    final classificationsBox = Hive.box<WasteClassification>(StorageKeys.classificationsBox);
    await classificationsBox.delete(key);
     debugPrint('Classification deleted: $key');
  }

  Future<void> clearAllClassifications() async {
     final classificationsBox = Hive.box<WasteClassification>(StorageKeys.classificationsBox);
     await classificationsBox.clear();
      debugPrint('All classifications cleared.');
  }

  // --- App Settings --- 
  Future<void> saveAppSettings(bool isDarkMode, bool isGoogleSyncEnabled) async {
    final settingsBox = Hive.box(StorageKeys.appSettingsBox);
    await settingsBox.put(StorageKeys.isDarkModeKey, isDarkMode);
    await settingsBox.put(StorageKeys.isGoogleSyncEnabledKey, isGoogleSyncEnabled);
  }

  Future<Map<String, bool>> getAppSettings() async {
    final settingsBox = Hive.box(StorageKeys.appSettingsBox);
    return {
      'isDarkMode': settingsBox.get(StorageKeys.isDarkModeKey, defaultValue: false),
      'isGoogleSyncEnabled': settingsBox.get(StorageKeys.isGoogleSyncEnabledKey, defaultValue: false),
    };
  }

  // --- Gamification Data --- 
  Future<void> saveGamificationProfile(GamificationProfile profile) async {
    final gamificationBox = Hive.box<GamificationProfile>(StorageKeys.gamificationBox);
    // Assuming only one profile, use a fixed key
    await gamificationBox.put('userProfile', profile);
     debugPrint('Gamification profile saved. Level: ${profile.points.level}');
  }

  Future<GamificationProfile?> getGamificationProfile() async {
    final gamificationBox = Hive.box<GamificationProfile>(StorageKeys.gamificationBox);
    return gamificationBox.get('userProfile');
  }
  
   Future<void> saveLastStreakUpdate(DateTime date) async {
      final settingsBox = Hive.box(StorageKeys.appSettingsBox);
      await settingsBox.put(StorageKeys.lastStreakUpdateKey, date.toIso8601String());
   }

   Future<DateTime?> getLastStreakUpdate() async {
      final settingsBox = Hive.box(StorageKeys.appSettingsBox);
      final dateString = settingsBox.get(StorageKeys.lastStreakUpdateKey);
      return dateString != null ? DateTime.parse(dateString) : null;
   }

  // --- Educational Content --- 
  Future<void> saveEducationalContent(List<EducationalContent> contents) async {
    final contentBox = Hive.box<EducationalContent>(StorageKeys.educationalContentBox);
    await contentBox.clear(); // Clear old content before saving new
    for (var content in contents) {
      await contentBox.put(content.id, content); // Use content ID as key
    }
     debugPrint('Saved ${contents.length} educational content items.');
  }

  Future<List<EducationalContent>> getAllEducationalContent() async {
    final contentBox = Hive.box<EducationalContent>(StorageKeys.educationalContentBox);
    return contentBox.values.toList();
  }

  Future<EducationalContent?> getEducationalContent(String id) async {
    final contentBox = Hive.box<EducationalContent>(StorageKeys.educationalContentBox);
    return contentBox.get(id);
  }

   // --- Sync Timestamp ---
   Future<void> saveLastSyncTimestamp(DateTime timestamp) async {
      final settingsBox = Hive.box(StorageKeys.appSettingsBox);
      await settingsBox.put(StorageKeys.lastSyncTimestampKey, timestamp.toIso8601String());
   }

   Future<DateTime?> getLastSyncTimestamp() async {
      final settingsBox = Hive.box(StorageKeys.appSettingsBox);
      final timestampString = settingsBox.get(StorageKeys.lastSyncTimestampKey);
      return timestampString != null ? DateTime.parse(timestampString) : null;
   }

  // --- Export/Import for Google Drive Sync --- 

  // Get all relevant data as a Map for export
  Future<Map<String, dynamic>> exportData() async {
    final classificationsBox = Hive.box<WasteClassification>(StorageKeys.classificationsBox);
    final gamificationBox = Hive.box<GamificationProfile>(StorageKeys.gamificationBox);
    // Add other boxes if needed
    
    return {
      StorageKeys.classificationsBox: classificationsBox.toMap().map((k, v) => MapEntry(k.toString(), v.toJson())), // Convert key to string
      StorageKeys.gamificationBox: gamificationBox.toMap().map((k,v) => MapEntry(k.toString(), v.toJson())), // Convert key to string
      // Add other data maps here
    };
  }

  // Import data from a Map (e.g., downloaded from Google Drive)
  Future<void> importData(Map<String, dynamic> data) async {
     debugPrint('Importing data...');
    // Import Classifications
    if (data.containsKey(StorageKeys.classificationsBox)) {
      final classificationsData = data[StorageKeys.classificationsBox] as Map<dynamic, dynamic>; // Might be Map<String, dynamic>
      final classificationsBox = Hive.box<WasteClassification>(StorageKeys.classificationsBox);
      await classificationsBox.clear(); // Clear existing before import
      classificationsData.forEach((key, value) {
        try {
           if (value is Map) { // Check if value is a map
              final classification = WasteClassification.fromJson(Map<String, dynamic>.from(value));
              classificationsBox.put(key.toString(), classification);
           } else {
             debugPrint('Skipping invalid classification data for key $key: $value');
           }
        } catch (e) {
          debugPrint('Error importing classification for key $key: $e');
        }
      });
        debugPrint('Imported ${classificationsBox.length} classifications.');
    }

    // Import Gamification Profile
    if (data.containsKey(StorageKeys.gamificationBox)) {
      final gamificationData = data[StorageKeys.gamificationBox] as Map<dynamic, dynamic>; // Might be Map<String, dynamic>
      final gamificationBox = Hive.box<GamificationProfile>(StorageKeys.gamificationBox);
      await gamificationBox.clear(); // Clear existing
       gamificationData.forEach((key, value) {
         try {
           if (value is Map) { // Check if value is a map
             final profile = GamificationProfile.fromJson(Map<String, dynamic>.from(value));
             gamificationBox.put(key.toString(), profile);
           } else {
              debugPrint('Skipping invalid gamification data for key $key: $value');
           }
         } catch (e) {
            debugPrint('Error importing gamification profile for key $key: $e');
         }
      });
      debugPrint('Imported ${gamificationBox.length} gamification profiles.');
    }

    // Add import logic for other data types if needed
     debugPrint('Data import finished.');
  }
}
