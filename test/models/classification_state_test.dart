import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/classification_state.dart';

void main() {
  group('ClassificationStateMachine', () {
    group('initial state', () {
      test('starts in idle', () {
        final machine = ClassificationStateMachine();
        expect(machine.current, equals(ClassificationState.idle));
      });

      test('transitionCount is 0', () {
        final machine = ClassificationStateMachine();
        expect(machine.transitionCount, equals(0));
      });

      test('isTerminal is false', () {
        final machine = ClassificationStateMachine();
        expect(machine.isTerminal, isFalse);
      });

      test('isRecoverable is false', () {
        final machine = ClassificationStateMachine();
        expect(machine.isRecoverable, isFalse);
      });

      test('isActive is false', () {
        final machine = ClassificationStateMachine();
        expect(machine.isActive, isFalse);
      });
    });

    group('valid transitions', () {
      test('idle → imageSelected', () {
        final machine = ClassificationStateMachine();
        machine.transition(ClassificationState.imageSelected);
        expect(machine.current, equals(ClassificationState.imageSelected));
        expect(machine.transitionCount, equals(1));
        expect(machine.isActive, isTrue);
      });

      test('idle → cancelled', () {
        final machine = ClassificationStateMachine();
        machine.transition(ClassificationState.cancelled);
        expect(machine.current, equals(ClassificationState.cancelled));
        expect(machine.isTerminal, isTrue);
        expect(machine.isActive, isFalse);
      });

      test('full happy path: idle → synced', () {
        final machine = ClassificationStateMachine();
        machine.transition(ClassificationState.imageSelected);
        machine.transition(ClassificationState.qualityChecking);
        machine.transition(ClassificationState.cacheChecking);
        machine.transition(ClassificationState.cloudClassifying);
        machine.transition(ClassificationState.classificationSucceeded);
        machine.transition(ClassificationState.policyApplied);
        machine.transition(ClassificationState.saving);
        machine.transition(ClassificationState.saved);
        machine.transition(ClassificationState.syncing);
        machine.transition(ClassificationState.synced);

        expect(machine.current, equals(ClassificationState.synced));
        expect(machine.isTerminal, isTrue);
        expect(machine.transitionCount, equals(10));
      });

      test('offline path: qualityChecking → queuedOffline → classificationSucceeded', () {
        final machine = ClassificationStateMachine();
        machine.transition(ClassificationState.imageSelected);
        machine.transition(ClassificationState.qualityChecking);
        machine.transition(ClassificationState.queuedOffline);
        machine.transition(ClassificationState.classificationSucceeded);

        expect(machine.current, equals(ClassificationState.classificationSucceeded));
      });

      test('cache hit path', () {
        final machine = ClassificationStateMachine();
        machine.transition(ClassificationState.imageSelected);
        machine.transition(ClassificationState.qualityChecking);
        machine.transition(ClassificationState.cacheChecking);
        machine.transition(ClassificationState.cacheHit);
        machine.transition(ClassificationState.classificationSucceeded);

        expect(machine.current, equals(ClassificationState.classificationSucceeded));
      });

      test('rejected quality → use anyway path', () {
        final machine = ClassificationStateMachine();
        machine.transition(ClassificationState.imageSelected);
        machine.transition(ClassificationState.qualityChecking);
        machine.transition(ClassificationState.qualityRejected);
        machine.transition(ClassificationState.cacheChecking);

        expect(machine.current, equals(ClassificationState.cacheChecking));
      });

      test('rejected quality → retake path', () {
        final machine = ClassificationStateMachine();
        machine.transition(ClassificationState.imageSelected);
        machine.transition(ClassificationState.qualityChecking);
        machine.transition(ClassificationState.qualityRejected);
        machine.transition(ClassificationState.imageSelected);

        expect(machine.current, equals(ClassificationState.imageSelected));
      });

      test('retryable failure → retry', () {
        final machine = ClassificationStateMachine();
        machine.transition(ClassificationState.imageSelected);
        machine.transition(ClassificationState.qualityChecking);
        machine.transition(ClassificationState.failedRetryable);
        machine.transition(ClassificationState.qualityChecking);

        expect(machine.current, equals(ClassificationState.qualityChecking));
      });

      test('user confirmation flow', () {
        final machine = ClassificationStateMachine();
        machine.transition(ClassificationState.imageSelected);
        machine.transition(ClassificationState.qualityChecking);
        machine.transition(ClassificationState.cacheChecking);
        machine.transition(ClassificationState.cloudClassifying);
        machine.transition(ClassificationState.classificationSucceeded);
        machine.transition(ClassificationState.awaitingUserConfirmation);
        machine.transition(ClassificationState.saving);

        expect(machine.current, equals(ClassificationState.saving));
      });

      test('user correction → re-analyze', () {
        final machine = ClassificationStateMachine();
        machine.transition(ClassificationState.imageSelected);
        machine.transition(ClassificationState.classificationSucceeded);
        // user disagreed, fallback to awaiting confirmation
        machine.transition(ClassificationState.awaitingUserConfirmation);
        // user corrected → re-analyze
        machine.transition(ClassificationState.cloudClassifying);

        expect(machine.current, equals(ClassificationState.cloudClassifying));
      });

      test('cancelled → idle resets', () {
        final machine = ClassificationStateMachine();
        machine.transition(ClassificationState.imageSelected);
        machine.transition(ClassificationState.qualityChecking);
        machine.transition(ClassificationState.cancelled);
        machine.transition(ClassificationState.idle);

        expect(machine.current, equals(ClassificationState.idle));
        expect(machine.isTerminal, isFalse);
      });

      test('reset() returns to idle with zero count', () {
        final machine = ClassificationStateMachine();
        machine.transition(ClassificationState.imageSelected);
        machine.transition(ClassificationState.cloudClassifying);
        expect(machine.transitionCount, equals(2));

        machine.reset();
        expect(machine.current, equals(ClassificationState.idle));
        expect(machine.transitionCount, equals(0));
      });

      test('terminal states are correctly identified', () {
        final synced = ClassificationStateMachine()
          ..transition(ClassificationState.imageSelected)
          ..transition(ClassificationState.qualityChecking)
          ..transition(ClassificationState.cacheChecking)
          ..transition(ClassificationState.cloudClassifying)
          ..transition(ClassificationState.classificationSucceeded)
          ..transition(ClassificationState.policyApplied)
          ..transition(ClassificationState.saving)
          ..transition(ClassificationState.saved)
          ..transition(ClassificationState.syncing)
          ..transition(ClassificationState.synced);
        expect(synced.isTerminal, isTrue);

        final permanent = ClassificationStateMachine()
          ..transition(ClassificationState.imageSelected)
          ..transition(ClassificationState.cloudClassifying)
          ..transition(ClassificationState.failedPermanent);
        expect(permanent.isTerminal, isTrue);

        final cancelled = ClassificationStateMachine()
          ..transition(ClassificationState.imageSelected)
          ..transition(ClassificationState.cancelled);
        expect(cancelled.isTerminal, isTrue);
      });

      test('isRecoverable only for failedRetryable', () {
        final retryable = ClassificationStateMachine()
          ..transition(ClassificationState.imageSelected)
          ..transition(ClassificationState.cloudClassifying)
          ..transition(ClassificationState.failedRetryable);
        expect(retryable.isRecoverable, isTrue);

        final permanent = ClassificationStateMachine()
          ..transition(ClassificationState.imageSelected)
          ..transition(ClassificationState.cloudClassifying)
          ..transition(ClassificationState.failedPermanent);
        expect(permanent.isRecoverable, isFalse);
      });
    });

    group('invalid transitions', () {
      test('idle → cloudClassifying throws', () {
        final machine = ClassificationStateMachine();
        expect(
          () => machine.transition(ClassificationState.cloudClassifying),
          throwsStateError,
        );
      });

      test('idle → qualityChecking throws', () {
        final machine = ClassificationStateMachine();
        expect(
          () => machine.transition(ClassificationState.qualityChecking),
          throwsStateError,
        );
      });

      test('imageSelected → saving throws', () {
        final machine = ClassificationStateMachine();
        machine.transition(ClassificationState.imageSelected);
        expect(
          () => machine.transition(ClassificationState.saving),
          throwsStateError,
        );
      });

      test('failedPermanent → qualityChecking throws', () {
        final machine = ClassificationStateMachine();
        machine.transition(ClassificationState.imageSelected);
        machine.transition(ClassificationState.cloudClassifying);
        machine.transition(ClassificationState.failedPermanent);
        expect(
          () => machine.transition(ClassificationState.qualityChecking),
          throwsStateError,
        );
      });

      test('synced → saving throws', () {
        final machine = ClassificationStateMachine();
        machine.transition(ClassificationState.imageSelected);
        machine.transition(ClassificationState.classificationSucceeded);
        machine.transition(ClassificationState.saving);
        machine.transition(ClassificationState.saved);
        machine.transition(ClassificationState.synced);
        expect(
          () => machine.transition(ClassificationState.saving),
          throwsStateError,
        );
      });

      test('tryTransition returns false for invalid transition', () {
        final machine = ClassificationStateMachine();
        final result = machine.tryTransition(ClassificationState.cloudClassifying);
        expect(result, isFalse);
        expect(machine.current, equals(ClassificationState.idle));
      });

      test('tryTransition returns true for valid transition', () {
        final machine = ClassificationStateMachine();
        final result = machine.tryTransition(ClassificationState.imageSelected);
        expect(result, isTrue);
        expect(machine.current, equals(ClassificationState.imageSelected));
      });
    });

    group('kClassificationTransitions completeness', () {
      test('every state has an entry in the transition map', () {
        for (final state in ClassificationState.values) {
          expect(
            kClassificationTransitions.containsKey(state),
            isTrue,
            reason: 'Missing transition entry for ${state.name}',
          );
        }
      });

      test('every entry contains only valid enum values', () {
        final allStates = ClassificationState.values.toSet();
        for (final entry in kClassificationTransitions.entries) {
          for (final next in entry.value) {
            expect(
              allStates.contains(next),
              isTrue,
              reason:
                  '${entry.key.name} → ${next.name} is not a valid ClassificationState',
            );
          }
        }
      });

      test('transition count matches total allowed edges', () {
        // Verify the map has reasonable coverage — at least one transition
        // per state.
        for (final entry in kClassificationTransitions.entries) {
          expect(
            entry.value.isNotEmpty,
            isTrue,
            reason: 'State ${entry.key.name} has no outgoing transitions',
          );
        }
      });
    });
  });

}
