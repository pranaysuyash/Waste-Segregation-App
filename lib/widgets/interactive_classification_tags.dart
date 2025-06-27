import 'package:flutter/material.dart';
import '../models/waste_classification.dart';

/// Interactive widget to display classification tags with visual indicators
class InteractiveClassificationTags extends StatefulWidget {
  const InteractiveClassificationTags({
    super.key,
    required this.classification,
    this.maxTags = 5,
    this.showDescriptions = true,
    this.onTagTap,
  });

  final WasteClassification classification;
  final int maxTags;
  final bool showDescriptions;
  final Function(ClassificationTag)? onTagTap;

  @override
  State<InteractiveClassificationTags> createState() => _InteractiveClassificationTagsState();
}

class _InteractiveClassificationTagsState extends State<InteractiveClassificationTags>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int? _expandedTagIndex;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tags = widget.classification.getClassificationTags();
    
    if (tags.isEmpty) {
      return const SizedBox.shrink();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.label,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Environmental Tags',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildTagsGrid(context, tags),
              if (widget.showDescriptions && _expandedTagIndex != null)
                _buildTagDescription(context, tags[_expandedTagIndex!]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTagsGrid(BuildContext context, List<ClassificationTag> tags) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: tags.take(widget.maxTags).map((tag) {
        final index = tags.indexOf(tag);
        final isExpanded = _expandedTagIndex == index;
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: _buildTagChip(context, tag, index, isExpanded),
        );
      }).toList(),
    );
  }

  Widget _buildTagChip(
    BuildContext context, 
    ClassificationTag tag, 
    int index, 
    bool isExpanded,
  ) {
    final color = Color(tag.colorValue);
    final textColor = _getContrastColor(color);
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _expandedTagIndex = _expandedTagIndex == index ? null : index;
        });
        widget.onTagTap?.call(tag);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: isExpanded 
            ? Border.all(color: Colors.white, width: 2)
            : null,
          boxShadow: isExpanded
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getIconData(tag.icon),
              size: 16,
              color: textColor,
            ),
            const SizedBox(width: 4),
            Text(
              tag.label,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (widget.showDescriptions) ...[
              const SizedBox(width: 4),
              Icon(
                isExpanded ? Icons.expand_less : Icons.expand_more,
                size: 14,
                color: textColor,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTagDescription(BuildContext context, ClassificationTag tag) {
    final description = _getTagDescription(tag);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getIconData(tag.icon),
                size: 16,
                color: Color(tag.colorValue),
              ),
              const SizedBox(width: 6),
              Text(
                tag.label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Color(tag.colorValue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
          _buildTagActions(context, tag),
        ],
      ),
    );
  }

  Widget _buildTagActions(BuildContext context, ClassificationTag tag) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          _buildActionButton(
            context,
            'Learn More',
            Icons.info_outline,
            () => _showTagDetails(context, tag),
          ),
          const SizedBox(width: 8),
          if (_hasQuickAction(tag))
            _buildActionButton(
              context,
              _getQuickActionLabel(tag),
              _getQuickActionIcon(tag),
              () => _performQuickAction(context, tag),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 14),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  // Helper methods

  Color _getContrastColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'warning':
        return Icons.warning;
      case 'autorenew':
        return Icons.autorenew;
      case 'recycling':
        return Icons.recycling;
      case 'block':
        return Icons.block;
      case 'dangerous':
        return Icons.dangerous;
      case 'medical_services':
        return Icons.medical_services;
      case 'compost':
        return Icons.nature;
      case 'verified':
        return Icons.verified;
      case 'co2':
        return Icons.cloud;
      default:
        return Icons.label;
    }
  }

  String _getTagDescription(ClassificationTag tag) {
    switch (tag.label) {
      case 'Single-Use':
        return 'This item is designed for one-time use. Consider eco-friendly alternatives for future purchases.';
      case 'Multi-Use':
        return 'This item can be used multiple times. Clean and store properly to extend its lifespan.';
      case 'Fully Recyclable':
        return 'This item can be completely recycled through standard recycling programs. Clean before disposal.';
      case 'Partially Recyclable':
        return 'Some parts of this item can be recycled. Separate recyclable components when possible.';
      case 'Not Recyclable':
        return 'This item cannot be recycled through standard programs. Consider disposal alternatives.';
      case 'Hazardous':
        return 'This item contains materials that can be harmful to health or environment. Handle with care.';
      case 'Special Disposal':
        return 'This item requires special handling and cannot go in regular waste bins.';
      case 'Compostable':
        return 'This organic material can be composted to create nutrient-rich soil amendment.';
      case 'High CO₂ Impact':
        return 'This item has a significant carbon footprint. Consider lower-impact alternatives.';
      default:
        if (tag.label.startsWith('BBMP:')) {
          return 'This classification follows BBMP (Bangalore) waste management guidelines.';
        }
        return 'Environmental classification tag providing disposal guidance.';
    }
  }

  bool _hasQuickAction(ClassificationTag tag) {
    return tag.label == 'Single-Use' || 
           tag.label == 'Not Recyclable' || 
           tag.label.startsWith('BBMP:');
  }

  String _getQuickActionLabel(ClassificationTag tag) {
    if (tag.label == 'Single-Use' || tag.label == 'Not Recyclable') {
      return 'Find Alternatives';
    }
    if (tag.label.startsWith('BBMP:')) {
      return 'BBMP Guidelines';
    }
    return 'Take Action';
  }

  IconData _getQuickActionIcon(ClassificationTag tag) {
    if (tag.label == 'Single-Use' || tag.label == 'Not Recyclable') {
      return Icons.eco;
    }
    if (tag.label.startsWith('BBMP:')) {
      return Icons.gavel;
    }
    return Icons.arrow_forward;
  }

  void _showTagDetails(BuildContext context, ClassificationTag tag) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(_getIconData(tag.icon), color: Color(tag.colorValue)),
            const SizedBox(width: 8),
            Text(tag.label),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_getTagDescription(tag)),
            const SizedBox(height: 16),
            ..._getDetailedInfo(tag),
          ],
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

  List<Widget> _getDetailedInfo(ClassificationTag tag) {
    switch (tag.label) {
      case 'Single-Use':
        return [
          const Text('Impact:', style: TextStyle(fontWeight: FontWeight.bold)),
          const Text('• Increased waste generation'),
          const Text('• Higher resource consumption'),
          const Text('• Limited reuse potential'),
          const SizedBox(height: 8),
          const Text('Alternatives:', style: TextStyle(fontWeight: FontWeight.bold)),
          const Text('• Reusable containers'),
          const Text('• Refillable products'),
          const Text('• Durable materials'),
        ];
      case 'Hazardous':
        return [
          const Text('Safety Precautions:', style: TextStyle(fontWeight: FontWeight.bold)),
          const Text('• Wear protective equipment'),
          const Text('• Avoid direct contact'),
          const Text('• Store in safe location'),
          const Text('• Never mix with regular waste'),
        ];
      default:
        return [
          Text('Priority: ${tag.priority}'),
          Text('Color Code: ${tag.color}'),
        ];
    }
  }

  void _performQuickAction(BuildContext context, ClassificationTag tag) {
    if (tag.label == 'Single-Use' || tag.label == 'Not Recyclable') {
      _showAlternatives(context);
    } else if (tag.label.startsWith('BBMP:')) {
      _showBBMPGuidelines(context);
    }
  }

  void _showAlternatives(BuildContext context) {
    final alternatives = widget.classification.alternativeOptions ?? [];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.eco, color: Colors.green),
            SizedBox(width: 8),
            Text('Eco-Friendly Alternatives'),
          ],
        ),
        content: alternatives.isNotEmpty
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: alternatives.map((alt) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_right, size: 16),
                    const SizedBox(width: 4),
                    Expanded(child: Text(alt)),
                  ],
                ),
              )).toList(),
            )
          : const Text('Consider reusable or biodegradable alternatives when replacing this item.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showBBMPGuidelines(BuildContext context) {
    final regulations = widget.classification.localRegulations ?? {};
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.gavel, color: Colors.blue),
            SizedBox(width: 8),
            Text('BBMP Guidelines'),
          ],
        ),
        content: regulations.isNotEmpty
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: regulations.entries.map((entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key.replaceAll('_', ' ').toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    Text(entry.value),
                    const SizedBox(height: 4),
                  ],
                ),
              )).toList(),
            )
          : const Text('Follow BBMP waste segregation guidelines for Bangalore.'),
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

