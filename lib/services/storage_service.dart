import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/waste_classification.dart';
import '../models/filter_options.dart';
import '../models/user_profile.dart';
import '../models/classification_feedback.dart';
import '../utils/constants.dart';
import 'gamification_service.dart';
import 'cloud_storage_service.dart';
import 'package:uuid/uuid.dart';
import 'classification_migration_service.dart';

class StorageService {
  static const String _userProfileKey = 'user_profile';
  
  // Global lock mechanism to prevent concurrent saves across all code paths
  static final Map<String, DateTime> _recentSaves = <String, DateTime>{};
  static final Set<String> _activeSaves = <String>{};

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
    await Hive.openBox(StorageKeys.gamificationBox);
    await Hive.openBox(StorageKeys.familiesBox);
    await Hive.openBox(StorageKeys.invitationsBox);
    await Hive.openBox(StorageKeys.classificationFeedbackBox);
    
    // Open cache box for image classification caching
    // We're using String type to store serialized CachedClassification objects
    await Hive.openBox<String>(StorageKeys.cacheBox);
  }

  // User methods
  Future<void> saveUserProfile(UserProfile userProfile) async {
    final userBox = Hive.box(StorageKeys.userBox);
    await userBox.put(StorageKeys.userProfileKey, jsonEncode(userProfile.toJson()));
  }

  Future<UserProfile?> getCurrentUserProfile() async {
    final userBox = Hive.box(StorageKeys.userBox);
    final String? userProfileJson = userBox.get(StorageKeys.userProfileKey);
    if (userProfileJson != null) {
      return UserProfile.fromJson(jsonDecode(userProfileJson));
    }
    return null;
  }

  Future<void> clearUserInfo() async {
    final userBox = Hive.box(StorageKeys.userBox);
    // Clear the new userProfileKey 
    await userBox.delete(StorageKeys.userProfileKey);
    // Note: Old individual keys (userIdKey, userEmailKey, userDisplayNameKey) were removed
    // during UserProfile refactoring and are no longer needed
  }

  Future<bool> isUserLoggedIn() async {
    final userProfile = await getCurrentUserProfile();
    return userProfile != null && userProfile.id.isNotEmpty;
  }

  // Classification methods
  Future<void> saveClassification(WasteClassification classification) async {
    // Create a unique key based on content and user to prevent duplicates
    final contentHash = '${classification.itemName}_${classification.category}_${classification.subcategory}_${classification.userId}';
    final now = DateTime.now();
    
    // Check if this exact content was saved recently (within 30 seconds)
    final recentSaveTime = _recentSaves[contentHash];
    if (recentSaveTime != null && now.difference(recentSaveTime).inSeconds < 30) {
      debugPrint('🚫 RECENT SAVE DETECTED: Skipping save for ${classification.itemName} (saved ${now.difference(recentSaveTime).inSeconds}s ago)');
      return;
    }
    
    // Check if this classification ID is currently being saved
    if (_activeSaves.contains(classification.id)) {
      debugPrint('🔒 ACTIVE SAVE DETECTED: Classification ${classification.id} is currently being saved, skipping');
      return;
    }
    
    // Add to active saves
    _activeSaves.add(classification.id);
    
    try {
      final classificationsBox = Hive.box(StorageKeys.classificationsBox);
      
      // Get current user ID
      final userProfile = await getCurrentUserProfile();
      final currentUserId = userProfile?.id ?? 'guest_user';
      
      // Ensure the classification has the correct user ID
      final classificationWithUserId = classification.copyWith(userId: currentUserId);
      
      // Debug logging
      debugPrint('💾 Saving classification for user: $currentUserId');
      debugPrint('💾 Classification: ${classification.itemName}');
      debugPrint('💾 Classification ID: ${classification.id}');
      
      // Check if this exact classification already exists in storage
      final existingData = classificationsBox.get(classification.id);
      if (existingData != null) {
        debugPrint('🚫 DUPLICATE DETECTED: Classification with ID ${classification.id} already exists in storage');
        return;
      }
      
      // Save using classification ID as key for consistent upserting
      await classificationsBox.put(classification.id, classificationWithUserId.toJson());
      
      // Record this save to prevent immediate duplicates
      _recentSaves[contentHash] = now;
      
      // Clean up old entries (keep only last 100 entries)
      if (_recentSaves.length > 100) {
        final oldestEntries = _recentSaves.entries.toList()
          ..sort((a, b) => a.value.compareTo(b.value));
        for (int i = 0; i < 20; i++) {
          _recentSaves.remove(oldestEntries[i].key);
        }
      }
      
      debugPrint('✅ Classification saved successfully');
      debugPrint('✅ Total classifications in storage: ${classificationsBox.length}');
      
    } finally {
      // Always remove from active saves
      _activeSaves.remove(classification.id);
    }
    
    // Note: UI refresh will happen through provider pattern in calling code
  }

  Future<List<WasteClassification>> getAllClassifications({FilterOptions? filterOptions}) async {
    final classificationsBox = Hive.box(StorageKeys.classificationsBox);
    final classifications = <WasteClassification>[];

    // Get current user ID
    final userProfile = await getCurrentUserProfile();
    final currentUserId = userProfile?.id ?? 'guest_user';

    // Debug logging - REDUCED
    debugPrint('📖 Loading classifications for user: $currentUserId');
    debugPrint('📖 Total classifications in storage: ${classificationsBox.keys.length}');
    
    // Counter for different types of classifications
    var totalProcessed = 0;
    var successfullyParsed = 0;
    var includedForUser = 0;
    var excludedDifferentUser = 0;
    var corruptedEntries = 0;
    var guestEntries = 0;
    var signedInUserEntries = 0;
    var nullUserIdEntries = 0;
    
    // Process classifications for the current user (main filtering loop)
    for (final key in classificationsBox.keys) {
      totalProcessed++;
      try {
        final data = classificationsBox.get(key);
        if (data == null) {
          corruptedEntries++;
          continue;
        }
        
        Map<String, dynamic> json;
        
        // Handle both JSON string and Map formats
        if (data is String) {
          if (data.isEmpty) {
            corruptedEntries++;
            continue;
          }
          json = jsonDecode(data);
        } else if (data is Map<String, dynamic>) {
          json = data;
        } else if (data is Map) {
          json = Map<String, dynamic>.from(data);
        } else {
          debugPrint('📖 ⚠️ Invalid data format for key: $key (${data.runtimeType}), deleting corrupted entry');
          await classificationsBox.delete(key);
          corruptedEntries++;
          continue;
        }
        
        var classification = WasteClassification.fromJson(json);
        successfullyParsed++;
        
        // Count user ID types
        if (classification.userId == null) {
          nullUserIdEntries++;
        } else if (classification.userId == 'guest_user' || classification.userId!.startsWith('guest_')) {
          guestEntries++;
        } else {
          signedInUserEntries++;
        }
        
        // Assign a new ID if it's missing (for older entries) and save back
        if (classification.id.isEmpty) {
          classification = classification.copyWith(id: const Uuid().v4());
          // Always store as JSON string for consistency
          await classificationsBox.put(key, jsonEncode(classification.toJson()));
          debugPrint('📖 Generated and saved new ID for classification: ${classification.itemName}');
        }
        
        // Include classifications based on user context
        var shouldInclude = false;
        
        if (currentUserId == 'guest_user') {
          // For guest users, include guest classifications and legacy null userId
          shouldInclude = classification.userId == 'guest_user' || 
                         classification.userId == null ||
                         (classification.userId != null && 
                          classification.userId!.startsWith('guest_'));
        } else {
          // For signed-in users, only include their own classifications
          shouldInclude = classification.userId == currentUserId;
        }
        
        if (shouldInclude) {
          classifications.add(classification);
          includedForUser++;
        } else {
          excludedDifferentUser++;
        }
      } catch (e) {
        debugPrint('📖 ❌ Error processing classification with key $key: $e');
        corruptedEntries++;
        
        // Delete corrupted entry to prevent future errors
        try {
          await classificationsBox.delete(key);
          debugPrint('📖 🗑️ Deleted corrupted classification entry: $key');
        } catch (deleteError) {
          debugPrint('📖 ❌ Failed to delete corrupted entry: $deleteError');
        }
      }
    }
    
    // Final debug summary
    debugPrint('📊 SUMMARY:');
    debugPrint('📊 Total entries processed: $totalProcessed');
    debugPrint('📊 Successfully parsed: $successfullyParsed');
    debugPrint('📊 Corrupted entries: $corruptedEntries');
    debugPrint('📊 Classifications included for user: $includedForUser');
    debugPrint('📊 Classifications excluded (different user): $excludedDifferentUser');
    debugPrint('📊 Total classifications returned: ${classifications.length}');

    // Apply filters if provided
    if (filterOptions != null && filterOptions.isNotEmpty) {
      return _applyFilters(classifications, filterOptions);
    }

    // Default sorting by timestamp in descending order (newest first)
    classifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return classifications;
  }
  
  /// Applies filters to the list of classifications
  List<WasteClassification> _applyFilters(
    List<WasteClassification> classifications, 
    FilterOptions filterOptions
  ) {
    // Create a filtered list
    var filteredClassifications = List<WasteClassification>.from(classifications);
    
    // Filter by search text (case-insensitive)
    if (filterOptions.searchText != null && filterOptions.searchText!.isNotEmpty) {
      final searchText = filterOptions.searchText!.toLowerCase();
      filteredClassifications = filteredClassifications.where((classification) {
        return classification.itemName.toLowerCase().contains(searchText) ||
          (classification.subcategory != null && 
           classification.subcategory!.toLowerCase().contains(searchText)) ||
          (classification.materialType != null && 
           classification.materialType!.toLowerCase().contains(searchText)) ||
          classification.category.toLowerCase().contains(searchText);
      }).toList();
    }
    
    // Filter by categories
    if (filterOptions.categories != null && filterOptions.categories!.isNotEmpty) {
      filteredClassifications = filteredClassifications.where((classification) {
        // Case-insensitive category comparison
        return filterOptions.categories!.any((category) => 
          classification.category.toLowerCase() == category.toLowerCase());
      }).toList();
    }
    
    // Filter by subcategories
    if (filterOptions.subcategories != null && filterOptions.subcategories!.isNotEmpty) {
      filteredClassifications = filteredClassifications.where((classification) {
        if (classification.subcategory == null) return false;
        // Case-insensitive subcategory comparison
        return filterOptions.subcategories!.any((subcategory) => 
          classification.subcategory!.toLowerCase() == subcategory.toLowerCase());
      }).toList();
    }
    
    // Filter by material types
    if (filterOptions.materialTypes != null && filterOptions.materialTypes!.isNotEmpty) {
      filteredClassifications = filteredClassifications.where((classification) {
        if (classification.materialType == null) return false;
        // Case-insensitive material type comparison
        return filterOptions.materialTypes!.any((materialType) => 
          classification.materialType!.toLowerCase() == materialType.toLowerCase());
      }).toList();
    }
    
    // Filter by recyclable status
    if (filterOptions.isRecyclable != null) {
      filteredClassifications = filteredClassifications.where((classification) =>
        classification.isRecyclable == filterOptions.isRecyclable).toList();
    }
    
    // Filter by compostable status
    if (filterOptions.isCompostable != null) {
      filteredClassifications = filteredClassifications.where((classification) =>
        classification.isCompostable == filterOptions.isCompostable).toList();
    }
    
    // Filter by special disposal requirement
    if (filterOptions.requiresSpecialDisposal != null) {
      filteredClassifications = filteredClassifications.where((classification) =>
        classification.requiresSpecialDisposal == filterOptions.requiresSpecialDisposal).toList();
    }
    
    // Filter by date range
    if (filterOptions.startDate != null) {
      final startDate = DateTime(
        filterOptions.startDate!.year,
        filterOptions.startDate!.month,
        filterOptions.startDate!.day,
      );
      
      filteredClassifications = filteredClassifications.where((classification) {
        final classificationDate = DateTime(
          classification.timestamp.year,
          classification.timestamp.month,
          classification.timestamp.day,
        );
        return classificationDate.isAtSameMomentAs(startDate) || 
               classificationDate.isAfter(startDate);
      }).toList();
    }
    
    if (filterOptions.endDate != null) {
      final endDate = DateTime(
        filterOptions.endDate!.year,
        filterOptions.endDate!.month,
        filterOptions.endDate!.day,
        23, 59, 59, 999, // End of day
      );
      
      filteredClassifications = filteredClassifications.where((classification) {
        return classification.timestamp.isBefore(endDate) || 
               classification.timestamp.isAtSameMomentAs(endDate);
      }).toList();
    }
    
    // Apply sorting
    switch (filterOptions.sortBy) {
      case SortField.date:
        if (filterOptions.sortNewestFirst) {
          filteredClassifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        } else {
          filteredClassifications.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        }
        break;
      case SortField.name:
        if (filterOptions.sortNewestFirst) {
          // "Newest first" isn't applicable for names, so we'll interpret it as A-Z vs Z-A
          filteredClassifications.sort((a, b) => a.itemName.compareTo(b.itemName));
        } else {
          filteredClassifications.sort((a, b) => b.itemName.compareTo(a.itemName));
        }
        break;
      case SortField.category:
        if (filterOptions.sortNewestFirst) {
          // "Newest first" isn't applicable for categories, so we'll interpret it as A-Z vs Z-A
          filteredClassifications.sort((a, b) => a.category.compareTo(b.category));
        } else {
          filteredClassifications.sort((a, b) => b.category.compareTo(a.category));
        }
        break;
    }
    
    return filteredClassifications;
  }
  
  /// Get classifications with pagination support
  Future<List<WasteClassification>> getClassificationsWithPagination({
    FilterOptions? filterOptions,
    int pageSize = 20,
    int page = 0,
  }) async {
    final allClassifications = await getAllClassifications(filterOptions: filterOptions);
    
    // Calculate start and end indexes for pagination
    final startIndex = page * pageSize;
    final endIndex = (page + 1) * pageSize;
    
    // Return the specified page of classifications
    if (startIndex >= allClassifications.length) {
      return []; // No more items
    }
    
    final actualEndIndex = endIndex > allClassifications.length 
      ? allClassifications.length 
      : endIndex;
      
    return allClassifications.sublist(startIndex, actualEndIndex);
  }
  
  /// Get the total count of classifications matching the filter
  Future<int> getClassificationsCount({FilterOptions? filterOptions}) async {
    final allClassifications = await getAllClassifications(filterOptions: filterOptions);
    return allClassifications.length;
  }
  
  /// Export classifications to a CSV file format as a string
  Future<String> exportClassificationsToCSV({FilterOptions? filterOptions}) async {
    final classifications = await getAllClassifications(filterOptions: filterOptions);
    
    // Create CSV header
    final headers = [
      'Item Name',
      'Category',
      'Subcategory',
      'Material Type',
      'Recyclable',
      'Compostable',
      'Special Disposal',
      'Disposal Method',
      'Recycling Code',
      'Date'
    ];
    
    // Create CSV content with header row
    var csvContent = '${headers.join(',')}\n';
    
    // Add each classification as a row
    for (final classification in classifications) {
      final row = [
        _escapeCsvField(classification.itemName),
        _escapeCsvField(classification.category),
        _escapeCsvField(classification.subcategory ?? ''),
        _escapeCsvField(classification.materialType ?? ''),
        if (classification.isRecyclable == true) 'Yes' else if (classification.isRecyclable == false) 'No' else '',
        if (classification.isCompostable == true) 'Yes' else if (classification.isCompostable == false) 'No' else '',
        if (classification.requiresSpecialDisposal == true) 'Yes' else if (classification.requiresSpecialDisposal == false) 'No' else '',
        _escapeCsvField(classification.disposalMethod ?? ''),
        _escapeCsvField(classification.recyclingCode?.toString() ?? ''),
        _formatDateForCsv(classification.timestamp)
      ];
      
      csvContent += '${row.join(',')}\n';
    }
    
    return csvContent;
  }
  
  /// Helper method to escape fields for CSV
  String _escapeCsvField(String field) {
    // If the field contains commas, quotes, or newlines, wrap it in quotes
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      // Replace any double quotes with two double quotes
      field = field.replaceAll('"', '""');
      // Wrap the field in double quotes
      return '"$field"';
    }
    return field;
  }
  
  /// Helper method to format dates for CSV
  String _formatDateForCsv(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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
    DateTime? lastCloudSync,
    bool? allowHistoryFeedback,
    int? feedbackTimeframeDays,
    bool? notifications,
    bool? eduNotifications,
    bool? gamificationNotifications,
    bool? reminderNotifications,
  }) async {
    final settings = await getSettings();
    
    // Update the settings with new values
    settings['isDarkMode'] = isDarkMode;
    settings['isGoogleSyncEnabled'] = isGoogleSyncEnabled;
    if (lastCloudSync != null) {
      settings['lastCloudSync'] = lastCloudSync.toIso8601String();
    }
    
    // Update feedback settings if provided
    if (allowHistoryFeedback != null) {
      settings['allowHistoryFeedback'] = allowHistoryFeedback;
    }
    if (feedbackTimeframeDays != null) {
      settings['feedbackTimeframeDays'] = feedbackTimeframeDays;
    }
    if (notifications != null) {
      settings['notifications'] = notifications;
    }
    if (eduNotifications != null) {
      settings['eduNotifications'] = eduNotifications;
    }
    if (gamificationNotifications != null) {
      settings['gamificationNotifications'] = gamificationNotifications;
    }
    if (reminderNotifications != null) {
      settings['reminderNotifications'] = reminderNotifications;
    }
    
    // Save the updated settings
    final settingsBox = Hive.box(StorageKeys.settingsBox);
    await settingsBox.put('settings', settings);
    
    // Also save to the old format for backward compatibility
    await settingsBox.put(StorageKeys.isDarkModeKey, isDarkMode);
    await settingsBox.put(StorageKeys.isGoogleSyncEnabledKey, isGoogleSyncEnabled);
  }

  /// Update the last successful cloud sync timestamp.
  Future<void> updateLastCloudSync(DateTime timestamp) async {
    // Prevent storing timestamps far in the future which could happen due to
    // clock issues or bad data.
    if (timestamp.isAfter(DateTime.now().add(const Duration(minutes: 1)))) {
      debugPrint('⚠️ Invalid sync timestamp: $timestamp is in the future');
      return;
    }

    final settings = await getSettings();
    settings['lastCloudSync'] = timestamp.toIso8601String();
    final settingsBox = Hive.box(StorageKeys.settingsBox);
    await settingsBox.put('settings', settings);
  }

  /// Retrieve the last successful cloud sync time, or null if none.
  Future<DateTime?> getLastCloudSync() async {
    final settings = await getSettings();
    final value = settings['lastCloudSync'];
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  /// Get user settings with default values
  Future<Map<String, dynamic>> getSettings() async {
    try {
      final settings = await Hive.box(StorageKeys.settingsBox).get('settings');
      if (settings == null) {
        // Default settings for new users - Cloud sync ENABLED by default
        final defaultSettings = {
          'notifications': true,
          'eduNotifications': true,
          'gamificationNotifications': true,
          'reminderNotifications': true,
          'darkMode': false,
          'soundEffects': true,
          'autoSave': true,
          'isGoogleSyncEnabled': true, // Default to enabled for better user experience
          'allowHistoryFeedback': true, // Allow feedback on recent classifications from history
          'feedbackTimeframeDays': 7, // How many days back to allow feedback
        };
        await Hive.box(StorageKeys.settingsBox).put('settings', defaultSettings);
        return defaultSettings;
      }
      return Map<String, dynamic>.from(settings);
    } catch (e) {
      debugPrint('Error getting settings: $e');
      // Return default settings with cloud sync enabled
      return {
        'notifications': true,
        'eduNotifications': true,
        'gamificationNotifications': true,
        'reminderNotifications': true,
        'darkMode': false,
        'soundEffects': true,
        'autoSave': true,
        'isGoogleSyncEnabled': true, // Default to enabled for better user experience
        'allowHistoryFeedback': true, // Allow feedback on recent classifications from history
        'feedbackTimeframeDays': 7, // How many days back to allow feedback
      };
    }
  }

  // --------------------------------------------------------------------------
  // Classification Cache methods (local hash-based cache)
  // --------------------------------------------------------------------------
  /// Retrieve a cached classification by image hash, or null if none exists.
  Future<WasteClassification?> getCachedClassification(String hash) async {
    final cacheBox = Hive.box(StorageKeys.cacheBox);
    final jsonString = cacheBox.get(hash);
    if (jsonString == null) return null;
    try {
      final jsonMap = jsonDecode(jsonString);
      return WasteClassification.fromJson(jsonMap);
    } catch (_) {
      return null;
    }
  }

  /// Save a classification to cache keyed by image hash.
  Future<void> saveCachedClassification(
    String hash,
    WasteClassification classification,
  ) async {
    final cacheBox = Hive.box(StorageKeys.cacheBox);
    final jsonString = jsonEncode(classification.toJson());
    await cacheBox.put(hash, jsonString);
  }

  // Export all user data for backup
  Future<String> exportUserData() async {
    final userProfile = await getCurrentUserProfile();
    final exportData = {
      // Store UserProfile if available, otherwise store old user info for backward compatibility
      'userProfileData': userProfile?.toJson(), 
      'settings': await getSettings(),
      'classifications': await getAllClassifications().then(
        (list) => list.map((item) => item.toJson()).toList(),
      ),
      // Consider adding gamification data to export here too
    };

    return jsonEncode(exportData);
  }

  // Import user data from backup
  Future<void> importUserData(String jsonData) async {
    try {
      final importData = jsonDecode(jsonData);

      // Clear existing data first (clearUserInfo now handles UserProfile and old keys)
      await clearUserInfo();
      await clearAllClassifications();
      // Consider clearing gamification data too
      final gamificationBox = Hive.box(StorageKeys.gamificationBox);
      await gamificationBox.clear();

      // Import UserProfile data if present (new format)
      if (importData.containsKey('userProfileData') && importData['userProfileData'] != null) {
        final userProfile = UserProfile.fromJson(importData['userProfileData']);
        await saveUserProfile(userProfile);
      } 
      // Else, try to import old format userData if present
      else if (importData.containsKey('userData')) {
        final oldUserData = importData['userData'];
        if (oldUserData != null && oldUserData['userId'] != null) {
          final userProfile = UserProfile(
            id: oldUserData['userId'] ?? 'guest_id_${DateTime.now().millisecondsSinceEpoch}', // Ensure ID is not empty
            email: oldUserData['email'],
            displayName: oldUserData['displayName'],
            createdAt: DateTime.now(), // Assign current time as these weren't tracked before
            lastActive: DateTime.now(),
          );
          await saveUserProfile(userProfile);
        }
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
        final classifications = importData['classifications'];
        final classificationsBox = Hive.box(StorageKeys.classificationsBox);

        for (var i = 0; i < classifications.length; i++) {
          final classification =
              WasteClassification.fromJson(classifications[i]);
          final key =
              'classification_${classification.timestamp.millisecondsSinceEpoch}';
          await classificationsBox.put(
              key, jsonEncode(classification.toJson()));
        }
      }
    } catch (e) {
      throw Exception('Failed to import data: $e');
    }
  }

  Future<void> clearClassifications() async {
    try {
      final box = await Hive.openBox<WasteClassification>('classifications');
      await box.clear();
      await box.close();
    } catch (e) {
      debugPrint('Error clearing classifications: $e');
      rethrow;
    }
  }

  /// Clear all user-specific data (user info, classifications, settings, gamification, cache, SharedPreferences)
  Future<void> clearAllUserData() async {
    try {
      // Clear Hive boxes
      await clearUserInfo();
      await clearAllClassifications();
      final settingsBox = Hive.box(StorageKeys.settingsBox);
      await settingsBox.clear();
      
      // Import GamificationService to ensure proper clearing
      // Create a temporary instance with minimal dependencies for clearing
      final storageService = this;
      final cloudStorageService = CloudStorageService(storageService);
      final gamificationService = GamificationService(storageService, cloudStorageService);
      await gamificationService.clearGamificationData(); // Use the proper clear method
      
      final cacheBox = Hive.box<String>(StorageKeys.cacheBox);
      await cacheBox.clear();
      
      // Clear SharedPreferences (theme, user consent, etc.) with proper error handling
      try {
        final prefs = await SharedPreferences.getInstance();
        // Get all keys first to avoid type casting issues
        final keys = prefs.getKeys();
        for (final key in keys) {
          try {
            await prefs.remove(key);
          } catch (keyError) {
            debugPrint('⚠️ Warning: Could not remove SharedPreferences key "$key": $keyError');
            // Continue with other keys instead of failing completely
          }
        }
        debugPrint('✅ SharedPreferences cleared (${keys.length} keys processed)');
      } catch (prefsError) {
        debugPrint('⚠️ Warning: Error clearing SharedPreferences: $prefsError');
        // Don't rethrow - this shouldn't block the entire factory reset
      }
      
      debugPrint('✅ All user data cleared successfully');
    } catch (e) {
      debugPrint('❌ Error clearing user data: $e');
      rethrow;
    }
  }

  /// Saves analytics events to local storage for offline sync
  Future<void> saveAnalyticsEvents(List<dynamic> events) async {
    try {
      final box = await Hive.openBox<String>('analytics_events');
      final eventsJson = events.map((event) => jsonEncode(event.toJson())).toList();
      await box.put('pending_events', jsonEncode(eventsJson));
      debugPrint('✅ Saved ${events.length} analytics events to local storage');
    } catch (e) {
      debugPrint('❌ Failed to save analytics events: $e');
    }
  }

  /// Loads analytics events from local storage
  Future<List<Map<String, dynamic>>> loadAnalyticsEvents() async {
    try {
      final box = await Hive.openBox<String>('analytics_events');
      final eventsJsonString = box.get('pending_events');
      if (eventsJsonString != null) {
        final eventsJson = jsonDecode(eventsJsonString);
        return eventsJson.map((eventJson) => jsonDecode(eventJson) as Map<String, dynamic>).toList();
      }
      return [];
    } catch (e) {
      debugPrint('❌ Failed to load analytics events: $e');
      return [];
    }
  }

  /// Check if there's guest data that can be migrated for a new user
  Future<int> getGuestDataMigrationCount() async {
    final classificationsBox = Hive.box(StorageKeys.classificationsBox);
    final userProfile = await getCurrentUserProfile();
    
    // Only check for migration if user is signed in
    if (userProfile == null || userProfile.id.isEmpty || userProfile.id == 'guest_user') {
      return 0;
    }
    
    // Check if user has any existing classifications
    final existingUserClassifications = classificationsBox.keys
        .where((key) {
          try {
            final data = classificationsBox.get(key);
            if (data == null) return false;
            
            Map<String, dynamic> json;
            if (data is String) {
              if (data.isEmpty) return false;
              json = jsonDecode(data);
            } else if (data is Map<String, dynamic>) {
              json = data;
            } else if (data is Map) {
              json = Map<String, dynamic>.from(data);
            } else {
              return false;
            }
            
            final classification = WasteClassification.fromJson(json);
            return classification.userId == userProfile.id;
          } catch (e) {
            debugPrint('Error processing classification during migration count: $e');
            return false;
          }
        })
        .toList();
    
    // If user has existing data, don't offer migration
    if (existingUserClassifications.isNotEmpty) {
      return 0;
    }
    
    // Count guest classifications available for migration
    final guestClassifications = classificationsBox.keys
        .where((key) {
          try {
            final data = classificationsBox.get(key);
            if (data == null) return false;
            
            Map<String, dynamic> json;
            if (data is String) {
              if (data.isEmpty) return false;
              json = jsonDecode(data);
            } else if (data is Map<String, dynamic>) {
              json = data;
            } else if (data is Map) {
              json = Map<String, dynamic>.from(data);
            } else {
              return false;
            }
            
            final classification = WasteClassification.fromJson(json);
            return classification.userId == 'guest_user' || 
                   classification.userId == null ||
                   (classification.userId != null && classification.userId!.startsWith('guest_'));
          } catch (e) {
            debugPrint('Error processing classification during migration count: $e');
            return false;
          }
        })
        .toList();
    
    return guestClassifications.length;
  }
  
  /// Migrate guest data to the current signed-in user
  Future<int> migrateGuestDataToCurrentUser() async {
    final classificationsBox = Hive.box(StorageKeys.classificationsBox);
    final userProfile = await getCurrentUserProfile();
    
    if (userProfile == null || userProfile.id.isEmpty || userProfile.id == 'guest_user') {
      return 0;
    }
    
    var migratedCount = 0;
    
    // Find all guest classifications
    for (final key in classificationsBox.keys) {
      try {
        final data = classificationsBox.get(key);
        if (data == null) continue;
        
        Map<String, dynamic> json;
        if (data is String) {
          if (data.isEmpty) continue;
          json = jsonDecode(data);
        } else if (data is Map<String, dynamic>) {
          json = data;
        } else if (data is Map) {
          json = Map<String, dynamic>.from(data);
        } else {
          continue;
        }
        
        final classification = WasteClassification.fromJson(json);
        
        // Check if this is guest data
        if (classification.userId == 'guest_user' || 
            classification.userId == null ||
            (classification.userId != null && classification.userId!.startsWith('guest_'))) {
          
          // Migrate to current user
          final migratedClassification = classification.copyWith(userId: userProfile.id);
          await classificationsBox.put(key, jsonEncode(migratedClassification.toJson()));
          migratedCount++;
          
          debugPrint('🔄 Migrated classification: ${classification.itemName} to user ${userProfile.id}');
        }
      } catch (e) {
        debugPrint('Error migrating classification for key $key: $e');
        continue;
      }
    }
    
    debugPrint('✅ Successfully migrated $migratedCount classifications');
    return migratedCount;
  }

  /// Public method to apply filters to a list of classifications
  List<WasteClassification> applyFiltersToClassifications(
    List<WasteClassification> classifications,
    FilterOptions filterOptions,
  ) {
    if (filterOptions.isEmpty) {
      // Default sorting by timestamp in descending order (newest first)
      classifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return classifications;
    }
    
    return _applyFilters(classifications, filterOptions);
  }

  /// One-time cleanup to remove duplicate classifications
  Future<int> cleanupDuplicateClassifications() async {
    final classificationsBox = Hive.box(StorageKeys.classificationsBox);
    final userProfile = await getCurrentUserProfile();
    final currentUserId = userProfile?.id ?? 'guest_user';
    
    debugPrint('🧹 Starting duplicate cleanup for user: $currentUserId');
    
    // Load all classifications
    final allKeys = classificationsBox.keys.toList();
    final seenClassifications = <String, String>{}; // content hash -> key
    final keysToDelete = <String>[];
    var duplicatesFound = 0;
    
    for (final key in allKeys) {
      try {
        final data = classificationsBox.get(key);
        if (data == null) continue;
        
        Map<String, dynamic> json;
        if (data is String) {
          if (data.isEmpty) continue;
          json = jsonDecode(data);
        } else if (data is Map<String, dynamic>) {
          json = data;
        } else if (data is Map) {
          json = Map<String, dynamic>.from(data);
        } else {
          continue;
        }
        
        final classification = WasteClassification.fromJson(json);
        
        // Only process classifications for current user
        if (classification.userId != currentUserId) continue;
        
        // Create a unique identifier for this classification
        final contentHash = '${classification.itemName}|${classification.category}|${classification.subcategory}|${classification.timestamp.millisecondsSinceEpoch}';
        
        if (seenClassifications.containsKey(contentHash)) {
          // This is a duplicate, mark for deletion
          keysToDelete.add(key);
          duplicatesFound++;
          debugPrint('🧹 Found duplicate: ${classification.itemName} at ${classification.timestamp}');
        } else {
          // First occurrence, keep it
          seenClassifications[contentHash] = key;
        }
      } catch (e) {
        debugPrint('🧹 Error processing key $key during cleanup: $e');
        // Corrupted entry, mark for deletion
        keysToDelete.add(key);
      }
    }
    
    // Delete all duplicates
    for (final key in keysToDelete) {
      await classificationsBox.delete(key);
    }
    
    debugPrint('🧹 Cleanup complete: Removed $duplicatesFound duplicates');
    return duplicatesFound;
  }

  // ---------------------------------------------------------------------------
  // Classification Feedback methods
  // ---------------------------------------------------------------------------
  Future<void> saveClassificationFeedback(ClassificationFeedback feedback) async {
    final box = Hive.box(StorageKeys.classificationFeedbackBox);
    await box.put(feedback.id, feedback.toJson());
  }

  Future<List<ClassificationFeedback>> getAllClassificationFeedback() async {
    final box = Hive.box(StorageKeys.classificationFeedbackBox);
    final feedbackList = <ClassificationFeedback>[];
    for (final key in box.keys) {
      final data = box.get(key);
      if (data == null) continue;
      try {
        Map<String, dynamic> json;
        if (data is String) {
          json = jsonDecode(data);
        } else if (data is Map<String, dynamic>) {
          json = data;
        } else if (data is Map) {
          json = Map<String, dynamic>.from(data);
        } else {
          continue;
        }
        feedbackList.add(ClassificationFeedback.fromJson(json, key.toString()));
      } catch (_) {
        continue;
      }
    }
    return feedbackList;
  }

  /// Trigger migration of old classifications to update imageUrl fields
  Future<void> migrateOldClassifications() async {
    try {
      debugPrint('🔄 Starting classification migration process...');
      
      // Create cloud storage service instance
      final cloudStorageService = CloudStorageService(this);
      
      // Create migration service
      final migrationService = ClassificationMigrationService(this, cloudStorageService);
      
      // Run migration
      final result = await migrationService.migrateOldClassifications();
      
      debugPrint('📊 Migration completed: $result');
    } catch (e) {
      debugPrint('❌ Migration failed: $e');
    }
  }

}
