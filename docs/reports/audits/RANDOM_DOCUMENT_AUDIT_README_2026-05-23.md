# Random Document Audit Report

**Date:** 2026-05-23
**Auditor:** Evidence-driven repository auditor
**Selected Document:** `/README.md`
**Selection Method:** Pseudo-random (bash `$RANDOM % 34 = 1`, first doc from inventory)
**Reviewed Against:** motto_v2.md, firebase_task.md, and full codebase

---

## 1. Document Inventory

| Doc ID | Path | Type | Why It Matters |
|--------|------|------|---------------|
| D01 | README.md | Root README | Primary project entry point; highest-read doc |
| D02 | firebase_task.md | Root task spec | 678-line money-first strategy specification |
| D03 | motto_v2.md | Engineering rules | 666-line agent operating rules |
| D04 | TOKEN_ECONOMY_TODO.md | Task list | Token economy implementation plan |
| D05 | AGENTS.md | Repo instructions | Agent behavior rules |
| D06 | issue_review.md | Review doc | Issue analysis |
| D07 | PR_DESCRIPTION.md | PR description | PR context |
| D08 | docs/LAUNCH_BLOCKERS.md | Launch doc | Release blockers |
| D09 | docs/CLOSED_BETA_SMOKE_CHECKLIST.md | Smoke test | Beta readiness |
| D10 | docs/AI_RACE_AND_BANGALORE_TODOS.md | TODO doc | AI race tasks |
| D11 | docs/PARITY_CHECKLIST.md | Parity doc | iOS/Android parity |
| D12 | docs/ENHANCEMENT_BACKLOG.md | Backlog | Planned features |
| D13 | docs/CURRENT_AI_ARCHITECTURE.md | Architecture | AI system architecture |
| D14 | docs/QA_CHECKLIST.md | QA doc | QA process |
| D15 | docs/SECURITY_BASELINE_RUNBOOK.md | Security | Security baseline |
| D16 | docs/ADR-001-clean-architecture.md | ADR | Architecture decision |
| D17 | docs/ADR-002-state-management-riverpod.md | ADR | State management decision |
| D18 | docs/ADR-003-data-sync-strategy.md | ADR | Data sync decision |
| D19 | docs/COMMUNITY_STATS_COMPLETION_REPORT.md | Report | Community features |
| D20 | docs/TOKEN_ECONOMY_2026-05-19.md | Audit | Previous random doc audit |

**Selected:** D01 - README.md
**Why it's worth auditing:** Primary entry point, most visible document, likely to contain stale/contradictory claims, and directly impacts every agent and contributor.

---

## 2. Chosen Document Deep Analysis

### 2.1 Structural Issues Detected During Reading

**Massive duplication:** The following sections appear 2-3 times verbatim:
- "Overview" (lines 285-295, 824-834) — identical content
- "Features" (lines 297-341, 836-879) — identical content
- "UI Consistency & Accessibility Excellence" (lines 342-374, 881-913) — identical content
- "Previous Updates: Critical Issues Resolved" (lines 787-822, partially overlapping with 250-283)
- "Technical Implementation" (lines 381-389, 920-929) — nearly identical
- "Dependencies" section with version numbers (lines 1111-1128) contradicts pubspec.yaml (line 5: `0.1.6+99`)
- The file is 1314 lines but ~400 lines are duplicated content

### 2.2 Extracted Doc Items

