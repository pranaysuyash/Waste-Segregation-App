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
    
    return Card(
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
          child: Row(
            children: [
              // Thumbnail (if available)
              if (classification.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                  child: SizedBox(
                    width: 60,
                    height: 60,
                    child: _buildImage(),
                  ),
                ),
              
              // Gap between image and content
              if (classification.imageUrl != null)
                const SizedBox(width: AppTheme.paddingRegular),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Item name and date row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Item name
                        Expanded(
                          child: Text(
                            classification.itemName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: AppTheme.fontSizeRegular,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        
                        // Date
                        Text(
                          _formatDateForDisplay(classification.timestamp),
                          style: const TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontSize: AppTheme.fontSizeSmall,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Categories row
                    Row(
                      children: [
                        // Main category badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
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
                        
                        // Subcategory badge if available
                        if (classification.subcategory != null) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
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
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        
                        // Spacer
                        const Spacer(),
                        
                        // Properties indicators (recyclable, compostable, special disposal)
                        if (classification.isRecyclable == true)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Tooltip(
                              message: 'Recyclable',
                              child: Icon(
                                Icons.recycling,
                                size: 16,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        
                        if (classification.isCompostable == true)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Tooltip(
                              message: 'Compostable',
                              child: Icon(
                                Icons.eco,
                                size: 16,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        
                        if (classification.requiresSpecialDisposal == true)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Tooltip(
                              message: 'Special Disposal Required',
                              child: Icon(
                                Icons.warning_amber,
                                size: 16,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                        
                        // Arrow indicator
                        const Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
        return AppTheme.accentColor;
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
              height: 60,
              width: 60,
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
              // Handle errors better
              errorBuilder: (context, error, stackTrace) {
                debugPrint('Error loading web image: $error');
                return _buildImagePlaceholder();
              },
              // Cache images for better performance
              cacheWidth: 120, // 2x display size for high-DPI displays
              cacheHeight: 120,
            );
          }
        } catch (e) {
          debugPrint('Error processing web image data: $e');
          return _buildImagePlaceholder();
        }
      }
      
      // Handle regular URLs
      if (classification.imageUrl!.startsWith('http:') || 
          classification.imageUrl!.startsWith('https:')) {
        return Image.network(
          classification.imageUrl!,
          height: 60,
          width: 60,
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
            debugPrint('Error loading network image: $error');
            return _buildImagePlaceholder();
          },
          cacheWidth: 120,
          cacheHeight: 120,
        );
      }
      
      // If we got here, it's an unsupported image format for web
      return _buildImagePlaceholder();
    } 
    
    // For mobile platforms - handle file existence check properly
    try {
      final file = File(classification.imageUrl!);
      
      // Use FutureBuilder to check if the file exists before rendering
      return FutureBuilder<bool>(
        future: file.exists(),
        builder: (context, snapshot) {
          // Show placeholder while checking
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingPlaceholder();
          }
          
          // If file exists, show it
          if (snapshot.hasData && snapshot.data == true) {
            return Image.file(
              file,
              height: 60,
              width: 60,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('Error rendering image file: $error');
                return _buildImagePlaceholder();
              },
              cacheWidth: 120,
              cacheHeight: 120,
            );
          } 
          
          // File doesn't exist or check failed
          return _buildImagePlaceholder();
        },
      );
    } catch (e) {
      debugPrint('Error handling image file: $e');
      return _buildImagePlaceholder();
    }
  }
  
  /// Builds a loading placeholder while checking file existence
  Widget _buildLoadingPlaceholder() {
    return Container(
      height: 60,
      width: 60,
      color: Colors.grey.shade100,
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
          ),
        ),
      ),
    );
  }
  
  /// Builds a placeholder for missing images
  Widget _buildImagePlaceholder() {
    return Container(
      height: 60,
      width: 60,
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(
          Icons.image,
          size: 24,
          color: Colors.grey,
        ),
      ),
    );
  }
}