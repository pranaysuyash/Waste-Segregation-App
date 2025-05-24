import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/services/educational_content_service.dart';
import 'package:waste_segregation_app/models/educational_content.dart';

void main() {
  group('Quiz Navigation Fix Tests', () {
    late EducationalContentService educationalService;

    setUp(() {
      educationalService = EducationalContentService();
    });

    test('should find quiz content for all major waste categories', () {
      final majorCategories = ['Wet Waste', 'Dry Waste', 'Hazardous Waste'];
      
      for (final category in majorCategories) {
        final categoryContent = educationalService.getContentByCategory(category);
        final quizContent = categoryContent
            .where((content) => content.type == ContentType.quiz)
            .toList();
        
        expect(quizContent.isNotEmpty, true, 
               reason: 'Should find quiz content for $category');
        
        print('✅ Found ${quizContent.length} quiz(es) for $category');
        for (final quiz in quizContent) {
          print('   - ${quiz.title}');
        }
      }
    });

    test('should have quiz questions for category-specific quizzes', () {
      final categoryQuizzes = {
        'Wet Waste': 'quiz2',
        'Dry Waste': 'quiz3', 
        'Hazardous Waste': 'quiz4',
      };
      
      for (final entry in categoryQuizzes.entries) {
        final category = entry.key;
        final quizId = entry.value;
        
        final quiz = educationalService.getContentById(quizId);
        expect(quiz, isNotNull, reason: 'Quiz $quizId should exist');
        expect(quiz!.type, ContentType.quiz, reason: 'Content should be a quiz');
        expect(quiz.questions, isNotEmpty, reason: 'Quiz should have questions');
        expect(quiz.categories.contains(category), true, 
               reason: 'Quiz should be categorized under $category');
        
        print('✅ $category quiz "${quiz.title}" has ${quiz.questions!.length} questions');
      }
    });

    test('should filter content correctly by category and type', () {
      // Test the same filtering logic used in the educational content screen
      final wetWasteContent = educationalService.getContentByCategory('Wet Waste');
      final wetWasteQuizzes = wetWasteContent
          .where((content) => content.type == ContentType.quiz)
          .toList();
      
      expect(wetWasteQuizzes.isNotEmpty, true, 
             reason: 'Should find wet waste quizzes');
      
      // Verify quiz content has proper questions
      for (final quiz in wetWasteQuizzes) {
        expect(quiz.questions, isNotNull, reason: 'Quiz should have questions');
        expect(quiz.questions!.isNotEmpty, true, reason: 'Quiz should have non-empty questions');
        
        // Check that each question has the required fields
        for (final question in quiz.questions!) {
          expect(question.question.isNotEmpty, true, reason: 'Question should have text');
          expect(question.options.length, greaterThanOrEqualTo(2), 
                 reason: 'Question should have multiple options');
          expect(question.correctOptionIndex, greaterThanOrEqualTo(0), 
                 reason: 'Question should have valid correct answer index');
          expect(question.correctOptionIndex, lessThan(question.options.length), 
                 reason: 'Correct answer index should be within options range');
        }
      }
      
      print('✅ All quiz questions are properly formatted');
    });

    test('should handle educational content screen navigation scenario', () {
      // Simulate the exact scenario: user classifies "Wet Waste" and clicks "Learn More"
      const initialCategory = 'Wet Waste';
      
      // This is the filtering logic from EducationalContentScreen._getFilteredContent
      final allContent = educationalService.getAllContent();
      final contentType = ContentType.quiz;
      
      // First filter by content type (Quizzes tab)
      var filteredContent = educationalService.getContentByType(contentType);
      
      // Then filter by category
      filteredContent = filteredContent
          .where((content) => content.categories.contains(initialCategory))
          .toList();
      
      expect(filteredContent.isNotEmpty, true, 
             reason: 'Should find quiz content for $initialCategory via Learn More navigation');
      
      print('✅ Learn More navigation for $initialCategory will show ${filteredContent.length} quiz(es)');
    });
  });
} 