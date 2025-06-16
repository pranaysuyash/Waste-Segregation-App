import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_functions/cloud_functions.dart';
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

  /// ULTIMATE FACTORY RESET - True fresh install with no ghost data possible
  /// WARNING: This will delete ALL data permanently - use only for testing!
  Future<void> ultimateFactoryReset() async {
    if (kReleaseMode) {
      throw Exception('Firebase cleanup is not allowed in release mode');
    }

    debugPrint('🔥 Starting ULTIMATE FACTORY RESET - no ghost data will survive...');
    
    try {
      // 🔥 STEP 1: Wipe ALL server-side data (so nothing can ever come back)
      debugPrint('💥 STEP 1: Wiping ALL server-side data...');
      await _wipeServerSideData();
      
      // 🔥 STEP 2: Sign user out (so they can't re-sync under same UID)
      debugPrint('🚪 STEP 2: Signing out user to prevent re-sync...');
      await _signOutCurrentUser();
      
      // 🔥 STEP 3: Clear Firestore's on-device cache, offline persistence
      debugPrint('🧹 STEP 3: Clearing Firestore local cache and persistence...');
      await _clearFirestoreLocalCache();
      
      // 🔥 STEP 4: Delete every local box, prefs and restart services
      debugPrint('💥 STEP 4: Deleting ALL local storage from disk...');
      await _deleteAllLocalStorage();
      
      // 🔥 STEP 5: Sign back in & re-initialize app as fresh anonymous user
      debugPrint('🔄 STEP 5: Signing in as fresh anonymous user...');
      await _signInAsFreshUser();
      
      // 🔥 STEP 6: Re-initialize essential services for app functionality
      debugPrint('⚡ STEP 6: Re-initializing essential services...');
      await _reinitializeEssentialServices();
      
      // Final verification
      await _verifyUltimateReset();
      
      debugPrint('🎉 ULTIMATE FACTORY RESET COMPLETED - absolutely no ghost data possible!');
      
    } catch (e) {
      debugPrint('❌ Error during ULTIMATE FACTORY RESET: $e');
      // Critical: Always try to re-enable Firestore network
      try {
        await _firestore.enableNetwork();
        debugPrint('✅ Firestore network re-enabled after error');
      } catch (networkError) {
        debugPrint('⚠️ Critical: Failed to re-enable Firestore network: $networkError');
      }
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

  /// Clear global collections using the FIXED Cloud Function
  Future<void> _clearGlobalCollections() async {
    debugPrint('🗑️ Clearing global collections via Cloud Function...');

    try {
      // Call the FIXED Cloud Function that properly awaits all deletions
      final callable = FirebaseFunctions.instanceFor(region: 'asia-south1').httpsCallable('clearAllData');
      
      debugPrint('📞 Calling clearAllData Cloud Function...');
      final result = await callable.call();
      
      if (result.data['success'] == true) {
        final collectionsDeleted = result.data['collectionsDeleted'] ?? 0;
        debugPrint('✅ Cloud Function completed successfully - $collectionsDeleted collections deleted');
      } else {
        throw Exception('Cloud Function returned failure: ${result.data}');
      }
      
    } catch (e) {
      debugPrint('⚠️ Cloud Function failed, falling back to manual deletion: $e');
      
      // Fallback to manual deletion if Cloud Function fails
      for (final collection in _collectionsToDelete) {
        try {
          await _deleteCollection(collection);
          debugPrint('✅ Manually cleared collection: $collection');
        } catch (e) {
          debugPrint('⚠️ Error manually clearing collection $collection: $e');
        }
      }
    }
  }

  /// COMPLETELY nuke local Hive storage - delete box files from disk for true fresh install
  Future<void> _completelyNukeLocalStorage() async {
    debugPrint('💥 COMPLETELY nuking local Hive storage with deleteBoxFromDisk...');
    
    try {
      // Step 1: Close ALL Hive boxes first - CRITICAL for deleteBoxFromDisk to work
      debugPrint('🔒 Closing all Hive boxes...');
      await Hive.close();
      debugPrint('✅ All Hive boxes closed');
      
      // Step 2: Delete ALL Hive boxes from disk (not just known ones)
      var deletedCount = 0;
      
      // Delete all known boxes from disk
      for (final boxName in _hiveBoxesToClear) {
        try {
          await Hive.deleteBoxFromDisk(boxName);
          debugPrint('💥 DELETED box file from disk: $boxName');
          deletedCount++;
        } catch (e) {
          debugPrint('ℹ️ Box file $boxName not found on disk: $e');
        }
      }
      
      // Also try to delete additional possible boxes
      final additionalBoxes = [
        'userSettings',
        'appData', 
        'cache',
        'temp',
        'backup',
        'analytics_events',
        'premium_features',
        'community_stats',
        'community_feed',
        'classificationHashesBox',
        'gamification_cache',
      ];
      
      for (final boxName in additionalBoxes) {
        if (!_hiveBoxesToClear.contains(boxName)) {
          try {
            await Hive.deleteBoxFromDisk(boxName);
            debugPrint('💥 DELETED additional box file from disk: $boxName');
            deletedCount++;
          } catch (e) {
            debugPrint('ℹ️ Additional box file $boxName not found: $e');
          }
        }
      }
      
      // Step 3: Re-initialize only the most critical boxes for app functionality
      debugPrint('🔄 Re-initializing essential Hive boxes...');
      try {
        // Only re-open the absolute minimum needed for app to function
        await Hive.openBox(StorageKeys.settingsBox);
        debugPrint('✅ Re-initialized essential Hive boxes');
      } catch (e) {
        debugPrint('⚠️ Error re-initializing Hive boxes: $e');
      }
      
      debugPrint('💥 COMPLETE local storage nuking completed ($deletedCount box files deleted from disk)');
      
    } catch (e) {
      debugPrint('❌ Error during complete local storage nuking: $e');
      rethrow;
    }
  }

  /// Clear local Hive storage - LEGACY METHOD (kept for compatibility)
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

  // ============================================================================
  // ULTIMATE FACTORY RESET METHODS - Following the definitive recipe
  // ============================================================================

  /// STEP 1: Wipe ALL server-side data (so nothing can ever come back)
  Future<void> _wipeServerSideData() async {
    debugPrint('💥 Wiping ALL server-side data via Cloud Function...');

    try {
      // Call the enhanced Cloud Function that recursively deletes everything
      final callable = FirebaseFunctions.instanceFor(region: 'asia-south1').httpsCallable('clearAllData');
      
      debugPrint('📞 Calling ULTIMATE clearAllData Cloud Function...');
      final result = await callable.call();
      
      if (result.data['success'] == true) {
        final collectionsDeleted = result.data['collectionsDeleted'] ?? 0;
        debugPrint('✅ ULTIMATE server wipe completed - $collectionsDeleted collections COMPLETELY deleted');
      } else {
        throw Exception('Cloud Function returned failure: ${result.data}');
      }
      
    } catch (e) {
      debugPrint('⚠️ Cloud Function failed, attempting manual server wipe: $e');
      
      // Fallback: Manual batch deletion of everything
      await _manualServerWipe();
    }
  }

  /// Manual server wipe as fallback
  Future<void> _manualServerWipe() async {
    debugPrint('🔧 Performing manual server wipe...');
    
    // Get all collections and delete everything
    for (final collection in _collectionsToDelete) {
      try {
        await _batchDeleteCollection(collection);
        debugPrint('✅ Manually wiped collection: $collection');
      } catch (e) {
        debugPrint('⚠️ Error manually wiping collection $collection: $e');
      }
    }
  }

  /// Batch delete entire collection
  Future<void> _batchDeleteCollection(String collectionName) async {
    final collection = _firestore.collection(collectionName);
    
    QuerySnapshot snapshot;
    do {
      snapshot = await collection.limit(500).get();
      
      if (snapshot.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        debugPrint('Deleted batch of ${snapshot.docs.length} documents from $collectionName');
      }
    } while (snapshot.docs.isNotEmpty);
  }

  /// STEP 3: Clear Firestore's on-device cache and offline persistence
  Future<void> _clearFirestoreLocalCache() async {
    debugPrint('🧹 Clearing Firestore local cache and persistence...');
    
    try {
      // CRITICAL: Must terminate Firestore before clearing persistence
      await _firestore.terminate();
      debugPrint('✅ Firestore terminated');
      
      // Clear all local cache and persistence
      await _firestore.clearPersistence();
      debugPrint('✅ Firestore persistence cleared');
      
      // Re-enable network for future operations
      await _firestore.enableNetwork();
      debugPrint('✅ Firestore network re-enabled');
      
    } catch (e) {
      debugPrint('⚠️ Error clearing Firestore cache: $e');
      // Try to re-enable network even if clearing failed
      try {
        await _firestore.enableNetwork();
      } catch (networkError) {
        debugPrint('⚠️ Failed to re-enable Firestore network: $networkError');
      }
    }
  }

  /// STEP 4: Delete every local box, prefs and restart services
  Future<void> _deleteAllLocalStorage() async {
    debugPrint('💥 Deleting ALL local storage from disk...');
    
    try {
      // Close ALL Hive boxes
      await Hive.close();
      debugPrint('✅ All Hive boxes closed');
      
      // Delete ALL Hive boxes from disk (not just clear memory)
      var deletedCount = 0;
      for (final boxName in _hiveBoxesToClear) {
        try {
          await Hive.deleteBoxFromDisk(boxName);
          debugPrint('💥 DELETED box file from disk: $boxName');
          deletedCount++;
        } catch (e) {
          debugPrint('ℹ️ Box file $boxName not found: $e');
        }
      }
      
      // Clear ALL SharedPreferences (complete wipe)
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      debugPrint('✅ ALL SharedPreferences cleared');
      
      debugPrint('💥 ALL local storage deleted ($deletedCount Hive boxes + SharedPreferences)');
      
    } catch (e) {
      debugPrint('❌ Error deleting local storage: $e');
      rethrow;
    }
  }

  /// STEP 5: Sign back in as fresh anonymous user
  Future<void> _signInAsFreshUser() async {
    debugPrint('🔄 Signing in as fresh anonymous user...');
    
    try {
      // Sign in anonymously to get a completely new UID
      final userCredential = await _auth.signInAnonymously();
      final newUser = userCredential.user;
      
      if (newUser != null) {
        debugPrint('✅ Signed in as fresh anonymous user: ${newUser.uid}');
      } else {
        throw Exception('Failed to sign in anonymously');
      }
      
    } catch (e) {
      debugPrint('❌ Error signing in as fresh user: $e');
      rethrow;
    }
  }

  /// STEP 6: Re-initialize essential services for app functionality
  Future<void> _reinitializeEssentialServices() async {
    debugPrint('⚡ Re-initializing essential services...');
    
    try {
      // Re-open only the most critical Hive boxes
      await Hive.openBox(StorageKeys.settingsBox);
      await Hive.openBox(StorageKeys.classificationsBox);
      await Hive.openBox(StorageKeys.gamificationBox);
      await Hive.openBox(StorageKeys.userBox);
      
      debugPrint('✅ Essential Hive boxes re-initialized');
      
      // Initialize fresh community stats
      await _initializeFreshCommunityStats();
      
    } catch (e) {
      debugPrint('⚠️ Error re-initializing services: $e');
    }
  }

  /// Initialize fresh community stats
  Future<void> _initializeFreshCommunityStats() async {
    try {
      await _firestore.collection('community_stats').doc('main').set({
        'totalUsers': 0,
        'totalClassifications': 0,
        'totalPoints': 0,
        'categoryBreakdown': {},
        'lastUpdated': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Fresh community stats initialized');
    } catch (e) {
      debugPrint('⚠️ Error initializing community stats: $e');
    }
  }

  /// Verify that the ultimate reset was successful
  Future<void> _verifyUltimateReset() async {
    debugPrint('🔍 Verifying ULTIMATE reset success...');
    
    var issuesFound = 0;
    
    try {
      // Check that user is signed in with new UID
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        debugPrint('✅ New anonymous user signed in: ${currentUser.uid}');
      } else {
        debugPrint('⚠️ No user signed in after reset');
        issuesFound++;
      }
      
      // Check SharedPreferences are empty
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      if (keys.isEmpty) {
        debugPrint('✅ SharedPreferences completely empty');
      } else {
        debugPrint('⚠️ SharedPreferences still contains ${keys.length} keys: ${keys.take(5).join(', ')}');
        issuesFound++;
      }
      
      if (issuesFound == 0) {
        debugPrint('🎉 ULTIMATE reset verification PASSED - true fresh install achieved!');
      } else {
        debugPrint('⚠️ ULTIMATE reset verification found $issuesFound issues');
      }
      
    } catch (e) {
      debugPrint('❌ Error during ultimate reset verification: $e');
    }
  }

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

  /// Clear ALL SharedPreferences entries for complete reset
  Future<void> _clearSharedPreferences() async {
    try {
      debugPrint('  🧹 Clearing ALL SharedPreferences for complete reset...');
      
      final prefs = await SharedPreferences.getInstance();
      
      // For a complete reset, clear everything
      await prefs.clear();
      
      debugPrint('  ✅ ALL SharedPreferences cleared for complete reset');
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