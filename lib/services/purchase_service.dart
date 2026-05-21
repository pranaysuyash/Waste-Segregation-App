import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../models/premium_feature.dart';
import '../utils/firebase_gate.dart';
import '../utils/waste_app_logger.dart';
import 'premium_service.dart';

/// Launchable purchase rail for a single premium subscription product.
///
/// This service owns store interaction and synchronizes entitlement state
/// into [PremiumService].
class PurchaseService extends ChangeNotifier {
  PurchaseService(
    this._premiumService, {
    StoreBillingGateway? gateway,
    this.productId = _defaultProductId,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _gateway = gateway ?? InAppPurchaseGateway(),
        _firestore = firestore,
        _auth = auth;

  static const String _defaultProductId = String.fromEnvironment(
      'PREMIUM_SUBSCRIPTION_PRODUCT_ID',
      defaultValue: 'waste_premium_monthly');

  final PremiumService _premiumService;
  final StoreBillingGateway _gateway;
  final String productId;
  final FirebaseFirestore? _firestore;
  final FirebaseAuth? _auth;

  bool _initialized = false;
  bool _isAvailable = false;
  bool _isLoading = false;
  bool _isProcessingPurchase = false;
  String? _errorMessage;
  PurchaseProduct? _premiumProduct;
  StreamSubscription<List<PurchaseUpdate>>? _purchaseSub;

  bool get isInitialized => _initialized;
  bool get isAvailable => _isAvailable;
  bool get isLoading => _isLoading;
  bool get isProcessingPurchase => _isProcessingPurchase;
  String? get errorMessage => _errorMessage;
  PurchaseProduct? get premiumProduct => _premiumProduct;

  bool get canPurchase =>
      _isAvailable && _premiumProduct != null && !_isProcessingPurchase;

  Future<void> initialize() async {
    if (_initialized || _isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _isAvailable = await _gateway.isAvailable();
      if (!_isAvailable) {
        _errorMessage =
            'In-app purchases are currently unavailable on this device.';
        return;
      }

      _purchaseSub = _gateway.purchaseUpdates.listen(_onPurchaseUpdates,
          onError: (Object error, StackTrace stackTrace) {
        WasteAppLogger.severe('Purchase updates stream failed',
            error: error,
            stackTrace: stackTrace,
            context: {'service': 'purchase_service'});
        _errorMessage = 'Purchase updates stream failed.';
        notifyListeners();
      });

      final products = await _gateway.queryProducts({productId});
      if (products.isEmpty) {
        _errorMessage =
            'Premium product is not configured in the store for this build.';
      } else {
        _premiumProduct = products.first;
      }

      _initialized = true;
    } catch (e, s) {
      WasteAppLogger.severe('Purchase service initialization failed',
          error: e, stackTrace: s, context: {'service': 'purchase_service'});
      _errorMessage = 'Failed to initialize purchases.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> buyPremium() async {
    if (!_initialized) {
      await initialize();
    }

    if (!canPurchase || _premiumProduct == null) {
      _errorMessage ??= 'Premium purchase is not available right now.';
      notifyListeners();
      return;
    }

    _isProcessingPurchase = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _gateway.buyNonConsumable(_premiumProduct!.id);
    } catch (e, s) {
      WasteAppLogger.severe('Failed to start premium purchase',
          error: e, stackTrace: s, context: {'service': 'purchase_service'});
      _errorMessage = 'Could not start purchase flow.';
      _isProcessingPurchase = false;
      notifyListeners();
    }
  }

  Future<void> restorePurchases() async {
    if (!_initialized) {
      await initialize();
    }

    if (!_isAvailable) {
      _errorMessage =
          'In-app purchases are currently unavailable on this device.';
      notifyListeners();
      return;
    }

    _isProcessingPurchase = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _gateway.restorePurchases();
    } catch (e, s) {
      WasteAppLogger.severe('Failed to restore purchases',
          error: e, stackTrace: s, context: {'service': 'purchase_service'});
      _errorMessage = 'Could not restore purchases.';
      _isProcessingPurchase = false;
      notifyListeners();
    }
  }

  Future<void> _onPurchaseUpdates(List<PurchaseUpdate> updates) async {
    var shouldStopProcessing = false;

    for (final update in updates) {
      if (update.productId != productId) {
        if (update.needsCompletion) {
          await _gateway.completePurchase(update);
        }
        continue;
      }

      switch (update.status) {
        case PurchaseUpdateStatus.pending:
          _isProcessingPurchase = true;
          break;
        case PurchaseUpdateStatus.purchased:
        case PurchaseUpdateStatus.restored:
          await _grantPremiumEntitlements();
          shouldStopProcessing = true;
          break;
        case PurchaseUpdateStatus.error:
          _errorMessage = update.errorMessage ?? 'Purchase failed.';
          shouldStopProcessing = true;
          break;
        case PurchaseUpdateStatus.canceled:
          _errorMessage = 'Purchase canceled.';
          shouldStopProcessing = true;
          break;
      }

      if (update.needsCompletion) {
        await _gateway.completePurchase(update);
      }
    }

    if (shouldStopProcessing) {
      _isProcessingPurchase = false;
    }

    notifyListeners();
  }

  Future<void> _grantPremiumEntitlements() async {
    await _premiumService.setPremiumFeature(
        PremiumService.proSubscriptionEntitlement, true);
    for (final feature in PremiumFeature.features) {
      await _premiumService.setPremiumFeature(feature.id, true);
    }
    await _syncSubscriptionTierToFirestore('premium');
  }

  Future<void> _syncSubscriptionTierToFirestore(String tier) async {
    if (!isFirebaseEnabled) return;
    try {
      final uid = (_auth ?? FirebaseAuth.instance).currentUser?.uid;
      if (uid == null || uid.isEmpty) {
        WasteAppLogger.warning(
          'Cannot sync subscriptionTier: no authenticated user',
          context: {'service': 'purchase_service', 'tier': tier},
        );
        return;
      }
      await (_firestore ?? FirebaseFirestore.instance)
          .collection('users')
          .doc(uid)
          .set({'subscriptionTier': tier}, SetOptions(merge: true));
      WasteAppLogger.info('subscriptionTier synced to Firestore', context: {
        'service': 'purchase_service',
        'uid': uid,
        'tier': tier,
      });
    } catch (e, s) {
      // Non-fatal: local entitlement grant still succeeded.
      WasteAppLogger.severe(
        'Failed to sync subscriptionTier to Firestore',
        error: e,
        stackTrace: s,
        context: {'service': 'purchase_service', 'tier': tier},
      );
    }
  }

  @override
  void dispose() {
    _purchaseSub?.cancel();
    _purchaseSub = null;
    super.dispose();
  }
}

class PurchaseProduct {
  const PurchaseProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
  });

  final String id;
  final String title;
  final String description;
  final String price;
}

