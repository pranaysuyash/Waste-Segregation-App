import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/enhanced_family.dart' as family_models;
import '../models/user_profile.dart' as user_models;
import '../models/family_invitation.dart' as invitation_models;
import '../models/user_profile.dart' as user_profile_models;
import '../services/firebase_family_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import 'package:waste_segregation_app/utils/waste_app_logger.dart';

class FamilyManagementScreen extends StatefulWidget {
  const FamilyManagementScreen({
    super.key,
    required this.family,
  });
  final family_models.Family family;

  @override
  State<FamilyManagementScreen> createState() => _FamilyManagementScreenState();
}

class _FamilyManagementScreenState extends State<FamilyManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  user_models.UserProfile? _currentUser;
  final FirebaseFamilyService _familyService = FirebaseFamilyService();
  late family_models.Family _currentFamily;

  @override
  void initState() {
    super.initState();
    _currentFamily = widget.family;
    _tabController = TabController(length: 3, vsync: this);
    _loadInitialUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialUserData() async {
    try {
      final storageService = Provider.of<StorageService>(context, listen: false);
      _currentUser = await storageService.getCurrentUserProfile();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load user data: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _handleRefresh() async {
    await _loadInitialUserData();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<family_models.Family?>(
      stream: _familyService.getFamilyStream(widget.family.id),
      initialData: _currentFamily,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: Text('Manage ${widget.family.name}')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: Text('Manage ${widget.family.name}')),
            body: Center(child: Text('Error loading family data: ${snapshot.error}')),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          _currentFamily = snapshot.data!;
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('Manage ${_currentFamily.name}'),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.people), text: 'Members'),
                Tab(icon: Icon(Icons.mail), text: 'Invitations'),
                Tab(icon: Icon(Icons.settings), text: 'Settings'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildMembersTab(_currentFamily),
              _buildInvitationsTab(_currentFamily),
              _buildSettingsTab(_currentFamily),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMembersTab(family_models.Family family) {
    return StreamBuilder<List<user_models.UserProfile>>(
      stream: _familyService.getFamilyMembersStream(family.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error loading members: ${snapshot.error}'));
        }
        final members = snapshot.data ?? [];
        if (members.isEmpty) {
          return const Center(child: Text('No members found.'));
        }

        return RefreshIndicator(
          onRefresh: _handleRefresh,
          child: ListView.builder(
            padding: const EdgeInsets.all(AppTheme.paddingRegular),
            itemCount: members.length,
            itemBuilder: (context, index) {
              final memberProfile = members[index];
              final familyMemberData = family.getMember(memberProfile.id);
              final isCurrentUser = _currentUser?.id == memberProfile.id;
              final canModify = _canModifyMember(family, memberProfile.id);

              return Card(
                margin: const EdgeInsets.only(bottom: AppTheme.paddingRegular),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                    backgroundImage: memberProfile.photoUrl != null ? NetworkImage(memberProfile.photoUrl!) : null,
                    child:
                        memberProfile.photoUrl == null ? Text(memberProfile.displayName?.substring(0, 1) ?? 'U') : null,
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          memberProfile.displayName ?? 'Unknown User',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (isCurrentUser)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'You',
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(memberProfile.email ?? 'No email'),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getRoleColor(familyMemberData?.role ?? family_models.UserRole.member),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getRoleText(familyMemberData?.role ?? family_models.UserRole.member),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Joined ${_formatDate(familyMemberData?.joinedAt ?? DateTime.now())}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                      if (familyMemberData != null)
                        Text(
                          '${familyMemberData.individualStats.totalPoints} points • '
                          '${familyMemberData.individualStats.totalClassifications} classifications',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                    ],
                  ),
                  trailing: canModify
                      ? PopupMenuButton<String>(
                          onSelected: (value) => _handleMemberAction(value, memberProfile, family),
                          itemBuilder: (context) => [
                            if (!isCurrentUser && _canChangeRole(family, memberProfile.id))
                              const PopupMenuItem(
                                value: 'change_role',
                                child: Row(
                                  children: [
                                    Icon(Icons.admin_panel_settings),
                                    SizedBox(width: 8),
                                    Text('Change Role'),
                                  ],
                                ),
                              ),
                            if (!isCurrentUser && _canRemoveMember(family, memberProfile.id))
                              const PopupMenuItem(
                                value: 'remove',
                                child: Row(
                                  children: [
                                    Icon(Icons.remove_circle, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Remove', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                          ],
                        )
                      : null,
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildInvitationsTab(family_models.Family family) {
    return StreamBuilder<List<invitation_models.FamilyInvitation>>(
      stream: _familyService.getInvitationsStream(family.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error loading invitations: ${snapshot.error}'));
        }
        final invitations = snapshot.data ?? [];
        if (invitations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('No pending invitations.'),
                const SizedBox(height: AppTheme.paddingLarge),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Invite Member'),
                  onPressed: () => _showInviteDialog(family),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _handleRefresh,
          child: ListView.builder(
            padding: const EdgeInsets.all(AppTheme.paddingRegular),
            itemCount: invitations.length,
            itemBuilder: (context, index) {
              final invitation = invitations[index];
              final canManage = _canManageInvitations(family);

              return Card(
                margin: const EdgeInsets.only(bottom: AppTheme.paddingRegular),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.mail_outline)),
                  title: Text(invitation.invitedEmail),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getRoleColor(_convertUserRole(invitation.roleToAssign)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getRoleText(_convertUserRole(invitation.roleToAssign)),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (invitation.status == invitation_models.InvitationStatus.pending)
                            const Chip(label: Text('Pending'), backgroundColor: Colors.orangeAccent),
                          if (invitation.status == invitation_models.InvitationStatus.accepted)
                            const Chip(label: Text('Accepted'), backgroundColor: Colors.greenAccent),
                          if (invitation.status == invitation_models.InvitationStatus.declined)
                            const Chip(label: Text('Declined'), backgroundColor: Colors.redAccent),
                        ],
                      ),
                      Text('Invited ${_formatDate(invitation.createdAt)}'),
                      if (invitation.expiresAt.isAfter(DateTime.now()))
                        Text('Expires ${_formatDate(invitation.expiresAt)}',
                            style: const TextStyle(color: Colors.redAccent))
                      else
                        const Text('Expired', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                  trailing: canManage && invitation.status == invitation_models.InvitationStatus.pending
                      ? PopupMenuButton<String>(
                          onSelected: (value) => _handleInvitationAction(value, invitation, family),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'resend',
                              child: Row(
                                children: [
                                  Icon(Icons.send),
                                  SizedBox(width: 8),
                                  Text('Resend Invitation'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'cancel',
                              child: Row(
                                children: [
                                  Icon(Icons.cancel_outlined),
                                  SizedBox(width: 8),
                                  Text('Cancel Invitation'),
                                ],
                              ),
                            ),
                          ],
                        )
                      : null,
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSettingsTab(family_models.Family family) {
    final currentFamilyData = family;
    final canModify = _canModifySettings(currentFamilyData);

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: ListView(
        padding: const EdgeInsets.all(AppTheme.paddingRegular),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Family Name'),
              subtitle: Text(currentFamilyData.name),
              trailing: canModify ? const Icon(Icons.chevron_right) : null,
              onTap: canModify ? () => _editFamilyName(currentFamilyData) : null,
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.copy_all_outlined),
              title: const Text('Family ID'),
              subtitle: Text(currentFamilyData.id),
              trailing: const Icon(Icons.copy),
              onTap: () => _copyFamilyId(currentFamilyData),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('Family Description'),
              subtitle: Text(currentFamilyData.description ?? 'No description'),
              trailing: canModify ? const Icon(Icons.chevron_right) : null,
              onTap: canModify ? () => _editFamilyDescription(currentFamilyData) : null,
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.public),
            title: const Text('Public Family'),
            subtitle: const Text('Allow non-members to view family stats (anonymized)'),
            value: currentFamilyData.isPublic,
            onChanged: canModify ? (value) => _togglePublicFamily(currentFamilyData, value) : null,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.share_outlined),
            title: const Text('Share Classifications Publicly'),
            subtitle: const Text('Allow family classifications to appear in global anonymous feed'),
            value: currentFamilyData.settings.shareClassificationsPublicly,
            onChanged: canModify ? (value) => _toggleShareClassifications(currentFamilyData, value) : null,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.visibility_outlined),
            title: const Text('Show Member Activity in Feed'),
            subtitle: const Text('Display individual member classifications in the family feed'),
            value: currentFamilyData.settings.showMemberActivityInFeed,
            onChanged: canModify ? (value) => _toggleShowMemberActivity(currentFamilyData, value) : null,
          ),
          ListTile(
            leading: const Icon(Icons.leaderboard_outlined),
            title: const Text('Family Leaderboard Visibility'),
            subtitle: Text(currentFamilyData.settings.leaderboardVisibility.toString().split('.').last),
            trailing: canModify ? const Icon(Icons.chevron_right) : null,
            onTap: canModify ? () => _showLeaderboardVisibilityDialog(currentFamilyData) : null,
          ),
          if (_isAdmin(currentFamilyData))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.paddingLarge),
              child: TextButton.icon(
                icon: const Icon(Icons.delete_forever, color: Colors.red),
                label: const Text('Delete Family', style: TextStyle(color: Colors.red)),
                onPressed: () => _deleteFamily(currentFamilyData),
              ),
            ),
        ],
      ),
    );
  }

  void _handleMemberAction(String action, user_models.UserProfile member, family_models.Family family) {
    if (action == 'change_role') {
      _showChangeRoleDialog(family, member);
    } else if (action == 'remove') {
      _showRemoveMemberDialog(family, member);
    }
  }

  void _handleInvitationAction(
      String action, invitation_models.FamilyInvitation invitation, family_models.Family family) {
    if (action == 'resend') {
      _resendInvitation(invitation, family);
    } else if (action == 'cancel') {
      _cancelInvitation(invitation, family);
    }
  }

  bool _canModifyMember(family_models.Family family, String memberId) {
    final currentUserMemberData = family.getMember(_currentUser?.id ?? '');
    return currentUserMemberData?.role == family_models.UserRole.admin ||
        currentUserMemberData?.role == family_models.UserRole.moderator;
  }

  bool _canChangeRole(family_models.Family family, String memberId) {
    final currentUserMemberData = family.getMember(_currentUser?.id ?? '');
    return currentUserMemberData?.role == family_models.UserRole.admin;
  }

  bool _canRemoveMember(family_models.Family family, String memberId) {
    final currentUserMemberData = family.getMember(_currentUser?.id ?? '');
    if (currentUserMemberData?.userId == memberId) return false;
    return currentUserMemberData?.role == family_models.UserRole.admin ||
        (currentUserMemberData?.role == family_models.UserRole.moderator &&
            family.getMember(memberId)?.role == family_models.UserRole.member);
  }

  bool _canManageInvitations(family_models.Family family) {
    final currentUserMemberData = family.getMember(_currentUser?.id ?? '');
    return currentUserMemberData?.role == family_models.UserRole.admin ||
        currentUserMemberData?.role == family_models.UserRole.moderator;
  }

  bool _canModifySettings(family_models.Family family) {
    final currentUserMemberData = family.getMember(_currentUser?.id ?? '');
    return currentUserMemberData?.role == family_models.UserRole.admin;
  }

  bool _isAdmin(family_models.Family family) {
    final currentUserMemberData = family.getMember(_currentUser?.id ?? '');
    return currentUserMemberData?.role == family_models.UserRole.admin;
  }

  Future<void> _showInviteDialog(family_models.Family family) async {
    final emailController = TextEditingController();
    var roleToAssign = family_models.UserRole.member;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Invite New Member'),
          content: StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email Address'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: AppTheme.paddingRegular),
                DropdownButtonFormField<family_models.UserRole>(
                  decoration: const InputDecoration(labelText: 'Assign Role'),
                  value: roleToAssign,
                  items: family_models.UserRole.values.map((family_models.UserRole role) {
                    return DropdownMenuItem<family_models.UserRole>(
                      value: role,
                      child: Text(_getRoleText(role)),
                    );
                  }).toList(),
                  onChanged: (family_models.UserRole? newValue) {
                    if (newValue != null) {
                      setState(() {
                        roleToAssign = newValue;
                      });
                    }
                  },
                ),
              ],
            );
          }),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Send Invite'),
              onPressed: () async {
                if (emailController.text.isNotEmpty) {
                  Navigator.of(context).pop();
                  await _sendInvitation(family, emailController.text, roleToAssign);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendInvitation(family_models.Family family, String email, family_models.UserRole role) async {
    try {
      final inviteRole = _convertToUserRole(role);
      await _familyService.createInvitation(family.id, _currentUser?.id ?? '', email, inviteRole);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invitation sent!')));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to send invitation: ${e.toString()}')));
    }
  }

  Future<void> _showChangeRoleDialog(family_models.Family family, user_models.UserProfile member) async {
    var selectedRole = family.getMember(member.id)?.role;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Change Role for ${member.displayName}'),
          content: DropdownButton<family_models.UserRole>(
            value: selectedRole,
            items: family_models.UserRole.values.map((family_models.UserRole role) {
              return DropdownMenuItem<family_models.UserRole>(
                  value: role,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_getRoleText(role)),
                      Text(_getRoleDescription(role), style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ));
            }).toList(),
            onChanged: (family_models.UserRole? newValue) {
              selectedRole = newValue;
            },
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Confirm Change'),
              onPressed: () async {
                if (selectedRole != null) {
                  Navigator.of(context).pop();
                  await _changeRole(family, member.id, selectedRole!);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showRemoveMemberDialog(family_models.Family family, user_models.UserProfile member) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Remove ${member.displayName}?'),
          content: Text(
              'Are you sure you want to remove ${member.displayName} from the family? This action cannot be undone.'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Remove Member', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                Navigator.of(context).pop();
                await _removeMember(family, member.id);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _changeRole(family_models.Family family, String userId, family_models.UserRole newFamilyRole) async {
    try {
      user_profile_models.UserRole newProfileRole;
      switch (newFamilyRole) {
        case family_models.UserRole.admin:
          newProfileRole = user_profile_models.UserRole.admin;
          break;
        case family_models.UserRole.member:
          newProfileRole = user_profile_models.UserRole.member;
          break;
        default:
          final newFamilyRoleName = newFamilyRole.toString().split('.').last;
          try {
            newProfileRole = user_profile_models.UserRole.values
                .firstWhere((profileRole) => profileRole.toString().split('.').last == newFamilyRoleName);
          } catch (e) {
            WasteAppLogger.warning(
                'Warning: Role "$newFamilyRoleName" from family_models.UserRole not found in user_profile_models.UserRole. Defaulting to member.');
            newProfileRole = user_profile_models.UserRole.member;
          }
      }

      await _familyService.updateMemberRole(family.id, userId, newProfileRole);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Member role updated.')));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update role: ${e.toString()}')));
    }
  }

  Future<void> _removeMember(family_models.Family family, String userId) async {
    try {
      await _familyService.removeMember(family.id, userId);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Member removed.')));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to remove member: ${e.toString()}')));
    }
  }

  Future<void> _resendInvitation(invitation_models.FamilyInvitation invitation, family_models.Family family) async {
    try {
      await _familyService.resendInvitation(invitation.id);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invitation resent.')));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to resend invitation: ${e.toString()}')));
    }
  }

  Future<void> _cancelInvitation(invitation_models.FamilyInvitation invitation, family_models.Family family) async {
    try {
      await _familyService.cancelInvitation(invitation.id);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invitation cancelled.')));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to cancel invitation: ${e.toString()}')));
    }
  }

  Future<void> _editFamilyName(family_models.Family family) async {
    final nameController = TextEditingController(text: family.name);
    await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Edit Family Name'),
            content:
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'New Family Name')),
            actions: [
              TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(context).pop()),
              ElevatedButton(
                  child: const Text('Save'),
                  onPressed: () async {
                    if (nameController.text.isNotEmpty) {
                      final navigator = Navigator.of(context);
                      final messenger = ScaffoldMessenger.of(context);
                      navigator.pop();
                      final updatedFamily = family.copyWith(name: nameController.text);
                      await _familyService.updateFamily(updatedFamily);
                      if (mounted) messenger.showSnackBar(const SnackBar(content: Text('Family name updated.')));
                    }
                  }),
            ],
          );
        });
  }

  Future<void> _editFamilyDescription(family_models.Family family) async {
    final descriptionController = TextEditingController(text: family.description);
    await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Edit Family Description'),
            content: TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'New Family Description'),
              maxLines: 3,
            ),
            actions: [
              TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(context).pop()),
              ElevatedButton(
                  child: const Text('Save'),
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);
                    navigator.pop();
                    final updatedFamily = family.copyWith(description: descriptionController.text);
                    await _familyService.updateFamily(updatedFamily);
                    if (mounted) messenger.showSnackBar(const SnackBar(content: Text('Family description updated.')));
                  }),
            ],
          );
        });
  }

  void _copyFamilyId(family_models.Family family) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Family ID copied: ${family.id}')));
  }

  Future<void> _togglePublicFamily(family_models.Family family, bool value) async {
    try {
      final updatedFamily = family.copyWith(isPublic: value);
      await _familyService.updateFamily(updatedFamily);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Public setting updated to $value.')));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to update public setting: ${e.toString()}')));
    }
  }

  Future<void> _toggleShareClassifications(family_models.Family family, bool value) async {
    try {
      final updatedSettings = family.settings.copyWith(shareClassificationsPublicly: value);
      final updatedFamily = family.copyWith(settings: updatedSettings);
      await _familyService.updateFamily(updatedFamily);
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Share classifications setting updated to $value.')));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to update share setting: ${e.toString()}')));
    }
  }

  Future<void> _toggleShowMemberActivity(family_models.Family family, bool value) async {
    try {
      final updatedSettings = family.settings.copyWith(showMemberActivityInFeed: value);
      final updatedFamily = family.copyWith(settings: updatedSettings);
      await _familyService.updateFamily(updatedFamily);
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Show member activity setting updated to $value.')));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to update member activity setting: ${e.toString()}')));
    }
  }

  Future<void> _showLeaderboardVisibilityDialog(family_models.Family family) async {
    family_models.FamilyLeaderboardVisibility? selectedVisibility = family.settings.leaderboardVisibility;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Set Leaderboard Visibility'),
          content: DropdownButton<family_models.FamilyLeaderboardVisibility>(
            value: selectedVisibility,
            items: family_models.FamilyLeaderboardVisibility.values
                .map((family_models.FamilyLeaderboardVisibility visibility) {
              return DropdownMenuItem<family_models.FamilyLeaderboardVisibility>(
                value: visibility,
                child: Text(visibility.toString().split('.').last),
              );
            }).toList(),
            onChanged: (family_models.FamilyLeaderboardVisibility? newValue) {
              selectedVisibility = newValue;
            },
          ),
          actions: [
            TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(context).pop()),
            ElevatedButton(
              child: const Text('Save'),
              onPressed: () async {
                if (selectedVisibility != null) {
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  navigator.pop();
                  final updatedSettings = family.settings.copyWith(leaderboardVisibility: selectedVisibility);
                  final updatedFamily = family.copyWith(settings: updatedSettings);
                  await _familyService.updateFamily(updatedFamily);
                  if (mounted) messenger.showSnackBar(const SnackBar(content: Text('Leaderboard visibility updated.')));
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteFamily(family_models.Family family) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Family?'),
        content: Text(
            'Are you sure you want to delete the family "${family.name}"? This action is permanent and cannot be undone. All associated data will be lost.'),
        actions: [
          TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(context).pop(false)),
          ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('DELETE FAMILY', style: TextStyle(color: Colors.white)),
              onPressed: () => Navigator.of(context).pop(true)),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _familyService.deleteFamily(family.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Family deleted successfully.')));
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Failed to delete family: ${e.toString()}')));
      }
    }
  }

  Color _getRoleColor(family_models.UserRole role) {
    switch (role) {
      case family_models.UserRole.admin:
        return Colors.redAccent;
      case family_models.UserRole.moderator:
        return Colors.blueAccent;
      case family_models.UserRole.member:
        return Colors.green;
    }
  }

  String _getRoleText(family_models.UserRole role) {
    switch (role) {
      case family_models.UserRole.admin:
        return 'Admin';
      case family_models.UserRole.moderator:
        return 'Moderator';
      case family_models.UserRole.member:
        return 'Member';
    }
  }

  String _getRoleDescription(family_models.UserRole role) {
    switch (role) {
      case family_models.UserRole.admin:
        return 'Manages family, members, and settings.';
      case family_models.UserRole.moderator:
        return 'Manages members and invitations.';
      case family_models.UserRole.member:
        return 'Participates in family activities.';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Convert user_models.UserRole to family_models.UserRole
  family_models.UserRole _convertUserRole(user_models.UserRole role) {
    switch (role) {
      case user_models.UserRole.admin:
        return family_models.UserRole.admin;
      case user_models.UserRole.member:
        return family_models.UserRole.member;
      case user_models.UserRole.child:
      case user_models.UserRole.guest:
        return family_models.UserRole.member; // Default to member for child/guest
    }
  }

  /// Convert family_models.UserRole to user_models.UserRole
  user_models.UserRole _convertToUserRole(family_models.UserRole role) {
    switch (role) {
      case family_models.UserRole.admin:
        return user_models.UserRole.admin;
      case family_models.UserRole.moderator:
      case family_models.UserRole.member:
        return user_models.UserRole.member;
    }
  }
}
