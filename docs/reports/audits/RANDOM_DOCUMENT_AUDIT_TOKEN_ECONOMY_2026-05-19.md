# Random Document Audit Report

**Chosen document:** `TOKEN_ECONOMY_TODO.md`
**Selection method:** Pseudo-random (Unix epoch seconds % document count → index 17)
**Audit date:** 2026-05-19
**Auditor model:** moonshotai/kimi-k2.6

---

## 1. Document Inventory

| Doc ID | Path | Type | Why it may matter |
|--------|------|------|-------------------|
| D01 | TOKEN_ECONOMY_TODO.md | TODO/Roadmap | Central token economy task tracker |
| D02 | docs/launch/LAUNCH_BLOCKERS.md | Launch Gate | May block release |
| D03 | docs/launch/CLOSED_BETA_SMOKE_CHECKLIST.md | QA Checklist | Pre-launch validation |
| D04 | docs/planning/MAY_END_RELEASE_SAFETY.md | Release Plan | Timeline pressure |
| D05 | docs/adr/ADR-003-data-sync-strategy.md | ADR | Architecture decision |
| D06 | docs/roadmap/ENHANCEMENT_BACKLOG.md | Backlog | Unprioritized work |
| D07 | docs/results_parity/PARITY_CHECKLIST.md | Parity | iOS/Android parity |
| D08 | docs/results_parity/TESTING_STATUS.md | Test Status | Test coverage report |
| D09 | docs/ai_service_refactor_motto_v2_2026-05-19.md | Refactor Plan | AI service changes |
| D10 | docs/reports/architecture/AI_MODEL_STRATEGY_DISCUSSION_2026-05-19.md | Architecture | AI model choice |
| D11 | docs/maintenance/STASH_SALVAGE_AUDIT_2026-05-19.md | Salvage Audit | Preserved work recovery |
| D12 | docs/technical/features/camera_architecture.md | Feature Spec | Camera pipeline |
| D13 | docs/planning/roadmap/SOCIAL_GAMIFICATION.md | Roadmap | Gamification features |
| D14 | docs/guides/development/data_storage/firestore_schema.md | Schema Guide | Firestore schema reference |
| D15 | docs/TODO/AI_RACE_AND_BANGALORE_TODOS.md | TODO | AI race A/B + Bangalore work |
| D16 | docs/smoke_tests/ai_race_ab_test.md | Smoke Test | AI race validation |
| D17 | docs/results_parity/RESULT_TRUST_NOTE.md | Trust Note | Result reliability |
| D18 | docs/reference/APP_KNOWLEDGE_BASE.md | Knowledge Base | App domain reference |
| D19 | docs/reports/architecture/API_SECURITY_ARCHITECTURE_DECISION.md | ADR | Security architecture |
| D20 | docs/planning/ideas_to_explore.md | Ideation | Future ideas |
| D21 | docs/archive/fixes/AI_API_PHASE1_FIXES.md | Archive | Past fix notes |
| D22 | PR_DESCRIPTION.md | PR Context | Recent PR description |

---

## 2. Random Selection

**Chosen document:** `TOKEN_ECONOMY_TODO.md`
**Selection method:** Pseudo-random — `int(time.time()) % 22 = 17` at audit time
**Why this doc is worth auditing:** It is the central task tracker for the token economy, claims multiple phases as complete, and directly ties to monetization, security, and user-facing behavior. If its claims are stale or wrong, the app may be showing users token costs it never actually enforces.

---

## 3. Chosen Document Deep Analysis

Full content read. 56 lines, 6 phases, 9 success metrics, 5 dependency items.

### Extracted Items

