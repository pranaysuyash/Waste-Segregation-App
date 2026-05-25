# Launch Readiness P0 Hardening (2026-05-25)

## Scope
This pass validates and hardens the production-critical launch path identified in the readiness feedback, following `motto_v2.md` and repo instruction stack.

## Verified current-state findings
- `classifyImage` export is already present in `functions/src/index.ts` (not a current blocker).
- Core auth path still used Google account identity in app profile flow, not guaranteed Firebase Auth UID alignment.
- Guest flow did not guarantee Firebase anonymous auth before entering app.
- Classification token charging had duplicate-risk path (client spend after backend-routed classification).
- Android release signing still allowed fallback to debug signing.
- Android manifest still hardcoded test AdMob app ID.
- Firestore subscription rule allowed any authenticated user to read subscription docs.

## Implemented fixes

### 1) Firebase Auth alignment for Google sign-in
- Updated: `lib/services/google_drive_service.dart`
- Changes:
  - Google sign-in now creates FirebaseAuth session using `GoogleAuthProvider.credential(...)`.
  - Canonical app `userId` now uses Firebase UID (`FirebaseAuth.user.uid`) in this flow.
  - Sign-out now signs out both Google and FirebaseAuth.

### 2) Guest mode backend compatibility
- Updated: `lib/screens/auth_screen.dart`
- Changes:
  - “Continue as Guest” now signs in with `FirebaseAuth.signInAnonymously()` when Firebase is enabled.
  - Maintains safe fallback in environments where Firebase is intentionally disabled by config.

### 3) Token single-authority correction (backend-routed flows)
- Updated: `lib/screens/image_capture_screen.dart`
- Updated: `lib/services/ai_service.dart`
- Updated: `lib/services/enhanced_ai_api_service.dart`
- Updated: `lib/services/offline_queue_service.dart`
- Changes:
  - Instant classification no longer spends client tokens when backend routing is enabled.
  - Offline queue no longer pre-spends/refunds local tokens when backend routing is enabled.
  - Added explicit runtime getter for backend routing status to avoid test-only access leaks.

### 4) Android release guardrails
- Updated: `android/app/build.gradle`
- Updated: `android/app/src/main/AndroidManifest.xml`
- Changes:
  - `targetSdk` pinned to `35` in app module config.
  - Release build now hard-fails if signing key config is missing.
  - AdMob app ID moved to manifest placeholder `${adMobAppId}`.
  - Release build now hard-fails if `ADMOB_APP_ID` missing or set to Google test app ID.

### 5) AdMob release unit safety
- Updated: `lib/services/ad_service.dart`
- Changes:
  - Release ad unit resolution now throws hard error when release ad unit IDs are absent (no test-unit fallback in release).

### 6) Firestore subscription privacy rule
- Updated: `firestore.rules`
- Changes:
  - `/subscriptions/{subscriptionId}` read now requires ownership:
    - `request.auth != null && resource.data.userId == request.auth.uid`

### 7) Minor codebase consistency note
- Updated: `functions/src/rate_limit_config.ts`
- Changes:
  - Corrected stale comment indicating `classifyImage` didn’t exist.

## Validation executed
- `dart format` on touched Dart files.
- `flutter analyze` on touched Dart modules.
  - Result: no new errors from this patch set; existing repo-wide info/warnings remain.
- `cd functions && npm run build`
  - Result: failed due to pre-existing Functions TypeScript environment/dependency/type setup in `functions/` (missing modules/types and broad TS errors not introduced by this patch).

## Remaining P0/P1 blockers (not fully closed in this pass)
1. Correction/re-analysis in release still uses direct client AI path and can fail under production safety guard.
   - Requires backend callable parity for correction loop.
2. End-to-end Firebase UID migration for historical user docs keyed by non-UID identity is not fully automated here.
   - Current fix ensures new/authenticated paths use Firebase UID.
3. App Check + internal-testing release validation still needs real signed-build smoke verification against deployed backend.
4. Privacy policy/Data Safety/App Privacy declarations still need legal/product artifact updates to match actual SDK/data flows.

## Immediate next actions (recommended order)
1. Implement backend callable for correction/re-analysis and wire `ResultScreen` correction flow to it.
2. Add UID migration helper/backfill strategy for legacy profile IDs.
3. Run signed internal test build smoke run:
   - Google auth user
   - Anonymous guest
   - classify image
   - verify single token debit
   - verify history write/read
4. Complete policy and store disclosure updates for Play + Apple.

## Confidence
High confidence on implemented code-path fixes above.
Moderate confidence on full launch readiness until correction backend path and signed-release E2E verification are complete.

## Additional completion pass (same day)

### 8) Release-safe correction re-analysis backend path (closed)
- Updated: `functions/src/classify_image.ts`
- Updated: `functions/src/index.ts`
- Updated: `lib/services/ai_service.dart`
- Changes:
  - Added new callable: `reanalyzeWithCorrection` in `asia-south1`.
  - Enforces Firebase Auth and App Check policy consistently with backend classification policy.
  - Uses server-side provider routing (OpenAI primary, Gemini fallback) with correction-aware prompt.
  - Writes cost telemetry for re-analysis route.
  - App correction flow (`AiService.handleUserCorrection`) now routes to backend callable when backend routing is enabled (release-safe).
  - Direct client correction route remains available only for non-backend local/dev paths.

### Updated remaining blockers after this pass
1. `functions/` TypeScript toolchain/dependency state is still failing local `npm run build` in this environment; function code changes are in place but local compile proof is blocked by pre-existing package/type setup.
2. Legacy user profile IDs already persisted with non-Firebase identity may still require migration/backfill script.
3. Signed internal-test E2E run and store policy artifact updates still required before final public launch declaration.
