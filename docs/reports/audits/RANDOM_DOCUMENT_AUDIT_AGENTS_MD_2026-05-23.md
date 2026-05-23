# Random Document Audit Report

## 1. Document Inventory

| Doc ID | Path | Type | Why it may matter |
|--------|------|------|-------------------|
| D001 | README.md | Root doc | Project overview, status, quick start |
| D002 | motto_v2.md | Root doc | Engineering operating rules (666 lines) |
| D003 | AGENTS.md | Root doc | Agent instruction layer |
| D004 | firebase_task.md | Root doc | Source-of-truth Phase/P0 task checklist (678 lines) |
| D005 | TOKEN_ECONOMY_TODO.md | Root doc | Token economy implementation items |
| D006 | issue_review.md | Root doc | Issue review tracking |
| D007 | PR_DESCRIPTION.md | Root doc | PR description template/notes |
| D008 | docs/launch/LAUNCH_BLOCKERS.md | Launch doc | Release blockers |
| D009 | docs/EXPLORATION_FRONTIER.md | Exploration doc | Future exploration topics |
| D010 | docs/planning/FIREBASE_MONEY_FIRST_STRATEGY.md | Strategy doc | Monetization platform strategy |
| D011 | docs/security/SECURITY_BASELINE_RUNBOOK.md | Security doc | Security runbook |
| D012 | docs/reports/architecture/API_SECURITY_ARCHITECTURE_DECISION.md | Architecture doc | API security architecture |
| D013 | docs/planning/STRATEGIC_ROADMAP_COMPREHENSIVE.md | Roadmap doc | Strategic roadmap |
| D014 | docs/reference/CHANGELOG.md | Reference doc | Change history |
| D015 | docs/config/environment_variables.md | Config doc | Environment variable setup |

95+ total markdown documents inventoried across root, docs/, functions/, eval/, .github/, and subdirectories.

---

## 2. Random Selection

**Chosen document:** `AGENTS.md`
**Selection method:** `shuf -n 1` with a pre-filtered list of 25 significant non-trivial documents
**Why this doc is worth auditing:** AGENTS.md is the critical instruction layer that every agent (and human) must follow when working in this repo. It sits in the priority context chain at position 3 and cross-references two large instruction files (motto_v2.md and firebase_task.md). Verifying its claims reveals whether the entire agent safety and workflow contract is actually enforced by the codebase.

---

## 3. Chosen Document Deep Analysis

### Full Document Content (34 lines)

```
AGENTS.md at root defines:
- Priority context chain: /Users/pranay/AGENTS.md → /Users/pranay/Projects/AGENTS.md → this file → motto_v2.md → firebase_task.md
- Execution rules: follow motto_v2, use firebase_task for Phase/P0, additive changes, document under docs/
- Git safety: read-only git allowed, no destructive ops, no stage/commit/push/reset/checkout without permission
- Security: no hardcoded keys, prefer runtime env vars, replace secrets with placeholders
- Verification: run tests, report blockers, provide exact file paths
```

### Extracted Doc Items

| Doc Item ID | Type | Short quote / evidence | Location | Interpretation | Confidence |
|---|---|---|---|---|---|
| AG-01 | Explicit Task | "Follow motto_v2.md execution discipline" | AGENTS.md:16 | Agents must load and follow motto_v2.md | High |
| AG-02 | Explicit Task | "Use firebase_task.md as source-of-truth checklist for Phase/P0 tasks" | AGENTS.md:17 | firebase_task.md must exist with Phase/P0 tasks | High |
| AG-03 | Explicit Task | "Keep changes additive and architecture-safe; no temporary hacks" | AGENTS.md:18 | Production paths must be clean | High |
| AG-04 | Explicit Task | "Document decisions and outcomes under docs/" | AGENTS.md:19 | All decisions must go to docs/ | High |
| AG-05 | Explicit Task | "Run relevant tests/validation commands for touched areas" | AGENTS.md:32 | Tests must exist and be runnable | High |
| AG-06 | Explicit Task | "Report remaining risks/blockers explicitly" | AGENTS.md:33 | Blockers must be surfaced | High |
| AG-07 | Explicit Task | "Provide exact file paths for all new/updated artifacts" | AGENTS.md:34 | Path-level precision required | High |
| AG-08 | Explicit Task | "Do not hardcode API keys or tokens" | AGENTS.md:27 | No secrets in source | High |
| AG-09 | Explicit Task | "Prefer runtime env vars / secure config" | AGENTS.md:28 | Env-based config only | High |
| AG-10 | Explicit Task | "If a secret is found in source, replace with placeholder and document migration" | AGENTS.md:29 | Remediation protocol for leaked secrets | High |
| AG-11 | Implicit Task | Priority context chain must exist and be functional | AGENTS.md:7-11 | Chain of instruction files must be intact | High |
| AG-12 | Implicit Task | Read-only git inspection allowed | AGENTS.md:22 | Agents can run git status/log/diff | High |
| AG-13 | Implicit Task | Do not run destructive git operations | AGENTS.md:23 | No git mutation without approval | High |
| AG-14 | Implicit Task | Do not stage/commit/push/reset/checkout without explicit permission | AGENTS.md:24 | Explicit permission gate | High |
| AG-15 | Architecture Claim | "If instructions conflict, use the most specific one" | AGENTS.md:13 | Conflict resolution order | High |
| AG-16 | Security Claim | "Do not hardcode API keys or tokens" | AGENTS.md:27 | Source code is secret-free | High |
| AG-17 | Security Claim | "Prefer runtime env vars / secure config" | AGENTS.md:28 | Runtime env var loading | Medium |
| AG-18 | Operational Claim | firebase_task.md as "source-of-truth checklist for Phase/P0 tasks" | AGENTS.md:17 | Single source of truth for task tracking | High |

