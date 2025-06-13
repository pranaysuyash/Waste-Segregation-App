import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

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
      await Share.share(text, subject: subject);

      if (onShareComplete != null) {
        onShareComplete!('Shared');
      }
    } catch (e) {
      debugPrint('Error in ShareService.share: $e');
      if (onShareComplete != null) {
        onShareComplete!('Error: $e');
      }
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

  // Legacy methods removed
}
