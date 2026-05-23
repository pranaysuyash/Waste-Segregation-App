# AI Feedback Loop Implementation

Date: 2026-05-23
Status: Implemented and verified at the widget/unit level

## Scope
This note records the continuous-learning / user-correction loop that ties the result screen and history screen back into the training-data pipeline.

## What the app does now
- `CorrectionDialog` is the user entry point for confirmation or correction.
- `ResultPipeline.submitFeedback()`:
  - saves the corrected classification locally
  - persists a stable `classification_feedback` record
  - awards gamification points
  - non-blockingly attaches the feedback to the training candidate via `TrainingDataService`
  - syncs to cloud when enabled
- `TrainingDataService.attachFeedbackToCandidate()` forwards feedback to the `attachTrainingLabelFeedback` Cloud Function.
- `HistoryListItem` now refreshes history after any non-null correction dialog result.
- `HistoryScreen` now reloads classifications after feedback instead of overwriting the saved corrected classification with stale data.

## Architecture decision
History feedback is now read-after-write refresh only. It does not re-save the original classification back into storage.

Reason:
- `CorrectionDialog` already routes the feedback through `ResultPipeline`.
- `ResultPipeline` is the source of truth for persistence and training-data side effects.
- Re-saving the original history item after feedback would risk overwriting the corrected local record.

## Verification
- Added a regression test in `test/ui_overflow_fixes_test.dart` that opens the feedback dialog and verifies the history refresh callback fires when the dialog returns a non-null `CorrectionResult`.
- Existing feedback-related tests already cover:
  - `test/widgets/correction_dialog_test.dart`
  - `test/services/result_pipeline_test.dart`
  - `test/services/result_pipeline_side_effects_test.dart`
  - `test/services/training_data_service_test.dart`

## Residual risk
- If the feedback dialog return type changes away from `CorrectionResult`, the history refresh callback should be rechecked.
- The unrelated `lib/services/storage_service.dart` test blocker reported earlier still exists in the repo and is outside this fix.
