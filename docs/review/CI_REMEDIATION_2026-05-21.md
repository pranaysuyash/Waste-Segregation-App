# CI Remediation Addendum — 2026-05-21

## Scope
Follow-up remediation after `Build and Test` failures on main.

## Changes made

1. Android CI portability and signing fallback
- File: `android/gradle.properties`
  - Removed host-specific `org.gradle.java.home` hardcoded macOS path.
- File: `android/app/build.gradle`
  - Guarded release keystore usage behind `key.properties` + `storeFile` presence.
  - Added CI-safe fallback to debug signing config when release keystore is absent.

2. Firestore rules workflow path fix
- File: `.github/workflows/firestore_rules_test.yml`
  - Replaced relative `fs.readFileSync('firestore.rules', 'utf8')` with
    `fs.readFileSync(require('path').resolve(__dirname, '../../firestore.rules'), 'utf8')`.
  - This removes working-directory coupling that caused ENOENT in CI.

3. Golden test runner environment alignment
- File: `.github/workflows/build_and_test.yml`
  - Updated `golden_tests` runner from `ubuntu-latest` to `macos-14`.
  - Reason: baseline goldens are stable in macOS local runs and were failing in Linux CI with widespread visual diffs.

## Verification executed locally

- `dart format --set-exit-if-changed .` => PASS (0 changed)
- `flutter analyze --no-fatal-warnings --no-fatal-infos` => PASS
- `flutter test test/golden/ --reporter=json > /tmp/golden_test_results.json` then grep for `"result":"error"` => `golden_errors=0`

## Notes

- Local `flutter build apk --debug` failed due workstation disk exhaustion (`No space left on device`), not a code/config error.
- CI evidence from run `26243936319` before this patch cycle showed build failure moved from JDK path issue to keystore path null; this addendum addresses the latter.

## Expected outcome after push

- `Build Flutter App` should no longer fail due missing release keystore path on CI.
- Firestore rules test harness should resolve rules path deterministically.
- Golden tests should run in a macOS environment consistent with local baseline generation.