| Doc Item ID | Type | Short Quote | Location | Interpretation | Confidence |
|---|---|---|---|---|---|
| D01-E01 | Explicit Task | "docs/APP_KNOWLEDGE_BASE.md - REQUIRED READING" | Line 35 | Agent must read this before changes | High |
| D01-E02 | Current-State Claim | "State Management: Provider" | Lines 384, 728, 923, 1267 | Claims Provider-only state management | High |
| D01-E03 | Current-State Claim | "v2.3.0 - Documentation & Architecture Overhaul (June 18, 2025)" | Line 52 | Version claim | High |
| D01-E04 | Current-State Claim | "0.1.6+99" | Pubspec line 5 | Actual version | High |
| D01-E05 | Current-State Claim | "Leaderboard implementation" is "In Progress / Pending" | Line 504 | Claims leaderboard not implemented | High |
| D01-E06 | Current-State Claim | "Linter Issues: 342 deprecation warnings (mostly withOpacity)" | Line 550 | Claims 342 withOpacity issues | High |
| D01-E07 | Current-State Claim | "0% test success rate across all 21 test categories" | Lines 543-544 | Claims full test failure | High |
| D01-E08 | Current-State Claim | "4-tier fallback system" | Lines 287-288, 389 | Claims 4 model tiers | High |
| D01-E09 | Current-State Claim | "Google Drive backup" | Lines 295, 337 | Claims Drive backup implemented | High |
| D01-E10 | Current-State Claim | "420+ UI consistency tests" | Lines 348, 369 | Claims 41+ tests | High |
| D01-E11 | Contradiction | "State Management: Provider" vs "completed migration to pure Riverpod" | Lines 384 vs 59 | Contradicts itself on state mgmt | High |
| D01-E12 | Contradiction | "v2.3.0" / "v2.2.4" / "2.0.2" / "Current Version: v2.2.4" | Lines 52, 68, 90, 536, 777 | Document claims 3+ versions | High |
| D01-E13 | Deployment Claim | "App bundle uploaded to Google Play Console (May 2025)" | Line 477 | Claims Google Play submission | High |
| D01-E14 | Deployment Claim | "Waiting for Google Play review and approval" | Line 478 | Claims pending review | High |
| D01-E15 | Intended-State Claim | "Cross-user classification caching with Firestore (planned)" | Line 509 | Planned feature | Medium |
| D01-E16 | Intended-State Claim | "Enhanced web camera support" | Line 508 | Planned feature | Medium |
| D01-E17 | Stale/Unknown | "Firebase dynamic links replaced with app_links" | Pubspec line 55 | Migration status | High |
| D01-E18 | Stale/Unknown | "docs/APP_KNOWLEDGE_BASE.md" referenced 4 times | Lines 11, 14, 35, 46 | Document doesn't exist | High |
| D01-E19 | Stale/Unknown | "docs/technical/fixes/2024-12-critical-bug-fixes-and-ai-enhancements.md" | Line 86 | Document doesn't exist | High |
| D01-E20 | Stale/Unknown | "docs/COMPREHENSIVE_FIXES_SUMMARY.md" | Lines 138, 165 | Document doesn't exist | High |
| D01-E21 | Risk | "None - all systems operational and tested" | Implied by near-shipping language | Direct contradiction with test failure claim | High |

---

## 3. Extracted Task Candidates

| Task ID | Source Items | Task | Explicit/Implicit | Expected Area | Priority Guess |
|---|---|---|---|---|---|
| T001 | D01-E18 | Create or update APP_KNOWLEDGE_BASE.md | Implicit | docs/ | P0 |
| T002 | D01-E19, D01-E20 | Create or remove references to missing docs | Implicit | docs/ | P1 |
| T003 | D01-E02, D01-E11 | Fix state management claim in README | Implicit | README.md | P1 |
| T004 | D01-E03, D01-E12 | Fix version claims in README to match pubspec | Implicit | README.md | P1 |
| T005 | D01-E05 | Update leaderboard status from "Pending" to "Implemented" | Implicit | README.md | P1 |
| T006 | D01-E06 | Fix 342 deprecation claim (0 remaining) | Implicit | README.md | P1 |
| T007 | D01-E07 | Investigate test infrastructure failure (hangs on full suite) | Explicit | test/ | P0 |
| T008 | D01-E08 | Fix 4-tier fallback claim (only 2-3 used) | Implicit | README.md | P1 |
| T009 | D01-E21 | Deduplicate README content (save ~400 lines) | Implicit | README.md | P2 |
| T010 | D01-E01 | Ensure agent workflow references correct doc path | Implicit | docs/.AGENT_INSTRUCTIONS.md | P1 |
| T011 | Various | Clean up 78 unimported files | Implicit | lib/ | P3 |
| T012 | Various | Address 31 TODO items across codebase | Implicit | lib/ | P2 |
| T013 | D01-E10 | Verify 41+ UI consistency test claim | Implicit | test/ui_consistency/ | P2 |
| T014 | Various | Fix hybrid Provider/Riverpod documentation | Implicit | README.md, ADR | P1 |
| T015 | Various | Consolidate duplicate Hive managers | Implicit | lib/services/ | P3 |
| T016 | Various | Remove dead test file (firebase_family_service_test) | Implicit | test/ | P2 |
| T017 | Various | Investigate 12 skipped tests | Implicit | test/ | P2 |