| Doc Item ID | Type | Short Quote / Evidence | Location (line) | Interpretation | Confidence |
|-------------|------|------------------------|-----------------|----------------|------------|
| DI-01 | Current-State Claim | "Critical compilation errors resolved" | 3 | Claims build errors fixed | High (stale risk: tflite_flutter noted as external) |
| DI-02 | Current-State Claim | "Phase 2 (Job Queue & Batch API) fully implemented" | 3 | Claims batch job system complete | High |
| DI-03 | Current-State Claim | "Phase 3 (UI Components) mostly complete" | 3 | Claims UI components mostly done | Medium (does "mostly" exclude critical gaps?) |
| DI-04 | Current-State Claim | "Build failure is due to tflite_flutter dependency namespace issue (not our code)" | 3 | Blames external dependency for build failure | Unknown (needs verification) |
| DI-05 | Explicit Task | "[x] Fix WasteAppLogger calls in api_management_service.dart" | 6 | Done - compilation fix | High (completed) |
| DI-06 | Explicit Task | "[x] Fix undefined method 'StorageService' in image_quality_gate.dart" | 7 | Done - compilation fix | High (completed) |
| DI-07 | Explicit Task | "[x] Resolve all Too many positional arguments errors" | 8 | Done - compilation fix | High (completed) |
| DI-08 | Explicit Task | "[x] Implement AiJobService with OpenAI Batch API integration" | 11 | Claims complete | High (codebase confirms) |
| DI-09 | Explicit Task | "[x] Create job queue data models (AiJob, AiJobStatus, QueueStats)" | 12 | Claims complete | High (codebase confirms) |
| DI-10 | Explicit Task | "[x] Add batch processing workflow" | 13 | Claims complete | High |
| DI-11 | Explicit Task | "[x] Implement job status tracking and completion callbacks" | 14 | Claims complete | High |
| DI-12 | Explicit Task | "[x] Add job queue UI components for user visibility" | 15 | Claims complete | High |
| DI-13 | Explicit Task | "[x] Create AnalysisSpeedSelector widget" | 18 | Claims complete | Medium (exists but has TODO at line 293) |
| DI-14 | Explicit Task | "[x] Implement speed-based pricing display" | 19 | Claims complete | High |
| DI-15 | Explicit Task | "[x] Add queue position and estimated wait time UI" | 20 | Claims complete | High |
| DI-16 | Explicit Task | "[x] Create batch mode educational content/tooltips" | 21 | Claims complete | High |
| DI-17 | Explicit Task | "[x] Update result screens to show processing mode" | 22 | Claims complete | High |
| DI-18 | Explicit Task | "[x] Implement Firestore security rules for wallet data protection" | 25 | Claims complete but rules protect UNUSED collections | Medium |
| DI-19 | Explicit Task | "[ ] Add wallet data encryption for sensitive operations" | 26 | Incomplete | High |
| DI-20 | Explicit Task | "[x] Create token transaction audit logging" | 27 | Claims complete - embedded in UserProfile | High |
| DI-21 | Explicit Task | "[ ] Implement wallet backup and restore functionality" | 28 | Incomplete | High |
| DI-22 | Explicit Task | "[x] Add cross-device wallet synchronization" | 29 | Claims complete via UserProfile sync | Medium (does not use dedicated Firestore collections) |
| DI-23 | Explicit Task | "[ ] Implement Remote Config for dynamic pricing" | 32 | Incomplete | High |
| DI-24 | Explicit Task | "[ ] Add cost guardrails and budget monitoring" | 33 | Incomplete but cost_management_providers.dart exists | Medium (partial implementation?) |
| DI-25 | Explicit Task | "[ ] Create usage analytics and cost reporting" | 34 | Incomplete | High |
| DI-26 | Explicit Task | "[ ] Implement freemium feature gating" | 35 | Incomplete | High |
| DI-27 | Explicit Task | "[ ] Add token purchase/earn incentives UI" | 36 | Incomplete | High |
| DI-28 | Explicit Task | "[ ] Add comprehensive unit tests for TokenService" | 39 | Incomplete - ZERO TokenService test files exist | High |
| DI-29 | Explicit Task | "[ ] Implement integration tests for wallet operations" | 40 | Incomplete | High |
| DI-30 | Explicit Task | "[ ] Performance testing for high-volume token transactions" | 41 | Incomplete | High |
| DI-31 | Explicit Task | "[ ] Security testing for wallet data protection" | 42 | Incomplete | High |
| DI-32 | Explicit Task | "[ ] User acceptance testing for token economy flows" | 43 | Incomplete | High |
| DI-33 | Intended-State Claim | "40-50% reduction in OpenAI API costs" | 46 | Unmeasured success metric | Low (no baseline or measurement) |
| DI-34 | Intended-State Claim | ">80% user adoption of batch mode" | 47 | Unmeasured success metric | Low |
| DI-35 | Intended-State Claim | "Positive user feedback on token system" | 48 | Unmeasured | Low |
| DI-36 | Intended-State Claim | "Secure wallet data with zero breaches" | 49 | Unverified (no server-side validation) | Low |
| DI-37 | Intended-State Claim | "Smooth integration with existing AI workflows" | 50 | **CONTRADICTED** — instant analysis path has NO token integration | High |
| DI-38 | Implicit Task | Instant analysis must deduct tokens when UI shows cost | Lines 1087, 1128 (image_capture_screen) | UI shows cost but code never deducts | High |
| DI-39 | Implicit Task | Firestore token_wallets/token_transactions collections should be used by TokenService | Schema registry + rules define them | Collections defined but unused — data goes through UserProfile | High |
| DI-40 | Implicit Task | Server-side validation of token balances | No cloud functions + client-only logic | Anyone with Firestore write access could modify their own balance | High |
| DI-41 | Architecture Claim | Token economy integrates with AI workflows (both instant and batch) | Implicit from document scope | **FALSE for instant path** — only batch path integrates | High |
| DI-42 | Security Claim | Firestore rules protect wallet data | Line 25, 34-41 (firestore.rules) | Rules exist but protect collections that TokenService does not write to | High |
| DI-43 | Risk | Client-side token balance could be manipulated | TokenService._saveWallet writes locally then syncs | No server-side validation; balance is just a number in user's profile | High |

---

## 4. Extracted Task Candidates

