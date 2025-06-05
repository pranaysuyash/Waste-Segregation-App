import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

// Create a simple platform-conditional sharing implementation that doesn't rely on context
class ShareService {
  // Callback for when sharing is complete
  static void Function(String message)? onShareComplete;

  // Share content across platforms
  static Future<void> share({
    required String text,
    String? subject,
    List<String>? files,
    BuildContext? context,
  }) async {
    try {
      debugPrint('ShareService.share called');
      
      if (kIsWeb) {
        // Web implementation
        await _shareOnWeb(text, subject, context);
      } else {
        // Native implementation - simpler approach for iOS
        await _shareOnNative(text, subject, files, context);
      }
      
      debugPrint('ShareService.share completed');
      
      // Notify caller that sharing is complete
      if (onShareComplete != null) {
        onShareComplete!('Content copied to clipboard');
      }
      
      // If context is provided, show a snackbar
      if (context != null && context.mounted) {
        _showSnackBar(context, 'Content copied to clipboard');
      }
    } catch (e) {
      debugPrint('Error in ShareService.share: $e');
      
      // Notify caller of error
      if (onShareComplete != null) {
        onShareComplete!('Error: $e');
      }
      
      // If context is provided, show error snackbar
      if (context != null && context.mounted) {
        _showSnackBar(context, 'Error sharing content');
      }
    }
  }

  // Show a snackbar if context is available
  static void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Web implementation with clipboard fallback
  static Future<void> _shareOnWeb(String text, String? subject, BuildContext? context) async {
    debugPrint('Copying to clipboard: $text');
    
    // Just copy to clipboard for simplicity
    await Clipboard.setData(ClipboardData(text: text));
  }

  // Native implementation - simple clipboard approach
  static Future<void> _shareOnNative(String text, String? subject, List<String>? files, BuildContext? context) async {
    // Just copy to clipboard for simplicity
    await Clipboard.setData(ClipboardData(text: text));
  }
}
