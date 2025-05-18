# Firebase Troubleshooting Guide

This guide provides solutions to common Firebase integration issues encountered in the Waste Segregation App.

## Common Issues

### 1. `google-services.json` or `GoogleService-Info.plist` not found

**Error Message (Android)**:
`File google-services.json is missing. The Google Services Plugin cannot function without it.`

**Error Message (iOS)**:
`[Firebase/Core][I-COR000005] No App configuration found.`

**Solution**:
-   Ensure `google-services.json` is in the `android/app/` directory.
-   Ensure `GoogleService-Info.plist` is in the `ios/Runner/` directory and correctly added to the Xcode project target.
-   If using FlutterFire CLI, run `flutterfire configure` again to ensure files are correctly generated and placed.
-   For iOS, open `ios/Runner.xcworkspace` in Xcode. Select `Runner` from the project navigator, then `Runner` under TARGETS. Go to `Build Phases > Copy Bundle Resources` and ensure `GoogleService-Info.plist` is listed. If not, add it.

### 2. SHA-1 certificate fingerprint mismatch (Android - Google Sign-In)

**Symptom**: Google Sign-In fails, often with an error code like `10` or `DEVELOPER_ERROR`.

**Solution**:
-   Firebase requires the SHA-1 fingerprint of your signing certificate (debug and release).
-   **Get SHA-1 for Debug**: Navigate to the `android` directory in your project and run `./gradlew signingReport`. Copy the SHA-1 for the `debug` variant.
-   **Get SHA-1 for Release**: If you have a release keystore, use `keytool -list -v -keystore your_release_keystore.jks -alias your_alias_name`.
-   **Add SHA-1 to Firebase**: Go to Firebase Console > Project Settings > Your apps > Select your Android app. Add the SHA-1 fingerprint(s) under "SHA certificate fingerprints".
-   Download the updated `google-services.json` and replace the old one in `android/app/`.

### 3. PlatformException (PlatformException(sign_in_failed, com.google.android.gms.common.api.ApiException: 10: , null, null))

**Symptom**: Common with Google Sign-In on Android.

**Solution**:
-   **Check SHA-1 fingerprints** (as above).
-   **Enable Google Sign-In**: In Firebase Console > Authentication > Sign-in method, ensure Google is enabled as a provider.
-   **Support Email**: In Firebase Console > Project Settings > General, make sure a "Support email" is set.
-   **OAuth Consent Screen**: In Google Cloud Console (for the same project) > APIs & Services > OAuth consent screen, ensure your app is configured, especially the user type and scopes.
-   **Clean and rebuild**: Sometimes, old build artifacts can cause issues.
    ```bash
    flutter clean
    flutter pub get
    # For Android
    cd android && ./gradlew clean && cd ..
    ```

### 4. MissingPluginException

**Error Message**: `MissingPluginException(No implementation found for method X on channel Y)`

**Solution**:
-   This usually means a Flutter plugin is not correctly registered or the native part failed to build.
-   **Stop and restart the app**: A hot reload/restart might not be enough after adding new plugins.
-   **Verify plugin installation**: Check `pubspec.yaml` and ensure `flutter pub get` was successful.
-   **Check native builds**: Look for errors in the Android Logcat or Xcode console during the build process.
    -   For iOS, `pod install` might have failed. Navigate to `ios/` and run `pod install --repo-update` then `pod install` again.
-   Ensure your `MainActivity.kt` (Android) or `AppDelegate.swift`/`.m` (iOS) are correctly configured if they required manual changes for plugins (though this is rare with modern Flutter).

### 5. Kotlin Version Incompatibility (Android)

**Error Message**: Errors related to `kotlin_module`, `metadata is 1.x.x, expected version is 1.y.y`.

**Solution**:
-   Firebase Android SDKs often require specific Kotlin versions.
-   Check the `android/build.gradle` file for `ext.kotlin_version`. Try updating it. For example, if Firebase BOM requires a newer Kotlin, you might need to increase this.
    ```gradle
    buildscript {
        ext.kotlin_version = '2.0.0' // Adjust as needed
        // ...
    }
    ```
-   Also, check `android/settings.gradle` for the Kotlin plugin version if your project uses a centralized plugin versions block:
    ```gradle
    plugins {
        // ...
        id "org.jetbrains.kotlin.android" version "2.0.0" apply false // Match ext.kotlin_version
    }
    ```
-   Ensure your Android Gradle Plugin version (in `android/build.gradle`) is compatible with your Kotlin version and Firebase SDKs.
-   Clean the project: `flutter clean`, then `cd android && ./gradlew clean`.

### 6. Cocoapods issues (iOS)

**Symptom**: Build failures on iOS, often mentioning pods or specific native libraries.

**Solution**:
-   Navigate to the `ios` directory of your Flutter project.
-   Delete `Podfile.lock`: `rm Podfile.lock`
-   Delete `Pods` directory: `rm -rf Pods`
-   Clean workspace: In Xcode, Product > Clean Build Folder.
-   Update pods: `pod repo update` (can take a while)
-   Reinstall pods: `pod install`
-   If issues persist, try `arch -x86_64 pod install` if you are on an Apple Silicon Mac and suspect architecture issues.

### 7. Web Specific Issues

**Symptom**: Firebase not initializing on the web, or auth methods failing.

**Solution**:
-   **Firebase Configuration**: Ensure your `web/index.html` contains the Firebase initialization script with your project's `firebaseConfig` object.
    ```html
    <!-- Firebase App (the core Firebase SDK) is always required and must be listed first -->
    <script src="https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js"></script>
    <!-- Add SDKs for Firebase products you want to use -->
    <script src="https://www.gstatic.com/firebasejs/10.12.2/firebase-auth-compat.js"></script>
    <script src="https://www.gstatic.com/firebasejs/10.12.2/firebase-firestore-compat.js"></script>
    // Add other compat SDKs as needed, e.g., firebase-storage-compat.js
    <script>
      const firebaseConfig = {
        apiKey: "YOUR_WEB_API_KEY",
        // ... other config values
      };
      // Initialize Firebase
      const firebaseApp = firebase.initializeApp(firebaseConfig);
    </script>
    ```
-   **`lib/firebase_options.dart`**: Make sure this file is correctly generated by `flutterfire configure` and includes the web configuration.
-   **Initialization in `main.dart`**: Ensure `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` is called.
-   **Authorized Domains for OAuth**: For OAuth providers like Google Sign-In, ensure your app's domain (e.g., `localhost`, `your-project-id.web.app`, `your-project-id.firebaseapp.com`) is added to the list of authorized domains in Firebase Console > Authentication > Settings > Authorized domains.
-   **Browser Console**: Check the browser's developer console for specific error messages.

## General Troubleshooting Steps

1.  **Flutter Doctor**: Run `flutter doctor -v` to check for any environment issues.
2.  **Flutter Clean**: `flutter clean` followed by `flutter pub get`.
3.  **Restart IDE and Emulator/Device**.
4.  **Check Official Documentation**: Refer to the documentation for FlutterFire and the specific Firebase service you're having trouble with.
5.  **Look at Verbose Logs**: Run `flutter run -v` to get more detailed output.

If you are still facing issues, consider posting a detailed question on Stack Overflow with the relevant code, error messages, and steps you've already tried. 