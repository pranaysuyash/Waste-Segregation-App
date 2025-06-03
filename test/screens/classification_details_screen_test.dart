import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/gamification.dart';
import 'package:waste_segregation_app/models/shared_waste_classification.dart';
import 'package:waste_segregation_app/models/waste_classification.dart' as wc_model;
import 'package:waste_segregation_app/screens/classification_details_screen.dart';
import 'package:waste_segregation_app/utils/constants.dart'; // For AppTheme

// Helper functions (can be shared if multiple test files need them)
SharedWasteClassification createMockSharedClassification({
  String id = 'shared1',
  String itemName = 'Plastic Water Bottle',
  String category = 'Plastic',
  String? subcategory = 'PET',
  String? imageUrl,
  String sharedByDisplayName = 'Sharer User',
  DateTime? sharedAt,
  List<FamilyReaction> reactions = const [],
  List<FamilyComment> comments = const [],
}) {
  return SharedWasteClassification(
    id: id,
    classification: wc_model.WasteClassification(
      id: 'wc-$id',
      itemName: itemName,
      category: category,
      subcategory: subcategory,
      explanation: 'A common plastic water bottle, usually recyclable.',
      disposalInstructions: wc_model.DisposalInstructions(
        primaryMethod: 'Recycling Bin',
        steps: ['Empty contents', 'Rinse if possible', 'Place in recycling bin'],
      ),
      imageUrl: imageUrl,
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    sharedBy: 'sharerUserId',
    sharedByDisplayName: sharedByDisplayName,
    sharedAt: sharedAt ?? DateTime.now().subtract(const Duration(minutes: 30)),
    familyId: 'fam1',
    reactions: reactions,
    comments: comments,
  );
}

FamilyReaction createMockReaction({
  String userId = 'user1',
  String displayName = 'Reactor One',
  String? photoUrl,
  FamilyReactionType type = FamilyReactionType.like,
  DateTime? timestamp,
}) {
  return FamilyReaction(
    userId: userId,
    displayName: displayName,
    photoUrl: photoUrl,
    type: type,
    timestamp: timestamp ?? DateTime.now().subtract(const Duration(minutes: 10)),
  );
}

FamilyComment createMockComment({
  String id = 'comment1',
  String userId = 'user2',
  String displayName = 'Commenter Two',
  String? photoUrl,
  String text = 'Great find!',
  DateTime? timestamp,
}) {
  return FamilyComment(
    id: id,
    userId: userId,
    displayName: displayName,
    photoUrl: photoUrl,
    text: text,
    timestamp: timestamp ?? DateTime.now().subtract(const Duration(minutes: 5)),
  );
}


void main() {
  Widget createTestableWidget(Widget child) {
    return MaterialApp(
      home: child,
      theme: ThemeData( // Apply a theme similar to the app's for consistency
        primaryColor: AppTheme.primaryColor,
        colorScheme: ColorScheme.fromSeed(seedColor: AppTheme.primaryColor),
        textTheme: AppTheme.textTheme,
        cardTheme: AppTheme.cardTheme,
      ),
    );
  }

  group('ClassificationDetailsScreen Tests', () {
    testWidgets('Displays basic classification info correctly', (WidgetTester tester) async {
      final mockClassification = createMockSharedClassification(
        itemName: 'Old Newspaper',
        category: 'Paper',
        subcategory: 'Newsprint',
        sharedByDisplayName: 'Alice',
        imageUrl: 'https://example.com/newspaper.jpg',
      );

      await tester.pumpWidget(createTestableWidget(ClassificationDetailsScreen(classification: mockClassification)));

      expect(find.text('Old Newspaper'), findsOneWidget); // AppBar title
      expect(find.text('Item: Old Newspaper'), findsOneWidget);
      expect(find.text('Category: Paper'), findsOneWidget);
      expect(find.text('Subcategory: Newsprint'), findsOneWidget);
      expect(find.text('Shared by: Alice'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget); // Check for Image widget
      // Note: Testing actual network image loading is complex and often skipped in unit/widget tests.
      // Here, we just check if the Image widget is part of the tree.
    });

    testWidgets('Displays "No reactions yet" when reactions list is empty', (WidgetTester tester) async {
      final mockClassification = createMockSharedClassification(reactions: []);
      await tester.pumpWidget(createTestableWidget(ClassificationDetailsScreen(classification: mockClassification)));
      expect(find.text('No reactions yet.'), findsOneWidget);
    });

    testWidgets('Displays reactions list correctly', (WidgetTester tester) async {
      final reactions = [
        createMockReaction(displayName: 'Bob'),
        createMockReaction(displayName: 'Charlie', type: FamilyReactionType.love, photoUrl: 'https://example.com/charlie.jpg'),
      ];
      final mockClassification = createMockSharedClassification(reactions: reactions);

      await tester.pumpWidget(createTestableWidget(ClassificationDetailsScreen(classification: mockClassification)));

      expect(find.text('Reactions'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      expect(find.textContaining('👍 like'), findsOneWidget); // Assuming _getReactionEmoji maps .like to 👍

      expect(find.text('Charlie'), findsOneWidget);
      expect(find.textContaining('❤️ love'), findsOneWidget);
      // Check if CircleAvatar for Charlie (with image) is present
      // This might require more specific finders if there are multiple CircleAvatars
    });

    testWidgets('Displays "No comments yet" when comments list is empty', (WidgetTester tester) async {
      final mockClassification = createMockSharedClassification(comments: []);
      await tester.pumpWidget(createTestableWidget(ClassificationDetailsScreen(classification: mockClassification)));
      expect(find.text('No comments yet.'), findsOneWidget);
    });

    testWidgets('Displays comments list correctly', (WidgetTester tester) async {
      final comments = [
        createMockComment(displayName: 'David', text: 'Very informative!'),
        createMockComment(displayName: 'Eve', text: 'Thanks for sharing.', photoUrl: 'https://example.com/eve.jpg'),
      ];
      final mockClassification = createMockSharedClassification(comments: comments);

      await tester.pumpWidget(createTestableWidget(ClassificationDetailsScreen(classification: mockClassification)));

      expect(find.text('Comments'), findsOneWidget);
      expect(find.text('David'), findsOneWidget);
      expect(find.text('Very informative!'), findsOneWidget);

      expect(find.text('Eve'), findsOneWidget);
      expect(find.text('Thanks for sharing.'), findsOneWidget);
    });

    testWidgets('Displays correct date format for sharedAt and comment timestamps', (WidgetTester tester) async {
      final fixedTime = DateTime(2023, 1, 1, 10, 0); // Known past time
      final mockClassification = createMockSharedClassification(
        sharedAt: fixedTime,
        comments: [createMockComment(displayName: 'TestCommenter', text: 'Test', timestamp: fixedTime.add(const Duration(hours:1)))]
      );

      await tester.pumpWidget(createTestableWidget(ClassificationDetailsScreen(classification: mockClassification)));

      // Example: if current time makes sharedAt > 7 days ago
      // This test is a bit fragile due to "time ago" logic.
      // A more robust way is to mock DateTime.now() or test the _formatDate helper separately.
      // For widget test, checking for a part of the expected string can be an option.
      expect(find.textContaining('1/1/2023'), findsWidgets); // Shared on and comment on
    });

  });
}
