# Classification Lifecycle State Machine

**Date**: 2026-05-21  
**Scope**: Audit → Canonical State Model → Migration Plan  
**Status**: Design + Implementation Complete  

---

## 1. Audit of Current Lifecycle Logic

### 1.1 Scattered State Across Subsystems

| Subsystem | File | State Mechanism | Problems |
|---|---|---|---|
| Capture Screen | `image_capture_screen.dart` | `_isAnalyzing` (bool), `_isCancelled` (bool), `_analysisStage` (AnalysisProgressStage enum), `_isOnline` (bool) | 4 separate variables for one lifecycle; no invalid-transition protection |
| AI Service | `ai_service.dart` | `_cancelToken` (CancelToken), `isCancelled` getter | Cancellation tracked outside state machine; cache/retry logic interleaved |
| Enhanced AI API | `enhanced_ai_api_service.dart` | `_initialized` (bool), `_modelUsageCount` (Map) | No lifecycle state at all for the classification itself |
| ResultPipeline | `result_pipeline.dart` | `ResultPipelineState` (isProcessing, isSaved), `_processingClassifications` (Set\<String\>) | Dedup set is fragile; not a proper state machine; double-gamification risk |
| Offline Queue | `offline_queue_service.dart` | `_isProcessing` (bool), `retryCount` (int per item) | No integration with analysis lifecycle state |
| Gamification | `gamification_service.dart` | No dedup guard against double-processing | `processClassification` called independently from pipeline |
| UI Progress View | `analysis_progress_view.dart` | `AnalysisProgressStage` enum (8 values) | Missing `cacheChecking`, `cacheHit`, `localClassifying`, `saving`, `saved`, `syncing`, `synced`, `failedPermanent`, `cancelled`, `idle`, `imageSelected`, `awaitingUserConfirmation` |

### 1.2 Root Cause

There is **no single authority** for classification lifecycle state. Each subsystem
tracks its own subset with booleans, ad-hoc enums, or string flags. This creates:

- **Double-save risk**: `ResultPipeline.processClassification()` and `GamificationService.processClassification()` both accept any classification with no guard against re-processing.
- **Double-gamification risk**: A classification can go through `processClassification` via the pipeline and again via `processRetroactiveGamification()`. The dedup `Set<String> _processingClassifications` is in-memory only and resets on app restart.
- **Race between cancel and success**: `_isCancelled` flag and analysis stage are independent — the stage can be `success` while `_isCancelled` is also `true`.
- **Invalid transitions possible**: Any code path can `setState(() => _analysisStage = ...)` to any value regardless of current state.
- **Missing terminal states**: No `failedPermanent` — `failedRetryable` is used for everything including auth failures that should never retry.
- **UI renders from flags, not state**: `ImageCaptureScreen.build()` reads `_isAnalyzing`, `_isSelectingRegions`, and `_analysisStage` separately instead of deriving everything from a single state value.

---

## 2. Canonical State Model

### 2.1 Enum: `ClassificationState`

**File**: `lib/models/classification_state.dart`

```
idle
  → imageSelected
  → qualityChecking
  → qualityRejected
  → cacheChecking
  → cacheHit
  → cloudClassifying
  → localClassifying
  → queuedOffline
  → classificationSucceeded
  → policyApplied
  → awaitingUserConfirmation
  → saving
  → saved
  → syncing
  → synced
  → failedRetryable
  → failedPermanent
  → cancelled
```

### 2.2 Transition Rules

Defined as a static `Map<ClassificationState, Set<ClassificationState>>` in
`kClassificationTransitions`.  Any transition not in the map throws `StateError`.

