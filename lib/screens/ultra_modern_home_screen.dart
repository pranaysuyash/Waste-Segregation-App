import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/waste_classification.dart';
import '../models/gamification.dart';
import '../models/user_profile.dart';
import '../providers/app_providers.dart';
import '../providers/points_manager.dart';
import '../screens/history_screen.dart';
import '../screens/achievements_screen.dart';
import '../screens/image_capture_screen.dart';
import '../screens/instant_analysis_screen.dart';
import '../utils/constants.dart';
import 'package:waste_segregation_app/utils/waste_app_logger.dart';

// Profile provider using FutureProvider for better performance
final profileProvider = FutureProvider<GamificationProfile?>((ref) async {
  final gamificationService = ref.watch(gamificationServiceProvider);
  try {
    return await gamificationService.getProfile();
  } catch (e) {
    WasteAppLogger.severe('Error loading profile: $e');
    return null;
  }
});

// User profile provider for getting actual user name
final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final storageService = ref.watch(storageServiceProvider);
  try {
    return await storageService.getCurrentUserProfile();
  } catch (e) {
    WasteAppLogger.severe('Error loading user profile: $e');
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
    final userProfileAsync = ref.watch(userProfileProvider);
    
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
                  _buildHeroHeader(context, profileAsync, userProfileAsync),
                  
                  // Content sections
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        
                        // Horizontal scrolling action chips
                        _buildActionChips(context),
                        const SizedBox(height: 20),
                        
                        // Content with padding
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Active Challenge section
                              _buildActiveChallengeSection(context, profileAsync),
                              const SizedBox(height: 32),
                              
                              // Recent Classifications
                              _buildRecentClassifications(context, classificationsAsync),
                              
                              // Bottom padding for navigation
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ],
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

  Widget _buildHeroHeader(BuildContext context, AsyncValue<GamificationProfile?> profileAsync, AsyncValue<UserProfile?> userProfileAsync) {
    final hour = DateTime.now().hour;
    final timePhase = _getTimePhase(hour);
    final greeting = _getPersonalizedGreeting(timePhase);
    final gradientColors = _getTimeBasedGradient(hour);
    
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Greeting and user info
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          userProfileAsync.when(
                            data: (userProfile) {
                              final firstName = userProfile?.displayName?.split(' ').first ?? AppStrings.ecoHero;
                              return Text(
                                '$greeting, $firstName!',
                                style: GoogleFonts.inter(
                                  fontSize: AppTheme.fontSizeLarge,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1.1,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              );
                            },
                            loading: () => Text(
                              '$greeting, ${AppStrings.ecoHero}!',
                              style: GoogleFonts.inter(
                                fontSize: AppTheme.fontSizeLarge,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            error: (_, __) => Text(
                              '$greeting, ${AppStrings.ecoHero}!',
                              style: GoogleFonts.inter(
                                fontSize: AppTheme.fontSizeLarge,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getMotivationalMessage(timePhase),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.9),
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Time-aware animated icon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getTimeBasedIcon(timePhase),
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Stats chips with impact info
                Row(
                  children: [
                    _buildPointsChip(context),
                    const SizedBox(width: 8),
                    profileAsync.when(
                      data: (profile) => _buildStatChip(
                        '${profile?.streaks[StreakType.dailyClassification.toString()]?.currentCount ?? 0}',
                        AppStrings.streak,
                        Icons.local_fire_department,
                      ),
                      loading: () => _buildStatChip('...', AppStrings.streak, Icons.local_fire_department),
                      error: (_, __) => _buildStatChip('0', AppStrings.streak, Icons.local_fire_department),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDaysActiveChip(context),
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
      data: (points) => _buildStatChip('${points.total}', AppStrings.points, Icons.stars),
      loading: () => _buildStatChip('...', AppStrings.points, Icons.stars),
      error: (_, __) => _buildStatChip('0', AppStrings.points, Icons.stars),
    );
  }

  Widget _buildDaysActiveChip(BuildContext context) {
    final classificationsAsync = ref.watch(classificationsProvider);
    final userProfileAsync = ref.watch(userProfileProvider);
    
    return classificationsAsync.when(
      data: (classifications) {
        return userProfileAsync.when(
          data: (userProfile) {
            // Calculate unique days with activity (classifications)
            final uniqueActivityDays = <String>{};
            for (final classification in classifications) {
              final dateKey = '${classification.timestamp.year}-${classification.timestamp.month}-${classification.timestamp.day}';
              uniqueActivityDays.add(dateKey);
            }
            
            // If user has activity days, use that count
            // Otherwise, fall back to days since account creation (logged-in days)
            int daysActive;
            if (uniqueActivityDays.isNotEmpty) {
              daysActive = uniqueActivityDays.length;
            } else if (userProfile?.createdAt != null) {
              daysActive = DateTime.now().difference(userProfile!.createdAt!).inDays + 1;
            } else {
              daysActive = 1;
            }
            
            return _buildStatChip('$daysActive', 'Days Active', Icons.eco);
          },
          loading: () => _buildStatChip('...', 'Days Active', Icons.eco),
          error: (_, __) => _buildStatChip('1', 'Days Active', Icons.eco),
        );
      },
      loading: () => _buildStatChip('...', 'Days Active', Icons.eco),
      error: (_, __) => _buildStatChip('1', 'Days Active', Icons.eco),
    );
  }

  Widget _buildStatChip(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: AppTheme.fontSizeRegular,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                                      style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: AppTheme.fontSizeSmall,
                    ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionChips(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _getActionItems().length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final action = _getActionItems()[index];
          return _buildActionCard(action);
        },
      ),
    );
  }

  List<ActionItem> _getActionItems() {
    return [
      ActionItem(
        title: AppStrings.takePhoto,
        subtitle: AppStrings.reviewAnalyze,
        icon: Icons.camera_alt,
        color: const Color(0xFF2196F3),
        onTap: () => _takePhoto(),
      ),
      ActionItem(
        title: AppStrings.uploadImage,
        subtitle: AppStrings.fromGallery,
        icon: Icons.photo_library,
        color: const Color(0xFF4CAF50),
        onTap: () => _pickImage(),
      ),
      ActionItem(
        title: AppStrings.instantCamera,
        subtitle: AppStrings.autoAnalyze,
        icon: Icons.flash_on,
        color: const Color(0xFFFF9800),
        onTap: () => _takePhotoInstant(),
      ),
      ActionItem(
        title: AppStrings.instantUpload,
        subtitle: AppStrings.autoAnalyze,
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
          width: MediaQuery.of(context).size.width * 0.32, // Even bigger cards for better interaction
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

  Widget _buildActiveChallengeSection(BuildContext context, AsyncValue<GamificationProfile?> profileAsync) {
    return profileAsync.when(
      data: (profile) {
        if (profile?.activeChallenges == null || profile!.activeChallenges.isEmpty) {
          return const SizedBox.shrink();
        }
        
        // Find active challenges with progress > 0
        final activeChallenges = profile.activeChallenges.where((challenge) {
          return challenge.isActive && !challenge.isCompleted && challenge.progress > 0;
        }).toList();
        
        if (activeChallenges.isEmpty) {
          return const SizedBox.shrink();
        }
        
        // Pick a random active challenge based on day
        final randomChallenge = activeChallenges[DateTime.now().day % activeChallenges.length];
        final progressPercentage = (randomChallenge.progress * 100).round();
        final currentCount = (randomChallenge.progress * (randomChallenge.requirements['count'] ?? 1)).round();
        final targetCount = randomChallenge.requirements['count'] ?? 1;
        
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AchievementsScreen()),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  randomChallenge.color.withValues(alpha: 0.1),
                  randomChallenge.color.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: randomChallenge.color.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: randomChallenge.color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getChallengeIcon(randomChallenge.iconName),
                        color: randomChallenge.color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            randomChallenge.title,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            randomChallenge.description,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '$progressPercentage%',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: randomChallenge.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: randomChallenge.progress,
                        backgroundColor: randomChallenge.color.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(randomChallenge.color),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '$currentCount/$targetCount',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  IconData _getChallengeIcon(String iconName) {
    switch (iconName) {
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'restaurant':
        return Icons.restaurant;
      case 'recycling':
        return Icons.recycling;
      case 'compost':
        return Icons.eco;
      case 'warning':
        return Icons.warning;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'battery_charging_full':
        return Icons.battery_charging_full;
      case 'lightbulb':
        return Icons.lightbulb;
      default:
        return Icons.star;
    }
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
                    AppStrings.recentClassifications,
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
                  child: const Text(AppStrings.viewAll),
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
            AppStrings.startYourJourney,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.takeFirstPhoto,
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
      WasteAppLogger.severe('${AppStrings.errorTakingPhoto}: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppStrings.errorTakingPhoto}: $e')),
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
      WasteAppLogger.severe('${AppStrings.errorPickingImage}: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppStrings.errorPickingImage}: $e')),
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
      WasteAppLogger.severe('${AppStrings.errorTakingPhoto}: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppStrings.errorTakingPhoto}: $e')),
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
      WasteAppLogger.severe('${AppStrings.errorPickingImage}: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppStrings.errorPickingImage}: $e')),
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

  // Time-based personalization helper methods
  String _getTimePhase(int hour) {
    if (hour >= 5 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 17) return 'afternoon';
    if (hour >= 17 && hour < 21) return 'evening';
    return 'night';
  }

  String _getPersonalizedGreeting(String phase) {
    switch (phase) {
      case 'morning':
        return AppStrings.goodMorning;
      case 'afternoon':
        return AppStrings.goodAfternoon;
      case 'evening':
        return AppStrings.goodEvening;
      case 'night':
        return AppStrings.goodEvening;
      default:
        return 'Welcome back';
    }
  }

  String _getMotivationalMessage(String phase) {
    switch (phase) {
      case 'morning':
        return AppStrings.keepGoingChampion;
      case 'afternoon':
        return AppStrings.energyToday;
      case 'evening':
        return AppStrings.excellentProgress;
      case 'night':
        return AppStrings.nightOwlEco;
      default:
        return AppStrings.makingDifference;
    }
  }

  List<Color> _getTimeBasedGradient(int hour) {
    if (hour >= 5 && hour < 12) {
      // Morning: Fresh green with golden sunrise
      return [const Color(0xFF4CAF50), const Color(0xFF8BC34A)];
    } else if (hour >= 12 && hour < 17) {
      // Afternoon: Bright eco green
      return [const Color(0xFF43A047), const Color(0xFF66BB6A)];
    } else if (hour >= 17 && hour < 21) {
      // Evening: Warm green with orange sunset
      return [const Color(0xFF388E3C), const Color(0xFF689F38)];
    } else {
      // Night: Deep green with blue tones
      return [const Color(0xFF2E7D32), const Color(0xFF388E3C)];
    }
  }

  IconData _getTimeBasedIcon(String phase) {
    switch (phase) {
      case 'morning':
        return Icons.wb_sunny;
      case 'afternoon':
        return Icons.eco;
      case 'evening':
        return Icons.wb_twilight;
      case 'night':
        return Icons.nights_stay;
      default:
        return Icons.eco;
    }
  }
}

class ActionItem {
  ActionItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
} 