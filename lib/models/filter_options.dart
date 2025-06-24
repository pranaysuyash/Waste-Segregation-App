/// A class to represent filter options for classification history
class FilterOptions {
  /// Constructor
  FilterOptions({
    this.searchText,
    this.categories,
    this.subcategories,
    this.materialTypes,
    this.isRecyclable,
    this.isCompostable,
    this.requiresSpecialDisposal,
    this.startDate,
    this.endDate,
    this.sortNewestFirst = true,
    this.sortBy = SortField.date,
  });

  /// Creates a new empty FilterOptions
  factory FilterOptions.empty() {
    return FilterOptions();
  }

  /// Search text to filter classifications by item name, subcategory, or material type
  final String? searchText;

  /// Filter by category (can be multiple)
  final List<String>? categories;

  /// Filter by subcategory (can be multiple)
  final List<String>? subcategories;

  /// Filter by material type (can be multiple)
  final List<String>? materialTypes;

  /// Filter by recyclable status
  final bool? isRecyclable;

  /// Filter by compostable status
  final bool? isCompostable;

  /// Filter by special disposal requirement
  final bool? requiresSpecialDisposal;

  /// Filter from a specific date
  final DateTime? startDate;

  /// Filter until a specific date
  final DateTime? endDate;

  /// Sorting direction (true for newest first, false for oldest first)
  final bool sortNewestFirst;

  /// Sort by field (timestamp, category, etc.)
  final SortField sortBy;

  /// Creates a copy of this FilterOptions but with the given fields replaced
  FilterOptions copyWith({
    String? searchText,
    List<String>? categories,
    List<String>? subcategories,
    List<String>? materialTypes,
    bool? isRecyclable,
    bool? isCompostable,
    bool? requiresSpecialDisposal,
    DateTime? startDate,
    DateTime? endDate,
    bool? sortNewestFirst,
    SortField? sortBy,
  }) {
    return FilterOptions(
      searchText: searchText ?? this.searchText,
      categories: categories ?? this.categories,
      subcategories: subcategories ?? this.subcategories,
      materialTypes: materialTypes ?? this.materialTypes,
      isRecyclable: isRecyclable ?? this.isRecyclable,
      isCompostable: isCompostable ?? this.isCompostable,
      requiresSpecialDisposal: requiresSpecialDisposal ?? this.requiresSpecialDisposal,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      sortNewestFirst: sortNewestFirst ?? this.sortNewestFirst,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  /// Returns true if no filters are applied
  bool get isEmpty {
    return searchText == null &&
        (categories == null || categories!.isEmpty) &&
        (subcategories == null || subcategories!.isEmpty) &&
        (materialTypes == null || materialTypes!.isEmpty) &&
        isRecyclable == null &&
        isCompostable == null &&
        requiresSpecialDisposal == null &&
        startDate == null &&
        endDate == null;
  }

  /// Returns true if any filters are applied
  bool get isNotEmpty => !isEmpty;

  /// Converts this FilterOptions to a human-readable string
  @override
  String toString() {
    final appliedFilters = <String>[];

    if (searchText != null && searchText!.isNotEmpty) {
      appliedFilters.add('Search: "$searchText"');
    }

    if (categories != null && categories!.isNotEmpty) {
      appliedFilters.add('Categories: ${categories!.join(", ")}');
    }

    if (subcategories != null && subcategories!.isNotEmpty) {
      appliedFilters.add('Subcategories: ${subcategories!.join(", ")}');
    }

    if (materialTypes != null && materialTypes!.isNotEmpty) {
      appliedFilters.add('Materials: ${materialTypes!.join(", ")}');
    }

    if (isRecyclable != null) {
      appliedFilters.add('Recyclable: ${isRecyclable! ? "Yes" : "No"}');
    }

    if (isCompostable != null) {
      appliedFilters.add('Compostable: ${isCompostable! ? "Yes" : "No"}');
    }

    if (requiresSpecialDisposal != null) {
      appliedFilters.add('Special Disposal: ${requiresSpecialDisposal! ? "Yes" : "No"}');
    }

    if (startDate != null && endDate != null) {
      appliedFilters.add('Date Range: ${_formatDate(startDate!)} to ${_formatDate(endDate!)}');
    } else if (startDate != null) {
      appliedFilters.add('From: ${_formatDate(startDate!)}');
    } else if (endDate != null) {
      appliedFilters.add('Until: ${_formatDate(endDate!)}');
    }

    if (appliedFilters.isEmpty) {
      return 'No filters applied';
    }

    return appliedFilters.join(', ');
  }

  /// Helper method to format dates
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Enum for sorting options
enum SortField { date, name, category }

/// Extension to provide human-readable names for sort fields
extension SortFieldExtension on SortField {
  String get displayName {
    switch (this) {
      case SortField.date:
        return 'Date';
      case SortField.name:
        return 'Item Name';
      case SortField.category:
        return 'Category';
    }
  }
}
