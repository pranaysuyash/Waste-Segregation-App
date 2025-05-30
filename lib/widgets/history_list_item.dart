import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/waste_classification.dart';
import '../utils/constants.dart';

/// A simplified version of ClassificationCard for list views in the history screen
class HistoryListItem extends StatelessWidget {
  final WasteClassification classification;
  final VoidCallback onTap;
  
  const HistoryListItem({
    super.key,
    required this.classification,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final Color categoryColor = _getCategoryColor();
    
    return Semantics(
      button: true,
      label: 'Classification result for ${classification.itemName}, ${classification.category}',
      hint: 'Tap to view details',
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(
          vertical: AppTheme.paddingSmall, 
          horizontal: AppTheme.paddingRegular
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
          side: BorderSide(color: categoryColor.withOpacity(0.3), width: 1),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.paddingRegular),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Item name, confidence, and thumbnail
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Content area (item name + confidence)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Item name with tooltip for long names
                          Tooltip(
                            message: classification.itemName,
                            child: Text(
                              classification.itemName,
                              style: const TextStyle(
                                fontSize: AppTheme.fontSizeMedium,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimaryColor,
                              ),
                              maxLines: 2, // Allow 2 lines for long names
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          
                          const SizedBox(height: 4),
                          
                          // Date and confidence row
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: AppTheme.textSecondaryColor,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _formatDateForDisplay(classification.timestamp),
                                  style: const TextStyle(
                                    color: AppTheme.textSecondaryColor,
                                    fontSize: AppTheme.fontSizeSmall,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Confidence badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _getConfidenceColor().withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                                  border: Border.all(
                                    color: _getConfidenceColor(),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  '${((classification.confidence ?? 0.0) * 100).round()}%',
                                  style: TextStyle(
                                    color: _getConfidenceColor(),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Thumbnail (if available)
                    if (classification.imageUrl != null) ...[
                      const SizedBox(width: AppTheme.paddingRegular),
                      Semantics(
                        image: true,
                        label: 'Thumbnail image of ${classification.itemName}',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                          child: SizedBox(
                            width: 50,
                            height: 50,
                            child: _buildImage(),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Tags row with proper wrapping
                _buildTagsSection(categoryColor),
                
                const SizedBox(height: 8),
                
                // Properties indicators row
                _buildPropertiesRow(),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  /// Builds the tags section with proper wrapping to prevent overflow
  Widget _buildTagsSection(Color categoryColor) {
    final List<Widget> tags = [];
    
    // Main category tag
    tags.add(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: categoryColor,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
        ),
        child: Text(
          classification.category,
          style: const TextStyle(
            color: Colors.white,
            fontSize: AppTheme.fontSizeSmall,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
    
    // Subcategory tag if available
    if (classification.subcategory != null) {
      tags.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
            border: Border.all(
              color: categoryColor.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Text(
            classification.subcategory!,
            style: TextStyle(
              color: categoryColor,
              fontSize: AppTheme.fontSizeSmall,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }
    
    // Material type tag if available
    if (classification.materialType != null) {
      tags.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Text(
            classification.materialType!,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: AppTheme.fontSizeSmall,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }
    
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: tags,
    );
  }
  
  /// Builds the properties indicators row
  Widget _buildPropertiesRow() {
    final List<Widget> indicators = [];
    
    if (classification.isRecyclable == true) {
      indicators.add(
        Tooltip(
          message: 'Recyclable',
          child: Icon(
            Icons.recycling,
            size: 16,
            color: Colors.blue,
            semanticLabel: 'Recyclable',
          ),
        ),
      );
    }
    
    if (classification.isCompostable == true) {
      indicators.add(
        Tooltip(
          message: 'Compostable',
          child: Icon(
            Icons.eco,
            size: 16,
            color: Colors.green,
            semanticLabel: 'Compostable',
          ),
        ),
      );
    }
    
    if (classification.requiresSpecialDisposal == true) {
      indicators.add(
        Tooltip(
          message: 'Special Disposal Required',
          child: Icon(
            Icons.warning_amber,
            size: 16,
            color: Colors.orange,
            semanticLabel: 'Special disposal required',
          ),
        ),
      );
    }
    
    return Row(
      children: [
        ...indicators.map((indicator) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: indicator,
        )),
        const Spacer(),
        Icon(
          Icons.chevron_right,
          size: 18,
          color: AppTheme.textSecondaryColor,
          semanticLabel: 'View details',
        ),
      ],
    );
  }
  
  /// Gets the category color for styling
  Color _getCategoryColor() {
    switch (classification.category.toLowerCase()) {
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
  
  /// Gets the confidence color based on confidence level
  Color _getConfidenceColor() {
    final confidence = classification.confidence ?? 0.0;
    if (confidence >= 0.8) {
      return Colors.green;
    } else if (confidence >= 0.6) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
  
  /// Formats the date for display
  String _formatDateForDisplay(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateToCheck = DateTime(date.year, date.month, date.day);
    
    if (dateToCheck == today) {
      return 'Today, ${_formatTime(date)}';
    } else if (dateToCheck == yesterday) {
      return 'Yesterday, ${_formatTime(date)}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
  
  /// Formats time as HH:MM
  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
  
  /// Builds the image widget based on platform with improved error handling
  Widget _buildImage() {
    if (classification.imageUrl == null) {
      return _buildImagePlaceholder();
    }
    
    // For web platform
    if (kIsWeb) {
      // Handle web image formats (data URLs)
      if (classification.imageUrl!.startsWith('web_image:')) {
        try {
          // Extract the data URL
          final dataUrl = classification.imageUrl!.substring('web_image:'.length);
          
          // Check if it's a valid data URL
          if (dataUrl.startsWith('data:image')) {
            // Create Image widget from data URL
            return Image.network(
              dataUrl,
              height: 50,
              width: 50,
              fit: BoxFit.cover,
              // Fade-in animation for smoother loading
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if (wasSynchronouslyLoaded) return child;
                return AnimatedOpacity(
                  opacity: frame == null ? 0 : 1,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: child,
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return _buildImagePlaceholder();
              },
            );
          }
        } catch (e) {
          return _buildImagePlaceholder();
        }
      }
      
      // For regular web URLs
      return Image.network(
        classification.imageUrl!,
        height: 50,
        width: 50,
        fit: BoxFit.cover,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) return child;
          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: child,
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildImagePlaceholder();
        },
      );
    }
    
    // For mobile platforms (file paths)
    final file = File(classification.imageUrl!);
    if (file.existsSync()) {
      return Image.file(
        file,
        height: 50,
        width: 50,
        fit: BoxFit.cover,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) return child;
          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: child,
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildImagePlaceholder();
        },
      );
    }
    
    return _buildImagePlaceholder();
  }
  
  /// Builds a placeholder when image is not available
  Widget _buildImagePlaceholder() {
    return Container(
      height: 50,
      width: 50,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
      ),
      child: Icon(
        Icons.image_not_supported,
        color: Colors.grey.shade400,
        size: 24,
      ),
    );
  }
}