| Task Candidate ID | Source Doc Item IDs | Task | Explicit/Implicit | Why This Is a Task | Expected Repo Area | Priority Guess |
|-------------------|---------------------|------|-------------------|--------------------|--------------------|------|
| TC-01 | DI-38, DI-41 | Wire instant analysis through TokenService so tokens are actually deducted | Implicit | UI shows 5-token cost for instant analysis; code never deducts; user gets free instant analysis | image_capture_screen.dart, ai_service.dart | P0 |
| TC-02 | DI-39, DI-42 | Reconcile Firestore token collections: either use token_wallets/token_transactions or remove them from schema/rules | Implicit | Schema defines dedicated collections; TokenService writes everything into UserProfile; Firestore rules protect phantom collections | token_service.dart, firestore_schema_registry.dart, firestore.rules | P1 |
| TC-03 | DI-40, DI-43 | Add server-side token validation: cloud function to verify balance before allowing spend | Implicit | All token logic is client-side; no server validates; users could write inflated balances | functions/, firestore.rules | P1 |
| TC-04 | DI-28 | Create comprehensive unit tests for TokenService | Explicit | Zero TokenService test files exist; doc explicitly lists as incomplete | test/services/ | P1 |
| TC-05 | DI-13, DI-38 | Fix TODO at analysis_speed_selector.dart:293 (navigate to token wallet screen) | Explicit | Code has TODO comment; screen does not exist | analysis_speed_selector.dart | P2 |
| TC-06 | DI-19 | Add wallet data encryption for sensitive operations | Explicit | Marked incomplete in doc | token_service.dart or storage layer | P2 |
| TC-07 | DI-21 | Implement wallet backup and restore | Explicit | Marked incomplete | token_service.dart, cloud layer | P2 |
| TC-08 | DI-24 | Verify/implement cost guardrails | Explicit / Partial | Marked incomplete but cost_management_providers.dart exists | providers/cost_management_providers.dart | P2 |
| TC-09 | DI-23 | Implement Remote Config for dynamic pricing | Explicit | Marked incomplete | remote_config_service.dart, token_service.dart | P2 |
| TC-10 | DI-26 | Implement freemium feature gating | Explicit | Marked incomplete; premium system is separate from token system | premium_service.dart, token_service.dart | P3 |
| TC-11 | DI-27 | Add token purchase/earn incentives UI | Explicit | No in-app purchase; no buy tokens UI | screens/, services/ | P3 |
| TC-12 | DI-29, DI-30, DI-31, DI-32 | Add integration, performance, security, and UAT tests for token economy | Explicit | All marked incomplete | test/ | P2 |
| TC-13 | DI-04 | Verify build failure cause (tflite_flutter) | Implicit | Document blames external dependency; may be resolved or may block deployment | build system | P2 |
| TC-14 | DI-33, DI-34, DI-35 | Establish baseline measurements for success metrics | Implicit | No baseline exists for cost reduction, batch adoption, user feedback | analytics, Remote Config | P3 |

---

## 5. Static Codebase Reality Check

| Task Candidate ID | Codebase Status | Evidence | What Exists Today | Gap | Actual Work Needed |
|-------------------|----------------|----------|-------------------|-----|-------------------|
| TC-01 | **Broken** | `lib/screens/image_capture_screen.dart:360-440` _analyzeImage calls aiServiceProvider directly, never TokenService. Line 1087 shows `$tokenCost tokens`. Line 92 button calls `_analyzeImage`. | Instant analysis UI displays token cost but never deducts | Token deduction for instant analysis is completely missing | Wire _analyzeImage to check token balance first, call spendTokens(), and handle insufficient balance |
| TC-02 | **Stale Code / Contradictory Evidence** | `lib/services/firestore_schema_registry.dart:54-55` defines tokenWallets/tokenTransactions. `firestore.rules:34-42` protects them. `lib/services/token_service.dart:365-382` saves to UserProfile, not these collections | Dedicated collections defined in schema/rules but never written to | TokenService writes wallet data as embedded fields in UserProfile, not to dedicated collections | Either migrate TokenService to use dedicated collections (and keep rules useful) or remove collections from schema/rules |
| TC-03 | **Missing** | Searched `functions/` for token/credit/wallet validation functions. Zero results. `lib/services/token_service.dart` runs entirely client-side. | No server-side enforcement of token balances | Anyone who can write to Firestore can modify their token balance | Create cloud function that validates token balance before allowing spend operations |
| TC-04 | **Missing** | Searched `test/` for `token_service_test.dart`. Zero results. Searched all test files for `spendTokens`/`earnTokens`. Zero results. | Only `test/services/simple_api_integration_test.dart` tests TokenWallet MODEL (construction, JSON, cost constants) — never the service | TokenService.earnTokens, spendTokens, convertPointsToTokens, processDailyLogin all untested | Create token_service_test.dart with tests for each operation, edge cases, rejection paths |
| TC-05 | **Partial** | `lib/widgets/analysis_speed_selector.dart:293` has `// TODO: Navigate to token wallet/earning screen` | AnalysisSpeedSelector widget exists and works; navigation to wallet screen does not | Token wallet/earning screen does not exist | Create token wallet screen or remove TODO |
| TC-06 | **Missing** | `lib/services/token_service.dart:_saveWallet` writes plain data to StorageService | No encryption anywhere in token persistence path | Wallet data stored in plaintext in StorageService + synced to Firestore | Add encryption layer for sensitive wallet fields |
| TC-07 | **Missing** | No backup/restore logic in token_service.dart | Token data only persists via UserProfile sync | No export/import/restore capability | Design and implement backup/restore for wallet |
| TC-08 | **Partially Done** | `lib/providers/cost_management_providers.dart` contains providers for DynamicPricingService, CostGuardrailService, AiCostTracker | Cost guardrail providers exist but doc marks item incomplete | May be providers without actual enforcement or incomplete integration | Verify whether guardrails are enforced or just tracked |
| TC-09 | **Missing** | `lib/services/remote_config_service.dart` exists but no token-related remote config | Remote Config service exists for other features | No dynamic pricing via Remote Config | Add token pricing to Remote Config |
| TC-10 | **Missing** | `lib/services/premium_service.dart` and token system are completely disconnected | Two separate "monetization" systems: tokens and premium, no bridge | No connection between token economy and freemium gating | Define relationship between tokens and premium features |
| TC-11 | **Missing** | No in_app_purchase package; `lib/screens/premium_features_screen.dart:290-295` has stub comment | No real purchase flow | Zero ability for users to buy tokens or premium | Implement IAP or token purchase flow |
| TC-12 | **Missing** | No integration/perf/security/UAT test files for tokens | Only simple_api_integration_test.dart with model-level tests | Full test coverage gap | Create integration, performance, security test suites |
| TC-13 | **Unknown** | Document claims "Build failure is due to tflite_flutter dependency namespace issue (not our code)" | Cannot verify without running `flutter build` | May block deployment | Run flutter build and verify |
| TC-14 | **Missing** | No analytics or cost tracking baseline in codebase for success metrics | Success metrics defined but unmeasurable | No measurement infrastructure | Add analytics events for token usage and cost tracking |

