import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_contribution.dart';
import '../utils/constants.dart';

class ContributionHistoryScreen extends StatefulWidget {
  const ContributionHistoryScreen({super.key});

  @override
  State<ContributionHistoryScreen> createState() => _ContributionHistoryScreenState();
}

class _ContributionHistoryScreenState extends State<ContributionHistoryScreen> {
  final String _currentUserId = 'current_user_id'; // TODO: Get from auth provider
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Contributions'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('user_contributions')
            .where('userId', isEqualTo: _currentUserId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading contributions',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final contributions = snapshot.data?.docs ?? [];

          if (contributions.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppTheme.paddingRegular),
            itemCount: contributions.length,
            itemBuilder: (context, index) {
              final doc = contributions[index];
              final contribution = UserContribution.fromJson(
                doc.data() as Map<String, dynamic>,
                doc.id,
              );
              return _buildContributionCard(contribution);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.edit_location_alt,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'No Contributions Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Start contributing by suggesting edits to disposal facilities or adding new ones to help improve the community database.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.add_location),
              label: const Text('Find Facilities to Improve'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContributionCard(UserContribution contribution) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: AppTheme.paddingRegular),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingRegular),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getContributionTypeIcon(contribution.contributionType),
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getContributionTypeTitle(contribution.contributionType),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (contribution.facilityId != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Facility ID: ${contribution.facilityId}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                _buildStatusBadge(contribution.status),
              ],
            ),
            const SizedBox(height: AppTheme.paddingRegular),
            
            // Contribution details
            _buildContributionDetails(contribution),
            
