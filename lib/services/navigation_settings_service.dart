import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/waste_app_logger.dart';

class NavigationSettingsService extends ChangeNotifier {
  NavigationSettingsService() {
    _loadSettings();
  }
  static const String _bottomNavEnabledKey = 'bottom_nav_enabled';
  static const String _fabEnabledKey = 'fab_enabled';
  static const String _navigationStyleKey = 'navigation_style';

  static const List<String> validStyles = [
    'glassmorphism',
    'material3',
    'floating',
  ];
  static const String _defaultStyle = 'glassmorphism';

  bool _bottomNavEnabled = true;
  bool _fabEnabled = false;
  String _navigationStyle = _defaultStyle;

  bool get bottomNavEnabled => _bottomNavEnabled;
  bool get fabEnabled => _fabEnabled;
  String get navigationStyle => _navigationStyle;

  static bool isValidStyle(String style) => validStyles.contains(style);

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _bottomNavEnabled = prefs.getBool(_bottomNavEnabledKey) ?? true;
      _fabEnabled = prefs.getBool(_fabEnabledKey) ?? false;
      final rawStyle = prefs.getString(_navigationStyleKey) ?? _defaultStyle;
      _navigationStyle = isValidStyle(rawStyle) ? rawStyle : _defaultStyle;
      notifyListeners();
    } catch (e) {
      WasteAppLogger.severe('Error loading navigation settings',
          error: e, context: {'action': 'use_default_settings'});
      _navigationStyle = _defaultStyle;
      notifyListeners();
    }
  }

  Future<void> setBottomNavEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_bottomNavEnabledKey, enabled);
      _bottomNavEnabled = enabled;
      notifyListeners();
    } catch (e) {
      WasteAppLogger.severe('Error saving bottom nav setting',
          error: e,
          context: {'setting': 'bottom_nav_enabled', 'value': enabled});
    }
  }

  Future<void> setFabEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_fabEnabledKey, enabled);
      _fabEnabled = enabled;
      notifyListeners();
    } catch (e) {
      WasteAppLogger.severe('Error saving FAB setting',
          error: e, context: {'setting': 'fab_enabled', 'value': enabled});
    }
  }

  Future<void> setNavigationStyle(String style) async {
    if (!isValidStyle(style)) {
      WasteAppLogger.warning('Invalid navigation style rejected',
          context: {'invalid_style': style, 'valid_styles': validStyles});
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_navigationStyleKey, style);
      _navigationStyle = style;
      notifyListeners();
    } catch (e) {
      WasteAppLogger.severe('Error saving navigation style',
          error: e, context: {'setting': 'navigation_style', 'value': style});
    }
  }

  Future<void> resetToDefaults() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_bottomNavEnabledKey);
      await prefs.remove(_fabEnabledKey);
      await prefs.remove(_navigationStyleKey);

      _bottomNavEnabled = true;
      _fabEnabled = false;
      _navigationStyle = _defaultStyle;
      notifyListeners();
    } catch (e) {
      WasteAppLogger.severe('Error resetting navigation settings',
          error: e, context: {'action': 'reset_to_defaults'});
    }
  }
}
