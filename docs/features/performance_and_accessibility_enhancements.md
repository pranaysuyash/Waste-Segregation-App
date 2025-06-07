# Performance Monitoring and Accessibility Enhancements

**Version:** 1.1.0
**Date:** 2025-06-07

## Summary
This update introduces Firebase Performance Monitoring and improves accessibility for the camera capture buttons.

## Key Changes
- Added `firebase_performance` to `pubspec.yaml`.
- Initialized a startup performance trace in `lib/main.dart`.
- Wrapped camera capture buttons in `Semantics` widgets and ensured a minimum touch target of 48 px in `home_screen.dart`.

## Benefits
- Real‑time performance metrics to diagnose slow startup and screen transitions.
- Better screen reader support and larger touch targets for improved WCAG compliance.

## Related Files
- `pubspec.yaml`
- `lib/main.dart`
- `lib/screens/home_screen.dart`

### 1.1.0 Updates
- Fixed initialization order of the Firebase Performance startup trace and wrapped
  the main initialization block in a `try/finally` to guarantee the trace is
  stopped.
- Added an LRU cache for image existence checks in `home_screen.dart` to prevent
  memory leaks and avoid stale placeholders.
- Improved the lifetime points accessibility label to announce the numeric
  points value.

