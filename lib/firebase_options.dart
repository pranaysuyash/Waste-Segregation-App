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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCvMKQNvA00QZHTg6BQ4mOaKtRXgKNqbpo',
    appId: '1:1093372542184:android:160b71eb63bc7004355d5d',
    messagingSenderId: '1093372542184',
    projectId: 'waste-segregation-app-df523',
    storageBucket: 'waste-segregation-app-df523.firebasestorage.app',
  );

  // Firebase configuration settings for Android

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB6r1DqZvXQtMEEYtJTZ8dxlXWU_26_1Hk',
    appId: '1:1093372542184:ios:90435500e0965a1c355d5d',
    messagingSenderId: '1093372542184',
    projectId: 'waste-segregation-app-df523',
    storageBucket: 'waste-segregation-app-df523.firebasestorage.app',
    androidClientId: '1093372542184-vt0daid8t327soohu1um5hf5lpmkqg92.apps.googleusercontent.com',
    iosClientId: '1093372542184-ce0c41hlrj11il6tnrisugjud0l5u3j7.apps.googleusercontent.com',
    iosBundleId: 'com.example.wasteSegregationApp',
  );

  // Firebase configuration settings for iOS

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyB6r1DqZvXQtMEEYtJTZ8dxlXWU_26_1Hk',
    appId: '1:1093372542184:ios:90435500e0965a1c355d5d',
    messagingSenderId: '1093372542184',
    projectId: 'waste-segregation-app-df523',
    storageBucket: 'waste-segregation-app-df523.firebasestorage.app',
    androidClientId: '1093372542184-vt0daid8t327soohu1um5hf5lpmkqg92.apps.googleusercontent.com',
    iosClientId: '1093372542184-ce0c41hlrj11il6tnrisugjud0l5u3j7.apps.googleusercontent.com',
    iosBundleId: 'com.example.wasteSegregationApp',
  );

  // Firebase configuration settings for macOS

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBKU5b43AxbK4S_SHotfT8vYTabNVGyWOk',
    appId: '1:1093372542184:web:f6d7c0170b4a16a6355d5d',
    messagingSenderId: '1093372542184',
    projectId: 'waste-segregation-app-df523',
    authDomain: 'waste-segregation-app-df523.firebaseapp.com',
    storageBucket: 'waste-segregation-app-df523.firebasestorage.app',
    measurementId: 'G-4NHHDPWNYJ',
  );

  // Firebase configuration settings for Web
}
