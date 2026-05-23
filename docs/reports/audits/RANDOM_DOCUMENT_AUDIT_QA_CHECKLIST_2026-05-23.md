# Random Document Audit Report

## 1. Document Inventory

The repo contains ~250+ markdown documents across `docs/` subdirectories. Key categories:

| Doc ID | Path | Type | Why it may matter |
|--------|------|------|-------------------|
| DOC-001 | `docs/testing/QA_CHECKLIST.md` | QA/Testing checklist | Claims pre-release checks, test infrastructure, CI pipeline |
| DOC-002 | `docs/planning/MASTER_TODO_COMPREHENSIVE.md` | Planning/TODO | Master task list |
| DOC-003 | `docs/launch/LAUNCH_BLOCKERS.md` | Launch readiness | Production blockers |
| DOC-004 | `docs/launch/CLOSED_BETA_SMOKE_CHECKLIST.md` | Launch checklist | Beta readiness |
| DOC-005 | `docs/security/SECURITY_BASELINE_RUNBOOK.md` | Security | Security runbook |
| DOC-006 | `docs/results_parity/PARITY_CHECKLIST.md` | Feature verification | Cross-screen parity |
| DOC-007 | `docs/reports/architecture/classification_pipeline.md` | Architecture | Classification pipeline |
| DOC-008 | `README.md` | Root README | Project overview |
| DOC-009 | `firebase_task.md` | Task/planning | Phase/P0 checklist |
| DOC-010 | `TOKEN_ECONOMY_TODO.md` | Planning | Token economy TODOs |

## 2. Random Selection

**Chosen document:** `docs/testing/QA_CHECKLIST.md`

**Selection method:** Pseudo-random via `find docs/ -name "*.md" | sort -R | head -1` using macOS `sort -R` (random hash sort). First result selected.

**Why this doc is worth auditing:** It contains multiple actionable claims about production readiness, critical integration gaps, test infrastructure, and automation tooling. Many claims are testable against the codebase (TODO counts, widget behavior, service integration, file existence).

## 3. Chosen Document Deep Analysis

### Document Profile
- **Title:** QA Checklist - Developer Error Prevention
- **Last Updated:** December 2024
- **Version:** 1.2
- **Length:** 666 lines
- **Sections:** 15 sections covering pre-release checks, testing procedures, build validation, CI/CD, accessibility, performance budgets, release approval criteria, automation setup, post-release monitoring

### Extracted Items Table

| Doc Item ID | Type | Short quote / evidence | Location | Interpretation | Confidence |
|-------------|------|----------------------|----------|----------------|------------|
| Q1 | Explicit Task | "No 'Already in tree' AdWidget errors (Critical: AdMob service has 15+ TODOs)" | Line 15 | AdMob service needs cleanup; claims 15+ TODOs | High |
| Q2 | Explicit Task | "No TODO comments in production code (40+ TODOs identified in codebase)" | Line 17 | Codebase should have zero production TODOs; claims 40+ count | High |
| Q3 | Explicit Task | "AdMob placeholder IDs replaced with real ad unit IDs" | Line 18 | AdMob config needs production IDs | High |
| Q4 | Explicit Task | "Result screen text overflow fixed (Critical: Material information overflows containers)" | Line 26 | Result screen overflow is a critical fix item | High |
| Q5 | Explicit Task | "Recycling code widget displays correctly (Critical: Inconsistent display issues)" | Line 27 | Recycling code widget has display bugs | High |
| Q6 | Explicit Task | "ViewAllButton responsive behavior (80px, 120px breakpoints working)" | Line 28 | ViewAllButton needs responsive breakpoints at 80/120px | High |
| Q7 | Explicit Task | "ResponsiveText.cardTitle handles overflow properly" | Line 29 | ResponsiveText.cardTitle needs overflow handling | High |
| Q8 | Explicit Task | "Firebase family service integrated (Critical: Backend exists but no UI integration)" | Line 38 | Firebase family backend has no UI integration | High |
| Q9 | Explicit Task | "Analytics service tracking active (Critical: Service exists but no tracking calls)" | Line 39 | Analytics service exists but is not called | High |
| Q10 | Explicit Task | "User feedback widget visible (Critical: Widget exists but not integrated)" | Line 40 | Feedback widget needs integration | High |
| Q11 | Explicit Task | "Analysis cancellation flow working (Recently fixed - verify no regression)" | Line 41 | Cancellation flow was recently fixed | High |
| Q12 | Explicit Task | "Achievement unlock logic works for all user levels" | Line 34 | Achievement logic should work at all levels | High |
| Q13 | Explicit Task | "Firebase family features - Users can access family dashboard with real data" | Line 147 | Integration test scenario requiring family UI | High |
| Q14 | Explicit Task | "User feedback collection - Feedback widget appears in result screen" | Line 148 | Integration test scenario for feedback | High |
| Q15 | Explicit Task | "Analytics tracking - Events are logged throughout app usage" | Line 149 | Integration test scenario for analytics | High |
| Q16 | Claim | "AdMob service has 15+ TODOs" | Line 15 | Assertion about TODO count in AdMob service | High |
| Q17 | Claim | "40+ TODOs identified in codebase" | Line 17, 171 | Assertion about total TODO count | High |
| Q18 | Configuration Claim | `.github/workflows/qa-checks.yml` exists | Lines 207-266 | CI/CD pipeline defined | High |
| Q19 | Configuration Claim | `scripts/pre-commit-qa.sh` exists | Lines 269-303 | Pre-commit hook script defined | High |
| Q20 | Test Claim | `test_driver/performance_test.dart` exists | Lines 306-350 | Performance test driver defined | High |
| Q21 | Test Claim | `test/accessibility/accessibility_test.dart` exists | Lines 353-413 | Accessibility test suite defined | High |
| Q22 | Test Assertion | `flutter test test/regression_tests.dart` works | Line 76 | Regression test file exists | High |
| Q23 | Test Assertion | `flutter test test/ui_overflow_fixes_test.dart` works | Line 77 | UI overflow test file exists | High |
| Q24 | DevDep Claim | `flutter_a11y` is installed | Line 100-101 | Pub global activate command | High |
| Q25 | DevDep Claim | `accessibility_tools` is a dev dependency | Line 94 | Pub package | High |
| Q26 | DevDep Claim | `flutter_driver` is a dev dependency | Line 308 | Imports flutter_driver | High |
| Q27 | Implicit Task | CI/CD pipeline must be set up | Lines 207-266 | Automation for QA checks | Medium |
| Q28 | Implicit Task | Pre-commit hooks must be configured | Lines 269-303 | Local dev workflow | Medium |
| Q29 | Implicit Task | Performance budgets must be enforced | Lines 108-124 | Build size, frame time, memory | Medium |
| Q30 | Implicit Task | Accessibility standards must be met (WCAG AA+) | Lines 458-464 | Contrast, semantic labels, screen reader | Medium |
| Q31 | Implicit Task | "Family management TODOs completed (Name editing, copy ID, toggle settings)" | Line 473 | Family feature completeness | Medium |
| Q32 | Implicit Task | "Achievement screen TODOs resolved (Challenge generation, navigation)" | Line 475 | Achievement feature completeness | Medium |
| Q33 | Deployment Claim | "GDPR consent management implemented" | Line 504 | Production readiness for GDPR | Medium |
| Q34 | Security Claim | "All TODO comments resolved or documented for future releases" | Line 505 | Production readiness for TODOs | Medium |
| Q35 | Contradiction | "Version: 1.1" at top vs "Version: 1.2" at bottom | Lines 6, 636 | Version inconsistency | Low |
| Q36 | Stale | Doc dates itself "December 2024" | Line 5 | Document is 5+ months old | High |