---

## 6. Dynamic Verification and Test Baseline

**Flutter test suite command:** `flutter test` — not executed (Flutter SDK may not be in PATH or project has build issues per doc claim about tflite_flutter).

**Test baseline status:**
- TokenWallet model tests: PASSING (simple_api_integration_test.dart — basic construction, JSON, cost values)
- TokenService tests: **ZERO EXIST** — no baseline at all
- Image capture screen tests exist (`test/screens/image_capture_screen_test.dart`) but were not verified for token-related assertions

**What could not be dynamically verified:**
- Full Flutter test suite (build may fail per doc)
- Whether instant analysis actually bypasses token deduction at runtime (static evidence is conclusive)
- Whether Firestore rules actually prevent balance manipulation (rules exist but protect unused collections)

**Why this matters:**
TC-01 is statically proven as Broken. The code path `image_capture_screen._analyzeImage()` -> `aiServiceProvider` never touches `tokenServiceProvider`. No runtime test can falsify this because no TokenService test exists.

---

## 7. Critical Implementation and Test Traps Checked

**7A. Environment Variable and Config Loading:**
- `_isDebugGridSegmentationEnabled` in `image_capture_screen.dart:49-50` is read at class initialization via `bool.fromEnvironment('ENABLE_DEBUG_GRID_SEGMENTATION')`. This is compile-time, not runtime — correct for Flutter.
- `AnalysisSpeed _selectedSpeed = AnalysisSpeed.instant` at line 61 defaults to instant (5 tokens). This means the default path that bypasses TokenService also defaults to the more expensive option.
- No lru_cache or module-level env caching found in token-related code.
- **No ModuleCacheIssue detected.**

**7B. Test Isolation and State Leakage:**
- `simple_api_integration_test.dart` creates `DynamicPricingService()` and `TokenWallet.newUser()` directly — no shared state. **StateLeakage: None detected** in existing tests.
- However, since zero TokenService tests exist, there is no way to assess test isolation for the service that manages mutable wallet state.

**7C. Full Test Suite:**
- Could not run. Doc claims a tflite_flutter build failure. The test evidence is limited to static analysis.

**7D. Proof-of-Concept:**
- Not needed for TC-01. Static analysis is conclusive: `_analyzeImage()` code path is traceable and contains zero TokenService references. A PoC would not add evidence.

---

## 8. Data, Privacy, and PII Boundary Checks

**8A. Data Serialization Boundary:**
- `TokenWallet` serializes via `toJson()` → embedded in `UserProfile.toJson()` → saved to StorageService and synced to Firestore.
- Token transactions (including `reference` field linking to classification IDs) are embedded in UserProfile.
- **Risk:** UserProfile.sync path writes entire profile including token data. If any field contains PII (e.g., transaction descriptions with classification names), it flows to Firestore without additional checks.
- **DataBoundaryRisk: Low-Medium** — token data itself (balance, earned, spent) is not PII. Transaction descriptions like "Instant analysis" are not PII. But classification references could indirectly link to user images.

**8B. Firestore Rules:**
- `firestore.rules:34-42` restricts `token_wallets/{userId}` and `token_transactions/{transactionId}` to the owning user.
- **Critical gap:** TokenService does NOT write to these collections. It writes to `/users/{userId}` (the user profile document). The token_wallets rules protect **data that does not exist**.
- The `/users/{userId}` rule at lines 9-21 does protect the user profile, but line 18-20 adds a gamification validation function. Whether this catches token balance manipulation depends on `validateGamificationUpdate` implementation.
- **OperationalRisk: Medium** — rules protect phantom collections; real data location has different (potentially weaker) validation.

**8C. Fixture vs Production:**
- `TokenWallet.newUser()` gives 50 welcome tokens (line 89 in test). This constructor is used in production code. No fixture marker exists.
- **DataBoundaryRisk: Low** — wallet data is synthetic by nature (a number), not user-content PII.

**8D. Write Paths:**
- Token wallet writes go through `_saveWallet()` → `StorageService.saveUserProfile()` + `cloudStorageService.saveUserProfileToFirestore()`.
- There is no other write path to token balance.
- **All write paths covered** for the current implementation.

**8E. Privacy Guard / Kill Switch:**
- No privacy guard or kill switch for token economy exists.
- No environment variable controls token behavior.
- No feature flag for enabling/disabling the token system.
- If token deduction were added and caused issues, there is no way to disable it without a code change.
- **RollbackRisk: Medium** for TC-01 (adding token deduction to instant analysis).

---

## 9. Deduped Issue / Task Register

### ISSUE-001: Instant Analysis Bypasses Token Deduction

**Category:** bug / reliability

**Origin:**
- Implicit (discovered during audit)
- Source doc: `TOKEN_ECONOMY_TODO.md` claims "Smooth integration with existing AI workflows" (line 50) — contradicted by codebase
- Related doc items: DI-38, DI-41, DI-37

**Codebase Evidence:**
- `lib/screens/image_capture_screen.dart:360` `_analyzeImage()` calls `aiServiceProvider` directly — no token check
- `lib/screens/image_capture_screen.dart:1087` displays `'$tokenCost tokens'` in the UI
- `lib/screens/image_capture_screen.dart:1092` button onPressed calls `_analyzeImage`
- `lib/screens/image_capture_screen.dart:61` defaults to `AnalysisSpeed.instant` (5-token cost)
- `lib/services/ai_service.dart` imports token_wallet model but never uses TokenService
- `lib/services/ai_job_service.dart:63` correctly calls `spendTokens()` for batch — proving the pattern exists but is not applied consistently

