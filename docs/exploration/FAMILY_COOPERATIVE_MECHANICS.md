# Family/Team Cooperative Mechanics

**Date**: 2026-05-24
**Status**: Implemented — model, service, dashboard integration, and analytics instrumented
**Parent**: `docs/EXPLORATION_TOPICS.md` item 141
**Unblocks**: The family dashboard is now behavioral, not just presentational

---

## Why this matters

The family dashboard was observable before this work. Household members could see each other's stats but there was no shared behavioral surface — no reason for a non-primary user to return, no household-level accountability, no cooperative moment.

This exploration adds the behavioral layer: shared goals that all members contribute toward, role-based tasks, a no-shame household streak, cooperative challenges that need multiple members to complete, and parent-child missions.

---

## What was built

### Model (`lib/models/cooperative_mechanics.dart`)

| Type | Purpose |
|------|---------|
| `FamilyGoal` | Shared household goal (scan count, disposal count, category focus, points target, education) |
| `GoalContribution` | Per-member contribution tracked inside the goal doc; opt-in display |
| `FamilyTask` | Role-based task (any adult, admin only, child, any member, specific member) |
| `HouseholdStreak` | Collective streak: maintained when ANY member is active on a given day |
| `CooperativeChallenge` | Challenge requiring multiple members to contribute |
| `MemberChallengeProgress` | Per-member progress within a cooperative challenge |
| `ParentChildMission` | Paired mission: adult task + child task, succeeds only when both complete |
| `CooperativeMechanicSnapshot` | Mechanic-level analytics snapshot (stored daily for the kill-criteria dashboard) |

### Service (`lib/services/cooperative_mechanics_service.dart`)

All writes use Firestore transactions where multiple members can race (contribution, streak update, challenge progress). Subcollections live under `families/{familyId}/` so Firestore rules inherit correctly.

| Method | What it does |
|--------|-------------|
| `createGoal` / `watchActiveGoals` | Create and observe shared goals |
| `contributeToGoal` | Transactional: adds contribution, increments total, auto-completes at target |
| `createTask` / `watchPendingTasks` / `completeTask` | Full task lifecycle; auto-contributes to linked goal |
| `getOrInitStreak` / `watchStreak` / `recordMemberActivity` | Transactional streak update: advances streak once per day, resets on gap |
| `createCoopChallenge` / `watchActiveChallenges` / `joinChallenge` / `recordChallengeProgress` | Full challenge lifecycle |
| `createMission` / `watchActiveMissions` / `completeMission` | Parent-child missions |
| `buildSnapshot` | Aggregates live subcollections → writes daily snapshot |

### Firestore schema additions (in `FirestoreCollections`)

```
families/{familyId}/family_goals/{goalId}
families/{familyId}/family_tasks/{taskId}
families/{familyId}/household_streaks/current
families/{familyId}/cooperative_challenges/{challengeId}
families/{familyId}/parent_child_missions/{missionId}
families/{familyId}/cooperative_snapshots/{date}
```

### Dashboard integration (`lib/screens/family_dashboard_screen.dart`)

Four sections injected between Stats Overview and Members:
- 🔥 **Household Streak** (hidden when streak = 0)
- 🎯 **Shared Goals** with per-goal progress bars (hidden when no active goals)
- ✅ **Household Tasks** with role label and overdue highlight (hidden when no pending tasks)
- 🤝 **Team Challenges** with participant count and progress bar (hidden when no active challenges)

All four sections are reactive (StreamBuilder) and silent when empty — they don't pollute the dashboard for solo users or families that haven't started cooperative mechanics yet.

### Analytics (`lib/services/gamification_analytics_service.dart`)

Events tracked through the existing `AnalyticsService` under the new `AnalyticsEventTypes.cooperative` event type:
- `family_goal_created`, `family_goal_contribution`, `family_goal_completed`, `family_goal_expired`
- `family_task_created`, `family_task_completed`
- `household_streak_maintained`, `household_streak_broken`
- `coop_challenge_created`, `coop_challenge_joined`, `coop_challenge_completed`
- `parent_child_mission_created`, `parent_child_mission_completed`

### Analytics dashboard (`lib/screens/gamification_analytics_screen.dart`)