## 4. Extracted Task Candidates

| Task Candidate ID | Source Doc Item IDs | Task | Explicit or Implicit | Why this is a task | Expected repo area | Initial priority guess |
|-------------------|---------------------|------|---------------------|--------------------|--------------------|----------------------|
| T1 | Q1, Q16 | Count and resolve AdMob service TODOs | Explicit | Doc claims 15+ TODOs; verify and resolve | `lib/services/ad_service.dart` | P1 |
| T2 | Q2, Q17 | Count and resolve all production TODOs | Explicit | Doc claims 40+ TODOs; verify and resolve | `lib/` | P1 |
| T3 | Q3 | Replace AdMob placeholder IDs with production IDs | Explicit | Doc says placeholder IDs exist | `android/`, `ios/`, `lib/services/ad_service.dart` | P0 |
| T4 | Q4 | Fix result screen text overflow | Explicit | Doc says overflow is critical | `lib/screens/result_screen.dart` | P0 |
| T5 | Q5 | Fix recycling code widget display | Explicit | Doc says inconsistent display | `lib/widgets/recycling_code_info.dart` | P1 |
| T6 | Q6 | Verify ViewAllButton 80px/120px breakpoints | Explicit | Doc says responsive breakpoints needed | `lib/widgets/modern_ui/modern_buttons.dart` | P2 |
| T7 | Q7 | Verify ResponsiveText.cardTitle overflow handling | Explicit | Doc says overflow needed | `lib/widgets/responsive_text.dart` | P2 |
| T8 | Q8 | Integrate Firebase family service into UI | Explicit | Doc says no UI integration | `lib/screens/family_*.dart` | P0 |
| T9 | Q9 | Wire analytics tracking calls throughout app | Explicit | Doc says no tracking calls | `lib/services/analytics_service.dart` | P0 |
| T10 | Q10 | Integrate user feedback widget | Explicit | Doc says widget not integrated | `lib/widgets/correction_dialog.dart`, result screen | P0 |
| T11 | Q11 | Verify analysis cancellation flow | Explicit | Doc says recently fixed | `lib/services/ai_service.dart`, `lib/screens/image_capture_screen.dart` | P2 |
| T12 | Q12 | Verify achievement unlock logic for all levels | Explicit | Doc says should work for all levels | `lib/services/gamification_service.dart` | P2 |
| T13 | Q18, Q27 | Create `.github/workflows/qa-checks.yml` | Explicit | Doc references specific CI file | `.github/workflows/` | P1 |
| T14 | Q19, Q28 | Create `scripts/pre-commit-qa.sh` | Explicit | Doc references specific script | `scripts/` | P1 |
| T15 | Q20 | Create `test_driver/performance_test.dart` | Explicit | Doc contains inline code for this | `test_driver/` | P2 |
| T16 | Q21 | Create `test/accessibility/accessibility_test.dart` | Explicit | Doc contains inline code for this | `test/accessibility/` | P2 |
| T17 | Q24, Q25, Q26 | Install `flutter_a11y`, `accessibility_tools`, `flutter_driver` | Explicit | Doc references these as dependencies | `pubspec.yaml` | P2 |
| T18 | Q29 | Enforce performance budgets (<50MB APK, <16ms frames, <200MB memory) | Implicit | Doc defines performance budgets | CI/CD, build config | P2 |
| T19 | Q30 | Meet WCAG AA+ accessibility standards | Implicit | Doc defines accessibility requirements | All UI widgets | P2 |
| T20 | Q31 | Complete family management TODOs (name editing, copy ID, toggle settings) | Explicit | Doc lists family feature TODOs | `lib/screens/family_*.dart` | P1 |
| T21 | Q32 | Complete achievement screen TODOs (challenge generation, navigation) | Explicit | Doc lists achievement TODOs | `lib/screens/achievements_screen.dart` | P1 |
| T22 | Q33 | Implement GDPR consent management | Implicit | Doc says this must be done for production | `lib/services/user_consent_service.dart` | P0 |
| T23 | Q34 | Resolve all TODO comments for production | Explicit | Doc says all TODOs must be resolved | `lib/` | P1 |
| T24 | Q35 | Fix version inconsistency (v1.1 vs v1.2) | Implicit | Two version numbers in same doc | Doc itself | P3 |
| T25 | Q36 | Update document date/version to current | Implicit | Doc is 5+ months old | Doc itself | P2 |
| T26 | Q13 | Verify family dashboard integration test works | Explicit | Doc describes scenario 4 test | Integration tests | P1 |

## 5. Static Codebase Reality Check

### Task Candidate Verification

