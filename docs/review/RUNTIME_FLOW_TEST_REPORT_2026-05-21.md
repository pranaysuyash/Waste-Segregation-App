# Runtime Flow Test Report

Date: 2026-05-21
Project: waste_segregation_app
Simulator: `99B3D785-20D8-4889-9622-43F89781AD9A` (`DailyHue iPhone 16`)
Bundle ID: `com.example.wasteSegregationApp`

## Scope

This report captures the live simulator/browser verification pass requested for the app flow. The goal was to test the app as a user would, using the installed `serve-sim` preview plus simulator automation, and to record what actually happened at runtime.

## Environment Notes

- The iOS build initially failed because the machine was nearly out of disk space and CocoaPods had been tripping over the non-system `base64` path.
- I fixed the pod installation path issue by forcing `/usr/bin` first in `PATH` during `pod install`.
- I then cleared generated build artifacts to recover disk space:
  - `build/`
  - `~/Library/Developer/Xcode/DerivedData`
- After that, the simulator build and launch succeeded.
- `Computer Use` remained unavailable in this session because of the server/client version mismatch, so the simulator was driven through the iOS simulator tooling instead.

## Build and Launch Evidence

- `pod install` completed successfully after the path fix.
- `flutter run -d 99B3D785-20D8-4889-9622-43F89781AD9A` reached `Xcode build done` and launched the app on the simulator.
- `simctl install` and `simctl launch` also succeeded for the built app bundle.

## Verified Runtime Flows

### 1. Consent gate

- The app opened on the consent screen.
- Tapping `Accept & Continue` advanced to the next screen.

### 2. Pre-auth home screen

After consent, the app showed the home dashboard with:

- `Sign in with Google`
- `Continue as Guest`
- dashboard cards for points, tokens, streak, and days
- no crash on startup

### 3. Guest path

- Tapping `Continue as Guest` entered the main app shell.
- The home dashboard showed:
  - `Take Photo`
  - `Upload Image`
  - `Instant Camera`
  - `Today's sorting tip`
  - `Scan`
  - bottom navigation: `Home`, `History`, `Learn`, `Social`, `Rewards`

### 4. Upload image flow

- Tapping `Upload Image` opened the native photo picker.
- Selecting a sample image opened the `Review Image` screen.
- The review screen showed:
  - `AI Vision Mode`
  - `Instant scan ready`
  - `Scan Insights`
  - `Analysis Speed`
  - `Batch`
  - `Instant`
  - the mode summary (`Mode`, `Model`, `Status`, `Token cost`, `Estimated time`, `Segmentation`)

### 5. Google auth handoff

- Tapping the scan/capture flow eventually produced the Google sign-in handoff.
- The simulator opened `accounts.google.com` with:
  - `Sign in`
  - `Email or phone`
  - `Next`
- I did not fabricate credentials.

### 6. Camera permission gate

- Tapping the take-photo path first produced a camera permission dialog.
- I granted simulator camera access with:
  - `xcrun simctl privacy ... grant camera com.example.wasteSegregationApp`
- This confirmed the app’s camera permission gating is real and device-level permissions are involved.

### 7. Main shell tabs

The bottom navigation routes were verified:

- `History`
  - empty state: `No classifications yet`
  - CTA: `Scan your first item`
- `Learn`
  - article list rendered
  - opening `Understanding Plastic Recycling Codes` worked
  - a visible runtime issue was present during the first pass: `WIDGET ERROR: This AdWidget is already in the Widget tree`
  - the issue was then fixed by removing the duplicate bottom ad from the Learn screen when it is hosted inside the main navigation wrapper
- `Social`
  - `Community`
  - empty state: `No community activity yet`
- `Rewards`
  - `Achievements`
  - `Level 1`
  - `Recycling Rookie`
  - `Daily Streak 0 days`

## Issues Observed

### High priority

- The `Analyze` action on the `Review Image` screen did not advance to a result screen in simulator-driven testing.
- The review screen remained on the same state after the tap, so the full classification result path is still not proven end-to-end.

### Medium priority

- The Learn tab originally showed an in-app widget error banner:
  - `WIDGET ERROR: This AdWidget is already in the Widget tree`
- That issue has been fixed in the current simulator build by ensuring the Learn screen does not render a second bottom banner when the main shell already provides one.

### Informational

- The Google sign-in branch opens correctly, but it requires real credentials.
- The camera path is gated by device permission and external auth behavior, so the flow depends on device state.

## What This Means

- The app now launches successfully on iOS simulator.
- The consent gate, guest entry, upload flow, article route, history empty state, social empty state, and rewards route all work.
- The capture/review stage is present and interactive.
- The Learn screen ad-widget duplication error is resolved in the current simulator build.
- The final analysis/submit action still needs follow-up because it did not complete a visible result transition during this pass.

## Follow-Up

1. Investigate why the `Analyze (Instant)` action does not advance from the review screen in simulator testing.
2. Investigate why the `Analyze (Instant)` action does not advance from the review screen in simulator testing.
3. Re-run the capture flow after the analysis action is confirmed to move to a result state.
