# Issue Review: Home follow-up reminder slice (2026-08-03)

## Scope
- Add recurring disposal reminder visibility on Home from completion history.
- Keep reminder flow in existing persistence surface (`UserProfile.preferences`).
- Add lightweight navigation into completion history.

## What was implemented
- `lib/screens/home_screen.dart`
  - Added `_buildPendingFollowUpCard` and `_collectPendingCompletionFollowUps`.
  - Card shows unresolved follow-up disposal records from `disposalCompletionHistory` with item name/action/status.
  - Added "Open follow-up list" CTA that routes to `DisposalCompletionHistoryScreen`.
  - Added `_openCompletionHistory` helper and `_HomeCompletionFollowUpItem` model.
  - Inserted card in home content flow immediately after last-completion summary.
- `test/screens/home_screen_test.dart`
  - Added regression for pending follow-up card rendering and navigation to completion history.

## Evidence
- Command: `flutter test test/screens/home_screen_test.dart`
- Result: 17 tests passed in the file.

## Follow-up
- This remains a local reminder layer only.
- Next P1 step: reminders and operator confirmation still require schedule/notification/event workflow and status transition rules.
