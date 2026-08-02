import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../config/monetization_ai_config_contract.dart';
import '../models/premium_feature.dart';
import '../utils/waste_app_logger.dart';
import 'firestore_schema_registry.dart';
import 'remote_config_service.dart';

/// Entitlement projection from server — the ONLY authoritative source.
///
/// Client-side Hive is a cache. Never grant durable entitlement from Hive.
/// Never write `subscriptionTier` or `billing.entitlements` to Firestore from
/// the client. The server (webhook / Cloud Function) is the sole writer.
enum EntitlementState {
  /// No entitlement known. Fail closed for all premium operations.
  unknown,

  /// Entitlement active on the server. Safe to unlock features.
  active,

  /// Entitlement expired or revoked on the server. No premium access.
  expired,
}

// Future states for grace-period and pending-verification detection can be
// added here once the subscription lifecycle fields (currentPeriodEnd,
// graceEnd) are surfaced from the server-side subscription record.

enum PremiumTier {
  free,
  premium,
  family,
}

class PremiumService extends ChangeNotifier {
  PremiumService() {
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

  // --- Server-authoritative entitlement state ---
  EntitlementState _entitlementState = EntitlementState.unknown;
  DateTime? _lastServerVerification;
  StreamSubscription<DocumentSnapshot>? _entitlementSubscription;
  StreamSubscription<User?>? _authSubscription;

  /// The ONLY authoritative entitlement state — read from Firestore
  /// server projection, never from local Hive alone.
  EntitlementState get entitlementState => _entitlementState;

  /// Timestamp of last successful server verification.
  DateTime? get lastServerVerification => _lastServerVerification;

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
      if (Hive.isBoxOpen(_premiumBoxName)) {
        _premiumBox = Hive.box<bool>(_premiumBoxName);
      } else {
        _premiumBox = await Hive.openBox<bool>(_premiumBoxName);
      }
      _isInitialized = true;
      _migrateLegacyPremiumSignal();

      // COMMIT-6: Start observing the server-authoritative entitlement.
      // The client NEVER writes subscriptionTier or billing to Firestore.
      // The server (webhook / Cloud Function) is the sole writer.
      // Also listen for auth state changes to re-subscribe on logout/re-login.
      _startAuthStateListener();

      // Opt-in only: do not implicitly grant premium in debug/test runs.
      if (kDebugMode && _enableDebugAutoSeed) {
        _initTestFeatures();
      }

      notifyListeners();
    } catch (e) {
      WasteAppLogger.severe('Error initializing premium service',
          error: e,
          context: {'service': 'premium', 'action': 'attempt_recovery'});
      try {
        if (!Hive.isBoxOpen(_premiumBoxName)) {
          await Hive.deleteBoxFromDisk(_premiumBoxName);
          _premiumBox = await Hive.openBox<bool>(_premiumBoxName);
        } else {
          _premiumBox = Hive.box<bool>(_premiumBoxName);
        }
        _isInitialized = true;
        _startEntitlementListener();
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

  // --- Server-authoritative entitlement listener ---

  /// Observes `billing.entitlements.pro_subscription` on the user's Firestore
  /// document. This is the ONLY source of truth for premium state.
  ///
  /// Local Hive flags are a UI cache only — they control which widgets are
  /// visible but never gate server-side paid operations (tokens, API calls).
  void _startEntitlementListener() {
    _entitlementSubscription?.cancel();

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      WasteAppLogger.info(
        'Entitlement listener skipped: no authenticated user.',
      );
      _entitlementState = EntitlementState.unknown;
      return;
    }

    final userRef = FirebaseFirestore.instance
        .collection(FirestoreCollections.users)
        .doc(uid);

    _entitlementSubscription = userRef.snapshots().listen(
      (snapshot) {
        if (!snapshot.exists) {
          _entitlementState = EntitlementState.unknown;
          _lastServerVerification = null;
          _syncLocalCacheFromServer(false);
          notifyListeners();
          return;
        }

        final data = snapshot.data()!;
        final billing = data['billing'] as Map<String, dynamic>?;
        final entitlements =
            billing?['entitlements'] as Map<String, dynamic>?;
        final isProActive = entitlements?['pro_subscription'] == true;

        final previousState = _entitlementState;
        _entitlementState =
            isProActive ? EntitlementState.active : EntitlementState.expired;
        _lastServerVerification = DateTime.now();

        // Sync the local Hive cache to match server state (UI only).
        _syncLocalCacheFromServer(isProActive);

        if (previousState != _entitlementState) {
          WasteAppLogger.info(
            'Server entitlement state changed',
            context: {
              'previous': previousState.name,
              'current': _entitlementState.name,
            },
          );
        }
        notifyListeners();
      },
      onError: (Object error, StackTrace stackTrace) {
        WasteAppLogger.severe(
          'Entitlement listener error — falling back to unknown (fail closed)',
          error: error,
          stackTrace: stackTrace,
        );
        _entitlementState = EntitlementState.unknown;
        _lastServerVerification = null;
        notifyListeners();
      },
    );
  }

  /// Sync local Hive cache to match server projection. This is a UI cache
  /// only — server-side guards must NEVER trust these Hive values.
  void _syncLocalCacheFromServer(bool isPremium) {
    if (_premiumBox == null) return;
    _premiumBox!.put(proSubscriptionEntitlement, isPremium);
    _premiumBox!.put(legacyPremiumSignal, isPremium);
    for (final feature in PremiumFeature.features) {
      _premiumBox!.put(feature.id, isPremium);
    }
  }

  /// Subscribe to auth state changes to re-subscribe the entitlement listener
  /// when the user logs in/out. Prevents observing the wrong user's document.
  /// Called automatically from _doInitialize(); also handles the case where
  /// the user is already logged in at subscription time.
  void _startAuthStateListener() {
    _authSubscription?.cancel();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      _entitlementSubscription?.cancel();
      _entitlementSubscription = null;

      if (user == null) {
        _entitlementState = EntitlementState.unknown;
        _lastServerVerification = null;
        _syncLocalCacheFromServer(false);
        notifyListeners();
      } else {
        _startEntitlementListener();
      }
    });

