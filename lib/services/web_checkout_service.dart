import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  StreamSubscription<DocumentSnapshot>? _billingSub;

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

      _listenForBillingUpdate(uid);

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

  void _listenForBillingUpdate(String uid) {
    _billingSub?.cancel();

    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    _billingSub = userRef.snapshots().listen((snapshot) {
      if (!snapshot.exists) return;

      final data = snapshot.data()!;
      final billing = data['billing'] as Map<String, dynamic>?;
      final entitlements = billing?['entitlements'] as Map<String, dynamic>?;
      final isPremium = entitlements?['pro_subscription'] == true;

      if (isPremium) {
        _premiumService.setPremiumPlanEntitlement(true);
        _isAwaitingPayment = false;
        _billingSub?.cancel();
        _billingSub = null;
        notifyListeners();
      }
    });
  }

  void cancelAwaitingPayment() {
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
