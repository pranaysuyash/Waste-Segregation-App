# Firebase and Google Sign-In Integration

I've updated the following files to fix the Google Sign-In crash:

## 1. Updated iOS Configuration Files

### AppDelegate.swift
- Added Firebase initialization:
```swift
import Firebase
FirebaseApp.configure()
```

### Info.plist
- Added URL scheme configuration for Google Sign-In using the REVERSED_CLIENT_ID from your GoogleService-Info.plist

## 2. Updated Flutter Project Files

### main.dart
- Added Firebase initialization:
```dart
await Firebase.initializeApp();
```

### pubspec.yaml
- Added Firebase dependencies:
```yaml
firebase_core: ^2.25.4
firebase_auth: ^4.17.4
```

## Next Steps to Complete the Setup

1. **Install Flutter Dependencies:**
   ```bash
   cd /Users/pranay/Projects/LLM/image/waste_seg/waste_segregation_app
   flutter pub get
   ```

2. **Update CocoaPods:**
   ```bash
   cd ios
   pod install --repo-update
   cd ..
   ```

3. **Selecting Firebase Modules in Xcode:**
   - In the Swift Package Manager dialog, select the following Firebase modules:
     - FirebaseCore (required)
     - FirebaseAuth (required for authentication)
     - GoogleSignIn (if available)

4. **Run the App:**
   ```bash
   flutter run
   ```

## Troubleshooting

If you encounter any issues:

1. **Clear Flutter Cache:**
   ```bash
   flutter clean
   flutter pub get
   ```

2. **Rebuild iOS Project:**
   ```bash
   cd ios
   pod install --repo-update
   cd ..
   ```

3. **Check Xcode Log:**
   If you still experience crashes, check the Xcode logs or run the app directly from Xcode to see more detailed error messages.

## Files Modified:
- AppDelegate.swift
- Info.plist
- main.dart
- pubspec.yaml
