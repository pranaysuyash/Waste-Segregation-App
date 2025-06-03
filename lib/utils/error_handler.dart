import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Comprehensive Error Management System for Waste Segregation App
/// Provides standardized error types, handling, and user feedback

/// Base class for all application-specific exceptions
abstract class WasteAppException implements Exception {
  
  WasteAppException._(this.message, this.code, this.metadata) 
    : timestamp = DateTime.now();
  final String message;
  final String code;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;

  @override
  String toString() => 'WasteAppException($code): $message';
  
  Map<String, dynamic> toMap() => {
    'code': code,
    'message': message,
    'metadata': metadata,
    'timestamp': timestamp.toIso8601String(),
  };
}

/// Classification-related exceptions
class ClassificationException extends WasteAppException {
  ClassificationException(String message, [Map<String, dynamic>? metadata])
      : super._(message, 'CLASSIFICATION_ERROR', metadata);
}

/// Network connectivity exceptions
class NetworkException extends WasteAppException {
  NetworkException(String message, [Map<String, dynamic>? metadata])
      : super._(message, 'NETWORK_ERROR', metadata);
}

/// Storage and data persistence exceptions
class StorageException extends WasteAppException {
  StorageException(String message, [Map<String, dynamic>? metadata])
      : super._(message, 'STORAGE_ERROR', metadata);
}

/// Camera and image processing exceptions
class CameraException extends WasteAppException {
  CameraException(String message, [Map<String, dynamic>? metadata])
      : super._(message, 'CAMERA_ERROR', metadata);
}

/// Authentication and authorization exceptions
class AuthException extends WasteAppException {
  AuthException(String message, [Map<String, dynamic>? metadata])
      : super._(message, 'AUTH_ERROR', metadata);
}

/// Global error handler
class ErrorHandler {
  static final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;
  static GlobalKey<NavigatorState>? navigatorKey;
  
  static void initialize(GlobalKey<NavigatorState> navKey) {
    navigatorKey = navKey;
  }
  
  static void handleError(
    dynamic error,
    StackTrace stackTrace, {
    bool fatal = false,
    Map<String, dynamic>? context,
  }) {
    // Log to console
    debugPrint('Error: $error');
    debugPrint('StackTrace: $stackTrace');
    
    // Report to Crashlytics
    _crashlytics.recordError(error, stackTrace, fatal: fatal);
    
    // Show user message
    _showUserFriendlyError(error);
  }
  
  static void _showUserFriendlyError(dynamic error) {
    final context = navigatorKey?.currentContext;
    if (context == null) return;
    
    var message = 'An error occurred. Please try again.';
    var icon = Icons.error_outline;
    Color color = Colors.red;
    
    if (error is ClassificationException) {
      message = 'Unable to analyze image. Try a clearer photo.';
      icon = Icons.image_not_supported;
      color = Colors.orange;
    } else if (error is NetworkException) {
      message = 'Connection problem. Check internet.';
      icon = Icons.wifi_off;
      color = Colors.red;
    } else if (error is CameraException) {
      message = 'Camera unavailable. Try gallery instead.';
      icon = Icons.camera_alt_outlined;
      color = Colors.amber;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
  
  /// Get a user-friendly error message from an exception
  static String getUserFriendlyMessage(dynamic error) {
    if (error is WasteAppException) {
      return error.message;
    } else if (error is ClassificationException) {
      return 'Unable to analyze image. Try a clearer photo.';
    } else if (error is NetworkException) {
      return 'Connection problem. Check internet.';
    } else if (error is CameraException) {
      return 'Camera unavailable. Try gallery instead.';
    } else if (error is StorageException) {
      return 'Storage error. Please try again.';
    } else if (error is AuthException) {
      return 'Authentication error. Please sign in again.';
    }
    return 'An unexpected error occurred. Please try again.';
  }
}
