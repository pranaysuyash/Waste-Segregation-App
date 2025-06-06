import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/enhanced_family.dart' as family_models;
import '../models/family_invitation.dart' as invitation_models;
import '../models/user_profile.dart' as user_profile_models;
import '../models/waste_classification.dart';
import '../models/gamification.dart' show FamilyReaction, FamilyComment, FamilyReactionType, ClassificationLocation;
import '../models/shared_waste_classification.dart' show SharedWasteClassification;

/// Service for managing family-related data in Firebase Firestore.
class FirebaseFamilyService {
  static const String _familiesCollection = 'families';
  static const String _invitationsCollection = 'invitations';
  static const String _classificationsCollection = 'shared_classifications';
  static const String _usersCollection = 'users';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // ================ FAMILY MANAGEMENT ================

  /// Creates a new family with the specified creator.
  Future<family_models.Family> createFamily(String name, user_profile_models.UserProfile creator) async {
    try {
      final familyId = _uuid.v4();
      final now = DateTime.now();

      // Create the family object
      final family = family_models.Family(
        id: familyId,
        name: name,
        createdBy: creator.id,
        createdAt: now,
        updatedAt: now,
        members: [
          family_models.FamilyMember(
            userId: creator.id,
            role: family_models.UserRole.admin,
            joinedAt: now,
            individualStats: family_models.UserStats.empty(),
            displayName: creator.displayName,
            photoUrl: creator.photoUrl,
          ),
        ],
        settings: family_models.FamilySettings.defaultSettings(),
      );

      // Save family to Firestore
      await _firestore
          .collection(_familiesCollection)
          .doc(familyId)
          .set(family.toJson());

      // Update creator's profile to include family ID
      await _updateUserFamilyId(creator.id, familyId, user_profile_models.UserRole.admin);

      return family;
    } catch (e) {
      throw Exception('Failed to create family: $e');
    }
  }

  /// Gets a family by ID.
  Future<family_models.Family?> getFamily(String familyId) async {
    try {
      final doc = await _firestore
          .collection(_familiesCollection)
          .doc(familyId)
          .get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      return family_models.Family.fromJson(doc.data()!);
    } catch (e) {
      throw Exception('Failed to get family: $e');
    }
  }

  /// Updates an existing family.
  Future<void> updateFamily(family_models.Family family) async {
    try {
      final updatedFamily = family.copyWith(updatedAt: DateTime.now());
      
      await _firestore
          .collection(_familiesCollection)
          .doc(family.id)
          .update(updatedFamily.toJson());
    } catch (e) {
      throw Exception('Failed to update family: $e');
    }
  }

