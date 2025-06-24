import 'package:flutter/foundation.dart';
import '../utils/waste_app_logger.dart';
import 'package:hive/hive.dart';
import '../models/premium_feature.dart';

class PremiumService extends ChangeNotifier {
  // Constructor now initializes immediately
  PremiumService() {
    // Ensure initialization happens early
    initialize();
  }
  static const String _premiumBoxName = 'premium_features';
  Box<bool>? _premiumBox;
  bool _isInitialized = false;
  bool _isInitializing = false;

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    // Prevent multiple simultaneous initialization attempts
    if (_isInitialized || _isInitializing) return;

    _isInitializing = true;

    try {
      // Check if the box is already open
      if (Hive.isBoxOpen(_premiumBoxName)) {
        _premiumBox = Hive.box<bool>(_premiumBoxName);
      } else {
        _premiumBox = await Hive.openBox<bool>(_premiumBoxName);
      }
      _isInitialized = true;

      // Add test features in debug mode for easy testing
      if (kDebugMode) {
        // Initialize with test values for development
        _initTestFeatures();
      }

      notifyListeners();
    } catch (e) {
      WasteAppLogger.severe(
          'Error initializing premium service', e, null, {'service': 'premium', 'action': 'attempt_recovery'});
      // Try to recover by creating the box
      try {
        if (!Hive.isBoxOpen(_premiumBoxName)) {
          await Hive.deleteBoxFromDisk(_premiumBoxName);
          _premiumBox = await Hive.openBox<bool>(_premiumBoxName);
        } else {
          _premiumBox = Hive.box<bool>(_premiumBoxName);
        }
        _isInitialized = true;
        notifyListeners();
      } catch (e) {
        WasteAppLogger.severe('Failed to recover from premium service initialization error', e, null,
            {'service': 'premium', 'action': 'continue_without_premium_features'});
      }
    } finally {
      _isInitializing = false;
    }
  }

  // Safe check for premium feature that handles initialization issues
  bool isPremiumFeature(String featureId) {
    if (_premiumBox == null) return false;
    return _premiumBox!.get(featureId) ?? false;
  }

  Future<void> setPremiumFeature(String featureId, bool isPremium) async {
    if (!_isInitialized) await initialize();
    if (_premiumBox == null) return;

    await _premiumBox!.put(featureId, isPremium);
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

    return PremiumFeature.features.where((feature) => !isPremiumFeature(feature.id)).toList();
  }

  Future<void> resetPremiumFeatures() async {
    if (!_isInitialized) await initialize();
    if (_premiumBox == null) return;

    await _premiumBox!.clear();
    notifyListeners();
  }

  // Initialize test features for development environment
  void _initTestFeatures() {
    // Enable one premium feature for testing
    if (_premiumBox != null && _premiumBox!.isEmpty) {
      // Add the "remove ads" feature for testing
      _premiumBox!.put('remove_ads', true);
    }
  }

  // Toggle a premium feature (useful for debug/test mode)
  Future<void> toggleFeature(String featureId) async {
    if (!_isInitialized) await initialize();
    if (_premiumBox == null) return;

    final currentValue = _premiumBox!.get(featureId) ?? false;
    await _premiumBox!.put(featureId, !currentValue);
    notifyListeners();
  }
}
