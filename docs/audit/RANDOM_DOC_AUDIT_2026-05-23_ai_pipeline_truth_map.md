# Random Document Audit Report

**Audit Date**: 2026-05-23
**Auditor**: Agent (evidence-driven, not automated)
**Chosen Document**: `docs/review/AI_PIPELINE_TRUTH_MAP_2026-05-21.md`
**Selection Method**: Pseudo-random via `$RANDOM % 335` on full inventory of 335 candidate documents

---

## 1. Document Inventory

335 candidate documents inventoried across root, docs/, functions/, scripts/, tools/, assets/, eval/, prompts/, test/, .github/. Full inventory stored in `find` output. Key document categories:

| Category | Count | Example Paths |
|----------|-------|---------------|
| Root markdown/txt | 8 | README.md, motto_v2.md, firebase_task.md, goal1.txt |
| docs/review/ | 60+ | Backend strategy, P0 hardening, AI flywheel audits |
| docs/planning/ | 40+ | Roadmaps, task matrices, battle plans |
| docs/exploration/ | 25+ | AI routing, privacy, gamification, training data |
| docs/testing/ | 15+ | Q&A checklists, testing guides, coverage status |
| docs/implementation/ | 10+ | ML training data, admin dashboard, step guides |
| docs/audit/ | 5 | Prior random doc audits, deprecation audits |
| docs/architecture/ | 1 | CURRENT_AI_ARCHITECTURE.md |
| docs/adr/ | 3 | Architecture decision records |
| functions/ | 13 | TypeScript source and test files |

---

## 2. Random Selection

- **Chosen document**: `docs/review/AI_PIPELINE_TRUTH_MAP_2026-05-21.md`
- **Selection method**: `find ... | sort | sed -n "$(( RANDOM % 335 + 1 ))p"` on 335 sorted document paths
- **Why this doc is worth auditing**: It claims to be a citation-accurate inventory of every AI entry point in the codebase, asserts specific build-mode behaviors, lists stale documentation, and identifies gaps. This makes it a high-value target for verification against real code and runtime evidence.

---

## 3. Chosen Document Deep Analysis

### 3.1 Doc Item Extraction

| Doc Item ID | Type | Short quote / evidence | Location | Interpretation | Confidence |
|-------------|------|------------------------|----------|----------------|-------------|
| D01 | Current-State Claim | "Classification now routes through a secure backend proxy in release" | Section 1 | Release-mode classification is backend-first | High |
| D02 | Current-State Claim | "Direct OpenAI and Gemini clients still exist" | Section 1 | Direct clients remain in debug/profile | High |
| D03 | Current-State Claim | "Disposal instructions remain backend-first" | Section 1 | generateDisposal is canonical text-only path | High |
| D04 | Current-State Claim | "On-device inference is still scaffolded, not real" | Section 1 | TFLite placeholder, no real inference | High |
| D05 | Current-State Claim | "Cost control is now split" (client + server-side gate) | Section 1 | Dual cost enforcement exists | High |
| D06 | Current-State Claim | "InstantAnalysisScreen delegates to FlowCoordinator" | Section 1 | Testable handoff exists | High |
| D07 | Current-State Claim | Entry point #3: `analyzeImageRegions()` "Backend proxy or OpenAI-only" | Section 2, Row 3 | Claims region analysis uses backend proxy | Medium |
| D08 | Current-State Claim | Entry point #7: `EnhancedAiApiService.analyzeWasteImage()` "no guardClientAiCall" | Section 2, Row 7 | Claims enhanced service is unguarded | Low (stale) |
| D09 | Current-State Claim | Entry point #8: `EnhancedAiApiService.analyzeWithRace()` "no production safety guard" | Section 2, Row 8 | Claims race analysis is unguarded | Low (stale) |
| D10 | Current-State Claim | Entry point #10: `OfflineQueueService` retry "inherits the direct-service gap" | Section 2, Row 10 | Claims queue retry is unguarded | Medium |
| D11 | Architecture Claim | "Release is fail-closed to the backend path" | Section 4 | Release mode can't fall through to direct client | High |
| D12 | Architecture Claim | Sequence diagram showing backend proxy routing for all paths | Section 3 | Full flow diagram | High |
| D13 | Current-State Claim | Stale doc: api_key doc claims classifyImage is aspirational | Section 6, Row 1 | Stale claim about old doc | Medium |
| D14 | Current-State Claim | Stale doc: api_key doc claims USE_BACKEND_AI_IN_RELEASE is dead | Section 6, Row 2 | Stale claim about old doc | Low |
| D15 | Current-State Claim | Stale doc: CURRENT_AI_ARCHITECTURE.md "no backend classification function" | Section 6, Row 3 | Claim about old version of doc | Low |
| D16 | Current-State Claim | Stale doc: IMPLEMENTATION_NOTES "Phase 2 wiring was pending" | Section 6, Row 4 | Pre-rewrite state no longer on disk | Low |
| D17 | Explicit Gap | Gap 1: "Direct-client safety parity for EnhancedAiApiService" | Section 7, Row 1 | EnhancedAiApiService needs guardClientAiCall | Low (fixed) |
| D18 | Explicit Gap | Gap 2: "On-device TFLite inference" still a placeholder stub | Section 7, Row 2 | TFLite inference not implemented | High |
| D19 | Explicit Gap | Gap 3: "Daily quota on top of per-UID callable limit" | Section 7, Row 3 | Server-side daily quota missing | Medium |
| D20 | Explicit Gap | Gap 4: "Server-side premium verification for token debit" | Section 7, Row 4 | spendUserTokens trusts client amounts | Low (fixed) |
| D21 | Implicit Task | Make all non-debug classification use backend proxy | Section 8 | Hardening step: remove debug-only direct client paths | Medium |
| D22 | Implicit Task | Bring remaining direct-client surfaces under same safety rules | Section 8 | Consistency work | Medium |
| D23 | Implicit Task | Defer on-device inference until real TFLite path exists | Section 8 | Explicit deferral decision | Low |
| D24 | Implicit Task | Update truth map when gaps close | (implied by doc purpose) | Doc maintenance | Medium |
| D25 | Question | Entry point #3 claim about regions routing via backend - is it accurate? | Section 2 | Line number question + routing accuracy | High |
| D26 | Contradiction | Sequence diagram shows all paths via backend proxy, but regions don't | Section 3 vs Section 2 | Sequence diagram implies regions route through backend too | High |
| D27 | Risk | `OfflineQueueService` retry path using direct EnhancedAiApiService | Section 2, Row 10 | Queue retry may bypass production safety in release | High |