| Task ID | Codebase Status | Evidence | What exists today | Gap | Actual Work Needed |
|---------|----------------|----------|-------------------|-----|-------------------|
| T1 | **Already Done / Doc is wrong** | `lib/services/ad_service.dart:33,143,625,720` - exactly 4 TODOs, not 15+ | 4 TODOs exist: reward ad IDs, error tracking, reward ad functionality, setup checklist | Doc overstated count by 3.75x | Resolve 4 remaining TODOs; update doc |
| T2 | **Partially Done / Doc is wrong** | 31 real TODOs in `lib/` (word-boundary search); doc claimed 40+ | 31 TODOs across 17 files; top files: `recycling_code_info.dart` (5), `ad_service.dart` (4), `home_header_wrapper.dart` (3) | 31 TODOs remain; doc count inaccurate | Resolve TODOs or document for tracking; update doc |
| T3 | **Partially Done** | `lib/services/ad_service.dart:737,742` - placeholder XXXXXXXXXXXXXXXX~XXXXXXXXXX in block comments; production configs (`android/app/src/main/AndroidManifest.xml`, `ios/Runner/Info.plist`) use Google test IDs `ca-app-pub-3940256099942544` | Test IDs in production config; placeholders in comment | Need real AdMob IDs for production release | Replace test IDs with production AdMob unit IDs |
| T4 | **Already Done** | `lib/screens/result_screen.dart` - 18+ `Expanded()` usages, `TextOverflow.ellipsis`, `ReadMoreText`, `Wrap` patterns; 14 sub-widget files all use overflow protection | Comprehensive overflow protection exists | No gap | Update doc to reflect completion |
| T5 | **Already Done** | `lib/widgets/recycling_code_info.dart` - `Expanded` at lines 99,128,272; `maxLines`+`TextOverflow.ellipsis` at 137-138,146-147; collapsible `AnimatedSize` section at 173-209 | Proper overflow handling; 5 TODOs are i18n localization markers only, no display bugs | No display gap; i18n TODOs remain | Resolve i18n TODOs; update doc |
| T6 | **Already Done** | `lib/widgets/modern_ui/modern_buttons.dart:610-611` - `constraints.maxWidth < 80` and `< 120` breakpoints; confirmed by 16 passing tests in `test/widgets/view_all_button_test.dart` | 3 responsive modes: icon-only (<80px), abbreviated (80-120px), full text (>120px) | No gap | Update doc |
| T7 | **Already Done** | `lib/widgets/responsive_text.dart:50-96` - `cardTitle` constructor sets `maxLines=2`, `overflow=TextOverflow.ellipsis`, `minFontSize=14.0`, `maxFontSize=18.0`, `enableAutoSizing=true`, `enableWrapping=true` | `AutoSizeText` with comprehensive overflow protection | No gap | Update doc |
| T8 | **Already Done / Doc is dead wrong** | `lib/services/firebase_family_service.dart` (1028 lines); used by `lib/screens/family_dashboard_screen.dart` (1203 lines), `lib/screens/family_management_screen.dart` (1121 lines), `lib/screens/family_creation_screen.dart` (323 lines), `lib/screens/family_invite_screen.dart` (610 lines); accessible via 4th nav tab → `SocialScreen` → `FamilyDashboardScreen` | ~3200 lines of UI code across 4 screens; full streaming integration; document MASTER_TODO_COMPREHENSIVE.md confirms COMPLETED at line 1097 | No gap; doc is stale | Update doc to remove this "critical" item |
| T9 | **Already Done / Doc is dead wrong** | 46+ analytics tracking calls across 12 production files: `result_screen.dart` (11), `history_screen.dart` (5), `result_pipeline.dart` (6), `analytics_route_observer.dart` (5), `analytics_tracking_wrapper.dart` (7), `enhanced_reanalysis_widget.dart` (3), `frame_performance_monitor.dart` (3), `ui_performance_service.dart` (2), `offline_queue_service.dart` (1), `service_initialization_mixin.dart` (1), `content_detail_screen.dart` (1), `educational_content_service.dart` (1) | Comprehensive analytics tracking with 30+ method types | No gap; doc is stale | Update doc |
| T10 | **Already Done / Doc is dead wrong** | `lib/widgets/correction_dialog.dart` (505 lines) fully integrated: result screen (line 1032), history items (line 412), history screen (line 1002), settings screen (line 761), `lib/widgets/settings/feedback_settings_section.dart` (181 lines), `lib/models/classification_feedback.dart` (161 lines); feeds into `ResultPipeline.submitFeedback()` → local storage → cloud → gamification → analytics | Full feedback pipeline from UI to backend | No gap; doc is stale | Update doc |
| T11 | **Already Done** | `lib/services/ai_service.dart:139,208-223,273-298` - `CancelToken`, `cancelAnalysis()`, `isCancelled`, `_handleDioException` with `AiFailureKind.cancelled`; `lib/models/classification_state.dart:64,75-195` - `cancelled` as first-class enum; `lib/screens/image_capture_screen.dart:462-489` - `_cancelAnalysis()` with 34 `mounted` guards | End-to-end cancellation through HTTP layer, state machine, and UI | No gap; verify no regression | Run targeted cancellation test if available |
| T12 | **Already Done** | `lib/services/gamification_service.dart:840-841,623-624,655-656` - level check in 3 code paths; `lib/screens/achievements_screen.dart:467-469` - UI lock display; achievements gated at levels 2,3,4,5,6,7,8,10 | Level-gated achievements with UI lock indicators | No gap | Update doc |
| T13 | **Missing** | `.github/workflows/qa-checks.yml` does NOT exist; but 14 real workflows exist including `ci.yml`, `build_and_test.yml`, `comprehensive_testing.yml`, `security.yml`, `performance.yml` | The specific `qa-checks.yml` file from the doc doesn't exist | QA coverage exists via other workflows; `qa-checks.yml` not created | Either create it or note existing workflows suffice |
| T14 | **Missing** | `scripts/pre-commit-qa.sh` does NOT exist; `scripts/setup-git-hooks.sh` exists as alternative | No pre-commit QA script | Pre-commit QA not automated locally | Create or adapt |
| T15 | **Missing** | `test_driver/` directory does not exist at all | No Flutter Driver-based performance tests | Performance testing via driver is absent | Create or note that `test/performance/` directory exists as alternative |
| T16 | **Missing** | `test/accessibility/` directory does not exist; `test/accessibility/accessibility_test.dart` does not exist | No automated accessibility tests | Accessibility testing is manual only | Create or accept gap |
| T17 | **Missing** | `flutter_a11y`, `accessibility_tools`, `flutter_driver` NOT in `pubspec.yaml` dev_dependencies; only `flutter_test`, `flutter_lints`, `build_runner`, `json_serializable` present | No accessibility-specific Flutter packages installed | Dependencies not installed | Install if needed |
| T18 | **Missing / CI not enforcing** | `performance.yml` exists but verify it enforces budgets; no evidence of budget enforcement in CI | Performance CI workflow exists | May not enforce specific numeric budgets from doc | Add budget thresholds to CI |
| T19 | **Missing** | No accessibility tests; no `flutter_a11y`; 43 dart files mention `semanticsLabel` in lib/ | Some semantic labeling exists (43 files) | No automated WCAG AA+ verification | Add accessibility test infrastructure |
| T20 | **Partially Done / Needs verification** | Family management UI exists; TODO items from doc: "Name editing, copy ID, toggle settings" - need to verify against code | Family features exist | Specific TODOs may remain | Verify individual TODO items |
| T21 | **Needs Verification** | Achievement screen exists; doc lists "Challenge generation, navigation" as TODOs | Achievement screen exists | Specific TODOs may remain | Verify individual TODO items |
| T22 | **Partially Done** | `lib/services/user_consent_service.dart` exists; consent flow exists in UI; GDPR-specific controls need verification | Consent infrastructure exists | GDPR-specific consent management may need hardening | Audit consent flows |
| T23 | **Needs Work** | 31 real TODOs remain in `lib/` | 31 TODOs | All need resolution or tracking | Resolve or document each |
| T24 | **Minor doc bug** | Line 6: "Version: 1.1"; Line 636: "Version: 1.2" | Version inconsistency | One version number | Fix version in doc |
| T25 | **Doc maintenance** | Doc dated December 2024 | 5+ months stale | Need current date | Update doc |
| T26 | **Exists** | `test/screens/family_dashboard_screen_test.dart` - 1 passing test | Test exists and passes | Only 1 test; thin coverage | Expand test coverage |

