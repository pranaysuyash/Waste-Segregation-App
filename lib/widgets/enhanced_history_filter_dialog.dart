import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/ui_consistency_utils.dart';
import '../models/filter_options.dart';
import '../models/waste_classification.dart';

/// Enhanced history filter dialog with improved visual hierarchy and UX
class EnhancedHistoryFilterDialog extends StatefulWidget {
  final FilterOptions currentFilters;
  final Function(FilterOptions) onFiltersApplied;
  final Function() onFiltersCleared;

  const EnhancedHistoryFilterDialog({
    super.key,
    required this.currentFilters,
    required this.onFiltersApplied,
    required this.onFiltersCleared,
  });

  @override
  State<EnhancedHistoryFilterDialog> createState() => _EnhancedHistoryFilterDialogState();
}

class _EnhancedHistoryFilterDialogState extends State<EnhancedHistoryFilterDialog> 
    with TickerProviderStateMixin {
  late FilterOptions _tempFilters;
  late List<String> _selectedCategories;
  late TabController _tabController;
  
  final List<String> _allCategories = [
    'Wet Waste',
    'Dry Waste',
    'Hazardous Waste',
    'Medical Waste',
    'Non-Waste',
  ];

  @override
  void initState() {
    super.initState();
    _tempFilters = widget.currentFilters;
    _selectedCategories = List<String>.from(widget.currentFilters.categories ?? []);
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLg),
      ),
      child: Container(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusLg),
          color: theme.colorScheme.surface,
        ),
        child: Column(
          children: [
            // Header with improved styling
            _buildHeader(theme),
            
            // Tab bar for filter categories
            _buildTabBar(theme),
            
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCategoryFilters(),
                  _buildDateRangeFilters(),
                  _buildSortingFilters(),
                ],
              ),
            ),
            
            // Action buttons
            _buildActionButtons(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingLarge),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppTheme.borderRadiusLg),
          topRight: Radius.circular(AppTheme.borderRadiusLg),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.filter_list,
            color: theme.colorScheme.onPrimaryContainer,
            size: 28,
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter History',
                  style: UIConsistency.headingMedium(context).copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  'Customize your classification history view',
                  style: UIConsistency.caption(context).copyWith(
                    color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.close,
              color: theme.colorScheme.onPrimaryContainer,
            ),
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.onPrimaryContainer.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surface,
      child: TabBar(
        controller: _tabController,
        labelColor: theme.colorScheme.primary,
        unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
        indicatorColor: theme.colorScheme.primary,
        indicatorWeight: 3,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: AppTheme.fontSizeRegular,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: AppTheme.fontSizeRegular,
        ),
        tabs: const [
          Tab(
            icon: Icon(Icons.category),
            text: 'Categories',
          ),
          Tab(
            icon: Icon(Icons.date_range),
            text: 'Date Range',
          ),
          Tab(
            icon: Icon(Icons.sort),
            text: 'Sorting',
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          _buildSectionHeader(
            'Waste Categories',
            'Select categories to filter your history',
            Icons.category_outlined,
          ),
          
          const SizedBox(height: AppTheme.spacingLg),
          
          // Select all/none buttons
          Row(
            children: [
              UIConsistency.secondaryButton(
                text: 'Select All',
                onPressed: () {
                  setState(() {
                    _selectedCategories.clear();
                    _selectedCategories.addAll(_allCategories);
                  });
                },
                isExpanded: false,
              ),
              const SizedBox(width: AppTheme.spacingSm),
              UIConsistency.secondaryButton(
                text: 'Clear All',
                onPressed: () {
                  setState(() {
                    _selectedCategories.clear();
                  });
                },
                isExpanded: false,
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spacingLg),
          
          // Category chips
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3,
                crossAxisSpacing: AppTheme.spacingMd,
                mainAxisSpacing: AppTheme.spacingMd,
              ),
              itemCount: _allCategories.length,
              itemBuilder: (context, index) {
                final category = _allCategories[index];
                final isSelected = _selectedCategories.contains(category);
                final categoryColor = UIConsistency.getCategoryColor(category);
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedCategories.remove(category);
                      } else {
                        _selectedCategories.add(category);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: AppTheme.animationFast,
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? categoryColor.withOpacity(0.15)
                          : Colors.grey.shade100,
                      border: Border.all(
                        color: isSelected 
                            ? categoryColor 
                            : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getCategoryIcon(category),
                          color: isSelected ? categoryColor : Colors.grey.shade600,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          category,
                          style: TextStyle(
                            color: isSelected ? categoryColor : Colors.grey.shade700,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            fontSize: AppTheme.fontSizeSmall,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (isSelected)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            child: Icon(
                              Icons.check_circle,
                              color: categoryColor,
                              size: 16,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeFilters() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          _buildSectionHeader(
            'Date Range',
            'Filter by when items were classified',
            Icons.calendar_today_outlined,
          ),
          
          const SizedBox(height: AppTheme.spacingLg),
          
          // Quick date range options
          _buildQuickDateRanges(),
          
          const SizedBox(height: AppTheme.spacingLg),
          
          // Custom date range
          _buildCustomDateRange(),
          
          const Spacer(),
          
          // Current selection display
          _buildCurrentDateSelection(),
        ],
      ),
    );
  }

  Widget _buildSortingFilters() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          _buildSectionHeader(
            'Sort Options',
            'Choose how to order your history',
            Icons.sort_outlined,
          ),
          
          const SizedBox(height: AppTheme.spacingLg),
          
          // Sort field selection
          _buildSortFieldSelection(),
          
          const SizedBox(height: AppTheme.spacingLg),
          
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
          padding: const EdgeInsets.all(AppTheme.paddingSmall),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusSm),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: AppTheme.spacingMd),
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
      {'label': 'Today', 'days': 1},
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
        const SizedBox(height: AppTheme.spacingSm),
        Wrap(
          spacing: AppTheme.spacingSm,
          runSpacing: AppTheme.spacingSm,
          children: quickRanges.map((range) {
            final endDate = DateTime.now();
            final startDate = endDate.subtract(Duration(days: range['days'] as int));
            final isSelected = _isDateRangeSelected(startDate, endDate);
            
            return GestureDetector(
              onTap: () {
                setState(() {
                  _tempFilters = _tempFilters.copyWith(
                    startDate: startDate,
                    endDate: endDate,
                  );
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.paddingMd,
                  vertical: AppTheme.paddingSmall,
                ),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusSm),
                  border: Border.all(
                    color: isSelected 
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  range['label'] as String,
                  style: TextStyle(
                    color: isSelected 
                        ? Colors.white
                        : Colors.grey.shade700,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
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
        const SizedBox(height: AppTheme.spacingSm),
        UIConsistency.secondaryButton(
          text: 'Select Custom Dates',
          icon: Icons.date_range,
          onPressed: _showDateRangePicker,
          isExpanded: true,
        ),
      ],
    );
  }

  Widget _buildCurrentDateSelection() {
    String selectionText = 'All time';
    if (_tempFilters.startDate != null || _tempFilters.endDate != null) {
      final start = _tempFilters.startDate != null 
          ? _formatDate(_tempFilters.startDate!) 
          : 'Beginning';
      final end = _tempFilters.endDate != null 
          ? _formatDate(_tempFilters.endDate!) 
          : 'Now';
      selectionText = '$start to $end';
    }

    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingMd),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSm),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.date_range,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Selection',
                  style: UIConsistency.caption(context),
                ),
                Text(
                  selectionText,
                  style: UIConsistency.bodyMedium(context).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (_tempFilters.startDate != null || _tempFilters.endDate != null)
            IconButton(
              onPressed: () {
                setState(() {
                  _tempFilters = _tempFilters.copyWith(
                    startDate: null,
                    endDate: null,
                  );
                });
              },
              icon: const Icon(Icons.clear),
              iconSize: 20,
            ),
        ],
      ),
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
        const SizedBox(height: AppTheme.spacingSm),
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
        }).toList(),
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
        const SizedBox(height: AppTheme.spacingSm),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusSm),
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

  Widget _buildActionButtons(ThemeData theme) {
    final hasChanges = widget.currentFilters.toString() != _tempFilters.toString() ||
                      !_listEquals(widget.currentFilters.categories ?? [], _selectedCategories);

    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingLarge),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: UIConsistency.secondaryButton(
              text: 'Clear All',
              onPressed: () {
                widget.onFiltersCleared();
                Navigator.pop(context);
              },
              isExpanded: true,
            ),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            flex: 2,
            child: UIConsistency.primaryButton(
              text: 'Apply Filters',
              onPressed: hasChanges
                  ? () {
                      final finalFilters = _tempFilters.copyWith(
                        categories: _selectedCategories.isEmpty ? null : _selectedCategories,
                      );
                      widget.onFiltersApplied(finalFilters);
                      Navigator.pop(context);
                    }
                  : null,
              isExpanded: true,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Wet Waste': return Icons.eco;
      case 'Dry Waste': return Icons.recycling;
      case 'Hazardous Waste': return Icons.warning;
      case 'Medical Waste': return Icons.medical_services;
      case 'Non-Waste': return Icons.block;
      default: return Icons.category;
    }
  }

  bool _isDateRangeSelected(DateTime start, DateTime end) {
    return _tempFilters.startDate != null &&
           _tempFilters.endDate != null &&
           _isSameDay(_tempFilters.startDate!, start) &&
           _isSameDay(_tempFilters.endDate!, end);
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
      case SortField.itemName:
        return 'Sort alphabetically by item name';
      case SortField.category:
        return 'Sort by waste category';
      case SortField.confidence:
        return 'Sort by AI confidence level';
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
              primary: AppTheme.primaryColor,
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

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
} 