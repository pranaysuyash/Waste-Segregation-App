# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run Commands
- Run app: `flutter run` or platform-specific: `flutter run -d chrome/ios/android`
- Debug with hot reload: `flutter run --debug`
- Release build: `flutter build apk/ios/web`
- Get dependencies: `flutter pub get`
- Web-specific: `flutter run -d chrome --web-renderer canvaskit`

## Testing Commands
- Run all tests: `flutter test`
- Single test: `flutter test test/widget_test.dart`
- Specific test: `flutter test path/to/test_file.dart:lineNumber`
- Test with coverage: `flutter test --coverage && genhtml coverage/lcov.info -o coverage/html`

## Linting & Formatting
- Analyze code: `flutter analyze`
- Format code: `flutter format lib/`
- Fix lints: `dart fix --apply`

## Code Style Guidelines
- **Imports**: Order: dart core → flutter → packages → relative (alphabetize each group)
- **Formatting**: 2-space indent, max 80 chars per line, trailing commas for multiline
- **Types**: Strong typing, avoid dynamic, use null safety with ? and required
- **Naming**: lowerCamelCase for variables/methods, UpperCamelCase for classes/types
- **Error Handling**: Use mounted check in async code, wrap platform calls in try/catch
- **Architecture**: Follow models/services/screens/widgets/utils structure
- **Platform Compatibility**: Use kIsWeb for web vs mobile detection
- **State Management**: Provider pattern with context.watch/read
- **File Organization**: Keep files under 400 lines, extract reusable widgets
- **Constants**: Use AppTheme and AppStrings from utils/constants.dart
- **APIs**: Use the Gemini API via OpenAI-compatible endpoint with Bearer token authentication
- **Firebase**: Use Firebase services for authentication, storage, and analytics

## Important Notes
- Test on both web and mobile platforms before submitting changes
- Update user_doc.md when adding/changing user-facing features
- When working with the camera, test fallback mechanisms across platforms