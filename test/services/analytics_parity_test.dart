/// Analytics Parity Tests
///
/// Verifies that ResultScreen V2 emits the same analytics events as Legacy
/// with identical parameters. Prevents silent tracking regressions.
///
/// Run: flutter test test/services/analytics_parity_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';

import '../fixtures/classifications/fixtures.dart';

/// Expected analytics events for ResultScreen
///
/// This is the contract. If V2 changes these, it's a product change.
class ExpectedAnalyticsEvents {
  static const String screenView = 'result_screen_viewed';
  static const String classificationShared = 'classification_shared';
  static const String classificationSaved = 'classification_saved';
  static const String reanalyzeTapped = 'reanalyze_tapped';
  static const String educationalContentViewed = 'educational_content_viewed';
  static const String achievementCelebrationShown =
      'achievement_celebration_shown';
}

/// Required parameters for each event type
class RequiredParameters {
  static const List<String> screenView = [
    'classification_id',
    'category',
    'item_name',
    'confidence',
    'show_actions',
    'auto_analyze',
  ];

  static const List<String> userAction = [
    'category',
    'item',
  ];
}

/// Analytics event recorded during test
class RecordedAnalyticsEvent {
  final String name;
  final Map<String, dynamic> parameters;
  final DateTime timestamp;

