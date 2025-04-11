import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/educational_content.dart';
import '../services/educational_content_service.dart';
import '../utils/constants.dart';
import 'quiz_screen.dart';

class ContentDetailScreen extends StatelessWidget {
  final String contentId;
  
  const ContentDetailScreen({
    super.key,
    required this.contentId,
  });
  
  @override
  Widget build(BuildContext context) {
    final educationalService = Provider.of<EducationalContentService>(context);
    final content = educationalService.getContentById(contentId);
    
    if (content == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Content Not Found'),
        ),
        body: const Center(
          child: Text('The requested content could not be found.'),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(content.title),
        backgroundColor: content.getTypeColor(),
        foregroundColor: Colors.white,
      ),
      body: _buildContentBody(context, content),
    );
  }
  
  Widget _buildContentBody(BuildContext context, EducationalContent content) {
    switch (content.type) {
      case ContentType.article:
        return _buildArticleView(context, content);
      case ContentType.video:
        return _buildVideoView(context, content);
      case ContentType.infographic:
        return _buildInfographicView(context, content);
      case ContentType.quiz:
        return _buildQuizView(context, content);
      case ContentType.tutorial:
        return _buildTutorialView(context, content);
      case ContentType.tip:
        return _buildTipView(context, content);
    }
  }
  
  Widget _buildArticleView(BuildContext context, EducationalContent content) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.paddingRegular),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header image (placeholder)
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
            ),
            child: Icon(
              Icons.article,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          
          const SizedBox(height: AppTheme.paddingRegular),
          
          // Title and metadata
          Text(
            content.title,
            style: const TextStyle(
              fontSize: AppTheme.fontSizeExtraLarge,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: AppTheme.paddingSmall),
          
          // Metadata row
          Row(
            children: [
              // Reading time
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    content.getFormattedDuration(),
                    style: const TextStyle(
                      fontSize: AppTheme.fontSizeSmall,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(width: AppTheme.paddingRegular),
              
              // Difficulty level
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.school, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    content.getLevelText(),
                    style: const TextStyle(
                      fontSize: AppTheme.fontSizeSmall,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.paddingRegular),
          
          // Content categories
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: content.categories.map((category) {
              final categoryColor = _getCategoryColor(category);
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.paddingSmall,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                  border: Border.all(color: categoryColor.withOpacity(0.5)),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeSmall,
                    color: categoryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: AppTheme.paddingLarge),
          
          // Content text
          if (content.contentText != null)
            Text(
              content.contentText!,
              style: const TextStyle(
                fontSize: AppTheme.fontSizeRegular,
                height: 1.5,
              ),
            ),
          
          const SizedBox(height: AppTheme.paddingLarge),
          
          // Related tags
          if (content.tags.isNotEmpty) ...[
            const Text(
              'Related Topics',
              style: TextStyle(
                fontSize: AppTheme.fontSizeMedium,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: AppTheme.paddingSmall),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: content.tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.paddingSmall,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                  ),
                  child: Text(
                    '#$tag',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeSmall,
                      color: Colors.grey.shade700,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildVideoView(BuildContext context, EducationalContent content) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.paddingRegular),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Video player (placeholder)
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
            ),
            child: const Center(
              child: Icon(
                Icons.play_circle_fill,
                size: 64,
                color: Colors.white,
              ),
            ),
          ),
          
          const SizedBox(height: AppTheme.paddingRegular),
          
          // Title and metadata
          Text(
            content.title,
            style: const TextStyle(
              fontSize: AppTheme.fontSizeExtraLarge,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: AppTheme.paddingSmall),
          
          // Metadata row
          Row(
            children: [
              // Video duration
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    content.getFormattedDuration(),
                    style: const TextStyle(
                      fontSize: AppTheme.fontSizeSmall,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(width: AppTheme.paddingRegular),
              
              // Difficulty level
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.school, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    content.getLevelText(),
                    style: const TextStyle(
                      fontSize: AppTheme.fontSizeSmall,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.paddingRegular),
          
          // Content categories
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: content.categories.map((category) {
              final categoryColor = _getCategoryColor(category);
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.paddingSmall,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                  border: Border.all(color: categoryColor.withOpacity(0.5)),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeSmall,
                    color: categoryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: AppTheme.paddingLarge),
          
          // Description
          const Text(
            'Description',
            style: TextStyle(
              fontSize: AppTheme.fontSizeMedium,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: AppTheme.paddingSmall),
          
          Text(
            content.description,
            style: const TextStyle(
              fontSize: AppTheme.fontSizeRegular,
              height: 1.5,
            ),
          ),
          
          const SizedBox(height: AppTheme.paddingLarge),
          
          // Video transcript placeholder
          const Text(
            'Transcript',
            style: TextStyle(
              fontSize: AppTheme.fontSizeMedium,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: AppTheme.paddingSmall),
          
          Container(
            padding: const EdgeInsets.all(AppTheme.paddingRegular),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
            ),
            child: const Text(
              'Transcript not available for this video yet.',
              style: TextStyle(
                fontSize: AppTheme.fontSizeRegular,
                color: AppTheme.textSecondaryColor,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfographicView(BuildContext context, EducationalContent content) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.paddingRegular),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            content.title,
            style: const TextStyle(
              fontSize: AppTheme.fontSizeExtraLarge,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: AppTheme.paddingSmall),
          
          // Description
          Text(
            content.description,
            style: const TextStyle(
              fontSize: AppTheme.fontSizeRegular,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          
          const SizedBox(height: AppTheme.paddingRegular),
          
          // Content categories
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: content.categories.map((category) {
              final categoryColor = _getCategoryColor(category);
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.paddingSmall,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                  border: Border.all(color: categoryColor.withOpacity(0.5)),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeSmall,
                    color: categoryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: AppTheme.paddingLarge),
          
          // Infographic image (placeholder)
          Container(
            width: double.infinity,
            height: 500,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Icon(
              Icons.image,
              size: 80,
              color: Colors.grey.shade400,
            ),
          ),
          
          const SizedBox(height: AppTheme.paddingLarge),
          
          // Additional explanation
          if (content.contentText != null) ...[
            const Text(
              'Additional Information',
              style: TextStyle(
                fontSize: AppTheme.fontSizeMedium,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: AppTheme.paddingSmall),
            
            Text(
              content.contentText!,
              style: const TextStyle(
                fontSize: AppTheme.fontSizeRegular,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildQuizView(BuildContext context, EducationalContent content) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.paddingRegular),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header image (placeholder)
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.quiz,
                    size: 48,
                    color: Colors.orange.shade800,
                  ),
                  const SizedBox(height: AppTheme.paddingSmall),
                  Text(
                    'Quiz: ${content.title}',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeLarge,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: AppTheme.paddingLarge),
          
          // Quiz description
          Text(
            content.description,
            style: const TextStyle(
              fontSize: AppTheme.fontSizeRegular,
              height: 1.5,
            ),
          ),
          
          const SizedBox(height: AppTheme.paddingRegular),
          
          // Quiz metadata
          Container(
            padding: const EdgeInsets.all(AppTheme.paddingRegular),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                // Number of questions
                Row(
                  children: [
                    const Icon(
                      Icons.question_answer,
                      size: 20,
                      color: AppTheme.secondaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${content.questions?.length ?? 0} Questions',
                      style: const TextStyle(
                        fontSize: AppTheme.fontSizeRegular,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppTheme.paddingSmall),
                
                // Estimated time
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      size: 20,
                      color: AppTheme.secondaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      content.getFormattedDuration(),
                      style: const TextStyle(
                        fontSize: AppTheme.fontSizeRegular,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppTheme.paddingSmall),
                
                // Difficulty level
                Row(
                  children: [
                    const Icon(
                      Icons.school,
                      size: 20,
                      color: AppTheme.secondaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      content.getLevelText(),
                      style: const TextStyle(
                        fontSize: AppTheme.fontSizeRegular,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppTheme.paddingLarge),
          
          // Start quiz button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Navigate to quiz screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QuizScreen(
                      quizContent: content,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: AppTheme.paddingRegular,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
                ),
              ),
              child: const Text(
                'Start Quiz',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeMedium,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: AppTheme.paddingRegular),
          
          // Quiz preview
          if (content.questions != null && content.questions!.isNotEmpty) ...[
            const Text(
              'Preview Question',
              style: TextStyle(
                fontSize: AppTheme.fontSizeMedium,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: AppTheme.paddingSmall),
            
            Container(
              padding: const EdgeInsets.all(AppTheme.paddingRegular),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content.questions!.first.question,
                    style: const TextStyle(
                      fontSize: AppTheme.fontSizeMedium,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: AppTheme.paddingRegular),
                  
                  // First two options preview
                  ...content.questions!.first.options.take(2).map((option) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: AppTheme.paddingSmall),
                      padding: const EdgeInsets.all(AppTheme.paddingSmall),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(option),
                    );
                  }),
                  
                  const SizedBox(height: AppTheme.paddingSmall),
                  
                  // More options text
                  if (content.questions!.first.options.length > 2)
                    Text(
                      '+ ${content.questions!.first.options.length - 2} more options',
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeSmall,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildTutorialView(BuildContext context, EducationalContent content) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.paddingRegular),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            content.title,
            style: const TextStyle(
              fontSize: AppTheme.fontSizeExtraLarge,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: AppTheme.paddingSmall),
          
          // Description
          Text(
            content.description,
            style: const TextStyle(
              fontSize: AppTheme.fontSizeRegular,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          
          const SizedBox(height: AppTheme.paddingRegular),
          
          // Tutorial metadata
          Row(
            children: [
              // Duration
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    content.getFormattedDuration(),
                    style: const TextStyle(
                      fontSize: AppTheme.fontSizeSmall,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(width: AppTheme.paddingRegular),
              
              // Difficulty level
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.school, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    content.getLevelText(),
                    style: const TextStyle(
                      fontSize: AppTheme.fontSizeSmall,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(width: AppTheme.paddingRegular),
              
              // Number of steps
              if (content.steps != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.list, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${content.steps!.length} Steps',
                      style: const TextStyle(
                        fontSize: AppTheme.fontSizeSmall,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          
          const SizedBox(height: AppTheme.paddingRegular),
          
          // Content categories
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: content.categories.map((category) {
              final categoryColor = _getCategoryColor(category);
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.paddingSmall,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                  border: Border.all(color: categoryColor.withOpacity(0.5)),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeSmall,
                    color: categoryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: AppTheme.paddingLarge),
          
          // Tutorial steps
          if (content.steps != null && content.steps!.isNotEmpty) ...[
            const Text(
              'Steps',
              style: TextStyle(
                fontSize: AppTheme.fontSizeLarge,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: AppTheme.paddingRegular),
            
            // List of steps
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: content.steps!.length,
              itemBuilder: (context, index) {
                final step = content.steps![index];
                return Container(
                  margin: const EdgeInsets.only(bottom: AppTheme.paddingRegular),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Step header
                      Container(
                        padding: const EdgeInsets.all(AppTheme.paddingRegular),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(AppTheme.borderRadiusRegular - 1),
                            topRight: Radius.circular(AppTheme.borderRadiusRegular - 1),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Step number
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    fontSize: AppTheme.fontSizeMedium,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            
                            const SizedBox(width: AppTheme.paddingRegular),
                            
                            // Step title
                            Expanded(
                              child: Text(
                                step.title,
                                style: const TextStyle(
                                  fontSize: AppTheme.fontSizeMedium,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Step image (placeholder)
                      if (step.imageUrl != null)
                        Container(
                          height: 150,
                          width: double.infinity,
                          color: Colors.grey.shade200,
                          child: Icon(
                            Icons.image,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      
                      // Step description
                      Padding(
                        padding: const EdgeInsets.all(AppTheme.paddingRegular),
                        child: Text(
                          step.description,
                          style: const TextStyle(
                            fontSize: AppTheme.fontSizeRegular,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildTipView(BuildContext context, EducationalContent content) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.paddingRegular),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tip card
          Container(
            padding: const EdgeInsets.all(AppTheme.paddingRegular),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tip icon and title
                Row(
                  children: [
                    const Icon(
                      Icons.lightbulb_outline,
                      color: AppTheme.primaryColor,
                      size: 28,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        content.title,
                        style: const TextStyle(
                          fontSize: AppTheme.fontSizeLarge,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: AppTheme.paddingRegular),
                
                // Tip content
                if (content.contentText != null)
                  Text(
                    content.contentText!,
                    style: const TextStyle(
                      fontSize: AppTheme.fontSizeRegular,
                      height: 1.5,
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: AppTheme.paddingLarge),
          
          // Why this matters section
          const Text(
            'Why This Matters',
            style: TextStyle(
              fontSize: AppTheme.fontSizeMedium,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: AppTheme.paddingSmall),
          
          // Detailed explanation
          Text(
            content.description,
            style: const TextStyle(
              fontSize: AppTheme.fontSizeRegular,
              height: 1.5,
            ),
          ),
          
          const SizedBox(height: AppTheme.paddingLarge),
          
          // Related categories
          const Text(
            'Related Categories',
            style: TextStyle(
              fontSize: AppTheme.fontSizeMedium,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: AppTheme.paddingSmall),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: content.categories.map((category) {
              final categoryColor = _getCategoryColor(category);
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.paddingSmall,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                  border: Border.all(color: categoryColor.withOpacity(0.5)),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeSmall,
                    color: categoryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Wet Waste':
        return AppTheme.wetWasteColor;
      case 'Dry Waste':
        return AppTheme.dryWasteColor;
      case 'Hazardous Waste':
        return AppTheme.hazardousWasteColor;
      case 'Medical Waste':
        return AppTheme.medicalWasteColor;
      case 'Non-Waste':
        return AppTheme.nonWasteColor;
      case 'General':
        return AppTheme.secondaryColor;
      case 'Sorting':
        return AppTheme.accentColor;
      case 'Composting':
        return Colors.green.shade800;
      case 'Recycling':
        return Colors.blue.shade700;
      case 'E-waste':
        return Colors.orange;
      case 'Plastic':
        return Colors.lightBlue;
      case 'Home Organization':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}