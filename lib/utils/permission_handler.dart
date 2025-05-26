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
  
  /// Check and request storage permission
  static Future<bool> checkStoragePermission() async {
    if (kIsWeb) return true; // Web handles permissions differently
    
    try {
      final status = await Permission.storage.status;
      
      if (status.isGranted) {
        return true;
      } else if (status.isDenied) {
        final result = await Permission.storage.request();
        return result.isGranted;
      } else if (status.isPermanentlyDenied) {
        return false;
      }
      
      return false;
    } catch (e) {
      debugPrint('Error checking storage permission: $e');
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