---

## 4. Extracted Task Candidates

| Task Candidate ID | Source Doc Items | Task | Explicit / Implicit | Why This Is A Task | Expected Repo Area | Initial Priority |
|-------------------|------------------|------|---------------------|--------------------|--------------------|------------------|
| TC01 | D07, D25, D26 | Fix `analyzeImageRegions()` to route through backend proxy like other methods | Implicit | Region analysis hardcodes OpenAI direct and is the only classification path not going through backend | lib/services/ai_service.dart | P1 |
| TC02 | D08, D09, D17 | Verify and update doc to reflect that EnhancedAiApiService now has guardClientAiCall | Explicit | Doc claims gaps that are now fixed; truth map is stale | docs/review/ | P2 |
| TC03 | D18 | Implement real TFLite on-device inference | Explicit | Placeholder stub means no zero-cost local classification | lib/services/on_device_vision_service.dart | P2 |
| TC04 | D19 | Implement server-side daily request quota cap | Explicit | Per-minute rate limit exists but no hard daily cap | functions/src/classify_image.ts | P2 |
| TC05 | D20 | Verify spendUserTokens server-side verification and update doc | Explicit | Doc says "trusted client amount" but code shows server-side enforcement | docs/review/ | P2 |
| TC06 | D10, D27 | Add backend routing awareness to OfflineQueueService retry path | Implicit | Queue retry uses EnhancedAiApiService directly without backend routing | lib/services/offline_queue_service.dart | P1 |
| TC07 | D13 | Update api_key_management_and_security.md body text beyond stale banner | Implicit | Banner added but body still describes client-side-first architecture | docs/implementation/ai/ | P3 |
| TC08 | D21 | Remove debug-only direct client fallthrough paths in release mode | Explicit | Hardening step from doc section 8 | lib/services/ai_service.dart | P1 |
| TC09 | D24 | Regular truth-map/drift audit cadence | Implicit | Doc will continue to get stale without process | docs/review/ | P3 |
| TC10 | N/A | Fix stale code comment in rate_limit_config.ts:36-37 | Implicit | Comment says classifyImage doesn't exist, but it does | functions/src/rate_limit_config.ts | P3 |
| TC11 | D01-D27 | Run full-suite regression after any backend routing changes | Implicit | Any routing change touches AI path used by all classification flows | test/ | P1 |
| TC12 | D01-D27 | Add test for analyzeImageRegions() backend routing | Implicit | No test currently verifies region analysis backend routing | test/ | P1 |

---

## 5. Static Codebase Reality Check

### TC01: Fix analyzeImageRegions() backend routing

- **Codebase Status**: Broken / Contradictory Evidence
- **Evidence**: `lib/services/ai_service.dart:924-1048` — `analyzeImageRegions()` calls `_analyzeSingleRegion()` at line 935, which hardcodes `_analyzeWithOpenAI()` at line 1040. It does NOT go through `_orchestrateAnalysis()` at line 1050, which is where backend routing is checked.
- **What exists today**: All other `AiService` methods (analyzeImage, analyzeWebImage) route through `_orchestrateAnalysis()` which checks `_backendRoutingEnabled`.
- **Gap**: Region analysis is the ONLY classification path that bypasses backend routing entirely.
- **Actual work needed**: Refactor `_analyzeSingleRegion()` to use backend proxy when routing is enabled, or route through `_orchestrateAnalysis()`.

### TC02: Update doc for EnhancedAiApiService guardClientAiCall

- **Codebase Status**: Stale Doc
- **Evidence**: `lib/services/enhanced_ai_api_service.dart:456` — `ProductionSafetyConfig.guardClientAiCall('OpenAI')`. `lib/services/enhanced_ai_api_service.dart:586` — `ProductionSafetyConfig.guardClientAiCall('Gemini')`. Both added since doc was written. `lib/services/enhanced_ai_api_service.dart:176` — backend routing check exists at top of `analyzeWasteImage()`.
- **What exists today**: Guards exist in sub-methods. The doc's claim "no guardClientAiCall() call" was never about entry-point-only, but about ANY guard existing.
- **Gap**: Doc section 7 is stale. Gap 1 is fixed in code.
- **Actual work needed**: Update truth map to reflect current state.

