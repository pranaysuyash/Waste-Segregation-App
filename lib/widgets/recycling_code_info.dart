import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Displays information about a recycling code (1-7) with description.
class RecyclingCodeInfoCard extends StatefulWidget {
  final String code;
  const RecyclingCodeInfoCard({super.key, required this.code});

  @override
  State<RecyclingCodeInfoCard> createState() => _RecyclingCodeInfoCardState();
}

class _RecyclingCodeInfoCardState extends State<RecyclingCodeInfoCard> {
  bool _isExpanded = false;
  
  Map<String, Map<String, String>> get recyclingCodesDetailed => {
    '1': {
      'name': 'PET (Polyethylene Terephthalate)',
      'examples': 'Water bottles, soft drink bottles, food containers',
      'recyclable': 'Yes - widely recyclable',
    },
    '2': {
      'name': 'HDPE (High-Density Polyethylene)', 
      'examples': 'Milk jugs, detergent bottles, yogurt containers',
      'recyclable': 'Yes - widely recyclable',
    },
    '3': {
      'name': 'PVC (Polyvinyl Chloride)',
      'examples': 'Food wrap, bottles for toiletries, medical equipment',
      'recyclable': 'Limited - check local facilities',
    },
    '4': {
      'name': 'LDPE (Low-Density Polyethylene)',
      'examples': 'Shopping bags, food wraps, squeeze bottles', 
      'recyclable': 'Limited - some stores accept bags',
    },
    '5': {
      'name': 'PP (Polypropylene)',
      'examples': 'Yogurt containers, bottle caps, straws',
      'recyclable': 'Growing acceptance - check locally',
    },
    '6': {
      'name': 'PS (Polystyrene)',
      'examples': 'Disposable cups, takeout containers, packing peanuts',
      'recyclable': 'Rarely accepted - avoid if possible',
    },
    '7': {
      'name': 'Other (Mixed plastics)',
      'examples': 'Water cooler bottles, some food containers',
      'recyclable': 'Varies - check with manufacturer',
    },
  };

  @override
  Widget build(BuildContext context) {
    final codeInfo = recyclingCodesDetailed[widget.code];
    
    if (codeInfo == null) {
      return Container(
        padding: const EdgeInsets.all(AppTheme.paddingRegular),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Unknown recycling code: ${widget.code}',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingRegular),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.secondaryColor,
                ),
                child: Text(
                  widget.code,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recycling Code',
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeSmall,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    Text(
                      codeInfo['name']!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: AppTheme.fontSizeMedium,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                ),
                onPressed: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
              ),
            ],
          ),
          
          if (_isExpanded) ...[
            const SizedBox(height: AppTheme.paddingRegular),
            
            // Examples section
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  width: 80,
                  child: Text(
                    'Examples:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: AppTheme.fontSizeSmall,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    codeInfo['examples']!,
                    style: const TextStyle(
                      fontSize: AppTheme.fontSizeSmall,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Recyclability section
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  width: 80,
                  child: Text(
                    'Recycling:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: AppTheme.fontSizeSmall,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    codeInfo['recyclable']!,
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeSmall,
                      color: _getRecyclabilityColor(codeInfo['recyclable']!),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              codeInfo['examples']!,
              style: const TextStyle(
                fontSize: AppTheme.fontSizeSmall,
                color: AppTheme.textSecondaryColor,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
  
  Color _getRecyclabilityColor(String recyclableText) {
    if (recyclableText.toLowerCase().contains('yes') || 
        recyclableText.toLowerCase().contains('widely')) {
      return Colors.green;
    } else if (recyclableText.toLowerCase().contains('limited') ||
               recyclableText.toLowerCase().contains('growing')) {
      return Colors.orange;
    } else if (recyclableText.toLowerCase().contains('rarely') ||
               recyclableText.toLowerCase().contains('avoid')) {
      return Colors.red;
    }
    return AppTheme.textSecondaryColor;
  }
}