enum PurchaseUpdateStatus { pending, purchased, restored, error, canceled }

class PurchaseUpdate {
  const PurchaseUpdate({
    required this.productId,
    required this.status,
    this.errorMessage,
    this.needsCompletion = false,
    this.raw,
  });

  final String productId;
  final PurchaseUpdateStatus status;
  final String? errorMessage;
  final bool needsCompletion;
  final Object? raw;
}

abstract class StoreBillingGateway {
  Stream<List<PurchaseUpdate>> get purchaseUpdates;

  Future<bool> isAvailable();
  Future<List<PurchaseProduct>> queryProducts(Set<String> ids);
  Future<void> buyNonConsumable(String productId);
  Future<void> restorePurchases();
  Future<void> completePurchase(PurchaseUpdate update);
}

class InAppPurchaseGateway implements StoreBillingGateway {
  InAppPurchaseGateway({InAppPurchase? iap})
      : _iap = iap ?? InAppPurchase.instance;

  final InAppPurchase _iap;

  @override
  Stream<List<PurchaseUpdate>> get purchaseUpdates =>
      _iap.purchaseStream.map((events) =>
          events.map(_mapPurchaseDetailsToUpdate).toList(growable: false));

  @override
  Future<bool> isAvailable() => _iap.isAvailable();

  @override
  Future<List<PurchaseProduct>> queryProducts(Set<String> ids) async {
    final response = await _iap.queryProductDetails(ids);
    if (response.error != null) {
      throw Exception(response.error!.message);
    }

    return response.productDetails
        .map((p) => PurchaseProduct(
              id: p.id,
              title: p.title,
              description: p.description,
              price: p.price,
            ))
        .toList(growable: false);
  }

  @override
  Future<void> buyNonConsumable(String productId) async {
    final response = await _iap.queryProductDetails({productId});
    if (response.error != null) {
      throw Exception(response.error!.message);
    }
    final details = response.productDetails.where((p) => p.id == productId);
    if (details.isEmpty) {
      throw Exception('Product not found: $productId');
    }

    final param = PurchaseParam(productDetails: details.first);
    final started = await _iap.buyNonConsumable(purchaseParam: param);
    if (!started) {
      throw Exception('Store rejected purchase start for product $productId');
    }
  }

  @override
  Future<void> restorePurchases() => _iap.restorePurchases();

  @override
  Future<void> completePurchase(PurchaseUpdate update) async {
    final raw = update.raw;
    if (raw is PurchaseDetails && raw.pendingCompletePurchase) {
      await _iap.completePurchase(raw);
    }
  }

  PurchaseUpdate _mapPurchaseDetailsToUpdate(PurchaseDetails details) {
    final status = switch (details.status) {
      PurchaseStatus.pending => PurchaseUpdateStatus.pending,
      PurchaseStatus.purchased => PurchaseUpdateStatus.purchased,
      PurchaseStatus.restored => PurchaseUpdateStatus.restored,
      PurchaseStatus.error => PurchaseUpdateStatus.error,
      PurchaseStatus.canceled => PurchaseUpdateStatus.canceled,
    };

    return PurchaseUpdate(
      productId: details.productID,
      status: status,
      errorMessage: details.error?.message,
      needsCompletion: details.pendingCompletePurchase,
      raw: details,
    );
  }
}
