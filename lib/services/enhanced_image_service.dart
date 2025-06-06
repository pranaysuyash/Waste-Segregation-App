import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Provides helper methods for saving and loading images across
/// platforms with basic retry logic for network requests.
class EnhancedImageService {
  factory EnhancedImageService() => _instance;
  EnhancedImageService._();
  static final EnhancedImageService _instance = EnhancedImageService._();

  /// Directory name for stored images.
  static const _imagesDirName = 'images';

  /// Save raw image bytes to a permanent file location and
  /// return the file path.
  Future<String> saveImagePermanently(Uint8List bytes, {String? fileName}) async {
    if (kIsWeb) {
      final base64Data = base64Encode(bytes);
      // Prefix with custom identifier for easier detection in widgets
      return 'web_image:data:image/jpeg;base64,$base64Data';
    }

    final dir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(dir.path, _imagesDirName));
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    final name = fileName ?? '${DateTime.now().millisecondsSinceEpoch}.jpg';
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
