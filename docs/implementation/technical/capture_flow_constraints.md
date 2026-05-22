# Capture Flow Image Constraints

## Canonical profile

All active capture entrypoints should use the same image picker constraints:

- `maxWidth: 1200`
- `maxHeight: 1200`
- `imageQuality: 85`

## Why

The app previously drifted between multiple capture profiles across Home, the navigation wrapper, and legacy compatibility screens. That creates inconsistent input size, inconsistent compression, and avoidable duplication.

The canonical helper lives at:

- `lib/utils/capture_image_options.dart`

## Updated entrypoints

- `lib/screens/home_screen.dart`
- `lib/widgets/navigation_wrapper.dart`
- `lib/widgets/platform_camera.dart`
- `lib/screens/image_capture_screen.dart`
- `lib/screens/ultra_modern_home_screen.dart`
- `lib/widgets/simple_web_camera.dart`
- `lib/widgets/web_camera_access.dart`

## Verification target

The capture flow should no longer contain hardcoded 1920x1080 or other mismatched capture profiles in runtime paths.
