# Waste Segregation App: Comprehensive Troubleshooting Guide

## Overview

This troubleshooting guide provides solutions for common issues encountered during development, testing, and production use of the Waste Segregation App. Updated with the latest critical fixes and learnings.

_Last updated: May 24, 2025_

## Table of Contents

1. [🔥 Critical Production Issues](#critical-production-issues)
2. [Development Environment Issues](#development-environment-issues)
3. [Build and Compilation Issues](#build-and-compilation-issues)
4. [Runtime and App Crashes](#runtime-and-app-crashes)
5. [AI Service Integration Issues](#ai-service-integration-issues)
6. [Firebase Integration Issues](#firebase-integration-issues)
7. [Performance Issues](#performance-issues)
8. [Platform-Specific Issues](#platform-specific-issues)
9. [User-Reported Issues](#user-reported-issues)
10. [Production Deployment Issues](#production-deployment-issues)
11. [Emergency Procedures](#emergency-procedures)

## 🔥 Critical Production Issues

### Play Store Google Sign-In Failure

#### Problem: `PlatformException(sign_in_failed, error code: 10)` in Play Store internal testing
**Symptoms:**
- Google Sign-In works locally but fails in Play Store
- Error code 10 (DEVELOPER_ERROR)
- Users can't authenticate when app is downloaded from Play Store

**Root Cause:** Play Store App Signing certificate SHA-1 not registered in Firebase Console

**Immediate Solution:**
```bash
# 1. Get Play Store SHA-1 from Play Console → App Signing
# 2. Add SHA-1 to Firebase Console → Project Settings → Android App
# 3. Download updated google-services.json
# 4. Clean build and upload new AAB

chmod +x fix_play_store_signin.sh
./fix_play_store_signin.sh
```

**Prevention:**
- Always add Play Store App Signing SHA-1 before internal testing
- Test Google Sign-In in Play Store environment before wider release
- Document all SHA-1 certificates for team reference

### State Management Crashes ✅ **RESOLVED**

#### Problem: `setState() or markNeedsBuild() called during build`
**Solution Pattern:**
```dart
// ❌ BAD - Causes build errors
notifyListeners(); 

// ✅ GOOD - Safe state update
WidgetsBinding.instance.addPostFrameCallback((_) {
  if (mounted) notifyListeners();
});
```

### Collection Access Errors ✅ **RESOLVED**

#### Problem: `Bad state: No element` exceptions
**Solution Pattern:**
```dart
// ❌ BAD - Throws if empty
final first = list.first;
final filtered = list.where((item) => condition).toList();

// ✅ GOOD - Safe access
final first = list.safeFirst;
final filtered = list.safeWhere((item) => condition);
```

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

#### Problem: Tree shaking icon font errors (Release builds)
**Error:** "This application cannot tree shake icons fonts"
**Solution:** Use constant IconData objects instead of dynamic construction
```dart
// ❌ BAD
IconData(_getIconCodePoint(iconName), fontFamily: 'MaterialIcons')

// ✅ GOOD
Icons.emoji_events
```

#### Problem: Kotlin version incompatibility
**Error:** Metadata version mismatch errors
**Solution:** Update Kotlin version in `android/build.gradle`:
```gradle
buildscript {
    ext.kotlin_version = '2.0.0' // Update as needed
}
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

### UI Overflow Issues ✅ **RESOLVED**

#### Problem: Text overflow in result screens
**Solution:** Implemented controlled text with "Read More" functionality
```dart
Text(
  content,
  maxLines: 5,
  overflow: TextOverflow.ellipsis,
  style: TextStyle(fontSize: AppTheme.fontSizeRegular, height: 1.4),
),
TextButton(
  onPressed: () => _showFullContentDialog(),
  child: Text('Read More'),
)
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

#### Problem: Classification taking too long
**Solution:** Implement performance monitoring
```dart
Future<WasteClassification> classifyImage(File image) async {
  return PerformanceMonitor.trackOperation(
    'image_classification',
    () => _performClassification(image),
  );
}
```

## Firebase Integration Issues

### Authentication Issues

#### Problem: Google Sign-In not working locally
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

#### Problem: SHA-1 certificate fingerprint mismatch
**Solutions:**
1. **Get Debug SHA-1:**
   ```bash
   cd android
   ./gradlew signingReport
   ```

2. **Get Release SHA-1:**
   ```bash
   keytool -list -v -keystore your_release_keystore.jks -alias your_alias
   ```

3. **Add to Firebase Console:**
   - Go to Project Settings → Your Android App
   - Add SHA-1 under "SHA certificate fingerprints"
   - Download updated `google-services.json`

#### Problem: `google-services.json` or `GoogleService-Info.plist` not found
**Solutions:**
- Ensure files are in correct locations:
  - Android: `android/app/google-services.json`
  - iOS: `ios/Runner/GoogleService-Info.plist`
- Run `flutterfire configure` to regenerate files
- For iOS, verify file is added to Xcode target

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

**Performance Monitoring System** ✅ **NEW**
```dart
// Track operations automatically with thresholds
final result = await PerformanceMonitor.trackOperation(
  'image_classification',
  () => classifyImage(image),
);

// Get performance insights
final stats = PerformanceMonitor.getPerformanceStats();
final recommendations = PerformanceMonitor.getRecommendations();
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

#### Problem: Package name issues
**Common when changing from com.example:**
- Update `applicationId` in `android/app/build.gradle`
- Move `MainActivity.kt` to new package path
- Update package declaration in MainActivity.kt
- Update Firebase project with new package name
- Download new `google-services.json`

### iOS Issues

#### Problem: Google Sign-In "network connection lost"
**Solutions:**
- Check URL schemes in `Info.plist`
- Ensure reversed client ID is correct
- Add `LSApplicationQueriesSchemes` for Google
- Verify `GoogleService-Info.plist` is in Xcode target

#### Problem: CocoaPods dependency issues
```bash
cd ios
rm Podfile.lock
rm -rf Pods
pod repo update
pod install
```

### Web Issues

#### Problem: Web version shows blank screen
**Solutions:**
- Test with HTTP server, not `flutter run`
- Check Firebase web configuration in `web/index.html`
- Verify browser console for JavaScript errors
- Ensure authorized domains include localhost

## User-Reported Issues

### UI/UX Issues ✅ **RESOLVED**

#### Problem: Text cut off in educational content
**Solution:** Enhanced recycling code widget with expandable sections
```dart
// Color-coded recyclability status
Color _getRecyclabilityColor(String recyclableText) {
  if (recyclableText.contains('widely')) return Colors.green;
  if (recyclableText.contains('limited')) return Colors.orange;
  if (recyclableText.contains('rarely')) return Colors.red;
  return AppTheme.textSecondaryColor;
}
```

#### Problem: Poor contrast for text readability
**Solution:** Implemented comprehensive contrast improvements
- Text shadows for better visibility
- High-contrast color schemes
- Proper background overlays
- Accessibility-compliant color ratios

## Production Deployment Issues

### Play Store Publishing

#### Problem: Release signing issues
**Solution:**
```bash
# Generate release keystore
keytool -genkey -v -keystore ~/my-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias wastewise

# Configure in android/key.properties
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=wastewise
storeFile=../your-keystore-path.jks
```

#### Problem: Version code conflicts
**Pattern:**
- Internal testing: High version codes (90+)
- Public release: Clean version names (0.1.x)
- Always increment version code, can reset version name

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

#### Rollback Procedure
1. **Immediate:** Halt current release in Play Console
2. **Assess:** Identify issue scope and impact
3. **Communicate:** Notify users and stakeholders
4. **Fix:** Implement hotfix or rollback to stable version
5. **Test:** Verify fix in controlled environment
6. **Deploy:** Push emergency update

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
    
    // 4. Firebase connectivity
    await _testFirebaseConnection();
    
    // 5. Google Sign-In status
    await _testGoogleSignIn();
    
    print('✅ COMPREHENSIVE DIAGNOSTICS COMPLETED');
  }
}
```

### Enhanced Error Handling ✅ **NEW**
```dart
class EnhancedErrorHandler {
  static void handleError(dynamic error, StackTrace stackTrace) {
    // Log for debugging
    debugPrint('Error: $error');
    debugPrint('Stack trace: $stackTrace');
    
    // User-friendly message
    String userMessage = _getUserFriendlyMessage(error);
    
    // Report to analytics (if configured)
    FirebaseCrashlytics.instance.recordError(error, stackTrace);
    
    // Show to user
    _showErrorSnackbar(userMessage);
  }
}
```

## Quick Reference Commands

### Development
```bash
# Complete clean and rebuild
flutter clean && flutter pub get && cd android && ./gradlew clean && cd .. && flutter build appbundle --release

# Check Flutter environment
flutter doctor -v

# Generate SHA-1 fingerprints
cd android && ./gradlew signingReport

# iOS pod reset
cd ios && pod deintegrate && pod install --repo-update
```

### Firebase
```bash
# Configure Firebase
flutterfire configure

# Test Firebase connection
firebase use your-project-id
firebase list
```

### Debugging
```bash
# Verbose Flutter logs
flutter run -v

# Android logs
adb logcat | grep flutter

# iOS logs (in Xcode)
# Window → Devices and Simulators → View Device Logs
```

---

This troubleshooting guide is continuously updated with new issues and solutions. For the most current information, always check the project documentation and recent commit messages.

**Last Major Updates:**
- **May 24, 2025**: Added Play Store Google Sign-In certificate fix
- **May 23, 2025**: Added state management and UI/UX fixes
- **May 19, 2025**: Added package name change procedures
