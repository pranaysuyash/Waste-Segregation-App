# Launch Blockers Register

## BLOCKER-001: tflite_flutter build failure (Android) — RESOLVED

- **Severity**: Resolved (was Blocker)
- **Evidence**: `tflite_flutter` was an unused dependency (no Dart imports anywhere in production code). `OnDeviceVisionService` only has comments about future TFLite use. No `.tflite` model files exist in assets (only a README). Removing the dependency resolves the AGP 8.x namespace error.
- **Fix applied**: Removed `tflite_flutter: ^0.9.0` from `pubspec.yaml`.
- **Product impact**: None. On-device ML inference was not implemented; app uses cloud AI services for classification.
- **Status**: Resolved

## BLOCKER-002: Android NDK missing CMake toolchain — ENVIRONMENT

- **Severity**: Environment blocker (not code)
- **Evidence**: `flutter build apk --debug` fails with CMake error: `Could not find toolchain file: .../ndk/27.1.12297006/build/cmake/android.toolchain.cmake`. The NDK installations at `/Users/pranay/Projects/adhoc_resources/ndk/` are stripped/incomplete — they have compiler binaries but no `build/cmake/` directory. The `android.toolchain.cmake` file is missing from all three NDK versions.
- **User impact**: App cannot build on this machine until NDK is properly installed.
- **Fix recommendation**: Install a complete NDK via Android Studio SDK Manager or `sdkmanager --install "ndk;27.1.12297006"`. The current NDK directories appear to be partial copies. A fresh install should include `build/cmake/android.toolchain.cmake`.
- **Test needed**: `flutter build apk --debug` succeeds after proper NDK installation.
- **Status**: Open (environment, not code)

## HIGH-001: Firestore rules not deployed

- **Severity**: High
- **Evidence**: Firestore rules are tested locally via emulator but have not been deployed to the Firebase project. The `firebase deploy --only firestore:rules` step has not been run.
- **User impact**: Production Firestore is using whatever rules were last deployed, not the hardened rules in the repo.
- **Fix recommendation**: Run `firebase deploy --only firestore:rules` after verifying the local test suite passes.
- **Test needed**: Verify `firebase deploy --only firestore:rules --project <project_id>` succeeds and that deployed rules match local `firestore.rules`.
- **Status**: Open

## INFO-001: 39 analyzer warnings, 374 info lints

- **Severity**: Info (not blocker)
- **Evidence**: `flutter analyze` reports 39 warnings (unused imports, unused variables, unnecessary null comparisons) and 374 info lints. No errors.
- **User impact**: None at runtime. Warnings indicate dead code paths that could be cleaned up.
- **Fix recommendation**: Address unused imports/variables in a cleanup pass. Not launch-blocking.
- **Status**: Open

## INFO-002: temp/debug files in repo

- **Severity**: Info
- **Evidence**: `temp/debug_gamification.dart` uses deprecated `subcategory` field. This is a debug/temp file that should not ship in release.
- **User impact**: None if excluded from release builds.
- **Fix recommendation**: Exclude `temp/` from release builds or remove before launch.
- **Status**: Open