/// Enhanced tag widget with environmental impact indicator
class EnvironmentalImpactIndicator extends StatelessWidget {
  const EnvironmentalImpactIndicator({
    super.key,
    required this.classification,
    this.showScore = true,
  });

  final WasteClassification classification;
  final bool showScore;

  @override
  Widget build(BuildContext context) {
    final impact = classification.getEnvironmentalImpactScore();
    final color = _getImpactColor(impact);
    final level = _getImpactLevel(impact);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getImpactIcon(impact),
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            level,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (showScore) ...[
            const SizedBox(width: 4),
            Text(
              '(${impact.toStringAsFixed(1)})',
              style: TextStyle(
                color: color.withValues(alpha: 0.8),
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getImpactColor(double impact) {
    if (impact <= 3.0) return Colors.green;
    if (impact <= 5.0) return Colors.orange;
    if (impact <= 7.0) return Colors.deepOrange;
    return Colors.red;
  }

  String _getImpactLevel(double impact) {
    if (impact <= 2.0) return 'Very Low Impact';
    if (impact <= 3.5) return 'Low Impact';
    if (impact <= 5.5) return 'Moderate Impact';
    if (impact <= 7.5) return 'High Impact';
    return 'Very High Impact';
  }

  IconData _getImpactIcon(double impact) {
    if (impact <= 3.0) return Icons.eco;
    if (impact <= 5.0) return Icons.warning_amber;
    if (impact <= 7.0) return Icons.warning;
    return Icons.dangerous;
  }
}