    // Handle already-logged-in case: authStateChanges only fires on changes,
    // not the current state. Explicitly check and subscribe now.
    if (FirebaseAuth.instance.currentUser != null) {
      _startEntitlementListener();
    }
  }

  /// Premium feature check — reads from local Hive cache (UI only).
  /// Server-side guards must NEVER trust this value.
  bool isPremiumFeature(String featureId) {
    if (_premiumBox == null) return false;
    return _premiumBox!.get(featureId) ?? false;
  }

  /// Canonical premium-plan entitlement.
  ///
  /// COMMIT-6: This now checks the server-authoritative entitlement state
  /// instead of local Hive flags. The Hive flags are a UI cache synced from
  /// the server listener, but the authoritative check is the entitlement state.
  ///
  /// Returns `true` only when the server confirms the entitlement is active.
  /// Fail closed: returns `false` for unknown or expired states.
  bool hasActivePremiumPlan() {
    return _entitlementState == EntitlementState.active;
  }

  PremiumTier getCurrentTier() {
    if (!hasActivePremiumPlan()) return PremiumTier.free;
    return PremiumTier.premium;
  }

  int getDailyScanLimit() {
    final remoteLimit = MonetizationAiConfigKeys.readInt(
      RemoteConfigService().getAllValues(),
      MonetizationAiConfigKeys.freeDailyScanLimit,
      defaultValue: 5,
    );

    switch (getCurrentTier()) {
      case PremiumTier.free:
        return remoteLimit;
      case PremiumTier.premium:
        return 100;
      case PremiumTier.family:
        return 500;
    }
  }

  bool canPerformScan(int dailyScanCount) {
    return dailyScanCount < getDailyScanLimit();
  }

  Future<void> setPremiumFeature(String featureId, bool isPremium) async {
    if (!_isInitialized) await initialize();
    if (_premiumBox == null) return;
    if (!_isKnownFeature(featureId)) return;

    // COMMIT-6: Local Hive write only — UI cache for widget rendering.
    // Server-side guards must NEVER trust these Hive values.
    await _premiumBox!.put(featureId, isPremium);

    // Keep canonical entitlement in sync when legacy signal is toggled on.
    if (featureId == legacyPremiumSignal && isPremium) {
      await _premiumBox!.put(proSubscriptionEntitlement, true);
    }

    // COMMIT-6: REMOVED _syncTierToFirestore call.
    // The client must never write subscriptionTier or billing to Firestore.
    // Server (webhook / Cloud Function) is the sole writer.

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

  /// Returns sellable features that are currently enabled for this user.
  /// Non-sellable features are excluded — they are not ready to market.
  List<PremiumFeature> getPremiumFeatures() {
    if (_premiumBox == null) return [];

    return PremiumFeature.features
        .where((feature) => feature.sellable && isPremiumFeature(feature.id))
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

  /// Returns sellable features that are NOT yet enabled for this user.
  /// Non-sellable features are excluded — they are not ready to market.
  /// Only sellable features appear in the upgrade prompt.
  List<PremiumFeature> getComingSoonFeatures() {
    if (_premiumBox == null) {
      return PremiumFeature.features.where((f) => f.sellable).toList();
    }

    return PremiumFeature.features
        .where((feature) => feature.sellable && !isPremiumFeature(feature.id))
        .toList();
  }

  Future<void> resetPremiumFeatures() async {
    if (!_isInitialized) await initialize();
    if (_premiumBox == null) return;

    // COMMIT-6: Clear local cache only. Server-side state is not affected.
    // The entitlement listener will re-sync from server projection.
    await _premiumBox!.clear();
    notifyListeners();
  }

  // Initialize test features for development environment
  void _initTestFeatures() {
    // COMMIT-6: Debug/test mode sets local cache only.
    // Server state is unaffected. The entitlement listener will re-sync.
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
      // COMMIT-6: Local migration only. No Firestore write from client.
      // The entitlement listener will reconcile with server state.
      _premiumBox!.put(proSubscriptionEntitlement, true);
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

  @override
  void dispose() {
    _authSubscription?.cancel();
    _authSubscription = null;
    _entitlementSubscription?.cancel();
    _entitlementSubscription = null;
    super.dispose();
  }
}
