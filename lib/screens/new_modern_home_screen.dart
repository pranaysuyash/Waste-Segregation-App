import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../utils/constants.dart';
import '../models/waste_classification.dart';
import '../models/gamification.dart';
import '../providers/app_providers.dart'; // Import central providers
import '../services/community_service.dart';
import '../widgets/modern_ui/modern_cards.dart';
import '../widgets/classification_card.dart';
import '../widgets/advanced_ui/achievement_celebration.dart';
import '../widgets/home_header.dart';
import 'image_capture_screen.dart';
import 'instant_analysis_screen.dart';
import 'history_screen.dart';
import 'achievements_screen.dart';
import 'educational_content_screen.dart';
import 'waste_dashboard_screen.dart';
import 'settings_screen.dart';
import 'social_screen.dart';
import 'package:waste_segregation_app/utils/waste_app_logger.dart';

// REMOVED: Duplicate provider declarations - now imported from app_providers.dart

final communityServiceProvider = Provider<CommunityService>((ref) => CommunityService());

// Fixed connectivity provider to return single ConnectivityResult
final connectivityProvider = StreamProvider<ConnectivityResult>((ref) {
  return Connectivity().onConnectivityChanged.map((results) => 
    results.isNotEmpty ? results.first : ConnectivityResult.none);
});

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

// Classifications provider
final classificationsProvider = FutureProvider<List<WasteClassification>>((ref) async {
  final storageService = ref.watch(storageServiceProvider);
  return storageService.getAllClassifications();
});

// Navigation state provider
final _navIndexProvider = StateProvider<int>((ref) => 0);

class NewModernHomeScreen extends ConsumerStatefulWidget {

  const NewModernHomeScreen({super.key, this.isGuestMode = false});
  final bool isGuestMode;

  @override
  NewModernHomeScreenState createState() => NewModernHomeScreenState();
}

