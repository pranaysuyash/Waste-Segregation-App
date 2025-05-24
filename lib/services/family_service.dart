import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:waste_segregation_app/models/family.dart';
import 'package:waste_segregation_app/models/user_profile.dart';
import 'package:waste_segregation_app/services/storage_service.dart';
import 'package:waste_segregation_app/utils/constants.dart';
import 'package:hive/hive.dart';

class FamilyService extends ChangeNotifier {
  final StorageService _storageService;

  FamilyService(this._storageService);

  /// Creates a new family with the given admin user and family name.
  /// 
  /// Updates the admin's UserProfile with the new familyId and admin role.
  /// Returns the newly created Family object, or null if creation failed.
  Future<Family?> createFamily(String adminUserId, String familyName) async {
    try {
      // 1. Get admin UserProfile
      UserProfile? adminProfile = await _storageService.getCurrentUserProfile();

      if (adminProfile == null || adminProfile.id != adminUserId) {
        // If the current user is not the specified admin or profile not found
        // This might happen if the adminUserId passed is different from the logged-in user.
        // For now, assume adminUserId is the ID of the currently logged-in user.
        adminProfile = await _storageService.getUserProfile(adminUserId);
        if (adminProfile == null) {
            debugPrint('FamilyService: Admin user profile not found for ID: $adminUserId');
            return null;
        }
      }

      // 2. Check if user is already in a family
      if (adminProfile.familyId != null && adminProfile.familyId!.isNotEmpty) {
        debugPrint('FamilyService: User $adminUserId is already in family ${adminProfile.familyId}');
        // Optionally, retrieve and return the existing family or throw an error
        return await getFamily(adminProfile.familyId!);
      }

      // 3. Create the Family object
      final newFamily = Family(
        familyName: familyName,
        adminUserId: adminUserId,
        // memberUserIds will automatically include adminUserId from the Family constructor
      );

      // 4. Save the Family object to its Hive box
      final familiesBox = Hive.box<String>(StorageKeys.familiesBox);
      await familiesBox.put(newFamily.id, jsonEncode(newFamily.toJson()));
      // Alternative: Register FamilyAdapter and store Family object directly
      // For now, JSON string is simpler without needing to run build_runner for adapters.

      // 5. Update the admin's UserProfile
      final updatedAdminProfile = adminProfile.copyWith(
        familyId: newFamily.id,
        role: UserRole.admin, // Set user's role to admin in their family
      );
      await _storageService.saveUserProfile(updatedAdminProfile);

      debugPrint('FamilyService: Family "${newFamily.familyName}" (ID: ${newFamily.id}) created by admin ${adminUserId}.');
      notifyListeners();
      return newFamily;
    } catch (e, stackTrace) {
      debugPrint('FamilyService: Error creating family: $e\n$stackTrace');
      // Consider more specific error handling or re-throwing
      return null;
    }
  }

  /// Retrieves a family by its ID.
  Future<Family?> getFamily(String familyId) async {
    try {
      final familiesBox = Hive.box<String>(StorageKeys.familiesBox);
      final familyJsonString = familiesBox.get(familyId);

      if (familyJsonString != null) {
        // familyJsonString is a JSON string, decode it to a Map
        final Map<String, dynamic> familyJson = jsonDecode(familyJsonString);
        return Family.fromJson(familyJson);
      }
      debugPrint('FamilyService: Family with ID $familyId not found.');
      return null;
    } catch (e, stackTrace) {
      debugPrint('FamilyService: Error retrieving family $familyId: $e\n$stackTrace');
      return null;
    }
  }

   /// Saves an updated Family object.
  Future<bool> updateFamily(Family family) async {
    try {
      final familiesBox = Hive.box<String>(StorageKeys.familiesBox);
      family.updatedAt = DateTime.now(); // Update timestamp
      // Convert to JSON string before saving
      await familiesBox.put(family.id, jsonEncode(family.toJson())); 
      debugPrint('FamilyService: Family "${family.familyName}" (ID: ${family.id}) updated.');
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      debugPrint('FamilyService: Error updating family ${family.id}: $e\n$stackTrace');
      return false;
    }
  }