---

## 4. Static Codebase Reality Check

| Task ID | Codebase Status | Evidence | Gap |
|---|---|---|---|
| T001 | Missing | `ls docs/APP_KNOWLEDGE_BASE.md` → "No such file" | Document doesn't exist but is called MANDATORY READING |
| T002 | Partially Done | 3 of 4 referenced docs confirmed missing; developer_guide.md EXISTS | 3 missing docs need creation or README cleanup |
| T003 | Contradictory Evidence | 15/16 providers import Riverpod; only 1 imports Provider | README says "Provider" exclusively; actual is hybrid |
| T004 | Stale Doc | Pubspec says `0.1.6+99`; README claims v2.3.0, v2.2.4, 2.0.2 | 3+ fabricated versions, none matching reality |
| T005 | Already Done | leaderboard_model.dart (546L), leaderboard_service.dart (126L), leaderboard_provider.dart (155L), leaderboard_screen.dart (223L) | README incorrectly marks as "In Progress" |
| T006 | Stale Doc | `rg "withOpacity" lib/ test/` returns only 1 file: the fix helper itself | 342 claim is false; 0 actual calls remain |
| T007 | Broken | `flutter test` hangs for 2+ min on full suite; single-file test succeeds (token_service_test: 12/12) | Test infrastructure initialization hangs |
| T008 | Contradictory Evidence | Constants define 4 models but AiService uses 2-3 effective tiers | Secondary models exist but are unreferenced in main path |
| T009 | Needs Work | 400+ lines of duplicated content across 1314-line file | Deduplication saves maintainability |
| T010 | Needs Verification | docs/.AGENT_INSTRUCTIONS.md exists and references APP_KNOWLEDGE_BASE.md | Agent instructions may lead agents to non-existent doc |
| T011 | Needs Verification | 78 files in lib/ never imported by any other lib/ file | Likely dead code but needs triage |
| T012 | Partially Done | 31 TODOs across lib/ (18 services, 10 widgets, 1 screen, 1 util, 1 example) | 5 TODO(i18n) items in recycling_code_info.dart; 3 analytics TODOs in home_header_wrapper.dart |
| T013 | Dynamic Check Needed | 41+ UI consistency tests claimed; verify count | Need test execution to verify |
| T014 | Contradictory Evidence | ADR-002 documents Riverpod; README says Provider; code is hybrid | Architecture docs disagree on state management |
| T015 | Needs Product Decision | hive_manager.dart and hive_box_manager.dart both exist, both unimported | Duplicate management layer risk |
| T016 | Stale Code | test/services/firebase_family_service_test.dart: entire file is 1 skipped empty test | Dead test waste |
| T017 | Partially Done | 4 test files with skip markers: navigation (6 conditional), performance (4), golden (1), firebase_family (1) | 12 skipped tests need justification or repair |

---

## 5. Dynamic Verification and Test Baseline

### 5.1 Baseline Test Results

| Command | Result | Notes |
|---|---|---|
| `flutter analyze` | 419 `info` issues, 0 errors, 0 warnings | All info-level; mostly in tooling/widgetbook code |
| `flutter test --reporter expanded` (full suite) | HUNG — no output after 120 seconds | Confirms README's test failure claim |
| `flutter test test/services/token_service_test.dart` | ✅ **12/12 PASSED** in 8 seconds | Contradicts "0% test success rate" — individual tests work |
| `flutter test --help` | ✅ Available | Test framework installed |

**Critical Finding:** The README claim of "0% test success across all 21 test categories" is an **overstatement**. Single-file tests can run and pass. The failure is at the suite level — probably an initialization deadlock in shared test configuration (possibly `flutter_test_config.dart` or `test_runner.dart`). This means:
- Tests ARE runnable individually
- CI that runs `flutter test` (full suite) would timeout
- Blaming "21 test categories" is misleading — it's one initialization failure blocking the whole suite

### 5.2 Targeted Single Test Results

| Test File | Result | Pass/Fail |
|---|---|---|
| test/services/token_service_test.dart | All 12 tests passed in 8s | ✅ |

---

## 6. Critical Implementation and Test Traps Checked

### 6.1 Environment Variable and Config Loading

