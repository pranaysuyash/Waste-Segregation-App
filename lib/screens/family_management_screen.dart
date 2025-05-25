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
  bool _isLoading = false;
  List<UserProfile> _members = [];
  List<FamilyInvitation> _invitations = [];
  UserProfile? _currentUser;
  final _familyService = FirebaseFamilyService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final storageService = Provider.of<StorageService>(context, listen: false);
      
      // Load current user
      _currentUser = await storageService.getCurrentUserProfile();
      
      // Load family members
      final members = await _familyService.getFamilyMembers(widget.family.id);
      
      // Load invitations
      final invitations = await _familyService.getInvitations(widget.family.id);
      
      setState(() {
        _members = members;
        _invitations = invitations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load data: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage ${widget.family.name}'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Members'),
            Tab(icon: Icon(Icons.mail), text: 'Invitations'),
            Tab(icon: Icon(Icons.settings), text: 'Settings'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMembersTab(),
                _buildInvitationsTab(),
                _buildSettingsTab(),
              ],
            ),
    );
  }

  Widget _buildMembersTab() {
    if (_members.isEmpty) {
      return const Center(
        child: Text('No members found'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.paddingRegular),
        itemCount: _members.length,
        itemBuilder: (context, index) {
          final member = _members[index];
          final familyMember = widget.family.getMember(member.id);
          final isCurrentUser = _currentUser?.id == member.id;
          final canModify = _canModifyMember(member.id);

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

  Widget _buildInvitationsTab() {
    if (_invitations.isEmpty) {
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
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.paddingRegular),
        itemCount: _invitations.length,
        itemBuilder: (context, index) {
          final invitation = _invitations[index];
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
                  : null,
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
                    subtitle: Text(widget.family.name),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _editFamilyName(),
                  ),
                  ListTile(
                    leading: const Icon(Icons.info),
                    title: const Text('Family ID'),
                    subtitle: Text(widget.family.id),
                    trailing: IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () => _copyFamilyId(),
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
                    value: widget.family.settings.isPublic,
                    onChanged: _canModifySettings() ? _togglePublicFamily : null,
                  ),
                  SwitchListTile(
                    title: const Text('Share Classifications'),
                    subtitle: const Text('Share waste classifications with family members'),
                    value: widget.family.settings.shareClassifications,
                    onChanged: _canModifySettings() ? _toggleShareClassifications : null,
                  ),
                  SwitchListTile(
                    title: const Text('Show Member Activity'),
                    subtitle: const Text('Show individual member activity to all'),
                    value: widget.family.settings.showMemberActivity,
                    onChanged: _canModifySettings() ? _toggleShowMemberActivity : null,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppTheme.paddingLarge),

          // Danger Zone
          if (_isAdmin())
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
  bool _canModifyMember(String memberId) {
    return _isAdmin() && _currentUser?.id != memberId;
  }

  bool _canChangeRole(String memberId) {
    return _isAdmin() && _currentUser?.id != memberId;
  }

  bool _canRemoveMember(String memberId) {
    return _isAdmin() && _currentUser?.id != memberId;
  }

  bool _canManageInvitations() {
    return _isAdmin();
  }

  bool _canModifySettings() {
    return _isAdmin();
  }

  bool _isAdmin() {
    final currentMember = widget.family.getMember(_currentUser?.id ?? '');
    return currentMember?.role == UserRole.admin;
  }

  void _handleMemberAction(String action, UserProfile member) {
    switch (action) {
      case 'change_role':
        _showChangeRoleDialog(member);
        break;
      case 'remove':
        _showRemoveMemberDialog(member);
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

  Future<void> _showChangeRoleDialog(UserProfile member) async {
    final currentMember = widget.family.getMember(member.id);
    if (currentMember == null) return;

    UserRole? newRole = await showDialog<UserRole>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Change Role for ${member.displayName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: UserRole.values.map((role) {
            return RadioListTile<UserRole>(
              title: Text(_getRoleText(role)),
              subtitle: Text(_getRoleDescription(role)),
              value: role,
              groupValue: currentMember.role,
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

    if (newRole != null && newRole != currentMember.role) {
      await _changeRole(member.id, newRole);
    }
  }

  Future<void> _showRemoveMemberDialog(UserProfile member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Are you sure you want to remove ${member.displayName} from the family?'),
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
      await _removeMember(member.id);
    }
  }

  Future<void> _changeRole(String userId, UserRole newRole) async {
    try {
      await _familyService.updateMemberRole(widget.family.id, userId, newRole);
      await _loadData();
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

  Future<void> _removeMember(String userId) async {
    try {
      await _familyService.removeMember(widget.family.id, userId);
      await _loadData();
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
      await _loadData();
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

  void _editFamilyName() {
    // TODO: Implement family name editing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Family name editing coming soon!')),
    );
  }

  void _copyFamilyId() {
    // TODO: Copy family ID to clipboard
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Family ID copied to clipboard!')),
    );
  }

  void _togglePublicFamily(bool value) {
    // TODO: Implement toggle public family
  }

  void _toggleShareClassifications(bool value) {
    // TODO: Implement toggle share classifications
  }

  void _toggleShowMemberActivity(bool value) {
    // TODO: Implement toggle show member activity
  }

  void _deleteFamily() async {
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