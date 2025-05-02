import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/educational_content.dart';
import '../services/educational_content_service.dart';
import '../utils/constants.dart';
import 'content_detail_screen.dart';

class EducationalContentScreen extends StatefulWidget {
  final String? initialCategory;

  const EducationalContentScreen({
    super.key,
    this.initialCategory,
  });

  @override
  State<EducationalContentScreen> createState() =>
      _EducationalContentScreenState();
}

class _EducationalContentScreenState extends State<EducationalContentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategory;
  List<String> _allCategories = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _selectedCategory = widget.initialCategory;

    // Initialize all categories
    final educationalService =
        Provider.of<EducationalContentService>(context, listen: false);
    final allContent = educationalService.getAllContent();

    // Extract all unique categories
    final Set<String> categorySet = {};
    for (final content in allContent) {
      categorySet.addAll(content.categories);
    }

    _allCategories = ['All', ...categorySet.toList()..sort()];

    // Set initial tab based on initialCategory if provided
    if (widget.initialCategory != null) {
      // Find content type corresponding to category
      final categoryContent =
          educationalService.getContentByCategory(widget.initialCategory!);
      if (categoryContent.isNotEmpty) {
        // Get most common content type for this category
        Map<ContentType, int> typeCount = {};
        for (final content in categoryContent) {
          typeCount[content.type] = (typeCount[content.type] ?? 0) + 1;
        }
        ContentType? mostCommonType;
        int highestCount = 0;
        typeCount.forEach((type, count) {
          if (count > highestCount) {
            highestCount = count;
            mostCommonType = type;
          }
        });

        // Use null-aware operator to safely access the index
        final typeIndex = mostCommonType?.index;
        if (typeIndex != null &&
            _tabController.index >= 0 &&
            typeIndex < _tabController.length) {
          _tabController.index = typeIndex;
        }
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<EducationalContent> _getFilteredContent(BuildContext context) {
    final educationalService = Provider.of<EducationalContentService>(context);
    List<EducationalContent> filteredContent = [];

    // First filter by tab (content type)
    final contentType = ContentType.values[_tabController.index];
    filteredContent = educationalService.getContentByType(contentType);

    // Then filter by category if selected
    if (_selectedCategory != null && _selectedCategory != 'All') {
      filteredContent = filteredContent
          .where((content) => content.categories.contains(_selectedCategory))
          .toList();
    }

    // Then filter by search query if provided
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filteredContent = filteredContent
          .where((content) =>
              content.title.toLowerCase().contains(query) ||
              content.description.toLowerCase().contains(query) ||
              content.tags.any((tag) => tag.toLowerCase().contains(query)) ||
              content.categories
                  .any((category) => category.toLowerCase().contains(query)))
          .toList();
    }

    return filteredContent;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learn'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: 'Articles', icon: Icon(Icons.article)),
            Tab(text: 'Videos', icon: Icon(Icons.video_library)),
            Tab(text: 'Infographics', icon: Icon(Icons.image)),
            Tab(text: 'Quizzes', icon: Icon(Icons.quiz)),
            Tab(text: 'Tutorials', icon: Icon(Icons.menu_book)),
            Tab(text: 'Tips', icon: Icon(Icons.lightbulb_outline)),
          ],
          onTap: (_) {
            setState(() {});
          },
        ),
      ),
      body: Column(
        children: [
          // Search and filter bar
          Container(
            padding: const EdgeInsets.all(AppTheme.paddingRegular),
            child: Row(
              children: [
                // Search field
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.borderRadiusRegular),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),

                const SizedBox(width: AppTheme.paddingRegular),

                // Category filter dropdown
                DropdownButton<String>(
                  // Make sure the value exists in the items list
                  value: _allCategories.contains(_selectedCategory)
                      ? _selectedCategory
                      : 'All',
                  icon: const Icon(Icons.filter_list),
                  underline: Container(
                    height: 2,
                    color: AppTheme.primaryColor,
                  ),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCategory = newValue == 'All' ? null : newValue;
                    });
                  },
                  items: _allCategories
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Content list
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: ContentType.values.map((contentType) {
                final filteredContent = _getFilteredContent(context);

                if (filteredContent.isEmpty) {
                  return const Center(
                    child: Text('No content found matching your criteria'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(AppTheme.paddingRegular),
                  itemCount: filteredContent.length,
                  itemBuilder: (context, index) {
                    final content = filteredContent[index];
                    return _buildContentCard(content);
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentCard(EducationalContent content) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.paddingRegular),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ContentDetailScreen(contentId: content.id),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Content type badge and thumbnail
            Stack(
              children: [
                // Thumbnail (placeholder for now)
                Container(
                  height: 150,
                  width: double.infinity,
                  color: Colors.grey.shade300,
                  child: Icon(
                    content.icon,
                    size: 50,
                    color: Colors.grey.shade500,
                  ),
                ),

                // Content type badge
                Positioned(
                  top: AppTheme.paddingSmall,
                  left: AppTheme.paddingSmall,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.paddingSmall,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: content.getTypeColor(),
                      borderRadius:
                          BorderRadius.circular(AppTheme.borderRadiusSmall),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          content.icon,
                          size: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          content.type.toString().split('.').last,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: AppTheme.fontSizeSmall,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Premium badge if applicable
                if (content.isPremium)
                  Positioned(
                    top: AppTheme.paddingSmall,
                    right: AppTheme.paddingSmall,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.paddingSmall,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius:
                            BorderRadius.circular(AppTheme.borderRadiusSmall),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star,
                            size: 12,
                            color: Colors.white,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Premium',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // Content details
            Padding(
              padding: const EdgeInsets.all(AppTheme.paddingRegular),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    content.title,
                    style: const TextStyle(
                      fontSize: AppTheme.fontSizeMedium,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  // Description
                  Text(
                    content.description,
                    style: const TextStyle(
                      fontSize: AppTheme.fontSizeSmall,
                      color: AppTheme.textSecondaryColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: AppTheme.paddingSmall),

                  // Metadata
                  Row(
                    children: [
                      // Level indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius:
                              BorderRadius.circular(AppTheme.borderRadiusSmall),
                        ),
                        child: Text(
                          content.getLevelText(),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Duration
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: Colors.grey.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            content.getFormattedDuration(),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),

                      const Spacer(),

                      // Category chip
                      if (content.categories.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(content.categories.first)
                                .withOpacity(0.2),
                            borderRadius: BorderRadius.circular(
                                AppTheme.borderRadiusSmall),
                          ),
                          child: Text(
                            content.categories.first,
                            style: TextStyle(
                              fontSize: 10,
                              color:
                                  _getCategoryColor(content.categories.first),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Wet Waste':
        return AppTheme.wetWasteColor;
      case 'Dry Waste':
        return AppTheme.dryWasteColor;
      case 'Hazardous Waste':
        return AppTheme.hazardousWasteColor;
      case 'Medical Waste':
        return AppTheme.medicalWasteColor;
      case 'Non-Waste':
        return AppTheme.nonWasteColor;
      case 'General':
        return AppTheme.secondaryColor;
      case 'Sorting':
        return AppTheme.accentColor;
      case 'Composting':
        return Colors.green.shade800;
      case 'Recycling':
        return Colors.blue.shade700;
      case 'E-waste':
        return Colors.orange;
      case 'Plastic':
        return Colors.lightBlue;
      case 'Home Organization':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
