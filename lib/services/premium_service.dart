import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../models/premium_feature.dart';
import '../utils/waste_app_logger.dart';
import 'firestore_schema_registry.dart';

class PremiumService extends ChangeNotifier {
  // Constructor now initializes immediately
  PremiumService() {
    // Ensure initialization happens early
    initialize();
  }
  static const String _premiumBoxName = 'premium_features';
  static const String proSubscriptionEntitlement = 'pro_subscription';
  static const String legacyPremiumSignal = 'remove_ads';
  static const bool _enableDebugAutoSeed =
      bool.fromEnvironment('PREMIUM_DEBUG_AUTO_SEED');
  Box<bool>? _premiumBox;
  bool _isInitialized = false;
  bool _isInitializing = false;
  Future<void>? _initializationFuture;

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    // Prevent multiple simultaneous initialization attempts
    if (_isInitialized) return;
    if (_isInitializing) {
      await _initializationFuture;
      return;
    }

    _isInitializing = true;
    _initializationFuture = _doInitialize();
    try {
      await _initializationFuture;
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _doInitialize() async {
    try {
      // Check if the box is already open
      if (Hive.isBoxOpen(_premiumBoxName)) {
        _premiumBox = Hive.box<bool>(_premiumBoxName);
      } else {
        _premiumBox = await Hive.openBox<bool>(_premiumBoxName);
      }
      _isInitialized = true;
      _migrateLegacyPremiumSignal();

      // Boot-time Firestore sync: if the user already has premium in Hive
      // (from a purchase made before this sync path existed), push the tier to
      // Firestore so the server-side spendUserTokens guard sees 'premium'
      // without waiting for a new purchase or restore event.
      // Fire-and-forget — Hive is always authoritative client-side.
      if (hasActivePremiumPlan()) {
        unawaited(_syncTierToFirestore(true));
      }

      // Opt-in only: do not implicitly grant premium in debug/test runs.
      if (kDebugMode && _enableDebugAutoSeed) {
        _initTestFeatures();
      }

      notifyListeners();
    } catch (e) {
      WasteAppLogger.severe('Error initializing premium service',
          error: e,
          context: {'service': 'premium', 'action': 'attempt_recovery'});
      // Try to recover by creating the box
      try {
        if (!Hive.isBoxOpen(_premiumBoxName)) {
          await Hive.deleteBoxFromDisk(_premiumBoxName);
          _premiumBox = await Hive.openBox<bool>(_premiumBoxName);
        } else {
          _premiumBox = Hive.box<bool>(_premiumBoxName);
        }
        _isInitialized = true;
        if (hasActivePremiumPlan()) {
          unawaited(_syncTierToFirestore(true));
        }
        notifyListeners();
      } catch (e) {
        WasteAppLogger.severe(
            'Failed to recover from premium service initialization error',
            error: e,
            context: {
              'service': 'premium',
              'action': 'continue_without_premium_features'
            });
      }
    }
  }

  // Safe check for premium feature that handles initialization issues
  bool isPremiumFeature(String featureId) {
    if (_premiumBox == null) return false;
    return _premiumBox!.get(featureId) ?? false;
  }

  /// Canonical premium-plan entitlement for pricing and plan-level behavior.
  /// Falls back to legacy signal for backward compatibility with old data.
  bool hasActivePremiumPlan() {
    if (_premiumBox == null) return false;
    return (_premiumBox!.get(proSubscriptionEntitlement) ?? false) ||
        (_premiumBox!.get(legacyPremiumSignal) ?? false);
  }

  Future<void> setPremiumFeature(String featureId, bool isPremium) async {
    if (!_isInitialized) await initialize();
    if (_premiumBox == null) return;
    if (!_isKnownFeature(featureId)) return;

    await _premiumBox!.put(featureId, isPremium);

    // Keep canonical entitlement in sync when legacy signal is toggled on.
    if (featureId == legacyPremiumSignal && isPremium) {
      await _premiumBox!.put(proSubscriptionEntitlement, true);
    }

    // Propagate tier change to Firestore so the server-side spendUserTokens
    // guard can verify discounts without trusting the client.
    //
    // - proSubscriptionEntitlement set/cleared → sync directly
    // - legacyPremiumSignal set to true       → also elevates to premium
    if (featureId == proSubscriptionEntitlement) {
      unawaited(_syncTierToFirestore(isPremium));
    } else if (featureId == legacyPremiumSignal && isPremium) {
      unawaited(_syncTierToFirestore(true));
    }

    notifyListeners();
  }

  /// Preferred entry point for purchase and restore flows.
  /// Keeps canonical and legacy premium flags aligned.
  Future<void> setPremiumPlanEntitlement(bool isPremium) async {
    await setPremiumFeature(proSubscriptionEntitlement, isPremium);
    if (_premiumBox == null) return;
    await _premiumBox!.put(legacyPremiumSignal, isPremium);
    notifyListeners();
  }

  List<PremiumFeature> getPremiumFeatures() {
    if (_premiumBox == null) return [];

    return PremiumFeature.features
        .where((feature) => isPremiumFeature(feature.id))
        .map((feature) => PremiumFeature(
              id: feature.id,
              title: feature.title,
              description: feature.description,
              icon: feature.icon,
              route: feature.route,
              isEnabled: true,
            ))
        .toList();
  }

  List<PremiumFeature> getComingSoonFeatures() {
    if (_premiumBox == null) return PremiumFeature.features;

    return PremiumFeature.features
        .where((feature) => !isPremiumFeature(feature.id))
        .toList();
  }

  Future<void> resetPremiumFeatures() async {
    if (!_isInitialized) await initialize();
    if (_premiumBox == null) return;

    await _premiumBox!.clear();
    // Propagate revocation to Firestore so the server-side guard enforces
    // free-tier caps immediately after a reset (dev/debug/support action).
    unawaited(_syncTierToFirestore(false));
    notifyListeners();
  }

  /// Writes the server-authoritative subscription tier to Firestore so that
  /// Cloud Functions (e.g. `spendUserTokens`) can verify it without trusting
  /// any client-supplied values.
  ///
  /// Fire-and-forget: a Firestore failure is logged but never surfaces to the
  /// caller — the local Hive entitlement is always the source of truth for
  /// client-side feature gates, while Firestore is the source of truth for
  /// server-side enforcement.
  Future<void> _syncTierToFirestore(bool isPremium) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null || uid.isEmpty) {
        WasteAppLogger.info(
          'subscriptionTier Firestore sync skipped: no authenticated user.',
        );
        return;
      }
      final tier = isPremium ? 'premium' : 'free';
      await FirebaseFirestore.instance
          .collection(FirestoreCollections.users)
          .doc(uid)
          .set(
            {UsersSchema.subscriptionTierField: tier},
            SetOptions(merge: true),
          );
      WasteAppLogger.info(
        'subscriptionTier synced to Firestore',
        context: {'tier': tier},
      );
    } catch (e, s) {
      WasteAppLogger.warning(
        'Failed to sync subscriptionTier to Firestore (non-fatal); '
        'server-side token guard will default to free tier until next sync.',
        error: e,
        stackTrace: s,
        context: {'isPremium': isPremium},
      );
    }
  }

  // Initialize test features for development environment
  void _initTestFeatures() {
    // Enable one premium feature for testing
    if (_premiumBox != null && _premiumBox!.isEmpty) {
      _premiumBox!.put(proSubscriptionEntitlement, true);
      _premiumBox!.put(legacyPremiumSignal, true);
    }
  }

  void _migrateLegacyPremiumSignal() {
    if (_premiumBox == null) return;
    final hasPlan = _premiumBox!.get(proSubscriptionEntitlement) ?? false;
    final hasLegacy = _premiumBox!.get(legacyPremiumSignal) ?? false;
    if (!hasPlan && hasLegacy) {
      _premiumBox!.put(proSubscriptionEntitlement, true);
      // Ensure the Firestore tier is brought in sync for users who are being
      // migrated from the legacy signal so the server-side guard sees 'premium'.
      unawaited(_syncTierToFirestore(true));
    }
  }

  // Toggle a premium feature (useful for debug/test mode)
  Future<void> toggleFeature(String featureId) async {
    if (!_isInitialized) await initialize();
    if (_premiumBox == null) return;
    if (!_isKnownFeature(featureId)) return;

    final currentValue = _premiumBox!.get(featureId) ?? false;
    await _premiumBox!.put(featureId, !currentValue);
    notifyListeners();
  }

  bool _isKnownFeature(String featureId) {
    return PremiumFeature.features.any((feature) => feature.id == featureId) ||
        featureId == proSubscriptionEntitlement ||
        featureId == legacyPremiumSignal;
  }
}
