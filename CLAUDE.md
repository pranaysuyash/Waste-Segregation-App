# Waste Segregation App Developer Guide

## Build & Run Commands
- Run app: `flutter run` or for specific platform: `flutter run -d chrome/ios/android`
- Dev mode with hot reload: `flutter run --debug`
- Release build: `flutter build apk/ios/web`
- Get dependencies: `flutter pub get`

## Testing Commands
- Run all tests: `flutter test`
- Single test: `flutter test test/widget_test.dart`
- Test with coverage: `flutter test --coverage`

## Linting & Formatting
- Analyze code: `flutter analyze`
- Format code: `flutter format lib/`
- Fix specific lint: `dart fix --apply`

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
- **Gamification**: Process achievements after user actions, update UI accordingly