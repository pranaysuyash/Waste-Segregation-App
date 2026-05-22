import 'dart:collection';

/// Canonical enum of all classification lifecycle states.
///
/// Every classification flows through a directed acyclic graph of these
/// states.  Invalid transitions produce a [StateError] at runtime so that
/// scattered boolean / try-catch paths are replaced by a single authority.
enum ClassificationState {
  /// No image selected yet (initial / reset).
  idle,

  /// User has selected or captured an image but not started analysis.
  imageSelected,

  /// Pre-flight quality gate running (blur, brightness, resolution).
  qualityChecking,

  /// Quality gate rejected the image; user may re-take or force-proceed.
  qualityRejected,

  /// Checking the classification cache (perceptual hash + context key).
  cacheChecking,

  /// Cache returned a valid result — skipping cloud/backend inference.
  cacheHit,

  /// AI/Backend classification is in flight.
  cloudClassifying,

  /// On-device / local model is running.
  localClassifying,

  /// User is offline; image queued for later processing.
  queuedOffline,

  /// AI returned a usable result (pre-policy, pre-pipeline).
  classificationSucceeded,

  /// Local policy engine (BBMP, region rules) is applying amendments.
  policyApplied,

  /// Result needs user review (low confidence / fallback mode).
  awaitingUserConfirmation,

  /// Classification + gamification + feedback saving to local storage.
  saving,

  /// Local save confirmed.
  saved,

  /// Syncing to cloud (Firestore).
  syncing,

  /// Cloud sync confirmed.
  synced,

  /// Transient failure — user can retry.
  failedRetryable,

  /// Permanent / terminal failure — no retry possible.
  failedPermanent,

  /// User or system cancelled the flow.
  cancelled,
}

/// Thread-safe transition rules for [ClassificationState].
///
/// Every entry maps (current state) → (set of legal next states).
/// Any transition not in this map throws [StateError] at runtime.
final Map<ClassificationState, Set<ClassificationState>>
    kClassificationTransitions =
    UnmodifiableMapView<ClassificationState, Set<ClassificationState>>(
  <ClassificationState, Set<ClassificationState>>{
    // ── Start ──────────────────────────────────────────────────────
    ClassificationState.idle: {
      ClassificationState.imageSelected,
      ClassificationState.cancelled,
    },

    // ── Image selection ────────────────────────────────────────────
    ClassificationState.imageSelected: {
      ClassificationState.qualityChecking,
      ClassificationState.cancelled,
    },

    // ── Quality gate ───────────────────────────────────────────────
    ClassificationState.qualityChecking: {
      ClassificationState.qualityRejected,
      ClassificationState.cacheChecking,
      ClassificationState.queuedOffline,
      ClassificationState.failedRetryable,
      ClassificationState.failedPermanent,
      ClassificationState.cancelled,
    },
    ClassificationState.qualityRejected: {
      ClassificationState.cacheChecking, // user tapped "Use Anyway"
      ClassificationState.imageSelected, // user tapped "Retake"
      ClassificationState.cancelled,
    },

    // ── Cache check ────────────────────────────────────────────────
    ClassificationState.cacheChecking: {
      ClassificationState.cacheHit,
      ClassificationState.cloudClassifying,
      ClassificationState.localClassifying,
      ClassificationState.failedRetryable,
      ClassificationState.cancelled,
    },
    ClassificationState.cacheHit: {
      ClassificationState.classificationSucceeded,
      ClassificationState.failedRetryable,
      ClassificationState.cancelled,
    },

    // ── Classification (cloud / local / offline) ───────────────────
    ClassificationState.cloudClassifying: {
      ClassificationState.classificationSucceeded,
      ClassificationState.queuedOffline,
      ClassificationState.failedRetryable,
      ClassificationState.failedPermanent,
      ClassificationState.cancelled,
    },
    ClassificationState.localClassifying: {
      ClassificationState.classificationSucceeded,
      ClassificationState.cloudClassifying,
      ClassificationState.failedRetryable,
      ClassificationState.failedPermanent,
      ClassificationState.cancelled,
    },
    ClassificationState.queuedOffline: {
      ClassificationState.classificationSucceeded,
      ClassificationState.failedPermanent,
      ClassificationState.cancelled,
    },

    // ── Post-classification ────────────────────────────────────────
    ClassificationState.classificationSucceeded: {
      ClassificationState.policyApplied,
      ClassificationState.saving,
      ClassificationState.awaitingUserConfirmation,
      ClassificationState.failedRetryable,
      ClassificationState.cancelled,
    },

    // ── Policy / Rules engine ──────────────────────────────────────
    ClassificationState.policyApplied: {
      ClassificationState.saving,
      ClassificationState.awaitingUserConfirmation,
      ClassificationState.failedRetryable,
      ClassificationState.cancelled,
    },

    // ── User confirmation / correction ─────────────────────────────
    ClassificationState.awaitingUserConfirmation: {
      ClassificationState.saving, // user confirmed
      ClassificationState.cloudClassifying, // user supplied correction → re-analyze
      ClassificationState.cancelled,
    },

    // ── Save ───────────────────────────────────────────────────────
    ClassificationState.saving: {
      ClassificationState.saved,
      ClassificationState.failedRetryable,
      ClassificationState.cancelled,
    },
    ClassificationState.saved: {
      ClassificationState.syncing,
      ClassificationState.synced, // skip sync if disabled
      ClassificationState.cancelled,
    },

    // ── Sync ───────────────────────────────────────────────────────
    ClassificationState.syncing: {
      ClassificationState.synced,
      ClassificationState.saved, // sync failure is non-critical
      ClassificationState.cancelled,
    },
    ClassificationState.synced: {
      ClassificationState.idle, // flow complete, reset
      ClassificationState.cancelled,
    },

    // ── Failure / terminal ─────────────────────────────────────────
    ClassificationState.failedRetryable: {
      ClassificationState.qualityChecking, // retry from beginning
      ClassificationState.cancelled,
    },
    ClassificationState.failedPermanent: {
      ClassificationState.idle,
      ClassificationState.cancelled,
    },

    // ── Cancelled (absorb transitions, only reset) ─────────────────
    ClassificationState.cancelled: {
      ClassificationState.idle,
    },
  },
);