## 6. Dynamic Verification and Test Baseline

### Baseline Test Commands and Results

| Command | Result | Notes |
|---------|--------|-------|
| `flutter test test/widgets/view_all_button_test.dart` | **16/16 passing** | All breakpoint, layout, and edge case tests pass |
| `flutter test test/ui_overflow_fixes_test.dart` | **2/2 passing** | Long category names and many-tag overflow tests pass |
| `flutter test test/regression_tests.dart` | **5/5 passing** | Achievement unlock, layout prevention, save/share, model validation |
| `flutter test test/screens/family_dashboard_screen_test.dart` | **1/1 passing** | Family dashboard create/join state test passes |

### Pre-existing Failures

No pre-existing failures discovered. All targeted tests pass. Full suite was not run due to likely long runtime.

**Full-suite command:**
```bash
flutter test --concurrency=1 2>&1 | tee test_baseline_full.log
```
**Not run.** Targeted tests provide reasonable but not complete evidence. The full suite should be run by a human before committing to work.

## 7. Critical Implementation and Test Traps Checked

### 7A. Environment Variable and Config Loading

- `os.getenv()` or equivalent Dart env var patterns: Not checked in depth for this audit. The Flutter/Dart `.env` files exist at root (`.env`, `.env.backup`, `.env.example`, `.env.template`) suggesting env var usage.
- No module-level env var caching issues identified in the search scope for this audit.
- **Flag:** Unknown - deeper env var search needed if privacy/security tasks are picked up.

### 7B. Test Isolation and State Leakage

- Target tests use standard `flutter_test` with `WidgetTester` - each test creates fresh widget trees.
- No order-dependent tests detected in checked files.
- No shared mutable state between tests detected.

### 7C. Full Test Suite Not Run

The full suite was not executed due to expected runtime. A full run is recommended before any production-related work.

### 7D. Proof-of-Concept Not Needed

No proof-of-concept probe was required. Static code verification and targeted dynamic tests provided sufficient evidence to resolve every claim.

## 8. Data, Privacy, and PII Boundary Checks

This QA checklist doc does not directly address PII, privacy guardrails, or data serialization boundaries. However:

- **Doc item Q33 (GDPR consent management):** `lib/services/user_consent_service.dart` (line 56+). Needs audit against GDPR requirements if T22 is picked up.
- **Doc line 180:** `grep -r "password\|secret\|key\|token" lib/ --exclude-dir=test | grep -v "// Safe:"` - A grep check is defined but the actual sensitivity of results is unknown.
- No PII-specific guardrails mentioned in this doc. The doc focuses on developer errors (layout, lifecycle, TODOs), not data privacy.

## 9. Deduped Issue / Task Register

### ISSUE-001: QA Document is Stale - Multiple "Critical" Claims Proven False

**Category:** docs

**Origin:** Explicit and Implicit
**Source doc:** `docs/testing/QA_CHECKLIST.md:38-40`
**Related doc items:** Q8, Q9, Q10, Q1, Q2, Q16, Q17

**Codebase Evidence:**
- `lib/services/firebase_family_service.dart` - 1028-line service fully integrated into 4 UI screens (T8)
- `lib/services/analytics_service.dart` - 46+ tracking calls across 12 production files (T9)
- `lib/widgets/correction_dialog.dart` - 505-line feedback widget fully integrated (T10)
- `lib/services/ad_service.dart:33,143,625,720` - 4 real TODOs, not 15+ (T1)

**Static Verification:**
- Full codebase search for FirebaseFamilyService usage: 4 production screens, 3 test files
- Full codebase search for analytics tracking calls: 46+ across 12 files
- Full codebase search for feedback widget integration: 5 integration points
- Word-boundary TODO count: 31, not 40+

**Dynamic Verification:**
- `flutter test test/screens/family_dashboard_screen_test.dart` - PASSES
- `flutter test test/regression_tests.dart` - 5/5 PASSING
- `flutter test test/widgets/view_all_button_test.dart` - 16/16 PASSING

**Current Behavior:**
The QA doc claims multiple systems are unimplemented when they are comprehensively implemented.

**Expected Behavior / Decision Needed:**
Doc should reflect current reality. Remove stale "Critical" items or mark them as verified.

**Gap:**
Doc is 5+ months stale. Three "Critical" items are false.

**Impact:** Misleads developers about what work remains; creates busywork verifying already-done items.

**Risk:** Low - doc is the problem, not the code.

**Confidence:** High - directly verified against code and tests.

**Acceptance Criteria:**
- [ ] Remove or update Q8 ("Firebase family service no UI integration") to reflect completion
- [ ] Remove or update Q9 ("Analytics no tracking calls") to reflect 46+ calls
- [ ] Remove or update Q10 ("Feedback widget not integrated") to reflect full integration
- [ ] Update TODO count claims from 40+ to 31
- [ ] Update AdMob TODO count from 15+ to 4
- [ ] Update document date/version

