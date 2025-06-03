import 'package:flutter/material.dart';
import 'package:waste_segregation_app/models/shared_waste_classification.dart';
import 'package:waste_segregation_app/models/gamification.dart' show FamilyReactionType;
import 'package:waste_segregation_app/utils/constants.dart'; // For AppTheme

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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.paddingRegular),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Basic Info Section
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.paddingLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Item: ${originalClassification.itemName}',
                      style: const TextStyle(fontSize: AppTheme.fontSizeLarge, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppTheme.paddingSmall),
                    Text(
                      'Category: ${originalClassification.category}',
                      style: const TextStyle(fontSize: AppTheme.fontSizeMedium, color: AppTheme.textSecondaryColor),
                    ),
                    if (originalClassification.subcategory != null) ...[
                      const SizedBox(height: AppTheme.paddingSmall),
                      Text(
                        'Subcategory: ${originalClassification.subcategory}',
                        style: const TextStyle(fontSize: AppTheme.fontSizeMedium, color: AppTheme.textSecondaryColor),
                      ),
                    ],
                    if (originalClassification.imageUrl != null && originalClassification.imageUrl!.isNotEmpty) ...[
                      const SizedBox(height: AppTheme.paddingMedium),
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
                          child: Image.network(
                            originalClassification.imageUrl!,
                            height: 200,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.image_not_supported, size: 100, color: AppTheme.textDisabledColor),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppTheme.paddingMedium),
                    Text(
                      'Shared by: ${classification.sharedByDisplayName}',
                      style: const TextStyle(fontSize: AppTheme.fontSizeSmall, fontStyle: FontStyle.italic),
                    ),
                    Text(
                      'On: ${_formatDate(classification.sharedAt)}', // Helper needed or use intl package
                      style: const TextStyle(fontSize: AppTheme.fontSizeSmall, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTheme.paddingLarge),

            // Reactions Section
            _buildReactionsSection(),
            const SizedBox(height: AppTheme.paddingLarge),

            // Comments Section
            _buildCommentsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildReactionsSection() {
    if (classification.reactions.isEmpty) {
      return const Card(
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(AppTheme.paddingLarge),
          child: Center(child: Text('No reactions yet.', style: TextStyle(color: AppTheme.textSecondaryColor))),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reactions',
              style: TextStyle(fontSize: AppTheme.fontSizeMedium, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.paddingRegular),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: classification.reactions.length,
              itemBuilder: (context, index) {
                final reaction = classification.reactions[index];
                return ListTile(
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundImage: reaction.photoUrl != null && reaction.photoUrl!.isNotEmpty
                        ? NetworkImage(reaction.photoUrl!)
                        : null,
                    child: reaction.photoUrl == null || reaction.photoUrl!.isEmpty
                        ? Text(reaction.displayName.substring(0,1).toUpperCase())
                        : null,
                  ),
                  title: Text(reaction.displayName),
                  trailing: Text('${_getReactionEmoji(reaction.type)} ${reaction.type.toString().split('.').last}'),
                );
              },
              separatorBuilder: (context, index) => const Divider(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsSection() {
    if (classification.comments.isEmpty) {
      return const Card(
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(AppTheme.paddingLarge),
          child: Center(child: Text('No comments yet.', style: TextStyle(color: AppTheme.textSecondaryColor))),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Comments',
              style: TextStyle(fontSize: AppTheme.fontSizeMedium, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.paddingRegular),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: classification.comments.length,
              itemBuilder: (context, index) {
                final comment = classification.comments[index];
                return ListTile(
                   leading: CircleAvatar(
                    radius: 18,
                    backgroundImage: comment.photoUrl != null && comment.photoUrl!.isNotEmpty
                        ? NetworkImage(comment.photoUrl!)
                        : null,
                    child: comment.photoUrl == null || comment.photoUrl!.isEmpty
                        ? Text(comment.displayName.substring(0,1).toUpperCase())
                        : null,
                  ),
                  title: Text(comment.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(comment.text),
                  trailing: Text(_formatDate(comment.timestamp), style: const TextStyle(fontSize: AppTheme.fontSizeSmall)),
                );
              },
              separatorBuilder: (context, index) => const Divider(),
            ),
          ],
        ),
      ),
    );
  }

  // TODO: Move these helpers to a utility file if used elsewhere or use intl package
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
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
}
