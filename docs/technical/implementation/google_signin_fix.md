# Google Sign-In Fixes for Waste Segregation App

This document details the steps taken to resolve issues with Google Sign-In functionality in the Waste Segregation App, particularly focusing on Android SHA-1 fingerprint configuration and ensuring all necessary settings in Firebase and Google Cloud Console are correct.

## Problem Summary

Users were encountering errors during Google Sign-In, typically `ApiException: 10` or `DEVELOPER_ERROR` on Android. This indicated a misconfiguration related to the app's identity verification with Google services.

## Key Areas of Investigation

1.  **SHA-1 Certificate Fingerprints**: Ensuring both debug and release SHA-1 fingerprints were correctly added to the Firebase project settings for the Android app.
2.  **Firebase Authentication Settings**: Verifying that Google was enabled as a sign-in provider.
3.  **Google Cloud Console OAuth Consent Screen**: Checking that the consent screen was properly configured and a support email was provided.
4.  **`google-services.json`**: Making sure the latest version of this file, reflecting any SHA-1 or other configuration changes, was included in the Android app module (`android/app/`).
5.  **Flutter Plugin Configuration**: Ensuring the `google_sign_in` Flutter plugin was correctly implemented and any platform-specific setup (like iOS URL Schemes) was done.

## Resolution Steps Taken

### 1. Verified/Added SHA-1 Fingerprints

-   **Debug SHA-1**: 
    -   Navigated to the `android` directory in the project.
    -   Executed `./gradlew signingReport`.
    -   Identified and copied the SHA-1 fingerprint for the `debug` build variant.
    -   Added this SHA-1 to Firebase Console: Project Settings > Your Apps > Select Android App > Add Fingerprint.
-   **Release SHA-1** (Placeholder for future release builds):
    -   Documented the process: `keytool -list -v -keystore YOUR_RELEASE_KEYSTORE.jks -alias YOUR_ALIAS`.
    -   Noted that this would need to be added to Firebase before publishing a release build signed with the release keystore.

### 2. Updated `google-services.json`

-   After adding/verifying SHA-1 fingerprints in Firebase, downloaded the fresh `google-services.json` file.
-   Replaced the existing `android/app/google-services.json` with the newly downloaded one.

### 3. Confirmed Firebase Authentication Provider

-   In Firebase Console > Authentication > Sign-in method tab.
-   Verified that "Google" was listed as an enabled provider.
-   Ensured the Web SDK configuration section (even if primarily a mobile app, this section is sometimes relevant for client IDs) had the correct web client ID for Google Sign-In, if applicable for any web portions or backend verification.

### 4. Reviewed Google Cloud Console OAuth Consent Screen

-   Navigated to Google Cloud Console for the associated Firebase project.
-   Selected "APIs & Services" > "OAuth consent screen".
-   **User Type**: Confirmed as "External" (or "Internal" if applicable for a GSuite organization).
-   **App Information**:
    -   App name was set.
    -   **User support email** was configured (this is crucial).
    -   App logo (optional) was considered.
-   **Authorized domains**: Ensured necessary domains were listed (often auto-populated by Firebase).
-   **Scopes**: Verified that basic scopes like `email`, `profile`, `openid` were requested, matching what the `google_sign_in` plugin typically requests.
-   **Publishing Status**: If the app was in "Testing" mode, ensured test users were added. If ready, considered publishing the consent screen.

### 5. Code Implementation Check (Flutter)

-   Reviewed the `AuthService` or equivalent in the Flutter app where `GoogleSignIn` is instantiated and used.
-   Ensured the `GoogleSignIn()` constructor was called without specific client IDs unless absolutely necessary and correctly configured (typically, FlutterFire handles this via `firebase_options.dart`).
    ```dart
    final GoogleSignIn _googleSignIn = GoogleSignIn();
    // For specific scopes, if needed:
    // final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);
    ```
-   Confirmed that `Firebase.initializeApp()` was called before any Firebase services, including Auth, were used.

### 6. iOS Specifics (Checked for completeness, though the primary issue was Android)

-   Verified that if Google Sign-In was used on iOS, the `GoogleService-Info.plist` was correct.
-   Ensured URL schemes were correctly added to `ios/Runner/Info.plist` as per the `google_sign_in` plugin documentation (usually involving the `REVERSED_CLIENT_ID` from `GoogleService-Info.plist`).

### 7. Cleaned Build Artifacts

-   Executed `flutter clean`.
-   In the `android` directory, ran `./gradlew clean`.
-   Rebuilt and re-ran the application.

## Outcome

After ensuring the correct SHA-1 fingerprints were present in Firebase, the `google-services.json` was up-to-date, and the OAuth consent screen had a support email, Google Sign-In functionality was restored on Android devices. The `ApiException: 10` was resolved.

## Future Considerations & Maintenance

-   **Release Builds**: Before creating a release build, the release SHA-1 fingerprint MUST be added to Firebase, and the new `google-services.json` must be included.
-   **New Dev Machines**: Each developer setting up the project will need to add their debug SHA-1 to Firebase or use a shared debug keystore whose SHA-1 is already registered.
-   **Google Cloud Project Sync**: Periodically review the Google Cloud Console settings linked to the Firebase project to ensure they haven't been inadvertently changed. 