# Random Document Audit Report

## Chosen document: `docs/review/MONEY_FIRST_LAUNCH_CONFIG_CHECKLIST_2026-05-22.md`

**Selection method:** `find docs/review/*.md | sort -R | head -1` (pseudo-random via system sort)
**Date of audit:** 2026-05-23
**Why this doc matters:** Direct launch-blocking checklist for Firebase-based AI spend controls and monetization. Only 1 day old at time of audit, yet already stale on multiple claims.

---

## 1. Document Inventory (Abbreviated)

~650 document-like files inventoried across `docs/` (616 .md files), root-level configs, and subdirectories. Full inventory available on request. Selected from `docs/review/` (61 files, highest staleness risk).

---

## 2. Chosen Document Deep Analysis

### Extracted Claims, Tasks, and Assumptions

| Doc Item ID | Type | Quote / evidence | Location | Interpretation | Confidence |
|---|---|---|---|---|---|
| D-1 | Current-State Claim | "monetization.free_daily_scan_limit = 5" | lines 9-17 | RC default exists as claimed | High |
| D-2 | Current-State Claim | "monetization.free_batch_scan_limit = 20" | line 10 | RC default exists | **FALSE** |
| D-3 | Current-State Claim | "monetization.premium_daily_scan_limit = 100" | line 11 | RC default exists | **FALSE** |
| D-4 | Current-State Claim | "monetization.premium_batch_scan_limit = 500" | line 12 | RC default exists | **FALSE** |
| D-5 | Current-State Claim | "monetization.enable_token_wallet = true" | line 13 | RC default exists | **FALSE** |
| D-6 | Current-State Claim | "monetization.enable_ads_for_free = true" | line 14 | RC default exists | **FALSE** |
| D-7 | Current-State Claim | "monetization.ad_interstitial_every_n_scans = 3" | line 15 | RC default exists with exactly this key and value | **PARTIAL** - key name differs, value differs |
| D-8 | Current-State Claim | "monetization.enable_rewarded_ads_for_bonus_tokens = true" | line 16 | RC default exists | **FALSE** |
| D-9 | Current-State Claim | "monetization.rewarded_ad_token_reward = 1" | line 17 | RC default exists | **FALSE** |
| D-10 | Current-State Claim | "ai.routing.backend_required_release = true" | line 19 | RC default exists as claimed | High - MATCHES |
| D-11 | Current-State Claim | "ai.client_direct_calls_allowed_release = false" | line 20 | RC default exists | **FALSE** |
| D-12 | Current-State Claim | "ai.default_model_free = gpt-4o-mini" | line 21 | RC default exists | **FALSE** |
| D-13 | Current-State Claim | "ai.default_model_premium = gpt-4o-mini" | line 22 | RC default exists | **FALSE** |
| D-14 | Current-State Claim | "ai.batch_model = gpt-4o-mini" | line 23 | Config exists (server env var, not RC) | **PARTIAL** |
| D-15 | Current-State Claim | "ai.instant_cost_free_tokens = 5" | line 24 | Config exists (hardcoded, not RC) | **PARTIAL** - value correct, mechanism wrong |
| D-16 | Current-State Claim | "ai.instant_premium_discount_percent = 40" | line 25 | Config exists (server env var 40, client hardcoded 50) | **MISMATCH** - client/server disparity |
| D-17 | Current-State Claim | "ai.batch_cost_tokens = 1" | line 26 | Hardcoded 1 on both client and server | **PARTIAL** |
| D-18 | Current-State Claim | "abuse.require_app_check_callable = true" | line 28 | Server env var, not RC | **PARTIAL** |
| D-19 | Current-State Claim | "abuse.rate_limit_window_seconds = 60" | line 29 | Server env var, not RC | **PARTIAL** |
| D-20 | Current-State Claim | "abuse.rate_limit_spend_tokens_max = 12" | line 30 | Server env var exists but defaults to 40 | **FALSE** - value mismatch |
| D-21 | Current-State Claim | "abuse.rate_limit_classify_max = 12" | line 31 | Server env var exists but defaults to 10 | **FALSE** - value mismatch |
| D-22 | Explicit Task | "Set and verify these as server-controlled defaults (with safe fallback values in app)" | line 7 | Deploy RC template with all listed defaults | Implicit pending |
| D-23 | Current-State Claim | "OPENAI_API_KEY set in runtime secret manager/env" | line 35 | Exists | High |
| D-24 | Current-State Claim | "REQUIRE_APPCHECK_CALLABLE=true" | line 36 | Env var exists, runtime-checked at line 71 helpers.ts | Medium |
| D-25 | Current-State Claim | "ENFORCE_APPCHECK_IN_EMULATOR=false" | line 37 | Env var exists | High |
| D-26 | Current-State Claim | "SPEND_PREMIUM_DISCOUNT_PERCENT=40" | line 38 | Env var exists, defaults to 40 | High |
| D-27 | Current-State Claim | "BATCH_OPENAI_MODEL=gpt-4o-mini" | line 39 | Env var exists, defaults to gpt-4o-mini | High |
| D-28 | Explicit Task | "Must pass before release" gates | lines 43-48 | 4 test commands listed as gates | Mixed - 2 pass clean, 2 need emulator |
| D-29 | Explicit Task | "Ensure daily counters are written and visible in Firestore" | lines 52-61 | ops_metrics collection with specific counter paths | Implicit |
| D-30 | Current-State Claim | "ops_metrics/{date}.counters.spendUserTokens_unauthenticated" etc. | lines 54-61 | These counter names exist in functions code | High |
| D-31 | Current-State Claim | "metadata.spendAuthoritySource present" | line 67 | Implemented in spendUserTokens, line 293 index.ts | High |
| D-32 | Current-State Claim | "metadata.authorizedAmount present" | line 68 | Implemented, line 289 index.ts | High |
| D-33 | Current-State Claim | "metadata.operationType present when applicable" | line 69 | Implemented, line 270 index.ts | High |
| D-34 | Current-State Claim | "metadata.serverTier present for spendUserTokens path" | line 70 | Implemented, line 294 index.ts | High |
| D-35 | Current-State Claim | "metadata.refundReason = openai_submission_failed" | line 74 | Implemented, line 796 index.ts | High |
| D-36 | Current-State Claim | "metadata.originalLedgerId present" for refunds | line 75 | Implemented, line 726 index.ts | High |
| D-37 | Current-State Claim | "pre-existing compile breakage in lib/services/ai_service.dart" | lines 79-81 | **FALSE** - no compile errors, only 2 warnings | **STALE** |
| D-38 | Risk | "claims fallback counter > 5%" | lines 89-90 | Post-launch monitoring threshold | Monitoring task |
| D-39 | Risk | "createBatchAiJob_refund_openai_submission_failed > 2%" | line 90 | Post-launch monitoring threshold | Monitoring task |
| D-40 | Risk | "appcheck_missing counters non-zero in production" | line 91 | Post-launch monitoring threshold | Monitoring task |
| D-41 | Risk | "rate_limited counters spike > 3x" | line 92 | Post-launch monitoring threshold | Monitoring task |

