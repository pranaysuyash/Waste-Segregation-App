import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:uuid/uuid.dart';
import 'package:waste_segregation_app/utils/safe_file_path.dart';
import 'package:waste_segregation_app/utils/waste_app_logger.dart';

/// Provides helper methods for saving and loading images across
/// platforms with basic retry logic for network requests.
class EnhancedImageService {
  factory EnhancedImageService() => _instance;
  EnhancedImageService._();
  static final EnhancedImageService _instance = EnhancedImageService._();

  static const _imagesDirName = 'images';
  static const _thumbnailsDirName = 'thumbnails';
  static const _tempImagesSubDirName = 'app_temp_images';

  static const _maxThumbnailCacheMB = 100;
  static const _maxThumbnailFiles = 4000;

  static const _maxDownloadBytes = 25 * 1024 * 1024;
  static const _networkTimeout = Duration(seconds: 15);

  /// Save raw image bytes to a permanent file location and
  /// return the file path. On web platforms, returns a base64 data URL.
  Future<String> saveImagePermanently(Uint8List bytes,
      {String? fileName}) async {
    if (bytes.isEmpty) {
      WasteAppLogger.severe('image_save_failed',
          context: {'reason': 'empty_bytes'});
      throw ArgumentError('Cannot save empty image bytes');
    }

    final detectedMime = _detectImageMime(bytes);
    final extension = _extensionForMime(detectedMime);

    if (kIsWeb) {
      return _saveWebImageAsDataUrl(bytes, detectedMime);
    }

    final dir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(dir.path, _imagesDirName));
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    final id = const Uuid().v4();
    final safeName = fileName != null
        ? '${sanitizeFileName(fileName, fallback: id)}_$id$extension'
        : '$id$extension';
    final file = File(safeJoinWithin(imagesDir.path, safeName));
    await file.writeAsBytes(bytes, flush: true);

