import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/educational_content.dart';
import '../services/educational_content_service.dart';
import '../services/ad_service.dart';
import '../utils/constants.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/animations/educational_animations.dart';
import 'content_detail_screen.dart';

class EducationalContentScreen extends StatefulWidget {

  const EducationalContentScreen({
    super.key,
    this.initialCategory,
    this.initialSubcategory,
  });
  final String? initialCategory;
  final String? initialSubcategory;

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

    final educationalService =
        Provider.of<EducationalContentService>(context, listen: false);
    final allContent = educationalService.getAllContent();
    final categorySet = <String>{};
    for (final content in allContent) {
      categorySet.addAll(content.categories);
    }
    _allCategories = ['All', ...categorySet.toList()..sort()];

    if (widget.initialCategory != null) {
      final categoryContent =
          educationalService.getContentByCategory(widget.initialCategory!);
      if (categoryContent.isNotEmpty) {
        final typeCount = <ContentType, int>{};
        for (final content in categoryContent) {
          typeCount[content.type] = (typeCount[content.type] ?? 0) + 1;
        }
        ContentType? mostCommonType;
        var highestCount = 0;
        typeCount.forEach((type, count) {
          if (count > highestCount) {
            highestCount = count;
            mostCommonType = type;
          }
        });
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
    var filteredContent = <EducationalContent>[];
    final contentType = ContentType.values[_tabController.index];
    filteredContent = educationalService.getContentByType(contentType);
    if (_selectedCategory != null && _selectedCategory != 'All') {
      filteredContent = filteredContent
          .where((content) => content.categories.contains(_selectedCategory))
          .toList();
    }
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
    final adService = Provider.of<AdService>(context, listen: false);
    adService.setInClassificationFlow(false);
    adService.setInEducationalContent(true);
    adService.setInSettings(false);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learn'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
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
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.paddingRegular),
                child: Row(
                  children: [
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
                          contentPadding: const EdgeInsets.symmetric(),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: AppTheme.paddingRegular),
                    DropdownButton<String>(
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
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: ContentType.values.map((contentType) {
                    final filteredContent = _getFilteredContent(context);
                    if (filteredContent.isEmpty) {
                      return const Center(
                        child: ContentDiscoveryWidget(
                          child: Text('No content found'),
                        ),
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
          const BannerAdWidget(showAtBottom: true),
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
            Stack(
              children: [
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
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppTheme.paddingRegular),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  Row(
                    children: [
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
                            fontSize: 12,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.paddingSmall),
                      // Icon(
                      //   Icons.visibility,
                      //   size: 12,
                      //   color: Colors.grey.shade500,
                      // ),
                      // const SizedBox(width: 2),
                      // Text(
                      //   '${content.viewCount} views',
                      //   style: TextStyle(
                      //     fontSize: 10,
                      //     color: Colors.grey.shade600,
                      //   ),
                      // ),
                      const Spacer(),
                      Text(
                        content.getFormattedDuration(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
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


}
