import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:waste_segregation_app/models/shared_waste_classification.dart';
import 'package:waste_segregation_app/models/gamification.dart' show FamilyReactionType;
import 'package:waste_segregation_app/utils/constants.dart';
import 'package:waste_segregation_app/widgets/modern_ui/modern_cards.dart';

class ClassificationDetailsScreen extends StatelessWidget {
  const ClassificationDetailsScreen({super.key, required this.classification});
  final SharedWasteClassification classification;

  @override
  Widget build(BuildContext context) {
    final originalClassification = classification.classification;

    return Scaffold(
      appBar: AppBar(
        title: Text(originalClassification.itemName),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => _toggleBookmark(context),
            icon: const Icon(Icons.bookmark_border),
            tooltip: 'Bookmark this classification',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Basic Info Section
            ModernCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    originalClassification.itemName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  Text(
                    'Category: ${originalClassification.category}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  if (originalClassification.subcategory != null) ...[
                    const SizedBox(height: AppTheme.spacingXs),
                    Text(
                      'Subcategory: ${originalClassification.subcategory}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                  if (originalClassification.imageUrl != null && originalClassification.imageUrl!.isNotEmpty) ...[
                    const SizedBox(height: AppTheme.spacingMd),
                    Center(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
                          child: Image.network(
                            originalClassification.imageUrl!,
                            height: MediaQuery.of(context).size.height * 0.25,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                              Container(
                                height: MediaQuery.of(context).size.height * 0.25,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
                                ),
                                child: const Icon(
                                  Icons.image_not_supported, 
                                  size: 100, 
                                  color: AppTheme.textDisabledColor,
                                ),
                              ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppTheme.spacingMd),
                  Row(
                    children: [
                      Icon(Icons.person, size: 16, color: AppTheme.textSecondaryColor),
                      const SizedBox(width: AppTheme.spacingXs),
                      Text(
                        'Shared by ${classification.sharedByDisplayName}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingXs),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: AppTheme.textSecondaryColor),
                      const SizedBox(width: AppTheme.spacingXs),
                      Text(
                        _formatDateWithIntl(classification.sharedAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // Reactions Section
            _buildReactionsSection(context),
            const SizedBox(height: AppTheme.spacingLg),

            // Comments Section
            _buildCommentsSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildReactionsSection(BuildContext context) {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header with icon
          Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
            child: Row(
              children: [
                Icon(Icons.emoji_emotions, color: AppTheme.primaryColor),
                const SizedBox(width: AppTheme.spacingSm),
                Text(
                  'Reactions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Horizontal reaction summary or empty state
          if (classification.reactions.isNotEmpty)
            SizedBox(
              height: 56,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: classification.reactions.length > 6 ? 6 : classification.reactions.length,
                separatorBuilder: (_, __) => const SizedBox(width: AppTheme.spacingXs),
                itemBuilder: (_, i) {
                  if (i == 5 && classification.reactions.length > 6) {
                    return Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingSm,
                          vertical: AppTheme.spacingXs,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppTheme.borderRadiusSm),
                        ),
                        child: Text(
                          '+${classification.reactions.length - 5} more',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }
                  final reaction = classification.reactions[i];
                  return Column(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: reaction.photoUrl != null && reaction.photoUrl!.isNotEmpty
                            ? NetworkImage(reaction.photoUrl!)
                            : null,
                        child: reaction.photoUrl == null || reaction.photoUrl!.isEmpty
                            ? Text(
                                reaction.displayName.substring(0, 1).toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              )
                            : null,
                      ),
                      const SizedBox(height: AppTheme.spacingXs),
                      Text(
                        _getReactionEmoji(reaction.type),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  );
                },
              ),
            )
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
                child: Column(
                  children: [
                    Icon(
                      Icons.emoji_emotions_outlined,
                      size: 48,
                      color: AppTheme.textDisabledColor,
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    Text(
                      'No reactions yet',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Show detailed reactions if there are any
          if (classification.reactions.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingMd),
            const Divider(),
            const SizedBox(height: AppTheme.spacingSm),
            ...classification.reactions.map((reaction) => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingXs),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: reaction.photoUrl != null && reaction.photoUrl!.isNotEmpty
                        ? NetworkImage(reaction.photoUrl!)
                        : null,
                    child: reaction.photoUrl == null || reaction.photoUrl!.isEmpty
                        ? Text(
                            reaction.displayName.substring(0, 1).toUpperCase(),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  Expanded(
                    child: Text(
                      reaction.displayName,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingSm,
                      vertical: AppTheme.spacingXs,
                    ),
                    decoration: BoxDecoration(
                      color: _getReactionColor(reaction.type).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.borderRadiusSm),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getReactionEmoji(reaction.type),
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: AppTheme.spacingXs),
                        Text(
                          reaction.type.toString().split('.').last,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _getReactionColor(reaction.type),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildCommentsSection(BuildContext context) {
    return ModernCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header with icon
          Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacingMd),
            child: Row(
              children: [
                Icon(Icons.chat_bubble_outline, color: AppTheme.primaryColor),
                const SizedBox(width: AppTheme.spacingSm),
                Text(
                  'Comments',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          if (classification.comments.isNotEmpty)
            ...classification.comments.map((comment) => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: comment.photoUrl != null && comment.photoUrl!.isNotEmpty
                        ? NetworkImage(comment.photoUrl!)
                        : null,
                    child: comment.photoUrl == null || comment.photoUrl!.isEmpty
                        ? Text(
                            comment.displayName.substring(0, 1).toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              comment.displayName,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _formatDateWithIntl(comment.timestamp),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacingXs),
                        Text(
                          comment.text,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ))
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
                child: Column(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 48,
                      color: AppTheme.textDisabledColor,
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    Text(
                      'No comments yet',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _toggleBookmark(BuildContext context) {
    // TODO: Implement bookmark functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bookmark feature coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _formatDateWithIntl(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      final dateFormat = DateFormat.yMMMd();
      final timeFormat = DateFormat.jm();
      return '${dateFormat.format(date)} at ${timeFormat.format(date)}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String _getReactionEmoji(FamilyReactionType reactionType) {
    switch (reactionType) {
      case FamilyReactionType.like:
        return '👍';
      case FamilyReactionType.love:
        return '❤️';
      case FamilyReactionType.helpful:
        return '🤝';
      case FamilyReactionType.amazing:
        return '🤩';
      case FamilyReactionType.wellDone:
        return '👏';
      case FamilyReactionType.educational:
        return '📚';
    }
  }

  Color _getReactionColor(FamilyReactionType reactionType) {
    switch (reactionType) {
      case FamilyReactionType.like:
        return Colors.blue;
      case FamilyReactionType.love:
        return Colors.red;
      case FamilyReactionType.helpful:
        return Colors.green;
      case FamilyReactionType.amazing:
        return Colors.orange;
      case FamilyReactionType.wellDone:
        return Colors.purple;
      case FamilyReactionType.educational:
        return Colors.indigo;
    }
  }
}