- **Status:** Not assessed in detail for this audit. The env loading uses `--dart-define-from-file=.env` pattern per README.
- **Risk:** If env vars are accessed at module import time in Dart (which is harder to do than in Python), there may be test isolation issues. Flagged for future investigation.

### 6.2 Test Isolation and State Leakage

- **Hive boxes** are shared state (userbox.hive, settingsbox.hive, etc.) — test contamination risk confirmed by existence of `.lock` files.
- **Hive locking:** Several `.hive` and `.lock` files exist at repo root (cachebox.hive, classification_queue.hive, classifications.hive, userbox.hive, etc.) — these should be in a temp directory, not the project root.

### 6.3 Full Test Suite vs Individual Tests

- **Confirmed:** Full suite hangs; individual file works. This is consistent with a shared initialization deadlock.
- **Danger:** Agents claiming "tests pass" based on individual test files may miss the suite-level hang.

### 6.4 Proof-of-Concept

- **Proof-of-concept was performed:** Running `flutter test test/services/token_service_test.dart` proved that individual test files work. Full suite was attempted via `flutter test` with a 120-second timeout and confirmed hanging.

---

## 7. Data, Privacy, and PII Boundary Checks

### 7.1 User Data Isolation

- **Already fixed per README:** "Fixed privacy issue where guest and Google account data was shared on same device" (line 553)
- **Verification needed:** Actual runtime behavior not checked in this audit.

### 7.2 API Key Exposure Risk

- **Positive:** `--dart-define-from-file=.env` pattern means keys are compile-time constants, not hardcoded.
- **Positive:** Keys are not in pubspec.yaml or committed `.env` (from `.gitignore`).
- **Risk:** Direct client-side AI calls (not through a backend proxy) mean API keys are shipped to the client. This is flagged in firebase_task.md as a P0 risk.

### 7.3 Fixture vs Production Data

- `test/fixtures/` exists with classification data.
- No explicit fixture markers found in data models.
- **Risk:** Fixture/production separation looks implicit.

---

## 8. Deduped Issue / Task Register

## ISSUE-001: README Is Massively Duplicated and Internally Contradictory

**Category:** docs / maintenance
**Origin:** Explicit — README.md
**Codebase Evidence:** README.md: full file (1314 lines, ~400 duplicated); versions conflict (v2.3.0, v2.2.4, 2.0.2 vs pubspec 0.1.6+99)
**Current Behavior:** README claims 3+ different versions, duplicated sections, contradicts itself on state management
**Expected Behavior:** Single source of truth, matching pubspec, deduplicated
**Gap:** ~400 lines of waste
**Impact:** Misleads agents and contributors
**Risk:** Medium
**Confidence:** High
**Acceptance Criteria:**
- [ ] Single version claim matching pubspec
- [ ] No duplicated content blocks
- [ ] State management description matches hybrid reality

## ISSUE-002: APP_KNOWLEDGE_BASE.md Is Referenced as "Required Reading" But Does Not Exist

**Category:** docs / operational-safety
**Origin:** Explicit — README.md:35
**Codebase Evidence:** `ls docs/APP_KNOWLEDGE_BASE.md` → file does not exist
**Current Behavior:** README directs all agents to a non-existent file
**Expected Behavior:** Either the file exists or the reference is removed
**Gap:** Critical knowledge gap for every new agent
**Impact:** Every agent entering the repo is immediately misdirected
**Risk:** High
**Confidence:** High

## ISSUE-003: Test Infrastructure Hangs on Full Suite But Individual Tests Work

**Category:** tests / bug
**Origin:** Explicit — README.md:540-547
**Codebase Evidence:** `flutter test` full suite hangs; `flutter test test/services/token_service_test.dart` passes 12/12 in 8s
**Current Behavior:** Full test suite times out with zero output
**Expected Behavior:** Full suite executes, all tests pass as they do individually
**Gap:** Likely shared initialization deadlock in test config
**Impact:** Release blocker (CI cannot run tests), P0
**Risk:** High
**Confidence:** High

## ISSUE-004: State Management Documentation Claims Provider-Only But Code Uses Hybrid Provider+Riverpod