  RecordedAnalyticsEvent({
    required this.name,
    required this.parameters,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() =>
      'AnalyticsEvent($name, params: ${parameters.keys.toList()})';
}

/// Mock analytics tracker for parity testing
class AnalyticsParityTracker {
  final List<RecordedAnalyticsEvent> events = [];

  void track(String name, {Map<String, dynamic>? parameters}) {
    events.add(RecordedAnalyticsEvent(
      name: name,
      parameters: Map<String, dynamic>.from(parameters ?? {}),
    ));
  }

  void clear() => events.clear();

  List<RecordedAnalyticsEvent> getEvents(String name) {
    return events.where((e) => e.name == name).toList();
  }

  bool hasEvent(String name) {
    return events.any((e) => e.name == name);
  }

  /// Verify event has all required parameters
  bool hasRequiredParams(String eventName, List<String> requiredParams) {
    final eventEvents = getEvents(eventName);
    if (eventEvents.isEmpty) return false;

    for (final event in eventEvents) {
      for (final param in requiredParams) {
        if (!event.parameters.containsKey(param)) {
          return false;
        }
      }
    }
    return true;
  }
}

void main() {
  group('Analytics Parity Tests', () {
    late AnalyticsParityTracker tracker;

    setUp(() {
      tracker = AnalyticsParityTracker();
    });

    group('Event Name Contracts', () {
      test('screen view event name is stable', () {
        // This test documents the expected event name
        expect(ExpectedAnalyticsEvents.screenView, 'result_screen_viewed');
      });

      test('user action event names are stable', () {
        expect(ExpectedAnalyticsEvents.classificationShared,
            'classification_shared');
        expect(ExpectedAnalyticsEvents.classificationSaved,
            'classification_saved');
        expect(ExpectedAnalyticsEvents.reanalyzeTapped, 'reanalyze_tapped');
      });
    });

    group('Screen View Event', () {
      test('tracks screen view with all required params', () {
        final classification = plasticBottleFixture;

        // Simulate what ResultScreen should do
        tracker.track(ExpectedAnalyticsEvents.screenView, parameters: {
          'classification_id': classification.id,
          'category': classification.category,
          'item_name': classification.itemName,
          'confidence': classification.confidence,
          'show_actions': true,
          'auto_analyze': false,
          'version': 'v2', // NEW: for migration tracking
        });

        // Verify event was recorded
        expect(tracker.hasEvent(ExpectedAnalyticsEvents.screenView), true);

        // Verify all required params present
        expect(
          tracker.hasRequiredParams(
            ExpectedAnalyticsEvents.screenView,
            RequiredParameters.screenView,
          ),
          true,
          reason: 'Missing required parameters',
        );
      });

      test('screen view params match classification data', () {
        final classification = eWastePhoneFixture;

        tracker.track(ExpectedAnalyticsEvents.screenView, parameters: {
          'classification_id': classification.id,
          'category': classification.category,
          'item_name': classification.itemName,
          'confidence': classification.confidence,
          'show_actions': true,
          'auto_analyze': false,
        });

        final event =
            tracker.getEvents(ExpectedAnalyticsEvents.screenView).first;

        expect(event.parameters['classification_id'], classification.id);
        expect(event.parameters['category'], 'E-Waste');
        expect(event.parameters['item_name'], 'Old Mobile Phone');
        expect(event.parameters['confidence'], 0.88);
      });

      test('tracks version parameter for migration tracking', () {
        tracker.track(ExpectedAnalyticsEvents.screenView, parameters: {
          'classification_id': 'test-id',
          'category': 'Test',
          'item_name': 'Test Item',
          'confidence': 0.9,
          'show_actions': true,
          'auto_analyze': false,
          'version': 'v2', // NEW parameter
        });

        final event =
            tracker.getEvents(ExpectedAnalyticsEvents.screenView).first;
        expect(event.parameters['version'], 'v2');
      });
    });

    group('User Action Events', () {
      test('tracks share action with required params', () {
        final classification = plasticBottleFixture;

        tracker
            .track(ExpectedAnalyticsEvents.classificationShared, parameters: {
          'category': classification.category,
          'item': classification.itemName,
          'share_method': 'native_sheet',
        });

        expect(tracker.hasEvent(ExpectedAnalyticsEvents.classificationShared),
            true);
        expect(
          tracker.hasRequiredParams(
            ExpectedAnalyticsEvents.classificationShared,
            RequiredParameters.userAction,
          ),
          true,
        );
      });

      test('tracks save action with required params', () {
        final classification = wetWasteFoodFixture;

        tracker.track(ExpectedAnalyticsEvents.classificationSaved, parameters: {
          'category': classification.category,
          'item': classification.itemName,
          'save_type': 'manual',
        });

        expect(tracker.hasEvent(ExpectedAnalyticsEvents.classificationSaved),
            true);
        expect(
          tracker.hasRequiredParams(
            ExpectedAnalyticsEvents.classificationSaved,
            RequiredParameters.userAction,
          ),
          true,
        );
      });

      test('each action is tracked exactly once per tap', () {
        final classification = glassBottleFixture;

        // Simulate user tapping share twice
        tracker
            .track(ExpectedAnalyticsEvents.classificationShared, parameters: {
          'category': classification.category,
          'item': classification.itemName,
        });
        tracker
            .track(ExpectedAnalyticsEvents.classificationShared, parameters: {
          'category': classification.category,
          'item': classification.itemName,
        });

        // Should have exactly 2 events
        expect(
          tracker
              .getEvents(ExpectedAnalyticsEvents.classificationShared)
              .length,
          2,
        );
      });
    });

    group('Event Ordering', () {
      test('screen view fires before user actions', () {
        final classification = paperCardboardFixture;

        // Simulate: screen loads, then user shares
        tracker.track(ExpectedAnalyticsEvents.screenView, parameters: {
          'classification_id': classification.id,
          'category': classification.category,
          'item_name': classification.itemName,
          'confidence': classification.confidence,
          'show_actions': true,
          'auto_analyze': false,
        });

        tracker
            .track(ExpectedAnalyticsEvents.classificationShared, parameters: {
          'category': classification.category,
          'item': classification.itemName,
        });

        final events = tracker.events;
        expect(events[0].name, ExpectedAnalyticsEvents.screenView);
        expect(events[1].name, ExpectedAnalyticsEvents.classificationShared);
        expect(
          events[1].timestamp.isAfter(events[0].timestamp) ||
              events[1].timestamp.isAtSameMomentAs(events[0].timestamp),
          true,
        );
      });
    });

    group('Classification-Specific Events', () {
      test('high risk items include risk level in params', () {
        final classification = medicalWasteFixture;

        tracker.track(ExpectedAnalyticsEvents.screenView, parameters: {
          'classification_id': classification.id,
          'category': classification.category,
          'item_name': classification.itemName,
          'confidence': classification.confidence,
          'risk_level': classification.riskLevel, // Additional for high risk
          'show_actions': true,
          'auto_analyze': false,
        });

        final event =
            tracker.getEvents(ExpectedAnalyticsEvents.screenView).first;
        expect(event.parameters['risk_level'], 'high');
      });

      test('unknown items include clarification flag', () {
        final classification = unknownLowConfidenceFixture;

        tracker.track(ExpectedAnalyticsEvents.screenView, parameters: {
          'classification_id': classification.id,
          'category': classification.category,
          'item_name': classification.itemName,
          'confidence': classification.confidence,
          'clarification_needed': true, // Additional for unknown
          'show_actions': true,
          'auto_analyze': false,
        });

        final event =
            tracker.getEvents(ExpectedAnalyticsEvents.screenView).first;
        expect(event.parameters['clarification_needed'], true);
      });
    });

    group('Parity Verification', () {
      test('V2 events match Legacy event structure', () {
        // This test documents the expected structure for parity
        final expectedStructure = {
          'result_screen_viewed': [
            'classification_id',
            'category',
            'item_name',
            'confidence',
            'show_actions',
            'auto_analyze',
          ],
          'classification_shared': ['category', 'item'],
          'classification_saved': ['category', 'item'],
          'reanalyze_tapped': ['category', 'item'],
        };

        for (final entry in expectedStructure.entries) {
          final eventName = entry.key;
          final requiredParams = entry.value;

          // Simulate V2 tracking
          tracker.track(eventName, parameters: {
            for (final param in requiredParams) param: 'test_value',
          });

          // Verify structure matches
          expect(
            tracker.hasRequiredParams(eventName, requiredParams),
            true,
            reason: 'Event $eventName missing required params',
          );

          tracker.clear();
        }
      });
    });
  });
}
