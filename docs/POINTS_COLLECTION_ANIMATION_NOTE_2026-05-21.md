# Themed Reward Animation Update (2026-05-21)

## Scope
- Updated `/lib/widgets/result_screen/points_popup.dart`
- Updated `/lib/screens/result_screen.dart`

## What changed
- Reworked reward popup into a themed `waste action -> collection -> eco reward` sequence.
- Added a compact waste-action visual in the popup:
  - generated eco reward asset drops into a collection bin lane
  - eco impact particles appear on successful collection
  - eco points continue to animate in as collectable chips
- Added generated project asset:
  - `assets/images/generated/waste_reward_collection_asset.png`
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