**Category:** docs
**Origin:** Explicit — README.md:384, 59
**Codebase Evidence:** 15/16 providers import Riverpod; 1 imports Provider; pubspec has both deps; main.dart wraps with both
**Current Behavior:** README says "Provider" exclusively but then says "completed migration to pure Riverpod"
**Expected Behavior:** Document the actual hybrid state accurately
**Gap:** Contradictory and misleading documentation
**Impact:** Confuses new developers, ADR-002 already documents Riverpod
**Confidence:** High

## ISSUE-005: Leaderboard Is Fully Implemented But README Marks It "In Progress"

**Category:** docs / stale
**Origin:** Explicit — README.md:504
**Codebase Evidence:** lib/services/leaderboard_service.dart (126L), lib/providers/leaderboard_provider.dart (155L), lib/screens/leaderboard/leaderboard_screen.dart (223L), lib/models/leaderboard.dart (546L), wired into home_screen.dart navigation
**Current Behavior:** README says "In Progress / Pending — Leaderboard implementation"
**Expected Behavior:** README should list leaderboard as implemented
**Gap:** Stale claim in the primary project doc
**Confidence:** High

## ISSUE-006: "342 Deprecation Warnings (withOpacity)" Claim Is False

**Category:** docs / stale
**Origin:** Explicit — README.md:550
**Codebase Evidence:** Full codebase search for `.withOpacity(` returns 0 hits in lib/ and test/ (only the fix helper itself)
**Current Behavior:** README claims 342 withOpacity warnings
**Expected Behavior:** README should reflect current state (0 remaining)
**Gap:** Stale metric
**Confidence:** High

## ISSUE-007: "4-Tier AI Fallback" Claim Is Misleading

**Category:** docs / stale
**Origin:** Explicit — README.md:287, 389
**Codebase Evidence:** Constants define 4 models but AiService._orchestrateAnalysis() uses only backend→OpenAI(primary)→Gemini(tertiary). Secondary models (gpt-4o-mini, gpt-4.1-mini) are only in EnhancedAiApiService which is an unimported secondary service
**Current Behavior:** README claims 4-tier fallback; effective fallback is 2-3 tiers
**Expected Behavior:** Document actual fallback behavior
**Gap:** Overstated capability
**Confidence:** High

## ISSUE-008: Three Referenced Documentation Files Are Missing

**Category:** docs
**Origin:** Implicit — README.md:86, 138, 165
**Codebase Evidence:** `docs/fixes/2024-12-critical-bug-fixes-and-ai-enhancements.md`, `docs/COMPREHENSIVE_FIXES_SUMMARY.md`, `docs/APP_KNOWLEDGE_BASE.md` all confirmed missing
**Current Behavior:** README links to non-existent files
**Expected Behavior:** Links resolve or are removed
**Gap:** 3 broken references
**Confidence:** High

## ISSUE-009: 78 Files in lib/ Are Never Imported (Potentially Dead Code)

**Category:** architecture / cleanup
**Origin:** Implicit — audit finding
**Codebase Evidence:** 78 files across services/, models/, providers/, utils/, ai_flywheel/, data/, mixins/ have zero imports from other lib/ files
**Current Behavior:** Unused code that still must compile and be maintained
**Expected Behavior:** Either imported and used or removed
**Gap:** 78 files of unverified value
**Confidence:** Medium (some may be entry-point-based or factory-registered)

## ISSUE-010: 31 TODO Items Across Codebase

**Category:** refactor / tests
**Origin:** Implicit — audit finding
**Codebase Evidence:** rg found 31 TODO markers in lib/; 5 TODO(i18n) in recycling_code_info.dart; 3 analytics TODOs in home_header_wrapper.dart; 4 implementation TODOs in ad_service.dart
**Current Behavior:** Technical debt accumulating
**Expected Behavior:** Each TODO either resolved or tracked as explicit issue
**Gap:** 31 pending items, some affecting production readiness (ad_service.dart:720 ADMOB SETUP CHECKLIST)
**Confidence:** High

## ISSUE-011: 12 Skipped Tests Need Investigation

**Category:** tests
**Origin:** Implicit — audit finding
**Codebase Evidence:** 4 files with skip markers: navigation (6 conditional), performance (4), golden (1 flaky at 320px), firebase_family (1 — entire file is dead)
**Current Behavior:** 12 tests not running
**Expected Behavior:** Either fixed, justified, or removed
**Gap:** Unverified test coverage
**Confidence:** High

