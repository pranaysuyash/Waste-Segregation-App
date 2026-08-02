# Scan Orchestrator Architecture

Date: 2026-08-01

Status: implemented in the current checkout, focused verification pending

## Decision

`ScanOrchestrator` is the application boundary for scan classification and
completion. It composes the existing canonical services instead of creating a
new AI implementation:

```text
capture
  -> ScanOrchestrator
       -> AiService: provider routing, backend boundary, parsing and result post-processing
       -> ResultPipeline: local persistence, policy-derived persistence data,
          deduplication, training capture, gamification, analytics, optional sync
  -> ResultScreen or queued-work state
```

The orchestrator owns composition, not domain logic. `AiService` remains the
single classification provider-routing owner. `ResultPipeline` remains the
single completion and persistence owner.

## Why this is the canonical path

Previously, foreground scans reached `AiService` and later `ResultPipeline`,
while offline queue work used `EnhancedAiApiService` and then called
`StorageService.saveClassification()` directly. The latter skipped the same
policy, taxonomy, duplicate, training, gamification, analytics, and optional
cloud-sync behavior. This created multiple mini-pipelines for one product
operation.

The queue now requires a configured `ScanOrchestrator`. If configuration is
missing, queued work stays pending instead of being processed through a
divergent fallback path.

## Active entry points

- `ImageCaptureScreen` uses the orchestrator for file, byte, and region analysis.
- `InstantAnalysisScreen` uses the orchestrator for file and byte analysis.
- `ResultScreen` uses the orchestrator for completion and manual save.
- `OfflineQueueService` uses the orchestrator for queued analysis and completion.
- Debug-only segmentation remains an explicit `AiService.segmentImage` helper,
  because it is not a classification completion flow.

## Background lifecycle rule

`ResultPipeline` has a foreground Riverpod state machine. Queue processing must
not mutate that shared foreground lifecycle while still using the same
persistence pipeline. The orchestrator therefore supports
`manageLifecycle: false` for background work. This changes only lifecycle
notification ownership. It does not bypass persistence or side effects.

The corrected foreground lifecycle order is:

```text
classificationSucceeded / policyApplied / awaitingUserConfirmation
  -> saving
  -> saved
  -> syncing
  -> synced
```

When sync is disabled, the pipeline reaches `saved` and then `synced` as the
terminal local-completion state. Duplicate saves use the same ordered terminal
transitions.

## Scope boundaries and remaining work

This decision consolidates the application classification and completion
boundary without deleting existing local-first infrastructure. The following
items remain explicit hardening work:

1. `ClassificationPipeline` and `OfflineClassificationService` are local-first
   infrastructure used for segmentation, hints, and related flows. Their
   relationship to the application orchestrator needs a separate migration
   decision before either path is removed.
2. Multi-region analysis currently exposes a list from `AiService`, while some
   callers still select a first result. The long-term contract should preserve
   all region results or define an explicit aggregation policy.
3. Degraded/fallback classifications should become a typed outcome that cannot
   be mistaken for a normal successful classification without explicit user
   confirmation.
4. The lifecycle provider is still global foreground state. A per-scan
   lifecycle store would improve concurrent background and foreground
   observability, but is a separate state-model migration.

These are not alternate orchestrators. They are documented follow-up seams for
the same canonical flow.

## Verification contract

The implementation must be checked at three levels:

- static: imports, signatures, formatting, and analyzer checks;
- targeted: orchestrator and result-pipeline behavior, including duplicate and
  background lifecycle handling;
- integration: online, instant, queued, and result-screen flows all reaching
  the same completion pipeline.

This document records the architecture decision and its current evidence. It
does not claim production or device verification until those checks are run.
