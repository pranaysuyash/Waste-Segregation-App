# Community Screen Fixes - 2026-05-24

## Scope

Implements the concrete fixes called out in `docs/reports/audits/SCREEN_AUDIT_COMMUNITY_2026-05-24.md` for the community surface.

## Implemented

- `lib/screens/community_screen.dart`
  - separated the initial read-only community load from the explicit sync button path
  - switched the reconciliation card to compare classification counts against canonical stats semantics
  - replaced the raw sync exception snackbar with a user-safe message
  - kept the raw exception in logs for debugging

## Remaining Product Decisions

1. Whether the reconciliation card should eventually surface a separate "pending local sync" indicator when the user has new Hive classifications that have not been pushed yet.
2. Whether the reconciliation panel should remain classification-only, or expand in a later stats model to include other activity types such as achievements and streaks.

## Verification Targets

- Community screen loads feed and stats without mutating Firestore.
- Explicit sync still backfills local history and refreshes the read model afterward.
- Reconciliation warnings only appear when classification semantics differ, not because feed activity types are mixed.

