# Premium Toggle Visuals Followthrough (2026-05-23)

## Scope
Follow-up hardening for VIS-13 style premium-lock consistency across settings-adjacent feature entry points.

## What was changed

### 1) Premium feature entry cards now use standardized locked/unlocked semantics and indicators
- File: `lib/widgets/premium_feature_card.dart`
- Changes:
  - Replaced hardcoded English semantics value (`Enabled` / `Locked, premium feature`) with shared helper:
    - `PremiumFeatureVisuals.semanticsState(context, isUnlocked: ...)`
  - Added semantic hint:
    - unlocked: feature description
    - locked: `upgradeToUse(featureTitle)`
  - Replaced ad-hoc lock/check trailing icons with shared visual indicator:
    - `PremiumFeatureVisuals.buildStatusIndicator(..., showChevron: false)`

### 2) Locked premium cards are now tappable and show concrete upgrade explanation
- File: `lib/screens/premium_features_screen.dart`
- Changes:
  - Locked cards under "Available Premium Features" now receive `onTap`.
  - Added `_showLockedFeaturePrompt(...)` that calls `DialogHelper.showPremiumPrompt(...)`.
  - Dialog body is concrete and feature-specific via:
    - `PremiumFeatureVisuals.upgradeMessage(context, featureName, benefit: feature.description)`
  - Upgrade CTA routes to `Routes.premiumFeatures`.

### 3) Premium lock wrapper now supports “visual lock without tap blocking”
- File: `lib/widgets/premium_lock_wrapper.dart`
- Changes:
  - Added `absorbInteractions` parameter (default `true` to preserve existing behavior).
  - `PremiumFeatureCard` passes `absorbInteractions: false` so cards remain visually locked but still tappable for upgrade explanation.

### 4) Regression coverage added for locked-card tap behavior
- File: `test/screens/premium_features_screen_test.dart`
- Changes:
  - Added localization delegates to test app wrapper.
  - Added test:
    - `locked premium feature card opens upgrade explanation`
  - Test asserts locked premium card tap opens dialog with:
    - CTA: `See Premium Features`
    - feature-specific copy containing `Offline Classification is a premium feature`

### 5) Shared component test harness now provides localization for PremiumFeatureCard directly
- File: `test/helpers/component_test_harness.dart`
- Changes:
  - Added `AppLocalizations` delegates/supported locales to the common pump helper.
  - This keeps PremiumFeatureCard and related accessibility/overflow tests from silently failing when they instantiate the widget outside the main screen.

## Verification run

Commands executed:
1. `flutter analyze --no-fatal-infos lib/widgets/premium_lock_wrapper.dart lib/widgets/premium_feature_card.dart lib/screens/premium_features_screen.dart test/screens/premium_features_screen_test.dart`
2. `TMPDIR=$PWD/.tmp flutter test test/screens/premium_features_screen_test.dart`
3. `TMPDIR=$PWD/.tmp flutter test test/widgets/premium_segmentation_toggle_test.dart test/widgets/settings/settings_navigation_contract_test.dart`

Results:
- All targeted tests passed.
- Analyze passed with non-fatal info only (const-constructor suggestion in test file).

## Notes / environment constraint
- System temp storage was near-full during validation. Tests were run with `TMPDIR=$PWD/.tmp` to avoid temp-space failures in global `/var/.../T` during Flutter compilation.

## Addendum (continued verification + harness hardening)

### Additional code/test updates

1) Settings golden harness now provides premium dependency explicitly
- File: `test/golden/settings_golden_test.dart`
- Change:
  - Added `PremiumService` provider in the settings-sections harness.
  - Added `_FakePremiumService` override to avoid Hive init side effects in golden tests.
  - Re-generated settings goldens after intentional VIS-13 visual updates.

2) PremiumFeatureCard test suite aligned with standardized premium visuals
- File: `test/widgets/premium_feature_card_test.dart`
- Changes:
  - Updated assertions that assumed a single `workspace_premium` icon (overlay + status indicator can produce multiple in locked state).
  - Relaxed brittle `Row` count assertion (`findsOneWidget` -> `findsAtLeastNWidgets(1)`).
  - Added localization delegates/supported locales to test-only `MaterialApp` wrappers that instantiated `PremiumFeatureCard` directly.
  - Updated disposal replacement app wrapper to include localization context.

### Additional verification commands and outcomes

