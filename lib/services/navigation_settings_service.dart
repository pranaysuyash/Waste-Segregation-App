import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NavigationSettingsService extends ChangeNotifier {
  static const String _bottomNavEnabledKey = 'bottom_nav_enabled';
  static const String _fabEnabledKey = 'fab_enabled';
  static const String _navigationStyleKey = 'navigation_style';
  
  bool _bottomNavEnabled = true;
  bool _fabEnabled = false;
  String _navigationStyle = 'glassmorphism'; // glassmorphism, material3, floating
  
  bool get bottomNavEnabled => _bottomNavEnabled;
  bool get fabEnabled => _fabEnabled;
  String get navigationStyle => _navigationStyle;
  
  NavigationSettingsService() {
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _bottomNavEnabled = prefs.getBool(_bottomNavEnabledKey) ?? true;
      _fabEnabled = prefs.getBool(_fabEnabledKey) ?? false;
      _navigationStyle = prefs.getString(_navigationStyleKey) ?? 'glassmorphism';
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading navigation settings: $e');
    }
  }
  
  Future<void> setBottomNavEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_bottomNavEnabledKey, enabled);
      _bottomNavEnabled = enabled;
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving bottom nav setting: $e');
    }
  }
  
  Future<void> setFabEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_fabEnabledKey, enabled);
      _fabEnabled = enabled;
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving FAB setting: $e');
    }
  }
  
  Future<void> setNavigationStyle(String style) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_navigationStyleKey, style);
      _navigationStyle = style;
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving navigation style: $e');
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
      _navigationStyle = 'glassmorphism';
      notifyListeners();
    } catch (e) {
      debugPrint('Error resetting navigation settings: $e');
    }
  }
} 