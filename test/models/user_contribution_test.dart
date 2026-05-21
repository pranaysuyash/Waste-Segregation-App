import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/user_contribution.dart';

void main() {
  group('UserContribution Model Tests', () {
    test('should create UserContribution with all required properties', () {
      final contribution = UserContribution(
        userId: 'user123',
        contributionType: ContributionType.newFacility,
        suggestedData: {'name': 'Recycling Center', 'address': '123 Main St'},
        timestamp: Timestamp.fromDate(DateTime(2024, 1, 15, 10, 30)),
        status: ContributionStatus.pendingReview,
      );

      expect(contribution.userId, 'user123');
      expect(contribution.contributionType, ContributionType.newFacility);
      expect(contribution.suggestedData['name'], 'Recycling Center');
      expect(contribution.status, ContributionStatus.pendingReview);
    });

    test('should create with optional properties', () {
      final contribution = UserContribution(
        userId: 'user456',
        contributionType: ContributionType.editHours,
        suggestedData: {'hours': '9-5'},
        timestamp: Timestamp.fromDate(DateTime(2024, 1, 15, 10, 30)),
        status: ContributionStatus.approvedIntegrated,
        userNotes: 'Updated hours',
        photoUrls: ['https://example.com/photo.jpg'],
        upvotes: 5,
        downvotes: 1,
        reviewNotes: 'Good update',
        reviewerId: 'mod_001',
      );

      expect(contribution.userNotes, 'Updated hours');
      expect(contribution.photoUrls, ['https://example.com/photo.jpg']);
      expect(contribution.upvotes, 5);
      expect(contribution.downvotes, 1);
    });

    test('should serialize to and from JSON', () {
      final contribution = UserContribution(
        userId: 'user789',
        contributionType: ContributionType.addPhoto,
        suggestedData: {'photo': 'new_photo.jpg'},
        timestamp: Timestamp.fromDate(DateTime(2024, 1, 15, 10, 30)),
        status: ContributionStatus.pendingReview,
        id: 'contrib_001',
        upvotes: 3,
      );

      final json = contribution.toJson();
      final restored = UserContribution.fromJson(json, 'contrib_001');

      expect(restored.userId, contribution.userId);
      expect(restored.contributionType, contribution.contributionType);
      expect(restored.status, contribution.status);
      expect(restored.upvotes, contribution.upvotes);
    });

    test('should handle all ContributionType values', () {
      expect(ContributionType.newFacility, isA<ContributionType>());
      expect(ContributionType.editHours, isA<ContributionType>());
      expect(ContributionType.editContact, isA<ContributionType>());
      expect(ContributionType.editAcceptedMaterials, isA<ContributionType>());
      expect(ContributionType.addPhoto, isA<ContributionType>());
      expect(ContributionType.reportClosure, isA<ContributionType>());
      expect(ContributionType.otherCorrection, isA<ContributionType>());
    });

    test('should handle all ContributionStatus values', () {
      expect(ContributionStatus.pendingReview, isA<ContributionStatus>());
      expect(ContributionStatus.approvedIntegrated, isA<ContributionStatus>());
      expect(ContributionStatus.rejected, isA<ContributionStatus>());
      expect(ContributionStatus.needsMoreInfo, isA<ContributionStatus>());
    });

    test('should convert type to and from string', () {
      expect(contributionTypeToString(ContributionType.newFacility),
          'NEW_FACILITY');
      expect(
          contributionTypeToString(ContributionType.editHours), 'EDIT_HOURS');
      expect(contributionTypeFromString('NEW_FACILITY'),
          ContributionType.newFacility);
      expect(
          contributionTypeFromString('EDIT_HOURS'), ContributionType.editHours);
    });

    test('should convert status to and from string', () {
      expect(contributionStatusToString(ContributionStatus.pendingReview),
          'PENDING_REVIEW');
      expect(contributionStatusToString(ContributionStatus.approvedIntegrated),
          'APPROVED_INTEGRATED');
      expect(contributionStatusFromString('PENDING_REVIEW'),
          ContributionStatus.pendingReview);
      expect(contributionStatusFromString('APPROVED_INTEGRATED'),
          ContributionStatus.approvedIntegrated);
    });

    test('should copyWith correctly', () {
      final original = UserContribution(
        userId: 'user123',
        contributionType: ContributionType.newFacility,
        suggestedData: {'name': 'Old Center'},
        timestamp: Timestamp.fromDate(DateTime(2024, 1, 15)),
        status: ContributionStatus.pendingReview,
      );

      final updated = original.copyWith(
        suggestedData: {'name': 'Updated Center'},
        status: ContributionStatus.approvedIntegrated,
        reviewerId: 'mod_001',
        reviewNotes: 'Looks good!',
      );

      expect(updated.suggestedData['name'], 'Updated Center');
      expect(updated.status, ContributionStatus.approvedIntegrated);
      expect(updated.reviewNotes, 'Looks good!');
      expect(original.status, ContributionStatus.pendingReview);
    });
  });
}