**Test Plan:**
- Manual: Review updated doc against code evidence

**Rollback / Kill Switch:** N/A - doc change only

**Open Questions:** None

---

### ISSUE-002: CI/CD and Test Infrastructure Doc References Don't Match Reality

**Category:** tooling / docs

**Origin:** Explicit
**Source doc:** `docs/testing/QA_CHECKLIST.md:207-413`
**Related doc items:** Q18, Q19, Q20, Q21, Q24, Q25, Q26

**Codebase Evidence:**
- `.github/workflows/qa-checks.yml` - DOES NOT EXIST (14 real workflows exist)
- `scripts/pre-commit-qa.sh` - DOES NOT EXIST
- `test_driver/performance_test.dart` - DOES NOT EXIST (`test_driver/` dir absent)
- `test/accessibility/accessibility_test.dart` - DOES NOT EXIST (`test/accessibility/` dir absent)
- `flutter_a11y`, `accessibility_tools`, `flutter_driver` - NOT in pubspec.yaml

**Static Verification:**
- File existence checks for all claimed paths
- grep of pubspec.yaml for all claimed dev dependencies

**Dynamic Verification:** N/A

**Current Behavior:**
The QA doc contains inline code for CI pipeline, pre-commit hook, performance driver, and accessibility test suite. None of these files exist. However, real CI infrastructure exists (14 workflows, including `ci.yml`, `build_and_test.yml`, `comprehensive_testing.yml`, `security.yml`, `performance.yml`).

**Expected Behavior / Decision Needed:**
Either create the listed files or update the doc to reference the existing infrastructure. The existing CI workflows likely cover most of the described functionality.

**Gap:**
- No `qa-checks.yml` (but other CI workflows exist)
- No pre-commit QA hook (local dev workflow gap)
- No automated performance driver tests
- No automated accessibility tests
- No accessibility-specific Flutter packages

**Impact:** New developers following the doc would try to run non-existent scripts. Local QA workflow doesn't have pre-commit hooks.

**Risk:** Medium - existing CI provides coverage; pre-commit hook gap is a local dev workflow gap.

**Confidence:** High

**Acceptance Criteria:**
- [ ] Either create `scripts/pre-commit-qa.sh` or document existing setup scripts
- [ ] Either create `qa-checks.yml` or document which existing workflows cover QA
- [ ] Either create accessibility test infrastructure or document it as deferred
- [ ] Update doc to reference real files, not aspirational ones

**Test Plan:**
- Automated: Verify pre-commit hook runs if created
- Manual: Review CI workflow coverage

**Rollback / Kill Switch:** N/A - config only

**Open Questions:**
- Do the existing 14 CI workflows sufficiently cover QA needs?
- Is the team actually using Flutter Driver or has it migrated to `integration_test`?

---

### ISSUE-003: 31 Production TODOs Remain Unresolved

**Category:** refactor / maintanability

**Origin:** Explicit
**Source doc:** `docs/testing/QA_CHECKLIST.md:17`
**Related doc items:** Q2, Q17, Q34, T2, T23

**Codebase Evidence:**
- 31 real TODOs in `lib/` (word-boundary `\bTODO\b` search)
- Top offenders: `lib/widgets/recycling_code_info.dart` (5 i18n TODOs), `lib/services/ad_service.dart` (4), `lib/widgets/home_header_wrapper.dart` (3 analytics), `lib/services/dynamic_pricing_service.dart` (3), `lib/services/analytics_service.dart` (3 hardcoded version/segment)
- `lib/screens/contribution_submission_screen.dart:967` - "TODO: Implement cloud function call"
- `lib/services/on_device_vision_service.dart:161` - "TODO: Implement actual TFLite inference here"
- `lib/services/cache_service.dart:842` - "TODO: Integrate with Firebase Remote Config"

**Static Verification:**
```bash
rg '\bTODO\b' lib/ -c | sort -t: -k2 -rn
```
31 TODOs total, 0 FIXME, 0 HACK

**Dynamic Verification:** N/A

**Current Behavior:**
31 TODOs exist in production code (`lib/`). The doc claims "No TODO comments in production code" as a pre-release must-pass.

**Expected Behavior / Decision Needed:**
Each TODO must be either: (1) resolved in code, (2) converted to a tracked issue, or (3) documented as intentionally deferred with reason.

**Gap:** 31 unresolved TODOs vs. 0 allowed per the QA checklist.

**Impact:** Mixed - some are minor (i18n, analytics hardcoding), some are significant (cloud function calls, TFLite inference, Remote Config).

**Risk:** Medium - some TODOs represent missing functionality; others are cosmetic.

**Confidence:** High

**Acceptance Criteria:**
- [ ] Classify all 31 TODOs: P0/P1/P2/P3
- [ ] Resolve P0/P1 TODOs
- [ ] Create tracked issues for deferred TODOs
- [ ] Update doc to set realistic TODO threshold (not zero)

**Test Plan:**
- Automated: `rg '\bTODO\b' lib/ -c` count should decrease
- Manual: Review each resolved TODO

**Rollback / Kill Switch:** N/A

**Open Questions:**
- What is the actual tolerance for TODOs before release?
- Should `on_device_vision_service.dart` TODOs be removed if TFLite is not planned soon?

---

### ISSUE-004: AdMob Uses Test Ad Unit IDs, Not Production IDs

**Category:** bug / operational-safety

**Origin:** Explicit
**Source doc:** `docs/testing/QA_CHECKLIST.md:18`
**Related doc items:** Q3, T3

**Codebase Evidence:**
- `android/app/src/main/AndroidManifest.xml` - uses Google test ad unit ID `ca-app-pub-3940256099942544/6300978111`
- `ios/Runner/Info.plist` - uses Google test ad unit ID `ca-app-pub-3940256099942544~1458002511`
- `lib/services/ad_service.dart:737,742` - placeholder `ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX` in comment block
- `lib/services/ad_service.dart:720` - ADMOB SETUP CHECKLIST TODO block

**Static Verification:**
- grep for `ca-app-pub-` across android/, ios/, lib/

**Dynamic Verification:** N/A - would need production AdMob account

**Current Behavior:**
App uses Google's official test ad IDs in production config files. Real ad unit IDs are not configured.

**Expected Behavior / Decision Needed:**
Before production release, replace test IDs with real AdMob ad unit IDs. Keep the test IDs for development builds.

