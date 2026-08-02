> **Review baseline:** `pranaysuyash/Waste-Segregation-App`, branch `main`, commit `d7a9c73f75779ddcbf9f22f4ce2fba9a0280b171`
>
> **Remote commit date:** 2026-05-25
>
> **Review date:** 2026-08-02
>
> **Hard limitation:** This review does not include local, uncommitted, or unpushed work. Run `02_TASK_LOCAL_CHANGE_RECONCILIATION.md` before implementing any other task. Existing local work is authoritative where it is newer and intentional.

# Task: QA, CI, Deployment and Release Evidence

## Priority

P0.

## Objective

Create a reproducible pipeline that proves the Flutter app, Firebase Functions, security rules and release artifacts are compatible and deployable.

## Current gaps

- Flutter warnings/infos are non-fatal.
- Functions are not built or tested in the main CI workflow.
- Rules tests and Functions use different Node assumptions.
- The golden step can modify dependencies during CI.
- Storybook CI invokes the wrong script for a server-dependent runner.
- No release app bundle/archive is built.
- Latest remote commit exposes no combined status evidence.
- Deployment status is not tied to a commit and environment manifest.

## Required workflow structure

### Job 1: repository policy

- forbidden secrets;
- generated artefacts;
- broken mandatory doc links;
- lockfile consistency;
- formatting.

### Job 2: Flutter static checks

```bash
flutter pub get
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
```

If existing lint debt prevents immediate strictness, create a checked-in baseline with an expiry and fail on net-new findings. Do not permanently use broad `--no-fatal-*`.

### Job 3: Flutter tests

- unit;
- widget;
- golden;
- integration subsets;
- coverage report;
- randomised order plus fixed reproduction seed on failure.

Golden dependencies must already be in `pubspec.yaml`. CI must never edit source manifests.

### Job 4: Functions

```bash
npm --prefix functions ci
npm --prefix functions run lint
npm --prefix functions run build
npm --prefix functions test
```

Add type, unit and emulator integration tests for billing, classification, referral and storage functions.

### Job 5: security rules

Run Firestore and Storage emulator tests against the exact rules files intended for deployment.

### Job 6: AI eval

- generate report into a temporary/artifact directory;
- validate schema;
- compare to a versioned baseline;
- gate safety errors separately from aggregate score;
- upload report and summary.

### Job 7: release builds

At minimum:

```bash
flutter build appbundle --release
flutter build web --release
```

If iOS is supported, add an unsigned CI archive/build and a signed release lane in the secure environment.

Validate that release mode cannot access client AI secrets or developer toggles.

### Job 8: staging deploy

Deploy:

- Functions;
- Firestore rules;
- indexes;
- Storage rules;
- Remote Config template where applicable;
- Hosting/web.

Record deployed commit SHA and configuration manifest.

### Job 9: smoke tests

- sign in;
- classify;
- apply policy;
- save;
- sync;
- payment sandbox;
- report generation;
- account deletion;
- non-member access denied.

### Job 10: release evidence

Generate:

`docs/release/evidence/<version>/<commit>/RELEASE_EVIDENCE.md`

Include:

- commit;
- workflow run;
- tool versions;
- config hashes;
- test counts;
- eval report;
- artifact checksums;
- staging deployment IDs;
- smoke results;
- known exceptions;
- rollback reference.

## Environment management

- define `dev`, `staging`, `prod`;
- separate Firebase projects;
- separate payment provider environments;
- separate buckets;
- no production secret in local `.env` committed to source;
- use secret manager;
- use `dart-define-from-file` only with ignored files;
- verify App Check enforcement per environment.

## Release blocker policy

Block on:

- test failure;
- Functions build failure;
- rule test failure;
- safety eval failure;
- release build failure;
- secret scan;
- unsigned/unknown production configuration;
- missing rollback;
- billing sandbox regression.

Warnings can be accepted only through a dated exception with owner and removal issue.

## Rollback drill

Test:

- Functions rollback;
- rules rollback;
- Remote Config kill switch;
- billing disable;
- AI provider disable/fallback;
- app release halt;
- data migration reversal or forward-fix.

## Acceptance criteria

- One PR cannot merge unless all required jobs pass.
- Functions and rules are tested together.
- CI does not mutate repository files.
- Release artifacts are reproducible from the recorded commit.
- Staging deployment is traceable to a commit/config manifest.
- A smoke suite proves the critical user and denial paths.
- Rollback has been executed in staging.
