import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:waste_segregation_app/services/premium_service.dart';
import 'package:waste_segregation_app/utils/waste_app_logger.dart';

class WebCheckoutService extends ChangeNotifier {
  WebCheckoutService(this._premiumService);

  final PremiumService _premiumService;

  bool _isCreatingSession = false;
  bool _isAwaitingPayment = false;
  String? _errorMessage;
  StreamSubscription<void>? _billingSub;

  bool get isCreatingSession => _isCreatingSession;
  bool get isAwaitingPayment => _isAwaitingPayment;
  String? get errorMessage => _errorMessage;

  Future<void> startCheckout({
    String? productId,
    String? returnUrl,
  }) async {
    _errorMessage = null;
    _isCreatingSession = true;
    notifyListeners();

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        throw Exception('User not authenticated');
      }

      final functions = FirebaseFunctions.instanceFor(region: 'asia-south1');
      final callable = functions.httpsCallable('createCheckoutSession');
      final result = await callable.call(<String, dynamic>{
        if (productId != null) 'product_id': productId,
        if (returnUrl != null) 'return_url': returnUrl,
      });

      final data = result.data as Map<String, dynamic>;
      final checkoutUrl = data['checkout_url'] as String;

      _isCreatingSession = false;
      _isAwaitingPayment = true;
      notifyListeners();

      _startEntitlementPoll();

      final uri = Uri.parse(checkoutUrl);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        _errorMessage = 'Could not open checkout page.';
        _isAwaitingPayment = false;
        notifyListeners();
      }
    } catch (e, s) {
      WasteAppLogger.severe('Web checkout session creation failed',
        error: e, stackTrace: s,
        context: {'service': 'web_checkout_service'},
      );
      _errorMessage = 'Failed to start checkout. Please try again.';
      _isCreatingSession = false;
      notifyListeners();
    }
  }

  /// Poll the server-authoritative entitlement state from PremiumService
  /// after initiating checkout. The PremiumService entitlement listener
  /// already observes billing.entitlements.pro_subscription in real time,
  /// so this is a lightweight poll rather than a second Firestore subscription.
  void _startEntitlementPoll() {
    _billingSub?.cancel();

    final startTime = DateTime.now();
    const pollTimeout = Duration(minutes: 5);

    _billingSub = Stream.periodic(const Duration(seconds: 2)).listen(
      (_) {
        if (_premiumService.entitlementState == EntitlementState.active) {
          _isAwaitingPayment = false;
          _billingSub?.cancel();
          _billingSub = null;
          notifyListeners();
        } else if (DateTime.now().difference(startTime) > pollTimeout) {
          _errorMessage = 'Payment verification timed out. Please check your subscription status.';
          _isAwaitingPayment = false;
          _billingSub?.cancel();
          _billingSub = null;
          notifyListeners();
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        _errorMessage = 'Payment verification failed. Please try again.';
        _isAwaitingPayment = false;
        _billingSub?.cancel();
        _billingSub = null;
        notifyListeners();
      },
    );
  }

  /// Public API for external callers to cancel the payment flow.
  void cancelPayment() {
    _isAwaitingPayment = false;
    _billingSub?.cancel();
    _billingSub = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _billingSub?.cancel();
    super.dispose();
  }
}