**From** | **Allowed To**
|---|---
`idle` | `imageSelected`, `cancelled`
`imageSelected` | `qualityChecking`, `cancelled`
`qualityChecking` | `qualityRejected`, `cacheChecking`, `queuedOffline`, `failedRetryable`, `failedPermanent`, `cancelled`
`qualityRejected` | `cacheChecking`, `imageSelected`, `cancelled`
`cacheChecking` | `cacheHit`, `cloudClassifying`, `localClassifying`, `failedRetryable`, `cancelled`
`cacheHit` | `classificationSucceeded`, `failedRetryable`, `cancelled`
`cloudClassifying` | `classificationSucceeded`, `queuedOffline`, `failedRetryable`, `failedPermanent`, `cancelled`
`localClassifying` | `classificationSucceeded`, `failedRetryable`, `failedPermanent`, `cancelled`
`queuedOffline` | `classificationSucceeded`, `failedPermanent`, `cancelled`
`classificationSucceeded` | `policyApplied`, `saving`, `awaitingUserConfirmation`, `failedRetryable`, `cancelled`
`policyApplied` | `saving`, `awaitingUserConfirmation`, `failedRetryable`, `cancelled`
`awaitingUserConfirmation` | `saving`, `cloudClassifying`, `cancelled`
`saving` | `saved`, `failedRetryable`, `cancelled`
`saved` | `syncing`, `synced`, `cancelled`
`syncing` | `synced`, `saved`, `cancelled`
`synced` | `idle`, `cancelled`
`failedRetryable` | `qualityChecking`, `cancelled`
`failedPermanent` | `idle`, `cancelled`
`cancelled` | `idle`

### 2.3 State Machine Class: `ClassificationStateMachine`

Properties:
- `current` → current `ClassificationState`
- `transitionCount` → number of valid transitions performed
- `isTerminal` → true if `synced`, `failedPermanent`, or `cancelled`
- `isRecoverable` → true if `failedRetryable`
- `isActive` → true if not idle and not terminal

Methods:
- `transition(next)` → validated transition, throws `StateError` on invalid
- `tryTransition(next)` → returns `bool` instead of throwing
- `reset()` → back to `idle`

### 2.4 Riverpod Provider: `classificationStateMachineProvider`

Exposes `ClassificationStateMachineNotifier` which wraps the machine as a
`StateNotifier<ClassificationStateMachine>` so the UI can `ref.watch()` it.

---

## 3. Migration: ImageCaptureScreen

### 3.1 What Changes

| Before | After |
|---|---|
| `bool _isAnalyzing` | Deleted — replaced by `stateMachine.isActive` |
| `bool _isCancelled` | Deleted — replaced by `stateMachine.current == cancelled` |
| `AnalysisProgressStage _analysisStage` | Deleted — replaced by `stateMachine.current` |
| `bool _isOnline` | Stay — connectivity is orthogonal to lifecycle |
| `_retryAnalysis()` | Calls `machine.transition(qualityChecking)` |
| `_cancelAnalysis()` | Calls `machine.transition(cancelled)` |
| `_queueAnalysisOffline()` | Calls `machine.transition(queuedOffline)` |

### 3.2 UI Derivation from Single State

`AnalysisProgressView` is updated to accept `ClassificationState` instead of
`AnalysisProgressStage`.  The mapping from state → progress bar, title,
description, haptics, and action buttons is centralized in the widget.

---

## 4. Migration: ResultPipeline

The pipeline already has a `StateNotifier<ResultPipelineState>` with `isProcessing`
and `isSaved`.  Integration with `ClassificationStateMachine`:

- When pipeline **starts**, state becomes `saving`
- When pipeline **finishes**, state becomes `saved`
- When pipeline **syncs**, state becomes `syncing` / `synced`
- If gamification is **duplicate-detected**, the state machine's `classificationSucceeded` already prevents re-entry into `saving`

---

## 5. Double-Save & Double-Gamification Risk Analysis

### 5.1 Identified Paths

| Risk Path | Current Mitigation | Gap |
|---|---|---|
| `ResultPipeline.processClassification()` called twice | `_processingClassifications` Set\<String\> (in-memory) | Cleared on app restart; not durable |
| `GamificationService.processClassification()` called via pipeline + retroactive | `oldEarnedIds` diff | Can re-award if profile checkpoint is stale |
| Feedback with `submitFeedback()` | Deterministic dedup key (userId + classificationId) | Well-implemented; no change needed |
| Offline queue item processed + also processed via normal path | No cross-check | Risk: same image classified twice |

