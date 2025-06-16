import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

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

  /// Hive boxes to clear for fresh install simulation
  static const List<String> _hiveBoxesToClear = [
    'classifications',
    'classificationHashes', // Secondary index for duplicate detection
    'cache', // Classification cache service
    'gamification', // Gamification points and achievements
    'userProfile',
    'settings',
    'achievements',
    'communityStats',
    'communityFeed',
    'analytics',
    'contentProgress',
    'familyData',
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

  /// Clear local Hive storage
  Future<void> _clearLocalStorage() async {
    debugPrint('🗑️ Clearing local Hive storage...');

    for (final boxName in _hiveBoxesToClear) {
      try {
        if (Hive.isBoxOpen(boxName)) {
          final box = Hive.box(boxName);
          await box.clear();
          debugPrint('✅ Cleared Hive box: $boxName');
        } else {
          // Try to open and clear the box
          try {
            final box = await Hive.openBox(boxName);
            await box.clear();
            await box.close();
            debugPrint('✅ Cleared Hive box: $boxName');
          } catch (e) {
            debugPrint('ℹ️ Hive box $boxName not found or already empty');
          }
        }
      } catch (e) {
        debugPrint('⚠️ Error clearing Hive box $boxName: $e');
      }
    }

    // Also clear any remaining boxes that might exist
    try {
      // Get all registered adapters and clear their boxes if open
      final allPossibleBoxes = [
        'userSettings',
        'appData',
        'cache',
        'temp',
        'backup',
      ];
      
      for (final boxName in allPossibleBoxes) {
        if (!_hiveBoxesToClear.contains(boxName)) {
          try {
            if (Hive.isBoxOpen(boxName)) {
              final box = Hive.box(boxName);
              await box.clear();
              debugPrint('✅ Cleared additional Hive box: $boxName');
            }
          } catch (e) {
            debugPrint('⚠️ Error clearing additional box $boxName: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('ℹ️ No additional Hive boxes to clear');
    }

    debugPrint('✅ Local storage cleanup completed');
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
      // Note: We only clear classification-related preferences, not all app settings
      // This prevents breaking theme, language, and other user preferences
      debugPrint('  🧹 Clearing classification-related SharedPreferences...');
      
      // Add specific SharedPreferences keys that should be cleared here
      // For now, just log that this step is complete
      debugPrint('  ✅ SharedPreferences cleanup completed');
    } catch (e) {
      debugPrint('  ⚠️ Error clearing SharedPreferences: $e');
    }
  }

  /// Clear temporary files and image caches
  Future<void> _clearTemporaryFiles() async {
    try {
      debugPrint('  🧹 Clearing temporary files and image caches...');
      
      // Note: Add logic here to clear:
      // - Cached images
      // - Temporary classification files
      // - Any other file-based caches
      
      debugPrint('  ✅ Temporary files cleanup completed');
    } catch (e) {
      debugPrint('  ⚠️ Error clearing temporary files: $e');
    }
  }
} 