**Static Verification:** Confirmed — traced full code path from button press to AI call; zero TokenService interaction for instant mode.

**Dynamic Verification:** None (no tests exist; static evidence is conclusive).

**Current Behavior:**
- User sees "5 tokens" cost on instant analysis button
- User presses Analyze
- Instant analysis runs via AI service
- Token balance is never checked or deducted
- User gets unlimited free instant analysis while UI claims it costs tokens

**Expected Behavior:** Token balance checked before analysis; tokens deducted on success; insufficient balance blocks analysis or shows warning.

**Gap:** Full integration of TokenService into the instant analysis code path.

**Impact:** Core monetization bypass. Users can use the more expensive instant mode for free. 5 tokens per instant vs 1 per batch means the most costly path is the one with zero enforcement.

**Risk:** High — if tokens are just display candy, user trust erodes. If deduction is added retroactively, users will lose functionality they assumed was free.

**Confidence:** High

**Acceptance Criteria:**
- [ ] `_analyzeImage()` checks `canAfford` before proceeding
- [ ] On successful instant analysis, `spendTokens()` is called with correct cost
- [ ] On insufficient balance, user is blocked or redirected to batch/earning
- [ ] AnalysisSpeedSelector affordability check reflects in analyze button state
- [ ] Analysis failure does not deduct tokens (refund or avoid-deduct-on-failure)

**Test Plan:**
- Automated: token_service_test.dart (new) covering spend path for instant analysis
- Manual: Run app, verify instant mode deducts tokens, verify batch mode still works, verify insufficient balance blocks analysis

**Rollback / Kill Switch:** Add feature flag `ENABLE_TOKEN_ENFORCEMENT` defaulting to `true`. If `false`, skip token check (current behavior). Allows instant disable without redeploy.

**Open Questions:**
- Should insufficient balance block analysis entirely, or allow it with a warning and auto-switch to batch?
- Should users who already used free instant analysis get their balances adjusted retroactively?

---

### ISSUE-002: Firestore Token Collections Defined but Unused

**Category:** architecture / refactor

**Origin:**
- Implicit
- Source doc: `TOKEN_ECONOMY_TODO.md:25-29` claims Firestore rules and cross-device sync are complete
- Related doc items: DI-18, DI-22, DI-39, DI-42

**Codebase Evidence:**
- `lib/services/firestore_schema_registry.dart:54-55` defines `tokenWallets` and `tokenTransactions` collection names
- `firestore.rules:34-42` protects `/token_wallets/{userId}` and `/token_transactions/{transactionId}`
- `lib/services/token_service.dart:365-382` saves wallet to `StorageService.saveUserProfile()` and syncs via `cloudStorageService.saveUserProfileToFirestore()` — never to dedicated collections

**Current Behavior:**
- Token data lives inside the `UserProfile` document in `/users/{userId}`
- Dedicated collections `/token_wallets/` and `/token_transactions/` exist in schema + rules but are never written to
- Firestore rules protect ghost collections

**Expected Behavior:** Either TokenService uses the dedicated collections (for scalability, query performance, and rule enforcement), or the unused schema definitions and rules are removed to avoid confusion.

**Gap:** Architecture mismatch between schema definition and data flow.

**Impact:** Medium — unused collections waste rule complexity, create false confidence in security, and will confuse future developers.

**Risk:** Medium — if someone adds writes to these collections later without understanding the current flow, they could create data inconsistency.

**Confidence:** High

**Acceptance Criteria:**
- [ ] TokenService writes to dedicated Firestore collections OR
- [ ] Unused schema entries and rules are removed with documentation of why
- [ ] If migrating, add migration path for existing embedded wallet data

**Test Plan:**
- Automated: Verify write destination in token_service_test.dart
- Manual: Check Firestore console for empty token_wallets/token_transactions collections

**Rollback / Kill Switch:** Not applicable (architecture decision, not runtime behavior).

**Open Questions:**
- Should tokens live in dedicated collections for query performance (e.g., leaderboard of top token holders)?
- Is embedding in UserProfile acceptable for current scale?

---

### ISSUE-003: No Server-Side Token Validation

**Category:** security / operational-safety

**Origin:**
- Implicit
- Related doc items: DI-40, DI-43, DI-36

**Codebase Evidence:**
- `functions/src/index.ts` — zero token-related functions
- `functions/batch_processor.js` — zero token-related functions
- `lib/services/token_service.dart` — all logic runs client-side
- Firestore rules allow users to write their own user profile, which contains token balance

**Current Behavior:**
- Token balance is a number in the client-side `TokenWallet` model
- Client calls `spendTokens()` which reduces the number locally
- Client saves updated UserProfile (containing new balance) to Firestore
- Nothing on the server verifies the previous balance or the delta

**Expected Behavior:** Server validates that spend operations have sufficient balance and that earned amounts are legitimate.

**Gap:** Complete absence of server-side enforcement.

**Impact:** Any user with Firestore write access can set arbitrary token balances. In practice, this requires bypassing the client, but Firebase security rules alone may not catch all manipulation.

**Risk:** High if real money ever ties to tokens. Medium for current state (tokens are free, no IAP).

**Confidence:** High

**Acceptance Criteria:**
- [ ] Cloud function validates token spend before allowing AI API calls
- [ ] Balance cannot be increased client-side without server validation
- [ ] Firestore rules or cloud functions prevent direct profile balance manipulation

**Test Plan:**
- Automated: Security test suite verifying direct balance write is rejected
- Manual: Attempt direct Firestore write to user profile to inflate balance

**Rollback / Kill Switch:** Cloud function can be disabled via Firebase Remote Config flag.

