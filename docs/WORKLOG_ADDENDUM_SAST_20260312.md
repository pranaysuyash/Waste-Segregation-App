# Worklog Addendum - SAST Remediation - 2026-03-12

## Objective
Address the user-reported SAST findings for the ReLoop app in the actual repo under `LLM/image/waste_seg/waste_segregation_app`.

## Scope
- Fix workflow shell/template injection in `.github/workflows/check-no-golden-failures.yml`.
- Harden file path handling for local image and export paths in Dart services/widgets.
- Remove iOS ATS exceptions that disabled perfect forward secrecy.
- Explicitly disable Android backup/data extraction.
- Upgrade vulnerable `functions/` JavaScript dependencies and regenerate `package-lock.json`.
- Reduce WebView exposure by blocking unexpected navigation while retaining the embedded chart behavior.

## Observed
- The repo already had some Android transport hardening in place:
  - `android:usesCleartextTraffic="false"` in `android/app/src/main/AndroidManifest.xml`
  - system trust anchors only in `android/app/src/main/res/xml/network_security_config.xml`
- The JS dependency alerts were real in `functions/package-lock.json` before remediation:
  - `fast-xml-parser`
  - `form-data`
  - `node-forge`
  - `jws`
  - `@fastify/busboy`
  - `@firebase/util`

## Changes
- Added `lib/utils/safe_file_path.dart` and used it in:
  - `lib/services/enhanced_image_service.dart`
  - `lib/services/ai_service.dart`
  - `lib/services/google_drive_service.dart`
  - `lib/widgets/history_list_item.dart`
- Hardened `lib/screens/waste_dashboard_screen.dart` to block unexpected WebView navigation.
- Reworked `.github/workflows/check-no-golden-failures.yml` to use environment variables instead of direct GitHub expression interpolation inside the shell script.
- Updated `android/app/src/main/AndroidManifest.xml` and added `android/app/src/main/res/xml/data_extraction_rules.xml`.
- Removed `NSExceptionRequiresForwardSecrecy` overrides from `ios/Runner/Info.plist`.
- Upgraded `functions/package.json` and `functions/package-lock.json`:
  - `axios` -> `^1.13.6`
  - `cors` -> `^2.8.6`
  - `firebase-admin` -> `^12.7.0`
  - `firebase-functions` -> `^5.1.1`
  - `openai` -> `^4.104.0`

## Verification
- `dart format ...`
  - Result: success on all touched Dart files.
- `flutter analyze` on the touched Dart files
  - Result: no analyzer errors introduced by this change; existing warnings/info remain elsewhere in the files.
- `npm audit --json` in `functions/`
  - Result: `0 critical`, `0 high`, `0 moderate`; remaining advisories are `8 low`.
- `plutil -lint ios/Runner/Info.plist`
  - Result: OK
- Parsed:
  - `.github/workflows/check-no-golden-failures.yml`
  - `android/app/src/main/AndroidManifest.xml`
  - `android/app/src/main/res/xml/data_extraction_rules.xml`
  - Result: valid YAML/XML

## Remaining Constraint
- `functions/` still has low-severity transitive advisories under `firebase-admin` / Google Cloud transport packages.
- `npm audit` indicates the only available fix path is a breaking `firebase-admin@10.3.0` change, which is not an acceptable automated remediation for this scoped pass.

## Prompt Trace
- User-reported cross-repo SAST remediation
