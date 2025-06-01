import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/enhanced_family.dart';
import '../models/user_profile.dart';
import '../models/family_invitation.dart';
import '../services/firebase_family_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

class FamilyManagementScreen extends StatefulWidget {
  final Family family;

  const FamilyManagementScreen({
    super.key,
    required this.family,
  });

  @override
  State<FamilyManagementScreen> createState() => _FamilyManagementScreenState();
}

class _FamilyManagementScreenState extends State<FamilyManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  // bool _isLoading = false; // Replaced by StreamBuilder states
  List<UserProfile> _members = []; // Will be populated by a StreamBuilder
  List<FamilyInvitation> _invitations = []; // Will be populated by a StreamBuilder
  UserProfile? _currentUser;
  final _familyService = FirebaseFamilyService();

  // To hold the current family data, updated by stream
  late Family _currentFamily;

  @override
  void initState() {
    super.initState();
    _currentFamily = widget.family; // Initialize with passed data
    _tabController = TabController(length: 3, vsync: this);
    _loadInitialUserData(); // For _currentUser
    // _loadData(); // Will be replaced by StreamBuilders
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialUserData() async {
    // Only load current user profile initially, other data will be streamed
    try {
      final storageService = Provider.of<StorageService>(context, listen: false);
      _currentUser = await storageService.getCurrentUserProfile();
      if (mounted) {
        setState(() {}); // Update UI if needed after getting current user
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load user data: ${e.toString()}')),
        );
      }
    }
  }

  // Placeholder for refreshing data, might be used by RefreshIndicator
  Future<void> _handleRefresh() async {
    await _loadInitialUserData();
    // Streams will auto-refresh, but if members/invitations also need manual refresh trigger:
    // This might involve re-subscribing or using a StreamController if not directly using Firestore streams.
    // For now, Firestore streams handle their own updates.
    setState(() {}); // Cause a rebuild to pick up any changes from _loadInitialUserData
  }


  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Family?>(
      stream: _familyService.getFamilyStream(widget.family.id),
      initialData: _currentFamily, // Use initial family data
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
          _currentFamily = snapshot.data!; // Update _currentFamily with the latest from stream
        }
        // If snapshot.data is null (e.g., family deleted), _currentFamily retains last known good state or initial.
        // Consider how to handle if family is deleted while on this screen. For now, assumes it exists.

        return Scaffold(
          appBar: AppBar(
            title: Text('Manage ${_currentFamily.name}'), // Use _currentFamily
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
              _buildMembersTab(_currentFamily), // Pass _currentFamily
              _buildInvitationsTab(_currentFamily), // Pass _currentFamily
              _buildSettingsTab(_currentFamily), // Pass _currentFamily
            ],
          ),
        );
      },
    );
  }

  Widget _buildMembersTab(Family family) { // Now takes Family
    return StreamBuilder<List<UserProfile>>(
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
          onRefresh: _handleRefresh, // Manual refresh can still be useful
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
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                backgroundImage: member.photoUrl != null
                    ? NetworkImage(member.photoUrl!)
                    : null,
                child: member.photoUrl == null
                    ? Text(member.displayName?.substring(0, 1) ?? 'U')
                    : null,
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      member.displayName ?? 'Unknown User',
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
                        color: Colors.blue.withOpacity(0.1),
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
                  Text(member.email ?? 'No email'),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getRoleColor(familyMember?.role ?? UserRole.member),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getRoleText(familyMember?.role ?? UserRole.member),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Joined ${_formatDate(familyMember?.joinedAt ?? DateTime.now())}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                  if (familyMember != null)
                    Text(
                      '${familyMember.individualStats.totalPoints} points • '
                      '${familyMember.individualStats.totalClassifications} classifications',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                ],
              ),
              trailing: canModify
                  ? PopupMenuButton<String>(
                      onSelected: (value) => _handleMemberAction(value, member),
                      itemBuilder: (context) => [
                        if (!isCurrentUser && _canChangeRole(member.id))
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
                        if (!isCurrentUser && _canRemoveMember(member.id))
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
  }

  Widget _buildInvitationsTab(Family family) { // Now takes Family
    return StreamBuilder<List<FamilyInvitation>>(
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
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(AppTheme.paddingLarge),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.mail_outline,
                    size: 64,
                    color: AppTheme.textSecondaryColor,
                  ),
                  SizedBox(height: AppTheme.paddingRegular),
                  Text(
                    'No pending invitations',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeMedium,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _handleRefresh, // Manual refresh
          child: ListView.builder(
            padding: const EdgeInsets.all(AppTheme.paddingRegular),
            itemCount: invitations.length,
            itemBuilder: (context, index) {
              final invitation = invitations[index];
              final isExpired = invitation.expiresAt.isBefore(DateTime.now());

              return Card(
            margin: const EdgeInsets.only(bottom: AppTheme.paddingRegular),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isExpired
                    ? Colors.red.withOpacity(0.1)
                    : AppTheme.primaryColor.withOpacity(0.1),
                child: Icon(
                  isExpired ? Icons.error : Icons.mail,
                  color: isExpired ? Colors.red : AppTheme.primaryColor,
                ),
              ),
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
                          color: _getRoleColor(invitation.roleToAssign),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getRoleText(invitation.roleToAssign),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isExpired ? Colors.red : Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isExpired ? 'Expired' : 'Pending',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Invited ${_formatDate(invitation.createdAt)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  Text(
                    'Expires ${_formatDate(invitation.expiresAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isExpired ? Colors.red : AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
              trailing: _canManageInvitations()
                  ? PopupMenuButton<String>(
                      onSelected: (value) => _handleInvitationAction(value, invitation),
                      itemBuilder: (context) => [
                        if (!isExpired && invitation.status == InvitationStatus.pending)
                        if (!isExpired && invitation.status == InvitationStatus.pending && _canManageInvitations(family))
                          const PopupMenuItem(
                            value: 'resend',
                            child: Row(
                              children: [
                                Icon(Icons.send),
                                SizedBox(width: 8),
                                Text('Resend'),
                              ],
                            ),
                            ),
                        if (_canManageInvitations(family)) // Cancel can always be shown if manager
                          const PopupMenuItem(
                            value: 'cancel',
                            child: Row(
                              children: [
                                Icon(Icons.cancel, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Cancel', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                      ],
                    )
                  : null, // No actions if not manager
            ),
          );
        },
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.paddingRegular),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Family Information
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.paddingRegular),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Family Information',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeMedium,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppTheme.paddingRegular),
                  ListTile(
                    leading: const Icon(Icons.edit),
                    title: const Text('Family Name'),
                    subtitle: Text(family.name), // Use family from StreamBuilder
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _editFamilyName(family), // Pass family
                  ),
                  ListTile(
                    leading: const Icon(Icons.info),
                    title: const Text('Family ID'),
                    subtitle: Text(family.id), // Use family from StreamBuilder
                    trailing: IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () => _copyFamilyId(family), // Pass family
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppTheme.paddingLarge),

          // Privacy Settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.paddingRegular),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Privacy Settings',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeMedium,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppTheme.paddingRegular),
                  SwitchListTile(
                    title: const Text('Public Family'),
                    subtitle: const Text('Allow others to find and join your family'),
                    value: family.settings.isPublic, // Use family from StreamBuilder
                    onChanged: _canModifySettings(family) ? (value) => _togglePublicFamily(family, value) : null,
                  ),
                  SwitchListTile(
                    title: const Text('Share Classifications'),
                    subtitle: const Text('Share waste classifications with family members'),
                    value: family.settings.shareClassifications, // Use family from StreamBuilder
                    onChanged: _canModifySettings(family) ? (value) => _toggleShareClassifications(family, value) : null,
                  ),
                  SwitchListTile(
                    title: const Text('Show Member Activity'),
                    subtitle: const Text('Show individual member activity to all'),
                    value: family.settings.showMemberActivity, // Use family from StreamBuilder
                    onChanged: _canModifySettings(family) ? (value) => _toggleShowMemberActivity(family, value) : null,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppTheme.paddingLarge),

          // Danger Zone
          if (_isAdmin(family)) // Pass family
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.paddingRegular),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Danger Zone',
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeMedium,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: AppTheme.paddingRegular),
                    ListTile(
                      leading: const Icon(Icons.delete_forever, color: Colors.red),
                      title: const Text(
                        'Delete Family',
                        style: TextStyle(color: Colors.red),
                      ),
                      subtitle: const Text(
                        'Permanently delete this family and all associated data',
                      ),
                      onTap: () => _deleteFamily(),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Member management methods
  bool _canModifyMember(Family family, String memberId) { // Pass family
    return _isAdmin(family) && _currentUser?.id != memberId;
  }

  bool _canChangeRole(Family family, String memberId) { // Pass family
    return _isAdmin(family) && _currentUser?.id != memberId;
  }

  bool _canRemoveMember(Family family, String memberId) { // Pass family
    return _isAdmin(family) && _currentUser?.id != memberId;
  }

  bool _canManageInvitations(Family family) { // Pass family
    return _isAdmin(family);
  }

  bool _canModifySettings(Family family) { // Pass family
    return _isAdmin(family);
  }

  bool _isAdmin(Family family) { // Pass family
    final currentMember = family.getMember(_currentUser?.id ?? '');
    return currentMember?.role == UserRole.admin;
  }

  void _handleMemberAction(Family family, String action, UserProfile member) { // Pass family
    switch (action) {
      case 'change_role':
        _showChangeRoleDialog(family, member); // Pass family
        break;
      case 'remove':
        _showRemoveMemberDialog(family, member); // Pass family
        break;
    }
  }

  void _handleInvitationAction(String action, FamilyInvitation invitation) {
    switch (action) {
      case 'resend':
        _resendInvitation(invitation);
        break;
      case 'cancel':
        _cancelInvitation(invitation);
        break;
    }
  }

  Future<void> _showChangeRoleDialog(Family family, UserProfile member) async { // Pass family
    final currentFamilyMember = family.getMember(member.id); // Use passed family
    if (currentFamilyMember == null) return;

    UserRole? newRole = await showDialog<UserRole>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Change Role for ${member.displayName ?? 'Unknown'}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: UserRole.values.map((role) {
            return RadioListTile<UserRole>(
              title: Text(_getRoleText(role)),
              subtitle: Text(_getRoleDescription(role)),
              value: role,
              groupValue: currentFamilyMember.role, // Use currentFamilyMember
              onChanged: (value) => Navigator.of(context).pop(value),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (newRole != null && newRole != currentFamilyMember.role) {
      await _changeRole(family, member.id, newRole); // Pass family
    }
  }

  Future<void> _showRemoveMemberDialog(Family family, UserProfile member) async { // Pass family
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Are you sure you want to remove ${member.displayName ?? 'this member'} from the family?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _removeMember(family, member.id); // Pass family
    }
  }

  Future<void> _changeRole(Family family, String userId, UserRole newRole) async {
    try {
      await _familyService.updateMemberRole(family.id, userId, newRole);
      // Stream for Family object will trigger rebuild of members list if roles are part of FamilyMember in Family.members
      // Stream for UserProfile list in _buildMembersTab will also update.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Member role updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update role: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _removeMember(Family family, String userId) async {
    try {
      await _familyService.removeMember(family.id, userId);
      // Family stream will update the family object, which should rebuild members list.
      // UserProfile stream will update based on the change in family.members.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Member removed successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove member: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _resendInvitation(FamilyInvitation invitation) async {
    try {
      await _familyService.resendInvitation(invitation.id);
      // Invitations stream will update the list
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation resent successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to resend invitation: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _cancelInvitation(FamilyInvitation invitation) async {
    try {
      await _familyService.cancelInvitation(invitation.id);
      // Invitations stream will update the list
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation cancelled successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel invitation: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _editFamilyName(Family family) async { // Pass family
    final newNameController = TextEditingController(text: family.name);
    final confirmed = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Family Name'),
        content: TextField(
          controller: newNameController,
          decoration: const InputDecoration(hintText: 'Enter new family name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(newNameController.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirmed != null && confirmed.isNotEmpty && confirmed != family.name) {
      try {
        final updatedFamily = family.copyWith(name: confirmed);
        await _familyService.updateFamily(updatedFamily);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Family name updated!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update family name: $e')),
          );
        }
      }
    }
  }

  void _copyFamilyId(Family family) { // Pass family
    Clipboard.setData(ClipboardData(text: family.id));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Family ID copied to clipboard!')),
    );
  }

  Future<void> _togglePublicFamily(Family family, bool value) async { // Pass family
    final newSettings = family.settings.copyWith(isPublic: value);
    final updatedFamily = family.copyWith(settings: newSettings);
    try {
      await _familyService.updateFamily(updatedFamily);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Public family setting updated to $value')),
        );
      }
    } catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update setting: $e')),
        );
      }
    }
  }

  Future<void> _toggleShareClassifications(Family family, bool value) async { // Pass family
    final newSettings = family.settings.copyWith(shareClassifications: value);
    final updatedFamily = family.copyWith(settings: newSettings);
     try {
      await _familyService.updateFamily(updatedFamily);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Share classifications setting updated to $value')),
        );
      }
    } catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update setting: $e')),
        );
      }
    }
  }

  Future<void> _toggleShowMemberActivity(Family family, bool value) async { // Pass family
    final newSettings = family.settings.copyWith(showMemberActivity: value);
    final updatedFamily = family.copyWith(settings: newSettings);
    try {
      await _familyService.updateFamily(updatedFamily);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Show member activity setting updated to $value')),
        );
      }
    } catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update setting: $e')),
        );
      }
    }
  }

  void _deleteFamily(Family family) async { // Pass family
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Family'),
        content: const Text(
          'Are you sure you want to delete this family? This action cannot be undone and all family data will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _familyService.deleteFamily(widget.family.id);
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Family deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete family: ${e.toString()}')),
          );
        }
      }
    }
  }

  // Helper methods
  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Colors.red;
      case UserRole.member:
        return AppTheme.primaryColor;
      case UserRole.child:
        return Colors.orange;
      case UserRole.guest:
        return Colors.grey;
    }
  }

  String _getRoleText(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.member:
        return 'Member';
      case UserRole.child:
        return 'Child';
      case UserRole.guest:
        return 'Guest';
    }
  }

  String _getRoleDescription(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Can manage family settings and members';
      case UserRole.member:
        return 'Can participate in family activities';
      case UserRole.child:
        return 'Limited access with parental controls';
      case UserRole.guest:
        return 'Limited temporary access';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
} 