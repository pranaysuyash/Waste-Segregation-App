import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/waste_classification.dart';
import '../models/gamification.dart';
import '../providers/app_providers.dart';
import '../providers/points_manager.dart';
import '../screens/history_screen.dart';
import '../screens/achievements_screen.dart';
import '../screens/image_capture_screen.dart';
import '../screens/instant_analysis_screen.dart';
import '../widgets/personal_header.dart';

// Profile provider using FutureProvider for better performance
final profileProvider = FutureProvider<GamificationProfile?>((ref) async {
  final gamificationService = ref.watch(gamificationServiceProvider);
  try {
    return await gamificationService.getProfile();
  } catch (e) {
    debugPrint('Error loading profile: $e');
    return null;
  }
});

// Classifications provider
final classificationsProvider = FutureProvider<List<WasteClassification>>((ref) async {
  final storageService = ref.watch(storageServiceProvider);
  return storageService.getAllClassifications();
});

/// Ultra-modern home screen with Material 3 design improvements
class UltraModernHomeScreen extends ConsumerStatefulWidget {
  const UltraModernHomeScreen({
    super.key,
    this.isGuestMode = false,
  });

  final bool isGuestMode;

  @override
  ConsumerState<UltraModernHomeScreen> createState() => _UltraModernHomeScreenState();
}

