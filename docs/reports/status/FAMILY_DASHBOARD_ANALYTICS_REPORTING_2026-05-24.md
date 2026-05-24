# Family Dashboard Analytics Reporting

**Date:** 2026-05-24  
**Status:** Implemented in source; Flutter and backend verification passed; remaining Flutter analyze output is pre-existing deprecation noise

## Scope
Persist family dashboard snapshot analytics into a durable reporting layer with retention and aggregation rules.

## What changed

### Flutter app
- Added durable analytics contract fields to family dashboard snapshot events:
  - `timestampUtc`
  - `timestampMillis`
- Extended family dashboard widget tests to assert the analytics snapshot payload includes:
  - `analytics_contract_version`
  - `family_id`
- Added reporting-collection awareness to the Firestore schema registry:
  - `family_dashboard_reports`
- Added an app-side analytics query entry point for durable family dashboard reports:
  - `AnalyticsService.getFamilyDashboardAnalyticsSummary(...)`

### Cloud Functions
- Added a new scheduled reporting function:
  - `aggregateFamilyDashboardAnalytics`
- Added a new source file:
  - `functions/src/family_dashboard_analytics.ts`
- The scheduled job:
  - reads `family_dashboard_snapshot` events from `analytics_events`
  - aggregates global and per-family scopes
  - writes daily and rolling report docs into `family_dashboard_reports`
  - retains the latest 90 days of daily docs
  - deletes stale daily docs beyond retention

## Report shape
The durable report documents include:
- scope metadata:
  - `scopeType`
  - `familyId`
  - `reportType`
  - `windowDays`
  - `reportDate`
  - `windowStartDate`
  - `windowEndDate`
- freshness metadata:
  - `generatedAtIso`
  - `generatedAtMillis`
  - `reportVersion`
- core metrics:
  - `snapshotCount`
  - `loadedSnapshotCount`
  - `noFamilySnapshotCount`
  - `errorSnapshotCount`
  - `familyParticipationRate`
  - `uniqueUsers`
  - `returningUsers`
  - `returnRate`
  - `uniqueFamilies`
- family dashboard aggregates:
  - `averageFamilyMemberCount`
  - `averageFamilyTotalClassifications`
  - `averageFamilyTotalPoints`
  - `averageFamilyCurrentStreak`
- categorical breakdowns:
  - `stateCounts`
  - `roleCounts`

## Retention / aggregation rules
- Daily report docs are generated per scope.
- Rolling report docs are generated for 7-day and 28-day windows.
- Daily docs older than 90 days are deleted.
- Event timestamps now carry UTC-friendly fields so future reporting does not depend on parsing ambiguous local strings.

## Verification
Passed:
- `flutter test test/screens/family_dashboard_screen_test.dart`
- `node --test test/family_dashboard_analytics.test.js`
- `npm run build` in `functions/`

Notes:
- `flutter analyze lib/services/analytics_service.dart lib/services/firestore_schema_registry.dart lib/models/gamification.dart test/screens/family_dashboard_screen_test.dart` reports three pre-existing `deprecated_member_use` infos in `lib/models/gamification.dart`. No new errors were introduced by this work.

## Files touched
- `lib/models/gamification.dart`
- `lib/services/analytics_service.dart`
- `lib/services/firestore_schema_registry.dart`
- `test/screens/family_dashboard_screen_test.dart`
- `functions/src/family_dashboard_analytics.ts`
- `functions/test/family_dashboard_analytics.test.js`

## Notes
The Flutter side and Cloud Functions reporting logic are verified in this repo. The only analyzer output is the pre-existing `deprecated_member_use` infos in `lib/models/gamification.dart`.
