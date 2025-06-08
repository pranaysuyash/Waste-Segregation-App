import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/constants.dart';
import '../screens/educational_content_screen.dart';
import '../screens/history_screen.dart';

/// Interactive tag widget that can navigate to educational content or filter results
class InteractiveTag extends StatelessWidget {

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
  final String text;
  final Color color;
  final Color textColor;
  final VoidCallback? onTap;
  final String? category;
  final String? subcategory;
  final TagAction action;
  final IconData? icon;
  final bool isOutlined;

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
              color: color.withValues(alpha:0.3),
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
            Flexible(
              child: Text(
                text,
                style: TextStyle(
                  color: isOutlined ? color : textColor,
                  fontSize: AppTheme.fontSizeSmall,
                  fontWeight: FontWeight.bold,
                  // Add text shadow for better readability on colored backgrounds
                  shadows: isOutlined ? null : [
                    Shadow(
                      color: Colors.black.withValues(alpha:0.5),
                      offset: const Offset(1, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            // Add chevron icon to indicate interactivity
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              size: 14,
              color: isOutlined ? color : textColor.withValues(alpha:0.8),
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
      case TagAction.environmental:
        _showEnvironmentalDialog(context);
        break;
      case TagAction.location:
        _showLocationDialog(context);
        break;
      case TagAction.warning:
        _showWarningDialog(context);
        break;
      case TagAction.local:
        _showLocalInfoDialog(context);
        break;
      case TagAction.action:
        _showActionDialog(context);
        break;
      case TagAction.tip:
        _showTipDialog(context);
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

  /// Show environmental impact dialog
  void _showEnvironmentalDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.eco, color: Colors.green.shade600),
            const SizedBox(width: 8),
            const Text('Environmental Impact'),
          ],
        ),
        content: Text(_getEnvironmentalText()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
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

  /// Show location/facility information dialog
  void _showLocationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.location_on, color: Colors.teal.shade600),
            const SizedBox(width: 8),
            const Text('Nearby Facilities'),
          ],
        ),
        content: Text(_getLocationText()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _openMaps();
            },
            child: const Text('Get Directions'),
          ),
        ],
      ),
    );
  }

  /// Show warning dialog
  void _showWarningDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange.shade600),
            const SizedBox(width: 8),
            const Text('Important Notice'),
          ],
        ),
        content: Text(_getWarningText()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }

  /// Show local information dialog (BBMP schedules, etc.)
  void _showLocalInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.schedule, color: Colors.indigo.shade600),
            const SizedBox(width: 8),
            const Text('Local Information'),
          ],
        ),
        content: Text(_getLocalInfoText()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Show action required dialog
  void _showActionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.priority_high, color: Colors.red.shade600),
            const SizedBox(width: 8),
            const Text('Action Required'),
          ],
        ),
        content: Text(_getActionText()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  /// Show educational tip dialog
  void _showTipDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lightbulb, color: Colors.amber.shade600),
            const SizedBox(width: 8),
            const Text('Helpful Tip'),
          ],
        ),
        content: Text(_getTipText()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Thanks'),
          ),
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

  String _getEnvironmentalText() {
    if (text.contains('CO₂')) {
      return 'By properly disposing of this item, you\'re helping reduce carbon emissions. Every kilogram of CO₂ saved contributes to fighting climate change.';
    }
    return 'Proper disposal of this item has a positive environmental impact. Learn more about sustainable waste management practices.';
  }

  String _getLocationText() {
    return 'This facility accepts $category waste. Call ahead to confirm availability and operating hours. Some facilities may have special requirements.';
  }

  String _getWarningText() {
    if (text.contains('Avoid')) {
      return 'This is a common mistake that can contaminate recycling or cause disposal problems. Following proper procedures helps everyone.';
    }
    return 'Please pay attention to this important information for safe and proper waste disposal.';
  }

  String _getLocalInfoText() {
    if (text.contains('BBMP')) {
      return 'Bruhat Bengaluru Mahanagara Palike (BBMP) provides waste collection services. Check your area-specific schedule for collection timings.';
    }
    return 'This information is specific to the Bangalore area. Local waste management schedules and services may vary by location.';
  }

  String _getActionText() {
    return 'This action is recommended for proper disposal. Following these steps helps ensure the item is handled correctly and safely.';
  }

  String _getTipText() {
    return '${text.replaceFirst('Tip: ', '')}\n\nThis tip can help you dispose of waste more effectively and contribute to better environmental outcomes.';
  }
  Future<void> _openMaps() async {
    final query = Uri.encodeComponent(category ?? text);
    final Uri url = Uri.parse("https://www.google.com/maps/search/?api=1&query=$query");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("Could not launch maps for $query");
    }
  }

}

/// Enhanced tag collection widget for displaying multiple interactive tags
class InteractiveTagCollection extends StatelessWidget {

  const InteractiveTagCollection({
    super.key,
    required this.tags,
    this.maxTags,
    this.showViewMore = true,
  });
  final List<TagData> tags;
  final int? maxTags;
  final bool showViewMore;

