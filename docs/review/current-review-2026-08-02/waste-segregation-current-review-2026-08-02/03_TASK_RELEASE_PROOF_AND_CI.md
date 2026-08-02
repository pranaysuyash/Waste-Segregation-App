> **Repository:** `pranaysuyash/Waste-Segregation-App`
>
> **Reviewed branch:** `main`
>
> **Reviewed commit:** `e48a66bd6c9116e939a3eddfa5cc48c5d2171e6a`
>
> **Commit timestamp:** 2026-08-02T03:40:33Z
>
> **Review timestamp:** 2026-08-02
>
> **Previous review baseline:** `d7a9c73f75779ddcbf9f22f4ce2fba9a0280b171`
>
> **Evidence limit:** Static remote-code inspection plus current official/public-source research. The latest GitHub commit exposes no combined status checks or associated workflow runs, so build, test, deployment and runtime claims remain unverified until the release-proof task is executed.

# Task: Release Proof and CI

## Priority

P0. First executable engineering track.

## Objective

Turn the current high-blast-radius head into a reproducible, testable and deployable release candidate, or identify the exact breakpoints without changing product behaviour.

## Files owned

- `.github/workflows/**`
- CI helper scripts
- `functions/package.json`
- test configuration
- release-evidence docs
- environment manifest templates

Do not refactor domain logic in this branch.

## Findings

- no combined GitHub status on current head;
- no associated workflow run visible;
- Functions not compiled/tested in main CI;
- non-fatal analyser warnings/infos;
- CI can mutate `pubspec.yaml`;
- Node 18/22 mismatch;
- AI safety counts are not explicit hard failures;
- no release build or staging smoke evidence.

## Commit units

### Commit 1: non-mutating deterministic checks

Add:

```bash
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
flutter test --coverage
```

If existing lint debt blocks strictness:

- generate a checked-in baseline;
- fail on net-new findings;
- assign owner and removal condition;
- do not leave broad `--no-fatal-*` permanently.

Golden dependencies must already exist. CI must never run `flutter pub add`.

### Commit 2: Functions gate

Add scripts:

```json
{
  "lint": "...",
  "test": "npm run build && node --test test/*.test.js",
  "ci": "npm ci && npm run lint && npm run test"
}
```

Use Node 22 consistently.

Run emulator tests for:

- classify;
- spend/refund;
- Dodo webhook;
- token purchase;
- referrals;
- R2 intent/finalisation;
- HTTP response contracts.

### Commit 3: rules and schema gate

Run Firestore and Storage rules against the exact deploy files.

Add tests for protected fields and society paths from Task 04.

### Commit 4: AI/policy gate

Replace the current aggregate-only threshold with gates:

- schema validity: 100%;
- zero safety-critical must-not violations;
- class-specific regression limits;
- policy source/version present;
- unknown/abstain rate bounds;
- report versioned by taxonomy/prompt/model.

Write reports to an artefact directory, not a tracked source path.

### Commit 5: release artefacts

Build at least:

```bash
flutter build appbundle --release
flutter build web --release
```

Add unsigned iOS build/archive if iOS remains supported.

Assert in release mode:

- developer toggles disabled;
- direct client provider secrets unavailable;
- fake/local classifier cannot be advertised as production;
- web checkout respects platform/storefront feature flag;
- debug endpoints disabled.

### Commit 6: staging deployment and smoke

Separate Firebase projects:

- dev;
- staging;
- production.

Deploy Functions, rules, indexes, hosting and config to staging from the reviewed commit.

Smoke:

1. sign in;
2. foreground classification;
3. queued classification;
4. low-confidence safety;
5. save and sync;
6. non-member access denial;
7. billing sandbox;
8. webhook retry;
9. account/image deletion;
10. society policy precedence.

### Commit 7: release evidence generator

Produce:

`docs/release/evidence/<version>/<sha>/RELEASE_EVIDENCE.md`

Include:

- SHA;
- workflow/run IDs;
- tool versions;
- config hashes;
- test totals;
- eval report;
- artefact checksums;
- deployed Function/rule versions;
- smoke evidence;
- known exceptions;
- rollback commands.

## Acceptance criteria

- every PR runs Flutter, Functions, rules and AI gates;
- CI does not modify tracked files;
- current head produces release artefacts;
- staging deployment is traceable to SHA/config;
- safety failures are blocking;
- rollback is executed in staging;
- no “production ready” claim exists without corresponding release evidence.

## Anything else?

Inspect all new/renamed files in the August commit for case-sensitive paths. `Docs/` versus `docs/` must fail in CI.
