import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:waste_segregation_app/utils/waste_app_logger.dart';

class WasteAppLogger {
  static late IOSink _logSink;
  static String _sessionId = '';
  static String _appVersion = '';
  static String _currentAction = 'unknown';
  static String _currentScreen = 'unknown';
  static Map<String, dynamic> _userContext = {};

  static Future<void> initialize() async {
    try {
      // Generate session ID
      _sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
      
      // Get app version
      try {
        final packageInfo = await PackageInfo.fromPlatform();
        _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
      } catch (e) {
        _appVersion = 'unknown';
      }

      // Create or append to JSONL log file in project root
      final logFile = File('waste_app_logs.jsonl');
      _logSink = logFile.openWrite(mode: FileMode.append);

      // Setup the Dart logging package
      Logger.root.level = Level.ALL;
      Logger.root.onRecord.listen((record) {
        final entry = {
          'timestamp': record.time.toIso8601String(),
          'level': record.level.name,
          'logger': record.loggerName,
          'message': record.message,
          if (record.error != null) 'error': record.error.toString(),
          if (record.stackTrace != null) 'stackTrace': record.stackTrace.toString(),
          'session_id': _sessionId,
          'app_version': _appVersion,
          'current_action': _currentAction,
          'current_screen': _currentScreen,
          'user_context': _userContext,
        };

        // Write JSONL line
        _logSink.writeln(jsonEncode(entry));
        _logSink.flush(); // Ensure immediate write

        // Mirror to console for development
        if (kDebugMode) {
          WasteAppLogger.info('WasteAppLogger: ${jsonEncode(entry)}');
        }
      });

      // Log initialization
      info('WasteAppLogger initialized', null, null, {'session_id': _sessionId, 'app_version': _appVersion});
    } catch (e) {
      // Fallback to debug print if logger initialization fails
      WasteAppLogger.severe('WasteAppLogger initialization failed: $e');
    }
  }

  static void dispose() {
    try {
      info('WasteAppLogger disposing');
      _logSink.close();
    } catch (e) {
      WasteAppLogger.severe('WasteAppLogger dispose error: $e');
    }
  }

  // Context management
  static void setCurrentAction(String action) {
    _currentAction = action;
  }

  static void setCurrentScreen(String screen) {
    _currentScreen = screen;
  }

  static void setUserContext(Map<String, dynamic> context) {
    _userContext = Map.from(context);
  }

  static void updateUserContext(String key, dynamic value) {
    _userContext[key] = value;
  }

  // Convenience logging methods
  static void debug(String message, [Map<String, dynamic>? context]) {
    final logger = Logger('WasteApp');
    if (context != null) {
      logger.fine('$message | Context: ${jsonEncode(context)}');
    } else {
      logger.fine(message);
    }
  }

  static void info(String message, [Object? error, StackTrace? stackTrace, Map<String, dynamic>? context]) {
    final logger = Logger('WasteApp');
    final fullMessage = context != null ? '$message | Context: ${jsonEncode(context)}' : message;
    logger.info(fullMessage, error, stackTrace);
  }

  static void warning(String message, [Object? error, StackTrace? stackTrace, Map<String, dynamic>? context]) {
    final logger = Logger('WasteApp');
    final fullMessage = context != null ? '$message | Context: ${jsonEncode(context)}' : message;
    logger.warning(fullMessage, error, stackTrace);
  }

  static void severe(String message, [Object? error, StackTrace? stackTrace, Map<String, dynamic>? context]) {
    final logger = Logger('WasteApp');
    final fullMessage = context != null ? '$message | Context: ${jsonEncode(context)}' : message;
    logger.severe(fullMessage, error, stackTrace);
  }

  // Waste-specific logging methods
  static void userAction(String action, {Map<String, dynamic>? context}) {
    setCurrentAction(action);
    final actionContext = {
      'action_type': 'user_interaction',
      if (context != null) ...context,
    };
    info('User action: $action', null, null, actionContext);
  }

  static void wasteEvent(String event, String wasteType, {Object? error, Map<String, dynamic>? context}) {
    final wasteContext = {
      'event_type': 'waste_processing',
      'waste_type': wasteType,
      if (context != null) ...context,
    };
    
    if (error != null) {
      severe('Waste event failed: $event for $wasteType', error, null, wasteContext);
    } else {
      info('Waste event: $event for $wasteType', null, null, wasteContext);
    }
  }

  static void performanceLog(String operation, int durationMs, {Map<String, dynamic>? context}) {
    final perfContext = {
      'event_type': 'performance',
      'operation': operation,
      'duration_ms': durationMs,
      if (context != null) ...context,
    };
    info('Performance: $operation took ${durationMs}ms', null, null, perfContext);
  }

  static void aiEvent(String event, {String? model, int? tokensUsed, Object? error, Map<String, dynamic>? context}) {
    final aiContext = {
      'event_type': 'ai_processing',
      'ai_event': event,
      if (model != null) 'model': model,
      if (tokensUsed != null) 'tokens_used': tokensUsed,
      if (context != null) ...context,
    };
    
    if (error != null) {
      severe('AI event failed: $event', error, null, aiContext);
    } else {
      info('AI event: $event', null, null, aiContext);
    }
  }

  static void cacheEvent(String event, String cacheType, {bool? hit, String? key, Object? error, Map<String, dynamic>? context}) {
    final cacheContext = {
      'event_type': 'cache_operation',
      'cache_type': cacheType,
      'cache_event': event,
      if (hit != null) 'cache_hit': hit,
      if (key != null) 'cache_key': key,
      if (context != null) ...context,
    };
    
    if (error != null) {
      severe('Cache event failed: $event', error, null, cacheContext);
    } else {
      info('Cache event: $event', null, null, cacheContext);
    }
  }

  static void navigationEvent(String event, String? fromScreen, String? toScreen, {Map<String, dynamic>? context}) {
    final navContext = {
      'event_type': 'navigation',
      'navigation_event': event,
      if (fromScreen != null) 'from_screen': fromScreen,
      if (toScreen != null) 'to_screen': toScreen,
      if (context != null) ...context,
    };
    
    if (toScreen != null) {
      setCurrentScreen(toScreen);
    }
    
    info('Navigation: $event', null, null, navContext);
  }

  static void gamificationEvent(String event, {int? pointsEarned, String? achievementId, Object? error, Map<String, dynamic>? context}) {
    final gamificationContext = {
      'event_type': 'gamification',
      'gamification_event': event,
      if (pointsEarned != null) 'points_earned': pointsEarned,
      if (achievementId != null) 'achievement_id': achievementId,
      if (context != null) ...context,
    };
    
    if (error != null) {
      severe('Gamification event failed: $event', error, null, gamificationContext);
    } else {
      info('Gamification event: $event', null, null, gamificationContext);
    }
  }
} 