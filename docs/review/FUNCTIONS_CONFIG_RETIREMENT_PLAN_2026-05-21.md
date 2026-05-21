# functions.config() Retirement Plan + Key Precedence Test (Phase 4)

Date: 2026-05-21
Repo: /Users/pranay/Projects/LLM/image/waste_seg/waste_segregation_app

## Current state
- Runtime key resolver is env-first with legacy fallback:
  - `functions/src/index.ts:18-22`
  - `functions/batch_processor.js:15-18`
- New precedence test added:
  - `functions/test/openai_key_resolution.test.js`
  - Script: `npm --prefix functions run test:key-resolution`
  - Status: PASS (3/3)

## Why not remove fallback immediately
- Existing deployed environments may still rely on `functions.config().openai.*`.
- Immediate removal without rollout audit risks production outage on AI endpoints.

## Retirement plan (safe sequence)

### Stage A: Visibility and enforcement guardrails
1. Keep env-first resolver and emit structured log when fallback branch is used.
2. Add metric/log counter: `openai_key_source=env|legacy_config`.
3. Confirm all non-local environments show `env` source for >= 7 consecutive days.

### Stage B: Freeze legacy writes
1. Stop setting/updating `functions.config().openai.*` in deployment docs/runbooks.
2. Ensure only env/secret manager is documented for key provisioning.

### Stage C: Remove fallback
1. In `functions/src/index.ts`, remove `functions.config()?.openai?.key/api_key` branches.
2. In `functions/batch_processor.js`, remove legacy config branches.
3. Keep explicit missing-key error behavior unchanged.

### Stage D: Validation and rollback safety
1. Run:
   - `npm --prefix functions run test:key-resolution`
   - `npm --prefix functions run test:http-guards`
   - `npm --prefix functions run test:http-guards:emulator`
2. Validate runtime logs in staging for key presence and endpoint health.
3. Rollback path: reintroduce fallback function only if env key provisioning is proven broken.

## Required acceptance criteria to retire fallback
- All environments provision `OPENAI_API_KEY`.
- No runtime log evidence of legacy fallback usage during observation window.
- Test suite above passes on CI/staging.
- Deployment docs updated to env-only key path.

## File delta in this phase
- `functions/src/index.ts` (exported helper for testability)
- `functions/test/openai_key_resolution.test.js` (new)
- `functions/package.json` (new `test:key-resolution` script)
