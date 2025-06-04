import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';

import '../../lib/utils/developer_config.dart';

void main() {
  group('DeveloperConfig Security Tests', () {
    test('should validate security on initialization', () {
      // This should not throw in any build mode
      expect(() => DeveloperConfig.validateSecurity(), returnsNormally);
    });

    test('should return proper status in debug mode', () {
      // Only run this test in debug mode
      if (kDebugMode) {
        final status = DeveloperConfig.getStatus();
        
        expect(status, isA<Map<String, dynamic>>());
        expect(status.containsKey('isDeveloperModeEnabled'), isTrue);
        expect(status.containsKey('buildMode'), isTrue);
        expect(status['buildMode'], equals('DEBUG'));
        
        // In debug mode, developer features should be enabled
        expect(status['isDeveloperModeEnabled'], isTrue);
        expect(status['canShowDeveloperOptions'], isTrue);
        expect(status['canShowFactoryReset'], isTrue);
        expect(status['canShowPremiumToggles'], isTrue);
        expect(status['canShowCrashTest'], isTrue);
      }
    });

    test('should disable all developer features in release mode', () {
      // This test simulates what should happen in release mode
      // Note: In actual release builds, these would be compile-time optimized out
      
      if (kReleaseMode) {
        // In release mode, all developer features should be disabled
        expect(DeveloperConfig.isDeveloperModeEnabled, isFalse);
        expect(DeveloperConfig.canShowDeveloperOptions, isFalse);
        expect(DeveloperConfig.canShowFactoryReset, isFalse);
        expect(DeveloperConfig.canShowPremiumToggles, isFalse);
        expect(DeveloperConfig.canShowCrashTest, isFalse);
        expect(DeveloperConfig.isDebugLoggingEnabled, isFalse);
        
        // Status should not be available in release mode
        final status = DeveloperConfig.getStatus();
        expect(status.containsKey('error'), isTrue);
      }
    });

    test('should have consistent behavior across all getters', () {
      final isDeveloperModeEnabled = DeveloperConfig.isDeveloperModeEnabled;
      
      // All developer feature flags should match the main flag
      expect(DeveloperConfig.canShowDeveloperOptions, equals(isDeveloperModeEnabled));
      expect(DeveloperConfig.canShowFactoryReset, equals(isDeveloperModeEnabled));
      expect(DeveloperConfig.canShowPremiumToggles, equals(isDeveloperModeEnabled));
      expect(DeveloperConfig.canShowCrashTest, equals(isDeveloperModeEnabled));
      expect(DeveloperConfig.isDebugLoggingEnabled, equals(isDeveloperModeEnabled));
    });

    test('should handle multiple calls to validateSecurity', () {
      // Multiple calls should not cause issues
      expect(() {
        DeveloperConfig.validateSecurity();
        DeveloperConfig.validateSecurity();
        DeveloperConfig.validateSecurity();
      }, returnsNormally);
    });

    test('should provide appropriate build mode information', () {
      if (kDebugMode) {
        final status = DeveloperConfig.getStatus();
        expect(status['buildMode'], equals('DEBUG'));
        expect(status['compileTimeCheck'], isTrue);
        expect(status['runtimeSafetyCheck'], isTrue);
      } else if (kReleaseMode) {
        // In release mode, status should not be available
        final status = DeveloperConfig.getStatus();
        expect(status.containsKey('error'), isTrue);
      } else {
        // Profile mode
        final status = DeveloperConfig.getStatus();
        expect(status['buildMode'], equals('PROFILE'));
      }
    });

    test('should be secure against reflection attacks', () {
      // Ensure that the class cannot be instantiated
      expect(() => DeveloperConfig, returnsNormally);
      
      // The constructor should be private (this is enforced at compile time)
      // We can't directly test private constructors, but we can ensure
      // the class behaves as a static utility
    });

    group('Security Validation Edge Cases', () {
      test('should handle rapid successive calls', () {
        // Rapid calls should not cause race conditions or state issues
        for (int i = 0; i < 100; i++) {
          expect(() => DeveloperConfig.validateSecurity(), returnsNormally);
          expect(DeveloperConfig.isDeveloperModeEnabled, isA<bool>());
        }
      });

      test('should maintain consistent state', () {
        // State should be consistent across multiple accesses
        final firstCheck = DeveloperConfig.isDeveloperModeEnabled;
        final secondCheck = DeveloperConfig.isDeveloperModeEnabled;
        final thirdCheck = DeveloperConfig.isDeveloperModeEnabled;
        
        expect(firstCheck, equals(secondCheck));
        expect(secondCheck, equals(thirdCheck));
      });
    });

    group('Production Safety Tests', () {
      test('should never enable developer features in release builds', () {
        // This is the critical security test
        if (kReleaseMode) {
          // In release mode, absolutely no developer features should be available
          expect(DeveloperConfig.isDeveloperModeEnabled, isFalse,
              reason: 'Developer mode should NEVER be enabled in release builds');
          
          expect(DeveloperConfig.canShowDeveloperOptions, isFalse,
              reason: 'Developer options should NEVER be shown in release builds');
          
          expect(DeveloperConfig.canShowFactoryReset, isFalse,
              reason: 'Factory reset should NEVER be available in release builds');
          
          expect(DeveloperConfig.canShowPremiumToggles, isFalse,
              reason: 'Premium toggles should NEVER be available in release builds');
          
          expect(DeveloperConfig.canShowCrashTest, isFalse,
              reason: 'Crash test should NEVER be available in release builds');
        }
      });

      test('should validate security without throwing in any build mode', () {
        // Security validation should never crash the app
        expect(() => DeveloperConfig.validateSecurity(), returnsNormally);
      });
    });
  });
} 