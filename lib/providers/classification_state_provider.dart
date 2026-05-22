import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/classification_state.dart';

/// Riverpod provider that exposes a [ClassificationStateMachine] across the
/// widget tree so the UI, capture screen, result pipeline, and gamification
/// all read from a single source of truth.
///
/// Consumers:
/// - `ImageCaptureScreen` → renders progress, action buttons
/// - `ResultScreen` / `ResultPipeline` → gates save/sync/gamification
/// - `AnalysisProgressView` → renders from [ClassificationState]
final classificationStateMachineProvider =
    StateNotifierProvider<ClassificationStateMachineNotifier,
        ClassificationStateMachine>(
  (_) => ClassificationStateMachineNotifier(),
);

class ClassificationStateMachineNotifier
    extends StateNotifier<ClassificationStateMachine> {
  ClassificationStateMachineNotifier() : super(ClassificationStateMachine());

  /// Convenience getter for the current state value.
  ClassificationState get current => state.current;

  /// Transition to [next] with validation.
  /// Throws [StateError] on invalid transition.
  void transitionTo(ClassificationState next) {
    state = state..transition(next);
  }

  /// Attempt a transition; returns whether it was allowed.
  bool tryTransitionTo(ClassificationState next) {
    if (state.tryTransition(next)) {
      state = state;
      return true;
    }
    return false;
  }

  /// Reset the machine to [ClassificationState.idle].
  void reset() {
    state = state..reset();
  }
}
