import 'package:flutter/material.dart';

/// NavigatorObserver for debugging navigation issues
class DebugNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    debugPrint('🧭 NAVIGATION PUSH: ${route.settings.name ?? route.runtimeType} '
        '(from: ${previousRoute?.settings.name ?? previousRoute?.runtimeType ?? 'none'})');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    debugPrint('🧭 NAVIGATION POP: ${route.settings.name ?? route.runtimeType} '
        '(to: ${previousRoute?.settings.name ?? previousRoute?.runtimeType ?? 'none'})');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    debugPrint('🧭 NAVIGATION REPLACE: ${oldRoute?.settings.name ?? oldRoute?.runtimeType} '
        '→ ${newRoute?.settings.name ?? newRoute?.runtimeType}');
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    debugPrint('🧭 NAVIGATION REMOVE: ${route.settings.name ?? route.runtimeType}');
  }
} 