Commands executed:
1. `TMPDIR=$PWD/.tmp flutter analyze --no-fatal-infos lib/widgets/settings/premium_feature_visuals.dart lib/widgets/settings/app_settings_section.dart lib/widgets/premium_feature_card.dart test/golden/settings_golden_test.dart test/widgets/premium_feature_card_test.dart`
2. `TMPDIR=$PWD/.tmp flutter test --update-goldens test/golden/settings_golden_test.dart`
3. `TMPDIR=$PWD/.tmp flutter test test/golden/settings_golden_test.dart`
4. `TMPDIR=$PWD/.tmp flutter test test/widgets/premium_feature_card_test.dart`
5. `TMPDIR=$PWD/.tmp flutter test test/golden/settings_golden_test.dart test/widgets/premium_feature_card_test.dart test/widgets/settings/settings_sections_test.dart test/screens/settings_screen_test.dart test/screens/enhanced_settings_screen_test.dart`
6. `TMPDIR=$PWD/.tmp flutter test` (full suite)
7. `TMPDIR=$PWD/.tmp flutter test test/widgets/quick_action_cards_test.dart` (isolation check)

Results:
- Targeted VIS-13/premium/settings suites pass.
- Full suite currently ends with `~12 -3` failures.
- Isolated run of `quick_action_cards_test.dart` passes, indicating the remaining `-3` in full-suite context are not directly caused by VIS-13 premium-toggle changes and are likely cross-test-order/shared-state interactions.

## Addendum (root-cause closure + full-suite green)

### Root-cause investigation summary

Observed full-suite failure classes:
1) Multiple `loading ...` compile failures caused by Dart language-version mismatch from `video_player_platform_interface 6.7.0` requiring language 3.9 while current toolchain supports 3.8.
2) Two deterministic `gamification_service_test` assertion failures in `getNearMilestoneNudge` daily-goal scenarios.

### Fixes applied

1) Dependency pin to restore toolchain compatibility
- File: `pubspec.yaml`
- Change:
  - `dependency_overrides.video_player_platform_interface` pinned from caret range to exact `6.6.0`.
- Rationale:
  - Prevent resolver drift to 6.7.0 (Dart 3.9 language version) on current Flutter/Dart runtime.

2) Daily-goal nudge tests aligned to canonical app constant
- File: `test/services/gamification_service_test.dart`
- Changes:
  - Added `AppValues` constants import.
  - Replaced hardcoded daily-goal assumptions (`itemsIdentified: 4`, `target: 5`) with `AppValues.dailyGoalTarget` derived values.
  - Updated both relevant scenarios:
    - `returns daily goal nudge when 1 scan away from daily target`
    - `prioritizes daily goal over challenge`
- Root cause:
  - Tests were stale after `AppValues.dailyGoalTarget` moved to `3` in canonical constants.

### Verification commands and outcomes

Commands executed:
1. `TMPDIR=$PWD/.tmp flutter pub get`
2. `TMPDIR=$PWD/.tmp flutter test test/widgetbook/widgetbook_smoke_test.dart`
3. `set -o pipefail; TMPDIR=$PWD/.tmp flutter test --machine | tee .tmp/full_suite_machine_2026-05-23_3.jsonl`
4. `TMPDIR=$PWD/.tmp flutter test test/services/gamification_service_test.dart -r expanded`
5. `set -o pipefail; TMPDIR=$PWD/.tmp flutter test --machine | tee .tmp/full_suite_machine_2026-05-23_4.jsonl`
6. `TMPDIR=$PWD/.tmp flutter analyze test/services/gamification_service_test.dart test/widgets/premium_feature_card_test.dart test/golden/settings_golden_test.dart pubspec.yaml`

Results:
- `widgetbook_smoke_test.dart`: pass.
- `gamification_service_test.dart`: pass after constant-alignment update.
- Full suite: green (`type: done`, `success: true`) on run `full_suite_machine_2026-05-23_4.jsonl`.
- Analyze output: info-level lints only, no new errors/warnings blocking execution.

### Residual risk
- Dependency pin is explicit and stable for this toolchain. When Flutter/Dart is upgraded, reevaluate this pin and remove/raise it only with matching SDK verification.

## Addendum (motto_v2 continuation pass: UI consistency + accessibility hardening)

### Additional implementation changes

1) Premium lock overlay now uses localization-backed accessibility labels
- File: `lib/widgets/premium_lock_wrapper.dart`
- Changes:
  - Added `AppLocalizations` usage in locked overlay.
  - Replaced hardcoded semantic label/text fallback (`Premium feature`) with localized `premiumFeatureBadge` when available.
- Why:
  - Keeps premium-locked indicator wording consistent with the rest of VIS-13 UI semantics.
  - Removes hardcoded English fallback from accessibility path.

2) Navigation contract tests now verify contextual premium copy, not only generic prompt title
- File: `test/widgets/settings/settings_navigation_contract_test.dart`
- Changes:
  - Extended `AppSettingsSection locked premium feature opens upgrade flow` to assert benefit-specific copy and feature-specific upgrade explanation body.
  - Added `FeaturesSection locked advanced analytics opens contextual upgrade dialog` test.
