import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/filter_options.dart';
import '../models/waste_classification.dart';
import '../screens/result_screen.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../widgets/history_list_item.dart';

/// A screen that displays the complete history of waste classifications with filtering and searching
class HistoryScreen extends StatefulWidget {
  final String? filterCategory;
  final String? filterSubcategory;
  
  const HistoryScreen({
    super.key,
    this.filterCategory,
    this.filterSubcategory,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // Current filter options
  FilterOptions _filterOptions = FilterOptions.empty();
  
  // Pagination state
  int _currentPage = 0;
  final int _itemsPerPage = 20;
  bool _isLoadingMore = false;
  bool _hasMorePages = true;
  
  // State for search field
  final TextEditingController _searchController = TextEditingController();
  
  // Loading state
  bool _isLoading = true;
  bool _isExporting = false;
  
  // List of classifications
  List<WasteClassification> _classifications = [];
  Map<String, List<WasteClassification>> _groupedClassifications = {};
  
  // Scroll controller for pagination
  final ScrollController _scrollController = ScrollController();
  
  // Category filter selections
  final List<String> _selectedCategories = [];
  
  // List of all possible categories
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
    
    // Apply initial filters if provided
    if (widget.filterCategory != null) {
      _selectedCategories.add(widget.filterCategory!);
      _filterOptions = _filterOptions.copyWith(
        categories: [widget.filterCategory!],
      );
    }
    
    _loadClassifications();
    
    // Add scroll listener for pagination
    _scrollController.addListener(_scrollListener);
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }
  
  // Scroll listener for pagination
  void _scrollListener() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200 && 
        !_isLoadingMore && 
        _hasMorePages) {
      _loadMoreClassifications();
    }
  }
  
  // Load classifications with current filters
  Future<void> _loadClassifications() async {
    setState(() {
      _isLoading = true;
      _currentPage = 0;
      _hasMorePages = true;
    });
    
    try {
      final storageService = Provider.of<StorageService>(context, listen: false);
      
      // Get total count for pagination
      // _totalItems = await storageService.getClassificationsCount(
      //   filterOptions: _filterOptions,
      // );
      
      // Get first page of classifications
      final classifications = await storageService.getClassificationsWithPagination(
        filterOptions: _filterOptions,
        pageSize: _itemsPerPage,
        page: _currentPage,
      );
      
      setState(() {
        _classifications = classifications;
        _hasMorePages = classifications.length >= _itemsPerPage;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load classifications: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Load more classifications for pagination
  Future<void> _loadMoreClassifications() async {
    if (_isLoadingMore || !_hasMorePages) return;
    
    setState(() {
      _isLoadingMore = true;
    });
    
    try {
      final storageService = Provider.of<StorageService>(context, listen: false);
      
      // Load next page
      final nextPage = _currentPage + 1;
      final moreClassifications = await storageService.getClassificationsWithPagination(
        filterOptions: _filterOptions,
        pageSize: _itemsPerPage,
        page: nextPage,
      );
      
      if (moreClassifications.isNotEmpty) {
        setState(() {
          _classifications.addAll(moreClassifications);
          _currentPage = nextPage;
          _hasMorePages = moreClassifications.length >= _itemsPerPage;
        });
      } else {
        setState(() {
          _hasMorePages = false;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load more classifications: $e');
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }
  
  // Apply search filter
  void _applySearchFilter(String searchText) {
    final newFilterOptions = _filterOptions.copyWith(
      searchText: searchText.trim().isEmpty ? null : searchText.trim(),
    );
    
    if (newFilterOptions.toString() != _filterOptions.toString()) {
      setState(() {
        _filterOptions = newFilterOptions;
      });
      _loadClassifications();
    }
  }
  
  // Apply category filters
  void _applyCategoryFilters(List<String> categories) {
    final newFilterOptions = _filterOptions.copyWith(
      categories: categories.isEmpty ? null : categories,
    );
    
    if (newFilterOptions.toString() != _filterOptions.toString()) {
      setState(() {
        _filterOptions = newFilterOptions;
      });
      _loadClassifications();
    }
  }
  
  // Apply date range filter
  void _applyDateRangeFilter(DateTime? startDate, DateTime? endDate) {
    final newFilterOptions = _filterOptions.copyWith(
      startDate: startDate,
      endDate: endDate,
    );
    
    if (newFilterOptions.toString() != _filterOptions.toString()) {
      setState(() {
        _filterOptions = newFilterOptions;
      });
      _loadClassifications();
    }
  }
  
  // Clear all filters
  void _clearFilters() {
    setState(() {
      _filterOptions = FilterOptions.empty();
      _searchController.clear();
      _selectedCategories.clear();
    });
    _loadClassifications();
  }
  
  // Change sorting options
  void _changeSorting(SortField sortField, bool sortNewestFirst) {
    final newFilterOptions = _filterOptions.copyWith(
      sortBy: sortField,
      sortNewestFirst: sortNewestFirst,
    );
    
    if (newFilterOptions.toString() != _filterOptions.toString()) {
      setState(() {
        _filterOptions = newFilterOptions;
      });
      _loadClassifications();
    }
  }
  
  // Show date range picker
  Future<void> _showDateRangePicker() async {
    final initialDateRange = DateTimeRange(
      start: _filterOptions.startDate ?? DateTime.now().subtract(const Duration(days: 30)),
      end: _filterOptions.endDate ?? DateTime.now(),
    );
    
    final pickedDateRange = await showDateRangePicker(
      context: context,
      initialDateRange: initialDateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppTheme.textPrimaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (pickedDateRange != null) {
      _applyDateRangeFilter(
        pickedDateRange.start,
        pickedDateRange.end,
      );
    }
  }
  
  // Show filter dialog
  Future<void> _showFilterDialog() async {
    List<String> tempSelectedCategories = List.from(_selectedCategories);
    
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Filter Classifications'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Categories',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: AppTheme.fontSizeRegular,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _allCategories.map((category) {
                        final isSelected = tempSelectedCategories.contains(category);
                        final categoryColor = _getCategoryColor(category);
                        
                        return FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                tempSelectedCategories.add(category);
                              } else {
                                tempSelectedCategories.remove(category);
                              }
                            });
                          },
                          selectedColor: categoryColor.withOpacity(0.2),
                          checkmarkColor: categoryColor,
                          backgroundColor: Colors.grey.shade200,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Date Range',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: AppTheme.fontSizeRegular,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _filterOptions.startDate != null || _filterOptions.endDate != null
                                ? '${_filterOptions.startDate != null ? _formatDate(_filterOptions.startDate!) : 'Any'} to ${_filterOptions.endDate != null ? _formatDate(_filterOptions.endDate!) : 'Now'}'
                                : 'All time',
                            style: const TextStyle(fontSize: AppTheme.fontSizeRegular),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            await _showDateRangePicker();
                          },
                          icon: const Icon(Icons.date_range),
                          label: const Text('Select'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Sorting',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: AppTheme.fontSizeRegular,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<SortField>(
                      value: _filterOptions.sortBy,
                      decoration: const InputDecoration(
                        labelText: 'Sort by',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items: SortField.values.map((sortField) {
                        return DropdownMenuItem<SortField>(
                          value: sortField,
                          child: Text(sortField.displayName),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          Navigator.of(context).pop();
                          _changeSorting(value, _filterOptions.sortNewestFirst);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _filterOptions.sortBy == SortField.date
                                ? _filterOptions.sortNewestFirst
                                    ? 'Newest first'
                                    : 'Oldest first'
                                : _filterOptions.sortNewestFirst
                                    ? 'A to Z'
                                    : 'Z to A',
                            style: const TextStyle(fontSize: AppTheme.fontSizeRegular),
                          ),
                        ),
                        Switch(
                          value: _filterOptions.sortNewestFirst,
                          onChanged: (value) {
                            Navigator.of(context).pop();
                            _changeSorting(_filterOptions.sortBy, value);
                          },
                          activeColor: AppTheme.primaryColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _clearFilters();
                  },
                  child: const Text('Clear All'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Update selected categories and apply filters
                    _selectedCategories.clear();
                    _selectedCategories.addAll(tempSelectedCategories);
                    _applyCategoryFilters(_selectedCategories);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  // Export classifications to CSV
  Future<void> _exportToCSV() async {
    try {
      setState(() {
        _isExporting = true;
      });
      
      final storageService = Provider.of<StorageService>(context, listen: false);
      final csvContent = await storageService.exportClassificationsToCSV(
        filterOptions: _filterOptions,
      );
      
      // Share the CSV file
      final directory = await _getTempDirectory();
      final filePath = '${directory.path}/waste_classifications_${DateTime.now().millisecondsSinceEpoch}.csv';
      
      final file = File(filePath);
      await file.writeAsString(csvContent);
      
      // Share the file
      if (mounted) {
        final result = await Share.shareXFiles(
          [XFile(filePath)],
          subject: 'Waste Classifications Export',
        );
        
        if (result.status == ShareResultStatus.success) {
          _showSuccessSnackBar('Export successful');
        } else {
          _showErrorSnackBar('Export cancelled');
        }
      }
    } catch (e) {
      _showErrorSnackBar('Failed to export classifications: $e');
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }
  
  // Get temporary directory for export
  Future<Directory> _getTempDirectory() async {
    if (kIsWeb) {
      throw Exception('Export is not supported on web platform yet');
    }
    
    return await getTemporaryDirectory();
  }
  
  // Show error snackbar
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Show success snackbar
  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
  
  // Format date helper
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
  
  // Get category color helper
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
  
  // Navigate to classification details
  void _navigateToClassificationDetails(WasteClassification classification) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultScreen(
          classification: classification,
          showActions: false,
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          // Export button with accessibility
          if (_classifications.isNotEmpty)
            IconButton(
              onPressed: _isExporting ? null : _exportToCSV,
              icon: _isExporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.file_download),
              tooltip: 'Export classification history to CSV',
            ),
          
          // Filter button with accessibility
          IconButton(
            onPressed: _showFilterDialog,
            icon: Badge(
              isLabelVisible: _filterOptions.isNotEmpty,
              child: const Icon(Icons.filter_list),
            ),
            tooltip: _filterOptions.isNotEmpty 
                  ? 'Filter history (active filters applied)'
                  : 'Filter history',
          ),
        ],
      ),
      body: Column(
        children: [
          // Header section with search and filters
          Container(
            color: Colors.white,
            child: Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.all(AppTheme.paddingRegular),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search classifications...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _applySearchFilter('');
                              },
                              tooltip: 'Clear search',
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      // Debounce search input
                      Future.delayed(const Duration(milliseconds: 300), () {
                        if (value == _searchController.text) {
                          _applySearchFilter(value);
                        }
                      });
                    },
                  ),
                ),
                
                // Active filters display
                if (_filterOptions.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.paddingRegular,
                      vertical: AppTheme.paddingSmall,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      border: Border(
                        top: BorderSide(color: Colors.blue.shade100),
                        bottom: BorderSide(color: Colors.blue.shade100),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.filter_list,
                          size: 16,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Active filters: ${_filterOptions.toString()}',
                            style: TextStyle(
                              fontSize: AppTheme.fontSizeSmall,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _clearFilters,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            foregroundColor: Colors.blue.shade700,
                          ),
                          icon: const Icon(Icons.clear, size: 16),
                          label: const Text('Clear'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          
          // List of classifications
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _classifications.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadClassifications,
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.only(
                            bottom: AppTheme.paddingRegular + 60, // Extra space for FAB
                          ),
                          itemCount: _classifications.length + (_hasMorePages ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _classifications.length) {
                              // Loading indicator at the end
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                              );
                            }
                            
                            final classification = _classifications[index];
                            return HistoryListItem(
                              classification: classification,
                              onTap: () => _navigateToClassificationDetails(classification),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
  
  // Empty state widget
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.history,
            size: 64,
            color: AppTheme.textSecondaryColor,
          ),
          const SizedBox(height: AppTheme.paddingRegular),
          Text(
            _filterOptions.isNotEmpty
                ? 'No classifications match your filters'
                : 'No classifications yet',
            style: const TextStyle(
              fontSize: AppTheme.fontSizeLarge,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.paddingSmall),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingLarge),
            child: Text(
              _filterOptions.isNotEmpty
                  ? 'Try changing or clearing your filters'
                  : 'Capture or upload an image to analyze waste items',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: AppTheme.fontSizeRegular,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.paddingLarge),
          if (_filterOptions.isNotEmpty)
            ElevatedButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.clear),
              label: const Text('Clear Filters'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}