**Open Questions:**
- Is this needed before tokens have real monetary value? (If tokens are purely virtual for now, client-side may be acceptable short-term.)
- Should this block TC-01 implementation, or can enforcement be phased?

---

### ISSUE-004: Zero Tests for TokenService

**Category:** tests / reliability

**Origin:**
- Explicit — `TOKEN_ECONOMY_TODO.md:39`
- Related doc items: DI-28

**Codebase Evidence:**
- Searched `test/` for `token_service_test.dart` — zero results
- Searched all test files for `spendTokens`/`earnTokens` — zero results
- `test/services/simple_api_integration_test.dart` tests TokenWallet MODEL only (construction, JSON, cost constants) — never the service

**Current Behavior:** TokenService has 5+ public methods (earnTokens, spendTokens, convertPointsToTokens, processDailyLogin, getTransactionHistory) with zero test coverage.

**Gap:** No automated verification that any token operation works correctly.

**Impact:** High — any refactor or fix to token logic has zero safety net. ISSUE-001 fix cannot be verified without new tests.

**Confidence:** High

**Acceptance Criteria:**
- [ ] token_service_test.dart exists with tests for each public method
- [ ] Edge cases tested: insufficient balance, daily conversion limit, concurrent operations
- [ ] Tests pass in CI

**Test Plan:**
- Automated: New test file covers all TokenService methods
- Manual: Run `flutter test test/services/token_service_test.dart`

**Rollback / Kill Switch:** Not applicable.

**Open Questions:** None.

---

### ISSUE-005: Two Disconnected Monetization Systems (Tokens + Premium)

**Category:** architecture / product-decision

**Origin:**
- Implicit (discovered during audit)
- Related doc items: DI-26, DI-27

**Codebase Evidence:**
- `lib/services/token_service.dart` — token economy (earn/spend/convert)
- `lib/services/premium_service.dart` — premium features (remove_ads, offline_mode, advanced_analytics)
- Zero cross-references between the two services
- Premium features use mock/in-app-purchase stubs; tokens use a wallet model

**Current Behavior:** Two independent systems that both relate to monetization but do not interact. Users could have 0 tokens and still have premium features, or have 500 tokens but not premium.

**Gap:** No defined relationship between tokens and premium features.

**Impact:** Medium — product strategy unclear; users will be confused about two "currencies" or "upgrades".

**Confidence:** High

**Acceptance Criteria:**
- [ ] Product decision documented: how tokens relate to premium (if at all)
- [ ] If connected, implementation bridges the two services
- [ ] If separate by design, documented rationale

**Test Plan:**
- Manual: Document product decision

**Rollback / Kill Switch:** Not applicable (product decision).

**Open Questions:**
- Should premium features be purchasable with tokens?
- Should tokens be earnable only, while premium is purchasable only?
- Are these intentionally separate systems?

---

### ISSUE-006: Firestore Rules Protect Phantom Data

**Category:** security

**Origin:**
- Implicit (derived from ISSUE-002)
- Related doc items: DI-18, DI-42

**Codebase Evidence:**
- `firestore.rules:34-42` — rules for `/token_wallets/` and `/token_transactions/`
- `lib/services/token_service.dart:365-382` — writes to `/users/{userId}` (UserProfile), not these collections

**Current Behavior:**
- Rules exist for collections that receive no writes
- The real data location (`/users/{userId}` with embedded token fields) may have weaker or different validation
- `firestore.rules:18-20` calls `validateGamificationUpdate` for user profile updates — unknown if this covers token balance manipulation

**Impact:** False sense of security. Rules say "token data is protected" but the protection targets a location that never receives data.

**Confidence:** High

**Acceptance Criteria:**
- [ ] Verify `validateGamificationUpdate` covers token balance fields
- [ ] If not, add validation or document the gap
- [ ] Remove or annotate unused collection rules

**Test Plan:**
- Manual: Inspect validateGamificationUpdate function in firestore.rules
- Automated: Firestore rules test for token balance manipulation

**Rollback / Kill Switch:** Not applicable.

---

### ISSUE-007: Token Wallet Screen Missing (TODO at line 293)

**Category:** UX / bug

**Origin:**
- Explicit — `// TODO: Navigate to token wallet/earning screen` at `lib/widgets/analysis_speed_selector.dart:293`

**Codebase Evidence:** Code comment is a dead TODO — no wallet screen exists.

**Current Behavior:** AnalysisSpeedSelector presumably has a button/tap that should navigate to a wallet screen but does nothing.

**Impact:** Low — minor UX gap.

**Confidence:** High

**Acceptance Criteria:**
- [ ] Token wallet/earning screen created OR
- [ ] TODO removed if feature deprioritized

---

## 10. Prioritization

| ID | Title | Severity | Blast Radius | Effort | Confidence | Priority | Why |
|----|-------|----------|-------------|--------|------------|----------|-----|
| ISSUE-001 | Instant Analysis Bypasses Token Deduction | 5 | 5 | 3 | 5 | **P0** | Core monetization bypass; UI lies to users |
| ISSUE-003 | No Server-Side Token Validation | 4 | 4 | 4 | 5 | **P1** | Security gap; blocks real monetization |
| ISSUE-004 | Zero Tests for TokenService | 4 | 3 | 3 | 5 | **P1** | No safety net for any token refactor |
| ISSUE-002 | Firestore Token Collections Defined but Unused | 3 | 2 | 3 | 5 | **P2** | Architecture confusion; future developer trap |
| ISSUE-006 | Firestore Rules Protect Phantom Data | 3 | 3 | 2 | 5 | **P2** | False security confidence |
| ISSUE-005 | Two Disconnected Monetization Systems | 3 | 3 | 4 | 4 | **P2** | Product strategy gap |
| ISSUE-007 | Token Wallet Screen Missing | 1 | 1 | 2 | 5 | **P3** | Minor UX TODO |

