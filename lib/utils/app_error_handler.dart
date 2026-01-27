import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'waste_app_logger.dart';

/// Comprehensive app-level error handler that catches all unhandled errors
class AppErrorHandler {
  static bool _isInitialized = false;
  static final List<ErrorReport> _errorReports = [];
  static const int _maxErrorReports = 100;

  /// Initialize the global error handler
  static void initialize() {
    if (_isInitialized) return;

    // Handle Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      _handleFlutterError(details);
    };

    // Handle errors outside of Flutter framework
    PlatformDispatcher.instance.onError = (error, stack) {
      _handlePlatformError(error, stack);
      return true;
    };

    // Handle zone errors (async errors not caught by Flutter)
    runZonedGuarded(() {
      // This will catch any errors in the root zone
    }, (error, stack) {
      _handleZoneError(error, stack);
    });

    _isInitialized = true;
    WasteAppLogger.info('App error handler initialized');
  }

  /// Handle Flutter framework errors
  static void _handleFlutterError(FlutterErrorDetails details) {
    final errorReport = ErrorReport(
      error: details.exception,
      stackTrace: details.stack,
      context: 'Flutter Framework',
      timestamp: DateTime.now(),
      errorType: ErrorType.flutter,
      details: {
        'library': details.library,
        'context': details.context?.toString(),
        'informationCollector': details.informationCollector?.toString(),
      },
    );

    _recordError(errorReport);

    // Log the error
    WasteAppLogger.severe('Flutter Error: ${details.exception}',
        error: details.exception,
        stackTrace: details.stack,
        context: {
          'library': details.library,
          'context': details.context?.toString(),
        });

    // In debug mode, show the red screen
    if (kDebugMode) {
      FlutterError.presentError(details);
    }
  }

  /// Handle platform-level errors
  static void _handlePlatformError(Object error, StackTrace stack) {
    final errorReport = ErrorReport(
      error: error,
      stackTrace: stack,
      context: 'Platform',
      timestamp: DateTime.now(),
      errorType: ErrorType.platform,
    );

    _recordError(errorReport);

    WasteAppLogger.severe('Platform Error: $error',
        error: error, stackTrace: stack, context: {'source': 'platform'});
  }

  /// Handle zone errors (uncaught async errors)
  static void _handleZoneError(Object error, StackTrace stack) {
    final errorReport = ErrorReport(
      error: error,
      stackTrace: stack,
      context: 'Zone',
      timestamp: DateTime.now(),
      errorType: ErrorType.zone,
    );

    _recordError(errorReport);

    WasteAppLogger.severe('Zone Error: $error',
        error: error, stackTrace: stack, context: {'source': 'zone'});
  }

  /// Record an error report
  static void _recordError(ErrorReport report) {
    _errorReports.add(report);

    // Keep only the most recent errors
    if (_errorReports.length > _maxErrorReports) {
      _errorReports.removeAt(0);
    }
  }

  /// Get all recorded error reports
  static List<ErrorReport> getErrorReports() {
    return List.unmodifiable(_errorReports);
  }

  /// Get error reports by type
  static List<ErrorReport> getErrorReportsByType(ErrorType type) {
    return _errorReports.where((report) => report.errorType == type).toList();
  }

  /// Get recent error reports (last hour)
  static List<ErrorReport> getRecentErrorReports() {
    final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
    return _errorReports
        .where((report) => report.timestamp.isAfter(oneHourAgo))
        .toList();
  }

  /// Clear all error reports
  static void clearErrorReports() {
    _errorReports.clear();
  }

  /// Get error statistics
  static ErrorStatistics getErrorStatistics() {
    final now = DateTime.now();
    final lastHour = now.subtract(const Duration(hours: 1));
    final lastDay = now.subtract(const Duration(days: 1));

    final recentErrors =
        _errorReports.where((r) => r.timestamp.isAfter(lastHour)).length;
    final dailyErrors =
        _errorReports.where((r) => r.timestamp.isAfter(lastDay)).length;

    final errorsByType = <ErrorType, int>{};
    for (final report in _errorReports) {
      errorsByType[report.errorType] =
          (errorsByType[report.errorType] ?? 0) + 1;
    }

    return ErrorStatistics(
      totalErrors: _errorReports.length,
      recentErrors: recentErrors,
      dailyErrors: dailyErrors,
      errorsByType: errorsByType,
      oldestError:
          _errorReports.isNotEmpty ? _errorReports.first.timestamp : null,
      newestError:
          _errorReports.isNotEmpty ? _errorReports.last.timestamp : null,
    );
  }

  /// Show error dialog for critical errors
  static void showCriticalErrorDialog(
      BuildContext context, ErrorReport report) {
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Critical Error'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('A critical error has occurred:'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                report.error.toString(),
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 8),
            Text('Time: ${report.timestamp.toString()}'),
            Text('Type: ${report.errorType.name}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: report.toString()));
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Error details copied to clipboard')),
              );
            },
            child: const Text('Copy Details'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Restart the app or navigate to a safe screen
              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/', (route) => false);
            },
            child: const Text('Restart App'),
          ),
        ],
      ),
    );
  }

  /// Create a safe zone for critical operations
  static Future<T?> runInSafeZone<T>(
    Future<T> Function() operation, {
    String? context,
    T? fallbackValue,
  }) async {
    return await runZonedGuarded<Future<T?>>(() async {
      try {
        return await operation();
      } catch (error, stackTrace) {
        final errorReport = ErrorReport(
          error: error,
          stackTrace: stackTrace,
          context: context ?? 'Safe Zone Operation',
          timestamp: DateTime.now(),
          errorType: ErrorType.application,
        );

        _recordError(errorReport);

        WasteAppLogger.severe('Safe zone error: $error',
            error: error,
            stackTrace: stackTrace,
            context: {'context': context});

        return fallbackValue;
      }
    }, (error, stackTrace) {
      final errorReport = ErrorReport(
        error: error,
        stackTrace: stackTrace,
        context: context ?? 'Safe Zone',
        timestamp: DateTime.now(),
        errorType: ErrorType.zone,
      );

      _recordError(errorReport);

      WasteAppLogger.severe('Safe zone uncaught error: $error',
          error: error, stackTrace: stackTrace, context: {'context': context});
    });
  }
}