class NewModernHomeScreenState extends ConsumerState<NewModernHomeScreen> 
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final int _selectedIndex = 0;
  final ImagePicker _picker = ImagePicker();
  TutorialCoachMark? _coachMark;
  List<TargetFocus> _targets = [];
  bool _showedCoach = false;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Global keys for tutorial targets
  final GlobalObjectKey _takePhotoKey = const GlobalObjectKey('takePhoto');
  final GlobalObjectKey _homeTabKey = const GlobalObjectKey('homeTab');
  final GlobalObjectKey _analyticsTabKey = const GlobalObjectKey('analyticsTab');

  // Achievement celebration state
  bool _showCelebration = false;
  Achievement? _celebrationAchievement;
  
  // Navigation guard to prevent double navigation
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAnimations();
    _loadFirstRunFlag();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _coachMark?.finish();
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

  Future<void> _loadFirstRunFlag() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _showedCoach = prefs.getBool('new_home_coach_shown') ?? false;
      if (!_showedCoach && mounted) {
        // Delay to ensure widgets are built
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) {
              _prepareCoachTargets();
              _showCoachMark();
              prefs.setBool('new_home_coach_shown', true);
            }
          });
        });
      }
    } catch (e) {
      WasteAppLogger.severe('Error loading first run flag: $e');
    }
  }

  void _prepareCoachTargets() {
    _targets = [
      TargetFocus(
        identify: 'takePhoto',
        keyTarget: _takePhotoKey,
        contents: [
          TargetContent(
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Take Photo',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 20.0,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 10.0),
                  child: Text(
                    'Tap here to take a photo of your waste item for classification.',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'analytics',
        keyTarget: _analyticsTabKey,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analytics',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 20.0,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 10.0),
                  child: Text(
                    'View your waste classification statistics and progress.',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ];
  }

  void _showCoachMark() {
    if (_targets.isEmpty) return;
    
    try {
      _coachMark = TutorialCoachMark(
        targets: _targets,
        onFinish: () {
          WasteAppLogger.info('Tutorial finished');
        },
        onSkip: () {
          WasteAppLogger.info('Tutorial skipped');
          return true;
        },
      );
      _coachMark?.show(context: context);
    } catch (e) {
      WasteAppLogger.severe('Error showing coach mark: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final navIndex = ref.watch(_navIndexProvider);
    final connectivityAsync = ref.watch(connectivityProvider);
    
    return Scaffold(
      body: Stack(
        children: [
          // Main content column
          Column(
            children: [
              // Connectivity banner
              connectivityAsync.when(
                data: (connectivity) => connectivity == ConnectivityResult.none
                    ? const ConnectivityBanner()
                    : const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              
              // Main content - remove Expanded and use Flexible instead
              Flexible(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: IndexedStack(
                      index: navIndex,
                      children: [
                                                                         HomeTab(
                          picker: _picker, 
                          takePhotoKey: _takePhotoKey,
                          onTakePhoto: _takePhoto,
                          onPickImage: _pickImage,
                          onTakePhotoInstant: _takePhotoInstant,
                          onPickImageInstant: _pickImageInstant,
                        ),
                        const AnalyticsTab(),
                        const LearnTab(),
                        const CommunityTab(),
                        const ProfileTab(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // Achievement celebration overlay
          if (_showCelebration && _celebrationAchievement != null)
            AchievementCelebration(
              achievement: _celebrationAchievement!,
              onDismiss: _onCelebrationDismissed,
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(navIndex),
    );
  }

  Widget _buildBottomNavigation(int index) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: index,
      onTap: (index) => ref.read(_navIndexProvider.notifier).state = index,
      items: [
        BottomNavigationBarItem(
          key: _homeTabKey,
          icon: const Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          key: _analyticsTabKey,
          icon: const Icon(Icons.analytics),
          label: 'Analytics',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.school),
          label: 'Learn',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.people),
          label: 'Community',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }

  // Photo capture methods
  Future<void> _takePhoto(ImagePicker picker, BuildContext context) async {
    if (_isNavigating) {
      WasteAppLogger.info('🚫 Navigation already in progress, ignoring tap');
      return;
    }
    
    _isNavigating = true;
    WasteAppLogger.info('📸 Taking photo - manual review mode');
    
    try {
      final image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      
      if (image != null && mounted) {
        await _navigateToImageCapture(image);
      }
    } catch (e) {
      WasteAppLogger.severe('Error taking photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking photo: $e')),
        );
      }
    } finally {
      _isNavigating = false;
    }
  }

  Future<void> _pickImage(ImagePicker picker, BuildContext context) async {
    if (_isNavigating) {
      WasteAppLogger.info('🚫 Navigation already in progress, ignoring tap');
      return;
    }
    
    _isNavigating = true;
    WasteAppLogger.info('🖼️ Picking image - manual review mode');
    
    try {
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      
      if (image != null && mounted) {
        await _navigateToImageCapture(image);
      }
    } catch (e) {
      WasteAppLogger.severe('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    } finally {
      _isNavigating = false;
    }
  }

  // Instant analyze methods
  Future<void> _takePhotoInstant(ImagePicker picker, BuildContext context) async {
    if (_isNavigating) {
      WasteAppLogger.info('🚫 Navigation already in progress, ignoring tap');
      return;
    }
    
    _isNavigating = true;
    WasteAppLogger.info('📸 Taking photo - instant analysis mode');
    
    try {
      final image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      
      if (image != null && mounted) {
        await _navigateToImageCapture(image, autoAnalyze: true);
      }
    } catch (e) {
      WasteAppLogger.severe('Error taking photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking photo: $e')),
        );
      }
    } finally {
      _isNavigating = false;
    }
  }

  Future<void> _pickImageInstant(ImagePicker picker, BuildContext context) async {
    if (_isNavigating) {
      WasteAppLogger.info('🚫 Navigation already in progress, ignoring tap');
      return;
    }
    
    _isNavigating = true;
    WasteAppLogger.info('🖼️ Picking image - instant analysis mode');
    
    try {
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      
      if (image != null && mounted) {
        await _navigateToImageCapture(image, autoAnalyze: true);
      }
    } catch (e) {
      WasteAppLogger.severe('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    } finally {
      _isNavigating = false;
    }
  }

  Future<void> _navigateToImageCapture(XFile image, {bool autoAnalyze = false}) async {
    if (autoAnalyze) {
      // For auto-analyze, go directly to analysis without showing ImageCaptureScreen
      // The InstantAnalysisScreen will handle the entire flow including navigation to ResultScreen
      // and all gamification processing is handled within the ResultScreen itself
      await _navigateToInstantAnalysis(image);
    } else {
      // For manual review, use the traditional flow
      final gamificationService = ref.read(gamificationServiceProvider);
      final oldProfile = await gamificationService.getProfile();
      
      final result = await Navigator.push<WasteClassification>(
        context,
        MaterialPageRoute(
          builder: (context) => ImageCaptureScreen.fromXFile(image),
        ),
      );
      
      if (result != null && mounted) {
        await _handleScanResult(result, oldProfile);
      }
    }
  }

  Future<void> _navigateToInstantAnalysis(XFile image) async {
    // Navigate directly to analysis loader, then to results
    // No need to await a result since InstantAnalysisScreen handles everything internally
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) => InstantAnalysisScreen(image: image),
      ),
    );

    // <-- Add this to force-refresh your history
    ref.invalidate(classificationsProvider);
  }

  Future<void> _handleScanResult(WasteClassification result, GamificationProfile oldProfile) async {
    try {
      final gamificationService = ref.read(gamificationServiceProvider);
      
      // Process the classification for gamification
      await gamificationService.processClassification(result);
      
      // Get updated profile
      final newProfile = await gamificationService.getProfile();
      
      // RACE CONDITION FIX: Invalidate providers to refresh UI with new points
      ref.invalidate(profileProvider);
      ref.invalidate(classificationsProvider);
      
      // Check for daily goal achievement
      await _checkDailyGoalAchievement(oldProfile, newProfile);
      
      // Check for other newly earned achievements
      await _checkNewlyEarnedAchievements(oldProfile, newProfile);
      
    } catch (e) {
      WasteAppLogger.severe('Error handling scan result: $e');
    }
  }

  Future<void> _checkDailyGoalAchievement(GamificationProfile oldProfile, GamificationProfile newProfile) async {
    // Check if daily goal was reached for the first time today
    const dailyGoal = 50; // You can make this configurable from user profile
    
    if (oldProfile.points.total < dailyGoal && newProfile.points.total >= dailyGoal) {
      // Daily goal reached! Show celebration
      final dailyGoalAchievement = Achievement(
        id: 'daily_goal_${DateTime.now().day}',
        title: 'Daily Impact Goal Reached!',
        description: "You've hit your $dailyGoal-point goal today!",
        type: AchievementType.userGoal,
        threshold: dailyGoal,
        pointsReward: 25,
        color: AppTheme.successColor,
        iconName: 'local_fire_department',
      );
      
      _showAchievementCelebration(dailyGoalAchievement);
    }
  }

  Future<void> _checkNewlyEarnedAchievements(GamificationProfile oldProfile, GamificationProfile newProfile) async {
    // Find newly earned achievements
    final oldEarnedIds = oldProfile.achievements
        .where((a) => a.isEarned)
        .map((a) => a.id)
        .toSet();
    
    final newlyEarned = newProfile.achievements
        .where((a) => a.isEarned && !oldEarnedIds.contains(a.id))
        .toList();
    
    // Show celebration for the first newly earned achievement
    if (newlyEarned.isNotEmpty) {
      _showAchievementCelebration(newlyEarned.first);
    }
  }

  void _showAchievementCelebration(Achievement achievement) {
    setState(() {
      _celebrationAchievement = achievement;
      _showCelebration = true;
    });
  }

  void _onCelebrationDismissed() {
    setState(() {
      _showCelebration = false;
      _celebrationAchievement = null;
    });
  }
}

// Connectivity banner widget
class ConnectivityBanner extends StatelessWidget {
  const ConnectivityBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.redAccent,
      height: 24,
      child: const Center(
        child: Text(
          'Offline Mode',
          style: TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }
}

// Tab implementations with beautiful design
class HomeTab extends ConsumerWidget {
  
  const HomeTab({
    super.key, 
    required this.picker, 
    required this.takePhotoKey,
    required this.onTakePhoto,
    required this.onPickImage,
    required this.onTakePhotoInstant,
    required this.onPickImageInstant,
  });
  final ImagePicker picker;
  final GlobalKey takePhotoKey;
  final Future<void> Function(ImagePicker, BuildContext) onTakePhoto;
  final Future<void> Function(ImagePicker, BuildContext) onPickImage;
  final Future<void> Function(ImagePicker, BuildContext) onTakePhotoInstant;
  final Future<void> Function(ImagePicker, BuildContext) onPickImageInstant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classificationsAsync = ref.watch(classificationsProvider);
    final profileAsync = ref.watch(profileProvider);
    
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      children: [
        // NEW: Lean header with personalization and micro-interactions
        const HomeHeader(),
        const SizedBox(height: AppTheme.spacingLg),
        
        // Quick actions with beautiful cards
        _buildQuickActionsSection(context),
        const SizedBox(height: AppTheme.spacingLg),
        
        // Stats overview
        _buildStatsSection(context, classificationsAsync, profileAsync),
        const SizedBox(height: AppTheme.spacingLg),
        
        // Recent classifications
        _buildRecentClassifications(context, classificationsAsync),
        
        // Bottom padding for navigation
        const SizedBox(height: AppTheme.spacingXl),
      ],
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        Row(
          children: [
            Expanded(
              child: ModernCard(
                onTap: () => onTakePhoto(picker, context),
                backgroundColor: Colors.blue.withValues(alpha: 0.1),
                child: Column(
                  children: [
                    Container(
                      key: takePhotoKey,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    const Text(
                      'Take Photo',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXs),
                    Text(
                      'Review & analyze',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: ModernCard(
                onTap: () => onPickImage(picker, context),
                backgroundColor: Colors.green.withValues(alpha: 0.1),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
                      ),
                      child: const Icon(
                        Icons.photo_library,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    const Text(
                      'Upload Image',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXs),
                    Text(
                      'From gallery',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingMd),
        
        // Instant analyze options
        Row(
          children: [
            Expanded(
              child: ModernCard(
                                 onTap: () => onTakePhotoInstant(picker, context),
                backgroundColor: Colors.orange.withValues(alpha: 0.1),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
                      ),
                      child: const Icon(
                        Icons.flash_on,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                                         const SizedBox(height: AppTheme.spacingXs),
                     const Text(
                       'Instant Camera',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXs),
                    Text(
                      'Auto-analyze',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: ModernCard(
                                 onTap: () => onPickImageInstant(picker, context),
                backgroundColor: Colors.purple.withValues(alpha: 0.1),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.purple,
                        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
                      ),
                      child: const Icon(
                        Icons.bolt,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                                         const SizedBox(height: AppTheme.spacingXs),
                     const Text(
                       'Instant Upload',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXs),
                    Text(
                      'Auto-analyze',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsSection(
    BuildContext context, 
    AsyncValue<List<WasteClassification>> classificationsAsync,
    AsyncValue<GamificationProfile?> profileAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Impact',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        Row(
          children: [
            Expanded(
              child: classificationsAsync.when(
                data: (classifications) => StatsCard(
                  title: 'Total Items',
                  value: '${classifications.length}',
                  icon: Icons.recycling,
                  color: AppTheme.primaryColor,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HistoryScreen(),
                      ),
                    );
                  },
                ),
                loading: () => const StatsCard(
                  title: 'Total Items',
                  value: '...',
                  icon: Icons.recycling,
                  color: AppTheme.primaryColor,
                ),
                error: (_, __) => const StatsCard(
                  title: 'Total Items',
                  value: '0',
                  icon: Icons.recycling,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: profileAsync.when(
                data: (profile) => StatsCard(
                  title: 'Points',
                  value: '${profile?.points.total ?? 0}',
                  icon: Icons.stars,
                  color: Colors.amber,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AchievementsScreen(),
                      ),
                    );
                  },
                ),
                loading: () => const StatsCard(
                  title: 'Points',
                  value: '...',
                  icon: Icons.stars,
                  color: Colors.amber,
                ),
                error: (_, __) => const StatsCard(
                  title: 'Points',
                  value: '0',
                  icon: Icons.stars,
                  color: Colors.amber,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentClassifications(
    BuildContext context, 
    AsyncValue<List<WasteClassification>> classificationsAsync,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Classifications',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HistoryScreen(),
                  ),
                );
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingMd),
        classificationsAsync.when(
          data: (classifications) {
            if (classifications.isEmpty) {
              return ModernCard(
                child: Column(
                  children: [
                    Icon(
                      Icons.history,
                      size: AppTheme.iconSizeXl,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    Text(
                      'No classifications yet',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXs),
                    Text(
                      'Take a photo or upload an image to get started',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }
            
            // show just the last 3
            final latest = [...classifications]
              ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
            final recent = latest.take(3).toList();
            return ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: recent.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppTheme.spacingMd),
              itemBuilder: (_, i) => ClassificationCard(classification: recent[i]),
            );
          },
          loading: () => const ModernCard(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const ModernCard(
            child: Text('Error loading classifications'),
          ),
        ),
      ],
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'recyclable':
        return Colors.green;
      case 'organic':
        return Colors.brown;
      case 'hazardous':
        return Colors.red;
      case 'electronic':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'recyclable':
        return Icons.recycling;
      case 'organic':
        return Icons.eco;
      case 'hazardous':
        return Icons.warning;
      case 'electronic':
        return Icons.electrical_services;
      default:
        return Icons.delete;
    }
  }

  Widget _buildBeautifulClassificationCard(BuildContext context, WasteClassification classification) {
    final catColor = _getCategoryColor(classification.category);
    final confidence = (classification.confidence ?? 0) * 100;
    final timeAgo = _formatRelativeTime(classification.timestamp);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: catColor.withValues(alpha: 0.2)),
      ),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () => _showClassificationDetails(context, classification),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // ── Thumbnail ─────────────────────────
              Hero(
                tag: 'photo-${classification.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: classification.imageUrl != null
                      ? Image.network(
                          classification.imageUrl!,
                          width: 64, 
                          height: 64, 
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 64, 
                            height: 64,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [catColor, catColor.withValues(alpha: 0.7)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Icon(
                              _getCategoryIcon(classification.category),
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        )
                      : Container(
                          width: 64, 
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [catColor, catColor.withValues(alpha: 0.7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Icon(
                            _getCategoryIcon(classification.category),
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),

              // ── Main Info ──────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      classification.itemName,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        // Category chip - filled with category color
                        Chip(
                          backgroundColor: catColor.withValues(alpha: 0.1),
                          label: Text(
                            classification.category,
                            style: TextStyle(color: catColor, fontWeight: FontWeight.w500),
                          ),
                          avatar: Icon(
                            _getCategoryIcon(classification.category),
                            size: 16,
                            color: catColor,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),

                        // Disposal method chip - outline style
                        if (classification.disposalMethod != null)
                          Chip(
                            backgroundColor: Colors.white,
                            shape: StadiumBorder(
                              side: BorderSide(color: catColor),
                            ),
                            label: Text(
                              _getDisposalText(classification.disposalMethod),
                              style: TextStyle(color: catColor, fontSize: 12),
                            ),
                            visualDensity: VisualDensity.compact,
                          ),

                        // Confidence chip - color-coded
                        if (classification.confidence != null)
                          Chip(
                            backgroundColor: _confidenceColor(confidence).withValues(alpha: 0.1),
                            label: Text(
                              '${confidence.toInt()}%',
                              style: TextStyle(
                                color: _confidenceColor(confidence),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            avatar: Icon(
                              Icons.verified,
                              size: 16,
                              color: _confidenceColor(confidence),
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Meta row: time ago
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          timeAgo,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Impact + Chevron ───────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Impact points
                  if (classification.environmentalImpact != null)
                    Chip(
                      backgroundColor: Colors.green.withValues(alpha: 0.1),
                      label: Text(
                        '+${classification.environmentalImpact} pts',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                      avatar: const Icon(Icons.eco, size: 16, color: Colors.green),
                      visualDensity: VisualDensity.compact,
                    ),
                  const SizedBox(height: 8),
                  Icon(Icons.chevron_right, color: Colors.grey.shade400),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }

  String _getRelativeTimeDisplay(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays == 0) {
      // Today - show relative time
      if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      // Older items - show date
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  // Helper methods for the enhanced classification cards
  Color _confidenceColor(double pct) {
    if (pct >= 80) return Colors.green;
    if (pct >= 60) return Colors.orange;
    return Colors.red;
  }

  String _formatRelativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  bool _isToday(DateTime dateTime) {
    final now = DateTime.now();
    return dateTime.year == now.year &&
           dateTime.month == now.month &&
           dateTime.day == now.day;
  }

  ({Color color, IconData icon}) _getConfidenceLevel(double? confidence) {
    if (confidence == null) return (color: Colors.grey, icon: Icons.help_outline);
    if (confidence >= 0.8) return (color: Colors.green, icon: Icons.verified);
    if (confidence >= 0.6) return (color: Colors.orange, icon: Icons.check_circle_outline);
    return (color: Colors.red, icon: Icons.warning_outlined);
  }

  Color _getDisposalColor(String? disposalMethod) {
    switch (disposalMethod?.toLowerCase()) {
      case 'recycle':
        return Colors.green;
      case 'compost':
        return Colors.brown;
      case 'hazardous':
        return Colors.red;
      case 'landfill':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  String _getDisposalText(String? disposalMethod) {
    switch (disposalMethod?.toLowerCase()) {
      case 'recycle':
        return 'Recycle';
      case 'compost':
        return 'Compost';
      case 'hazardous':
        return 'Hazardous';
      case 'landfill':
        return 'Landfill';
      default:
        return 'General';
    }
  }

  void _showClassificationDetails(BuildContext context, WasteClassification classification) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      'Classification Details',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      classification.itemName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Category: ${classification.category}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    if (classification.confidence != null)
                      Text(
                        'Confidence: ${(classification.confidence! * 100).toInt()}%',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    if (classification.disposalMethod != null)
                      Text(
                        'Disposal: ${classification.disposalMethod}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    Text(
                      'Date: ${_formatDate(classification.timestamp)} at ${_formatTime(classification.timestamp)}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final classificationDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (classificationDate == today) {
      return 'Today';
    } else if (classificationDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}

class AnalyticsTab extends ConsumerWidget {
  const AnalyticsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classificationsAsync = ref.watch(classificationsProvider);
    final profileAsync = ref.watch(profileProvider);

    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      children: [
        Text(
          'Analytics Dashboard',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spacingLg),
        
        // Quick stats cards
        Row(
          children: [
            Expanded(
              child: classificationsAsync.when(
                data: (classifications) => _buildAnalyticsCard(
                  context,
                  'Total Classifications',
                  '${classifications.length}',
                  Icons.analytics,
                  Colors.blue,
                ),
                loading: () => _buildAnalyticsCard(
                  context,
                  'Total Classifications',
                  '...',
                  Icons.analytics,
                  Colors.blue,
                ),
                error: (_, __) => _buildAnalyticsCard(
                  context,
                  'Total Classifications',
                  '0',
                  Icons.analytics,
                  Colors.blue,
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: classificationsAsync.when(
                data: (classifications) {
                  final today = DateTime.now();
                  final todayCount = classifications.where((c) => 
                    c.timestamp.year == today.year &&
                    c.timestamp.month == today.month &&
                    c.timestamp.day == today.day
                  ).length;
                  return _buildAnalyticsCard(
                    context,
                    'Today',
                    '$todayCount',
                    Icons.today,
                    Colors.green,
                  );
                },
                loading: () => _buildAnalyticsCard(
                  context,
                  'Today',
                  '...',
                  Icons.today,
                  Colors.green,
                ),
                error: (_, __) => _buildAnalyticsCard(
                  context,
                  'Today',
                  '0',
                  Icons.today,
                  Colors.green,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: AppTheme.spacingLg),
        
        // Feature cards for detailed analytics
        FeatureCard(
          icon: Icons.bar_chart,
          title: 'Detailed Analytics',
          subtitle: 'View comprehensive waste classification statistics',
          iconColor: AppTheme.infoColor,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const WasteDashboardScreen(),
              ),
            );
          },
        ),
        
        const SizedBox(height: AppTheme.spacingSm),
        
        FeatureCard(
          icon: Icons.history,
          title: 'Classification History',
          subtitle: 'Browse all your past classifications',
          iconColor: Colors.purple,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const HistoryScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAnalyticsCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return ModernCard(
      backgroundColor: color.withValues(alpha: 0.1),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMd),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class LearnTab extends StatelessWidget {
  const LearnTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      children: [
        Text(
          'Learn & Grow',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spacingLg),
        
        FeatureCard(
          icon: Icons.school,
          title: 'Educational Content',
          subtitle: 'Learn about waste management and environmental impact',
          iconColor: AppTheme.successColor,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const EducationalContentScreen(),
              ),
            );
          },
        ),
        
        const SizedBox(height: AppTheme.spacingSm),
        
        FeatureCard(
          icon: Icons.tips_and_updates,
          title: 'Eco Tips',
          subtitle: 'Daily tips for sustainable living',
          iconColor: Colors.orange,
          onTap: () {
            // Navigate to tips screen
          },
        ),
        
        const SizedBox(height: AppTheme.spacingSm),
        
        FeatureCard(
          icon: Icons.quiz,
          title: 'Knowledge Quiz',
          subtitle: 'Test your environmental knowledge',
          iconColor: Colors.purple,
          onTap: () {
            // Navigate to quiz screen
          },
        ),
      ],
    );
  }
}

class CommunityTab extends ConsumerWidget {
  const CommunityTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final communityService = ref.watch(communityServiceProvider);
    
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      children: [
        Text(
          'Community',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spacingLg),
        
        FeatureCard(
          icon: Icons.people,
          title: 'Community Feed',
          subtitle: 'Connect with other eco-warriors',
          iconColor: Colors.blue,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SocialScreen(),
              ),
            );
          },
        ),
        
        const SizedBox(height: AppTheme.spacingSm),
        
        FeatureCard(
          icon: Icons.leaderboard,
          title: 'Leaderboard',
          subtitle: 'See how you rank among other users',
          iconColor: Colors.amber,
          onTap: () {
            // Navigate to leaderboard
          },
        ),
        
        const SizedBox(height: AppTheme.spacingSm),
        
        FeatureCard(
          icon: Icons.campaign,
          title: 'Environmental Campaigns',
          subtitle: 'Join local environmental initiatives',
          iconColor: Colors.green,
          onTap: () {
            // Navigate to campaigns
          },
        ),
      ],
    );
  }
}

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      children: [
        Text(
          'Profile',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spacingLg),
        
        // Profile card
        profileAsync.when(
          data: (profile) => ModernCard(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppTheme.primaryColor,
                  child: Text(
                    'U',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                Text(
                  'User Profile',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXs),
                                 Text(
                   '${profile?.points.total ?? 0} points • Level ${profile?.points.level ?? 1}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          loading: () => const ModernCard(
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const ModernCard(
            child: Text('Error loading profile'),
          ),
        ),
        
        const SizedBox(height: AppTheme.spacingLg),
        
        FeatureCard(
          icon: Icons.settings,
          title: 'Settings',
          subtitle: 'Manage your account and preferences',
          iconColor: Colors.grey,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SettingsScreen(),
              ),
            );
          },
        ),
        
        const SizedBox(height: AppTheme.spacingSm),
        
        FeatureCard(
          icon: Icons.emoji_events,
          title: 'Achievements',
          subtitle: 'View your earned badges and milestones',
          iconColor: Colors.amber,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AchievementsScreen(),
              ),
            );
          },
        ),
      ],
    );
  }
} 