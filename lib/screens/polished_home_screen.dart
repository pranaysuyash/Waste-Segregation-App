import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../services/gamification_service.dart';
import '../models/waste_classification.dart';
import '../models/educational_content.dart';
import '../models/gamification.dart';
import '../utils/app_theme.dart';
import '../utils/waste_app_logger.dart';
import '../widgets/polished/polished_card.dart';
import '../widgets/polished/polished_divider.dart';
import '../widgets/polished/polished_section.dart';
import '../widgets/polished/polished_fab.dart';
import '../widgets/polished/shimmer_loading.dart';
import '../widgets/home_header_wrapper.dart';
import '../screens/history_screen.dart';
import '../screens/educational_content_screen.dart';

/// Polished home screen demonstrating UI improvements
class PolishedHomeScreen extends StatefulWidget {
  const PolishedHomeScreen({super.key});

  @override
  State<PolishedHomeScreen> createState() => _PolishedHomeScreenState();
}

class _PolishedHomeScreenState extends State<PolishedHomeScreen>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  String? _userName;
  List<WasteClassification> _recentClassifications = [];
  List<EducationalContent> _featuredContent = [];
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: AppThemePolish.animationMedium,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _loadData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    // Simulate loading with shimmer
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Load actual data
    final storageService = Provider.of<StorageService>(context, listen: false);
    final classifications = await storageService.getAllClassifications();
    
    setState(() {
      _userName = 'Pranay'; // This would come from user service
      _recentClassifications = classifications.take(3).toList();
      _featuredContent = _generateFeaturedContent();
      _isLoading = false;
    });
    
    _fadeController.forward();
  }

  List<EducationalContent> _generateFeaturedContent() {
    return [
      EducationalContent(
        id: '1',
        title: 'Plastic Recycling Guide',
        description: 'Learn about different types of plastic and how to recycle them properly.',
        type: ContentType.article,
        categories: ['Plastic', 'Recycling'],
        icon: Icons.recycling,
        thumbnailUrl: 'https://example.com/plastic-guide.jpg',
        level: ContentLevel.beginner,
        dateAdded: DateTime.now(),
        durationMinutes: 5,
        contentText: 'Learn about different types of plastic and how to recycle them properly.',
      ),
      EducationalContent(
        id: '2',
        title: 'Composting Basics',
        description: 'Start your own compost bin and reduce food waste.',
        type: ContentType.tip,
        categories: ['Organic', 'Composting'],
        icon: Icons.eco,
        thumbnailUrl: 'https://example.com/composting-guide.jpg',
        level: ContentLevel.beginner,
        dateAdded: DateTime.now(),
        durationMinutes: 3,
        contentText: 'Start your own compost bin and reduce food waste.',
      ),
    ];
  }

  void _takePicture() {
    // Implementation would go here
    WasteAppLogger.info('Taking picture...');
  }

  void _pickImage() {
    // Implementation would go here
    WasteAppLogger.info('Picking image...');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppThemePolish.spacingGenerous),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                    // Hero welcome section with luxurious spacing
                    const PolishedSection.luxurious(
                      child: HomeHeaderWrapper(),
                    ),

                  // Action buttons section with generous spacing
                  PolishedSection.generous(
                    title: 'Quick Actions',
                    subtitle: 'Identify waste items instantly',
                    child: _buildActionButtons(),
                  ),

                  const PolishedDivider.section(),

                  // Gamification section
                  if (!_isLoading)
                    PolishedSection.generous(
                      title: 'Your Progress',
                      subtitle: 'Keep up the great work!',
                      trailing: const Icon(Icons.trending_up, color: Colors.green),
                      child: _buildGamificationSection(),
                    )
                  else
                    _buildGamificationSkeleton(),

                  const PolishedDivider.section(),

                  // Recent classifications
                  if (_recentClassifications.isNotEmpty)
                    PolishedSection.generous(
                      title: 'Recent Identifications',
                      subtitle: '${_recentClassifications.length} items classified',
                      onTitleTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const HistoryScreen()),
                      ),
                      child: _buildRecentClassifications(),
                    )
                  else if (!_isLoading)
                    _buildEmptyState()
                  else
                    _buildRecentClassificationsSkeleton(),

                  const PolishedDivider.dotted(),

                  // Featured content
                  PolishedSection.generous(
                    title: 'Learn & Improve',
                    subtitle: 'Educational content to help you waste less',
                    onTitleTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const EducationalContentScreen()),
                    ),
                    child: _buildFeaturedContent(),
                  ),

                  // Bottom padding for FAB
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: PolishedFAB(
        onPressed: _takePicture,
        icon: Icons.camera_alt,
        backgroundColor: AppThemePolish.accentVibrant,
      ),
    );
  }

  Widget _buildWelcomeSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Greeting with enhanced typography
        Text(
          'Hello, ${_userName ?? 'User'}! 👋',
          style: theme.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
            height: AppThemePolish.lineHeightComfortable,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'What waste would you like to identify today?',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: AppThemePolish.lineHeightGenerous,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: PolishedCard(
            onTap: _takePicture,
            backgroundColor: AppThemePolish.accentVibrant.withValues(alpha: 0.1),
            child: const Column(
              children: [
                Icon(
                  Icons.camera_alt,
                  size: 48,
                  color: AppThemePolish.accentVibrant,
                ),
                SizedBox(height: 12),
                Text(
                  'Take Photo',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppThemePolish.accentVibrant,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: PolishedCard(
            onTap: _pickImage,
            backgroundColor: AppThemePolish.accentWarm.withValues(alpha: 0.1),
            child: const Column(
              children: [
                Icon(
                  Icons.photo_library,
                  size: 48,
                  color: AppThemePolish.accentWarm,
                ),
                SizedBox(height: 12),
                Text(
                  'Upload Image',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppThemePolish.accentWarm,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGamificationSection() {
    return Consumer<GamificationService>(
      builder: (context, gamificationService, child) {
        final profile = gamificationService.currentProfile;
        if (profile == null) {
          return const SizedBox.shrink();
        }

        return Row(
          children: [
            Expanded(
              child: PolishedCard(
                backgroundColor: Colors.green.withValues(alpha: 0.1),
                child: Column(
                  children: [
                    Text(
                      '${profile.points.total}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const Text('Total Points'),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PolishedCard(
                backgroundColor: Colors.blue.withValues(alpha: 0.1),
                child: Column(
                  children: [
                    Text(
                      'Level ${profile.points.level}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const Text('Current Level'),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PolishedCard(
                backgroundColor: Colors.orange.withValues(alpha: 0.1),
                child: Column(
                  children: [
                    Text(
                      '${profile.streaks[StreakType.dailyClassification.toString()]?.currentCount ?? 0}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const Text('Day Streak'),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGamificationSkeleton() {
    return ShimmerLoading(
      child: Row(
        children: [
          Expanded(child: ShimmerSkeleton.card(height: 80)),
          const SizedBox(width: 12),
          Expanded(child: ShimmerSkeleton.card(height: 80)),
          const SizedBox(width: 12),
          Expanded(child: ShimmerSkeleton.card(height: 80)),
        ],
      ),
    );
  }

  Widget _buildRecentClassifications() {
    return Column(
      children: _recentClassifications.map((classification) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: PolishedCard(
            child: Row(
              children: [
                // Thumbnail placeholder
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.image, color: Colors.grey),
                ),
                const SizedBox(width: 16),
                // Classification details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        classification.itemName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        classification.category,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                // Confidence indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${((classification.confidence ?? 0.0) * 100).round()}%',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentClassificationsSkeleton() {
    return ShimmerLoading(
      child: Column(
        children: List.generate(3, (index) => 
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ShimmerSkeleton.listItem(),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return PolishedCard(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(
        children: [
          Icon(
            Icons.eco,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No classifications yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start by taking a photo or uploading an image of waste to classify!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedContent() {
    return Column(
      children: _featuredContent.map((content) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: PolishedCard(
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppThemePolish.accentCool.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    content.icon,
                    color: AppThemePolish.accentCool,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        content.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        content.description,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Text(
                  '${content.durationMinutes} min',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
} 