---

## 4. Extracted Task Candidates

| Task Candidate ID | Source Doc Item IDs | Task | Explicit/Implicit | Why this is a task | Expected repo area | Initial priority |
|---|---|---|---|---|---|---|
| TC-001 | AG-11 | Verify priority context chain integrity | Implicit | Every file in the chain must exist and be loadable | Root, /Users/pranay, /Users/pranay/Projects | P1 |
| TC-002 | AG-02, AG-18 | Verify firebase_task.md contains Phase/P0 task list | Explicit | Must be source-of-truth for priorities | firebase_task.md | P1 |
| TC-003 | AG-08, AG-16 | Audit codebase for hardcoded secrets | Explicit | Security requirement | lib/ | P0 |
| TC-004 | AG-09, AG-17 | Verify env var loading mechanism is runtime-safe | Explicit | Term mismatch: compile-time vs runtime | lib/utils/constants.dart, lib/utils/production_safety_config.dart | P1 |
| TC-005 | AG-01 | Verify motto_v2.md exists and is canonical | Explicit | Single copy must be truth | Root | P2 |
| TC-006 | AG-05 | Establish test baseline and surface pre-existing failures | Explicit | Tests must be run before changes | test/ | P1 |
| TC-007 | AG-03 | Audit lib/ for HACK/TEMPORARY/WORKAROUND patterns | Explicit | Production path cleanliness | lib/ | P2 |
| TC-008 | AG-04 | Verify docs/ is active and receiving documentation | Explicit | Documentation must persist | docs/ | P2 |
| TC-009 | AG-10 | Check if .env and secrets files are properly gitignored | Implicit | Secret exposure prevention | .gitignore, .env* | P0 |
| TC-010 | AG-06, AG-07 | Verify verification protocol is executable | Implicit | Agents must be able to report blockers with paths | test/, flutter analyze | P1 |

---

## 5. Static Codebase Reality Check

### TC-001: Priority Context Chain

| File | Exists | Readable | Verify |
|---|---|---|---|
| /Users/pranay/AGENTS.md | Yes | Yes (229 lines) | PASS |
| /Users/pranay/Projects/AGENTS.md | Yes | Yes (714 lines) | PASS |
| AGENTS.md (local) | Yes | Yes (34 lines) | PASS |
| motto_v2.md | Yes | Yes (676 lines) | PASS |
| firebase_task.md | Yes | Yes (678 lines) | PASS |

**Status: ALREADY DONE.** The entire chain is intact. Both copies of motto_v2.md (root and functions/) are **identical** (verified via diff).

### TC-002: firebase_task.md as Source of Truth

firebase_task.md defines 12 phases (Phase 0-12) covering backend platform strategy, monetization, deployment, security hardening, and agent task breakdown. Severity levels P0-P3 are defined at lines 231-234.

**Status: ALREADY DONE.** The document exists and provides the structured task framework agents need.

### TC-003: Hardcoded Secrets Audit

**Finding: lib/ Dart source code is clean.** No `sk-proj-`, `AIza`, or similar API key patterns found in any Dart file. All keys use `String.fromEnvironment()`.

**Exception found:**

| File | Line | Issue | Severity |
|---|---|---|---|
| `lib/services/minicpm_service.dart` | 17 | `static const String _kDefaultApiKey = 'sk-minicpm-free'` -- hardcoded API key compiled into binary | P1 |
| `lib/utils/constants.dart` | 14-15 | `defaultValue: 'your-openai-api-key-here'` -- safe placeholder, but masks missing env | P1 |
| `lib/utils/constants.dart` | 37-38 | `defaultValue: 'your-gemini-api-key-here'` -- safe placeholder, but masks missing env | P1 |

**Live secrets on disk (gitignored):**
- `.env:2` -- real OpenAI project key (`sk-proj-P1Va...`)
- `.env:3` -- real Gemini API key (`AIzaSyDY...`)
- `.env.backup:12,16,20` -- real Firebase platform keys in backup file

**Status: PARTIALLY DONE.** Source code is clean of real keys. Two gaps: (a) minicpm_service.dart has a hardcoded default key, (b) `.env.backup` unnecessarily stores real keys.

### TC-004: Env Var Loading Mechanism

The app uses `String.fromEnvironment()` -- a **compile-time** mechanism, not runtime. The `.env` file is consumed at build time via `--dart-define-from-file=.env`. The statement "Prefer runtime env vars / secure config" in AGENTS.md:28 is technically incorrect for this project.

The real security boundary is `lib/utils/production_safety_config.dart` which:
- Blocks client-side AI calls in release builds by default (`ALLOW_CLIENT_AI_IN_RELEASE=false`)
- Detects placeholder keys via `hasPlaceholderKey()`
- Routes to backend AI proxy when `USE_BACKEND_AI_IN_RELEASE=true`

