import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default Firebase configuration options for the current platform
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not available for this platform.',
        );
    }
  }

  // Firebase configuration settings for Android
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_ANDROID_API_KEY',
    appId: 'YOUR_ANDROID_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'waste-segregation-app',
    storageBucket: 'waste-segregation-app.appspot.com',
  );

  // Firebase configuration settings for iOS
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID', 
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'waste-segregation-app',
    storageBucket: 'waste-segregation-app.appspot.com',
    iosClientId: 'YOUR_IOS_CLIENT_ID',
    iosBundleId: 'com.example.wasteSegregationApp',
  );

  // Firebase configuration settings for macOS
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'YOUR_MACOS_API_KEY',
    appId: 'YOUR_MACOS_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'waste-segregation-app',
    storageBucket: 'waste-segregation-app.appspot.com',
    iosClientId: 'YOUR_MACOS_CLIENT_ID',
    iosBundleId: 'com.example.wasteSegregationApp',
  );

  // Firebase configuration settings for Web
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA6u5t0aBkVB6h_6AKeGEOhhUF9oHqFXUA',
    appId: '1:123456789012:web:1234567890abcdef123456',
    messagingSenderId: '123456789012',
    projectId: 'waste-segregation-app',
    storageBucket: 'waste-segregation-app.appspot.com',
    authDomain: 'waste-segregation-app.firebaseapp.com',
  );
} 