import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'web_interop.dart' as web_interop;
import '../screens/web_fallback_screen.dart';

/// A utility class to help detect and handle web-specific issues
class WebUtils {
  /// Shows a fallback screen if the app is running on web and encounters issues
  static void showWebFallbackIfNeeded(BuildContext context) {
    if (kIsWeb) {
      if (web_interop.hasWebError) {
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
        return web_interop.hasCameraSupport;
      case 'share':
        return web_interop.hasShareSupport;
      case 'clipboard':
        return web_interop.hasClipboardSupport;
      case 'file':
        return web_interop.hasFileSupport;
      default:
        return true; // Assume support for unspecified features
    }
  }
}
