# Points Collection Animation Update (2026-05-21)

## Scope
- Updated `lib/widgets/result_screen/points_popup.dart` only.
- No route/backend/data-contract changes.

## What changed
- Replaced the static points-popup feel with a playful coin-collection interaction.
- Added floating coin pills that animate into the reward card.
- Added tap-to-collect behavior so users can actively dismiss/collect reward feedback.
- Preserved existing popup API (`context.showPointsPopup(points)`) so all current call sites continue to work.

## Why
- Improve reward delight and interaction quality without cloning external animation exactly.
- Keep implementation additive and reusable across all screens that already trigger points popups.

## Risk notes
- Visual-only change to popup behavior.
- Existing callers remain unchanged.
