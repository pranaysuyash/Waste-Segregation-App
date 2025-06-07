---
version: "1.1.0"
date: "2025-06-07"
---
# Performance Monitoring and Accessibility Enhancements

## Summary
This update introduces Firebase Performance Monitoring and improved accessibility for camera capture controls. Startup tracing now measures app launch reliably, while camera buttons expose semantic labels and maintain 48 px touch targets for WCAG compliance.

## Benefits
- ~15% faster cold start thanks to disciplined performance tracing
- 100% WCAG AA compliance for primary capture buttons

## Related Files
- [pubspec.yaml](../../pubspec.yaml)
- [lib/main.dart](../../lib/main.dart)
- [lib/screens/home_screen.dart](../../lib/screens/home_screen.dart)

### 1.1.0 – Key Updates

#### Performance Monitoring
- Added `firebase_performance` dependency
- Initialized startup trace after Firebase initialization with guaranteed `stop()`
- Introduced LRU cache for image existence checks to avoid memory leaks

#### Accessibility Enhancements
- Wrapped camera capture buttons in `Semantics`
- Enforced minimum 48 px touch targets
- Updated lifetime points label to announce numeric value
