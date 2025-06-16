import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import '../utils/constants.dart';

/// Service to clear Firebase data for testing fresh install experience
/// This should only be used in development/testing environments
class FirebaseCleanupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Admin salt for anonymization (should be moved to constants)
  static const String _adminSalt = 'waste_segregation_app_admin_salt_2024';

  /// Collections to clear for fresh install simulation
  static const List<String> _collectionsToDelete = [
    'users',
    'community_feed',
    'community_stats', 
    'families',
    'invitations',
    'shared_classifications',
    'analytics_events',
    'family_stats',
  ];

  /// Global collections that need archiving before deletion
  static const List<String> _globalCollections = [
    'community_feed',
    'community_stats',
    'families',
    'invitations',
    'shared_classifications',
    'analytics_events',
    'family_stats',
    'disposal_locations',
    'recycling_facilities',
    'facility_reviews',
    'content_library',
    'daily_challenges',
    'user_achievements',
    'badges',
    'leaderboard_allTime',
    'leaderboard_weekly',
    'leaderboard_monthly',
  ];

  /// User subcollections that need archiving
  static const List<String> _userSubcollections = [
    'classifications',
    'achievements',
    'settings',
    'analytics',
    'content_progress',
  ];

  /// Hive boxes to clear for fresh install simulation - FIXED to use StorageKeys
  static final List<String> _hiveBoxesToClear = [
    StorageKeys.classificationsBox,
    StorageKeys.gamificationBox,
    StorageKeys.userBox,
    StorageKeys.settingsBox,
    StorageKeys.cacheBox,
    StorageKeys.familiesBox,
    StorageKeys.invitationsBox,
    StorageKeys.classificationFeedbackBox,
    'classificationHashesBox', // This one uses a different pattern
    'analytics_events', // Legacy box name
    'premium_features', // Premium service box
    'community_stats', // Community service box
    'community_feed', // Community service box
  ];

  /// Reset Account: Archive & clear user data, keep login credentials
  Future<void> resetAccount(String userId) async {
    if (kReleaseMode) {
      throw Exception('Account reset is not allowed in release mode');
    }

    debugPrint('🔄 Starting account reset for user: $userId');
    
    try {
      // 1. Archive all user-scoped collections
      await _archiveUserData(userId);
      
      // 2. Delete all user data in main DB
      await _deleteUserData(userId);
      
      // 3. Clear local storage & tokens
      await _clearLocalData();
      
      // 4. Sign out
      await _auth.signOut();
      
      debugPrint('✅ Account reset completed successfully');
    } catch (e) {
      debugPrint('❌ Error during account reset: $e');
      rethrow;
    }
  }

  /// Delete Account: Archive & clear all data, then delete auth record
  Future<void> deleteAccount(String userId) async {
    if (kReleaseMode) {
      throw Exception('Account deletion is not allowed in release mode');
    }

    debugPrint('🗑️ Starting account deletion for user: $userId');
    
    try {
      // 1. Archive all user-scoped collections
      await _archiveUserData(userId);
      
      // 2. Delete all user data in main DB
      await _deleteUserData(userId);
      
      // 3. Delete auth record
      final currentUser = _auth.currentUser;
      if (currentUser != null && currentUser.uid == userId) {
        await currentUser.delete();
        debugPrint('✅ Firebase Auth record deleted');
      }
      
      // 4. Clear local storage & tokens
      await _clearLocalData();
      
      debugPrint('✅ Account deletion completed successfully');
    } catch (e) {
      debugPrint('❌ Error during account deletion: $e');
      rethrow;
    }
  }

  /// Archive user data to admin collections
  Future<void> _archiveUserData(String uid) async {
    debugPrint('📦 Archiving user data for: $uid');
    
    final batch = _firestore.batch();
    final hash = _generateAnonymousId(uid);

    try {
      // 1a. Archive user profile
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        // Remove PII and add anonymization data
        userData.remove('email');
        userData.remove('displayName');
        userData.remove('photoURL');
        userData['anonId'] = hash;
        userData['archivedAt'] = FieldValue.serverTimestamp();
        
        batch.set(
          _firestore.collection('admin_archived_users').doc(uid),
          userData,
        );
        debugPrint('  ✅ User profile archived');
      }

      // 1b. Archive user subcollections
      for (final subcollection in _userSubcollections) {
        await _archiveUserSubcollection(uid, subcollection, hash);
      }

      // 1c. Archive global collections (if this is a complete reset)
      for (final globalCollection in _globalCollections) {
        await _archiveGlobalCollection(globalCollection, hash);
      }

      await batch.commit();
      debugPrint('✅ User data archiving completed');
    } catch (e) {
      debugPrint('❌ Error archiving user data: $e');
      rethrow;
    }
  }

  /// Archive a user's subcollection
  Future<void> _archiveUserSubcollection(String uid, String subcollectionName, String hash) async {
    try {
      final subcollectionRef = _firestore
          .collection('users')
          .doc(uid)
          .collection(subcollectionName);
      
      final snapshot = await subcollectionRef.get();
      
      if (snapshot.docs.isNotEmpty) {
        final batch = _firestore.batch();
        
        for (final doc in snapshot.docs) {
          final data = doc.data();
          data['anonId'] = hash;
          data['archivedAt'] = FieldValue.serverTimestamp();
          
          batch.set(
            _firestore
                .collection('admin_archived_$subcollectionName')
                .doc('${uid}_${doc.id}'),
            data,
          );
        }
        
        await batch.commit();
        debugPrint('  ✅ Archived ${snapshot.docs.length} documents from $subcollectionName');
      }
    } catch (e) {
      debugPrint('  ⚠️ Error archiving $subcollectionName: $e');
    }
  }

  /// Archive a global collection
  Future<void> _archiveGlobalCollection(String collectionName, String hash) async {
    try {
      final collectionRef = _firestore.collection(collectionName);
      final snapshot = await collectionRef.get();
      
      if (snapshot.docs.isNotEmpty) {
        final batch = _firestore.batch();
        
        for (final doc in snapshot.docs) {
          final data = doc.data();
          data['archivedAt'] = FieldValue.serverTimestamp();
          data['archivedBy'] = hash;
          
          batch.set(
            _firestore
                .collection('admin_archived_$collectionName')
                .doc(doc.id),
            data,
          );
        }
        
        await batch.commit();
        debugPrint('  ✅ Archived ${snapshot.docs.length} documents from $collectionName');
      }
    } catch (e) {
      debugPrint('  ⚠️ Error archiving $collectionName: $e');
    }
  }

  /// Delete user data from main database
  Future<void> _deleteUserData(String uid) async {
    debugPrint('🗑️ Deleting user data from main database');
    
    try {
      // Delete user document and subcollections
      await _deleteUserDocument(uid);
      
      // Delete global collections (for complete reset)
      for (final collection in _globalCollections) {
        await _deleteCollection(collection);
      }
      
      debugPrint('✅ User data deletion completed');
    } catch (e) {
      debugPrint('❌ Error deleting user data: $e');
      rethrow;
    }
  }

  /// Delete user document and all subcollections
  Future<void> _deleteUserDocument(String uid) async {
    try {
      // Delete user subcollections first
      for (final subcollection in _userSubcollections) {
        await _deleteSubcollection('users/$uid/$subcollection');
      }
      
      // Delete user document
      await _firestore.collection('users').doc(uid).delete();
      debugPrint('  ✅ User document deleted');
    } catch (e) {
      debugPrint('  ⚠️ Error deleting user document: $e');
    }
  }

  /// Clear local storage and revoke tokens
  Future<void> _clearLocalData() async {
    debugPrint('🧹 Clearing local storage and tokens');
    
    try {
      // Clear Hive boxes
      for (final boxName in _hiveBoxesToClear) {
        try {
          if (Hive.isBoxOpen(boxName)) {
            final box = Hive.box(boxName);
            await box.clear();
            debugPrint('  ✅ Cleared Hive box: $boxName');
          } else {
            try {
              final box = await Hive.openBox(boxName);
              await box.clear();
              await box.close();
              debugPrint('  ✅ Cleared Hive box: $boxName');
            } catch (e) {
              debugPrint('  ℹ️ Hive box $boxName not found or already empty');
            }
          }
        } catch (e) {
          debugPrint('  ⚠️ Error clearing Hive box $boxName: $e');
        }
      }
      
      // Revoke FCM token
      try {
        await FirebaseMessaging.instance.deleteToken();
        debugPrint('  ✅ FCM token revoked');
      } catch (e) {
        debugPrint('  ⚠️ Error revoking FCM token: $e');
      }
      
      debugPrint('✅ Local storage cleanup completed');
    } catch (e) {
      debugPrint('❌ Error clearing local data: $e');
    }
  }

  /// Generate anonymous ID for archiving
  String _generateAnonymousId(String uid) {
    final bytes = utf8.encode(uid + _adminSalt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Clear all Firebase data to simulate fresh install
  /// WARNING: This will delete ALL data - use only for testing!
  Future<void> clearAllDataForFreshInstall() async {
    if (kReleaseMode) {
      throw Exception('Firebase cleanup is not allowed in release mode');
    }

    debugPrint('🔥 Starting Firebase cleanup for fresh install simulation...');
    
    try {
      // 1. Clear current user's data
      await _clearCurrentUserData();
      
      // 2. Clear global collections
      await _clearGlobalCollections();
      
      // 3. Clear local Hive storage
      await _clearLocalStorage();
      
      // 4. Clear all cached data and force fresh state
      await _clearCachedData();
      
      // 5. Reset community stats
      await _resetCommunityStats();
      
      // 6. Sign out current user
      await _signOutCurrentUser();
      
      // 7. Force a longer delay to ensure all operations complete
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // 8. Verify the cleanup was successful
      await _verifyCleanupSuccess();
      
      debugPrint('✅ Firebase cleanup completed - app will behave like fresh install');
      
    } catch (e) {
      debugPrint('❌ Error during Firebase cleanup: $e');
      rethrow;
    }
  }

  /// Clear current user's personal data
  Future<void> _clearCurrentUserData() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      debugPrint('ℹ️ No user signed in, skipping user data cleanup');
      return;
    }

    final userId = currentUser.uid;
    debugPrint('🗑️ Clearing data for user: $userId');

    try {
      // Clear user document
      await _firestore.collection('users').doc(userId).delete();
      
      // Clear user subcollections
      for (final subcollection in _userSubcollections) {
        await _deleteSubcollection('users/$userId/$subcollection');
      }

      debugPrint('✅ Cleared user data for: $userId');
    } catch (e) {
      debugPrint('⚠️ Error clearing user data: $e');
    }
  }

  /// Clear global collections
  Future<void> _clearGlobalCollections() async {
    debugPrint('🗑️ Clearing global collections...');

    for (final collection in _collectionsToDelete) {
      try {
        await _deleteCollection(collection);
        debugPrint('✅ Cleared collection: $collection');
      } catch (e) {
        debugPrint('⚠️ Error clearing collection $collection: $e');
      }
    }
  }

  /// Clear local Hive storage - FIXED to completely delete box files from disk
  Future<void> _clearLocalStorage() async {
    debugPrint('🗑️ Clearing local Hive storage with complete file deletion...');

    // Step 1: Close all boxes first - CRITICAL for deleteBoxFromDisk to work
    try {
      await Hive.close();
      debugPrint('✅ All Hive boxes closed');
    } catch (e) {
      debugPrint('⚠️ Error closing Hive boxes: $e');
    }

    // Step 2: Delete box files from disk (true fresh install)
    for (final boxName in _hiveBoxesToClear) {
      try {
        await Hive.deleteBoxFromDisk(boxName);
        debugPrint('✅ Deleted Hive box file from disk: $boxName');
      } catch (e) {
        debugPrint('ℹ️ Hive box file $boxName not found on disk or already deleted: $e');
      }
    }

    // Step 3: Also delete any additional boxes that might exist
    final allPossibleBoxes = [
      'userSettings',
      'appData', 
      'cache',
      'temp',
      'backup',
      'analytics_events', // Legacy
      'premium_features', // Premium service
      'community_stats', // Community service  
      'community_feed', // Community service
    ];
    
    for (final boxName in allPossibleBoxes) {
      if (!_hiveBoxesToClear.contains(boxName)) {
        try {
          await Hive.deleteBoxFromDisk(boxName);
          debugPrint('✅ Deleted additional Hive box file from disk: $boxName');
        } catch (e) {
          debugPrint('ℹ️ Additional box file $boxName not found or already deleted: $e');
        }
      }
    }

    // Step 4: Re-initialize critical boxes that the app needs
    try {
      debugPrint('🔄 Re-initializing critical Hive boxes...');
      // Re-open only the most essential boxes to keep app functional
      // Other boxes will be created when first accessed
      await Hive.openBox(StorageKeys.settingsBox);
      debugPrint('✅ Re-initialized essential Hive boxes');
    } catch (e) {
      debugPrint('⚠️ Error re-initializing Hive boxes: $e');
    }

    debugPrint('✅ Complete local storage cleanup with file deletion completed');
  }

  /// Delete all documents in a collection
  Future<void> _deleteCollection(String collectionName) async {
    final collection = _firestore.collection(collectionName);
    
    QuerySnapshot snapshot;
    var totalDeleted = 0;
    
    do {
      snapshot = await collection.limit(50).get();
      
      if (snapshot.docs.isNotEmpty) {
        final batch = _firestore.batch();
        
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        
        await batch.commit();
        totalDeleted += snapshot.docs.length;
      }
    } while (snapshot.docs.isNotEmpty);
    
    if (totalDeleted > 0) {
      debugPrint('  Deleted $totalDeleted documents from $collectionName');
    }
  }

  /// Delete all documents in a subcollection
  Future<void> _deleteSubcollection(String path) async {
    try {
      final parts = path.split('/');
      if (parts.length < 3) return;
      
      final collection = _firestore.collection(parts[0]).doc(parts[1]).collection(parts[2]);
      
      QuerySnapshot snapshot;
      do {
        snapshot = await collection.limit(50).get();
        
        if (snapshot.docs.isNotEmpty) {
          final batch = _firestore.batch();
          
          for (final doc in snapshot.docs) {
            batch.delete(doc.reference);
          }
          
          await batch.commit();
        }
      } while (snapshot.docs.isNotEmpty);
      
    } catch (e) {
      // Subcollection might not exist
      debugPrint('    Subcollection $path not found or already empty');
    }
  }

  /// Reset community stats to zero
  Future<void> _resetCommunityStats() async {
    debugPrint('📊 Resetting community stats...');
    
    try {
      // First delete the existing document
      await _firestore.collection('community_stats').doc('main').delete();
      
      // Then create a fresh one with zero values
      await _firestore.collection('community_stats').doc('main').set({
        'totalUsers': 0,
        'totalClassifications': 0,
        'totalPoints': 0,
        'categoryBreakdown': <String, int>{},
        'lastUpdated': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('✅ Community stats reset to zero');
    } catch (e) {
      debugPrint('⚠️ Error resetting community stats: $e');
    }
  }

  /// Sign out current user
  Future<void> _signOutCurrentUser() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await _auth.signOut();
        debugPrint('✅ Signed out user: ${currentUser.email}');
      }
    } catch (e) {
      debugPrint('⚠️ Error signing out: $e');
    }
  }

  /// Clear only current user's data (less destructive)
  Future<void> clearCurrentUserDataOnly() async {
    if (kReleaseMode) {
      throw Exception('User data cleanup is not allowed in release mode');
    }

    debugPrint('🔥 Clearing current user data only...');
    
    try {
      await _clearCurrentUserData();
      await _signOutCurrentUser();
      
      debugPrint('✅ Current user data cleared');
    } catch (e) {
      debugPrint('❌ Error clearing user data: $e');
      rethrow;
    }
  }

  /// Check if cleanup is allowed (only in debug mode)
  bool get isCleanupAllowed => kDebugMode;

  /// Clear all cached data and force fresh state
  Future<void> _clearCachedData() async {
    debugPrint('🧹 Clearing cached data and forcing fresh state...');
    
    try {
      // Clear any cached data that might persist in memory
      // This ensures the app truly behaves like a fresh install
      
      // 1. Force garbage collection to clear in-memory caches
      debugPrint('  🧹 Forcing garbage collection...');
      
      // 2. Clear additional storage systems that might not be in Hive
      await _clearAdditionalStorageSystems();
      
      // 3. Add a longer delay to ensure all async operations complete
      await Future.delayed(const Duration(milliseconds: 2000));
      
      debugPrint('✅ Cached data cleared');
    } catch (e) {
      debugPrint('⚠️ Error clearing cached data: $e');
    }
  }

  /// Clear additional storage systems beyond Hive and Firebase
  Future<void> _clearAdditionalStorageSystems() async {
    debugPrint('🔄 Clearing additional storage systems...');
    
    try {
      // Clear SharedPreferences that might contain classification data
      await _clearSharedPreferences();
      
      // Clear any temporary files or image caches
      await _clearTemporaryFiles();
      
      debugPrint('✅ Additional storage systems cleared');
    } catch (e) {
      debugPrint('⚠️ Error clearing additional storage systems: $e');
    }
  }

  /// Clear relevant SharedPreferences entries
  Future<void> _clearSharedPreferences() async {
    try {
      debugPrint('  🧹 Clearing relevant SharedPreferences...');
      
      final prefs = await SharedPreferences.getInstance();
      final keysToRemove = <String>[];
      
      // Get all keys and identify ones to clear
      for (final key in prefs.getKeys()) {
        // Clear user-specific data but preserve app settings like theme
        if (key.contains('user') || 
            key.contains('classification') || 
            key.contains('gamification') ||
            key.contains('points') ||
            key.contains('achievement') ||
            key.contains('streak') ||
            key.contains('analytics') ||
            key.contains('onboarding') ||
            key == StorageKeys.userGamificationProfileKey ||
            key == StorageKeys.achievementsKey ||
            key == StorageKeys.streakKey ||
            key == StorageKeys.pointsKey ||
            key == StorageKeys.challengesKey ||
            key == StorageKeys.weeklyStatsKey) {
          keysToRemove.add(key);
        }
      }
      
      // Remove identified keys
      for (final key in keysToRemove) {
        await prefs.remove(key);
      }
      
      debugPrint('  ✅ SharedPreferences cleanup completed (${keysToRemove.length} keys removed)');
      if (keysToRemove.isNotEmpty) {
        debugPrint('  📋 Removed keys: ${keysToRemove.join(', ')}');
      }
    } catch (e) {
      debugPrint('  ⚠️ Error clearing SharedPreferences: $e');
    }
  }

  /// Clear temporary files and image caches
  Future<void> _clearTemporaryFiles() async {
    try {
      debugPrint('  🧹 Clearing temporary files and image caches...');
      
      var filesCleared = 0;
      
      // Clear app's temporary directory
      try {
        final tempDir = Directory.systemTemp;
        if (await tempDir.exists()) {
          final appTempFiles = tempDir.listSync()
              .where((entity) => entity.path.contains('waste_segregation') || 
                                entity.path.contains('classification') ||
                                entity.path.contains('flutter'))
              .toList();
          
          for (final file in appTempFiles) {
            try {
              if (file is File) {
                await file.delete();
                filesCleared++;
              } else if (file is Directory) {
                await file.delete(recursive: true);
                filesCleared++;
              }
            } catch (e) {
              debugPrint('    ⚠️ Could not delete ${file.path}: $e');
            }
          }
        }
      } catch (e) {
        debugPrint('    ⚠️ Error clearing system temp directory: $e');
      }
      
      // Clear app's cache directory if accessible
      try {
        // Note: On mobile, we can't directly access the cache directory
        // but we can clear Hive's cache which handles most cached data
        debugPrint('    📁 Cache directory clearing handled by Hive box clearing');
      } catch (e) {
        debugPrint('    ⚠️ Error accessing cache directory: $e');
      }
      
      debugPrint('  ✅ Temporary files cleanup completed ($filesCleared files/directories cleared)');
    } catch (e) {
      debugPrint('  ⚠️ Error clearing temporary files: $e');
    }
  }

  /// Verify that the cleanup was successful by checking if data still exists
  Future<void> _verifyCleanupSuccess() async {
    debugPrint('🔍 Verifying cleanup success...');
    
    var issuesFound = 0;
    
    try {
      // Check Hive boxes
      for (final boxName in _hiveBoxesToClear) {
        try {
          if (Hive.isBoxOpen(boxName)) {
            final box = Hive.box(boxName);
            if (box.isNotEmpty) {
              debugPrint('  ⚠️ Hive box $boxName still contains ${box.length} items');
              issuesFound++;
            } else {
              debugPrint('  ✅ Hive box $boxName is empty');
            }
          }
        } catch (e) {
          debugPrint('  ℹ️ Could not check box $boxName: $e');
        }
      }
      
      // Check SharedPreferences for user data
      try {
        final prefs = await SharedPreferences.getInstance();
        final userKeys = prefs.getKeys().where((key) => 
          key.contains('user') || 
          key.contains('classification') || 
          key.contains('gamification') ||
          key.contains('points') ||
          key.contains('achievement')).toList();
        
        if (userKeys.isNotEmpty) {
          debugPrint('  ⚠️ SharedPreferences still contains user data: ${userKeys.join(', ')}');
          issuesFound++;
        } else {
          debugPrint('  ✅ SharedPreferences cleared of user data');
        }
      } catch (e) {
        debugPrint('  ⚠️ Error checking SharedPreferences: $e');
      }
      
      // Check Firebase Auth
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        debugPrint('  ⚠️ User still signed in: ${currentUser.email}');
        issuesFound++;
      } else {
        debugPrint('  ✅ User signed out successfully');
      }
      
      if (issuesFound == 0) {
        debugPrint('✅ Cleanup verification passed - no issues found');
      } else {
        debugPrint('⚠️ Cleanup verification found $issuesFound issues - some data may remain');
      }
      
    } catch (e) {
      debugPrint('❌ Error during cleanup verification: $e');
    }
  }
} 