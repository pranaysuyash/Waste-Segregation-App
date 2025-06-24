import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/filter_options.dart';
import '../models/waste_classification.dart';
import '../screens/result_screen.dart';
import '../services/storage_service.dart';
import '../services/cloud_storage_service.dart';
import '../utils/constants.dart';
import '../utils/error_handler.dart';
import '../l10n/app_localizations.dart';
import '../widgets/history_list_item.dart';
import '../widgets/animations/enhanced_loading_states.dart';
import '../services/analytics_service.dart';
import 'package:waste_segregation_app/utils/waste_app_logger.dart';

/// A screen that displays the complete history of waste classifications with filtering and searching
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({
    super.key,
    this.filterCategory,
    this.filterSubcategory,
  });
  final String? filterCategory;
  final String? filterSubcategory;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with RestorationMixin {
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

  // List of classifications
  List<WasteClassification> _classifications = [];

  bool _allowHistoryFeedback = true;
  int _feedbackTimeframeDays = 7;

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

  // Selected classification for wide layouts
  WasteClassification? _selectedClassification;
  final RestorableStringN _selectedClassificationId = RestorableStringN(null);

  // Analytics service
  late AnalyticsService _analyticsService;

  @override
  String? get restorationId => 'history_screen';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_selectedClassificationId, 'selected_classification_id');

    // When data is loaded, attempt to restore selected classification
    if (_classifications.isNotEmpty && _selectedClassificationId.value != null) {
      final id = _selectedClassificationId.value!;
      try {
        _selectedClassification = _classifications.firstWhere((c) => c.id == id);
      } catch (_) {
        _selectedClassification = null;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _analyticsService = Provider.of<AnalyticsService>(context, listen: false);

    // Track screen view
    _analyticsService.trackScreenView('HistoryScreen', parameters: {
      'filter_category': widget.filterCategory,
      'filter_subcategory': widget.filterSubcategory,
    });

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
    _selectedClassificationId.dispose();
    super.dispose();
  }

  // Scroll listener for pagination
  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMorePages) {
      _loadMoreClassifications();
    }
  }

  // Load classifications with current filters
  Future<void> _loadClassifications() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _currentPage = 0;
      _hasMorePages = true;
    });

    try {
      final storageService = Provider.of<StorageService>(context, listen: false);
      final cloudStorageService = Provider.of<CloudStorageService>(context, listen: false);

      // Get Google sync and feedback settings
      final settings = await storageService.getSettings();
      final isGoogleSyncEnabled = settings['isGoogleSyncEnabled'] ?? false;
      _allowHistoryFeedback = settings['allowHistoryFeedback'] ?? true;
      _feedbackTimeframeDays = settings['feedbackTimeframeDays'] ?? 7;

      // Load from cloud or local based on sync setting
      final allClassifications = isGoogleSyncEnabled
          ? await cloudStorageService.getAllClassificationsWithCloudSync(isGoogleSyncEnabled)
          : await storageService.getAllClassifications(filterOptions: _filterOptions);

      // Apply filters if not already applied
      final filteredClassifications = isGoogleSyncEnabled
          ? storageService.applyFiltersToClassifications(allClassifications, _filterOptions)
          : allClassifications;

      // Get first page
      final startIndex = _currentPage * _itemsPerPage;
      final endIndex = startIndex + _itemsPerPage;
      final pageClassifications = filteredClassifications.length > startIndex
          ? filteredClassifications.sublist(
              startIndex, endIndex > filteredClassifications.length ? filteredClassifications.length : endIndex)
          : <WasteClassification>[];

      if (!mounted) return;

      setState(() {
        _classifications = pageClassifications;
        _hasMorePages = endIndex < filteredClassifications.length;
      });

      if (_selectedClassificationId.value != null) {
        try {
          _selectedClassification = _classifications.firstWhere((c) => c.id == _selectedClassificationId.value);
        } catch (_) {
          _selectedClassification = null;
        }
      }

      WasteAppLogger.info(
          '📊 History: Loaded ${pageClassifications.length} classifications (Google sync: $isGoogleSyncEnabled)');
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to load classifications: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Load more classifications for pagination
  Future<void> _loadMoreClassifications() async {
    if (_isLoadingMore || !_hasMorePages || !mounted) return;

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

      if (!mounted) return;

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
      if (mounted) {
        _showErrorSnackBar('Failed to load more classifications: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
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
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
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
    // Track filter dialog open
    _analyticsService.trackUserAction('open_history_filter_dialog', parameters: {
      'current_active_filters': _isFilterActive(),
      'active_categories': _selectedCategories,
    });

    final tempSelectedCategories = List<String>.from(_selectedCategories);

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
                          selectedColor: categoryColor.withValues(alpha: 0.2),
                          checkmarkColor: categoryColor,
                          backgroundColor: Colors.grey.shade200,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
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
                    const Divider(),
                    const SizedBox(height: 12),
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
                    // Track filter application
                    _analyticsService.trackUserAction('apply_history_filters', parameters: {
                      'categories_selected': tempSelectedCategories,
                      'filters_count': tempSelectedCategories.length,
                    });

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
    if (!mounted) return;

    // Track export action
    _analyticsService.trackUserAction('export_history_csv', parameters: {
      'total_classifications': _classifications.length,
      'active_filters': _isFilterActive(),
      'selected_categories': _selectedCategories,
    });

    try {
      setState(() {
        _isLoading = true;
      });

      final storageService = Provider.of<StorageService>(context, listen: false);
      final csvContent = await storageService.exportClassificationsToCSV(
        filterOptions: _filterOptions,
      );

      if (!mounted) return;

      // Share the CSV file
      final directory = await _getTempDirectory();
      final filePath = '${directory.path}/waste_classifications_${DateTime.now().millisecondsSinceEpoch}.csv';

      final file = File(filePath);
      await file.writeAsString(csvContent);

      if (!mounted) return;

      // Share the file
      final result = await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Waste Classifications Export',
      );

      if (mounted) {
        if (result.status == ShareResultStatus.success) {
          _showSuccessSnackBar('Export successful');
        } else {
          _showErrorSnackBar('Export cancelled');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to export classifications: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Get temporary directory for export
  Future<Directory> _getTempDirectory() async {
    if (kIsWeb) {
      throw Exception('Export is not supported on web platform yet');
    }

    return getTemporaryDirectory();
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
      case 'requires manual review':
        return AppTheme.manualReviewColor;
      default:
        return AppTheme.secondaryColor;
    }
  }

  // Navigate to classification details
  void _navigateToClassificationDetails(WasteClassification classification) {
    // Track viewing classification from history
    _analyticsService.trackUserAction('view_history_classification', parameters: {
      'classification_id': classification.id,
      'category': classification.category,
      'item_name': classification.itemName,
      'from_screen': 'HistoryScreen',
      'is_wide_layout': MediaQuery.of(context).size.width >= 840,
    });

    _selectedClassificationId.value = classification.id;
    if (MediaQuery.of(context).size.width >= 840) {
      setState(() {
        _selectedClassification = classification;
      });
    } else {
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
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 840;

        final listBody = _isLoading
            ? const HistoryLoadingWidget()
            : _classifications.isEmpty && !_isFilterActive()
                ? EmptyStateWidget(
                    title: 'No History Yet',
                    message: 'Start classifying items to build your waste history.',
                    icon: Icons.history_toggle_off_outlined,
                    actionButton: Builder(
                      builder: (context) {
                        final t = AppLocalizations.of(context)!;
                        return Semantics(
                          excludeSemantics: true,
                          hint: t.startClassifyingHint,
                          button: true,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Start Classifying'),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        );
                      },
                    ),
                  )
                : _classifications.isEmpty && _isFilterActive()
                    ? EmptyStateWidget(
                        title: 'No Results Found',
                        message: 'Try adjusting your filters or clearing them to see more items.',
                        icon: Icons.filter_alt_off_outlined,
                        actionButton: ElevatedButton.icon(
                          icon: const Icon(Icons.clear_all),
                          label: const Text('Clear Filters'),
                          onPressed: _clearFilters,
                        ),
                      )
                    : _buildHistoryList();

        final scaffoldBody = isWide
            ? Row(
                children: [
                  Expanded(child: listBody),
                  const VerticalDivider(width: 1),
                  Expanded(
                    child: _selectedClassification != null
                        ? ResultScreen(
                            classification: _selectedClassification!,
                            showActions: false,
                          )
                        : const Center(child: Text('Select an item')),
                  ),
                ],
              )
            : listBody;

        return Scaffold(
          appBar: AppBar(
            title: const Text('History'),
            actions: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _showFilterDialog,
                tooltip: 'Filter',
              ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: _exportToCSV,
                tooltip: 'Export History',
              ),
            ],
          ),
          body: scaffoldBody,
          floatingActionButton: _isLoadingMore
              ? FloatingActionButton(
                  onPressed: null,
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.5),
                  child: const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _buildHistoryList() {
    return RefreshIndicator(
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
            onFeedbackSubmitted: _handleFeedbackSubmission,
            showFeedbackButton: _canProvideFeedback(classification),
          );
        },
      ),
    );
  }

  Future<void> _handleFeedbackSubmission(WasteClassification updatedClassification) async {
    try {
      final storageService = Provider.of<StorageService>(context, listen: false);
      await storageService.saveClassification(updatedClassification);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Thank you for your feedback!'),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      // Refresh list to reflect feedback state
      await _loadClassifications();
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save feedback: ${ErrorHandler.getUserFriendlyMessage(e)}'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  bool _canProvideFeedback(WasteClassification classification) {
    if (!_allowHistoryFeedback) return false;
    final now = DateTime.now();
    final daysDifference = now.difference(classification.timestamp).inDays;
    return daysDifference <= _feedbackTimeframeDays;
  }

  bool _isFilterActive() {
    return _filterOptions.isNotEmpty;
  }
}

class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.message,
    this.actionButton,
    this.icon,
  });
  final String title;
  final String message;
  final Widget? actionButton;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: AppTheme.paddingLarge),
            ],
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.paddingSmall),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: AppTheme.fontSizeRegular,
                height: 1.4,
              ),
            ),
            if (actionButton != null) ...[
              const SizedBox(height: AppTheme.paddingLarge),
              actionButton!,
            ],
          ],
        ),
      ),
    );
  }
}
