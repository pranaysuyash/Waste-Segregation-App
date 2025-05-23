import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../screens/educational_content_screen.dart';
import '../screens/history_screen.dart';

/// Interactive tag widget that can navigate to educational content or filter results
class InteractiveTag extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;
  final VoidCallback? onTap;
  final String? category;
  final String? subcategory;
  final TagAction action;
  final IconData? icon;
  final bool isOutlined;

  const InteractiveTag({
    super.key,
    required this.text,
    required this.color,
    this.textColor = Colors.white,
    this.onTap,
    this.category,
    this.subcategory,
    this.action = TagAction.educate,
    this.icon,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _handleTap(context),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isOutlined ? Colors.transparent : color,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
          border: Border.all(
            color: color,
            width: isOutlined ? 2 : 0,
          ),
          // Add shadow for better depth and readability
          boxShadow: isOutlined ? null : [
            BoxShadow(
              color: color.withOpacity(0.3),
              offset: const Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isOutlined ? color : textColor,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              text,
              style: TextStyle(
                color: isOutlined ? color : textColor,
                fontSize: AppTheme.fontSizeSmall,
                fontWeight: FontWeight.bold,
                // Add text shadow for better readability on colored backgrounds
                shadows: isOutlined ? null : [
                  Shadow(
                    color: Colors.black.withOpacity(0.5),
                    offset: const Offset(1, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
            // Add chevron icon to indicate interactivity
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              size: 14,
              color: isOutlined ? color : textColor.withOpacity(0.8),
            ),
          ],
        ),
      ),
    );
  }

  void _handleTap(BuildContext context) {
    if (onTap != null) {
      onTap!();
      return;
    }

    switch (action) {
      case TagAction.educate:
        _navigateToEducation(context);
        break;
      case TagAction.filter:
        _navigateToFilteredHistory(context);
        break;
      case TagAction.info:
        _showInfoDialog(context);
        break;
    }
  }

  void _navigateToEducation(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EducationalContentScreen(
          initialCategory: category ?? text,
          initialSubcategory: subcategory,
        ),
      ),
    );
  }

  void _navigateToFilteredHistory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HistoryScreen(
          filterCategory: category ?? text,
          filterSubcategory: subcategory,
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('About $text'),
        content: Text(_getInfoText()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (category != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToEducation(context);
              },
              child: const Text('Learn More'),
            ),
        ],
      ),
    );
  }

  String _getInfoText() {
    // Get information from WasteInfo constants
    if (category != null) {
      final examples = WasteInfo.categoryExamples[category];
      final disposal = WasteInfo.disposalInstructions[category];
      
      if (examples != null && disposal != null) {
        return 'Examples: $examples\n\nDisposal: $disposal';
      }
    }
    
    // Fallback information
    return 'Tap "Learn More" to discover educational content about $text and proper waste management practices.';
  }
}

/// Enhanced tag collection widget for displaying multiple interactive tags
class InteractiveTagCollection extends StatelessWidget {
  final List<TagData> tags;
  final int? maxTags;
  final bool showViewMore;

  const InteractiveTagCollection({
    super.key,
    required this.tags,
    this.maxTags,
    this.showViewMore = true,
  });

  @override
  Widget build(BuildContext context) {
    final displayTags = maxTags != null && tags.length > maxTags! 
        ? tags.take(maxTags!).toList()
        : tags;
    
    final hiddenCount = tags.length - displayTags.length;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...displayTags.map((tagData) => InteractiveTag(
          text: tagData.text,
          color: tagData.color,
          textColor: tagData.textColor,
          category: tagData.category,
          subcategory: tagData.subcategory,
          action: tagData.action,
          icon: tagData.icon,
          isOutlined: tagData.isOutlined,
          onTap: tagData.onTap,
        )),
        
        // Show "View More" button if there are hidden tags
        if (hiddenCount > 0 && showViewMore)
          GestureDetector(
            onTap: () => _showAllTags(context),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '+$hiddenCount more',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: AppTheme.fontSizeSmall,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.expand_more,
                    size: 14,
                    color: Colors.grey.shade700,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _showAllTags(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('All Tags'),
        content: SizedBox(
          width: double.maxFinite,
          child: InteractiveTagCollection(
            tags: tags,
            showViewMore: false,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// Data class for tag configuration
class TagData {
  final String text;
  final Color color;
  final Color textColor;
  final String? category;
  final String? subcategory;
  final TagAction action;
  final IconData? icon;
  final bool isOutlined;
  final VoidCallback? onTap;

  const TagData({
    required this.text,
    required this.color,
    this.textColor = Colors.white,
    this.category,
    this.subcategory,
    this.action = TagAction.educate,
    this.icon,
    this.isOutlined = false,
    this.onTap,
  });
}

/// Actions that tags can perform
enum TagAction {
  educate,  // Navigate to educational content
  filter,   // Filter history/search results
  info,     // Show information dialog
}

/// Helper class to create common tag configurations
class TagFactory {
  /// Create a category tag
  static TagData category(String category) {
    return TagData(
      text: category,
      color: _getCategoryColor(category),
      category: category,
      action: TagAction.educate,
      icon: _getCategoryIcon(category),
    );
  }

  /// Create a subcategory tag
  static TagData subcategory(String subcategory, String parentCategory) {
    return TagData(
      text: subcategory,
      color: _getCategoryColor(parentCategory),
      category: parentCategory,
      subcategory: subcategory,
      action: TagAction.educate,
      isOutlined: true,
    );
  }

  /// Create a material type tag
  static TagData material(String material) {
    return TagData(
      text: material,
      color: Colors.deepPurple,
      action: TagAction.info,
      icon: Icons.science,
    );
  }

  /// Create a property tag (recyclable, compostable, etc.)
  static TagData property(String property, bool value) {
    return TagData(
      text: property,
      color: value ? Colors.green : Colors.red,
      action: TagAction.info,
      icon: value ? Icons.check_circle : Icons.cancel,
    );
  }

  /// Create a filter tag for history
  static TagData filter(String text, String category, {String? subcategory}) {
    return TagData(
      text: text,
      color: Colors.blue,
      category: category,
      subcategory: subcategory,
      action: TagAction.filter,
      icon: Icons.filter_list,
    );
  }

  static Color _getCategoryColor(String category) {
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
        return AppTheme.accentColor;
    }
  }

  static IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'wet waste':
        return Icons.eco;
      case 'dry waste':
        return Icons.recycling;
      case 'hazardous waste':
        return Icons.warning;
      case 'medical waste':
        return Icons.medical_services;
      case 'non-waste':
        return Icons.refresh;
      default:
        return Icons.category;
    }
  }
}