  /// Deletes a family (admin only).
  Future<void> deleteFamily(String familyId) async {
    try {
      final batch = _firestore.batch();

      // Delete family document
      batch.delete(_firestore.collection(_familiesCollection).doc(familyId));

      // Remove family ID from all members
      final family = await getFamily(familyId);
      if (family != null) {
        for (final member in family.members) {
          await _updateUserFamilyId(member.userId, null, null);
        }
      }

      // Delete all related invitations
      final invitations = await _firestore
          .collection(_invitationsCollection)
          .where('familyId', isEqualTo: familyId)
          .get();

      for (final doc in invitations.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete family: $e');
    }
  }

  /// Returns a stream of the family document.
  Stream<family_models.Family?> getFamilyStream(String familyId) {
    return _firestore
        .collection(_familiesCollection)
        .doc(familyId)
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return family_models.Family.fromJson(doc.data()!);
    }).handleError((error) {
      // Log error or handle appropriately
      debugPrint('Error in getFamilyStream: $error');
      throw Exception('Failed to stream family data: $error');
    });
  }

  // ================ MEMBER MANAGEMENT ================

  /// Adds a new member to a family.
  Future<void> addMember(String familyId, String userId, user_profile_models.UserRole roleFromProfile) async {
    try {
      final family = await getFamily(familyId);
      if (family == null) {
        throw Exception('Family not found');
      }

      if (family.hasMember(userId)) {
        // User already part of family; no action needed
        return;
      }

      final userProfile = await _getUserProfile(userId);
      if (userProfile == null) {
        throw Exception('User profile not found');
      }
      
      // Convert user_profile_models.UserRole to family_models.UserRole
      family_models.UserRole familyMemberRole;
      switch (roleFromProfile) {
        case user_profile_models.UserRole.admin:
          familyMemberRole = family_models.UserRole.admin;
          break;
        case user_profile_models.UserRole.member:
          familyMemberRole = family_models.UserRole.member;
          break;
        // Add other cases if UserRole enums diverge more in the future
        default:
          // Default to member if a direct mapping isn't found or if new roles are added to one enum but not the other
          familyMemberRole = family_models.UserRole.member; 
      }

      final newMember = family_models.FamilyMember(
        userId: userId,
        role: familyMemberRole, // Use the converted family_models.UserRole
        joinedAt: DateTime.now(),
        individualStats: family_models.UserStats.empty(),
        displayName: userProfile.displayName,
        photoUrl: userProfile.photoUrl,
      );

      final updatedMembers = [...family.members, newMember];
      final updatedFamily = family.copyWith(members: updatedMembers);

      await updateFamily(updatedFamily);
      await _updateUserFamilyId(userId, familyId, roleFromProfile); // Pass the original profile role here
    } catch (e) {
      throw Exception('Failed to add member: $e');
    }
  }

  /// Removes a member from a family.
  Future<void> removeMember(String familyId, String userId) async {
    try {
      final family = await getFamily(familyId);
      if (family == null) {
        throw Exception('Family not found');
      }

      // Check if user is a member
      if (!family.hasMember(userId)) {
        throw Exception('User is not a family member');
      }

      // Cannot remove the family creator unless transferring ownership
      if (family.createdBy == userId && family.members.length > 1) {
        throw Exception('Cannot remove family creator. Transfer ownership first.');
      }

      // Remove member from family
      final updatedMembers = family.members
          .where((member) => member.userId != userId)
          .toList();

      final updatedFamily = family.copyWith(members: updatedMembers);
      await updateFamily(updatedFamily);

      // Remove family ID from user's profile
      await _updateUserFamilyId(userId, null, null);

      // If this was the last member, delete the family
      if (updatedMembers.isEmpty) {
        await deleteFamily(familyId);
      }
    } catch (e) {
      throw Exception('Failed to remove member: $e');
    }
  }

  /// Updates a member's role in the family.
  Future<void> updateMemberRole(String familyId, String userId, user_profile_models.UserRole newRoleFromProfile) async {
    try {
      final family = await getFamily(familyId);
      if (family == null) {
        throw Exception('Family not found');
      }

      final memberIndex = family.members.indexWhere((m) => m.userId == userId);
      if (memberIndex == -1) {
        throw Exception('Member not found');
      }

      // Convert user_profile_models.UserRole to family_models.UserRole
      family_models.UserRole newFamilyMemberRole;
      switch (newRoleFromProfile) {
        case user_profile_models.UserRole.admin:
          newFamilyMemberRole = family_models.UserRole.admin;
          break;
        case user_profile_models.UserRole.member:
          newFamilyMemberRole = family_models.UserRole.member;
          break;
        // Add other cases if necessary
        default:
          newFamilyMemberRole = family_models.UserRole.member;
      }

      final updatedMembers = [...family.members];
      updatedMembers[memberIndex] = updatedMembers[memberIndex].copyWith(role: newFamilyMemberRole);

      final updatedFamily = family.copyWith(members: updatedMembers);
      await updateFamily(updatedFamily);
      await _updateUserFamilyId(userId, familyId, newRoleFromProfile); // Pass the original profile role here
    } catch (e) {
      throw Exception('Failed to update member role: $e');
    }
  }

  /// Gets all family members with their full profiles.
  Future<List<user_profile_models.UserProfile>> getFamilyMembers(String familyId) async {
    try {
      final family = await getFamily(familyId);
      if (family == null) {
        return [];
      }

      final members = <user_profile_models.UserProfile>[];
      for (final member in family.members) {
        final profile = await _getUserProfile(member.userId);
        if (profile != null) {
          members.add(profile);
        }
      }

      return members;
    } catch (e) {
      throw Exception('Failed to get family members: $e');
    }
  }

  /// Returns a stream of family members' UserProfile objects.
  Stream<List<user_profile_models.UserProfile>> getFamilyMembersStream(String familyId) {
    return _firestore
        .collection(_familiesCollection)
        .doc(familyId)
        .snapshots()
        .asyncMap((familyDoc) async {
      if (!familyDoc.exists || familyDoc.data() == null) {
        return <user_profile_models.UserProfile>[];
      }
      final family = family_models.Family.fromJson(familyDoc.data()!);
      final memberProfiles = <user_profile_models.UserProfile>[];
      for (final member in family.members) {
        final profile = await _getUserProfile(member.userId);
        if (profile != null) {
          memberProfiles.add(profile);
        }
      }
      return memberProfiles;
    }).handleError((error) {
      debugPrint('Error in getFamilyMembersStream: $error');
      throw Exception('Failed to stream family members: $error');
    });
  }

  // ================ FAMILY STATISTICS ================

  /// Gets comprehensive statistics for a family.
  Future<family_models.FamilyStats> getFamilyStats(String familyId) async {
    try {
      // Get family classifications
      final classifications = await getFamilyClassifications(familyId);
      
      // Calculate statistics
      final totalClassifications = classifications.length;
      final totalPoints = classifications.fold<int>(
        0, 
        (accumulator, classification) => accumulator + 10, // Default 10 points per classification
      );

      // Calculate category breakdown
      final categoryBreakdown = <String, int>{};
      for (final classification in classifications) {
        final category = classification.classification.category;
        categoryBreakdown[category] = (categoryBreakdown[category] ?? 0) + 1;
      }

      // Calculate streaks (simplified - would need more complex logic)
      final currentStreak = _calculateCurrentStreak(classifications);
      final bestStreak = _calculateBestStreak(classifications);

      // Calculate environmental impact
      final environmentalImpact = _calculateEnvironmentalImpact(classifications);

      // Get weekly progress
      final weeklyProgress = _calculateWeeklyProgress(classifications);

      return family_models.FamilyStats(
        totalClassifications: totalClassifications,
        totalPoints: totalPoints,
        currentStreak: currentStreak,
        bestStreak: bestStreak,
        categoryBreakdown: categoryBreakdown,
        environmentalImpact: environmentalImpact,
        weeklyProgress: weeklyProgress,
        achievementCount: 0, // Would be calculated from achievements
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Failed to get family stats: $e');
    }
  }

  /// Gets all classifications for a family.
  Future<List<SharedWasteClassification>> getFamilyClassifications(String familyId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_classificationsCollection)
          .where('familyId', isEqualTo: familyId)
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => SharedWasteClassification.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get family classifications: $e');
    }
  }

  /// Gets dashboard data for a family.
  Future<Map<String, dynamic>> getFamilyDashboardData(String familyId) async {
    try {
      final family = await getFamily(familyId);
      final stats = await getFamilyStats(familyId);
      final recentClassifications = await _getRecentFamilyClassifications(familyId, 10);
      final topMembers = await _getTopFamilyMembers(familyId);

      return {
        'family': family?.toJson(),
        'stats': stats.toJson(),
        'recentClassifications': recentClassifications.map((c) => c.toJson()).toList(),
        'topMembers': topMembers,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw Exception('Failed to get family dashboard data: $e');
    }
  }

  /// Returns a stream of recent shared classifications for a family.
  Stream<List<SharedWasteClassification>> getFamilyClassificationsStream(
      String familyId, {int limit = 5}) {
    return _firestore
        .collection(_classificationsCollection)
        .where('familyId', isEqualTo: familyId)
        .orderBy('sharedAt', descending: true) // Assuming 'sharedAt' for ordering recent items
        .limit(limit)
        .snapshots()
        .map((querySnapshot) {
      return querySnapshot.docs
          .map((doc) => SharedWasteClassification.fromJson(doc.data()))
          .toList();
    }).handleError((error) {
      // Log error or handle appropriately
      debugPrint('Error in getFamilyClassificationsStream: $error');
      throw Exception('Failed to stream family classifications: $error');
    });
  }

  // ================ SHARED CLASSIFICATIONS ================

  /// Saves a shared waste classification to the family feed.
  Future<void> saveSharedClassification(
    String familyId,
    String userId,
    WasteClassification classification,
    int pointsEarned, {
    String? educationalNote,
    List<String> tags = const [],
    ClassificationLocation? location,
  }) async {
    try {
      final userProfile = await _getUserProfile(userId);
      if (userProfile == null) {
        throw Exception('User profile not found');
      }

      final sharedClassification = SharedWasteClassification(
        id: _uuid.v4(),
        classification: classification,
        sharedBy: userId,
        sharedByDisplayName: userProfile.displayName ?? 'Unknown User',
        sharedByPhotoUrl: userProfile.photoUrl,
        sharedAt: DateTime.now(),
        familyId: familyId,
        location: location,
        familyTags: tags,
      );

      await _firestore
          .collection(_classificationsCollection)
          .doc(sharedClassification.id)
          .set(sharedClassification.toJson());

      // Update family stats
      await _updateFamilyStatsAfterClassification(familyId, pointsEarned);
    } catch (e) {
      throw Exception('Failed to save shared classification: $e');
    }
  }

  /// Adds a reaction to a shared classification.
  Future<void> addReactionToClassification(
    String classificationId,
    String userId,
    FamilyReactionType reactionType, {
    String? comment,
  }) async {
    try {
      final userProfile = await _getUserProfile(userId);
      if (userProfile == null) {
        throw Exception('User profile not found');
      }

      final reaction = FamilyReaction(
        userId: userId,
        displayName: userProfile.displayName ?? 'Unknown User',
        photoUrl: userProfile.photoUrl,
        type: reactionType,
        timestamp: DateTime.now(),
        comment: comment,
      );

      await _firestore
          .collection(_classificationsCollection)
          .doc(classificationId)
          .update({
        'reactions': FieldValue.arrayUnion([reaction.toJson()])
      });
    } catch (e) {
      throw Exception('Failed to add reaction: $e');
    }
  }

  /// Adds a comment to a shared classification.
  Future<void> addCommentToClassification(
    String classificationId,
    String userId,
    String text, {
    String? parentCommentId,
  }) async {
    try {
      final userProfile = await _getUserProfile(userId);
      if (userProfile == null) {
        throw Exception('User profile not found');
      }

      final comment = FamilyComment(
        id: _uuid.v4(),
        userId: userId,
        displayName: userProfile.displayName ?? 'Unknown User',
        photoUrl: userProfile.photoUrl,
        text: text,
        timestamp: DateTime.now(),
        parentCommentId: parentCommentId,
      );

      await _firestore
          .collection(_classificationsCollection)
          .doc(classificationId)
          .update({
        'comments': FieldValue.arrayUnion([comment.toJson()])
      });
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  // ================ INVITATION MANAGEMENT ================

  /// Creates an invitation for someone to join a family.
  Future<invitation_models.FamilyInvitation> createInvitation(
    String familyId,
    String inviterUserId,
    String inviteeEmail,
    user_profile_models.UserRole roleToAssign,
    {invitation_models.InvitationMethod method = invitation_models.InvitationMethod.email}
  ) async {
    try {
      final family = await getFamily(familyId);
      if (family == null) {
        throw Exception('Family not found');
      }

      final inviter = await _getUserProfile(inviterUserId);
      if (inviter == null) {
        throw Exception('Inviter profile not found');
      }

      final invitation = invitation_models.FamilyInvitation(
        familyId: familyId,
        familyName: family.name,
        inviterUserId: inviterUserId,
        inviterName: inviter.displayName ?? 'Unknown User',
        invitedEmail: inviteeEmail,
        roleToAssign: roleToAssign,
        method: method,
      );

      await _firestore
          .collection(_invitationsCollection)
          .doc(invitation.id)
          .set(invitation.toJson());

      return invitation;
    } catch (e) {
      throw Exception('Failed to create invitation: $e');
    }
  }

  /// Accepts a family invitation.
  Future<void> acceptInvitation(String invitationId, String userId) async {
    try {
      final invitationDoc = await _firestore
          .collection(_invitationsCollection)
          .doc(invitationId)
          .get();

      if (!invitationDoc.exists) {
        throw Exception('Invitation not found');
      }

      final invitation =
          invitation_models.FamilyInvitation.fromJson(invitationDoc.data()!);

      if (invitation.status != invitation_models.InvitationStatus.pending) {
        throw Exception('Invitation is not pending');
      }

      if (invitation.isExpired) {
        throw Exception('Invitation has expired');
      }

      final family = await getFamily(invitation.familyId);
      if (family == null) {
        throw Exception('Family not found');
      }

      if (!family.hasMember(userId)) {
        await addMember(invitation.familyId, userId, invitation.roleToAssign);
      }

      final updatedInvitation = invitation.copyWith(
        status: invitation_models.InvitationStatus.accepted,
        respondedAt: DateTime.now(),
        invitedUserId: userId,
      );

      await _firestore
          .collection(_invitationsCollection)
          .doc(invitationId)
          .update(updatedInvitation.toJson());
    } catch (e) {
      // Log original error for debugging while showing user-friendly message
      debugPrint('Invitation acceptance failed: $e');
      throw Exception('Unable to join family. Please try again later.');
    }
  }

  /// Declines a family invitation.
  Future<void> declineInvitation(String invitationId, String userId) async {
    try {
      final invitationDoc = await _firestore
          .collection(_invitationsCollection)
          .doc(invitationId)
          .get();

      if (!invitationDoc.exists) {
        throw Exception('Invitation not found');
      }

      final invitation = invitation_models.FamilyInvitation.fromJson(invitationDoc.data()!);

      if (invitation.status != invitation_models.InvitationStatus.pending) {
        throw Exception('Invitation is not pending');
      }

      // Update invitation status
      final updatedInvitation = invitation.copyWith(
        status: invitation_models.InvitationStatus.declined,
        respondedAt: DateTime.now(),
        invitedUserId: userId,
      );

      await _firestore
          .collection(_invitationsCollection)
          .doc(invitationId)
          .update(updatedInvitation.toJson());
    } catch (e) {
      throw Exception('Failed to decline invitation: $e');
    }
  }

  /// Resends a family invitation.
  Future<void> resendInvitation(String invitationId) async {
    try {
      final docRef = _firestore.collection(_invitationsCollection).doc(invitationId);
      await docRef.update({
        'status': invitation_models.InvitationStatus.pending.toString().split('.').last,
        'createdAt': DateTime.now().toIso8601String(),
        'expiresAt': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
        'respondedAt': null, // Reset respondedAt
      });
    } catch (e) {
      throw Exception('Failed to resend invitation: $e');
    }
  }

  /// Cancels a family invitation.
  Future<void> cancelInvitation(String invitationId) async {
    try {
      final docRef = _firestore.collection(_invitationsCollection).doc(invitationId);
      await docRef.update({
        'status': invitation_models.InvitationStatus.cancelled.toString().split('.').last,
        'respondedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to cancel invitation: $e');
    }
  }

  /// Gets all invitations for a family.
  Future<List<invitation_models.FamilyInvitation>> getInvitations(String familyId) async {
    try {
      final snapshot = await _firestore
          .collection(_invitationsCollection)
          .where('familyId', isEqualTo: familyId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => invitation_models.FamilyInvitation.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get invitations: $e');
    }
  }

  /// Returns a stream of invitations for a family.
  Stream<List<invitation_models.FamilyInvitation>> getInvitationsStream(String familyId) {
    return _firestore
        .collection(_invitationsCollection)
        .where('familyId', isEqualTo: familyId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => invitation_models.FamilyInvitation.fromJson(doc.data()))
          .toList();
    }).handleError((error) {
      debugPrint('Error in getInvitationsStream: $error');
      throw Exception('Failed to stream invitations: $error');
    });
  }

  // ================ HELPER METHODS ================

  /// Updates a user's family ID and role in their profile.
  Future<void> _updateUserFamilyId(String userId, String? familyId, user_profile_models.UserRole? role) async {
    try {
      final data = {'familyId': familyId, 'role': role?.toString().split('.').last};
      // Remove null values to avoid overwriting existing data with null if not intended
      data.removeWhere((key, value) => value == null);

      await _firestore.collection(_usersCollection).doc(userId).update(data);
    } catch (e) {
      // Log the error but don't re-throw, as this is a helper function and the main operation might still succeed
      debugPrint('Error updating user familyId: $e');
    }
  }

  /// Gets a user profile by ID.
  Future<user_profile_models.UserProfile?> _getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection(_usersCollection).doc(userId).get();
      
      if (!doc.exists || doc.data() == null) {
        return null;
      }

      return user_profile_models.UserProfile.fromJson(doc.data()!);
    } catch (e) {
      return null;
    }
  }

  /// Gets recent family classifications (limited number).
  Future<List<SharedWasteClassification>> _getRecentFamilyClassifications(String familyId, int limit) async {
    try {
      final querySnapshot = await _firestore
          .collection(_classificationsCollection)
          .where('familyId', isEqualTo: familyId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => SharedWasteClassification.fromJson(doc.data()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Gets top family members by points/activity.
  Future<List<Map<String, dynamic>>> _getTopFamilyMembers(String familyId) async {
    try {
      final family = await getFamily(familyId);
      if (family == null) return [];

      // Sort members by their individual stats (simplified)
      final sortedMembers = family.members.toList()
        ..sort((a, b) => b.individualStats.totalPoints.compareTo(a.individualStats.totalPoints));

      return sortedMembers.take(5).map((member) => {
        'userId': member.userId,
        'displayName': member.displayName,
        'photoUrl': member.photoUrl,
        'totalPoints': member.individualStats.totalPoints,
        'role': member.role.toString().split('.').last,
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Updates family stats after a new classification.
  Future<void> _updateFamilyStatsAfterClassification(String familyId, int pointsEarned) async {
    // This method needs to be re-evaluated as Family model does not have a stats property directly.
    // It might involve updating a separate 'family_stats' collection or denormalizing stats into the family document.
    // For now, this will be a no-op to prevent errors.
    debugPrint('Skipping _updateFamilyStatsAfterClassification as Family.stats is not directly available.');
    return;
    /* try {
      final family = await getFamily(familyId);
      if (family == null) return;

      // This part is problematic as family.stats doesn't exist directly
      // final updatedStats = family.stats.copyWith(
      //   totalClassifications: family.stats.totalClassifications + 1,
      //   totalPoints: family.stats.totalPoints + pointsEarned,
      //   lastUpdated: DateTime.now(),
      // );

      // final updatedFamily = family.copyWith(stats: updatedStats); // also problematic
      // await updateFamily(updatedFamily);
    } catch (e) {
      // Log error but don't throw to avoid breaking classification flow
      debugPrint('Failed to update family stats: $e');
    }*/
  }

  /// Calculates current streak for a family.
  int _calculateCurrentStreak(List<SharedWasteClassification> classifications) {
    // Simplified implementation - would need more complex logic
    // to track consecutive days with classifications
    return 0;
  }

  /// Calculates best streak for a family.
  int _calculateBestStreak(List<SharedWasteClassification> classifications) {
    // Simplified implementation
    return 0;
  }

  /// Calculates environmental impact metrics.
  family_models.EnvironmentalImpact _calculateEnvironmentalImpact(List<SharedWasteClassification> classifications) {
    final recyclableCount = classifications
        .where((c) => c.classification.isRecyclable == true)
        .length;
    
    final co2Saved = recyclableCount * 0.5; // Simplified calculation
    
    return family_models.EnvironmentalImpact(
      co2Saved: co2Saved,
      treesEquivalent: co2Saved / 22, // Rough conversion
      waterSaved: recyclableCount * 10.0, // Liters saved per item
      lastUpdated: DateTime.now(),
    );
  }

  /// Calculates weekly progress data.
  List<family_models.WeeklyProgress> _calculateWeeklyProgress(List<SharedWasteClassification> classifications) {
    // Simplified implementation - would group by weeks and calculate progress
    return [];
  }
} 