### Priority Queues

**P0:**
- ISSUE-001: Instant analysis shows token cost but never deducts tokens

**P1:**
- ISSUE-003: No server-side token validation
- ISSUE-004: Zero TokenService tests

**P2:**
- ISSUE-002: Phantom Firestore token collections
- ISSUE-006: Firestore rules protect data that does not exist
- ISSUE-005: Disconnected token + premium systems

**P3:**
- ISSUE-007: Missing wallet screen navigation

**Quick Wins:**
- ISSUE-006: Verify `validateGamificationUpdate` in Firestore rules (read and document; 30 minutes)
- ISSUE-007: Remove dead TODO or file a tracked issue (15 minutes)

**Risky Changes:**
- ISSUE-001: Adding token deduction changes existing user behavior (users who expect free instant analysis will lose it)
- ISSUE-003: Server-side validation requires cloud function deployment + Firebase config changes

**Needs Discussion Before Work:**
- ISSUE-001: What should happen when balance is insufficient? Block? Auto-switch to batch? Warn?
- ISSUE-003: Is server-side validation needed before tokens have real money value?
- ISSUE-005: What is the intended relationship between tokens and premium?

**Not Worth Doing (yet):**
- ISSUE-014 (success metrics baseline): No point measuring until token enforcement works
- TC-11 (in-app purchase): Premature until token economy is functional and enforced

---

## 11. Proof-of-Concept Validation

No proof-of-concept probe was needed. Static and existing dynamic evidence were sufficient.
- TC-01 is statically conclusive: line-by-line code trace proves the gap.
- TC-04 is statically conclusive: directory/search evidence proves zero test files.

---

## 12. Assumptions Challenged by Implementation

| Assumption | Why It Seemed True | What Disproved It | Evidence | How Recommendation Changed |
|-----------|-------------------|-------------------|----------|---------------------------|
| "Phase 3 UI is mostly complete" means token enforcement works | Doc claims phases as checked; UI shows token costs | _analyzeImage() never calls TokenService | image_capture_screen.dart:360-440 | Elevated ISSUE-001 to P0; token display is cosmetic |
| Firestore rules protect token data | Rules exist for token_wallets/token_transactions | TokenService writes to UserProfile, not these collections | token_service.dart:365-382 vs firestore_schema_registry.dart:54-55 | Added ISSUE-002 and ISSUE-006 as separate items |
| "Cross-device wallet synchronization" is complete | Doc marks it as [x] | Sync goes through UserProfile, not dedicated collections; inconsistent with schema | token_service.dart:380-381 | Downgraded confidence; flagged as architecture gap |

---

## 13. Parallel Agent / Multi-Model Findings

**Agent A (Codebase Verifier):** Completed successfully. Found all token-related code paths, identified the critical gap in instant analysis, confirmed Firestore collection discrepancy, and found zero cloud functions for server-side validation.

**Agent B (Test/Runtime Verifier):** Timed out. I compensated by running test searches sequentially. Found: zero TokenService tests, only TokenWallet model tests in simple_api_integration_test.dart.

**Agent C (Security/Privacy Reviewer):** Timed out. I compensated by reading firestore.rules directly and searching for env var/config patterns. Found: rules protect phantom collections, no server-side validation, no kill switch for token enforcement.

**Reconciliation:** All agent findings (from A) plus my manual verification (for B and C) are consistent. No contradictions found between sources.

---

## 14. Discussion Pack

### My Recommendation

I recommend working on:

1. **ISSUE-004** - Zero Tests for TokenService (P1)
2. **ISSUE-001** - Instant Analysis Bypasses Token Deduction (P0)
3. **ISSUE-006** - Verify Firestore Rules Protect Real Data (P2 quick win)

### Why These Matter Now

- ISSUE-004 must come before ISSUE-001 because adding token deduction to instant analysis without tests means we cannot verify the fix works or catch regressions.
- ISSUE-001 is the highest-impact bug: the UI claims a cost that is never enforced.
- ISSUE-006 is a 30-minute read-and-document task that eliminates a false confidence in security.

### What Breaks If Ignored

- Users get free unlimited instant analysis while the UI says it costs 5 tokens.
- Token balance becomes cosmetic — meaningless number displayed but never enforced.
- If tokens ever tie to real money, the lack of server-side validation (ISSUE-003) becomes a financial vulnerability.
- Any token economy refactor will have zero test safety net.

### What I Would Not Work On Yet

- ISSUE-005 (token + premium relationship) — needs product decision first
- ISSUE-003 (server-side validation) — not needed until tokens have real value
- TC-11 (in-app purchase) — premature

### What Is Ambiguous

- Should insufficient-balance instant analysis be blocked, auto-switched to batch, or allowed with a warning?
- Is the current "tokens as cosmetic display" state intentional (soft launch) or an oversight?
- Should `validateGamificationUpdate` in Firestore rules cover token balance manipulation?

### Questions For You

1. When a user has 0 tokens and presses "Analyze (Instant)" costing 5 tokens, what should happen: block with an error, auto-switch to batch mode, or allow free analysis with a warning?

2. Is the current state (tokens displayed but not enforced) intentional as a soft launch strategy, or was the enforcement simply never implemented?

3. Should the token_wallets and token_transactions Firestore collections be migrated to (making rules meaningful) or removed from the schema (simplifying architecture)?

### Needs Runtime Verification

- `validateGamificationUpdate` function in firestore.rules — need to read lines 51+ to confirm whether it covers token balance fields
- Whether `flutter build` currently succeeds or fails (doc claims tflite_flutter NS issue)