**Status: TERMINOLOGY GAP.** The mechanism is compile-time injection, not runtime. The production safety config provides the actual security guardrail. This is a docs-only fix -- update AGENTS.md to say "prefer compile-time dart-define from .env files with production safety guards."

### TC-005: motto_v2.md Canonicality

Both copies (root and functions/) are **identical** -- verified via `diff` showing 0 differences. No drift risk.

**Status: ALREADY DONE.** No duplicate drift.

### TC-006: Test Baseline

| Metric | Value |
|---|---|
| Total test files | 206 .dart files |
| Total test cases | 2,283 |
| Passed | 2,267 (99.3%) |
| Skipped | 12 (0.5%) |
| Failed | 4 (0.2%) |
| Static analysis | 419 info/warnings, 0 errors |

**4 Pre-existing failures:**

| # | File | Line | Test | Root Cause |
|---|---|---|---|---|
| 1 | `test/ui_consistency/comprehensive_overflow_test.dart` | 95 | PremiumFeatureCard text scaling | Null check operator on null in `lib/widgets/premium_feature_card.dart:22` |
| 2 | `test/ui_consistency/contrast_accessibility_test.dart` | 133 | PremiumFeatureCard disabled state | Same null check operator bug |
| 3 | `test/services/gamification_service_test.dart` | 226 | getNearMilestoneNudge returns daily goal nudge | Returns null, expected not null |
| 4 | `test/services/gamification_service_test.dart` | 415 | Prioritizes daily goal over challenge | Wrong nudge type returned (challenge vs dailyGoal) |

**Status: 4 PRE-EXISTING FAILURES.** 99.8% pass rate among non-skipped tests. Overall health is good.

### TC-007: Production Path Hacks

Grep for `HACK|WORKAROUND|TEMPORARY` in `lib/` returned **0 matches.** No temporary hack annotations in production code.

31 TODOs exist in `lib/`, all legitimate feature-gap markers (model loading, i18n, analytics integration). None are hacks.

**Status: ALREADY DONE.** Production paths are clean.

### TC-008: docs/ Directory

docs/ is extensive with 95+ files across subdirectories: review/, planning/, audit/, exploration/, guides/, reference/, technical/, design/, implementation/, testing/, architecture/, reports/, playbooks/. Most recent content is from May 23, 2026.

**Status: ALREADY DONE.** docs/ is active and receiving documentation.

### TC-009: .gitignore Secret Coverage

| File | Gitignored? | Evidence |
|---|---|---|
| .env | Yes | `.gitignore:85` |
| .env.backup | Yes | `.gitignore:90` |
| .env.example | No | Intentionally tracked (template) |
| .env.template | No | Intentionally tracked (template) |

**Gap:** `.gitignore` uses individual patterns (lines 84-90) rather than a catch-all `.env*`. If a new variant like `.env.staging.backup` is created, it could be committed.

**Status: PARTIALLY DONE.** Coverage is adequate but fragile.

### TC-010: Verification Protocol

`flutter analyze --no-fatal-infos --no-fatal-warnings` completes with 419 info-level issues, 0 errors. `flutter test` completes in ~3 minutes with 99.8% pass rate.

**Status: ALREADY DONE.** Verification tools are functional.

---

## 6. Dynamic Verification and Test Baseline

### Static Analysis

```bash
flutter analyze --no-fatal-infos --no-fatal-warnings
```
- 419 info-level issues (deprecated_member_use, cascade_invocations, unawaited_futures, etc.)
- **0 errors, 0 fatal issues**
- All issues are non-blocking

### Full Test Suite

```bash
flutter test --reporter expanded
```
- 2,283 total tests
- 2,267 passed
- 12 skipped (6 E2E gated behind `RUN_E2E_NAV_TESTS`, 4 GoogleFonts assets, 1 legacy family service, 1 flaky golden)
- 4 failed

### Pre-existing Baseline Failures

All 4 failures are **pre-existing** -- none were introduced by this audit:
1. `PremiumFeatureCard` null safety bug (2 tests affected)
2. `GamificationService.getNearMilestoneNudge` logic regression (2 tests affected)

### CI Configuration

14 GitHub Actions workflows covering: build & test, CI, comprehensive testing, performance, visual regression, golden checks, firestore rules test, security, release, policy checks, markdown lint, TODO-to-issue, and TODO sync.

---

## 7. Critical Implementation and Test Traps Checked

### 7A. Environment Variable Loading

