# Contribution Submission Flow Refactor (2026-06-17)

## Scope
- Focus: app feature path for community contributions.
- Goal: replace screen-local Firestore/Storage submission logic with a single service contract.
- Alignment: long-term first-principles, avoiding duplicate API write paths for the same resource.

## What changed
- `lib/screens/contribution_submission_screen.dart`
  - Replaced inline photo upload and Firestore write code with `CommunityContributionService`.
  - Added a submission guard requiring an authenticated user before sending contributions.
  - Added an explicit pre-submit check that the contribution has payload (suggested data, notes, or photos).
  - Kept the UX feedback intact and added upload-result messaging for partial photo failures.
  - Removed stale direct TODO path and dead methods.
- `lib/services/community_contribution_service.dart`
  - Added canonical submission API: `submitContribution(...)`.
  - Added schema validation integration before write:
    - required field checks
    - unexpected field checks (warn-only)
  - Centralized photo upload logic for contribution assets.
- `lib/services/firestore_schema_registry.dart`
  - Added `CommunityContributionSchema` for `user_contributions`.
  - Registered the schema in `FirestoreSchemaValidator._getSchemaForCollection`.

## Why this is long-term safe
- One submission contract avoids duplicate write behavior in UI and service layers.
- Validation now runs from a canonical schema registry, making drift easier to detect.
- Feature behavior is now testable by service-level contract before UI concerns.

## Risks / follow-ups
- Current path still uses client-side write to `user_contributions`; the code intentionally leaves a migration note in comments for future server-side hardening.
- Additional UX improvement: add a preview/count chip for selected photos and explicit max-file limits.
