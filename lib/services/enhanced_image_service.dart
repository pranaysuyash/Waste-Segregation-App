import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:uuid/uuid.dart';

/// Provides helper methods for saving and loading images across
/// platforms with basic retry logic for network requests.
class EnhancedImageService {
  factory EnhancedImageService() => _instance;
  EnhancedImageService._();
  static final EnhancedImageService _instance = EnhancedImageService._();

  /// Directory name for stored images.
  static const _imagesDirName = 'images';
  
  /// Directory name for stored thumbnails.
  static const _thumbnailsDirName = 'thumbnails';

  /// Save raw image bytes to a permanent file location and
  /// return the file path. On web platforms, returns a base64 data URL.
  Future<String> saveImagePermanently(Uint8List bytes, {String? fileName}) async {
    if (kIsWeb) {
      final base64Data = base64Encode(bytes);
      // Detect image format or default to jpeg
      var mimeType = 'image/jpeg';
      if (bytes.length > 4) {
        // PNG signature: 0x89 0x50 0x4E 0x47
        if (bytes[0] == 0x89 &&
            bytes[1] == 0x50 &&
            bytes[2] == 0x4E &&
            bytes[3] == 0x47) {
          mimeType = 'image/png';
        }
        // GIF signature: 'G' 'I' 'F'
        else if (bytes[0] == 0x47 &&
                 bytes[1] == 0x49 &&
                 bytes[2] == 0x46) {
          mimeType = 'image/gif';
        }
      }
      // Prefix with custom identifier for easier detection in widgets
      return 'web_image:data:$mimeType;base64,$base64Data';
    }

    final dir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(dir.path, _imagesDirName));
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    // Use UUID for atomic file naming to prevent collisions
    final id = const Uuid().v4();
    final extension = fileName != null ? p.extension(fileName) : '.jpg';
    final name = fileName ?? '$id$extension';
    final file = File(p.join(imagesDir.path, name));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  /// Copy an existing image file to a permanent location and
  /// return the new file path.
  Future<String> saveFilePermanently(File source) async {
    final bytes = await source.readAsBytes();
    final fileName = p.basename(source.path);
    return saveImagePermanently(bytes, fileName: fileName);
  }

  /// Generate and save a dedicated thumbnail for an image
  /// 
  /// This creates a 256px max-edge thumbnail with proper orientation
  /// and saves it to the thumbnails directory.
  /// 
  /// [bytes]: The raw image data
  /// [baseName]: Optional base name for the thumbnail file
  /// 
  /// Returns the absolute path to the saved thumbnail
  Future<String> saveThumbnail(Uint8List bytes, {String? baseName}) async {
    if (kIsWeb) {
      // For web, return a smaller base64 data URL
      final thumbnailBytes = await _generateThumbnailBytes(bytes);
      final base64Data = base64Encode(thumbnailBytes);
      return 'web_thumbnail:data:image/jpeg;base64,$base64Data';
    }

    final dir = await getApplicationDocumentsDirectory();
    final thumbnailsDir = Directory(p.join(dir.path, _thumbnailsDirName));
    if (!await thumbnailsDir.exists()) {
      await thumbnailsDir.create(recursive: true);
    }

    // Generate thumbnail bytes
    final thumbnailBytes = await _generateThumbnailBytes(bytes);
    
    // Create unique filename
    final id = const Uuid().v4();
    final name = baseName != null 
        ? '${baseName}_${DateTime.now().millisecondsSinceEpoch}.jpg'
        : '$id.jpg';
    
    final file = File(p.join(thumbnailsDir.path, name));
    await file.writeAsBytes(thumbnailBytes, flush: true);
    return file.path;
  }

  /// Generate thumbnail bytes from image data
  /// 
  /// Creates a 256px max-edge thumbnail with proper orientation
  Future<Uint8List> _generateThumbnailBytes(Uint8List bytes) async {
    try {
      final img.Image? raw = img.decodeImage(bytes);
      if (raw == null) throw Exception('Failed to decode image for thumbnail');

      // Bake orientation to handle EXIF rotation
      final oriented = img.bakeOrientation(raw);
      
      // Keep aspect ratio, max edge = 256px
      final thumb = img.copyResize(oriented, width: 256);
      
      // Encode with good quality for thumbnails
      return Uint8List.fromList(img.encodeJpg(thumb, quality: 80));
    } catch (e) {
      debugPrint('Error generating thumbnail: $e');
      // Return original bytes if thumbnail generation fails
      return bytes;
    }
  }

  /// Download a network image with retry logic. Returns the image
  /// bytes or null if all attempts fail.
  Future<Uint8List?> fetchImageWithRetry(String url, {int retries = 3}) async {
    for (var attempt = 0; attempt < retries; attempt++) {
      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          return response.bodyBytes;
        }
        debugPrint('Image download failed with status ${response.statusCode}');
      } catch (e) {
        debugPrint('Image download error on attempt ${attempt + 1}: $e');
      }
      await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
    }
    return null;
  }

  /// Remove files from the temporary directory older than the
  /// specified [olderThan] duration to free space.
  Future<void> cleanUpTempImages({Duration olderThan = const Duration(days: 1)}) async {
    final dir = await getTemporaryDirectory();
    final now = DateTime.now();
    if (!await dir.exists()) return;
    await for (final entity in dir.list()) {
      if (entity is File) {
        final stat = await entity.stat();
        if (now.difference(stat.modified) > olderThan) {
          try {
            await entity.delete();
          } catch (_) {}
        }
      }
    }
  }
}
