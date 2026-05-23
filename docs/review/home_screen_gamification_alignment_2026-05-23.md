# Home screen gamification alignment

Date: 2026-05-23

## What changed

- Aligned the daily goal target behind a shared constant:
  - `lib/utils/constants.dart`
  - `lib/providers/app_providers.dart`
  - `lib/services/gamification_service.dart`
- Switched contribution photo capture to the shared capture helper:
  - `lib/screens/contribution_submission_screen.dart`
- Fixed the content detail screen lifecycle bug by removing provider lookup from `dispose()` and caching the service safely:
  - `lib/screens/content_detail_screen.dart`
- Expanded home screen widget coverage:
  - daily progress card
  - near milestone card
  - community impact card
  - active challenge card
  - daily tip contentId navigation
  - 320px + larger text scale rendering
- Updated the home screen test harness to provide the provider package dependencies needed by downstream screens.

## Why

- The app had a real drift in daily goal logic: the provider used 3 while the gamification service had drifted to 5.
- The contribution submission screen was using a separate capture profile instead of the canonical helper.
- The content detail screen was unsafe in `dispose()` because it looked up a provider through a deactivated `BuildContext`.

## Verification

- `flutter test test/screens/home_screen_test.dart` ✅
- `flutter analyze lib/providers/app_providers.dart lib/services/gamification_service.dart lib/screens/contribution_submission_screen.dart lib/screens/content_detail_screen.dart test/screens/home_screen_test.dart` ✅

## Notes

- The home screen test now exercises the exact user-facing cards and navigation paths that were previously drifting.
- The content detail screen fix is structural, not a test-only workaround.