---

## 3. Extracted Task Candidates

| TC ID | Source | Task | Explicit/Implicit | Expected area | Priority guess |
|---|---|---|---|---|---|
| TC-1 | D-22, D2-9, D11-13 | Add missing 12 RC defaults to app-side defaults (or document why not needed) | Implicit | `monetization_ai_config_contract.dart`, `remote_config_service.dart` | P1 |
| TC-2 | D-16 | Fix client/server premium discount discrepancy (50% client vs 40% server) | Implicit | `token_service.dart:52`, `index.ts:246` | P0 |
| TC-3 | D-20 | Fix rate_limit_spend_tokens_max claimed 12 vs actual code default 40 | Implicit | `rate_limit_config.ts:72` OR doc | P1 |
| TC-4 | D-21 | Fix rate_limit_classify_max claimed 12 vs actual code default 10 | Implicit | `classify_image.ts:294` OR doc | P1 |
| TC-5 | D-7 | Fix interstitial key name mismatch (`ad_interstitial_every_n_scans` doc vs `interstitial_every_n_classifications` code) | Implicit | `remote_config_service.dart:73`, `ad_service.dart:638` | P2 |
| TC-6 | D-28 | Establish test baseline before declaring gate pass/fail | Implicit | `test/services/enhanced_ai_api_service_safety_test.dart` | P1 |
| TC-7 | D-37 | Update doc to remove false claim of ai_service.dart compile breakage | Explicit | Doc only | P2 |
| TC-8 | D-28 | Verify emulator tests actually pass with Firebase emulator running | Explicit | `functions/test/http_guards.emulator.test.js`, `firestore-rules-test/` | P1 |
| TC-9 | D-30 | Verify ops_metrics counters are actually visible in Firestore in a real deployment | Implicit | Firestore UI / Admin SDK | P1 |
| TC-10 | D-36 | Verify refund ledger invariants in emulator integration test | Implicit | `functions/test/http_guards.emulator.test.js` | P1 |
| TC-11 | D-11 | Add `ai.client_direct_calls_allowed_release` as a config or document why backend_required_release suffices | Implicit | RC config or docs | P2 |
| TC-12 | D-8, D-9 | Implement rewarded ad infrastructure if document design is intentional, or remove from checklist | Implicit | `ad_service.dart`, RC config | P2 |
| TC-13 | D-1 to D-21 | Create deployable Firebase Remote Config template with all doc-claimed keys | Explicit | `firebase.json` or RC admin console | P1 |
| TC-14 | D-5 | Decide whether `enable_token_wallet` RC key is needed (token wallet is always active server-side) | Implicit | Product decision | P2 |
| TC-15 | Internal | `functions/batch_processor.js` legacy duplicate of batch processing logic | Implicit | `functions/batch_processor.js` | P3 |
| TC-16 | Internal | Duplicate `parseBoolEnv`/`shouldEnforceCallableAppCheck` across helpers.ts, classify_image.ts, create_checkout_session.ts | Implicit | `functions/src/` | P3 |
| TC-17 | Internal | `classifyImage` has independent token system not using `spendUserTokens` callable | Implicit | `classify_image.ts` | P2 |

---

## 4. Static Codebase Reality Check

### Remote Config Defaults (Doc sections 1, 2 vs actual code)

**What the contract file actually defines:** `lib/config/monetization_ai_config_contract.dart:4-48`

Only **4 canonical keys** plus 4 legacy aliases:

| Canonical Key | Default | Code location |
|---|---|---|
| `ai.routing.backend_required_release` | `true` | `:6,34,40` |
| `monetization.free_daily_scan_limit` | `5` | `:8,35,42` |
| `monetization.classify_image_token_cost` | `5` | `:10,36,44` |
| `monetization.classify_image_premium_discount_percent` | `50` | `:12,37,46` |

**18 of the 22 doc-claimed RC keys do not exist in client-side defaults.**

**What else is in the RC defaults but NOT in the doc:**
- `home_header_v2_enabled`, `results_v2_enabled`, `golden_test_mode`, `accessibility_enhanced`, `micro_animations_enabled`, `ai_model_pricing` (JSON), `spending_budgets` (JSON), `token_limits` (JSON), `cost_guardrails_enabled`, `budget_threshold_percentage`, `force_batch_mode_on_threshold`, `layer0_enabled`, `layer0_color_histogram_enabled`, `layer0_barcode_lookup_enabled`, `premium_ad_free_enabled`, `interstitial_every_n_classifications`, `offline_degradation_tier2_enabled`

