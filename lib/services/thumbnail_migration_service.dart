import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/waste_classification.dart';
import '../utils/constants.dart';
import 'enhanced_image_service.dart';
import 'storage_service.dart';
import '../utils/waste_app_logger.dart';

/// Service to migrate existing classifications by generating missing thumbnails
class ThumbnailMigrationService {
  ThumbnailMigrationService(this._imageService, this._storageService);
  
  final EnhancedImageService _imageService;
  final StorageService _storageService;

  /// Migrate existing classifications to generate missing thumbnails
  Future<ThumbnailMigrationResult> migrateThumbnails() async {
    WasteAppLogger.info('Starting thumbnail migration process', null, null, {
      'service': 'thumbnail_migration',
      'operation': 'migrate_thumbnails'
    });
    
    var totalProcessed = 0;
    var thumbnailsGenerated = 0;
    var skipped = 0;
    var errors = 0;
    
    try {
      final classifications = await _storageService.getAllClassifications();
      totalProcessed = classifications.length;
      
      WasteAppLogger.info('Found classifications to process', null, null, {
        'total_classifications': totalProcessed,
        'service': 'thumbnail_migration'
      });
      
      for (var i = 0; i < classifications.length; i++) {
        final classification = classifications[i];
        
        try {
          // Skip if already has thumbnail
          if (classification.thumbnailRelativePath != null && 
              classification.thumbnailRelativePath!.isNotEmpty) {
            skipped++;
            continue;
          }
          
          // Try to generate thumbnail from existing image
          final updatedClassification = await _generateThumbnailForClassification(classification);
          
          if (updatedClassification != null) {
            // Update the classification in the list
            classifications[i] = updatedClassification;
            thumbnailsGenerated++;
            
            WasteAppLogger.info('Generated thumbnail for classification', null, null, {
              'item_name': classification.itemName,
              'classification_id': classification.id,
              'service': 'thumbnail_migration'
            });
            
            // Progress indicator
            if (thumbnailsGenerated % 10 == 0) {
              WasteAppLogger.info('Thumbnail generation progress', null, null, {
                'thumbnails_generated': thumbnailsGenerated,
                'total_processed': totalProcessed,
                'progress_percentage': ((thumbnailsGenerated / totalProcessed) * 100).round()
              });
            }
          } else {
            skipped++;
            WasteAppLogger.info('Skipped classification (no image)', null, null, {
              'item_name': classification.itemName,
              'classification_id': classification.id,
              'reason': 'no_image_available'
            });
          }
        } catch (e) {
          errors++;
          WasteAppLogger.severe('Error processing classification for thumbnail', e, null, {
            'item_name': classification.itemName,
            'classification_id': classification.id,
            'service': 'thumbnail_migration'
          });
        }
      }
      
      // Batch update all classifications if any thumbnails were generated
      if (thumbnailsGenerated > 0) {
        await _batchUpdateClassifications(classifications);
        WasteAppLogger.info('Batch updated classifications with thumbnails', null, null, {
          'thumbnails_generated': thumbnailsGenerated,
          'batch_size': classifications.length,
          'service': 'thumbnail_migration'
        });
      }
      
      final result = ThumbnailMigrationResult(
        success: true,
        totalProcessed: totalProcessed,
        thumbnailsGenerated: thumbnailsGenerated,
        skipped: skipped,
        errors: errors,
        message: 'Thumbnail migration completed successfully',
      );
      
      WasteAppLogger.info('Thumbnail migration completed', null, null, {
        'service': 'thumbnail_migration',
        'total_processed': totalProcessed,
        'thumbnails_generated': thumbnailsGenerated,
        'skipped': skipped,
        'errors': errors,
        'success_rate': totalProcessed > 0 ? ((thumbnailsGenerated / totalProcessed) * 100).round() : 0
      });
      
      return result;
    } catch (e) {
      WasteAppLogger.severe('Thumbnail migration failed', e, null, {
        'service': 'thumbnail_migration',
        'total_processed': totalProcessed,
        'action': 'return_failure_result'
      });
      return ThumbnailMigrationResult(
        success: false,
        totalProcessed: totalProcessed,
        thumbnailsGenerated: 0,
        skipped: 0,
        errors: 1,
        message: 'Thumbnail migration failed: $e',
      );
    }
  }
  
