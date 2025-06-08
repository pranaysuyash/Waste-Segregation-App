import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:waste_segregation_app/models/shared_waste_classification.dart';
import 'package:waste_segregation_app/models/gamification.dart' show FamilyReactionType;
import 'package:waste_segregation_app/utils/constants.dart';
import 'package:waste_segregation_app/utils/image_utils.dart';
import 'package:waste_segregation_app/widgets/modern_ui/modern_cards.dart';

class ClassificationDetailsScreen extends StatefulWidget {
  const ClassificationDetailsScreen({super.key, required this.classification});
  final SharedWasteClassification classification;

  @override
  State<ClassificationDetailsScreen> createState() => _ClassificationDetailsScreenState();
}

class _ClassificationDetailsScreenState extends State<ClassificationDetailsScreen> with TickerProviderStateMixin {
  bool _isBookmarked = false;
  late AnimationController _bookmarkAnimationController;
  late Animation<double> _bookmarkAnimation;

  // Avatar fallback colors palette
  static const List<Color> _avatarColors = [
    Color(0xFF6B73FF), // Blue
    Color(0xFF9C27B0), // Purple
    Color(0xFF00BCD4), // Cyan
    Color(0xFF4CAF50), // Green
    Color(0xFFFF9800), // Orange
    Color(0xFFE91E63), // Pink
    Color(0xFF795548), // Brown
    Color(0xFF607D8B), // Blue Grey
  ];

  @override
  void initState() {
    super.initState();
    _bookmarkAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _bookmarkAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _bookmarkAnimationController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _bookmarkAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final originalClassification = widget.classification.classification;

    return Scaffold(
      appBar: AppBar(
        title: Text(originalClassification.itemName),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          AnimatedBuilder(
            animation: _bookmarkAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _bookmarkAnimation.value,
                child: IconButton(
                  onPressed: () => _toggleBookmark(context),
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      key: ValueKey(_isBookmarked),
                      color: _isBookmarked ? Colors.amber : Colors.white,
                    ),
                  ),
                  tooltip: _isBookmarked ? 'Remove bookmark' : 'Bookmark this classification',
                ),
              );
            },
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
                          child: ImageUtils.buildImage(
                            imageSource: originalClassification.imageUrl!,
                            height: MediaQuery.of(context).size.height * 0.25,
                            fit: BoxFit.cover,
                            errorWidget: Container(
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
                        'Shared by ${widget.classification.sharedByDisplayName}',
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
                        _formatDateWithIntl(widget.classification.sharedAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),

            // Reactions Section
            _buildReactionsSection(context),
            const SizedBox(height: AppTheme.spacingMd),

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
          if (widget.classification.reactions.isNotEmpty)
            SizedBox(
              height: 56,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: widget.classification.reactions.length > 6 ? 6 : widget.classification.reactions.length,
                separatorBuilder: (_, __) => const SizedBox(width: AppTheme.spacingSm),
                itemBuilder: (_, i) {
                  if (i == 5 && widget.classification.reactions.length > 6) {
                    return Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingSm,
                          vertical: AppTheme.spacingXs,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          border: Border.all(
                            color: AppTheme.primaryColor.withValues(alpha: 0.3),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(AppTheme.borderRadiusSm),
                        ),
                        child: Text(
                          '+${widget.classification.reactions.length - 5} more',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }
                  final reaction = widget.classification.reactions[i];
                  return Column(
                    children: [
                      reaction.photoUrl != null && reaction.photoUrl!.isNotEmpty
                        ? ImageUtils.buildCircularAvatar(
                            imageSource: reaction.photoUrl!,
                            radius: 20,
                            backgroundColor: _getAvatarColor(reaction.displayName),
                            child: Text(
                              reaction.displayName.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : CircleAvatar(
                            radius: 20,
                            backgroundColor: _getAvatarColor(reaction.displayName),
                            child: Text(
                              reaction.displayName.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
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
          if (widget.classification.reactions.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingMd),
            const Divider(),
            const SizedBox(height: AppTheme.spacingSm),
            ...widget.classification.reactions.map((reaction) => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingXs),
              child: Row(
                children: [
                  reaction.photoUrl != null && reaction.photoUrl!.isNotEmpty
                    ? ImageUtils.buildCircularAvatar(
                        imageSource: reaction.photoUrl!,
                        radius: 16,
                        backgroundColor: _getAvatarColor(reaction.displayName),
                        child: Text(
                          reaction.displayName.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12, 
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : CircleAvatar(
                        radius: 16,
                        backgroundColor: _getAvatarColor(reaction.displayName),
                        child: Text(
                          reaction.displayName.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12, 
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
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
                      border: Border.all(
                        color: _getReactionColor(reaction.type).withValues(alpha: 0.3),
                        width: 1,
                      ),
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
                            fontWeight: FontWeight.w600,
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

          if (widget.classification.comments.isNotEmpty)
            Column(
              children: widget.classification.comments.asMap().entries.map((entry) {
                final index = entry.key;
                final comment = entry.value;
                final isLast = index == widget.classification.comments.length - 1;
                
                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
                      decoration: BoxDecoration(
                        color: index.isEven 
                          ? Colors.transparent 
                          : AppTheme.primaryColor.withValues(alpha: 0.02),
                        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSm),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          comment.photoUrl != null && comment.photoUrl!.isNotEmpty
                            ? ImageUtils.buildCircularAvatar(
                                imageSource: comment.photoUrl!,
                                radius: 18,
                                backgroundColor: _getAvatarColor(comment.displayName),
                                child: Text(
                                  comment.displayName.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            : CircleAvatar(
                                radius: 18,
                                backgroundColor: _getAvatarColor(comment.displayName),
                                child: Text(
                                  comment.displayName.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
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
                    ),
                    if (!isLast) 
                      Divider(
                        height: 1,
                        color: AppTheme.textDisabledColor.withValues(alpha: 0.2),
                      ),
                  ],
                );
              }).toList(),
            )
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
    setState(() {
      _isBookmarked = !_isBookmarked;
    });
    
    // Trigger animation
    _bookmarkAnimationController.forward().then((_) {
      _bookmarkAnimationController.reverse();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isBookmarked ? 'Added to bookmarks!' : 'Removed from bookmarks'),
        duration: const Duration(seconds: 2),
        backgroundColor: _isBookmarked ? Colors.green : Colors.orange,
      ),
    );
  }

  /// Get a consistent color for avatar fallback based on display name
  Color _getAvatarColor(String displayName) {
    final hash = displayName.hashCode;
    return _avatarColors[hash.abs() % _avatarColors.length];
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
