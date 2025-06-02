import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/waste_classification.dart';
import '../models/filter_options.dart';
import '../models/user_profile.dart';
import '../utils/constants.dart';
import 'gamification_service.dart';

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
    await Hive.openBox(StorageKeys.gamificationBox);
    await Hive.openBox(StorageKeys.familiesBox);
    await Hive.openBox(StorageKeys.invitationsBox);
    
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
    final classificationsBox = Hive.box(StorageKeys.classificationsBox);
    
    // Get current user ID
    final userProfile = await getCurrentUserProfile();
    String currentUserId;
    
    if (userProfile != null && userProfile.id.isNotEmpty) {
      // Signed-in user
      currentUserId = userProfile.id;
    } else {
      // Guest user - use a consistent guest identifier
      currentUserId = 'guest_user';
    }
    
    // Ensure the classification has the correct user ID
    final classificationWithUserId = classification.copyWith(userId: currentUserId);
    
    // Debug logging
    debugPrint('💾 Saving classification for user: $currentUserId');
    debugPrint('💾 Classification: ${classification.itemName}');
    
    final String key = 'classification_${currentUserId}_${DateTime.now().millisecondsSinceEpoch}';
    await classificationsBox.put(key, jsonEncode(classificationWithUserId.toJson()));
  }

  Future<List<WasteClassification>> getAllClassifications({FilterOptions? filterOptions}) async {
    final classificationsBox = Hive.box(StorageKeys.classificationsBox);
    final List<WasteClassification> classifications = [];

    // Get current user ID
    final userProfile = await getCurrentUserProfile();
    String currentUserId;
    
    if (userProfile != null && userProfile.id.isNotEmpty) {
      // Signed-in user
      currentUserId = userProfile.id;
    } else {
      // Guest user - use a consistent guest identifier
      currentUserId = 'guest_user';
    }

    // Debug logging - ENHANCED
    debugPrint('=== CLASSIFICATION LOADING DEBUG ===');
    debugPrint('📖 Current user ID: $currentUserId');
    debugPrint('📖 User profile: ${userProfile?.toJson()}');
    debugPrint('📖 Total classifications in storage: ${classificationsBox.keys.length}');
    debugPrint('📖 All keys in storage: ${classificationsBox.keys.toList()}');
    
    // Debug all classifications in storage
    for (var key in classificationsBox.keys) {
      final String jsonString = classificationsBox.get(key);
      final Map<String, dynamic> json = jsonDecode(jsonString);
      final classification = WasteClassification.fromJson(json);
      debugPrint('📖 Classification: ${classification.itemName} | userId: ${classification.userId} | timestamp: ${classification.timestamp}');
    }
    
    for (var key in classificationsBox.keys) {
      final String jsonString = classificationsBox.get(key);
      final Map<String, dynamic> json = jsonDecode(jsonString);
      final classification = WasteClassification.fromJson(json);
      
      // Include classifications based on user context
      bool shouldInclude = false;
      
      if (currentUserId == 'guest_user') {
        // For guest users, include guest classifications and legacy null userId
        shouldInclude = classification.userId == 'guest_user' || 
                       classification.userId == null ||
                       (classification.userId != null && 
                        classification.userId!.startsWith('guest_'));
        debugPrint('📖 Guest mode check: $shouldInclude (userId: ${classification.userId})');
      } else {
        // For signed-in users, only include their own classifications
        shouldInclude = classification.userId == currentUserId;
        debugPrint('📖 Signed-in mode check: $shouldInclude (looking for: $currentUserId, found: ${classification.userId})');
      }
      
      if (shouldInclude) {
        classifications.add(classification);
        debugPrint('📖 ✅ Including classification: ${classification.itemName}');
      } else {
        debugPrint('📖 ❌ Excluding classification: ${classification.itemName} (different user)');
      }
    }
    
    debugPrint('📖 Total classifications loaded for user $currentUserId: ${classifications.length}');
    debugPrint('=====================================');

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
    List<WasteClassification> filteredClassifications = List.from(classifications);
    
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
    List<String> headers = [
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
    String csvContent = '${headers.join(',')}\n';
    
    // Add each classification as a row
    for (var classification in classifications) {
      List<String> row = [
        _escapeCsvField(classification.itemName),
        _escapeCsvField(classification.category),
        _escapeCsvField(classification.subcategory ?? ''),
        _escapeCsvField(classification.materialType ?? ''),
        classification.isRecyclable == true ? 'Yes' : classification.isRecyclable == false ? 'No' : '',
        classification.isCompostable == true ? 'Yes' : classification.isCompostable == false ? 'No' : '',
        classification.requiresSpecialDisposal == true ? 'Yes' : classification.requiresSpecialDisposal == false ? 'No' : '',
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
    
    // Get current user ID
    final userProfile = await getCurrentUserProfile();
    String currentUserId;
    
    if (userProfile != null && userProfile.id.isNotEmpty) {
      // Signed-in user
      currentUserId = userProfile.id;
    } else {
      // Guest user - use a consistent guest identifier
      currentUserId = 'guest_user';
    }
    
    // Only clear classifications for the current user
    final keysToDelete = <String>[];
    for (var key in classificationsBox.keys) {
      final String jsonString = classificationsBox.get(key);
      final Map<String, dynamic> json = jsonDecode(jsonString);
      final classification = WasteClassification.fromJson(json);
      
      // Delete if it belongs to current user or if both are null (backward compatibility)
      if (classification.userId == currentUserId || 
          (classification.userId == null && currentUserId == 'guest_user')) {
        keysToDelete.add(key);
      }
    }
    
    // Delete the identified keys
    for (final key in keysToDelete) {
      await classificationsBox.delete(key);
    }
  }

  // Settings methods
  Future<void> saveSettings({
    required bool isDarkMode,
    required bool isGoogleSyncEnabled,
  }) async {
    final settingsBox = Hive.box(StorageKeys.settingsBox);
    await settingsBox.put(StorageKeys.isDarkModeKey, isDarkMode);
    await settingsBox.put(
        StorageKeys.isGoogleSyncEnabledKey, isGoogleSyncEnabled);
  }

  /// Get user settings with default values
  Future<Map<String, dynamic>> getSettings() async {
    try {
      final settings = await Hive.box(StorageKeys.settingsBox).get('settings');
      if (settings == null) {
        // Default settings for new users - Cloud sync ENABLED by default
        final defaultSettings = {
          'isGoogleSyncEnabled': true,  // ← ENABLED BY DEFAULT
          'notifications': true,
          'darkMode': false,
          'language': 'en',
          'autoBackup': true,
          'dataSharingConsent': true,
          'privacyOptIn': true,
        };
        await Hive.box(StorageKeys.settingsBox).put('settings', defaultSettings);
        return defaultSettings;
      }
      return Map<String, dynamic>.from(settings);
    } catch (e) {
      debugPrint('Error getting settings: $e');
      // Return default settings with cloud sync enabled
      return {
        'isGoogleSyncEnabled': true,  // ← ENABLED BY DEFAULT
        'notifications': true,
        'darkMode': false,
        'language': 'en',
        'autoBackup': true,
        'dataSharingConsent': true,
        'privacyOptIn': true,
      };
    }
  }

  // --------------------------------------------------------------------------
  // Classification Cache methods (local hash-based cache)
  // --------------------------------------------------------------------------
  /// Retrieve a cached classification by image hash, or null if none exists.
  Future<WasteClassification?> getCachedClassification(String hash) async {
    final cacheBox = Hive.box(StorageKeys.cacheBox);
    final String? jsonString = cacheBox.get(hash);
    if (jsonString == null) return null;
    try {
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
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
    final String jsonString = jsonEncode(classification.toJson());
    await cacheBox.put(hash, jsonString);
  }

  // Export all user data for backup
  Future<String> exportUserData() async {
    final UserProfile? userProfile = await getCurrentUserProfile();
    final Map<String, dynamic> exportData = {
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
      final Map<String, dynamic> importData = jsonDecode(jsonData);

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
        final List<dynamic> classifications = importData['classifications'];
        final classificationsBox = Hive.box(StorageKeys.classificationsBox);

        for (var i = 0; i < classifications.length; i++) {
          final classification =
              WasteClassification.fromJson(classifications[i]);
          final String key =
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
      final gamificationService = GamificationService();
      await gamificationService.clearGamificationData(); // Use the proper clear method
      
      final cacheBox = Hive.box<String>(StorageKeys.cacheBox);
      await cacheBox.clear();
      
      // Clear SharedPreferences (theme, user consent, etc.)
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
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
        final List<dynamic> eventsJson = jsonDecode(eventsJsonString);
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
          final String jsonString = classificationsBox.get(key);
          final Map<String, dynamic> json = jsonDecode(jsonString);
          final classification = WasteClassification.fromJson(json);
          return classification.userId == userProfile.id;
        })
        .toList();
    
    // If user has existing data, don't offer migration
    if (existingUserClassifications.isNotEmpty) {
      return 0;
    }
    
    // Count guest classifications available for migration
    final guestClassifications = classificationsBox.keys
        .where((key) {
          final String jsonString = classificationsBox.get(key);
          final Map<String, dynamic> json = jsonDecode(jsonString);
          final classification = WasteClassification.fromJson(json);
          return classification.userId == 'guest_user' || 
                 classification.userId == null ||
                 (classification.userId != null && classification.userId!.startsWith('guest_'));
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
    
    int migratedCount = 0;
    
    // Find all guest classifications
    for (var key in classificationsBox.keys) {
      final String jsonString = classificationsBox.get(key);
      final Map<String, dynamic> json = jsonDecode(jsonString);
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
}
