import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../utils/constants.dart';

/// Service to clear Firebase data for testing fresh install experience
/// This should only be used in development/testing environments
class FirebaseCleanupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const List<String> _userSubcollections = [
    'classifications',
    'achievements',
    'settings',
    'analytics',
    'content_progress',
  ];

  static final List<String> _hiveBoxesToClear = [
    StorageKeys.classificationsBox,
    StorageKeys.gamificationBox,
    StorageKeys.userBox,
    StorageKeys.settingsBox,
    StorageKeys.cacheBox,
    StorageKeys.familiesBox,
    StorageKeys.invitationsBox,
    StorageKeys.classificationFeedbackBox,
    'classificationHashesBox',
    'analytics_events',
    'premium_features',
    'community_stats',
    'community_feed',
  ];
  
  /// Clears all cloud and local data for the current user to simulate a fresh install.
  Future<void> clearAllDataForFreshInstall() async {
    if (kReleaseMode) {
      throw Exception('Data cleanup is not allowed in release mode');
    }

    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      debugPrint('ℹ️ No user signed in, skipping data cleanup.');
      return;
    }
    final uid = currentUser.uid;

    debugPrint('🔥 Starting data reset for user: $uid');

    try {
      await _auth.signOut();
      debugPrint('✅ User signed out successfully.');
      
      await _clearFirestoreDataForUser(uid);

      await _deleteAllLocalStorage();
      
      await _reinitializeEssentialServices();

      debugPrint('✅ Data reset completed successfully. Please restart the app.');

    } catch (e) {
      debugPrint('❌ Error during data reset: $e');
      rethrow;
    }
  }

  Future<void> _clearFirestoreDataForUser(String uid) async {
    debugPrint('🗑️ Clearing Firestore data for user: $uid');
    final batch = _firestore.batch();

    final userDocRef = _firestore.collection('users').doc(uid);
    batch.delete(userDocRef);

    for (final subcollection in _userSubcollections) {
      final snapshot = await userDocRef.collection(subcollection).get();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      debugPrint('  - Added ${snapshot.docs.length} docs from subcollection "$subcollection" to delete batch.');
    }

    final globalCollectionsWithUserId = ['community_feed', 'families', 'shared_classifications']; 
    for (final collectionName in globalCollectionsWithUserId) {
      try {
        final query = _firestore.collection(collectionName).where('userId', isEqualTo: uid);
        final snapshot = await query.get();
        for (final doc in snapshot.docs) {
            batch.delete(doc.reference);
        }
        debugPrint('  - Added ${snapshot.docs.length} docs from collection "$collectionName" to delete batch.');
      } catch (e) {
        debugPrint('Could not query collection $collectionName. It might not have a userId field or exist. Error: $e');
      }
    }

    await batch.commit();
    debugPrint('✅ Firestore data cleared for user.');
  }

  Future<void> _deleteAllLocalStorage() async {
    debugPrint('💥 Deleting ALL local storage from disk...');
    
    try {
      await Hive.close();
      debugPrint('✅ All Hive boxes closed');
      
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
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      debugPrint('✅ ALL SharedPreferences cleared');
      
      final tempDir = await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
        debugPrint('✅ Temporary directory cleared');
      }
      
      debugPrint('💥 ALL local storage deleted ($deletedCount Hive boxes + SharedPreferences + Temp Dir)');
      
    } catch (e) {
      debugPrint('❌ Error deleting local storage: $e');
      rethrow;
    }
  }

  Future<void> _reinitializeEssentialServices() async {
    debugPrint('⚡ Re-initializing essential services...');
    
    try {
      final appDocumentDir = await getApplicationDocumentsDirectory();
      Hive.init(appDocumentDir.path);
      debugPrint('✅ Hive re-initialized');

      await Hive.openBox(StorageKeys.settingsBox);
      await Hive.openBox(StorageKeys.userBox);
      
      debugPrint('✅ Essential Hive boxes re-opened');
      
    } catch (e) {
      debugPrint('⚠️ Error re-initializing services: $e');
    }
  }

  /// [ADMIN-ONLY] Deletes all of a specific user's data from Firestore.
  /// This is a server-side operation and does not affect local device data.
  /// Throws an exception if the currently authenticated user is not an admin.
  Future<void> adminDeleteUser(String userIdToDelete) async {
    await _verifyCurrentUserIsAdmin();

    debugPrint('🔥 [ADMIN] Deleting all Firestore data for user: $userIdToDelete');
    try {
      // Re-using the same Firestore deletion logic, but targeted at a specific user.
      await _clearFirestoreDataForUser(userIdToDelete);
      debugPrint('✅ [ADMIN] Successfully deleted all Firestore data for user: $userIdToDelete');
    } catch (e) {
      debugPrint('❌ [ADMIN] Error deleting data for user $userIdToDelete: $e');
      rethrow;
    }
  }

  /// Placeholder for admin verification.
  /// In a real app, this would check for a custom claim.
  Future<void> _verifyCurrentUserIsAdmin() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('No user is signed in. Admin verification failed.');
    }

    // In a production environment, you would get the ID token and check for a custom claim.
    // final idTokenResult = await currentUser.getIdTokenResult(true);
    // if (idTokenResult.claims?['role'] != 'admin') {
    //   throw Exception('User ${currentUser.uid} is not an admin.');
    // }

    // For now, we can use a placeholder check.
    // This is NOT secure and should be replaced with custom claims logic.
    const adminEmail = 'pranaysuyash@gmail.com'; // As defined in admin_dashboard_specification.md
    if (currentUser.email != adminEmail) {
      throw Exception('User ${currentUser.email} is not authorized for this action.');
    }
     debugPrint('✅ Admin user ${currentUser.email} verified.');
  }
} 