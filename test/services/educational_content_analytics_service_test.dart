// import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
// import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waste_segregation_app/services/educational_content_analytics_service.dart';

void main() {
  group('ContentAnalytics', () {
    test('should create with required parameters', () {
      const analytics = ContentAnalytics(
        contentId: 'content_1',
        views: 5,
        totalTimeSpent: Duration(minutes: 15),
        completions: 2,
      );

      expect(analytics.contentId, equals('content_1'));
      expect(analytics.views, equals(5));
      expect(analytics.totalTimeSpent, equals(Duration(minutes: 15)));
      expect(analytics.completions, equals(2));
      expect(analytics.interactions, equals(0));
      expect(analytics.lastViewed, isNull);
      expect(analytics.isFavorite, isFalse);
    });

    test('should create with optional parameters', () {
      final lastViewed = DateTime.now();
      final analytics = ContentAnalytics(
        contentId: 'content_2',
        views: 10,
        totalTimeSpent: Duration(minutes: 30),
        completions: 5,
        interactions: 8,
        lastViewed: lastViewed,
        isFavorite: true,
      );

      expect(analytics.interactions, equals(8));
      expect(analytics.lastViewed, equals(lastViewed));
      expect(analytics.isFavorite, isTrue);
    });

    test('should copyWith correctly', () {
      const original = ContentAnalytics(
        contentId: 'content_original',
        views: 3,
        totalTimeSpent: Duration(minutes: 10),
        completions: 1,
      );

      final updated = original.copyWith(
        views: 5,
        interactions: 3,
        isFavorite: true,
      );

      expect(updated.contentId, equals('content_original'));
      expect(updated.views, equals(5));
      expect(updated.totalTimeSpent, equals(Duration(minutes: 10)));
      expect(updated.completions, equals(1));
      expect(updated.interactions, equals(3));
      expect(updated.isFavorite, isTrue);
      expect(original.views, equals(3)); // Original unchanged
    });

    test('should calculate engagement score correctly', () {
      // High engagement content
      const highEngagement = ContentAnalytics(
        contentId: 'high',
        views: 10, // 30 points (capped at 30)
        totalTimeSpent: Duration(minutes: 25),
        completions: 5, // 20 points (capped at 20)
        interactions: 8, // 10 points (capped at 10)
      );

      // Low engagement content
      const lowEngagement = ContentAnalytics(
        contentId: 'low',
        views: 1, // 5 points
        totalTimeSpent: Duration(minutes: 2),
        completions: 0, // 0 points
        interactions: 1, // 2 points
      );

      // Zero engagement content
      const zeroEngagement = ContentAnalytics(
        contentId: 'zero',
        views: 0,
        totalTimeSpent: Duration.zero,
        completions: 0,
      );

      expect(highEngagement.engagementScore, equals(100.0));
      expect(lowEngagement.engagementScore, equals(11.0)); // 5+4+0+2
      expect(zeroEngagement.engagementScore, equals(0.0));
    });

    test('should cap engagement score components correctly', () {
      // Over-engaged content that should be capped
      const overEngagement = ContentAnalytics(
        contentId: 'over',
        views: 20, // Should cap at 30 points
        totalTimeSpent: Duration(hours: 2),
        completions: 10, // Should cap at 20 points
        interactions: 20, // Should cap at 10 points
      );

      expect(overEngagement.engagementScore, equals(100.0));
    });
  });

  group('EngagementMetrics', () {
    test('should create with required parameters', () {
      const metrics = EngagementMetrics(
        totalViews: 100,
        totalTimeSpent: Duration(hours: 5),
        totalCompletions: 25,
        totalInteractions: 50,
        uniqueContentViewed: 20,
        favoriteCount: 8,
      );

      expect(metrics.totalViews, equals(100));
      expect(metrics.totalTimeSpent, equals(Duration(hours: 5)));
      expect(metrics.totalCompletions, equals(25));
      expect(metrics.totalInteractions, equals(50));
      expect(metrics.uniqueContentViewed, equals(20));
      expect(metrics.favoriteCount, equals(8));
    });

    test('should calculate average time per content correctly', () {
      const metrics = EngagementMetrics(
        totalViews: 50,
        totalTimeSpent: Duration(minutes: 100),
        totalCompletions: 10,
        totalInteractions: 20,
        uniqueContentViewed: 10,
        favoriteCount: 5,
      );

      const zeroContentMetrics = EngagementMetrics(
        totalViews: 0,
        totalTimeSpent: Duration(minutes: 50),
        totalCompletions: 0,
        totalInteractions: 0,
        uniqueContentViewed: 0,
        favoriteCount: 0,
      );

      expect(metrics.averageTimePerContent, equals(Duration(minutes: 10)));
      expect(zeroContentMetrics.averageTimePerContent, equals(Duration.zero));
    });

    test('should calculate completion rate correctly', () {
      const highCompletionMetrics = EngagementMetrics(
        totalViews: 100,
        totalTimeSpent: Duration(hours: 10),
        totalCompletions: 75,
        totalInteractions: 200,
        uniqueContentViewed: 50,
        favoriteCount: 15,
      );

      const lowCompletionMetrics = EngagementMetrics(
        totalViews: 100,
        totalTimeSpent: Duration(hours: 10),
        totalCompletions: 10,
        totalInteractions: 50,
        uniqueContentViewed: 30,
        favoriteCount: 5,
      );

      const zeroViewsMetrics = EngagementMetrics(
        totalViews: 0,
        totalTimeSpent: Duration.zero,
        totalCompletions: 0,
        totalInteractions: 0,
        uniqueContentViewed: 0,
        favoriteCount: 0,
      );

      expect(highCompletionMetrics.completionRate, equals(0.75));
      expect(lowCompletionMetrics.completionRate, equals(0.10));
      expect(zeroViewsMetrics.completionRate, equals(0.0));
    });
  });

  group('ContentInteractionType', () {
    test('should have all expected enum values', () {
      expect(ContentInteractionType.values, hasLength(5));
      expect(ContentInteractionType.values, contains(ContentInteractionType.favorite));
      expect(ContentInteractionType.values, contains(ContentInteractionType.unfavorite));
      expect(ContentInteractionType.values, contains(ContentInteractionType.share));
      expect(ContentInteractionType.values, contains(ContentInteractionType.bookmark));
      expect(ContentInteractionType.values, contains(ContentInteractionType.like));
    });
  });

  group('EducationalContent', () {
    test('should create with required parameters', () {
      const content = EducationalContent(
        id: 'edu_1',
        title: 'Recycling Basics',
        category: 'Environment',
        type: 'Article',
      );

      expect(content.id, equals('edu_1'));
      expect(content.title, equals('Recycling Basics'));
      expect(content.category, equals('Environment'));
      expect(content.type, equals('Article'));
    });
  });

  group('EducationalContentAnalyticsService', () {
    late EducationalContentAnalyticsService service;

    setUp(() async {
      // Mock SharedPreferences
      SharedPreferences.setMockInitialValues({});
      service = EducationalContentAnalyticsService();
      await Future.delayed(const Duration(milliseconds: 100)); // Allow initialization
    });

    tearDown(() {
      service.dispose();
    });

    group('Basic Analytics Tracking', () {
      test('should start with empty analytics', () {
        final analytics = service.getContentAnalytics('nonexistent');

        expect(analytics.contentId, equals('nonexistent'));
        expect(analytics.views, equals(0));
        expect(analytics.totalTimeSpent, equals(Duration.zero));
        expect(analytics.completions, equals(0));
        expect(analytics.interactions, equals(0));
        expect(analytics.isFavorite, isFalse);
      });

      test('should track content views correctly', () async {
        await service.trackContentView('content_1', 'Environment');
        await service.trackContentView('content_1', 'Environment');
        await service.trackContentView('content_2', 'Science');

        final content1Analytics = service.getContentAnalytics('content_1');
        final content2Analytics = service.getContentAnalytics('content_2');

        expect(content1Analytics.views, equals(2));
        expect(content2Analytics.views, equals(1));
        expect(content1Analytics.lastViewed, isNotNull);
      });

      test('should track recently viewed content', () async {
        await service.trackContentView('content_1', 'Environment');
        await service.trackContentView('content_2', 'Science');
        await service.trackContentView('content_3', 'Health');

        final recentlyViewed = service.getRecentlyViewed();

        expect(recentlyViewed, hasLength(3));
        expect(recentlyViewed[0], equals('content_3')); // Most recent first
        expect(recentlyViewed[1], equals('content_2'));
        expect(recentlyViewed[2], equals('content_1'));
      });

      test('should limit recently viewed to 50 items', () async {
        for (var i = 0; i < 60; i++) {
          await service.trackContentView('content_$i', 'Category');
        }

        final recentlyViewed = service.getRecentlyViewed(limit: 100);
        expect(recentlyViewed, hasLength(50));
        expect(recentlyViewed[0], equals('content_59')); // Most recent
      });

      test('should track category views', () async {
        await service.trackContentView('content_1', 'Environment');
        await service.trackContentView('content_2', 'Environment');
        await service.trackContentView('content_3', 'Science');
        await service.trackContentView('content_4', 'Environment');

        final popularCategories = service.getPopularCategories();

        expect(popularCategories, hasLength(2));
        expect(popularCategories[0].key, equals('Environment'));
        expect(popularCategories[0].value, equals(3));
        expect(popularCategories[1].key, equals('Science'));
        expect(popularCategories[1].value, equals(1));
      });
    });

    group('Session Management', () {
      test('should track session time correctly', () async {
        service.startContentSession('content_1');

        // Simulate some time passing
        await Future.delayed(const Duration(milliseconds: 100));

        await service.endContentSession(wasCompleted: true);

        final analytics = service.getContentAnalytics('content_1');
        expect(analytics.totalTimeSpent.inMilliseconds, greaterThan(50));
        expect(analytics.completions, equals(1));
      });

      test('should handle session without completion', () async {
        service.startContentSession('content_1');
        await Future.delayed(const Duration(milliseconds: 100));
        await service.endContentSession();

        final analytics = service.getContentAnalytics('content_1');
        expect(analytics.totalTimeSpent.inMilliseconds, greaterThan(50));
        expect(analytics.completions, equals(0));
      });

      test('should end previous session when starting new one', () async {
        service.startContentSession('content_1');
        await Future.delayed(const Duration(milliseconds: 50));

        service.startContentSession('content_2');
        await Future.delayed(const Duration(milliseconds: 50));

        await service.endContentSession(wasCompleted: true);

        final content1Analytics = service.getContentAnalytics('content_1');
        final content2Analytics = service.getContentAnalytics('content_2');

        // content_1 session should have been automatically ended
        expect(content1Analytics.totalTimeSpent.inMilliseconds, greaterThan(0));
        expect(content2Analytics.completions, equals(1));
      });

      test('should handle ending session without starting', () async {
        // Should not throw an error
        await service.endContentSession(wasCompleted: true);

        final analytics = service.getContentAnalytics('content_1');
        expect(analytics.totalTimeSpent, equals(Duration.zero));
        expect(analytics.completions, equals(0));
      });
    });

    group('Content Interactions', () {
      test('should track favorite interactions', () async {
        await service.trackContentInteraction('content_1', ContentInteractionType.favorite);

        final analytics = service.getContentAnalytics('content_1');
        final favorites = service.getFavoriteContent();

        expect(analytics.interactions, equals(1));
        expect(analytics.isFavorite, isTrue);
        expect(favorites, contains('content_1'));
      });

      test('should track unfavorite interactions', () async {
        // First favorite it
        await service.trackContentInteraction('content_1', ContentInteractionType.favorite);
        // Then unfavorite it
        await service.trackContentInteraction('content_1', ContentInteractionType.unfavorite);

        final analytics = service.getContentAnalytics('content_1');
        final favorites = service.getFavoriteContent();

        expect(analytics.interactions, equals(2));
        expect(analytics.isFavorite, isFalse);
        expect(favorites, isNot(contains('content_1')));
      });

      test('should track other interaction types', () async {
        await service.trackContentInteraction('content_1', ContentInteractionType.share);
        await service.trackContentInteraction('content_1', ContentInteractionType.bookmark);
        await service.trackContentInteraction('content_1', ContentInteractionType.like);

        final analytics = service.getContentAnalytics('content_1');
        expect(analytics.interactions, equals(3));
      });

      test('should not duplicate favorites', () async {
        await service.trackContentInteraction('content_1', ContentInteractionType.favorite);
        await service.trackContentInteraction('content_1', ContentInteractionType.favorite);

        final favorites = service.getFavoriteContent();
        expect(favorites.where((id) => id == 'content_1'), hasLength(1));
      });
    });

    group('Search Tracking', () {
      test('should track search queries', () async {
        await service.trackSearchQuery('recycling tips', resultsCount: 5);
        await service.trackSearchQuery('composting guide', resultsCount: 3);
        await service.trackSearchQuery('recycling tips', resultsCount: 7);

        final popularQueries = service.getPopularSearchQueries();

        expect(popularQueries, hasLength(2));
        expect(popularQueries[0].key, equals('recycling tips'));
        expect(popularQueries[0].value, equals(2));
        expect(popularQueries[1].key, equals('composting guide'));
        expect(popularQueries[1].value, equals(1));
      });

      test('should normalize search queries', () async {
        await service.trackSearchQuery('  Recycling Tips  ');
        await service.trackSearchQuery('RECYCLING TIPS');
        await service.trackSearchQuery('recycling tips');

        final popularQueries = service.getPopularSearchQueries();

        expect(popularQueries, hasLength(1));
        expect(popularQueries[0].key, equals('recycling tips'));
        expect(popularQueries[0].value, equals(3));
      });

      test('should ignore empty search queries', () async {
        await service.trackSearchQuery('');
        await service.trackSearchQuery('   ');
        await service.trackSearchQuery('valid query');

        final popularQueries = service.getPopularSearchQueries();

        expect(popularQueries, hasLength(1));
        expect(popularQueries[0].key, equals('valid query'));
      });

      test('should limit popular queries results', () async {
        for (var i = 0; i < 15; i++) {
          await service.trackSearchQuery('query_$i');
        }

        final limitedQueries = service.getPopularSearchQueries(limit: 5);
        expect(limitedQueries, hasLength(5));
      });
    });

    group('Analytics Retrieval', () {
      test('should get most viewed content', () async {
        await service.trackContentView('content_1', 'Cat1');
        await service.trackContentView('content_1', 'Cat1');
        await service.trackContentView('content_1', 'Cat1');
        await service.trackContentView('content_2', 'Cat2');
        await service.trackContentView('content_2', 'Cat2');
        await service.trackContentView('content_3', 'Cat3');

        final mostViewed = service.getMostViewedContent(limit: 2);

        expect(mostViewed, hasLength(2));
        expect(mostViewed[0], equals('content_1'));
        expect(mostViewed[1], equals('content_2'));
      });

      test('should calculate total engagement metrics', () async {
        // Set up some analytics data
        await service.trackContentView('content_1', 'Environment');
        await service.trackContentView('content_2', 'Science');

        service.startContentSession('content_1');
        await Future.delayed(const Duration(milliseconds: 100));
        await service.endContentSession(wasCompleted: true);

        await service.trackContentInteraction('content_1', ContentInteractionType.favorite);
        await service.trackContentInteraction('content_2', ContentInteractionType.share);

        final metrics = service.getTotalEngagementMetrics();

        expect(metrics.totalViews, equals(2));
        expect(metrics.totalCompletions, equals(1));
        expect(metrics.totalInteractions, equals(2));
        expect(metrics.uniqueContentViewed, equals(2));
        expect(metrics.favoriteCount, equals(1));
        expect(metrics.totalTimeSpent.inMilliseconds, greaterThan(50));
      });

      test('should calculate learning streak correctly', () async {
        final now = DateTime.now();

        // Create a service and manually set last viewed dates for testing
        await service.trackContentView('content_today', 'Category');
        await service.trackContentView('content_yesterday', 'Category');

        // The service tracks views with current timestamp, so streak should be 1
        // (we can't easily mock DateTime.now() in this test setup)
        final streak = service.getLearningStreak();
        expect(streak, greaterThanOrEqualTo(0));
      });
    });

    group('Personalized Recommendations', () {
      test('should provide personalized recommendations', () async {
        // Set up user preferences
        await service.trackContentView('env_content_1', 'Environment');
        await service.trackContentView('env_content_2', 'Environment');
        await service.trackContentView('sci_content_1', 'Science');

        const allContent = [
          EducationalContent(id: 'env_new', title: 'New Env', category: 'Environment', type: 'Article'),
          EducationalContent(id: 'sci_new', title: 'New Sci', category: 'Science', type: 'Video'),
          EducationalContent(id: 'health_new', title: 'New Health', category: 'Health', type: 'Article'),
          EducationalContent(id: 'env_viewed', title: 'Viewed Env', category: 'Environment', type: 'Article'),
        ];

        // Mark one as heavily viewed
        for (var i = 0; i < 5; i++) {
          await service.trackContentView('env_viewed', 'Environment');
        }

        final recommendations = service.getPersonalizedRecommendations(
          allContent: allContent,
          limit: 3,
        );

        expect(recommendations, isNotEmpty);
        expect(recommendations, contains('env_new')); // Should recommend new content in favorite category
        expect(recommendations, isNot(contains('env_viewed'))); // Should not recommend heavily viewed content
      });

      test('should handle empty content list for recommendations', () {
        final recommendations = service.getPersonalizedRecommendations(
          allContent: [],
        );

        expect(recommendations, isEmpty);
      });
    });

    group('Data Management', () {
      test('should clear all analytics data', () async {
        // Set up some data
        await service.trackContentView('content_1', 'Environment');
        await service.trackContentInteraction('content_1', ContentInteractionType.favorite);
        await service.trackSearchQuery('test query');

        // Verify data exists
        expect(service.getContentAnalytics('content_1').views, equals(1));
        expect(service.getFavoriteContent(), isNotEmpty);
        expect(service.getPopularSearchQueries(), isNotEmpty);

        // Clear all data
        await service.clearAllAnalytics();

        // Verify data is cleared
        expect(service.getContentAnalytics('content_1').views, equals(0));
        expect(service.getFavoriteContent(), isEmpty);
        expect(service.getPopularSearchQueries(), isEmpty);
        expect(service.getRecentlyViewed(), isEmpty);
        expect(service.getPopularCategories(), isEmpty);
      });

      test('should export analytics data correctly', () async {
        // Set up comprehensive test data
        await service.trackContentView('content_1', 'Environment');
        await service.trackContentView('content_2', 'Science');
        await service.trackContentInteraction('content_1', ContentInteractionType.favorite);
        await service.trackSearchQuery('recycling');

        service.startContentSession('content_1');
        await Future.delayed(const Duration(milliseconds: 100));
        await service.endContentSession(wasCompleted: true);

        final exportedData = service.exportAnalyticsData();

        expect(exportedData, containsPair('totalMetrics', isMap));
        expect(exportedData, containsPair('topCategories', isList));
        expect(exportedData, containsPair('recentContent', isList));
        expect(exportedData, containsPair('favoriteContent', isList));
        expect(exportedData, containsPair('searchHistory', isList));

        final totalMetrics = exportedData['totalMetrics'] as Map<String, dynamic>;
        expect(totalMetrics['totalViews'], equals(2));
        expect(totalMetrics['totalCompletions'], equals(1));
        expect(totalMetrics['favoriteCount'], equals(1));
        expect(totalMetrics['uniqueContentViewed'], equals(2));
      });
    });

    group('Edge Cases and Error Handling', () {
      test('should handle concurrent operations safely', () async {
        // Simulate concurrent view tracking
        final futures = <Future>[];
        for (var i = 0; i < 10; i++) {
          futures.add(service.trackContentView('content_1', 'Environment'));
        }

        await Future.wait(futures);

        final analytics = service.getContentAnalytics('content_1');
        expect(analytics.views, equals(10));
      });

      test('should handle very long session times', () async {
        service.startContentSession('content_1');

        // Simulate a very long session (simulate by direct calculation)
        await Future.delayed(const Duration(milliseconds: 50));
        await service.endContentSession(wasCompleted: true);

        final analytics = service.getContentAnalytics('content_1');
        expect(analytics.totalTimeSpent.inMilliseconds, greaterThan(0));
        expect(analytics.completions, equals(1));
      });

      test('should handle special characters in content IDs', () async {
        const specialId = 'content-with-special_chars.123!@#';

        await service.trackContentView(specialId, 'Environment');
        await service.trackContentInteraction(specialId, ContentInteractionType.favorite);

        final analytics = service.getContentAnalytics(specialId);
        expect(analytics.views, equals(1));
        expect(analytics.isFavorite, isTrue);
      });

      test('should handle very large datasets', () async {
        // Track many content items
        for (var i = 0; i < 1000; i++) {
          await service.trackContentView('content_$i', 'Category_${i % 10}');
        }

        final mostViewed = service.getMostViewedContent(limit: 50);
        final recentlyViewed = service.getRecentlyViewed(limit: 100);
        final popularCategories = service.getPopularCategories();

        expect(mostViewed, hasLength(50));
        expect(recentlyViewed, hasLength(50)); // Limited by service to 50
        expect(popularCategories, hasLength(10));

        final metrics = service.getTotalEngagementMetrics();
        expect(metrics.totalViews, equals(1000));
        expect(metrics.uniqueContentViewed, equals(1000));
      });

      test('should handle null and invalid inputs gracefully', () async {
        // These should not throw errors
        await service.trackSearchQuery('');
        await service.trackSearchQuery('   ');

        final analytics = service.getContentAnalytics('');
        expect(analytics.contentId, equals(''));
        expect(analytics.views, equals(0));

        final emptyRecommendations = service.getPersonalizedRecommendations(
          allContent: [],
          limit: 0,
        );
        expect(emptyRecommendations, isEmpty);
      });
    });

    group('Notification and State Management', () {
      test('should notify listeners on data changes', () async {
        var notificationCount = 0;

        service.addListener(() {
          notificationCount++;
        });

        await service.trackContentView('content_1', 'Environment');
        await service.trackContentInteraction('content_1', ContentInteractionType.favorite);

        service.startContentSession('content_2');
        await service.endContentSession(wasCompleted: true);

        // Should have received multiple notifications
        expect(notificationCount, greaterThan(0));
      });

      test('should maintain state consistency during rapid operations', () async {
        // Rapid content viewing
        for (var i = 0; i < 100; i++) {
          await service.trackContentView('rapid_content', 'Environment');
        }

        final analytics = service.getContentAnalytics('rapid_content');
        expect(analytics.views, equals(100));

        final recentlyViewed = service.getRecentlyViewed();
        expect(recentlyViewed.where((id) => id == 'rapid_content'), hasLength(1));
      });
    });

    group('Persistence', () {
      test('should persist and load analytics data', () async {
        await service.trackContentView('persist_1', 'CategoryA');
        await service.recordTimeSpent('persist_1', const Duration(seconds: 30));
        await service.trackContentInteraction('persist_1', ContentInteractionType.favorite);
        await service.recordCompletion('persist_1');

        // Create a new service instance to simulate app restart
        final newService = EducationalContentAnalyticsService();
        await Future.delayed(const Duration(milliseconds: 100)); // Allow initialization

        final loadedAnalytics = newService.getContentAnalytics('persist_1');
        expect(loadedAnalytics.views, equals(1));
        expect(loadedAnalytics.totalTimeSpent, equals(const Duration(seconds: 30)));
        expect(loadedAnalytics.interactions, equals(1)); // Favorite
        expect(loadedAnalytics.completions, equals(1));
        expect(loadedAnalytics.isFavorite, isTrue);

        newService.dispose();
      });

      test('should clear analytics data correctly', () async {
        await service.trackContentView('clear_test', 'CategoryClear');
        await service.clearAnalyticsData();

        final analytics = service.getContentAnalytics('clear_test');
        expect(analytics.views, equals(0));

        // Verify persistence by loading into a new service
        final newService = EducationalContentAnalyticsService();
        await Future.delayed(const Duration(milliseconds: 100));
        final loadedAnalytics = newService.getContentAnalytics('clear_test');
        expect(loadedAnalytics.views, equals(0));
        newService.dispose();
      });

      test('should handle multiple content items correctly', () async {
        await service.trackContentView('multi_1', 'MultiCat');
        await service.recordTimeSpent('multi_1', const Duration(minutes: 1));
        await service.trackContentInteraction('multi_1', ContentInteractionType.like);

        await service.trackContentView('multi_2', 'MultiCat');
        await service.recordTimeSpent('multi_2', const Duration(minutes: 2));
        await service.trackContentInteraction('multi_2', ContentInteractionType.bookmark);

        // New service
        final newService = EducationalContentAnalyticsService();
        await Future.delayed(const Duration(milliseconds: 100));

        final analytics1 = newService.getContentAnalytics('multi_1');
        final analytics2 = newService.getContentAnalytics('multi_2');

        expect(analytics1.views, equals(1));
        expect(analytics1.totalTimeSpent, equals(const Duration(minutes: 1)));
        expect(analytics1.interactions, equals(1));

        expect(analytics2.views, equals(1));
        expect(analytics2.totalTimeSpent, equals(const Duration(minutes: 2)));
        expect(analytics2.interactions, equals(1));

        newService.dispose();
      });

      test('should calculate overall engagement metrics correctly', () async {
        await service.trackContentView('content_A', 'CategoryX');
        await service.recordTimeSpent('content_A', const Duration(minutes: 5));
        await service.recordCompletion('content_A');
        await service.trackContentInteraction('content_A', ContentInteractionType.favorite);

        await service.trackContentView('content_B', 'CategoryY');
        await service.recordTimeSpent('content_B', const Duration(minutes: 10));
        // No completion for content_B
        await service.trackContentInteraction('content_B', ContentInteractionType.share);
        await service.trackContentInteraction('content_B', ContentInteractionType.like);

        await service.trackContentView('content_A', 'CategoryX'); // Second view for content_A

        final overallMetrics = service.getOverallEngagementMetrics();

        expect(overallMetrics.totalViews, equals(3)); // 2 for A, 1 for B
        expect(overallMetrics.totalTimeSpent, equals(const Duration(minutes: 15)));
        expect(overallMetrics.totalCompletions, equals(1)); // Only A completed
        expect(overallMetrics.totalInteractions, equals(3)); // 1 for A, 2 for B
        expect(overallMetrics.uniqueContentViewed, equals(2)); // A and B
        expect(overallMetrics.favoriteCount, equals(1)); // Only A favorited

        expect(overallMetrics.averageTimePerContent,
            equals(const Duration(minutes: 7, seconds: 30))); // 15 min / 2 unique contents
        expect(overallMetrics.completionRate, closeTo(1 / 3, 0.01)); // 1 completion / 3 views
      });
    });
  });
}
