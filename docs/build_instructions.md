# How to Build the Waste Segregation App

This guide provides step-by-step instructions for building and running the Waste Segregation App, including the new Enhanced Gamification System and Waste Analytics Dashboard features.

## Prerequisites

Before you begin, ensure you have the following installed:

- **Flutter SDK**: Version 3.10.0 or higher
- **Dart**: Version 3.0.0 or higher
- **Android Studio** (for Android development) or **Xcode** (for iOS development)
- **Git**: For version control
- **Firebase CLI**: For Firebase configuration (optional, only if using Firebase)
- **Kotlin**: Version 2.0.0 or higher (for Android development)

## Setting Up the Development Environment

1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-username/waste_segregation_app.git
   cd waste_segregation_app
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Generate code** (for Hive adapters, etc.):
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

## Configuration

### API Keys & Firebase Configuration

API keys for Firebase services are managed through the `lib/firebase_options.dart` file (primarily for web configurations) and platform-specific configuration files:

- **Firebase**:
  1. Create a Firebase project in the [Firebase Console](https://console.firebase.google.com/).
  2. Add your Android, iOS, and Web applications to the project.
  3. **For Android**: Download `google-services.json` and place it in the `android/app/` directory.
  4. **For iOS**: Download `GoogleService-Info.plist` and place it in the `ios/Runner/` directory. Ensure it's added to the Xcode project.
  5. **For Web**: The necessary Firebase configuration (API key, auth domain, project ID, etc.) is typically managed within `lib/firebase_options.dart` and referenced by `web/index.html`. The `flutterfire configure` command helps generate `lib/firebase_options.dart`.
  6. Ensure Firebase is initialized in `lib/main.dart` for all platforms.

- **Other API Keys (e.g., for a separate AI service like Gemini if not used via a Firebase extension)**:
  - If your project requires API keys for services not managed by Firebase (e.g., a direct Gemini API key), you must manage these securely.
  - **Do not hardcode API keys directly in version-controlled files.**
  - A common practice is to use a gitignored file (e.g., `lib/config/runtime_constants.dart` or similar) to define these keys, or pass them via environment variables at build time.
  - Example of a gitignored constants file:
    ```dart
    // lib/config/runtime_constants.dart (add this file to .gitignore)
    // class RuntimeConstants {
    //   static const String thirdPartyApiKey = 'YOUR_ACTUAL_API_KEY';
    // }
    ```
  - Ensure any such file is included in your `.gitignore`.

## Building the App

### For Android

1. **Connect an Android device** or start an emulator
2. **Build and run**:
   ```bash
   flutter run
   ```
   
   Or for a release build:
   ```bash
   flutter build apk --release
   ```

#### Android Build Notes

* **Kotlin Version**: The app requires Kotlin 2.0.0+ to build properly due to Firebase and Google Play Services dependencies
* If you encounter Kotlin version errors, update the following files:
  * In `android/build.gradle`, set `ext.kotlin_version = '2.0.0'`
  * In `android/settings.gradle`, set `id "org.jetbrains.kotlin.android" version "2.0.0" apply false`

### For iOS

1. **Connect an iOS device** or start a simulator
2. **Build and run**:
   ```bash
   flutter run
   ```
   
   Or for a release build:
   ```bash
   flutter build ios --release
   ```

### For Web

1. **Build and run**:
   ```bash
   flutter run -d chrome
   ```
   
   Or for a release build:
   ```bash
   flutter build web --release
   ```

#### Web Development Notes

* The app uses a specialized web structure for better Firebase and PWA support:
  * `lib/web_standalone.dart` - Web-specific initialization
  * `web/index.html` - Web entry point with custom Firebase initialization
  * `lib/screens/web_fallback_screen.dart` - Fallback UI for the web platform
* Web platform has some limitations compared to mobile:
  * Camera access requires HTTPS
  * Some advanced image processing features may be limited
  * Web storage is capped by browser limits

## Testing the New Features

### Testing Enhanced Gamification

1. **Run the app** and log in or continue as guest
2. **Classify waste items** to trigger immediate feedback animations
3. **Complete challenges** to see completion celebrations
4. **Earn achievements** to see animated notifications
5. **Maintain a streak** by using the app on consecutive days

### Testing Waste Dashboard

1. **Navigate to the dashboard** by:
   - Tapping the chart icon in the app bar
   - Tapping "View Waste Analytics Dashboard" on the home screen
   - Tapping the dashboard button after classification
2. **Explore different tabs**:
   - Overview tab: Check waste composition
   - Trends tab: Observe time-based patterns
   - Insights tab: View personalized recommendations
3. **Test time filters**:
   - Switch between week, month, and all time views
4. **Test chart interactions**:
   - Tap on chart elements to see detailed information
   - Observe animations when switching between tabs

## Common Build Issues

### Dependencies Issues

**Problem**: Missing or conflicting dependencies
**Solution**:
```bash
flutter clean
flutter pub get
```

### Kotlin Version Issues

**Problem**: Incompatible Kotlin version with Firebase and Google Play Services
**Solution**:
```bash
# Update Kotlin version in android/build.gradle
# Change ext.kotlin_version to '2.0.0'

# Update Kotlin version in android/settings.gradle
# Change org.jetbrains.kotlin.android version to '2.0.0'
```

### Web Platform Issues

**Problem**: Web version shows blank page or JavaScript errors
**Solution**:
- Check browser console for specific errors
- Verify Firebase web configuration in index.html
- Ensure web platform dependencies are properly initialized

### Animation Performance Issues

**Problem**: Animations laggy on lower-end devices
**Solution**: Enable performance monitoring to identify bottlenecks
```bash
flutter run --profile --trace-skia
```

### Firebase Authentication Issues

**Problem**: Firebase authentication not working
**Solution**: Verify Firebase configuration files and permissions
```bash
flutter pub run flutterfire_cli:flutterfire configure
```

### Chart Rendering Issues

**Problem**: Charts not rendering or displaying incorrectly
**Solution**: Check data formatting and chart configuration. Ensure fl_chart dependency is properly added.

## Advanced Configuration

### Customizing the Enhanced Gamification System

You can modify the gamification settings in `lib/services/gamification_service.dart`:

```dart
// Adjust points earned for different actions
static const Map<String, int> _pointValues = {
  'classification': 10,      // Points for identifying an item
  'daily_streak': 5,         // Points for maintaining streak
  'challenge_complete': 25,  // Points for completing a challenge
  // ...
};
```

### Customizing the Dashboard

You can modify the dashboard tabs and charts in `lib/screens/waste_dashboard_screen.dart`:

```dart
// Add or change tabs in the TabController setup
_tabController = TabController(length: 3, vsync: this);

// Change chart configurations in individual build methods
_buildOverviewTab() {
  // ...
}
```

## Continuous Integration

The project includes GitHub Actions workflows for CI/CD:

### Running CI Locally

To test the CI process locally:

```bash
# Install the tools
dart pub global activate flutter_ci

# Run checks
flutter_ci lint
flutter_ci test
```

## Additional Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [FL Chart Documentation](https://pub.dev/packages/fl_chart)
- [Hive Database Documentation](https://pub.dev/packages/hive)
- [Firebase Documentation](https://firebase.google.com/docs/flutter/setup)

## Troubleshooting

If you encounter any issues during the build process, please check the following:

1. **Flutter Version**: Ensure you're using a compatible Flutter version
   ```bash
   flutter --version
   ```

2. **Dependencies**: Make sure all dependencies are properly resolved
   ```bash
   flutter pub outdated
   flutter pub upgrade
   ```

3. **Clean Build**: Try cleaning the build and rebuilding
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

4. **Check Logs**: Examine the build logs for specific error messages
   ```bash
   flutter run -v
   ```

For any additional issues, please refer to the developer documentation or create an issue in the GitHub repository.
