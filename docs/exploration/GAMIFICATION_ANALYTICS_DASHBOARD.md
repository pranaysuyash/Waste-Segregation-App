# Gamification Analytics Dashboard

**Date**: 2026-05-24
**Status**: Implemented — kill-criteria dashboard with mechanic-level metrics
**Parent**: `docs/EXPLORATION_TOPICS.md` item 160
**Depends on**: `FAMILY_COOPERATIVE_MECHANICS.md` (snapshot data source)

---

## Purpose

The gamification analytics dashboard is the measurement instrument for cooperative mechanics. Without it, the only way to know if household streaks, shared goals, and cooperative challenges are working is to guess from retention curves. With it, every mechanic has a daily snapshot that shows whether it's earning its place.

This dashboard is internal (operator-facing), not user-facing. It can be gated behind an admin check in the navigation.

---

## Architecture

### Data flow

```
Classification / Scan
  → CooperativeMechanicsService.recordMemberActivity()
  → CooperativeMechanicsService.contributeToGoal()
  → CooperativeMechanicsService.buildSnapshot()         ← called after state changes
  → families/{familyId}/cooperative_snapshots/{date}    ← daily Firestore document
  → GamificationAnalyticsService.getSnapshotHistory()   ← query from dashboard
  → GamificationAnalyticsScreen                         ← renders metrics
```

### Event tracking (via AnalyticsService)

All cooperative events are tracked under `AnalyticsEventTypes.cooperative`. These go to the `analytics_events` Firestore collection and can be queried separately from the snapshot system. The snapshot system is the primary source for the dashboard; raw events are for deeper drill-down.

### Snapshot document (`cooperative_snapshots/{date}`)

One document per day per family. Written by `CooperativeMechanicsService.buildSnapshot()` after significant state changes. Fields:

| Field | Type | Description |
|-------|------|-------------|
| `familyId` | String | The family this snapshot belongs to |
| `snapshotDate` | ISO 8601 | Day of snapshot |
| `activeGoalCount` | int | Active shared goals |
| `completedGoalCount` | int | Completed shared goals |
| `activeTaskCount` | int | Pending/in-progress tasks |
| `completedTaskCount` | int | Completed tasks |
| `householdStreakDays` | int | Current household streak |
| `activeCoopChallenges` | int | Active cooperative challenges |
| `completedCoopChallenges` | int | Completed cooperative challenges |
| `participationRate` | float | Active members / total members (0–1) |
| `nonPrimaryUserReturnCount` | int | Non-primary member returns in past 7 days |
| `challengeJoinCount` | int | Total challenge joins |
| `goalCompletionRate` | float | Completed / (completed + failed + expired) |

---

## Screen (`lib/screens/gamification_analytics_screen.dart`)

### Views provided

| Section | What it shows |
|---------|--------------|
| Summary header | Latest participation rate, goal completion rate, streak, non-primary returns |
| Kill criteria panel | Pass/fail state for each kill criterion with consequence text |
| Participation chart | Bar chart of participation rate over selected time range |
| Goal metrics card | Active, completed, completion rate, task counts |
| Challenge metrics card | Active, completed, join count, non-primary returns |
| Streak distribution | Bar chart of household streak over time |
| Snapshot history | Raw table of last 7 snapshots |

### Time range selector
Supports 7-day, 30-day, 90-day windows. Defaults to 30 days.

---

## Kill criteria

The kill criteria panel is the most important part of this dashboard. These are the thresholds that determine whether each cooperative mechanic earns continued investment.

| Criterion | Threshold | Mechanic at risk |
|-----------|-----------|-----------------|
| Participation rate | ≥ 50% active per week | Family dashboard (demote to presentation layer) |
| Goal completion rate | ≥ 30% | Shared goals (simplify or remove) |
| Non-primary returns | ≥ 2/week | All cooperative mechanics (if no return signal, remove all) |
| Active challenges | ≥ 1 per active family | Cooperative challenges |

### How to apply kill criteria

1. Set a 30-day baseline window from the first family group that actively uses cooperative mechanics.
2. At the 30-day mark, read this dashboard for all qualifying families (those with ≥2 members and ≥7 days of usage).
3. If ≥60% of qualifying families fail a criterion, remove the corresponding mechanic.
4. If ≥40% fail, A/B test a simplified version.
5. If ≥80% pass all criteria, expand to more family groups and move toward GA.

---

## Firestore rules note

The aggregate view uses `collectionGroup(cooperative_snapshots)`. This requires a Firestore index and a rules entry allowing read access to the snapshots subcollection. The per-family view reads `families/{familyId}/cooperative_snapshots` directly — covered by the existing family member read rules.

---

## Future extensions

1. **Cohort comparison** — family-group users vs solo users at day 7/14/28/30 retention
2. **Per-mechanic breakdown** — which of goals/tasks/streak/challenges drives the most return
3. **Admin aggregate view** — cross-all-families aggregation using `getAggregatedMetrics()`; currently implemented in `GamificationAnalyticsService` but the screen shows per-family only
4. **Alert thresholds** — email/Slack alert when a kill criterion fails for a significant fraction of families
5. **Funnel view** — family created → goal set → goal contributed → goal completed

---

## Related exploration topics

- `FAMILY_COOPERATIVE_MECHANICS.md` — the mechanics this dashboard measures
- `GAMIFICATION_DEPTH.md` — the individual gamification v2 system
- `HABIT_FORMATION_LOOP.md` — the broader retention model
- topic 164 in `EXPLORATION_TOPICS.md`: Mechanic-level kill criteria (every mechanic must justify itself)
