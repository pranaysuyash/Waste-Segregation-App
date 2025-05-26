import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';
import 'constants.dart';

class PermissionHandler {
  /// Check and request camera permission
  static Future<bool> checkCameraPermission() async {
    if (kIsWeb) return true; // Web handles permissions differently
    
    try {
      final status = await Permission.camera.status;
      
      if (status.isGranted) {
        return true;
      } else if (status.isDenied) {
        final result = await Permission.camera.request();
        return result.isGranted;
      } else if (status.isPermanentlyDenied) {
        return false;
      }
      
      return false;
    } catch (e) {
      debugPrint('Error checking camera permission: $e');
      return false;
    }
  }
  
  /// Check and request storage permission (for gallery access)
  static Future<bool> checkStoragePermission() async {
    if (kIsWeb) return true; // Web handles permissions differently
    
    try {
      // For Android 13+ (API 33+), use photos permission instead of storage
      // For older versions, fall back to storage permission
      Permission permission;
      
      // Try photos permission first (Android 13+)
      try {
        permission = Permission.photos;
        final status = await permission.status;
        
        if (status.isGranted) {
          debugPrint('Photos permission already granted');
          return true;
        } else if (status.isDenied) {
          debugPrint('Photos permission denied, requesting...');
          final result = await permission.request();
          if (result.isGranted) {
            debugPrint('Photos permission granted after request');
            return true;
          }
        } else if (status.isPermanentlyDenied) {
          debugPrint('Photos permission permanently denied');
          return false;
        }
      } catch (e) {
        debugPrint('Photos permission not available, trying storage: $e');
      }
      
      // Fallback to storage permission for older Android versions
      try {
        permission = Permission.storage;
        final status = await permission.status;
        
        if (status.isGranted) {
          debugPrint('Storage permission already granted');
          return true;
        } else if (status.isDenied) {
          debugPrint('Storage permission denied, requesting...');
          final result = await permission.request();
          if (result.isGranted) {
            debugPrint('Storage permission granted after request');
            return true;
          }
        } else if (status.isPermanentlyDenied) {
          debugPrint('Storage permission permanently denied');
          return false;
        }
      } catch (e) {
        debugPrint('Storage permission check failed: $e');
      }
      
      return false;
    } catch (e) {
      debugPrint('Error checking storage/photos permission: $e');
      return false;
    }
  }
  
  /// Show permission denied dialog
  static void showPermissionDeniedDialog(
    BuildContext context, 
    String permissionType,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$permissionType Permission Required'),
        content: Text(
          'This app needs $permissionType permission to function properly. '
          'Please grant the permission in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: AppTheme.dialogCancelButtonStyle(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            style: AppTheme.dialogConfirmButtonStyle(context),
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }
} 