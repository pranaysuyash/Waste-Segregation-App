# Waste Segregation App Developer Guide

## Build & Run Commands
- Run app: `flutter run` or for specific platform: `flutter run -d chrome/ios/android`
- Dev mode with hot reload: `flutter run --debug`
- Release build: `flutter build apk/ios/web`
- Get dependencies: `flutter pub get`
- Web-specific run: `flutter run -d chrome --web-renderer canvaskit`

## Testing Commands
- Run all tests: `flutter test`
- Single test: `flutter test test/widget_test.dart`
- Test specific file: `flutter test path/to/test_file.dart`
- Test with coverage: `flutter test --coverage && genhtml coverage/lcov.info -o coverage/html`

## Linting & Formatting
- Analyze code: `flutter analyze`
- Format code: `flutter format lib/`
- Fix specific lint: `dart fix --apply`
- Format specific file: `dart format path/to/file.dart`

## Camera Implementation

The app uses an enhanced cross-platform camera implementation that works across all platforms:

1. **Architecture:**
   - `PlatformCamera` class: Core utility functions for camera operations
   - `EnhancedCamera` widget: UI component with preview and buttons
   - `CameraScreen`: Dedicated screen for the camera experience

2. **Key Features:**
   - Multi-approach camera access (direct camera API + image_picker)
   - Fallback mechanisms for different platforms and environments
   - Permission handling with permission_handler
   - Native camera preview when available
   - Graceful error handling with user-friendly messages

3. **Usage:**
   - Use `CameraScreen` for a full-screen camera experience
   - For embedding camera in custom UIs, use the `EnhancedCamera` widget
   - For direct camera operations, use the static methods in `PlatformCamera`

4. **Platform-Specific Notes:**
   - **Web:** Uses image_picker only, no direct camera preview
   - **Android/iOS:** Uses both camera API and image_picker with fallbacks
   - **Desktop:** Limited support, falls back to image_picker dialog

5. **Dependencies:**
   - camera: ^0.10.5+9
   - permission_handler: ^11.2.0
   - image_picker: ^1.0.7

## Code Style Guidelines
- **Imports**: Order: dart core, flutter, packages, relative (group & alphabetize)
- **Formatting**: 2-space indent, max 80 chars per line, trailing commas for multiline
- **Types**: Strong typing, avoid dynamic, respect null safety with ? and required
- **Naming**: lowerCamelCase for variables/methods, UpperCamelCase for classes/types
- **Error Handling**: Use mounted check in async code, wrap platform calls in try/catch
- **Architecture**: Follow models/services/screens/widgets/utils structure
- **Platform Compatibility**: Use kIsWeb for web vs mobile detection
- **State Management**: Provider pattern with context.watch/read
- **Comments**: Document public APIs, use TODO tags with owner (@username)
- **File Organization**: Keep files under 400 lines, extract reusable widgets
- **Constants**: Use AppTheme and AppStrings from utils/constants.dart
- **Gamification**: Process achievements after user actions, update UI accordingly

## Important Notes
- Always handle state loading/error cases with appropriate UI feedback
- Test on both web and mobile platforms before submitting changes
- Update user_doc.md when adding/changing user-facing features
- When working with the camera, test fallback mechanisms across platforms