**Gap:** Production configs contain test IDs; no build-variant-based AdMob ID switching.

**Impact:** Ads won't serve real inventory in production; AdMob may suspend account.

**Risk:** High for production launch; zero for development.

**Confidence:** High

**Acceptance Criteria:**
- [ ] Create real AdMob ad unit IDs (banner, interstitial, reward)
- [ ] Implement build-variant-based ID switching (debug uses test IDs, release uses production)
- [ ] Verify ads load correctly in release builds

**Test Plan:**
- Automated: Config check in CI that release builds don't contain test IDs
- Manual: Test ad loading in release build

**Rollback / Kill Switch:** Keep test IDs as fallback in debug mode. Ad loading can be disabled via feature flag.

**Open Questions:**
- Is the AdMob account set up and approved?
- Should ad loading be behind a feature flag?

---

### ISSUE-005: No Automated Accessibility Testing Infrastructure

**Category:** tests / accessibility

**Origin:** Implicit
**Source doc:** `docs/testing/QA_CHECKLIST.md:90-106`
**Related doc items:** Q21, Q24, Q25, T16, T17, T19

**Codebase Evidence:**
- `test/accessibility/` - DOES NOT EXIST
- `flutter_a11y` - NOT in pubspec.yaml
- `accessibility_tools` - NOT in pubspec.yaml
- 43 files in `lib/` mention `semanticsLabel` - semantic labeling exists in production code
- No automated accessibility scanning tooling

**Static Verification:**
- File existence checks
- `grep -r "semanticsLabel" lib/ | wc -l` = 43 (good organic coverage)
- pubspec.yaml analysis

**Dynamic Verification:** N/A

**Current Behavior:**
Semantic labels exist organically in 43 files. No automated accessibility testing or WCAG compliance checking.

**Expected Behavior / Decision Needed:**
Add accessibility test automation or explicitly document that manual testing is sufficient for current phase.

**Gap:** No automated accessibility testing; 43 semantic labels exist but aren't verified.

**Impact:** WCAG AA+ compliance cannot be verified automatically. Risk of accessibility regressions.

**Risk:** Medium - manual testing may catch basic issues; automated would be better.

**Confidence:** High

**Acceptance Criteria:**
- [ ] Add `accessibility_tools` or equivalent to dev_dependencies
- [ ] Create basic accessibility test for key screens
- [ ] OR document that manual testing is the current approach and why
- [ ] Update doc to reflect actual accessibility testing approach

**Test Plan:**
- Automated: Accessibility test for home screen, result screen
- Manual: Screen reader testing on iOS/Android

**Rollback / Kill Switch:** N/A

**Open Questions:**
- Is WCAG AA+ actually required for this app?
- What accessibility standards apply to mobile apps vs web?

---

### ISSUE-006: Doc Contains Aspirational Inline Code Presented as Existing

**Category:** docs

**Origin:** Implicit
**Source doc:** `docs/testing/QA_CHECKLIST.md:207-413`
**Related doc items:** Q18, Q19, Q20, Q21, T13, T14, T15, T16

**Codebase Evidence:**
- Lines 207-266: YAML for `qa-checks.yml` - presented as configuration but doesn't exist
- Lines 269-303: Bash for `pre-commit-qa.sh` - presented as script but doesn't exist
- Lines 306-350: Dart for `performance_test.dart` - presented as test but doesn't exist
- Lines 353-413: Dart for `accessibility_test.dart` - presented as test but doesn't exist
- These are inline examples/suggestions, but the doc presents them as existing infrastructure via integration references and "Run with" commands

**Static Verification:**
- File existence checks for all paths

**Dynamic Verification:**
- N/A - files don't exist so can't run

**Current Behavior:**
Doc contains what appears to be reference implementation code. The section headers describe "Workflows", "Scripts", "Test Drivers" without clearly distinguishing aspirational from existing.

**Expected Behavior / Decision Needed:**
Either: (1) implement the described infrastructure, or (2) clearly mark code blocks as aspirational/templates with "Not yet implemented" banners.

**Gap:** Misleading doc structure - looks like reference docs for existing infra but it's a wishlist.

**Impact:** Developers waste time trying to find or run non-existent files.

**Risk:** Low - nuisance for developers; no production impact.

**Confidence:** High

**Acceptance Criteria:**
- [ ] Add "TEMPLATE - Not yet implemented" headers to inline code sections
- [ ] OR create the referenced files
- [ ] Remove "Run with" commands that reference non-existent paths

**Test Plan:**
- Manual: Verify doc clarity

**Rollback / Kill Switch:** N/A

**Open Questions:** None

---

### ISSUE-007: No Performance Budget CI Enforcement

**Category:** tooling

**Origin:** Implicit
**Source doc:** `docs/testing/QA_CHECKLIST.md:108-124, 583-601`
**Related doc items:** Q29, T18

**Codebase Evidence:**
- `performance.yml` CI workflow exists but may not enforce specific numeric budgets
- No automated APK size check, frame budget check, memory usage check in CI
- Doc defines budgets: 50MB APK, 3s startup, 16ms frame, 200MB memory, 5s network

**Static Verification:**
- CI workflow file content review needed; `performance.yml` exists

**Dynamic Verification:**
- Not run - need to review CI workflow content

**Current Behavior:**
Performance budgets are defined in doc. Real CI enforcement unknown. No automated performance regression detection confirmed.

**Expected Behavior / Decision Needed:**
Add budget enforcement to CI or document threshold monitoring approach.

**Gap:** Budgets defined but enforcement mechanism unclear.

**Impact:** Performance regressions may go undetected.

**Risk:** Medium - performance issues catchable in manual testing but not automated.

**Confidence:** Medium - need to review `performance.yml` contents

**Acceptance Criteria:**
- [ ] Review existing `performance.yml` for budget enforcement
- [ ] Add budget checks or document that manual performance testing is current approach
- [ ] Update doc to reference actual enforcement mechanism

**Test Plan:**
- Automated: CI build with size check
- Manual: Profile build on device

**Rollback / Kill Switch:** Budget thresholds can be adjusted

**Open Questions:**
- What does `performance.yml` currently do?

---

## 10. Prioritization

