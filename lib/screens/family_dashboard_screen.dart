import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/enhanced_family.dart';
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
import 'classification_details_screen.dart'; // Import the new screen

class FamilyDashboardScreen extends StatefulWidget {
  const FamilyDashboardScreen({super.key});

  @override
  State<FamilyDashboardScreen> createState() => _FamilyDashboardScreenState();
}

class _FamilyDashboardScreenState extends State<FamilyDashboardScreen> {
  late FirebaseFamilyService _familyService;
  String? _familyId;
  // Family? _family; // Will be provided by StreamBuilder
  // FamilyStats? _stats; // Will be part of Family object from StreamBuilder
  List<UserProfile> _members = [];
  // List<SharedWasteClassification> _recentClassifications = []; // Will be provided by StreamBuilder
  String? _error; // For initial familyId loading error or global errors

  // To track if initial family ID loading is done
  bool _isInitialLoading = true;

  @override
  void initState() {
    super.initState();
    _familyService = FirebaseFamilyService();
    _initializeFamilyId();
  }

  Future<void> _initializeFamilyId() async {
    setState(() {
      _isInitialLoading = true;
      _error = null;
    });
    try {
      final storageService = Provider.of<StorageService>(context, listen: false);
      final currentUser = await storageService.getCurrentUserProfile();
      if (currentUser?.familyId == null) {
        setState(() {
          _error = 'You are not part of any family yet.';
          _familyId = null; // Explicitly null if not part of family
          _isInitialLoading = false;
        });
      } else {
        setState(() {
          _familyId = currentUser!.familyId!;
          _isInitialLoading = false;
        });
        // After familyId is available, load members (non-streamed part)
        _loadMembers();
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to get your family information: ${e.toString()}';
        _familyId = null;
        _isInitialLoading = false;
      });
    }
  }

  Future<void> _loadMembers() async {
    if (_familyId == null) return;
    // This can remain a one-time fetch if members don't need strict real-time update for the dashboard's purpose
    try {
      final members = await _familyService.getFamilyMembers(_familyId!);
      if (mounted) {
        setState(() {
          _members = members;
        });
      }
    } catch (e) {
      if (mounted) {
        // Optionally set an error specific to members loading, or log
        print('Error loading family members: $e');
      }
    }
  }

  // _loadFamilyData is largely replaced by StreamBuilders.
  // RefreshIndicator can call _initializeFamilyId and _loadMembers if needed,
  // or specific stream refresh logic if StreamProviders were used.
  Future<void> _handleRefresh() async {
    await _initializeFamilyId(); // Re-check family ID and load members
    // StreamBuilders will automatically listen to new data if familyId changes or on their own.
  }


  @override
  Widget build(BuildContext context) {
    // The AppBar title might need to access family data from the StreamBuilder
    // This can be done by wrapping Scaffold with the Family StreamBuilder or passing data down.
    // For simplicity, we might initially show a generic title or update it via the stream.

    if (_isInitialLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Family Dashboard')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_familyId == null) {
      // If after initial load, familyId is still null (e.g., user not in family or error)
      return Scaffold(
        appBar: AppBar(title: const Text('Family Dashboard')),
        body: _error != null ? _buildErrorState(_error!) : _buildNoFamilyState(),
      );
    }

    // Main content with StreamBuilder for Family data
    return StreamBuilder<Family?>(
      stream: _familyService.getFamilyStream(_familyId!),
      builder: (context, familySnapshot) {
        final family = familySnapshot.data;
        final familyStats = family?.stats;

        // Determine AppBar title based on family data
        final appBarTitle = familySnapshot.connectionState == ConnectionState.active && family != null
            ? family.name
            : 'Family Dashboard';

        return Scaffold(
          appBar: AppBar(
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
          ),
          body: _buildBodyContent(familySnapshot, family, familyStats),
        );
      },
    );
  }

  Widget _buildBodyContent(AsyncSnapshot<Family?> familySnapshot, Family? family, FamilyStats? stats) {
    if (familySnapshot.connectionState == ConnectionState.waiting && family == null) { // Show loading only if no data yet
      return const Center(child: CircularProgressIndicator());
    }

    if (familySnapshot.hasError) {
      return _buildErrorState('Error loading family details: ${familySnapshot.error}');
    }

    if (family == null) { // This could be after stream starts but returns null (e.g. family deleted)
      return _buildNoFamilyState(); // Or a specific "Family not found" state
    }

    // Now that we have family, we can build the rest of the UI, including the classifications stream
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.paddingRegular),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFamilyHeader(family), // Pass family
            const SizedBox(height: AppTheme.paddingLarge),
            _buildStatsOverview(stats), // Pass stats
            const SizedBox(height: AppTheme.paddingLarge),
            _buildMembersSection(family), // Pass family to get member roles if needed
            const SizedBox(height: AppTheme.paddingLarge),
            _buildRecentActivityStream(), // This will have its own StreamBuilder
            const SizedBox(height: AppTheme.paddingLarge),
            _buildEnvironmentalImpact(stats), // Pass stats
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityStream() {
    if (_familyId == null) return const SizedBox.shrink(); // Should not happen if we reach here

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
        return _buildRecentActivity(recentClassifications); // Pass the list to the existing method
      },
    );
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
              errorMessage, // Use passed error message
              style: const TextStyle(
                fontSize: AppTheme.fontSizeMedium,
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.paddingLarge),
            ElevatedButton(
              onPressed: _initializeFamilyId, // Retry initialization
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

  Widget _buildFamilyHeader(Family family) { // Now takes Family object
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
                    family.name, // Use family.name
                    style: const TextStyle(
                      fontSize: AppTheme.fontSizeLarge,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_members.length} members', // _members is still loaded separately
                    style: const TextStyle(
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  Text(
                    'Created ${_formatDate(family.createdAt)}', // Use family.createdAt
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

  Widget _buildStatsOverview(FamilyStats? stats) { // Now takes FamilyStats object
    if (stats == null) return const Center(child: Text("Loading stats...")); // Or some placeholder

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
                stats.totalClassifications.toString(), // Use stats.
                Icons.category,
                AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: AppTheme.paddingRegular),
            Expanded(
              child: _buildStatCard(
                'Total Points',
                stats.totalPoints.toString(), // Use stats.
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
                '${stats.currentStreak} days', // Use stats.
                Icons.local_fire_department,
                Colors.orange,
              ),
            ),
            const SizedBox(width: AppTheme.paddingRegular),
            Expanded(
              child: _buildStatCard(
                'Best Streak',
                '${stats.bestStreak} days', // Use stats.
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

  Widget _buildMembersSection(Family family) { // Pass family for member roles
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
              onPressed: () => _navigateToManagement(family),
              child: const Text('Manage'),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.paddingRegular),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _members.length, // _members still loaded via _loadMembers
          itemBuilder: (context, index) {
            final memberProfile = _members[index]; // This is UserProfile
            final familyMemberData = family.getMember(memberProfile.id); // This is FamilyMember
            
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: memberProfile.photoUrl != null
                      ? ClipOval(
                          child: Image.network(
                            memberProfile.photoUrl!,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Text(memberProfile.displayName?.substring(0, 1) ?? 'U'),
                          ),
                        )
                      : Text(memberProfile.displayName?.substring(0, 1) ?? 'U'),
                ),
                title: Text(memberProfile.displayName ?? 'Unknown User'),
                subtitle: Text(
                  '${familyMemberData?.role.toString().split('.').last ?? 'Member'} • '
                  '${familyMemberData?.individualStats.totalPoints ?? 0} points',
                ),
                trailing: familyMemberData?.role == UserRole.admin
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

  Widget _buildRecentActivity(List<SharedWasteClassification> recentClassifications) { // Takes list from StreamBuilder
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
        if (recentClassifications.isEmpty)
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
            itemCount: recentClassifications.length,
            itemBuilder: (context, index) {
              final classificationItem = recentClassifications[index];
              // Find member who shared this. _members should be loaded.
              final member = _members.firstWhere(
                (m) => m.id == classificationItem.sharedBy,
                orElse: () => UserProfile( // Fallback, should ideally not happen if _members is synced
                  id: classificationItem.sharedBy,
                  email: 'unknown@example.com',
                  displayName: classificationItem.sharedByDisplayName, // Use display name from classification
                  photoUrl: classificationItem.sharedByPhotoUrl,
                ),
              );
              
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 20,
                    backgroundColor: _getCategoryColor(classificationItem.classification.category),
                    child: const Icon(Icons.delete, color: Colors.white, size: 16),
                  ),
                  title: Text(classificationItem.classification.itemName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${member.displayName ?? classificationItem.sharedByDisplayName} • ${classificationItem.classification.category}'),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.thumb_up_alt_outlined, size: 14, color: AppTheme.textSecondaryColor),
                          const SizedBox(width: 2),
                          Text('${classificationItem.reactions.length}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
                          const SizedBox(width: 8),
                          Icon(Icons.comment_outlined, size: 14, color: AppTheme.textSecondaryColor),
                          const SizedBox(width: 2),
                          Text('${classificationItem.comments.length}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
                        ],
                      ),
                    ],
                  ),
                  trailing: Text(
                    _formatDate(classificationItem.sharedAt),
                    style: const TextStyle(
                      fontSize: AppTheme.fontSizeSmall,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ClassificationDetailsScreen(classification: classificationItem),
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

  Widget _buildEnvironmentalImpact(FamilyStats? stats) { // Now takes FamilyStats
    if (stats?.environmentalImpact == null) return const Center(child: Text("Loading impact..."));

    final impact = stats!.environmentalImpact;
    
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

  Widget _buildImpactItem(String value, String label, IconData icon, Color color, String tooltipMessage) {
    return Tooltip(
      message: tooltipMessage,
      padding: const EdgeInsets.all(AppTheme.paddingSmall),
      margin: const EdgeInsets.all(AppTheme.paddingSmall),
      preferBelow: false,
      child: Column(
        mainAxisSize: MainAxisSize.min, // To make tooltip target the column itself
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
      ),
    );
  }

  void _navigateToManagement(Family family) { // Takes family
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FamilyManagementScreen(family: family), // Pass family
      ),
    ).then((_) {
      // Refresh might be needed if family settings changed, streams should handle most data
      _loadMembers(); // Explicitly reload members as they are not streamed here
    });
  }

  void _navigateToInvite(Family family) { // Takes family
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FamilyInviteScreen(family: family), // Pass family
      ),
    );
  }

  void _createFamily() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FamilyCreationScreen(),
      ),
    ).then((_) => _initializeFamilyId()); // Re-initialize to get new family ID
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