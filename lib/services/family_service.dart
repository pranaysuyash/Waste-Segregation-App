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

  // TODO: Implement other methods:
  // - inviteUserToFamily(familyId, emailOrIdentifierToInvite)
  // - acceptFamilyInvite(inviteId, userIdAccepting)
  // - declineFamilyInvite(inviteId)
  // - leaveFamily(familyId, userIdLeaving) // User initiated
  // - deleteFamily(familyId, adminUserId) // Admin initiated, careful with this!
} 