  /// Adds a user to an existing family.
  /// 
  /// Updates the Family's member list and the UserProfile of the added user.
  /// Returns true if successful, false otherwise.
  Future<bool> addUserToFamily(String familyId, String userIdToAdd, {UserRole role = UserRole.member}) async {
    try {
      // 1. Retrieve the Family
      Family? family = await getFamily(familyId);
      if (family == null) {
        debugPrint('FamilyService: Cannot add user to non-existent family $familyId');
        return false;
      }

      // 2. Retrieve the UserProfile of the user to add
      UserProfile? userProfileToAdd = await _storageService.getUserProfile(userIdToAdd);
      if (userProfileToAdd == null) {
        debugPrint('FamilyService: User profile $userIdToAdd not found to add to family $familyId');
        return false;
      }

      // 3. Check if user is already in a different family (basic check)
      if (userProfileToAdd.familyId != null && userProfileToAdd.familyId != familyId) {
        debugPrint('FamilyService: User $userIdToAdd is already in another family (${userProfileToAdd.familyId}). Cannot add to $familyId without leaving first.');
        // For a more robust system, this might throw an error or require a specific flow.
        return false; 
      }

      // 4. Update Family object
      bool familyModified = false;
      if (!family.memberUserIds.contains(userIdToAdd)) {
        family.memberUserIds.add(userIdToAdd);
        familyModified = true;
      }
      // If invites were implemented, you might remove from pendingInviteIds here.

      if (familyModified) {
        family.updatedAt = DateTime.now();
        bool familyUpdateSuccess = await updateFamily(family);
        if (!familyUpdateSuccess) {
          debugPrint('FamilyService: Failed to update family $familyId after adding user $userIdToAdd');
          return false; // Or attempt to rollback UserProfile changes if any were made
        }
      }

      // 5. Update UserProfile object
      // Only update if familyId or role changes, or if explicitly joining this family
      if (userProfileToAdd.familyId != familyId || userProfileToAdd.role != role) {
          final updatedUserProfile = userProfileToAdd.copyWith(
            familyId: familyId,
            role: role,
            updatedAt: DateTime.now(),
          );
          await _storageService.saveUserProfile(updatedUserProfile);
      } else if (familyModified) {
          // if user was already in this family (familyId and role matched) but family.memberUserIds was updated (e.g. admin re-added)
          // ensure their profile reflects current time of this family activity
          final updatedUserProfile = userProfileToAdd.copyWith(updatedAt: DateTime.now());
          await _storageService.saveUserProfile(updatedUserProfile);
      }
      

      debugPrint('FamilyService: User $userIdToAdd added to family "${family.familyName}" (ID: $familyId) with role $role.');
      notifyListeners(); // Notify if either family or user profile was likely changed.
      return true;

    } catch (e, stackTrace) {
      debugPrint('FamilyService: Error adding user $userIdToAdd to family $familyId: $e\n$stackTrace');
      return false;
    }
  }