            if (contribution.userNotes != null) ...[
              const SizedBox(height: AppTheme.paddingSmall),
              Container(
                padding: const EdgeInsets.all(AppTheme.paddingSmall),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Notes:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      contribution.userNotes!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (contribution.reviewNotes != null) ...[
              const SizedBox(height: AppTheme.paddingSmall),
              Container(
                padding: const EdgeInsets.all(AppTheme.paddingSmall),
                decoration: BoxDecoration(
                  color: _getStatusColor(contribution.status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                  border: Border.all(
                    color: _getStatusColor(contribution.status).withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin Review:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(contribution.status),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      contribution.reviewNotes!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _getStatusColor(contribution.status),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppTheme.paddingSmall),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  'Submitted: ${_formatDate(contribution.timestamp)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                if (contribution.reviewTimestamp != null) ...[
                  const SizedBox(width: 16),
                  Icon(
                    Icons.rate_review,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Reviewed: ${_formatDate(contribution.reviewTimestamp!)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContributionDetails(UserContribution contribution) {
    final suggestedData = contribution.suggestedData;
    
    switch (contribution.contributionType) {
      case ContributionType.editHours:
        final operatingHours = suggestedData['operatingHours'] as Map<String, dynamic>? ?? {};
        return _buildDataSection(
          'Operating Hours',
          operatingHours.entries
              .map((e) => '${_capitalizeFirstLetter(e.key)}: ${e.value}')
              .toList(),
        );
      
      case ContributionType.editContact:
        final contactInfo = suggestedData['contactInfo'] as Map<String, dynamic>? ?? {};
        return _buildDataSection(
          'Contact Information',
          contactInfo.entries
              .map((e) => '${_capitalizeFirstLetter(e.key)}: ${e.value}')
              .toList(),
        );
      
      case ContributionType.editAcceptedMaterials:
        final materials = suggestedData['acceptedMaterials'] as List<dynamic>? ?? [];
        return _buildDataSection(
          'Accepted Materials',
          materials.map((m) => m.toString()).toList(),
        );
      
      case ContributionType.newFacility:
        return _buildNewFacilityDetails(suggestedData);
      
      case ContributionType.reportClosure:
        return _buildDataSection(
          'Closure Report',
          ['Facility reported as permanently closed'],
        );
      
      case ContributionType.addPhoto:
        return _buildDataSection(
          'Photo Contribution',
          ['Photos uploaded for facility identification'],
        );
      
      case ContributionType.otherCorrection:
        final description = suggestedData['description'] ?? 'No description provided';
        return _buildDataSection(
          'Other Correction',
          [description.toString()],
        );
    }
  }

  Widget _buildNewFacilityDetails(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'New Facility Details:',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (data['name'] != null) ...[
          Text('Name: ${data['name']}'),
          const SizedBox(height: 4),
        ],
        if (data['address'] != null) ...[
          Text('Address: ${data['address']}'),
          const SizedBox(height: 4),
        ],
        if (data['coordinates'] != null) ...[
          Builder(
            builder: (context) {
              final coords = data['coordinates'] as Map<String, dynamic>;
              return Column(
                children: [
                  Text('Location: ${coords['latitude']}, ${coords['longitude']}'),
                  const SizedBox(height: 4),
                ],
              );
            },
          ),
        ],
        if (data['acceptedMaterials'] != null) ...[
          Builder(
            builder: (context) {
              final materials = data['acceptedMaterials'] as List<dynamic>;
              return Text('Materials: ${materials.join(', ')}');
            },
          ),
        ],
      ],
    );
  }

  Widget _buildDataSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title:',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 2),
          child: Text(
            '• $item',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        )),
      ],
    );
  }

  Widget _buildStatusBadge(ContributionStatus status) {
    final color = _getStatusColor(status);
    final text = _getStatusText(status);
    final icon = _getStatusIcon(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: AppTheme.fontSizeSmall,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getContributionTypeIcon(ContributionType type) {
    switch (type) {
      case ContributionType.newFacility:
        return Icons.add_location;
      case ContributionType.editHours:
        return Icons.access_time;
      case ContributionType.editContact:
        return Icons.contact_phone;
      case ContributionType.editAcceptedMaterials:
        return Icons.recycling;
      case ContributionType.addPhoto:
        return Icons.add_a_photo;
      case ContributionType.reportClosure:
        return Icons.report_problem;
      case ContributionType.otherCorrection:
        return Icons.edit;
    }
  }

  String _getContributionTypeTitle(ContributionType type) {
    switch (type) {
      case ContributionType.newFacility:
        return 'New Facility Suggestion';
      case ContributionType.editHours:
        return 'Operating Hours Update';
      case ContributionType.editContact:
        return 'Contact Information Update';
      case ContributionType.editAcceptedMaterials:
        return 'Accepted Materials Update';
      case ContributionType.addPhoto:
        return 'Photo Contribution';
      case ContributionType.reportClosure:
        return 'Closure Report';
      case ContributionType.otherCorrection:
        return 'Other Correction';
    }
  }

  Color _getStatusColor(ContributionStatus status) {
    switch (status) {
      case ContributionStatus.pendingReview:
        return Colors.orange;
      case ContributionStatus.approvedIntegrated:
        return Colors.green;
      case ContributionStatus.rejected:
        return Colors.red;
      case ContributionStatus.needsMoreInfo:
        return Colors.blue;
    }
  }

  String _getStatusText(ContributionStatus status) {
    switch (status) {
      case ContributionStatus.pendingReview:
        return 'Pending Review';
      case ContributionStatus.approvedIntegrated:
        return 'Approved';
      case ContributionStatus.rejected:
        return 'Rejected';
      case ContributionStatus.needsMoreInfo:
        return 'Needs More Info';

    }
  }

  IconData _getStatusIcon(ContributionStatus status) {
    switch (status) {
      case ContributionStatus.pendingReview:
        return Icons.pending;
      case ContributionStatus.approvedIntegrated:
        return Icons.check_circle;
      case ContributionStatus.rejected:
        return Icons.cancel;
      case ContributionStatus.needsMoreInfo:
        return Icons.info_outline;

    }
  }

  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }
} 