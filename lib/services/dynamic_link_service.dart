import 'package:flutter/material.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import '../models/waste_classification.dart';
import '../screens/result_screen.dart';

/// Handles Firebase Dynamic Links for sharing and deep linking
class DynamicLinkService {
  static const _uriPrefix = 'https://wastesegapp.page.link';

  /// Create a short dynamic link that opens a result screen for [classification].
  static Future<String> createResultLink(WasteClassification classification) async {
    final parameters = DynamicLinkParameters(
      uriPrefix: _uriPrefix,
      link: Uri.parse(
        '$_uriPrefix/result?id=${classification.id}'
        '&item=${Uri.encodeComponent(classification.itemName)}'
        '&category=${Uri.encodeComponent(classification.category)}',
      ),
      androidParameters: const AndroidParameters(
        packageName: 'com.example.waste_segregation_app',
      ),
      iosParameters: const IOSParameters(
        bundleId: 'com.example.wasteSegregationApp',
      ),
    );

    final shortLink = await FirebaseDynamicLinks.instance.buildShortLink(parameters);
    return shortLink.shortUrl.toString();
  }

  /// Initialize listeners for incoming links.
  static Future<void> initDynamicLinks(BuildContext context) async {
    final data = await FirebaseDynamicLinks.instance.getInitialLink();
    _handleLinkData(data, context);

    FirebaseDynamicLinks.instance.onLink.listen(
      (event) => _handleLinkData(event, context),
    );
  }

  static void _handleLinkData(PendingDynamicLinkData? data, BuildContext context) {
    final deepLink = data?.link;
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
}