  /// Removes a user from an existing family.
  ///
  /// Updates the Family's member list and clears family-related fields in the UserProfile.
  /// Returns true if successful, false otherwise.
  /// Note: This method does not currently handle admin transfer or family deletion if an admin is removed.
  Future<bool> removeUserFromFamily(String familyId, String userIdToRemove) async {
    try {
      // 1. Retrieve the Family
      Family? family = await getFamily(familyId);
      if (family == null) {
        debugPrint('FamilyService: Cannot remove user from non-existent family $familyId');
        return false;
      }

      // 2. Retrieve the UserProfile of the user to remove
      UserProfile? userProfileToRemove = await _storageService.getUserProfile(userIdToRemove);
      if (userProfileToRemove == null) {
        debugPrint('FamilyService: User profile $userIdToRemove not found to remove from family $familyId');
        return false;
      }

      // 3. Check if user is actually part of this family in their profile
      if (userProfileToRemove.familyId != familyId) {
        debugPrint('FamilyService: User $userIdToRemove is not listed under family $familyId in their profile. Current family: ${userProfileToRemove.familyId}');
        // User might already have been removed or belongs to another family. Consider this a success or a specific state.
        // For now, if they are not in *this* family as per their profile, we don't need to update their profile further regarding *this* family.
        // However, we should still ensure they are not in the family's member list.
      }
      
      // 4. Update Family object
      bool familyModified = false;
      if (family.memberUserIds.contains(userIdToRemove)) {
        // Special handling if the admin is being removed
        if (family.adminUserId == userIdToRemove) {
          debugPrint('FamilyService: Admin $userIdToRemove is being removed from family $familyId. This might require admin transfer or family deletion logic not yet implemented.');
          // For now, we allow admin removal. The family might become admin-less or require manual intervention.
          // A more robust solution would involve an admin transfer or checks if other members exist.
        }
        family.memberUserIds.remove(userIdToRemove);
        familyModified = true;

        // If the family is now empty, what happens? For now, it just becomes an empty family.
        if (family.memberUserIds.isEmpty) {
            debugPrint('FamilyService: Family $familyId is now empty after removing $userIdToRemove.');
            // Future: Consider auto-archiving or deleting empty families after a grace period.
        }
      } else {
        // User not in family's member list. No change to family needed.
        // If their profile *did* point to this family (handled above), then profile update is still needed.
      }

      if (familyModified) {
        family.updatedAt = DateTime.now();
        bool familyUpdateSuccess = await updateFamily(family);
        if (!familyUpdateSuccess) {
          debugPrint('FamilyService: Failed to update family $familyId after removing user $userIdToRemove');
          return false;
        }
      }

      // 5. Update UserProfile object for the removed user
      // Only update if their profile was indeed pointing to this familyId
      if (userProfileToRemove.familyId == familyId) {
          final updatedUserProfile = userProfileToRemove.copyWith(
            familyId: null, // Clear family ID
            role: null,     // Clear role
            updatedAt: DateTime.now(),
          );
          await _storageService.saveUserProfile(updatedUserProfile);
      }

      debugPrint('FamilyService: User $userIdToRemove removed from family "${family.familyName}" (ID: $familyId).');
      notifyListeners();
      return true;

    } catch (e, stackTrace) {
      debugPrint('FamilyService: Error removing user $userIdToRemove from family $familyId: $e\n$stackTrace');
      return false;
    }
  }

  /// Retrieves a list of UserProfile objects for all members of a given family.
  Future<List<UserProfile>> getFamilyMembers(String familyId) async {
    final List<UserProfile> members = [];
    try {
      Family? family = await getFamily(familyId);
      if (family == null) {
        debugPrint('FamilyService: Family $familyId not found when trying to get members.');
        return members; // Return empty list
      }

      for (String memberId in family.memberUserIds) {
        UserProfile? userProfile = await _storageService.getUserProfile(memberId);
        if (userProfile != null) {
          members.add(userProfile);
        } else {
          debugPrint('FamilyService: User profile $memberId (member of family $familyId) not found.');
          // Decide if this is critical. For now, we just skip them.
        }
      }
    } catch (e, stackTrace) {
      debugPrint('FamilyService: Error retrieving family members for $familyId: $e\n$stackTrace');
      // Return whatever was collected so far, or an empty list on severe error.
    }
    return members;
  }

  /// Retrieves the Family object a specific user belongs to, if any.
  Future<Family?> getUserFamily(String userId) async {
    try {
      UserProfile? userProfile = await _storageService.getUserProfile(userId);
      if (userProfile == null) {
        debugPrint('FamilyService: User profile $userId not found when trying to get their family.');
        return null;
      }

      if (userProfile.familyId != null && userProfile.familyId!.isNotEmpty) {
        return await getFamily(userProfile.familyId!);
      }
      // User is not part of any family
      return null;
    } catch (e, stackTrace) {
      debugPrint('FamilyService: Error retrieving family for user $userId: $e\n$stackTrace');
      return null;
    }
  }