/// Error report data class
class ErrorReport {
  const ErrorReport({
    required this.error,
    this.stackTrace,
    required this.context,
    required this.timestamp,
    required this.errorType,
    this.details,
  });
  final Object error;
  final StackTrace? stackTrace;
  final String context;
  final DateTime timestamp;
  final ErrorType errorType;
  final Map<String, dynamic>? details;

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('Error Report:');
    buffer.writeln('Type: ${errorType.name}');
    buffer.writeln('Context: $context');
    buffer.writeln('Timestamp: $timestamp');
    buffer.writeln('Error: $error');
    if (stackTrace != null) {
      buffer.writeln('Stack Trace:');
      buffer.writeln(stackTrace.toString());
    }
    if (details != null && details!.isNotEmpty) {
      buffer.writeln('Details:');
      details!.forEach((key, value) {
        buffer.writeln('  $key: $value');
      });
    }
    return buffer.toString();
  }
}

/// Error type enumeration
enum ErrorType {
  flutter,
  platform,
  zone,
  application,
  network,
  storage,
}

/// Error statistics data class
class ErrorStatistics {
  const ErrorStatistics({
    required this.totalErrors,
    required this.recentErrors,
    required this.dailyErrors,
    required this.errorsByType,
    this.oldestError,
    this.newestError,
  });
  final int totalErrors;
  final int recentErrors;
  final int dailyErrors;
  final Map<ErrorType, int> errorsByType;
  final DateTime? oldestError;
  final DateTime? newestError;

  @override
  String toString() {
    return 'ErrorStatistics(total: $totalErrors, recent: $recentErrors, daily: $dailyErrors)';
  }
}