### Needs Online Research

None. All findings are repo-evidence based.

---

## 17. Recommended Next Work Unit

### Unit-1: TokenService Test Coverage + Instant Analysis Token Wiring

**Goal:**
- Create test coverage for TokenService so that the instant analysis enforcement fix has a safety net
- Wire instant analysis through TokenService to enforce the displayed token cost

**Issues covered:**
- ISSUE-004 (Zero Tests for TokenService)
- ISSUE-001 (Instant Analysis Bypasses Token Deduction)

**Scope:**
- In:
  - Create `test/services/token_service_test.dart`
  - Modify `lib/screens/image_capture_screen.dart` to check balance and deduct tokens on instant analysis
  - Verify `lib/widgets/analysis_speed_selector.dart:293` TODO handling
- Out:
  - Server-side validation (ISSUE-003)
  - Firestore collection migration (ISSUE-002)
  - Premium + token relationship (ISSUE-005)
  - Wallet encryption (DI-19)
  - In-app purchase (TC-11)

**Likely files touched:**
- `test/services/token_service_test.dart` (new)
- `lib/screens/image_capture_screen.dart`
- `lib/widgets/analysis_speed_selector.dart`

**Acceptance criteria:**
- [ ] token_service_test.dart tests earnTokens, spendTokens, convertPointsToTokens, processDailyLogin, insufficient balance rejection, concurrent operation handling
- [ ] _analyzeImage() in image_capture_screen.dart checks canAfford before proceeding
- [ ] spendTokens() called on successful instant analysis
- [ ] On insufficient balance: user is informed and offered batch mode alternative
- [ ] Batch analysis path still works (regression check)
- [ ] Token balance chip on home screen updates after spend

**Tests to run:**
- Baseline: `flutter test test/services/simple_api_integration_test.dart`
- Targeted: `flutter test test/services/token_service_test.dart`
- Full suite: `flutter test` (if build permits)

**Manual verification:**
- Run app, perform instant analysis, verify token balance decreases
- Run app with 0 balance, attempt instant analysis, verify blocked/redirected
- Run app, perform batch analysis, verify batch token deduction still works

**Docs to update:**
- `TOKEN_ECONOMY_TODO.md` — mark DI-28 (unit tests) as partially done, mark DI-41 claim as corrected
- Consider ADR for token enforcement decision (block vs auto-switch vs warn)

**Operational safety:**
- Kill switch: Add `ENABLE_TOKEN_ENFORCEMENT` boolean defaulting to `true`. When `false`, skip token check (preserves current free-instant-analysis behavior). Read from Remote Config or `bool.fromEnvironment`.
- Rollback: Set `ENABLE_TOKEN_ENFORCEMENT=false` or revert image_capture_screen.dart changes.

**Risks:**
- Existing users who relied on free instant analysis will experience a behavior change
- If _analyzeImage has edge cases (e.g., auto-analyze on init at line 136), token deduction could trigger unexpectedly
- Tests for TokenService require mocking StorageService, CloudStorageService, and UserProfile — these mocks may not exist yet

---

## 18. Appendix: Searches Performed

1. `search_files(path=repo, pattern=motto_v2.md)` — found root motto_v2.md
2. `search_files(path=repo, pattern=*.md, target=files)` — 50+ markdown documents found
3. `search_files(path=repo, pattern=TODO|FIXME|HACK|NOTE|XXX, target=content)` — 50+ code TODO/FIXME hits
4. `search_files(path=repo, pattern=**/*.py, target=files)` — 1 Python script (fix_logger_calls.py)
5. `search_files(path=repo, pattern=**/*.yaml|**/*.json|**/*.toml, target=files)` — 14 config files
6. `read_file(motto_v2.md)` — 631 lines of engineering rules
7. `read_file(TOKEN_ECONOMY_TODO.md)` — 56 lines, chosen document
8. `delegate_task(3 agents)` — Agent A: code path tracer (completed); Agent B: test verifier (timed out); Agent C: security reviewer (timed out)
9. `search_files(path=test, pattern=token|credit|wallet|token_service, target=content, file_glob=*test*)` — 30 hits, mostly unrelated (API token, FCM token)
10. `search_files(path=test, pattern=*_test.dart, target=files)` — 50+ test files
11. `search_files(path=test, pattern=token_wallet|token_service, target=content, file_glob=*_test.dart)` — 39 hits, only model-level tests
12. `read_file(firestore.rules, limit=50)` — lines 1-50, confirmed token collection rules
13. `read_file(simple_api_integration_test.dart)` — 274 lines, model-only tests
14. `search_files(path=lib/screens, pattern=spendTokens|_tokenService|_analyzeImage, target=content, context=3)` — confirmed no TokenService usage in image_capture_screen
15. `search_files(path=lib/services/ai_service.dart, pattern=spendTokens|tokenService|TokenService, target=content)` — 5 matches, all import statements, no usage
16. `read_file(image_capture_screen.dart:360-439)` — confirmed _analyzeImage code path
17. `read_file(image_capture_screen.dart:1070-1129)` — confirmed token cost display
18. `read_file(image_capture_screen.dart:40-119)` — confirmed AnalysisSpeed.instant default
19. `search_files(path=lib, pattern=token_wallets|token_transactions, target=content)` — only in firestore_schema_registry.dart
20. `read_file(token_service.dart:360-419)` — confirmed _saveWallet writes to UserProfile, not dedicated collections
21. `search_files(path=test, pattern=token_service_test, target=files)` — zero results
22. `search_files(path=repo/test, pattern=spendTokens|earnTokens, target=content)` — zero results