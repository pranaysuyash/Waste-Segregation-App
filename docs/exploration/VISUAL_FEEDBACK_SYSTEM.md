# Visual Feedback & Haptic System

- **Decision it unblocks**: Design a consistent feedback system for classification results — animations, haptics, color transitions, and micro-interactions that communicate correctness, confidence, and action without overwhelming the user.
- **Key questions**:
  - What feedback patterns exist already (success/failure/loading animations, haptic patterns, color shifts)?
  - Should feedback be tied to classification confidence tiers (high → subtle, low → instructive)?
  - How to avoid feedback fatigue — when to animate and when to stay quiet?
  - Cross-platform parity for haptics (iOS Core Haptics vs. Android Vibrator vs. web fallback)?
- **Kill criteria**: App uses only native OS toast/snackbar patterns with no custom feedback.
- **Status**: Seed — 2026-05-25
- **Links**: [`visual_feedback_service.dart`](../../lib/services/visual_feedback_service.dart), [`gen_z_microinteractions.dart`](../../lib/widgets/gen_z_microinteractions.dart), [`success_celebrations.dart`](../../lib/widgets/animations/success_celebrations.dart), [`error_recovery_animations.dart`](../../lib/widgets/animations/error_recovery_animations.dart)
- **Source discovery**: Gap analysis of `lib/` services — `visual_feedback_service.dart` exists as a dedicated service with no exploration topic.