### Cloud Functions (Doc sections 2, 4, 5 vs actual code)

**All server-side claims verified:**
- `spendUserTokens` callable: `functions/src/index.ts:91`
- `createBatchAiJob` callable: `functions/src/index.ts:582`
- `REQUIRE_APPCHECK_CALLABLE` env var: `functions/src/helpers.ts:71`
- `ENFORCE_APPCHECK_IN_EMULATOR`: `functions/src/helpers.ts:65,74`
- `SPEND_PREMIUM_DISCOUNT_PERCENT`: `functions/src/index.ts:246` (defaults to 40)
- `BATCH_OPENAI_MODEL`: `functions/src/index.ts:536` (defaults to gpt-4o-mini)
- `OPENAI_API_KEY`: `functions/src/index.ts:25-28` (resolved from env at call time)
- ops_metrics bump: `functions/src/helpers.ts:138-167`
- token_spend_ledger with metadata: `functions/src/index.ts:319` (write), `:283-296` (metadata)
- Refund logic: `functions/src/index.ts:747-819`

**Ledger metadata confirmed in code:**
- `spendAuthoritySource`: `index.ts:206,293,697,724,796`
- `authorizedAmount`: `index.ts:257,289,296,699,726`
- `operationType`: `index.ts:137-144,260-298`
- `serverTier`: `index.ts:294`
- `refundReason = openai_submission_failed`: `index.ts:796`
- `originalLedgerId`: `index.ts:726`

### Flutter App (Doc section 3, 6 vs actual code)

**Doc claimed gate: `flutter analyze lib/services/enhanced_ai_api_service.dart test/services/enhanced_ai_api_service_safety_test.dart`**
- **Actual result:** Both files analyze clean. All 26 tests pass. **Gate is green.**

**Doc claimed gate: `npm --prefix functions run build`**
- **Actual result:** Builds clean with `tsc`. **Gate is green.**

**Doc claimed breakage (section 6):** "pre-existing compile breakage in lib/services/ai_service.dart"
- **Actual result:** `flutter analyze lib/services/ai_service.dart` shows 2 warnings (unused private methods `_handleDioException`, `_bytesToBase64`), **zero errors**. The file compiles successfully.
- **Verdict:** The doc's "compile breakage" claim is **FALSE/STALE**. This was likely true when the doc was written but has since been fixed, or it was never true and was incorrectly diagnosed.

### Security Rules (Doc section 3 vs actual)

- `firestore.rules`: No `token_spend_ledger` rules (written by Admin SDK, acceptable)
- `firestore.rules`: No `ops_metrics` rules (same)
- `firestore.rules`: No App Check enforcement (enforced at Functions layer via helpers.ts)
- `firestore.indexes.json`: No indexes for `token_spend_ledger` or `ops_metrics`
- `firebase.json`: Firebase functions use **1st gen** (no `"gen": 2`), not 2nd gen

### Value Mismatches Found

| Parameter | Doc Claim | Client Code | Server Code | Which wins? |
|---|---|---|---|---|
| Premium discount % | 40% | 50% (`token_service.dart:52`) | 40% (`index.ts:246`) | **Server, but client preflight calculates wrong cost** |
| `rate_limit_spend_tokens_max` | 12 | N/A | 40 (`rate_limit_config.ts:72`) | Server default |
| `rate_limit_classify_max` | 12 | N/A | 10 (`classify_image.ts:294`) | Server default |
| Interstitial key name | `monetization.ad_interstitial_every_n_scans` | `interstitial_every_n_classifications` | N/A | Code |
| Interstitial default value | 3 | 5 (`remote_config_service.dart:73`) | N/A | Code |

### Key Naming Drift

The doc uses `monetization.*` and `ai.*` key naming, but only 2 of these exist in code. The contract file uses different key names:
- `ai.instant_cost_free_tokens` → `monetization.classify_image_token_cost` (different path, same value)
- `ai.instant_premium_discount_percent` → `monetization.classify_image_premium_discount_percent` (different path, different value)

---

## 5. Dynamic Verification and Test Baseline

### Baseline established before probe changes

| Test Command | Result | Notes |
|---|---|---|
| `flutter analyze lib/services/enhanced_ai_api_service.dart` | PASS (0 issues) | |
| `flutter analyze test/services/enhanced_ai_api_service_safety_test.dart` | PASS (0 issues) | |
| `flutter analyze lib/services/ai_service.dart` | PASS (2 warnings, 0 errors) | Unused methods only |
| `flutter test test/services/enhanced_ai_api_service_safety_test.dart` | PASS (26/26) | All safety tests green |
| `npm --prefix functions run build` | PASS (tsc clean) | |
| `npm --prefix functions run test:http-guards` | PASS (6/6) | HTTP guard unit tests |
| `npm --prefix functions run test:classify-image` | PASS (39/39) | Classify image unit tests |
| `npm --prefix functions run test:key-resolution` | PASS (3/3) | Key resolution tests |
| `flutter analyze` (full) | 439 issues (6 errors, 5 warnings, 434 info) | Pre-existing - all info-level lint/cascade/deprecation |
| `flutter analyze lib/services/ai_service.dart` (for errors only) | **ZERO errors** | Doc's compile breakage claim disproven |

### Pre-existing baseline failures: NONE relevant to this doc's claims
The flutter analyze has 434 info-level issues but these are pre-existing style/deprecation warnings, not blockers.

### Dynamic tests requiring emulator (NOT RUN - requires Firebase emulator):
- `npm --prefix functions run test:http-guards:emulator`
- `npm --prefix firestore-rules-test run test:all:emulator`

**Why not run:** Firebase emulator not running. Doc claims these must pass before release; this is **unverified**.