class _UltraModernHomeScreenState extends ConsumerState<UltraModernHomeScreen>
    with TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  bool _isNavigating = false;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final classificationsAsync = ref.watch(classificationsProvider);
    final profileAsync = ref.watch(profileProvider);
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(classificationsProvider);
                ref.invalidate(profileProvider);
              },
              child: CustomScrollView(
                slivers: [
                  // Hero header with gradient
                  _buildHeroHeader(context, profileAsync),
                  
                  // Content sections
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          
                          // Personal header with time-of-day awareness
                          PersonalHeader(
                            profileAsync: profileAsync,
                            classificationsAsync: classificationsAsync,
                          ),
                          const SizedBox(height: 24),
                          
                          // Horizontal scrolling action chips
                          _buildActionChips(context),
                          const SizedBox(height: 32),
                          
                          // Your Impact section with progress ring
                          _buildImpactSection(context, classificationsAsync, profileAsync),
                          const SizedBox(height: 32),
                          
                          // Recent Classifications
                          _buildRecentClassifications(context, classificationsAsync),
                          
                          // Bottom padding for navigation
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context, AsyncValue<GamificationProfile?> profileAsync) {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF43A047), // Eco green start
                Color(0xFF66BB6A), // Eco green end
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back!',
                            style: GoogleFonts.inter(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ready to make a difference today?',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: Colors.white.withValues(alpha: 0.9),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Animated eco icon
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.eco,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Stats chips
                Row(
                  children: [
                    _buildPointsChip(context),
                    const SizedBox(width: 12),
                    profileAsync.when(
                      data: (profile) => _buildStatChip(
                        '${profile?.streaks[StreakType.dailyClassification.toString()]?.currentCount ?? 0}',
                        'Day Streak',
                        Icons.local_fire_department,
                      ),
                      loading: () => _buildStatChip('...', 'Day Streak', Icons.local_fire_department),
                      error: (_, __) => _buildStatChip('0', 'Day Streak', Icons.local_fire_department),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPointsChip(BuildContext context) {
    final pointsAsync = ref.watch(pointsManagerProvider);
    
    return pointsAsync.when(
      data: (points) => _buildStatChip('${points.total}', 'Points', Icons.stars),
      loading: () => _buildStatChip('...', 'Points', Icons.stars),
      error: (_, __) => _buildStatChip('0', 'Points', Icons.stars),
    );
  }

  Widget _buildStatChip(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionChips(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _getActionItems().length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final action = _getActionItems()[index];
              return _buildActionCard(action);
            },
          ),
        ),
      ],
    );
  }

  List<ActionItem> _getActionItems() {
    return [
      ActionItem(
        title: 'Take Photo',
        subtitle: 'Review & analyze',
        icon: Icons.camera_alt,
        color: const Color(0xFF2196F3),
        onTap: () => _takePhoto(),
      ),
      ActionItem(
        title: 'Upload Image',
        subtitle: 'From gallery',
        icon: Icons.photo_library,
        color: const Color(0xFF4CAF50),
        onTap: () => _pickImage(),
      ),
      ActionItem(
        title: 'Instant Camera',
        subtitle: 'Auto-analyze',
        icon: Icons.flash_on,
        color: const Color(0xFFFF9800),
        onTap: () => _takePhotoInstant(),
      ),
      ActionItem(
        title: 'Instant Upload',
        subtitle: 'Auto-analyze',
        icon: Icons.bolt,
        color: const Color(0xFF9C27B0),
        onTap: () => _pickImageInstant(),
      ),
    ];
  }

  Widget _buildActionCard(ActionItem action) {
    return AnimatedScale(
      scale: 1.0,
      duration: const Duration(milliseconds: 150),
      child: GestureDetector(
        onTapDown: (_) => setState(() {}),
        onTapUp: (_) => setState(() {}),
        onTapCancel: () => setState(() {}),
        onTap: action.onTap,
        child: Container(
          width: 96,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: action.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  action.icon,
                  color: action.color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                action.title,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                action.subtitle,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImpactSection(
    BuildContext context,
    AsyncValue<List<WasteClassification>> classificationsAsync,
    AsyncValue<GamificationProfile?> profileAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Impact',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: classificationsAsync.when(
                data: (classifications) => _buildImpactCard(
                  'Total Items',
                  '${classifications.length}',
                  Icons.recycling,
                  const Color(0xFF4CAF50),
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HistoryScreen()),
                  ),
                ),
                loading: () => _buildImpactCard(
                  'Total Items',
                  '...',
                  Icons.recycling,
                  const Color(0xFF4CAF50),
                  null,
                ),
                error: (_, __) => _buildImpactCard(
                  'Total Items',
                  '0',
                  Icons.recycling,
                  const Color(0xFF4CAF50),
                  null,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: profileAsync.when(
                data: (profile) => _buildImpactCard(
                  'Points',
                  '${profile?.points.total ?? 0}',
                  Icons.stars,
                  const Color(0xFFFFC107),
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AchievementsScreen()),
                  ),
                ),
                loading: () => _buildImpactCard(
                  'Points',
                  '...',
                  Icons.stars,
                  const Color(0xFFFFC107),
                  null,
                ),
                error: (_, __) => _buildImpactCard(
                  'Points',
                  '0',
                  Icons.stars,
                  const Color(0xFFFFC107),
                  null,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImpactCard(String title, String value, IconData icon, Color color, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                if (onTap != null)
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentClassifications(BuildContext context, AsyncValue<List<WasteClassification>> classificationsAsync) {
    return classificationsAsync.when(
      data: (classifications) {
        if (classifications.isEmpty) {
          return _buildEmptyState(context);
        }
        
        final recent = classifications.take(3).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Recent Classifications',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HistoryScreen()),
                  ),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...recent.map((classification) => _buildClassificationCard(classification)),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _buildEmptyState(context),
    );
  }

  Widget _buildClassificationCard(WasteClassification classification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getCategoryColor(classification.category).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getCategoryIcon(classification.category),
              color: _getCategoryColor(classification.category),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  classification.itemName,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Text(
                  classification.category,
                  style: GoogleFonts.inter(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${((classification.confidence ?? 0.0) * 100).round()}%',
              style: GoogleFonts.inter(
                color: Colors.green,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.eco_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Start Your Journey',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Take your first photo to begin making a positive environmental impact!',
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'wet waste':
      case 'organic':
        return const Color(0xFF4CAF50);
      case 'dry waste':
      case 'recyclable':
        return const Color(0xFF2196F3);
      case 'hazardous':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'wet waste':
      case 'organic':
        return Icons.compost;
      case 'dry waste':
      case 'recyclable':
        return Icons.recycling;
      case 'hazardous':
        return Icons.warning;
      default:
        return Icons.delete;
    }
  }

  // Photo capture methods
  Future<void> _takePhoto() async {
    if (_isNavigating) return;
    _isNavigating = true;
    
    try {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      
      if (image != null && mounted) {
        await _navigateToImageCapture(image);
      }
    } catch (e) {
      debugPrint('Error taking photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking photo: $e')),
        );
      }
    } finally {
      _isNavigating = false;
    }
  }

  Future<void> _pickImage() async {
    if (_isNavigating) return;
    _isNavigating = true;
    
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      
      if (image != null && mounted) {
        await _navigateToImageCapture(image);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    } finally {
      _isNavigating = false;
    }
  }

  Future<void> _takePhotoInstant() async {
    if (_isNavigating) return;
    _isNavigating = true;
    
    try {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      
      if (image != null && mounted) {
        await _navigateToInstantAnalysis(image);
      }
    } catch (e) {
      debugPrint('Error taking photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking photo: $e')),
        );
      }
    } finally {
      _isNavigating = false;
    }
  }

  Future<void> _pickImageInstant() async {
    if (_isNavigating) return;
    _isNavigating = true;
    
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      
      if (image != null && mounted) {
        await _navigateToInstantAnalysis(image);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    } finally {
      _isNavigating = false;
    }
  }

  Future<void> _navigateToImageCapture(XFile image) async {
    if (kIsWeb) {
      final bytes = await image.readAsBytes();
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImageCaptureScreen(
              xFile: image,
              webImage: bytes,
            ),
          ),
        );
      }
    } else {
      final file = File(image.path);
      if (await file.exists() && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImageCaptureScreen(
              imageFile: file,
            ),
          ),
        );
      }
    }
  }

  Future<void> _navigateToInstantAnalysis(XFile image) async {
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => InstantAnalysisScreen(image: image),
        ),
      );
    }
  }
}

class ActionItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  ActionItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
} 