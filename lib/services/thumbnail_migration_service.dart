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

/// Service to migrate existing classifications by generating missing thumbnails
class ThumbnailMigrationService {
  ThumbnailMigrationService(this._imageService, this._storageService);
  
  final EnhancedImageService _imageService;
  final StorageService _storageService;

  /// Migrate existing classifications to generate missing thumbnails
  Future<ThumbnailMigrationResult> migrateThumbnails() async {
    debugPrint('🔄 Starting thumbnail migration process...');
    
    var totalProcessed = 0;
    var thumbnailsGenerated = 0;
    var skipped = 0;
    var errors = 0;
    
    try {
      final classifications = await _storageService.getAllClassifications();
      totalProcessed = classifications.length;
      
      debugPrint('📊 Found $totalProcessed classifications to process');
      
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
            
            debugPrint('✅ Generated thumbnail for: ${classification.itemName}');
            
            // Progress indicator
            if (thumbnailsGenerated % 10 == 0) {
              debugPrint('📊 Progress: $thumbnailsGenerated/$totalProcessed thumbnails generated');
            }
          } else {
            skipped++;
            debugPrint('⏭️ Skipped (no image): ${classification.itemName}');
          }
        } catch (e) {
          errors++;
          debugPrint('❌ Error processing ${classification.itemName}: $e');
        }
      }
      
      // Batch update all classifications if any thumbnails were generated
      if (thumbnailsGenerated > 0) {
        await _batchUpdateClassifications(classifications);
        debugPrint('💾 Batch updated $thumbnailsGenerated classifications with new thumbnails');
      }
      
      final result = ThumbnailMigrationResult(
        success: true,
        totalProcessed: totalProcessed,
        thumbnailsGenerated: thumbnailsGenerated,
        skipped: skipped,
        errors: errors,
        message: 'Thumbnail migration completed successfully',
      );
      
      debugPrint('📊 Thumbnail Migration Summary:');
      debugPrint('📊 Total processed: $totalProcessed');
      debugPrint('📊 Thumbnails generated: $thumbnailsGenerated');
      debugPrint('📊 Skipped: $skipped');
      debugPrint('📊 Errors: $errors');
      
      return result;
    } catch (e) {
      debugPrint('❌ Thumbnail migration failed: $e');
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
            debugPrint('Error decoding web image: $e');
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
      debugPrint('Error generating thumbnail for ${classification.itemName}: $e');
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
      debugPrint('Error resolving relative path: $e');
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
      
      debugPrint('💾 Successfully batch updated ${classifications.length} classifications');
    } catch (e) {
      debugPrint('❌ Error batch updating classifications: $e');
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