  /// Invites a user (by email) to join a specific family.
  ///
  /// Only family admins can send invitations.
  /// Returns the created FamilyInvitation object if successful, null otherwise.
  Future<FamilyInvitation?> inviteUserToFamily(
    String familyId,
    String invitedEmail,
    {UserRole roleToAssign = UserRole.member}
  ) async {
    try {
      // 1. Get the current user (inviter)
      UserProfile? inviterProfile = await _storageService.getCurrentUserProfile();
      if (inviterProfile == null) {
        debugPrint('FamilyService: Inviter profile not found. User must be logged in to invite.');
        return null;
      }

      // 2. Get the family
      Family? family = await getFamily(familyId);
      if (family == null) {
        debugPrint('FamilyService: Family $familyId not found to send invitation from.');
        return null;
      }

      // 3. Check if inviter is an admin of the family
      if (family.adminUserId != inviterProfile.id) {
        // More complex permission check could go here if non-admins can invite
        debugPrint('FamilyService: User ${inviterProfile.id} is not an admin of family $familyId. Cannot send invite.');
        return null;
      }

      // 4. Check if the invited email already corresponds to an existing member
      List<UserProfile> currentMembers = await getFamilyMembers(familyId);
      for (UserProfile member in currentMembers) {
        if (member.email == invitedEmail) {
          debugPrint('FamilyService: User with email $invitedEmail is already a member of family $familyId.');
          // Optionally, could return an error or a specific status code
          return null; // Or throw Exception('User is already a member.');
        }
      }

      // 5. Check for existing, non-expired, pending invitation for this email to this family
      final invitationsBox = Hive.box<String>(StorageKeys.invitationsBox);
      for (var key in invitationsBox.keys) {
        final inviteJsonString = invitationsBox.get(key);
        if (inviteJsonString != null) {
          final existingInvite = FamilyInvitation.fromJson(jsonDecode(inviteJsonString));
          if (existingInvite.familyId == familyId &&
              existingInvite.invitedEmail == invitedEmail &&
              existingInvite.status == InvitationStatus.pending &&
              !existingInvite.isExpired) {
            debugPrint('FamilyService: Active pending invitation already exists for $invitedEmail to family $familyId.');
            return existingInvite; // Return existing active invite
          }
        }
      }

      // 6. Create FamilyInvitation object
      final newInvitation = FamilyInvitation(
        familyId: family.id,
        familyName: family.familyName,
        inviterUserId: inviterProfile.id,
        inviterName: inviterProfile.displayName,
        invitedEmail: invitedEmail,
        roleToAssign: roleToAssign,
      );

      // 7. Save the invitation
      await invitationsBox.put(newInvitation.id, jsonEncode(newInvitation.toJson()));

      // 8. Add invitation ID to Family.pendingInviteIds and update family
      if (!family.pendingInviteIds.contains(newInvitation.id)) {
        family.pendingInviteIds.add(newInvitation.id);
        family.updatedAt = DateTime.now();
        await updateFamily(family); // This will also notify listeners if successful
      }

      debugPrint('FamilyService: Invitation sent to $invitedEmail for family "${family.familyName}" by ${inviterProfile.displayName}.');
      // notifyListeners(); // updateFamily already calls notifyListeners
      return newInvitation;

    } catch (e, stackTrace) {
      debugPrint('FamilyService: Error inviting user to family: $e\n$stackTrace');
      return null;
    }
  }

