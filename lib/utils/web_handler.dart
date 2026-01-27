import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:waste_segregation_app/utils/waste_app_logger.dart';

/// A utility class for handling web-specific image operations
class WebImageHandler {
  /// Converts a blob URL XFile to image data
  static Future<Uint8List?> xFileToBytes(XFile xFile) async {
    try {
      WasteAppLogger.info('Converting XFile to bytes: ${xFile.path}');
      return await xFile.readAsBytes();
    } catch (e) {
      WasteAppLogger.severe('Error converting XFile to bytes: $e');
      return null;
    }
  }

  /// Determines if the path is a web blob URL
  static bool isBlobUrl(String path) {
    return path.startsWith('blob:');
  }

  /// Extracts a display name from a blob URL or path
  static String getDisplayName(String path) {
    // Extract the last part of a blob URL as a simple ID
    if (isBlobUrl(path)) {
      // For blob URLs, extract the UUID part
      final uriParts = path.split('/');
      return uriParts.last.length > 8
          ? uriParts.last.substring(0, 8)
          : uriParts.last;
    }

    // Otherwise extract filename from a regular path
    final parts = path.split('/');
    return parts.isNotEmpty ? parts.last : 'unknown';
  }

  /// Validates if a web image blob URL is available
  static Future<bool> isWebImageValid(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      return bytes.isNotEmpty;
    } catch (e) {
      WasteAppLogger.severe('Web image validation failed: $e');
      return false;
    }
  }
}
