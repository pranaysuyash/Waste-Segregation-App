import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeProvider() {
    _loadThemeMode();
  }
  SharedPreferences? _prefs;
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  Future<void> _loadThemeMode() async {
    _prefs = await SharedPreferences.getInstance();
    final themeModeIndex = _prefs?.getInt(StorageKeys.themeModeKey) ?? 1;

    // Validate the index is within valid range
    if (themeModeIndex >= 0 && themeModeIndex < ThemeMode.values.length) {
      _themeMode = ThemeMode.values[themeModeIndex];
    } else {
      // Fallback to light theme for invalid indices
      _themeMode = ThemeMode.light;
    }

    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    _prefs = _prefs ?? await SharedPreferences.getInstance();
    await _prefs?.setInt(StorageKeys.themeModeKey, mode.index);
    notifyListeners();
  }
}
