import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/waste_classification.dart';
import '../utils/constants.dart';

class ClassificationCard extends StatelessWidget {
  final WasteClassification classification;
  final VoidCallback? onShare;
  final VoidCallback? onSave;

  const ClassificationCard({
    super.key,
    required this.classification,
    this.onShare,
    this.onSave,
  });

  /// Helper method to build the image widget based on platform with improved error handling
  Widget _buildImage(String imageUrl) {
    // For web platform
    if (kIsWeb) {
      // Handle web image formats (data URLs)
      if (imageUrl.startsWith('web_image:')) {
        try {
          // Extract the data URL
          final dataUrl = imageUrl.substring('web_image:'.length);
          
          // Check if it's a valid data URL
          if (dataUrl.startsWith('data:image')) {
            // Create Image widget from data URL
            return Image.network(
              dataUrl,
              height: 200,
              width: double.infinity,
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
              cacheWidth: 600, // 3x display size for high-DPI displays
              cacheHeight: 400,
            );
          }
        } catch (e) {
          debugPrint('Error processing web image data: $e');
          return _buildImagePlaceholder();
        }
      }
      
      // Handle regular URLs
      if (imageUrl.startsWith('http:') || imageUrl.startsWith('https:')) {
        return Image.network(
          imageUrl,
          height: 200,
          width: double.infinity,
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
          cacheWidth: 600,
          cacheHeight: 400,
        );
      }
      
      // If we got here, it's an unsupported image format for web
      return _buildImagePlaceholder();
    } 
    
    // For mobile platforms - handle file existence check properly
    try {
      final file = File(imageUrl);
      
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
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('Error rendering image file: $error');
                return _buildImagePlaceholder();
              },
              cacheWidth: 600,
              cacheHeight: 400,
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
      height: 200,
      width: double.infinity,
      color: Colors.grey.shade100,
      child: const Center(
        child: SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 200,
      width: double.infinity,
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(
          Icons.image,
          size: 64,
          color: Colors.grey,
        ),
      ),
    );
  }

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

  // This is now replaced by the improved version defined above

  String _getExamples() {
    // Try to get subcategory examples first, falling back to category examples if not available
    if (classification.subcategory != null &&
        WasteInfo.subcategoryExamples.containsKey(classification.subcategory)) {
      return WasteInfo.subcategoryExamples[classification.subcategory]!;
    }
    return WasteInfo.categoryExamples[classification.category] ??
        'No examples available.';
  }

  String _getDisposalInstructions() {
    // Try to get subcategory disposal instructions first, falling back to category instructions
    if (classification.subcategory != null &&
        WasteInfo.subcategoryDisposal.containsKey(classification.subcategory)) {
      return WasteInfo.subcategoryDisposal[classification.subcategory]!;
    }
    return WasteInfo.disposalInstructions[classification.category] ??
        'Dispose according to local guidelines.';
  }

  // Helper method to create property badges
  Widget _buildPropertyBadge(IconData icon, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: AppTheme.fontSizeSmall,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color categoryColor = _getCategoryColor();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
        side: BorderSide(color: categoryColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image section
          if (classification.imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppTheme.borderRadiusLarge - 2),
                topRight: Radius.circular(AppTheme.borderRadiusLarge - 2),
              ),
              child: _buildImage(classification.imageUrl!),
            ),

          // Item details
          Padding(
            padding: const EdgeInsets.all(AppTheme.paddingRegular),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item name
                Row(
                  children: [
                    const Icon(Icons.category),
                    const SizedBox(width: 8),
                    const Text(
                      AppStrings.identifiedAs,
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeRegular,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        classification.itemName,
                        style: const TextStyle(
                          fontSize: AppTheme.fontSizeMedium,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppTheme.paddingRegular),

                // Category and subcategory badges
                Row(
                  children: [
                    // Main category badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.paddingRegular,
                        vertical: AppTheme.paddingSmall,
                      ),
                      decoration: BoxDecoration(
                        color: categoryColor,
                        borderRadius:
                            BorderRadius.circular(AppTheme.borderRadiusSmall),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.recycling,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            classification.category,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: AppTheme.fontSizeRegular,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Subcategory badge if available
                    if (classification.subcategory != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.paddingRegular,
                          vertical: AppTheme.paddingSmall,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(AppTheme.borderRadiusSmall),
                          border:
                              Border.all(color: categoryColor.withOpacity(0.5)),
                        ),
                        child: Text(
                          classification.subcategory!,
                          style: TextStyle(
                            color: categoryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: AppTheme.fontSizeSmall,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                // Material type and recycling code if available
                if (classification.materialType != null ||
                    classification.recyclingCode != null) ...[
                  const SizedBox(height: AppTheme.paddingRegular),
                  Row(
                    children: [
                      // Material type
                      if (classification.materialType != null)
                        Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.science,
                                  size: 16, color: categoryColor),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Material: ${classification.materialType}',
                                  style: const TextStyle(
                                    fontSize: AppTheme.fontSizeSmall,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Recycling code
                      if (classification.recyclingCode != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: categoryColor),
                          ),
                          child: Text(
                            classification.recyclingCode!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: categoryColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],

                // Properties indicators (recyclable, compostable, special disposal)
                if (classification.isRecyclable != null ||
                    classification.isCompostable != null ||
                    classification.requiresSpecialDisposal != null) ...[
                  const SizedBox(height: AppTheme.paddingRegular),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      if (classification.isRecyclable == true)
                        _buildPropertyBadge(
                            Icons.recycling, 'Recyclable', Colors.blue),
                      if (classification.isCompostable == true)
                        _buildPropertyBadge(
                            Icons.eco, 'Compostable', Colors.green),
                      if (classification.requiresSpecialDisposal == true)
                        _buildPropertyBadge(Icons.warning_amber,
                            'Special Disposal', Colors.orange),
                    ],
                  ),
                ],

                const SizedBox(height: AppTheme.paddingRegular),

                // Explanation
                const Text(
                  AppStrings.explanation,
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeRegular,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  classification.explanation,
                  style: const TextStyle(fontSize: AppTheme.fontSizeRegular),
                ),

                // Disposal method if available
                if (classification.disposalMethod != null) ...[
                  const SizedBox(height: AppTheme.paddingRegular),
                  const Text(
                    'Disposal Instructions',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeRegular,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    classification.disposalMethod!,
                    style: const TextStyle(fontSize: AppTheme.fontSizeRegular),
                  ),
                ],

                const SizedBox(height: AppTheme.paddingRegular),

                // Disposal instructions
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppTheme.paddingRegular),
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.1),
                    borderRadius:
                        BorderRadius.circular(AppTheme.borderRadiusSmall),
                    border: Border.all(color: categoryColor.withOpacity(0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: categoryColor),
                          const SizedBox(width: 8),
                          Text(
                            'How to dispose',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: categoryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(_getDisposalInstructions()),
                      const SizedBox(height: 8),
                      Text(
                        'Examples: ${_getExamples()}',
                        style: const TextStyle(
                          fontSize: AppTheme.fontSizeSmall,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppTheme.paddingRegular),

                // Action buttons
                if (onShare != null || onSave != null)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (onSave != null)
                          OutlinedButton.icon(
                            onPressed: onSave,
                            icon: const Icon(Icons.save),
                            label: const Text(AppStrings.saveResult),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: categoryColor,
                              side: BorderSide(color: categoryColor),
                            ),
                          ),
                        if (onSave != null && onShare != null)
                          const SizedBox(width: AppTheme.paddingRegular),
                        if (onShare != null)
                          ElevatedButton.icon(
                            onPressed: onShare,
                            icon: const Icon(Icons.share),
                            label: const Text(AppStrings.shareResult),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: categoryColor,
                              foregroundColor: Colors.white,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}