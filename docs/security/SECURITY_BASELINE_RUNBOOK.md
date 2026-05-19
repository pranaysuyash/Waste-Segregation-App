# Security Baseline Runbook

This runbook is the canonical pre-change and pre-release security verification path for auth/guardrail work.

## Scope

The baseline verifies:
- Cloud Functions HTTP auth guard behavior (unit-level harness)
- Cloud Functions + Auth Emulator integration behavior (real ID tokens)
- Firestore security rules behavior (emulator-backed rules suite)

## Commands (Run In Order)

1. Functions guard unit tests

```bash
cd /Users/pranay/Projects/LLM/image/waste_seg/waste_segregation_app/functions
npm run test:http-guards
```

Expected result:
- `6/6` tests passing

2. Functions + Auth Emulator integration tests

```bash
cd /Users/pranay/Projects/LLM/image/waste_seg/waste_segregation_app/functions
npm run test:http-guards:emulator
```

Expected result:
- `2/2` tests passing

3. Firestore rules emulator tests

```bash
cd /Users/pranay/Projects/LLM/image/waste_seg/waste_segregation_app/firestore-rules-test
npm run test:emulator
```

Expected result:
- `83 passing`

## Interpreting Failures

- If step 1 fails: treat as function-guard regression first (fastest signal).
- If step 1 passes but step 2 fails: investigate emulator/runtime auth semantics, env flags, or function wiring.
- If step 3 fails: treat as Firestore rules contract regression, even when functions tests pass.

## Environment Notes

- `firebase.json` must include emulator config for `auth` and `functions`.
- Emulator warning about multiple running suites can occur; do not ignore it if ports collide or tests become flaky.
- Functions tests may show Node engine mismatch warnings (`18` vs host `23`); warnings are non-blocking, but keep runtime alignment on the backlog.

## Enforcement Policy

- Any change touching:
  - `functions/src/index.ts`
  - auth/token verification flow
  - Firestore rules
  - user-write paths
  
  must run this full baseline before closure.

## Last Verified Baseline

- Date: `2026-05-19`
- Results:
  - `test:http-guards`: pass (`6/6`)
  - `test:http-guards:emulator`: pass (`2/2`)
  - `firestore-rules-test test:emulator`: pass (`83 passing`)
