import 'package:flutter/material.dart';
import '../models/filter_options.dart';
import '../utils/ui_consistency_utils.dart';

/// Enhanced History Filter Dialog with improved visual hierarchy and spacing
class EnhancedHistoryFilterDialog extends StatefulWidget {

  const EnhancedHistoryFilterDialog({
    super.key,
    required this.initialFilters,
    required this.onFiltersChanged,
  });
  final FilterOptions initialFilters;
  final Function(FilterOptions) onFiltersChanged;

  @override
  State<EnhancedHistoryFilterDialog> createState() => _EnhancedHistoryFilterDialogState();
}

class _EnhancedHistoryFilterDialogState extends State<EnhancedHistoryFilterDialog>
    with TickerProviderStateMixin {
  late FilterOptions _tempFilters;
  late TabController _tabController;
  
  // Predefined filter options
  final List<String> _availableCategories = [
    'Recyclable',
    'Organic/Compostable', 
    'Hazardous Waste',
    'Electronic Waste',
    'General Waste',
  ];

  @override
  void initState() {
    super.initState();
    _tempFilters = widget.initialFilters;
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Tab bar
            _buildTabBar(),
            
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBasicFilters(),
                  _buildDateFilters(),
                  _buildSortingFilters(),
                ],
              ),
            ),
            
            // Action buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16.0),
          topRight: Radius.circular(16.0),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(
              Icons.filter_alt_outlined,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter History',
                  style: UIConsistency.headingSmall(context),
                ),
                const SizedBox(height: 4),
                Text(
                  'Customize your classification history view',
                  style: UIConsistency.caption(context),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.close,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Theme.of(context).colorScheme.primary,
        unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        indicatorColor: Theme.of(context).colorScheme.primary,
        tabs: const [
          Tab(
            icon: Icon(Icons.category_outlined),
            text: 'Categories',
          ),
          Tab(
            icon: Icon(Icons.date_range_outlined),
            text: 'Date Range',
          ),
          Tab(
            icon: Icon(Icons.sort_outlined),
            text: 'Sort Options',
          ),
        ],
      ),
    );
  }

  Widget _buildBasicFilters() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          _buildSectionHeader(
            'Filter by Category',
            'Choose which types of waste to include',
            Icons.category_outlined,
          ),
          
          const SizedBox(height: 20),
          
          // Category filters
          Expanded(
            child: ListView.builder(
              itemCount: _availableCategories.length,
              itemBuilder: (context, index) {
                final category = _availableCategories[index];
                final isSelected = _tempFilters.categories?.contains(category) ?? false;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 8.0),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected 
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: CheckboxListTile(
                    title: Text(category),
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        final currentCategories = List<String>.from(_tempFilters.categories ?? []);
                        if (value == true) {
                          if (!currentCategories.contains(category)) {
                            currentCategories.add(category);
                          }
                        } else {
                          currentCategories.remove(category);
                        }
                        _tempFilters = _tempFilters.copyWith(
                          categories: currentCategories.isEmpty ? null : currentCategories,
                        );
                      });
                    },
                    activeColor: Theme.of(context).colorScheme.primary,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilters() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          _buildSectionHeader(
            'Date Range',
            'Filter classifications by when they were made',
            Icons.date_range_outlined,
          ),
          
          const SizedBox(height: 20),
          
          // Quick date range options
          _buildQuickDateRanges(),
          
          const SizedBox(height: 24),
          
          // Custom date range
          _buildCustomDateRange(),
          
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildSortingFilters() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          _buildSectionHeader(
            'Sort Options',
            'Choose how to order your history',
            Icons.sort_outlined,
          ),
          
          const SizedBox(height: 20),
          
          // Sort field selection
          _buildSortFieldSelection(),
          
          const SizedBox(height: 20),
          
          // Sort order selection
          _buildSortOrderSelection(),
          
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: UIConsistency.headingSmall(context),
              ),
              Text(
                subtitle,
                style: UIConsistency.caption(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickDateRanges() {
    final quickRanges = [
      {'label': 'Today', 'days': 0},
      {'label': 'Last 7 days', 'days': 7},
      {'label': 'Last 30 days', 'days': 30},
      {'label': 'Last 90 days', 'days': 90},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Ranges',
          style: UIConsistency.bodyMedium(context).copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: quickRanges.map((range) {
            final isSelected = _isQuickRangeSelected(range['days'] as int);
            return FilterChip(
              label: Text(range['label'] as String),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  _applyQuickDateRange(range['days'] as int);
                } else {
                  _clearDateFilters();
                }
              },
              selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
              checkmarkColor: Theme.of(context).colorScheme.primary,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCustomDateRange() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Custom Range',
          style: UIConsistency.bodyMedium(context).copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'From',
                          style: UIConsistency.caption(context),
                        ),
                        Text(
                          _tempFilters.startDate != null
                              ? _formatDate(_tempFilters.startDate!)
                              : 'Select start date',
                          style: UIConsistency.bodyMedium(context),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'to',
                    style: UIConsistency.caption(context),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'To',
                          style: UIConsistency.caption(context),
                        ),
                        Text(
                          _tempFilters.endDate != null
                              ? _formatDate(_tempFilters.endDate!)
                              : 'Select end date',
                          style: UIConsistency.bodyMedium(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _showDateRangePicker,
                icon: const Icon(Icons.date_range),
                label: const Text('Select Dates'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSortFieldSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sort By',
          style: UIConsistency.bodyMedium(context).copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...SortField.values.map((field) {
          return RadioListTile<SortField>(
            title: Text(field.displayName),
            subtitle: Text(_getSortFieldDescription(field)),
            value: field,
            groupValue: _tempFilters.sortBy,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _tempFilters = _tempFilters.copyWith(sortBy: value);
                });
              }
            },
            activeColor: Theme.of(context).colorScheme.primary,
          );
        }),
      ],
    );
  }

  Widget _buildSortOrderSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sort Order',
          style: UIConsistency.bodyMedium(context).copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: SwitchListTile(
            title: Text(
              _tempFilters.sortBy == SortField.date
                  ? (_tempFilters.sortNewestFirst ? 'Newest First' : 'Oldest First')
                  : (_tempFilters.sortNewestFirst ? 'A to Z' : 'Z to A'),
            ),
            subtitle: Text(
              _tempFilters.sortBy == SortField.date
                  ? 'Most recent classifications appear first'
                  : 'Alphabetical order',
            ),
            value: _tempFilters.sortNewestFirst,
            onChanged: (value) {
              setState(() {
                _tempFilters = _tempFilters.copyWith(sortNewestFirst: value);
              });
            },
            activeColor: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                setState(() {
                  _tempFilters = FilterOptions.empty();
                });
              },
              child: const Text('Reset All'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () {
                widget.onFiltersChanged(_tempFilters);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Apply Filters'),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  bool _isQuickRangeSelected(int days) {
    if (_tempFilters.startDate == null || _tempFilters.endDate == null) {
      return false;
    }
    
    final now = DateTime.now();
    final expectedStart = days == 0 
        ? DateTime(now.year, now.month, now.day)
        : DateTime(now.year, now.month, now.day).subtract(Duration(days: days));
    final expectedEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
    
    return _isSameDay(_tempFilters.startDate!, expectedStart) &&
           _isSameDay(_tempFilters.endDate!, expectedEnd);
  }

  void _applyQuickDateRange(int days) {
    final now = DateTime.now();
    final start = days == 0 
        ? DateTime(now.year, now.month, now.day)
        : DateTime(now.year, now.month, now.day).subtract(Duration(days: days));
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    
    setState(() {
      _tempFilters = _tempFilters.copyWith(
        startDate: start,
        endDate: end,
      );
    });
  }

  void _clearDateFilters() {
    setState(() {
      _tempFilters = _tempFilters.copyWith(
        
      );
    });
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getSortFieldDescription(SortField field) {
    switch (field) {
      case SortField.date:
        return 'Sort by classification date and time';
      case SortField.name:
        return 'Sort alphabetically by item name';
      case SortField.category:
        return 'Sort by waste category';
    }
  }

  Future<void> _showDateRangePicker() async {
    final initialDateRange = DateTimeRange(
      start: _tempFilters.startDate ?? DateTime.now().subtract(const Duration(days: 30)),
      end: _tempFilters.endDate ?? DateTime.now(),
    );

    final pickedDateRange = await showDateRangePicker(
      context: context,
      initialDateRange: initialDateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDateRange != null) {
      setState(() {
        _tempFilters = _tempFilters.copyWith(
          startDate: pickedDateRange.start,
          endDate: pickedDateRange.end,
        );
      });
    }
  }
} 