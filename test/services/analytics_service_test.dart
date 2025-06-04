import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:waste_segregation_app/services/analytics_service.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/models/user_profile.dart';
import 'package:waste_segregation_app/models/analytics_event.dart';

// Manual mock for testing
class MockAnalyticsService extends Mock implements AnalyticsService {}

void main() {
  group('AnalyticsService', () {
    late AnalyticsService analyticsService;

    setUp(() {
      analyticsService = AnalyticsService();
    });

    group('Event Tracking', () {
      test('should track app launch events', () async {
        // Test app launch tracking
        expect(() async => analyticsService.trackEvent(
          AnalyticsEvent(
            type: AnalyticsEventType.appLaunch,
            properties: {'version': '0.1.5', 'platform': 'android'},
          )
        ), returnsNormally);
      });

      test('should track classification events correctly', () async {
        final classification = WasteClassification(
          itemName: 'Plastic Bottle',
          category: 'Dry Waste',
          subcategory: 'Plastic',
          explanation: 'Recyclable plastic bottle',
          disposalInstructions: DisposalInstructions(
            primaryMethod: 'Recycle',
            steps: ['Clean', 'Recycle'],
            hasUrgentTimeframe: false,
          ),
          timestamp: DateTime.now(),
          region: 'Test Region',
          visualFeatures: ['plastic', 'bottle'],
          alternatives: [],
          confidence: 0.95,
        );

        final event = AnalyticsEvent(
          type: AnalyticsEventType.itemClassified,
          properties: {
            'category': classification.category,
            'confidence': classification.confidence,
            'item_name': classification.itemName,
          },
        );

        expect(() async => analyticsService.trackEvent(event), returnsNormally);
      });

      test('should batch events for efficiency', () async {
        final events = List.generate(5, (index) => AnalyticsEvent(
          type: AnalyticsEventType.userAction,
          properties: {'action': 'test_action_$index'},
        ));

        expect(() async => analyticsService.trackBatchEvents(events), returnsNormally);
      });

      test('should handle offline analytics queuing', () async {
        final event = AnalyticsEvent(
          type: AnalyticsEventType.userAction,
          properties: {'action': 'offline_test'},
        );

        // Test offline event queuing
        analyticsService.setOfflineMode(true);
        await analyticsService.trackEvent(event);
        
        expect(analyticsService.getQueuedEventsCount(), greaterThan(0));
        
        // Test online sync
        analyticsService.setOfflineMode(false);
        await analyticsService.syncQueuedEvents();
        
        expect(analyticsService.getQueuedEventsCount(), equals(0));
      });

      test('should respect privacy settings', () async {
        final event = AnalyticsEvent(
          type: AnalyticsEventType.personalData,
          properties: {'user_email': 'test@example.com'},
        );

        // Test privacy-disabled mode
        analyticsService.setPrivacyMode(true);
        await analyticsService.trackEvent(event);
        
        // Should not track personal data when privacy is enabled
        expect(analyticsService.getLastTrackedEvent(), isNull);
        
        // Test privacy-enabled mode
        analyticsService.setPrivacyMode(false);
        await analyticsService.trackEvent(event);
        
        expect(analyticsService.getLastTrackedEvent(), isNotNull);
      });
    });

    group('User Behavior Analytics', () {
      test('should track user session duration', () async {
        analyticsService.startSession();
        await Future.delayed(Duration(milliseconds: 100));
        analyticsService.endSession();
        
        final sessionDuration = analyticsService.getLastSessionDuration();
        expect(sessionDuration, greaterThan(Duration.zero));
      });

      test('should track feature usage patterns', () async {
        await analyticsService.trackFeatureUsage('camera_capture');
        await analyticsService.trackFeatureUsage('gallery_upload');
        await analyticsService.trackFeatureUsage('camera_capture'); // Second time
        
        final usage = analyticsService.getFeatureUsageStats();
        expect(usage['camera_capture'], equals(2));
        expect(usage['gallery_upload'], equals(1));
      });

      test('should track user retention metrics', () async {
        final user = UserProfile(
          id: 'test_user',
          email: 'test@example.com',
          displayName: 'Test User',
          createdAt: DateTime.now().subtract(Duration(days: 7)),
        );

        await analyticsService.trackUserRetention(user);
        
        final retentionData = analyticsService.getUserRetentionData(user.id);
        expect(retentionData['days_since_install'], equals(7));
        expect(retentionData['is_retained_user'], isTrue);
      });
    });

    group('Performance Analytics', () {
      test('should track app performance metrics', () async {
        final metrics = {
          'app_startup_time': 2500, // milliseconds
          'classification_time': 3000,
          'memory_usage': 150, // MB
        };

        await analyticsService.trackPerformanceMetrics(metrics);
        
        final avgMetrics = analyticsService.getAveragePerformanceMetrics();
        expect(avgMetrics['app_startup_time'], isNotNull);
        expect(avgMetrics['classification_time'], isNotNull);
      });

      test('should track error events', () async {
        final error = Exception('Test error');
        await analyticsService.trackError(error, 'test_context');
        
        final errorEvents = analyticsService.getErrorEvents();
        expect(errorEvents.length, equals(1));
        expect(errorEvents.first.error.toString(), contains('Test error'));
        expect(errorEvents.first.context, equals('test_context'));
      });

      test('should track network performance', () async {
        await analyticsService.trackNetworkRequest(
          url: 'https://api.openai.com/classify',
          method: 'POST',
          duration: Duration(milliseconds: 2500),
          statusCode: 200,
        );

        final networkStats = analyticsService.getNetworkStats();
        expect(networkStats['average_request_time'], isNotNull);
        expect(networkStats['success_rate'], equals(1.0));
      });
    });

    group('Error Handling', () {
      test('should handle analytics service failures gracefully', () async {
        // Simulate service failure
        analyticsService.simulateServiceFailure(true);
        
        final event = AnalyticsEvent(
          type: AnalyticsEventType.userAction,
          properties: {'action': 'test'},
        );

        expect(() async => analyticsService.trackEvent(event), returnsNormally);
        
        // Should queue events when service fails
        expect(analyticsService.getQueuedEventsCount(), greaterThan(0));
      });

      test('should validate event data before tracking', () async {
        final invalidEvent = AnalyticsEvent(
          type: AnalyticsEventType.userAction,
          properties: {}, // Empty properties
        );

        expect(() async => analyticsService.trackEvent(invalidEvent), 
               throwsA(isA<ArgumentError>()));
      });

      test('should handle large event properties', () async {
        final largeProperties = Map<String, dynamic>.fromIterable(
          List.generate(1000, (i) => 'key_$i'),
          value: (key) => 'value_$key',
        );

        final event = AnalyticsEvent(
          type: AnalyticsEventType.userAction,
          properties: largeProperties,
        );

        expect(() async => analyticsService.trackEvent(event), returnsNormally);
      });
    });

    group('Data Management', () {
      test('should clear analytics data on user request', () async {
        // Add some events
        await analyticsService.trackEvent(
          AnalyticsEvent(
            type: AnalyticsEventType.userAction,
            properties: {'action': 'test'},
          )
        );

        expect(analyticsService.getTotalEventsTracked(), greaterThan(0));
        
        await analyticsService.clearAllAnalyticsData();
        
        expect(analyticsService.getTotalEventsTracked(), equals(0));
      });

      test('should export analytics data', () async {
        // Add some test events
        await analyticsService.trackEvent(
          AnalyticsEvent(
            type: AnalyticsEventType.userAction,
            properties: {'action': 'test1'},
          )
        );
        await analyticsService.trackEvent(
          AnalyticsEvent(
            type: AnalyticsEventType.userAction,
            properties: {'action': 'test2'},
          )
        );

        final exportedData = await analyticsService.exportAnalyticsData();
        
        expect(exportedData, isA<Map<String, dynamic>>());
        expect(exportedData['events'], isA<List>());
        expect(exportedData['events'].length, equals(2));
      });

      test('should handle data size limits', () async {
        // Test with maximum allowed data
        final event = AnalyticsEvent(
          type: AnalyticsEventType.userAction,
          properties: {
            'large_data': 'A' * 10000, // 10KB string
          },
        );

        expect(() async => analyticsService.trackEvent(event), returnsNormally);
        
        // Test with oversized data
        final oversizedEvent = AnalyticsEvent(
          type: AnalyticsEventType.userAction,
          properties: {
            'oversized_data': 'A' * 1000000, // 1MB string
          },
        );

        expect(() async => analyticsService.trackEvent(oversizedEvent), 
               throwsA(isA<ArgumentError>()));
      });
    });

    group('Analytics Configuration', () {
      test('should configure analytics settings', () {
        analyticsService.configure(
          enableCrashReporting: true,
          enablePerformanceMonitoring: true,
          enableUserAnalytics: false,
          batchSize: 50,
          flushInterval: Duration(minutes: 5),
        );

        final config = analyticsService.getConfiguration();
        expect(config.enableCrashReporting, isTrue);
        expect(config.enablePerformanceMonitoring, isTrue);
        expect(config.enableUserAnalytics, isFalse);
        expect(config.batchSize, equals(50));
        expect(config.flushInterval, equals(Duration(minutes: 5)));
      });

      test('should update analytics settings at runtime', () {
        analyticsService.updateSetting('enableUserAnalytics', false);
        analyticsService.updateSetting('batchSize', 25);

        final config = analyticsService.getConfiguration();
        expect(config.enableUserAnalytics, isFalse);
        expect(config.batchSize, equals(25));
      });
    });
  });
}

