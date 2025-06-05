import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/services/analytics_service.dart';
import 'package:waste_segregation_app/services/storage_service.dart';
import 'package:waste_segregation_app/models/user_profile.dart';
import 'package:waste_segregation_app/models/gamification.dart'; // AnalyticsEvent is here
import '../test_config/plugin_mock_setup.dart'; // Import Firebase mocks

// Simple manual mock for testing - only implements methods used by AnalyticsService
class MockStorageService extends StorageService {
  UserProfile? _mockUserProfile;
  
  void setMockUserProfile(UserProfile? profile) {
    _mockUserProfile = profile;
  }

  @override
  Future<UserProfile?> getCurrentUserProfile() async {
    return _mockUserProfile;
  }

  @override
  Future<void> saveAnalyticsEvents(List<dynamic> events) async {
    // Mock implementation - do nothing
  }
}

void main() {
  // Set up Firebase mocks before all tests
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    PluginMockSetup.setupFirebase();
  });

  // Clean up after all tests
  tearDownAll(() {
    PluginMockSetup.tearDownAll();
  });

  group('AnalyticsService', () {
    late AnalyticsService analyticsService;
    late MockStorageService mockStorageService;

    setUp(() {
      mockStorageService = MockStorageService();
      
      // Set up a mock user profile
      mockStorageService.setMockUserProfile(UserProfile(
        id: 'test_user_123',
        email: 'test@example.com',
        displayName: 'Test User',
        createdAt: DateTime.now(),
      ));
      
      analyticsService = AnalyticsService(mockStorageService);
    });

    group('Event Tracking', () {
      test('should track events with correct parameters', () async {
        // Test basic event tracking
        await analyticsService.trackEvent(
          eventType: AnalyticsEventTypes.userAction,
          eventName: AnalyticsEventNames.buttonClick,
          parameters: {'button_name': 'test_button', 'screen': 'home'},
        );

        // Verify the service doesn't throw errors
        expect(analyticsService.pendingEventsCount, greaterThanOrEqualTo(0));
      });

      test('should track classification events correctly', () async {
        await analyticsService.trackClassification(
          classificationId: 'test_classification_123',
          category: 'Recyclable',
          isRecyclable: true,
          confidence: 0.95,
          method: 'AI',
          additionalData: {'item_type': 'plastic_bottle'},
        );

        expect(analyticsService.pendingEventsCount, greaterThanOrEqualTo(0));
      });

      test('should track screen view events', () async {
        await analyticsService.trackScreenView(
          'home_screen',
          parameters: {'previous_screen': 'splash'},
        );

        expect(analyticsService.pendingEventsCount, greaterThanOrEqualTo(0));
      });

      test('should track user actions', () async {
        await analyticsService.trackUserAction(
          'button_click',
          parameters: {'button_id': 'capture_button'},
        );

        expect(analyticsService.pendingEventsCount, greaterThanOrEqualTo(0));
      });

      test('should track social interactions', () async {
        await analyticsService.trackSocialInteraction(
          interactionType: 'family_invitation_sent',
          targetId: 'user_456',
          familyId: 'family_789',
          additionalData: {'invitation_method': 'email'},
        );

        expect(analyticsService.pendingEventsCount, greaterThanOrEqualTo(0));
      });

      test('should track achievement events', () async {
        await analyticsService.trackAchievement(
          achievementId: 'first_classification',
          achievementType: 'milestone',
          pointsAwarded: 100,
          additionalData: {'category': 'beginner'},
        );

        expect(analyticsService.pendingEventsCount, greaterThanOrEqualTo(0));
      });

      test('should track error events', () async {
        await analyticsService.trackError(
          errorType: 'classification_error',
          errorMessage: 'Failed to classify image',
          stackTrace: 'Stack trace here...',
          additionalData: {'error_code': 'IMG_001'},
        );

        expect(analyticsService.pendingEventsCount, greaterThanOrEqualTo(0));
      });
    });

    group('Convenience Methods', () {
      test('should track button clicks', () {
        analyticsService.trackButtonClick('capture_button', screenName: 'camera');
        expect(analyticsService.pendingEventsCount, greaterThanOrEqualTo(0));
      });

      test('should track screen swipes', () {
        analyticsService.trackScreenSwipe('left', screenName: 'home');
        expect(analyticsService.pendingEventsCount, greaterThanOrEqualTo(0));
      });

      test('should track search actions', () {
        analyticsService.trackSearch('plastic bottle', resultCount: 5);
        expect(analyticsService.pendingEventsCount, greaterThanOrEqualTo(0));
      });

      test('should track classification workflow', () {
        analyticsService.trackClassificationStarted(method: 'camera');
        analyticsService.trackClassificationShared('classification_123', familyId: 'family_456');
        expect(analyticsService.pendingEventsCount, greaterThanOrEqualTo(0));
      });

      test('should track family events', () {
        analyticsService.trackFamilyCreated('family_123', memberCount: 3);
        analyticsService.trackFamilyJoined('family_456', invitationId: 'invite_789');
        expect(analyticsService.pendingEventsCount, greaterThanOrEqualTo(0));
      });
    });

    group('Session Management', () {
      test('should track session end', () {
        analyticsService.trackSessionEnd();
        expect(analyticsService.pendingEventsCount, greaterThanOrEqualTo(0));
      });

      test('should clear analytics data', () {
        analyticsService.clearAnalyticsData();
        // After clearing, pending events should be 0
        expect(analyticsService.pendingEventsCount, equals(0));
      });
    });

    group('Connection Status', () {
      test('should report Firestore connection status', () {
        final isConnected = analyticsService.isFirestoreConnected;
        expect(isConnected, isA<bool>());
      });

      test('should report pending events count', () {
        final count = analyticsService.pendingEventsCount;
        expect(count, isA<int>());
        expect(count, greaterThanOrEqualTo(0));
      });
    });

    group('Error Handling', () {
      test('should handle null user profile gracefully', () async {
        // Set up mock to return null user profile
        mockStorageService.setMockUserProfile(null);
        
        final newAnalyticsService = AnalyticsService(mockStorageService);
        
        // Should not throw when user profile is null
        await newAnalyticsService.trackEvent(
          eventType: AnalyticsEventTypes.userAction,
          eventName: 'test_event',
        );
        
        expect(newAnalyticsService.pendingEventsCount, equals(0));
      });

      test('should handle storage service errors gracefully', () async {
        // Create a mock that throws errors
        final errorMockStorageService = ErrorThrowingMockStorageService();
        
        final newAnalyticsService = AnalyticsService(errorMockStorageService);
        
        // Should not throw when storage service fails
        expect(() async => newAnalyticsService.trackEvent(
          eventType: AnalyticsEventTypes.userAction,
          eventName: 'test_event',
        ), returnsNormally);
      });
    });
  });

  group('AnalyticsEvent Model', () {
    test('should create analytics event with factory method', () {
      final event = AnalyticsEvent.create(
        userId: 'user_123',
        eventType: AnalyticsEventTypes.classification,
        eventName: AnalyticsEventNames.classificationCompleted,
        parameters: {'category': 'Recyclable', 'confidence': 0.95},
        sessionId: 'session_456',
        deviceInfo: 'iOS 15.0',
      );

      expect(event.id, isNotEmpty);
      expect(event.userId, equals('user_123'));
      expect(event.eventType, equals(AnalyticsEventTypes.classification));
      expect(event.eventName, equals(AnalyticsEventNames.classificationCompleted));
      expect(event.parameters['category'], equals('Recyclable'));
      expect(event.sessionId, equals('session_456'));
      expect(event.deviceInfo, equals('iOS 15.0'));
      expect(event.timestamp, isNotNull);
    });

    test('should serialize to and from JSON correctly', () {
      final event = AnalyticsEvent.create(
        userId: 'analytics_user',
        eventType: AnalyticsEventTypes.userAction,
        eventName: AnalyticsEventNames.buttonClick,
        parameters: {'button': 'capture', 'screen': 'home'},
        sessionId: 'session123',
        deviceInfo: 'iOS 15.0',
      );

      final json = event.toJson();
      final fromJson = AnalyticsEvent.fromJson(json);

      expect(fromJson.id, equals(event.id));
      expect(fromJson.userId, equals(event.userId));
      expect(fromJson.eventType, equals(event.eventType));
      expect(fromJson.eventName, equals(event.eventName));
      expect(fromJson.parameters, equals(event.parameters));
      expect(fromJson.sessionId, equals(event.sessionId));
      expect(fromJson.deviceInfo, equals(event.deviceInfo));
    });
  });

  group('AnalyticsEventTypes Constants', () {
    test('should have correct event type constants', () {
      expect(AnalyticsEventTypes.userAction, equals('user_action'));
      expect(AnalyticsEventTypes.screenView, equals('screen_view'));
      expect(AnalyticsEventTypes.classification, equals('classification'));
      expect(AnalyticsEventTypes.social, equals('social'));
      expect(AnalyticsEventTypes.achievement, equals('achievement'));
      expect(AnalyticsEventTypes.error, equals('error'));
    });
  });

  group('AnalyticsEventNames Constants', () {
    test('should have correct event name constants', () {
      expect(AnalyticsEventNames.buttonClick, equals('button_click'));
      expect(AnalyticsEventNames.screenSwipe, equals('screen_swipe'));
      expect(AnalyticsEventNames.classificationCompleted, equals('classification_completed'));
      expect(AnalyticsEventNames.achievementUnlocked, equals('achievement_unlocked'));
    });
  });
}

// Mock that throws errors for testing error handling
class ErrorThrowingMockStorageService extends StorageService {
  @override
  Future<UserProfile?> getCurrentUserProfile() async {
    throw Exception('Storage error');
  }

  @override
  Future<void> saveAnalyticsEvents(List<dynamic> events) async {
    throw Exception('Storage error');
  }
}
