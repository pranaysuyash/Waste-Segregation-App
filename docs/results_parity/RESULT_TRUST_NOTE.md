# Result Trust Note

> **Last Updated:** 2026-05-19  
> **Scope:** Result screen trust, feedback capture, and debug gating

## Canonical Contracts

### Unknown / Unclear Color
- Unknown or unclear classifications must never surface a `null` color in the display contract.
- Canonical fallback color: `#9E9E9E`.
- This applies to fixtures, result display, and any fallback classification path.

### Feedback / Correction Data Model
- Feedback uses `ClassificationFeedback` as the durable local record.
- The correction flow captures:
  - original classification context
  - confirmed vs corrected state
  - corrected category
  - corrected item name
  - corrected material
  - optional notes
- The stable ID is derived from `userId + classificationId` so the same user cannot create duplicate feedback records for the same classification.

### Result Processing Idempotency
- `processClassification()` must remain safe to call more than once for the same classification.
- `submitFeedback()` must remain idempotent across local storage and cloud sync checks.
- Duplicate feedback must not re-award points or re-track analytics.

### Debug Overlay Gate
- The init-status/debug overlay in `lib/main.dart` must stay behind an explicit dev-only opt-in.
- Default behavior must keep the overlay out of user-facing review and live screenshots.
- The overlay should never block normal result-screen QA.

## Notes

- The result screen now shows a visible trust prompt: "Was this correct?".
- Correction submissions are routed through the existing `resultPipelineProvider` path, not a new backend.
- If future re-analysis needs extra fields, extend `ClassificationFeedback` first so the model remains the source of truth.
