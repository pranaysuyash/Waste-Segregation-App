# Firebase Troubleshooting Guide - Enhanced

This guide provides solutions to common Firebase integration issues encountered in the Waste Segregation App, with special focus on recent critical fixes.

_Last updated: May 24, 2025_

## 🔥 Critical Issues (Immediate Action Required)

### 1. Play Store Google Sign-In Certificate Mismatch ⚠️

**Error Message (Android - Play Store only)**:
```
PlatformException(sign_in_failed, com.google.android.gms.common.api.ApiException: 10: , null, null)
```

**Symptom**: Google Sign-In works locally but fails when app is downloaded from Play Store internal testing.

**Root Cause**: Play Store App Signing certificate SHA-1 fingerprint not registered in Firebase Console.

**Critical Solution**:
1. **Get Play Store SHA-1**: Play Console → Release → Setup → App signing → "App signing key certificate" 
2. **Your Play Store SHA-1**: `F8:78:26:A3:26:81:48:8A:BF:78:95:DA:D2:C0:12:36:64:96:31:B3`
3. **Add to Firebase**: Project Settings → Android App → "Add fingerprint"
4. **Download new `google-services.json`** and replace existing file
5. **Clean build and upload new AAB**

**Prevention**: Always add Play Store App Signing SHA-1 before internal testing release.

## Common Firebase Issues

### 2. `google-services.json` or `GoogleService-Info.plist` not found

**Error Message (Android)**:
`File google-services.json is missing. The Google Services Plugin cannot function without it.`

**Error Message (iOS)**:
`[Firebase/Core][I-COR000005] No App configuration found.`

**Enhanced Solution**:
- **Android**: Ensure `google-services.json` is in `android/app/` directory
- **iOS**: Ensure `GoogleService-Info.plist` is in `ios/Runner/` directory AND added to Xcode project target
- **Flutter**: Use `flutterfire configure` to regenerate files correctly
- **Verification**: Check `Build Phases > Copy Bundle Resources` in Xcode includes the plist file

**Project-Specific Paths**:
```
waste_segregation_app/
├── android/app/google-services.json          ← Android config
├── ios/Runner/GoogleService-Info.plist       ← iOS config  
└── lib/firebase_options.dart                 ← Flutter config
```

### 3. SHA-1 Certificate Management Strategy

**Current SHA-1 Certificates in Firebase**:
- **Debug**: `96:0e:d9:bf:3a:9d:33:b5:8e:3f:83:01:ec:c6:c5:39:5e:9a:cc:1d`
- **Upload**: `af:94:30:cd:b1:da:f0:21:36:61:52:bf:50:54:0f:77:43:97:31:08`
- **Play Store**: `F8:78:26:A3:26:81:48:8A:BF:78:95:DA:D2:C0:12:36:64:96:31:B3` ⚠️ **CRITICAL**

**How to Get Each Certificate**:

**Debug Certificate** (for development):
```bash
cd android
./gradlew signingReport
# Look for "SHA1" under "Variant: debug"
```

**Release Certificate** (from your keystore):
```bash
keytool -list -v -keystore ~/my-release-key.jks -alias wastewise
# Enter keystore password when prompted
```

**Play Store Certificate** (from Play Console):
1. Go to Play Console → Your App → Release → Setup → App signing
2. Copy SHA-1 from "App signing key certificate" section

**Firebase Configuration Process**:
1. Add ALL three SHA-1 certificates to Firebase Console
2. Download updated `google-services.json` after each addition
3. Replace existing file in `android/app/`
4. Clean build after each config change

### 4. Enhanced Google Sign-In Troubleshooting

**Error Code Reference**:
- **Code 10**: DEVELOPER_ERROR (SHA-1 mismatch)
- **Code 12**: CANCELED (user canceled sign-in)
- **Code 7**: NETWORK_ERROR (connectivity issues)

**Comprehensive Diagnostic Tool**:
```dart
class EnhancedGoogleSignInDiagnostics {
  static Future<void> runCompleteDiagnostics() async {
    print('🔍 Starting Google Sign-In diagnostics...');
    
    // 1. Check Firebase initialization
    try {
      await Firebase.initializeApp();
      print('✅ Firebase initialized successfully');
    } catch (e) {
      print('❌ Firebase initialization failed: $e');
      return;
    }
    
    // 2. Test Google Sign-In configuration
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final isSignedIn = await googleSignIn.isSignedIn();
      print('📱 Currently signed in: $isSignedIn');
      
      if (isSignedIn) {
        final account = await googleSignIn.signInSilently();
        print('✅ Silent sign-in successful: ${account?.email}');
      }
    } catch (e) {
      print('❌ Google Sign-In configuration error: $e');
    }
    
    // 3. Check Firebase Auth state
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      print('✅ Firebase user signed in: ${user.email}');
    } else {
      print('ℹ️ No Firebase user currently signed in');
    }
    
    print('✅ Diagnostics completed');
  }
}
```