  /// Accepts a family invitation.
  /// 
  /// The currently logged-in user accepts the invitation specified by invitationId.
  /// Returns true if successful, false otherwise.
  Future<bool> acceptFamilyInvite(String invitationId) async {
    try {
      // 1. Get current user (acceptingUser)
      UserProfile? acceptingUser = await _storageService.getCurrentUserProfile();
      if (acceptingUser == null) {
        debugPrint('FamilyService: User must be logged in to accept an invitation.');
        return false;
      }

      // 2. Retrieve the FamilyInvitation
      final invitationsBox = Hive.box<String>(StorageKeys.invitationsBox);
      final inviteJsonString = invitationsBox.get(invitationId);
      if (inviteJsonString == null) {
        debugPrint('FamilyService: Invitation $invitationId not found.');
        return false;
      }
      FamilyInvitation invitation = FamilyInvitation.fromJson(jsonDecode(inviteJsonString));

      // 3. Validate the invitation
      if (invitation.status != InvitationStatus.pending) {
        debugPrint('FamilyService: Invitation $invitationId is not pending (status: ${invitation.status}).');
        return false;
      }
      if (invitation.isExpired) {
        invitation.status = InvitationStatus.expired;
        invitation.respondedAt = DateTime.now();
        await invitationsBox.put(invitation.id, jsonEncode(invitation.toJson()));
        debugPrint('FamilyService: Invitation $invitationId has expired.');
        // Attempt to remove from family's pending list if it was still there
        _removeInviteIdFromFamilyPendingList(invitation.familyId, invitation.id);
        return false;
      }
      if (invitation.invitedEmail.toLowerCase() != acceptingUser.email?.toLowerCase()) {
        debugPrint('FamilyService: Invitation $invitationId for ${invitation.invitedEmail} cannot be accepted by ${acceptingUser.email}.');
        return false;
      }

      // 4. Check if user is already in another family
      if (acceptingUser.familyId != null && acceptingUser.familyId!.isNotEmpty) {
        debugPrint('FamilyService: User ${acceptingUser.id} is already in family ${acceptingUser.familyId}. Must leave current family first.');
        return false;
      }

      // 5. Process acceptance
      bool addedToFamily = await addUserToFamily(invitation.familyId, acceptingUser.id, role: invitation.roleToAssign);

      if (addedToFamily) {
        invitation.status = InvitationStatus.accepted;
        invitation.respondedAt = DateTime.now();
        invitation.invitedUserId = acceptingUser.id;
        await invitationsBox.put(invitation.id, jsonEncode(invitation.toJson()));

        // Remove from family's pending list (addUserToFamily already calls notifyListeners)
        await _removeInviteIdFromFamilyPendingList(invitation.familyId, invitation.id);
        
        debugPrint('FamilyService: User ${acceptingUser.id} accepted invitation $invitationId for family ${invitation.familyId}.');
        // notifyListeners(); // addUserToFamily and updateFamily (called by _removeInviteId...) will notify
        return true;
      } else {
        debugPrint('FamilyService: Failed to add user ${acceptingUser.id} to family ${invitation.familyId} after accepting invite $invitationId.');
        // Invitation remains pending if addUserToFamily failed
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('FamilyService: Error accepting family invitation $invitationId: $e\n$stackTrace');
      return false;
    }
  }

  /// Declines a family invitation.
  ///
  /// The currently logged-in user declines the invitation.
  Future<bool> declineFamilyInvite(String invitationId) async {
    try {
      UserProfile? decliningUser = await _storageService.getCurrentUserProfile();
      if (decliningUser == null) {
        debugPrint('FamilyService: User must be logged in to decline an invitation.');
        return false;
      }

      final invitationsBox = Hive.box<String>(StorageKeys.invitationsBox);
      final inviteJsonString = invitationsBox.get(invitationId);
      if (inviteJsonString == null) {
        debugPrint('FamilyService: Invitation $invitationId not found to decline.');
        return false;
      }
      FamilyInvitation invitation = FamilyInvitation.fromJson(jsonDecode(inviteJsonString));

      if (invitation.status != InvitationStatus.pending) {
        debugPrint('FamilyService: Invitation $invitationId cannot be declined (status: ${invitation.status}).');
        return false; // Or already handled
      }
      if (invitation.isExpired) {
        invitation.status = InvitationStatus.expired;
        // No need to update respondedAt for an auto-expiration while trying to decline
        await invitationsBox.put(invitation.id, jsonEncode(invitation.toJson()));
        _removeInviteIdFromFamilyPendingList(invitation.familyId, invitation.id);
        return false; // Already expired
      }
      if (invitation.invitedEmail.toLowerCase() != decliningUser.email?.toLowerCase()) {
        debugPrint('FamilyService: Invitation $invitationId for ${invitation.invitedEmail} cannot be declined by ${decliningUser.email}.');
        return false;
      }

      invitation.status = InvitationStatus.declined;
      invitation.respondedAt = DateTime.now();
      invitation.invitedUserId = decliningUser.id; // Record who declined
      await invitationsBox.put(invitation.id, jsonEncode(invitation.toJson()));

      await _removeInviteIdFromFamilyPendingList(invitation.familyId, invitation.id);

      debugPrint('FamilyService: User ${decliningUser.id} declined invitation $invitationId for family ${invitation.familyId}.');
      // notifyListeners(); // updateFamily (called by _removeInviteId...) will notify
      return true;
    } catch (e, stackTrace) {
      debugPrint('FamilyService: Error declining family invitation $invitationId: $e\n$stackTrace');
      return false;
    }
  }

  /// Helper to remove an invitation ID from a family's pending list.
  Future<void> _removeInviteIdFromFamilyPendingList(String familyId, String invitationId) async {
    Family? family = await getFamily(familyId);
    if (family != null && family.pendingInviteIds.contains(invitationId)) {
      family.pendingInviteIds.remove(invitationId);
      family.updatedAt = DateTime.now();
      await updateFamily(family); // This handles notifyListeners
    }
  }

  /// Retrieves all non-expired, pending invitations for a given user email.
  Future<List<FamilyInvitation>> getPendingInvitesForUser(String userEmail) async {
    final List<FamilyInvitation> pendingInvites = [];
    try {
      final invitationsBox = Hive.box<String>(StorageKeys.invitationsBox);
      final lowercasedUserEmail = userEmail.toLowerCase();

      for (var key in invitationsBox.keys) {
        final inviteJsonString = invitationsBox.get(key);
        if (inviteJsonString != null) {
          final invitation = FamilyInvitation.fromJson(jsonDecode(inviteJsonString));
          if (invitation.invitedEmail.toLowerCase() == lowercasedUserEmail &&
              invitation.status == InvitationStatus.pending &&
              !invitation.isExpired) {
            pendingInvites.add(invitation);
          }
        }
      }
      // Sort by creation date, newest first
      pendingInvites.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return pendingInvites;
    } catch (e, stackTrace) {
      debugPrint('FamilyService: Error retrieving pending invites for user $userEmail: $e\n$stackTrace');
      return []; // Return empty list on error
    }
  }

  /// Retrieves all non-expired, pending invitations for a given family ID.
  Future<List<FamilyInvitation>> getPendingInvitesForFamily(String familyId) async {
    final List<FamilyInvitation> pendingInvites = [];
    try {
      final invitationsBox = Hive.box<String>(StorageKeys.invitationsBox);

      for (var key in invitationsBox.keys) {
        final inviteJsonString = invitationsBox.get(key);
        if (inviteJsonString != null) {
          final invitation = FamilyInvitation.fromJson(jsonDecode(inviteJsonString));
          if (invitation.familyId == familyId &&
              invitation.status == InvitationStatus.pending &&
              !invitation.isExpired) {
            pendingInvites.add(invitation);
          }
        }
      }
      // Sort by creation date, newest first
      pendingInvites.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return pendingInvites;
    } catch (e, stackTrace) {
      debugPrint('FamilyService: Error retrieving pending invites for family $familyId: $e\n$stackTrace');
      return [];
    }
  }
  
  /// Admin action to cancel a pending invitation.
  Future<bool> cancelFamilyInvitation(String invitationId, String adminUserId) async {
    try {
        FamilyInvitation? invitation = await getInvitationById(invitationId);
        if (invitation == null) {
            debugPrint('FamilyService: Invitation $invitationId not found to cancel.');
            return false;
        }

        Family? family = await getFamily(invitation.familyId);
        if (family == null || family.adminUserId != adminUserId) {
            debugPrint('FamilyService: User $adminUserId is not authorized to cancel invites for family ${invitation.familyId}.');
            return false;
        }

        if (invitation.status != InvitationStatus.pending || invitation.isExpired) {
            debugPrint('FamilyService: Invitation $invitationId cannot be cancelled (status: ${invitation.status}, expired: ${invitation.isExpired}).');
            return false;
        }

        invitation.status = InvitationStatus.cancelled;
        invitation.respondedAt = DateTime.now(); // Time of cancellation
        
        final invitationsBox = Hive.box<String>(StorageKeys.invitationsBox);
        await invitationsBox.put(invitation.id, jsonEncode(invitation.toJson()));

        await _removeInviteIdFromFamilyPendingList(invitation.familyId, invitation.id);
        notifyListeners();
        debugPrint('FamilyService: Invitation $invitationId cancelled by admin $adminUserId.');
        return true;
    } catch (e, stackTrace) {
        debugPrint('FamilyService: Error cancelling invitation $invitationId: $e\n$stackTrace');
        return false;
    }
  }

  /// Helper to get a single invitation by its ID (internal use or for specific scenarios)
  Future<FamilyInvitation?> getInvitationById(String invitationId) async {
    try {
      final invitationsBox = Hive.box<String>(StorageKeys.invitationsBox);
      final invitationJsonString = invitationsBox.get(invitationId);

      if (invitationJsonString != null) {
        final Map<String, dynamic> invitationJson = jsonDecode(invitationJsonString);
        return FamilyInvitation.fromJson(invitationJson);
      }
      debugPrint('FamilyService: Invitation with ID $invitationId not found.');
      return null;
    } catch (e, stackTrace) {
      debugPrint('FamilyService: Error retrieving invitation $invitationId: $e\n$stackTrace');
      return null;
    }
  }

  /// Allows the currently logged-in user to leave their family.
  ///
  /// Returns true if successful, false otherwise.
  /// If the user is the admin and other members exist, they cannot leave
  /// without transferring admin rights (not yet implemented).
  /// If the user is the admin and is the sole member, the family may be deleted (future enhancement).
  Future<bool> leaveFamily() async {
    try {
      // 1. Get current user
      UserProfile? currentUser = await _storageService.getCurrentUserProfile();
      if (currentUser == null) {
        debugPrint('FamilyService: No logged-in user found. Cannot leave family.');
        return false;
      }

      // 2. Check if user is in a family
      if (currentUser.familyId == null || currentUser.familyId!.isEmpty) {
        debugPrint('FamilyService: User ${currentUser.id} is not in a family. Cannot leave.');
        // Consider this a success if the goal is "not in a family"
        return true;
      }

      String familyId = currentUser.familyId!;

      // 3. Retrieve the Family
      Family? family = await getFamily(familyId);
      if (family == null) {
        debugPrint('FamilyService: Family $familyId not found for user ${currentUser.id}. Clearing profile.');
        // Family doesn't exist, but user profile points to it. Clean up user profile.
        final updatedUserProfile = currentUser.copyWith(
          familyId: null,
          role: null,
          updatedAt: DateTime.now(),
        );
        await _storageService.saveUserProfile(updatedUserProfile);
        notifyListeners();
        return true; // User is effectively out of a non-existent family.
      }

      // 4. Handle admin leaving
      if (family.adminUserId == currentUser.id) {
        if (family.memberUserIds.length > 1) {
          debugPrint('FamilyService: Admin ${currentUser.id} cannot leave family ${family.id} as other members exist. Admin transfer required.');
          // TODO: Implement admin transfer logic or prompt.
          // For now, prevent leaving.
          return false;
        } else {
          // Admin is the only member.
          // Future: Consider deleting the family here or marking it for deletion.
          debugPrint('FamilyService: Admin ${currentUser.id} is the only member of family ${family.id}. Leaving will make the family memberless (or could delete it).');
          // Proceed to remove them. The family will become memberless.
        }
      }

      // 5. Remove user from family's member list
      bool familyModified = false;
      if (family.memberUserIds.contains(currentUser.id)) {
        family.memberUserIds.remove(currentUser.id);
        familyModified = true;
      }

      if (familyModified) {
        family.updatedAt = DateTime.now();
        // If the family becomes empty after the user leaves
        if (family.memberUserIds.isEmpty) {
            debugPrint('FamilyService: Family ${family.id} is now empty after user ${currentUser.id} left.');
            // Future: Decide if an empty family should be deleted or archived.
            // For now, it remains an empty family.
        }
        bool familyUpdateSuccess = await updateFamily(family);
        if (!familyUpdateSuccess) {
          debugPrint('FamilyService: Failed to update family ${family.id} after user ${currentUser.id} left.');
          // Attempt to rollback? For now, profile will still be updated.
          // This could lead to inconsistency if family update fails.
        }
      }

      // 6. Update UserProfile
      final updatedUserProfile = currentUser.copyWith(
        familyId: null,
        role: null,
        updatedAt: DateTime.now(),
      );
      await _storageService.saveUserProfile(updatedUserProfile);

      debugPrint('FamilyService: User ${currentUser.id} successfully left family ${family.id}.');
      notifyListeners();
      return true;

    } catch (e, stackTrace) {
      debugPrint('FamilyService: Error leaving family: $e\n$stackTrace');
      return false;
    }
  }

  /// Allows the admin of a family to delete the family.
  /// 
  /// All members will be removed from the family (their profiles updated).
  /// All pending invitations for this family will be cancelled.
  /// Returns true if successful, false otherwise.
  /// Optional: `confirmDeletionIfMembersExist` - if false (default), deletion is blocked if >1 member.
  Future<bool> deleteFamily(String familyId, String adminUserId, {bool confirmDeletionIfMembersExist = false}) async {
    try {
      // 1. Get current user (admin)
      UserProfile? adminProfile = await _storageService.getUserProfile(adminUserId);
      if (adminProfile == null) {
        debugPrint('FamilyService: Admin profile $adminUserId not found. Cannot delete family.');
        return false;
      }
      if (adminProfile.familyId != familyId) {
          debugPrint('FamilyService: Admin $adminUserId is not part of family $familyId they are trying to delete.');
          return false;
      }

      // 2. Retrieve the Family
      Family? family = await getFamily(familyId);
      if (family == null) {
        debugPrint('FamilyService: Family $familyId not found. Cannot delete.');
        // If family doesn't exist, it's already effectively deleted.
        // We should still ensure the admin's profile is clean if it somehow still references it.
        if (adminProfile.familyId == familyId) {
            final updatedAdminProfile = adminProfile.copyWith(familyId: null, role: null, updatedAt: DateTime.now());
            await _storageService.saveUserProfile(updatedAdminProfile);
        }
        return true; 
      }

      // 3. Check if the user is the admin of this family
      if (family.adminUserId != adminUserId) {
        debugPrint('FamilyService: User $adminUserId is not the admin of family ${family.id}. Cannot delete.');
        return false;
      }

      // 4. Check for other members if confirmation is not given
      if (family.memberUserIds.length > 1 && !confirmDeletionIfMembersExist) {
        debugPrint('FamilyService: Family ${family.id} has other members. Admin $adminUserId must confirm deletion.');
        // TODO: This could throw a specific exception or return a specific status code
        // to inform the UI to ask for confirmation.
        return false; 
      }

      // 5. Remove/update all members
      List<String> membersToRemove = List.from(family.memberUserIds); // Create a copy to iterate
      for (String memberId in membersToRemove) {
        UserProfile? memberProfile = await _storageService.getUserProfile(memberId);
        if (memberProfile != null && memberProfile.familyId == familyId) {
          final updatedMemberProfile = memberProfile.copyWith(
            familyId: null,
            role: null, // Clear role
            updatedAt: DateTime.now(),
          );
          await _storageService.saveUserProfile(updatedMemberProfile);
          debugPrint('FamilyService: Cleared family info for member $memberId from deleted family ${family.id}.');
        }
      }
      // The family object's member list will be effectively cleared by deleting the family.

      // 6. Cancel all pending invitations for this family
      List<FamilyInvitation> pendingInvites = await getPendingInvitesForFamily(familyId);
      for (FamilyInvitation invite in pendingInvites) {
        if (invite.status == InvitationStatus.pending) {
          invite.status = InvitationStatus.cancelled; // Or a new status like 'family_deleted'
          invite.respondedAt = DateTime.now();
          final invitationsBox = Hive.box<String>(StorageKeys.invitationsBox);
          await invitationsBox.put(invite.id, jsonEncode(invite.toJson()));
          debugPrint('FamilyService: Cancelled pending invitation ${invite.id} for deleted family ${family.id}.');
        }
      }
      // The family object's pendingInviteIds list will be cleared by deleting the family.

      // 7. Delete the Family from Hive box
      final familiesBox = Hive.box<String>(StorageKeys.familiesBox);
      await familiesBox.delete(familyId);

      debugPrint('FamilyService: Family ${family.id} deleted by admin $adminUserId.');
      notifyListeners(); // Notify listeners about the change (e.g., admin's UI might update)
      return true;

    } catch (e, stackTrace) {
      debugPrint('FamilyService: Error deleting family $familyId: $e\n$stackTrace');
      return false;
    }
  }

  // TODO: Implement admin transfer logic for when an admin leaves/is removed
}

</rewritten_file>