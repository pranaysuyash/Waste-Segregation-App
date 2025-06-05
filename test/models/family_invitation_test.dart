import 'package:flutter_test/flutter_test.dart';
import 'package:waste_segregation_app/models/family_invitation.dart';

void main() {
  group('FamilyInvitation Model Tests', () {
    group('Constructor and Properties', () {
      test('should create FamilyInvitation with all required properties', () {
        final invitation = FamilyInvitation(
          id: 'invite123',
          familyId: 'family456',
          familyName: 'Smith Family',
          inviterName: 'John Smith',
          inviteeEmail: 'jane@example.com',
          inviteCode: 'ABC123',
          status: InvitationStatus.pending,
          createdAt: DateTime(2024, 1, 15),
          expiresAt: DateTime(2024, 1, 22),
        );

        expect(invitation.id, 'invite123');
        expect(invitation.familyId, 'family456');
        expect(invitation.familyName, 'Smith Family');
        expect(invitation.inviterName, 'John Smith');
        expect(invitation.inviteeEmail, 'jane@example.com');
        expect(invitation.inviteCode, 'ABC123');
        expect(invitation.status, InvitationStatus.pending);
        expect(invitation.createdAt, DateTime(2024, 1, 15));
        expect(invitation.expiresAt, DateTime(2024, 1, 22));
      });

      test('should create FamilyInvitation with optional properties', () {
        final invitation = FamilyInvitation(
          id: 'invite123',
          familyId: 'family456',
          familyName: 'Smith Family',
          inviterName: 'John Smith',
          inviteeEmail: 'jane@example.com',
          inviteCode: 'ABC123',
          status: InvitationStatus.pending,
          createdAt: DateTime(2024, 1, 15),
          expiresAt: DateTime(2024, 1, 22),
          message: 'Join our family!',
          inviteeUserId: 'user789',
          acceptedAt: DateTime(2024, 1, 16),
        );

        expect(invitation.message, 'Join our family!');
        expect(invitation.inviteeUserId, 'user789');
        expect(invitation.acceptedAt, DateTime(2024, 1, 16));
      });
    });

    group('JSON Serialization', () {
      test('should serialize to JSON correctly', () {
        final invitation = FamilyInvitation(
          id: 'invite123',
          familyId: 'family456',
          familyName: 'Smith Family',
          inviterName: 'John Smith',
          inviteeEmail: 'jane@example.com',
          inviteCode: 'ABC123',
          status: InvitationStatus.pending,
          createdAt: DateTime(2024, 1, 15),
          expiresAt: DateTime(2024, 1, 22),
          message: 'Join our family!',
        );

        final json = invitation.toJson();

        expect(json['id'], 'invite123');
        expect(json['familyId'], 'family456');
        expect(json['familyName'], 'Smith Family');
        expect(json['inviterName'], 'John Smith');
        expect(json['inviteeEmail'], 'jane@example.com');
        expect(json['inviteCode'], 'ABC123');
        expect(json['status'], 'pending');
        expect(json['message'], 'Join our family!');
        expect(json['createdAt'], isA<String>());
        expect(json['expiresAt'], isA<String>());
      });

      test('should deserialize from JSON correctly', () {
        final json = {
          'id': 'invite123',
          'familyId': 'family456',
          'familyName': 'Smith Family',
          'inviterName': 'John Smith',
          'inviteeEmail': 'jane@example.com',
          'inviteCode': 'ABC123',
          'status': 'pending',
          'createdAt': '2024-01-15T00:00:00.000',
          'expiresAt': '2024-01-22T00:00:00.000',
          'message': 'Join our family!',
        };

        final invitation = FamilyInvitation.fromJson(json);

        expect(invitation.id, 'invite123');
        expect(invitation.familyId, 'family456');
        expect(invitation.familyName, 'Smith Family');
        expect(invitation.inviterName, 'John Smith');
        expect(invitation.inviteeEmail, 'jane@example.com');
        expect(invitation.inviteCode, 'ABC123');
        expect(invitation.status, InvitationStatus.pending);
        expect(invitation.message, 'Join our family!');
        expect(invitation.createdAt, DateTime(2024, 1, 15));
        expect(invitation.expiresAt, DateTime(2024, 1, 22));
      });

      test('should handle null optional fields in JSON', () {
        final json = {
          'id': 'invite123',
          'familyId': 'family456',
          'familyName': 'Smith Family',
          'inviterName': 'John Smith',
          'inviteeEmail': 'jane@example.com',
          'inviteCode': 'ABC123',
          'status': 'pending',
          'createdAt': '2024-01-15T00:00:00.000',
          'expiresAt': '2024-01-22T00:00:00.000',
          'message': null,
          'inviteeUserId': null,
          'acceptedAt': null,
        };

        final invitation = FamilyInvitation.fromJson(json);

        expect(invitation.message, null);
        expect(invitation.inviteeUserId, null);
        expect(invitation.acceptedAt, null);
      });
    });

    group('Status Management', () {
      test('should handle all invitation statuses', () {
        final statuses = [
          InvitationStatus.pending,
          InvitationStatus.accepted,
          InvitationStatus.declined,
          InvitationStatus.expired,
        ];

        for (final status in statuses) {
          final invitation = FamilyInvitation(
            id: 'invite123',
            familyId: 'family456',
            familyName: 'Smith Family',
            inviterName: 'John Smith',
            inviteeEmail: 'jane@example.com',
            inviteCode: 'ABC123',
            status: status,
            createdAt: DateTime.now(),
            expiresAt: DateTime.now().add(const Duration(days: 7)),
          );

          expect(invitation.status, status);
        }
      });

      test('should check if invitation is pending', () {
        final pendingInvitation = FamilyInvitation(
          id: 'invite123',
          familyId: 'family456',
          familyName: 'Smith Family',
          inviterName: 'John Smith',
          inviteeEmail: 'jane@example.com',
          inviteCode: 'ABC123',
          status: InvitationStatus.pending,
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(days: 7)),
        );

        expect(pendingInvitation.isPending, true);
        expect(pendingInvitation.isAccepted, false);
        expect(pendingInvitation.isDeclined, false);
        expect(pendingInvitation.isExpired, false);
      });

      test('should check if invitation is accepted', () {
        final acceptedInvitation = FamilyInvitation(
          id: 'invite123',
          familyId: 'family456',
          familyName: 'Smith Family',
          inviterName: 'John Smith',
          inviteeEmail: 'jane@example.com',
          inviteCode: 'ABC123',
          status: InvitationStatus.accepted,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          expiresAt: DateTime.now().add(const Duration(days: 6)),
          acceptedAt: DateTime.now(),
        );

        expect(acceptedInvitation.isPending, false);
        expect(acceptedInvitation.isAccepted, true);
        expect(acceptedInvitation.isDeclined, false);
        expect(acceptedInvitation.isExpired, false);
      });
    });

    group('Expiration Logic', () {
      test('should detect expired invitation', () {
        final expiredInvitation = FamilyInvitation(
          id: 'invite123',
          familyId: 'family456',
          familyName: 'Smith Family',
          inviterName: 'John Smith',
          inviteeEmail: 'jane@example.com',
          inviteCode: 'ABC123',
          status: InvitationStatus.expired,
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
          expiresAt: DateTime.now().subtract(const Duration(days: 3)),
        );

        expect(expiredInvitation.isExpired, true);
        expect(expiredInvitation.hasExpired, true);
      });

      test('should detect if invitation will expire soon', () {
        final soonToExpireInvitation = FamilyInvitation(
          id: 'invite123',
          familyId: 'family456',
          familyName: 'Smith Family',
          inviterName: 'John Smith',
          inviteeEmail: 'jane@example.com',
          inviteCode: 'ABC123',
          status: InvitationStatus.pending,
          createdAt: DateTime.now().subtract(const Duration(days: 6)),
          expiresAt: DateTime.now().add(const Duration(hours: 12)),
        );

        expect(soonToExpireInvitation.expiresWithin(const Duration(days: 1)), true);
        expect(soonToExpireInvitation.expiresWithin(const Duration(hours: 6)), false);
      });

      test('should calculate remaining time', () {
        final invitation = FamilyInvitation(
          id: 'invite123',
          familyId: 'family456',
          familyName: 'Smith Family',
          inviterName: 'John Smith',
          inviteeEmail: 'jane@example.com',
          inviteCode: 'ABC123',
          status: InvitationStatus.pending,
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(days: 3, hours: 12)),
        );

        final remaining = invitation.timeUntilExpiry;
        expect(remaining.inDays, 3);
        expect(remaining.inHours, greaterThan(80)); // 3 days + 12 hours
      });
    });

    group('Validation', () {
      test('should validate invitation code format', () {
        final invitation = FamilyInvitation(
          id: 'invite123',
          familyId: 'family456',
          familyName: 'Smith Family',
          inviterName: 'John Smith',
          inviteeEmail: 'jane@example.com',
          inviteCode: 'ABC123',
          status: InvitationStatus.pending,
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(days: 7)),
        );

        expect(invitation.hasValidInviteCode, true);
      });

      test('should validate email format', () {
        final validEmailInvitation = FamilyInvitation(
          id: 'invite123',
          familyId: 'family456',
          familyName: 'Smith Family',
          inviterName: 'John Smith',
          inviteeEmail: 'jane@example.com',
          inviteCode: 'ABC123',
          status: InvitationStatus.pending,
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(days: 7)),
        );

        final invalidEmailInvitation = FamilyInvitation(
          id: 'invite124',
          familyId: 'family456',
          familyName: 'Smith Family',
          inviterName: 'John Smith',
          inviteeEmail: 'invalid-email',
          inviteCode: 'ABC124',
          status: InvitationStatus.pending,
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(days: 7)),
        );

        expect(validEmailInvitation.hasValidEmail, true);
        expect(invalidEmailInvitation.hasValidEmail, false);
      });

      test('should check if invitation can be accepted', () {
        final acceptableInvitation = FamilyInvitation(
          id: 'invite123',
          familyId: 'family456',
          familyName: 'Smith Family',
          inviterName: 'John Smith',
          inviteeEmail: 'jane@example.com',
          inviteCode: 'ABC123',
          status: InvitationStatus.pending,
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(days: 7)),
        );

        final expiredInvitation = FamilyInvitation(
          id: 'invite124',
          familyId: 'family456',
          familyName: 'Smith Family',
          inviterName: 'John Smith',
          inviteeEmail: 'jane@example.com',
          inviteCode: 'ABC124',
          status: InvitationStatus.expired,
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
          expiresAt: DateTime.now().subtract(const Duration(days: 3)),
        );

        expect(acceptableInvitation.canBeAccepted, true);
        expect(expiredInvitation.canBeAccepted, false);
      });
    });

    group('Equality and Comparison', () {
      test('should compare invitations for equality', () {
        final invitation1 = FamilyInvitation(
          id: 'invite123',
          familyId: 'family456',
          familyName: 'Smith Family',
          inviterName: 'John Smith',
          inviteeEmail: 'jane@example.com',
          inviteCode: 'ABC123',
          status: InvitationStatus.pending,
          createdAt: DateTime(2024, 1, 15),
          expiresAt: DateTime(2024, 1, 22),
        );

        final invitation2 = FamilyInvitation(
          id: 'invite123',
          familyId: 'family456',
          familyName: 'Smith Family',
          inviterName: 'John Smith',
          inviteeEmail: 'jane@example.com',
          inviteCode: 'ABC123',
          status: InvitationStatus.pending,
          createdAt: DateTime(2024, 1, 15),
          expiresAt: DateTime(2024, 1, 22),
        );

        final invitation3 = FamilyInvitation(
          id: 'invite124',
          familyId: 'family456',
          familyName: 'Smith Family',
          inviterName: 'John Smith',
          inviteeEmail: 'jane@example.com',
          inviteCode: 'ABC124',
          status: InvitationStatus.pending,
          createdAt: DateTime(2024, 1, 15),
          expiresAt: DateTime(2024, 1, 22),
        );

        expect(invitation1 == invitation2, true);
        expect(invitation1 == invitation3, false);
        expect(invitation1.hashCode == invitation2.hashCode, true);
      });
    });

    group('Copy and Update', () {
      test('should create copy with updated properties', () {
        final original = FamilyInvitation(
          id: 'invite123',
          familyId: 'family456',
          familyName: 'Smith Family',
          inviterName: 'John Smith',
          inviteeEmail: 'jane@example.com',
          inviteCode: 'ABC123',
          status: InvitationStatus.pending,
          createdAt: DateTime(2024, 1, 15),
          expiresAt: DateTime(2024, 1, 22),
        );

        final updated = original.copyWith(
          status: InvitationStatus.accepted,
          acceptedAt: DateTime(2024, 1, 16),
          inviteeUserId: 'user789',
        );

        expect(updated.id, original.id);
        expect(updated.familyId, original.familyId);
        expect(updated.status, InvitationStatus.accepted);
        expect(updated.acceptedAt, DateTime(2024, 1, 16));
        expect(updated.inviteeUserId, 'user789');
        expect(original.status, InvitationStatus.pending); // Original unchanged
      });
    });

    group('String Representation', () {
      test('should provide meaningful string representation', () {
        final invitation = FamilyInvitation(
          id: 'invite123',
          familyId: 'family456',
          familyName: 'Smith Family',
          inviterName: 'John Smith',
          inviteeEmail: 'jane@example.com',
          inviteCode: 'ABC123',
          status: InvitationStatus.pending,
          createdAt: DateTime(2024, 1, 15),
          expiresAt: DateTime(2024, 1, 22),
        );

        final stringRepresentation = invitation.toString();
        
        expect(stringRepresentation, contains('invite123'));
        expect(stringRepresentation, contains('Smith Family'));
        expect(stringRepresentation, contains('John Smith'));
        expect(stringRepresentation, contains('pending'));
      });
    });
  });
}
