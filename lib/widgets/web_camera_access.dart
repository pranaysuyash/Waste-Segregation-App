import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class WebCameraAccess {
  // Setup camera access - returns true if camera is available (always true on web with image_picker_for_web)
  static Future<bool> setup() async {
    // On web, assume camera is available if running in browser
    if (kIsWeb) return true;
    // On mobile, handled by image_picker
    return true;
  }
}

// Helper method for getting images from the camera (works on web and mobile)
Future<XFile?> getImageFromWebCamera(BuildContext context) async {
  // Use image_picker for both web and mobile
  return ImagePicker().pickImage(source: ImageSource.camera);
}