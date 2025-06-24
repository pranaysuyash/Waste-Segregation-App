import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/waste_classification.dart';
import 'storage_service.dart';
import 'cloud_storage_service.dart';
import 'package:waste_segregation_app/utils/waste_app_logger.dart';

/// Service to migrate old classification records and update them with existing images
class ClassificationMigrationService {
  ClassificationMigrationService(this._localStorageService, this._cloudStorageService);
  final StorageService _localStorageService;
  final CloudStorageService _cloudStorageService;

  /// Migrate old classifications by updating imageUrl if images exist locally
  Future<MigrationResult> migrateOldClassifications() async {
    try {
      WasteAppLogger.info('🔄 Starting classification migration...');
      
      final userProfile = await _localStorageService.getCurrentUserProfile();
      if (userProfile == null || userProfile.id.isEmpty) {
        WasteAppLogger.info('🚫 Cannot migrate: User not signed in');
        return MigrationResult(
          success: false,
          totalProcessed: 0,
          updated: 0,
          skipped: 0,
          errors: 0,
          cloudUpdated: 0,
          message: 'User not signed in',
        );
      }

      // Get all local classifications
      final localClassifications = await _localStorageService.getAllClassifications();
      WasteAppLogger.info('📊 Found ${localClassifications.length} local classifications');

      var totalProcessed = 0;
      var updated = 0;
      var skipped = 0;
      var errors = 0;
      final updatedClassifications = <WasteClassification>[];

      for (final classification in localClassifications) {
        totalProcessed++;
        
        try {
          // Check if classification already has a valid imageUrl
          if (classification.imageUrl != null && classification.imageUrl!.isNotEmpty) {
            // For mobile platforms, check if the file exists
            if (!kIsWeb) {
              final file = File(classification.imageUrl!);
              if (await file.exists()) {
                skipped++;
                continue; // Image already exists and is valid
              }
            } else {
              // For web, assume existing imageUrl is valid
              skipped++;
              continue;
            }
          }

          // Try to find an image for this classification
          final updatedClassification = await _findAndUpdateImage(classification);
          
          if (updatedClassification != null) {
            // Save updated classification locally
            await _localStorageService.saveClassification(updatedClassification);
            
            // Add to list for batch cloud update
            updatedClassifications.add(updatedClassification);
            
            updated++;
            WasteAppLogger.info('✅ Updated classification: ${classification.itemName}');
          } else {
            skipped++;
            WasteAppLogger.info('⏭️ No image found for: ${classification.itemName}');
          }
        } catch (e) {
          errors++;
          WasteAppLogger.severe('❌ Error processing ${classification.itemName}: $e');
        }
      }

      // Batch update cloud storage if there are updated classifications
      var cloudUpdated = 0;
      if (updatedClassifications.isNotEmpty) {
        final isGoogleSyncEnabled = await _isGoogleSyncEnabled();
        if (isGoogleSyncEnabled) {
          WasteAppLogger.info('☁️ Batch updating ${updatedClassifications.length} classifications in cloud...');
          cloudUpdated = await _cloudStorageService.batchUpdateClassificationsInCloud(updatedClassifications);
          WasteAppLogger.info('☁️ Successfully updated $cloudUpdated classifications in cloud');
        }
      }

      final result = MigrationResult(
        success: true,
        totalProcessed: totalProcessed,
        updated: updated,
        skipped: skipped,
        errors: errors,
        cloudUpdated: cloudUpdated,
        message: 'Migration completed successfully',
      );

      WasteAppLogger.info('📊 Migration Summary:');
      WasteAppLogger.info('📊 Total processed: $totalProcessed');
      WasteAppLogger.info('📊 Updated locally: $updated');
      WasteAppLogger.info('📊 Updated in cloud: $cloudUpdated');
      WasteAppLogger.info('📊 Skipped: $skipped');
      WasteAppLogger.severe('📊 Errors: $errors');

      return result;
    } catch (e) {
      WasteAppLogger.severe('❌ Migration failed: $e');
      return MigrationResult(
        success: false,
        totalProcessed: 0,
        updated: 0,
        skipped: 0,
        errors: 1,
        cloudUpdated: 0,
        message: 'Migration failed: $e',
      );
    }
  }

