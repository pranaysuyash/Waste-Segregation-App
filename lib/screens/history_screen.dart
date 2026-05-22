import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/filter_options.dart';
import 'package:waste_segregation_app/models/waste_classification.dart';
import '../screens/result_screen_wrapper.dart';
import '../services/storage_service.dart';
import '../services/cloud_storage_service.dart';
import '../utils/constants.dart';
import '../utils/waste_theme.dart';
import '../utils/error_handler.dart';
import '../widgets/history_list_item.dart';
import '../widgets/animations/enhanced_loading_states.dart';
import '../widgets/animations/empty_state_animations.dart';
import '../services/analytics_service.dart';
import 'package:waste_segregation_app/utils/waste_app_logger.dart';

// ignore_for_file: cascade_invocations

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
  FilterOptions _filterOptions = FilterOptions.empty();

  int _currentPage = 0;
  final int _itemsPerPage = 20;
  bool _isLoadingMore = false;
  bool _hasMorePages = true;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  bool _isLoading = true;

  List<WasteClassification> _classifications = [];

  bool _allowHistoryFeedback = true;
  int _feedbackTimeframeDays = 7;

  final ScrollController _scrollController = ScrollController();

  final List<String> _selectedCategories = [];

  static const List<String> _filterChipLabels = [
    'All',
    'Wet Waste',
    'Dry Waste',
    'Hazardous',
    'Manual Review',
    'Saved',
  ];

  String _activeFilterChip = 'All';

  WasteClassification? _selectedClassification;
  final RestorableStringN _selectedClassificationId = RestorableStringN(null);

  late AnalyticsService _analyticsService;

  @override
  String? get restorationId => 'history_screen';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(
        _selectedClassificationId, 'selected_classification_id');

    if (_classifications.isNotEmpty &&
        _selectedClassificationId.value != null) {
      final id = _selectedClassificationId.value!;
      try {
        _selectedClassification =
            _classifications.firstWhere((c) => c.id == id);
      } catch (_) {
        _selectedClassification = null;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    try {
      _analyticsService = Provider.of<AnalyticsService>(context, listen: false);
    } catch (_) {
      _analyticsService = AnalyticsService(
        StorageService(),
        enableFirestore: false,
      );
      WasteAppLogger.warning(
        'HistoryScreen: AnalyticsService provider missing, using local fallback',
        context: {'screen': 'HistoryScreen'},
      );
    }
    _analyticsService.trackScreenView('HistoryScreen', parameters: {
      'filter_category': widget.filterCategory,
      'filter_subcategory': widget.filterSubcategory,
    });

    if (widget.filterCategory != null) {
      _selectedCategories.add(widget.filterCategory!);
      _filterOptions = _filterOptions.copyWith(
        categories: [widget.filterCategory!],
      );
      _activeFilterChip = widget.filterCategory!;
    }

    _loadClassifications();

    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _selectedClassificationId.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMorePages) {
      _loadMoreClassifications();
    }
  }

  Future<void> _loadClassifications() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _currentPage = 0;
      _hasMorePages = true;
    });

    try {
      final storageService =
          Provider.of<StorageService>(context, listen: false);

      final settings = await storageService.getSettings();
      final isGoogleSyncEnabled = settings['isGoogleSyncEnabled'] ?? false;
      _allowHistoryFeedback = settings['allowHistoryFeedback'] ?? true;
      _feedbackTimeframeDays = settings['feedbackTimeframeDays'] ?? 7;

      final List<WasteClassification> allClassifications;
      if (isGoogleSyncEnabled) {
        if (!mounted) return;
        final cloudStorageService =
            Provider.of<CloudStorageService>(context, listen: false);
        allClassifications = await cloudStorageService
            .getAllClassificationsWithCloudSync(isGoogleSyncEnabled);
      } else {
        allClassifications = await storageService.getAllClassifications(
          filterOptions: _filterOptions,
        );
      }

      final filteredClassifications = isGoogleSyncEnabled
          ? storageService.applyFiltersToClassifications(
              allClassifications, _filterOptions)
          : allClassifications;

      final startIndex = _currentPage * _itemsPerPage;
      final endIndex = startIndex + _itemsPerPage;
      final pageClassifications = filteredClassifications.length > startIndex
          ? filteredClassifications.sublist(
              startIndex,
              endIndex > filteredClassifications.length
                  ? filteredClassifications.length
                  : endIndex)
          : <WasteClassification>[];

      if (!mounted) return;

      setState(() {
        _classifications = pageClassifications;
        _hasMorePages = endIndex < filteredClassifications.length;
      });

      if (_selectedClassificationId.value != null) {
        try {
          _selectedClassification = _classifications
              .firstWhere((c) => c.id == _selectedClassificationId.value);
        } catch (_) {
          _selectedClassification = null;
        }
      }

      WasteAppLogger.info(
          'History: Loaded ${pageClassifications.length} classifications (Google sync: $isGoogleSyncEnabled)');
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

  Future<void> _loadMoreClassifications() async {
    if (_isLoadingMore || !_hasMorePages || !mounted) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final storageService =
          Provider.of<StorageService>(context, listen: false);

      final nextPage = _currentPage + 1;
      final moreClassifications =
          await storageService.getClassificationsWithPagination(
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

  void _onFilterChipSelected(String label) {
    if (label == 'All') {
      _activeFilterChip = 'All';
      _selectedCategories.clear();
      _applyFilters();
      return;
    }

    if (label == 'Saved') {
      _activeFilterChip = 'Saved';
      _selectedCategories.clear();
      _applyFilters();
      return;
    }

    _activeFilterChip = label;
    _selectedCategories.clear();
    _selectedCategories.add(label);
    _applyFilters();
  }

  void _applyFilters() {
    List<String>? categories;
    if (_activeFilterChip == 'All' || _activeFilterChip == 'Saved') {
      categories = null;
    } else {
      categories = _selectedCategories.isNotEmpty
          ? List.from(_selectedCategories)
          : null;
    }

    final newFilterOptions = _filterOptions.copyWith(
      categories: categories,
      searchText:
          _searchController.text.isNotEmpty ? _searchController.text : null,
    );

    setState(() {
      _filterOptions = newFilterOptions;
    });
    _loadClassifications();
  }

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

  void _clearFilters() {
    setState(() {
      _filterOptions = FilterOptions.empty();
      _searchController.clear();
      _selectedCategories.clear();
      _activeFilterChip = 'All';
    });
    _loadClassifications();
  }

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

  Future<void> _showDateRangePicker() async {
    final initialDateRange = DateTimeRange(
      start: _filterOptions.startDate ??
          DateTime.now().subtract(const Duration(days: 30)),
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
      _applyDateRangeFilter(pickedDateRange.start, pickedDateRange.end);
    }
  }

  Future<void> _showFilterDialog() async {
    unawaited(_analyticsService
        .trackUserAction('open_history_filter_dialog', parameters: {
      'current_active_filters': _isFilterActive(),
      'active_categories': _selectedCategories,
    }));

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
                      children: _allCategoryNames.map((category) {
                        final isSelected =
                            tempSelectedCategories.contains(category);
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
                            _filterOptions.startDate != null ||
                                    _filterOptions.endDate != null
                                ? '${_filterOptions.startDate != null ? _formatDate(_filterOptions.startDate!) : 'Any'} to ${_filterOptions.endDate != null ? _formatDate(_filterOptions.endDate!) : 'Now'}'
                                : 'All time',
                            style: const TextStyle(
                                fontSize: AppTheme.fontSizeRegular),
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
                            style: const TextStyle(
                                fontSize: AppTheme.fontSizeRegular),
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
                    unawaited(_analyticsService
                        .trackUserAction('apply_history_filters', parameters: {
                      'categories_selected': tempSelectedCategories,
                      'filters_count': tempSelectedCategories.length,
                    }));

                    Navigator.of(context).pop();
                    _selectedCategories.clear();
                    _selectedCategories.addAll(tempSelectedCategories);
                    if (tempSelectedCategories.isNotEmpty) {
                      _activeFilterChip = tempSelectedCategories.first;
                    } else {
                      _activeFilterChip = 'All';
                    }
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

  Future<void> _exportToCSV() async {
    if (!mounted) return;

    unawaited(
        _analyticsService.trackUserAction('export_history_csv', parameters: {
      'total_classifications': _classifications.length,
      'active_filters': _isFilterActive(),
      'selected_categories': _selectedCategories,
    }));

    try {
      setState(() {
        _isLoading = true;
      });

      final storageService =
          Provider.of<StorageService>(context, listen: false);
      final csvContent = await storageService.exportClassificationsToCSV(
        filterOptions: _filterOptions,
      );

      if (!mounted) return;

      final directory = await _getTempDirectory();
      final filePath =
          '${directory.path}/waste_classifications_${DateTime.now().millisecondsSinceEpoch}.csv';

      final file = File(filePath);
      await file.writeAsString(csvContent);

      if (!mounted) return;

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

  Future<Directory> _getTempDirectory() async {
    if (kIsWeb) {
      throw Exception('Export is not supported on web platform yet');
    }

    return getTemporaryDirectory();
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getCategoryColor(String category) =>
      WasteTheme.categoryColor(category);

  List<String> get _allCategoryNames => [
        'Wet Waste',
        'Dry Waste',
        'Hazardous Waste',
        'Medical Waste',
        'Non-Waste',
      ];

  Color _getFilterChipColor(String label) {
    if (label == 'All') return AppTheme.primaryColor;
    if (label == 'Saved') return AppTheme.rewardGold;
    if (label == 'Manual Review') return AppTheme.manualReviewColor;
    return _getCategoryColor(label);
  }

  IconData _getFilterChipIcon(String label) {
    switch (label) {
      case 'All':
        return Icons.list;
      case 'Wet Waste':
        return Icons.water_drop;
      case 'Dry Waste':
        return Icons.recycling;
      case 'Hazardous':
        return Icons.warning_amber;
      case 'Manual Review':
        return Icons.help_outline;
      case 'Saved':
        return Icons.bookmark;
      default:
        return Icons.category;
    }
  }

  void _navigateToClassificationDetails(WasteClassification classification) {
    unawaited(_analyticsService
        .trackUserAction('view_history_classification', parameters: {
      'classification_id': classification.id,
      'category': classification.category,
      'item_name': classification.itemName,
      'from_screen': 'HistoryScreen',
      'is_wide_layout': MediaQuery.of(context).size.width >= 840,
    }));

    _selectedClassificationId.value = classification.id;
    if (MediaQuery.of(context).size.width >= 840) {
      setState(() {
        _selectedClassification = classification;
      });
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreenWrapper(
            classification: classification,
            showActions: false,
          ),
        ),
      );
    }
  }

  bool get _hasLocalFilter =>
      _searchController.text.isNotEmpty || _activeFilterChip != 'All';

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 840;

        final listBody = _buildListBody();

        final scaffoldBody = isWide
            ? Row(
                children: [
                  Expanded(child: listBody),
                  const VerticalDivider(width: 1),
                  Expanded(
                    child: _selectedClassification != null
                        ? ResultScreenWrapper(
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.paddingMedium,
          AppTheme.paddingSmall, AppTheme.paddingMedium, 0),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onChanged: (_) => _applyFilters(),
        decoration: InputDecoration(
          hintText: 'Search items...',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    _applyFilters();
                  },
                )
              : null,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppTheme.paddingMedium,
            vertical: AppTheme.paddingSmall,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.paddingMedium),
        itemCount: _filterChipLabels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final label = _filterChipLabels[index];
          final isSelected = _activeFilterChip == label;
          final chipColor = _getFilterChipColor(label);

          return FilterChip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getFilterChipIcon(label),
                  size: 16,
                  color: isSelected ? Colors.white : chipColor,
                ),
                const SizedBox(width: 6),
                Text(label),
              ],
            ),
            selected: isSelected,
            onSelected: (_) => _onFilterChipSelected(label),
            selectedColor: chipColor,
            checkmarkColor: Colors.white,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : chipColor,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 13,
            ),
            backgroundColor: chipColor.withValues(alpha: 0.08),
            showCheckmark: false,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            visualDensity: VisualDensity.compact,
          );
        },
      ),
    );
  }

  Widget _buildListBody() {
    if (_isLoading) {
      return const HistoryLoadingWidget();
    }

    if (_classifications.isEmpty && !_hasLocalFilter) {
      return EmptyHistoryStateWidget(
        onStartClassifying: () => Navigator.pop(context),
        onLearnHowSortingWorks: () => _showLearnMore(),
      );
    }

    if (_classifications.isEmpty && _hasLocalFilter) {
      return EmptyFilteredResultsWidget(
        onClearFilters: _clearFilters,
        activeFiltersCount: _countActiveFilters(),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadClassifications,
      child: Column(
        children: [
          _buildSearchBar(),
          _buildFilterChips(),
          _buildActiveFilterIndicator(),
          Expanded(child: _buildHistoryList()),
        ],
      ),
    );
  }

  Widget _buildActiveFilterIndicator() {
    final count = _countActiveFilters();
    if (count == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.paddingMedium,
        vertical: AppTheme.paddingSmall / 2,
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_alt, size: 14, color: AppTheme.primaryColor),
          const SizedBox(width: 4),
          Text(
            '$count filter${count != 1 ? 's' : ''} active',
            style: const TextStyle(
              fontSize: AppTheme.fontSizeSmall,
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: _clearFilters,
            icon: const Icon(Icons.clear_all, size: 16),
            label: const Text('Clear', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  int _countActiveFilters() {
    var count = 0;
    if (_activeFilterChip != 'All') count++;
    if (_searchController.text.isNotEmpty) count++;
    if (_filterOptions.startDate != null || _filterOptions.endDate != null)
      count++;
    return count;
  }

  Widget _buildHistoryList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(
        bottom: AppTheme.paddingRegular + 60,
      ),
      itemCount: _classifications.length + (_hasMorePages ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _classifications.length) {
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
        return RepaintBoundary(
          child: HistoryListItem(
            key: ValueKey<String>(classification.id),
            classification: classification,
            onTap: () => _navigateToClassificationDetails(classification),
            onFeedbackSubmitted: _handleFeedbackSubmission,
            showFeedbackButton: _canProvideFeedback(classification),
          ),
        );
      },
    );
  }

  void _showLearnMore() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Waste sorting guide: Wet waste (food scraps), Dry waste (paper, plastic, metal), Hazardous (batteries, electronics). Take a photo to get started!',
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Start Scanning',
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  Future<void> _handleFeedbackSubmission(
      WasteClassification updatedClassification) async {
    try {
      final storageService =
          Provider.of<StorageService>(context, listen: false);
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

      await _loadClassifications();
    } catch (e, stackTrace) {
      ErrorHandler.handleError(e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Failed to save feedback: ${ErrorHandler.getUserFriendlyMessage(e)}'),
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
