# Runtime Blockers Classification (Phase 2)

Date: 2026-05-21
Repo: /Users/pranay/Projects/LLM/image/waste_seg/waste_segregation_app
Scope: iOS pods, Firebase web key/bootstrap, consent automation

## Executive result
- iOS pod blocker: not reproducible now (pod install succeeds).
- Firebase web bootstrap risk: fixed in this run.
- Consent automation: still open and launch-blocking for production ads.

## 1) iOS pods blocker

Observed now:
- Command: `pod install` in `ios/`
- Result: exit 0
- Output highlights:
  - "Pod installation complete! There are 29 dependencies ... 75 total pods installed"
  - Warnings: custom base config warning; FirebaseDynamicLinks deprecated.

Classification:
- Status: RESOLVED_FOR_NOW
- Severity: P1 (can reappear with local env drift, but not currently blocking)

Safe action taken:
- Re-ran pod install and verified successful resolution.

Remaining risk:
- Pod toolchain/env drift on other machines.
- Not a code architecture issue; mostly environment consistency issue.

## 2) Firebase web key/bootstrap blocker

Prior risk:
- `web/index.html` contained manual Firebase JS SDK and static placeholder config init.

Action taken:
- Removed manual Firebase SDK script tags and manual `firebase.initializeApp(firebaseConfig)` block.
- Left explicit note that Firebase must initialize via Dart `DefaultFirebaseOptions` + dart-defines.

Evidence:
- `web/index.html` updated.
- Search checks for `firebaseConfig`, `firebase.initializeApp`, `firebasejs` in `web/index.html` now return no matches.

Classification:
- Status: FIXED
- Severity: P0 (wrong bootstrap path can silently break runtime and config hygiene)

## 3) Consent automation blocker

Observed now:
- `lib/services/ad_service.dart:110` still contains:
  - `TODO: Add consent management for GDPR compliance`
- Ad units are still test IDs at lines 25/26/31/32.

Classification:
- Status: OPEN
- Severity: P0 for production monetized launch

Why P0:
- Production ad monetization without consent workflow is not acceptable for GDPR/EEA flows.
- Test ad IDs mean ad revenue path is not production-ready.

## Blocker table

| Blocker | Current state | Severity | Safe fix applied now | Remaining work |
|---|---|---:|---|---|
| iOS pods install failure | Not reproducing | P1 | Verified `pod install` success | Keep reproducibility notes in release runbook |
| Web Firebase static bootstrap | Fixed | P0 | Removed manual HTML Firebase init | Keep Dart-only config path enforced |
| Consent automation for ads | Open | P0 | None (documentation + classification only) | Implement UMP/consent flow + prod ad IDs |

## Recommendations (next execution slice)
1. Implement consent gate before ad SDK load and before ad request dispatch.
2. Replace test ad IDs with environment-specific production IDs.
3. Add a startup diagnostic event proving consent state and ad serving eligibility.
4. Add an integration check for web bootstrap path to prevent reintroduction of manual HTML Firebase init.
