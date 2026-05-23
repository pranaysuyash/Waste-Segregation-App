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
