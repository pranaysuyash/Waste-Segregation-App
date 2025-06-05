import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/enhanced_family.dart' as family_models;
import '../models/user_profile.dart' as user_profile_models;
import '../models/shared_waste_classification.dart';
import '../services/firebase_family_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import 'family_management_screen.dart';
import 'family_invite_screen.dart';
import 'family_creation_screen.dart';
import 'classification_details_screen.dart'; // Import the new screen

class FamilyDashboardScreen extends StatefulWidget {
  final bool showAppBar;

  const FamilyDashboardScreen({super.key, this.showAppBar = true});

  @override
  State<FamilyDashboardScreen> createState() => _FamilyDashboardScreenState();
}

class _FamilyDashboardScreenState extends State<FamilyDashboardScreen> {
  late FirebaseFamilyService _familyService;
  String? _familyId;
  family_models.FamilyStats? _familyStats;
  List<user_profile_models.UserProfile> _members = [];
  String? _error;
  bool _isInitialLoading = true;
  bool _isStatsLoading = false;

  @override
  void initState() {
    super.initState();
    _familyService = FirebaseFamilyService();
    _initializeFamilyData();
  }

  Future<void> _initializeFamilyData() async {
    setState(() {
      _isInitialLoading = true;
      _isStatsLoading = true;
      _error = null;
    });
    try {
      final storageService = Provider.of<StorageService>(context, listen: false);
      final currentUser = await storageService.getCurrentUserProfile();
      if (currentUser?.familyId == null) {
        setState(() {
          // Don't set error - this is a normal state when user has no family
          _familyId = null;
          _isInitialLoading = false;
          _isStatsLoading = false;
        });
      } else {
        _familyId = currentUser!.familyId!;
        await Future.wait([
          _loadMembers(),
          _loadFamilyStats(),
        ]);
        setState(() {
          _isInitialLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to get your family information: ${e.toString()}';
        _familyId = null;
        _isInitialLoading = false;
        _isStatsLoading = false;
      });
    }
  }

  Future<void> _loadFamilyStats() async {
    if (_familyId == null) return;
    try {
      final stats = await _familyService.getFamilyStats(_familyId!);
      if (mounted) {
        setState(() {
          _familyStats = stats;
          _isStatsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        debugPrint('Error loading family stats: $e');
        setState(() {
           _error = '${_error ?? ''}\nFailed to load family statistics.';
          _isStatsLoading = false;
        });
      }
    }
  }

  Future<void> _loadMembers() async {
    if (_familyId == null) return;
    try {
      final members = await _familyService.getFamilyMembers(_familyId!);
      if (mounted) {
        setState(() {
          _members = members;
        });
      }
    } catch (e) {
      if (mounted) {
        debugPrint('Error loading family members: $e');
      }
    }
  }

  Future<void> _handleRefresh() async {
    await _initializeFamilyData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialLoading) {
      return Scaffold(
        appBar: widget.showAppBar ? AppBar(title: const Text('Family Dashboard')) : null,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_familyId == null && _error != null) {
      return Scaffold(
        appBar: widget.showAppBar ? AppBar(title: const Text('Family Dashboard')) : null,
        body: _buildErrorState(_error!), 
      );
    }
    
    if (_familyId == null && _error == null) {
      return Scaffold(
        appBar: widget.showAppBar ? AppBar(title: const Text('Family Dashboard')) : null,
        body: _buildNoFamilyState(), 
      );
    }

    return StreamBuilder<family_models.Family?>(
      stream: _familyService.getFamilyStream(_familyId!),
      builder: (context, familySnapshot) {
        final family = familySnapshot.data;
        final appBarTitle = widget.showAppBar 
            ? (familySnapshot.connectionState == ConnectionState.active && family != null
                ? family.name
                : 'Family Dashboard') 
            : '';

        return Scaffold(
          appBar: widget.showAppBar ? AppBar(
            title: Text(appBarTitle),
            actions: [
              if (family != null) ...[
                IconButton(
                  icon: const Icon(Icons.person_add),
                  tooltip: 'Invite Member',
                  onPressed: () => _navigateToInvite(family),
                ),
                IconButton(
                  icon: const Icon(Icons.manage_accounts),
                  tooltip: 'Manage Family',
                  onPressed: () => _navigateToManagement(family),
                ),
              ],
            ],
          ) : null,
          body: _buildBodyContent(familySnapshot, family, _familyStats), 
        );
      },
    );
  }

  Widget _buildBodyContent(AsyncSnapshot<family_models.Family?> familySnapshot, family_models.Family? family, family_models.FamilyStats? statsFromState) {
    if (familySnapshot.connectionState == ConnectionState.waiting && family == null && !_isStatsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (familySnapshot.hasError && _error == null) {
      return _buildErrorState('Error loading family details: ${familySnapshot.error}');
    }

    if (_error != null && family == null) { 
      return _buildErrorState(_error!);
    }

    if (family == null ){
        if(familySnapshot.connectionState == ConnectionState.waiting || _isInitialLoading || _isStatsLoading) {
             return const Center(child: CircularProgressIndicator());
        }
        return _buildNoFamilyState();
    }

    final bottomPadding = AppTheme.paddingRegular + 56.0;

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppTheme.paddingRegular,
          AppTheme.paddingRegular,
          AppTheme.paddingRegular,
          bottomPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFamilyHeader(family),
            const SizedBox(height: AppTheme.paddingLarge),
            if (_isStatsLoading) const Center(child: CircularProgressIndicator()) else _buildStatsOverview(statsFromState), 
            const SizedBox(height: AppTheme.paddingLarge),
            _buildMembersSection(family),
            const SizedBox(height: AppTheme.paddingLarge),
            _buildRecentActivityStream(),
            const SizedBox(height: AppTheme.paddingLarge),
            if (_isStatsLoading) const Center(child: CircularProgressIndicator()) else _buildEnvironmentalImpact(statsFromState),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyHeader(family_models.Family family) {
    return Card(
      elevation: AppTheme.elevationSm,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingRegular),
        child: Row(
          children: [
            Hero(
              tag: 'family_icon_${family.id}',
              child: CircleAvatar(
                radius: 30,
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                child: family.imageUrl != null && family.imageUrl!.isNotEmpty
                    ? ClipOval(child: Image.network(family.imageUrl!, fit: BoxFit.cover, width: 60, height: 60))
                    : const Icon(Icons.family_restroom, size: 30, color: AppTheme.primaryColor),
              ),
            ),
            const SizedBox(width: AppTheme.paddingRegular),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    family.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  if (family.description != null && family.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: AppTheme.paddingMicro),
                      child: Text(
                        family.description!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondaryColor),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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

  Widget _buildStatsOverview(family_models.FamilyStats? stats) {
    if (stats == null) {
      // Enhanced empty state for new families
      return Card(
        elevation: AppTheme.elevationSm,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.paddingRegular),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Family Achievements',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppTheme.paddingRegular),
              Container(
                padding: const EdgeInsets.all(AppTheme.paddingLarge),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
                  border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.1)),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.family_restroom,
                      size: 48,
                      color: AppTheme.primaryColor.withValues(alpha: 0.7),
                    ),
                    const SizedBox(height: AppTheme.paddingRegular),
                    Text(
                      'Welcome to your family!',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.paddingSmall),
                    Text(
                      'Start classifying waste items together to build your family\'s environmental impact statistics.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.paddingRegular),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(Icons.recycling, '0', 'Items Classified', AppTheme.primaryColor),
                  _buildStatItem(Icons.star, '0', 'Total Points', AppTheme.accentColor),
                  _buildStatItem(Icons.leaderboard, '0 days', 'Current Streak', AppTheme.secondaryColor),
                ],
              ),
            ],
          ),
        ),
      );
    }
    return Card(
      elevation: AppTheme.elevationSm,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingRegular),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Family Achievements',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.paddingRegular),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(Icons.recycling, '${stats.totalClassifications}', 'Items Classified', AppTheme.primaryColor),
                _buildStatItem(Icons.star, '${stats.totalPoints}', 'Total Points', AppTheme.accentColor),
                _buildStatItem(Icons.leaderboard, '${stats.currentStreak} days', 'Current Streak', AppTheme.secondaryColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 30, color: color),
          const SizedBox(height: AppTheme.paddingSmall),
          Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: AppTheme.paddingMicro),
          Text(label, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondaryColor)),
        ],
      ),
    );
  }

  Widget _buildMembersSection(family_models.Family family) {
    if (_members.isEmpty && !_isInitialLoading) {
      return const Center(child: Text('No members yet, or still loading members...'));
    }
    if(_members.isEmpty && _isInitialLoading){
        return const Center(child: CircularProgressIndicator());
    }

    return FutureBuilder<user_profile_models.UserProfile?>(
      future: Provider.of<StorageService>(context, listen: false).getCurrentUserProfile(),
      builder: (context, snapshot) {
        final currentUserProfile = snapshot.data;
        final currentUserId = currentUserProfile?.id;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Family Members (${_members.length})',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.paddingRegular),
            SizedBox(
              height: 120, 
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _members.length,
                itemBuilder: (context, index) {
                  final memberProfile = _members[index];
                  final familyMember = family.members.firstWhere((fm) => fm.userId == memberProfile.id, orElse: () => family_models.FamilyMember(userId: memberProfile.id, role: family_models.UserRole.member, joinedAt: DateTime.now(), individualStats: family_models.UserStats.empty()));
                  final userRole = familyMember.role;

                  return Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: AppTheme.paddingRegular),
                    child: Card(
                      elevation: AppTheme.elevationSm,
                      child: Padding(
                        padding: const EdgeInsets.all(AppTheme.paddingSmall),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundImage: memberProfile.photoUrl != null && memberProfile.photoUrl!.isNotEmpty
                                      ? NetworkImage(memberProfile.photoUrl!)
                                      : null,
                                  child: memberProfile.photoUrl == null || memberProfile.photoUrl!.isEmpty
                                      ? Text(memberProfile.displayName?.substring(0, 1) ?? 'U', style: const TextStyle(fontSize: 18))
                                      : null,
                                ),
                                if (memberProfile.id == currentUserId)
                                  Positioned(
                                    top: -2,
                                    right: -2,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 14),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Flexible(
                              child: Text(
                                memberProfile.displayName ?? 'User',
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            ),
                            Flexible(
                              child: Text(
                                 _getRoleName(userRole), 
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondaryColor, fontSize: 9),
                              ),
                            ),
                            if (userRole == family_models.UserRole.admin)
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Icon(Icons.admin_panel_settings, size: 10, color: AppTheme.accentColor),
                              )
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecentActivityStream() {
    if (_familyId == null) return const SizedBox.shrink();

    return StreamBuilder<List<SharedWasteClassification>>(
      stream: _familyService.getFamilyClassificationsStream(_familyId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Error loading recent activity: ${snapshot.error}', style: const TextStyle(color: Colors.red));
        }
        final recentClassifications = snapshot.data ?? [];
        return _buildRecentActivity(recentClassifications);
      },
    );
  }

  Widget _buildRecentActivity(List<SharedWasteClassification> recentClassifications) {
    if (recentClassifications.isEmpty) {
      return const Card(
          elevation: AppTheme.elevationSm,
          child: Padding(
            padding: EdgeInsets.all(AppTheme.paddingLarge),
            child: Center(child: Text('No recent family activity yet.')),
          ));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Family Activity',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppTheme.paddingRegular),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recentClassifications.length > 5 ? 5 : recentClassifications.length,
          itemBuilder: (context, index) {
            final item = recentClassifications[index];
            return Card(
              elevation: AppTheme.elevationSm,
              margin: const EdgeInsets.only(bottom: AppTheme.paddingRegular),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.secondaryColor.withValues(alpha: 0.1),
                  child: Icon(_getCategoryIcon(item.classification.category), color: AppTheme.secondaryColor),
                ),
                title: Text('${item.classification.itemName} (${item.classification.category})'),
                subtitle: Text('Shared by ${item.sharedByDisplayName} • ${TimeAgo.format(item.sharedAt)}'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ClassificationDetailsScreen(classification: item),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEnvironmentalImpact(family_models.FamilyStats? stats) {
    if (stats == null) {
      return const SizedBox.shrink();
    }
    final impact = stats.environmentalImpact;
    return Card(
      elevation: AppTheme.elevationSm,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingRegular),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Environmental Impact',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.paddingRegular),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: AppTheme.paddingRegular,
              mainAxisSpacing: AppTheme.paddingRegular,
              children: [
                _buildImpactItem(Icons.eco, 'CO₂ Saved', '${impact.co2Saved.toStringAsFixed(1)} kg', AppTheme.wetWasteColor, impact.co2Saved > 0),
                _buildImpactItem(Icons.park, 'Trees Equivalent', impact.treesEquivalent.toStringAsFixed(1), AppTheme.dryWasteColor, impact.treesEquivalent > 0),
                _buildImpactItem(Icons.water_drop, 'Water Saved', '${impact.waterSaved.toStringAsFixed(1)} L', AppTheme.hazardousWasteColor, impact.waterSaved > 0),
                 _buildImpactItem(Icons.timeline, 'Activity Streak', '${stats.currentStreak} days', AppTheme.medicalWasteColor, stats.currentStreak > 0 ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImpactItem(IconData icon, String label, String value, Color color, bool hasImpact) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingSmall),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: AppTheme.paddingRegular),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(color: color, fontWeight: FontWeight.bold),
                ),
                if (!hasImpact) Text('No impact yet', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey))
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'paper': return Icons.description;
      case 'plastic': return Icons.opacity;
      case 'glass': return Icons.wine_bar;
      case 'metal': return Icons.build_circle;
      case 'organic': return Icons.eco;
      case 'e-waste': return Icons.electrical_services;
      default: return Icons.category;
    }
  }

  String _getRoleName(family_models.UserRole role) {
    switch (role) {
      case family_models.UserRole.admin:
        return 'Admin';
      case family_models.UserRole.member:
        return 'Member';
      default:
        return role.toString().split('.').last;
    }
  }

  void _navigateToInvite(family_models.Family family) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FamilyInviteScreen(family: family),
      ),
    );
  }

  void _navigateToManagement(family_models.Family family) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FamilyManagementScreen(family: family),
      ),
    ).then((_) {
      _handleRefresh();
    });
  }

  Widget _buildErrorState(String errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: AppTheme.paddingRegular),
            Text(
              errorMessage,
              style: const TextStyle(
                fontSize: AppTheme.fontSizeMedium,
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.paddingLarge),
            ElevatedButton(
              onPressed: _initializeFamilyData,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoFamilyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.family_restroom,
              size: 64,
              color: AppTheme.textSecondaryColor,
            ),
            const SizedBox(height: AppTheme.paddingRegular),
            const Text(
              'Join or Create a Family',
              style: TextStyle(
                fontSize: AppTheme.fontSizeLarge,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.paddingSmall),
            const Text(
              'Connect with family members to track waste reduction together and compete in challenges.',
              style: TextStyle(
                fontSize: AppTheme.fontSizeRegular,
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.paddingLarge),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _createFamily(),
                  icon: const Icon(Icons.add),
                  label: const Text('Create Family'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _joinFamily(),
                  icon: const Icon(Icons.group_add),
                  label: const Text('Join Family'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _createFamily() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FamilyCreationScreen(),
      ),
    ).then((_) => _initializeFamilyData());
  }

  void _joinFamily() {
    final inviteController = TextEditingController();
    var isLoading = false;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Join Family'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter family invitation ID (recommended) or family ID (direct join):'),
              const SizedBox(height: AppTheme.paddingRegular),
              TextField(
                controller: inviteController,
                decoration: const InputDecoration(
                  hintText: 'e.g. abc123...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.family_restroom),
                ),
                enabled: !isLoading,
              ),
              if (isLoading) ...[
                const SizedBox(height: AppTheme.paddingRegular),
                const CircularProgressIndicator(),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                final inviteId = inviteController.text.trim();
                if (inviteId.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid invitation ID')),
                  );
                  return;
                }

                setDialogState(() {
                  isLoading = true;
                });

                // Capture context dependencies before async operations
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(dialogContext);

                try {
                  final storageService = Provider.of<StorageService>(context, listen: false);
                  final currentUser = await storageService.getCurrentUserProfile();

                  if (currentUser == null) {
                    throw Exception('User not found. Please sign in again.');
                  }

                  // Determine if the entered ID is a direct family ID
                  final existingFamily = await _familyService.getFamily(inviteId);
                  if (existingFamily != null) {
                    // Check if user is already a member
                    final isAlreadyMember = existingFamily.members
                        .any((member) => member.userId == currentUser.id);
                    if (isAlreadyMember) {
                      throw Exception('You are already a member of this family.');
                    }
                    // Join family directly
                    await _familyService.addMember(
                      inviteId,
                      currentUser.id,
                      user_profile_models.UserRole.member,
                    );
                  } else {
                    // Otherwise attempt to accept an invitation
                    await _familyService.acceptInvitation(inviteId, currentUser.id);
                  }

                  navigator.pop();
                  await _initializeFamilyData(); // Refresh the family data

                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(
                        content: Text('Successfully joined the family!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  setDialogState(() {
                    isLoading = false;
                  });
                  
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text('Failed to join family: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Join'),
            ),
          ],
        ),
      ),
    );
  }
}

class TimeAgo {
  static String format(DateTime date) {
    final duration = DateTime.now().difference(date);
    if (duration.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    }
    if (duration.inDays >= 1) {
      return '${duration.inDays}d ago';
    }
    if (duration.inHours >= 1) {
      return '${duration.inHours}h ago';
    }
    if (duration.inMinutes >= 1) {
      return '${duration.inMinutes}m ago';
    }
    return 'Just now';
  }
}