- Why:
  - Enforces DoD requirement that locked taps show useful, feature-specific upgrade explanation.

### Additional verification commands and outcomes

Commands executed:
1. `TMPDIR=$PWD/.tmp flutter analyze --no-fatal-infos lib/widgets/premium_lock_wrapper.dart test/widgets/settings/settings_navigation_contract_test.dart`
2. `TMPDIR=$PWD/.tmp flutter test test/widgets/settings/settings_navigation_contract_test.dart`
3. `TMPDIR=$PWD/.tmp flutter test test/screens/premium_features_screen_test.dart test/widgets/premium_feature_card_test.dart`
4. `TMPDIR=$PWD/.tmp flutter test test/widgets/premium_segmentation_toggle_test.dart`

Results:
- Analyze: pass (no issues).
- `settings_navigation_contract_test.dart`: pass after expectation hardening (`textContaining` can appear in tile subtitle + dialog body).
- `premium_features_screen_test.dart` + `premium_feature_card_test.dart`: pass.
- `premium_segmentation_toggle_test.dart`: pass (locked/unlocked visuals + accessibility assertions green).

### Current patch-boundary status (for review/staging discipline)
- This continuation touched only:
  - `lib/widgets/premium_lock_wrapper.dart`
  - `test/widgets/settings/settings_navigation_contract_test.dart`
  - this review doc
- Working tree contains many unrelated concurrent edits from other tracks. Keep VIS-13 review/staging scoped to the files above plus the previously accepted VIS-13 files.

## Addendum (motto_v2 continuation pass: theme-settings feature-entry standardization)

### Additional implementation changes

1) Theme customization entry in Theme Settings now follows shared premium-lock visuals/semantics
- File: `lib/screens/theme_settings_screen.dart`
- Changes:
  - Added shared premium status indicator usage via `PremiumFeatureVisuals.buildStatusIndicator(..., showChevron: false)`.
  - Added accessibility semantics for locked/unlocked state:
    - `label`: `themeCustomization`
    - `value`: `PremiumFeatureVisuals.semanticsState(...)`
    - `hint`: feature benefit when unlocked, upgrade hint when locked.
  - Replaced hardcoded "Custom Themes" row with localization-backed `themeCustomization` and `themeSettingsSubtitle`.
  - Always renders the theme customization entry so premium users see active state (`ENABLED`) instead of hidden state.

2) Theme customization locked tap now uses contextual upgrade prompt
- File: `lib/screens/theme_settings_screen.dart`
- Changes:
  - Replaced local generic alert dialog with `DialogHelper.showPremiumPrompt(...)`.
  - Uses `PremiumFeatureVisuals.upgradeMessage(...)` so dialog body includes concrete feature benefit + feature-specific premium explanation.
  - Upgrade CTA now routes to canonical `Routes.premiumFeatures` for consistency with other settings entry points.

3) Added regression test coverage for Theme Settings premium-gating behavior
- File: `test/screens/theme_settings_screen_premium_gate_test.dart`
- Coverage:
  - free-tier: locked "Theme Customization" shows `PRO` state and contextual upgrade dialog copy.
  - premium-tier: same entry shows active `ENABLED` state and does not open upgrade dialog.

### Additional verification commands and outcomes

Commands executed:
1. `TMPDIR=$PWD/.tmp flutter test test/screens/theme_settings_screen_premium_gate_test.dart` (red)
2. `TMPDIR=$PWD/.tmp flutter test test/screens/theme_settings_screen_premium_gate_test.dart` (green after implementation)
3. `TMPDIR=$PWD/.tmp flutter analyze --no-fatal-infos lib/screens/theme_settings_screen.dart lib/widgets/settings/app_settings_section.dart lib/widgets/settings/features_section.dart lib/widgets/premium_segmentation_toggle.dart test/screens/theme_settings_screen_premium_gate_test.dart test/widgets/settings/settings_navigation_contract_test.dart test/widgets/premium_segmentation_toggle_test.dart`
4. `TMPDIR=$PWD/.tmp flutter test test/widgets/settings/settings_navigation_contract_test.dart test/widgets/premium_segmentation_toggle_test.dart test/screens/theme_settings_screen_premium_gate_test.dart test/screens/premium_features_screen_test.dart test/widgets/premium_feature_card_test.dart`
5. `TMPDIR=$PWD/.tmp flutter analyze --no-fatal-infos lib/screens/theme_settings_screen.dart test/screens/theme_settings_screen_premium_gate_test.dart`
6. `TMPDIR=$PWD/.tmp flutter test test/screens/theme_settings_screen_premium_gate_test.dart`

Results:
- New theme-settings premium-gating tests: pass.
- Targeted settings/premium regression suite: pass.
- Analyze for final touched theme-settings scope: pass with no issues.
