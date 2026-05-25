# Money-First Launch Config Checklist (MVP)

Scope: Firebase-first launch with backend-authoritative AI spend and monetization controls.

## 1) Required Remote Config defaults (pre-launch)

Set and verify these as server-controlled defaults (with safe fallback values in app):

- monetization.free_daily_scan_limit = 5
- monetization.free_batch_scan_limit = 20
- monetization.premium_daily_scan_limit = 100
- monetization.premium_batch_scan_limit = 500
- monetization.enable_token_wallet = true
- monetization.enable_ads_for_free = true
- monetization.ad_interstitial_every_n_scans = 3
- monetization.enable_rewarded_ads_for_bonus_tokens = true
- monetization.rewarded_ad_token_reward = 1

- ai.routing.backend_required_release = true
- ai.client_direct_calls_allowed_release = false
- ai.default_model_free = gpt-4o-mini
- ai.default_model_premium = gpt-4o-mini
- ai.batch_model = gpt-4o-mini
- ai.instant_cost_free_tokens = 5
- ai.instant_premium_discount_percent = 40
- ai.batch_cost_tokens = 1

- abuse.require_app_check_callable = true
- abuse.rate_limit_window_seconds = 60
- abuse.rate_limit_spend_tokens_max = 12
- abuse.rate_limit_classify_max = 12

## 2) Required Function env/secrets (pre-launch)

- OPENAI_API_KEY set in runtime secret manager/env
- REQUIRE_APPCHECK_CALLABLE=true
- ENFORCE_APPCHECK_IN_EMULATOR=false (true only for dedicated emulator tests)
- SPEND_PREMIUM_DISCOUNT_PERCENT=40
- BATCH_OPENAI_MODEL=gpt-4o-mini

## 3) Required rule/test gates (pre-launch)

Must pass before release:

- npm --prefix functions run build
- npm --prefix functions run test:http-guards:emulator
- npm --prefix firestore-rules-test run test:all:emulator
- flutter analyze lib/services/enhanced_ai_api_service.dart test/services/enhanced_ai_api_service_safety_test.dart

## 4) Observability minimum (pre-launch)

Ensure daily counters are written and visible in Firestore:

- ops_metrics/{date}.counters.spendUserTokens_unauthenticated
- ops_metrics/{date}.counters.spendUserTokens_appcheck_missing
- ops_metrics/{date}.counters.spendUserTokens_rate_limited
- ops_metrics/{date}.counters.spendUserTokens_claims_fallback
- ops_metrics/{date}.counters.createBatchAiJob_unauthenticated
- ops_metrics/{date}.counters.createBatchAiJob_owner_path_denied
- ops_metrics/{date}.counters.createBatchAiJob_rate_limited
- ops_metrics/{date}.counters.createBatchAiJob_refund_openai_submission_failed

## 5) Ledger metadata invariants (pre-launch)

For each token spend in token_spend_ledger:

- metadata.spendAuthoritySource present
- metadata.authorizedAmount present
- metadata.operationType present when applicable
- metadata.serverTier present for spendUserTokens path

For batch refund records:

- metadata.refundReason = openai_submission_failed
- metadata.originalLedgerId present

## 6) Full Flutter-suite blocker status

Previous blocker status has been revalidated and is now closed in current repo state.

- flutter test test/services/enhanced_ai_api_service_safety_test.dart -> PASS

As of latest verification, this checklist no longer has an open compile blocker for the release-safety test lane.

## 7) Post-launch week-1 thresholds

Trigger immediate investigation if any condition is met:

- claims fallback counter > 5% of total spendUserTokens calls for 2 consecutive days
- createBatchAiJob_refund_openai_submission_failed > 2% of batch attempts
- appcheck_missing counters non-zero in production after launch day
- rate_limited counters spike > 3x day-over-day

## 8) Non-goals for this checklist

- No backend platform migration (InsForge/Supabase/VPS)
- No source-control actions
- No broad UI refactors

## 9) Secret hygiene guardrail (operational)

- Rotate/revoke any token exposed in terminal history or shared context exports.
- Do not place token values directly in command lines that persist in shell history.
- Prefer secret-manager backed environment loading and local `.env` sourcing patterns.
