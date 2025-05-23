# Waste Segregation App: Comprehensive Troubleshooting Guide

## Overview

This troubleshooting guide provides solutions for common issues encountered during development, testing, and production use of the Waste Segregation App.

## Table of Contents

1. [Development Environment Issues](#development-environment-issues)
2. [Build and Compilation Issues](#build-and-compilation-issues)
3. [Runtime and App Crashes](#runtime-and-app-crashes)
4. [AI Service Integration Issues](#ai-service-integration-issues)
5. [Firebase Integration Issues](#firebase-integration-issues)
6. [Performance Issues](#performance-issues)
7. [Platform-Specific Issues](#platform-specific-issues)
8. [User-Reported Issues](#user-reported-issues)
9. [Production Deployment Issues](#production-deployment-issues)
10. [Emergency Procedures](#emergency-procedures)

## Development Environment Issues

### Flutter Doctor Issues

#### Problem: Flutter doctor shows errors
```bash
flutter doctor -v
```

**Common Solutions:**

1. **Android SDK Issues**
```bash
# Accept Android licenses
flutter doctor --android-licenses

# Update Android SDK
sdkmanager --update
```

2. **iOS Development Issues (macOS)**
```bash
# Install/update Xcode
sudo xcode-select --install

# Update CocoaPods
sudo gem install cocoapods
pod setup
```

3. **Flutter SDK Issues**
```bash
# Update Flutter
flutter upgrade

# Clear Flutter cache
flutter clean
flutter pub cache repair
```

## Build and Compilation Issues

### Common Build Errors

#### Problem: Gradle build failures
```bash
# Clean Gradle cache
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

#### Problem: Pod install failures (iOS)
```bash
cd ios
pod deintegrate
pod install --repo-update
cd ..
```

## Runtime and App Crashes

### Memory Issues

#### Problem: Out of memory errors
**Solutions:**
```dart
class MemoryOptimization {
  static void optimizeImages() {
    // Clear image cache
    PaintingBinding.instance.imageCache.clear();
    
    // Limit image cache size
    PaintingBinding.instance.imageCache.maximumSize = 50;
    PaintingBinding.instance.imageCache.maximumSizeBytes = 50 * 1024 * 1024;
  }
}
```

## AI Service Integration Issues

### Gemini API Issues

#### Problem: API key not working
**Diagnostic Steps:**
```dart
class GeminiDiagnostics {
  static Future<void> testApiKey() async {
    try {
      final response = await http.get(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models'),
        headers: {
          'Authorization': 'Bearer ${ApiKeyManager.getGeminiKey()}',
        },
      );
      
      if (response.statusCode == 200) {
        print('✅ Gemini API key is valid');
      } else if (response.statusCode == 401) {
        print('❌ Invalid API key');
      }
    } catch (e) {
      print('❌ API test failed: $e');
    }
  }
}
```

## Firebase Integration Issues

### Authentication Issues

#### Problem: Google Sign-In not working
**Solutions:**
```dart
class AuthTroubleshooting {
  static Future<void> diagnoseGoogleSignIn() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser != null) {
        print('✅ Google Sign-In successful: ${googleUser.email}');
      } else {
        print('❌ Google Sign-In returned null');
      }
    } catch (e) {
      print('❌ Google Sign-In failed: $e');
    }
  }
}
```

## Performance Issues

### App Launch Performance

#### Problem: Slow app startup
**Diagnostic Code:**
```dart
class PerformanceDiagnostics {
  static void trackAppStart() {
    final loadTime = DateTime.now().difference(_appStartTime);
    print('App load time: ${loadTime.inMilliseconds}ms');
    
    if (loadTime.inSeconds > 3) {
      print('⚠️ Slow app startup detected');
    }
  }
}
```

## Platform-Specific Issues

### Android Issues

#### Problem: Camera not working on Android
**Solutions:**
```dart
class AndroidCameraDiagnostics {
  static Future<void> checkCameraPermissions() async {
    final permission = await Permission.camera.status;
    print('Camera permission: $permission');
    
    if (permission.isDenied) {
      final result = await Permission.camera.request();
      print('Permission request result: $result');
    }
  }
}
```

## Emergency Procedures

### Critical Production Issues

#### Emergency Response Checklist
```bash
#!/bin/bash
# emergency_response.sh

echo "🚨 EMERGENCY RESPONSE ACTIVATED"
echo "1. Checking app status..."
echo "2. Checking Firebase status..."
echo "3. Preparing emergency rollback..."
echo "4. Team notification sent"
```

## Troubleshooting Tools

### Diagnostic Command Center
```dart
class DiagnosticCenter {
  static Future<void> runComprehensiveDiagnostics() async {
    print('🔍 COMPREHENSIVE DIAGNOSTICS STARTING...');
    
    // 1. System diagnostics
    await _runSystemDiagnostics();
    
    // 2. Network diagnostics
    await _runNetworkDiagnostics();
    
    // 3. Performance diagnostics
    await _runPerformanceDiagnostics();
    
    print('✅ COMPREHENSIVE DIAGNOSTICS COMPLETED');
  }
}
```

This troubleshooting guide provides systematic approaches to identify and resolve common issues in the Waste Segregation App across development, testing, and production environments.