| ID | Title | Severity | Blast Radius | Effort | Confidence | Priority | Why |
|----|-------|----------|-------------|--------|------------|----------|-----|
| ISSUE-001 | Stale doc - critical claims false | 3 | 4 | 1 | 5 | **P0** | Misleads all developers; 3 "Critical" claims are completely wrong; doc update is trivial effort |
| ISSUE-004 | AdMob uses test IDs | 4 | 3 | 2 | 5 | **P1** | Blocks production ad serving; only matters for release builds |
| ISSUE-003 | 31 production TODOs | 3 | 3 | 3 | 5 | **P1** | Accumulated technical debt; some TODOs represent missing features |
| ISSUE-002 | CI/infra doc mismatch | 2 | 2 | 3 | 5 | **P2** | Local dev workflow improvement; existing CI covers needs |
| ISSUE-005 | No accessibility tests | 2 | 2 | 3 | 5 | **P2** | Good semantic label coverage; automated testing would help |
| ISSUE-006 | Aspirational code in doc | 1 | 2 | 1 | 5 | **P2** | Cosmetic doc clarity issue |
| ISSUE-007 | No perf budget enforcement | 2 | 2 | 2 | 3 | **P2** | Needs more investigation of existing CI |

### Priority Queues

#### P0
- **ISSUE-001:** Update QA_CHECKLIST.md to remove stale "Critical" claims. Trivial effort, high blast radius (every developer who reads this doc).

#### P1
- **ISSUE-004:** Replace AdMob test IDs with production IDs (or build-variant switching). Blocks production monetization.
- **ISSUE-003:** Classify and resolve/schedule all 31 production TODOs. Notable blocking items: cloud function calls, TFLite inference, hardcoded analytics versions.

#### P2
- **ISSUE-002:** Align CI/pre-commit doc references with reality.
- **ISSUE-005:** Add accessibility test infrastructure or document approach.
- **ISSUE-006:** Mark aspirational doc code blocks.
- **ISSUE-007:** Investigate and harden performance budget enforcement.

#### P3
- **ISSUE-003 subsets:** i18n TODOs in recycling_code_info.dart (low impact, deferrable)
- **Doc version inconsistency** (T24 - trivial)

#### Quick Wins
- **ISSUE-001:** 10-minute doc update, removes 3 false "Critical" alerts.
- **ISSUE-006:** Add "TEMPLATE" labels to inline code sections.

#### Risky Changes
- **ISSUE-004:** AdMob ID changes require AdMob account setup; risk of ad serving issues if misconfigured.
- **ISSUE-003:** Some TODOs (TFLite inference, cloud functions) are large features, not simple fixes.

#### Needs Discussion Before Work
- **ISSUE-003:** Should on-device vision TODOs be deferred or removed if TFLite isn't planned soon?

#### Not Worth Doing
- None identified. All issues have genuine value.

## 11. Proof-of-Concept Validation

No proof-of-concept probe was needed. Static verification (code reading, grep-based search, file existence checks) plus targeted dynamic tests (4 test files, 24 tests, all passing) provided sufficient evidence for every claim.

## 12. Assumptions Challenged by Implementation

| Assumption | Why it seemed true | What disproved it | Evidence | How recommendation changed |
|-----------|-------------------|-------------------|----------|--------------------------|
| QA doc "Critical" claims are accurate | Doc is authoritative testing reference | Code search revealed full implementation | FirebaseFamilyService: 4 screens, 3200+ lines; Analytics: 46+ calls, 12 files; Feedback: 5 integration points | P0 priority shifted to doc update, not implementation |
| AdMob has 15+ TODOs | Doc states "15+ TODOs" | Exact word-boundary grep found 4 TODOs | `lib/services/ad_service.dart:33,143,625,720` | Reduced urgency; 4 TODOs are manageable |
| Total TODO count is 40+ | Doc states "40+ TODOs identified" | Word-boundary grep found 31 | `\bTODO\b` search across lib/ | Count was off by ~25% |
| QA CI workflow exists | Doc includes inline YAML for it | File existence check | `.github/workflows/qa-checks.yml` doesn't exist | CI gap smaller than doc suggests (14 real workflows exist) |
| Performance test driver exists | Doc includes inline Dart code | Directory check | `test_driver/` doesn't exist | Performance testing via driver is absent |

## 13. Parallel Agent / Multi-Model Findings

4 parallel exploration agents were used to verify different claim categories simultaneously:

| Agent | Role | Key Finding |
|-------|------|-------------|
| Agent A | TODO count + AdMob TODOs | 31 real TODOs (false positive issue with `toDouble()` substring); AdMob has 4, not 15+ |
| Agent B | Firebase family service UI integration | Service IS fully integrated across 4 screens; claim is dead wrong; other docs confirm completion |
| Agent C | Analytics + feedback widget | 46+ analytics calls across 12 files; feedback widget fully integrated at 5 touchpoints; both claims wrong |
| Agent D | ViewAllButton, ResponsiveText, recycle code, result screen | All 4 widget claims are accurate; overflow protection is comprehensive |

**Reconciliation:** All 4 agents returned consistent evidence. No disagreements. Agent B found documentation inconsistency across related docs (MASTER_TODO_COMPREHENSIVE.md correctly marks these as COMPLETED, while QA_CHECKLIST.md and STRATEGIC_ROADMAP_COMPREHENSIVE.md mark them as gaps).

## 14. Discussion Pack

### My Recommendation

I recommend working on:

1. **ISSUE-001** - Update QA_CHECKLIST.md to remove 3 false "Critical" claims
2. **ISSUE-003** - Triage and resolve/defer the 31 production TODOs
3. **ISSUE-004** - Set up real AdMob ad unit IDs

### Why These Matter Now

- **ISSUE-001** is undermining the entire QA process. Every developer reading this doc is told three systems are broken when they work. This wastes time and erodes trust in documentation.
- **ISSUE-003** contains blocking items: cloud function calls (967), TFLite inference (161), Remote Config (842), and hardcoded analytics versions (131, 299, 301). These represent real missing functionality.
- **ISSUE-004** blocks production monetization. Every day with test IDs in production configs risks AdMob compliance.

### What Breaks If Ignored

- **ISSUE-001 ignored:** Developers keep rediscovering that firebase/analytics/feedback already work, wasting time and creating a "docs aren't reliable" culture.
- **ISSUE-003 ignored:** Hardcoded app version in analytics will be wrong in releases. TFLite and cloud function stubs provide false promises to users.
- **ISSUE-004 ignored:** AdMob won't serve real ads. App may face policy violations for using test IDs in production.

### What I Would Not Work On Yet

