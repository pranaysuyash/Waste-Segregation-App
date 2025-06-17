import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:waste_segregation_app/utils/waste_app_logger.dart';

/// Comprehensive Firebase Data Archival and Fresh Start Script
/// 
/// This script provides a safe way to:
/// 1. Archive all existing Firebase data to timestamped collections
/// 2. Clear main collections for fresh start
/// 3. Clear local Hive storage
/// 4. Provide restore capability
/// 
/// Usage: dart run scripts/archive_and_fresh_start.dart [--archive-only] [--restore TIMESTAMP]
class FirebaseArchivalService {

  FirebaseArchivalService() {
    final now = DateTime.now();
    _archiveTimestamp = '${now.year}_${now.month.toString().padLeft(2, '0')}_${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}_${now.minute.toString().padLeft(2, '0')}';
  }
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // Archive timestamp for consistent naming
  late final String _archiveTimestamp;
  
  // Main collections to archive and clear
  static const List<String> _mainCollections = [
    'users',
    'community_feed',
    'community_stats',
    'leaderboard_allTime',
    'leaderboard_weekly',
    'leaderboard_monthly',
    'admin_classifications',
    'admin_user_recovery',
    'analytics_events',
    'disposal_instructions',
    'families',
    'invitations',
    'shared_classifications',
    'classification_feedback',
    'daily_challenges',
    'user_achievements',
    'badges',
    'content_library',
    'recycling_facilities',
    'facility_reviews',
  ];

  // Local Hive boxes to clear
  static const List<String> _hiveBoxes = [
    'classificationsBox',
    'gamificationBox',
    'userBox',
    'settingsBox',
    'cacheBox',
    'familiesBox',
    'invitationsBox',
    'classificationFeedbackBox',
    'classificationHashesBox',
    'communityBox',
  ];