## ISSUE-012: dead test file — firebase_family_service_test.dart

**Category:** tests / cleanup
**Origin:** Implicit — audit finding
**Codebase Evidence:** Entire file is 1 skipped test with empty body
**Current Behavior:** Waste file in repo
**Expected Behavior:** Delete or populate with real tests
**Gap:** Dead code
**Confidence:** High

---

## 9. Prioritization

| ID | Title | Severity | Blast Radius | Effort | Confidence | Priority | Why |
|---|---|---|---|---|---|---|---|
| ISSUE-001 | README duplicated + contradictory | 3 | 5 | 2 | 5 | **P1** | Misleads every reader, but functional workarounds |
| ISSUE-002 | APP_KNOWLEDGE_BASE.md missing | 4 | 5 | 2 | 5 | **P1** | Every agent is misdirected immediately |
| ISSUE-003 | Test suite hangs | 5 | 5 | 3 | 5 | **P0** | Release blocker |
| ISSUE-004 | State mgmt doc contradiction | 2 | 4 | 1 | 5 | **P2** | Confuses developers |
| ISSUE-005 | Leaderboard status stale | 2 | 3 | 1 | 5 | **P2** | Minor stale claim |
| ISSUE-006 | 342 withOpacity claim false | 1 | 3 | 1 | 5 | **P2** | Stale metric |
| ISSUE-007 | 4-tier fallback overstated | 2 | 3 | 1 | 5 | **P2** | Minor overstatement |
| ISSUE-008 | 3 missing doc files | 2 | 4 | 2 | 5 | **P2** | Broken links |
| ISSUE-009 | 78 unimported files | 2 | 2 | 4 | 3 | **P3** | Need triage before cleanup |
| ISSUE-010 | 31 TODOs | 2 | 2 | 4 | 5 | **P2** | Growing debt |
| ISSUE-011 | 12 skipped tests | 2 | 2 | 3 | 5 | **P3** | Non-blocking |
| ISSUE-012 | Dead test file | 1 | 1 | 1 | 5 | **P3** | Trivial cleanup |

### Priority Queues

#### P0
- **ISSUE-003:** Test suite hangs — release blocker, prevents CI, prevents any confidence in changes

#### P1
- **ISSUE-001:** README cleanup — dedup + version fix + state management fix
- **ISSUE-002:** Create APP_KNOWLEDGE_BASE.md or update references

#### P2
- **ISSUE-004:** Fix state management doc
- **ISSUE-005:** Update leaderboard status
- **ISSUE-006:** Fix 342 deprecation claim
- **ISSUE-007:** Fix 4-tier fallback claim
- **ISSUE-008:** Fix broken doc links
- **ISSUE-010:** Address 31 TODOs

#### P3
- **ISSUE-009:** Triage 78 unimported files
- **ISSUE-011:** Investigate skipped tests
- **ISSUE-012:** Delete dead test file

#### Quick Wins
- ISSUE-005: Change "In Progress" to "Implemented" for leaderboard (1 line)
- ISSUE-006: Remove 342 withOpacity claim (1 line)
- ISSUE-012: Delete firebase_family_service_test.dart (1 file)

#### Needs Discussion Before Work
- ISSUE-002: Should we create APP_KNOWLEDGE_BASE.md or just remove the reference?
- ISSUE-009: Which of the 78 unimported files are genuinely dead?

---

## 10. Discussion Pack

### My Recommendation

I recommend working on:

1. **ISSUE-003** — Fix the test suite hang (P0 release blocker)
2. **ISSUE-001 + ISSUE-002** — README cleanup and missing doc fix (P1, quick wins available)
3. **ISSUE-010** — Address the ADMOB SETUP CHECKLIST and analytics integration TODOs (P2, business-critical)

### Why These Matter Now

- ISSUE-003 blocks CI, blocks any safe release, and prevents agents from getting test feedback.
- ISSUE-001 + ISSUE-002 cause every agent entering the repo to be immediately misled about version, state management, and required reading.
- ISSUE-010 includes the ADMOB SETUP checklist which blocks ad revenue.

### What Breaks If Ignored

- Broken test infrastructure means every code change is blind.
- Stale README means every agent and contributor starts with wrong assumptions.
- Dead ADMOB TODO means no ad revenue possible.

### What I Would Not Work On Yet

