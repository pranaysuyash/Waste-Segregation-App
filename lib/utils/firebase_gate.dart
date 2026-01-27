import 'package:flutter/foundation.dart';

const bool _forceFirebase = bool.fromEnvironment('FORCE_FIREBASE');

bool get isFirebaseEnabled {
  if (_forceFirebase) {
    return true;
  }
  if (kIsWeb) {
    return true;
  }
  if (kDebugMode && defaultTargetPlatform == TargetPlatform.iOS) {
    return false;
  }
  return true;
}
