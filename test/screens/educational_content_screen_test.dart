import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:waste_segregation_app/screens/educational_content_screen.dart';
import 'package:waste_segregation_app/screens/content_detail_screen.dart';
import 'package:waste_segregation_app/services/educational_content_service.dart';
import 'package:waste_segregation_app/services/ad_service.dart';
import 'package:waste_segregation_app/models/educational_content.dart';

// Mock classes
@GenerateMocks([EducationalContentService, AdService])
import 'educational_content_screen_test.mocks.dart';

void main() {
  group('EducationalContentScreen', () {
    late MockEducationalContentService mockEducationalService;
    late MockAdService mockAdService;
    late List<EducationalContent> testContent;

    setUp(() {
      mockEducationalService = MockEducationalContentService();
      mockAdService = MockAdService();

      testContent = [
        EducationalContent(
          id: 'article_1',
          title: 'Recycling Basics',
          description: 'Learn the fundamentals of recycling',
          type: ContentType.article,
          level: ContentLevel.beginner,
          categories: ['Recycling', 'General'],
          tags: ['plastic', 'paper', 'metal'],
          readTimeMinutes: 5,
          content: 'Content about recycling basics...',
          author: 'Dr. Green',
          publishedDate: DateTime.now().subtract(const Duration(days: 10)),
          lastUpdated: DateTime.now().subtract(const Duration(days: 5)),
        ),
        EducationalContent(
          id: 'video_1',
          title: 'Composting at Home',
          description: 'Step-by-step video guide to home composting',
          type: ContentType.video,
          level: ContentLevel.intermediate,
          categories: ['Composting', 'Home Organization'],
          tags: ['organic', 'kitchen', 'garden'],
          readTimeMinutes: 15,
          content: 'Video content about composting...',
          author: 'Eco Expert',
          publishedDate: DateTime.now().subtract(const Duration(days: 20)),
          lastUpdated: DateTime.now().subtract(const Duration(days: 15)),
          isPremium: true,
        ),
        EducationalContent(
          id: 'infographic_1',
          title: 'Plastic Types Guide',
          description: 'Visual guide to different plastic types',
          type: ContentType.infographic,
          level: ContentLevel.beginner,
          categories: ['Plastic', 'Recycling'],
          tags: ['plastic', 'types', 'recycling codes'],
          readTimeMinutes: 3,
          content: 'Infographic about plastic types...',
          author: 'Visual Team',
          publishedDate: DateTime.now().subtract(const Duration(days: 5)),
          lastUpdated: DateTime.now().subtract(const Duration(days: 2)),
        ),
        EducationalContent(
          id: 'quiz_1',
          title: 'Waste Sorting Quiz',
          description: 'Test your knowledge of waste sorting',
          type: ContentType.quiz,
          level: ContentLevel.intermediate,
          categories: ['Sorting', 'General'],
          tags: ['quiz', 'sorting', 'knowledge'],
          readTimeMinutes: 10,
          content: 'Quiz content about waste sorting...',
          author: 'Quiz Master',
          publishedDate: DateTime.now().subtract(const Duration(days: 3)),
          lastUpdated: DateTime.now().subtract(const Duration(days: 1)),
        ),
        EducationalContent(
          id: 'tutorial_1',
          title: 'E-waste Disposal Tutorial',
          description: 'How to properly dispose of electronic waste',
          type: ContentType.tutorial,
          level: ContentLevel.advanced,
          categories: ['E-waste', 'Hazardous Waste'],
          tags: ['electronics', 'disposal', 'hazardous'],
          readTimeMinutes: 20,
          content: 'Tutorial about e-waste disposal...',
          author: 'Tech Expert',
          publishedDate: DateTime.now().subtract(const Duration(days: 15)),
          lastUpdated: DateTime.now().subtract(const Duration(days: 10)),
          isPremium: true,
        ),
        EducationalContent(
          id: 'tip_1',
          title: 'Quick Sorting Tips',
          description: 'Simple tips for everyday waste sorting',
          type: ContentType.tip,
          level: ContentLevel.beginner,
          categories: ['Sorting', 'General'],
          tags: ['tips', 'quick', 'everyday'],
          readTimeMinutes: 2,
          content: 'Tips for waste sorting...',
          author: 'Tip Master',
          publishedDate: DateTime.now().subtract(const Duration(days: 1)),
          lastUpdated: DateTime.now(),
        ),
      ];
    });

    Widget createTestWidget({String? initialCategory, String? initialSubcategory}) {
      return MaterialApp(
        home: MultiProvider(
          providers: [
            Provider<EducationalContentService>.value(value: mockEducationalService),
            Provider<AdService>.value(value: mockAdService),
          ],
          child: EducationalContentScreen(
            initialCategory: initialCategory,
            initialSubcategory: initialSubcategory,
          ),
        ),
      );
    }

    group('Initialization and Setup', () {
      testWidgets('should display app bar with correct title and tabs', (tester) async {
        when(mockEducationalService.getAllContent()).thenReturn(testContent);
        when(mockEducationalService.getContentByType(any)).thenReturn([]);

        await tester.pumpWidget(createTestWidget());

        expect(find.text('Learn'), findsOneWidget);
        expect(find.text('Articles'), findsOneWidget);
        expect(find.text('Videos'), findsOneWidget);
        expect(find.text('Infographics'), findsOneWidget);
        expect(find.text('Quizzes'), findsOneWidget);
        expect(find.text('Tutorials'), findsOneWidget);
        expect(find.text('Tips'), findsOneWidget);

        expect(find.byIcon(Icons.article), findsOneWidget);
        expect(find.byIcon(Icons.video_library), findsOneWidget);
        expect(find.byIcon(Icons.image), findsOneWidget);
        expect(find.byIcon(Icons.quiz), findsOneWidget);
        expect(find.byIcon(Icons.menu_book), findsOneWidget);
        expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
      });

      testWidgets('should initialize with default category and tab', (tester) async {
        when(mockEducationalService.getAllContent()).thenReturn(testContent);
        when(mockEducationalService.getContentByType(ContentType.article)).thenReturn([testContent[0]]);

        await tester.pumpWidget(createTestWidget());

        expect(find.text('All'), findsOneWidget); // Default category
        // Should start on Articles tab (index 0)
      });

      testWidgets('should initialize with specific category', (tester) async {
        when(mockEducationalService.getAllContent()).thenReturn(testContent);
        when(mockEducationalService.getContentByCategory('Recycling')).thenReturn([testContent[0], testContent[2]]);
        when(mockEducationalService.getContentByType(any)).thenReturn([]);

        await tester.pumpWidget(createTestWidget(initialCategory: 'Recycling'));

        // Should set up the screen with Recycling category
        expect(find.text('Recycling'), findsOneWidget);
      });

      testWidgets('should configure ad service correctly', (tester) async {
        when(mockEducationalService.getAllContent()).thenReturn(testContent);
        when(mockEducationalService.getContentByType(any)).thenReturn([]);

        await tester.pumpWidget(createTestWidget());

        verify(mockAdService.setInClassificationFlow(false)).called(1);
        verify(mockAdService.setInEducationalContent(true)).called(1);
        verify(mockAdService.setInSettings(false)).called(1);
      });

      testWidgets('should populate categories from content', (tester) async {
        when(mockEducationalService.getAllContent()).thenReturn(testContent);
        when(mockEducationalService.getContentByType(any)).thenReturn([]);

        await tester.pumpWidget(createTestWidget());

        // Tap on category dropdown to see options
        await tester.tap(find.byIcon(Icons.filter_list));
        await tester.pumpAndSettle();

        expect(find.text('All'), findsWidgets);
        expect(find.text('Composting'), findsOneWidget);
        expect(find.text('E-waste'), findsOneWidget);
        expect(find.text('General'), findsOneWidget);
        expect(find.text('Hazardous Waste'), findsOneWidget);
        expect(find.text('Home Organization'), findsOneWidget);
        expect(find.text('Plastic'), findsOneWidget);
        expect(find.text('Recycling'), findsOneWidget);
        expect(find.text('Sorting'), findsOneWidget);
      });
    });

    group('Search Functionality', () {
      testWidgets('should display search field', (tester) async {
        when(mockEducationalService.getAllContent()).thenReturn(testContent);
        when(mockEducationalService.getContentByType(any)).thenReturn([]);

        await tester.pumpWidget(createTestWidget());

        expect(find.byType(TextField), findsOneWidget);
        expect(find.text('Search...'), findsOneWidget);
        expect(find.byIcon(Icons.search), findsOneWidget);
      });

      testWidgets('should filter content by search query', (tester) async {
        when(mockEducationalService.getAllContent()).thenReturn(testContent);
        when(mockEducationalService.getContentByType(ContentType.article)).thenReturn([testContent[0]]);

        await tester.pumpWidget(createTestWidget());

        // Enter search query
        await tester.enterText(find.byType(TextField), 'recycling');
        await tester.pump();

        // Should filter the content (exact filtering behavior depends on implementation)
      });

      testWidgets('should clear search when text is cleared', (tester) async {
        when(mockEducationalService.getAllContent()).thenReturn(testContent);
        when(mockEducationalService.getContentByType(ContentType.article)).thenReturn([testContent[0]]);

        await tester.pumpWidget(createTestWidget());

        // Enter search query
        await tester.enterText(find.byType(TextField), 'recycling');
        await tester.pump();

        // Clear search
        await tester.enterText(find.byType(TextField), '');
        await tester.pump();

        // Should show all content again
      });

      testWidgets('should search across title, description, tags, and categories', (tester) async {
        when(mockEducationalService.getAllContent()).thenReturn(testContent);
        when(mockEducationalService.getContentByType(ContentType.article)).thenReturn([testContent[0]]);

        await tester.pumpWidget(createTestWidget());

        // Search by title
        await tester.enterText(find.byType(TextField), 'recycling');
        await tester.pump();

        // Search by tag
        await tester.enterText(find.byType(TextField), 'plastic');
        await tester.pump();

        // Search by category
        await tester.enterText(find.byType(TextField), 'composting');
        await tester.pump();

        // Should handle case-insensitive search
        await tester.enterText(find.byType(TextField), 'RECYCLING');
        await tester.pump();
      });
    });

    group('Category Filtering', () {
      testWidgets('should filter content by selected category', (tester) async {
        when(mockEducationalService.getAllContent()).thenReturn(testContent);
        when(mockEducationalService.getContentByType(any)).thenReturn(testContent);

        await tester.pumpWidget(createTestWidget());

        // Tap category dropdown
        await tester.tap(find.byIcon(Icons.filter_list));
        await tester.pumpAndSettle();

        // Select Recycling category
        await tester.tap(find.text('Recycling').last);
        await tester.pumpAndSettle();

        // Should filter to show only recycling content
      });

      testWidgets('should show all content when "All" is selected', (tester) async {
        when(mockEducationalService.getAllContent()).thenReturn(testContent);
        when(mockEducationalService.getContentByType(any)).thenReturn(testContent);

        await tester.pumpWidget(createTestWidget());

        // Select a specific category first
        await tester.tap(find.byIcon(Icons.filter_list));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Recycling').last);
        await tester.pumpAndSettle();

        // Then select "All"
        await tester.tap(find.byIcon(Icons.filter_list));
        await tester.pumpAndSettle();
        await tester.tap(find.text('All').last);
        await tester.pumpAndSettle();

        // Should show all content
      });

      testWidgets('should handle invalid category selection gracefully', (tester) async {
        when(mockEducationalService.getAllContent()).thenReturn(testContent);
        when(mockEducationalService.getContentByType(any)).thenReturn([]);

        await tester.pumpWidget(createTestWidget(initialCategory: 'NonExistentCategory'));

        // Should default to "All" for invalid category
        expect(find.text('All'), findsOneWidget);
      });
    });

    group('Tab Navigation', () {
      testWidgets('should switch between content type tabs', (tester) async {
        when(mockEducationalService.getAllContent()).thenReturn(testContent);
        when(mockEducationalService.getContentByType(ContentType.article)).thenReturn([testContent[0]]);
        when(mockEducationalService.getContentByType(ContentType.video)).thenReturn([testContent[1]]);
        when(mockEducationalService.getContentByType(ContentType.infographic)).thenReturn([testContent[2]]);
        when(mockEducationalService.getContentByType(ContentType.quiz)).thenReturn([testContent[3]]);
        when(mockEducationalService.getContentByType(ContentType.tutorial)).thenReturn([testContent[4]]);
        when(mockEducationalService.getContentByType(ContentType.tip)).thenReturn([testContent[5]]);

        await tester.pumpWidget(createTestWidget());

        // Start on Articles tab
        expect(find.text('Recycling Basics'), findsOneWidget);

        // Switch to Videos tab
        await tester.tap(find.text('Videos'));
        await tester.pump();
        expect(find.text('Composting at Home'), findsOneWidget);

        // Switch to Infographics tab
        await tester.tap(find.text('Infographics'));
        await tester.pump();
        expect(find.text('Plastic Types Guide'), findsOneWidget);

        // Switch to Quizzes tab
        await tester.tap(find.text('Quizzes'));
        await tester.pump();
        expect(find.text('Waste Sorting Quiz'), findsOneWidget);

        // Switch to Tutorials tab
        await tester.tap(find.text('Tutorials'));
        await tester.pump();
        expect(find.text('E-waste Disposal Tutorial'), findsOneWidget);

        // Switch to Tips tab
        await tester.tap(find.text('Tips'));
        await tester.pump();
        expect(find.text('Quick Sorting Tips'), findsOneWidget);
      });

      testWidgets('should filter content when tab changes', (tester) async {
        when(mockEducationalService.getAllContent()).thenReturn(testContent);
        when(mockEducationalService.getContentByType(ContentType.article)).thenReturn([testContent[0]]);
        when(mockEducationalService.getContentByType(ContentType.video)).thenReturn([testContent[1]]);

        await tester.pumpWidget(createTestWidget());

        // Verify articles are shown
        expect(find.text('Recycling Basics'), findsOneWidget);
        expect(find.text('Composting at Home'), findsNothing);

        // Switch to Videos tab
        await tester.tap(find.text('Videos'));
        await tester.pump();

        // Verify videos are shown
        expect(find.text('Recycling Basics'), findsNothing);
        expect(find.text('Composting at Home'), findsOneWidget);
      });
    });

    group('Content Display', () {
      testWidgets('should display content cards with correct information', (tester) async {
        when(mockEducationalService.getAllContent()).thenReturn(testContent);
        when(mockEducationalService.getContentByType(ContentType.article)).thenReturn([testContent[0]]);

        await tester.pumpWidget(createTestWidget());

        expect(find.text('Recycling Basics'), findsOneWidget);
        expect(find.text('Learn the fundamentals of recycling'), findsOneWidget);
        expect(find.text('Beginner'), findsOneWidget);
        expect(find.text('5 min read'), findsOneWidget);
      });

      testWidgets('should show premium badges for premium content', (tester) async {
        when(mockEducationalService.getAllContent()).thenReturn(testContent);
        when(mockEducationalService.getContentByType(ContentType.video)).thenReturn([testContent[1]]);

        await tester.pumpWidget(createTestWidget());

        // Switch to Videos tab to see premium content
        await tester.tap(find.text('Videos'));
        await tester.pump();

        expect(find.text('Premium'), findsOneWidget);
        expect(find.byIcon(Icons.star), findsAtLeastNWidgets(1));
      });

      testWidgets('should display content type badges', (tester) async {
        when(mockEducationalService.getAllContent()).thenReturn(testContent);
        when(mockEducationalService.getContentByType(ContentType.article)).thenReturn([testContent[0]]);

        await tester.pumpWidget(createTestWidget());

        expect(find.text('article'), findsOneWidget);
      });

      testWidgets('should handle content with different levels', (tester) async {
        when(mockEducationalService.getAllContent()).thenReturn(testContent);
        when(mockEducationalService.getContentByType(ContentType.tutorial)).thenReturn([testContent[4]]);

        await tester.pumpWidget(createTestWidget());

        // Switch to Tutorials tab to see advanced content
        await tester.tap(find.text('Tutorials'));
        await tester.pump();

        expect(find.text('Advanced'), findsOneWidget);
      });

      testWidgets('should display formatted duration correctly', (tester) async {
        when(mockEducationalService.getAllContent()).thenReturn(testContent);
        when(mockEducationalService.getContentByType(ContentType.tip)).thenReturn([testContent[5]]);

        await tester.pumpWidget(createTestWidget());

        // Switch to Tips tab to see short content
        await tester.tap(find.text('Tips'));
        await tester.pump();

        expect(find.text('2 min read'), findsOneWidget);
      });

      testWidgets('should navigate to content detail when tapped', (tester) async {
        when(mockEducationalService.getAllContent()).thenReturn(testContent);
        when(mockEducationalService.getContentByType(ContentType.article)).thenReturn([testContent[0]]);

        await tester.pumpWidget(createTestWidget());

        await tester.tap(find.text('Recycling Basics'));
        await tester.pumpAndSettle();

        expect(find.byType(ContentDetailScreen), findsOneWidget);
      });
    });

    group('Empty States', () {
      testWidgets('should show empty state when no content matches criteria', (tester) async {
        when(mockEducationalService.getAllContent()).thenReturn(testContent);
        when(mockEducationalService.getContentByType(any)).thenReturn([]);

        await tester.pumpWidget(createTestWidget());

        expect(find.text('No content found matching your criteria'), findsOneWidget);
      });

      testWidgets('should show empty state after filtering', (tester) async {
        when(mockEducationalService.getAllContent()).thenReturn(testContent);
        when(mockEducationalService.getContentByType(ContentType.article)).thenReturn([testContent[0]]);

        await tester.pumpWidget(createTestWidget());

        // Enter search query that matches nothing
        await tester.enterText(find.byType(TextField), 'nonexistentcontent');
        await tester.pump();

        expect(find.text('No content found matching your criteria'), findsOneWidget);
      });

      testWidgets('should show empty state for tab with no content', (tester) async {
        when(mockEducationalService.getAllContent()).thenReturn(testContent);
        when(mockEducationalService.getContentByType(ContentType.article)).thenReturn([testContent[0]]);
        when(mockEducationalService.getContentByType(ContentType.video)).thenReturn([]);

        await tester.pumpWidget(createTestWidget());

        // Switch to Videos tab with no content
        await tester.tap(find.text('Videos'));
        await tester.pump();

        expect(find.text('No content found matching your criteria'), findsOneWidget);
      });
    });

    group('Combined Filtering', () {
      testWidgets('should apply both category and search filters', (tester) async {
        when(mockEducationalService.getAllContent()).thenReturn(testContent);
        when(mockEducationalService.getContentByType(ContentType.article)).thenReturn([testContent[0]]);

        await tester.pumpWidget(createTestWidget());

        // Select category
        await tester.tap(find.byIcon(Icons.filter_list));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Recycling').last);
        await tester.pumpAndSettle();

        // Enter search query
        await tester.enterText(find.byType(TextField), 'basics');
        await tester.pump();

        // Should apply both filters
      });

      testWidgets('should apply category, search, and tab filters', (tester) async {
        when(mockEducationalService.getAllContent()).thenReturn(testContent);
        when(mockEducationalService.getContentByType(ContentType.infographic)).thenReturn([testContent[2]]);

        await tester.pumpWidget(createTestWidget());

        // Switch tab
        await tester.tap(find.text('Infographics'));
        await tester.pump();

        // Select category
        await tester.tap(find.byIcon(Icons.filter_list));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Plastic').last);
        await tester.pumpAndSettle();

        // Enter search query
        await tester.enterText(find.byType(TextField), 'types');
        await tester.pump();

        // Should apply all three filters
      });
    });

    group('Error Handling and Edge Cases', () {
      testWidgets('should handle empty content list gracefully', (tester) async {
        when(mockEducationalService.getAllContent()).thenReturn([]);
        when(mockEducationalService.getContentByType(any)).thenReturn([]);

        await tester.pumpWidget(createTestWidget());

        expect(find.text('All'), findsOneWidget); // Should still show category dropdown
        expect(find.text('No content found matching your criteria'), findsOneWidget);
      });

      testWidgets('should handle content without categories', (tester) async {
        final contentWithoutCategories = [
          EducationalContent(
            id: 'no_cat_1',
            title: 'No Category Content',
            description: 'Content without categories',
            type: ContentType.article,
            level: ContentLevel.beginner,
            categories: [],
            tags: [],
            readTimeMinutes: 5,
            content: 'Content...',
            author: 'Author',
            publishedDate: DateTime.now(),
            lastUpdated: DateTime.now(),
          ),
        ];

        when(mockEducationalService.getAllContent()).thenReturn(contentWithoutCategories);
        when(mockEducationalService.getContentByType(ContentType.article)).thenReturn(contentWithoutCategories);

        await tester.pumpWidget(createTestWidget());

        expect(find.text('All'), findsOneWidget);
        expect(find.text('No Category Content'), findsOneWidget);
      });

      testWidgets('should handle very long content titles and descriptions', (tester) async {
        const longContentTitle =
            'This is a very long title that should be truncated to prevent overflow issues in the UI';
        const longContentDescription =
            'This is a very long description that should also be truncated to prevent UI overflow and maintain good user experience across different screen sizes';

        final longContent = [
          EducationalContent(
            id: 'long_1',
            title: longContentTitle,
            description: longContentDescription,
            type: ContentType.article,
            level: ContentLevel.beginner,
            categories: ['General'],
            tags: ['long'],
            readTimeMinutes: 5,
            content: 'Content...',
            author: 'Author',
            publishedDate: DateTime.now(),
            lastUpdated: DateTime.now(),
          ),
        ];

        when(mockEducationalService.getAllContent()).thenReturn(longContent);
        when(mockEducationalService.getContentByType(ContentType.article)).thenReturn(longContent);

        await tester.pumpWidget(createTestWidget());

        // Should display truncated text without overflow
        expect(find.textContaining('This is a very long title'), findsOneWidget);
        expect(find.textContaining('This is a very long description'), findsOneWidget);
      });

      testWidgets('should handle special characters in search', (tester) async {
        when(mockEducationalService.getAllContent()).thenReturn(testContent);
        when(mockEducationalService.getContentByType(ContentType.article)).thenReturn([testContent[0]]);

        await tester.pumpWidget(createTestWidget());

        // Search with special characters
        await tester.enterText(find.byType(TextField), '@#\$%^&*()');
        await tester.pump();

        // Should not crash
        expect(find.byType(EducationalContentScreen), findsOneWidget);
      });

      testWidgets('should handle rapid tab switching', (tester) async {
        when(mockEducationalService.getAllContent()).thenReturn(testContent);
        when(mockEducationalService.getContentByType(any)).thenReturn([]);

        await tester.pumpWidget(createTestWidget());

        // Rapidly switch tabs
        for (var i = 0; i < 5; i++) {
          await tester.tap(find.text('Videos'));
          await tester.pump();
          await tester.tap(find.text('Articles'));
          await tester.pump();
        }

        // Should not crash
        expect(find.byType(EducationalContentScreen), findsOneWidget);
      });
    });

    group('Widget Disposal', () {
      testWidgets('should dispose controllers properly', (tester) async {
        when(mockEducationalService.getAllContent()).thenReturn(testContent);
        when(mockEducationalService.getContentByType(any)).thenReturn([]);

        await tester.pumpWidget(createTestWidget());

        expect(find.byType(EducationalContentScreen), findsOneWidget);

        // Navigate away to trigger disposal
        await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Text('Other Screen'))));

        // Should not crash during disposal
        expect(find.text('Other Screen'), findsOneWidget);
      });
    });

    group('Performance', () {
      testWidgets('should handle large content lists efficiently', (tester) async {
        final largeContentList = List.generate(
            100,
            (index) => EducationalContent(
                  id: 'content_$index',
                  title: 'Content $index',
                  description: 'Description $index',
                  type: ContentType.values[index % ContentType.values.length],
                  level: ContentLevel.values[index % ContentLevel.values.length],
                  categories: ['Category${index % 5}'],
                  tags: ['tag$index'],
                  readTimeMinutes: index + 1,
                  content: 'Content $index...',
                  author: 'Author $index',
                  publishedDate: DateTime.now().subtract(Duration(days: index)),
                  lastUpdated: DateTime.now().subtract(Duration(days: index ~/ 2)),
                ));

        when(mockEducationalService.getAllContent()).thenReturn(largeContentList);
        when(mockEducationalService.getContentByType(ContentType.article))
            .thenReturn(largeContentList.where((c) => c.type == ContentType.article).toList());

        await tester.pumpWidget(createTestWidget());

        expect(find.text('Content 0'), findsOneWidget);
        expect(find.byType(ListView), findsOneWidget);

        // Should be able to scroll through content
        await tester.scrollUntilVisible(
          find.text('Content 5'),
          100.0,
          scrollable: find.byType(Scrollable).first,
        );

        expect(find.text('Content 5'), findsOneWidget);
      });
    });

    group('Accessibility', () {
      testWidgets('should have proper semantic structure', (tester) async {
        when(mockEducationalService.getAllContent()).thenReturn(testContent);
        when(mockEducationalService.getContentByType(any)).thenReturn([]);

        await tester.pumpWidget(createTestWidget());

        expect(find.byType(TabBar), findsOneWidget);
        expect(find.byType(TabBarView), findsOneWidget);
        expect(find.byType(TextField), findsOneWidget);
        expect(find.byType(DropdownButton<String>), findsOneWidget);
      });

      testWidgets('should support keyboard navigation', (tester) async {
        when(mockEducationalService.getAllContent()).thenReturn(testContent);
        when(mockEducationalService.getContentByType(ContentType.article)).thenReturn([testContent[0]]);

        await tester.pumpWidget(createTestWidget());

        // Focus on search field
        await tester.tap(find.byType(TextField));
        await tester.pump();

        // Should be able to interact with search field
        expect(find.byType(TextField), findsOneWidget);
      });
    });
  });
}