/// A validatable state machine for a single classification lifecycle.
///
/// Usage:
/// ```dart
/// final machine = ClassificationStateMachine();
/// machine.transition(ClassificationState.imageSelected);
/// print(machine.current); // ClassificationState.imageSelected
/// ```
class ClassificationStateMachine {
  ClassificationStateMachine([this._state = ClassificationState.idle]);

  ClassificationState _state;
  int _transitionCount = 0;

  /// The current state.
  ClassificationState get current => _state;

  /// Number of transitions that have occurred.
  int get transitionCount => _transitionCount;

  /// Whether the machine has reached a terminal state.
  bool get isTerminal =>
      _state == ClassificationState.synced ||
      _state == ClassificationState.failedPermanent ||
      _state == ClassificationState.cancelled;

  /// Whether the machine is in a recoverable failure state.
  bool get isRecoverable =>
      _state == ClassificationState.failedRetryable;

  /// Whether the machine is actively processing (not terminal, not idle).
  bool get isActive =>
      _state != ClassificationState.idle && !isTerminal;

  /// Attempt a state transition.
  ///
  /// Throws [StateError] if the transition is not allowed by
  /// [kClassificationTransitions].  Returns `this` for chaining.
  ClassificationStateMachine transition(ClassificationState next) {
    final allowed = kClassificationTransitions[_state];
    if (allowed == null || !allowed.contains(next)) {
      throw StateError(
        'Invalid classification state transition: '
        '${_state.name} → ${next.name}',
      );
    }
    _state = next;
    _transitionCount++;
    return this;
  }

  /// Try a state transition; returns `false` instead of throwing.
  bool tryTransition(ClassificationState next) {
    final allowed = kClassificationTransitions[_state];
    if (allowed == null || !allowed.contains(next)) {
      return false;
    }
    _state = next;
    _transitionCount++;
    return true;
  }

  /// Reset to [ClassificationState.idle].
  void reset() {
    _state = ClassificationState.idle;
    _transitionCount = 0;
  }
}
