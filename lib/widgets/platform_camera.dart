import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

/// A platform-agnostic camera interface that provides consistent camera
/// functionality across different platforms.
class PlatformCamera {
  // ImagePicker instance for capturing images
  static final ImagePicker _picker = ImagePicker();

  /// Sets up any necessary camera initialization
  /// Returns true if camera setup was successful
  static Future<bool> setup() async {
    try {
      if (kIsWeb) {
        // Web doesn't need special setup
        return true;
      }
      
      if (Platform.isAndroid || Platform.isIOS) {
        // Check camera permission first
        final cameraStatus = await Permission.camera.status;
        
        if (cameraStatus.isGranted) {
          debugPrint('Camera permission already granted');
          return true;
        } else if (cameraStatus.isDenied) {
          debugPrint('Camera permission denied, requesting...');
          final result = await Permission.camera.request();
          return result.isGranted;
        } else if (cameraStatus.isPermanentlyDenied) {
          debugPrint('Camera permission permanently denied');
          return false;
        }
        
        return false;
      }
    } catch (e) {
      debugPrint('Camera setup error: $e');
    }

    // Default return false for unsupported platforms
    return false;
  }

  /// Captures an image using the platform-appropriate method
  /// Returns an XFile containing the image, or null if capture failed
  static Future<XFile?> takePicture() async {
    try {
      debugPrint('Attempting to take picture...');
      
      // Use image_picker for consistent camera interface
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null) {
        debugPrint('Image captured successfully: ${image.path}');

        // For mobile platforms, verify file exists
        if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
          final file = File(image.path);
          if (await file.exists()) {
            final fileSize = await file.length();
            debugPrint('Image file verified, size: $fileSize bytes');
            return image;
          } else {
            debugPrint('Camera captured image file does not exist: ${image.path}');
            return null;
          }
        }

        return image;
      } else {
        debugPrint('No image captured - user may have canceled');
        return null;
      }
    } catch (e) {
      debugPrint('Error taking picture: $e');
      return null;
    }
  }

  /// Cleans up any camera resources
  static Future<void> cleanup() async {
    // Currently a no-op on all platforms
    // Could be extended for platform-specific cleanup
    debugPrint('Camera cleanup completed');
  }

  /// Checks if camera is available on the device
  static Future<bool> isCameraAvailable() async {
    if (kIsWeb) {
      // Web camera availability is handled by the browser
      return true;
    }

    try {
      if (Platform.isAndroid || Platform.isIOS) {
        // Check if camera permission is available
        final status = await Permission.camera.status;
        return status.isGranted || status.isDenied; // Available if not permanently denied
      }
    } catch (e) {
      debugPrint('Error checking camera availability: $e');
    }

    return false;
  }
}
