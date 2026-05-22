import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/waste_app_logger.dart';

class HapticSettingsService extends ChangeNotifier {
  HapticSettingsService() {
    _load();
  }

  static const String _enabledKey = 'haptic_success_enabled';
  bool _enabled = true;

  bool get enabled => _enabled;

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _enabled = prefs.getBool(_enabledKey) ?? true;
    } catch (e) {
      WasteAppLogger.severe('Error loading haptic setting, using default',
          error: e, context: {'setting': _enabledKey});
      _enabled = true;
    }
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_enabledKey, value);
      _enabled = value;
      notifyListeners();
    } catch (e) {
      WasteAppLogger.severe('Error saving haptic setting',
          error: e, context: {'setting': _enabledKey, 'value': value});
    }
  }
}
