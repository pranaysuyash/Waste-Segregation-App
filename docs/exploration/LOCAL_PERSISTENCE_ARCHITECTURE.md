# Local Persistence Architecture

- **Decision it unblocks**: Design a coherent local persistence layer — Hive boxes for offline data, cache service for API responses, offline queue for pending operations — with consistent eviction, sync, and conflict resolution policies.
- **Key questions**:
  - Hive box schema: what data lives in local boxes vs. Firestore cache vs. memory?
  - Cache invalidation strategy: TTL, version-gated, or usage-based eviction?
  - Offline queue semantics: retry order (FIFO? priority?), conflict resolution on sync, queue limits?
  - How does local persistence interact with data migrations and account deletion?
- **Kill criteria**: Always-online app where local storage is limited to auth tokens and theme preferences.
- **Status**: Seed — 2026-05-25
- **Links**: [`hive_box_manager.dart`](../../lib/services/hive_box_manager.dart), [`hive_manager.dart`](../../lib/services/hive_manager.dart), [`cache_service.dart`](../../lib/services/cache_service.dart), [`enhanced_cache_service.dart`](../../lib/services/enhanced_cache_service.dart), [`offline_queue_service.dart`](../../lib/services/offline_queue_service.dart), [`offline_classification_service.dart`](../../lib/services/offline_classification_service.dart)
- **Source discovery**: Gap analysis — six persistence-related services exist with no unifying architecture topic.
