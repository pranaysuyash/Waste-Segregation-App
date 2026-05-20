import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/shared_waste_classification.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import 'package:waste_segregation_app/models/gamification.dart';

void main() {
  group('SharedWasteClassification Model Tests', () {
    test('should create SharedWasteClassification', () {
      final classification = WasteClassification(
        itemName: 'Test Item',
        explanation: 'Test explanation',
        category: 'plastic',
        region: 'Test Region',
        visualFeatures: ['test feature'],
        alternatives: [],
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Test method',
          steps: ['Test step'],
          hasUrgentTimeframe: false,
        ),
      );

      final shared = SharedWasteClassification(
        id: 'shared_001',
        classification: classification,
        sharedBy: 'user123',
        sharedByDisplayName: 'John Doe',
        sharedAt: DateTime.now(),
        familyId: 'family456',
      );

      expect(shared.id, 'shared_001');
      expect(shared.sharedBy, 'user123');
      expect(shared.sharedByDisplayName, 'John Doe');
      expect(shared.familyId, 'family456');
    });

    test('should create from fromClassification factory', () {
      final classification = WasteClassification(
        itemName: 'Test Item',
        explanation: 'Test explanation',
        category: 'plastic',
        region: 'Test Region',
        visualFeatures: ['test feature'],
        alternatives: [],
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Test method',
          steps: ['Test step'],
          hasUrgentTimeframe: false,
        ),
      );

      final shared = SharedWasteClassification.fromClassification(
        classification: classification,
        sharedBy: 'user456',
        sharedByDisplayName: 'Jane Smith',
        familyId: 'family789',
        location: ClassificationLocation(city: 'Bangalore'),
      );

      expect(shared.sharedBy, 'user456');
      expect(shared.familyId, 'family789');
      expect(shared.location?.city, 'Bangalore');
    });

    test('should serialize to and from JSON', () {
      final classification = WasteClassification(
        id: 'class_001',
        itemName: 'Test Item',
        explanation: 'Test explanation',
        category: 'plastic',
        region: 'Test Region',
        visualFeatures: ['test feature'],
        alternatives: [],
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Test method',
          steps: ['Test step'],
          hasUrgentTimeframe: false,
        ),
      );

      final shared = SharedWasteClassification(
        id: 'shared_001',
        classification: classification,
        sharedBy: 'user123',
        sharedByDisplayName: 'John Doe',
        sharedAt: DateTime(2024, 1, 15, 11),
        familyId: 'family456',
        familyTags: ['tag1', 'tag2'],
      );

      final json = shared.toJson();
      final restored = SharedWasteClassification.fromJson(json);

      expect(restored.id, shared.id);
      expect(restored.sharedBy, shared.sharedBy);
      expect(restored.sharedByDisplayName, shared.sharedByDisplayName);
      expect(restored.familyTags, shared.familyTags);
    });

    test('should calculate last activity timestamp', () {
      final classification = WasteClassification(
        itemName: 'Test',
        explanation: 'Test',
        category: 'plastic',
        region: 'Test',
        visualFeatures: [],
        alternatives: [],
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Test',
          steps: ['Test'],
          hasUrgentTimeframe: false,
        ),
      );

      final shared = SharedWasteClassification(
        id: 'shared_001',
        classification: classification,
        sharedBy: 'user123',
        sharedByDisplayName: 'John Doe',
        sharedAt: DateTime(2024, 1, 15, 10),
        familyId: 'family456',
        reactions: [
          FamilyReaction(
            userId: 'user2',
            displayName: 'User 2',
            type: FamilyReactionType.like,
            timestamp: DateTime(2024, 1, 15, 12),
          ),
        ],
      );

      expect(shared.lastActivityTimestamp, DateTime(2024, 1, 15, 12));
      expect(shared.engagementCount, 1);
    });

    test('should check user reactions', () {
      final classification = WasteClassification(
        itemName: 'Test',
        explanation: 'Test',
        category: 'plastic',
        region: 'Test',
        visualFeatures: [],
        alternatives: [],
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Test',
          steps: ['Test'],
          hasUrgentTimeframe: false,
        ),
      );

      final shared = SharedWasteClassification(
        id: 'shared_001',
        classification: classification,
        sharedBy: 'user123',
        sharedByDisplayName: 'John Doe',
        sharedAt: DateTime.now(),
        familyId: 'family456',
        reactions: [
          FamilyReaction(
            userId: 'user2',
            displayName: 'User 2',
            type: FamilyReactionType.love,
            timestamp: DateTime.now(),
          ),
        ],
      );

      expect(shared.hasUserReacted('user2'), true);
      expect(shared.hasUserReacted('user3'), false);
      expect(shared.getUserReaction('user2')?.type, FamilyReactionType.love);
    });

    test('should get top level comments', () {
      final classification = WasteClassification(
        itemName: 'Test',
        explanation: 'Test',
        category: 'plastic',
        region: 'Test',
        visualFeatures: [],
        alternatives: [],
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Test',
          steps: ['Test'],
          hasUrgentTimeframe: false,
        ),
      );

      final reply = FamilyComment.create(
        userId: 'user2',
        displayName: 'User 2',
        text: 'A reply',
        parentCommentId: 'parent',
      );

      final shared = SharedWasteClassification(
        id: 'shared_001',
        classification: classification,
        sharedBy: 'user123',
        sharedByDisplayName: 'John Doe',
        sharedAt: DateTime.now(),
        familyId: 'family456',
        comments: [
          reply,
        ],
      );

      expect(shared.topLevelComments, isEmpty);
      expect(shared.totalCommentCount, 1);
    });

    test('should check if from today', () {
      final classification = WasteClassification(
        itemName: 'Test',
        explanation: 'Test',
        category: 'plastic',
        region: 'Test',
        visualFeatures: [],
        alternatives: [],
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Test',
          steps: ['Test'],
          hasUrgentTimeframe: false,
        ),
      );

      final shared = SharedWasteClassification(
        id: 'shared_001',
        classification: classification,
        sharedBy: 'user123',
        sharedByDisplayName: 'John Doe',
        sharedAt: DateTime.now(),
        familyId: 'family456',
      );

      expect(shared.isFromToday, true);
    });

    test('should get time ago text', () {
      final classification = WasteClassification(
        itemName: 'Test',
        explanation: 'Test',
        category: 'plastic',
        region: 'Test',
        visualFeatures: [],
        alternatives: [],
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Test',
          steps: ['Test'],
          hasUrgentTimeframe: false,
        ),
      );

      final justNow = SharedWasteClassification(
        id: 'shared_1',
        classification: classification,
        sharedBy: 'user123',
        sharedByDisplayName: 'John Doe',
        sharedAt: DateTime.now(),
        familyId: 'family456',
      );

      final hoursAgo = SharedWasteClassification(
        id: 'shared_2',
        classification: classification,
        sharedBy: 'user123',
        sharedByDisplayName: 'John Doe',
        sharedAt: DateTime.now().subtract(const Duration(hours: 3)),
        familyId: 'family456',
      );

      expect(justNow.timeAgo, 'Just now');
      expect(hoursAgo.timeAgo, '3h ago');
    });

    test('should copyWith correctly', () {
      final classification = WasteClassification(
        itemName: 'Test',
        explanation: 'Test',
        category: 'plastic',
        region: 'Test',
        visualFeatures: [],
        alternatives: [],
        disposalInstructions: DisposalInstructions(
          primaryMethod: 'Test',
          steps: ['Test'],
          hasUrgentTimeframe: false,
        ),
      );

      final shared = SharedWasteClassification(
        id: 'shared_001',
        classification: classification,
        sharedBy: 'user123',
        sharedByDisplayName: 'John Doe',
        sharedAt: DateTime.now(),
        familyId: 'family456',
        isVisible: true,
      );

      final updated = shared.copyWith(isVisible: false);
      expect(updated.isVisible, false);
      expect(shared.isVisible, true);
    });
  });
}
