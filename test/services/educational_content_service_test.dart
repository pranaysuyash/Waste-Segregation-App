import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/services/educational_content_service.dart';
import 'package:waste_segregation_app/models/educational_content.dart';
import '../test_helper.dart';

void main() {
  group('EducationalContentService Critical Tests', () {
    late EducationalContentService service;

    setUpAll(() async {
      await TestHelper.setupCompleteTest();
    });

    tearDownAll(() async {
      await TestHelper.tearDownCompleteTest();
    });

    setUp(() {
      service = EducationalContentService();
    });

    group('Initialization Tests', () {
      test('should initialize with content and daily tips', () {
        final allContent = service.getAllContent();
        final allTips = service.getAllDailyTips();

        expect(allContent, isNotEmpty);
        expect(allTips, isNotEmpty);
        expect(allContent.length, greaterThan(10)); // Should have substantial content
        expect(allTips.length, greaterThan(5)); // Should have multiple tips
      });

      test('should initialize with diverse content types', () {
        final allContent = service.getAllContent();

        final articles = allContent.where((c) => c.type == ContentType.article).toList();
        final videos = allContent.where((c) => c.type == ContentType.video).toList();
        final quizzes = allContent.where((c) => c.type == ContentType.quiz).toList();
        final tutorials = allContent.where((c) => c.type == ContentType.tutorial).toList();
        final infographics = allContent.where((c) => c.type == ContentType.infographic).toList();

        expect(articles, isNotEmpty);
        expect(videos, isNotEmpty);
        expect(quizzes, isNotEmpty);
        expect(tutorials, isNotEmpty);
        expect(infographics, isNotEmpty);
      });

      test('should initialize with content covering all waste categories', () {
        final allContent = service.getAllContent();
        final allCategories = allContent
            .expand((c) => c.categories)
            .toSet()
            .toList();

        expect(allCategories.contains('Dry Waste'), isTrue);
        expect(allCategories.contains('Wet Waste'), isTrue);
        expect(allCategories.contains('Hazardous Waste'), isTrue);
        expect(allCategories.contains('Medical Waste'), isTrue);
        expect(allCategories.contains('General'), isTrue);
      });

      test('should initialize with valid content structure', () {
        final allContent = service.getAllContent();

        for (final content in allContent) {
          expect(content.id, isNotEmpty);
          expect(content.title, isNotEmpty);
          expect(content.description, isNotEmpty);
          expect(content.thumbnailUrl, isNotEmpty);
          expect(content.categories, isNotEmpty);
          expect(content.durationMinutes, greaterThan(0));
        }
      });

      test('should initialize daily tips with proper structure', () {
        final allTips = service.getAllDailyTips();

        for (final tip in allTips) {
          expect(tip.id, isNotEmpty);
          expect(tip.title, isNotEmpty);
          expect(tip.content, isNotEmpty);
          expect(tip.category, isNotEmpty);
          expect(tip.date, isA<DateTime>());
        }
      });
    });

    group('Daily Tips Tests', () {
      test('should return random daily tip', () {
        final tip1 = service.getRandomDailyTip();
        final tip2 = service.getRandomDailyTip();

        expect(tip1, isA<DailyTip>());
        expect(tip2, isA<DailyTip>());
        expect(tip1.id, isNotEmpty);
        expect(tip1.title, isNotEmpty);
        expect(tip1.content, isNotEmpty);
        
        // Tips might be the same due to randomness, but structure should be valid
        expect(tip1.category, isNotEmpty);
      });

      test('should return specific daily tip for date', () {
        final today = DateTime.now();
        final yesterday = today.subtract(const Duration(days: 1));
        final tomorrow = today.add(const Duration(days: 1));

        final tipToday = service.getDailyTip(date: today);
        final tipYesterday = service.getDailyTip(date: yesterday);
        final tipTomorrow = service.getDailyTip(date: tomorrow);

        expect(tipToday, isA<DailyTip>());
        expect(tipYesterday, isA<DailyTip>());
        expect(tipTomorrow, isA<DailyTip>());

        // Same date should return same tip
        final tipTodayAgain = service.getDailyTip(date: today);
        expect(tipToday.id, equals(tipTodayAgain.id));
      });

      test('should return daily tip when no date specified', () {
        final tip = service.getDailyTip();
        
        expect(tip, isA<DailyTip>());
        expect(tip.id, isNotEmpty);
        expect(tip.title, isNotEmpty);
        expect(tip.content, isNotEmpty);
      });

      test('should return consistent tip for same date across calls', () {
        final testDate = DateTime(2024, 1, 15);
        
        final tip1 = service.getDailyTip(date: testDate);
        final tip2 = service.getDailyTip(date: testDate);
        final tip3 = service.getDailyTip(date: testDate);

        expect(tip1.id, equals(tip2.id));
        expect(tip2.id, equals(tip3.id));
        expect(tip1.title, equals(tip2.title));
      });

      test('should handle edge case dates', () {
        final farFuture = DateTime(2030, 12, 31);
        final farPast = DateTime(2000);
        
        final futureTip = service.getDailyTip(date: farFuture);
        final pastTip = service.getDailyTip(date: farPast);

        expect(futureTip, isA<DailyTip>());
        expect(pastTip, isA<DailyTip>());
        expect(futureTip.id, isNotEmpty);
        expect(pastTip.id, isNotEmpty);
      });

      test('should return all daily tips', () {
        final allTips = service.getAllDailyTips();
        
        expect(allTips, isNotEmpty);
        expect(allTips.length, greaterThan(5));
        
        // Verify each tip has unique ID
        final tipIds = allTips.map((t) => t.id).toSet();
        expect(tipIds.length, equals(allTips.length));
      });
    });

    group('Content Retrieval Tests', () {
      test('should return all content', () {
        final allContent = service.getAllContent();
        
        expect(allContent, isNotEmpty);
        expect(allContent.length, greaterThan(10));
        
        // Verify each content has unique ID
        final contentIds = allContent.map((c) => c.id).toSet();
        expect(contentIds.length, equals(allContent.length));
      });

      test('should filter content by category', () {
        final dryWasteContent = service.getContentByCategory('Dry Waste');
        final wetWasteContent = service.getContentByCategory('Wet Waste');
        final hazardousContent = service.getContentByCategory('Hazardous Waste');
        final medicalContent = service.getContentByCategory('Medical Waste');

        expect(dryWasteContent, isNotEmpty);
        expect(wetWasteContent, isNotEmpty);
        expect(hazardousContent, isNotEmpty);
        expect(medicalContent, isNotEmpty);

        // Verify filtering works correctly
        for (final content in dryWasteContent) {
          expect(content.categories.contains('Dry Waste'), isTrue);
        }

        for (final content in wetWasteContent) {
          expect(content.categories.contains('Wet Waste'), isTrue);
        }
      });

      test('should filter content by type', () {
        final articles = service.getContentByType(ContentType.article);
        final videos = service.getContentByType(ContentType.video);
        final quizzes = service.getContentByType(ContentType.quiz);
        final tutorials = service.getContentByType(ContentType.tutorial);
        final infographics = service.getContentByType(ContentType.infographic);
        final tips = service.getContentByType(ContentType.tip);

        expect(articles, isNotEmpty);
        expect(videos, isNotEmpty);
        expect(quizzes, isNotEmpty);
        expect(tutorials, isNotEmpty);
        expect(infographics, isNotEmpty);
        // Tips might be empty if none are initialized in the content list

        // Verify filtering works correctly
        for (final content in articles) {
          expect(content.type, equals(ContentType.article));
        }

        for (final content in videos) {
          expect(content.type, equals(ContentType.video));
        }

        for (final content in quizzes) {
          expect(content.type, equals(ContentType.quiz));
        }
      });

      test('should return empty list for non-existent category', () {
        final nonExistentContent = service.getContentByCategory('Non-Existent Category');
        expect(nonExistentContent, isEmpty);
      });

      test('should get content by ID', () {
        final allContent = service.getAllContent();
        final firstContent = allContent.first;
        
        final foundContent = service.getContentById(firstContent.id);
        expect(foundContent, isNotNull);
        expect(foundContent!.id, equals(firstContent.id));
        expect(foundContent.title, equals(firstContent.title));
      });

      test('should return null for non-existent ID', () {
        final nonExistentContent = service.getContentById('non_existent_id');
        expect(nonExistentContent, isNull);
      });

      test('should return featured content', () {
        final featuredContent = service.getFeaturedContent();
        
        expect(featuredContent, isNotEmpty);
        expect(featuredContent.length, lessThanOrEqualTo(4));
        
        // If there are more than 4 total content items, should return exactly 4
        final allContent = service.getAllContent();
        if (allContent.length > 4) {
          expect(featuredContent.length, equals(4));
        } else {
          expect(featuredContent.length, equals(allContent.length));
        }
      });

      test('should return different featured content on multiple calls', () {
        final featured1 = service.getFeaturedContent();
        final featured2 = service.getFeaturedContent();
        
        expect(featured1.length, equals(featured2.length));
        
        // Due to randomness, they might occasionally be the same, but structure should be valid
        for (final content in featured1) {
          expect(content.id, isNotEmpty);
        }
        
        for (final content in featured2) {
          expect(content.id, isNotEmpty);
        }
      });
    });

    group('Search Functionality Tests', () {
      test('should search content by title', () {
        final results = service.searchContent('plastic');
        
        expect(results, isNotEmpty);
        for (final content in results) {
          final titleMatch = content.title.toLowerCase().contains('plastic');
          final descMatch = content.description.toLowerCase().contains('plastic');
          final tagMatch = content.tags.any((tag) => tag.toLowerCase().contains('plastic'));
          final categoryMatch = content.categories.any((cat) => cat.toLowerCase().contains('plastic'));
          
          expect(titleMatch || descMatch || tagMatch || categoryMatch, isTrue);
        }
      });

      test('should search content by description', () {
        final results = service.searchContent('recycling');
        
        expect(results, isNotEmpty);
        for (final content in results) {
          final titleMatch = content.title.toLowerCase().contains('recycling');
          final descMatch = content.description.toLowerCase().contains('recycling');
          final tagMatch = content.tags.any((tag) => tag.toLowerCase().contains('recycling'));
          final categoryMatch = content.categories.any((cat) => cat.toLowerCase().contains('recycling'));
          
          expect(titleMatch || descMatch || tagMatch || categoryMatch, isTrue);
        }
      });

      test('should search content by tags', () {
        final results = service.searchContent('composting');
        
        expect(results, isNotEmpty);
        for (final content in results) {
          final titleMatch = content.title.toLowerCase().contains('composting');
          final descMatch = content.description.toLowerCase().contains('composting');
          final tagMatch = content.tags.any((tag) => tag.toLowerCase().contains('composting'));
          final categoryMatch = content.categories.any((cat) => cat.toLowerCase().contains('composting'));
          
          expect(titleMatch || descMatch || tagMatch || categoryMatch, isTrue);
        }
      });

      test('should search content by categories', () {
        final results = service.searchContent('hazardous');
        
        expect(results, isNotEmpty);
        for (final content in results) {
          final titleMatch = content.title.toLowerCase().contains('hazardous');
          final descMatch = content.description.toLowerCase().contains('hazardous');
          final tagMatch = content.tags.any((tag) => tag.toLowerCase().contains('hazardous'));
          final categoryMatch = content.categories.any((cat) => cat.toLowerCase().contains('hazardous'));
          
          expect(titleMatch || descMatch || tagMatch || categoryMatch, isTrue);
        }
      });

      test('should handle case-insensitive search', () {
        final results1 = service.searchContent('PLASTIC');
        final results2 = service.searchContent('plastic');
        final results3 = service.searchContent('Plastic');
        
        expect(results1.length, equals(results2.length));
        expect(results2.length, equals(results3.length));
        
        final ids1 = results1.map((c) => c.id).toSet();
        final ids2 = results2.map((c) => c.id).toSet();
        expect(ids1, equals(ids2));
      });

      test('should return empty list for no matches', () {
        final results = service.searchContent('xyznomatchstring');
        expect(results, isEmpty);
      });

      test('should handle empty search query', () {
        final results = service.searchContent('');
        expect(results, isEmpty);
      });

      test('should handle whitespace-only search query', () {
        final results = service.searchContent('   ');
        expect(results, isEmpty);
      });
    });

    group('Content Quality Tests', () {
      test('should have articles with proper content text', () {
        final articles = service.getContentByType(ContentType.article);
        
        for (final article in articles) {
          expect(article.contentText, isNotNull);
          expect(article.contentText!, isNotEmpty);
          expect(article.contentText!.length, greaterThan(100)); // Substantial content
        }
      });

      test('should have videos with proper URLs', () {
        final videos = service.getContentByType(ContentType.video);
        
        for (final video in videos) {
          expect(video.videoUrl, isNotNull);
          expect(video.videoUrl!, isNotEmpty);
          expect(video.videoUrl!, startsWith('http'));
        }
      });

      test('should have quizzes with proper questions', () {
        final quizzes = service.getContentByType(ContentType.quiz);
        
        for (final quiz in quizzes) {
          expect(quiz.questions, isNotNull);
          expect(quiz.questions!, isNotEmpty);
          
          for (final question in quiz.questions!) {
            expect(question.question, isNotEmpty);
            expect(question.options, isNotEmpty);
            expect(question.options.length, greaterThanOrEqualTo(2));
            expect(question.correctOptionIndex, greaterThanOrEqualTo(0));
            expect(question.correctOptionIndex, lessThan(question.options.length));
            
            if (question.explanation != null) {
              expect(question.explanation!, isNotEmpty);
            }
          }
        }
      });

      test('should have tutorials with proper steps', () {
        final tutorials = service.getContentByType(ContentType.tutorial);
        
        for (final tutorial in tutorials) {
          expect(tutorial.steps, isNotNull);
          expect(tutorial.steps!, isNotEmpty);
          
          for (final step in tutorial.steps!) {
            expect(step.title, isNotEmpty);
            expect(step.description, isNotEmpty);
            
            if (step.imageUrl != null) {
              expect(step.imageUrl!, isNotEmpty);
            }
          }
        }
      });

      test('should have infographics with proper image URLs', () {
        final infographics = service.getContentByType(ContentType.infographic);
        
        for (final infographic in infographics) {
          expect(infographic.imageUrl, isNotNull);
          expect(infographic.imageUrl!, isNotEmpty);
        }
      });

      test('should have content with realistic duration estimates', () {
        final allContent = service.getAllContent();
        
        for (final content in allContent) {
          expect(content.durationMinutes, greaterThan(0));
          expect(content.durationMinutes, lessThan(120)); // Should be under 2 hours
          
          // Different content types should have appropriate durations
          switch (content.type) {
            case ContentType.tip:
              expect(content.durationMinutes, lessThanOrEqualTo(5));
              break;
            case ContentType.infographic:
              expect(content.durationMinutes, lessThanOrEqualTo(10));
              break;
            case ContentType.quiz:
              expect(content.durationMinutes, lessThanOrEqualTo(15));
              break;
            case ContentType.article:
            case ContentType.video:
            case ContentType.tutorial:
              // These can vary widely
              break;
          }
        }
      });

      test('should have content with appropriate difficulty levels', () {
        final allContent = service.getAllContent();
        
        final beginnerContent = allContent.where((c) => c.level == ContentLevel.beginner).toList();
        final intermediateContent = allContent.where((c) => c.level == ContentLevel.intermediate).toList();
        final advancedContent = allContent.where((c) => c.level == ContentLevel.advanced).toList();

        expect(beginnerContent, isNotEmpty);
        expect(intermediateContent, isNotEmpty);
        // Advanced content might be empty, which is okay
        
        // Most content should be beginner-friendly
        expect(beginnerContent.length, greaterThanOrEqualTo(intermediateContent.length));
      });

      test('should have diverse content topics', () {
        final allContent = service.getAllContent();
        
        // Should cover main waste categories
        final wasteCategories = ['Dry Waste', 'Wet Waste', 'Hazardous Waste', 'Medical Waste'];
        
        for (final category in wasteCategories) {
          final categoryContent = allContent.where((c) => c.categories.contains(category)).toList();
          expect(categoryContent, isNotEmpty, reason: 'Should have content for $category');
        }
      });
    });

    group('Performance and Edge Cases Tests', () {
      test('should handle rapid successive calls efficiently', () {
        final stopwatch = Stopwatch()..start();
        
        for (var i = 0; i < 100; i++) {
          service.getAllContent();
          service.getRandomDailyTip();
          service.searchContent('test');
        }
        
        stopwatch.stop();
        
        // Should complete quickly (under 1 second for 300 calls)
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });

      test('should handle multiple instances correctly', () {
        final service1 = EducationalContentService();
        final service2 = EducationalContentService();
        
        final content1 = service1.getAllContent();
        final content2 = service2.getAllContent();
        
        expect(content1.length, equals(content2.length));
        
        // Should have same content structure
        final ids1 = content1.map((c) => c.id).toSet();
        final ids2 = content2.map((c) => c.id).toSet();
        expect(ids1, equals(ids2));
      });

      test('should handle large search result sets', () {
        // Search for common terms that should return many results
        final results = service.searchContent('waste');
        
        expect(results, isNotEmpty);
        expect(results.length, greaterThan(5));
        
        // All results should be valid
        for (final content in results) {
          expect(content.id, isNotEmpty);
          expect(content.title, isNotEmpty);
        }
      });

      test('should handle special characters in search', () {
        final specialSearches = [
          'plastic!',
          'recycling?',
          'waste & disposal',
          'compost (organic)',
          'e-waste',
          'CO₂',
        ];
        
        for (final query in specialSearches) {
          final results = service.searchContent(query);
          // Should not crash, results may be empty or non-empty
          expect(results, isA<List<EducationalContent>>());
        }
      });

      test('should handle very long search queries', () {
        final longQuery = 'plastic recycling composting waste management environmental sustainability' * 10;
        
        final results = service.searchContent(longQuery);
        expect(results, isA<List<EducationalContent>>());
      });

      test('should maintain content consistency across calls', () {
        final content1 = service.getAllContent();
        final content2 = service.getAllContent();
        
        expect(content1.length, equals(content2.length));
        
        for (var i = 0; i < content1.length; i++) {
          expect(content1[i].id, equals(content2[i].id));
          expect(content1[i].title, equals(content2[i].title));
        }
      });

      test('should handle concurrent access patterns', () {
        final futures = <Future>[];
        
        for (var i = 0; i < 50; i++) {
          futures.add(Future(() {
            service.getAllContent();
            service.getRandomDailyTip();
            service.searchContent('test$i');
            return true;
          }));
        }
        
        expect(() async => Future.wait(futures), returnsNormally);
      });
    });

    group('Integration and Data Integrity Tests', () {
      test('should have unique content IDs', () {
        final allContent = service.getAllContent();
        final allTips = service.getAllDailyTips();
        
        final contentIds = allContent.map((c) => c.id).toList();
        final tipIds = allTips.map((t) => t.id).toList();
        
        // Check content IDs are unique
        final uniqueContentIds = contentIds.toSet();
        expect(uniqueContentIds.length, equals(contentIds.length));
        
        // Check tip IDs are unique
        final uniqueTipIds = tipIds.toSet();
        expect(uniqueTipIds.length, equals(tipIds.length));
        
        // Check no overlap between content and tip IDs
        final allIds = [...contentIds, ...tipIds];
        final uniqueAllIds = allIds.toSet();
        expect(uniqueAllIds.length, equals(allIds.length));
      });

      test('should have appropriate content distribution', () {
        final allContent = service.getAllContent();
        
        // Count by type
        final typeCounts = <ContentType, int>{};
        for (final content in allContent) {
          typeCounts[content.type] = (typeCounts[content.type] ?? 0) + 1;
        }
        
        // Should have multiple types represented
        expect(typeCounts.keys.length, greaterThanOrEqualTo(4));
        
        // Should have reasonable distribution (no single type dominates too much)
        final maxCount = typeCounts.values.reduce((a, b) => a > b ? a : b);
        final totalCount = allContent.length;
        expect(maxCount / totalCount, lessThan(0.7)); // No type should be >70% of content
      });

      test('should have comprehensive category coverage', () {
        final allContent = service.getAllContent();
        final allCategories = allContent
            .expand((c) => c.categories)
            .toSet()
            .toList();
        
        // Should cover essential waste management categories
        final essentialCategories = [
          'Dry Waste',
          'Wet Waste', 
          'Hazardous Waste',
          'Medical Waste',
          'Recycling',
          'Composting',
        ];
        
        for (final category in essentialCategories) {
          expect(allCategories.contains(category), isTrue, 
                 reason: 'Should have content for essential category: $category');
        }
      });

      test('should have valid asset paths', () {
        final allContent = service.getAllContent();
        
        for (final content in allContent) {
          expect(content.thumbnailUrl, anyOf([startsWith('assets/'), startsWith('http')]));
          
          if (content.videoUrl != null) {
            expect(content.videoUrl!, startsWith('http'));
          }
          
          if (content.imageUrl != null) {
            expect(content.imageUrl!, anyOf([startsWith('assets/'), startsWith('http')]));
          }
          
          if (content.steps != null) {
            for (final step in content.steps!) {
              if (step.imageUrl != null) {
                expect(step.imageUrl!, anyOf([startsWith('assets/'), startsWith('http')]));
              }
            }
          }
        }
      });

      test('should have meaningful educational progression', () {
        final allContent = service.getAllContent();
        
        // Should have beginner content for each major category
        final majorCategories = ['Dry Waste', 'Wet Waste', 'Hazardous Waste'];
        
        for (final category in majorCategories) {
          final categoryContent = allContent
              .where((c) => c.categories.contains(category))
              .toList();
          
          final beginnerContent = categoryContent
              .where((c) => c.level == ContentLevel.beginner)
              .toList();
          
          expect(beginnerContent, isNotEmpty, 
                 reason: 'Should have beginner content for $category');
        }
      });
    });
  });
}