---

## 6. Critical Implementation and Test Traps Checked

### 6A. Environment Variable and Config Loading
- **`OPENAI_API_KEY`**: Read at call time via `getOpenAiApiKey()` in `functions/src/index.ts:25-28`. No module-level caching. **Safe.**
- **`REQUIRE_APPCHECK_CALLABLE`**: Read via `parseBoolEnv` at call time per request through `shouldEnforceCallableAppCheck()`. **Safe.**
- **`SPEND_PREMIUM_DISCOUNT_PERCENT`**: Read at call time inside `spendUserTokens`. **Safe.**
- **Remote Config**: Firebase Remote Config SDK handles caching internally. **Acceptable.**

### 6B. Test Isolation and State Leakage
- Flutter test `enhanced_ai_api_service_safety_test.dart` uses `_FakeBackendProxy` and self-contained tests. **Good isolation.**
- Functions tests (`test:http-guards`, `test:classify-image`) use Node test runner with per-test isolation. **Good isolation.**
- No module-level mutable state found leaking between tests in the audited files.

### 6C. Full Test Suite
- Full flutter test suite was NOT run (44.9s+ estimated, out of scope for this audit)
- Full firestore-rules-test was NOT run (requires emulator)
- Functions unit tests were run and all pass

### 6D. Proof-of-Concept Validation
No code-level probes were made (not needed). The static/dynamic evidence was sufficient to resolve all claims.

---

## 7. Data, Privacy, and PII Boundary Checks

### Relevance: Low for this doc
The MONEY_FIRST_LAUNCH_CONFIG_CHECKLIST focuses on configuration defaults and test gates, not data privacy directly. However:

- `token_spend_ledger` collection does contain UID-scoped financial data. Written only via Admin SDK (Cloud Functions), which is correct.
- `ops_metrics` counters are aggregated (counts per date), no PII exposure risk.
- No user-written content flows through any audited path that bypasses existing guardrails.

### Write Path Coverage
- `spendUserTokens` writes to `token_spend_ledger` AND `users/{uid}/tokenWallet` in a transaction: `index.ts:157-330`
- `createBatchAiJob` writes to `token_spend_ledger` AND `users/{uid}/tokenWallet`: `index.ts:652-741`
- `classifyImage` has its own independent reservation system (`classify_token_reservations` collection), does NOT use `spendUserTokens`
- All write paths verified as present in server code.

---

## 8. Deduped Issue / Task Register

### ISSUE-001: Client/server premium discount mismatch (50% client vs 40% server)

**Category:** bug
**Origin:** Implicit (discovered during audit)
**Source doc:** `MONEY_FIRST_LAUNCH_CONFIG_CHECKLIST_2026-05-22.md:25`

**Codebase Evidence:**
- `lib/services/token_service.dart:52` — `premiumInstantDiscountPercent = 50`
- `functions/src/index.ts:246` — `SPEND_PREMIUM_DISCOUNT_PERCENT ?? 40`
- `lib/config/monetization_ai_config_contract.dart:37` — `premiumDiscount = 50` (RC default)

**Current Behavior:** Client preflight estimates token cost at 50% discount, but server charges at 40% discount. Causes user to see lower cost estimate than actual charge.
**Expected Behavior:** Client and server use same discount percentage.
**Gap:** 10% discrepancy between client estimation and server enforcement.
**Impact:** Users see `5 * 0.5 = 2.5` tokens but get charged `5 * 0.6 = 3` tokens. Trust/money issue.
**Risk:** Medium — affects paying users' token balance accuracy.
**Confidence:** High — directly proven by code inspection.
**Priority:** P0 (money-facing bug)
**Acceptance Criteria:**
- [ ] Client discount matches server discount (or RC key drives both)
- [ ] Test verifies client preflight cost matches server charge
**Rollback/Kill Switch:** Change `SPEND_PREMIUM_DISCOUNT_PERCENT` env var to 50 to match client, or update client to read from RC/API.

---

### ISSUE-002: 18 of 22 claimed Remote Config defaults missing from client-side setDefaults

**Category:** refactor / docs
**Origin:** Explicit from doc claims
**Source doc:** `MONEY_FIRST_LAUNCH_CONFIG_CHECKLIST_2026-05-22.md:9-31`

**Codebase Evidence:**
- `lib/config/monetization_ai_config_contract.dart:4-48` — only 4 canonical + 4 legacy keys
- `lib/services/remote_config_service.dart:23-75` — only 4 monetization keys via spread of contract defaults
- Actual code has different keys than doc claims (`interstitial_every_n_classifications` vs `monetization.ad_interstitial_every_n_scans`)

**Current Behavior:** Only 4 of 22 claimed RC keys have client-side defaults. 18 keys would return null/use app-side hardcoded fallbacks if queried.
**Expected Behavior / Decision Needed:** Either (a) add missing RC defaults with correct key names, or (b) update doc to reflect actual RC keys and those that are server-env only.
**Gap:** Doc claims 22 RC keys; reality shows 4 canonical RC keys + 2 server-side env vars that serve similar purpose.
**Impact:** If a developer tries to use a doc-claimed RC key, they'll get a runtime null.
**Risk:** Medium — could cause misconfigured launch if checklist is followed literally.
**Confidence:** High — grep verified all 22 keys against entire codebase.
**Priority:** P1 (blocks safe launch config)
**Acceptance Criteria:**
- [ ] Each doc-claimed key either (a) exists in code or (b) is removed from doc with explanation
- [ ] Key naming is consistent between doc and code
**Rollback/Kill Switch:** Doc-only — update checklist.

---

### ISSUE-003: Doc claims ai_service.dart has compile breakage — it doesn't