  /// Try to find an existing image for a classification
  Future<WasteClassification?> _findAndUpdateImage(WasteClassification classification) async {
    // Strategy 1: Look for images with classification ID in filename
    var foundImagePath = await _findImageByClassificationId(classification.id);
    
    // Strategy 2: Look for images with similar timestamp
    foundImagePath ??= await _findImageByTimestamp(classification.timestamp);
    
    // Strategy 3: Look for images with similar item name
    foundImagePath ??= await _findImageByItemName(classification.itemName);

    if (foundImagePath != null) {
      return classification.copyWith(imageUrl: foundImagePath);
    }

    return null;
  }

  /// Find image by classification ID in filename
  Future<String?> _findImageByClassificationId(String classificationId) async {
    if (kIsWeb) return null; // Not applicable for web
    
    try {
      // Common image directories to search
      final searchPaths = await _getImageSearchPaths();
      
      for (final searchPath in searchPaths) {
        final directory = Directory(searchPath);
        if (!await directory.exists()) continue;
        
        final files = await directory.list().toList();
        for (final file in files) {
          if (file is File) {
            final filename = file.path.split('/').last;
            if (filename.contains(classificationId)) {
              return file.path;
            }
          }
        }
      }
    } catch (e) {
      WasteAppLogger.severe('Error searching by classification ID: $e');
    }
    
    return null;
  }

  /// Find image by timestamp (within 5 minutes)
  Future<String?> _findImageByTimestamp(DateTime timestamp) async {
    if (kIsWeb) return null; // Not applicable for web
    
    try {
      final searchPaths = await _getImageSearchPaths();
      const timeWindow = Duration(minutes: 5);
      
      for (final searchPath in searchPaths) {
        final directory = Directory(searchPath);
        if (!await directory.exists()) continue;
        
        final files = await directory.list().toList();
        for (final file in files) {
          if (file is File) {
            final stat = await file.stat();
            final fileTime = stat.modified;
            
            if (fileTime.isAfter(timestamp.subtract(timeWindow)) &&
                fileTime.isBefore(timestamp.add(timeWindow))) {
              return file.path;
            }
          }
        }
      }
    } catch (e) {
      WasteAppLogger.severe('Error searching by timestamp: $e');
    }
    
    return null;
  }

  /// Find image by item name similarity
  Future<String?> _findImageByItemName(String itemName) async {
    if (kIsWeb) return null; // Not applicable for web
    
    try {
      final searchPaths = await _getImageSearchPaths();
      final cleanItemName = itemName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      
      for (final searchPath in searchPaths) {
        final directory = Directory(searchPath);
        if (!await directory.exists()) continue;
        
        final files = await directory.list().toList();
        for (final file in files) {
          if (file is File) {
            final filename = file.path.split('/').last.toLowerCase();
            if (filename.contains(cleanItemName)) {
              return file.path;
            }
          }
        }
      }
    } catch (e) {
      WasteAppLogger.severe('Error searching by item name: $e');
    }
    
    return null;
  }

  /// Get common image search paths
  Future<List<String>> _getImageSearchPaths() async {
    final paths = <String>[];
    
    try {
      // Add app documents directory
      final appDir = await getApplicationDocumentsDirectory();
      paths.add(appDir.path);
      paths.add('${appDir.path}/images');
      paths.add('${appDir.path}/classifications');
      
      // Add temporary directory
      final tempDir = await getTemporaryDirectory();
      paths.add(tempDir.path);
    } catch (e) {
      WasteAppLogger.severe('Error getting search paths: $e');
    }
    
    return paths;
  }

  /// Check if Google sync is enabled
  Future<bool> _isGoogleSyncEnabled() async {
    try {
      // This would typically be stored in user preferences
      // For now, assume it's enabled if user is signed in
      final userProfile = await _localStorageService.getCurrentUserProfile();
      return userProfile != null && userProfile.id.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}

/// Result of the migration operation
class MigrationResult {
  MigrationResult({
    required this.success,
    required this.totalProcessed,
    required this.updated,
    required this.skipped,
    required this.errors,
    required this.cloudUpdated,
    required this.message,
  });
  final bool success;
  final int totalProcessed;
  final int updated;
  final int skipped;
  final int errors;
  final int cloudUpdated;
  final String message;

  @override
  String toString() {
    return 'MigrationResult(success: $success, processed: $totalProcessed, updated: $updated, cloudUpdated: $cloudUpdated, skipped: $skipped, errors: $errors, message: $message)';
  }
} 