### 5.2 State Machine Mitigation

The state machine prevents re-entry into `saving` from `saved` or `synced`.
Once a classification reaches `saved`, the pipeline's `processClassification`
will fail at the transition guard because `classificationSucceeded → saving`
is only valid from specific pre-states.

---

## 6. Offline / Failure / Success Paths

### 6.1 Happy Path
```
idle → imageSelected → qualityChecking → cacheChecking
  → cloudClassifying → classificationSucceeded → policyApplied
  → saving → saved → syncing → synced → idle
```

### 6.2 Offline Path
```
imageSelected → qualityChecking → cacheChecking
  → cloudClassifying
    (connectivity lost) → queuedOffline
    → classificationSucceeded (when queue processes)
```

### 6.3 Cache Hit Path
```
qualityChecking → cacheChecking → cacheHit
  → classificationSucceeded → policyApplied → ...
```

### 6.4 Low Confidence / Fallback Path
```
classificationSucceeded → awaitingUserConfirmation → saving (user confirmed)
classificationSucceeded → awaitingUserConfirmation → cloudClassifying (user corrected)
```

### 6.5 Failure Paths
```
* → failedRetryable → qualityChecking (retry)
* → failedRetryable → cancelled
* → failedPermanent → idle
* → cancelled → idle
```

---

## 7. Test Plan

### 7.1 Unit Tests for `ClassificationStateMachine`
- Valid transitions succeed
- Invalid transitions throw `StateError`
- `tryTransition` returns `false` for invalid transitions
- `isTerminal` correctly identifies terminal states
- `isRecoverable` correctly identifies retryable states
- `isActive` correctly identifies active states
- `reset` returns to idle
- `transitionCount` increments correctly
- **All 19 states covered**

### 7.2 Unit Tests for Transition Map Completeness
- Every state in the enum has an entry in `kClassificationTransitions`
- Every entry's value set contains only valid members of the enum

### 7.3 Integration Test
- Pipeline flow with state machine: end-to-end state transitions match expected sequence

---

## 8. Files Changed

| File | Change |
|---|---|
| `lib/models/classification_state.dart` | **New** — canonical enum + machine + transition rules |
| `lib/providers/classification_state_provider.dart` | **New** — Riverpod provider |
| `lib/screens/image_capture_screen.dart` | Migrate from booleans to state machine |
| `lib/widgets/analysis_progress_view.dart` | Accept `ClassificationState` instead of `AnalysisProgressStage` |
| `lib/services/result_pipeline.dart` | Integrate state machine into pipeline lifecycle |
| `docs/review/CLASSIFICATION_LIFECYCLE_STATE_MACHINE_2026-05-21.md` | **This file** |

### 8.1 Files Not Changed (but audited)
- `ai_service.dart` — cancellation via CancelToken is orthogonal; the screen maps cancel to state machine transition
- `enhanced_ai_api_service.dart` — service layer doesn't need lifecycle state
- `offline_queue_service.dart` — its own retry state is unrelated to classification lifecycle
- `gamification_service.dart` — pipeline integration covers dedup
- `classification_cache_key.dart` — no state needed
- `image_quality_gate.dart` — static checker, no state needed
- `local_policy_engine.dart` — stateless evaluator, no state needed

---

## 9. Remaining Risks & Hardening Path

| Risk | Severity | Hardening Path |
|---|---|---|
| `AnalysisProgressStage` enum still exists in old code | Low | Deprecate → remove after full migration of all consumers |
| State machine is in-memory only | Medium | Optional: persist state to Hive for crash recovery |
| `ResultPipeline.processClassification()` Set dedup still separate | Low | After state machine is the single authority, remove the Set and rely on state guards |
| Offline queue double-classify | Medium | Offline queue should check state machine before processing |
