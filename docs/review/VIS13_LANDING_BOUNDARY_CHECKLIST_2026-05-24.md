# VIS-13 Landing Boundary Checklist (2026-05-24)

## Purpose
Freeze an explicit, review-safe boundary for VIS-13 (Premium Toggle Visuals) so it can be landed without mixing unrelated in-flight work.

## Canonical VIS-13 file set (include list)
Implementation/UI:
- lib/widgets/settings/premium_feature_visuals.dart
- lib/widgets/settings/app_settings_section.dart
- lib/widgets/settings/features_section.dart
- lib/widgets/premium_feature_card.dart
- lib/widgets/premium_lock_wrapper.dart
- lib/widgets/premium_segmentation_toggle.dart
- lib/screens/premium_features_screen.dart
- lib/screens/theme_settings_screen.dart

Tests:
- test/screens/premium_features_screen_test.dart
- test/screens/theme_settings_screen_premium_gate_test.dart
- test/widgets/premium_feature_card_test.dart
- test/widgets/premium_segmentation_toggle_test.dart
- test/widgets/settings/settings_navigation_contract_test.dart
- test/helpers/component_test_harness.dart
- test/golden/settings_golden_test.dart

Evidence docs:
- docs/review/premium_toggle_visuals_followthrough_2026-05-23.md

## Live git-state check (read-only evidence)
Command used:
- git status --short -- <VIS-13 canonical file set>

Result:
- Modified in canonical VIS-13 set: docs/review/premium_toggle_visuals_followthrough_2026-05-23.md
- No other canonical VIS-13 code/test files currently dirty.

Interpretation:
- VIS-13 code/test implementation appears already landed in current working tree snapshot.
- The only outstanding VIS-13 delta in this session is documentation addendum content.

## Current unrelated dirty workspace (explicit exclude list)
Do not include these in VIS-13 landing:
- docs/EXPLORATION_ROADMAP_WHILE_BUILDING.md
- docs/review/FAMILY_DASHBOARD_UI_IMPLEMENTATION_2026-05-24.md
- docs/testing/TEST_STATUS_SUMMARY.md
- lib/main.dart
- lib/models/waste_classification.dart
- lib/models/waste_classification.g.dart
- lib/screens/family_creation_screen.dart
- lib/services/classification_router_guardrails.dart
- lib/utils/animation_system.dart
- lib/utils/constants.dart
- lib/widgets/analysis_progress_view.dart
- test/ai_flywheel/flywheel_foundation_test.dart
- test/golden/recent_classification_list_golden_test.dart
- test/models/cached_classification_test.dart
- test/models/models_test.dart
- test/models/waste_classification_test.dart
- test/screens/family_dashboard_screen_test.dart
- test/services/classification_pipeline_test.dart
- test/services/layer0_router_test.dart
- test/services/offline_degradation_test.dart
- test/services/providers/ai_provider_router_test.dart
- tool/ai_flywheel_acceptance_report.dart
- tool/ai_flywheel_evidence_summary.dart
- tool/router_compare_report.dart
- tools/verify_ai_flywheel_foundation.sh
- lib/ai_flywheel/provider_quality_gate.dart (untracked)
- lib/ai_flywheel/router_policy_recommendations.dart (untracked)

## Ready-to-land verdict (for VIS-13 only)
Status: PARTIAL_READY
- Functional UI/test scope: ready
- Boundary hygiene: ready
- Remaining item before closure in this session: decide whether to keep or trim the latest review-doc addendum in docs/review/premium_toggle_visuals_followthrough_2026-05-23.md

## Next gate after boundary freeze
Run full-repo release gate before any merge/release claim:
- flutter analyze (repo scope)
- flutter test (repo scope)

Report failures as:
- pre-existing baseline failures
- current failures
- net delta

## Gate execution status (started 2026-05-24)
Commands run:
1) `TMPDIR=$PWD/.tmp flutter analyze --no-fatal-infos`
2) `set -o pipefail; TMPDIR=$PWD/.tmp flutter test --machine | tee .tmp/full_suite_machine_2026-05-24_vis13_boundary.jsonl`

Observed outcomes:
- Analyze exit code: 1
- Analyze surfaced repo-wide existing issues plus hard errors outside VIS-13 scope, including:
  - `temp/debug_gamification.dart` (undefined named parameter/getter)
  - `tool/ai_flywheel_acceptance_report.dart` (undefined/referenced-before-declaration)
  - `tool/router_compare_report.dart` (undefined function)
- Full test run hit 600s timeout before suite completion (exit code 124).
- Partial machine-log parse at timeout point:
  - `testDone_total`: 2403
  - `success`: 2393
  - `failure`: 0
  - `error`: 10
  - Log path: `.tmp/full_suite_machine_2026-05-24_vis13_boundary.jsonl`

Current blocker classification for release gate:
- RELEASE-GATE BLOCKED (repo-level)
- VIS-13 boundary remains isolated and clean; blockers are outside canonical VIS-13 file set.

Immediate next step for reliable classification:
- Run/collect a known-good baseline comparison (or last accepted full-suite artifact) and classify the 10 machine-log errors into pre-existing vs new delta before any release claim.
