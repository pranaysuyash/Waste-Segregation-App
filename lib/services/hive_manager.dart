import 'package:hive_flutter/hive_flutter.dart';

/// Singleton manager for Hive box operations to prevent duplicate box opening errors
class HiveManager {
  factory HiveManager() => _instance;
  HiveManager._internal();
  static final HiveManager _instance = HiveManager._internal();

  /// Safely opens a Hive box, checking if it's already open first
  static Future<Box<T>> openBox<T>(String name) async {
    if (Hive.isBoxOpen(name)) {
      return Hive.box<T>(name);
    }
    return Hive.openBox<T>(name);
  }

  /// Safely opens a regular (dynamic) Hive box
  static Future<Box> openDynamicBox(String name) async {
    if (Hive.isBoxOpen(name)) {
      return Hive.box(name);
    }
    return Hive.openBox(name);
  }

  /// Check if a box is already open
  static bool isBoxOpen(String name) {
    return Hive.isBoxOpen(name);
  }

  /// Get an already opened box
  static Box<T> getBox<T>(String name) {
    return Hive.box<T>(name);
  }

  /// Get an already opened dynamic box
  static Box getDynamicBox(String name) {
    return Hive.box(name);
  }

  /// Close a specific box
  static Future<void> closeBox(String name) async {
    if (Hive.isBoxOpen(name)) {
      await Hive.box(name).close();
    }
  }

  /// Close all open boxes
  static Future<void> closeAllBoxes() async {
    await Hive.close();
  }
} 