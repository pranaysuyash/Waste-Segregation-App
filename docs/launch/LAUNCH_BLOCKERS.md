# Launch Blockers Register

## BLOCKER-001: tflite_flutter build failure (Android)

- **Severity**: Blocker
- **Evidence**: `flutter build apk --debug` fails with: `Namespace not specified` for `tflite_flutter-0.9.5/android/build.gradle`. This is a known AGP 8.x incompatibility with older Flutter plugins that don't declare a namespace.
- **User impact**: App cannot be built for Android in current config.
- **Fix recommendation**: 
  1. Add `namespace 'com.tfliteflutter.tflite_flutter'` to `android/build.gradle` in the tflite_flutter package (pub cache patch), or
  2. Use `tflite_flutter` fork with AGP 8.x fix, or
  3. Add a Gradle subproject fix in `android/settings.gradle` to inject namespace, or
  4. Migrate to a maintained ML inference plugin (e.g., `onnxruntime` or `google_mlkit_commons`).
- **Test needed**: `flutter build apk --debug` succeeds.
- **Status**: Open

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
