import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/user_contribution.dart';

void main() {
  group('UserContribution Model Tests', () {
    group('UserContribution Model', () {
      test('should create UserContribution with all required properties', () {
        final contribution = UserContribution(
          id: 'contrib_001',
          userId: 'user123',
          userName: 'John Doe',
          type: ContributionType.classification,
          title: 'Plastic Bottle Classification',
          description: 'Helped identify plastic bottle disposal method',
          points: 50,
          timestamp: DateTime(2024, 1, 15, 10, 30),
          status: ContributionStatus.approved,
        );

        expect(contribution.id, 'contrib_001');
        expect(contribution.userId, 'user123');
        expect(contribution.userName, 'John Doe');
        expect(contribution.type, ContributionType.classification);
        expect(contribution.title, 'Plastic Bottle Classification');
        expect(contribution.description, 'Helped identify plastic bottle disposal method');
        expect(contribution.points, 50);
        expect(contribution.timestamp, DateTime(2024, 1, 15, 10, 30));
        expect(contribution.status, ContributionStatus.approved);
      });

      test('should create UserContribution with optional properties', () {
        final contribution = UserContribution(
          id: 'contrib_002',
          userId: 'user456',
          userName: 'Jane Smith',
          type: ContributionType.educational_content,
          title: 'Recycling Guide Update',
          description: 'Added comprehensive recycling guide for electronics',
          points: 200,
          timestamp: DateTime(2024, 1, 15, 10, 30),
          status: ContributionStatus.approved,
          category: 'electronics',
          tags: ['recycling', 'electronics', 'guide'],
          relatedItemId: 'classification_123',
          moderatorId: 'mod_001',
          moderatorName: 'Admin User',
          reviewedAt: DateTime(2024, 1, 15, 11, 0),
          reviewNotes: 'Excellent comprehensive guide',
          quality: ContributionQuality.excellent,
          visibility: ContributionVisibility.public,
          upvotes: 15,
          downvotes: 2,
          reportCount: 0,
        );

        expect(contribution.category, 'electronics');
        expect(contribution.tags, ['recycling', 'electronics', 'guide']);
        expect(contribution.relatedItemId, 'classification_123');
        expect(contribution.moderatorId, 'mod_001');
        expect(contribution.moderatorName, 'Admin User');
        expect(contribution.reviewedAt, DateTime(2024, 1, 15, 11, 0));
        expect(contribution.reviewNotes, 'Excellent comprehensive guide');
        expect(contribution.quality, ContributionQuality.excellent);
        expect(contribution.visibility, ContributionVisibility.public);
        expect(contribution.upvotes, 15);
        expect(contribution.downvotes, 2);
        expect(contribution.reportCount, 0);
      });

      test('should serialize UserContribution to JSON correctly', () {
        final contribution = UserContribution(
          id: 'contrib_003',
          userId: 'user789',
          userName: 'Alice Brown',
          type: ContributionType.disposal_location,
          title: 'New Recycling Center',
          description: 'Added new recycling center location downtown',
          points: 100,
          timestamp: DateTime(2024, 1, 15, 10, 30),
          status: ContributionStatus.pending,
          category: 'locations',
          tags: ['recycling', 'center', 'downtown'],
          quality: ContributionQuality.good,
          upvotes: 5,
        );

        final json = contribution.toJson();

        expect(json['id'], 'contrib_003');
        expect(json['userId'], 'user789');
        expect(json['userName'], 'Alice Brown');
        expect(json['type'], 'disposal_location');
        expect(json['title'], 'New Recycling Center');
        expect(json['description'], 'Added new recycling center location downtown');
        expect(json['points'], 100);
        expect(json['timestamp'], isA<String>());
        expect(json['status'], 'pending');
        expect(json['category'], 'locations');
        expect(json['tags'], ['recycling', 'center', 'downtown']);
        expect(json['quality'], 'good');
        expect(json['upvotes'], 5);
      });

      test('should deserialize UserContribution from JSON correctly', () {
        final json = {
          'id': 'contrib_004',
          'userId': 'user012',
          'userName': 'Bob Wilson',
          'type': 'bug_report',
          'title': 'Camera Issue',
          'description': 'Reported camera not working on Android devices',
          'points': 25,
          'timestamp': '2024-01-15T10:30:00.000',
          'status': 'reviewed',
          'category': 'bugs',
          'tags': ['camera', 'android', 'bug'],
          'moderatorId': 'mod_002',
          'reviewedAt': '2024-01-15T11:00:00.000',
          'reviewNotes': 'Valid bug report, forwarded to dev team',
          'quality': 'average',
          'visibility': 'public',
          'upvotes': 3,
          'downvotes': 0,
          'reportCount': 0,
        };

        final contribution = UserContribution.fromJson(json);

        expect(contribution.id, 'contrib_004');
        expect(contribution.userId, 'user012');
        expect(contribution.userName, 'Bob Wilson');
        expect(contribution.type, ContributionType.bug_report);
        expect(contribution.title, 'Camera Issue');
        expect(contribution.description, 'Reported camera not working on Android devices');
        expect(contribution.points, 25);
        expect(contribution.timestamp, DateTime(2024, 1, 15, 10, 30));
        expect(contribution.status, ContributionStatus.reviewed);
        expect(contribution.category, 'bugs');
        expect(contribution.tags, ['camera', 'android', 'bug']);
        expect(contribution.moderatorId, 'mod_002');
        expect(contribution.reviewedAt, DateTime(2024, 1, 15, 11, 0));
        expect(contribution.reviewNotes, 'Valid bug report, forwarded to dev team');
        expect(contribution.quality, ContributionQuality.average);
        expect(contribution.visibility, ContributionVisibility.public);
        expect(contribution.upvotes, 3);
        expect(contribution.downvotes, 0);
        expect(contribution.reportCount, 0);
      });

      test('should calculate net score correctly', () {
        final contribution = UserContribution(
          id: 'contrib_005',
          userId: 'user123',
          userName: 'John Doe',
          type: ContributionType.classification,
          title: 'Test Contribution',
          description: 'Test description',
          points: 50,
          timestamp: DateTime.now(),
          status: ContributionStatus.approved,
          upvotes: 10,
          downvotes: 3,
        );

        expect(contribution.netScore, 7); // 10 - 3
        expect(contribution.totalVotes, 13); // 10 + 3
      });

      test('should calculate approval rate correctly', () {
        final contribution = UserContribution(
          id: 'contrib_006',
          userId: 'user123',
          userName: 'John Doe',
          type: ContributionType.classification,
          title: 'Test Contribution',
          description: 'Test description',
          points: 50,
          timestamp: DateTime.now(),
          status: ContributionStatus.approved,
          upvotes: 8,
          downvotes: 2,
        );

        expect(contribution.approvalRate, 0.8); // 8 / (8 + 2)
      });

      test('should handle zero votes gracefully', () {
        final contribution = UserContribution(
          id: 'contrib_007',
          userId: 'user123',
          userName: 'John Doe',
          type: ContributionType.classification,
          title: 'Test Contribution',
          description: 'Test description',
          points: 50,
          timestamp: DateTime.now(),
          status: ContributionStatus.pending,
          upvotes: 0,
          downvotes: 0,
        );

        expect(contribution.netScore, 0);
        expect(contribution.totalVotes, 0);
        expect(contribution.approvalRate, 0.0);
      });

      test('should check if contribution is recent', () {
        final recentContribution = UserContribution(
          id: 'contrib_recent',
          userId: 'user123',
          userName: 'John Doe',
          type: ContributionType.classification,
          title: 'Recent Contribution',
          description: 'Made recently',
          points: 50,
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          status: ContributionStatus.approved,
        );

        final oldContribution = UserContribution(
          id: 'contrib_old',
          userId: 'user123',
          userName: 'John Doe',
          type: ContributionType.classification,
          title: 'Old Contribution',
          description: 'Made long ago',
          points: 50,
          timestamp: DateTime.now().subtract(const Duration(days: 30)),
          status: ContributionStatus.approved,
        );

        expect(recentContribution.isRecent, true);
        expect(oldContribution.isRecent, false);
      });

      test('should check if contribution needs review', () {
        final pendingContribution = UserContribution(
          id: 'contrib_pending',
          userId: 'user123',
          userName: 'John Doe',
          type: ContributionType.classification,
          title: 'Pending Review',
          description: 'Awaiting review',
          points: 50,
          timestamp: DateTime.now(),
          status: ContributionStatus.pending,
        );

        final reportedContribution = UserContribution(
          id: 'contrib_reported',
          userId: 'user123',
          userName: 'John Doe',
          type: ContributionType.classification,
          title: 'Reported Content',
          description: 'Has reports',
          points: 50,
          timestamp: DateTime.now(),
          status: ContributionStatus.approved,
          reportCount: 3,
        );

        final approvedContribution = UserContribution(
          id: 'contrib_approved',
          userId: 'user123',
          userName: 'John Doe',
          type: ContributionType.classification,
          title: 'Approved Content',
          description: 'Already approved',
          points: 50,
          timestamp: DateTime.now(),
          status: ContributionStatus.approved,
          reportCount: 0,
        );

        expect(pendingContribution.needsReview, true);
        expect(reportedContribution.needsReview, true);
        expect(approvedContribution.needsReview, false);
      });

      test('should check if contribution can be edited', () {
        final ownRecentContribution = UserContribution(
          id: 'contrib_editable',
          userId: 'user123',
          userName: 'John Doe',
          type: ContributionType.educational_content,
          title: 'Editable Content',
          description: 'Can be edited',
          points: 50,
          timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
          status: ContributionStatus.pending,
        );

        final oldContribution = UserContribution(
          id: 'contrib_old',
          userId: 'user123',
          userName: 'John Doe',
          type: ContributionType.educational_content,
          title: 'Old Content',
          description: 'Too old to edit',
          points: 50,
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
          status: ContributionStatus.pending,
        );

        final approvedContribution = UserContribution(
          id: 'contrib_approved',
          userId: 'user123',
          userName: 'John Doe',
          type: ContributionType.educational_content,
          title: 'Approved Content',
          description: 'Already approved',
          points: 50,
          timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
          status: ContributionStatus.approved,
        );

        expect(ownRecentContribution.canBeEditedBy('user123'), true);
        expect(oldContribution.canBeEditedBy('user123'), false);
        expect(approvedContribution.canBeEditedBy('user123'), false);
        expect(ownRecentContribution.canBeEditedBy('user456'), false);
      });

      test('should get time since contribution', () {
        final contribution = UserContribution(
          id: 'contrib_time',
          userId: 'user123',
          userName: 'John Doe',
          type: ContributionType.classification,
          title: 'Time Test',
          description: 'Testing time calculation',
          points: 50,
          timestamp: DateTime.now().subtract(const Duration(hours: 3)),
          status: ContributionStatus.approved,
        );

        expect(contribution.timeSinceContribution.inHours, 3);
      });
    });

    group('Contribution Types', () {
      test('should handle all contribution types', () {
        final types = [
          ContributionType.classification,
          ContributionType.educational_content,
          ContributionType.disposal_location,
          ContributionType.bug_report,
          ContributionType.feature_request,
          ContributionType.community_guideline,
          ContributionType.translation,
          ContributionType.data_validation,
        ];

        for (final type in types) {
          expect(type.displayName, isNotEmpty);
          expect(type.description, isNotEmpty);
          expect(type.icon, isNotEmpty);
          expect(type.basePoints, greaterThan(0));
        }
      });

      test('should provide appropriate points for different types', () {
        expect(ContributionType.classification.basePoints, 10);
        expect(ContributionType.educational_content.basePoints, 50);
        expect(ContributionType.disposal_location.basePoints, 30);
        expect(ContributionType.bug_report.basePoints, 25);
        expect(ContributionType.feature_request.basePoints, 15);
        expect(ContributionType.data_validation.basePoints, 20);
      });

      test('should categorize contribution types by difficulty', () {
        expect(ContributionType.classification.difficulty, ContributionDifficulty.easy);
        expect(ContributionType.educational_content.difficulty, ContributionDifficulty.hard);
        expect(ContributionType.disposal_location.difficulty, ContributionDifficulty.medium);
        expect(ContributionType.bug_report.difficulty, ContributionDifficulty.medium);
        expect(ContributionType.translation.difficulty, ContributionDifficulty.hard);
      });
    });

    group('Contribution Status Management', () {
      test('should handle all contribution statuses', () {
        expect(ContributionStatus.pending.displayName, 'Pending Review');
        expect(ContributionStatus.approved.displayName, 'Approved');
        expect(ContributionStatus.rejected.displayName, 'Rejected');
        expect(ContributionStatus.reviewed.displayName, 'Reviewed');
        expect(ContributionStatus.flagged.displayName, 'Flagged');
        expect(ContributionStatus.archived.displayName, 'Archived');
      });

      test('should check if status allows editing', () {
        expect(ContributionStatus.pending.allowsEditing, true);
        expect(ContributionStatus.rejected.allowsEditing, true);
        expect(ContributionStatus.approved.allowsEditing, false);
        expect(ContributionStatus.reviewed.allowsEditing, false);
        expect(ContributionStatus.flagged.allowsEditing, false);
        expect(ContributionStatus.archived.allowsEditing, false);
      });

      test('should check if status requires action', () {
        expect(ContributionStatus.pending.requiresAction, true);
        expect(ContributionStatus.flagged.requiresAction, true);
        expect(ContributionStatus.approved.requiresAction, false);
        expect(ContributionStatus.rejected.requiresAction, false);
        expect(ContributionStatus.reviewed.requiresAction, false);
        expect(ContributionStatus.archived.requiresAction, false);
      });
    });

    group('Contribution Quality', () {
      test('should handle all quality levels', () {
        expect(ContributionQuality.poor.displayName, 'Poor');
        expect(ContributionQuality.average.displayName, 'Average');
        expect(ContributionQuality.good.displayName, 'Good');
        expect(ContributionQuality.excellent.displayName, 'Excellent');
        expect(ContributionQuality.outstanding.displayName, 'Outstanding');
      });

      test('should provide quality scores', () {
        expect(ContributionQuality.poor.score, 1);
        expect(ContributionQuality.average.score, 2);
        expect(ContributionQuality.good.score, 3);
        expect(ContributionQuality.excellent.score, 4);
        expect(ContributionQuality.outstanding.score, 5);
      });

      test('should provide point multipliers', () {
        expect(ContributionQuality.poor.pointMultiplier, 0.5);
        expect(ContributionQuality.average.pointMultiplier, 1.0);
        expect(ContributionQuality.good.pointMultiplier, 1.2);
        expect(ContributionQuality.excellent.pointMultiplier, 1.5);
        expect(ContributionQuality.outstanding.pointMultiplier, 2.0);
      });

      test('should calculate adjusted points based on quality', () {
        final contribution = UserContribution(
          id: 'contrib_quality',
          userId: 'user123',
          userName: 'John Doe',
          type: ContributionType.educational_content, // 50 base points
          title: 'Quality Test',
          description: 'Testing quality calculation',
          points: 50,
          timestamp: DateTime.now(),
          status: ContributionStatus.approved,
          quality: ContributionQuality.excellent, // 1.5x multiplier
        );

        expect(contribution.adjustedPoints, 75); // 50 * 1.5
      });
    });

    group('Contribution Visibility', () {
      test('should handle all visibility levels', () {
        expect(ContributionVisibility.public.displayName, 'Public');
        expect(ContributionVisibility.community.displayName, 'Community Only');
        expect(ContributionVisibility.family.displayName, 'Family Only');
        expect(ContributionVisibility.private.displayName, 'Private');
      });

      test('should check visibility permissions', () {
        final publicContribution = UserContribution(
          id: 'contrib_public',
          userId: 'user123',
          userName: 'John Doe',
          type: ContributionType.classification,
          title: 'Public Content',
          description: 'Visible to all',
          points: 50,
          timestamp: DateTime.now(),
          status: ContributionStatus.approved,
          visibility: ContributionVisibility.public,
        );

        final privateContribution = UserContribution(
          id: 'contrib_private',
          userId: 'user123',
          userName: 'John Doe',
          type: ContributionType.classification,
          title: 'Private Content',
          description: 'Visible only to owner',
          points: 50,
          timestamp: DateTime.now(),
          status: ContributionStatus.approved,
          visibility: ContributionVisibility.private,
        );

        expect(publicContribution.isVisibleTo('user456', null, false), true);
        expect(privateContribution.isVisibleTo('user456', null, false), false);
        expect(privateContribution.isVisibleTo('user123', null, false), true);
      });
    });

    group('Validation', () {
      test('should validate contribution content', () {
        expect(() => UserContribution(
          id: '', // Empty ID
          userId: 'user123',
          userName: 'John Doe',
          type: ContributionType.classification,
          title: 'Valid Title',
          description: 'Valid description',
          points: 50,
          timestamp: DateTime.now(),
          status: ContributionStatus.pending,
        ), throwsArgumentError);

        expect(() => UserContribution(
          id: 'valid_id',
          userId: 'user123',
          userName: 'John Doe',
          type: ContributionType.classification,
          title: '', // Empty title
          description: 'Valid description',
          points: 50,
          timestamp: DateTime.now(),
          status: ContributionStatus.pending,
        ), throwsArgumentError);

        expect(() => UserContribution(
          id: 'valid_id',
          userId: 'user123',
          userName: 'John Doe',
          type: ContributionType.classification,
          title: 'Valid Title',
          description: '', // Empty description
          points: 50,
          timestamp: DateTime.now(),
          status: ContributionStatus.pending,
        ), throwsArgumentError);
      });

      test('should validate point values', () {
        expect(() => UserContribution(
          id: 'valid_id',
          userId: 'user123',
          userName: 'John Doe',
          type: ContributionType.classification,
          title: 'Valid Title',
          description: 'Valid description',
          points: -10, // Negative points
          timestamp: DateTime.now(),
          status: ContributionStatus.pending,
        ), throwsArgumentError);
      });

      test('should validate vote counts', () {
        expect(() => UserContribution(
          id: 'valid_id',
          userId: 'user123',
          userName: 'John Doe',
          type: ContributionType.classification,
          title: 'Valid Title',
          description: 'Valid description',
          points: 50,
          timestamp: DateTime.now(),
          status: ContributionStatus.pending,
          upvotes: -5, // Negative upvotes
        ), throwsArgumentError);

        expect(() => UserContribution(
          id: 'valid_id',
          userId: 'user123',
          userName: 'John Doe',
          type: ContributionType.classification,
          title: 'Valid Title',
          description: 'Valid description',
          points: 50,
          timestamp: DateTime.now(),
          status: ContributionStatus.pending,
          downvotes: -3, // Negative downvotes
        ), throwsArgumentError);

        expect(() => UserContribution(
          id: 'valid_id',
          userId: 'user123',
          userName: 'John Doe',
          type: ContributionType.classification,
          title: 'Valid Title',
          description: 'Valid description',
          points: 50,
          timestamp: DateTime.now(),
          status: ContributionStatus.pending,
          reportCount: -1, // Negative report count
        ), throwsArgumentError);
      });
    });

    group('Copy and Update', () {
      test('should create copy with updated properties', () {
        final original = UserContribution(
          id: 'contrib_original',
          userId: 'user123',
          userName: 'John Doe',
          type: ContributionType.classification,
          title: 'Original Title',
          description: 'Original description',
          points: 50,
          timestamp: DateTime.now(),
          status: ContributionStatus.pending,
        );

        final updated = original.copyWith(
          status: ContributionStatus.approved,
          moderatorId: 'mod_001',
          reviewedAt: DateTime.now(),
          reviewNotes: 'Looks good!',
          quality: ContributionQuality.good,
        );

        expect(updated.id, original.id);
        expect(updated.title, original.title);
        expect(updated.status, ContributionStatus.approved);
        expect(updated.moderatorId, 'mod_001');
        expect(updated.reviewNotes, 'Looks good!');
        expect(updated.quality, ContributionQuality.good);
        expect(original.status, ContributionStatus.pending); // Original unchanged
      });
    });

    group('Equality and Comparison', () {
      test('should compare UserContribution for equality', () {
        final contribution1 = UserContribution(
          id: 'contrib_001',
          userId: 'user123',
          userName: 'John Doe',
          type: ContributionType.classification,
          title: 'Test Contribution',
          description: 'Test description',
          points: 50,
          timestamp: DateTime(2024, 1, 15, 10, 30),
          status: ContributionStatus.approved,
        );

        final contribution2 = UserContribution(
          id: 'contrib_001',
          userId: 'user123',
          userName: 'John Doe',
          type: ContributionType.classification,
          title: 'Test Contribution',
          description: 'Test description',
          points: 50,
          timestamp: DateTime(2024, 1, 15, 10, 30),
          status: ContributionStatus.approved,
        );

        final contribution3 = UserContribution(
          id: 'contrib_002',
          userId: 'user456',
          userName: 'Jane Smith',
          type: ContributionType.educational_content,
          title: 'Different Contribution',
          description: 'Different description',
          points: 100,
          timestamp: DateTime(2024, 1, 16, 11, 30),
          status: ContributionStatus.pending,
        );

        expect(contribution1 == contribution2, true);
        expect(contribution1 == contribution3, false);
        expect(contribution1.hashCode == contribution2.hashCode, true);
      });

      test('should sort contributions by points', () {
        final contributions = [
          UserContribution(
            id: 'contrib_1', userId: 'user1', userName: 'User1',
            type: ContributionType.classification, title: 'Low Points',
            description: 'Description', points: 25, timestamp: DateTime.now(),
            status: ContributionStatus.approved,
          ),
          UserContribution(
            id: 'contrib_2', userId: 'user2', userName: 'User2',
            type: ContributionType.educational_content, title: 'High Points',
            description: 'Description', points: 100, timestamp: DateTime.now(),
            status: ContributionStatus.approved,
          ),
          UserContribution(
            id: 'contrib_3', userId: 'user3', userName: 'User3',
            type: ContributionType.disposal_location, title: 'Medium Points',
            description: 'Description', points: 50, timestamp: DateTime.now(),
            status: ContributionStatus.approved,
          ),
        ];

        contributions.sort((a, b) => b.points.compareTo(a.points));

        expect(contributions[0].points, 100);
        expect(contributions[1].points, 50);
        expect(contributions[2].points, 25);
      });
    });

    group('String Representation', () {
      test('should provide meaningful string representation', () {
        final contribution = UserContribution(
          id: 'contrib_001',
          userId: 'user123',
          userName: 'John Doe',
          type: ContributionType.classification,
          title: 'Plastic Bottle Classification',
          description: 'Helped identify disposal method',
          points: 50,
          timestamp: DateTime(2024, 1, 15, 10, 30),
          status: ContributionStatus.approved,
        );

        final stringRepresentation = contribution.toString();

        expect(stringRepresentation, contains('contrib_001'));
        expect(stringRepresentation, contains('John Doe'));
        expect(stringRepresentation, contains('Plastic Bottle Classification'));
        expect(stringRepresentation, contains('classification'));
        expect(stringRepresentation, contains('50'));
      });
    });
  });
}
