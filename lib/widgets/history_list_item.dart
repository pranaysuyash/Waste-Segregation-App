import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/waste_classification.dart';
import '../utils/constants.dart';
import '../services/enhanced_image_service.dart';
import 'classification_feedback_widget.dart';
import '../utils/waste_app_logger.dart';

/// A simplified version of ClassificationCard for list views in the history screen
class HistoryListItem extends StatelessWidget {
  
  const HistoryListItem({
    super.key,
    required this.classification,
    required this.onTap,
    required this.onFeedbackSubmitted,
    this.showFeedbackButton = true,
  });

  final WasteClassification classification;
  final VoidCallback onTap;
  final Function(WasteClassification) onFeedbackSubmitted;
  final bool showFeedbackButton;
  
  @override
  Widget build(BuildContext context) {
    final categoryColor = _getCategoryColor();
    
    return Semantics(
      button: true,
      label: 'Classification result for ${classification.itemName}, ${classification.category}',
      hint: 'Tap to view details',
      child: Card(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        elevation: 2,
        margin: const EdgeInsets.symmetric(
          vertical: AppTheme.paddingSmall, 
          horizontal: AppTheme.paddingRegular
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
          side: BorderSide(color: categoryColor.withValues(alpha:0.3)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.paddingSmall),
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
                              const Icon(
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
                                  color: _getConfidenceColor().withValues(alpha:0.2),
                                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                                  border: Border.all(
                                    color: _getConfidenceColor(),
                                  ),
                                ),
                                child: Text(
                                  '${((classification.confidence ?? 0.0) * 100).round()}%',
                                  style: TextStyle(
                                    color: _getConfidenceColor(),
                                    fontSize: 12,
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
                      const SizedBox(width: AppTheme.paddingSmall),
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
                
                const SizedBox(height: 4),
                
                // Tags row with proper wrapping
                _buildTagsSection(categoryColor),
                
                const SizedBox(height: 4),
                
                // Properties indicators row
                _buildPropertiesRow(context),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  /// Builds the tags section with proper wrapping to prevent overflow
  Widget _buildTagsSection(Color categoryColor) {
    final tags = <Widget>[];
    
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
            color: Colors.black.withValues(alpha:0.05),
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
            border: Border.all(
              color: categoryColor.withValues(alpha:0.5),
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
  Widget _buildPropertiesRow(BuildContext context) {
    final indicators = <Widget>[];
    
    if (classification.isRecyclable == true) {
      indicators.add(
        const Tooltip(
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
        const Tooltip(
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
        const Tooltip(
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
        if (showFeedbackButton)
          FeedbackButton(
            classification: classification,
            onFeedbackSubmitted: onFeedbackSubmitted,
          ),
        const Icon(
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
      case 'requires manual review':
        return AppTheme.manualReviewColor;
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
    // Try relative path first (new approach)
    if (classification.imageRelativePath != null) {
      return FutureBuilder<String>(
        future: _getFullImagePath(classification.imageRelativePath!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildImagePlaceholder();
          }
          if (snapshot.hasData) {
            final file = File(snapshot.data!);
            return FutureBuilder<bool>(
              future: file.exists(),
              builder: (context, existsSnapshot) {
                if (existsSnapshot.connectionState == ConnectionState.waiting) {
                  return _buildImagePlaceholder();
                }
                if (existsSnapshot.hasData && existsSnapshot.data == true) {
                  return Image.file(
                    file,
                    height: 50,
                    width: 50,
                    fit: BoxFit.cover,
                    cacheHeight: 90, // Optimize memory usage
                    errorBuilder: (context, error, stackTrace) {
                      WasteAppLogger.severe('Error occurred', null, null, {'service': 'widget', 'file': 'history_list_item'});
                      return _buildImagePlaceholder();
                    },
                  );
                }
                WasteAppLogger.info('Operation completed', null, null, {'service': 'widget', 'file': 'history_list_item'});
                return _buildImagePlaceholder();
              },
            );
          }
          return _buildImagePlaceholder();
        },
      );
    }
    
    // ---------- NEW fallback ----------
    // If local file missing but Firestore doc has imageUrl (remote URL)
    if (classification.imageRelativePath != null &&
        classification.imageUrl != null &&
        classification.imageUrl!.startsWith('http')) {
      return FutureBuilder<Uint8List?>(
        future: EnhancedImageService()
            .fetchImageWithRetry(classification.imageUrl!),
        builder: (context, snap) {
          if (!snap.hasData) return _buildImagePlaceholder();
          // Persist to disk so next cold start is instant
          _persistBytes(
            snap.data!,
            classification.imageRelativePath!,
          );
          return Image.memory(snap.data!, fit: BoxFit.cover);
        },
      );
    }
    // -------- END new code ---------
    
    // Fallback to legacy absolute path logic
    final url = classification.imageUrl;
    WasteAppLogger.info('Operation completed', null, null, {'service': 'widget', 'file': 'history_list_item'});
    if (url == null) {
      WasteAppLogger.info('Operation completed', null, null, {'service': 'widget', 'file': 'history_list_item'});
      return _buildImagePlaceholder();
    }

    // For web platform
    if (kIsWeb) {
      if (url.startsWith('web_image:')) {
        try {
          final dataUrl = url.substring('web_image:'.length);
          if (dataUrl.startsWith('data:image')) {
            return Image.network(
              dataUrl,
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
                WasteAppLogger.severe('Error occurred', null, null, {'service': 'widget', 'file': 'history_list_item'});
                return _buildImagePlaceholder();
              },
            );
          } else {
            WasteAppLogger.info('Operation completed', null, null, {'service': 'widget', 'file': 'history_list_item'});
          }
        } catch (e) {
          WasteAppLogger.info('Operation completed', null, null, {'service': 'widget', 'file': 'history_list_item'});
        }
        return _buildImagePlaceholder();
      }

      if (url.startsWith('http')) {
        return FutureBuilder<Uint8List?>(
          future: EnhancedImageService().fetchImageWithRetry(url),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildImagePlaceholder();
            }
            if (snapshot.hasData) {
              return Image.memory(
                snapshot.data!,
                height: 50,
                width: 50,
                fit: BoxFit.cover,
              );
            }
            WasteAppLogger.severe('Error occurred', null, null, {'service': 'widget', 'file': 'history_list_item'});
            return _buildImagePlaceholder();
          },
        );
      }

      return _buildImagePlaceholder();
    }

    // For mobile platforms (file paths)
    final file = File(url);
    return FutureBuilder<bool>(
      future: file.exists(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildImagePlaceholder();
        }
        if (snapshot.hasData && snapshot.data == true) {
          return Image.file(
            file,
            height: 50,
            width: 50,
            fit: BoxFit.cover,
            cacheHeight: 90, // Optimize memory usage
            errorBuilder: (context, error, stackTrace) {
              WasteAppLogger.severe('Error occurred', null, null, {'service': 'widget', 'file': 'history_list_item'});
              return _buildImagePlaceholder();
            },
          );
        }
        WasteAppLogger.info('Operation completed', null, null, {'service': 'widget', 'file': 'history_list_item'});
        return _buildImagePlaceholder();
      },
    );
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
        _getCategoryIcon(),
        color: Colors.grey.shade400,
        size: 24,
      ),
    );
  }

  /// Returns an icon that represents the classification category
  IconData _getCategoryIcon() {
    switch (classification.category.toLowerCase()) {
      case 'wet waste':
        return Icons.eco;
      case 'dry waste':
        return Icons.recycling;
      case 'hazardous waste':
        return Icons.warning;
      case 'medical waste':
        return Icons.medical_services;
      case 'non-waste':
        return Icons.check_circle;
      case 'requires manual review':
        return Icons.help_outline;
      default:
        return Icons.category;
    }
  }

  /// Get full image path from relative path
  Future<String> _getFullImagePath(String relativePath) async {
    final dir = await getApplicationDocumentsDirectory();
    // iOS & Android store images/…  ➜ was missing in join
    return path.join(dir.path, 'images', relativePath);
  }

  Future<void> _persistBytes(Uint8List bytes, String relPath) async {
    try {
      final full = await _getFullImagePath(relPath);
      await File(full).writeAsBytes(bytes, flush: true);
    } catch (e) {
      WasteAppLogger.severe('Error occurred', null, null, {'service': 'widget', 'file': 'history_list_item'});
    }
  }
}