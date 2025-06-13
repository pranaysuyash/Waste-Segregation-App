import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HapticSettingsService extends ChangeNotifier {
  HapticSettingsService() {
    _load();
  }

  static const String _enabledKey = 'haptic_success_enabled';
  bool _enabled = true;

  bool get enabled => _enabled;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_enabledKey) ?? true;
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);
    _enabled = value;
    notifyListeners();
  }
}
