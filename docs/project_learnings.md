# Waste Segregation App: Project Learnings

This document captures key technical learnings, issues, and solutions discovered during the development and release process of WasteWise.

## Flutter and Dart

### Build Issues

1. **Tree Shaking and IconData**
   - **Issue**: Release builds failing with "This application cannot tree shake icons fonts. It has non-constant instances of IconData"
   - **Solution**: Use constant IconData objects (e.g., `Icons.emoji_events`) instead of dynamically constructed ones
   - **Code fix**: Replace `IconData(_getIconCodePoint(iconName), fontFamily: 'MaterialIcons')` with constant icons like `Icons.emoji_events`

2. **Web Platform Blank Screen**
   - **Issue**: Web builds showing blank screen despite successful compilation
   - **Solution**: Ensure proper initialization of Firebase for web and check browser console for errors
   - **Note**: Web requires specific configuration in `web/index.html` and a dedicated entry point

3. **Debug Symbols in Play Console**
   - **Issue**: Play Console showing warning about missing debug symbols
   - **Solution**: Flutter's `.symbols` files are not the format Play Console expects
   - **Commands**:
     ```
     flutter build appbundle --release --obfuscate --split-debug-info=./debug-symbols
     ```
   - **Note**: Keep these files for Flutter crash reporting; not needed for Play Console

## Android Configuration

1. **Kotlin Version**
   - **Issue**: Incompatibility between Firebase and Kotlin version
   - **Solution**: Update Kotlin version to 2.0.0
   - **Files updated**:
     ```
     android/build.gradle:
       ext.kotlin_version = '2.0.0'
     ```

2. **Release Signing**
   - **Issue**: Debug-signed builds not accepted by Play Store
   - **Solution**: Create keystore, configure in `key.properties`, update `build.gradle`
   - **Steps**:
     ```
     keytool -genkey -v -keystore ~/my-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias wastewise
     ```
     Create `android/key.properties` with path and passwords
     Configure `signingConfigs` in `android/app/build.gradle`

3. **Package Name**
   - **Issue**: "com.example" package names rejected by Play Store
   - **Solution**: Change to unique package name (e.g., `com.pranaysuyash.wastewise`)
   - **Steps**:
     - Update `applicationId` in `build.gradle`
     - Move `MainActivity.kt` to new package path
     - Update package declaration in MainActivity.kt
     - Add new package to Firebase project and update `google-services.json`

4. **App Name and Manifest**
   - **Issue**: Best practice to use string resources for app name
   - **Solution**: Create `strings.xml` and reference in manifest
   - **Files**:
     - `android/app/src/main/res/values/strings.xml`
     - `android/app/src/main/AndroidManifest.xml`

## iOS Configuration

1. **Google Sign-In**
   - **Issue**: Google Sign-In failing with "network connection lost" error
   - **Solution**: Fix URL Schemes and AppDelegate configuration
   - **Steps**:
     - Ensure correct bundle ID and reversed client ID in `Info.plist`
     - Add `LSApplicationQueriesSchemes` for Google URL handling
     - Update AppDelegate to handle callback URLs

2. **CocoaPods Issues**
   - **Issue**: Dependencies not syncing properly
   - **Solution**: Run `pod install` after any Firebase config changes

## Firebase Configuration

1. **Cross-platform Firebase Setup**
   - **Issue**: Data not syncing between platforms
   - **Solution**: Ensure all platforms (Android, iOS, web) use the same Firebase project
   - **Files**:
     - `google-services.json` (Android)
     - `GoogleService-Info.plist` (iOS)
     - `firebase_options.dart` (Flutter)

2. **Google Services Plugin Version**
   - **Issue**: Conflicting plugin versions
   - **Solution**: Standardize on version 4.4.2
   - **Files**:
     ```
     android/build.gradle
     ```

## Play Store Publishing

1. **Release Notes Best Practices**
   - **Template**:
     ```
     Welcome to the first release of WasteWise!

     • AI-powered waste identification and sorting
     • Google Sign-In and guest mode
     • Gamification: achievements, challenges, and daily streaks
     • Educational content and waste analytics dashboard
     • Local data storage with optional Google Drive sync
     • Camera and gallery support for waste classification
     • Clean, modern UI with dark mode

     Thank you for helping make waste segregation smarter and easier!
     ```

2. **App Submission Checklist**
   - Package name requirements
   - App signing (release key)
   - App assets (icon, screenshots, descriptions)
   - Privacy policy URL
   - Release tracks (internal testing)

## Git and Version Control

1. **Package Name Changes**
   - Remember to update and commit all related files:
     - build.gradle
     - MainActivity.kt in new location
     - google-services.json
     - Documentation references

## Future Considerations

1. **Flutter Web Deployment**
   - Ensure Firebase web configuration matches project
   - Test in HTTP server environment, not just dev server
   - Check for platform-specific code that might break web

2. **Cross-platform Data Sync**
   - Implement Firestore sync for key user data
   - Keep classification history synced across devices
   - Handle offline/online state transitions

3. **Release Automation**
   - Create CI/CD pipeline for release builds
   - Automate obfuscation and debug symbol generation
   - Streamline Play Store and App Store deployment

### Play Store Package/Class Name & Versioning Issue (May 2025)
- Internal builds used 0.9.x versioning, but public release was reset to 0.1.x for clarity.
- Play Store crash due to mismatch between published package name and MainActivity class path.
- Solution: Unified all package references to `com.pranaysuyash.wastewise`, set versionCode to 92+, and updated documentation. 