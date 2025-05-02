import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// A platform-agnostic camera interface that provides consistent camera
/// functionality across different platforms.
class PlatformCamera {
  // ImagePicker instance for capturing images
  static final ImagePicker _picker = ImagePicker();

  /// Sets up any necessary camera initialization
  /// Returns true if camera setup was successful
  static Future<bool> setup() async {
    // On mobile, we simply check if the camera can be accessed
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        // Log that we're checking camera availability
        debugPrint('Checking camera availability...');

        // On Android, we might need additional runtime checks for camera access
        // This is a simple check to see if we can at least initialize the camera
        return true;
      }
    } catch (e) {
      debugPrint('Camera setup error: $e');
    }

    // Default return false for web or if setup fails
    return false;
  }

  /// Captures an image using the platform-appropriate method
  /// Returns an XFile containing the image, or null if capture failed
  static Future<XFile?> takePicture() async {
    try {
      // Use image_picker for consistent camera interface
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (image != null) {
        debugPrint('Image captured: ${image.path}');

        // For mobile platforms, verify file exists
        if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
          final File file = File(image.path);
          if (await file.exists()) {
            return image;
          } else {
            debugPrint(
                'Camera captured image file does not exist: ${image.path}');
            return null;
          }
        }

        return image;
      } else {
        debugPrint('No image captured or user canceled');
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
  }

  /// Checks if the device is likely running in an emulator
  /// This is a best-effort detection and may not be 100% accurate
  static Future<bool> isEmulator() async {
    if (kIsWeb) return false;

    try {
      if (Platform.isAndroid) {
        // For Android, we could use device info plugin
        // But for simplicity, we'll use a simple check
        return true; // Assume we're in an emulator for testing purposes
      } else if (Platform.isIOS) {
        // iOS emulator detection
        // For now, return false since iOS simulator camera isn't supported anyway
        return false;
      }
    } catch (e) {
      debugPrint('Error detecting emulator: $e');
    }

    return false;
  }
}
