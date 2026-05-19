# ADR-003: Data Sync Strategy — Deferred Centralized Architecture

* Status: proposed
* Deciders: Development Team
* Date: 2025-06-20 (updated from stash analysis)

Technical Story: Stash 3 contained a `DataSyncProvider` approach — a centralized `ChangeNotifierProvider` coordinating `GamificationService`, `StorageService`, `AnalyticsService`, and `CommunityService`. This ADR captures that architectural idea and proposes a lighter, phased path.

## Context and Problem Statement

The app has multiple services (GamificationService, StorageService, AnalyticsService, CommunityService) that need to stay consistent with each other. Currently, each screen independently calls services, leading to:

- Stale data across screens (e.g., points earned on ResultScreen not reflected on HomeScreen until manual refresh)
- Inconsistent sync status indicators
- No unified error handling for data operations
- Duplicate refresh logic scattered across screens

Stash 3 attempted a `DataSyncProvider` — a centralized coordinator class — but it was architecturally incompatible with the current `_AppBootstrapper` pattern and never merged.

## Decision Drivers

- **Avoid premature centralization**: Don't add a coordinator until the data flow patterns are stable
- **Current architecture compatibility**: Must work with `_AppBootstrapper` and existing Provider/Riverpod mix
- **Incremental value**: Each step should improve consistency independently
- **No single point of failure**: Services should function independently if the coordinator is down
- **Testability**: The solution should not make services harder to test in isolation

## Considered Options

* **Option 1**: Build DataSyncProvider as-is from stash 3
* **Option 2**: Defer — add per-service refresh methods now, coordinator later
* **Option 3**: Event bus pattern — services emit events, screens react
* **Option 4**: Riverpod ref.invalidate pattern (if fully migrated to Riverpod)

## Decision Outcome

Chosen option: **Option 2 — Defer centralized coordinator, add per-service refresh methods now.**

The stash 3 DataSyncProvider was a well-intentioned attempt but it tightly coupled multiple services into one class, created circular dependencies, and doesn't fit the current Provider-based architecture. A lighter approach is better.

### Positive Consequences

- Each service remains independently testable
- Screens can refresh specific services without coupling to a coordinator
- Easy to add a coordinator later when patterns stabilize
- Zero risk of regressions from architectural changes

### Negative Consequences

- Screens still need to coordinate multiple refreshes manually
- No unified sync status indicator yet
- More work to add a coordinator later if needed

## Implementation Guidelines (When Ready)

### Phase 1 — Per-Service Refresh (Current)

Each service should expose a simple `refresh()` or `reload()` method:

```dart
// In each service
Future<void> refresh() async {
  // Reload data from source
}
```

Screens call the specific service(s) they depend on.

#### Stash 3 Reference: Concrete Method Names

The stash 3 DataSyncProvider extended `GamificationService` with these sync methods (preserved here as reference, not merged):

```dart
// From stash@{3} GamificationService — not in main
Future<void> forceCompleteDataSync() async {
  // Full sync: classifications → achievements → streaks → profile refresh
}

Future<int> getLivePoints() async {
  // Force sync before returning points for real-time accuracy
}

Future<int> getTotalClassificationsCount() async {
  // Count from storage service directly
}

Future<Map<String, dynamic>> getClassificationStats() async {
  // Aggregate stats: counts by category, subcategory, timestamps
}

Future<bool> validateDataConsistency() async {
  // Compare profile points vs calculated points from classifications
}
```

These are not recommended for direct porting but illustrate the kind of operations a full sync layer would need.

### Phase 2 — Lightweight Coordinator (Future)

If needed, a lightweight coordinator can be built as:

```dart
class DataCoordinator {
  final GamificationService gamification;
  final StorageService storage;
  final AnalyticsService analytics;
  
  Future<void> refreshAll() async {
    await Future.wait([
      gamification.refresh(),
      storage.refresh(),
      analytics.refresh(),
    ]);
  }
}
```

This should be a plain class, not a Provider — injected into screens that need it.

### Phase 3 — Full DataSyncProvider (If justified)

Only if evidence shows that Phase 2 is insufficient (e.g., stale data bugs continue), implement the full centralized approach from stash 3. At that point, rewrite it for the current architecture.

## Links

* Refined by [ADR-001: Clean Architecture](ADR-001-clean-architecture.md)
* Informed by stash 3 (`stash@{3}`) DataSyncProvider implementation (archived, not merged)
* TRACK_1_2_CAPTURE_FLOW_INTEGRATION.md
