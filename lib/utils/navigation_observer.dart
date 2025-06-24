import 'package:flutter/material.dart';
import 'package:waste_segregation_app/utils/waste_app_logger.dart';

/// NavigatorObserver for debugging navigation issues
class DebugNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    WasteAppLogger.info('🧭 NAVIGATION PUSH: ${route.settings.name ?? route.runtimeType} '
        '(from: ${previousRoute?.settings.name ?? previousRoute?.runtimeType ?? 'none'})');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    WasteAppLogger.info('🧭 NAVIGATION POP: ${route.settings.name ?? route.runtimeType} '
        '(to: ${previousRoute?.settings.name ?? previousRoute?.runtimeType ?? 'none'})');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    WasteAppLogger.info('🧭 NAVIGATION REPLACE: ${oldRoute?.settings.name ?? oldRoute?.runtimeType} '
        '→ ${newRoute?.settings.name ?? newRoute?.runtimeType}');
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    WasteAppLogger.info('🧭 NAVIGATION REMOVE: ${route.settings.name ?? route.runtimeType}');
  }
}
