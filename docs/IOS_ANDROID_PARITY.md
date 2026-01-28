# iOS / Android Parity Notes

**Date:** 2026-01-27

Quick summary of parity changes and checks performed:

## Changes implemented

- Added App Tracking Transparency support on iOS:
  - `NSUserTrackingUsageDescription` key added to `ios/Runner/Info.plist`.
  - `PermissionHandler.checkTrackingPermission()` helper added to request ATT at runtime (non-blocking).
  - ATT is requested during app bootstrap (debug & release) non-blocking; failure is logged but does not block app.

- Debug status overlay added (debug builds only):
  - Shows quick statuses: Firebase initialized, Hive presence, Consent status, API keys present.
  - Implemented as a non-intrusive overlay at top-right in debug builds.

- MINIMAL MODE behavior clarified and made opt-in via `SKIP_HIVE` define (used to be iOS-only automatic in debug). The app now runs full init by default on both platforms.

## Parity checklist

- Permissions
  - Camera & Photo library: `NSCameraUsageDescription` and `NSPhotoLibraryUsageDescription` already present.
  - Tracking: `NSUserTrackingUsageDescription` added for iOS.
  - Storage & Photos permission flows handled via `PermissionHandler` for mobile platforms.

- Ads & Analytics
  - AdMob test IDs present. Ensure production IDs are added for iOS & Android in `AdService` and Info.plist (AdMob App ID).
  - Analytics consent enforced equally across platforms; make sure consent flows show up on first-run in iOS.

- Features parity
  - Image capture, gallery upload, instant analysis, and all main screens are available on iOS and Android.
  - Platform specific exceptions remain (e.g., on-device ML acceleration may differ by platform; documented in `APP_KNOWLEDGE_BASE.md`).

## Next recommended steps

1. Run manual user flows on iOS to confirm ATT prompt, consent UI behavior, and that debug overlay shows expected statuses.
2. Validate AdMob initialization and push notification registration on iOS via real device and Apple Developer settings.
3. Add a brief section to `README.md` summarizing platform-specific setup for iOS (APNs, AdMob IDs, Info.plist keys).

---

If you'd like, I can implement steps 1 and 3 next (add README iOS setup docs and a small test harness to validate ATT and consent flows).
