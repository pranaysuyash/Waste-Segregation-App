# Multi-Tier Storage & Cleanup Strategy

- **Decision it unblocks**: Design a coherent storage architecture across local (Hive/Firestore cache), cloud (Firestore, R2, Cloud Storage), and transient (classification result) tiers with automated cleanup policies.
- **Key questions**:
  - What data lives in each tier, and what's the promotion/demotion policy between tiers?
  - Cleanup strategy: TTL-based, usage-based, version-based, or user-triggered?
  - How to handle orphaned data after schema migrations, feature removal, or account deletion?
  - Is the existing `firebase_cleanup_service` sufficient or should cleanup be event-driven?
- **Kill criteria**: All data fits in one Firestore collection with no cleanup needs.
- **Status**: Seed — 2026-05-25
- **Links**: [`storage_service.dart`](../../lib/services/storage_service.dart), [`cloud_storage_service.dart`](../../lib/services/cloud_storage_service.dart), [`classification_storage_service.dart`](../../lib/services/classification_storage_service.dart), [`firebase_cleanup_service.dart`](../../lib/services/firebase_cleanup_service.dart), [`enhanced_storage_service.dart`](../../lib/services/enhanced_storage_service.dart)
- **Source discovery**: Gap analysis — five storage-related services exist with no unifying architecture topic.