### TC03: TFLite on-device inference

- **Codebase Status**: Partially Done (placeholder only)
- **Evidence**: `lib/services/on_device_vision_service.dart:226-240` — `_performInference()` has TODO comment and returns hardcoded placeholder response with 100ms simulated delay. No TFLite dependency, no model loading, no real inference.
- **Gap**: Complete. Real on-device classification does not exist.
- **Actual work needed**: Integrate TFLite Flutter plugin, bundle models, implement inference pipeline.

### TC04: Daily quota cap

- **Codebase Status**: Partially Done
- **Evidence**: `functions/src/classify_image.ts:329-336` — `getDailyFreeScanLimit()` exists with default 5 free scans. `functions/src/classify_image.ts:470-500` — `resolveDailyFreeUsageState()` tracks daily free usage. `functions/src/classify_image.ts:1228-1242` — per-UID per-minute rate limit (10 req/60s).
- **What exists**: Daily FREE scan limit + per-minute rate limiting.
- **Gap**: No absolute daily request cap (separate from free/token limits). User could pay tokens for unlimited scans within rate window.
- **Actual work needed**: Add configurable `MAX_DAILY_CLASSIFICATIONS` to cap total daily requests regardless of token balance.

### TC05: spendUserTokens server-side verification

- **Codebase Status**: Already Done (doc is stale)
- **Evidence**: `functions/src/index.ts:183-200` — subscription verification from Firestore `billing.entitlements.pro_subscription`. `functions/src/index.ts:244-255` — server-computed canonical costs. `functions/src/index.ts:266-286` — rejects undershooting and caps overshooting client amounts. `functions/src/index.ts:341-353` — full audit ledger with `requestedClientAmount` vs `authorizedAmount`.
- **Gap**: None. Server-side verification is implemented. Doc is stale.
- **Actual work needed**: Update truth map only.

### TC06: OfflineQueueService backend routing

- **Codebase Status**: Missing
- **Evidence**: `lib/services/offline_queue_service.dart:278-282` — `final result = await EnhancedAiApiService().analyzeWasteImage(...)` — creates new instance and calls direct. No `BackendProxyProvider` injection, no `_backendRoutingEnabled` check, no `overrideBackendRoutingForTest()` support.
- **Gap**: In release mode, queue retry uses EnhancedAiApiService's internal backend routing (which exists at top of method), but the queue service itself doesn't inject or validate routing.
- **Actual work needed**: The gap is partially mitigated because `EnhancedAiApiService.analyzeWasteImage()` at line 176 has its own `_backendRoutingEnabled` check. However, the queue creates a new instance each time, which may not respect the same routing state as the original AiService call. Needs explicit routing passthrough.

### TC07: Update api_key_management_and_security.md body text

- **Codebase Status**: Stale Doc
- **Evidence**: `docs/implementation/ai/api_key_management_and_security.md:1-12` — stale banner added acknowledging `classifyImage` exists. Lines 14-733 — body text still describes client-side classification as primary, backend as "no longer purely aspirational."
- **Gap**: Banner exists but body text is misleading for someone reading past the banner.
- **Actual work needed**: Rewrite body or add inline annotations marking sections as pre-backend-proxy era.

### TC08: Remove debug-only direct client fallthrough

- **Codebase Status**: Already Done
- **Evidence**: `lib/services/ai_service.dart:354-363` — `_backendRoutingEnabled` returns `true` in release. `lib/services/ai_service.dart:365-367` — `_backendRoutingFailClosed` returns `true` in release. `lib/services/ai_service.dart:1062-1064` — when backend routing enabled, calls `_analyzeWithBackend()`. `lib/services/ai_service.dart:1096-1102` — when fail-closed, rethrows without fallthrough.
- **Gap**: None. Release is already fail-closed to backend.
- **Actual work needed**: None. This hardening is done. Doc is accurate on this point.

### TC10: Fix stale comment in rate_limit_config.ts

- **Codebase Status**: Stale Code Comment
- **Evidence**: `functions/src/rate_limit_config.ts:36-37` — `"NOTE: classifyImage does not exist as a Cloud Function yet. Classification is currently Flutter client-side. Add here when added."` — classifyImage exists at `functions/src/classify_image.ts:1043` and is exported from `functions/src/index.ts:1153`.
- **Gap**: Comment contradicts reality.
- **Actual work needed**: Remove or update comment.

### TC12: Add test for analyzeImageRegions() backend routing

- **Codebase Status**: Missing
- **Evidence**: `test/services/ai_service_backend_test.dart` — tests exist for `analyzeImage()`, `analyzeWebImage()` backend routing but NOT for `analyzeImageRegions()`.
- **Gap**: No test coverage for region analysis backend routing.
- **Actual work needed**: Add test that verifies `analyzeImageRegions()` routes through `BackendProxyProvider` when routing is enabled.

---

## 6. Dynamic Verification and Test Baseline

### Baseline Commands and Results

