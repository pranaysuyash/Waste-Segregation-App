import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import '../widgets/responsive_text.dart';

/// A simple web-specific fallback page that can be used if Firebase initialization fails
class WebFallbackScreen extends StatelessWidget {
  const WebFallbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const ResponsiveAppBarTitle(
          title: 'WasteWise',
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.recycling,
              size: 100,
              color: Colors.green,
            ),
            const SizedBox(height: 24),
            const Text(
              'Waste Segregation App',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'This app works best on mobile devices.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // Clipboard sharing
                _copyToClipboard(
                  'Check out this Waste Segregation App! It helps you properly sort your waste using AI.',
                  context,
                );
              },
              child: const Text('Share App Info'),
            ),
            const SizedBox(height: 16),
            if (kIsWeb)
              const Text(
                'Note: Some features like image capture might not be fully available in the web version.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Simple clipboard share method
  void _copyToClipboard(String text, BuildContext context) {
    // Simplified version that works on all platforms
    try {
      Clipboard.setData(ClipboardData(text: text));
      _showSnackBar(context, 'Copied to clipboard!');
    } catch (e) {
      _showSnackBar(context, 'Failed to copy: $e');
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