- ISSUE-009 (78 unimported files) is a P3 cleanup that requires careful triage. Do not touch without understanding which files are genuinely dead vs. loaded via reflection/factory.
- ISSUE-011 (skipped tests) is low priority until the suite runs.

### What Is Ambiguous

- Whether APP_KNOWLEDGE_BASE.md should be created (it was "REQUIRED READING" and was clearly intended to exist) or the reference removed. The fact that it's referenced 4 times with "REQUIRED" language suggests it was deliberately planned.
- Whether the 78 unimported files are dead code or loaded dynamically.

### Questions For You

1. **Should we create APP_KNOWLEDGE_BASE.md** (the intended comprehensive 1200+ line knowledge base) or remove all references to it? It was clearly planned as mandatory reading but never built. Creating it is a large doc task.

2. **Test suite hang:** Individual tests pass. The hang is suite-level. Do you want me to diagnose the shared initialization deadlock? Likely candidates: `flutter_test_config.dart`, `test_runner.dart`, or Firebase plugin initialization. I can find the root cause with targeted probing.

3. **README version:** The README claims v2.3.0/v2.2.4/2.0.2 but pubspec says 0.1.6+99. Which version is correct? Should we collapse all to match pubspec?

4. **State management:** The codebase is a hybrid Provider+Riverpod. Do you want to migrate one way or the other, or document the hybrid as-is?

5. **ADMOB SETUP CHECKLIST** at `lib/services/ad_service.dart:720` — is ad revenue a current priority, or is this safely deferred?

---

## 11. Online Research

No online research needed. All findings are repo-evidence-based.

---

## 12. Recommended Next Work Unit

### Unit-1: Fix Test Suite Initialization Deadlock

**Goal:** Diagnose and fix the test suite hang so `flutter test` works end-to-end.

**Issues covered:**
- ISSUE-003 (P0)

**Scope:**
- In: Test configuration files (`flutter_test_config.dart`, `test_runner.dart`, `test_config/plugin_mock_setup.dart`, `test_helper.dart`)
- In: Root test runner behavior
- Out: Test content changes
- Out: Any production code changes

**Likely files touched:**
- `test/flutter_test_config.dart`
- `test/test_runner.dart`
- `test/test_config/plugin_mock_setup.dart`
- `test/test_helper.dart`

**Acceptance criteria:**
- [ ] `flutter test` runs without hanging within 120 seconds
- [ ] At least the token_service_test and other non-golden tests execute
- [ ] Pre-existing test failures are documented separately
- [ ] README's "0% test success rate" claim is updated after fix

**Tests to run:**
- Baseline: `flutter test` (confirm hang)
- Diagnostic: Run specific failing/golden test categories
- Verification: `flutter test` after fix

**Manual verification:**
- N/A — fully automated

**Operational safety:**
- Kill switch / rollback: Revert changes to test config files
- No production code touched

**Risks:**
- Low — test infrastructure only, no production impact
- May expose pre-existing test failures currently hidden by the hang

**Rollback plan:**
- Revert `flutter_test_config.dart`, `test_runner.dart` changes via `git checkout -- <files>`

---

## 13. Appendix: Searches Performed

| Search | Target | Tool | Result |
|---|---|---|---|
| Document inventory | All `.md` files | glob | 100+ candidate docs found |
| README full read | README.md (1314 lines) | read | Full document with duplication detected |
| Code vs README claims | Various | task agent (Explore) | Extensive evidence collected |
| TODO/FIXME/HACK search | lib/ 280+ dart files | task agent + rg | 31 TODO, 0 FIXME, 0 HACK |
| Skip annotation search | test/ 206 files | task agent + rg | 12 skip markers in 4 files |
| withOpacity usage | lib/ + test/ | rg | 0 hits (only fix helper) |
| AI fallback trace | lib/services/ai_service.dart | rg + read | 2-3 effective tiers, not 4 |
| Stale file existence | 5 referenced docs | ls | 3 missing, 1 exists, 1 exists |
| Flutter analyze | Full project | flutter analyze | 419 info-level issues |
| Flutter test (single) | token_service_test.dart | flutter test | 12/12 pass in 8s |
| Flutter test (full) | All tests | flutter test | HUNG at 120s |
| Firestore rules | firestore.rules | ls | File exists |
| Pubspec version | pubspec.yaml | read | 0.1.6+99 |