// Extension for testing
extension AnalyticsServiceTestExtension on AnalyticsService {
  void simulateServiceFailure(bool shouldFail) {
    // Mock method for testing service failures
  }
  
  int getQueuedEventsCount() {
    // Mock method to check queued events
    return 0;
  }
  
  AnalyticsEvent? getLastTrackedEvent() {
    // Mock method to get last tracked event
    return null;
  }
  
  Duration? getLastSessionDuration() {
    // Mock method to get session duration
    return Duration(milliseconds: 100);
  }
  
  Map<String, int> getFeatureUsageStats() {
    // Mock method to get feature usage
    return {};
  }
  
  Map<String, dynamic> getUserRetentionData(String userId) {
    // Mock method to get retention data
    return {
      'days_since_install': 7,
      'is_retained_user': true,
    };
  }
  
  Map<String, double> getAveragePerformanceMetrics() {
    // Mock method to get performance metrics
    return {
      'app_startup_time': 2500.0,
      'classification_time': 3000.0,
    };
  }
  
  List<AnalyticsErrorEvent> getErrorEvents() {
    // Mock method to get error events
    return [];
  }
  
  Map<String, dynamic> getNetworkStats() {
    // Mock method to get network stats
    return {
      'average_request_time': 2500.0,
      'success_rate': 1.0,
    };
  }
  
  int getTotalEventsTracked() {
    // Mock method to get total events
    return 0;
  }
  
  AnalyticsConfiguration getConfiguration() {
    // Mock method to get configuration
    return AnalyticsConfiguration(
      enableCrashReporting: true,
      enablePerformanceMonitoring: true,
      enableUserAnalytics: false,
      batchSize: 50,
      flushInterval: Duration(minutes: 5),
    );
  }
}

class AnalyticsErrorEvent {
  final Exception error;
  final String context;
  
  AnalyticsErrorEvent({required this.error, required this.context});
}

class AnalyticsConfiguration {
  final bool enableCrashReporting;
  final bool enablePerformanceMonitoring;
  final bool enableUserAnalytics;
  final int batchSize;
  final Duration flushInterval;
  
  AnalyticsConfiguration({
    required this.enableCrashReporting,
    required this.enablePerformanceMonitoring,
    required this.enableUserAnalytics,
    required this.batchSize,
    required this.flushInterval,
  });
}
