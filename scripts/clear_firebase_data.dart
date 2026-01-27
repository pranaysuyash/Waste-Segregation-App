import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Script to clear all Firebase data for a fresh install experience
/// This will delete all user data, classifications, community feed, etc.
class FirebaseDataCleaner {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Main collections to clear
  static const List<String> _collectionsToDelete = [
    'users',
    'classifications',
    'community_feed',
    'community_stats',
    'families',
    'invitations',
    'shared_classifications',
    'analytics_events',
    'disposal_locations',
    'leaderboard_allTime',
    'leaderboard_weekly',
    'leaderboard_monthly',
    'badges',
    'daily_challenges',
    'user_achievements',
    'family_stats',
    'classification_cache',
    'content_library',
    'recycling_facilities',
    'facility_reviews',
  ];

  /// Storage paths to clear
  static const List<String> _storagePaths = [
    'users/',
    'classifications/',
    'community/',
    'facility_photos/',
    'contribution_photos/',
    'educational_content/',
    'profile_images/',
    'classification_images/',
  ];

  Future<void> clearAllData() async {
    print('🔥 Starting Firebase data cleanup...');

    try {
      // 1. Clear Firestore collections
      await _clearFirestoreCollections();

      // 2. Clear Firebase Storage
      await _clearFirebaseStorage();

      // 3. Delete current user authentication (optional)
      await _clearAuthentication();

      print('✅ Firebase cleanup completed successfully!');
      print('📱 The app will now behave like a fresh install.');
    } catch (e) {
      print('❌ Error during cleanup: $e');
      rethrow;
    }
  }

  /// Delete all documents from specified Firestore collections
  Future<void> _clearFirestoreCollections() async {
    print('🗑️ Clearing Firestore collections...');

    for (final collection in _collectionsToDelete) {
      try {
        await _deleteCollection(collection);
        print('✅ Cleared collection: $collection');
      } catch (e) {
        print('⚠️ Error clearing collection $collection: $e');
      }
    }

    // Also clear user subcollections
    await _clearUserSubcollections();
  }

  /// Delete all documents in a collection
  Future<void> _deleteCollection(String collectionName) async {
    final collection = _firestore.collection(collectionName);

    // Get all documents in batches
    QuerySnapshot snapshot;
    do {
      snapshot = await collection.limit(500).get();

      if (snapshot.docs.isNotEmpty) {
        final batch = _firestore.batch();

        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }

        await batch.commit();
        print(
            '  Deleted ${snapshot.docs.length} documents from $collectionName');
      }
    } while (snapshot.docs.isNotEmpty);
  }

  /// Clear user-specific subcollections
  Future<void> _clearUserSubcollections() async {
    print('🗑️ Clearing user subcollections...');

    try {
      // Get all users first
      final usersSnapshot = await _firestore.collection('users').get();

      for (final userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;

        // Clear user subcollections
        final subcollections = [
          'classifications',
          'achievements',
          'settings',
          'analytics',
          'content_progress',
          'family_activity',
        ];

        for (final subcollection in subcollections) {
          await _deleteCollection('users/$userId/$subcollection');
        }

        print('  Cleared subcollections for user: $userId');
      }
    } catch (e) {
      print('⚠️ Error clearing user subcollections: $e');
    }
  }

  /// Clear Firebase Storage files
  Future<void> _clearFirebaseStorage() async {
    print('🗑️ Clearing Firebase Storage...');

    for (final path in _storagePaths) {
      try {
        await _deleteStoragePath(path);
        print('✅ Cleared storage path: $path');
      } catch (e) {
        print('⚠️ Error clearing storage path $path: $e');
      }
    }
  }

  /// Delete all files in a storage path
  Future<void> _deleteStoragePath(String path) async {
    try {
      final ref = _storage.ref().child(path);
      final result = await ref.listAll();

      // Delete all files
      for (final fileRef in result.items) {
        await fileRef.delete();
      }

      // Recursively delete subdirectories
      for (final folderRef in result.prefixes) {
        await _deleteStoragePath(folderRef.fullPath);
      }

      print('  Deleted ${result.items.length} files from $path');
    } catch (e) {
      // Path might not exist, which is fine
      if (!e.toString().contains('object-not-found')) {
        rethrow;
      }
    }
  }

  /// Clear authentication (sign out current user)
  Future<void> _clearAuthentication() async {
    print('🔐 Clearing authentication...');

    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await _auth.signOut();
        print('✅ Signed out user: ${currentUser.email}');
      } else {
        print('ℹ️ No user currently signed in');
      }
    } catch (e) {
      print('⚠️ Error during sign out: $e');
    }
  }

  /// Reset community stats to zero
  Future<void> _resetCommunityStats() async {
    print('📊 Resetting community stats...');

    try {
      await _firestore.collection('community_stats').doc('main').set({
        'totalUsers': 0,
        'totalClassifications': 0,
        'totalPoints': 0,
        'categoryBreakdown': <String, int>{},
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      print('✅ Community stats reset to zero');
    } catch (e) {
      print('⚠️ Error resetting community stats: $e');
    }
  }

  /// Verify cleanup was successful
  Future<void> verifyCleanup() async {
    print('🔍 Verifying cleanup...');

    var totalDocuments = 0;

    for (final collection in _collectionsToDelete) {
      try {
        final snapshot = await _firestore.collection(collection).limit(1).get();
        if (snapshot.docs.isNotEmpty) {
          print('⚠️ Collection $collection still has documents');
          totalDocuments += snapshot.docs.length;
        }
      } catch (e) {
        // Collection might not exist, which is fine
      }
    }

    if (totalDocuments == 0) {
      print('✅ Cleanup verification successful - all collections are empty');
    } else {
      print(
          '⚠️ Cleanup verification found $totalDocuments remaining documents');
    }
  }
}

/// Main function to run the cleanup
Future<void> main() async {
  print('🚀 Firebase Data Cleanup Tool');
  print('This will delete ALL Firebase data for a fresh install experience.');
  print('');

  // Confirm with user
  stdout.write('Are you sure you want to proceed? (yes/no): ');
  final confirmation = stdin.readLineSync();

  if (confirmation?.toLowerCase() != 'yes') {
    print('❌ Cleanup cancelled by user');
    return;
  }

  try {
    // Initialize Firebase
    await Firebase.initializeApp();
    print('✅ Firebase initialized');

    // Run cleanup
    final cleaner = FirebaseDataCleaner();
    await cleaner.clearAllData();

    // Reset community stats
    await cleaner._resetCommunityStats();

    // Verify cleanup
    await cleaner.verifyCleanup();

    print('');
    print('🎉 Firebase cleanup completed successfully!');
    print('📱 The app will now behave like a fresh install.');
    print('🔄 You can now restart the app to test the new user experience.');
  } catch (e) {
    print('❌ Cleanup failed: $e');
    exit(1);
  }
}
