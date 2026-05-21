import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';

class WasteAppLogger {
  static final Logger _logger = Logger('WasteApp');
  static String _sessionId = '';
  static String _appVersion = 'unknown';
  static String _currentAction = 'unknown';
  static String _currentScreen = 'unknown';
  static Map<String, dynamic> _userContext = {};
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      _sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';

      try {
        final packageInfo = await PackageInfo.fromPlatform().timeout(
          const Duration(seconds: 2),
          onTimeout: () => throw 'PackageInfo timeout',
        );
        _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
      } catch (e) {
        debugPrint('WasteAppLogger: Could not get package info: $e');
      }

      Logger.root.level = Level.ALL;
      Logger.root.onRecord.listen((record) {
        if (kDebugMode) {
          final time =
              record.time.toIso8601String().split('T').last.substring(0, 8);
          print('[$time] [${record.level.name}] ${record.message}');
          if (record.error != null) print('Error: ${record.error}');
        }
      });

      _initialized = true;
      info('WasteAppLogger initialized');
    } catch (e) {
      debugPrint('WasteAppLogger critical failure: $e');
    }
  }

  static void setCurrentAction(String action) => _currentAction = action;
  static void setCurrentScreen(String screen) => _currentScreen = screen;
  static void setUserContext(Map<String, dynamic> context) =>
      _userContext = Map.from(context);

  static void info(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    final enrichedContext = _enrichContext(context);
    _logger.info(
      enrichedContext != null ? '$message | $enrichedContext' : message,
      error,
      stackTrace,
    );
  }

  static void warning(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    final enrichedContext = _enrichContext(context);
    _logger.warning(
      enrichedContext != null ? '$message | $enrichedContext' : message,
      error,
      stackTrace,
    );
  }

  static void severe(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    final enrichedContext = _enrichContext(context);
    _logger.severe(
      enrichedContext != null ? '$message | $enrichedContext' : message,
      error,
      stackTrace,
    );
  }

  /// Enriches log context with session, screen, action, and user context
  static Map<String, dynamic>? _enrichContext(Map<String, dynamic>? context) {
    final enriched = <String, dynamic>{
      ...?context,
      if (_sessionId.isNotEmpty) 'session_id': _sessionId,
      if (_appVersion != 'unknown') 'app_version': _appVersion,
      if (_currentScreen != 'unknown') 'screen': _currentScreen,
      if (_currentAction != 'unknown') 'action': _currentAction,
      if (_userContext.isNotEmpty) 'user_context': _userContext,
    };
    return enriched.isEmpty ? null : enriched;
  }

  // Aliases for other common methods used in the app
  static void debug(String msg, {Map<String, dynamic>? context}) =>
      info(msg, context: context);
  static void fine(String msg, {Map<String, dynamic>? context}) =>
      info(msg, context: context);
  static void userAction(String action, {Map<String, dynamic>? context}) =>
      info('Action: $action', context: context);
  static void wasteEvent(
    String ev,
    String type, {
    Object? error,
    Map<String, dynamic>? context,
  }) =>
      info(
        'Waste: $ev - $type',
        error: error,
        context: context,
      );
  static void performanceLog(
    String op,
    int ms, {
    Map<String, dynamic>? context,
  }) =>
      info('Perf: $op ${ms}ms');
  static void aiEvent(
    String ev, {
    String? model,
    Object? error,
    Map<String, dynamic>? context,
  }) =>
      info('AI: $ev ${model ?? ""}', context: context);

  static void cacheEvent(
    String ev,
    String type, {
    bool? hit,
    String? key,
    Object? error,
    Map<String, dynamic>? context,
  }) {
    final merged = <String, dynamic>{
      'event': ev,
      'type': type,
      if (hit != null) 'hit': hit,
      if (key != null) 'key': key,
      ...?context,
    };
    info('Cache: $ev $type', context: merged);
    if (error != null) {
      warning('Cache: $ev $type error', error: error, context: merged);
    }
  }

  static void navigationEvent(String ev, String? from, String? to) =>
      info('Nav: $ev $from -> $to');

  static void gamificationEvent(
    String ev, {
    int? points,
    int? pointsEarned,
    String? achievementId,
    Object? error,
    Map<String, dynamic>? context,
  }) {
    final merged = <String, dynamic>{
      if (points != null) 'points': points,
      if (pointsEarned != null) 'pointsEarned': pointsEarned,
      if (achievementId != null) 'achievementId': achievementId,
      ...?context,
    };
    info('Game: $ev', context: merged.isEmpty ? null : merged);
    if (error != null) {
      warning(
        'Game: $ev error',
        error: error,
        context: merged.isEmpty ? null : merged,
      );
    }
  }
}