### 5. OAuth Consent Screen Configuration

**Issue**: Sign-in fails even with correct SHA-1 certificates

**Required OAuth Consent Screen Settings**:
1. **User Type**: External (or Internal for GSuite orgs)
2. **App Information**:
   - App name: "WasteWise" or "Waste Segregation"
   - **User support email**: ⚠️ **REQUIRED** - Must be set
   - App logo: Optional but recommended
3. **Authorized Domains**: Auto-populated by Firebase
4. **Scopes**: Include `email`, `profile`, `openid`
5. **Test Users**: Add if app is in "Testing" status

**Verification Steps**:
1. Go to Google Cloud Console for your Firebase project
2. Navigate to "APIs & Services" → "OAuth consent screen"
3. Ensure all required fields are completed
4. If in "Testing" mode, add test user email addresses

### 6. Kotlin Version Compatibility (Android)

**Error Message**: Errors related to `kotlin_module`, `metadata is 1.x.x, expected version is 1.y.y`

**Current Working Configuration**:
```gradle
// android/build.gradle
buildscript {
    ext.kotlin_version = '2.0.0'  // Updated for Firebase compatibility
    dependencies {
        classpath 'com.android.tools.build:gradle:8.1.2'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
        classpath 'com.google.gms:google-services:4.4.2'  // Compatible version
    }
}
```

**Firebase BOM Compatibility**:
```gradle
// android/app/build.gradle
dependencies {
    implementation platform('com.google.firebase:firebase-bom:32.7.2')
    implementation 'com.google.firebase:firebase-analytics'
    implementation 'com.google.firebase:firebase-auth'
}
```

### 7. CocoaPods Issues (iOS) - Enhanced

**Symptom**: Build failures on iOS mentioning pods or Firebase libraries

**Enhanced Solution Process**:
```bash
# 1. Complete pod reset
cd ios
rm Podfile.lock
rm -rf Pods
rm -rf ~/.cocoapods/repos/cocoapods

# 2. Update pod repositories  
pod repo update  # This can take 10-15 minutes

# 3. Clean Xcode workspace
# In Xcode: Product → Clean Build Folder

# 4. Reinstall pods
pod install --repo-update

# 5. For Apple Silicon Macs with architecture issues
arch -x86_64 pod install
```

**iOS-Specific Firebase Configuration**:
```xml
<!-- ios/Runner/Info.plist additions -->
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>REVERSED_CLIENT_ID</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.YOUR_REVERSED_CLIENT_ID</string>
        </array>
    </dict>
</array>

<key>LSApplicationQueriesSchemes</key>
<array>
    <string>googlegmail</string>
    <string>googlemail</string>
    <string>googleplus</string>
    <string>googledrive</string>
</array>
```

### 8. Web Platform Firebase Issues - Enhanced

**Symptom**: Firebase not initializing on web, or auth methods failing

**Enhanced Web Configuration**:

**1. Update `web/index.html`:**
```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>WasteWise</title>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body>
  <!-- Firebase SDKs -->
  <script src="https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js"></script>
  <script src="https://www.gstatic.com/firebasejs/10.12.2/firebase-auth-compat.js"></script>
  <script src="https://www.gstatic.com/firebasejs/10.12.2/firebase-firestore-compat.js"></script>
  
  <!-- Firebase Configuration -->
  <script>
    const firebaseConfig = {
      apiKey: "AIzaSyCvMKQNvA00QZHTg6BQ4mOaKtRXgKNqbpo",
      authDomain: "waste-segregation-app-df523.firebaseapp.com",
      projectId: "waste-segregation-app-df523",
      storageBucket: "waste-segregation-app-df523.firebasestorage.app",
      messagingSenderId: "1093372542184",
      appId: "1:1093372542184:web:your-web-app-id"
    };
    
    // Initialize Firebase
    firebase.initializeApp(firebaseConfig);
  </script>
  
  <div id="app"></div>
  <script src="main.dart.js" type="application/javascript"></script>
</body>
</html>
```

**2. Authorized Domains Configuration:**
- Firebase Console → Authentication → Settings → Authorized domains
- Add: `localhost`, `waste-segregation-app-df523.web.app`, `waste-segregation-app-df523.firebaseapp.com`

**3. Web-Specific Debugging:**
```dart
// lib/main.dart - Web-specific initialization
import 'package:flutter/foundation.dart' show kIsWeb;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (kIsWeb) {
    // Web-specific Firebase initialization
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "AIzaSyCvMKQNvA00QZHTg6BQ4mOaKtRXgKNqbpo",
        authDomain: "waste-segregation-app-df523.firebaseapp.com",
        projectId: "waste-segregation-app-df523",
        storageBucket: "waste-segregation-app-df523.firebasestorage.app",
        messagingSenderId: "1093372542184",
        appId: "1:1093372542184:web:your-web-app-id"
      ),
    );
  } else {
    // Mobile initialization
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  
  runApp(MyApp());
}
```

