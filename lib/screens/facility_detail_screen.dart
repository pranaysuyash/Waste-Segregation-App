import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/disposal_location.dart';
import '../models/user_contribution.dart';
import '../utils/constants.dart';
import 'contribution_submission_screen.dart';

class FacilityDetailScreen extends StatefulWidget {

  const FacilityDetailScreen({
    super.key,
    required this.facility,
  });
  final DisposalLocation facility;

  @override
  State<FacilityDetailScreen> createState() => _FacilityDetailScreenState();
}

class _FacilityDetailScreenState extends State<FacilityDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.facility.name),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _showContributionOptions(context),
            tooltip: 'Suggest an Edit',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.paddingRegular),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: AppTheme.paddingRegular),
            _buildContactInfoCard(),
            const SizedBox(height: AppTheme.paddingRegular),
            _buildOperatingHoursCard(),
            const SizedBox(height: AppTheme.paddingRegular),
            _buildAcceptedMaterialsCard(),
            if (widget.facility.photos != null && widget.facility.photos!.isNotEmpty) ...[
              const SizedBox(height: AppTheme.paddingRegular),
              _buildPhotosCard(),
            ],
            const SizedBox(height: AppTheme.paddingRegular),
            _buildFacilityInfoCard(),
            const SizedBox(height: AppTheme.paddingLarge),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 2,
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
                const Icon(
                  Icons.location_on,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.facility.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.paddingSmall),
            Row(
              children: [
                Icon(
                  Icons.place,
                  color: Colors.grey[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.facility.address,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.paddingSmall),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.grey[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getFacilitySourceColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                    border: Border.all(color: _getFacilitySourceColor().withOpacity(0.3)),
                  ),
                  child: Text(
                    _getFacilitySourceLabel(),
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeSmall,
                      color: _getFacilitySourceColor(),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.facility.isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                  ),
                  child: Text(
                    widget.facility.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeSmall,
                      color: widget.facility.isActive ? Colors.green[700] : Colors.red[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfoCard() {
    return Card(
      elevation: 2,
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
                const Icon(
                  Icons.contact_phone,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Contact Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: () => _suggestEdit(ContributionType.editContact),
                  tooltip: 'Edit Contact Info',
                ),
              ],
            ),
            const Divider(),
            if (widget.facility.contactInfo.isNotEmpty) ...[
              ...widget.facility.contactInfo.entries.map((entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      _getContactIcon(entry.key),
                      color: Colors.grey[600],
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${_getContactLabel(entry.key)}:',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              )),
            ] else ...[
              Text(
                'No contact information available',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOperatingHoursCard() {
    return Card(
      elevation: 2,
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
                const Icon(
                  Icons.access_time,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Operating Hours',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: () => _suggestEdit(ContributionType.editHours),
                  tooltip: 'Edit Hours',
                ),
              ],
            ),
            const Divider(),
            if (widget.facility.operatingHours.isNotEmpty) ...[
              ...widget.facility.operatingHours.entries.map((entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(
                        _capitalizeFirstLetter(entry.key),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text(
                      entry.value,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
              )),
            ] else ...[
              Text(
                'Operating hours not available',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAcceptedMaterialsCard() {
    return Card(
      elevation: 2,
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
                const Icon(
                  Icons.recycling,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Accepted Materials',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: () => _suggestEdit(ContributionType.editAcceptedMaterials),
                  tooltip: 'Edit Materials',
                ),
              ],
            ),
            const Divider(),
            if (widget.facility.acceptedMaterials.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.facility.acceptedMaterials.map((material) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                    border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    material,
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                      fontSize: AppTheme.fontSizeSmall,
                    ),
                  ),
                )).toList(),
              ),
            ] else ...[
              Text(
                'No accepted materials listed',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPhotosCard() {
    return Card(
      elevation: 2,
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
                const Icon(
                  Icons.photo_library,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Photos',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                  onPressed: () => _suggestEdit(ContributionType.addPhoto),
                  tooltip: 'Add Photo',
                ),
              ],
            ),
            const Divider(),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.facility.photos!.length,
                itemBuilder: (context, index) {
                  final photo = widget.facility.photos![index];
                  return Container(
                    width: 120,
                    margin: const EdgeInsets.only(right: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                      child: Image.network(
                        photo.url,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFacilityInfoCard() {
    return Card(
      elevation: 2,
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
                const Icon(
                  Icons.info,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Facility Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            if (widget.facility.lastVerifiedByAdmin != null) ...[
              Row(
                children: [
                  Icon(Icons.verified, color: Colors.green[600], size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Last verified: ${_formatDate(widget.facility.lastVerifiedByAdmin!)}',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontSize: AppTheme.fontSizeSmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            if (widget.facility.lastAdminUpdate != null) ...[
              Row(
                children: [
                  Icon(Icons.update, color: Colors.grey[600], size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Last updated: ${_formatDate(widget.facility.lastAdminUpdate!)}',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: AppTheme.fontSizeSmall,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showContributionOptions(context),
            icon: const Icon(Icons.edit),
            label: const Text('Suggest an Edit'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.paddingSmall),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _reportIssue,
            icon: const Icon(Icons.report_problem),
            label: const Text('Report Issue'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showContributionOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppTheme.paddingRegular),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppTheme.paddingRegular),
            Text(
              'How would you like to contribute?',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.paddingRegular),
            _buildContributionOption(
              icon: Icons.access_time,
              title: 'Update Operating Hours',
              subtitle: 'Correct or update facility hours',
              onTap: () {
                Navigator.pop(context);
                _suggestEdit(ContributionType.editHours);
              },
            ),
            _buildContributionOption(
              icon: Icons.contact_phone,
              title: 'Update Contact Information',
              subtitle: 'Add or correct phone, email, website',
              onTap: () {
                Navigator.pop(context);
                _suggestEdit(ContributionType.editContact);
              },
            ),
            _buildContributionOption(
              icon: Icons.recycling,
              title: 'Update Accepted Materials',
              subtitle: 'Add or correct waste types accepted',
              onTap: () {
                Navigator.pop(context);
                _suggestEdit(ContributionType.editAcceptedMaterials);
              },
            ),
            _buildContributionOption(
              icon: Icons.add_a_photo,
              title: 'Add Photos',
              subtitle: 'Upload photos of the facility',
              onTap: () {
                Navigator.pop(context);
                _suggestEdit(ContributionType.addPhoto);
              },
            ),
            _buildContributionOption(
              icon: Icons.close,
              title: 'Report Closure',
              subtitle: 'Report that this facility is closed',
              onTap: () {
                Navigator.pop(context);
                _suggestEdit(ContributionType.reportClosure);
              },
            ),
            _buildContributionOption(
              icon: Icons.edit,
              title: 'Other Correction',
              subtitle: 'Report other issues or corrections',
              onTap: () {
                Navigator.pop(context);
                _suggestEdit(ContributionType.otherCorrection);
              },
            ),
            const SizedBox(height: AppTheme.paddingRegular),
          ],
        ),
      ),
    );
  }

  Widget _buildContributionOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppTheme.primaryColor),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }

  void _suggestEdit(ContributionType type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContributionSubmissionScreen(
          facilityId: widget.facility.id!,
          facility: widget.facility,
          contributionType: type,
        ),
      ),
    );
  }

  void _reportIssue() {
    _suggestEdit(ContributionType.otherCorrection);
  }

  IconData _getContactIcon(String key) {
    switch (key.toLowerCase()) {
      case 'phone':
        return Icons.phone;
      case 'email':
        return Icons.email;
      case 'website':
        return Icons.web;
      default:
        return Icons.contact_page;
    }
  }

  String _getContactLabel(String key) {
    switch (key.toLowerCase()) {
      case 'phone':
        return 'Phone';
      case 'email':
        return 'Email';
      case 'website':
        return 'Website';
      default:
        return key.split('_').map((word) => _capitalizeFirstLetter(word)).join(' ');
    }
  }

  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  Color _getFacilitySourceColor() {
    switch (widget.facility.source) {
      case FacilitySource.adminEntered:
        return Colors.blue;
      case FacilitySource.userSuggestedIntegrated:
        return Colors.green;
      case FacilitySource.bulkImported:
        return Colors.orange;
    }
  }

  String _getFacilitySourceLabel() {
    switch (widget.facility.source) {
      case FacilitySource.adminEntered:
        return 'Admin Verified';
      case FacilitySource.userSuggestedIntegrated:
        return 'Community Contributed';
      case FacilitySource.bulkImported:
        return 'Imported Data';
    }
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }
} 