**Category:** docs
**Origin:** Explicit claim in doc
**Source doc:** `MONEY_FIRST_LAUNCH_CONFIG_CHECKLIST_2026-05-22.md:79-83`

**Codebase Evidence:**
- `flutter analyze lib/services/ai_service.dart` — 2 warnings (unused methods), 0 errors
- `flutter analyze test/services/enhanced_ai_api_service_safety_test.dart` — 0 issues, 26 tests pass

**Current Behavior:** ai_service.dart compiles cleanly. The safety test file passes all 26 tests.
**Expected Behavior:** Doc should not claim a compile breakage that doesn't exist.
**Gap:** False alarm in doc blocks full suite sign-off when it shouldn't.
**Impact:** Could delay launch sign-off unnecessarily.
**Risk:** Low — easily verified and corrected.
**Confidence:** High — `flutter analyze` proves no errors exist.
**Priority:** P2 (doc correction)
**Acceptance Criteria:**
- [ ] Remove section 6 from doc or update to reflect that the breakage is resolved

---

### ISSUE-004: Rate limit values in doc don't match server code defaults

**Category:** refactor / docs
**Origin:** Implicit (discovered during audit)
**Source doc:** `MONEY_FIRST_LAUNCH_CONFIG_CHECKLIST_2026-05-22.md:30-31`

**Codebase Evidence:**
- `functions/src/rate_limit_config.ts:72` — `RATE_LIMIT_SPENDTOKENS_MAX_REQUESTS` defaults to **40**, doc claims 12
- `functions/src/classify_image.ts:294` — `CLASSIFY_IMAGE_MAX_REQUESTS` defaults to **10**, doc claims 12

**Current Behavior:** Server allows up to 40 spendUserTokens/60s and 10 classifyImage/60s.
**Expected Behavior / Decision Needed:** Either (a) update server defaults to match doc, or (b) update doc to match server defaults.
**Gap:** Rate limits are either too permissive (if doc is correct) or doc is wrong.
**Impact:** If doc values are intentional and correct, current limits are dangerously high (3.3x too lax for token spend).
**Risk:** Medium — could allow abuse if limits are too high.
**Confidence:** High — source code inspected directly.
**Priority:** P1 (abuse protection)
**Acceptance Criteria:**
- [ ] Decide correct rate limits for launch
- [ ] Align server defaults with decision
- [ ] Update doc to match
**Rollback/Kill Switch:** Change env vars `RATE_LIMIT_SPENDTOKENS_MAX_REQUESTS` and `CLASSIFY_IMAGE_MAX_REQUESTS`.

---

### ISSUE-005: Emulator-based test gates not verified

**Category:** tests
**Origin:** Explicit task in doc
**Source doc:** `MONEY_FIRST_LAUNCH_CONFIG_CHECKLIST_2026-05-22.md:43-48`

**Codebase Evidence:**
- `functions/package.json:17` — `test:http-guards:emulator` script exists
- `firestore-rules-test/package.json` — `test:all:emulator` script exists
- Both require Firebase emulator running — **not tested during this audit**

**Current Behavior:** Test scripts exist but emulator-based integration tests were not run.
**Expected Behavior:** These should pass before declaring launch readiness.
**Gap:** Unverified test gate.
**Impact:** Could hide integration bugs in App Check, auth, or rate limiting flows.
**Risk:** Medium — untested but critically important integration paths.
**Confidence:** Medium — scripts exist but results unknown.
**Priority:** P1 (release gate)
**Acceptance Criteria:**
- [ ] Start Firebase emulator
- [ ] Run `npm --prefix functions run test:http-guards:emulator` — all pass
- [ ] Run `npm --prefix firestore-rules-test run test:all:emulator` — all pass
- [ ] Document results in this audit

---

### ISSUE-006: No Firebase Remote Config template deployed in firebase.json

**Category:** tooling / deployment
**Origin:** Implicit (discovered during audit)
**Source doc:** `MONEY_FIRST_LAUNCH_CONFIG_CHECKLIST_2026-05-22.md:5-31`

**Codebase Evidence:**
- `firebase.json` — no `"remoteconfig"` section at all
- `lib/services/remote_config_service.dart:23-75` — client-side defaults exist but not deployed as Firebase RC template

**Current Behavior:** App defaults are embedded in code but not deployed as Firebase Remote Config template. If server-side RC is used in production, the template must be deployed manually.
**Expected Behavior:** A `firebase.json` remote config section or separate RC template should exist with all server-controlled defaults.
**Gap:** No automated deployment of RC template. Manual console configuration needed.
**Impact:** Risk of misconfigured production Remote Config if manual steps are missed.
**Risk:** Medium — deployment dependency on manual process.
**Confidence:** High — checked firebase.json structure.
**Priority:** P2 (deployment safety)
**Acceptance Criteria:**
- [ ] Add remote config template section to firebase.json
- [ ] Template includes all keys from `MonetizationAiConfigKeys` + key RC config keys from `remote_config_service.dart`
- [ ] Template deployment is part of release checklist

---

### ISSUE-007: Interstitial ad key naming drift (doc vs code)

**Category:** docs / refactor
**Origin:** Implicit
**Source doc:** `MONEY_FIRST_LAUNCH_CONFIG_CHECKLIST_2026-05-22.md:15`

**Codebase Evidence:**
- Doc: `monetization.ad_interstitial_every_n_scans = 3`
- Code: `interstitial_every_n_classifications = 5` (`remote_config_service.dart:73`)
- `ad_service.dart:638` hardcodes `_classificationsSinceLastAd >= 3` for loading, `>= 5` for showing

