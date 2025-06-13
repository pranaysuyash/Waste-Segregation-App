import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import '../models/waste_classification.dart';
import '../screens/result_screen.dart';

/// Handles deep linking for sharing and navigation using app_links
class DynamicLinkService {
  static const _baseUrl = 'https://wastewise.app';
  static AppLinks? _appLinks;

  /// Create a shareable link that opens a result screen for [classification].
  static String createResultLink(WasteClassification classification) {
    // Create a web-compatible URL that can be shared
    return '$_baseUrl/result?id=${classification.id}'
        '&item=${Uri.encodeComponent(classification.itemName)}'
        '&category=${Uri.encodeComponent(classification.category)}';
  }

  /// Initialize listeners for incoming links.
  static Future<void> initDynamicLinks(BuildContext context) async {
    _appLinks = AppLinks();
    
    // Handle initial link if app was launched from a link
    try {
      final initialLink = await _appLinks!.getInitialLink();
      if (initialLink != null) {
        if (!context.mounted) return;
        _handleLinkData(initialLink, context);
      }
    } catch (e) {
      // Handle error silently - app wasn't launched from a link
    }

    // Listen for incoming links when app is already running
    _appLinks!.uriLinkStream.listen(
      (uri) {
        if (!context.mounted) return;
        _handleLinkData(uri, context);
      },
      onError: (err) {
        // Handle error silently
      },
    );
  }

  static void _handleLinkData(Uri? deepLink, BuildContext context) {
    if (deepLink == null) return;
    
    if (deepLink.pathSegments.contains('result')) {
      final id = deepLink.queryParameters['id'];
      final item = deepLink.queryParameters['item'];
      final category = deepLink.queryParameters['category'];
      
      if (id != null && item != null && category != null) {
        final classification = WasteClassification(
          id: id,
          itemName: item,
          category: category,
          explanation: '',
          disposalInstructions: DisposalInstructions(
            primaryMethod: '',
            steps: const [],
            hasUrgentTimeframe: false,
          ),
          region: 'Unknown',
          visualFeatures: const [],
          alternatives: const [],
        );
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ResultScreen(
              classification: classification,
              showActions: false,
            ),
          ),
        );
      }
    }
  }

  /// Dispose of resources
  static void dispose() {
    _appLinks = null;
  }
}