- **Pattern found:** Module-level `static const` with `String.fromEnvironment()` in `lib/utils/constants.dart`
- **Assessment:** Compile-time injection. No `os.getenv()` at import time (Dart doesn't have that). The pattern is correct for Dart/Flutter.
- **No ModuleCacheIssue.** Dart `const` values from environment are baked at compile time, not runtime-cached.

### 7B. Test Isolation

- **Test config:** `test/flutter_test_config.dart` sets `WidgetController.hitTestWarningShouldBeFatal = true`
- **Hive in tests:** `test/test_config/test_app_wrapper.dart` and `test/test_config/plugin_mock_setup.dart` handle test isolation
- **No StateLeakage found at static level.** Goldens are separated in CI to macOS runner only.
- **Shallow check only** -- deep test isolation review would require per-test analysis.

### 7C. Full Suite Ran

Yes -- full 2,283-test suite was executed. Pass rate 99.3%.

### 7D. Proof-of-Concept

**No proof-of-concept probe was performed.** Static and existing dynamic evidence were sufficient for this audit. The document under audit (AGENTS.md) is an instruction/contract file, not an implementation doc -- probes would not add value.

---

## 8. Data, Privacy, and PII Boundary Checks

The AGENTS.md document does not directly reference data, PII, or privacy boundaries. However, since the security audit uncovered API key exposure vectors, these findings are relevant:

### 8C. P0 Finding: Gemini Key via URL Query Parameter

`lib/services/enhanced_ai_api_service.dart:617` passes the Gemini API key as a URL query parameter:
```dart
queryParameters: {'key': ApiConfig.apiKey},
```

**Why P0:** Query parameters are logged by Firebase Functions request logs, Cloud Logging, intermediate proxies, and CDNs. This is a key exposure vector via logging. The same file's `GeminiProviderClient` already uses the correct header-based approach.

**Evidence:** The `gemini_provider_client.dart:115` correctly uses `x-goog-api-key` header. The `enhanced_ai_api_service.dart:617` uses the insecure query parameter pattern.

### 8F. All Write Paths

For this audit, the relevant "write paths" are:
- Source code files (no secrets found in committed code)
- Local `.env` files (secrets present but gitignored)
- `.env.backup` (unnecessary real keys present)

---

## 9. Deduped Issue / Task Register

### ISSUE-001: Gemini API Key Exposed via URL Query Parameter

**Category:** security

**Origin:** Implicit (audit finding)
**Source doc:** N/A (uncovered during security verification)

**Codebase Evidence:**
- `lib/services/enhanced_ai_api_service.dart:617` -- Gemini key passed as URL query parameter
- `lib/services/gemini_provider_client.dart:115` -- Same service uses correct header-based approach (`x-goog-api-key`)

**Static Verification:** Query parameter vs header pattern mismatch confirmed
**Dynamic Verification:** N/A (requires live API calls)

**Current Behavior:** Gemini API key is included in URL query string, making it visible in request logs, CDN logs, and proxy logs.

**Expected Behavior:** Key should be passed via `x-goog-api-key` HTTP header (already used in GeminiProviderClient), not as a query parameter.

**Gap:** Same service uses two different key transmission methods; one is secure (header), one is not (query param).

**Impact:** Potential API key exposure via logging infrastructure.

**Risk:** High -- real Gemini key could appear in logs. If key is rotated, only `.env` updates but the code pattern persists.

**Confidence:** High -- directly confirmed by code inspection.

**Acceptance Criteria:**
- [ ] `EnhancedAiApiService._analyzeWithGemini` passes key via header, not query parameter
- [ ] Existing `GeminiProviderClient` header pattern is replicated
- [ ] Related tests pass

**Test Plan:**
- Automated: Run existing AI service tests
- Manual: Verify no key appears in URL logs after fix

**Rollback / Kill Switch:** Revert the query parameter change to restore original behavior

**Open Questions:** Are there other places in the codebase where API keys pass via query parameters?

---

### ISSUE-002: Hardcoded Default API Key in MiniCPM Service

**Category:** security

**Origin:** Implicit (audit finding)
**Source doc:** AGENTS.md:27 -- "Do not hardcode API keys or tokens"

**Codebase Evidence:**
- `lib/services/minicpm_service.dart:17` -- `static const String _kDefaultApiKey = 'sk-minicpm-free';`
- `lib/services/minicpm_service.dart:42` -- `defaultValue: _kDefaultApiKey`

**Static Verification:** Hardcoded string compiled into every build binary
**Dynamic Verification:** N/A

**Current Behavior:** The string `sk-minicpm-free` is compiled into every APK/IPA build as a `defaultValue` for the MiniCPM API key.

**Expected Behavior:** If MiniCPM is not configured, fail cleanly with an error rather than falling back to a compiled-in key.

**Gap:** The `String.fromEnvironment` uses this as a `defaultValue`. If MINICPM_API_KEY is not set in `.env`, the hardcoded key is used.

**Impact:** If `sk-minicpm-free` is a valid API key granting any access, it's a credential in the binary.

**Risk:** Medium -- depends on whether the key is actually functional.

**Confidence:** High -- directly confirmed.

**Acceptance Criteria:**
- [ ] Remove `_kDefaultApiKey` constant
- [ ] Change `defaultValue` to empty string or remove fallback
- [ ] Fail cleanly with an error message when MINICPM_API_KEY is not configured

**Test Plan:**
- Automated: Verify MiniCPM service fails cleanly when env var is missing
- Manual: Test with and without MINICPM_API_KEY set

**Rollback / Kill Switch:** Add the default back if MiniCPM integration is critical and this was intentionally a free-tier demo key

**Open Questions:** Is `sk-minicpm-free` a real, functioning free-tier key or just a documentation placeholder?

---

### ISSUE-003: .env.backup Contains Real Firebase API Keys

**Category:** security

**Origin:** Implicit (audit finding)
**Source doc:** AGENTS.md:29 -- "replace with placeholder and document migration"

**Codebase Evidence:**
- `.env.backup:12` -- `FIREBASE_ANDROID_API_KEY=AIzaSyCvMKQNvA00QZHTg6BQ4mOaKtRXgKNqbpo`
- `.env.backup:16` -- `FIREBASE_IOS_API_KEY=AIzaSyB6r1DqZvXQtMEEYtJTZ8dxlXWU_26_1Hk`
- `.env.backup:20` -- `FIREBASE_WEB_API_KEY=AIzaSyBKU5b43AxbK4S_SHotfT8vYTabNVGyWOk`
- `.env.backup:2` -- `OPENAI_API_KEY=sk-proj-YOUR_NEW_OPENAI_KEY_HERE` (placeholder -- correct)
- `.env.backup:3` -- `GEMINI_API_KEY=AIzaSy-YOUR_NEW_GEMINI_KEY_HERE` (placeholder -- correct)

**Static Verification:** File exists on disk with mix of real and placeholder keys
**Dynamic Verification:** File is gitignored (`.gitignore:90`) -- confirmed via `git check-ignore`

**Current Behavior:** `.env.backup` contains real Firebase platform keys alongside placeholder OpenAI/Gemini keys. The OpenAI/Gemini placeholders suggest this was a transition artifact.

**Expected Behavior:** `.env.backup` should either be deleted entirely or contain only placeholders for all keys, matching the pattern of `.env.example` and `.env.template`.

**Gap:** Unnecessary exposure surface. There is no reason to maintain a parallel backup with real keys when `.env` is the source of truth.

**Impact:** Local exposure risk if backup tooling syncs this file.

**Risk:** Medium (gitignored, but unnecessary risk)

**Confidence:** High

**Acceptance Criteria:**
- [ ] Either delete `.env.backup` or replace all real keys with placeholders
- [ ] If kept, ensure all key values follow the `YOUR_NEW_*_KEY_HERE` convention

**Test Plan:**
- Manual: Verify `.env.backup` no longer contains real keys or has been deleted

**Rollback / Kill Switch:** Restore from git reflog if needed

**Open Questions:** Why does this file exist? Was it used for key rotation?

---

### ISSUE-004: AGENTS.md "Runtime Env Vars" Language Is Inaccurate

**Category:** docs

**Origin:** Explicit
**Source doc:** AGENTS.md:28 -- "Prefer runtime env vars / secure config"

**Codebase Evidence:**
- `lib/utils/constants.dart:14-15` -- `String.fromEnvironment('OPENAI_API_KEY', ...)` -- compile-time, not runtime
- `lib/utils/production_safety_config.dart:14-15` -- `bool.fromEnvironment('ALLOW_CLIENT_AI_IN_RELEASE')` -- compile-time
- `.vscode/launch.json:11` -- `--dart-define-from-file=.env` -- compile-time injection

**Static Verification:** Mechanism is `String.fromEnvironment()` which is compile-time constant evaluation in Dart
**Dynamic Verification:** N/A

**Current Behavior:** The AGENTS.md suggests "runtime env vars" but the actual mechanism is Dart's compile-time `--dart-define-from-file` approach.

**Expected Behavior:** AGENTS.md should accurately describe the mechanism. Suggested text: "Prefer compile-time dart-define from .env files with production safety guards in release builds."

**Gap:** Terminology mismatch between instruction doc (AGENTS.md) and actual implementation.

**Impact:** Low -- agents following the instruction would still use the correct mechanism because it's documented in README.md and .env.example.

**Risk:** Low

**Confidence:** High

**Acceptance Criteria:**
- [ ] Update AGENTS.md:28 to reflect compile-time dart-define mechanism
- [ ] Add reference to `ProductionSafetyConfig` as the release-mode guardrail

**Test Plan:**
- Automated: No code changes needed
- Manual: Verify updated text is accurate

---

### ISSUE-005: .gitignore Pattern Fragility for Env Files

**Category:** security

**Origin:** Implicit (audit finding)
**Source doc:** AGENTS.md:29 -- secret protection

**Codebase Evidence:**
- `.gitignore:84-90` -- individually listed patterns: `.env`, `.env.local`, `.env.development`, `.env.production`, `.env.staging`, `.env.backup`

**Static Verification:** If someone creates `.env.staging.backup` or `.env.production.backup`, it would NOT be matched by any current pattern.

**Current Behavior:** Each env file variant requires an explicit entry in `.gitignore`.

**Expected Behavior:** A catch-all `.env*` pattern with explicit exceptions for `.env.example` and `.env.template` would be more robust.

**Gap:** Fragile explicit listing vs catch-all pattern.

**Impact:** Low -- requires someone to create a non-standard env file name and commit it.

**Risk:** Low

**Confidence:** Medium

**Acceptance Criteria:**
- [ ] Replace lines 84-90 with `.env*` catch-all
- [ ] Add explicit `!.env.example` and `!.env.template` exceptions
- [ ] Verify with `git check-ignore` that templates are still tracked

**Test Plan:**
- Manual: Create a `.env.staging.backup` and verify it's ignored

---

### ISSUE-006: Placeholder DefaultValues Mask Missing Environment Configuration

**Category:** security

**Origin:** Implicit (audit finding)
**Source doc:** AGENTS.md:27-28

**Codebase Evidence:**
- `lib/utils/constants.dart:14-15` -- `defaultValue: 'your-openai-api-key-here'`
- `lib/utils/constants.dart:37-38` -- `defaultValue: 'your-gemini-api-key-here'`
- `lib/utils/production_safety_config.dart:54-61` -- `hasPlaceholderKey()` catches these (mitigation)

**Static Verification:** The `hasPlaceholderKey()` guard in `ProductionSafetyConfig` catches these placeholders before they reach API providers. This is a well-designed safety net.

**Current Behavior:** If a build is made without `--dart-define-from-file=.env`, the placeholder values are used. The production safety guard catches them before any API call.

**Expected Behavior:** Removing the `defaultValue` entirely (letting it be empty string) would force a hard failure rather than relying on the safety guard. However, the current approach with the guard is defensible.

**Gap:** Double protection: guard + placeholder. Could simplify to empty string default + guard.

**Impact:** Low -- the safety guard already blocks placeholder keys.

**Risk:** Low

**Confidence:** High

**Acceptance Criteria:**
- [ ] Decision needed: keep placeholder defaults with guard, or remove defaults for hard-fail
- [ ] If keeping: document the guard relationship in constants.dart
- [ ] If removing: verify that all callers handle empty string gracefully

**Test Plan:**
- Automated: Test that `hasPlaceholderKey()` returns true for all placeholder values
- Manual: Verify app fails cleanly with clear error when keys are missing

**Open Questions:** Would removing defaults break any existing test or debug workflow?

---

### ISSUE-007: 4 Pre-existing Test Failures

**Category:** bug / refactor

**Origin:** Implicit (audit finding -- test baseline)
**Source doc:** AGENTS.md:32 -- "Run relevant tests/validation commands"

**Codebase Evidence:**
- `lib/widgets/premium_feature_card.dart:22` -- Null check operator on null value (causes 2 test failures)
- `lib/services/gamification_service.dart` -- `getNearMilestoneNudge` returns wrong nudge type (2 test failures)

**Static Verification:** PremiumFeatureCard uses `!` on a nullable value; GamificationService nudge prioritization logic is wrong.
**Dynamic Verification:** Full suite confirmed 4 failures out of 2,283 tests.

**Current Behavior:** 4 tests consistently fail. PremiumFeatureCard widget crashes under certain states. Gamification nudge logic returns wrong priorities.

**Expected Behavior:** All tests pass. Widget handles null gracefully. Nudge logic returns correct priorities.

**Gap:** 2 distinct bugs affecting 4 tests.

**Impact:** Low-medium -- widget crash is potential UX issue, nudge logic is gamification detail.

**Risk:** Medium (the PremiumFeatureCard crash is a user-facing bug in certain states)

**Confidence:** High

**Acceptance Criteria:**
- [ ] Fix `PremiumFeatureCard` null safety (fallback instead of `!`)
- [ ] Fix `getNearMilestoneNudge` prioritization order
- [ ] All 4 tests pass
- [ ] Full suite passes with 0 failures

**Test Plan:**
- Automated: Re-run `flutter test` after fixes, verify 0 failures
- Manual: Verify PremiumFeatureCard renders in disabled state

---

### ISSUE-008: 31 TODOs in Production Code

**Category:** docs / refactor

**Origin:** Implicit
**Source doc:** AGENTS.md:18 -- "additive and architecture-safe"

**Codebase Evidence:**
- 31 TODOs across 14 files in `lib/`
- Key areas: `ad_service.dart` (reward ads), `analytics_service.dart` (user segments), `dynamic_pricing_service.dart` (Firestore persistence), `on_device_vision_service.dart` (TFLite inference), `segmentation_service.dart` (TFLite), `batching_service.dart` (batch API), `cache_service.dart` (Remote Config), `leaderboard_service.dart` (weekly/monthly), `object_detection_service.dart` (YOLO), `recycling_code_info.dart` (i18n)

**Static Verification:** All 31 TODOs are legitimate feature-gap markers, not hacks or workarounds.
**Dynamic Verification:** N/A

**Current Behavior:** TODOs mark incomplete features but do not affect current functionality.

**Expected Behavior:** These should be tracked as issues or gradually resolved. No action needed now.

**Gap:** None -- TODOs are normal development artifacts.

**Impact:** Low -- informational.

**Risk:** Low

**Confidence:** High

**Acceptance Criteria:**
- [ ] No action needed now; track if these become blockers

**Test Plan:** N/A

---

## 10. Prioritization

| ID | Title | Severity | Blast Radius | Effort | Confidence | Priority |
|---|---|---|---|---|---|---|
| ISSUE-001 | Gemini key via URL query param | 5 (security) | 3 | 2 (one-line fix) | 5 | **P0** |
| ISSUE-002 | Hardcoded MiniCPM key | 4 (security) | 2 | 1 (trivial) | 5 | **P0** |
| ISSUE-003 | .env.backup has real keys | 4 (security) | 1 | 1 (trivial) | 5 | **P1** |
| ISSUE-007 | 4 pre-existing test failures | 3 (UX/reliability) | 3 | 3 (moderate) | 5 | **P1** |
| ISSUE-004 | AGENTS.md "runtime" language | 1 (docs) | 1 | 1 (trivial) | 5 | **P2** |
| ISSUE-005 | .gitignore pattern fragility | 2 (security) | 1 | 1 (trivial) | 3 | **P2** |
| ISSUE-006 | Placeholder defaults mask missing env | 2 (defense-in-depth) | 1 | 1 (trivial) | 5 | **P2** |
| ISSUE-008 | 31 production TODOs | 1 (docs) | 1 | 1 (informational) | 5 | **P3** |

### Priority Queues

#### P0 (Fix Now)
- **ISSUE-001:** Gemini API key exposed via URL query parameter in `enhanced_ai_api_service.dart:617`
- **ISSUE-002:** Hardcoded `sk-minicpm-free` in `minicpm_service.dart:17`

#### P1 (Important)
- **ISSUE-003:** Delete or sanitize `.env.backup` (real Firebase keys unnecessarily stored)
- **ISSUE-007:** Fix 4 pre-existing test failures (PremiumFeatureCard null bug + gamification nudge logic)

#### P2 (Useful but not blocking)
- **ISSUE-004:** Update AGENTS.md "runtime env vars" language
- **ISSUE-005:** Make `.gitignore` env patterns a catch-all
- **ISSUE-006:** Consider removing placeholder defaults from constants.dart

#### P3 (Cleanup/Polish)
- **ISSUE-008:** 31 production TODOs (track, don't fix now)

#### Quick Wins
- ISSUE-001 (one-line fix: change query param to header)
- ISSUE-002 (one-line fix: remove default key)
- ISSUE-003 (one command: delete file or replace keys)

#### Risky Changes
- ISSUE-007: Fixing the PremiumFeatureCard null bug may expose other null safety issues in the same widget

#### Needs Discussion Before Work
- ISSUE-006: Remove placeholder defaults or keep as-is with guard?
- ISSUE-001: Should we rotate the OpenAI and Gemini keys after fixing the query param issue?

#### Not Worth Doing
- None identified. All issues have clear value.

---

## 11. Proof-of-Concept Validation

No proof-of-concept probe was needed. Static and existing dynamic evidence were sufficient.

The document under audit (AGENTS.md) is an instruction/contract file. All claims were verifiable through:
1. Static file inspection (context chain, doc existence)
2. Grep-based code search (secrets, hacks, patterns)
3. Full test suite execution (test baseline)
4. Static analysis (flutter analyze)

---

## 12. Assumptions Challenged by Implementation

| Assumption | Why it seemed true | What disproved it | Evidence | How recommendation changed |
|---|---|---|---|---|
| Both motto_v2.md copies had diverged | Agent reported 666 vs 687 lines | `diff` showed 0 differences, both files 676 lines | Direct `diff` comparison | Removed "duplicate drift" from issues; no action needed |
| "Runtime env vars" claim was correct | AGENTS.md:28 says "runtime env vars" | Actual mechanism is compile-time `String.fromEnvironment()` | constants.dart:14-15, launch.json:11 | Added ISSUE-004 to fix docs language |
| .env.backup was all placeholders | Agent noted OpenAI/Gemini were placeholders | Firebase keys were real, not placeholders | .env.backup:12,16,20 | Added ISSUE-003 to clean up backup file |

---

## 13. Parallel Agent / Multi-Model Findings

Three parallel agents were used for this audit:

| Agent | Role | Deliverable | Key Findings |
|---|---|---|---|
| Agent A (Codebase Verifier) | Verify all AGENTS.md claims against code | 10-point verification report | All claims verified; found .env with live keys, 31 TODOs, 2 motto copies identical |
| Agent B (Test/Runtime Verifier) | Establish test baseline | 2,283 tests, 4 failures, 12 skipped | 99.8% pass rate; PremiumFeatureCard and Gamification bugs identified |
| Agent C (Security Reviewer) | Find hardcoded secrets | 12 findings across 5 severity levels | P0: Gemini key via URL param, P0: hardcoded MiniCPM key, P1: .env.backup, P1: placeholder defaults |

**Consensus:** All agents agree the codebase is well-architected for security. The P0 security issues are real but narrow in scope.

**Contradictions resolved:**
- Agent A reported dual motto_v2.md drift -- disproved by direct `diff` showing identical files
- All other findings were corroborated across agents

---

## 14. Discussion Pack

### My Recommendation

I recommend working on these in order:

1. **ISSUE-001** (Gemini key via query param) -- P0, one-line fix, high impact
2. **ISSUE-002** (Hardcoded MiniCPM key) -- P0, one-line fix
3. **ISSUE-003** (.env.backup cleanup) -- P1, trivial
4. **ISSUE-007** (4 test failures) -- P1, moderate effort

### Why These Matter Now

ISSUE-001 and ISSUE-002 are active security issues that exist in the current codebase. The Gemini key is exposed through logging infrastructure every time the enhanced API service is used. The MiniCPM key is compiled into every binary.

ISSUE-007 (test failures) is a quality gate -- the README claims "NOT READY FOR RELEASE" partly because of test infrastructure, and these 4 failures contribute to that.

### What Breaks If Ignored

- ISSUE-001: Gemini API key continues to appear in request logs, CDN logs, and proxy logs
- ISSUE-002: MiniCPM key (if functional) is extractable from every APK/IPA binary
- ISSUE-007: PremiumFeatureCard widget can crash; gamification nudges show wrong messages

### What I Would Not Work On Yet

- ISSUE-008 (31 TODOs) -- these are feature-gap markers, not bugs
- ISSUE-005 (.gitignore) -- current coverage is adequate, low risk
- ISSUE-006 (placeholder defaults) -- the guard already catches these

### What Is Ambiguous

- Whether `sk-minicpm-free` is a real functioning key or a documentation placeholder -- this affects the severity of ISSUE-002
- Whether the OpenAI and Gemini keys in `.env` should be rotated, since they were examined during this audit

### Questions For You

1. **Should we rotate the OpenAI and Gemini API keys now?** The keys in `.env` were read during this audit. While they're gitignored, best practice is to rotate after any exposure. This is independent of the code fix.

2. **Is `sk-minicpm-free` a real key that provides access?** If yes, ISSUE-002 is genuinely P0. If no and it's just a convention (like `your-api-key-here`), it's a P2 docs issue.

3. **Should we fix the 4 pre-existing test failures now or track them separately?** The PremiumFeatureCard null bug is a user-facing crash risk. The gamification nudge bug is cosmetic but still a logic error.

---

## 15. Online Research

No online research needed. All findings are repo-evidence based.

---

## 16. ChatGPT / External Review Escalation Writeup

Not needed. The issues are clear-cut and require no external review. The P0 security findings are uncontroversial (query param vs header for API keys).

---

## 17. Recommended Next Work Unit

# Recommended Next Work Unit

## Unit-1: Fix P0 Security Issues (ISSUE-001, ISSUE-002)

**Goal:** Eliminate active API key exposure vectors -- Gemini key in URL query params and hardcoded MiniCPM default key.

**Issues covered:** ISSUE-001, ISSUE-002

**Scope:**
- In:
  - `lib/services/enhanced_ai_api_service.dart:617` -- change `queryParameters: {'key': ...}` to header-based auth
  - `lib/services/minicpm_service.dart:17,42` -- remove `_kDefaultApiKey`, change `defaultValue` to empty string
- Out:
  - Key rotation (ask first)
  - .env.backup cleanup (tracked as ISSUE-003)
  - Test failure fixes (tracked as ISSUE-007)

**Likely files touched:**
- `lib/services/enhanced_ai_api_service.dart` (line 617 area)
- `lib/services/minicpm_service.dart` (lines 17, 40-42)

**Acceptance criteria:**
- [ ] Gemini key is passed via `x-goog-api-key` header, not query parameter
- [ ] MiniCPM service fails cleanly when `MINICPM_API_KEY` is not configured
- [ ] All existing tests continue to pass (no new failures beyond the 4 pre-existing)
- [ ] Static analysis shows no new issues

**Tests to run:**
- Baseline: `flutter test` (2,267 pass, 4 fail, 12 skip)
- Targeted: `flutter test test/services/ai_service_backend_test.dart test/services/enhanced_ai_api_service_test.dart`
- Full suite: `flutter test` (verify no new failures beyond baseline)

**Manual verification:**
- Verify the Gemini key doesn't appear in URL after the fix
- Verify MiniCPM error message is clear when key is missing

**Operational safety:**
- Kill switch / rollback: Revert the two file changes

**Risks:**
- Low: The fix is mechanical (pattern match between GeminiProviderClient and EnhancedAiApiService)
- The MiniCPM change may break existing MiniCPM users if `sk-minicpm-free` was actually needed

**Rollback plan:**
- `git checkout lib/services/enhanced_ai_api_service.dart`
- `git checkout lib/services/minicpm_service.dart`

---

## 18. Appendix: Searches Performed

| Search | Scope | Results |
|---|---|---|
| `glob *.md` | Root | 7 files |
| `glob docs/**/*.md` | docs/ | 95+ files |
| `grep "sk-\|sk_proj\|API_KEY\|apiKey\|api_key" lib/` | lib/ | 0 hardcoded keys (only env references) |
| `grep "AIza" lib/` | lib/ | 0 hardcoded keys |
| `grep "HACK\|WORKAROUND\|TEMPORARY" lib/` | lib/ | 0 matches |
| `grep "TODO" lib/ --include="*.dart"` | lib/ | 31 matches across 14 files |
| `grep "Bearer" lib/ --include="*.dart"` | lib/ | Authorization header patterns (correct usage) |
| `grep "String.fromEnvironment" lib/ --include="*.dart"` | lib/ | constants.dart, firebase_options.dart, production_safety_config.dart, minicpm_service.dart |
| `grep "@Skip\|skip:" test/ --include="*.dart"` | test/ | 12 matches across 4 files |
| `diff motto_v2.md functions/motto_v2.md` | Both | 0 differences (identical) |
| `git check-ignore .env .env.backup .env.example .env.template` | Root | .env/.env.backup ignored; .env.example/.env.template tracked |
| `flutter analyze --no-fatal-infos --no-fatal-warnings` | All | 419 info-level, 0 errors |
| `flutter test --reporter expanded` | All | 2,283 tests; 2,267 pass, 12 skip, 4 fail |
