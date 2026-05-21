import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waste_segregation_app/models/gamification.dart';
import 'package:waste_segregation_app/services/analytics_consent_manager.dart';
import 'package:waste_segregation_app/services/analytics_schema_validator.dart';
import 'package:waste_segregation_app/services/analytics_service.dart';
import 'package:waste_segregation_app/services/storage_service.dart';

void main() {
  group('Comprehensive Analytics Tests', () {
    late AnalyticsConsentManager consentManager;
    late AnalyticsSchemaValidator validator;
    late AnalyticsService analyticsService;
    late StorageService storageService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      consentManager = AnalyticsConsentManager();
      validator = AnalyticsSchemaValidator();
      storageService = StorageService();
      analyticsService =
          AnalyticsService(storageService, enableFirestore: false);
    });

    group('AnalyticsConsentManager', () {
      test('starts with no optional consent', () async {
        expect(await consentManager.hasAnalyticsConsent(), false);
        expect(await consentManager.hasPerformanceConsent(), false);
        expect(await consentManager.hasMarketingConsent(), false);
        expect(await consentManager.hasEssentialConsent(), true);
      });

      test('persists explicit analytics consent', () async {
        await consentManager.setConsent(
          consentType: AnalyticsConsentManager.analyticsConsent,
          granted: true,
        );

        expect(await consentManager.hasAnalyticsConsent(), true);
      });

      test('generates stable anonymous id until cleared', () async {
        final id1 = await consentManager.getAnonymousId();
        final id2 = await consentManager.getAnonymousId();
        expect(id1, startsWith('anon_'));
        expect(id1, id2);

        await consentManager.clearAnonymousId();
        final id3 = await consentManager.getAnonymousId();
        expect(id3, isNot(id1));
      });
    });

    group('AnalyticsSchemaValidator', () {
      test('accepts a valid session_start event', () async {
        final event = AnalyticsEvent.create(
          userId: 'test_user',
          eventType: AnalyticsEventTypes.session,
          eventName: AnalyticsEventNames.sessionStart,
          sessionId: 'session_1',
          parameters: {
            'device_type': 'iOS',
            'app_version': '1.0.0',
            'platform': 'iOS',
          },
        );

        final result = await validator.validateEvent(event);
        expect(result.isValid, true);
      });

      test('rejects invalid parameter types and ranges', () async {
        final event = AnalyticsEvent.create(
          userId: 'test_user',
          eventType: AnalyticsEventTypes.classification,
          eventName: AnalyticsEventNames.fileClassified,
          sessionId: 'session_2',
          parameters: {
            'model_version': 'v1.0',
            'processing_duration_ms': 'invalid_int',
            'confidence_score': 1.5,
            'category': 'recyclable',
          },
        );

        final result = await validator.validateEvent(event);
        expect(result.isValid, false);
        expect(result.errors.any((e) => e.contains('processing_duration_ms')),
            true);
        expect(result.errors.any((e) => e.contains('confidence_score')), true);
      });

      test('flags potential pii warning', () async {
        final event = AnalyticsEvent.create(
          userId: 'test_user',
          eventType: AnalyticsEventTypes.userAction,
          eventName: AnalyticsEventNames.buttonClick,
          sessionId: 'session_3',
          parameters: {
            'user_email': 'test@example.com',
            'element_id': 'submit_button',
          },
        );

        final result = await validator.validateEvent(event);
        expect(result.warnings.any((w) => w.toLowerCase().contains('email')),
            true);
      });
    });

    group('AnalyticsService', () {
      test('handles session start tracking call without crashing', () async {
        await expectLater(analyticsService.trackSessionStart(), completes);
      });

      test('does not track invalid event payload', () async {
        final before = analyticsService.pendingEventsCount;

        await analyticsService.trackEvent(
          eventType: AnalyticsEventTypes.classification,
          eventName: AnalyticsEventNames.fileClassified,
          parameters: {
            'model_version': 'v2',
            'processing_duration_ms': 'bad_type',
            'confidence_score': 0.9,
            'category': 'dry',
          },
        );

        expect(analyticsService.pendingEventsCount, before);
      });

      test('handles click tracking call without crashing', () async {
        await consentManager.setConsent(
          consentType: AnalyticsConsentManager.analyticsConsent,
          granted: true,
        );

        await expectLater(
          analyticsService.trackClick(
            elementId: 'classify_button',
            screenName: 'HomeScreen',
            elementType: 'button',
          ),
          completes,
        );
      });
    });
  });
}
