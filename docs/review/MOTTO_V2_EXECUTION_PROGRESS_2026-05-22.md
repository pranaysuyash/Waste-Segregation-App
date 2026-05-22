# Motto_v2 Execution Progress (2026-05-22)

Scope: execute the five prioritized money-first hardening features from `docs/review/NEXT_FIVE_FEATURES_2026-05-22.md`.

## Status

- f1 complete
- f2 complete
- f3 complete
- f4 complete
- f5 complete

## What changed

### f1. Compile blocker + safety test lane

- Verified `lib/services/local_guidelines_plugin.dart` path compiles in the targeted lane.
- Verified `test/services/enhanced_ai_api_service_safety_test.dart` passes.

Evidence:
- `flutter test test/services/enhanced_ai_api_service_safety_test.dart`
- Result: pass

### f2. Server-enforced daily free-scan quota

Implemented in `functions/src/classify_image.ts`:
- Added canonical + legacy env-backed free quota resolver:
  - `MONETIZATION_FREE_DAILY_SCAN_LIMIT`
  - fallback: `CLASSIFY_DAILY_FREE_CLASSIFICATIONS`, `DAILY_FREE_CLASSIFICATIONS`
- Added UTC day normalization/reset logic for quota rollover.
- Reservation flow now:
  - consumes free daily quota first (tokenCost=0)
  - charges tokens only after quota exhaustion
  - preserves idempotency behavior
  - writes reservation metadata: `freeQuotaApplied`, `freeQuotaLimit`
- Added `reservedAt` / `reservedAtIso` to reservation records for ops reconciliation consistency.

Tests added/updated:
- `functions/test/classify_image.test.js`
  - daily quota helper tests (default/alias/rollover)
- `functions/test/http_guards.emulator.test.js`
  - quota exhausted + no tokens => insufficient
  - under quota + no tokens => not insufficient; quota increments
  - day rollover => quota resets and increments correctly

### f3. Unified monetization/AI routing config contract

Added canonical client contract:
- `lib/config/monetization_ai_config_contract.dart`
  - canonical keys
  - legacy aliases
  - default values
  - typed validation readers (`readBool`, `readInt` with bounds)

Updated client RC service:
- `lib/services/remote_config_service.dart`
  - imports contract
  - default RC values now emitted through canonical+legacy mapping
  - added `getMonetizationAiRoutingConfig()` to resolve canonical values safely

Updated backend env contract usage (classify path):
- canonical envs now supported with precedence:
  - `MONETIZATION_CLASSIFY_IMAGE_TOKEN_COST`
  - `MONETIZATION_CLASSIFY_IMAGE_PREMIUM_DISCOUNT_PERCENT`
  - `MONETIZATION_FREE_DAILY_SCAN_LIMIT`
- legacy envs remain supported for backward compatibility.

Tests:
- `test/config/monetization_ai_config_contract_test.dart`
- `functions/test/classify_image.test.js` (env precedence checks)

### f4. Entitlement precedence mismatch regression tests

Updated `functions/test/http_guards.emulator.test.js`:
- Added regression: billing entitlement true + stale claims free-tier
  - verifies canonical source remains `billing_entitlement`
  - verifies premium pricing path is applied
- Existing regression retained:
  - billing absent + premium claim true => `claims_fallback`

### f5. App Check production guardrails + automated ops threshold alerts

App Check production guardrails:
- `functions/src/index.ts`
  - added production runtime guardrail validator:
    - requires `REQUIRE_APPCHECK_CALLABLE=true`
    - requires `REQUIRE_APPCHECK_HTTP=true`
  - fails startup in production if misconfigured
  - emergency bypass: `ALLOW_INSECURE_FUNCTIONS_BOOT=true` (logs explicit error)
  - testable exports via `__testables`

Ops threshold automation:
- `functions/src/ops_hardening.ts`
  - added scheduled function `evaluateOpsThresholdAlerts` (every 15 min)
  - evaluates counters/refund rate against env thresholds
  - persists dashboard snapshot to `ops_monitoring/ops_threshold_alerts`
  - writes alert docs to `ops_alerts/{day_alertType}`
  - emits error logs on breaches
  - helper exported for unit tests (`__testables.buildThresholdAlerts`)
- `functions/src/index.ts`
  - exports `evaluateOpsThresholdAlerts`

Tests:
- `functions/test/ops_hardening.test.js`
- `functions/test/appcheck_guardrails.test.js`

## Verification runbook evidence

### Backend TypeScript build
- `cd functions && npm run build`
- pass

### Functions unit tests
- `cd functions && node --test test/classify_image.test.js test/ops_hardening.test.js test/appcheck_guardrails.test.js`
- pass (43/43)

### Emulator integration tests
- `cd functions && npm run test:http-guards:emulator`
- pass (11/11)

### Flutter tests
- `flutter test test/services/enhanced_ai_api_service_safety_test.dart test/config/monetization_ai_config_contract_test.dart`
- pass

### Flutter analyze (contract/client files)
- `flutter analyze lib/config/monetization_ai_config_contract.dart test/config/monetization_ai_config_contract_test.dart lib/services/remote_config_service.dart`
- pass

## Residual risks / follow-ups

1. Ops threshold function is fire-and-record today. Pager/Slack/Telegram delivery is not wired in this change.
2. Threshold defaults are conservative; tune env thresholds in production after observing one week of baseline metrics.
3. Existing non-blocking analyzer infos still exist in unrelated/deprecated code paths (not introduced by this batch).