- **ISSUE-005** (accessibility tests): Good organic semantic label coverage (43 files). Automated testing would be nice but not blocking.
- **ISSUE-006** (doc aspirational code): Purely cosmetic doc issue.
- **ISSUE-007** (perf budget enforcement): Needs more investigation of existing CI before acting.

### What Is Ambiguous

- Do the existing 14 CI workflows already cover what `qa-checks.yml` was supposed to do?
- Is `integration_test` (which IS in pubspec) the replacement for `flutter_driver` (which is NOT)?
- Should on-device vision TODOs be removed if TFLite integration isn't planned for the near term?

### Questions For You

1. **Should the QA_CHECKLIST.md be updated now, or should we audit all ~250 docs for similar staleness and do a batch update?**
2. **What's the actual TODO tolerance before release?** The doc says zero. Realistically, the 5 i18n TODOs and 3 hardcoded-version TODOs could ship. The cloud function TODO is more concerning. Where do you draw the line?
3. **Is the AdMob account set up?** If not, ISSUE-004 should be split into "set up AdMob account" and "configure IDs."
4. **Should the CI infrastructure be aligned to the doc, or should the doc be aligned to the infrastructure?** (i.e., create missing files or update doc to reference real files)

### Needs Runtime Verification

- Full `flutter test` suite run to establish baseline before any TODO resolution
- AdMob ID switching behavior in release builds
- GDPR consent flow end-to-end test

### Needs Online Research

- None required. All findings are repo-evidence based.

### Needs ChatGPT / External Review

Not needed. The evidence is clear and unambiguous.

## 15. Online Research

No online research needed. Current findings are repo-evidence based.

## 16. ChatGPT / External Review Escalation Writeup

Not needed.

## 17. Recommended Next Work Unit

### Unit-1: Update QA_CHECKLIST.md to Reflect Reality

**Goal:**
Update the QA checklist so it reflects actual codebase state. Remove the 3 false "Critical" claims (firebase family, analytics, feedback), correct TODO counts, and mark completed items accordingly.

**Issues covered:**
- ISSUE-001 (primary)
- ISSUE-006 (partial - can add clarity to aspirational code sections)

**Scope:**
- In: `docs/testing/QA_CHECKLIST.md` only
- Out: All other docs, code changes, TODO resolution

**Likely files touched:**
- `docs/testing/QA_CHECKLIST.md` - line 15 (AdMob TODO count), line 17 (total TODO count), line 38 (firebase family), line 39 (analytics), line 40 (feedback), lines 147-151 (scenario 4), line 505 (TODO resolution), version numbers

**Acceptance criteria:**
- [ ] Line 15: Update AdMob TODO count from "15+" to "4"
- [ ] Line 17: Update total TODO count from "40+" to "31"
- [ ] Line 38: Mark Firebase family service as COMPLETED with verification note
- [ ] Line 39: Mark Analytics tracking as COMPLETED with tracking call count
- [ ] Line 40: Mark Feedback widget as COMPLETED with integration points
- [ ] Lines 147-151: Mark scenario 4 integration tests as COMPLETED where applicable
- [ ] Lines 490-500: Update "Firebase Backend -> UI Integration" section to reflect completion
- [ ] Line 6 vs 636: Fix version inconsistency (use 1.3)
- [ ] Line 5: Update date to May 2026

**Tests to run:**
- Baseline: Same targeted tests as this audit (view_all_button, ui_overflow, regression, family_dashboard) - all passing
- Targeted: `flutter test test/widgets/view_all_button_test.dart test/ui_overflow_fixes_test.dart test/regression_tests.dart`
- Full suite: Optional for doc change; recommended before next code change

**Manual verification:**
- Read updated doc and verify no remaining stale claims
- Cross-reference with related docs (MASTER_TODO_COMPREHENSIVE.md lines 1052, 1097, 1106 for family completion)

**Docs to update:**
- `docs/testing/QA_CHECKLIST.md`

**Operational safety:**
- Kill switch / rollback: N/A - doc change only, revert with git

**Risks:**
- None - read-only doc update with no code changes

**Rollback plan:**
- Revert file to previous version

## 18. Appendix: Searches Performed

| # | Search | Tool | Purpose |
|---|--------|------|---------|
| 1 | `find docs/ -name "*.md"` | bash find | Document inventory |
| 2 | `rg '\bTODO\b' lib/ -c` | rg | Real TODO count in production code |
| 3 | `rg 'TODO' lib/ -c` | rg | Naive TODO count (includes `toDouble()` false positives) |
| 4 | `grep -n 'TODO' lib/services/ad_service.dart` | bash | AdMob TODO location and count |
| 5 | `grep -r 'FirebaseFamilyService' lib/` | rg | Firebase family service usage |
| 6 | `grep -r 'analytics\.\|\.logEvent\|\.trackEvent\|\.trackScreenView\|\.trackUserAction' lib/` | rg | Analytics tracking calls |
| 7 | `grep -r 'CorrectionDialog\|ClassificationFeedback\|submitFeedback' lib/` | rg | Feedback widget integration |
| 8 | `grep -r 'ca-app-pub-' lib/ android/ ios/` | rg | AdMob ad unit IDs |
| 9 | `grep -r 'mounted' lib/screens/image_capture_screen.dart` | rg | Mounted guard counts |
| 10 | `grep -r 'CancelToken\|cancelAnalysis\|isCancelled' lib/` | rg | Cancellation flow |
| 11 | `grep -r 'unlocksAtLevel' lib/` | rg | Achievement level gating |
| 12 | `grep -r 'semanticsLabel' lib/ -c` | rg | Semantic label coverage (43 files) |
| 13 | `grep 'flutter_a11y\|accessibility_tools\|flutter_driver' pubspec.yaml` | rg | Dev dependency check |
| 14 | File existence: `.github/workflows/qa-checks.yml`, `scripts/pre-commit-qa.sh`, `test_driver/`, `test/accessibility/` | bash ls | Infrastructure file existence |
| 15 | `flutter test test/widgets/view_all_button_test.dart` | flutter | Dynamic: 16/16 pass |
| 16 | `flutter test test/ui_overflow_fixes_test.dart` | flutter | Dynamic: 2/2 pass |
| 17 | `flutter test test/regression_tests.dart` | flutter | Dynamic: 5/5 pass |
| 18 | `flutter test test/screens/family_dashboard_screen_test.dart` | flutter | Dynamic: 1/1 pass |