## Advanced Troubleshooting Techniques

### 9. Firebase Authentication State Management

**Issue**: Authentication state not persisting or inconsistent across app restarts

**Enhanced State Management**:
```dart
class EnhancedAuthService extends ChangeNotifier {
  User? _user;
  bool _isInitialized = false;
  
  User? get currentUser => _user;
  bool get isSignedIn => _user != null;
  bool get isInitialized => _isInitialized;
  
  EnhancedAuthService() {
    _initializeAuth();
  }
  
  Future<void> _initializeAuth() async {
    // Listen to auth state changes
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      _user = user;
      _isInitialized = true;
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    });
    
    // Check current user on app start
    _user = FirebaseAuth.instance.currentUser;
    _isInitialized = true;
    notifyListeners();
  }
  
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;
      
      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;
      
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      return await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      print('Google Sign-In error: $e');
      rethrow;
    }
  }
}
```

### 10. Firebase Performance Monitoring

**Integration with App Performance System**:
```dart
class FirebasePerformanceIntegration {
  static Future<T> trackFirebaseOperation<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    final trace = FirebasePerformance.instance.newTrace(operationName);
    await trace.start();
    
    try {
      final result = await operation();
      trace.putAttribute('success', 'true');
      return result;
    } catch (e) {
      trace.putAttribute('success', 'false');
      trace.putAttribute('error', e.toString());
      rethrow;
    } finally {
      await trace.stop();
    }
  }
}
```

## Emergency Recovery Procedures

### 11. Firebase Project Recovery

**If Firebase Console becomes inaccessible or corrupted**:

1. **Backup Current Configuration**:
   ```bash
   # Save current config files
   cp android/app/google-services.json backup/
   cp ios/Runner/GoogleService-Info.plist backup/
   cp lib/firebase_options.dart backup/
   ```

2. **Project Recreation Process**:
   - Create new Firebase project with same name
   - Add Android/iOS/Web apps with same package names
   - Reconfigure authentication providers
   - Add all SHA-1 certificates
   - Update Firestore rules and security rules
   - Migrate user data if necessary

3. **Rollback Procedure**:
   ```bash
   # Restore previous working configuration
   cp backup/google-services.json android/app/
   cp backup/GoogleService-Info.plist ios/Runner/
   cp backup/firebase_options.dart lib/
   
   flutter clean
   flutter pub get
   ```

### 12. Quick Diagnostic Commands

**Complete Firebase Health Check**:
```bash
#!/bin/bash
# firebase_health_check.sh

echo "🔍 Firebase Health Check Starting..."

# 1. Check Flutter Firebase setup
echo "📱 Flutter Firebase Doctor:"
flutter packages pub run build_runner build

# 2. Check Android configuration
echo "🤖 Android Configuration:"
if [ -f "android/app/google-services.json" ]; then
    echo "✅ google-services.json found"
else
    echo "❌ google-services.json missing"
fi

# 3. Check iOS configuration
echo "🍎 iOS Configuration:"
if [ -f "ios/Runner/GoogleService-Info.plist" ]; then
    echo "✅ GoogleService-Info.plist found"
else
    echo "❌ GoogleService-Info.plist missing"
fi

# 4. Check SHA-1 certificates
echo "🔐 SHA-1 Certificates:"
cd android
./gradlew signingReport | grep SHA1
cd ..

echo "✅ Firebase Health Check Completed"
```

## Best Practices Summary

### Configuration Management
1. **Always** add all three SHA-1 certificates (debug, release, Play Store)
2. **Download fresh config files** after any Firebase Console changes
3. **Test authentication** in all environments (local, internal testing, production)
4. **Keep backup copies** of working configuration files

### Debugging Workflow
1. **Start with diagnostics** - run comprehensive checks
2. **Isolate the issue** - test each component separately
3. **Check recent changes** - what changed since it last worked?
4. **Verify environment** - ensure correct build variant and certificates

### Prevention Strategy
1. **Document all SHA-1 certificates** and their purposes
2. **Set up monitoring** for authentication failures
3. **Test in production-like environment** before release
4. **Keep Firebase Console and Play Console in sync**

---

**Critical Reminder**: The Play Store Google Sign-In issue affects ALL apps using Google authentication when deployed to Play Store. Always add the Play Store App Signing SHA-1 certificate to Firebase Console before internal testing.

**Emergency Contact**: If issues persist, escalate to Firebase Support with project ID `waste-segregation-app-df523` and reference this troubleshooting guide.