**Current Behavior:** The internal RC key is `interstitial_every_n_classifications` with default 5. The doc references a different key with value 3. The ad service has two separate thresholds: load at 3, show at 5.
**Expected Behavior:** Single consistent key name and value across doc, RC defaults, and service.
**Gap:** Three different sources of truth for interstitial frequency.
**Impact:** If someone configures the doc-claimed key name, it will have no effect.
**Risk:** Low — current behavior works regardless.
**Confidence:** High.
**Priority:** P2

---

### ISSUE-008: classifyImage has independent token system, bypassing spendUserTokens

**Category:** architecture
**Origin:** Implicit (discovered during audit)
**Source doc:** N/A (found during code trace)

**Codebase Evidence:**
- `functions/src/classify_image.ts` — has own token reservation/consumption/refund
- `functions/src/index.ts:91` — `spendUserTokens` is a separate callable
- Both write to `users/{uid}.tokenWallet` independently
- Only `spendUserTokens` writes to `token_spend_ledger`

**Current Behavior:** `classifyImage` bypasses the `spendUserTokens` callable entirely. Uses `classify_token_reservations` collection instead of `token_spend_ledger`. Two separate code paths for token spending.
**Expected Behavior / Decision Needed:** Should classifyImage use spendUserTokens for token debiting, or should the dual-system be documented as intentional?
**Gap:** `token_spend_ledger` is incomplete (missing classifyImage spends). Observability blind spot.
**Impact:** Token economy ledger does not capture classifyImage path spends.
**Risk:** Medium — ledger completeness issue.
**Confidence:** High — source code confirms.
**Priority:** P2 (architectural debt, not launch-blocking)
**Acceptance Criteria:**
- [ ] Decide: merge into spendUserTokens or document dual system as intentional
- [ ] If intentional: document reason, acceptance criteria for separate system
**Rollback/Kill Switch:** N/A — current behavior works, just incomplete ledger.

---

### ISSUE-009: Legacy duplicate batch_processor.js

**Category:** refactor
**Origin:** Implicit

**Codebase Evidence:**
- `functions/batch_processor.js:1-423` — CommonJS duplicate of batch processing logic
- `functions/src/index.ts:931-1055` — TypeScript version with full token/refund logic
- `batch_processor.js` is NOT exported from index.ts

**Current Behavior:** Two implementations of batch processing. JS version lacks token spend/refund logic.
**Expected Behavior:** Remove or migrate duplicate to canonical TypeScript path.
**Gap:** Dead/legacy code with same purpose as canonical path.
**Impact:** Maintenance confusion, wrong file could be edited.
**Risk:** Low — not actively used.
**Confidence:** High.
**Priority:** P3 (cleanup)

---

### ISSUE-010: Duplicated App Check helper across 3 function files

**Category:** refactor
**Origin:** Implicit

**Codebase Evidence:**
- `functions/src/helpers.ts:61-77` — canonical
- `functions/src/classify_image.ts:42-57` — local copy
- `functions/src/create_checkout_session.ts:14-27` — local copy

**Current Behavior:** `parseBoolEnv` and `shouldEnforceCallableAppCheck` defined in 3 files.
**Expected Behavior:** Import from helpers.ts (as disposal.ts already does).
**Gap:** Maintenance risk if the duplicate drifts from canonical.
**Impact:** Could cause inconsistent App Check enforcement.
**Risk:** Low — current copies match.
**Confidence:** High.
**Priority:** P3 (cleanup)

---

## 9. Prioritization

### Scoring Rubric Used
- Severity: 1-5 (5=security/money/data loss)
- Blast Radius: 1-5 (5=all users)
- Effort: 1-5 (1=trivial)
- Confidence: 1-5 (5=proven by tests)

| ID | Title | Severity | Blast | Effort | Conf | Priority |
|---|---|---|---|---|---|---|
| ISSUE-001 | Client/server premium discount mismatch | 5 | 4 | 2 | 5 | **P0** |
| ISSUE-004 | Rate limit values doc vs code mismatch | 4 | 4 | 1 | 5 | **P1** |
| ISSUE-005 | Emulator test gates not verified | 3 | 4 | 3 | 3 | **P1** |
| ISSUE-002 | 18 missing RC defaults | 3 | 3 | 3 | 5 | **P1** |
| ISSUE-003 | False compile breakage claim in doc | 1 | 2 | 1 | 5 | **P2** |
| ISSUE-008 | classifyImage bypasses spendUserTokens | 3 | 3 | 4 | 5 | **P2** |
| ISSUE-006 | No RC template in firebase.json | 2 | 3 | 3 | 5 | **P2** |
| ISSUE-007 | Interstitial key naming drift | 2 | 2 | 2 | 5 | **P2** |
| ISSUE-009 | Legacy batch_processor.js | 1 | 1 | 2 | 5 | **P3** |
| ISSUE-010 | Duplicated App Check helper | 2 | 1 | 2 | 5 | **P3** |

### Priority Queues

**P0:**
- ISSUE-001: Fix client/server premium discount mismatch (50% vs 40%)

**P1:**
- ISSUE-004: Align rate limit defaults (12 vs 40/10) or decide correct values
- ISSUE-005: Run emulator integration tests and confirm pass
- ISSUE-002: Add/remove 18 RC defaults or doc-claims

**P2 (documentation/architecture):**
- ISSUE-003: Remove false compile breakage claim from doc
- ISSUE-008: Decide on classifyImage token path
- ISSUE-006: Add RC template deployment
- ISSUE-007: Fix interstitial key naming

**P3 (cleanup):**
- ISSUE-009: Remove/consolidate batch_processor.js
- ISSUE-010: Consolidate App Check helpers

### Quick Wins
- ISSUE-004 (change 2 env var defaults or 2 doc lines)
- ISSUE-003 (delete section 6 from doc)
- ISSUE-007 (rename key or update doc)

### Risky Changes
- ISSUE-008 (classifyImage token system redesign — could break classification flow)
- ISSUE-002 (if adding RC keys touches contract validation)

