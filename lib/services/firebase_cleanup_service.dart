import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import 'package:waste_segregation_app/services/gamification_service.dart';
import 'package:waste_segregation_app/services/community_service.dart';
import 'package:waste_segregation_app/services/storage_service.dart';
import 'package:waste_segregation_app/services/enhanced_storage_service.dart';
import 'package:waste_segregation_app/services/cloud_storage_service.dart';
import 'package:waste_segregation_app/utils/waste_app_logger.dart';

/// Service to clear Firebase data for testing fresh install experience
/// This should only be used in development/testing environments
class FirebaseCleanupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// A flag to indicate that a fresh install has just been performed.
  /// App initialization logic can check this flag to prevent automatic
  /// data sync from repopulating wiped data.
  static bool didPerformFreshInstall = false;

  static const List<String> _userCollections = [
    'classifications',
    'profiles',
    'gamification_profiles',
    'analytics_events',
    'feedback',
    'content_progress',
    'classification_feedback',
    'user_contributions',
  ];

  static const List<String> _globalCollections = [
    'community_feed',
    'leaderboard_allTime',
    'community_stats',
    'disposal_instructions',
    'disposal_locations',
  ];

  /// Collections that need direct document deletion (not query-based)
  static const List<String> _directUserCollections = [
    'users',
  ];

  static final List<String> _hiveBoxesToNuke = [
    StorageKeys.classificationsBox,
    StorageKeys.gamificationBox,
    StorageKeys.userBox,
    StorageKeys.settingsBox,
    StorageKeys.cacheBox,
    StorageKeys.familiesBox,
    StorageKeys.invitationsBox,
    StorageKeys.classificationFeedbackBox,
  ];

  /// Performs a complete data wipe for the current user, providing a "fresh install" experience.
  /// This function is destructive and irreversible.
  Future<void> clearAllDataForFreshInstall() async {
    final user = _auth.currentUser;
    if (user == null) {
      WasteAppLogger.info('No user is signed in. Aborting fresh install.');
      return;
    }

    WasteAppLogger.info('🔥 Starting fresh install process for user: ${user.uid}');
    didPerformFreshInstall = false; // Reset flag at start

    try {
      // 1. Wipe Firestore data (cloud and local cache)
      await _wipeCloudAndFirestoreCache(user.uid);

      // 2. Erase all local Hive data from disk
      await _resetLocalHive();

      // 3. Clear SharedPreferences
      await _clearSharedPrefs();

      // 4. Delete user account from Firebase Auth
      await user.delete();
      WasteAppLogger.info('✅ User account deleted from Firebase Auth.');

      // 5. Set persistent flag to prevent immediate re-sync on next launch
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('justDidFreshInstall', true);
      didPerformFreshInstall = true;
      WasteAppLogger.info('✅ Fresh install process completed successfully.');
    } catch (e, s) {
      WasteAppLogger.severe('❌ Error during fresh install process: $e');
      WasteAppLogger.info('Stack trace: $s');
      // Even if it fails, try to leave the app in a somewhat clean state
      didPerformFreshInstall = true;
      throw Exception('Failed to complete fresh install. Error: $e');
    }
  }

  Future<void> _wipeCloudAndFirestoreCache(String uid) async {
    WasteAppLogger.info('🔥 Wiping all Firestore documents for user: $uid');
    final batch = _firestore.batch();

    // Delete user-specific documents from various collections
    for (final collectionName in _userCollections) {
      final snapshot = await _firestore.collection(collectionName).where('userId', isEqualTo: uid).get();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      WasteAppLogger.info('  - Found and staged ${snapshot.size} docs for deletion in "$collectionName"');
    }

    // Delete direct user collections (document ID = userId)
    for (final collectionName in _directUserCollections) {
      try {
        final docRef = _firestore.collection(collectionName).doc(uid);
        final docSnapshot = await docRef.get();
        if (docSnapshot.exists) {
          batch.delete(docRef);
          WasteAppLogger.info('  - Staged deletion for doc "$uid" in "$collectionName"');
        }
      } catch (e) {
        WasteAppLogger.warning('Failed to delete from $collectionName: $e');
      }
    }

    // Delete user from global collections
    for (final collectionName in _globalCollections) {
      final docRef = _firestore.collection(collectionName).doc(uid);
      batch.delete(docRef);
      WasteAppLogger.info('  - Staged deletion for doc "$uid" in "$collectionName"');
    }

    await batch.commit();
    WasteAppLogger.info('✅ Batch delete committed to Firestore.');

    // Crucially, clear the local persistence to prevent re-hydration
    await _firestore.clearPersistence();
    WasteAppLogger.info('✅ Firestore local persistence cache cleared.');
  }

  Future<void> _resetLocalHive() async {
    WasteAppLogger.info('🔥 Resetting local Hive storage...');
    await Hive.close();
    for (final boxName in _hiveBoxesToNuke) {
      try {
        await Hive.deleteBoxFromDisk(boxName);
        WasteAppLogger.info('  - Deleted box: $boxName');
      } catch (e) {
        WasteAppLogger.info('  - Could not delete box $boxName (may not exist): $e');
      }
    }
    WasteAppLogger.info('✅ All Hive boxes deleted from disk.');

    // Re-initialize essential services to get the app back into a usable state
    WasteAppLogger.info('🔄 Re-initializing core services...');
    final storageService = EnhancedStorageService();
    final gamificationService = GamificationService(storageService, CloudStorageService(storageService));
    final communityService = CommunityService();

    await StorageService.initializeHive();
    await gamificationService.initGamification();
    await communityService.initCommunity();
    WasteAppLogger.info('✅ Core services re-initialized.');
  }

  Future<void> _clearSharedPrefs() async {
    WasteAppLogger.info('🔥 Clearing SharedPreferences...');
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    WasteAppLogger.info('✅ SharedPreferences cleared.');
  }

  /// [ADMIN-ONLY] Deletes all of a specific user's data from Firestore.
  /// This is a server-side operation and does not affect local device data.
  /// Throws an exception if the currently authenticated user is not an admin.
  Future<void> adminDeleteUser(String userIdToDelete) async {
    await _verifyCurrentUserIsAdmin();

    WasteAppLogger.info('🔥 [ADMIN] Deleting all Firestore data for user: $userIdToDelete');
    try {
      // Re-using the same Firestore deletion logic, but targeted at a specific user.
      await _wipeCloudAndFirestoreCache(userIdToDelete);
      WasteAppLogger.info('✅ [ADMIN] Successfully deleted all Firestore data for user: $userIdToDelete');
    } catch (e) {
      WasteAppLogger.severe('❌ [ADMIN] Error deleting data for user $userIdToDelete: $e');
      throw Exception('Failed to delete user data. Error: $e');
    }
  }

  Future<void> _verifyCurrentUserIsAdmin() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Admin action failed: No user is currently signed in.');
    }
    // In a real app, this would check for a custom claim.
    // For this project, we'll use the email as a simple check.
    const adminEmail = 'pranaysuyash@gmail.com';
    if (currentUser.email != adminEmail) {
      throw Exception('Admin action failed: User ${currentUser.email} is not an authorized admin.');
    }
    WasteAppLogger.info('🔑 Admin user verified: ${currentUser.email}');
  }
}
