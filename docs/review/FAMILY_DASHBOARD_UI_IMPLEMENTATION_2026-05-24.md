# Family Dashboard UI Implementation Note

Date: 2026-05-24

## Decision
The family dashboard should be treated as a first-class household coordination surface, not a second home screen. The implementation was adjusted to be testable, responsive, and maintainable over time.

## What changed
- Added optional dependency injection to `FamilyDashboardScreen` so tests and future callers can supply alternate `StorageService` and `FirebaseFamilyService` implementations.
- Reworked the dashboard layout to use responsive `Wrap`-based action and metrics sections instead of rigid two-column assumptions.
- Added stable keys to major dashboard sections and primary actions so tests can target structure rather than brittle text alone.
- Replaced the brittle mockito-style screen test with fake-service widget tests.
- Added coverage for:
  - empty family state
  - populated family dashboard state
  - narrow layout with larger text scale
  - error state with retry affordance

## Why this is the long-term direction
- Injected services keep the screen decoupled from hard-coded construction and make future state changes easier to test.
- Responsive sections avoid layout regressions on 320px devices and under larger accessibility text settings.
- Stable keys and fake services reduce test fragility and eliminate dependence on stale generated mocks.

## Verification
- `TMPDIR=$PWD/.tmp flutter analyze --no-fatal-infos lib/screens/family_dashboard_screen.dart test/screens/family_dashboard_screen_test.dart`
- `TMPDIR=$PWD/.tmp flutter test test/screens/family_dashboard_screen_test.dart`

Both passed.

## Analytics contract addendum
- `FamilyDashboardScreen` now accepts an optional `AnalyticsService` and emits durable snapshot events for loaded, no-family, and error states.
- Snapshot payloads now include dashboard state plus the core counters that matter long-term: member count, total classifications, total points, current streak, current user role, and error type when relevant.
- Widget tests cover the snapshot contract and a representative click interaction on a visible dashboard control so analytics regressions fail at the screen boundary instead of drifting silently.
- The error-state widget test now triggers the top-level failure path via storage lookup failure, which is the actual branch that produces the error snapshot.
