import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import '../screens/result_screen_wrapper.dart';

/// Handles deep linking for sharing, referrals, and navigation using app_links
class DynamicLinkService {
  static const _baseUrl = 'https://wastewise.app';
  static AppLinks? _appLinks;

  /// Create a shareable link that opens a result screen for [classification].
  static String createResultLink(WasteClassification classification) {
    return '$_baseUrl/result?id=${classification.id}'
        '&item=${Uri.encodeComponent(classification.itemName)}'
        '&category=${Uri.encodeComponent(classification.category)}';
  }

  /// Create a referral link for the current user.
  static String createReferralLink(String referralCode) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
    return '$_baseUrl/refer?code=$referralCode&ref=$uid';
  }

  /// Initialize listeners for incoming links.
  static Future<void> initDynamicLinks(BuildContext context) async {
    _appLinks = AppLinks();

    try {
      final initialLink = await _appLinks!.getInitialLink();
      if (initialLink != null) {
        if (!context.mounted) return;
        _handleLinkData(initialLink, context);
      }
    } catch (e) {
      // Handle error silently
    }

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
    if (!context.mounted) return;

    if (deepLink.pathSegments.contains('result')) {
      _handleResultLink(deepLink, context);
    } else if (deepLink.pathSegments.contains('refer')) {
      _handleReferralLink(deepLink, context);
    }
  }

  static void _handleResultLink(Uri deepLink, BuildContext context) {
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

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ResultScreenWrapper(
              classification: classification,
              showActions: false,
            ),
          ),
        );
      }
    }
  }

  static void _handleReferralLink(Uri deepLink, BuildContext context) {
    final code = deepLink.queryParameters['code'];
    final ref = deepLink.queryParameters['ref'];

    if (code != null && ref != null && context.mounted) {
      _processReferral(context, code, ref);
    }
  }

  static void _processReferral(BuildContext context, String code, String referrerUid) {
    // Navigate to a referral landing screen where the user can sign up
    // and the referral code will be applied on registration.
    // For now, we emit a snackbar to inform the user.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Referred by a friend! Use code: $code'),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  /// Dispose of resources
  static void dispose() {
    _appLinks = null;
  }
}
