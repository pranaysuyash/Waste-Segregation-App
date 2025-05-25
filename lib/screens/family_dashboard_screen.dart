import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/enhanced_family.dart';
import '../models/user_profile.dart';
import '../models/shared_waste_classification.dart';
import '../services/firebase_family_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import 'family_management_screen.dart';
import 'family_invite_screen.dart';
import 'family_creation_screen.dart';

class FamilyDashboardScreen extends StatefulWidget {
  const FamilyDashboardScreen({super.key});

  @override
  State<FamilyDashboardScreen> createState() => _FamilyDashboardScreenState();
}

class _FamilyDashboardScreenState extends State<FamilyDashboardScreen> {
  bool _isLoading = true;
  Family? _family;
  FamilyStats? _stats;
  List<UserProfile> _members = [];
  List<SharedWasteClassification> _recentClassifications = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFamilyData();
  }

  Future<void> _loadFamilyData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final storageService = Provider.of<StorageService>(context, listen: false);
      final familyService = FirebaseFamilyService();

      // Get current user to find their family
      final currentUser = await storageService.getCurrentUserProfile();
      if (currentUser?.familyId == null) {
        setState(() {
          _error = 'You are not part of any family yet.';
          _isLoading = false;
        });
        return;
      }

      // Load family data
      final family = await familyService.getFamily(currentUser!.familyId!);
      if (family == null) {
        setState(() {
          _error = 'Family not found.';
          _isLoading = false;
        });
        return;
      }

      // Load family statistics
      final stats = await familyService.getFamilyStats(family.id);

      // Load family members
      final members = await familyService.getFamilyMembers(family.id);

      // Load recent classifications
      final classifications = await familyService.getFamilyClassifications(family.id);

      setState(() {
        _family = family;
        _stats = stats;
        _members = members;
        _recentClassifications = classifications.take(5).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load family data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_family?.name ?? 'Family Dashboard'),
        actions: [
          if (_family != null) ...[
            IconButton(
              icon: const Icon(Icons.person_add),
              tooltip: 'Invite Member',
              onPressed: () => _navigateToInvite(),
            ),
            IconButton(
              icon: const Icon(Icons.manage_accounts),
              tooltip: 'Manage Family',
              onPressed: () => _navigateToManagement(),
            ),
          ],
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_family == null) {
      return _buildNoFamilyState();
    }

    return RefreshIndicator(
      onRefresh: _loadFamilyData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.paddingRegular),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFamilyHeader(),
            const SizedBox(height: AppTheme.paddingLarge),
            _buildStatsOverview(),
            const SizedBox(height: AppTheme.paddingLarge),
            _buildMembersSection(),
            const SizedBox(height: AppTheme.paddingLarge),
            _buildRecentActivity(),
            const SizedBox(height: AppTheme.paddingLarge),
            _buildEnvironmentalImpact(),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
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
              _error!,
              style: const TextStyle(
                fontSize: AppTheme.fontSizeMedium,
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.paddingLarge),
            ElevatedButton(
              onPressed: _loadFamilyData,
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

  Widget _buildFamilyHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingRegular),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
              ),
              child: const Icon(
                Icons.family_restroom,
                size: 32,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: AppTheme.paddingRegular),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _family!.name,
                    style: const TextStyle(
                      fontSize: AppTheme.fontSizeLarge,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_members.length} members',
                    style: const TextStyle(
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  Text(
                    'Created ${_formatDate(_family!.createdAt)}',
                    style: const TextStyle(
                      fontSize: AppTheme.fontSizeSmall,
                      color: AppTheme.textSecondaryColor,
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

  Widget _buildStatsOverview() {
    if (_stats == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Family Statistics',
          style: TextStyle(
            fontSize: AppTheme.fontSizeLarge,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.paddingRegular),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Classifications',
                _stats!.totalClassifications.toString(),
                Icons.category,
                AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: AppTheme.paddingRegular),
            Expanded(
              child: _buildStatCard(
                'Total Points',
                _stats!.totalPoints.toString(),
                Icons.stars,
                Colors.amber,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.paddingRegular),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Current Streak',
                '${_stats!.currentStreak} days',
                Icons.local_fire_department,
                Colors.orange,
              ),
            ),
            const SizedBox(width: AppTheme.paddingRegular),
            Expanded(
              child: _buildStatCard(
                'Best Streak',
                '${_stats!.bestStreak} days',
                Icons.emoji_events,
                Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingRegular),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: AppTheme.paddingSmall),
            Text(
              value,
              style: TextStyle(
                fontSize: AppTheme.fontSizeLarge,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: AppTheme.fontSizeSmall,
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Family Members',
              style: TextStyle(
                fontSize: AppTheme.fontSizeLarge,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => _navigateToManagement(),
              child: const Text('Manage'),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.paddingRegular),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _members.length,
          itemBuilder: (context, index) {
            final member = _members[index];
            final familyMember = _family!.getMember(member.id);
            
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: member.photoUrl != null
                      ? ClipOval(
                          child: Image.network(
                            member.photoUrl!,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Text(member.displayName?.substring(0, 1) ?? 'U'),
                          ),
                        )
                      : Text(member.displayName?.substring(0, 1) ?? 'U'),
                ),
                title: Text(member.displayName ?? 'Unknown User'),
                subtitle: Text(
                  '${familyMember?.role.toString().split('.').last ?? 'Member'} • '
                  '${familyMember?.individualStats.totalPoints ?? 0} points',
                ),
                trailing: familyMember?.role == UserRole.admin
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Admin',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : null,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: AppTheme.fontSizeLarge,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.paddingRegular),
        if (_recentClassifications.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(AppTheme.paddingLarge),
              child: Center(
                child: Text(
                  'No recent activity',
                  style: TextStyle(color: AppTheme.textSecondaryColor),
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recentClassifications.length,
            itemBuilder: (context, index) {
              final classification = _recentClassifications[index];
              final member = _members.firstWhere(
                (m) => m.id == classification.sharedBy,
                orElse: () => UserProfile(
                  id: classification.sharedBy,
                  email: 'unknown@example.com',
                  displayName: 'Unknown User',
                ),
              );
              
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 20,
                    backgroundColor: _getCategoryColor(classification.classification.category),
                    child: const Icon(Icons.delete, color: Colors.white, size: 16),
                  ),
                  title: Text(classification.classification.itemName),
                  subtitle: Text(
                    '${member.displayName} • ${classification.classification.category}',
                  ),
                  trailing: Text(
                    _formatDate(classification.sharedAt),
                    style: const TextStyle(
                      fontSize: AppTheme.fontSizeSmall,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildEnvironmentalImpact() {
    if (_stats?.environmentalImpact == null) return const SizedBox.shrink();

    final impact = _stats!.environmentalImpact;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Environmental Impact',
          style: TextStyle(
            fontSize: AppTheme.fontSizeLarge,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.paddingRegular),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.paddingRegular),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildImpactItem(
                      '${impact.co2Saved.toStringAsFixed(1)} kg',
                      'CO₂ Saved',
                      Icons.cloud,
                      Colors.green,
                    ),
                    _buildImpactItem(
                      '${impact.treesEquivalent.toStringAsFixed(1)}',
                      'Trees Saved',
                      Icons.forest,
                      Colors.green.shade700,
                    ),
                    _buildImpactItem(
                      '${impact.waterSaved.toStringAsFixed(0)} L',
                      'Water Saved',
                      Icons.water_drop,
                      Colors.blue,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImpactItem(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: AppTheme.paddingSmall),
        Text(
          value,
          style: TextStyle(
            fontSize: AppTheme.fontSizeMedium,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: AppTheme.fontSizeSmall,
            color: AppTheme.textSecondaryColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _navigateToManagement() {
    if (_family != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FamilyManagementScreen(family: _family!),
        ),
      ).then((_) => _loadFamilyData());
    }
  }

  void _navigateToInvite() {
    if (_family != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FamilyInviteScreen(family: _family!),
        ),
      );
    }
  }

  void _createFamily() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FamilyCreationScreen(),
      ),
    ).then((_) => _loadFamilyData());
  }

  void _joinFamily() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Family'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter family ID or invitation link:'),
            const SizedBox(height: AppTheme.paddingRegular),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Family ID or invitation link',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Join family feature coming soon!')),
              );
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'wet waste':
        return AppTheme.wetWasteColor;
      case 'dry waste':
        return AppTheme.dryWasteColor;
      case 'hazardous waste':
        return AppTheme.hazardousWasteColor;
      case 'medical waste':
        return AppTheme.medicalWasteColor;
      case 'non-waste':
        return AppTheme.nonWasteColor;
      default:
        return AppTheme.secondaryColor;
    }
  }
} 