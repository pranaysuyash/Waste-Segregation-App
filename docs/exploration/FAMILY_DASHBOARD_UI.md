# Family Dashboard UI

Date: 2026-05-24
Status: Implemented, tested, and tracked in the active map

## Why this matters
The family dashboard is the household coordination surface for ReLoop. It turns individual recycling actions into shared progress, shared accountability, and shared habits.

## What it can unlock
- Cooperative family goals instead of purely individual streaks
- Household-level progress visibility
- Better onboarding for non-primary users in a family/friends group
- More durable retention through social accountability
- A clearer path for group challenges and shared achievements

## Questions to answer
- What should the default family dashboard show first: progress, members, challenges, or recent activity?
- Which actions are read-only vs editable by non-admin members?
- How do we prevent the dashboard from becoming noise for solo users?
- What metrics prove the dashboard improves retention or participation?

## Current placement in the roadmap
- Exploration map: `docs/EXPLORATION_TOPICS.md` under Community & Social
- Parallel build map: `docs/EXPLORATION_ROADMAP_WHILE_BUILDING.md` under gamification / habit-loop work

## Related implementation surfaces
- `lib/screens/family_dashboard_screen.dart`
- `lib/services/firebase_family_service.dart`
- `test/screens/family_dashboard_screen_test.dart` (fake-service coverage, no generated mocks)

## Relation to gamification redesign
Family/household features are explicitly deferred to gamification v2 per the [Gamification Redesign Spec](../planning/gamification-redesign-spec.md#31-target--scope) (interview decisions — family features phased separately, §3.6). The v1 gamification system is purely individual. This dashboard becomes the coordination surface when household challenges, shared streaks, and cooperative goals are added in v2, which aligns with the redesign spec's planned points sink for custom group challenges.

## Implementation direction
- Prefer injected services over hard-coded service construction so the screen stays testable and easy to evolve.
- Use responsive Wrap-based sections instead of fixed two-column rows so the dashboard holds up on 320px screens and larger text scales.
- Keep family actions, stats, invitations, recent activity, and household impact as separate sections with stable keys for tests and future refactors.
- Add tests that cover empty, populated, narrow-layout, and failure states.

## Open risk
This surface should not become a second generic home screen. It only earns its place if it drives household engagement or cooperative behaviour better than the individual flow.

Per the gamification redesign spec, family features are a separate v2 effort. This dashboard should be maintained as a thin presentation layer until v2 gamification is ready to provide the shared goals and cooperative mechanics it needs to earn its place.

## Next step
Move from observation to behaviour design, then keep the measurement loop tight.
- Family/team cooperative mechanics (see `docs/EXPLORATION_TOPICS.md` item 141): shared goals, role-based tasks, no-shame leaderboards, household streaks, parent-child missions, and conflict prevention
- Gamification analytics dashboard (see `docs/EXPLORATION_TOPICS.md` item 160): mechanic-level retention, challenge completion, correction quality, learning mastery, and long-term behaviour change
- Keep tracking household participation rate, non-primary-user return frequency, challenge join/complete rate, and 7-day / 28-day retention for family-group users versus solo users
- If those metrics do not move, demote this from a product bet to a presentation layer only
