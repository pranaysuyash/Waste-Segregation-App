import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/waste_classification.dart';
import '../utils/constants.dart';

class StorageService {
  // Initialize Hive database
  static Future<void> initializeHive() async {
    if (kIsWeb) {
      // For web, initialize Hive without a specific path
      await Hive.initFlutter();
    } else {
      // For mobile platforms, use the app document directory
      try {
        final appDocumentDirectory = await getApplicationDocumentsDirectory();
        await Hive.initFlutter(appDocumentDirectory.path);
      } catch (e) {
        // Fallback initialization if path_provider fails
        await Hive.initFlutter();
      }
    }
    
    // Register adapters if needed
    // Note: For simple objects we can use JSON serialization
    // For complex objects, create custom TypeAdapters
    
    // Open boxes
    await Hive.openBox(StorageKeys.userBox);
    await Hive.openBox(StorageKeys.classificationsBox);
    await Hive.openBox(StorageKeys.settingsBox);
  }
  
  // User methods
  Future<void> saveUserInfo({
    required String userId,
    required String email,
    required String displayName,
  }) async {
    final userBox = Hive.box(StorageKeys.userBox);
    await userBox.put(StorageKeys.userIdKey, userId);
    await userBox.put(StorageKeys.userEmailKey, email);
    await userBox.put(StorageKeys.userDisplayNameKey, displayName);
  }
  
  Future<Map<String, dynamic>> getUserInfo() async {
    final userBox = Hive.box(StorageKeys.userBox);
    return {
      'userId': userBox.get(StorageKeys.userIdKey),
      'email': userBox.get(StorageKeys.userEmailKey),
      'displayName': userBox.get(StorageKeys.userDisplayNameKey),
    };
  }
  
  Future<void> clearUserInfo() async {
    final userBox = Hive.box(StorageKeys.userBox);
    await userBox.clear();
  }
  
  bool isUserLoggedIn() {
    final userBox = Hive.box(StorageKeys.userBox);
    return userBox.get(StorageKeys.userIdKey) != null;
  }
  
  // Classification methods
  Future<void> saveClassification(WasteClassification classification) async {
    final classificationsBox = Hive.box(StorageKeys.classificationsBox);
    final String key = 'classification_${DateTime.now().millisecondsSinceEpoch}';
    await classificationsBox.put(key, jsonEncode(classification.toJson()));
  }
  
  Future<List<WasteClassification>> getAllClassifications() async {
    final classificationsBox = Hive.box(StorageKeys.classificationsBox);
    final List<WasteClassification> classifications = [];
    
    for (var key in classificationsBox.keys) {
      final String jsonString = classificationsBox.get(key);
      final Map<String, dynamic> json = jsonDecode(jsonString);
      classifications.add(WasteClassification.fromJson(json));
    }
    
    // Sort by timestamp in descending order (newest first)
    classifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    return classifications;
  }
  
  Future<void> deleteClassification(String key) async {
    final classificationsBox = Hive.box(StorageKeys.classificationsBox);
    await classificationsBox.delete(key);
  }
  
  Future<void> clearAllClassifications() async {
    final classificationsBox = Hive.box(StorageKeys.classificationsBox);
    await classificationsBox.clear();
  }
  
  // Settings methods
  Future<void> saveSettings({
    required bool isDarkMode,
    required bool isGoogleSyncEnabled,
  }) async {
    final settingsBox = Hive.box(StorageKeys.settingsBox);
    await settingsBox.put(StorageKeys.isDarkModeKey, isDarkMode);
    await settingsBox.put(StorageKeys.isGoogleSyncEnabledKey, isGoogleSyncEnabled);
  }
  
  Future<Map<String, dynamic>> getSettings() async {
    final settingsBox = Hive.box(StorageKeys.settingsBox);
    return {
      'isDarkMode': settingsBox.get(StorageKeys.isDarkModeKey, defaultValue: false),
      'isGoogleSyncEnabled': settingsBox.get(StorageKeys.isGoogleSyncEnabledKey, defaultValue: false),
    };
  }
  
  // Export all user data for backup
  Future<String> exportUserData() async {
    final Map<String, dynamic> exportData = {
      'userData': await getUserInfo(),
      'settings': await getSettings(),
      'classifications': await getAllClassifications().then(
        (list) => list.map((item) => item.toJson()).toList(),
      ),
    };
    
    return jsonEncode(exportData);
  }
  
  // Import user data from backup
  Future<void> importUserData(String jsonData) async {
    try {
      final Map<String, dynamic> importData = jsonDecode(jsonData);
      
      // Clear existing data
      await clearUserInfo();
      await clearAllClassifications();
      
      // Import user data
      if (importData.containsKey('userData')) {
        final userData = importData['userData'];
        await saveUserInfo(
          userId: userData['userId'] ?? '',
          email: userData['email'] ?? '',
          displayName: userData['displayName'] ?? '',
        );
      }
      
      // Import settings
      if (importData.containsKey('settings')) {
        final settings = importData['settings'];
        await saveSettings(
          isDarkMode: settings['isDarkMode'] ?? false,
          isGoogleSyncEnabled: settings['isGoogleSyncEnabled'] ?? false,
        );
      }
      
      // Import classifications
      if (importData.containsKey('classifications')) {
        final List<dynamic> classifications = importData['classifications'];
        final classificationsBox = Hive.box(StorageKeys.classificationsBox);
        
        for (var i = 0; i < classifications.length; i++) {
          final classification = WasteClassification.fromJson(classifications[i]);
          final String key = 'classification_${classification.timestamp.millisecondsSinceEpoch}';
          await classificationsBox.put(key, jsonEncode(classification.toJson()));
        }
      }
    } catch (e) {
      throw Exception('Failed to import data: $e');
    }
  }
}