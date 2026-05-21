# Capture → Analysis → Result Delight Pass

## Date
2026-05-21

## Scope
Create a coherent, stateful animation and messaging flow from capture to result, including:
- image capture quality gate and offline queue states
- analysis loading states in instant and result flows
- local rule application feedback
- fallback/error messaging with retry
- reduced-motion accessibility
- shared reusable component for analysis progress
- widget test coverage for primary states

## Implementation Summary

### 1) Shared component introduced
- Added/used one reusable stage component: `AnalysisProgressView` in `lib/widgets/analysis_progress_view.dart`.
- Supported stages now cover:  
  `checkingQuality`, `queuedOffline`, `uploading`, `analyzingImage`, `applyingLocalRules`, `success`, `fallback`, `failedRetryable`.
- Added haptic pulses tied to meaningful stage transitions with reduced-motion/accessible-navigation guard.
- Added queue stack visualization for offline waiting and local-rule chip reveal.
- Added stage-aware confidence/error messaging and continue/retry/cancel action slots.

### 2) Capture screen progress integration
- `lib/screens/image_capture_screen.dart` now transitions through:
  - quality check failure path (with retry/no-retry decision already existing),
  - offline queue path (`queuedOffline`) and explicit failure state.
- Offline queue failure now updates `_analysisStage` and `_analysisErrorMessage` immediately in `setState` for clear user feedback.

### 3) Instant analysis progress integration
- Replaced legacy `EnhancedAnalysisLoader` usage in `lib/screens/instant_analysis_screen.dart` with `AnalysisProgressView`.
- Flow now uses shared stages:
  - `checkingQuality` → `uploading` → `analyzingImage` → `applyingLocalRules` → `success`.
- Added retry path `_retryAnalysis()`.
- Removed direct call site for a second `GamificationService.processAnalysisCompleted` trigger to avoid duplicate gamification/analytics behavior in the instant flow.
- Extracted the success-path timing + navigation handoff into `lib/services/instant_analysis_flow_coordinator.dart` so route handoff can be tested without the full widget tree.

### 4) Result screen progress integration
- `lib/screens/result_screen.dart` now maps pipeline state into the same shared component via:
  - `_pipelineProgressStage(ResultPipelineState)`
  - `_pipelineStatusMessage(ResultPipelineState)`
  - `_buildPipelineProgress(...)`
- Processing and pipeline error states now render through `AnalysisProgressView`:
  - normal processing: `applyingLocalRules`
  - errors: `failedRetryable`
  - fallback: `fallback`
  - completed: `success`
- Added retry mechanism for pipeline failure:
  - `_retryClassificationProcessing()` with idempotent guard and state reset.

### 5) Accessibility and reduced-motion
- `AnalysisProgressView` uses `MediaQuery.disableAnimations` to collapse motion, including:
  - zero/low animation durations,
  - reduced transform offsets,
  - zero card elevation.
- Existing haptic triggers are skipped when `accessibleNavigation` or reduced-motion is enabled.

## UX Acceptance Check

### Capture → Result Coherence
- Coherent single state model is now used in both capture and result surfaces.
- States no longer have duplicated parallel loading visuals.

### Distinct State Messaging
- Each state has explicit title and description text.
- Offline queue and local-rule stages have dedicated UI treatments:
  - queue stack cards for offline position awareness,
  - local rule chip for apply step.

### Offline / Quality / Fallback Visibility
- Quality checks route are surfaced in capture and instant analysis.
- Offline queue state is clearly shown with queue position.
- Fallback and retryable errors show explicit retry/cancel messaging and controls.

### Reduced Motion
- Visual transitions and transform-heavy effects are muted when animations are disabled.
- Card and stage transitions degrade safely without blocking core state text/actions.

### No Duplicate Gamification / Analytics Triggers
- Confirmed direct duplicate gamification call removal from instant flow screen to prevent double-processing.
- Result flow keeps existing pipeline-driven reward flow untouched.

## Widget Tests Added
- New file: `test/widgets/analysis_progress_view_test.dart`
- Added a deterministic contract test for the instant-analysis success coordinator in `test/widgets/navigation_test.dart`.
- Coverage added for:
  - checkingQuality messaging
  - queuedOffline queue-position messaging
  - applyingLocalRules chip
  - success + fallback confidence text
  - failedRetryable retry action and error text
  - reduced-motion card elevation contract

## Verification Run
Executed:
- `flutter test test/widgets/analysis_progress_view_test.dart`
- `flutter test test/screens/result_screen_test.dart test/widgets/analysis_progress_view_test.dart`
- `flutter test test/screens/image_capture_screen_test.dart`

All tests passed.

## Notes / Risks
- The existing `EnhancedAnalysisLoader` widget remains in repo but is no longer used by the main capture/result progress path.
- No route/api layer changes were introduced; behavior remains state-driven within existing screens and pipelines.