Operator view that reads the daily snapshots. Shows:
- Participation rate trend bar chart
- Kill criteria panel with pass/fail state
- Goal, task, challenge, and streak metrics
- Raw snapshot history

---

## Design decisions

### No-shame leaderboard design
Individual contributions are opt-in (`showInFeed` on `GoalContribution`). The household sees aggregate progress, not a list of who isn't contributing. This avoids the social pressure safety problem (topic 152 in the exploration map).

### Household streak vs individual streak
The household streak is deliberately easier to maintain than the individual streak: any single member's activity keeps it alive. This reduces anxiety pressure on individuals while still rewarding collective consistency.

### Empty sections are invisible
None of the four cooperative sections render anything when there's no data. Solo users who have no family, or families that haven't created any goals/tasks/challenges yet, don't see any of this UI. The cooperative mechanics don't impose friction on users who haven't opted into them.

### Transactional writes for concurrent household updates
Multiple members can scan simultaneously. `contributeToGoal`, `recordMemberActivity`, `joinChallenge`, and `recordChallengeProgress` all use `FirebaseFirestore.runTransaction` to prevent write races.

### Tasks linked to goals
A task can be linked to a goal via `linkedGoalId`. When the task is completed, a contribution is automatically recorded against the goal. This creates a "complete the task → the goal advances" moment without requiring any extra user action.

---

## Kill criteria (30-day window)

These are the metrics to read in `GamificationAnalyticsScreen`. If a criterion fails after 30 days with real family users, remove the corresponding mechanic.

| Criterion | Threshold | Consequence on failure |
|-----------|-----------|------------------------|
| Household participation rate | ≥ 50% of members active/week | Demote dashboard to presentation layer |
| Goal completion rate | ≥ 30% of all goals completed | Simplify goals (scan count only) or remove |
| Cooperative challenge join rate | ≥ 40% of active families create/join a challenge | Remove cooperative challenges |
| Non-primary user 7-day return | ≥ 2 returns per week per family | Cooperative mechanics not driving retention; revert to individual-only |

---

## What was shipped after initial implementation (2026-05-25)

### Analytics screen navigation
- `GamificationAnalyticsScreen` wired into `Routes.gamificationAnalytics` and surfaced in `EnhancedSettingsScreen` developer section ("Cooperative Mechanics Analytics" tile).
- Gated by `DeveloperConfig.canShowDeveloperOptions` — invisible in production builds.

### Refactor: cooperative section extracted to widget
- `lib/widgets/family/cooperative_section.dart` — `CooperativeMechanicsSection` (`StatefulWidget`) owns the 4 reactive streams internally and renders streak, goals, tasks, challenges.
- `lib/utils/time_ago.dart` — `TimeAgo` utility extracted from the dashboard screen.
- `family_dashboard_screen.dart` reduced from ~1850 to ~1630 lines.

### Goal and task creation UX (admin-only)
- `CooperativeMechanicsSection` shows a "+" button in the Goals and Tasks section headers when `isAdmin: true`. Tapping opens a creation bottom sheet.
- Family dashboard `Scaffold` gains a `FloatingActionButton.extended` ("New Activity") when the current user is a family admin. Tapping shows a picker (Shared Goal / Household Task) that opens the same creation sheets.
- `CreateGoalSheet` — title, goal type (scan / disposal / points), target value, optional deadline. Calls `CooperativeMechanicsService.createGoal()`.
- `CreateTaskSheet` — title, role target (anyone / adults / admin / child), optional points reward, due date. Calls `CooperativeMechanicsService.createTask()`.

## Open questions

1. **Push notification integration** — streak-at-risk and goal-almost-complete notifications are high-value but not yet wired.
2. **Anti-farming** — household members could collude to farm goal contributions. Need rate limiting per user per goal per hour (topic 151 in the exploration map).
3. **Kid accounts** — child-safe task type is modeled but app has no concept of child vs adult accounts yet.
4. **Challenge creation UX** — `CreateCoopChallenge` sheet not yet implemented; only goals and tasks have creation UI.

---

## Next exploration steps

- **Social pressure safety** (topic 152): privacy controls for who sees who contributed what
- **Anti-farming threat model** (topic 151): rate limits on contributions per user
- **Notifications** for near-goal, streak-at-risk, challenge-joined
- **Household/team game modes** (topic 159): the game mode layer that uses cooperative mechanics
