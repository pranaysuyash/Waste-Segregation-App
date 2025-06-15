import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/shared_waste_classification.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';

void main() {
  group('SharedWasteClassification Model Tests', () {
    group('SharedWasteClassification Model', () {
      test('should create SharedWasteClassification with all required properties', () {
        final originalClassification = WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
          id: 'class_001',
          imageUrl: '/path/to/image.jpg',
          confidence: 0.95,
            region: 'Test Region',
            visualFeatures: ['test feature'],
            alternatives: [],
          timestamp: DateTime(2024, 1, 15, 10, 30),
        );

        final sharedClassification = SharedWasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
          id: 'shared_001',
          originalClassification: originalClassification,
          sharedBy: 'user123',
          sharedByName: 'John Doe',
          sharedAt: DateTime(2024, 1, 15, 11),
          visibility: SharingVisibility.public,
          familyId: 'family456',
        );

        expect(sharedClassification.id, 'shared_001');
        expect(sharedClassification.originalClassification, originalClassification);
        expect(sharedClassification.sharedBy, 'user123');
        expect(sharedClassification.sharedByName, 'John Doe');
        expect(sharedClassification.sharedAt, DateTime(2024, 1, 15, 11));
        expect(sharedClassification.visibility, SharingVisibility.public);
        expect(sharedClassification.familyId, 'family456');
      });

      test('should create SharedWasteClassification with optional properties', () {
        final originalClassification = WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
          id: 'class_002',
          imageUrl: '/path/to/image2.jpg',
          confidence: 0.88,
            region: 'Test Region',
            visualFeatures: ['test feature'],
            alternatives: [],
          timestamp: DateTime(2024, 1, 15, 10, 30),
        );

        final sharedClassification = SharedWasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
          id: 'shared_002',
          originalClassification: originalClassification,
          sharedBy: 'user456',
          sharedByName: 'Jane Smith',
          sharedAt: DateTime(2024, 1, 15, 11),
          visibility: SharingVisibility.family,
          familyId: 'family789',
          description: 'Great example of paper waste',
          tags: ['paper', 'recyclable', 'example'],
          likes: 5,
          comments: [
            SharingComment(
              id: 'comment_001',
              userId: 'user789',
              userName: 'Alice Brown',
              content: 'Great classification!',
              timestamp: DateTime(2024, 1, 15, 12),
            ),
          ],
          sharingSettings: SharingSettings(
            allowComments: true,
            allowLikes: true,
            allowSharing: false,
            isAnonymous: false,
          ),
        );

        expect(sharedClassification.description, 'Great example of paper waste');
        expect(sharedClassification.tags, ['paper', 'recyclable', 'example']);
        expect(sharedClassification.likes, 5);
        expect(sharedClassification.comments.length, 1);
        expect(sharedClassification.comments[0].content, 'Great classification!');
        expect(sharedClassification.sharingSettings?.allowComments, true);
      });

      test('should serialize SharedWasteClassification to JSON correctly', () {
        final originalClassification = WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
          id: 'class_003',
          imageUrl: '/path/to/image3.jpg',
          confidence: 0.92,
            region: 'Test Region',
            visualFeatures: ['test feature'],
            alternatives: [],
          timestamp: DateTime(2024, 1, 15, 10, 30),
        );

        final sharedClassification = SharedWasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
          id: 'shared_003',
          originalClassification: originalClassification,
          sharedBy: 'user123',
          sharedByName: 'John Doe',
          sharedAt: DateTime(2024, 1, 15, 11),
          visibility: SharingVisibility.public,
          description: 'Glass bottle example',
          tags: ['glass', 'bottle'],
          likes: 3,
        );

        final json = sharedClassification.toJson();

        expect(json['id'], 'shared_003');
        expect(json['originalClassification'], isA<Map<String, dynamic>>());
        expect(json['sharedBy'], 'user123');
        expect(json['sharedByName'], 'John Doe');
        expect(json['sharedAt'], isA<String>());
        expect(json['visibility'], 'public');
        expect(json['description'], 'Glass bottle example');
        expect(json['tags'], ['glass', 'bottle']);
        expect(json['likes'], 3);
      });

      test('should deserialize SharedWasteClassification from JSON correctly', () {
        final json = {
          'id': 'shared_004',
          'originalClassification': {
            'id': 'class_004',
            'imagePath': '/path/to/image4.jpg',
            'category': 'organic',
            'confidence': 0.89,
            'disposalInstructions': 'Place in compost bin',
            'timestamp': '2024-01-15T10:30:00.000',
          },
          'sharedBy': 'user456',
          'sharedByName': 'Jane Smith',
          'sharedAt': '2024-01-15T11:00:00.000',
          'visibility': 'family',
          'familyId': 'family789',
          'description': 'Composting example',
          'tags': ['organic', 'compost'],
          'likes': 2,
          'comments': [
            {
              'id': 'comment_001',
              'userId': 'user789',
              'userName': 'Alice Brown',
              'content': 'Good example!',
              'timestamp': '2024-01-15T12:00:00.000',
            }
          ],
        };

        final sharedClassification = SharedWasteClassification.fromJson(json);

        expect(sharedClassification.id, 'shared_004');
        expect(sharedClassification.originalClassification.category, 'organic');
        expect(sharedClassification.sharedBy, 'user456');
        expect(sharedClassification.sharedByName, 'Jane Smith');
        expect(sharedClassification.visibility, SharingVisibility.family);
        expect(sharedClassification.familyId, 'family789');
        expect(sharedClassification.description, 'Composting example');
        expect(sharedClassification.tags, ['organic', 'compost']);
        expect(sharedClassification.likes, 2);
        expect(sharedClassification.comments.length, 1);
      });

      test('should check if classification can be viewed by user', () {
        final publicClassification = SharedWasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
          id: 'shared_public',
          originalClassification: WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
            id: 'class', imageUrl: '/path', category: 'plastic',
            confidence: 0.9, disposalInstructions: DisposalInstructions(primaryMethod: 'Recycle', steps: ['Test step'], hasUrgentTimeframe: false),
            timestamp: DateTime.now(),
          ),
          sharedBy: 'user123',
          sharedByName: 'John Doe',
          sharedAt: DateTime.now(),
          visibility: SharingVisibility.public,
        );

        final familyClassification = SharedWasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
          id: 'shared_family',
          originalClassification: WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
            id: 'class', imageUrl: '/path', category: 'plastic',
            confidence: 0.9, disposalInstructions: DisposalInstructions(primaryMethod: 'Recycle', steps: ['Test step'], hasUrgentTimeframe: false),
            timestamp: DateTime.now(),
          ),
          sharedBy: 'user123',
          sharedByName: 'John Doe',
          sharedAt: DateTime.now(),
          visibility: SharingVisibility.family,
          familyId: 'family456',
        );

        final privateClassification = SharedWasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
          id: 'shared_private',
          originalClassification: WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
            id: 'class', imageUrl: '/path', category: 'plastic',
            confidence: 0.9, disposalInstructions: DisposalInstructions(primaryMethod: 'Recycle', steps: ['Test step'], hasUrgentTimeframe: false),
            timestamp: DateTime.now(),
          ),
          sharedBy: 'user123',
          sharedByName: 'John Doe',
          sharedAt: DateTime.now(),
          visibility: SharingVisibility.private,
        );

        // Public can be viewed by anyone
        expect(publicClassification.canBeViewedBy('user456', null), true);
        expect(publicClassification.canBeViewedBy('user456', 'family789'), true);

        // Family can only be viewed by family members
        expect(familyClassification.canBeViewedBy('user456', 'family456'), true);
        expect(familyClassification.canBeViewedBy('user456', 'family789'), false);
        expect(familyClassification.canBeViewedBy('user456', null), false);

        // Private can only be viewed by owner
        expect(privateClassification.canBeViewedBy('user123', null), true);
        expect(privateClassification.canBeViewedBy('user456', null), false);
      });

      test('should check if classification can be liked by user', () {
        final sharedClassification = SharedWasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
          id: 'shared_001',
          originalClassification: WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
            id: 'class', imageUrl: '/path', category: 'plastic',
            confidence: 0.9, disposalInstructions: DisposalInstructions(primaryMethod: 'Recycle', steps: ['Test step'], hasUrgentTimeframe: false),
            timestamp: DateTime.now(),
          ),
          sharedBy: 'user123',
          sharedByName: 'John Doe',
          sharedAt: DateTime.now(),
          visibility: SharingVisibility.public,
          sharingSettings: SharingSettings(
            allowLikes: true,
            allowComments: true,
            allowSharing: true,
          ),
        );

        final noLikesClassification = SharedWasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
          id: 'shared_002',
          originalClassification: WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
            id: 'class', imageUrl: '/path', category: 'plastic',
            confidence: 0.9, disposalInstructions: DisposalInstructions(primaryMethod: 'Recycle', steps: ['Test step'], hasUrgentTimeframe: false),
            timestamp: DateTime.now(),
          ),
          sharedBy: 'user123',
          sharedByName: 'John Doe',
          sharedAt: DateTime.now(),
          visibility: SharingVisibility.public,
          sharingSettings: SharingSettings(
            allowLikes: false,
            allowComments: true,
            allowSharing: true,
          ),
        );

        expect(sharedClassification.canBeLikedBy('user456'), true);
        expect(sharedClassification.canBeLikedBy('user123'), false); // Can't like own post
        expect(noLikesClassification.canBeLikedBy('user456'), false);
      });

      test('should check if classification can be commented on', () {
        final sharedClassification = SharedWasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
          id: 'shared_001',
          originalClassification: WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
            id: 'class', imageUrl: '/path', category: 'plastic',
            confidence: 0.9, disposalInstructions: DisposalInstructions(primaryMethod: 'Recycle', steps: ['Test step'], hasUrgentTimeframe: false),
            timestamp: DateTime.now(),
          ),
          sharedBy: 'user123',
          sharedByName: 'John Doe',
          sharedAt: DateTime.now(),
          visibility: SharingVisibility.public,
          sharingSettings: SharingSettings(
            allowComments: true,
            allowLikes: true,
            allowSharing: true,
          ),
        );

        final noCommentsClassification = SharedWasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
          id: 'shared_002',
          originalClassification: WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
            id: 'class', imageUrl: '/path', category: 'plastic',
            confidence: 0.9, disposalInstructions: DisposalInstructions(primaryMethod: 'Recycle', steps: ['Test step'], hasUrgentTimeframe: false),
            timestamp: DateTime.now(),
          ),
          sharedBy: 'user123',
          sharedByName: 'John Doe',
          sharedAt: DateTime.now(),
          visibility: SharingVisibility.public,
          sharingSettings: SharingSettings(
            allowComments: false,
            allowLikes: true,
            allowSharing: true,
          ),
        );

        expect(sharedClassification.canBeCommentedBy('user456'), true);
        expect(sharedClassification.canBeCommentedBy('user123'), true); // Can comment on own post
        expect(noCommentsClassification.canBeCommentedBy('user456'), false);
      });

      test('should calculate engagement score', () {
        final sharedClassification = SharedWasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
          id: 'shared_001',
          originalClassification: WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
            id: 'class', imageUrl: '/path', category: 'plastic',
            confidence: 0.9, disposalInstructions: DisposalInstructions(primaryMethod: 'Recycle', steps: ['Test step'], hasUrgentTimeframe: false),
            timestamp: DateTime.now(),
          ),
          sharedBy: 'user123',
          sharedByName: 'John Doe',
          sharedAt: DateTime.now(),
          visibility: SharingVisibility.public,
          likes: 10,
          comments: List.generate(5, (index) => SharingComment(
            id: 'comment_$index',
            userId: 'user_$index',
            userName: 'User $index',
            content: 'Comment $index',
            timestamp: DateTime.now(),
          )),
          shareCount: 3,
          viewCount: 50,
        );

        // Engagement score calculation: likes + (comments * 2) + (shares * 3) + (views * 0.1)
        const expectedScore = 10 + (5 * 2) + (3 * 3) + (50 * 0.1);
        expect(sharedClassification.engagementScore, expectedScore);
      });

      test('should check if shared recently', () {
        final recentlyShared = SharedWasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
          id: 'shared_recent',
          originalClassification: WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
            id: 'class', imageUrl: '/path', category: 'plastic',
            confidence: 0.9, disposalInstructions: DisposalInstructions(primaryMethod: 'Recycle', steps: ['Test step'], hasUrgentTimeframe: false),
            timestamp: DateTime.now(),
          ),
          sharedBy: 'user123',
          sharedByName: 'John Doe',
          sharedAt: DateTime.now().subtract(const Duration(hours: 2)),
          visibility: SharingVisibility.public,
        );

        final oldShared = SharedWasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
          id: 'shared_old',
          originalClassification: WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
            id: 'class', imageUrl: '/path', category: 'plastic',
            confidence: 0.9, disposalInstructions: DisposalInstructions(primaryMethod: 'Recycle', steps: ['Test step'], hasUrgentTimeframe: false),
            timestamp: DateTime.now(),
          ),
          sharedBy: 'user123',
          sharedByName: 'John Doe',
          sharedAt: DateTime.now().subtract(const Duration(days: 10)),
          visibility: SharingVisibility.public,
        );

        expect(recentlyShared.isSharedRecently, true);
        expect(oldShared.isSharedRecently, false);
      });

      test('should get time since shared', () {
        final sharedClassification = SharedWasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
          id: 'shared_001',
          originalClassification: WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
            id: 'class', imageUrl: '/path', category: 'plastic',
            confidence: 0.9, disposalInstructions: DisposalInstructions(primaryMethod: 'Recycle', steps: ['Test step'], hasUrgentTimeframe: false),
            timestamp: DateTime.now(),
          ),
          sharedBy: 'user123',
          sharedByName: 'John Doe',
          sharedAt: DateTime.now().subtract(const Duration(hours: 5)),
          visibility: SharingVisibility.public,
        );

        expect(sharedClassification.timeSinceShared.inHours, 5);
      });
    });

    group('SharingComment Model', () {
      test('should create SharingComment with all properties', () {
        final comment = SharingComment(
          id: 'comment_001',
          userId: 'user123',
          userName: 'John Doe',
          content: 'Great classification example!',
          timestamp: DateTime(2024, 1, 15, 12),
        );

        expect(comment.id, 'comment_001');
        expect(comment.userId, 'user123');
        expect(comment.userName, 'John Doe');
        expect(comment.content, 'Great classification example!');
        expect(comment.timestamp, DateTime(2024, 1, 15, 12));
      });

      test('should create SharingComment with optional properties', () {
        final comment = SharingComment(
          id: 'comment_002',
          userId: 'user456',
          userName: 'Jane Smith',
          content: 'Very helpful, thanks!',
          timestamp: DateTime(2024, 1, 15, 12),
          likes: 3,
          isEdited: true,
          editedAt: DateTime(2024, 1, 15, 12, 5),
          replyToId: 'comment_001',
        );

        expect(comment.likes, 3);
        expect(comment.isEdited, true);
        expect(comment.editedAt, DateTime(2024, 1, 15, 12, 5));
        expect(comment.replyToId, 'comment_001');
      });

      test('should serialize SharingComment to JSON correctly', () {
        final comment = SharingComment(
          id: 'comment_003',
          userId: 'user789',
          userName: 'Alice Brown',
          content: 'Thanks for sharing!',
          timestamp: DateTime(2024, 1, 15, 12),
          likes: 2,
        );

        final json = comment.toJson();

        expect(json['id'], 'comment_003');
        expect(json['userId'], 'user789');
        expect(json['userName'], 'Alice Brown');
        expect(json['content'], 'Thanks for sharing!');
        expect(json['timestamp'], isA<String>());
        expect(json['likes'], 2);
      });

      test('should check if comment is a reply', () {
        final originalComment = SharingComment(
          id: 'comment_001',
          userId: 'user123',
          userName: 'John Doe',
          content: 'Great example!',
          timestamp: DateTime.now(),
        );

        final replyComment = SharingComment(
          id: 'comment_002',
          userId: 'user456',
          userName: 'Jane Smith',
          content: 'I agree!',
          timestamp: DateTime.now(),
          replyToId: 'comment_001',
        );

        expect(originalComment.isReply, false);
        expect(replyComment.isReply, true);
      });

      test('should check if comment was recently posted', () {
        final recentComment = SharingComment(
          id: 'comment_recent',
          userId: 'user123',
          userName: 'John Doe',
          content: 'Recent comment',
          timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        );

        final oldComment = SharingComment(
          id: 'comment_old',
          userId: 'user123',
          userName: 'John Doe',
          content: 'Old comment',
          timestamp: DateTime.now().subtract(const Duration(days: 5)),
        );

        expect(recentComment.isRecent, true);
        expect(oldComment.isRecent, false);
      });
    });

    group('SharingSettings Model', () {
      test('should create SharingSettings with all properties', () {
        final settings = SharingSettings(
          allowComments: true,
          allowLikes: true,
          allowSharing: false,
          isAnonymous: false,
        );

        expect(settings.allowComments, true);
        expect(settings.allowLikes, true);
        expect(settings.allowSharing, false);
        expect(settings.isAnonymous, false);
      });

      test('should create default sharing settings', () {
        final defaultSettings = SharingSettings.defaultSettings();

        expect(defaultSettings.allowComments, true);
        expect(defaultSettings.allowLikes, true);
        expect(defaultSettings.allowSharing, true);
        expect(defaultSettings.isAnonymous, false);
      });

      test('should create restrictive sharing settings', () {
        final restrictiveSettings = SharingSettings.restrictive();

        expect(restrictiveSettings.allowComments, false);
        expect(restrictiveSettings.allowLikes, false);
        expect(restrictiveSettings.allowSharing, false);
        expect(restrictiveSettings.isAnonymous, true);
      });

      test('should serialize SharingSettings to JSON correctly', () {
        final settings = SharingSettings(
          allowComments: true,
          allowLikes: false,
          allowSharing: true,
          isAnonymous: false,
        );

        final json = settings.toJson();

        expect(json['allowComments'], true);
        expect(json['allowLikes'], false);
        expect(json['allowSharing'], true);
        expect(json['isAnonymous'], false);
      });
    });

    group('Sharing Visibility', () {
      test('should handle all visibility levels', () {
        expect(SharingVisibility.public.displayName, 'Public');
        expect(SharingVisibility.family.displayName, 'Family Only');
        expect(SharingVisibility.private.displayName, 'Private');
        expect(SharingVisibility.friends.displayName, 'Friends Only');
      });

      test('should check visibility restrictions', () {
        expect(SharingVisibility.public.isRestrictedTo, null);
        expect(SharingVisibility.family.isRestrictedTo, 'family');
        expect(SharingVisibility.private.isRestrictedTo, 'self');
        expect(SharingVisibility.friends.isRestrictedTo, 'friends');
      });

      test('should order visibility by restrictiveness', () {
        final visibilityLevels = [
          SharingVisibility.private,
          SharingVisibility.public,
          SharingVisibility.family,
          SharingVisibility.friends,
        ];

        visibilityLevels.sort((a, b) => a.restrictionLevel.compareTo(b.restrictionLevel));

        expect(visibilityLevels[0], SharingVisibility.public);
        expect(visibilityLevels[1], SharingVisibility.friends);
        expect(visibilityLevels[2], SharingVisibility.family);
        expect(visibilityLevels[3], SharingVisibility.private);
      });
    });

    group('Validation', () {
      test('should validate shared classification content', () {
        expect(() => SharedWasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
          id: '', // Empty ID
          originalClassification: WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
            id: 'class', imageUrl: '/path', category: 'plastic',
            confidence: 0.9, disposalInstructions: DisposalInstructions(primaryMethod: 'Recycle', steps: ['Test step'], hasUrgentTimeframe: false),
            timestamp: DateTime.now(),
          ),
          sharedBy: 'user123',
          sharedByName: 'John Doe',
          sharedAt: DateTime.now(),
          visibility: SharingVisibility.public,
        ), throwsArgumentError);

        expect(() => SharedWasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
          id: 'shared_001',
          originalClassification: WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
            id: 'class', imageUrl: '/path', category: 'plastic',
            confidence: 0.9, disposalInstructions: DisposalInstructions(primaryMethod: 'Recycle', steps: ['Test step'], hasUrgentTimeframe: false),
            timestamp: DateTime.now(),
          ),
          sharedBy: '', // Empty shared by
          sharedByName: 'John Doe',
          sharedAt: DateTime.now(),
          visibility: SharingVisibility.public,
        ), throwsArgumentError);
      });

      test('should validate comment content', () {
        expect(() => SharingComment(
          id: 'comment_001',
          userId: 'user123',
          userName: 'John Doe',
          content: '', // Empty content
          timestamp: DateTime.now(),
        ), throwsArgumentError);

        expect(() => SharingComment(
          id: 'comment_001',
          userId: 'user123',
          userName: 'John Doe',
          content: 'a' * 1001, // Too long content
          timestamp: DateTime.now(),
        ), throwsArgumentError);
      });

      test('should validate negative values', () {
        expect(() => SharedWasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
          id: 'shared_001',
          originalClassification: WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
            id: 'class', imageUrl: '/path', category: 'plastic',
            confidence: 0.9, disposalInstructions: DisposalInstructions(primaryMethod: 'Recycle', steps: ['Test step'], hasUrgentTimeframe: false),
            timestamp: DateTime.now(),
          ),
          sharedBy: 'user123',
          sharedByName: 'John Doe',
          sharedAt: DateTime.now(),
          visibility: SharingVisibility.public,
          likes: -5, // Negative likes
        ), throwsArgumentError);

        expect(() => SharingComment(
          id: 'comment_001',
          userId: 'user123',
          userName: 'John Doe',
          content: 'Valid content',
          timestamp: DateTime.now(),
          likes: -2, // Negative likes
        ), throwsArgumentError);
      });
    });

    group('Equality and Comparison', () {
      test('should compare SharedWasteClassification for equality', () {
        final classification1 = SharedWasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
          id: 'shared_001',
          originalClassification: WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
            id: 'class', imageUrl: '/path', category: 'plastic',
            confidence: 0.9, disposalInstructions: DisposalInstructions(primaryMethod: 'Recycle', steps: ['Test step'], hasUrgentTimeframe: false),
            timestamp: DateTime(2024, 1, 15),
          ),
          sharedBy: 'user123',
          sharedByName: 'John Doe',
          sharedAt: DateTime(2024, 1, 15, 11),
          visibility: SharingVisibility.public,
        );

        final classification2 = SharedWasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
          id: 'shared_001',
          originalClassification: WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
            id: 'class', imageUrl: '/path', category: 'plastic',
            confidence: 0.9, disposalInstructions: DisposalInstructions(primaryMethod: 'Recycle', steps: ['Test step'], hasUrgentTimeframe: false),
            timestamp: DateTime(2024, 1, 15),
          ),
          sharedBy: 'user123',
          sharedByName: 'John Doe',
          sharedAt: DateTime(2024, 1, 15, 11),
          visibility: SharingVisibility.public,
        );

        final classification3 = SharedWasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
          id: 'shared_002',
          originalClassification: WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
            id: 'class2', imageUrl: '/path2', category: 'paper',
            confidence: 0.8, disposalInstructions: DisposalInstructions(primaryMethod: 'Recycle', steps: ['Test step'], hasUrgentTimeframe: false),
            timestamp: DateTime(2024, 1, 16),
          ),
          sharedBy: 'user456',
          sharedByName: 'Jane Smith',
          sharedAt: DateTime(2024, 1, 16, 11),
          visibility: SharingVisibility.family,
        );

        expect(classification1 == classification2, true);
        expect(classification1 == classification3, false);
        expect(classification1.hashCode == classification2.hashCode, true);
      });

      test('should sort shared classifications by engagement', () {
        final classifications = [
          SharedWasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
            id: 'shared_1',
            originalClassification: WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
              id: 'class', imageUrl: '/path', category: 'plastic',
              confidence: 0.9, disposalInstructions: DisposalInstructions(primaryMethod: 'Recycle', steps: ['Test step'], hasUrgentTimeframe: false),
              timestamp: DateTime.now(),
            ),
            sharedBy: 'user123', sharedByName: 'John Doe',
            sharedAt: DateTime.now(), visibility: SharingVisibility.public,
            likes: 5,
          ),
          SharedWasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
            id: 'shared_2',
            originalClassification: WasteClassification(itemName: 'Test Item', explanation: 'Test explanation', category: 'plastic', region: 'Test Region', visualFeatures: ['test feature'], alternatives: [], disposalInstructions: DisposalInstructions(primaryMethod: 'Test method', steps: ['Test step'], hasUrgentTimeframe: false), 
              id: 'class', imageUrl: '/path', category: 'plastic',
              confidence: 0.9, disposalInstructions: DisposalInstructions(primaryMethod: 'Recycle', steps: ['Test step'], hasUrgentTimeframe: false),
              timestamp: DateTime.now(),
            ),
            sharedBy: 'user123', sharedByName: 'John Doe',
            sharedAt: DateTime.now(), visibility: SharingVisibility.public,
            likes: 10,
          ),
        ];

        classifications.sort((a, b) => b.engagementScore.compareTo(a.engagementScore));

        expect(classifications[0].likes, 10);
        expect(classifications[1].likes, 5);
      });
    });
  });
}