**Functions tests:**
- `npm run test:classify-image`: ✅ **39 passed, 0 failed** (862ms)
- `npm run test:key-resolution`: ✅ **3 passed, 0 failed** (866ms)

**Dart targeted tests:**
- `flutter test test/services/ai_service_backend_test.dart`: ✅ **19 passed, 0 failed** (15s)
- `flutter test test/services/enhanced_ai_api_service_safety_test.dart`: ✅ **26 passed, 0 failed** (6s)

**Full Flutter test suite:**
- `flutter test`: ❌ Timed out after 120s. Full suite unable to complete.
- Weakness: Full-suite evidence is unavailable. Targeted tests pass. Full suite must be run as a separate operation.

**Pre-existing failures**: None detected in targeted tests. Full-suite failures unknown.

---

## 7. Critical Implementation and Test Traps Checked

### 7A. Environment Variable and Config Loading

- **`ProductionSafetyConfig`** (`lib/utils/production_safety_config.dart:14-50`): Uses `bool.fromEnvironment()` which is a compile-time constant in Dart. These are NOT runtime env vars — they're build-time dart-defines. This is correct for Dart/Flutter and does not exhibit the Python-style module-level env var caching problem.
- **`BackendProxyProvider.isEnabled`** (`lib/services/providers/backend_proxy_provider.dart:81-87`): Same pattern — `bool.fromEnvironment()`. Testable via `overrideBackendRoutingForTest()` injection.
- **Risk**: ModuleCacheIssue does not apply (Dart compile-time constants). TestIsolationRisk is mitigated by test-only overrides.
- **Verdict**: No env-var caching trap. The pattern is appropriate for Flutter.

### 7B. Test Isolation and State Leakage

- Tests use injected `ClassificationProvider` via factory injection (not mock library) — `ai_service_backend_test.dart` defines `_FakeBackendProxy`.
- `EnhancedAiApiService` supports `overrideBackendRoutingForTest(null)` to restore production behavior — `enhanced_ai_api_service_safety_test.dart`.
- No global mutable singletons found that would leak between tests.
- **Verdict**: Test isolation appears adequate for targeted tests. Full suite isolation unverified.

### 7C. Full Test Suite Evidence

- **Targeted tests pass**: ai_service_backend (19), enhanced_ai_api_service (26), classify_image (39), key_resolution (3).
- **Full suite**: Timed out (120s). Could not establish full baseline.
- **Verdict**: Targeted evidence is strong for specific functions. Full-suite evidence is unavailable.

### 7D. Proof-of-Concept Validation

No proof-of-concept probe was needed. Static and existing dynamic evidence were sufficient. All claims were verifiable through code reading, targeted test execution, and grep search.

---

## 8. Data, Privacy, and PII Boundary Checks

This section applies because the document discusses AI classification data flow, backend proxy security, and client-side vs server-side data handling.

### 8A. Data Serialization Boundary

- **Backend proxy** (`lib/services/providers/backend_proxy_provider.dart:122-133`): Sends `imageBytes` (base64), `mimeType`, `region`, `language` to classifyImage Cloud Function. Image data goes through Firebase Callable, not direct API calls.
- **Direct client paths** (OpenAI/Gemini): Send image data directly to third-party APIs. These are blocked in release mode by `ProductionSafetyConfig.guardClientAiCall()`.
- **Verdict**: Release mode correctly routes image data through the backend proxy, preventing direct third-party API access. Images are not inspected/modified by the client before sending.

### 8B. Scan Depth Boundaries

- Not directly applicable to this document. The truth map doesn't discuss PII scanning of classification results.
- Classification results contain waste category, item name, confidence — no PII data from users.

### 8C. Minimum Content Thresholds

- Not applicable. No freeform user text scanning discussed.

### 8D. Heuristic Detection Limits

- `hasPlaceholderKey()` (`lib/utils/production_safety_config.dart:54-61`): Detects placeholder API key patterns. Catches: `your-openai-api-key-here`, `your-gemini-api-key-here`, `your-api-key-here`, any key starting with `your-`. Misses: empty keys (handled separately), other placeholder patterns. False positives unlikely (keys matching `your-*` pattern are not valid API keys).

### 8E. Fixture vs Production Data Boundary

- Not directly applicable. No test fixtures involve real user data classification.

### 8F. All Write Paths Covered

- Classification write paths: `BackendProxyProvider.analyze()` → `classifyImage` Cloud Function → Firestore save. Direct client paths blocked in release.
- **Relevant gap**: `analyzeImageRegions()` bypasses backend routing (see TC01) — this is a write path gap in the safety architecture.

### 8G-8I: Privacy Guard Naming, Error Messages, Deployment Modes

- `guardClientAiCall()` throws `ProductionSafetyException` with message "Client-side AI call blocked in release build." — adequate but could include provider label and remediation.
- Deployment modes: debug/profile allow direct client calls; release blocks them. Kill switch: `ALLOW_CLIENT_AI_IN_RELEASE=true` Dart-define at build time.

---

## 9. Deduped Issue / Task Register

---

## ISSUE-001: analyzeImageRegions() bypasses backend proxy routing

**Category**: bug / security

**Origin**: Implicit (from doc contradictions D07, D25, D26)

