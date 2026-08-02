> **Review baseline:** `pranaysuyash/Waste-Segregation-App`, branch `main`, commit `d7a9c73f75779ddcbf9f22f4ce2fba9a0280b171`
>
> **Remote commit date:** 2026-05-25
>
> **Review date:** 2026-08-02
>
> **Hard limitation:** This review does not include local, uncommitted, or unpushed work. Run `02_TASK_LOCAL_CHANGE_RECONCILIATION.md` before implementing any other task. Existing local work is authoritative where it is newer and intentional.

# Task: Architecture Canonicalisation

## Priority

P1, after local reconciliation and P0 trust fixes.

## Objective

Reduce the production system to one path for each critical responsibility: classification, entitlement, state, persistence, side effects and storage.

## Architectural rule

Every production capability must have:

- one public entry point;
- one owner;
- one canonical state;
- one documented failure contract;
- one test harness.

Adapters may exist during migration, but not as permanent peer implementations.

## Primary hotspots

- `lib/main.dart`
- `lib/services/ai_service.dart`
- `lib/services/enhanced_ai_api_service.dart`
- `lib/services/result_pipeline.dart`
- `lib/providers/**`
- `lib/services/storage_service.dart`
- `lib/services/enhanced_storage_service.dart`
- `lib/services/cloud_storage_service.dart`
- premium and billing services
- Firebase/R2 storage services

## Work breakdown

### T1. Build a runtime call graph

Create `docs/architecture/RUNTIME_CALL_GRAPH.md` for:

- app startup;
- authentication;
- classify;
- apply policy;
- display result;
- save result;
- award points;
- sync;
- submit feedback;
- create training candidate;
- purchase;
- restore;
- web checkout.

For every node identify:

- constructor/entry point;
- state owner;
- side effects;
- retries;
- idempotency key;
- telemetry;
- tests.

### T2. Select the classification facade

Target interface:

```dart
abstract interface class ClassificationGateway {
  Future<ClassificationOutcome> classify(ClassificationRequest request);
}
```

It owns:

- backend call;
- timeout/cancel;
- request ID;
- response parsing;
- policy application;
- usage accounting;
- provenance.

Retire or demote the overlapping orchestration in `AiService` and `EnhancedAiApiService`. Provider clients remain internal.

### T3. Select one state-management rule

Do not rewrite the whole app blindly.

Define:

- Riverpod for new domain state and async workflows;
- Provider only as a temporary compatibility shell, or the reverse if local changes establish a different decision;
- no service self-initialisation in constructors;
- all initialization from an explicit composition root;
- no hidden singleton creation inside services except platform SDK handles.

Create an ADR and a strangler migration sequence.

### T4. Shrink `main.dart`

Move startup into explicit modules:

```text
bootstrap/
  environment_bootstrap.dart
  firebase_bootstrap.dart
  local_storage_bootstrap.dart
  service_registry.dart
  app_startup_report.dart
```

Startup must produce a typed readiness report instead of continuing through arbitrary partial failures.

Classify dependencies:

- blocking;
- degradable;
- lazy;
- developer-only.

### T5. Replace the monolithic result pipeline

Current pipeline mixes:

- local save;
- duplicate detection;
- training capture;
- gamification;
- cloud sync;
- community;
- ads;
- analytics.

Use an idempotent event/outbox model:

```text
classification_completed
  -> local_projection
  -> sync_outbox
  -> reward_projection
  -> analytics_event
  -> training_candidate_if_consented
  -> optional_community_post
```

Each consumer must record its processed event ID.

Ads must be a UI/product policy, not a persistence side effect.

### T6. Canonicalise storage

Define responsibilities:

- local database/cache;
- Firestore operational records;
- object storage for consented images/evidence;
- export/backup;
- training dataset storage.

Choose Firebase Storage or R2 per object class. Do not let both become generic interchangeable stores.

### T7. Add dependency boundaries

Domain layer must not import UI or provider SDKs.

Suggested boundaries:

```text
domain/
application/
infrastructure/
presentation/
```

Do not perform a folder-only rewrite. Move code only when behaviour is protected by tests.

### T8. Remove dead and duplicate dependencies

Audit `pubspec.yaml` and `package.json` for:

- duplicate Markdown/rendering libraries;
- unused API SDKs;
- stale overrides;
- commented feature dependencies;
- packages whose version is pinned without justification.

Add a dependency decision log.

## Migration sequence

1. Add facade and tests around current behaviour.
2. Route one screen through facade.
3. Instrument both old/new path in shadow mode if safe.
4. compare output and side effects;
5. switch production route;
6. remove old path;
7. update docs and dependency graph.

Never add a third path.

## Acceptance criteria

- One production classification facade.
- One entitlement authority.
- One state owner per workflow.
- `main.dart` no longer manually constructs the entire system.
- Result processing is retryable and idempotent.
- Storage classes have non-overlapping responsibilities.
- Duplicate services are removed or marked with a dated removal plan.
- Architecture docs match the code and tests demonstrate each migrated path.

## Verification

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test --coverage
```

Add focused integration tests that restart the app between workflow stages and prove no duplicate save, points, post, token spend or training candidate.