    WasteAppLogger.info('image_save_started',
        context: {'path': file.path, 'size_bytes': bytes.length, 'mime': detectedMime});
    return file.path;
  }

  /// Copy an existing image file to a permanent location and
  /// return the new file path.
  Future<String> saveFilePermanently(File source) async {
    final bytes = await source.readAsBytes();
    return saveImagePermanently(bytes, fileName: p.basename(source.path));
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
    final thumbnailBytes = await _generateThumbnailBytes(bytes);

    if (kIsWeb) {
      final base64Data = base64Encode(thumbnailBytes);
      return 'web_thumbnail:data:image/jpeg;base64,$base64Data';
    }

    final dir = await getApplicationDocumentsDirectory();
    final thumbnailsDir = Directory(p.join(dir.path, _thumbnailsDirName));
    if (!await thumbnailsDir.exists()) {
      await thumbnailsDir.create(recursive: true);
    }

    final id = const Uuid().v4();
    final name = baseName != null
        ? '${sanitizeFileName(baseName, fallback: id)}_${DateTime.now().millisecondsSinceEpoch}.jpg'
        : '$id.jpg';

    final file = File(safeJoinWithin(thumbnailsDir.path, name));
    await file.writeAsBytes(thumbnailBytes, flush: true);

    await _maintainThumbnailCache(thumbnailsDir);

    return file.path;
  }

  /// Generate thumbnail bytes from image data
  ///
  /// Creates a 256px max-edge thumbnail with proper orientation.
  /// Throws on failure rather than returning original bytes.
  Future<Uint8List> _generateThumbnailBytes(Uint8List bytes) async {
    if (bytes.isEmpty) {
      throw ArgumentError('Cannot generate thumbnail from empty bytes');
    }
    final raw = img.decodeImage(bytes);
    if (raw == null) {
      WasteAppLogger.severe('thumbnail_generate_failed',
          context: {'reason': 'decode_failed'});
      throw const FormatException('Failed to decode image for thumbnail');
    }

    if (raw.width <= 0 || raw.height <= 0) {
      throw const FormatException('Image has invalid dimensions');
    }

    final oriented = img.bakeOrientation(raw);

    final int thumbWidth;
    final int thumbHeight;
    if (oriented.width >= oriented.height) {
      thumbWidth = 256;
      thumbHeight = (oriented.height * 256 / oriented.width).round().clamp(1, 256);
    } else {
      thumbHeight = 256;
      thumbWidth = (oriented.width * 256 / oriented.height).round().clamp(1, 256);
    }

    final thumb = img.copyResize(oriented,
        width: thumbWidth, height: thumbHeight);

    return Uint8List.fromList(img.encodeJpg(thumb, quality: 80));
  }

  /// Download a network image with retry logic. Returns the image
  /// bytes or null if all attempts fail.
  Future<Uint8List?> fetchImageWithRetry(String url, {int retries = 3}) async {
    final uri = Uri.parse(url);

    if (!_isAllowedScheme(uri)) {
      WasteAppLogger.severe('network_image_fetch_failed',
          context: {'reason': 'disallowed_scheme', 'scheme': uri.scheme});
      return null;
    }

    for (var attempt = 0; attempt < retries; attempt++) {
      try {
        final response = await http
            .get(Uri.parse(url))
            .timeout(_networkTimeout);

        if (response.statusCode != 200) {
          WasteAppLogger.severe('network_image_fetch_failed',
              context: {
                'status_code': response.statusCode,
                'attempt': attempt + 1,
                'host': uri.host,
              });
          continue;
        }

        if (response.bodyBytes.isEmpty) {
          WasteAppLogger.severe('network_image_fetch_failed',
              context: {'reason': 'empty_response', 'attempt': attempt + 1});
          continue;
        }

        if (response.bodyBytes.length > _maxDownloadBytes) {
          WasteAppLogger.severe('network_image_fetch_failed',
              context: {
                'reason': 'exceeds_max_size',
                'size_bytes': response.bodyBytes.length,
                'max_bytes': _maxDownloadBytes,
              });
          return null;
        }

        if (!_isImageBytes(response.bodyBytes)) {
          WasteAppLogger.severe('network_image_fetch_failed',
              context: {
                'reason': 'not_an_image',
                'content_type': response.headers['content-type'] ?? 'unknown',
                'attempt': attempt + 1,
              });
          continue;
        }

        return response.bodyBytes;
      } catch (e) {
        WasteAppLogger.severe('network_image_fetch_failed',
            context: {
              'reason': 'exception',
              'attempt': attempt + 1,
              'host': uri.host,
            },
            error: e);
      }
      await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
    }
    return null;
  }

  /// Resolve a potentially trusted local path to a verified absolute path.
  ///
  /// Accepts:
  /// - Absolute paths already under app docs/images or app docs/thumbnails
  /// - Absolute paths under app docs root
  /// - Relative "images/foo.jpg"
  /// - Relative "thumbnails/foo.jpg"
  ///
  /// Rejects:
  /// - Path traversal attempts
  /// - External absolute paths (outside app docs)
  /// - Non-existing paths
  Future<String?> resolveTrustedLocalPath(String inputPath) async {
    if (kIsWeb || inputPath.isEmpty) {
      return null;
    }

    final dir = await getApplicationDocumentsDirectory();
    final normalizedDocsRoot = p.normalize(dir.path);

    final allowedPrefixes = [
      p.join(normalizedDocsRoot, _imagesDirName),
      p.join(normalizedDocsRoot, _thumbnailsDirName),
      normalizedDocsRoot,
    ];

    if (p.isAbsolute(inputPath)) {
      final normalizedInput = p.normalize(inputPath);
      for (final prefix in allowedPrefixes) {
        final prefixWithSep = prefix.endsWith(p.separator)
            ? prefix
            : '$prefix${p.separator}';
        if (normalizedInput == prefix ||
            normalizedInput.startsWith(prefixWithSep)) {
          if (await File(normalizedInput).exists()) {
            return normalizedInput;
          }
          return null;
        }
      }
      return null;
    }

    for (final baseDir in allowedPrefixes) {
      try {
        final candidate = safeJoinWithin(baseDir, inputPath);
        if (await File(candidate).exists()) {
          return candidate;
        }
      } catch (_) {
        continue;
      }
    }

    return null;
  }

  /// Maintain thumbnail cache size within limits using LRU eviction.
  /// Deletes oldest files first until both file-count and total-size
  /// targets are satisfied.
  Future<void> _maintainThumbnailCache(Directory thumbnailsDir) async {
    try {
      if (!await thumbnailsDir.exists()) return;

      final files = <FileSystemEntity>[];
      await for (final entity in thumbnailsDir.list()) {
        if (entity is File && entity.path.endsWith('.jpg')) {
          files.add(entity);
        }
      }

      if (files.isEmpty) return;

      final filesWithStats = <_FileWithStat>[];
      for (final file in files) {
        final stat = await (file as File).stat();
        filesWithStats.add(_FileWithStat(file, stat));
      }

      filesWithStats.sort((a, b) => a.stat.modified.compareTo(b.stat.modified));

      final targetFileCount = (_maxThumbnailFiles * 0.8).round();
      const targetSizeBytes = (_maxThumbnailCacheMB * 0.8) * 1024 * 1024;

      var currentCount = filesWithStats.length;
      var currentSizeBytes =
          filesWithStats.fold<int>(0, (sum, f) => sum + f.stat.size);

      var removed = 0;
      for (final entry in filesWithStats) {
        if (currentCount <= targetFileCount &&
            currentSizeBytes <= targetSizeBytes) {
          break;
        }
        try {
          await entry.file.delete();
          currentCount--;
          currentSizeBytes -= entry.stat.size;
          removed++;
          WasteAppLogger.info('thumbnail_cache_evicted',
              context: {
                'filename': p.basename(entry.file.path),
                'size_bytes': entry.stat.size,
              });
        } catch (e) {
          WasteAppLogger.severe('thumbnail_cache_evict_failed',
              context: {'filename': p.basename(entry.file.path)},
              error: e);
        }
      }

      if (removed > 0) {
        WasteAppLogger.info('thumbnail_cache_maintained',
            context: {
              'removed_count': removed,
              'remaining_count': currentCount,
              'remaining_size_mb': (currentSizeBytes / (1024 * 1024)).toStringAsFixed(1),
            });
      }
    } catch (e) {
      WasteAppLogger.severe('thumbnail_cache_maintenance_failed',
          error: e);
    }
  }

  /// Clean up orphaned thumbnails that no longer have corresponding classifications
  Future<void> cleanUpOrphanedThumbnails(
      List<String> validThumbnailPaths) async {
    if (kIsWeb) return;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final thumbnailsDir = Directory(p.join(dir.path, _thumbnailsDirName));

      if (!await thumbnailsDir.exists()) return;

      final validPaths = validThumbnailPaths.toSet();
      var orphansRemoved = 0;

      await for (final entity in thumbnailsDir.list()) {
        if (entity is File && entity.path.endsWith('.jpg')) {
          final relativePath = 'thumbnails/${p.basename(entity.path)}';

          if (!validPaths.contains(relativePath) &&
              !validPaths.contains(entity.path)) {
            try {
              await entity.delete();
              orphansRemoved++;
            } catch (e) {
              WasteAppLogger.severe('orphaned_thumbnail_delete_failed',
                  context: {'filename': p.basename(entity.path)},
                  error: e);
            }
          }
        }
      }

      if (orphansRemoved > 0) {
        WasteAppLogger.info('orphaned_thumbnails_cleaned',
            context: {'removed_count': orphansRemoved});
      }
    } catch (e) {
      WasteAppLogger.severe('orphaned_thumbnail_cleanup_failed', error: e);
    }
  }

  /// Remove app-owned temp image files older than the specified duration.
  /// Only cleans files in an app-specific subdirectory to avoid affecting
  /// other app/plugin temp files.
  Future<void> cleanUpTempImages(
      {Duration olderThan = const Duration(days: 1)}) async {
    final tempDir = await getTemporaryDirectory();
    final appTempDir = Directory(p.join(tempDir.path, _tempImagesSubDirName));

    if (!await appTempDir.exists()) return;

    final now = DateTime.now();
    var removedCount = 0;

    await for (final entity in appTempDir.list()) {
      if (entity is File) {
        final stat = await entity.stat();
        if (now.difference(stat.modified) > olderThan) {
          try {
            await entity.delete();
            removedCount++;
          } catch (e) {
            WasteAppLogger.severe('temp_image_delete_failed',
                context: {'filename': p.basename(entity.path)},
                error: e);
          }
        }
      }
    }

    if (removedCount > 0) {
      WasteAppLogger.info('temp_images_cleaned',
          context: {'removed_count': removedCount, 'older_than_hours': olderThan.inHours});
    }
  }

  // ─── Private helpers ───────────────────────────────────────────

  String _saveWebImageAsDataUrl(Uint8List bytes, String mimeType) {
    final base64Data = base64Encode(bytes);
    WasteAppLogger.info('image_save_started',
        context: {'format': 'web_data_url', 'mime': mimeType, 'size_bytes': bytes.length});
    return 'web_image:data:$mimeType;base64,$base64Data';
  }

  /// Detect image MIME type from magic bytes.
  /// Returns 'image/jpeg' as default when unknown.
  String _detectImageMime(Uint8List bytes) {
    if (bytes.length < 4) return 'image/jpeg';

    if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
      return 'image/png';
    }
    if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) {
      return 'image/gif';
    }
    if (bytes[0] == 0xFF && (bytes[1] & 0xE0) == 0xE0) {
      return 'image/jpeg';
    }
    if (bytes.length >= 12 &&
        bytes[8] == 0x57 && bytes[9] == 0x45 && bytes[10] == 0x42 && bytes[11] == 0x50) {
      return 'image/webp';
    }
    if (bytes[0] == 0x42 && bytes[1] == 0x4D) {
      return 'image/bmp';
    }

    return 'image/jpeg';
  }

  /// Choose file extension from detected MIME type, not from user-supplied filename.
  String _extensionForMime(String mime) {
    switch (mime) {
      case 'image/png':
        return '.png';
      case 'image/gif':
        return '.gif';
      case 'image/webp':
        return '.webp';
      case 'image/bmp':
        return '.bmp';
      default:
        return '.jpg';
    }
  }

  /// Quick magic-byte check that bytes look like an image.
  /// Returns false for empty/trivial/clearly-non-image data.
  bool _isImageBytes(Uint8List bytes) {
    if (bytes.length < 4) return false;
    final mime = _detectImageMime(bytes);
    return mime != 'image/jpeg' || (bytes[0] == 0xFF && (bytes[1] & 0xE0) == 0xE0);
  }

  bool _isAllowedScheme(Uri uri) {
    return uri.scheme == 'http' || uri.scheme == 'https';
  }
}

/// Internal struct for cache eviction sorting
class _FileWithStat {
  const _FileWithStat(this.file, this.stat);

  final File file;
  final FileStat stat;
}