  @override
  Widget build(BuildContext context) {
    // FIXED: Improved layout with better overflow handling
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate how many tags can fit in the available space
        final availableWidth = constraints.maxWidth;
        const estimatedTagWidth = 80.0; // Estimated average tag width
        final maxTagsPerRow = (availableWidth / estimatedTagWidth).floor().clamp(2, 6);
        
        // Determine which tags to show
        final tagsToShow = showViewMore && tags.length > maxTagsPerRow 
            ? tags.take(maxTagsPerRow - 1).toList() 
            : tags;
        final hiddenCount = showViewMore && tags.length > maxTagsPerRow 
            ? tags.length - (maxTagsPerRow - 1) 
            : 0;

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...tagsToShow.map((tag) => InteractiveTag(
              text: tag.text,
              color: tag.color,
              textColor: tag.textColor,
              category: tag.category,
              subcategory: tag.subcategory,
              action: tag.action,
              icon: tag.icon,
              isOutlined: tag.isOutlined,
              onTap: tag.onTap,
            )),
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
      },
    );
  }

  void _showAllTags(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('All Tags'),
        content: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: SingleChildScrollView(
            child: InteractiveTagCollection(
              tags: tags,
              showViewMore: false,
            ),
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
  final String text;
  final Color color;
  final Color textColor;
  final String? category;
  final String? subcategory;
  final TagAction action;
  final IconData? icon;
  final bool isOutlined;
  final VoidCallback? onTap;
}

/// Actions that tags can perform - Enhanced version
enum TagAction {
  educate,      // Navigate to educational content
  filter,       // Filter history/search results
  info,         // Show information dialog
  environmental, // Environmental impact information
  location,     // Location/facility information
  warning,      // Important warnings or alerts
  local,        // Local information (BBMP, schedules)
  action,       // Required actions
  tip,          // Educational tips
}

/// Enhanced difficulty levels for recycling/disposal
enum DifficultyLevel {
  easy,
  medium,
  hard,
  expert;
  
  Color get color {
    switch (this) {
      case DifficultyLevel.easy:
        return Colors.green;
      case DifficultyLevel.medium:
        return Colors.orange;
      case DifficultyLevel.hard:
        return Colors.red;
      case DifficultyLevel.expert:
        return Colors.purple;
    }
  }
  
  String get label {
    switch (this) {
      case DifficultyLevel.easy:
        return 'Easy';
      case DifficultyLevel.medium:
        return 'Medium';
      case DifficultyLevel.hard:
        return 'Hard';
      case DifficultyLevel.expert:
        return 'Expert';
    }
  }
}

/// Enhanced urgency levels
enum UrgencyLevel {
  low,
  medium,
  high,
  critical;
  
  Color get color {
    switch (this) {
      case UrgencyLevel.low:
        return Colors.green;
      case UrgencyLevel.medium:
        return Colors.blue;
      case UrgencyLevel.high:
        return Colors.orange;
      case UrgencyLevel.critical:
        return Colors.red;
    }
  }
  
  String get urgencyText {
    switch (this) {
      case UrgencyLevel.low:
        return 'No rush';
      case UrgencyLevel.medium:
        return 'This week';
      case UrgencyLevel.high:
        return 'Within 24h';
      case UrgencyLevel.critical:
        return 'Immediately';
    }
  }
}
class TagFactory {
  /// Create a category tag
  static TagData category(String category) {
    return TagData(
      text: category,
      color: _getCategoryColor(category),
      category: category,
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

  /// Create an environmental impact tag
  static TagData environmentalImpact(String impact, Color color) {
    return TagData(
      text: impact,
      color: color,
      action: TagAction.environmental,
      icon: Icons.eco,
    );
  }

  /// Create a recycling difficulty tag
  static TagData recyclingDifficulty(String text, DifficultyLevel level) {
    return TagData(
      text: '${level.label} - $text',
      color: level.color,
      action: TagAction.info,
      icon: Icons.build,
    );
  }

  /// Create a local information tag (BBMP schedules, etc.)
  static TagData localInfo(String info, IconData icon) {
    return TagData(
      text: info,
      color: Colors.indigo,
      action: TagAction.local,
      icon: icon,
    );
  }

  /// Create a nearby facility tag
  static TagData nearbyFacility(String distance, IconData icon) {
    return TagData(
      text: distance,
      color: Colors.teal,
      action: TagAction.location,
      icon: icon,
    );
  }

  /// Create an action required tag
  static TagData actionRequired(String action, Color color) {
    return TagData(
      text: action,
      color: color,
      action: TagAction.action,
      icon: Icons.priority_high,
    );
  }

  /// Create a time urgency tag
  static TagData timeUrgent(String message, UrgencyLevel level) {
    return TagData(
      text: '${level.urgencyText} - $message',
      color: level.color,
      action: TagAction.warning,
      icon: Icons.schedule,
    );
  }

  /// Create an educational tip tag
  static TagData didYouKnow(String tip, Color color) {
    return TagData(
      text: 'Tip: $tip',
      color: color,
      action: TagAction.tip,
      icon: Icons.lightbulb,
    );
  }

  /// Create a common mistake warning tag
  static TagData commonMistake(String mistake, Color color) {
    return TagData(
      text: 'Avoid: $mistake',
      color: color,
      action: TagAction.warning,
      icon: Icons.error_outline,
    );
  }

  /// Create a CO2 savings tag
  static TagData co2Savings(double kgCO2Saved) {
    return TagData(
      text: 'Saves ${kgCO2Saved.toStringAsFixed(1)}kg CO₂',
      color: Colors.green.shade600,
      action: TagAction.environmental,
      icon: Icons.cloud_off,
    );
  }

  /// Create a resource conservation tag
  static TagData resourceSaved(String resource, double amount, String unit) {
    return TagData(
      text: 'Saves ${amount.toStringAsFixed(1)}$unit $resource',
      color: Colors.blue.shade600,
      action: TagAction.environmental,
      icon: Icons.water_drop,
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
      case 'requires manual review':
        return AppTheme.manualReviewColor;
      default:
        return AppTheme.secondaryColor;
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
      case 'requires manual review':
        return Icons.help_outline;
      default:
        return Icons.category;
    }
  }
}
