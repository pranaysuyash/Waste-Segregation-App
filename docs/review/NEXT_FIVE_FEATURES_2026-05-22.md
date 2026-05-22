# Next Five Features to Complete (Money-First Launch)

Date: 2026-05-22
Basis: repo state + latest Firebase hardening docs + targeted test execution.

## 1) Stabilize compile path blocking release-safety test lane

Why this is next:
- `flutter test test/services/enhanced_ai_api_service_safety_test.dart` currently fails at compile time.
- Failure location: `lib/services/local_guidelines_plugin.dart:344` (`bool?` negation issue).

Evidence:
- Command run: `flutter test test/services/enhanced_ai_api_service_safety_test.dart`
- Error: `A value of type 'bool?' can't be assigned to a variable of type 'bool'`.

Definition of done:
- Fix null-safe compliance condition in `local_guidelines_plugin.dart`.
- `flutter test test/services/enhanced_ai_api_service_safety_test.dart` passes.
- No new analyzer errors in touched files.

## 2) Add server-enforced daily free-scan quota (not just token balance)

Why this is next:
- Current classify path tracks `dailyConversionsUsed` fields but does not enforce or increment daily quota in `functions/src/classify_image.ts`.
- This leaves free-tier abuse control incomplete.

Evidence:
- `functions/src/classify_image.ts` reads `dailyConversionsUsed` / `lastConversionDate` but does not increment/reset/enforce against a limit.

Definition of done:
- Enforce per-user daily free scan cap server-side in callable flow.
- Proper day-boundary reset logic.
- Emulator tests for: under limit, at limit, and day rollover.

## 3) Unify monetization config contract across client + backend

Why this is next:
- Checklist expects keys like `monetization.free_daily_scan_limit` and `ai.routing.backend_required_release`, but those keys exist only in docs, not implemented as a strict shared contract.
- Current `RemoteConfigService` uses a mixed/legacy key set.

Evidence:
- Search for `monetization.free_daily_scan_limit` / `ai.routing.backend_required_release` returns only `docs/review/MONEY_FIRST_LAUNCH_CONFIG_CHECKLIST_2026-05-22.md`.
- `lib/services/remote_config_service.dart` has different keys (`daily_free_classifications`, etc.).

Definition of done:
- Define canonical config schema (single source of truth) for monetization + AI routing.
- Map client and backend to canonical keys.
- Add validation/fallback tests for missing or malformed config values.

## 4) Close entitlement mismatch test gap (billing authority precedence)

Why this is next:
- Claims fallback behavior is tested.
- Canonical billing-entitlement precedence under mismatch scenarios is not explicitly covered.

Evidence:
- `functions/test/http_guards.emulator.test.js` contains claims-fallback assertions, but no explicit test for: Firestore billing entitlement true + stale free tier/claims mismatch.

Definition of done:
- Add regression tests for entitlement precedence cases:
  - billing entitlement true + stale free claim/tier
  - billing entitlement false + premium claim true (fallback path)
- Assert `spendAuthoritySource` and charged amount for each case.

## 5) Add automated production guardrails for App Check + ops thresholds

Why this is next:
- App Check enforcement is env-controlled and defaults to `false` if unset.
- Ops counters are written, but threshold breach logic from checklist is not automated.

Evidence:
- `functions/src/index.ts` uses `parseBoolEnv(process.env.REQUIRE_APPCHECK_CALLABLE, false)`.
- Metrics are written to `ops_metrics/{date}`, but no threshold alarm evaluator found.

Definition of done:
- Fail deployment or function startup in production when required security env is unset/misconfigured.
- Implement threshold evaluator job for key counters (`claims_fallback`, `appcheck_missing`, refund rate spikes, rate-limit spikes).
- Emit actionable alerts (log + persistent alert record) with clear runbook links.

---

Priority order: 1 -> 2 -> 3 -> 4 -> 5
Rationale: unblock verification first, then close monetization abuse gaps, then harden contract correctness, then lock entitlement edge cases, then automate operational protection.