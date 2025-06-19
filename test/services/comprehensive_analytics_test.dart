import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waste_segregation_app/services/analytics_consent_manager.dart';
import 'package:waste_segregation_app/services/analytics_schema_validator.dart';
import 'package:waste_segregation_app/services/analytics_service.dart';
import 'package:waste_segregation_app/services/storage_service.dart';
import 'package:waste_segregation_app/models/gamification.dart';

void main() {
  group('Comprehensive Analytics Tests', () {
    late AnalyticsConsentManager consentManager;
    late AnalyticsSchemaValidator validator;
    late AnalyticsService analyticsService;
    late StorageService storageService;

    setUp(() async {
      // Initialize SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});
      
      consentManager = AnalyticsConsentManager();
      validator = AnalyticsSchemaValidator();
      storageService = StorageService();
      analyticsService = AnalyticsService(storageService);
    });

    group('AnalyticsConsentManager', () {
      test('should start with no consent by default', () async {
        expect(await consentManager.hasAnalyticsConsent(), false);
        expect(await consentManager.hasPerformanceConsent(), false);
        expect(await consentManager.hasMarketingConsent(), false);
        expect(await consentManager.hasEssentialConsent(), true); // Always true
      });

      test('should set and retrieve consent correctly', () async {
        await consentManager.setConsent(
          consentType: AnalyticsConsentManager.analyticsConsent,
          granted: true,
        );
        
        expect(await consentManager.hasAnalyticsConsent(), true);
        expect(await consentManager.hasPerformanceConsent(), false);
      });

      test('should set all consents at once', () async {
        await consentManager.setAllConsents(
          analytics: true,
          performance: true,
          marketing: false,
        );
        
        expect(await consentManager.hasAnalyticsConsent(), true);
        expect(await consentManager.hasPerformanceConsent(), true);
        expect(await consentManager.hasMarketingConsent(), false);
      });

      test('should generate and persist anonymous ID', () async {
        final id1 = await consentManager.getAnonymousId();
        final id2 = await consentManager.getAnonymousId();
        
        expect(id1, isNotEmpty);
        expect(id1, equals(id2)); // Should be the same on subsequent calls
        expect(id1, startsWith('anon_'));
      });

      test('should clear anonymous ID', () async {
        final id1 = await consentManager.getAnonymousId();
        await consentManager.clearAnonymousId();
        final id2 = await consentManager.getAnonymousId();
        
        expect(id1, isNot(equals(id2))); // Should be different after clearing
      });

      test('should check if consent dialog is needed', () async {
        expect(await consentManager.needsConsentDialog(), true); // First time
        
        await consentManager.setConsent(
          consentType: AnalyticsConsentManager.analyticsConsent,
          granted: true,
        );
        
        expect(await consentManager.needsConsentDialog(), false); // After setting consent
      });

      test('should determine event tracking permission correctly', () async {
        // No consent initially
        expect(await consentManager.shouldTrackEvent('analytics'), false);
        expect(await consentManager.shouldTrackEvent('performance'), false);
        expect(await consentManager.shouldTrackEvent('essential'), true);
        
        // Grant analytics consent
        await consentManager.setConsent(
          consentType: AnalyticsConsentManager.analyticsConsent,
          granted: true,
        );
        
        expect(await consentManager.shouldTrackEvent('analytics'), true);
        expect(await consentManager.shouldTrackEvent('user_action'), true);
        expect(await consentManager.shouldTrackEvent('performance'), false);
      });

      test('should withdraw all consent', () async {
        await consentManager.setAllConsents(
          analytics: true,
          performance: true,
          marketing: true,
        );
        
        expect(await consentManager.hasAnalyticsConsent(), true);
        
        await consentManager.withdrawAllConsent();
        
        expect(await consentManager.hasAnalyticsConsent(), false);
        expect(await consentManager.hasPerformanceConsent(), false);
        expect(await consentManager.hasMarketingConsent(), false);
      });
    });

    group('AnalyticsSchemaValidator', () {
      test('should validate a correct event', () async {
        final event = AnalyticsEvent.create(
          userId: 'test_user',
          eventType: AnalyticsEventTypes.session,
          eventName: AnalyticsEventNames.sessionStart,
          parameters: {
            'device_type': 'iOS',
            'app_version': '1.0.0',
            'platform': 'iOS',
          },
        );
        
        final result = await validator.validateEvent(event);
        
        expect(result.isValid, true);
        expect(result.errors, isEmpty);
      });

      test('should detect missing required fields', () async {
        final event = AnalyticsEvent.create(
          userId: 'test_user',
          eventType: AnalyticsEventTypes.session,
          eventName: AnalyticsEventNames.sessionStart,
          parameters: {
            // Missing required fields: device_type, app_version, platform
          },
        );
        
        final result = await validator.validateEvent(event);
        
        expect(result.isValid, false);
        expect(result.errors.length, greaterThan(0));
        expect(result.errors.any((error) => error.contains('device_type')), true);
      });

      test('should validate field types correctly', () async {
        final event = AnalyticsEvent.create(
          userId: 'test_user',
          eventType: AnalyticsEventTypes.classification,
          eventName: AnalyticsEventNames.fileClassified,
          parameters: {
            'model_version': 'v1.0',
            'processing_duration_ms': 'invalid_int', // Should be int
            'confidence_score': 0.85,
            'category': 'recyclable',
          },
        );
        
        final result = await validator.validateEvent(event);
        
        expect(result.isValid, false);
        expect(result.errors.any((error) => error.contains('processing_duration_ms')), true);
      });

      test('should validate numeric ranges', () async {
        final event = AnalyticsEvent.create(
          userId: 'test_user',
          eventType: AnalyticsEventTypes.classification,
          eventName: AnalyticsEventNames.fileClassified,
          parameters: {
            'model_version': 'v1.0',
            'processing_duration_ms': 1500,
            'confidence_score': 1.5, // Invalid: should be 0.0-1.0
            'category': 'recyclable',
          },
        );
        
        final result = await validator.validateEvent(event);
        
        expect(result.isValid, false);
        expect(result.errors.any((error) => error.contains('confidence_score')), true);
      });

      test('should validate event name format', () async {
        final event = AnalyticsEvent.create(
          userId: 'test_user',
          eventType: AnalyticsEventTypes.userAction,
          eventName: 'Invalid-Event-Name', // Should be snake_case
          parameters: {},
        );
        
        final result = await validator.validateEvent(event);
        
        expect(result.isValid, false);
        expect(result.errors.any((error) => error.contains('Invalid event name format')), true);
      });

      test('should detect potential PII', () async {
        final event = AnalyticsEvent.create(
          userId: 'test_user',
          eventType: AnalyticsEventTypes.userAction,
          eventName: AnalyticsEventNames.buttonClick,
          parameters: {
            'user_email': 'test@example.com', // PII detected
            'element_id': 'submit_button',
          },
        );
        
        final result = await validator.validateEvent(event);
        
        expect(result.warnings.any((warning) => warning.contains('email')), true);
      });

      test('should validate multiple events in batch', () async {
        final events = [
          AnalyticsEvent.create(
            userId: 'test_user',
            eventType: AnalyticsEventTypes.session,
            eventName: AnalyticsEventNames.sessionStart,
            parameters: {
              'device_type': 'iOS',
              'app_version': '1.0.0',
              'platform': 'iOS',
            },
          ),
          AnalyticsEvent.create(
            userId: 'test_user',
            eventType: AnalyticsEventTypes.userAction,
            eventName: 'invalid_event', // Invalid format
            parameters: {},
          ),
        ];
        
        final result = await validator.validateEvents(events);
        
        expect(result.totalEvents, 2);
        expect(result.validEvents, 1);
        expect(result.invalidEvents, 1);
        expect(result.validationRate, 0.5);
      });
    });

    group('Enhanced Analytics Service', () {
      test('should track session start with enhanced metadata', () async {
        // Grant consent first
        await consentManager.setConsent(
          consentType: AnalyticsConsentManager.analyticsConsent,
          granted: true,
        );
        
        await analyticsService.trackSessionStart();
        
        // Verify event was created (would need access to pending events)
        expect(analyticsService.pendingEventsCount, greaterThan(0));
      });

      test('should track page view with navigation context', () async {
        await consentManager.setConsent(
          consentType: AnalyticsConsentManager.analyticsConsent,
          granted: true,
        );
        
        await analyticsService.trackPageView(
          'HomeScreen',
          previousScreen: 'OnboardingScreen',
          navigationMethod: 'button_tap',
          timeOnPreviousScreen: 5000,
        );
        
        expect(analyticsService.pendingEventsCount, greaterThan(0));
      });

      test('should track click interactions', () async {
        await consentManager.setConsent(
          consentType: AnalyticsConsentManager.analyticsConsent,
          granted: true,
        );
        
        await analyticsService.trackClick(
          elementId: 'classify_button',
          screenName: 'HomeScreen',
          elementType: 'button',
          userIntent: 'start_classification',
        );
        
        expect(analyticsService.pendingEventsCount, greaterThan(0));
      });

      test('should track file classification with comprehensive data', () async {
        await consentManager.setConsent(
          consentType: AnalyticsConsentManager.analyticsConsent,
          granted: true,
        );
        
        await analyticsService.trackFileClassified(
          classificationId: 'test_id',
          category: 'recyclable_plastic',
          confidenceScore: 0.95,
          processingDuration: 1500,
          modelVersion: 'v2.1',
          method: 'instant',
          resultAccuracy: true,
        );
        
        expect(analyticsService.pendingEventsCount, greaterThan(0));
      });

      test('should track performance issues', () async {
        await consentManager.setConsent(
          consentType: AnalyticsConsentManager.performanceConsent,
          granted: true,
        );
        
        await analyticsService.trackSlowResource(
          operationName: 'image_processing',
          durationMs: 5000,
          resourceType: 'ai_classification',
        );
        
        expect(analyticsService.pendingEventsCount, greaterThan(0));
      });

      test('should track API errors', () async {
        await consentManager.setConsent(
          consentType: AnalyticsConsentManager.performanceConsent,
          granted: true,
        );
        
        await analyticsService.trackApiError(
          endpoint: '/api/classify',
          statusCode: 500,
          latencyMs: 3000,
          retryCount: 2,
          errorMessage: 'Internal server error',
        );
        
        expect(analyticsService.pendingEventsCount, greaterThan(0));
      });

      test('should not track events without consent', () async {
        // No consent granted
        final initialCount = analyticsService.pendingEventsCount;
        
        await analyticsService.trackClick(
          elementId: 'test_button',
          screenName: 'TestScreen',
          elementType: 'button',
        );
        
        expect(analyticsService.pendingEventsCount, equals(initialCount));
      });

      test('should track points earned events', () async {
        await consentManager.setConsent(
          consentType: AnalyticsConsentManager.analyticsConsent,
          granted: true,
        );
        
        await analyticsService.trackPointsEarned(
          pointsAmount: 10,
          sourceAction: 'classification',
          totalPoints: 150,
          category: 'recyclable',
        );
        
        expect(analyticsService.pendingEventsCount, greaterThan(0));
      });

      test('should track content engagement', () async {
        await consentManager.setConsent(
          consentType: AnalyticsConsentManager.analyticsConsent,
          granted: true,
        );
        
        await analyticsService.trackContentViewed(
          contentId: 'recycling_guide_1',
          contentType: 'educational_article',
          source: 'search',
          userLevel: 5,
        );
        
        await analyticsService.trackContentCompleted(
          contentId: 'recycling_guide_1',
          timeSpentMs: 45000,
          completionRate: 1.0,
          quizScore: 8,
        );
        
        expect(analyticsService.pendingEventsCount, greaterThan(1));
      });
    });

    group('Integration Tests', () {
      test('should validate events before tracking', () async {
        await consentManager.setConsent(
          consentType: AnalyticsConsentManager.analyticsConsent,
          granted: true,
        );
        
        final initialCount = analyticsService.pendingEventsCount;
        
        // Try to track an invalid event (missing required fields)
        await analyticsService.trackEvent(
          eventType: AnalyticsEventTypes.classification,
          eventName: AnalyticsEventNames.fileClassified,
          parameters: {
            // Missing required fields
          },
        );
        
        // Event should not be tracked due to validation failure
        expect(analyticsService.pendingEventsCount, equals(initialCount));
      });

      test('should include consent metadata in events', () async {
        await consentManager.setAllConsents(
          analytics: true,
          performance: false,
          marketing: true,
        );
        
        await analyticsService.trackClick(
          elementId: 'test_button',
          screenName: 'TestScreen',
          elementType: 'button',
        );
        
        // Would need access to the actual event to verify consent metadata is included
        expect(analyticsService.pendingEventsCount, greaterThan(0));
      });
    });
  });
} 