# Firestore Background Disconnect Notes

Date: 2026-05-21

## What was observed

The device log showed:

- `Application backgrounded at ...`
- `WatchStream` closed with `UNAVAILABLE`
- `ManagedChannelImpl` DNS resolution failures
- `Lost connection to device`

This pattern is consistent with Firestore/network activity dropping as the app backgrounds or the device connection becomes unstable. It was not accompanied by an app crash trace in the captured log.

## What was changed

- `lib/services/analytics_service.dart`
  - Removed the boot-time Firestore availability probe.
  - Switched to optimistic Firestore availability with fallback on real write failure.
  - Added a delayed recovery probe instead of immediate re-probing on every failure.
  - Fixed session event bookkeeping so the existing session cap is enforced.
  - Made `dispose()` synchronous and explicitly unawaited the session-end tracking.

- `lib/services/firebase_backend_diagnostics_service.dart`
  - Made the service lifecycle-aware.
  - Pauses periodic host checks while the app is backgrounded.
  - Resumes checks on foreground return.

## Verification

- `flutter analyze lib/services/analytics_service.dart lib/services/firebase_backend_diagnostics_service.dart`
- `flutter test test/services/analytics_service_test.dart`

## Notes

The change reduces avoidable backend churn and log noise when the app backgrounds, but it does not prove the emulator/device disconnect was entirely caused by app code. If the disconnect still appears after this change, the next place to inspect is the active Firestore stream owners in the family/community screens.
