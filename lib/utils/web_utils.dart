import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:js' as js;
import '../screens/web_fallback_screen.dart';

/// A utility class to help detect and handle web-specific issues
class WebUtils {
  /// Shows a fallback screen if the app is running on web and encounters issues
  static void showWebFallbackIfNeeded(BuildContext context) {
    if (kIsWeb) {
      // Check if a specific web initialization error occurred
      bool hasWebError = false;
      
      try {
        // Try to access _flutter.buildConfig
        final dynamic flutterObj = js.context['_flutter'];
        
        // If _flutter or buildConfig doesn't exist, there's an error
        hasWebError = flutterObj == null || js.context['_flutter']['buildConfig'] == null;
      } catch (e) {
        // If we can't even run this check, assume there's an error
        hasWebError = true;
      }
      
      if (hasWebError) {
        // Navigate to the fallback screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const WebFallbackScreen()),
        );
      }
    }
  }
  
  /// Checks if the current web platform supports a specific feature
  static bool isSupportedOnWeb(String feature) {
    if (!kIsWeb) return true; // Not relevant for non-web platforms
    
    switch (feature.toLowerCase()) {
      case 'camera':
        return _checkCameraSupport();
      case 'share':
        return _checkShareSupport();
      case 'clipboard':
        return _checkClipboardSupport();
      case 'file':
        return _checkFileSupport();
      default:
        return true; // Assume support for unspecified features
    }
  }
  
  // Internal methods to check for specific feature support
  
  static bool _checkCameraSupport() {
    try {
      // Check if navigator.mediaDevices exists
      final dynamic navigator = js.context['navigator'];
      return navigator != null && js.context['navigator']['mediaDevices'] != null;
    } catch (e) {
      return false;
    }
  }
  
  static bool _checkShareSupport() {
    try {
      // Check if navigator.share exists
      final dynamic navigator = js.context['navigator'];
      return navigator != null && js.context['navigator']['share'] != null;
    } catch (e) {
      return false;
    }
  }
  
  static bool _checkClipboardSupport() {
    try {
      // Check if navigator.clipboard exists
      final dynamic navigator = js.context['navigator'];
      return navigator != null && js.context['navigator']['clipboard'] != null;
    } catch (e) {
      return false;
    }
  }
  
  static bool _checkFileSupport() {
    try {
      // Check if Window.File exists
      return js.context['File'] != null;
    } catch (e) {
      return false;
    }
  }
}
