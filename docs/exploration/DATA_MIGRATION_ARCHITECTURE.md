# Data Migration Architecture

- **Decision it unblocks**: How to safely evolve local schemas, Firestore documents, and cached data across app versions without data loss or forced-update breakage.
- **Key questions**:
  - Migration runner pattern: version-gated vs. timestamp-gated vs. launch-once migrations?
  - How to handle partial migrations from interrupted upgrades?
  - How to detect stale migration state on reinstall vs. upgrade?
  - How to test migrations against real production data shapes?
- **Kill criteria**: Single-app-version lifespan where manual clean installs are acceptable.
- **Status**: Seed — 2026-05-25
- **Links**: [`classification_migration_service.dart`](../../lib/services/classification_migration_service.dart), [`thumbnail_migration_service.dart`](../../lib/services/thumbnail_migration_service.dart), [`data_migration_dialog.dart`](../../lib/widgets/data_migration_dialog.dart)
- **Source discovery**: Gap analysis of `lib/` services — migration services exist as real code with no corresponding exploration topic.
