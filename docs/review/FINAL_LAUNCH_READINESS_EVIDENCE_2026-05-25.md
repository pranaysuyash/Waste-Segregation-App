# Final Launch Readiness Evidence — 2026-05-25

## Objective
Close launch-readiness feedback with implementation + evidence, using canonical long-term paths only (no legacy parallel production flows pre-launch).

## Completed implementation closures

1. Identity and auth alignment
- Google sign-in now creates FirebaseAuth session and canonical UID usage in profile flow.
- Guest path uses Firebase anonymous auth (when Firebase enabled).
- Added cloud+local migration path for legacy non-UID identity records.

Files:
- `lib/services/google_drive_service.dart`
- `lib/screens/auth_screen.dart`
- `lib/services/storage_service.dart`
- `functions/src/migrate_legacy_user_data.ts`
- `functions/src/index.ts`

2. Production-safe AI routing
- Release/fail-closed backend classification already in place and verified in this pass.
- Added backend correction callable and app-side routing to backend for correction flow when backend routing is enabled.

Files:
- `functions/src/classify_image.ts`
- `functions/src/index.ts`
- `lib/services/ai_service.dart`

3. Token authority consolidation
- Prevented client-side token re-spend when backend routing is active for instant and offline-queue paths.

Files:
- `lib/screens/image_capture_screen.dart`
- `lib/services/offline_queue_service.dart`

4. Release hardening gates
- Release signing hard-fail if missing release keystore.
- AdMob app ID hard-fail for missing/test IDs in release.
- Android manifest uses placeholder App ID.
- targetSdk pinned to 35.
- Subscription privacy read rule tightened to owner-only.

Files:
- `android/app/build.gradle`
- `android/app/src/main/AndroidManifest.xml`
- `firestore.rules`
- `lib/services/ad_service.dart`

5. Privacy policy surface updated to match runtime reality
- Updated policy covers auth, backend AI, crash/perf, ads, payments/subscriptions, App Check, retention/deletion/export, and choices.

File:
- `assets/docs/privacy_policy.md`

6. Motto policy tightened
- Explicitly codified pre-existing/blast-radius closure and pre-launch no-legacy-parallel-path rule.

File:
- `motto_v2.md`

## Verification evidence executed

### Functions backend
- `cd functions && npm install --include=dev`
- `cd functions && npm run build`
- `cd functions && npm run test:classify-image`

Result:
- Build: PASS
- classify-image tests: PASS (39/39)

### Flutter scoped analysis
- `flutter analyze` on touched launch-path files

Result:
- No new hard compile blockers introduced in touched paths.
- Existing repo-level lint/info warnings remain in older code paths.

## Remaining launch gate (manual but required)

These require real signed release/internal-test environment and cannot be fully proven by static checks alone:

1. Internal testing smoke on signed release artifacts
- Google sign-in user flow
- Anonymous guest flow
- classifyImage callable success
- correction re-analysis callable success
- App Check accepted on release build
- single token charge behavior verified
- history save/read/delete/export verified

2. Store-console declarations finalization
- Play Data Safety entries must match actual runtime SDK/data behavior.
- Apple privacy labels must match collected/linked data categories.

## Go/No-go status
- Code-path hardening and core blocker closures: COMPLETE
- Store/internal-test operational evidence: PENDING MANUAL EXECUTION

## Next operator checklist (run in release lane)

1. Deploy callables:
- `firebase deploy --only functions:classifyImage,functions:reanalyzeWithCorrection,functions:migrateLegacyUserData`

2. Build release artifact with backend routing:
- `flutter build appbundle --release --dart-define=USE_BACKEND_CLASSIFICATION=true`

3. Install from internal testing track and execute end-to-end smoke.

4. Record screenshots/log snippets and append results to this document.
