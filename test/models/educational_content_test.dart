import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/educational_content.dart';
import '../test_helper.dart';

void main() {
  group('EducationalContent Model Tests', () {
    late DateTime testDate;

    setUpAll(() async {
      await TestHelper.setupCompleteTest();
    });

    tearDownAll(() async {
      await TestHelper.tearDownCompleteTest();
    });

    setUp(() {
      testDate = DateTime.parse('2024-01-15T10:30:00Z');
    });

    group('EducationalContent Constructor Tests', () {
      test('should create EducationalContent with all required fields', () {
        final content = EducationalContent(
          id: 'edu_content_123',
          title: 'Understanding Waste Categories',
          description: 'Learn about different types of waste and their disposal methods',
          type: ContentType.article,
          thumbnailUrl: 'https://example.com/thumbnail.jpg',
          categories: ['Waste Management', 'Environment'],
          level: ContentLevel.beginner,
          dateAdded: testDate,
          durationMinutes: 15,
          icon: Icons.article,
          contentText: 'Detailed article content about waste categories...',
          tags: ['waste', 'recycling', 'environment'],
        );

        expect(content.id, equals('edu_content_123'));
        expect(content.title, equals('Understanding Waste Categories'));
        expect(content.description, isNotEmpty);
        expect(content.type, equals(ContentType.article));
        expect(content.thumbnailUrl, equals('https://example.com/thumbnail.jpg'));
        expect(content.categories.length, equals(2));
        expect(content.level, equals(ContentLevel.beginner));
        expect(content.dateAdded, equals(testDate));
        expect(content.durationMinutes, equals(15));
        expect(content.icon, equals(Icons.article));
        expect(content.contentText, isNotEmpty);
        expect(content.tags.length, equals(3));
        expect(content.isPremium, isFalse);
      });

      test('should create EducationalContent with default values', () {
        final content = EducationalContent(
          id: 'edu_content_456',
          title: 'Basic Recycling',
          description: 'Introduction to recycling basics',
          type: ContentType.tip,
          thumbnailUrl: 'https://example.com/tip.jpg',
          categories: ['Recycling'],
          level: ContentLevel.beginner,
          dateAdded: testDate,
          durationMinutes: 5,
          icon: Icons.lightbulb_outline,
        );

        expect(content.tags, isEmpty); // Default empty list
        expect(content.isPremium, isFalse); // Default false
        expect(content.videoUrl, isNull);
        expect(content.contentText, isNull);
        expect(content.imageUrl, isNull);
        expect(content.questions, isNull);
        expect(content.steps, isNull);
      });
    });

    group('Factory Constructor Tests', () {
      test('should create article content using factory', () {
        final article = EducationalContent.article(
          id: 'article_123',
          title: 'Plastic Recycling Guide',
          description: 'Complete guide to plastic recycling',
          thumbnailUrl: 'https://example.com/plastic-thumb.jpg',
          contentText: 'Plastic recycling is an important process...',
          categories: ['Plastic', 'Recycling'],
          level: ContentLevel.intermediate,
          durationMinutes: 20,
          tags: ['plastic', 'recycling', 'PET'],
          isPremium: true,
        );

        expect(article.type, equals(ContentType.article));
        expect(article.icon, equals(Icons.article));
        expect(article.contentText, isNotEmpty);
        expect(article.isPremium, isTrue);
        expect(article.level, equals(ContentLevel.intermediate));
        expect(article.tags.contains('plastic'), isTrue);
        expect(article.videoUrl, isNull);
        expect(article.questions, isNull);
      });

      test('should create video content using factory', () {
        final video = EducationalContent.video(
          id: 'video_123',
          title: 'Composting Basics Video',
          description: 'Learn composting through this video tutorial',
          thumbnailUrl: 'https://example.com/compost-thumb.jpg',
          videoUrl: 'https://example.com/compost-video.mp4',
          categories: ['Composting', 'Organic Waste'],
          level: ContentLevel.beginner,
          durationMinutes: 12,
          tags: ['composting', 'organic', 'garden'],
        );

        expect(video.type, equals(ContentType.video));
        expect(video.icon, equals(Icons.video_library));
        expect(video.videoUrl, equals('https://example.com/compost-video.mp4'));
        expect(video.contentText, isNull);
        expect(video.questions, isNull);
        expect(video.steps, isNull);
      });

      test('should create infographic content using factory', () {
        final infographic = EducationalContent.infographic(
          id: 'infographic_123',
          title: 'Waste Sorting Infographic',
          description: 'Visual guide to waste sorting',
          thumbnailUrl: 'https://example.com/sorting-thumb.jpg',
          imageUrl: 'https://example.com/sorting-infographic.jpg',
          categories: ['Sorting', 'Visual Guide'],
          level: ContentLevel.beginner,
          durationMinutes: 3,
          contentText: 'This infographic shows...',
          tags: ['sorting', 'visual', 'guide'],
        );

        expect(infographic.type, equals(ContentType.infographic));
        expect(infographic.icon, equals(Icons.image));
        expect(infographic.imageUrl, equals('https://example.com/sorting-infographic.jpg'));
        expect(infographic.contentText, isNotEmpty);
        expect(infographic.videoUrl, isNull);
        expect(infographic.questions, isNull);
      });

      test('should create quiz content using factory', () {
        final questions = [
          const QuizQuestion(
            question: 'Which bin should plastic bottles go in?',
            options: ['Red bin', 'Blue bin', 'Green bin', 'Yellow bin'],
            correctOptionIndex: 1,
            explanation: 'Plastic bottles are recyclable and go in the blue bin.',
          ),
          const QuizQuestion(
            question: 'Are food containers recyclable after use?',
            options: ['Always', 'Never', 'Only if cleaned', 'Depends on material'],
            correctOptionIndex: 2,
            explanation: 'Food containers must be cleaned before recycling.',
          ),
        ];

        final quiz = EducationalContent.quiz(
          id: 'quiz_123',
          title: 'Recycling Knowledge Quiz',
          description: 'Test your recycling knowledge',
          thumbnailUrl: 'https://example.com/quiz-thumb.jpg',
          questions: questions,
          categories: ['Quiz', 'Assessment'],
          level: ContentLevel.intermediate,
          durationMinutes: 10,
          tags: ['quiz', 'assessment', 'knowledge'],
          isPremium: true,
        );

        expect(quiz.type, equals(ContentType.quiz));
        expect(quiz.icon, equals(Icons.quiz));
        expect(quiz.questions?.length, equals(2));
        expect(quiz.questions![0].question, contains('plastic bottles'));
        expect(quiz.questions![0].correctOptionIndex, equals(1));
        expect(quiz.questions![0].explanation, isNotEmpty);
        expect(quiz.contentText, isNull);
        expect(quiz.videoUrl, isNull);
      });

      test('should create tutorial content using factory', () {
        final steps = [
          const TutorialStep(
            title: 'Step 1: Gather Materials',
            description: 'Collect all recyclable items from your home',
            imageUrl: 'https://example.com/step1.jpg',
          ),
          const TutorialStep(
            title: 'Step 2: Sort Items',
            description: 'Separate items by material type',
            imageUrl: 'https://example.com/step2.jpg',
          ),
          const TutorialStep(
            title: 'Step 3: Clean Items',
            description: 'Rinse containers and remove labels',
          ),
        ];

        final tutorial = EducationalContent.tutorial(
          id: 'tutorial_123',
          title: 'Home Recycling Setup Tutorial',
          description: 'Step-by-step guide to setting up recycling at home',
          thumbnailUrl: 'https://example.com/tutorial-thumb.jpg',
          steps: steps,
          categories: ['Tutorial', 'Home Setup'],
          level: ContentLevel.beginner,
          durationMinutes: 25,
          tags: ['tutorial', 'home', 'setup'],
        );

        expect(tutorial.type, equals(ContentType.tutorial));
        expect(tutorial.icon, equals(Icons.menu_book));
        expect(tutorial.steps?.length, equals(3));
        expect(tutorial.steps![0].title, contains('Step 1'));
        expect(tutorial.steps![0].imageUrl, isNotEmpty);
        expect(tutorial.steps![2].imageUrl, isNull); // Step 3 has no image
        expect(tutorial.questions, isNull);
        expect(tutorial.videoUrl, isNull);
      });

      test('should create tip content using factory', () {
        final tip = EducationalContent.tip(
          id: 'tip_123',
          title: 'Quick Recycling Tip',
          description: 'Daily tip for better recycling',
          thumbnailUrl: 'https://example.com/tip-thumb.jpg',
          contentText: 'Always rinse containers before recycling to avoid contamination.',
          categories: ['Tips', 'Daily'],
          tags: ['tip', 'daily', 'quick'],
        );

        expect(tip.type, equals(ContentType.tip));
        expect(tip.icon, equals(Icons.lightbulb_outline));
        expect(tip.level, equals(ContentLevel.beginner)); // Default for tips
        expect(tip.durationMinutes, equals(1)); // Default for tips
        expect(tip.contentText, isNotEmpty);
        expect(tip.videoUrl, isNull);
        expect(tip.questions, isNull);
        expect(tip.steps, isNull);
      });
    });

    group('Helper Method Tests', () {
      test('should return correct type colors', () {
        final contentTypes = [
          ContentType.article,
          ContentType.video,
          ContentType.infographic,
          ContentType.quiz,
          ContentType.tutorial,
          ContentType.tip,
        ];

        final expectedColors = [
          Colors.blue,
          Colors.red,
          Colors.green,
          Colors.orange,
          Colors.purple,
          Colors.teal,
        ];

        for (var i = 0; i < contentTypes.length; i++) {
          final content = EducationalContent(
            id: 'test_$i',
            title: 'Test Content',
            description: 'Test',
            type: contentTypes[i],
            thumbnailUrl: 'https://example.com/thumb.jpg',
            categories: ['Test'],
            level: ContentLevel.beginner,
            dateAdded: testDate,
            durationMinutes: 5,
            icon: Icons.article,
          );

          expect(content.getTypeColor(), equals(expectedColors[i]));
        }
      });

      test('should return correct level text', () {
        final levels = [
          ContentLevel.beginner,
          ContentLevel.intermediate,
          ContentLevel.advanced,
        ];

        final expectedTexts = [
          'Beginner',
          'Intermediate',
          'Advanced',
        ];

        for (var i = 0; i < levels.length; i++) {
          final content = EducationalContent(
            id: 'test_$i',
            title: 'Test Content',
            description: 'Test',
            type: ContentType.article,
            thumbnailUrl: 'https://example.com/thumb.jpg',
            categories: ['Test'],
            level: levels[i],
            dateAdded: testDate,
            durationMinutes: 5,
            icon: Icons.article,
          );

          expect(content.getLevelText(), equals(expectedTexts[i]));
        }
      });

      test('should format duration correctly', () {
        final durations = [0, 1, 5, 30, 60, 90, 120, 150];
        final expectedFormats = [
          'Less than 1 min',
          '1 minute',
          '5 minutes',
          '30 minutes',
          '1 hour',
          '1 hour 30 min',
          '2 hours',
          '2 hours 30 min',
        ];

        for (var i = 0; i < durations.length; i++) {
          final content = EducationalContent(
            id: 'test_$i',
            title: 'Test Content',
            description: 'Test',
            type: ContentType.article,
            thumbnailUrl: 'https://example.com/thumb.jpg',
            categories: ['Test'],
            level: ContentLevel.beginner,
            dateAdded: testDate,
            durationMinutes: durations[i],
            icon: Icons.article,
          );

          expect(content.getFormattedDuration(), equals(expectedFormats[i]));
        }
      });

      test('should handle very long durations', () {
        final content = EducationalContent(
          id: 'long_content',
          title: 'Very Long Content',
          description: 'Test',
          type: ContentType.tutorial,
          thumbnailUrl: 'https://example.com/thumb.jpg',
          categories: ['Test'],
          level: ContentLevel.advanced,
          dateAdded: testDate,
          durationMinutes: 300, // 5 hours
          icon: Icons.menu_book,
        );

        expect(content.getFormattedDuration(), equals('5 hours'));
      });
    });

    group('QuizQuestion Tests', () {
      test('should create QuizQuestion with all fields', () {
        const question = QuizQuestion(
          question: 'What color bin is for recyclables?',
          options: ['Red', 'Blue', 'Green', 'Yellow'],
          correctOptionIndex: 1,
          explanation: 'Blue bins are typically used for recyclable materials.',
        );

        expect(question.question, equals('What color bin is for recyclables?'));
        expect(question.options.length, equals(4));
        expect(question.options[1], equals('Blue'));
        expect(question.correctOptionIndex, equals(1));
        expect(question.explanation, isNotEmpty);
      });

      test('should create QuizQuestion without explanation', () {
        const question = QuizQuestion(
          question: 'Is glass recyclable?',
          options: ['Yes', 'No', 'Sometimes'],
          correctOptionIndex: 0,
        );

        expect(question.question, isNotEmpty);
        expect(question.options.length, equals(3));
        expect(question.correctOptionIndex, equals(0));
        expect(question.explanation, isNull);
      });

      test('should handle edge cases for QuizQuestion', () {
        const question = QuizQuestion(
          question: '',
          options: [],
          correctOptionIndex: -1,
        );

        expect(question.question, equals(''));
        expect(question.options, isEmpty);
        expect(question.correctOptionIndex, equals(-1));
      });
    });

    group('TutorialStep Tests', () {
      test('should create TutorialStep with all fields', () {
        const step = TutorialStep(
          title: 'Step 1: Preparation',
          description: 'Gather all your recyclable materials in one place.',
          imageUrl: 'https://example.com/step1-image.jpg',
        );

        expect(step.title, equals('Step 1: Preparation'));
        expect(step.description, isNotEmpty);
        expect(step.imageUrl, equals('https://example.com/step1-image.jpg'));
      });

      test('should create TutorialStep without image', () {
        const step = TutorialStep(
          title: 'Step 2: Sorting',
          description: 'Sort materials by type: plastic, paper, glass, metal.',
        );

        expect(step.title, equals('Step 2: Sorting'));
        expect(step.description, isNotEmpty);
        expect(step.imageUrl, isNull);
      });

      test('should handle empty strings in TutorialStep', () {
        const step = TutorialStep(
          title: '',
          description: '',
          imageUrl: '',
        );

        expect(step.title, equals(''));
        expect(step.description, equals(''));
        expect(step.imageUrl, equals(''));
      });
    });

    group('DailyTip Tests', () {
      test('should create DailyTip with all fields', () {
        final tip = DailyTip(
          id: 'tip_daily_123',
          title: 'Recycling Tip of the Day',
          content: 'Clean containers before recycling to prevent contamination.',
          category: 'Recycling',
          date: testDate,
          actionText: 'Learn More',
          actionLink: '/recycling-guide',
        );

        expect(tip.id, equals('tip_daily_123'));
        expect(tip.title, equals('Recycling Tip of the Day'));
        expect(tip.content, isNotEmpty);
        expect(tip.category, equals('Recycling'));
        expect(tip.date, equals(testDate));
        expect(tip.actionText, equals('Learn More'));
        expect(tip.actionLink, equals('/recycling-guide'));
      });

      test('should create DailyTip without action', () {
        final tip = DailyTip(
          id: 'tip_daily_456',
          title: 'Quick Tip',
          content: 'Remove caps from bottles before recycling.',
          category: 'Quick Tips',
          date: testDate,
        );

        expect(tip.id, equals('tip_daily_456'));
        expect(tip.title, equals('Quick Tip'));
        expect(tip.content, isNotEmpty);
        expect(tip.category, equals('Quick Tips'));
        expect(tip.date, equals(testDate));
        expect(tip.actionText, isNull);
        expect(tip.actionLink, isNull);
      });
    });

    group('Content Type Integration Tests', () {
      test('should handle all content types with appropriate fields', () {
        // Article with text content
        final article = EducationalContent.article(
          id: 'article_test',
          title: 'Article Test',
          description: 'Test article',
          thumbnailUrl: 'https://example.com/thumb.jpg',
          contentText: 'Article content...',
          categories: ['Articles'],
          level: ContentLevel.beginner,
          durationMinutes: 10,
        );
        expect(article.contentText, isNotEmpty);
        expect(article.videoUrl, isNull);
        expect(article.questions, isNull);
        expect(article.steps, isNull);

        // Video with video URL
        final video = EducationalContent.video(
          id: 'video_test',
          title: 'Video Test',
          description: 'Test video',
          thumbnailUrl: 'https://example.com/thumb.jpg',
          videoUrl: 'https://example.com/video.mp4',
          categories: ['Videos'],
          level: ContentLevel.intermediate,
          durationMinutes: 15,
        );
        expect(video.videoUrl, isNotEmpty);
        expect(video.contentText, isNull);
        expect(video.questions, isNull);
        expect(video.steps, isNull);

        // Quiz with questions
        final quiz = EducationalContent.quiz(
          id: 'quiz_test',
          title: 'Quiz Test',
          description: 'Test quiz',
          thumbnailUrl: 'https://example.com/thumb.jpg',
          questions: [
            const QuizQuestion(
              question: 'Test question?',
              options: ['A', 'B', 'C'],
              correctOptionIndex: 0,
            ),
          ],
          categories: ['Quizzes'],
          level: ContentLevel.advanced,
          durationMinutes: 5,
        );
        expect(quiz.questions, isNotEmpty);
        expect(quiz.contentText, isNull);
        expect(quiz.videoUrl, isNull);
        expect(quiz.steps, isNull);

        // Tutorial with steps
        final tutorial = EducationalContent.tutorial(
          id: 'tutorial_test',
          title: 'Tutorial Test',
          description: 'Test tutorial',
          thumbnailUrl: 'https://example.com/thumb.jpg',
          steps: [
            const TutorialStep(
              title: 'Step 1',
              description: 'First step',
            ),
          ],
          categories: ['Tutorials'],
          level: ContentLevel.beginner,
          durationMinutes: 20,
        );
        expect(tutorial.steps, isNotEmpty);
        expect(tutorial.contentText, isNull);
        expect(tutorial.videoUrl, isNull);
        expect(tutorial.questions, isNull);
      });
    });

    group('Edge Cases and Validation Tests', () {
      test('should handle empty categories and tags', () {
        final content = EducationalContent(
          id: 'test_empty',
          title: 'Test Content',
          description: 'Test',
          type: ContentType.article,
          thumbnailUrl: 'https://example.com/thumb.jpg',
          categories: [], // Empty categories
          level: ContentLevel.beginner,
          dateAdded: testDate,
          durationMinutes: 5,
          icon: Icons.article,
          tags: [], // Empty tags
        );

        expect(content.categories, isEmpty);
        expect(content.tags, isEmpty);
      });

      test('should handle very long strings', () {
        final longString = 'A' * 1000;
        
        final content = EducationalContent(
          id: longString,
          title: longString,
          description: longString,
          type: ContentType.article,
          thumbnailUrl: longString,
          categories: [longString],
          level: ContentLevel.beginner,
          dateAdded: testDate,
          durationMinutes: 5,
          icon: Icons.article,
          contentText: longString,
          tags: [longString],
        );

        expect(content.id.length, equals(1000));
        expect(content.title.length, equals(1000));
        expect(content.description.length, equals(1000));
        expect(content.contentText?.length, equals(1000));
      });

      test('should handle extreme duration values', () {
        final shortContent = EducationalContent(
          id: 'short',
          title: 'Short Content',
          description: 'Very short',
          type: ContentType.tip,
          thumbnailUrl: 'https://example.com/thumb.jpg',
          categories: ['Short'],
          level: ContentLevel.beginner,
          dateAdded: testDate,
          durationMinutes: 0,
          icon: Icons.lightbulb_outline,
        );

        final longContent = EducationalContent(
          id: 'long',
          title: 'Long Content',
          description: 'Very long',
          type: ContentType.tutorial,
          thumbnailUrl: 'https://example.com/thumb.jpg',
          categories: ['Long'],
          level: ContentLevel.advanced,
          dateAdded: testDate,
          durationMinutes: 10000, // Very long duration
          icon: Icons.menu_book,
        );

        expect(shortContent.getFormattedDuration(), equals('Less than 1 min'));
        expect(longContent.getFormattedDuration(), contains('hours'));
      });

      test('should handle invalid quiz question indices', () {
        const invalidQuestion = QuizQuestion(
          question: 'Test question?',
          options: ['A', 'B', 'C'],
          correctOptionIndex: 10, // Invalid index
        );

        expect(invalidQuestion.correctOptionIndex, equals(10));
        expect(invalidQuestion.options.length, equals(3));
      });

      test('should handle premium content correctly', () {
        final premiumContent = EducationalContent.article(
          id: 'premium_test',
          title: 'Premium Article',
          description: 'Premium content',
          thumbnailUrl: 'https://example.com/thumb.jpg',
          contentText: 'Premium article content...',
          categories: ['Premium'],
          level: ContentLevel.advanced,
          durationMinutes: 30,
          isPremium: true,
        );

        final freeContent = EducationalContent.tip(
          id: 'free_test',
          title: 'Free Tip',
          description: 'Free content',
          thumbnailUrl: 'https://example.com/thumb.jpg',
          contentText: 'Free tip content...',
          categories: ['Free'],
        );

        expect(premiumContent.isPremium, isTrue);
        expect(freeContent.isPremium, isFalse);
      });

      test('should handle future dates', () {
        final futureDate = DateTime.now().add(const Duration(days: 365));
        
        final content = EducationalContent(
          id: 'future_content',
          title: 'Future Content',
          description: 'Content from the future',
          type: ContentType.article,
          thumbnailUrl: 'https://example.com/thumb.jpg',
          categories: ['Future'],
          level: ContentLevel.beginner,
          dateAdded: futureDate,
          durationMinutes: 10,
          icon: Icons.article,
        );

        expect(content.dateAdded.isAfter(DateTime.now()), isTrue);
      });
    });
  });
}