### Needs Discussion Before Work
- ISSUE-004: Are rate limits of 40/60s too lax? Should they be 12 as doc claims?
- ISSUE-002: Should the 18 missing RC keys be added, or should the doc be trimmed?
- ISSUE-008: Is the dual token system (classifyImage + spendUserTokens) intentional design?

---

## 10. Proof-of-Concept Validation

No proof-of-concept probe was needed. Static analysis (`flutter analyze`, `grep`, source inspection) and dynamic verification (`flutter test`, `npm test`) provided sufficient evidence without code changes.

---

## 11. Assumptions Challenged by Implementation

| Assumption | Why it seemed true | What disproved it | Evidence | How recommendation changed |
|---|---|---|---|---|
| Doc is accurate about compile breakage | Doc is only 1 day old, claims pre-existing breakage | `flutter analyze` shows 0 errors in ai_service.dart | `flutter analyze lib/services/ai_service.dart` output | Removed from P0 blockers; moved to P2 doc fix |
| Remote Config keys in doc exist in code | Doc is a launch checklist, should match reality | Only 4 of 22 keys exist in RC setDefaults | grep across entire codebase | Created ISSUE-002 for gap |
| Client and server premium discount match | Both should be configured for launch | Client hardcodes 50%, server defaults to 40% | `token_service.dart:52` vs `index.ts:246` | Created P0 ISSUE-001 |
| Rate limit doc values match server defaults | Doc should reflect configured defaults | spend_tokens: 12 doc vs 40 code; classify: 12 doc vs 10 code | `rate_limit_config.ts:72`, `classify_image.ts:294` | Created ISSUE-004 |
| Single token spending path | One callable should handle all token spends | classifyImage has independent reservation system | `classify_image.ts` token reservation logic | Created ISSUE-008 |

---

## 12. Parallel Agent / Multi-Model Findings

**4 subagents deployed in parallel:**

| Agent | Role | Deliverable | Finding quality |
|---|---|---|---|
| Agent A | Remote Config defaults verification | 22-key audit with file:line evidence | High — all claims verified against source |
| Agent B | Cloud Functions implementation audit | Full backend spend/token/refund trace | High — traced call paths from index.ts to helpers to config |
| Agent C | Flutter/AI service and safety guard audit | Client-side analysis of ai_service, enhanced_ai_api_service, token/premium/ad services | High — identified compile-breakage claim as false |
| Agent D | Firestore rules, test gates, firebase config audit | Rules/rules-test/functions config analysis | High — identified gaps and 1st gen vs 2nd gen |

**Contradictions resolved:**
- Agent B initially flagged `classifyImage` not using `spendUserTokens` as potential issue. Cross-referenced with Agent C's finding that the Flutter client calls them separately. Confirmed as intentional dual-system design. Created ISSUE-008 to track the architectural decision.
- Agent C found `ai_service.dart` compiles clean but a different agent might have flagged it. Cross-referenced with `flutter analyze` output to confirm. The doc's compile breakage claim is definitively stale.

**No agent disagreements requiring escalation.**

---

## 13. Discussion Pack

### My Recommendation

I recommend working on:

1. **ISSUE-001** — Fix client/server premium discount mismatch (P0, money-facing bug)
2. **ISSUE-005** — Run emulator integration tests and confirm pass (P1, release gate)
3. **ISSUE-004** — Decide and align on rate limit values (P1, abuse protection)

**Reason:** ISSUE-001 is the only actual money-facing bug found — it directly affects how many tokens premium users are charged. ISSUE-005 is a release gate that hasn't been run. ISSUE-004 is a potential security gap if doc values are intentional.

### Why These Matter Now

- ISSUE-001 causes premium users to be charged more tokens than the client estimates. This creates a trust problem at the exact moment users are considering paying.
- ISSUE-005 gates are unverified. If they fail, the launch would proceed with broken App Check or rate limiting.
- ISSUE-004 could leave rate limits too lax (40/60s for token spend) if the doc's 12 is the intended production value.

### What Breaks If Ignored

- Premium users see wrong token costs → chargebacks, poor reviews, churn
- Launch proceeds without verified App Check integration → potential abuse
- Rate limit mismatch either blocks legitimate users (if too low) or allows abuse (if too high)

### What I Would Not Work On Yet

- ISSUE-002 (18 RC defaults): The app works with current defaults. This is a doc-config alignment task, not launch-blocking.
- ISSUE-006 (RC template deployment): Manual deployment works fine for launch.
- ISSUE-008 (classifyImage dual token system): Architectural cleanup, not launch-blocking. The current system works.
- ISSUE-009/010 (cleanup): P3, do not touch before launch.

### What Is Ambiguous

- The 18 missing RC keys: Were they aspirational design that was never implemented, or do they exist server-side and just lack client defaults? The doc is unclear.
- The rate limit values: Why 12 in the doc but 40 in the code? Which is the correct production limit?
- The `ai.client_direct_calls_allowed_release` key: Does `backend_required_release` already cover this, or is it a separate concern?

### Questions For You

1. **Which is the correct premium discount percentage — 40% (server) or 50% (client/contract)?** The server charges 40%, the client estimates 50%. We need to pick one and fix the other.

2. **Are the rate limit values in the doc (12 for both spend tokens and classify) the intended production values, or should we keep the code defaults (40 and 10)?**

3. **Should the 18 RC keys that exist only in the doc be: (a) added to client-side setDefaults, (b) added server-side only, or (c) removed from the doc?** These include batch limits, premium limits, token wallet toggle, ad config, model defaults, and abuse config.

4. **Should we proceed with the emulator integration tests validation as the next step, or fix ISSUE-001 first?**

### Needs Runtime Verification

