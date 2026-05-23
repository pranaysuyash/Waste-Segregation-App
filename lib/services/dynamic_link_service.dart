     1|import 'package:flutter/material.dart';
     2|import 'package:app_links/app_links.dart';
     3|import 'package:firebase_auth/firebase_auth.dart';
     4|import 'package:waste_segregation_app/models/waste_classification.dart';
     5|import '../screens/result_screen_wrapper.dart';
     6|
     7|/// Handles deep linking for sharing, referrals, and navigation using app_links
     8|class DynamicLinkService {
     9|  static const _baseUrl = 'https://reloop.app';
    10|  static AppLinks? _appLinks;
    11|
    12|  /// Create a shareable link that opens a result screen for [classification].
    13|  static String createResultLink(WasteClassification classification) {
    14|    return '$_baseUrl/result?id=${classification.id}'
    15|        '&item=${Uri.encodeComponent(classification.itemName)}'
    16|        '&category=${Uri.encodeComponent(classification.category)}';
    17|  }
    18|
    19|  /// Create a referral link for the current user.
    20|  static String createReferralLink(String referralCode) {
    21|    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
    22|    return '$_baseUrl/refer?code=$referralCode&ref=$uid';
    23|  }
    24|
    25|  /// Initialize listeners for incoming links.
    26|  static Future<void> initDynamicLinks(BuildContext context) async {
    27|    _appLinks = AppLinks();
    28|
    29|    try {
    30|      final initialLink = await _appLinks!.getInitialLink();
    31|      if (initialLink != null) {
    32|        if (!context.mounted) return;
    33|        _handleLinkData(initialLink, context);
    34|      }
    35|    } catch (e) {
    36|      // Handle error silently
    37|    }
    38|
    39|    _appLinks!.uriLinkStream.listen(
    40|      (uri) {
    41|        if (!context.mounted) return;
    42|        _handleLinkData(uri, context);
    43|      },
    44|      onError: (err) {
    45|        // Handle error silently
    46|      },
    47|    );
    48|  }
    49|
    50|  static void _handleLinkData(Uri? deepLink, BuildContext context) {
    51|    if (deepLink == null) return;
    52|    if (!context.mounted) return;
    53|
    54|    if (deepLink.pathSegments.contains('result')) {
    55|      _handleResultLink(deepLink, context);
    56|    } else if (deepLink.pathSegments.contains('refer')) {
    57|      _handleReferralLink(deepLink, context);
    58|    }
    59|  }
    60|
    61|  static void _handleResultLink(Uri deepLink, BuildContext context) {
    62|    final id = deepLink.queryParameters['id'];
    63|    final item = deepLink.queryParameters['item'];
    64|    final category = deepLink.queryParameters['category'];
    65|
    66|    if (id != null && item != null && category != null) {
    67|      final classification = WasteClassification(
    68|        id: id,
    69|        itemName: item,
    70|        category: category,
    71|        explanation: '',
    72|        disposalInstructions: DisposalInstructions(
    73|          primaryMethod: '',
    74|          steps: const [],
    75|          hasUrgentTimeframe: false,
    76|        ),
    77|        region: 'Unknown',
    78|        visualFeatures: const [],
    79|        alternatives: const [],
    80|      );
    81|
    82|      if (context.mounted) {
    83|        Navigator.push(
    84|          context,
    85|          MaterialPageRoute(
    86|            builder: (_) => ResultScreenWrapper(
    87|              classification: classification,
    88|              showActions: false,
    89|            ),
    90|          ),
    91|        );
    92|      }
    93|    }
    94|  }
    95|
    96|  static void _handleReferralLink(Uri deepLink, BuildContext context) {
    97|    final code = deepLink.queryParameters['code'];
    98|    final ref = deepLink.queryParameters['ref'];
    99|
   100|    if (code != null && ref != null && context.mounted) {
   101|      _processReferral(context, code, ref);
   102|    }
   103|  }
   104|
   105|  static void _processReferral(BuildContext context, String code, String referrerUid) {
   106|    // Navigate to a referral landing screen where the user can sign up
   107|    // and the referral code will be applied on registration.
   108|    // For now, we emit a snackbar to inform the user.
   109|    ScaffoldMessenger.of(context).showSnackBar(
   110|      SnackBar(
   111|        content: Text('Referred by a friend! Use code: $code'),
   112|        duration: const Duration(seconds: 5),
   113|      ),
   114|    );
   115|  }
   116|
   117|  /// Dispose of resources
   118|  static void dispose() {
   119|    _appLinks = null;
   120|  }
   121|}
   122|