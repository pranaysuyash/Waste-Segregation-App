# Multi-Item Segmentation Flow

Date: 2026-05-21

## What was added

- `lib/screens/image_capture_screen.dart`
  - Manual multi-region analysis now builds a `MultiItemClassificationResult`.
  - The combined result screen now receives both the flat classifications and the richer region payload.

- `lib/screens/combined_result_screen.dart`
  - Multi-item guidance is shown when region data is present.
  - Per-item cards now render through `PerItemResultCard` when the result includes detected regions.

- `test/screens/image_capture_screen_test.dart`
  - Added a regression test for the mixed-waste guidance path.

- `lib/services/result_pipeline.dart`
  - Fixed the `_decorateForPersistence` signature syntax break that was blocking screen test compilation.

## Verification

- `flutter test test/screens/image_capture_screen_test.dart test/services/multi_item_classification_test.dart --reporter=compact`
  - Passed

## Notes

- The current multi-item flow is still manual-region driven. The segmentation service remains a stub/back-end placeholder and can be wired into the same result payload later without changing the result screen contract.