  /// Generate thumbnail for a single classification
  Future<WasteClassification?> _generateThumbnailForClassification(
    WasteClassification classification,
  ) async {
    try {
      // Check if image exists and is accessible
      final imageUrl = classification.imageUrl;
      if (imageUrl == null || imageUrl.isEmpty) {
        return null;
      }
      
      Uint8List? imageBytes;
      
      // Handle different image sources
      if (imageUrl.startsWith('web_image:')) {
        // Web data URL - extract base64 data
        final dataUrl = imageUrl.substring('web_image:'.length);
        if (dataUrl.startsWith('data:image')) {
          try {
            final base64Data = dataUrl.split(',')[1];
            imageBytes = base64Decode(base64Data);
          } catch (e) {
            WasteAppLogger.severe('Error decoding web image: $e');
            return null;
          }
        }
      } else if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
        // Network URL - download image
        imageBytes = await _imageService.fetchImageWithRetry(imageUrl);
      } else if (!kIsWeb) {
        // Local file path
        final file = File(imageUrl);
        if (await file.exists()) {
          imageBytes = await file.readAsBytes();
        } else {
          // Try relative path resolution
          final relativePath = classification.imageRelativePath;
          if (relativePath != null) {
            final resolvedPath = await _resolveRelativePath(relativePath);
            if (resolvedPath != null) {
              final resolvedFile = File(resolvedPath);
              if (await resolvedFile.exists()) {
                imageBytes = await resolvedFile.readAsBytes();
              }
            }
          }
        }
      }
      
      if (imageBytes == null) {
        return null;
      }
      
      // Generate thumbnail
      final thumbnailPath = await _imageService.saveThumbnail(
        imageBytes,
        baseName: classification.id,
      );
      
      // Extract relative path for thumbnail
      String? thumbnailRelativePath;
      if (!kIsWeb && thumbnailPath.contains('/thumbnails/')) {
        final index = thumbnailPath.indexOf('/thumbnails/');
        thumbnailRelativePath = thumbnailPath.substring(index + 1);
      } else if (thumbnailPath.startsWith('web_thumbnail:')) {
        thumbnailRelativePath = thumbnailPath;
      }
      
      // Return updated classification
      return classification.copyWith(
        thumbnailRelativePath: thumbnailRelativePath,
      );
    } catch (e) {
      WasteAppLogger.severe('Error generating thumbnail for ${classification.itemName}: $e');
      return null;
    }
  }
  
  /// Resolve relative path to absolute path
  Future<String?> _resolveRelativePath(String relativePath) async {
    try {
      if (kIsWeb) return null;
      
      final dir = await getApplicationDocumentsDirectory();
      final absolutePath = p.join(dir.path, relativePath);
      return absolutePath;
    } catch (e) {
      WasteAppLogger.severe('Error resolving relative path: $e');
      return null;
    }
  }
  
  /// Batch update classifications in storage
  Future<void> _batchUpdateClassifications(List<WasteClassification> classifications) async {
    try {
      final box = Hive.box(StorageKeys.classificationsBox);
      
      // Clear and repopulate with updated classifications
      await box.clear();
      
      for (final classification in classifications) {
        final key = 'classification_${classification.id}';
        await box.put(key, jsonEncode(classification.toJson()));
      }
      
      WasteAppLogger.info('💾 Successfully batch updated ${classifications.length} classifications');
    } catch (e) {
      WasteAppLogger.severe('❌ Error batch updating classifications: $e');
      rethrow;
    }
  }
}

/// Result of thumbnail migration operation
class ThumbnailMigrationResult {
  const ThumbnailMigrationResult({
    required this.success,
    required this.totalProcessed,
    required this.thumbnailsGenerated,
    required this.skipped,
    required this.errors,
    required this.message,
  });
  
  final bool success;
  final int totalProcessed;
  final int thumbnailsGenerated;
  final int skipped;
  final int errors;
  final String message;
  
  @override
  String toString() {
    return 'ThumbnailMigrationResult(success: $success, '
           'totalProcessed: $totalProcessed, '
           'thumbnailsGenerated: $thumbnailsGenerated, '
           'skipped: $skipped, '
           'errors: $errors, '
           'message: $message)';
  }
} 