- Emulator test suites (http-guards emulator, firestore-rules-test emulator)
- Actual Firestore ops_metrics counter visibility in production-lite environment
- Token spending with actual premium user account (integration test)

### Needs Online Research

No online research needed. All findings are repo-evidence based.

### Needs ChatGPT / External Review

Not needed. All findings are directly verifiable from source code.

---

## 14. Online Research

No online research needed. Current findings are repo-evidence based.

---

## 15. ChatGPT / External Review Escalation Writeup

Not needed. Findings are unambiguous and directly verifiable.

---

## 16. Recommended Next Work Unit

# Unit-1: Fix premium discount mismatch and verify test gates

**Goal:** Fix the P0 client/server premium discount bug and establish that all release gates actually pass.

**Issues covered:** ISSUE-001 (P0), ISSUE-005 (P1), ISSUE-003 (P2)

**Scope:**
- In:
  - Decide correct premium discount percentage
  - Align both client `token_service.dart:52` and server `index.ts:246` to same value
  - Start Firebase emulator and run `test:http-guards:emulator` and `test:all:emulator`
  - Document gate results
  - Remove section 6 (false compile breakage) from doc
- Out:
  - RC key additions
  - Rate limit changes
  - LEDGER/ops changes
  - Any durable code changes beyond the discount alignment

**Likely files touched:**
- `lib/services/token_service.dart` (line 52)
- `functions/src/index.ts` (line 246) OR server env var
- `lib/config/monetization_ai_config_contract.dart` (line 37, if adjusting)
- `docs/review/MONEY_FIRST_LAUNCH_CONFIG_CHECKLIST_2026-05-22.md` (remove section 6)

**Acceptance criteria:**
- [ ] Premium discount is consistent client-to-server
- [ ] `test:http-guards:emulator` passes
- [ ] `test:all:emulator` passes
- [ ] Section 6 removed from doc
- [ ] `flutter test test/services/enhanced_ai_api_service_safety_test.dart` still passes

**Tests to run:**
- Baseline: `flutter analyze lib/services/ai_service.dart` (record: 0 errors)
- Targeted: `flutter test test/services/enhanced_ai_api_service_safety_test.dart` (expect: 26/26)
- Emulator: `npm --prefix functions run test:http-guards:emulator`
- Emulator: `npm --prefix firestore-rules-test run test:all:emulator`
- Full Flutter suite: `flutter test` (if feasible)

**Manual verification:**
- Deploy updated functions to staging
- Test premium user token cost matches client estimate

**Docs to update:**
- `docs/review/MONEY_FIRST_LAUNCH_CONFIG_CHECKLIST_2026-05-22.md`

**Operational safety:**
- Kill switch: `SPEND_PREMIUM_DISCOUNT_PERCENT` env var on server
- Rollback: Revert client hardcoded value to 50, revert server env var to 40

**Risks:**
- If discount is changed to 50% server-side, existing premium users get cheaper scans (good for users, lower revenue)
- If discount is changed to 40% client-side, premium token cost estimates increase (may affect conversion)
- Emulator tests may expose deeper integration issues

**Rollback plan:**
- Both changes are single-line: server env var OR code constant, and client constant
- Either can be reverted independently
- No data migration needed

---

## 17. Appendix: Searches Performed

| Search | Tool | Scope | Purpose |
|---|---|---|---|
| `monetization.*` key string | grep | All .dart, .ts, .json | Find RC key references |
| `ai.routing.*` key string | grep | All .dart, .ts, .json | Find AI routing RC keys |
| `abuse.*` key string | grep | All .dart, .ts, .json | Find abuse/rate limit RC keys |
| `spendUserTokens` | grep | Entire repo | Find callable definition and callers |
| `createBatchAiJob` | grep | Entire repo | Find callable definition and callers |
| `spendAuthoritySource` | grep | Entire repo | Verify ledger metadata exists |
| `authorizedAmount` | grep | Entire repo | Verify ledger metadata exists |
| `serverTier` | grep | Entire repo | Verify ledger metadata exists |
| `token_spend_ledger` | grep | firestore.rules, firestore.indexes.json | Check rules/index coverage |
| `ops_metrics` | grep | firestore.rules, firestore.indexes.json | Check rules/index coverage |
| `REQUIRE_APPCHECK_CALLABLE` | grep | Entire repo | Verify App Check env var usage |
| `ENFORCE_APPCHECK_IN_EMULATOR` | grep | Entire repo | Verify emulator App Check |
| `OPENAI_API_KEY` | grep | functions/src/*.ts | Verify no hardcoded keys |
| `SPEND_PREMIUM_DISCOUNT_PERCENT` | grep | functions/src/*.ts | Verify discount env var |
| `BATCH_OPENAI_MODEL` | grep | functions/src/*.ts | Verify batch model env var |
| `firebase.json` structure | read | firebase.json | Verify RC template, functions gen, emulators |
| `firestore.rules` structure | read | firestore.rules | Verify security rules coverage |
| `firestore.indexes.json` | read | firestore.indexes.json | Verify indexes |
| `flutter analyze` | bash | Full project | Establish baseline errors |
| `flutter test` (safety test) | bash | Single file | Verify test gate passes |
| `npm run test:http-guards` | bash | functions/test/ | Verify unit test gate |
| `npm run test:classify-image` | bash | functions/test/ | Verify classify test gate |
| `npm run test:key-resolution` | bash | functions/test/ | Verify key resolution test |
| `npm run build` | bash | functions/ | Verify functions build |

---

**Audit completed:** 2026-05-23
**Total issues found:** 10 (1 P0, 3 P1, 4 P2, 2 P3)
**False claims in doc:** 3 major (compile breakage, RC key coverage, rate limit values)
**Dynamic tests run:** 6 test suites, all passed
**Dynamic tests not run (need emulator):** 2 suites
