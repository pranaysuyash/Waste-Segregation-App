import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/educational_content.dart';
import '../services/educational_content_service.dart';
import '../utils/constants.dart';
import 'quiz_screen.dart';
import 'package:video_player/video_player.dart';

class ContentDetailScreen extends StatelessWidget {

  const ContentDetailScreen({
    super.key,
    required this.contentId,
  });
  final String contentId;

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
          Text(
            content.title,
            style: const TextStyle(
              fontSize: AppTheme.fontSizeExtraLarge,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: AppTheme.paddingSmall),
          Row(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    content.getFormattedDuration(),
                    style: const TextStyle(
                      fontSize: AppTheme.fontSizeSmall,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppTheme.paddingRegular),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.school, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    content.getLevelText(),
                    style: const TextStyle(
                      fontSize: AppTheme.fontSizeSmall,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppTheme.paddingRegular),
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
                  borderRadius:
                      BorderRadius.circular(AppTheme.borderRadiusSmall),
                  border: Border.all(color: categoryColor.withValues(alpha: 0.5)),
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
          if (content.contentText != null)
            Text(
              content.contentText!,
              style: const TextStyle(
                fontSize: AppTheme.fontSizeRegular,
                height: 1.5,
              ),
            ),
          const SizedBox(height: AppTheme.paddingLarge),
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
                    borderRadius:
                        BorderRadius.circular(AppTheme.borderRadiusSmall),
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
          if (content.videoUrl != null && content.videoUrl!.isNotEmpty)
            _VideoPlayerWidget(url: content.videoUrl!)
          else
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
          Text(
            content.title,
            style: const TextStyle(
              fontSize: AppTheme.fontSizeExtraLarge,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: AppTheme.paddingSmall),
          Row(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    content.getFormattedDuration(),
                    style: const TextStyle(
                      fontSize: AppTheme.fontSizeSmall,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppTheme.paddingRegular),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.school, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    content.getLevelText(),
                    style: const TextStyle(
                      fontSize: AppTheme.fontSizeSmall,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppTheme.paddingRegular),
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
                  borderRadius:
                      BorderRadius.circular(AppTheme.borderRadiusSmall),
                  border: Border.all(color: categoryColor.withValues(alpha: 0.5)),
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
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: AppTheme.paddingLarge),
          const Text(
            'Transcript',
            style: TextStyle(
              fontSize: AppTheme.fontSizeMedium,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.paddingSmall),
          Text(
            content.description,
            style: TextStyle(
              fontSize: AppTheme.fontSizeSmall,
              color: AppTheme.textSecondaryColor,
              fontStyle: content.description.isEmpty ? FontStyle.italic : FontStyle.normal,
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
          if (content.imageUrl != null && content.imageUrl!.isNotEmpty)
            Image.network(
              content.imageUrl!,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) => Container(
                height: 200,
                color: Colors.grey.shade200,
                child: const Icon(Icons.broken_image, size: 64, color: Colors.grey),
              ),
            )
          else
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusRegular),
              ),
              child: Icon(
                Icons.image_search,
                size: 64,
                color: Colors.grey.shade400,
              ),
            ),
          const SizedBox(height: AppTheme.paddingRegular),
          Text(
            content.title,
            style: const TextStyle(
              fontSize: AppTheme.fontSizeExtraLarge,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: AppTheme.paddingSmall),
          Row(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.remove_red_eye_outlined, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    content.getFormattedDuration(), 
                    style: const TextStyle(
                      fontSize: AppTheme.fontSizeSmall,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppTheme.paddingRegular),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.school, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    content.getLevelText(),
                    style: const TextStyle(
                      fontSize: AppTheme.fontSizeSmall,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppTheme.paddingRegular),
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
                  borderRadius:
                      BorderRadius.circular(AppTheme.borderRadiusSmall),
                  border: Border.all(color: categoryColor.withValues(alpha: 0.5)),
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
          Text(
            content.description,
            style: const TextStyle(
              fontSize: AppTheme.fontSizeRegular,
              color: AppTheme.textPrimaryColor,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizView(BuildContext context, EducationalContent content) {
    return Center(
      child: ElevatedButton.icon(
        icon: const Icon(Icons.quiz_outlined),
        label: const Text('Start Quiz'),
        onPressed: () {
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
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.paddingLarge,
            vertical: AppTheme.paddingRegular,
          ),
          textStyle: const TextStyle(fontSize: AppTheme.fontSizeMedium),
        ),
      ),
    );
  }

  Widget _buildTutorialView(BuildContext context, EducationalContent content) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.paddingRegular),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            content.title,
            style: const TextStyle(
              fontSize: AppTheme.fontSizeExtraLarge,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: AppTheme.paddingSmall),
          Row(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    content.getFormattedDuration(),
                    style: const TextStyle(
                      fontSize: AppTheme.fontSizeSmall,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppTheme.paddingRegular),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.school, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    content.getLevelText(),
                    style: const TextStyle(
                      fontSize: AppTheme.fontSizeSmall,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppTheme.paddingRegular),
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
                  borderRadius:
                      BorderRadius.circular(AppTheme.borderRadiusSmall),
                  border: Border.all(color: categoryColor.withValues(alpha: 0.5)),
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
          if (content.steps != null && content.steps!.isNotEmpty)
            Column(
              children: content.steps!.asMap().entries.map((entry) {
                final idx = entry.key;
                final step = entry.value;
                return ListTile(
                  leading: CircleAvatar(child: Text('${idx + 1}')),
                  title: Text(step.title),
                  subtitle: Text(step.description),
                  contentPadding: EdgeInsets.zero,
                );
              }).toList(),
            )
          else
            Text(
              content.contentText ?? 'Tutorial content coming soon.',
              style: const TextStyle(
                fontSize: AppTheme.fontSizeRegular,
                height: 1.5,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTipView(BuildContext context, EducationalContent content) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.paddingLarge),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lightbulb_outline,
              size: 64,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: AppTheme.paddingRegular),
            Text(
              content.title,
              style: const TextStyle(
                fontSize: AppTheme.fontSizeLarge,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.paddingSmall),
            Text(
              content.contentText ?? 'Detailed tip content coming soon.',
              style: const TextStyle(
                fontSize: AppTheme.fontSizeRegular,
                color: AppTheme.textSecondaryColor,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'recycling': return Colors.green;
      case 'composting': return Colors.brown;
      case 'waste reduction': return Colors.blue;
      case 'hazardous waste': return Colors.red;
      case 'e-waste': return Colors.purple;
      default: return Colors.grey.shade400;
    }
  }
}

class _VideoPlayerWidget extends StatefulWidget {
  const _VideoPlayerWidget({required this.url});
  final String url;

  @override
  State<_VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  VideoPlayerController? _controller;
  bool _isPlaying = false;
  bool _isInitialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
        ..initialize().then((_) {
          if (!mounted) return;
          setState(() {
            _isInitialized = true;
          });
          _controller?.addListener(() {
            if (!mounted) return;
            if (_controller?.value.isPlaying != _isPlaying) {
              setState(() {
                _isPlaying = _controller!.value.isPlaying;
              });
            }
          });
        }).catchError((e) {
          if (!mounted) return;
          setState(() {
            _error = 'Failed to load video: ${e.toString()}';
            _isInitialized = true; 
          });
        });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Invalid video URL or format.';
         _isInitialized = true; 
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Container(
        height: 200,
        color: Colors.black,
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            _error!,
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (!_isInitialized || _controller == null || !_controller!.value.isInitialized) {
      return Container(
        height: 200,
        color: Colors.black,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      );
    }

    return AspectRatio(
      aspectRatio: _controller!.value.aspectRatio,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: <Widget>[
          VideoPlayer(_controller!),
          _PlayPauseOverlay(controller: _controller!),
          VideoProgressIndicator(_controller!, allowScrubbing: true),
        ],
      ),
    );
  }
}

class _PlayPauseOverlay extends StatelessWidget {
  const _PlayPauseOverlay({required this.controller});

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, VideoPlayerValue value, child) {
        return Stack(
          children: <Widget>[
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 50),
              reverseDuration: const Duration(milliseconds: 200),
              child: value.isPlaying
                  ? const SizedBox.shrink()
                  : Container(
                      color: Colors.black26,
                      child: const Center(
                        child: Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 100.0,
                          semanticLabel: 'Play',
                        ),
                      ),
                    ),
            ),
            GestureDetector(
              onTap: () {
                if (value.isPlaying) {
                  controller.pause();
                } else {
                  controller.play();
                }
              },
            ),
          ],
        );
      },
    );
  }
}
