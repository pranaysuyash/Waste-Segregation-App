import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/disposal_location.dart';
import '../utils/constants.dart';
import 'facility_detail_screen.dart';
import 'contribution_submission_screen.dart';
import 'contribution_history_screen.dart';
import '../models/user_contribution.dart';

class DisposalFacilitiesScreen extends StatefulWidget {
  const DisposalFacilitiesScreen({super.key});

  @override
  State<DisposalFacilitiesScreen> createState() => _DisposalFacilitiesScreenState();
}

class _DisposalFacilitiesScreenState extends State<DisposalFacilitiesScreen> {
  final _searchController = TextEditingController();
  String _selectedMaterialFilter = 'All';
  String _selectedSourceFilter = 'All';
  bool _activeOnlyFilter = false;
  
  final List<String> _materialOptions = [
    'All',
    'Plastic',
    'Paper',
    'Metal',
    'Glass',
    'Electronics',
    'Batteries',
    'Hazardous',
    'Organic',
    'Textile',
    'Other',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Disposal Facilities'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ContributionHistoryScreen(),
              ),
            ),
            tooltip: 'My Contributions',
          ),
          IconButton(
            icon: const Icon(Icons.add_location),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ContributionSubmissionScreen(
                  contributionType: ContributionType.newFacility,
                ),
              ),
            ),
            tooltip: 'Add New Facility',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          Expanded(
            child: _buildFacilitiesList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ContributionSubmissionScreen(
              contributionType: ContributionType.newFacility,
            ),
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_location),
        label: const Text('Add Facility'),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingRegular),
      color: Colors.grey[50],
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search facilities...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) => setState(() {}),
          ),
          const SizedBox(height: AppTheme.paddingRegular),
          
          // Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Material filter
                _buildFilterChip(
                  'Material: $_selectedMaterialFilter',
                  () => _showMaterialFilter(),
                ),
                const SizedBox(width: 8),
                
                // Source filter
                _buildFilterChip(
                  'Source: $_selectedSourceFilter',
                  () => _showSourceFilter(),
                ),
                const SizedBox(width: 8),
                
                // Active only filter
                FilterChip(
                  label: const Text('Active Only'),
                  selected: _activeOnlyFilter,
                  onSelected: (selected) {
                    setState(() {
                      _activeOnlyFilter = selected;
                    });
                  },
                  selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                  checkmarkColor: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                
                // Clear filters
                if (_hasActiveFilters())
                  ActionChip(
                    label: const Text('Clear'),
                    onPressed: _clearFilters,
                    backgroundColor: Colors.red.withValues(alpha: 0.1),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
          border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_drop_down,
              color: AppTheme.primaryColor,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFacilitiesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _buildQuery().snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          // Check if it's a Firestore indexing error
          final errorMessage = snapshot.error.toString();
          final bool isIndexingError = errorMessage.contains('failed-precondition') || 
                                     errorMessage.contains('index') ||
                                     errorMessage.contains('composite');
          
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isIndexingError ? Icons.sync_problem : Icons.error_outline,
                  size: 64,
                  color: Colors.orange[400],
                ),
                const SizedBox(height: 16),
                Text(
                  isIndexingError ? 'Database Indexing Required' : 'Error loading facilities',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  isIndexingError 
                    ? 'The database needs indexing for advanced filters. Using simplified view...'
                    : errorMessage,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (isIndexingError) {
                      // Reset filters to use simpler query
                      setState(() {
                        _selectedSourceFilter = 'All';
                        _activeOnlyFilter = false;
                      });
                    } else {
                      setState(() {});
                    }
                  },
                  child: Text(isIndexingError ? 'Use Simple View' : 'Retry'),
                ),
              ],
            ),
          );
        }

        final facilities = snapshot.data?.docs ?? [];
        final filteredFacilities = _filterFacilities(facilities);

        if (filteredFacilities.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppTheme.paddingRegular),
          itemCount: filteredFacilities.length,
          itemBuilder: (context, index) {
            final doc = filteredFacilities[index];
            final facility = DisposalLocation.fromJson(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
            return _buildFacilityCard(facility);
          },
        );
      },
    );
  }

  Query _buildQuery() {
    try {
      Query query = FirebaseFirestore.instance.collection('disposal_locations');
      
      // First apply the most selective filters
      if (_selectedSourceFilter != 'All') {
        final sourceValue = _getSourceValue(_selectedSourceFilter);
        query = query.where('source', isEqualTo: sourceValue);
        
        // If we have a source filter, we can add isActive filter and orderBy
        if (_activeOnlyFilter) {
          query = query.where('isActive', isEqualTo: true);
        }
        
        // Only add orderBy if we have a simple enough query
        query = query.orderBy('name');
      } else if (_activeOnlyFilter) {
        // If only active filter is applied
        query = query.where('isActive', isEqualTo: true).orderBy('name');
      } else {
        // No filters, just order by name
        query = query.orderBy('name');
      }
      
      return query;
    } catch (e) {
      // Fallback to simpler query if indexing fails
      debugPrint('Complex query failed, using fallback: $e');
      return FirebaseFirestore.instance
          .collection('disposal_locations')
          .orderBy('name');
    }
  }

  List<QueryDocumentSnapshot> _filterFacilities(List<QueryDocumentSnapshot> facilities) {
    return facilities.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final name = data['name']?.toString().toLowerCase() ?? '';
      final address = data['address']?.toString().toLowerCase() ?? '';
      final acceptedMaterials = List<String>.from(data['acceptedMaterials'] ?? []);
      
      // Search filter
      if (_searchController.text.isNotEmpty) {
        final searchQuery = _searchController.text.toLowerCase();
        if (!name.contains(searchQuery) && !address.contains(searchQuery)) {
          return false;
        }
      }
      
      // Material filter
      if (_selectedMaterialFilter != 'All') {
        final materialFound = acceptedMaterials.any((material) =>
            material.toLowerCase().contains(_selectedMaterialFilter.toLowerCase()));
        if (!materialFound) {
          return false;
        }
      }
      
      return true;
    }).toList();
  }

  Widget _buildFacilityCard(DisposalLocation facility) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: AppTheme.paddingRegular),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppTheme.paddingRegular),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getFacilitySourceColor(facility.source).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.location_on,
            color: _getFacilitySourceColor(facility.source),
            size: 24,
          ),
        ),
        title: Text(
          facility.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: AppTheme.fontSizeMedium,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              facility.address,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: AppTheme.fontSizeSmall,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: facility.acceptedMaterials.take(3).map((material) => 
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                  ),
                  child: Text(
                    material,
                    style: const TextStyle(
                      fontSize: AppTheme.fontSizeSmall - 1,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ).toList(),
            ),
            if (facility.acceptedMaterials.length > 3) ...[
              const SizedBox(height: 4),
              Text(
                '+${facility.acceptedMaterials.length - 3} more',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeSmall,
                  color: Colors.grey[600],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: facility.isActive ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                  ),
                  child: Text(
                    facility.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeSmall,
                      color: facility.isActive ? Colors.green[700] : Colors.red[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getFacilitySourceColor(facility.source).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                  ),
                  child: Text(
                    _getFacilitySourceLabel(facility.source),
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeSmall,
                      color: _getFacilitySourceColor(facility.source),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FacilityDetailScreen(facility: facility),
          ),
        ),
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
              Icons.location_off,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'No Facilities Found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _hasActiveFilters()
                  ? 'Try adjusting your search criteria or filters.'
                  : 'Be the first to add a disposal facility in your area!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ContributionSubmissionScreen(
                    contributionType: ContributionType.newFacility,
                  ),
                ),
              ),
              icon: const Icon(Icons.add_location),
              label: const Text('Add New Facility'),
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

  void _showMaterialFilter() {
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
              'Filter by Material',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.paddingRegular),
            ...(_materialOptions.map((material) => ListTile(
              title: Text(material),
              trailing: _selectedMaterialFilter == material
                  ? const Icon(Icons.check, color: AppTheme.primaryColor)
                  : null,
              onTap: () {
                setState(() {
                  _selectedMaterialFilter = material;
                });
                Navigator.pop(context);
              },
            ))),
          ],
        ),
      ),
    );
  }

  void _showSourceFilter() {
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
              'Filter by Source',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.paddingRegular),
            ListTile(
              title: const Text('All'),
              trailing: _selectedSourceFilter == 'All'
                  ? const Icon(Icons.check, color: AppTheme.primaryColor)
                  : null,
              onTap: () {
                setState(() {
                  _selectedSourceFilter = 'All';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Admin Verified'),
              trailing: _selectedSourceFilter == 'Admin Verified'
                  ? const Icon(Icons.check, color: AppTheme.primaryColor)
                  : null,
              onTap: () {
                setState(() {
                  _selectedSourceFilter = 'Admin Verified';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Community Contributed'),
              trailing: _selectedSourceFilter == 'Community Contributed'
                  ? const Icon(Icons.check, color: AppTheme.primaryColor)
                  : null,
              onTap: () {
                setState(() {
                  _selectedSourceFilter = 'Community Contributed';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Imported Data'),
              trailing: _selectedSourceFilter == 'Imported Data'
                  ? const Icon(Icons.check, color: AppTheme.primaryColor)
                  : null,
              onTap: () {
                setState(() {
                  _selectedSourceFilter = 'Imported Data';
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  bool _hasActiveFilters() {
    return _selectedMaterialFilter != 'All' ||
           _selectedSourceFilter != 'All' ||
           _activeOnlyFilter ||
           _searchController.text.isNotEmpty;
  }

  void _clearFilters() {
    setState(() {
      _selectedMaterialFilter = 'All';
      _selectedSourceFilter = 'All';
      _activeOnlyFilter = false;
      _searchController.clear();
    });
  }

  String _getSourceValue(String sourceLabel) {
    switch (sourceLabel) {
      case 'Admin Verified':
        return 'ADMIN_ENTERED';
      case 'Community Contributed':
        return 'USER_SUGGESTED_INTEGRATED';
      case 'Imported Data':
        return 'BULK_IMPORTED';
      default:
        return '';
    }
  }

  Color _getFacilitySourceColor(FacilitySource source) {
    switch (source) {
      case FacilitySource.adminEntered:
        return Colors.blue;
      case FacilitySource.userSuggestedIntegrated:
        return Colors.green;
      case FacilitySource.bulkImported:
        return Colors.orange;
    }
  }

  String _getFacilitySourceLabel(FacilitySource source) {
    switch (source) {
      case FacilitySource.adminEntered:
        return 'Admin Verified';
      case FacilitySource.userSuggestedIntegrated:
        return 'Community';
      case FacilitySource.bulkImported:
        return 'Imported';
    }
  }
} 