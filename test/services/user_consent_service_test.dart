import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waste_segregation_app/services/user_consent_service.dart';

@GenerateMocks([SharedPreferences])
import 'user_consent_service_test.mocks.dart';

void main() {
  group('UserConsentService Tests', () {
    late UserConsentService userConsentService;
    late MockSharedPreferences mockSharedPreferences;

    setUp(() {
      mockSharedPreferences = MockSharedPreferences();
      userConsentService = UserConsentService(mockSharedPreferences);
    });

    group('GDPR Compliance', () {
      test('should initialize with no consent by default', () {
        when(mockSharedPreferences.getBool(any)).thenReturn(null);

        expect(userConsentService.hasAnalyticsConsent, false);
        expect(userConsentService.hasMarketingConsent, false);
        expect(userConsentService.hasFunctionalConsent, false);
        expect(userConsentService.hasDataProcessingConsent, false);
      });

      test('should set and get analytics consent', () async {
        when(mockSharedPreferences.setBool(any, any))
            .thenAnswer((_) async => true);
        when(mockSharedPreferences.getBool('analytics_consent'))
            .thenReturn(true);

        await userConsentService.setAnalyticsConsent(true);

        expect(userConsentService.hasAnalyticsConsent, true);
        verify(mockSharedPreferences.setBool('analytics_consent', true)).called(1);
      });

      test('should set and get marketing consent', () async {
        when(mockSharedPreferences.setBool(any, any))
            .thenAnswer((_) async => true);
        when(mockSharedPreferences.getBool('marketing_consent'))
            .thenReturn(true);

        await userConsentService.setMarketingConsent(true);

        expect(userConsentService.hasMarketingConsent, true);
        verify(mockSharedPreferences.setBool('marketing_consent', true)).called(1);
      });

      test('should set and get functional consent', () async {
        when(mockSharedPreferences.setBool(any, any))
            .thenAnswer((_) async => true);
        when(mockSharedPreferences.getBool('functional_consent'))
            .thenReturn(true);

        await userConsentService.setFunctionalConsent(true);

        expect(userConsentService.hasFunctionalConsent, true);
        verify(mockSharedPreferences.setBool('functional_consent', true)).called(1);
      });

      test('should set and get data processing consent', () async {
        when(mockSharedPreferences.setBool(any, any))
            .thenAnswer((_) async => true);
        when(mockSharedPreferences.getBool('data_processing_consent'))
            .thenReturn(true);

        await userConsentService.setDataProcessingConsent(true);

        expect(userConsentService.hasDataProcessingConsent, true);
        verify(mockSharedPreferences.setBool('data_processing_consent', true)).called(1);
      });
    });

    group('Consent Management', () {
      test('should check if all necessary consents are given', () {
        when(mockSharedPreferences.getBool('analytics_consent')).thenReturn(true);
        when(mockSharedPreferences.getBool('functional_consent')).thenReturn(true);
        when(mockSharedPreferences.getBool('data_processing_consent')).thenReturn(true);
        when(mockSharedPreferences.getBool('marketing_consent')).thenReturn(false);

        expect(userConsentService.hasNecessaryConsents, true);
        expect(userConsentService.hasAllConsents, false);
      });

      test('should revoke all consents', () async {
        when(mockSharedPreferences.setBool(any, any))
            .thenAnswer((_) async => true);

        await userConsentService.revokeAllConsents();

        verify(mockSharedPreferences.setBool('analytics_consent', false)).called(1);
        verify(mockSharedPreferences.setBool('marketing_consent', false)).called(1);
        verify(mockSharedPreferences.setBool('functional_consent', false)).called(1);
        verify(mockSharedPreferences.setBool('data_processing_consent', false)).called(1);
      });

      test('should set consent timestamp', () async {
        when(mockSharedPreferences.setString(any, any))
            .thenAnswer((_) async => true);

        final timestamp = DateTime.now();
        await userConsentService.setConsentTimestamp(timestamp);

        verify(mockSharedPreferences.setString(
          'consent_timestamp', 
          timestamp.toIso8601String()
        )).called(1);
      });

      test('should get consent timestamp', () {
        final timestamp = DateTime(2024, 1, 15, 10, 30);
        when(mockSharedPreferences.getString('consent_timestamp'))
            .thenReturn(timestamp.toIso8601String());

        final retrievedTimestamp = userConsentService.consentTimestamp;

        expect(retrievedTimestamp, timestamp);
      });

      test('should handle null consent timestamp', () {
        when(mockSharedPreferences.getString('consent_timestamp'))
            .thenReturn(null);

        final retrievedTimestamp = userConsentService.consentTimestamp;

        expect(retrievedTimestamp, null);
      });
    });

    group('Consent Validation', () {
      test('should check if consent is expired', () {
        // Set consent timestamp to 1 year ago
        final oneYearAgo = DateTime.now().subtract(const Duration(days: 365));
        when(mockSharedPreferences.getString('consent_timestamp'))
            .thenReturn(oneYearAgo.toIso8601String());

        expect(userConsentService.isConsentExpired, true);
      });

      test('should check if consent is still valid', () {
        // Set consent timestamp to 6 months ago
        final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 180));
        when(mockSharedPreferences.getString('consent_timestamp'))
            .thenReturn(sixMonthsAgo.toIso8601String());

        expect(userConsentService.isConsentExpired, false);
      });

      test('should handle missing consent timestamp as expired', () {
        when(mockSharedPreferences.getString('consent_timestamp'))
            .thenReturn(null);

        expect(userConsentService.isConsentExpired, true);
      });

      test('should check if consent renewal is needed', () {
        // Set consent timestamp to 11 months ago (within renewal period)
        final elevenMonthsAgo = DateTime.now().subtract(const Duration(days: 330));
        when(mockSharedPreferences.getString('consent_timestamp'))
            .thenReturn(elevenMonthsAgo.toIso8601String());

        expect(userConsentService.needsConsentRenewal, true);
      });
    });

    group('Data Subject Rights', () {
      test('should check if user can request data deletion', () {
        when(mockSharedPreferences.getBool('data_processing_consent')).thenReturn(true);

        expect(userConsentService.canRequestDataDeletion, true);
      });

      test('should check if user can request data export', () {
        when(mockSharedPreferences.getBool('data_processing_consent')).thenReturn(true);

        expect(userConsentService.canRequestDataExport, true);
      });

      test('should record data deletion request', () async {
        when(mockSharedPreferences.setString(any, any))
            .thenAnswer((_) async => true);

        final requestTime = DateTime.now();
        await userConsentService.recordDataDeletionRequest(requestTime);

        verify(mockSharedPreferences.setString(
          'data_deletion_request_timestamp',
          requestTime.toIso8601String()
        )).called(1);
      });

      test('should record data export request', () async {
        when(mockSharedPreferences.setString(any, any))
            .thenAnswer((_) async => true);

        final requestTime = DateTime.now();
        await userConsentService.recordDataExportRequest(requestTime);

        verify(mockSharedPreferences.setString(
          'data_export_request_timestamp',
          requestTime.toIso8601String()
        )).called(1);
      });

      test('should get data deletion request timestamp', () {
        final timestamp = DateTime(2024, 1, 15, 10, 30);
        when(mockSharedPreferences.getString('data_deletion_request_timestamp'))
            .thenReturn(timestamp.toIso8601String());

        final retrievedTimestamp = userConsentService.dataDeletionRequestTimestamp;

        expect(retrievedTimestamp, timestamp);
      });

      test('should get data export request timestamp', () {
        final timestamp = DateTime(2024, 1, 15, 10, 30);
        when(mockSharedPreferences.getString('data_export_request_timestamp'))
            .thenReturn(timestamp.toIso8601String());

        final retrievedTimestamp = userConsentService.dataExportRequestTimestamp;

        expect(retrievedTimestamp, timestamp);
      });
    });

    group('Cookie Consent', () {
      test('should manage essential cookies consent', () async {
        when(mockSharedPreferences.setBool(any, any))
            .thenAnswer((_) async => true);
        when(mockSharedPreferences.getBool('essential_cookies_consent'))
            .thenReturn(true);

        await userConsentService.setEssentialCookiesConsent(true);

        expect(userConsentService.hasEssentialCookiesConsent, true);
        verify(mockSharedPreferences.setBool('essential_cookies_consent', true)).called(1);
      });

      test('should manage performance cookies consent', () async {
        when(mockSharedPreferences.setBool(any, any))
            .thenAnswer((_) async => true);
        when(mockSharedPreferences.getBool('performance_cookies_consent'))
            .thenReturn(true);

        await userConsentService.setPerformanceCookiesConsent(true);

        expect(userConsentService.hasPerformanceCookiesConsent, true);
        verify(mockSharedPreferences.setBool('performance_cookies_consent', true)).called(1);
      });

      test('should manage advertising cookies consent', () async {
        when(mockSharedPreferences.setBool(any, any))
            .thenAnswer((_) async => true);
        when(mockSharedPreferences.getBool('advertising_cookies_consent'))
            .thenReturn(true);

        await userConsentService.setAdvertisingCookiesConsent(true);

        expect(userConsentService.hasAdvertisingCookiesConsent, true);
        verify(mockSharedPreferences.setBool('advertising_cookies_consent', true)).called(1);
      });
    });

    group('Third-Party Services', () {
      test('should manage Google Analytics consent', () async {
        when(mockSharedPreferences.setBool(any, any))
            .thenAnswer((_) async => true);
        when(mockSharedPreferences.getBool('google_analytics_consent'))
            .thenReturn(true);

        await userConsentService.setGoogleAnalyticsConsent(true);

        expect(userConsentService.hasGoogleAnalyticsConsent, true);
        verify(mockSharedPreferences.setBool('google_analytics_consent', true)).called(1);
      });

      test('should manage Firebase consent', () async {
        when(mockSharedPreferences.setBool(any, any))
            .thenAnswer((_) async => true);
        when(mockSharedPreferences.getBool('firebase_consent'))
            .thenReturn(true);

        await userConsentService.setFirebaseConsent(true);

        expect(userConsentService.hasFirebaseConsent, true);
        verify(mockSharedPreferences.setBool('firebase_consent', true)).called(1);
      });

      test('should manage crash reporting consent', () async {
        when(mockSharedPreferences.setBool(any, any))
            .thenAnswer((_) async => true);
        when(mockSharedPreferences.getBool('crash_reporting_consent'))
            .thenReturn(true);

        await userConsentService.setCrashReportingConsent(true);

        expect(userConsentService.hasCrashReportingConsent, true);
        verify(mockSharedPreferences.setBool('crash_reporting_consent', true)).called(1);
      });
    });

    group('Consent Banner Management', () {
      test('should check if consent banner should be shown', () {
        when(mockSharedPreferences.getBool(any)).thenReturn(null);

        expect(userConsentService.shouldShowConsentBanner, true);
      });

      test('should not show banner if consents are given', () {
        when(mockSharedPreferences.getBool('analytics_consent')).thenReturn(true);
        when(mockSharedPreferences.getBool('functional_consent')).thenReturn(true);
        when(mockSharedPreferences.getBool('data_processing_consent')).thenReturn(true);

        expect(userConsentService.shouldShowConsentBanner, false);
      });

      test('should dismiss consent banner', () async {
        when(mockSharedPreferences.setBool(any, any))
            .thenAnswer((_) async => true);

        await userConsentService.dismissConsentBanner();

        verify(mockSharedPreferences.setBool('consent_banner_dismissed', true)).called(1);
      });

      test('should check if banner was dismissed', () {
        when(mockSharedPreferences.getBool('consent_banner_dismissed'))
            .thenReturn(true);

        expect(userConsentService.isConsentBannerDismissed, true);
      });
    });

    group('Consent Audit Trail', () {
      test('should record consent changes', () async {
        when(mockSharedPreferences.setStringList(any, any))
            .thenAnswer((_) async => true);
        when(mockSharedPreferences.getStringList('consent_audit_trail'))
            .thenReturn([]);

        await userConsentService.recordConsentChange(
          'analytics_consent', 
          true, 
          DateTime.now()
        );

        verify(mockSharedPreferences.setStringList('consent_audit_trail', any)).called(1);
      });

      test('should get consent audit trail', () {
        const auditEntry = '2024-01-15T10:30:00.000|analytics_consent|true';
        when(mockSharedPreferences.getStringList('consent_audit_trail'))
            .thenReturn([auditEntry]);

        final auditTrail = userConsentService.consentAuditTrail;

        expect(auditTrail.length, 1);
        expect(auditTrail[0].consentType, 'analytics_consent');
        expect(auditTrail[0].value, true);
        expect(auditTrail[0].timestamp, DateTime(2024, 1, 15, 10, 30));
      });

      test('should limit audit trail size', () async {
        // Create a large audit trail
        final largeAuditTrail = List.generate(200, (index) => 
          '2024-01-${(index % 30) + 1}T10:30:00.000|analytics_consent|true'
        );

        when(mockSharedPreferences.getStringList('consent_audit_trail'))
            .thenReturn(largeAuditTrail);
        when(mockSharedPreferences.setStringList(any, any))
            .thenAnswer((_) async => true);

        await userConsentService.recordConsentChange(
          'marketing_consent', 
          false, 
          DateTime.now()
        );

        // Verify that the audit trail is limited to 100 entries
        final captured = verify(mockSharedPreferences.setStringList(
          'consent_audit_trail', 
          captureAny
        )).captured;

        expect(captured[0].length, lessThanOrEqualTo(100));
      });
    });

    group('Regional Compliance', () {
      test('should set user region for compliance', () async {
        when(mockSharedPreferences.setString(any, any))
            .thenAnswer((_) async => true);

        await userConsentService.setUserRegion('EU');

        verify(mockSharedPreferences.setString('user_region', 'EU')).called(1);
      });

      test('should get user region', () {
        when(mockSharedPreferences.getString('user_region'))
            .thenReturn('US');

        expect(userConsentService.userRegion, 'US');
      });

      test('should check if GDPR applies', () {
        when(mockSharedPreferences.getString('user_region'))
            .thenReturn('EU');

        expect(userConsentService.isGDPRApplicable, true);
      });

      test('should check if CCPA applies', () {
        when(mockSharedPreferences.getString('user_region'))
            .thenReturn('US');

        expect(userConsentService.isCCPAApplicable, true);
      });

      test('should get required consents for region', () {
        when(mockSharedPreferences.getString('user_region'))
            .thenReturn('EU');

        final requiredConsents = userConsentService.requiredConsentsForRegion;

        expect(requiredConsents, contains('analytics'));
        expect(requiredConsents, contains('marketing'));
        expect(requiredConsents, contains('functional'));
        expect(requiredConsents, contains('data_processing'));
      });
    });

    group('Error Handling', () {
      test('should handle SharedPreferences write errors gracefully', () async {
        when(mockSharedPreferences.setBool(any, any))
            .thenThrow(Exception('Storage error'));

        expect(() async => await userConsentService.setAnalyticsConsent(true),
               returnsNormally);
      });

      test('should handle SharedPreferences read errors gracefully', () {
        when(mockSharedPreferences.getBool(any))
            .thenThrow(Exception('Read error'));

        expect(() => userConsentService.hasAnalyticsConsent, returnsNormally);
        expect(userConsentService.hasAnalyticsConsent, false);
      });

      test('should handle corrupted consent data', () {
        when(mockSharedPreferences.getString('consent_timestamp'))
            .thenReturn('invalid_timestamp');

        expect(userConsentService.consentTimestamp, null);
        expect(userConsentService.isConsentExpired, true);
      });

      test('should handle corrupted audit trail data', () {
        when(mockSharedPreferences.getStringList('consent_audit_trail'))
            .thenReturn(['invalid_audit_entry']);

        final auditTrail = userConsentService.consentAuditTrail;
        expect(auditTrail, isEmpty);
      });
    });

    group('Data Minimization', () {
      test('should only store necessary consent data', () async {
        when(mockSharedPreferences.setBool(any, any))
            .thenAnswer((_) async => true);

        await userConsentService.setAnalyticsConsent(true);

        // Verify that only the specific consent is stored
        verify(mockSharedPreferences.setBool('analytics_consent', true)).called(1);
        verifyNever(mockSharedPreferences.setString(any, any));
      });

      test('should provide minimal consent data export', () {
        when(mockSharedPreferences.getBool('analytics_consent')).thenReturn(true);
        when(mockSharedPreferences.getBool('marketing_consent')).thenReturn(false);
        when(mockSharedPreferences.getString('consent_timestamp'))
            .thenReturn(DateTime.now().toIso8601String());

        final consentData = userConsentService.exportConsentData();

        expect(consentData, contains('analytics_consent'));
        expect(consentData, contains('marketing_consent'));
        expect(consentData, contains('consent_timestamp'));
        expect(consentData.length, lessThanOrEqualTo(10)); // Minimal data
      });
    });

    group('Performance Tests', () {
      test('should handle multiple rapid consent changes efficiently', () async {
        when(mockSharedPreferences.setBool(any, any))
            .thenAnswer((_) async => true);

        // Simulate rapid consent changes
        for (var i = 0; i < 100; i++) {
          await userConsentService.setAnalyticsConsent(i % 2 == 0);
        }

        // Should complete without issues
        verify(mockSharedPreferences.setBool('analytics_consent', any)).called(100);
      });

      test('should handle large audit trail efficiently', () {
        final largeAuditTrail = List.generate(1000, (index) => 
          '2024-01-01T10:30:00.000|analytics_consent|true'
        );

        when(mockSharedPreferences.getStringList('consent_audit_trail'))
            .thenReturn(largeAuditTrail);

        final startTime = DateTime.now();
        final auditTrail = userConsentService.consentAuditTrail;
        final endTime = DateTime.now();

        // Should process quickly (under 1 second)
        expect(endTime.difference(startTime).inMilliseconds, lessThan(1000));
        expect(auditTrail, isNotEmpty);
      });
    });
  });
}
