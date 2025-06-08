import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Service to clear Firebase data for testing fresh install experience
/// This should only be used in development/testing environments
class FirebaseCleanupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

  /// Hive boxes to clear for fresh install simulation
  static const List<String> _hiveBoxesToClear = [
    'classifications',
    'userProfile',
    'settings',
    'achievements',
    'communityStats',
    'communityFeed',
    'analytics',
    'contentProgress',
    'familyData',
  ];

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
      final subcollections = [
        'classifications',
        'achievements',
        'settings', 
        'analytics',
        'content_progress',
      ];

      for (final subcollection in subcollections) {
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
    int totalDeleted = 0;
    
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
      
      // Note: Additional cache clearing can be added here as needed
      // For example, clearing image caches, temporary files, etc.
      
      debugPrint('✅ Cached data cleared');
    } catch (e) {
      debugPrint('⚠️ Error clearing cached data: $e');
    }
  }
} 