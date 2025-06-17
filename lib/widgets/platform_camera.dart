import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/waste_app_logger.dart';

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
          WasteAppLogger.userAction('camera_permission_granted');
          return true;
        } else if (cameraStatus.isDenied) {
          WasteAppLogger.userAction('camera_permission_requested');
          final result = await Permission.camera.request();
          if (result.isGranted) {
            WasteAppLogger.userAction('camera_permission_granted_after_request');
          } else {
            WasteAppLogger.userAction('camera_permission_denied_after_request');
          }
          return result.isGranted;
        } else if (cameraStatus.isPermanentlyDenied) {
          WasteAppLogger.warning('Camera permission permanently denied', null, null, {
            'permission_status': 'permanently_denied'
          });
          return false;
        }
        
        return false;
      }
    } catch (e) {
      WasteAppLogger.severe('Camera setup failed', e, null, {
        'platform': kIsWeb ? 'web' : Platform.operatingSystem
      });
    }

    // Default return false for unsupported platforms
    return false;
  }

  /// Captures an image using the platform-appropriate method
  /// Returns an XFile containing the image, or null if capture failed
  static Future<XFile?> takePicture() async {
    try {
      WasteAppLogger.userAction('camera_capture_started', context: {
        'platform': kIsWeb ? 'web' : Platform.operatingSystem
      });
      
      // Use image_picker for consistent camera interface
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null) {
        WasteAppLogger.userAction('camera_capture_success', context: {
          'image_path': image.path,
          'platform': kIsWeb ? 'web' : Platform.operatingSystem
        });

        // For mobile platforms, verify file exists
        if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
          final file = File(image.path);
          if (await file.exists()) {
            final fileSize = await file.length();
            WasteAppLogger.performanceLog('image_file_verification', 0, context: {
              'file_size_bytes': fileSize,
              'image_path': image.path
            });
            return image;
          } else {
            WasteAppLogger.severe('Camera captured image file does not exist', null, null, {
              'image_path': image.path,
              'platform': Platform.operatingSystem
            });
            return null;
          }
        }

        return image;
      } else {
        WasteAppLogger.userAction('camera_capture_cancelled');
        return null;
      }
    } catch (e) {
      WasteAppLogger.severe('Camera capture failed', e, null, {
        'platform': kIsWeb ? 'web' : Platform.operatingSystem
      });
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
