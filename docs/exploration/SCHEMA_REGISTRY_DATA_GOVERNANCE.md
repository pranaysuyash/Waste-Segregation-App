# Firestore Schema Registry & Data Governance

- **Decision it unblocks**: Whether to formalize schema versioning and data governance for Firestore documents, including field migration, contract enforcement, and deprecation.
- **Key questions**:
  - What does the existing `FirestoreSchemaRegistry` already track?
  - How to enforce document contracts at write time (Firestore rules + client-side validation)?
  - Field deprecation policy: how long to keep old fields after migration?
  - How to detect and alert on schema drift between client, functions, and Firestore?
- **Kill criteria**: Small team where schema changes are manually coordinated and rarely break.
- **Status**: Seed — 2026-05-25
- **Links**: [`firestore_schema_registry.dart`](../../lib/services/firestore_schema_registry.dart), [`analytics_schema_validator.dart`](../../lib/services/analytics_schema_validator.dart), [`firestore.rules`](../../firestore.rules)
- **Source discovery**: Gap analysis — `firestore_schema_registry.dart` and `analytics_schema_validator.dart` exist with no exploration topic covering schema governance broadly.
