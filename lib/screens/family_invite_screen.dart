import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/enhanced_family.dart' hide UserRole;
// import '../models/family_invitation.dart'; // Unused import
import '../models/user_profile.dart' show UserRole;
import '../services/firebase_family_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

class FamilyInviteScreen extends StatefulWidget {

  const FamilyInviteScreen({
    super.key,
    required this.family,
  });
  final Family family;

  @override
  State<FamilyInviteScreen> createState() => _FamilyInviteScreenState();
}

class _FamilyInviteScreenState extends State<FamilyInviteScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _familyService = FirebaseFamilyService();
  
  UserRole _selectedRole = UserRole.member;
  bool _isLoading = false;
  String? _inviteLink;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _generateInviteLink();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _generateInviteLink() {
    // Generate a shareable invite link
    _inviteLink = 'https://wasteapp.com/invite/${widget.family.id}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invite Family Members'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.email), text: 'Email Invite'),
            Tab(icon: Icon(Icons.qr_code), text: 'Share Link'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEmailInviteTab(),
          _buildShareLinkTab(),
        ],
      ),
    );
  }

  Widget _buildEmailInviteTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.paddingRegular),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Family info card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.paddingRegular),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
                      ),
                      child: const Icon(
                        Icons.family_restroom,
                        color: AppTheme.primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppTheme.paddingRegular),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Inviting to: ${widget.family.name}',
                            style: const TextStyle(
                              fontSize: AppTheme.fontSizeMedium,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${widget.family.members.length} current members',
                            style: const TextStyle(
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppTheme.paddingLarge),

            // Email input
            const Text(
              'Email Address',
              style: TextStyle(
                fontSize: AppTheme.fontSizeMedium,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.paddingSmall),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'Enter email address',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an email address';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),

            const SizedBox(height: AppTheme.paddingLarge),

            // Role selection
            const Text(
              'Member Role',
              style: TextStyle(
                fontSize: AppTheme.fontSizeMedium,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.paddingSmall),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.paddingRegular),
                child: Column(
                  children: UserRole.values.map((role) {
                    return RadioListTile<UserRole>(
                      title: Text(_getRoleText(role)),
                      subtitle: Text(_getRoleDescription(role)),
                      value: role,
                      groupValue: _selectedRole,
                      onChanged: (value) {
                        setState(() {
                          _selectedRole = value!;
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: AppTheme.paddingLarge),

            // Personal message (optional)
            const Text(
              'Personal Message (Optional)',
              style: TextStyle(
                fontSize: AppTheme.fontSizeMedium,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.paddingSmall),
            TextFormField(
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Add a personal message to your invitation...',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: AppTheme.paddingLarge),

            // Send button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _sendEmailInvitation,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: Text(_isLoading ? 'Sending...' : 'Send Invitation'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(AppTheme.paddingRegular),
                ),
              ),
            ),

            const SizedBox(height: AppTheme.paddingRegular),

            // Info text
            Container(
              padding: const EdgeInsets.all(AppTheme.paddingRegular),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: Colors.blue),
                  const SizedBox(width: AppTheme.paddingSmall),
                  Expanded(
                    child: Text(
                      'The invitation will be valid for 7 days. The recipient will need to create an account or sign in to join your family.',
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeSmall,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareLinkTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.paddingRegular),
      child: Column(
        children: [
          // QR Code
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.paddingLarge),
              child: Column(
                children: [
                  const Text(
                    'QR Code',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeLarge,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppTheme.paddingRegular),
                  Container(
                    padding: const EdgeInsets.all(AppTheme.paddingRegular),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
                    ),
                    child: QrImageView(
                      data: _inviteLink!,
                      size: 200.0,
                      gapless: false,
                    ),
                  ),
                  const SizedBox(height: AppTheme.paddingRegular),
                  const Text(
                    'Scan this QR code to join the family',
                    style: TextStyle(
                      color: AppTheme.textSecondaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppTheme.paddingLarge),

          // Share link
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.paddingRegular),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Invite Link',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeMedium,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppTheme.paddingRegular),
                  Container(
                    padding: const EdgeInsets.all(AppTheme.paddingRegular),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _inviteLink!,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: AppTheme.fontSizeSmall,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _copyInviteLink(),
                          icon: const Icon(Icons.copy),
                          tooltip: 'Copy link',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppTheme.paddingLarge),

          // Share buttons
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.paddingRegular),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Share Via',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeMedium,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppTheme.paddingRegular),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildShareButton(
                        icon: Icons.message,
                        label: 'Messages',
                        onTap: () => _shareViaMessages(),
                      ),
                      _buildShareButton(
                        icon: Icons.email,
                        label: 'Email',
                        onTap: () => _shareViaEmail(),
                      ),
                      _buildShareButton(
                        icon: Icons.share,
                        label: 'More',
                        onTap: () => _shareViaOther(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppTheme.paddingLarge),

          // Family info
          Container(
            padding: const EdgeInsets.all(AppTheme.paddingRegular),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
            ),
            child: Column(
              children: [
                Text(
                  widget.family.name,
                  style: const TextStyle(
                    fontSize: AppTheme.fontSizeLarge,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: AppTheme.paddingSmall),
                Text(
                  '${widget.family.members.length} members • Total family',
                  style: const TextStyle(
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.paddingRegular),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
              ),
              child: Icon(
                icon,
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(height: AppTheme.paddingSmall),
            Text(
              label,
              style: const TextStyle(
                fontSize: AppTheme.fontSizeSmall,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendEmailInvitation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user ID
      final storageService = Provider.of<StorageService>(context, listen: false);
      final currentUser = await storageService.getCurrentUserProfile();
      
      if (currentUser == null) {
        throw Exception('User not found. Please sign in again.');
      }

      await _familyService.createInvitation(
        widget.family.id,
        currentUser.id,
        _emailController.text.trim(),
        _selectedRole,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invitation sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Clear the form
        _emailController.clear();
        setState(() {
          _selectedRole = UserRole.member;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send invitation: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _copyInviteLink() {
    Clipboard.setData(ClipboardData(text: _inviteLink!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invite link copied to clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareViaMessages() {
    // TODO: Implement share via messages
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share via messages coming soon!')),
    );
  }

  void _shareViaEmail() {
    // TODO: Implement share via email
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share via email coming soon!')),
    );
  }

  void _shareViaOther() {
    // TODO: Implement generic share
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generic share coming soon!')),
    );
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
        return 'Read-only access to family activities';
    }
  }
} 