  /// Initialize Firebase
  Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      WasteAppLogger.info('✅ Firebase initialized successfully');
    } catch (e) {
      WasteAppLogger.severe('❌ Failed to initialize Firebase: $e');
      exit(1);
    }
  }

  /// Archive all data to timestamped collections
  Future<void> archiveAllData() async {
    WasteAppLogger.info('\n🗄️  Starting data archival process...');
    WasteAppLogger.info('📅 Archive timestamp: $_archiveTimestamp');
    
    var totalDocuments = 0;
    var totalCollections = 0;

    for (final collectionName in _mainCollections) {
      try {
        WasteAppLogger.info('\n📦 Processing collection: $collectionName');
        
        final sourceCollection = _firestore.collection(collectionName);
        final archiveCollectionName = 'archive_${_archiveTimestamp}_$collectionName';
        final archiveCollection = _firestore.collection(archiveCollectionName);
        
        // Get all documents from source collection
        final snapshot = await sourceCollection.get();
        
        if (snapshot.docs.isEmpty) {
          WasteAppLogger.info('   ⚪ Collection is empty, skipping...');
          continue;
        }

        WasteAppLogger.info('   📄 Found ${snapshot.docs.length} documents to archive');
        
        // Archive documents in batches
        const batchSize = 500;
        var batch = _firestore.batch();
        var batchCount = 0;
        var processedCount = 0;

        for (final doc in snapshot.docs) {
          // Add metadata to archived document
          final archiveData = {
            ...doc.data(),
            '_archived_at': FieldValue.serverTimestamp(),
            '_original_collection': collectionName,
            '_original_doc_id': doc.id,
            '_archive_timestamp': _archiveTimestamp,
          };

          batch.set(archiveCollection.doc(doc.id), archiveData);
          batchCount++;
          processedCount++;

          if (batchCount >= batchSize) {
            await batch.commit();
            batch = _firestore.batch();
            batchCount = 0;
            WasteAppLogger.info('   ✅ Archived $processedCount/${snapshot.docs.length} documents');
          }
        }

        // Commit remaining documents
        if (batchCount > 0) {
          await batch.commit();
        }

        WasteAppLogger.info('   ✅ Successfully archived ${snapshot.docs.length} documents to $archiveCollectionName');
        totalDocuments += snapshot.docs.length;
        totalCollections++;

        // Also archive subcollections for users collection
        if (collectionName == 'users') {
          await _archiveUserSubcollections(snapshot.docs);
        }

      } catch (e) {
        WasteAppLogger.severe('   ❌ Failed to archive collection $collectionName: $e');
      }
    }

    // Create archive metadata document
    await _createArchiveMetadata(totalDocuments, totalCollections);
    
    WasteAppLogger.info('\n✅ Data archival completed!');
    WasteAppLogger.info('📊 Total: $totalCollections collections, $totalDocuments documents archived');
  }

  /// Archive user subcollections (classifications, etc.)
  Future<void> _archiveUserSubcollections(List<QueryDocumentSnapshot> userDocs) async {
    WasteAppLogger.info('   📁 Archiving user subcollections...');
    
    for (final userDoc in userDocs) {
      try {
        // Archive user classifications
        final classificationsCollection = _firestore
            .collection('users')
            .doc(userDoc.id)
            .collection('classifications');
        
        final classificationsSnapshot = await classificationsCollection.get();
        
        if (classificationsSnapshot.docs.isNotEmpty) {
          final archiveCollectionName = 'archive_${_archiveTimestamp}_user_classifications';
          final archiveCollection = _firestore.collection(archiveCollectionName);
          
          var batch = _firestore.batch();
          var batchCount = 0;
          
          for (final classDoc in classificationsSnapshot.docs) {
            final archiveData = {
              ...classDoc.data(),
              '_archived_at': FieldValue.serverTimestamp(),
              '_original_user_id': userDoc.id,
              '_original_doc_id': classDoc.id,
              '_archive_timestamp': _archiveTimestamp,
            };
            
            batch.set(archiveCollection.doc('${userDoc.id}_${classDoc.id}'), archiveData);
            batchCount++;
            
            if (batchCount >= 500) {
              await batch.commit();
              batch = _firestore.batch();
              batchCount = 0;
            }
          }
          
          if (batchCount > 0) {
            await batch.commit();
          }
          
          WasteAppLogger.info('     ✅ Archived ${classificationsSnapshot.docs.length} classifications for user ${userDoc.id}');
        }
      } catch (e) {
        WasteAppLogger.severe('     ❌ Failed to archive subcollections for user ${userDoc.id}: $e');
      }
    }
  }

  /// Create archive metadata document
  Future<void> _createArchiveMetadata(int totalDocuments, int totalCollections) async {
    try {
      await _firestore.collection('archive_metadata').doc(_archiveTimestamp).set({
        'timestamp': _archiveTimestamp,
        'created_at': FieldValue.serverTimestamp(),
        'total_documents': totalDocuments,
        'total_collections': totalCollections,
        'archived_collections': _mainCollections,
        'description': 'Full data archive created for fresh start',
        'can_restore': true,
        'restore_instructions': 'Use restore command with this timestamp',
      });
      WasteAppLogger.info('📋 Archive metadata created');
    } catch (e) {
      WasteAppLogger.severe('❌ Failed to create archive metadata: $e');
    }
  }

  /// Clear all main collections
  Future<void> clearMainCollections() async {
    WasteAppLogger.info('\n🧹 Starting data cleanup process...');
    
    for (final collectionName in _mainCollections) {
      try {
        WasteAppLogger.info('🗑️  Clearing collection: $collectionName');
        
        final collection = _firestore.collection(collectionName);
        
        // Delete documents in batches
        var hasMore = true;
        var totalDeleted = 0;
        
        while (hasMore) {
          final snapshot = await collection.limit(500).get();
          
          if (snapshot.docs.isEmpty) {
            hasMore = false;
            continue;
          }
          
          final batch = _firestore.batch();
          for (final doc in snapshot.docs) {
            batch.delete(doc.reference);
          }
          
          await batch.commit();
          totalDeleted += snapshot.docs.length;
          
          WasteAppLogger.info('   🗑️  Deleted ${snapshot.docs.length} documents (total: $totalDeleted)');
        }
        
        // Clear user subcollections
        if (collectionName == 'users') {
          await _clearUserSubcollections();
        }
        
        WasteAppLogger.info('   ✅ Collection $collectionName cleared');
        
      } catch (e) {
        WasteAppLogger.severe('   ❌ Failed to clear collection $collectionName: $e');
      }
    }
    
    WasteAppLogger.info('✅ All collections cleared successfully!');
  }

  /// Clear user subcollections
  Future<void> _clearUserSubcollections() async {
    WasteAppLogger.info('   📁 Clearing user subcollections...');
    
    // Since we're clearing the users collection, subcollections will be orphaned
    // but Firestore will eventually clean them up. For immediate cleanup:
    try {
      final userClassificationsQuery = await _firestore
          .collectionGroup('classifications')
          .get();
      
      if (userClassificationsQuery.docs.isNotEmpty) {
        var batch = _firestore.batch();
        var batchCount = 0;
        
        for (final doc in userClassificationsQuery.docs) {
          batch.delete(doc.reference);
          batchCount++;
          
          if (batchCount >= 500) {
            await batch.commit();
            batch = _firestore.batch();
            batchCount = 0;
          }
        }
        
        if (batchCount > 0) {
          await batch.commit();
        }
        
        WasteAppLogger.info('     ✅ Cleared ${userClassificationsQuery.docs.length} user classification documents');
      }
    } catch (e) {
      WasteAppLogger.severe('     ❌ Failed to clear user subcollections: $e');
    }
  }

  /// Clear local Hive storage
  Future<void> clearLocalStorage() async {
    WasteAppLogger.info('\n💾 Clearing local storage...');
    
    try {
      // Initialize Hive
      // Since this is a command-line script, we assume it's not running in a web environment.
      final appDocumentDirectory = await getApplicationDocumentsDirectory();
      await Hive.initFlutter(appDocumentDirectory.path);
      
      // Clear each box
      for (final boxName in _hiveBoxes) {
        try {
          if (Hive.isBoxOpen(boxName)) {
            final box = Hive.box(boxName);
            await box.clear();
            WasteAppLogger.info('   ✅ Cleared Hive box: $boxName');
          } else {
            // Try to open and clear
            try {
              final box = await Hive.openBox(boxName);
              await box.clear();
              await box.close();
              WasteAppLogger.info('   ✅ Cleared Hive box: $boxName');
            } catch (e) {
              WasteAppLogger.info('   ⚪ Box $boxName not found or already empty');
            }
          }
        } catch (e) {
          WasteAppLogger.severe('   ❌ Failed to clear box $boxName: $e');
        }
      }
      
      WasteAppLogger.info('✅ Local storage cleared successfully!');
      
    } catch (e) {
      WasteAppLogger.severe('❌ Failed to clear local storage: $e');
    }
  }

  /// Restore data from archive
  Future<void> restoreFromArchive(String archiveTimestamp) async {
    WasteAppLogger.info('\n🔄 Starting data restoration from archive: $archiveTimestamp');
    
    // Verify archive exists
    final archiveMetadata = await _firestore
        .collection('archive_metadata')
        .doc(archiveTimestamp)
        .get();
    
    if (!archiveMetadata.exists) {
      WasteAppLogger.severe('❌ Archive with timestamp $archiveTimestamp not found!');
      return;
    }
    
    final metadata = archiveMetadata.data()!;
    WasteAppLogger.info('📋 Archive info: ${metadata['description']}');
    WasteAppLogger.info('📊 Contains: ${metadata['total_documents']} documents in ${metadata['total_collections']} collections');
    
    // Restore each collection
    for (final collectionName in _mainCollections) {
      try {
        final archiveCollectionName = 'archive_${archiveTimestamp}_$collectionName';
        final archiveCollection = _firestore.collection(archiveCollectionName);
        final targetCollection = _firestore.collection(collectionName);
        
        final snapshot = await archiveCollection.get();
        
        if (snapshot.docs.isEmpty) {
          WasteAppLogger.info('   ⚪ No archived data for collection: $collectionName');
          continue;
        }
        
        WasteAppLogger.info('   🔄 Restoring ${snapshot.docs.length} documents to $collectionName');
        
        var batch = _firestore.batch();
        var batchCount = 0;
        
        for (final doc in snapshot.docs) {
          final data = Map<String, dynamic>.from(doc.data());
          
          // Remove archive metadata
          data.remove('_archived_at');
          data.remove('_original_collection');
          data.remove('_original_doc_id');
          data.remove('_archive_timestamp');
          
          // Use original document ID
          final originalDocId = data['_original_doc_id'] ?? doc.id;
          data.remove('_original_doc_id');
          
          batch.set(targetCollection.doc(originalDocId), data);
          batchCount++;
          
          if (batchCount >= 500) {
            await batch.commit();
            batch = _firestore.batch();
            batchCount = 0;
          }
        }
        
        if (batchCount > 0) {
          await batch.commit();
        }
        
        WasteAppLogger.info('   ✅ Restored ${snapshot.docs.length} documents to $collectionName');
        
      } catch (e) {
        WasteAppLogger.severe('   ❌ Failed to restore collection $collectionName: $e');
      }
    }
    
    // Restore user classifications
    await _restoreUserClassifications(archiveTimestamp);
    
    WasteAppLogger.info('✅ Data restoration completed!');
  }

  /// Restore user classifications subcollection
  Future<void> _restoreUserClassifications(String archiveTimestamp) async {
    try {
      final archiveCollectionName = 'archive_${archiveTimestamp}_user_classifications';
      final archiveCollection = _firestore.collection(archiveCollectionName);
      
      final snapshot = await archiveCollection.get();
      
      if (snapshot.docs.isEmpty) {
        WasteAppLogger.info('   ⚪ No archived user classifications found');
        return;
      }
      
      WasteAppLogger.info('   🔄 Restoring ${snapshot.docs.length} user classifications');
      
      var batch = _firestore.batch();
      var batchCount = 0;
      
      for (final doc in snapshot.docs) {
        final data = Map<String, dynamic>.from(doc.data());
        
        final originalUserId = data['_original_user_id'];
        final originalDocId = data['_original_doc_id'];
        
        // Remove archive metadata
        data.remove('_archived_at');
        data.remove('_original_user_id');
        data.remove('_original_doc_id');
        data.remove('_archive_timestamp');
        
        if (originalUserId != null && originalDocId != null) {
          final targetRef = _firestore
              .collection('users')
              .doc(originalUserId)
              .collection('classifications')
              .doc(originalDocId);
          
          batch.set(targetRef, data);
          batchCount++;
          
          if (batchCount >= 500) {
            await batch.commit();
            batch = _firestore.batch();
            batchCount = 0;
          }
        }
      }
      
      if (batchCount > 0) {
        await batch.commit();
      }
      
      WasteAppLogger.info('   ✅ Restored ${snapshot.docs.length} user classifications');
      
    } catch (e) {
      WasteAppLogger.severe('   ❌ Failed to restore user classifications: $e');
    }
  }

  /// List available archives
  Future<void> listArchives() async {
    WasteAppLogger.info('\n📋 Available archives:');
    
    try {
      final snapshot = await _firestore.collection('archive_metadata').get();
      
      if (snapshot.docs.isEmpty) {
        WasteAppLogger.info('   ⚪ No archives found');
        return;
      }
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final timestamp = data['timestamp'];
        final description = data['description'];
        final totalDocs = data['total_documents'];
        final totalCols = data['total_collections'];
        final createdAt = data['created_at'];
        
        WasteAppLogger.info('   📦 $timestamp');
        WasteAppLogger.info('      Description: $description');
        WasteAppLogger.info('      Documents: $totalDocs, Collections: $totalCols');
        if (createdAt != null) {
          WasteAppLogger.info('      Created: ${(createdAt as Timestamp).toDate()}');
        }
        WasteAppLogger.info('');
      }
      
    } catch (e) {
      WasteAppLogger.severe('❌ Failed to list archives: $e');
    }
  }

  /// Main execution method
  Future<void> run(List<String> args) async {
    await initialize();
    
    if (args.contains('--list-archives')) {
      await listArchives();
      return;
    }
    
    if (args.contains('--restore')) {
      final restoreIndex = args.indexOf('--restore');
      if (restoreIndex + 1 < args.length) {
        final archiveTimestamp = args[restoreIndex + 1];
        await restoreFromArchive(archiveTimestamp);
      } else {
        WasteAppLogger.severe('❌ Please provide archive timestamp for restore');
        WasteAppLogger.info('Usage: dart run scripts/archive_and_fresh_start.dart --restore TIMESTAMP');
      }
      return;
    }
    
    if (args.contains('--archive-only')) {
      await archiveAllData();
      WasteAppLogger.info('\n✅ Archive-only mode completed. Data has been archived but not cleared.');
      WasteAppLogger.info('💡 To clear data, run without --archive-only flag');
      return;
    }
    
    // Default: Full archive and fresh start
    WasteAppLogger.info('🚀 Starting Full Archive and Fresh Start Process');
    WasteAppLogger.info('⚠️  This will archive all existing data and create a clean slate');
    WasteAppLogger.info('📅 Archive timestamp: $_archiveTimestamp');
    
    // Confirm action
    stdout.write('\nAre you sure you want to proceed? (yes/no): ');
    final confirmation = stdin.readLineSync();
    
    if (confirmation?.toLowerCase() != 'yes') {
      WasteAppLogger.severe('❌ Operation cancelled');
      return;
    }
    
    // Execute full process
    await archiveAllData();
    await clearMainCollections();
    await clearLocalStorage();
    
    WasteAppLogger.info('\n🎉 Fresh start completed successfully!');
    WasteAppLogger.info('📋 Your data has been archived with timestamp: $_archiveTimestamp');
    WasteAppLogger.info('💡 To restore your data later, run:');
    WasteAppLogger.info('   dart run scripts/archive_and_fresh_start.dart --restore $_archiveTimestamp');
  }
}

/// Main entry point
Future<void> main(List<String> args) async {
  final service = FirebaseArchivalService();
  
  if (args.contains('--help') || args.contains('-h')) {
    print('''
🗄️  Firebase Data Archival and Fresh Start Tool

Usage:
  dart run scripts/archive_and_fresh_start.dart [options]

Options:
  --help, -h           Show this help message
  --list-archives      List all available archives
  --archive-only       Archive data without clearing (safe mode)
  --restore TIMESTAMP  Restore data from specific archive
  
Examples:
  # Full archive and fresh start
  dart run scripts/archive_and_fresh_start.dart
  
  # Archive only (safe mode)
  dart run scripts/archive_and_fresh_start.dart --archive-only
  
  # List available archives
  dart run scripts/archive_and_fresh_start.dart --list-archives
  
  # Restore from archive
  dart run scripts/archive_and_fresh_start.dart --restore 2025_06_17_15_54

⚠️  Warning: The default mode will permanently clear all current data.
   Use --archive-only for safe archival without clearing.
''');
    return;
  }
  
  try {
    await service.run(args);
  } catch (e) {
    WasteAppLogger.severe('❌ Fatal error: $e');
    exit(1);
  }
}