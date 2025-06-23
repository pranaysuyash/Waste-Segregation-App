import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/analytics_service.dart';
import '../providers/app_providers.dart';
import 'waste_app_logger.dart';

/// Global RouteObserver instance for analytics tracking
final RouteObserver<PageRoute> analyticsRouteObserver = RouteObserver<PageRoute>();

/// Wrapper widget that automatically tracks screen views when routes change
class AnalyticsRouteAware extends ConsumerStatefulWidget {
  const AnalyticsRouteAware({
    super.key,
    required this.child,
    this.screenName,
    this.trackScrollDepth = false,
    this.additionalParameters,
  });

  final Widget child;
  final String? screenName;
  final bool trackScrollDepth;
  final Map<String, dynamic>? additionalParameters;

  @override
  ConsumerState<AnalyticsRouteAware> createState() => _AnalyticsRouteAwareState();
}

class _AnalyticsRouteAwareState extends ConsumerState<AnalyticsRouteAware>
    with RouteAware {
  late AnalyticsService _analyticsService;
  DateTime? _screenStartTime;
  String? _previousScreenName;
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _analyticsService = ref.read(analyticsServiceProvider);
    
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      analyticsRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    analyticsRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPush() {
    WasteAppLogger.info('🧭 Route pushed: ${_getScreenName()}');
    _trackScreenView('push');
  }
  
  @override
  void didPopNext() {
    WasteAppLogger.info('🧭 Route returned to: ${_getScreenName()}');
    _trackScreenView('pop_next');
  }

  @override
  void didPop() {
    WasteAppLogger.info('🧭 Route popped: ${_getScreenName()}');
    _trackScreenEnd();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    WasteAppLogger.info('🧭 Route replaced: ${_getScreenName()}');
    _trackScreenView('replace');
  }

  /// Track screen view with enhanced context
  void _trackScreenView(String navigationMethod) {
    final screenName = _getScreenName();
    final now = DateTime.now();
    
    // Calculate time on previous screen if available
    int? timeOnPreviousScreen;
    if (_screenStartTime != null) {
      timeOnPreviousScreen = now.difference(_screenStartTime!).inMilliseconds;
    }
    
    _screenStartTime = now;
    
    // Track the page view with enhanced parameters
    _analyticsService.trackPageView(
      screenName,
      previousScreen: _previousScreenName,
      navigationMethod: navigationMethod,
      timeOnPreviousScreen: timeOnPreviousScreen,
    );
    
    // Also track as screen view for backward compatibility
    _analyticsService.trackScreenView(screenName, parameters: {
      'navigation_method': navigationMethod,
      'previous_screen': _previousScreenName,
      if (timeOnPreviousScreen != null) 'time_on_previous_screen_ms': timeOnPreviousScreen,
      ...?widget.additionalParameters,
    });
    
    _previousScreenName = screenName;
    
    WasteAppLogger.info('📊 Screen tracked: $screenName', null, null, {
      'navigation_method': navigationMethod,
      'previous_screen': _previousScreenName,
      'service': 'AnalyticsRouteObserver',
    });
  }

  /// Track when user leaves screen
  void _trackScreenEnd() {
    if (_screenStartTime != null) {
      final timeSpent = DateTime.now().difference(_screenStartTime!).inMilliseconds;
      final screenName = _getScreenName();
      
      _analyticsService.trackUserAction('screen_exit', parameters: {
        'screen_name': screenName,
        'time_spent_ms': timeSpent,
        'exit_method': 'navigation',
      });
      
      WasteAppLogger.info('📊 Screen exit tracked: $screenName (${timeSpent}ms)', null, null, {
        'time_spent_ms': timeSpent,
        'service': 'AnalyticsRouteObserver',
      });
    }
  }

  /// Extract screen name from route or widget
  String _getScreenName() {
    // Use provided screen name first
    if (widget.screenName != null) {
      return widget.screenName!;
    }
    
    // Try to get from route settings
    final route = ModalRoute.of(context);
    if (route?.settings.name != null) {
      return route!.settings.name!;
    }
    
    // Fall back to route type
    if (route != null) {
      return route.runtimeType.toString().replaceAll('Route', '');
    }
    
    // Last resort: use widget type
    return widget.child.runtimeType.toString();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Enhanced analytics route observer that can track additional metrics
class EnhancedAnalyticsRouteObserver extends RouteObserver<PageRoute> {
  
  EnhancedAnalyticsRouteObserver(this.analyticsService);
  final AnalyticsService analyticsService;
  final Map<Route, DateTime> _routeStartTimes = {};

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _routeStartTimes[route] = DateTime.now();
    
    if (route is PageRoute) {
      _trackRouteChange(route, previousRoute, 'push');
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    
    if (route is PageRoute) {
      _trackRouteExit(route);
      _routeStartTimes.remove(route);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    
    if (oldRoute != null) {
      _trackRouteExit(oldRoute);
      _routeStartTimes.remove(oldRoute);
    }
    
    if (newRoute is PageRoute) {
      _routeStartTimes[newRoute] = DateTime.now();
      _trackRouteChange(newRoute, oldRoute, 'replace');
    }
  }

  void _trackRouteChange(PageRoute route, Route<dynamic>? previousRoute, String method) {
    final screenName = _getRouteName(route);
    final previousScreenName = previousRoute != null ? _getRouteName(previousRoute) : null;
    
    analyticsService.trackPageView(
      screenName,
      previousScreen: previousScreenName,
      navigationMethod: method,
    );
    
    WasteAppLogger.info('🧭 Enhanced route tracking: $screenName', null, null, {
      'method': method,
      'previous_screen': previousScreenName,
      'service': 'EnhancedAnalyticsRouteObserver',
    });
  }

  void _trackRouteExit(Route<dynamic> route) {
    final startTime = _routeStartTimes[route];
    if (startTime != null) {
      final timeSpent = DateTime.now().difference(startTime).inMilliseconds;
      final screenName = _getRouteName(route);
      
      analyticsService.trackUserAction('route_exit', parameters: {
        'screen_name': screenName,
        'time_spent_ms': timeSpent,
      });
    }
  }

  String _getRouteName(Route<dynamic> route) {
    if (route.settings.name != null) {
      return route.settings.name!;
    }
    return route.runtimeType.toString().replaceAll('Route', '');
  }
}

/// Utility class for managing route-based analytics
class RouteAnalyticsManager {
  static EnhancedAnalyticsRouteObserver? _enhancedObserver;
  
  /// Initialize enhanced route tracking
  static void initialize(AnalyticsService analyticsService) {
    _enhancedObserver = EnhancedAnalyticsRouteObserver(analyticsService);
  }
  
  /// Get the enhanced observer instance
  static RouteObserver<PageRoute> get observer {
    return _enhancedObserver ?? analyticsRouteObserver;
  }
  
  /// Track a custom route event
  static void trackCustomRouteEvent(String eventName, Map<String, dynamic> parameters) {
    // This could be used for special navigation events
    WasteAppLogger.info('🧭 Custom route event: $eventName', null, null, {
      'event_name': eventName,
      'parameters': parameters,
      'service': 'RouteAnalyticsManager',
    });
  }
} 