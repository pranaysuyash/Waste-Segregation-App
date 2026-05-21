# Random Document Audit Report

## 1. Document Inventory

Doc inventory method:
- Source: repository-wide markdown and named planning/audit files.
- Commanded inventory found 561 candidate docs.
- Inventory command output sample includes root docs, docs/**, archive fixes, ADRs, TODOs.

Sample inventory rows:

| Doc ID | Path | Type | Why it may matter |
|---|---|---|---|
| DOC-001 | README.md | README | Canonical product/runtime claims often drift from code. |
| DOC-002 | docs/reference/CHANGELOG.md | Changelog | Release claims must match present code reality. |
| DOC-003 | docs/archive/fixes/critical_gamification_model_migration.md | Fix Doc | Declares migration completeness and specific file-level changes. |
| DOC-004 | docs/adr/ADR-001-clean-architecture.md | ADR | Architectural expectations influence migration intent. |
| DOC-005 | docs/analytics/ANALYTICS_IMPLEMENTATION_TODOS.md | Plan/TODO | Shows expected unfinished work and dependencies. |
| DOC-006 | firebase_task.md | Task spec | Current phase priorities may constrain “next work unit”. |
| DOC-007 | motto_v2.md | Execution rules | Required quality and verification discipline. |

## 2. Random Selection

Chosen document: docs/archive/fixes/critical_gamification_model_migration.md

Selection method:
- Earlier in-session random choice was used from discovered doc inventory (system-random choice over full candidate set during initial audit pass).
- Reproducibility check performed later with a deterministic hash method produced a different file (docs/audit/DEPRECATION_AUDIT_2026-05-21.md), which confirms selection method differences and that deterministic replay was not the original selector.

Why this doc is worth auditing:
- It claims a critical architecture migration is complete and compilation-breaking issues are resolved.
- It names specific files, APIs, compatibility behavior, and test/build outcomes that are directly verifiable.

## 3. Chosen Document Deep Analysis

Source: docs/archive/fixes/critical_gamification_model_migration.md:1-207

### Extracted doc items (explicit + implicit + claims)

| Doc Item ID | Type | Short quote / evidence | Location | Interpretation | Confidence |
|---|---|---|---|---|---|
| DI-001 | Current-State Claim | “migration ... completed on January 4, 2025” | :5 | Historical completion claim; verify present consistency, not historical intent only. | High |
| DI-002 | Architecture Claim | “Map<String, StreakDetails> streaks” | :11, :37 | Core model should exist and be the active access pattern. | High |
| DI-003 | Current-State Claim | “Service Code: Still accessing old profile.streak.current” | :12 | Implies issue existed and was fixed; verify no remaining old accesses. | High |
| DI-004 | Explicit Task | “Code Changes Required ... constructor updates” | :60-91 | Constructors should include required new fields and streak map init. | High |
| DI-005 | Explicit Task | “Streak Access Pattern Updates” | :93-106 | UI/service must use map access by streak type key. | High |
| DI-006 | Intended-State Claim | “updateStreak rewritten ... backward compatibility” | :110-115 | Service should return/bridge legacy Streak shape where needed. | High |
| DI-007 | Intended-State Claim | “All UI screens now use helper methods” | :120 | Uniform helper pattern should exist or equivalent consistency. | Medium |
| DI-008 | Architecture Claim | “Screens Updated ... ModernHomeScreen” | :137-141, :170 | Referenced screen/file should exist or mapping should be documented. | High |
| DI-009 | Test/QA Claim | “Compilation successful ... app builds ... remaining test files need updates” | :185-189 | Verify with analyze/test/build proxies. | High |
| DI-010 | Intended-State Claim | “All streak features working ... all screens display correctly” | :1329-1331 in changelog | Must verify against active screens and tests. | Medium |
| DI-011 | Stale/Unknown | “docs/fixes/... - This file” | :175 | Path appears stale vs current archive location. | High |

## 4. Extracted Task Candidates

| Task Candidate ID | Source Doc Item IDs | Task | Explicit/Implicit | Why this is a task | Expected repo area | Initial priority |
|---|---|---|---|---|---|---|
| TC-001 | DI-002, DI-004 | Verify model actually uses streaks map + required fields | Explicit | Core migration invariant | lib/models/gamification.dart | P1 |
| TC-002 | DI-003, DI-005 | Verify old profile.streak.* access removed | Explicit | Prevent regression and runtime null/missing field bugs | lib/** | P1 |
| TC-003 | DI-006 | Verify updateStreak compatibility bridge behavior | Explicit | Legacy callers may still expect Streak object | lib/services/gamification_service.dart | P1 |
| TC-004 | DI-007, DI-008 | Verify all named screens updated; detect stale key usage | Explicit | UI drift is likely in duplicate/legacy screens | lib/screens/*home*, achievements, dashboard | P0 |
| TC-005 | DI-008, DI-011 | Validate referenced files/paths exist and docs are accurate | Implicit | Stale docs mislead future work selection | docs/archive/fixes, docs/reference/CHANGELOG.md | P2 |
| TC-006 | DI-009, DI-010 | Validate current build/test reality against completion claims | Explicit | Decision-making depends on present risk, not historical claims | flutter analyze, flutter test | P0 |
| TC-007 | DI-007 | Check for duplicated home screen implementation risk | Implicit | Multiple home implementations cause migration drift | lib/screens/home_screen.dart, ultra_modern_home_screen.dart | P1 |
| TC-008 | DI-009 | Baseline targeted vs full-suite signal quality | Implicit | Isolated pass may hide global breakages | test/* + full suite | P1 |

## 5. Static Codebase Reality Check

### TC-001: Model migration existence
Status: Already Done

Evidence:
- lib/models/gamification.dart:625 class GamificationProfile
- lib/models/gamification.dart:691 final Map<String, StreakDetails> streaks
- lib/models/gamification.dart:701-707 discoveredItemIds / unlockedHiddenContentIds present
- lib/models/gamification.dart:1262 enum StreakType
- lib/models/gamification.dart:1276 class StreakDetails

What exists today:
- Multi-streak model is present and serialized.

Gap:
- None for base model definition.

Actual work needed:
- None.

### TC-002: Legacy profile.streak access removal
Status: Already Done

Evidence:
- Search pattern `profile.streak.(current|longest|lastUsageDate)` returned no matches in lib.

What exists today:
- Active code references `profile.streaks[...]` map pattern.

Gap:
- None found for old direct `profile.streak.*` usage.

Actual work needed:
- None.

### TC-003: Service backward compatibility in updateStreak
Status: Already Done (with caveat)

Evidence:
- lib/services/gamification_service.dart:366-407 `Future<Streak> updateStreak()` returns legacy `Streak` while reading/writing `StreakDetails`.
- lib/services/gamification_service.dart:385-398 reads from map key and writes `StreakDetails`.

What exists today:
- Compatibility bridge exists.

Gap:
- No immediate mismatch seen in this function.

Actual work needed:
- None for migration-specific behavior.

### TC-004: UI consistency across named screens
Status: Partially Done + Duplicated + Contradictory Evidence

Evidence:
- Correct key usage:
  - lib/screens/home_screen.dart:364, 649 uses `StreakType.dailyClassification.toString()`.
  - lib/screens/achievements_screen.dart:1740, 1747 helper methods use typed key.
  - lib/screens/waste_dashboard_screen.dart:1250 uses typed key.
  - lib/screens/ultra_modern_home_screen.dart:361 uses typed key.
- Stale key usage:
  - lib/screens/ultra_modern_home_screen.dart:585 uses `profile?.streaks['daily']?.currentCount`.

What exists today:
- Most UI uses migrated access pattern, but at least one stale literal key remains.

Gap:
- Non-uniform key access in UltraModernHomeScreen.

Actual work needed:
- Normalize ultra_modern_home_screen.dart to the same typed key strategy.

### TC-005: File/path/documentation accuracy
Status: Stale Doc

Evidence:
- Doc references modern home file:
  - docs/archive/fixes/critical_gamification_model_migration.md:139,170 mention `ModernHomeScreen` / `modern_home_screen.dart`.
- Actual files:
  - search in lib/screens for `*modern_home_screen.dart` returns only `ultra_modern_home_screen.dart`.
- Canonical screen note:
  - lib/screens/home_screen.dart:31-35 says consolidated canonical HomeScreen, former ultra-modern wrapper should not be runtime source of truth.
- Doc location mismatch:
  - migration doc line 175 references `docs/fixes/...`, but file currently is in `docs/archive/fixes/...`.

What exists today:
- Documentation naming/path drift.

Gap:
- Doc claims don’t reflect current file naming and canonical ownership.

Actual work needed:
- Documentation correction addendum (not rewrite historical narrative, add present-state audit note).

### TC-006: Build/test claim verification
Status: Contradictory Evidence + Broken (current branch state)

Evidence:
- Full analyze failed:
  - `flutter analyze` exit_code=1 with 576 issues.
  - Hard errors include undefined identifiers in image capture flow:
    - lib/screens/image_capture_screen.dart:295,300,304 `_analysisStage` referenced but no declaration.
    - lib/screens/image_capture_screen.dart:350+ `_isCancelled` references.
    - lib/screens/image_capture_screen.dart:484+ `_isAnalyzing` references.
  - Declaration search confirms missing declarations:
    - no matches for `AnalysisProgressStage _analysisStage`, `bool _isAnalyzing`, `bool _isCancelled` in this file.
- Full test failed:
  - `flutter test` exit_code=1, final summary `Some tests failed` (at least `~11 -17` in current run).
- Widgetbook test failed:
  - `flutter test test/widgetbook/widgetbook_smoke_test.dart` exit_code=1 with cascading compile errors.

What exists today:
- Current branch does not satisfy “compilation successful / all screens correct” present-state claim.

Gap:
- Major current compile/test instability outside narrow gamification model migration scope.

Actual work needed:
- Triage and restore `image_capture_screen.dart` state-machine fields and related compile path before trusting broad migration-complete claims.

### TC-007: Duplicate home screen drift risk
Status: OperationalRisk + Duplicated

Evidence:
- Canonical claim:
  - lib/screens/home_screen.dart:31-35.
- Duplicate implementation still present:
  - lib/screens/ultra_modern_home_screen.dart full stateful implementation.
- Runtime route usage currently points to HomeScreen:
  - lib/widgets/navigation_wrapper.dart:177,610 instantiate HomeScreen.

What exists today:
- Two home implementations; one canonical in routing, one parallel file still editable.

Gap:
- Future edits can regress stale file unnoticed, then re-enter runtime later.

Actual work needed:
- Product/architecture decision: deprecate/remove UltraModernHomeScreen or keep it under explicit non-runtime boundary/tests.

### TC-008: Targeted vs full-suite evidence quality
Status: Needs Runtime Verification (completed) -> Contradictory Evidence resolved

Evidence:
- Targeted tests pass:
  - flutter test test/screens/classification_details_screen_test.dart -> pass
  - flutter test test/screens/image_capture_screen_test.dart -> pass
  - flutter test test/services/cache_service_test.dart -> pass
- Full suite fails with compile/runtime aggregate issues:
  - flutter test -> fail (`Some tests failed`, current run ~11 skipped, 17 failures).

What exists today:
- Narrow targeted tests are insufficient proof of repo health.

Gap:
- Full-suite signal conflicts with targeted pass.

Actual work needed:
- Keep full-suite as release gate; use targeted tests only for local fault isolation.

## 6. Dynamic Verification and Test Baseline

Baseline command set:
- flutter analyze
- flutter test
- flutter test test/widgetbook/widgetbook_smoke_test.dart
- flutter test test/screens/classification_details_screen_test.dart
- flutter test test/screens/image_capture_screen_test.dart
- flutter test test/services/cache_service_test.dart

Results:
- flutter analyze: failed (exit 1), 576 issues, includes hard errors in image_capture_screen.dart.
- flutter test (full): failed (exit 1), final summary indicates multiple failures (`Some tests failed`, ~17 failures in current run).
- widgetbook smoke test: failed (exit 1), compile cascade shown.
- targeted 3 tests above: passed.

Pre-existing vs new regressions:
- No code probe changes were made in this audit pass.
- Therefore all observed failures are treated as pre-existing branch state.

## 7. Critical Implementation and Test Traps Checked

1) Environment/config loading
- Relevant to selected migration: limited.
- Observed in ai_service/image_capture path `bool.fromEnvironment(...)` toggles debug segmentation:
  - lib/services/ai_service.dart:97-98
  - lib/screens/image_capture_screen.dart:64-66
- No migration-specific env-cache issue found for gamification streak model.

2) Module-level state leakage
- Gamification service has mutable state:
  - _cachedProfile and _isUpdatingStreak path (seen around updateStreak logic).
- No direct failing evidence in current targeted gamification tests.

3) Test isolation
- Targeted tests pass while full suite fails strongly.
- Conclusion: isolated success is weak evidence; full-suite gate must dominate.

4) Write-path coverage
- Migration doc is streak-model focused; no PII/persistence guardrail change was requested by selected doc.
- Save path in gamification service verifies streak map persistence through saveProfile path (static inspection), but broad write-path audit was outside this selected doc’s central claim.

## 8. Data, Privacy, and PII Boundary Checks

Not central to selected migration document.
No new privacy/PII enforcement introduced by this migration doc was detected in audited surfaces.

## 9. Deduped Issue / Task Register

## ISSUE-001: Stale streak key in UltraModernHomeScreen

Category:
- bug / architecture

Origin:
- Explicit + Implicit
- Source doc: docs/archive/fixes/critical_gamification_model_migration.md:93-106, 120-141
- Related doc items: DI-005, DI-007, DI-008

Codebase Evidence:
- lib/screens/ultra_modern_home_screen.dart:585 - uses `profile?.streaks['daily']?.currentCount`
- lib/screens/home_screen.dart:364,649 - uses typed key `StreakType.dailyClassification.toString()`

Static Verification:
- Mixed keying strategy exists.

Dynamic Verification:
- No specific failing test directly attributes to this stale key yet.

Current Behavior:
- Ultra modern path can read 0 streak despite existing streaks map key mismatch.

Expected Behavior / Decision Needed:
- All streak reads should use typed key source-of-truth.

Gap:
- One stale literal key remains.

Impact:
- Incorrect streak display if this screen is used.

Risk:
- Drift regression and incorrect UX data.

Confidence:
- High

Acceptance Criteria:
- [ ] All streak reads in ultra_modern_home_screen.dart use `StreakType.dailyClassification.toString()`.
- [ ] No `'daily'` literal streak key usage remains in lib/screens.
- [ ] Relevant screen tests updated/added for streak display correctness.

Test Plan:
- Automated:
  - grep/search no literal `'daily'` key in streak map lookups
  - targeted screen/widget tests for streak rendering
- Manual:
  - Navigate to home variants and compare streak counters with profile fixture

Rollback / Kill Switch:
- N/A (small UI read-path fix)

Open Questions:
- Is UltraModernHomeScreen still intended runtime surface or archival?

---

## ISSUE-002: Home screen duplication creates migration drift

Category:
- architecture / operational-safety

Origin:
- Implicit
- Source doc: docs/archive/fixes/critical_gamification_model_migration.md:135-141, 161-171
- Related doc items: DI-007, DI-008

Codebase Evidence:
- lib/screens/home_screen.dart:31-35 - canonical single source of truth claim
- lib/screens/ultra_modern_home_screen.dart:1-1849 - full parallel implementation
- lib/widgets/navigation_wrapper.dart:177,610 - runtime uses HomeScreen

Current Behavior:
- Duplicate home implementations exist but only one is routed.

Expected Behavior / Decision Needed:
- Explicit policy for ultra_modern_home_screen.dart lifecycle.

Gap:
- No enforced deprecation boundary, allowing silent drift.

Impact:
- Future refactors can miss one screen and reintroduce stale logic.

Risk:
- Medium architectural entropy.

Confidence:
- High

Acceptance Criteria:
- [ ] Decision recorded: retire, freeze, or keep with mirrored maintenance policy.
- [ ] If retained, add tests/linters/checks to prevent keying drift.
- [ ] Docs updated with actual canonical path and lifecycle status.

Test Plan:
- Automated: route tests confirm only intended screen is reachable.
- Manual: smoke nav to home entrypoints.

Rollback / Kill Switch:
- If removal path chosen, keep reversible commit-level backup (out of scope now).

Open Questions:
- Should UltraModernHomeScreen be removed in next cleanup phase?

---

## ISSUE-003: Migration docs/changelog contain stale file naming and path references

Category:
- docs

Origin:
- Explicit
- Source doc: docs/archive/fixes/critical_gamification_model_migration.md:139,170,175
- Related doc items: DI-008, DI-011

Codebase Evidence:
- No `lib/screens/modern_home_screen.dart`; only `lib/screens/ultra_modern_home_screen.dart`.
- Doc references `docs/fixes/...` while actual location is `docs/archive/fixes/...`.

Current Behavior:
- Historical migration docs can mislead active implementation planning.

Expected Behavior:
- Add present-state addendum clarifying canonical screen and stale references.

Gap:
- Reference drift unresolved.

Impact:
- Wasted engineering cycles and wrong file targeting.

Risk:
- Medium documentation reliability risk.

Confidence:
- High

Acceptance Criteria:
- [ ] Add addendum section: “Current state verification (2026-05-22)”.
- [ ] Correct file/path references or explicitly mark as historical.
- [ ] Link to canonical home screen comment location.

Test Plan:
- Manual docs review.

Rollback / Kill Switch:
- N/A

Open Questions:
- Prefer to edit archive doc in place or add new audit doc pointer only?

---

## ISSUE-004: Current branch compile/test health contradicts migration completion claims

Category:
- reliability / testing / operational-safety

Origin:
- Explicit
- Source doc: docs/archive/fixes/critical_gamification_model_migration.md:185-189; docs/reference/CHANGELOG.md:1328-1331
- Related doc items: DI-009, DI-010

Codebase Evidence:
- flutter analyze exit 1 with hard errors in image capture flow.
- lib/screens/image_capture_screen.dart references undeclared fields:
  - `_analysisStage` usages at :295, :300, :304
  - `_isCancelled` usages at :350, :357, :368, :374, etc.
  - `_isAnalyzing` usages at :484, :662, :1169, :1188, etc.
- search confirms no declarations for those fields in file.
- flutter test full suite fails (`Some tests failed`).

Current Behavior:
- Repo does not satisfy current compile/test green state.

Expected Behavior:
- Branch baseline should at least compile-analyze without hard errors before migration-closure claims are used for work selection.

Gap:
- Significant current breakage outside narrow streak model scope.

Impact:
- High; invalidates confidence in broad “done” claims.

Risk:
- High operational risk.

Confidence:
- High

Acceptance Criteria:
- [ ] Resolve undefined identifiers in image_capture_screen.dart.
- [ ] Re-run flutter analyze with zero hard errors.
- [ ] Re-run full suite and separate flaky/skipped from hard fails.

Test Plan:
- Automated: `flutter analyze`, `flutter test`.
- Manual: image capture happy path and cancellation path sanity checks.

Rollback / Kill Switch:
- Keep fixes scoped to image-capture compile path first; avoid broad refactors.

Open Questions:
- Were `_isAnalyzing/_isCancelled/_analysisStage` intentionally removed during a state-machine migration?

---

## ISSUE-005: Full-suite vs targeted-suite mismatch creates false confidence risk

Category:
- tests / reliability

Origin:
- Implicit
- Source doc: migration “remaining test files need updates” claim
- Related doc items: DI-009

Codebase Evidence:
- Targeted tests pass:
  - classification_details_screen_test
  - image_capture_screen_test
  - cache_service_test
- Full suite fails with many failures.

Current Behavior:
- Local targeted checks can pass while repository remains broken.

Expected Behavior:
- Any migration completion claim requires full-suite status context.

Gap:
- No enforced “full-suite or documented exception” gate for migration sign-off.

Impact:
- Medium-high; can ship regressions.

Risk:
- High false-negative risk.

Confidence:
- High

Acceptance Criteria:
- [ ] Add audit/release checklist requiring full-suite snapshot in migration docs.
- [ ] Record known-failing tests with ownership and reason.

Test Plan:
- Automated: CI/full suite.

Rollback / Kill Switch:
- N/A

Open Questions:
- What subset is authoritative if full suite is too slow/noisy?

## 10. Prioritization

| ID | Title | Severity | Blast Radius | Effort | Confidence | Priority | Why |
|---|---|---:|---:|---:|---:|---|---|
| ISSUE-004 | Compile/test health contradicts completion claims | 5 | 5 | 3 | 5 | P0 | Hard compile errors and full-suite failure block trustworthy progress. |
| ISSUE-001 | Stale streak key in UltraModernHomeScreen | 3 | 3 | 1 | 5 | P1 | Direct migration drift; low effort, clear correctness fix. |
| ISSUE-002 | Home screen duplication drift risk | 3 | 4 | 2 | 5 | P1 | Ongoing architecture risk and future regression vector. |
| ISSUE-005 | Targeted vs full-suite mismatch risk | 4 | 4 | 2 | 5 | P1 | Quality-gate process gap, not just code bug. |
| ISSUE-003 | Stale docs/path references | 2 | 3 | 1 | 5 | P2 | Important for planning accuracy, not immediate runtime blocker. |

Priority queues:

### P0
- ISSUE-004

### P1
- ISSUE-001
- ISSUE-002
- ISSUE-005

### P2
- ISSUE-003

### P3
- None

### Quick Wins
- ISSUE-001, ISSUE-003

### Risky Changes
- ISSUE-004 (touches capture flow/state machine behavior)

### Needs Discussion Before Work
- ISSUE-002 (retire vs maintain UltraModernHomeScreen)
- ISSUE-005 (quality gate policy)

### Not Worth Doing
- Rewriting archived historical narrative as if it were current reality. Better: add current-state addendum.

## 11. Proof-of-Concept Validation

No proof-of-concept probe was needed. Static and existing dynamic evidence were sufficient.

## 12. Assumptions Challenged by Implementation

| Assumption | Why it seemed true | What disproved it | Evidence | Recommendation change |
|---|---|---|---|---|
| Migration-complete docs imply current compile stability | Doc/changelog explicit completion language | Current analyze/test state is broken | flutter analyze (hard errors), flutter test fails | Prioritize baseline compile health before migration follow-up features |
| Targeted tests are enough evidence | Critical targeted tests passed | Full suite still fails | targeted passes + full-suite fail | Require full-suite snapshot for closure claims |
| All screens use migrated streak key | Doc says all screens updated | UltraModernHomeScreen still uses `'daily'` literal key | ultra_modern_home_screen.dart:585 | Add focused fix or deprecate screen |

## 13. Parallel Agent / Multi-Model Findings

- Subagent delegation was attempted earlier in this audit workflow and failed due provider subscription errors (403 model access).
- Result: role split was simulated sequentially in the main agent:
  - Document analyst
  - Codebase verifier
  - Test/runtime verifier
  - Architecture risk reviewer
  - Skeptic pass (contradiction check)

## 14. Discussion Pack

## My Recommendation

I recommend working on:
1. ISSUE-004 - Compile/test baseline restoration for image capture state fields
2. ISSUE-001 - Streak key normalization in UltraModernHomeScreen
3. ISSUE-003 - Documentation addendum for migration reality

Reason:
- ISSUE-004 is a hard blocker for credible delivery.
- ISSUE-001 is a direct migration correctness gap with low effort.
- ISSUE-003 prevents repeated mis-targeting and confusion.

## Why These Matter Now
- Without compile baseline, every subsequent audit/planning decision is noisy.
- Stale key usage is a concrete migration inconsistency.
- Stale docs are repeatedly causing wrong assumptions.

## What Breaks If Ignored
- Continued CI/test instability.
- Potential incorrect streak UX in alternate home surface.
- Repeated planner/operator confusion from outdated file references.

## What I Would Not Work On Yet
- Broad gamification feature expansion.
- Deep architectural rewrites beyond narrow baseline restore.

## What Is Ambiguous
- Whether UltraModernHomeScreen remains a supported runtime surface.
- Whether current image-capture errors are mid-refactor intentional state.

## Questions For You
1. Should UltraModernHomeScreen be treated as live product surface or deprecated artifact?
2. For current branch policy: must `flutter analyze` be hard-zero errors before feature work resumes?
3. Do you want archived migration docs edited directly, or a separate “current-state audit addendum” file only?

## Needs Runtime Verification
- After ISSUE-004/001: re-run full suite to confirm no hidden coupling regressions.

## Needs Online Research
- None for this decision set.

## Needs ChatGPT / External Review
- Not required right now; repo evidence is sufficient.

## 15. Online Research

No online research needed. Current findings are repo-evidence based.

## 16. ChatGPT / External Review Escalation Writeup

Not needed at this stage.

## 17. Recommended Next Work Unit

## Unit-1: Restore compile baseline for image capture state migration

Goal:
- Re-establish compile/test baseline by resolving missing image-capture state fields and ensuring state-machine migration is coherent.

Issues covered:
- ISSUE-004

Scope:
- In:
  - Resolve `_analysisStage`, `_isAnalyzing`, `_isCancelled` declaration/usage coherence in image_capture_screen.dart
  - Ensure deprecated bridge accessors map correctly to state machine
- Out:
  - Feature additions
  - Broad UI redesign
  - Gamification feature extension

Likely files touched:
- lib/screens/image_capture_screen.dart
- (possibly) providers/classification_state_provider.dart if bridge contract changed
- tests for image capture flow

Acceptance criteria:
- [ ] `flutter analyze` has no hard errors from image_capture_screen.dart
- [ ] `flutter test test/screens/image_capture_screen_test.dart` passes
- [ ] `flutter test` full suite run recorded; new failures vs baseline explicitly separated

Tests to run:
- Baseline:
  - flutter analyze
  - flutter test
- Targeted:
  - flutter test test/screens/image_capture_screen_test.dart
- Full suite:
  - flutter test

Manual verification:
- Launch capture flow, start analysis, cancel path, and completion path.

Docs to update:
- docs/audit/RANDOM_DOC_AUDIT_2026-05-22_gamification_migration.md (this file)
- add migration addendum note after fix completion.

Operational safety:
- Kill switch / rollback:
  - Keep changes scoped to state variables + state-machine bridge; rollback by reverting only image capture state migration chunk.

Risks:
- Hidden coupling with result screen and async callbacks.

Rollback plan:
- Revert only image_capture_screen.dart migration edits if new full-suite failures exceed baseline.

## 18. Appendix: Searches Performed

- Document inventory and counts (execute_code glob inventory)
- Search streak key usage:
  - `streaks['daily']`, `dailyClassification.toString()`, helper methods in screens
- Search legacy API usage:
  - `profile.streak.current|longest|lastUsageDate`
- Search file existence:
  - `*modern_home_screen.dart`
- Search runtime home usage:
  - `HomeScreen(` and `UltraModernHomeScreen(`
- Test and analyze commands:
  - flutter analyze
  - flutter test
  - flutter test test/widgetbook/widgetbook_smoke_test.dart
  - flutter test test/screens/classification_details_screen_test.dart
  - flutter test test/screens/image_capture_screen_test.dart
  - flutter test test/services/cache_service_test.dart
