import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

// Simple stub class for cross-platform compatibility
class WebCameraHelper {
  factory WebCameraHelper() => _instance;
  WebCameraHelper._internal();
  // Singleton
  static final WebCameraHelper _instance = WebCameraHelper._internal();

  // Platform-agnostic stubs
  Future<void> initialize() async {
    // Only works on web
    if (!kIsWeb) return;
  }

  Future<XFile?> takePicture() async {
    // Only works on web
    if (!kIsWeb) return null;

    // On non-web platforms, use standard image picker
    return null;
  }

  void dispose() {
    // Cleanup resources
  }
}
