import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/premium_feature.dart';

class PremiumService extends ChangeNotifier {
  static const String _premiumBoxName = 'premium_features';
  Box<bool>? _premiumBox;
  bool _isInitialized = false;

  PremiumService() {
    // Ensure initialization happens early
    initialize();
  }

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _premiumBox = await Hive.openBox<bool>(_premiumBoxName);
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing premium service: $e');
      // Try to recover by creating the box
      try {
        if (!Hive.isBoxOpen(_premiumBoxName)) {
          _premiumBox = await Hive.openBox<bool>(_premiumBoxName);
        } else {
          _premiumBox = Hive.box<bool>(_premiumBoxName);
        }
        _isInitialized = true;
        notifyListeners();
      } catch (e) {
        debugPrint('Failed to recover from premium service initialization error: $e');
      }
    }
  }

  bool isPremiumFeature(String featureId) {
    if (_premiumBox == null) return false;
    return _premiumBox!.get(featureId) ?? false;
  }

  Future<void> setPremiumFeature(String featureId, bool isPremium) async {
    if (_premiumBox == null) await initialize();
    if (_premiumBox == null) return;
    
    await _premiumBox!.put(featureId, isPremium);
    notifyListeners();
  }

  List<PremiumFeature> getPremiumFeatures() {
    if (_premiumBox == null) return [];
    return PremiumFeature.features.where((feature) => isPremiumFeature(feature.id)).toList();
  }

  List<PremiumFeature> getComingSoonFeatures() {
    if (_premiumBox == null) return PremiumFeature.features;
    return PremiumFeature.features.where((feature) => !isPremiumFeature(feature.id)).toList();
  }

  Future<void> resetPremiumFeatures() async {
    if (_premiumBox == null) await initialize();
    if (_premiumBox == null) return;
    
    await _premiumBox!.clear();
    notifyListeners();
  }
} 