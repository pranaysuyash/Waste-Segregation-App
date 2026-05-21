# Themed Reward Animation Update (2026-05-21)

## Scope
- Updated `/lib/widgets/result_screen/points_popup.dart`
- Updated `/lib/screens/result_screen.dart`

## What changed
- Reworked reward popup into a themed `waste action -> collection -> eco reward` sequence.
- Added a compact waste-action visual in the popup:
  - generated bin pulse asset confirms the disposal action
  - generated waste drop asset animates into the collection sequence
  - generated eco particle burst asset reinforces the impact moment
  - generated eco reward asset anchors the center of the popup
  - eco points continue to animate in as collectable chips
- Added gamification/unlock assets:
  - `assets/images/generated/gamification_unlock_badge_frame.png`
  - `assets/images/generated/gamification_levelup_burst.png`
  - `assets/images/generated/gamification_streak_flame.png`
- Wired the asset family into:
  - `lib/widgets/advanced_ui/achievement_celebration.dart`
  - `lib/widgets/enhanced_gamification_widgets.dart`
  - `lib/widgets/gamification_widgets.dart`
- Added generated project asset:
  - `assets/images/generated/waste_reward_collection_asset.png`
  - `assets/images/generated/waste_reward_bin_pulse_asset.png`
  - `assets/images/generated/waste_reward_particle_burst_asset.png`
  - `assets/images/generated/waste_reward_drop_asset.png`
- Preserved existing popup API compatibility while extending it:
  - `showPointsPopup(points)` still works
  - optional themed metadata now supported: `actionLabel`, `impactLabel`
- Wired `ResultScreen` to pass contextual labels so reward feedback is relevant to user action:
  - action text based on classification category
  - impact text derived from `co2Impact` when available

## Why
- Keep animation playful and interactive while matching app purpose and visual language.
- Ensure reward motion communicates environmental action, not abstract gamification only.

## Compatibility and risk
- Additive change only; no backend, route, or persistence changes.
- Existing call sites without labels remain valid.