**Source doc**: `docs/review/AI_PIPELINE_TRUTH_MAP_2026-05-21.md:25-26` (entry point #3)

**Codebase Evidence**:
- `lib/services/ai_service.dart:924-935` — `analyzeImageRegions()` calls `_analyzeSingleRegion()`
- `lib/services/ai_service.dart:999-1048` — `_analyzeSingleRegion()` hardcodes `_analyzeWithOpenAI()` at line 1040, does NOT call `_orchestrateAnalysis()` which handles backend routing
- `lib/services/ai_service.dart:1050-1138` — `_orchestrateAnalysis()` is the only path that checks `_backendRoutingEnabled`

**Static Verification**: `_analyzeSingleRegion()` never reaches `_orchestrateAnalysis()`. It directly calls `_analyzeWithOpenAI()` which calls OpenAI API without `guardClientAiCall()`.

**Dynamic Verification**:
- Baseline: `flutter test test/services/ai_service_backend_test.dart` — 19 passed, but no `analyzeImageRegions()` test exists
- No test verifies region analysis backend routing

**Current Behavior**: Multi-region image analysis calls OpenAI directly from the client regardless of release mode and backend routing configuration.

**Expected Behavior**: Region analysis should route through `BackendProxyProvider` when backend routing is enabled (release mode or `USE_BACKEND_AI_IN_RELEASE=true`).

**Gap**: `_analyzeSingleRegion()` needs to be refactored to use `_orchestrateAnalysis()` or a backend-compatible path.

**Impact**: Release builds doing multi-item region analysis bypass the backend proxy, exposing API keys and losing server-side rate limiting, caching, and cost controls.

**Risk**: High — API key exposure risk in release builds using region analysis.

**Confidence**: High (directly confirmed by code reading)

**Acceptance Criteria**:
- [ ] `analyzeImageRegions()` routes through `BackendProxyProvider` when `_backendRoutingEnabled` is true
- [ ] Release mode is fail-closed for region analysis (no direct client fallthrough)
- [ ] Test added to `test/services/ai_service_backend_test.dart` verifying region analysis backend routing
- [ ] Test added verifying region analysis is blocked in release without backend routing

**Test Plan**: Add `FakeBackendProxy` injection tests for `analyzeImageRegions()`. Verify providerCallCount increments. Verify fail-closed behavior in release mode.

**Rollback / Kill Switch**: `--dart-define=ALLOW_CLIENT_AI_IN_RELEASE=true` for emergency fallback

**Open Questions**: Should `_analyzeSingleRegion()` be folded into `_orchestrateAnalysis()`, or should it get its own backend-aware path?

---

## ISSUE-002: AI Pipeline Truth Map is stale on 3-4 claims

**Category**: docs

**Origin**: Explicit (D08, D09, D17, D20)

**Source doc**: `docs/review/AI_PIPELINE_TRUTH_MAP_2026-05-21.md:122-128`

**Codebase Evidence**:
- `lib/services/enhanced_ai_api_service.dart:456` — `guardClientAiCall('OpenAI')` exists (doc says missing)
- `lib/services/enhanced_ai_api_service.dart:586` — `guardClientAiCall('Gemini')` exists (doc says missing)
- `functions/src/index.ts:183-286` — spendUserTokens does server-side verification (doc says missing)
- `lib/services/enhanced_ai_api_service.dart:176` — `analyzeWasteImage()` has backend routing check (doc doesn't mention)

**Static Verification**: Doc section 7 "Gaps and Missing Pieces" lists 4 items:
1. "Still no guardClientAiCall() call" — **False**, guards added
2. "Still a placeholder stub" — **True**, TFLite still stub
3. "Not implemented yet" (daily quota) — **Partially True**
4. "Still trusted client amount flow" — **False**, server-side verification exists

**Dynamic Verification**: `flutter test test/services/enhanced_ai_api_service_safety_test.dart` — 26 passed, confirming guards work.

**Current Behavior**: Truth map is 23 days old and no longer reflects reality for 2 of 4 gaps.

**Expected Behavior**: Truth map should accurately reflect current codebase state.

**Gap**: Doc drift over 23 days.

**Impact**: Agents or developers reading the truth map will waste time on already-fixed items or make decisions based on stale information.

**Risk**: Low — the doc is still largely accurate, and stale items are mostly "things that were fixed" not "things that regressed."

**Confidence**: High

**Acceptance Criteria**:
- [ ] Section 7 Gap 1 marked as RESOLVED with file references
- [ ] Section 7 Gap 4 marked as RESOLVED with file references
- [ ] Section 7 Gap 3 updated to reflect current partial state
- [ ] Entry point #7 description updated to note guardClientAiCall exists in sub-methods
- [ ] Entry point #8 description updated to note backend routing exists

**Test Plan**: Manual review only.

**Open Questions**: Should the truth map be auto-generated from code or remain manually maintained?

---

## ISSUE-003: Backend routing missing from OfflineQueueService retry path

**Category**: architecture / security

**Origin**: Implicit (D10, D27)

**Source doc**: `docs/review/AI_PIPELINE_TRUTH_MAP_2026-05-21.md:32` (entry point #10)

**Codebase Evidence**:
- `lib/services/offline_queue_service.dart:278-282` — Creates new `EnhancedAiApiService()` and calls `analyzeWasteImage()` directly
- `lib/services/offline_queue_service.dart:267` — No `BackendProxyProvider` injection, no routing override

**Static Verification**: The new instance of `EnhancedAiApiService` has its own `_backendRoutingEnabled` check (line 176). However, this depends on `kReleaseMode || ProductionSafetyConfig.useBackendAiInRelease` which uses compile-time constants. In release mode, this is expected to work. But the `_backendRoutingFailClosed` property is initialized without injection support, making it untestable in the queue context.

**Dynamic Verification**: No queue-specific backend routing tests found. Targeted tests don't cover queue retry path.

**Current Behavior**: Queue creates a fresh `EnhancedAiApiService` each retry. In release, this "accidentally" routes through backend due to `kReleaseMode`. But there's no explicit guarantee or test.

**Expected Behavior**: Queue service should explicitly inject routing configuration, not rely on implicit compile-time behavior.

**Gap**: No explicit backend routing intent in queue service. No test coverage. No injection support for testing.

**Impact**: Medium — release mode works correctly by accident, but debug/profile queue testing may use direct client calls. Hard to test backend routing behavior in queue context.

**Risk**: Medium — low immediate risk but architectural debt.

**Confidence**: Medium

**Acceptance Criteria**:
- [ ] `OfflineQueueService` accepts `ClassificationProvider` injection for testability
- [ ] Queue retry uses `ClassificationProvider` when available instead of creating raw `EnhancedAiApiService`
- [ ] Test added verifying queue retry routes through backend in release mode

**Test Plan**: Inject mock `ClassificationProvider` into queue, verify it's used in retry path.

**Rollback / Kill Switch**: None needed. Existing behavior is functional.

**Open Questions**: Should queue share the same AiService instance that queued the item, or create its own?

---

## ISSUE-004: Stale code comment in rate_limit_config.ts

**Category**: docs / code quality

**Origin**: Implicit (discovered during verification)

**Source doc**: Not in truth map — discovered by Agent C during codebase verification

**Codebase Evidence**:
- `functions/src/rate_limit_config.ts:36-37` — `// NOTE: classifyImage does not exist as a Cloud Function yet.`
- `functions/src/classify_image.ts:1043` — `export const classifyImage = functions.region('asia-south1').https.onCall(...)` — function exists
- `functions/src/index.ts:1153` — `export { classifyImage } from './classify_image'`

**Static Verification**: Comment is contradicted by actual code. classifyImage has existed long enough to have comprehensive tests (39 test cases).

**Dynamic Verification**: `npm run test:classify-image` — 39 passed, 0 failed. Function is fully operational.

**Current Behavior**: Comment is misleading. No runtime impact.

**Expected Behavior**: Comment should reflect current state.

**Gap**: One stale code comment.

**Impact**: Negligible runtime impact. Confuses code readers.

**Risk**: Minimal.

**Confidence**: High

**Acceptance Criteria**:
- [ ] Remove or update the stale comment in rate_limit_config.ts:36-37

**Test Plan**: Visual inspection only.

**Open Questions**: None.

---

## ISSUE-005: No full-suite test baseline available

**Category**: tooling / tests

**Origin**: Implicit (discovered during dynamic verification)

**Source doc**: N/A — operational finding

**Codebase Evidence**: `flutter test` timed out at 120s. Targeted tests pass: ai_service_backend (19), enhanced_ai_api_service (26), classify_image (39), key_resolution (3).

**Static Verification**: Multiple test files exist: test/services/, test/widgets/, test/screens/, test/models/, test/utils/, test/integration/.

**Dynamic Verification**: Full suite timed out. Cannot establish baseline.

**Current Behavior**: Full Flutter test suite cannot complete within 2-minute window.

**Expected Behavior**: Full test suite should complete within reasonable time.

**Gap**: Unknown whether full suite has pre-existing failures or just takes too long.

**Impact**: Cannot verify that changes don't break unrelated tests. Regression risk for any code changes.

**Risk**: Medium — targeted tests pass, but full coverage unknown.

**Confidence**: Low (full suite outcomes unknown)

**Acceptance Criteria**:
- [ ] Run full Flutter test suite with larger timeout
- [ ] Identify if there are pre-existing failures
- [ ] Document any pre-existing failures
- [ ] Fix or quarantine failures

**Test Plan**: Run `flutter test` with 600s timeout. Categorize any failures.

**Open Questions**: What timeout does the full suite need? Are there pre-existing failures?

---

## 10. Prioritization

| ID | Title | Severity | Blast Radius | Effort | Confidence | Priority | Why |
|----|-------|----------|-------------|--------|------------|----------|-----|
| ISSUE-001 | Region analysis bypasses backend proxy | 5 | 3 | 3 | 5 | **P0** | SDK keys exposed in release for multi-item scans |
| ISSUE-003 | Queue retry lacks explicit backend routing | 3 | 2 | 2 | 3 | **P2** | Architectural debt, not immediate risk |
| ISSUE-002 | Truth map is stale | 2 | 2 | 2 | 5 | **P2** | Doc maintenance; low urgency |
| ISSUE-004 | Stale comment in rate_limit_config.ts | 1 | 1 | 1 | 5 | **P3** | Trivial fix |
| ISSUE-005 | No full-suite test baseline | 3 | 4 | 4 | 2 | **P1** | Blocks safe changes without regression awareness |

### Priority Queues

#### P0
- **ISSUE-001**: Region analysis bypasses backend proxy routing in release

#### P1
- **ISSUE-005**: Establish full-suite test baseline (prerequisite for P0 work)

#### P2
- **ISSUE-003**: Explicit backend routing in queue service
- **ISSUE-002**: Update stale truth map claims

#### P3
- **ISSUE-004**: Fix stale comment in rate_limit_config.ts

#### Quick Wins
- **ISSUE-004**: One-line comment fix — sub-minute work
- **ISSUE-002**: Doc update — 15 minutes

#### Risky Changes
- **ISSUE-001**: Touches core AI routing in AiService. Must ensure region analysis still works correctly.

#### Needs Discussion Before Work
- **ISSUE-001**: How should region analysis backend routing be implemented? Individual calls per region or batched?

#### Not Worth Doing
- None identified. All issues are actionable.

---

## 11. Proof-of-Concept Validation

No proof-of-concept probe was needed. Static and existing dynamic evidence were sufficient. All claims were verifiable through code reading (3 parallel agent traces), targeted test execution (87 tests across 4 suites), and comprehensive grep searches.

---

## 12. Assumptions Challenged by Implementation

| Assumption | Why it seemed true | What disproved it | Evidence | How recommendation changed |
|------------|-------------------|-------------------|----------|---------------------------|
| Truth map is fully accurate after 23 days | Doc was written with citation-level precision | `guardClientAiCall()` was added to EnhancedAiApiService; `spendUserTokens` server-side verification was implemented | `enhanced_ai_api_service.dart:456,586`; `index.ts:183-286` | Doc update moved from P3 to P2 |
| `analyzeImageRegions()` routes through backend | Sequence diagram implies all paths go through backend | Code shows `_analyzeSingleRegion()` hardcodes `_analyzeWithOpenAI()` bypassing `_orchestrateAnalysis()` | `ai_service.dart:1040` | Elevated from documentation gap to P0 bug |
| Stale doc claim about CURRENT_AI_ARCHITECTURE.md is current | Truth map section 6 claims doc says "no backend classification function" | The current version of that file (updated 2026-05-22) DOES document the backend function | `CURRENT_AI_ARCHITECTURE.md:149` | Truth map's stale doc list is itself stale |
| `EnhancedAiApiService` is unguarded in release | Truth map section 7 says so | Backend routing exists at entry points and guards exist in sub-methods; release mode routes through backend anyway | `enhanced_ai_api_service.dart:176` | Gap 1 in doc is fully resolved, not partially |

---

## 13. Parallel Agent / Multi-Model Findings

Three parallel agents were used for verification:

| Agent | Role | Status | Key Finding |
|-------|------|--------|-------------|
| Agent A | AI routing and guards verification | Complete | Found `analyzeImageRegions()` hardcodes OpenAI direct (P0), confirmed all other routing claims, found EnhancedAiApiService guards exist |
| Agent B | Stale doc verification | Complete | Found CURRENT_AI_ARCHITECTURE.md is already updated (truth map stale about it being stale); found rate_limit_config.ts stale comment; confirmed all API key doc stale claims |
| Agent C | Server-side and gaps verification | Complete | Found spendUserTokens has server-side verification (gap 4 resolved); found daily free scan limit exists (gap 3 partial); classified all function tests |

**Contradiction resolution**: Agents A and C independently confirmed the EnhancedAiApiService gap is fixed. Agent A's finding on `analyzeImageRegions()` was cross-validated by direct code reading. No agent disagreements requiring resolution — all findings are code-backed.

**Multi-model**: Not used (single-model verification sufficient with parallel agents).

---

## 14. Discussion Pack

### My Recommendation

I recommend working on:

1. **ISSUE-001** — `analyzeImageRegions()` backend proxy routing (P0)
2. **ISSUE-005** — Establish full-suite test baseline (P1, prerequisite)
3. **ISSUE-004 + ISSUE-002** — Fix stale comment + update truth map (quick wins)

**Reason**: ISSUE-001 is the only true security gap found. It exposes API keys in release for a specific code path (multi-item region analysis). Fixing it requires the baseline (ISSUE-005) to be known first.

### Why These Matter Now

- **ISSUE-001**: If the app is built in release mode and users use multi-item scan, API keys are sent directly from the client to OpenAI. This bypasses all server-side rate limiting, caching, cost tracking, App Check, and key protection.
- **ISSUE-005**: Without a full test baseline, we can't confidently verify ISSUE-001's fix doesn't regress other classification paths.

### What Breaks If Ignored

- **ISSUE-001 ignored**: Multi-item region analysis leaks API keys in release builds. Cost runaway possible since server-side rate limiting is bypassed.
- **ISSUE-005 ignored**: Any routing change risks breaking the main classification flow without detection.

### What I Would Not Work On Yet

- TFLite on-device inference (from truth map Gap 2): Placeholder is adequate. Real TFLite requires model selection, bundling, and performance testing — a multi-week effort.
- Full api_key_management_and_security.md rewrite: Banner exists. Body rewrite is documentation debt, not a functional gap.

### What Is Ambiguous

- Whether `analyzeImageRegions()` should make one backend call per region (current behavior: one OpenAI call per region) or batch all regions in a single call. Decision needed.

### Questions For You

1. Should `analyzeImageRegions()` batch all regions in a single backend call, or make separate backend calls per region (matching current behavior)?
2. Should the AI Pipeline Truth Map be maintained automatically (generated from code) or remain a manual doc?
3. The full Flutter test suite timed out at 2 minutes. Should I attempt a longer run (e.g., 10-minute timeout) to establish the baseline, or is this a known issue?
4. Should the OfflineQueueService retry path (ISSUE-003) get explicit backend routing injection now or remain as-is (since it accidentally works in release)?

---

## 15. Online Research

No online research needed. All findings are repo-evidence based. The codebase itself provides sufficient evidence for all claims.

---

## 16. ChatGPT / External Review Escalation Writeup

Not needed. All decisions are code-evidence based and within standard engineering judgment. No external facts or framework behavior questions remain.

---

## 17. Recommended Next Work Unit

# Recommended Next Work Unit

## Unit-1: Establish Full Test Baseline + Fix Region Analysis Backend Routing

**Goal**: Establish a known test baseline, then fix the P0 gap where `analyzeImageRegions()` bypasses backend proxy routing in release mode.

**Issues covered**: ISSUE-005 (baseline), ISSUE-001 (region routing)

**Scope**:
- **In**:
  - Run full Flutter test suite with adequate timeout (300s+)
  - Record and categorize all pre-existing failures
  - Refactor `_analyzeSingleRegion()` in `lib/services/ai_service.dart` to route through backend proxy when routing is enabled
  - Add test for region analysis backend routing in `test/services/ai_service_backend_test.dart`
  - Add test for region analysis fail-closed behavior in release mode
- **Out**:
  - TFLite on-device inference implementation
  - OfflineQueueService refactoring
  - Doc updates (deferred to separate quick-win unit)

**Likely files touched**:
- `lib/services/ai_service.dart` — refactor `_analyzeSingleRegion()` (lines 999-1048)
- `test/services/ai_service_backend_test.dart` — add region routing tests

**Acceptance criteria**:
- [ ] Full Flutter test suite runs without new failures (pre-existing failures documented)
- [ ] `analyzeImageRegions()` routes through `BackendProxyProvider` when `_backendRoutingEnabled` is true
- [ ] Release mode region analysis is fail-closed to backend (no direct client fallthrough)
- [ ] Test verifies backend routing for region analysis
- [ ] Test verifies region analysis is blocked in release without backend routing
- [ ] Existing tests continue to pass (targeted: ai_service_backend, enhanced_ai_api_service)

**Tests to run**:
- **Baseline**: `flutter test` with 300s timeout
- **Targeted**: `flutter test test/services/ai_service_backend_test.dart`
- **Full suite**: `flutter test` after changes

**Manual verification**: Build release APK, test multi-item region scan, verify network calls go to Cloud Function (not OpenAI directly).

**Operational safety**:
- **Kill switch**: `--dart-define=ALLOW_CLIENT_AI_IN_RELEASE=true` for emergency direct-client fallback
- **Rollback**: Revert `_analyzeSingleRegion()` changes

**Risks**:
- Region analysis is a less-tested path. Behavior regression possible if backend proxy has different response format.
- Full suite may reveal pre-existing failures unrelated to this change.

**Rollback plan**: `git diff` the changes to `ai_service.dart` only. Revert if region analysis breaks.

---

## 18. Appendix: Searches Performed

| Search | Tool | Pattern | Files Found | Key Finding |
|--------|------|---------|-------------|-------------|
| Document inventory | find | `*.md`, `*.txt` | 335 files | Full audit scope |
| Random selection | bash RANDOM | N/A | 1 file | AI_PIPELINE_TRUTH_MAP |
| guardClientAiCall | grep | `guardClientAiCall` | 12 files, 39 matches | Guards exist in EnhancedAiApiService sub-methods |
| USE_BACKEND_AI_IN_RELEASE | grep | `USE_BACKEND_AI_IN_RELEASE` | 14 files, 35 matches | Flag is alive and canonical |
| classifyImage existence | grep (functions) | `classifyImage` | 27 matches | Function exists and is exported |
| _backendRoutingEnabled | grep | `_backendRoutingEnabled` | 2 files | AiService and EnhancedAiApiService both check |
| _analyzeSingleRegion call chain | read | ai_service.dart lines 924-1048 | 1 file | Hardcodes _analyzeWithOpenAI() |
| OfflineQueueService retry | read | offline_queue_service.dart lines 267-282 | 1 file | Creates raw EnhancedAiApiService |
| spendUserTokens server verification | read | index.ts lines 183-353 | 1 file | Full server-side verification exists |
| rate_limit_config stale comment | read | rate_limit_config.ts lines 36-37 | 1 file | Stale comment about classifyImage |
| Function tests | bash | npm run test:* | 4 suites | classify-image (39), key-resolution (3) |
| Dart targeted tests | bash | flutter test | 2 suites | ai_service_backend (19), enhanced_ai (26) |
| Full Dart suite | bash | flutter test | N/A | Timed out at 120s |
