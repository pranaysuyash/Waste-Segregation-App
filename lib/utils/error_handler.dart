import 'package:flutter/material.dart';
import '../utils/waste_app_logger.dart';

/// Centralized error handling utility to eliminate duplicate error handling patterns
class ErrorHandler {
  static GlobalKey<NavigatorState>? _navigatorKey;

  /// Initialize the error handler with navigator key
  static void initialize(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
  }

  /// Handle common async operations with consistent error handling
  static Future<T?> handleAsync<T>(
    Future<T> Function() operation, {
    String? context,
    String? service,
    String? file,
    bool showSnackBar = false,
    BuildContext? buildContext,
    String? userMessage,
  }) async {
    try {
      return await operation();
    } catch (error, stackTrace) {
      WasteAppLogger.severe('Error in ${context ?? 'operation'}',
          error: error,
          stackTrace: stackTrace,
          context: {
            if (service != null) 'service': service,
            if (file != null) 'file': file,
          });

      if (showSnackBar && buildContext != null && buildContext.mounted) {
        ScaffoldMessenger.of(buildContext).showSnackBar(
          SnackBar(
            content:
                Text(userMessage ?? 'An error occurred. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }

      return null;
    }
  }

  /// Handle operations that don't return a value
  static Future<bool> handleAsyncVoid(
    Future<void> Function() operation, {
    String? context,
    String? service,
    String? file,
    bool showSnackBar = false,
    BuildContext? buildContext,
    String? userMessage,
  }) async {
    try {
      await operation();
      return true;
    } catch (error, stackTrace) {
      WasteAppLogger.severe('Error in ${context ?? 'operation'}',
          error: error,
          stackTrace: stackTrace,
          context: {
            if (service != null) 'service': service,
            if (file != null) 'file': file,
          });

      if (showSnackBar && buildContext != null && buildContext.mounted) {
        ScaffoldMessenger.of(buildContext).showSnackBar(
          SnackBar(
            content:
                Text(userMessage ?? 'An error occurred. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }

      return false;
    }
  }

  /// Handle synchronous operations with error logging
  static T? handleSync<T>(
    T Function() operation, {
    String? context,
    String? service,
    String? file,
    bool showSnackBar = false,
    BuildContext? buildContext,
    String? userMessage,
  }) {
    try {
      return operation();
    } catch (error, stackTrace) {
      WasteAppLogger.severe('Error in ${context ?? 'operation'}',
          error: error,
          stackTrace: stackTrace,
          context: {
            if (service != null) 'service': service,
            if (file != null) 'file': file,
          });

      if (showSnackBar && buildContext != null && buildContext.mounted) {
        ScaffoldMessenger.of(buildContext).showSnackBar(
          SnackBar(
            content:
                Text(userMessage ?? 'An error occurred. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }

      return null;
    }
  }

  /// Show a standardized error dialog
  static void showErrorDialog(
    BuildContext context, {
    String? title,
    String? message,
    VoidCallback? onRetry,
  }) {
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title ?? 'Error'),
        content:
            Text(message ?? 'An unexpected error occurred. Please try again.'),
        actions: [
          if (onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: const Text('Retry'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show a standardized success message
  static void showSuccessMessage(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: duration,
      ),
    );
  }

  /// Show a standardized warning message
  static void showWarningMessage(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        duration: duration,
      ),
    );
  }

  /// Handle error with logging (legacy method for compatibility)
  static void handleError(Object error, StackTrace? stackTrace,
      {String? context}) {
    WasteAppLogger.severe('Error handled: ${context ?? 'unknown context'}',
        error: error, stackTrace: stackTrace);
  }

  /// Get user-friendly error message (legacy method for compatibility)
  static String getUserFriendlyMessage(Object error) {
    if (error is Exception) {
      final errorString = error.toString();
      if (errorString.contains('network') ||
          errorString.contains('connection')) {
        return 'Network connection issue. Please check your internet connection.';
      }
      if (errorString.contains('timeout')) {
        return 'Operation timed out. Please try again.';
      }
      if (errorString.contains('permission')) {
        return 'Permission denied. Please check app permissions.';
      }
      if (errorString.contains('storage') || errorString.contains('space')) {
        return 'Storage issue. Please free up some space and try again.';
      }
    }
    return 'An unexpected error occurred. Please try again.';
  }

  /// Common retry logic with exponential backoff
  static Future<T?> retryOperation<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
    double backoffMultiplier = 2.0,
    String? context,
  }) async {
    var attempts = 0;
    var delay = initialDelay;

    while (attempts < maxRetries) {
      try {
        return await operation();
      } catch (error, stackTrace) {
        attempts++;

        if (attempts >= maxRetries) {
          WasteAppLogger.severe(
              'Operation failed after $maxRetries attempts: ${context ?? 'unknown'}',
              error: error,
              stackTrace: stackTrace);
          rethrow;
        }

        WasteAppLogger.warning(
            'Operation failed (attempt $attempts/$maxRetries), retrying in ${delay.inSeconds}s: ${context ?? 'unknown'}',
            error: error,
            stackTrace: stackTrace);

        await Future.delayed(delay);
        delay = Duration(
            milliseconds: (delay.inMilliseconds * backoffMultiplier).round());
      }
    }

    return null;
  }
}
