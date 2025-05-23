# Implementation Documentation

## Recent Code Improvements

- **Centralized Error Handling**: All major screens now use a centralized `ErrorHandler` and `AppException` pattern for consistent error logging and user feedback. See `constants.dart`.
- **Web Camera Access**: Camera capture is now supported in the browser using `image_picker_for_web` (see `web_camera_access.dart`).
- **UI and Media Rendering**: Improved text overflow handling and media (video/image) rendering in educational content screens (see `result_screen.dart`, `content_detail_screen.dart`).

This directory contains implementation guidelines, integration notes, and technical specifications for the Waste Segregation App.

## Main Files

- [Classification Caching Implementation](./classification_caching_implementation.md)
- [Classification Caching Options](./classification_caching_options.md)
- [Classification Caching Technical Spec](./classification_caching_technical_spec.md)
- [Firebase Integration Summary](./firebase_integration_summary.md)
- [Firebase Troubleshooting](./FIREBASE_TROUBLESHOOTING.md)
- [Firebase Setup Guide](./FIREBASE_SETUP_GUIDE.md)
- [Premium Features and Ads](./premium_features_and_ads.md)
- [Blockchain Waste Tracking](./blockchain_waste_tracking.md)
- [Smart Bin Integration](./smart_bin_integration.md)
- [Implementation Options](./implementation_options.md)
- [Upgrade Packages](./upgrade_packages.md)
- [Firebase Studio Changes](./firebase-studio-changes.md)
- [Google Sign-In Fix](./google_signin_fix.md)

## Reference Configurations

- [pubspec.sample.yaml](../project_files_archive/pubspec.sample.yaml)
- [updated_ios13_podfile.txt](../project_files_archive/updated_ios13_podfile.txt)
- [simplified_podfile.txt](../project_files_archive/simplified_podfile.txt)

## Error & Crash Reporting: Firebase Crashlytics

The app uses [Firebase Crashlytics](https://firebase.google.com/docs/crashlytics) for real-time error and crash reporting on both iOS and Android.

- **Integration:**
  - Crashlytics is initialized in `main.dart` after Firebase initialization.
  - All errors passed to `ErrorHandler.handleError` are reported to Crashlytics.
  - A test non-fatal error is sent on app startup (see `main.dart`).
  - A temporary force crash button is available in the Settings screen (Developer Options) for testing fatal crash reporting.
- **Setup:**
  - Ensure `GoogleService-Info.plist` (iOS) and `google-services.json` (Android) are present and match your Firebase project.
  - Run `flutter clean`, `flutter pub get`, and `cd ios && pod install` after any changes to dependencies or config files.
- **Testing:**
  - Use the force crash button in Settings > Developer Options to trigger a fatal crash and verify Crashlytics reporting.
  - Non-fatal errors are sent automatically on app startup for verification.
- **Troubleshooting:**
  - First crash may take up to 30 minutes to appear in the Firebase Console.
  - Ensure bundle identifier matches between Xcode, Firebase Console, and `GoogleService-Info.plist`.
  - Check terminal logs for Crashlytics submission messages. 